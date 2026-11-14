package LibTmux::Filter;
use v5.44;
use Scalar::Util qw(blessed refaddr reftype);
use JSON::PP     ();
use Storable     qw(dclone);
use LibTmux::Schema;
use LibTmux::X;

sub new ($class, %args) {
    my $kind = $args{entity};
    LibTmux::Schema->entity($kind);
    my $state = {seen => {}, nodes => 0};
    my ($tree, $where) =
        _compile($kind, $args{where}, "$kind.where", $state, 0);
    return bless {entity => $kind, tree => $tree, where => $where}, $class;
}
sub entity           ($self) { $self->{entity} }
sub normalized_where ($self) { dclone($self->{where}) }

sub register_adapter ($class, %args) {
    LibTmux::Schema->register_adapter(%args);
}

sub _bad ($path, $expected, $value) {
    LibTmux::Schema->invalid($path, $expected, $value);
}

sub _compile ($kind, $input, $path, $state, $depth) {
    _bad($path, 'unblessed criteria hash reference', $input)
        unless ref($input) eq 'HASH';
    _bad($path, 'acyclic criteria of depth <=64 and <=10000 nodes', $input)
        if $depth > 64
        || ++$state->{nodes} > 10000
        || $state->{seen}{refaddr $input};
    local $state->{seen}{refaddr $input} = 1;
    my (@children, %normalized);
    for my $key (sort keys %$input) {
        my $rhs = $input->{$key};
        my $at  = "$path.$key";
        if ($key eq '-and' || $key eq '-or') {
            _bad($at, 'array of criteria nodes', $rhs)
                unless ref($rhs) eq 'ARRAY';
            my (@nodes, @values);
            for my $i (0 .. $#$rhs) {
                my ($node, $value) =
                    _compile($kind, $rhs->[$i], "$at.$i", $state, $depth + 1);
                push @nodes,  $node;
                push @values, $value;
            }
            push @children, {tag => substr($key, 1), children => \@nodes};
            $normalized{$key} = \@values;
            next;
        }
        if ($key eq '-not') {
            my ($node, $value) = _compile($kind, $rhs, $at, $state, $depth + 1);
            push @children, {tag => 'not', child => $node};
            $normalized{$key} = $value;
            next;
        }
        my $field = LibTmux::Schema->field($kind, $key);
        _bad($at, 'registered field', $key) unless $field;
        my $ops = ref($rhs) eq 'HASH' ? $rhs : {-eq => $rhs};
        _bad($at, 'scalar or operator hash reference', $rhs)
            if ref($rhs) && ref($rhs) ne 'HASH';
        _bad($at, 'nonempty operator hash reference', $ops) unless keys %$ops;
        my %values;
        for my $op (sort keys %$ops) {
            my $name = $op =~ s/^-//r;
            _bad("$at.$op", 'allowed field operator', $op)
                unless $op =~ /^-/ && CORE::grep { $_ eq $name }
                $field->{operators}->@*;
            my $value = $ops->{$op};
            if ($field->{type} eq 'relation') {
                if (!defined($value) && !$field->{many} && $field->{nullable}) {
                    push @children,
                        {
                        tag   => 'relation',
                        kind  => $kind,
                        field => $key,
                        spec  => $field,
                        op    => $name,
                        child => undef,
                        path  => "$at.$op"
                        };
                    $values{$op} = undef;
                }
                else {
                    my ($node, $normal) =
                        _compile($field->{entity}, $value, "$at.$op", $state,
                        $depth + 1);
                    push @children,
                        {
                        tag   => 'relation',
                        kind  => $kind,
                        field => $key,
                        spec  => $field,
                        op    => $name,
                        child => $node,
                        path  => "$at.$op"
                        };
                    $values{$op} = $normal;
                }
                next;
            }
            if ($name eq 'in' || $name eq 'not_in') {
                _bad("$at.$op", 'array of scalar operands', $value)
                    unless ref($value) eq 'ARRAY';
                $value =
                    [map { LibTmux::Schema->normalize($field, $_, "$at.$op") }
                        @$value];
            }
            else {
                my %operand_spec = %$field;
                $operand_spec{nullable} = false
                    unless $name eq 'eq' || $name eq 'ne';
                $value = LibTmux::Schema->normalize(\%operand_spec, $value,
                    "$at.$op");
            }
            $values{$op} = $value;
            push @children,
                {
                tag   => 'scalar',
                kind  => $kind,
                field => $key,
                spec  => $field,
                op    => $name,
                value => $value,
                path  => "$at.$op"
                };
        }
        $normalized{$key} = ref($rhs) eq 'HASH' ? \%values : $values{'-eq'};
    }
    return ({tag => 'and', children => \@children}, \%normalized);
}

sub matches ($self, $record) {
    LibTmux::Schema->assert_record($self->entity, $record, $self->entity);
    return _evaluate($self->{tree}, $record) ? true : false;
}

sub _equal ($spec, $left, $right) {
    return !defined($left) && !defined($right)
        if !defined($left) || !defined($right);
    return $left == $right
        if $spec->{type} eq 'integer' || $spec->{type} eq 'boolean';
    return $left eq $right;
}

sub _evaluate ($node, $record) {
    my $tag = $node->{tag};
    if ($tag eq 'and') {
        for my $child ($node->{children}->@*) {
            return false unless _evaluate($child, $record);
        }
        return true;
    }
    if ($tag eq 'or') {
        for my $child ($node->{children}->@*) {
            return true if _evaluate($child, $record);
        }
        return false;
    }
    return !_evaluate($node->{child}, $record) if $tag eq 'not';
    my $op = $node->{op};
    if (   $tag eq 'scalar'
        && ($op eq 'in' || $op eq 'not_in')
        && !$node->{value}->@*)
    {
        return $op eq 'not_in';
    }
    my $left = LibTmux::Schema->read($node->{kind}, $record, $node->{field},
        $node->{path});
    if ($tag eq 'relation') {
        my $spec = $node->{spec};
        if (!$spec->{many}) {
            _bad($node->{path}, 'non-null relation', $left)
                if !defined($left) && !$spec->{nullable};
            my $match =
                  !defined($node->{child})
                ? !defined($left)
                : defined($left) ? do {
                LibTmux::Schema->assert_record($spec->{entity}, $left,
                    $node->{path});
                _evaluate($node->{child}, $left);
                }
                : false;
            return $op eq 'is_not' ? !$match : !!$match;
        }
        _bad($node->{path}, 'loaded relation array', $left)
            unless (reftype($left) // '') eq 'ARRAY';
        for my $i (0 .. $#$left) {
            _bad($node->{path}, 'defined relation member', $left->[$i])
                unless exists($left->[$i]) && defined($left->[$i]);
            LibTmux::Schema->assert_record($spec->{entity}, $left->[$i],
                $node->{path});
        }
        for my $child (@$left) {
            my $match = _evaluate($node->{child}, $child);
            return true  if $op eq 'some'  && $match;
            return false if $op eq 'every' && !$match;
            return false if $op eq 'none'  && $match;
        }
        return $op ne 'some';
    }
    my $right = $node->{value};
    return _equal($node->{spec},  $left, $right) if $op eq 'eq';
    return !_equal($node->{spec}, $left, $right) if $op eq 'ne';
    if ($op eq 'in' || $op eq 'not_in') {
        my $found = false;
        for my $item (@$right) {
            if (_equal($node->{spec}, $left, $item)) { $found = true; last }
        }
        return $op eq 'in' ? $found : !$found;
    }
    return false unless defined $left;
    return $left < $right            if $op eq 'lt';
    return $left <= $right           if $op eq 'lte';
    return $left > $right            if $op eq 'gt';
    return $left >= $right           if $op eq 'gte';
    return index($left, $right) >= 0 if $op eq 'contains';
    return index($left, $right) == 0 if $op eq 'starts_with';
    return !length($right)
        || (length($left) >= length($right)
        && substr($left, -length($right)) eq $right)
        if $op eq 'ends_with';
    die 'unreachable compiled operator';
}
sub _wire_op ($name) { $name =~ s/^-//; $name =~ s/_([a-z])/uc($1)/ge; $name }

sub _convert ($kind, $input, $decode, $path, $depth = 0) {
    _bad($path, 'criteria object of depth <=64', $input)
        unless ref($input) eq 'HASH' && $depth <= 64;
    my %out;
    my $fields = LibTmux::Schema->entity($kind)->{fields};
    my %names =
        map { ($decode ? $fields->{$_}{wire} : $_) => $_ } keys %$fields;
    for my $key (sort keys %$input) {
        my $logical =
            $decode && $key =~ /\A(and|or|not)\z/ ? '-' . $key : undef;
        $logical = $key if !$decode && $key =~ /\A-(and|or|not)\z/;
        if (defined $logical) {
            my $value = $input->{$key};
            my $dest  = $decode ? $logical : substr($logical, 1);
            if ($logical eq '-not') {
                $out{$dest} =
                    _convert($kind, $value, $decode, "$path.$key", $depth + 1);
            }
            else {
                _bad("$path.$key", 'array of criteria', $value)
                    unless ref($value) eq 'ARRAY';
                $out{$dest} = [
                    map {
                        _convert($kind, $_, $decode, "$path.$key", $depth + 1)
                    } @$value
                ];
            }
            next;
        }
        my $fieldname = $names{$key};
        _bad("$path.$key", 'registered wire field', $key)
            unless defined $fieldname;
        my $field = $fields->{$fieldname};
        my $dest  = $decode ? $fieldname : $field->{wire};
        my $value = $input->{$key};
        if (ref($value) eq 'HASH') {
            my %ops;
            my %opnames = map { ($decode ? _wire_op($_) : '-' . $_) => $_ }
                $field->{operators}->@*;
            for my $operator (sort keys %$value) {
                my $op = $opnames{$operator};
                _bad("$path.$key.$operator", 'registered operator', $operator)
                    unless defined $op;
                my $v = $value->{$operator};
                if ($field->{type} eq 'relation' && defined $v) {
                    $v = _convert($field->{entity}, $v, $decode,
                        "$path.$key.$operator", $depth + 1);
                }
                elsif (!$decode) {
                    $v =
                        ref($v) eq 'ARRAY'
                        ? [
                        map { LibTmux::Schema->wire_scalar($field, $_, $path) }
                            @$v
                        ]
                        : LibTmux::Schema->wire_scalar($field, $v, $path);
                }
                $ops{$decode ? '-' . $op : _wire_op($op)} = $v;
            }
            $out{$dest} = \%ops;
        }
        else {
            $out{$dest} =
                  $decode
                ? $value
                : LibTmux::Schema->wire_scalar($field, $value, $path);
        }
    }
    return \%out;
}

sub to_data ($self) {
    return {
        schema => 'libtmux.where/v1',
        entity => $self->entity,
        where  => _convert(
            $self->entity, $self->{where}, false, $self->entity . '.where'
        )
    };
}

sub to_json ($self) {
    JSON::PP->new->canonical->utf8->core_bools->encode($self->to_data);
}

sub from_data ($class, $data) {
    _bad('wire', 'versioned filter envelope', $data)
        unless ref($data) eq 'HASH'
        && keys(%$data) == 3
        && exists($data->{schema})
        && exists($data->{entity})
        && exists($data->{where});
    _bad('wire.schema', 'libtmux.where/v1', $data->{schema})
        unless !ref($data->{schema}) && $data->{schema} eq 'libtmux.where/v1';
    LibTmux::Schema->entity($data->{entity});
    return $class->new(
        entity => $data->{entity},
        where  => _convert($data->{entity}, $data->{where}, true, 'wire.where')
    );
}

sub from_json ($class, $bytes) {
    my $data;
    try {
        $data = JSON::PP->new->utf8->core_bools->max_depth(64)->decode($bytes)
    }
    catch ($e) { _bad('wire', 'valid JSON envelope', $bytes) }
    return $class->from_data($data);
}

=head1 NAME

LibTmux::Filter - Validated, reusable local criteria and explicit wire data

=head1 SYNOPSIS

    use v5.44;
    use LibTmux::Filter;
    my $filter = LibTmux::Filter->new(
        entity => 'pane', where => {width => {-gte => 120}},
    );
    my $matches = $snapshot->panes->where($filter);

=head1 CONTRACT

Compilation validates the entire tree and copies operands. Hash keys evaluate
lexically; logical arrays retain input order. Missing reads throw; known-null
ordering is false. String operators are literal. Relations use some/every/none
and is/is_not with explicit dash prefixes in Perl data.

C<matches> accepts entities, plain records, and registered adapters.
C<to_data>/C<to_json> export copies in libtmux.where/v1; C<from_data>/C<from_json>
validate input. Regex/coderefs/cycles and non-UTF-8 byte-path wire operands are
refused. Perl regex remains available through Selection C<grep>.

=head1 METHODS

=head2 new

C<new(entity =E<gt> kind, where =E<gt> $hashref)> validates the complete criteria tree and owns a normalized copy. Schemas choose comparison types; no scalar-history coercion or arbitrary method dispatch occurs. Errors throw L<InvalidFilter|LibTmux::X/InvalidFilter> with precise paths, even for unreachable branches.

=head2 entity

Return the declared entity-kind string. It remains known for an empty L<LibTmux::Selection>.

=head2 normalized_where

Return an independent copy of normalized Perl criteria. Editing it does not change the compiled filter.

=head2 matches

C<matches($entity_or_record)> returns a native Boolean. Accept captured entities, plain hash records, or registered adapters of the declared kind. Missing required reads throw L<Unloaded|LibTmux::X/Unloaded>; they never become null or false through negation. Evaluation performs no I/O.

=head2 register_adapter

C<register_adapter(class =E<gt> name, entity =E<gt> kind, readers =E<gt> { field =E<gt> coderef })> registers trusted field readers without inheritance. Only declared fields are accepted. Readers are executable local code; they never enter portable criteria. See L<LibTmux::Schema>.

=head2 to_data

Return a fresh C<libtmux.where/v1> envelope using canonical wire field/operator names. Normalize strings, numbers, native booleans, null, objects, and arrays by schema. Aliases are currently absent; one canonical name is encoded.

=head2 to_json

Return canonical-key UTF-8 JSON octets using L<JSON::PP>. Non-UTF-8 opaque path bytes throw L<UnsupportedValue|LibTmux::X/UnsupportedValue>. This is reproducible key order, not semantic canonicalization of arbitrary Boolean trees.

=head2 from_data

C<from_data($envelope)> validates the version, entity, fields, operators, and operands, then returns a compiled filter. Reject executable values, unknown versions, cycles, and unsupported regex nodes.

=head2 from_json

C<from_json($json_octets)> decodes bounded JSON using core booleans and calls L</from_data>. Invalid JSON throws L<InvalidFilter|LibTmux::X/InvalidFilter>.

=head1 EXECUTION

All methods in this module operate on local captured data and perform no tmux
I/O. Ordering is deterministic; public query methods do not mutate membership.
Typed validation/evaluation errors propagate. See L<LibTmux::Server/snapshot>
for explicit acquisition and L<LibTmux::X> for machine-readable failures.

=cut
