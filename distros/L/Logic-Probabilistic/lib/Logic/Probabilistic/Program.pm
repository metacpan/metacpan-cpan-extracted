package Logic::Probabilistic::Program;

use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';
use Carp qw(croak);

use Scalar::Util qw(blessed looks_like_number);

our $VERSION = '0.01';

sub new ( $class, %args ) {
    require Logic::Relational::Program;
    my $rel_prog = $args{relational_program}
      // Logic::Relational::Program->new();

    my $self = {
        relational_program => $rel_prog,
        pfacts             => [],
        pchoices           => [],
        prules             => [],
        prule_counter      => 0,
        known_pred_keys    => {},
        max_worlds         => $args{max_worlds},
        timeout            => $args{timeout},
    };

    return bless $self, $class;
}

sub relational_program ($self) { return $self->{relational_program}; }

sub max_worlds ( $self, @args ) {
    if (@args) {
        $self->{max_worlds} = $args[0];
    }
    return $self->{max_worlds};
}

sub timeout ( $self, @args ) {
    if (@args) {
        $self->{timeout} = $args[0];
    }
    return $self->{timeout};
}

sub pfact ( $self, $prob, $pred, @args ) {
    my %opts;
    if (   @args
        && ref( $args[-1] ) eq 'HASH'
        && ( exists $args[-1]{expires_in} || exists $args[-1]{expires_at} ) )
    {
        my $opts_ref = pop @args;
        %opts = %$opts_ref;
    }

    require Logic::Probabilistic::PFact;
    my $pfact = Logic::Probabilistic::PFact->new(
        probability => $prob,
        predicate   => $pred,
        args        => \@args,
        %opts,
    );

    push @{ $self->{pfacts} }, $pfact;
    $self->{known_pred_keys}{ $pfact->key } = 1;
    return $pfact;
}

sub assert_pfact ( $self, %args ) {
    require Logic::Probabilistic::PFact;
    my $pfact = Logic::Probabilistic::PFact->new(%args);

    push @{ $self->{pfacts} }, $pfact;
    $self->{known_pred_keys}{ $pfact->key } = 1;
    return $pfact;
}

sub retract_pfact ( $self, $pred, @args ) {
    if ( blessed($pred) && $pred->isa('Logic::Probabilistic::PFact') ) {
        my $target = $pred;
        my $pfacts = $self->{pfacts};
        for ( my $i = 0 ; $i < @$pfacts ; $i++ ) {
            if ( $pfacts->[$i] == $target || $pfacts->[$i]->id eq $target->id )
            {
                my ($removed) = splice @$pfacts, $i, 1;
                $self->_rebuild_known_pred_keys;
                return $removed;
            }
        }
        return;
    }

    my $pfacts = $self->{pfacts};
    for ( my $i = 0 ; $i < @$pfacts ; $i++ ) {
        my $pf = $pfacts->[$i];
        if (   $pf->predicate eq $pred
            && $self->_args_match( $pf->args, \@args ) )
        {
            my ($removed) = splice @$pfacts, $i, 1;
            $self->_rebuild_known_pred_keys;
            return $removed;
        }
    }
    return;
}

sub retract_all_pfacts ( $self, $pred, @args ) {
    my $pfacts = $self->{pfacts};
    my @removed;
    my @remaining;

    for my $pf (@$pfacts) {
        if ( $pf->predicate eq $pred
            && ( !@args || $self->_args_match( $pf->args, \@args ) ) )
        {
            push @removed, $pf;
        }
        else {
            push @remaining, $pf;
        }
    }

    if (@removed) {
        $self->{pfacts} = \@remaining;
        $self->_rebuild_known_pred_keys;
    }

    return @removed;
}

sub update_pfact ( $self, $arg1, $arg2, @rest ) {
    if ( blessed($arg1) && $arg1->isa('Logic::Probabilistic::PFact') ) {
        $arg1->set_probability($arg2);
        return $arg1;
    }

    my ( $prob, $pred, @args );
    if ( !looks_like_number($arg1) && looks_like_number($arg2) ) {
        ( $pred, $prob, @args ) = ( $arg1, $arg2, @rest );
    }
    else {
        ( $prob, $pred, @args ) = ( $arg1, $arg2, @rest );
    }

    my $pfacts = $self->{pfacts};
    for my $pf (@$pfacts) {
        if (   $pf->predicate eq $pred
            && $self->_args_match( $pf->args, \@args ) )
        {
            $pf->set_probability($prob);
            return $pf;
        }
    }
    return;
}

sub set_pfact ( $self, $prob, $pred, @args ) {
    my $existing = $self->update_pfact( $prob, $pred, @args );
    return $existing if $existing;
    return $self->pfact( $prob, $pred, @args );
}

sub cleanup_expired_pfacts ( $self, $now = time ) {
    my $pfacts = $self->{pfacts};
    my $count  = 0;
    my @retained;
    for my $pf (@$pfacts) {
        if ( $pf->is_expired($now) ) {
            $count++;
        }
        else {
            push @retained, $pf;
        }
    }
    if ($count) {
        $self->{pfacts} = \@retained;
        $self->_rebuild_known_pred_keys;
    }
    return $count;
}

sub pchoice ( $self, $pred, $outcomes, @args ) {
    my $base_args =
      ( @args == 1 && ref( $args[0] ) eq 'ARRAY' ) ? $args[0] : \@args;
    require Logic::Probabilistic::PChoice;
    my $pchoice = Logic::Probabilistic::PChoice->new(
        predicate => $pred,
        outcomes  => $outcomes,
        args      => $base_args,
    );

    push @{ $self->{pchoices} }, $pchoice;
    for my $out ( $pchoice->outcomes ) {
        $self->{known_pred_keys}{ $out->{key} } = 1;
    }
    return $pchoice;
}

sub retract_pchoice ( $self, $pred, @args ) {
    if ( blessed($pred) && $pred->isa('Logic::Probabilistic::PChoice') ) {
        my $target   = $pred;
        my $pchoices = $self->{pchoices};
        for ( my $i = 0 ; $i < @$pchoices ; $i++ ) {
            if ( $pchoices->[$i] == $target ) {
                my ($removed) = splice @$pchoices, $i, 1;
                $self->_rebuild_known_pred_keys;
                return $removed;
            }
        }
        return;
    }

    my $base_args =
      ( @args == 1 && ref( $args[0] ) eq 'ARRAY' ) ? $args[0] : \@args;
    my $pchoices = $self->{pchoices};
    for ( my $i = 0 ; $i < @$pchoices ; $i++ ) {
        my $pc = $pchoices->[$i];
        if (   $pc->predicate eq $pred
            && $self->_args_match( $pc->args, $base_args ) )
        {
            my ($removed) = splice @$pchoices, $i, 1;
            $self->_rebuild_known_pred_keys;
            return $removed;
        }
    }
    return;
}

sub update_pchoice ( $self, $pred, $outcomes, @args ) {
    my $base_args =
      ( @args == 1 && ref( $args[0] ) eq 'ARRAY' ) ? $args[0] : \@args;
    my $pchoices = $self->{pchoices};
    for ( my $i = 0 ; $i < @$pchoices ; $i++ ) {
        my $pc = $pchoices->[$i];
        if (   $pc->predicate eq $pred
            && $self->_args_match( $pc->args, $base_args ) )
        {
            require Logic::Probabilistic::PChoice;
            my $new_pc = Logic::Probabilistic::PChoice->new(
                predicate => $pred,
                outcomes  => $outcomes,
                args      => $base_args,
            );
            $pchoices->[$i] = $new_pc;
            $self->_rebuild_known_pred_keys;
            return $new_pc;
        }
    }
    return;
}

sub prule ( $self, %args ) {
    my $prob = $args{probability} // croak 'probability is required for prule';
    my $pred = $args{predicate}   // croak 'predicate is required for prule';
    my $params = $args{params}    // [];
    my $body   = $args{body}      // croak 'body is required for prule';

    $self->{prule_counter}++;
    my $aux_pred = '_cause_' . $pred . '_' . $self->{prule_counter};

    require Logic::Relational::Goal::Call;
    require Logic::Relational::Goal::All;

    my $head_goal = Logic::Relational::Goal::Call->new( $pred,     $params );
    my $aux_goal  = Logic::Relational::Goal::Call->new( $aux_pred, $params );
    my $combined_body =
      Logic::Relational::Goal::All->new( [ $body, $aux_goal ] );

    $self->rule(
        head => $head_goal,
        body => $combined_body,
    );

    my $entry = {
        id            => $self->{prule_counter},
        probability   => $prob,
        predicate     => $pred,
        params        => $params,
        body          => $body,
        aux_pred      => $aux_pred,
        grounded_keys => {},
    };

    push @{ $self->{prules} }, $entry;
    $self->_ground_prule($entry);

    return $entry;
}

sub _ensure_prules_grounded ($self) {
    return unless $self->{prules} && @{ $self->{prules} };
    for my $entry ( @{ $self->{prules} } ) {
        $self->_ground_prule($entry);
    }
    return;
}

sub _flatten_body ( $self, $goal ) {
    return [] unless defined $goal;
    if ( blessed($goal) && $goal->isa('Logic::Relational::Goal::All') ) {
        my @flat;
        for my $g ( @{ $goal->goals // [] } ) {
            push @flat, @{ $self->_flatten_body($g) };
        }
        return \@flat;
    }
    return [$goal];
}

sub _extract_variables_from_goal ( $self, $goal ) {
    my %seen;
    my @result;

    my $walker;
    $walker = sub ($item) {
        return unless defined $item;
        ## no critic (ControlStructures::ProhibitCascadingIfElse)
        if ( blessed($item) ) {
            if ( $item->isa('Logic::Relational::Variable') ) {
                if ( !$seen{ $item->id }++ ) {
                    push @result, $item;
                }
            }
            elsif ( $item->can('goals') ) {
                for my $sub ( @{ $item->goals // [] } ) {
                    $walker->($sub);
                }
            }
            elsif ( $item->can('inner_goal') ) {
                $walker->( $item->inner_goal );
            }
            elsif ( $item->can('args') ) {
                for my $sub ( @{ $item->args // [] } ) {
                    $walker->($sub);
                }
            }
            elsif ( $item->can('left') && $item->can('right') ) {
                $walker->( $item->left );
                $walker->( $item->right );
            }
            elsif ( $item->can('term') ) {
                $walker->( $item->term );
            }
            elsif ( $item->can('var') ) {
                $walker->( $item->var );
            }
        }
        elsif ( ref($item) eq 'ARRAY' ) {
            for my $sub (@$item) {
                $walker->($sub);
            }
        }
    };

    $walker->($goal);
    return @result;
}

sub is_probabilistic_predicate ( $self, $pred_name ) {
    return 0 unless defined $pred_name;
    return 1 if $pred_name =~ /\A_cause_/x;

    for my $pf ( @{ $self->{pfacts} // [] } ) {
        return 1 if $pf->predicate eq $pred_name;
    }
    for my $pc ( @{ $self->{pchoices} // [] } ) {
        return 1 if $pc->predicate eq $pred_name;
    }
    for my $pr ( @{ $self->{prules} // [] } ) {
        return 1 if $pr->{predicate} eq $pred_name;
        return 1 if $pr->{aux_pred} eq $pred_name;
    }
    return 0;
}

sub _is_probabilistic_goal ( $self, $goal ) {
    return 0 unless defined $goal && blessed($goal);

    if ( $goal->isa('Logic::Relational::Goal::Call') ) {
        return $self->is_probabilistic_predicate( $goal->name );
    }
    if ( $goal->isa('Logic::Relational::Goal::Not') ) {
        return $self->_is_probabilistic_goal( $goal->inner_goal );
    }
    if ( $goal->isa('Logic::Relational::Goal::All') ) {
        for my $sub ( @{ $goal->goals // [] } ) {
            return 1 if $self->_is_probabilistic_goal($sub);
        }
    }
    if ( $goal->isa('Logic::Relational::Goal::Any') ) {
        for my $sub ( @{ $goal->goals // [] } ) {
            return 1 if $self->_is_probabilistic_goal($sub);
        }
    }
    return 0;
}

sub _classify_candidate_goals ( $self, $flat_goals ) {
    my ( @positive_cands, @filter_cands );
    for my $g (@$flat_goals) {
        next if $self->_is_probabilistic_goal($g);
        my @vars = $self->_extract_variables_from_goal($g);
        next unless @vars;

        my $entry = {
            goal    => $g,
            vars    => \@vars,
            var_ids => { map { $_->id => 1 } @vars },
        };

        if ( blessed($g) && $g->isa('Logic::Relational::Goal::Not') ) {
            push @filter_cands, $entry;
        }
        else {
            push @positive_cands, $entry;
        }
    }
    return ( \@positive_cands, \@filter_cands );
}

sub _find_connected_positive_goals ( $self, $positive_cands, $param_var_ids ) {
    my %active_var_ids = %$param_var_ids;
    my %selected_idx;
    my $changed = 1;

    while ($changed) {
        $changed = 0;
        for ( my $i = 0 ; $i < @$positive_cands ; $i++ ) {
            next if $selected_idx{$i};
            my $cand     = $positive_cands->[$i];
            my $overlaps = 0;
            for my $vid ( keys %{ $cand->{var_ids} } ) {
                if ( $active_var_ids{$vid} ) {
                    $overlaps = 1;
                    last;
                }
            }
            if ($overlaps) {
                $selected_idx{$i} = 1;
                for my $vid ( keys %{ $cand->{var_ids} } ) {
                    $active_var_ids{$vid} = 1;
                }
                $changed = 1;
            }
        }
    }

    my @selected_goals =
      map { $positive_cands->[$_]{goal} } sort { $a <=> $b } keys %selected_idx;
    return ( \@selected_goals, \%active_var_ids );
}

sub _extract_domain_goals ( $self, $body, $params ) {
    my $flat = $self->_flatten_body($body);

    my %param_var_ids;
    for my $p (@$params) {
        if ( blessed($p) && $p->isa('Logic::Relational::Variable') ) {
            $param_var_ids{ $p->id } = 1;
        }
    }

    my ( $positive_cands, $filter_cands ) =
      $self->_classify_candidate_goals($flat);
    return () unless @$positive_cands;

    my ( $domain_goals, $active_var_ids ) =
      $self->_find_connected_positive_goals( $positive_cands, \%param_var_ids );

    my @results = @$domain_goals;
    for my $cand (@$filter_cands) {
        my $all_bound = 1;
        for my $vid ( keys %{ $cand->{var_ids} } ) {
            if ( !$active_var_ids->{$vid} ) {
                $all_bound = 0;
                last;
            }
        }
        if ($all_bound) {
            push @results, $cand->{goal};
        }
    }

    return @results;
}

sub _ground_prule ( $self, $entry ) {
    my $params   = $entry->{params} // [];
    my $aux_pred = $entry->{aux_pred};
    my $prob     = $entry->{probability};
    my $body     = $entry->{body};
    $entry->{grounded_keys} //= {};

    if ( !@$params ) {
        if ( !$entry->{grounded_keys}{''}++ ) {
            $self->pfact( $prob, $aux_pred );
        }
        return;
    }

    my @domain_goals = $self->_extract_domain_goals( $body, $params );
    return unless @domain_goals;

    require Logic::Relational::Goal::All;
    my $query_goal =
        @domain_goals == 1
      ? $domain_goals[0]
      : Logic::Relational::Goal::All->new( \@domain_goals );

    my $rel_prog = $self->relational_program;
    my $base     = $rel_prog->{predicates} // {};

    my %ground_predicates;
    for my $key ( keys %$base ) {
        $ground_predicates{$key} = [ @{ $base->{$key} } ];
    }
    for my $pf ( @{ $self->{pfacts} // [] } ) {
        $ground_predicates{ $pf->key } //= [];
        push @{ $ground_predicates{ $pf->key } }, $pf->clause;
    }
    for my $pc ( @{ $self->{pchoices} // [] } ) {
        for my $out ( $pc->outcomes ) {
            $ground_predicates{ $out->{key} } //= [];
            push @{ $ground_predicates{ $out->{key} } }, $out->{clause};
        }
    }
    for my $key ( keys %{ $self->{known_pred_keys} // {} } ) {
        $ground_predicates{$key} //= [];
    }

    try {
        require Logic::Relational::Query;
        my $query = Logic::Relational::Query->new(
            program    => $rel_prog,
            goals      => [$query_goal],
            predicates => \%ground_predicates,
            generators => $rel_prog->{generators} // {},
        );

        while ( my $sol = $query->next ) {
            my @ground_args;
            my $has_unbound = 0;
            for my $param (@$params) {
                my $val = $sol->value($param);
                if ( blessed($val) && $val->isa('Logic::Relational::Variable') )
                {
                    $has_unbound = 1;
                    last;
                }
                push @ground_args, $val;
            }
            next if $has_unbound;

            my $key = join( "\0", map { defined $_ ? "$_" : '' } @ground_args );
            next if $entry->{grounded_keys}{$key}++;

            $self->pfact( $prob, $aux_pred, @ground_args );
        }
    }
    catch ($e) {

     # Predicate may not be defined yet if facts/rules appear later in the block
        return;
    }
    return;
}

sub reground_prules ($self) {
    return unless $self->{prules} && @{ $self->{prules} };
    for my $entry ( @{ $self->{prules} } ) {
        $self->retract_all_pfacts( $entry->{aux_pred} );
        $entry->{grounded_keys} = {};
        $self->_ground_prule($entry);
    }
    return;
}

# Delegate deterministic facts, rules, and retractions to relational program
sub fact ( $self, $pred, @args ) {
    return $self->{relational_program}->fact( $pred, @args );
}

sub assert_fact ( $self, %args ) {
    return $self->{relational_program}->assert_fact(%args);
}

sub retract ( $self, $pred, @args ) {
    return $self->{relational_program}->retract( $pred, @args );
}

sub retract_all ( $self, $pred, @args ) {
    return $self->{relational_program}->retract_all( $pred, @args );
}

sub retract_clause ( $self, $id ) {
    return $self->{relational_program}->retract_clause($id);
}

sub cleanup_expired_facts ($self) {
    return $self->{relational_program}->cleanup_expired_facts;
}

sub rule ( $self, %args ) {
    return $self->{relational_program}->rule(%args);
}

sub generator ( $self, $name, $arity, $code ) {
    return $self->{relational_program}->generator( $name, $arity, $code );
}

sub table ( $self, $name, $arity = undef ) {
    return $self->{relational_program}->table( $name, $arity );
}

sub untable ( $self, $name, $arity = undef ) {
    return $self->{relational_program}->untable( $name, $arity );
}

sub is_tabled ( $self, $name, $arity = undef ) {
    return $self->{relational_program}->is_tabled( $name, $arity );
}

sub all_pfacts ($self) {
    $self->_ensure_prules_grounded;
    return @{ $self->{pfacts} };
}

sub all_pchoices ($self) {
    return @{ $self->{pchoices} };
}

sub all_prules ($self) {
    return @{ $self->{prules} // [] };
}

sub version ($self) { return $self->{version} // 1; }

sub increment_version ($self) {
    $self->{version} = ( $self->{version} // 1 ) + 1;
    return $self->{version};
}

sub save_snapshot ( $self, $target, %options ) {
    require Logic::Probabilistic::Serializer;
    return Logic::Probabilistic::Serializer::save_snapshot( $self, $target,
        %options );
}

sub load_snapshot ( $self, $source, %options ) {
    require Logic::Probabilistic::Serializer;
    return Logic::Probabilistic::Serializer::load_snapshot( $self, $source,
        %options );
}

sub _args_match ( $self, $stored_args, $given_args ) {
    return 0 unless @$stored_args == @$given_args;
    for ( my $i = 0 ; $i < @$stored_args ; $i++ ) {
        my $s = $stored_args->[$i];
        my $g = $given_args->[$i];
        if ( defined $s && defined $g ) {
            my $s_str =
              ref($s) ? ( $s->can('to_string') ? $s->to_string : "$s" ) : "$s";
            my $g_str =
              ref($g) ? ( $g->can('to_string') ? $g->to_string : "$g" ) : "$g";
            return 0 if $s_str ne $g_str;
        }
        elsif ( !defined $s && !defined $g ) {
            next;
        }
        else {
            return 0;
        }
    }
    return 1;
}

sub _rebuild_known_pred_keys ($self) {
    for my $pf ( @{ $self->{pfacts} } ) {
        $self->{known_pred_keys}{ $pf->key } = 1;
    }
    for my $pc ( @{ $self->{pchoices} } ) {
        for my $out ( $pc->outcomes ) {
            $self->{known_pred_keys}{ $out->{key} } = 1;
        }
    }
    return;
}

sub normalize_goal ( $self, $g ) {
    my $goal_obj;
    if ( blessed($g) && $g->isa('Logic::Relational::Goal') ) {
        $goal_obj = $g;
    }
    elsif ( ref($g) eq 'ARRAY' ) {
        my ( $pred, @args ) = @$g;
        require Logic::Relational::Goal::Call;
        $goal_obj = Logic::Relational::Goal::Call->new( $pred, \@args );
    }
    elsif ( !ref($g) ) {
        require Logic::Relational::Goal::Call;
        my $clean = $g;
        $clean =~ s/.*:://x;
        $goal_obj = Logic::Relational::Goal::Call->new( $clean, [] );
    }
    else {
        croak "Cannot normalize goal from: " . ref($g);
    }

    my $check_obj = $goal_obj;
    if ( blessed($check_obj)
        && $check_obj->isa('Logic::Relational::Goal::Not') )
    {
        $check_obj = $check_obj->inner_goal;
    }

    if ( $check_obj && $check_obj->can('name') && $check_obj->can('arity') ) {
        my $k = $check_obj->name . '/' . $check_obj->arity;
        $self->{known_pred_keys}{$k} = 1;
    }

    return $goal_obj;
}

sub build_world_predicates ( $self, $active_clauses_by_key = {} ) {
    $self->_ensure_prules_grounded;
    $self->{relational_program}->cleanup_expired_facts;
    $self->cleanup_expired_pfacts;

    my $base = $self->{relational_program}->{predicates} // {};

    my %world_predicates;
    for my $key ( keys %$base ) {
        $world_predicates{$key} = [ @{ $base->{$key} } ];
    }

    # Ensure all registered probabilistic predicates exist in the world table
    for my $key ( keys %{ $self->{known_pred_keys} } ) {
        $world_predicates{$key} //= [];
    }

    # Add active clauses selected for this world
    for my $key ( keys %$active_clauses_by_key ) {
        $world_predicates{$key} //= [];
        push @{ $world_predicates{$key} }, @{ $active_clauses_by_key->{$key} };
    }

    return \%world_predicates;
}

sub query ( $self, $goal, %options ) {
    $self->_ensure_prules_grounded;
    return $self->query_distribution( $goal, %options )
      if $options{as_distribution};

    my $method = $options{method} // 'exact';

    if ( $method eq 'exact' ) {
        require Logic::Probabilistic::Inference::Exact;
        my %engine_args = ( program => $self );
        my $mw =
          exists $options{max_worlds}
          ? $options{max_worlds}
          : $self->{max_worlds};
        $engine_args{max_worlds} = $mw if defined $mw;
        my $to =
          exists $options{timeout} ? $options{timeout} : $self->{timeout};
        $engine_args{timeout} = $to if defined $to;

        my $engine = Logic::Probabilistic::Inference::Exact->new(%engine_args);
        return $engine->query( query => $goal, %options );
    }
    elsif ( $method eq 'rejection' || $method eq 'monte_carlo' ) {
        require Logic::Probabilistic::Inference::Rejection;
        my %engine_args = ( program => $self );
        my $to =
          exists $options{timeout} ? $options{timeout} : $self->{timeout};
        $engine_args{timeout} = $to               if defined $to;
        $engine_args{samples} = $options{samples} if exists $options{samples};

        my $engine =
          Logic::Probabilistic::Inference::Rejection->new(%engine_args);
        return $engine->query( query => $goal, %options );
    }
    elsif ( $method eq 'mcmc' ) {
        require Logic::Probabilistic::Inference::MCMC;
        my %engine_args = ( program => $self );
        my $to =
          exists $options{timeout} ? $options{timeout} : $self->{timeout};
        $engine_args{timeout} = $to               if defined $to;
        $engine_args{samples} = $options{samples} if exists $options{samples};

        my $engine = Logic::Probabilistic::Inference::MCMC->new(%engine_args);
        return $engine->query( query => $goal, %options );
    }

    croak "Unsupported inference method '$method'";
}

sub query_distribution ( $self, $goal, %options ) {
    $self->_ensure_prules_grounded;
    my $method = $options{method} // 'exact';

    if ( $method eq 'exact' ) {
        require Logic::Probabilistic::Inference::Exact;
        my %engine_args = ( program => $self );
        my $mw =
          exists $options{max_worlds}
          ? $options{max_worlds}
          : $self->{max_worlds};
        $engine_args{max_worlds} = $mw if defined $mw;
        my $to =
          exists $options{timeout} ? $options{timeout} : $self->{timeout};
        $engine_args{timeout} = $to if defined $to;

        my $engine = Logic::Probabilistic::Inference::Exact->new(%engine_args);
        return $engine->query_distribution( query => $goal, %options );
    }
    elsif ( $method eq 'rejection' || $method eq 'monte_carlo' ) {
        require Logic::Probabilistic::Inference::Rejection;
        my %engine_args = ( program => $self );
        my $to =
          exists $options{timeout} ? $options{timeout} : $self->{timeout};
        $engine_args{timeout} = $to               if defined $to;
        $engine_args{samples} = $options{samples} if exists $options{samples};

        my $engine =
          Logic::Probabilistic::Inference::Rejection->new(%engine_args);
        return $engine->query_distribution( query => $goal, %options );
    }
    elsif ( $method eq 'mcmc' ) {
        require Logic::Probabilistic::Inference::MCMC;
        my %engine_args = ( program => $self );
        my $to =
          exists $options{timeout} ? $options{timeout} : $self->{timeout};
        $engine_args{timeout} = $to               if defined $to;
        $engine_args{samples} = $options{samples} if exists $options{samples};

        my $engine = Logic::Probabilistic::Inference::MCMC->new(%engine_args);
        return $engine->query_distribution( query => $goal, %options );
    }

    croak "Unsupported inference method '$method'";
}

1;

__END__

=head1 NAME

Logic::Probabilistic::Program - Represents a probabilistic logic program.

=head1 SYNOPSIS

    use Logic::Probabilistic::Program;

    my $prog = Logic::Probabilistic::Program->new;
    $prog->pfact(0.7, 'rain');
    $prog->rule(head => ..., body => ...);

    my $result = $prog->query('rain');

=head1 METHODS

=head2 pfact( $prob, $pred, @args, [ \%opts ] )

Asserts an independent probabilistic fact with probability C<$prob>.
Optional trailing options hashref supports C<expires_in => $seconds> or C<expires_at => $timestamp>.

=head2 assert_pfact( %args )

Named-argument variant of C<pfact>. Accepts C<probability>, C<predicate>, C<args>,
C<expires_in>, and C<expires_at>.

=head2 retract_pfact( $pred, @args )

Retracts the first matching probabilistic fact matching the predicate and arguments.
Returns the removed L<Logic::Probabilistic::PFact> object, or undef if not found.

=head2 retract_all_pfacts( $pred, @args )

Retracts all matching probabilistic facts. Returns the list of removed objects.

=head2 update_pfact( $prob, $pred, @args )

Updates the probability of an existing probabilistic fact in-place.
Returns the updated L<Logic::Probabilistic::PFact> object, or undef if not found.

=head2 set_pfact( $prob, $pred, @args )

Upsert method: updates the probability if the fact already exists, or asserts it if not.

=head2 pchoice( $pred, \@outcomes, @args )

Registers a categorical random variable (annotated disjunction).

=head2 retract_pchoice( $pred, @args )

Retracts a categorical random choice.

=head2 update_pchoice( $pred, \@outcomes, @args )

Updates the outcomes distribution of an existing categorical choice in-place.

=head2 assert_fact( %args )

Delegates to L<Logic::Relational::Program/assert_fact>. Supports C<expires_in> for TTL.

=head2 retract( $pred, @args )

Delegates to L<Logic::Relational::Program/retract>. Retracts a deterministic fact.

=head2 retract_all( $pred, @args )

Delegates to L<Logic::Relational::Program/retract_all>. Retracts all matching deterministic facts.

=head2 cleanup_expired_pfacts( [$now] )

Prunes any probabilistic facts whose C<expires_at> timestamp has passed.

=head2 prule( %args )

Registers a probabilistic clause / rule. Accepts C<probability>, C<predicate>, C<params>,
and C<body>. Automatically desugars into an auxiliary probabilistic cause fact template
and a deterministic Horn clause, auto-grounding across the domain of the body.

=head2 query( $goal, %options )

Performs probabilistic query inference using exact enumeration, rejection sampling, or MCMC.

=head2 save_snapshot( $target, %options )

Serializes the current program state (probabilistic facts, categorical choices,
deterministic ground facts, and metadata) to a JSON snapshot. C<$target> may be a file
path string, an open filehandle, or a scalar reference for in-memory serialization.
Options include C<pretty =E<gt> 1> for formatted JSON output.

=head2 load_snapshot( $source, %options )

Loads a previously serialized snapshot into the program. C<$source> may be a file path,
an open filehandle, or a scalar reference containing JSON text.

Options:

=over 4

=item * C<mode =E<gt> 'replace' | 'merge'>: Default is C<'replace'>, which clears previous
facts and choices while preserving compiled rules. C<'merge'> retains existing facts.

=item * C<ttl_mode =E<gt> 'absolute' | 'relative'>: Default is C<'absolute'>. Setting
C<'relative'> (or C<pause_ttl =E<gt> 1>) recalculates expiration deadlines relative to the current
clock time, allowing simulations to be paused and resumed.

=item * C<filter_expired =E<gt> 1>: Prunes any facts whose TTL has elapsed (default 1).

=back

=cut
