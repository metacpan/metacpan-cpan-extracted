package Logic::Relational::Program;

use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';
use Carp qw(croak);

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

=cut

sub new ($class) {
    my $self = {
        predicates         => {},
        active_predicates  => {},
        generators         => {},
        tabled             => {},
        on_expire_handlers => {},
        version            => 1,
        next_clause_id     => 1,
        in_transaction     => 0,
        observers          => [],
    };
    $self->{active_predicates} = $self->{predicates};
    return bless $self, $class;
}

sub fact ( $self, $name, @args ) {
    my $clause;
    if ( ref($name) eq 'Logic::Relational::Clause' ) {
        $clause = $name;
    }
    else {
        require Logic::Relational::Term;
        require Logic::Relational::Clause;
        my $head =
          Logic::Relational::Term->new( functor => $name, args => \@args );
        $clause = Logic::Relational::Clause->new( head => $head );
    }
    return $self->_add_clause($clause);
}

sub rule ( $self, %args ) {
    my $head     = $args{head}     // croak "rule head is required";
    my $body     = $args{body}     // croak "rule body is required";
    my $metadata = $args{metadata} // {};

    my $head_term;
    if ( ref($head) eq 'Logic::Relational::Goal::Call' ) {
        require Logic::Relational::Term;
        $head_term = Logic::Relational::Term->new(
            functor => $head->name,
            args    => $head->args
        );
    }
    elsif ( ref($head) eq 'Logic::Relational::Term' ) {
        $head_term = $head;
    }
    else {
        croak "Invalid rule head: must be a Term or Call goal";
    }

    require Logic::Relational::Clause;
    my $clause = Logic::Relational::Clause->new(
        head     => $head_term,
        body     => $body,
        metadata => $metadata,
    );
    return $self->_add_clause($clause);
}

sub _add_clause ( $self, $clause ) {
    $clause->{id} //= "clause-" . $self->{next_clause_id}++;

    my $key = $clause->head->functor . '/' . $clause->head->arity;

    # Copy the array for the predicate to avoid modifying existing snapshots
    my $old_list = $self->{active_predicates}{$key} // [];
    my $new_list = [ @$old_list, $clause ];

    $self->{active_predicates}{$key} = $new_list;

    if ( !$self->{in_transaction} ) {
        $self->{predicates} = $self->{active_predicates};
        $self->{version}++;
    }
    $self->_dispatch_change( 'assert', $clause );
    return $clause->id;
}

sub retract_clause ( $self, $id ) {
    my $found = 0;
    my $retracted_clause;
    for my $key ( keys %{ $self->{active_predicates} } ) {
        my $list = $self->{active_predicates}{$key} // [];
        my @new_list;
        for my $clause (@$list) {
            if ( $clause->id eq $id ) {
                $retracted_clause = $clause;
                $found            = 1;
            }
            else {
                push @new_list, $clause;
            }
        }
        if ($found) {
            $self->{active_predicates}{$key} = \@new_list;
            last;
        }
    }

    if ($found) {
        if ( !$self->{in_transaction} ) {
            $self->{predicates} = $self->{active_predicates};
            $self->{version}++;
        }
        $self->_dispatch_change( 'retract', $retracted_clause );
        return 1;
    }
    croak "Clause ID $id does not exist in program version "
      . $self->{version} . "\n";
}

sub retract ( $self, $name, @args ) {
    require Logic::Relational::Term;
    require Logic::Relational::Unifier;
    require Logic::Relational::Substitution;

    my $pattern =
      Logic::Relational::Term->new( functor => $name, args => \@args );
    my $key = $name . '/' . scalar(@args);

    my $list = $self->{active_predicates}{$key} // [];
    my $found_idx;
    for my $i ( 0 .. $#$list ) {
        my $clause  = $list->[$i];
        my $unifies = 0;
        try {
            if (
                Logic::Relational::Unifier::unify(
                    $pattern, $clause->head,
                    Logic::Relational::Substitution->new
                )
              )
            {
                $unifies = 1;
            }
        }
        catch ($e) { }

        if ($unifies) {
            $found_idx = $i;
            last;
        }
    }

    if ( defined $found_idx ) {
        my $retracted_clause = $list->[$found_idx];
        my @new_list         = @$list;
        splice( @new_list, $found_idx, 1 );
        $self->{active_predicates}{$key} = \@new_list;
        if ( !$self->{in_transaction} ) {
            $self->{predicates} = $self->{active_predicates};
            $self->{version}++;
        }
        $self->_dispatch_change( 'retract', $retracted_clause );
        return 1;
    }
    return 0;
}

sub retract_all ( $self, $name, @args ) {
    require Logic::Relational::Term;
    require Logic::Relational::Unifier;
    require Logic::Relational::Substitution;

    my $pattern =
      Logic::Relational::Term->new( functor => $name, args => \@args );
    my $key = $name . '/' . scalar(@args);

    my $list = $self->{active_predicates}{$key} // [];
    my @new_list;
    my @retracted_clauses;
    for my $clause (@$list) {
        my $unifies = 0;
        try {
            if (
                Logic::Relational::Unifier::unify(
                    $pattern, $clause->head,
                    Logic::Relational::Substitution->new
                )
              )
            {
                $unifies = 1;
            }
        }
        catch ($e) { }

        if ($unifies) {
            push @retracted_clauses, $clause;
        }
        else {
            push @new_list, $clause;
        }
    }

    if (@retracted_clauses) {
        $self->{active_predicates}{$key} = \@new_list;
        if ( !$self->{in_transaction} ) {
            $self->{predicates} = $self->{active_predicates};
            $self->{version}++;
        }
        for my $clause (@retracted_clauses) {
            $self->_dispatch_change( 'retract', $clause );
        }
    }
    return scalar(@retracted_clauses);
}

sub clauses_for ( $self, $name, $arity ) {
    my $key  = "$name/$arity";
    my $list = $self->{predicates}{$key} // [];
    return @$list;
}

sub on_change ( $self, $callback ) {
    push @{ $self->{observers} }, $callback;
    return;
}

sub _dispatch_change ( $self, $operation, $clause ) {
    return unless $self->{observers} && @{ $self->{observers} };
    require Logic::Relational::ChangeEvent;
    my $event = Logic::Relational::ChangeEvent->new(
        operation => $operation,
        clause    => $clause,
    );
    for my $cb ( @{ $self->{observers} } ) {
        $cb->($event);
    }
    return;
}

sub generator ( $self, $name, $arity, $code ) {
    my $key = "$name/$arity";
    $self->{generators}{$key} = $code;
    $self->{version}++;
    return;
}

sub query ( $self, $goal ) {
    $self->cleanup_expired_facts;
    require Logic::Relational::Query;
    return Logic::Relational::Query->new(
        program    => $self,
        goals      => [$goal],
        predicates => { %{ $self->{predicates} } },    # snapshot shallow copy
        generators => { %{ $self->{generators} } },    # snapshot generators
    );
}

sub on_expire ( $self, $name, $code ) {
    croak "code callback is required" unless ref($code) eq 'CODE';
    push @{ $self->{on_expire_handlers}{$name} }, $code;
    return;
}

sub assert_fact ( $self, %args ) {
    my $term       = $args{term} // croak "term is required";
    my $expires_at = $args{expires_at};
    if ( my $expires_in = $args{expires_in} ) {
        $expires_at = time + $expires_in;
    }

    my $expire_to = $args{expire_to};
    if ( ref($expire_to) eq 'ARRAY' ) {
        my ( $e_name, @e_args ) = @$expire_to;
        require Logic::Relational::Term;
        $expire_to = Logic::Relational::Term->new(
            functor => $e_name,
            args    => \@e_args
        );
    }
    elsif ( ref($expire_to) eq 'Logic::Relational::Goal::Call' ) {
        require Logic::Relational::Term;
        $expire_to = Logic::Relational::Term->new(
            functor => $expire_to->name,
            args    => $expire_to->args
        );
    }

    my %meta;
    $meta{expires_at} = $expires_at      if defined $expires_at;
    $meta{expire_to}  = $expire_to       if defined $expire_to;
    $meta{on_expire}  = $args{on_expire} if ref( $args{on_expire} ) eq 'CODE';

    my $head;
    if ( ref($term) eq 'Logic::Relational::Goal::Call' ) {    ## no critic (ProhibitCascadingIfElse)
        require Logic::Relational::Term;
        $head = Logic::Relational::Term->new(
            functor => $term->name,
            args    => $term->args
        );
    }
    elsif ( ref($term) eq 'Logic::Relational::Term' ) {
        $head = $term;
    }
    elsif ( ref($term) eq 'ARRAY' ) {
        my ( $name, @args_list ) = @$term;
        require Logic::Relational::Term;
        $head = Logic::Relational::Term->new(
            functor => $name,
            args    => \@args_list
        );
    }
    else {
        croak
"term must be a Logic::Relational::Term, Call goal, or array reference";
    }

    require Logic::Relational::Clause;
    my $clause = Logic::Relational::Clause->new(
        head     => $head,
        metadata => \%meta,
    );

    return $self->_add_clause($clause);
}

sub with_facts ( $self, $facts, $code ) {
    croak "facts must be an array reference" unless ref($facts) eq 'ARRAY';
    croak "code must be a code reference"    unless ref($code) eq 'CODE';

    my @clause_ids;
    try {
        for my $fact (@$facts) {
            my $clause_id;
            if ( ref($fact) eq 'Logic::Relational::Clause' ) {    ## no critic (ProhibitCascadingIfElse)
                $clause_id = $self->_add_clause($fact);
            }
            elsif ( ref($fact) eq 'Logic::Relational::Goal::Call' ) {
                $clause_id = $self->fact( $fact->name, @{ $fact->args } );
            }
            elsif ( ref($fact) eq 'Logic::Relational::Term' ) {
                $clause_id = $self->fact( $fact->functor, @{ $fact->args } );
            }
            elsif ( ref($fact) eq 'ARRAY' ) {
                my ( $name, @args ) = @$fact;
                $clause_id = $self->fact( $name, @args );
            }
            else {
                croak "Invalid fact definition in with_facts: " . ref($fact);
            }
            push @clause_ids, $clause_id if defined $clause_id;
        }

        use feature 'defer';
        no warnings 'experimental::defer';
        defer {
            for my $id (@clause_ids) {
                try { $self->retract_clause($id); } catch ($e) {
                }
            }
        }

        return $code->();
    }
    catch ($e) {
        die $e;    ## no critic (RequireCarping, ProhibitStringyDeath)
    }
    return;
}

sub _handle_clause_expiration ( $self, $clause ) {
    my $meta = $clause->metadata;

# Assert expire_to mutation before firing callbacks so queries inside callbacks see updated state
    if ( my $expire_to = $meta->{expire_to} ) {
        if ( ref($expire_to) eq 'Logic::Relational::Term' ) {
            $self->fact( $expire_to->functor, @{ $expire_to->args } );
        }
        elsif ( ref($expire_to) eq 'ARRAY' ) {
            my ( $fn, @fa ) = @$expire_to;
            $self->fact( $fn, @fa );
        }
    }

    # 1. Per-clause on_expire callback
    if ( my $cb = $meta->{on_expire} ) {
        if ( ref($cb) eq 'CODE' ) {
            try { $cb->( $clause, $self ); } catch ($e) {
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
        try { $handler->( $clause, $self ); } catch ($e) {
        }
    }

    return $meta->{expire_to};
}

sub cleanup_expired_facts ($self) {
    return 0 if $self->{in_cleanup};

    $self->{in_cleanup} = 1;
    use feature 'defer';
    no warnings 'experimental::defer';
    defer { $self->{in_cleanup} = 0; }

    my $now   = time;
    my $count = 0;
    my @expired_clauses;

    for my $key ( keys %{ $self->{active_predicates} } ) {
        my $list = $self->{active_predicates}{$key} // [];
        my @new_list;
        for my $clause (@$list) {
            my $meta = $clause->metadata;
            if (   exists $meta->{expires_at}
                && defined $meta->{expires_at}
                && $now >= $meta->{expires_at} )
            {
                $count++;
                push @expired_clauses, $clause;
                $self->_dispatch_change( 'retract', $clause );
            }
            else {
                push @new_list, $clause;
            }
        }
        $self->{active_predicates}{$key} = \@new_list;
    }

    if ( $count && !$self->{in_transaction} ) {
        $self->{predicates} = $self->{active_predicates};
        $self->{version}++;
    }

    for my $clause (@expired_clauses) {
        $self->_handle_clause_expiration($clause);
    }

    return $count;
}

sub transaction ( $self, $code ) {
    if ( $self->{in_transaction} ) {
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
    }
    catch ($e) {
        $self->{active_predicates} = $self->{predicates};
        $self->{in_transaction}    = 0;
        die $e;    ## no critic (RequireCarping, ProhibitStringyDeath)
    }
    return;
}

sub save_snapshot ( $self, $target, %options ) {
    require Logic::Relational::Serializer;

    $self->cleanup_expired_facts;

    my $now = time;
    my @encoded_facts;
    my $pred_map = $self->{predicates} // {};
    for my $key ( sort keys %$pred_map ) {
        my $list = $pred_map->{$key} // [];
        for my $clause (@$list) {

            # Only serialize facts (clauses with True body or no body)
            my $body_ref = ref( $clause->body );
            if ( !$body_ref || $body_ref eq 'Logic::Relational::Goal::True' ) {
                push @encoded_facts,
                  Logic::Relational::Serializer::encode_clause( $clause, $now );
            }
        }
    }

    my $snapshot_data = {
        metadata => {
            format_version   => 1,
            engine           => 'Logic::Relational',
            exported_at      => $now,
            program_version  => $self->{version},
            known_predicates => [ sort keys %$pred_map ],
        },
        facts => \@encoded_facts,
    };

    my $json_str =
      Logic::Relational::Serializer::to_json( $snapshot_data, %options );

    if ( ref($target) eq 'SCALAR' ) {
        $$target = $json_str;
    }
    elsif ( ref($target) || Scalar::Util::openhandle($target) ) {
        print {$target} $json_str;
    }
    else {
        open my $fh, '>:encoding(UTF-8)', $target
          or croak "Cannot write snapshot to file '$target': $!";
        print {$fh} $json_str;
        close $fh;
    }

    return $json_str;
}

sub load_snapshot ( $self, $source, %options ) {    ## no critic (Subroutines::ProhibitExcessComplexity)
    require Logic::Relational::Serializer;

    my $json_str;
    if ( ref($source) eq 'SCALAR' ) {
        $json_str = $$source;
    }
    elsif ( ref($source) || Scalar::Util::openhandle($source) ) {
        local $/ = undef;
        $json_str = <$source>;
    }
    else {
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
    my $ttl_mode       = $options{ttl_mode}
      // ( $options{pause_ttl} ? 'relative' : 'absolute' );
    my $now = time;

    if ( $mode eq 'replace' ) {
        my %new_active;
        for my $key ( keys %{ $self->{active_predicates} } ) {
            my $list = $self->{active_predicates}{$key} // [];
            my @rules_only;
            for my $clause (@$list) {
                my $body_ref = ref( $clause->body );
                if ( $body_ref && $body_ref ne 'Logic::Relational::Goal::True' )
                {
                    push @rules_only, $clause;
                }
            }
            $new_active{$key} = \@rules_only;
        }
        $self->{active_predicates} = \%new_active;
        $self->{predicates}        = \%new_active;
    }

    if ( my $kp = $snapshot_data->{metadata}{known_predicates} ) {
        if ( ref($kp) eq 'ARRAY' ) {
            for my $key (@$kp) {
                $self->{active_predicates}{$key} //= [];
            }
        }
    }

    my $loaded_count = 0;
    for my $fact_data ( @{ $snapshot_data->{facts} // [] } ) {
        my $clause = Logic::Relational::Serializer::decode_clause($fact_data);
        my $meta   = $clause->metadata;

        if ( $ttl_mode eq 'relative' ) {
            if ( exists $meta->{remaining_ttl}
                && defined $meta->{remaining_ttl} )
            {
                my $rem = $meta->{remaining_ttl};
                if ( $rem <= 0 ) {
                    next;    # Expired when saved
                }
                $meta->{expires_at} = $now + $rem;
            }
            elsif ( $filter_expired
                && exists $meta->{expires_at}
                && defined $meta->{expires_at}
                && $now >= $meta->{expires_at} )
            {
                next;
            }
        }
        elsif ( $filter_expired
            && exists $meta->{expires_at}
            && defined $meta->{expires_at}
            && $now >= $meta->{expires_at} )
        {
            next;    # Skip expired fact
        }

        $self->_add_clause($clause);
        $loaded_count++;
    }

    $self->{version}++;
    return $loaded_count;
}

sub table ( $self, $name, $arity = undef ) {
    if ( $name =~ m{\A([a-zA-Z_]\w*)/(\d+|\*)\z}x ) {
        ( $name, $arity ) = ( $1, $2 );
    }
    my $key = defined $arity ? "$name/$arity" : "$name/*";
    $self->{tabled}{$key} = 1;
    return $key;
}

sub untable ( $self, $name, $arity = undef ) {
    if ( $name =~ m{\A([a-zA-Z_]\w*)/(\d+|\*)\z}x ) {
        ( $name, $arity ) = ( $1, $2 );
    }
    if ( defined $arity ) {
        delete $self->{tabled}{"$name/$arity"};
    }
    else {
        delete $self->{tabled}{"$name/*"};
        for my $k ( keys %{ $self->{tabled} } ) {
            delete $self->{tabled}{$k} if $k =~ m{\A\Q$name\E/}x;
        }
    }
    return 1;
}

sub is_tabled ( $self, $name, $arity = undef ) {
    if ( $name =~ m{\A([a-zA-Z_]\w*)/(\d+|\*)\z}x ) {
        ( $name, $arity ) = ( $1, $2 );
    }
    if ( defined $arity ) {
        return 1
          if $self->{tabled}{"$name/$arity"} || $self->{tabled}{"$name/*"};
    }
    else {
        return 1 if $self->{tabled}{"$name/*"};
        for my $k ( keys %{ $self->{tabled} } ) {
            return 1 if $k =~ m{\A\Q$name\E/}x;
        }
    }
    return 0;
}

1;

