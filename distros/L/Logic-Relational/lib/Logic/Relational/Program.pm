package Logic::Relational::Program;

use v5.38;                          ## no critic (ValuesAndExpressions::ProhibitVersionStrings)
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';    ## no critic (TestingAndDebugging::ProhibitNoWarnings)
use builtin 'blessed';
no warnings 'experimental::builtin';
use Carp         qw(croak carp);
use Scalar::Util qw(openhandle);
use Time::HiRes  qw(time);

=head1 NAME

Logic::Relational::Program - Represents the mutable relational logic program.

=head1 SYNOPSIS

    use Logic::Relational::Program;
    my $program = Logic::Relational::Program->new;
    $program->fact(thief => 'badguy');

=head1 DESCRIPTION

C<Logic::Relational::Program> manages the knowledge base containing facts and rules.
It supports transaction isolation (atomicity on commits/rollbacks) and snapshot
semantics for active queries.

=head1 METHODS

=head2 new

Constructor.

=head2 fact

Asserts a fact. Can take a C<Logic::Relational::Clause> object, or a predicate
name and arguments. Returns the generated clause ID.

=head2 rule

Asserts a rule. Takes C<head> (Term or Call goal), C<body> (Goal), and C<metadata> (optional).
Returns the generated clause ID.

=head2 retract

Retracts the first clause whose head unifies with the pattern. Returns 1 if a clause
was retracted, 0 otherwise.

=head2 retract_all

Retracts all clauses whose heads unify with the pattern. Returns the number of retracted clauses.

=head2 retract_clause

Retracts a clause with the exact ID. Throws an exception if the ID does not exist.

=head2 clauses_for

Introspection method. Returns a list of C<Logic::Relational::Clause> objects
for the given name and arity.

=head2 query

Creates and returns a C<Logic::Relational::Query> snapshot query object.

=head2 transaction

Executes a coderef atomically. If the block throws an exception, all changes are
rolled back.

=head2 table

Marks a predicate (by name and optional arity, or C<'name/arity'>) for subgoal
tabling and answer memoization during queries.

=head2 untable

Removes tabling for the specified predicate.

=head2 is_tabled

Returns true if the predicate with the given name and arity is tabled.

=head2 name

Getter/setter for the user-defined program name (defaults to 'LogicProgram').

=head2 description

Getter/setter for the program description.

=head2 program_version

Getter/setter for the user-facing semantic version string (defaults to '1.0.0').

=head2 set_predicate_metadata

Registers metadata (docstrings, argument names/types, ground_required) for a predicate.
Accepts C<($name, $arity, \%meta)> or C<($name_with_arity, \%meta)> or C<($name, \%meta)>.

=head2 predicate_metadata

Retrieves metadata for a given predicate name and optional arity.

=head2 describe

Returns a JSON-serializable schema description of the program, including name,
version, description, and an array of predicate specifications.
Accepts optional C<include_stdlib => 0/1> (defaults to 1).

=head2 query_data

Executes a JSON-Datalog query specification (represented as a Perl HASH) against
the program. Returns a structured QueryResponse hashref.

=head2 query_json

Executes a JSON-Datalog query string against the program. Returns an encoded JSON string.

=cut

sub new ($class, %args) {
    my $self = {
        name               => $args{name}        // 'LogicProgram',
        description        => $args{description} // '',
        program_version    => $args{version}     // '1.0.0',
        predicates         => {},
        active_predicates  => {},
        predicate_metadata => {},
        generators         => {},
        tabled             => {},
        on_expire_handlers => {},
        version            => 1,
        next_clause_id     => 1,
        in_transaction     => 0,
        observers          => [],
        max_steps          => $args{max_steps},
    };
    if ($args{metadata} && ref($args{metadata}) eq 'HASH') {
        for my $k (keys %{ $args{metadata} }) {
            $self->set_predicate_metadata($k, $args{metadata}{$k});
        }
    }
    $self->{active_predicates} = $self->{predicates};
    return bless $self, $class;
}

sub name ($self, $val = undef) {
    if (defined $val) {
        $self->{name} = $val;
    }
    return $self->{name};
}

sub description ($self, $val = undef) {
    if (defined $val) {
        $self->{description} = $val;
    }
    return $self->{description};
}

sub program_version ($self, $val = undef) {
    if (defined $val) {
        $self->{program_version} = $val;
    }
    return $self->{program_version};
}

sub set_predicate_metadata ($self, $name, $arity_or_meta = undef, $meta = undef)    ## no critic (Subroutines::ProhibitManyArgs)
{
    my $arity;

    if ($name =~ m{\A([a-zA-Z_]\w*)/(\d+|\*)\z}x) {
        $name  = $1;
        $arity = $2;
        $meta  = $arity_or_meta;
    } elsif (defined $meta) {
        $arity = $arity_or_meta;
    } elsif (ref($arity_or_meta) eq 'HASH') {
        $meta  = $arity_or_meta;
        $arity = $meta->{arity};
        if (!defined $arity && $meta->{args} && ref($meta->{args}) eq 'ARRAY') {
            $arity = scalar(@{ $meta->{args} });
        }
        $arity //= '*';
    } else {
        croak "Invalid arguments to set_predicate_metadata";
    }

    $meta = { %{ $meta // {} } };

    # Normalize args
    if (exists $meta->{args} && ref($meta->{args}) eq 'ARRAY') {
        my @norm_args;
        for my $arg (@{ $meta->{args} }) {
            if (ref($arg) eq 'HASH') {
                push @norm_args, {%$arg};
            } else {
                push @norm_args, { name => "$arg" };
            }
        }
        $meta->{args} = \@norm_args;
        $arity = scalar(@norm_args) if $arity eq '*';
    }

    # Normalize ground_required
    if (exists $meta->{ground_required} && ref($meta->{ground_required}) eq 'ARRAY') {
        $meta->{ground_required} = [@{ $meta->{ground_required} }];
    } else {
        $meta->{ground_required} = [];
    }

    my $key = "$name/$arity";
    $self->{predicate_metadata}{$key} = $meta;
    return $key;
}

sub predicate_metadata ($self, $name, $arity = undef) {
    if ($name =~ m{\A([a-zA-Z_]\w*)/(\d+|\*)\z}x) {
        ($name, $arity) = ($1, $2);
    }

    if (defined $arity && $arity ne '*') {
        my $key = "$name/$arity";
        return $self->{predicate_metadata}{$key}
            if exists $self->{predicate_metadata}{$key};
    }

    if (exists $self->{predicate_metadata}{"$name/*"}) {
        return $self->{predicate_metadata}{"$name/*"};
    }
    if (exists $self->{predicate_metadata}{$name}) {
        return $self->{predicate_metadata}{$name};
    }

    return undef;
}

sub _collect_known_predicate_keys ($self) {
    my %known_keys;

    # Collect from active_predicates / predicates
    for my $k (keys %{ $self->{active_predicates} // {} }) {
        $known_keys{$k} = 1 if $k =~ m{\A[a-zA-Z_]\w*/\d+\z}x;
    }
    for my $k (keys %{ $self->{predicates} // {} }) {
        $known_keys{$k} = 1 if $k =~ m{\A[a-zA-Z_]\w*/\d+\z}x;
    }

    # Collect from generators
    for my $k (keys %{ $self->{generators} // {} }) {
        $known_keys{$k} = 1 if $k =~ m{\A[a-zA-Z_]\w*/\d+\z}x;
    }

    # Collect from predicate_metadata
    for my $k (keys %{ $self->{predicate_metadata} // {} }) {
        if ($k =~ m{\A([a-zA-Z_]\w*)/(\d+)\z}x) {
            $known_keys{$k} = 1;
        } elsif ($k =~ m{\A([a-zA-Z_]\w*)/\*?\z}x) {
            my $pname   = $1;
            my @matches = grep {m{\A\Q$pname\E/\d+\z}x} keys %known_keys;
            if (!@matches) {
                my $m  = $self->{predicate_metadata}{$k};
                my $ar = ($m->{args} && ref($m->{args}) eq 'ARRAY') ? scalar(@{ $m->{args} }) : 0;
                $known_keys{"$pname/$ar"} = 1;
            }
        }
    }

    return %known_keys;
}

sub _detect_predicate_kind_and_mutability ($self, $key, $meta) {
    my $kind    = 'rule';
    my $mutable = 0;

    if (exists $self->{generators}{$key}) {
        $kind    = 'generator';
        $mutable = 0;
    } elsif (exists $self->{active_predicates}{$key} && @{ $self->{active_predicates}{$key} }) {
        my $clauses   = $self->{active_predicates}{$key};
        my $all_facts = 1;
        for my $clause (@$clauses) {
            my $body = $clause->body;
            if (defined $body && blessed($body) && !$body->isa('Logic::Relational::Goal::True')) {
                $all_facts = 0;
                last;
            }
        }
        $kind    = $all_facts ? 'fact' : 'rule';
        $mutable = $all_facts ? 1      : 0;
    } elsif (exists $meta->{kind}) {
        $kind    = $meta->{kind};
        $mutable = $meta->{mutable} // ($kind eq 'fact' ? 1 : 0);
    }

    if (exists $meta->{mutable}) {
        $mutable = $meta->{mutable} ? 1 : 0;
    }

    return ($kind, $mutable);
}

sub _build_predicate_descriptor ($self, $key, $include_stdlib) {
    my ($pname, $arity) = split('/', $key, 2);
    $arity = int($arity);

    my $meta       = $self->predicate_metadata($pname, $arity) // {};
    my $is_builtin = $meta->{builtin} ? 1 : 0;

    return undef if !$include_stdlib && $is_builtin;

    my ($kind, $mutable) = $self->_detect_predicate_kind_and_mutability($key, $meta);

    my $desc = $meta->{description} // $meta->{doc} // '';

    my @args_meta;
    if (exists $meta->{args} && ref($meta->{args}) eq 'ARRAY' && @{ $meta->{args} }) {
        @args_meta = map {+{%$_}} @{ $meta->{args} };
    } else {
        @args_meta = map {+{ name => "arg$_" }} 0 .. ($arity - 1);
    }

    my @ground_required = @{ $meta->{ground_required} // [] };
    my $tabled          = $self->is_tabled($pname, $arity) ? 1 : 0;

    return {
        name            => $pname,
        arity           => $arity,
        kind            => $kind,
        mutable         => $mutable    ? JSON::PP::true() : JSON::PP::false(),
        builtin         => $is_builtin ? JSON::PP::true() : JSON::PP::false(),
        description     => $desc,
        args            => \@args_meta,
        ground_required => \@ground_required,
        tabled          => $tabled ? JSON::PP::true() : JSON::PP::false(),
    };
}

sub describe ($self, %opts) {
    require JSON::PP;

    my $include_stdlib = $opts{include_stdlib} // 1;
    my %known_keys     = $self->_collect_known_predicate_keys;

    my @pred_descriptors;
    for my $key (keys %known_keys) {
        my $desc = $self->_build_predicate_descriptor($key, $include_stdlib);
        push @pred_descriptors, $desc if defined $desc;
    }

    @pred_descriptors =
        sort {($a->{name} cmp $b->{name}) || ($a->{arity} <=> $b->{arity})} @pred_descriptors;

    return {
        name        => $self->name,
        version     => $self->program_version,
        description => $self->description,
        predicates  => \@pred_descriptors,
    };
}

sub query_data ($self, $spec, %opts) {
    require Logic::Relational::Query::Runner;
    return Logic::Relational::Query::Runner->run($self, $spec, %opts);
}

sub query_json ($self, $json_str, %opts) {
    require JSON::PP;
    require Logic::Relational::Query::Runner;

    my $spec;
    try {
        $spec = JSON::PP->new->utf8->decode($json_str);
    } catch ($e) {
        my $err_resp = {
            ok         => 0,
            error      => "Invalid JSON input: $e",
            error_code => 'INVALID_JSON',
            audit      => {
                steps      => 0,
                elapsed_ms => 0,
            },
        };
        return JSON::PP->new->utf8->encode($err_resp);
    }

    my $res = Logic::Relational::Query::Runner->run($self, $spec, %opts);
    my $json_coder =
        $opts{pretty}
        ? JSON::PP->new->utf8->pretty->canonical
        : JSON::PP->new->utf8->canonical;

    return $json_coder->encode($res);
}

sub max_steps ($self, @args) {
    if (@args) {
        $self->{max_steps} = $args[0];
    }
    return $self->{max_steps};
}

sub fact ($self, $name, @args) {
    my $clause;
    if (ref($name) eq 'Logic::Relational::Clause') {
        $clause = $name;
    } else {
        require Logic::Relational::Term;
        require Logic::Relational::Clause;
        my $head = Logic::Relational::Term->new(functor => $name, args => \@args);
        $clause = Logic::Relational::Clause->new(head => $head);
    }
    return $self->_add_clause($clause);
}

sub rule ($self, %args) {
    my $head     = $args{head}     // croak "rule head is required";
    my $body     = $args{body}     // croak "rule body is required";
    my $metadata = $args{metadata} // {};

    my $head_term;
    if (ref($head) eq 'Logic::Relational::Goal::Call') {
        require Logic::Relational::Term;
        $head_term = Logic::Relational::Term->new(
            functor => $head->name,
            args    => $head->args
        );
    } elsif (ref($head) eq 'Logic::Relational::Term') {
        $head_term = $head;
    } else {
        croak "Invalid rule head: must be a Term or Call goal";
    }

    # Detect direct left-recursion (excluding well-founded structural recursion)
    my $first_subgoal = $self->_first_subgoal($body);
    if (   defined $first_subgoal
        && blessed($first_subgoal)
        && $first_subgoal->isa('Logic::Relational::Goal::Call')
        && $first_subgoal->name eq $head_term->functor
        && $first_subgoal->arity == $head_term->arity
        && !$self->_is_structurally_decreasing($head_term->args, $first_subgoal->args)) {
        my $pred_spec = $head_term->functor . '/' . $head_term->arity;
        if (!$self->is_tabled($head_term->functor, $head_term->arity)) {
            carp
"Warning: Direct left-recursion detected in rule for '$pred_spec'. Automatically enabling tabling for '$pred_spec'.";
            $self->table($head_term->functor, $head_term->arity);
        }
    }

    require Logic::Relational::Clause;
    my $clause = Logic::Relational::Clause->new(
        head     => $head_term,
        body     => $body,
        metadata => $metadata,
    );
    return $self->_add_clause($clause);
}

sub _first_subgoal ($self, $goal) {
    return unless defined $goal;
    while (1) {
        if (ref($goal) eq 'ARRAY') {
            return unless @$goal;
            $goal = $goal->[0];
        } elsif (blessed($goal) && $goal->isa('Logic::Relational::Goal::All')) {
            my $goals = $goal->goals;
            return unless $goals && @$goals;
            $goal = $goals->[0];
        } else {
            last;
        }
    }
    return $goal;
}

sub _is_compound ($self, $term) {
    return 0 unless ref($term);
    return 1 if ref($term) eq 'ARRAY' || ref($term) eq 'HASH';
    return 1
        if blessed($term)
        && ($term->isa('Logic::Relational::ArrayRest')
        || ($term->isa('Logic::Relational::Term') && $term->arity > 0));
    return 0;
}

sub _term_contains_var ($self, $term, $target_name) {
    return 0 unless defined $term;
    if (blessed($term)) {
        if ($term->isa('Logic::Relational::Variable')) {
            return $term->name eq $target_name ? 1 : 0;
        }
        if ($term->isa('Logic::Relational::ArrayRest')) {
            return $self->_term_contains_var($term->term, $target_name);
        }
        if ($term->isa('Logic::Relational::Term')) {
            for my $arg (@{ $term->args }) {
                return 1 if $self->_term_contains_var($arg, $target_name);
            }
        }
    }
    if (ref($term) eq 'ARRAY') {
        for my $item (@$term) {
            return 1 if $self->_term_contains_var($item, $target_name);
        }
    }
    if (ref($term) eq 'HASH') {
        for my $item (values %$term) {
            return 1 if $self->_term_contains_var($item, $target_name);
        }
    }
    return 0;
}

sub _is_structurally_decreasing ($self, $head_args, $call_args) {
    return 0 unless $head_args && $call_args;
    my $count = scalar(@$head_args);
    for (my $i = 0; $i < $count; $i++) {
        my $h = $head_args->[$i];
        my $c = $call_args->[$i];
        if ($self->_is_compound($h)) {
            if (blessed($c) && $c->isa('Logic::Relational::Variable')) {
                return 1 if $self->_term_contains_var($h, $c->name);
            }
        }
    }
    return 0;
}

sub _add_clause ($self, $clause) {
    $clause->{id} //= "clause-" . $self->{next_clause_id}++;

    my $key = $clause->head->functor . '/' . $clause->head->arity;

    # Copy the array for the predicate to avoid modifying existing snapshots
    my $old_list = $self->{active_predicates}{$key} // [];
    my $new_list = [@$old_list, $clause];

    $self->{active_predicates}{$key} = $new_list;

    if (!$self->{in_transaction}) {
        $self->{predicates} = $self->{active_predicates};
        $self->{version}++;
    }
    $self->_dispatch_change('assert', $clause);
    return $clause->id;
}

sub retract_clause ($self, $id) {
    my $found = 0;
    my $retracted_clause;
    for my $key (keys %{ $self->{active_predicates} }) {
        my $list = $self->{active_predicates}{$key} // [];
        my @new_list;
        for my $clause (@$list) {
            if ($clause->id eq $id) {
                $retracted_clause = $clause;
                $found            = 1;
            } else {
                push @new_list, $clause;
            }
        }
        if ($found) {
            $self->{active_predicates}{$key} = \@new_list;
            last;
        }
    }

    if ($found) {
        if (!$self->{in_transaction}) {
            $self->{predicates} = $self->{active_predicates};
            $self->{version}++;
        }
        $self->_dispatch_change('retract', $retracted_clause);
        return 1;
    }
    croak "Clause ID $id does not exist in program version " . $self->{version} . "\n";
}

sub retract ($self, $name, @args) {
    require Logic::Relational::Term;
    require Logic::Relational::Unifier;
    require Logic::Relational::Substitution;

    my $pattern = Logic::Relational::Term->new(functor => $name, args => \@args);
    my $key     = $name . '/' . scalar(@args);

    my $list = $self->{active_predicates}{$key} // [];
    my $found_idx;
    for my $i (0 .. $#$list) {
        my $clause  = $list->[$i];
        my $unifies = 0;
        try {
            if (
                Logic::Relational::Unifier::unify(
                    $pattern, $clause->head, Logic::Relational::Substitution->new
                )
            ) {
                $unifies = 1;
            }
        } catch ($e) {
        }

        if ($unifies) {
            $found_idx = $i;
            last;
        }
    }

    if (defined $found_idx) {
        my $retracted_clause = $list->[$found_idx];
        my @new_list         = @$list;
        splice(@new_list, $found_idx, 1);
        $self->{active_predicates}{$key} = \@new_list;
        if (!$self->{in_transaction}) {
            $self->{predicates} = $self->{active_predicates};
            $self->{version}++;
        }
        $self->_dispatch_change('retract', $retracted_clause);
        return 1;
    }
    return 0;
}

sub retract_all ($self, $name, @args) {
    require Logic::Relational::Term;
    require Logic::Relational::Unifier;
    require Logic::Relational::Substitution;

    my $pattern = Logic::Relational::Term->new(functor => $name, args => \@args);
    my $key     = $name . '/' . scalar(@args);

    my $list = $self->{active_predicates}{$key} // [];
    my @new_list;
    my @retracted_clauses;
    for my $clause (@$list) {
        my $unifies = 0;
        try {
            if (
                Logic::Relational::Unifier::unify(
                    $pattern, $clause->head, Logic::Relational::Substitution->new
                )
            ) {
                $unifies = 1;
            }
        } catch ($e) {
        }

        if ($unifies) {
            push @retracted_clauses, $clause;
        } else {
            push @new_list, $clause;
        }
    }

    if (@retracted_clauses) {
        $self->{active_predicates}{$key} = \@new_list;
        if (!$self->{in_transaction}) {
            $self->{predicates} = $self->{active_predicates};
            $self->{version}++;
        }
        for my $clause (@retracted_clauses) {
            $self->_dispatch_change('retract', $clause);
        }
    }
    return scalar(@retracted_clauses);
}

sub clauses_for ($self, $name, $arity) {
    my $key  = "$name/$arity";
    my $list = $self->{predicates}{$key} // [];
    return @$list;
}

sub on_change ($self, $callback) {
    push @{ $self->{observers} }, $callback;
    return;
}

sub _dispatch_change ($self, $operation, $clause) {
    return unless $self->{observers} && @{ $self->{observers} };
    require Logic::Relational::ChangeEvent;
    my $event = Logic::Relational::ChangeEvent->new(
        operation => $operation,
        clause    => $clause,
    );
    for my $cb (@{ $self->{observers} }) {
        $cb->($event);
    }
    return;
}

sub generator ($self, $name, $arity, $code) {
    my $key = "$name/$arity";
    $self->{generators}{$key} = $code;
    $self->{version}++;
    return;
}

sub query ($self, $goal, %options) {
    $self->cleanup_expired_facts;
    require Logic::Relational::Query;
    return Logic::Relational::Query->new(
        program    => $self,
        goals      => [$goal],
        predicates => { %{ $self->{predicates} } },    # snapshot shallow copy
        generators => { %{ $self->{generators} } },    # snapshot generators
        %options,
    );
}

sub on_expire ($self, $name, $code) {
    croak "code callback is required" unless ref($code) eq 'CODE';
    push @{ $self->{on_expire_handlers}{$name} }, $code;
    return;
}

sub assert_fact ($self, %args) {
    my $term       = $args{term} // croak "term is required";
    my $expires_at = $args{expires_at};
    if (my $expires_in = $args{expires_in}) {
        $expires_at = time + $expires_in;
    }

    my $expire_to = $args{expire_to};
    if (ref($expire_to) eq 'ARRAY') {
        my ($e_name, @e_args) = @$expire_to;
        require Logic::Relational::Term;
        $expire_to = Logic::Relational::Term->new(
            functor => $e_name,
            args    => \@e_args
        );
    } elsif (ref($expire_to) eq 'Logic::Relational::Goal::Call') {
        require Logic::Relational::Term;
        $expire_to = Logic::Relational::Term->new(
            functor => $expire_to->name,
            args    => $expire_to->args
        );
    }

    my %meta;
    $meta{expires_at} = $expires_at      if defined $expires_at;
    $meta{expire_to}  = $expire_to       if defined $expire_to;
    $meta{on_expire}  = $args{on_expire} if ref($args{on_expire}) eq 'CODE';

    my $head;
    if (ref($term) eq 'Logic::Relational::Goal::Call') {    ## no critic (ProhibitCascadingIfElse)
        require Logic::Relational::Term;
        $head = Logic::Relational::Term->new(
            functor => $term->name,
            args    => $term->args
        );
    } elsif (ref($term) eq 'Logic::Relational::Term') {
        $head = $term;
    } elsif (ref($term) eq 'ARRAY') {
        my ($name, @args_list) = @$term;
        require Logic::Relational::Term;
        $head = Logic::Relational::Term->new(
            functor => $name,
            args    => \@args_list
        );
    } else {
        croak "term must be a Logic::Relational::Term, Call goal, or array reference";
    }

    require Logic::Relational::Clause;
    my $clause = Logic::Relational::Clause->new(
        head     => $head,
        metadata => \%meta,
    );

    return $self->_add_clause($clause);
}

sub with_facts ($self, $facts, $code) {
    croak "facts must be an array reference" unless ref($facts) eq 'ARRAY';
    croak "code must be a code reference"    unless ref($code) eq 'CODE';

    my @clause_ids;
    try {
        for my $fact (@$facts) {
            my $clause_id;
            if (ref($fact) eq 'Logic::Relational::Clause') {    ## no critic (ProhibitCascadingIfElse)
                $clause_id = $self->_add_clause($fact);
            } elsif (ref($fact) eq 'Logic::Relational::Goal::Call') {
                $clause_id = $self->fact($fact->name, @{ $fact->args });
            } elsif (ref($fact) eq 'Logic::Relational::Term') {
                $clause_id = $self->fact($fact->functor, @{ $fact->args });
            } elsif (ref($fact) eq 'ARRAY') {
                my ($name, @args) = @$fact;
                $clause_id = $self->fact($name, @args);
            } else {
                croak "Invalid fact definition in with_facts: " . ref($fact);
            }
            push @clause_ids, $clause_id if defined $clause_id;
        }

        use feature 'defer';
        no warnings 'experimental::defer';    ## no critic (TestingAndDebugging::ProhibitNoWarnings)
        defer {
            for my $id (@clause_ids) {
                try {$self->retract_clause($id);} catch ($e) {
                }
            }
        }

        return $code->();
    } catch ($e) {
        die $e;                               ## no critic (RequireCarping, ProhibitStringyDeath)
    }
    return;
}

sub _handle_clause_expiration ($self, $clause) {
    my $meta = $clause->metadata;

   # Assert expire_to mutation before firing callbacks so queries inside callbacks see updated state
    if (my $expire_to = $meta->{expire_to}) {
        if (ref($expire_to) eq 'Logic::Relational::Term') {
            $self->fact($expire_to->functor, @{ $expire_to->args });
        } elsif (ref($expire_to) eq 'ARRAY') {
            my ($fn, @fa) = @$expire_to;
            $self->fact($fn, @fa);
        }
    }

    # 1. Per-clause on_expire callback
    if (my $cb = $meta->{on_expire}) {
        if (ref($cb) eq 'CODE') {
            try {$cb->($clause, $self);} catch ($e) {
            }
        }
    }

    # 2. Program-level on_expire handlers
    my $pred_name = $clause->head->functor;
    my $pred_key  = $pred_name . '/' . $clause->head->arity;
    my @handlers  = (
        @{ $self->{on_expire_handlers}{$pred_name} // [] },
        @{ $self->{on_expire_handlers}{$pred_key}  // [] }
    );
    for my $handler (@handlers) {
        try {$handler->($clause, $self);} catch ($e) {
        }
    }

    return $meta->{expire_to};
}

sub cleanup_expired_facts ($self) {
    return 0 if $self->{in_cleanup};

    $self->{in_cleanup} = 1;
    use feature 'defer';
    no warnings 'experimental::defer';    ## no critic (TestingAndDebugging::ProhibitNoWarnings)
    defer {$self->{in_cleanup} = 0;}

    my $now   = time;
    my $count = 0;
    my @expired_clauses;

    for my $key (keys %{ $self->{active_predicates} }) {
        my $list = $self->{active_predicates}{$key} // [];
        my @new_list;
        for my $clause (@$list) {
            my $meta = $clause->metadata;
            if (   exists $meta->{expires_at}
                && defined $meta->{expires_at}
                && $now >= $meta->{expires_at}) {
                $count++;
                push @expired_clauses, $clause;
                $self->_dispatch_change('retract', $clause);
            } else {
                push @new_list, $clause;
            }
        }
        $self->{active_predicates}{$key} = \@new_list;
    }

    if ($count && !$self->{in_transaction}) {
        $self->{predicates} = $self->{active_predicates};
        $self->{version}++;
    }

    for my $clause (@expired_clauses) {
        $self->_handle_clause_expiration($clause);
    }

    return $count;
}

sub transaction ($self, $code) {
    if ($self->{in_transaction}) {
        return $code->();
    }

    $self->{in_transaction}    = 1;
    $self->{active_predicates} = { %{ $self->{predicates} } };

    try {
        my $res = $code->();
        $self->{predicates} = $self->{active_predicates};
        $self->{version}++;
        $self->{in_transaction} = 0;
        return $res;
    } catch ($e) {
        $self->{active_predicates} = $self->{predicates};
        $self->{in_transaction}    = 0;
        die $e;    ## no critic (RequireCarping, ProhibitStringyDeath)
    }
    return;
}

sub save_snapshot ($self, $target, %options) {
    require Logic::Relational::Serializer;

    $self->cleanup_expired_facts;

    my $now = time;
    my @encoded_facts;
    my $pred_map = $self->{predicates} // {};
    for my $key (sort keys %$pred_map) {
        my $list = $pred_map->{$key} // [];
        for my $clause (@$list) {

            # Only serialize facts (clauses with True body or no body)
            my $body_ref = ref($clause->body);
            if (!$body_ref || $body_ref eq 'Logic::Relational::Goal::True') {
                push @encoded_facts, Logic::Relational::Serializer::encode_clause($clause, $now);
            }
        }
    }

    my $snapshot_data = {
        metadata => {
            format_version     => 1,
            engine             => 'Logic::Relational',
            exported_at        => $now,
            program_version    => $self->{version},
            name               => $self->{name},
            user_version       => $self->{program_version},
            description        => $self->{description},
            known_predicates   => [sort keys %$pred_map],
            predicate_metadata => $self->{predicate_metadata},
        },
        facts => \@encoded_facts,
    };

    my $json_str = Logic::Relational::Serializer::to_json($snapshot_data, %options);

    if (ref($target) eq 'SCALAR') {
        $$target = $json_str;
    } elsif (ref($target) || openhandle($target)) {
        print {$target} $json_str;
    } else {
        open my $fh, '>:encoding(UTF-8)', $target
            or croak "Cannot write snapshot to file '$target': $!";
        print {$fh} $json_str;
        close $fh;
    }

    return $json_str;
}

sub load_snapshot ($self, $source, %options) {    ## no critic (Subroutines::ProhibitExcessComplexity)
    require Logic::Relational::Serializer;

    my $json_str;
    if (ref($source) eq 'SCALAR') {
        $json_str = $$source;
    } elsif (ref($source) || openhandle($source)) {
        local $/ = undef;
        $json_str = <$source>;
    } else {
        open my $fh, '<:encoding(UTF-8)', $source
            or croak "Cannot read snapshot from file '$source': $!";
        local $/ = undef;
        $json_str = <$fh>;
        close $fh;
    }

    my $snapshot_data = Logic::Relational::Serializer::from_json($json_str);
    croak "Invalid snapshot file format"
        unless ref($snapshot_data) eq 'HASH'
        && exists $snapshot_data->{metadata}
        && exists $snapshot_data->{facts};

    my $mode           = $options{mode}           // 'replace';
    my $filter_expired = $options{filter_expired} // 1;
    my $ttl_mode       = $options{ttl_mode} // ($options{pause_ttl} ? 'relative' : 'absolute');
    my $now            = time;

    if ($mode eq 'replace') {
        my %new_active;
        for my $key (keys %{ $self->{active_predicates} }) {
            my $list = $self->{active_predicates}{$key} // [];
            my @rules_only;
            for my $clause (@$list) {
                my $body_ref = ref($clause->body);
                if ($body_ref && $body_ref ne 'Logic::Relational::Goal::True') {
                    push @rules_only, $clause;
                }
            }
            $new_active{$key} = \@rules_only;
        }
        $self->{active_predicates} = \%new_active;
        $self->{predicates}        = \%new_active;
    }

    if (my $kp = $snapshot_data->{metadata}{known_predicates}) {
        if (ref($kp) eq 'ARRAY') {
            for my $key (@$kp) {
                $self->{active_predicates}{$key} //= [];
            }
        }
    }

    if (my $pm = $snapshot_data->{metadata}{predicate_metadata}) {
        if (ref($pm) eq 'HASH') {
            $self->{predicate_metadata} = {%$pm};
        }
    }
    if (my $name = $snapshot_data->{metadata}{name}) {
        $self->{name} = $name;
    }
    if (my $uv = $snapshot_data->{metadata}{user_version}) {
        $self->{program_version} = $uv;
    }
    if (my $desc = $snapshot_data->{metadata}{description}) {
        $self->{description} = $desc;
    }

    my $loaded_count = 0;
    for my $fact_data (@{ $snapshot_data->{facts} // [] }) {
        my $clause = Logic::Relational::Serializer::decode_clause($fact_data);
        my $meta   = $clause->metadata;

        if ($ttl_mode eq 'relative') {
            if (exists $meta->{remaining_ttl}
                && defined $meta->{remaining_ttl}) {
                my $rem = $meta->{remaining_ttl};
                if ($rem <= 0) {
                    next;    # Expired when saved
                }
                $meta->{expires_at} = $now + $rem;
            } elsif ($filter_expired
                && exists $meta->{expires_at}
                && defined $meta->{expires_at}
                && $now >= $meta->{expires_at}) {
                next;
            }
        } elsif ($filter_expired
            && exists $meta->{expires_at}
            && defined $meta->{expires_at}
            && $now >= $meta->{expires_at}) {
            next;    # Skip expired fact
        }

        $self->_add_clause($clause);
        $loaded_count++;
    }

    $self->{version}++;
    return $loaded_count;
}

sub table ($self, $name, $arity = undef) {
    if ($name =~ m{\A([a-zA-Z_]\w*)/(\d+|\*)\z}x) {
        ($name, $arity) = ($1, $2);
    }
    my $key = defined $arity ? "$name/$arity" : "$name/*";
    $self->{tabled}{$key} = 1;
    return $key;
}

sub untable ($self, $name, $arity = undef) {
    if ($name =~ m{\A([a-zA-Z_]\w*)/(\d+|\*)\z}x) {
        ($name, $arity) = ($1, $2);
    }
    if (defined $arity) {
        delete $self->{tabled}{"$name/$arity"};
    } else {
        delete $self->{tabled}{"$name/*"};
        for my $k (keys %{ $self->{tabled} }) {
            delete $self->{tabled}{$k} if $k =~ m{\A\Q$name\E/}x;
        }
    }
    return 1;
}

sub is_tabled ($self, $name, $arity = undef) {
    if ($name =~ m{\A([a-zA-Z_]\w*)/(\d+|\*)\z}x) {
        ($name, $arity) = ($1, $2);
    }
    if (defined $arity) {
        return 1
            if $self->{tabled}{"$name/$arity"} || $self->{tabled}{"$name/*"};
    } else {
        return 1 if $self->{tabled}{"$name/*"};
        for my $k (keys %{ $self->{tabled} }) {
            return 1 if $k =~ m{\A\Q$name\E/}x;
        }
    }
    return 0;
}

1;

