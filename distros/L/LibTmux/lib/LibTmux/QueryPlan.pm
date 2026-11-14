package LibTmux::QueryPlan;
use v5.44;
use Scalar::Util qw(blessed);
use LibTmux::Filter;
use LibTmux::Schema;
use LibTmux::X;

sub new ($class, %args) {
    my $policy = $args{pushdown} // 'auto';
    LibTmux::X::InvalidArgument->throw(
        message => 'pushdown must be auto/never/require')
        unless $policy =~ /\A(?:auto|never|require)\z/;
    LibTmux::X::InvalidArgument->throw(
        message => 'native_filter is exclusive with criteria and pushdown')
        if exists($args{native_filter})
        && (exists($args{where}) || exists($args{pushdown}));
    my $filter =
        blessed($args{where})
        && $args{where}->isa('LibTmux::Filter')
        ? $args{where}
        : LibTmux::Filter->new(entity => 'pane', where => $args{where} // {});
    LibTmux::X::InvalidFilter->throw(
        message => 'pane query needs a pane filter')
        unless $filter->entity eq 'pane';
    return bless {
        filter        => $filter,
        policy        => $policy,
        native_filter => $args{native_filter}
    }, $class;
}
sub filter ($self) { $self->{filter} }
sub policy ($self) { $self->{policy} }

sub _verification_report ($self, $snapshot, $local, $lowered, $native = undef) {
    my $metadata = $snapshot->metadata;
    my @captured = map { $_->id } $snapshot->panes->@*;
    my @local    = map { $_->id } $local->@*;
    my %captured = map { $_ => true } @captured;
    my %local    = map { $_ => true } @local;
    my %native   = map { $_ => true } ($native // [])->@*;
    my $expert   = $self->_is_native;
    my $checked  = defined $native;
    my @missing  = $checked && !$expert ? grep { !$native{$_} } @local : ();
    my @unexpected =
        $checked && !$expert && $lowered->{exact}
        ? grep { !$local{$_} } @$native
        : ();
    my @uncaptured = $checked ? grep { !$captured{$_} } @$native : ();
    my $disagree   = @missing || @unexpected || @uncaptured;
    return {
        policy => $expert ? 'native' : $self->policy,
        status => !$checked ? ($self->policy eq 'never' ? 'disabled' : 'local')
        : $disagree ? 'disagreed'
        : $expert   ? 'native'
        : 'agreed',
        comparison => !$checked ? 'none'
        : $expert           ? 'captured_membership'
        : $lowered->{exact} ? 'exact_ids'
        : 'candidate_superset',
        native_checked    => !!$checked,
        translation_exact => $expert
            || $self->policy eq 'never' ? undef : !!$lowered->{exact},
        native_filter  => $checked ? $lowered->{filter} : undef,
        reasons        => [($lowered->{reasons} // [])->@*],
        server_id      => $snapshot->server_id,
        generation     => $snapshot->generation,
        daemon_version => $metadata->{version},
        capture_start  => $metadata->{capture_start},
        capture_end    => $metadata->{capture_end},
        captured_ids   => [@captured],
        local_ids      => $expert  ? undef      : [@local],
        native_ids     => $checked ? [@$native] : undef,
        missing_ids    => [@missing],
        unexpected_ids => [@unexpected],
        uncaptured_ids => [@uncaptured],
    };
}

sub _is_native ($self) {
    exists $self->{native_filter} && defined $self->{native_filter};
}
sub _literal ($value) { $value =~ s/([#,}])/#$1/g; $value }

sub _join ($operator, $expressions, $identity) {
    return $identity unless @$expressions;
    my $value = shift @$expressions;
    $value = "#{$operator:$value,$_}" for @$expressions;
    return $value;
}

sub _node ($input, $version) {
    my (@parts, @reasons);
    my $exact = true;
    for my $key (sort keys %$input) {
        my $rhs = $input->{$key};
        if ($key eq '-and' || $key eq '-or') {
            my (@children, $all_exact);
            $all_exact = true;
            for my $child (@$rhs) {
                my ($expression, $full, $why) = _node($child, $version);
                push @children, $expression if defined $expression;
                push @reasons,  @$why;
                $all_exact = false unless $full;
            }
            if ($key eq '-or' && !$all_exact) { $exact = false; next }
            push @parts,
                _join($key eq '-and' ? '&&' : '||',
                \@children, $key eq '-and' ? '1' : '0');
            $exact = false unless $all_exact;
            next;
        }
        if ($key eq '-not') {
            my ($expression, $full, $why) = _node($rhs, $version);
            push @reasons, @$why;
            if ($full && defined $expression) {
                push @parts, "#{==:$expression,0}";
            }
            else { $exact = false }
            next;
        }
        my $field = LibTmux::Schema->field('pane', $key);
        if (   $field->{type} eq 'relation'
            || $field->{type} eq 'bytes'
            || $field->{nullable}
            || !LibTmux::Schema->_version_at_least($version, $field->{minimum}))
        {
            push @reasons,
"$key requires local relation, byte, null, or unavailable-field semantics";
            $exact = false;
            next;
        }
        my $ops = ref($rhs) eq 'HASH' ? $rhs : {-eq => $rhs};
        for my $op (sort keys %$ops) {
            my $value    = $ops->{$op};
            my $left     = '#{' . $field->{source} . '}';
            my @operands = ref($value) eq 'ARRAY' ? @$value : ($value);
            if (grep { defined($_) && !ref($_) && /\0/ } @operands) {
                push @reasons,
                    "$key.$op contains NUL and requires local evaluation";
                $exact = false;
                next;
            }
            if ($op eq '-in' || $op eq '-not_in') {
                my @items = map {
                    my $right =
                        $field->{type} eq 'boolean'
                        ? ($_ ? '1' : '0')
                        : _literal("$_");
                    "#{==:$left,$right}";
                } @$value;
                my $expression = _join('||', \@items, '0');
                push @parts, $op eq '-in' ? $expression : "#{==:$expression,0}";
            }
            elsif ($op eq '-eq' || $op eq '-ne') {
                my $right =
                    $field->{type} eq 'boolean'
                    ? ($value ? '1' : '0')
                    : _literal("$value");
                my $operator = $op eq '-eq' ? '==' : '!=';
                push @parts, "#{$operator:$left,$right}";
            }
            elsif ($field->{type} eq 'integer'
                && $op =~ /\A-(?:lt|lte|gt|gte)\z/)
            {
                my %operators = (
                    '-lt'  => '<',
                    '-lte' => '<=',
                    '-gt'  => '>',
                    '-gte' => '>='
                );
                push @parts, '#{e|' . $operators{$op} . ":$left,$value}";
            }
            else {
                push @reasons, "$key.$op has a local residual";
                $exact = false;
            }
        }
    }
    return (@parts ? _join('&&', \@parts, '1') : ($exact ? '1' : undef),
        $exact, \@reasons);
}

sub lowering ($self, $version = '3.3a') {
    return {filter => $self->{native_filter}, exact => true, reasons => []}
        if defined $self->{native_filter};
    my ($filter, $exact, $reasons) =
        _node($self->filter->normalized_where, $version);
    return {filter => $filter, exact => $exact, reasons => $reasons};
}

sub summary ($self) {
    my $lowered = $self->lowering;
    return 'local evaluation; pushdown disabled' if $self->policy eq 'never';
    return
'captured local evaluation with verified native scalar filter; runtime candidate agreement required'
        if $lowered->{exact};
    return 'local residual: ' . join('; ', $lowered->{reasons}->@*);
}

sub _requirements ($kind, $where, $out) {
    for my $key (sort keys %$where) {
        my $value = $where->{$key};
        if ($key eq '-and' || $key eq '-or') {
            _requirements($kind, $_, $out) for @$value;
            next;
        }
        if ($key eq '-not') { _requirements($kind, $value, $out); next }
        my $field = LibTmux::Schema->field($kind, $key);
        my $id    = "$kind.$key";
        if ($field->{type} eq 'relation') {
            $out->{relations}{$id} = {
                entity       => $kind,
                field        => $key,
                target       => $field->{entity},
                cardinality  => $field->{many} ? 'many' : 'one',
                completeness => 'complete captured domain required'
            };
            for my $op (sort keys %$value) {
                _requirements($field->{entity}, $value->{$op}, $out)
                    if defined $value->{$op};
            }
        }
        else {
            $out->{fields}{$id} = {
                entity  => $kind,
                field   => $key,
                source  => $field->{source},
                minimum => $field->{minimum},
                type    => $field->{type}
            };
        }
    }
}

sub to_data ($self) {
    my $lowered      = $self->lowering;
    my $requirements = {fields => {}, relations => {}};
    _requirements('pane', $self->filter->normalized_where, $requirements);
    return {
        required_fields => [
            map { $requirements->{fields}{$_} }
            sort keys $requirements->{fields}->%*
        ],
        required_relations => [
            map { $requirements->{relations}{$_} }
                sort keys $requirements->{relations}->%*
        ],
        capability_discovery =>
'execution reads connected daemon identity; explanation itself performs no I/O',
        acquisition =>
'strict complete snapshot before local evaluation and native candidate verification',
        residual_where => $lowered->{exact}
        ? {}
        : $self->filter->normalized_where,
        entity          => 'pane',
        policy          => $self->policy,
        where           => $self->filter->to_data,
        source_commands => [
            ['list-sessions'],    ['list-windows', '-a'],
            ['list-panes', '-a'], ['list-clients']
        ],
        native_filter    => $lowered->{filter},
        exact            => $lowered->{exact},
        residual_reasons => $lowered->{reasons},
        consistency      =>
'capture interval; auto falls back on candidate disagreement, require rejects it'
    };
}

=head1 NAME

LibTmux::QueryPlan - Explainable explicit pane acquisition

=head1 METHODS

=head2 summary

Describe native lowering and local residual reasons. Explanation performs no
I/O and uses the support floor until connected capabilities are available.

=head2 to_data

Return an inspectable plan with source commands, filter, policy, and reasons.
The L<LibTmux::Schema> catalog identifies required fields and relations.

=head2 filter

Return the compiled L<LibTmux::Filter>. Its matching remains local.

=head2 policy

Return auto, never, or require. L<LibTmux::Server/query_panes> executes the
plan with complete captured local evaluation. Native candidates cannot hide
errors or discard matches from that captured result. Only verified complete
translation qualifies for require; runtime disagreement throws
L<LibTmux::X/QueryMismatch> without assigning a cause. The optional
L<LibTmux::Server/query_panes> observer exposes completed comparisons.

=cut
