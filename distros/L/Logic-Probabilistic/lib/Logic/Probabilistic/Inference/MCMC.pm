package Logic::Probabilistic::Inference::MCMC;

use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';
use Carp         qw(croak);
use Scalar::Util qw(blessed);
use parent 'Logic::Probabilistic::Inference::Base';

our $VERSION = '0.01';

sub new ( $class, %args ) {
    my $self = $class->SUPER::new(%args);
    $self->{chains}   //= 4;
    $self->{samples}  //= 5000;
    $self->{burn_in}  //= 500;
    $self->{lag}      //= 5;
    $self->{max_init} //= 2000;
    $self->{timeout} = $args{timeout};
    return $self;
}

sub chains   ($self) { return $self->{chains}; }
sub samples  ($self) { return $self->{samples}; }
sub burn_in  ($self) { return $self->{burn_in}; }
sub lag      ($self) { return $self->{lag}; }
sub max_init ($self) { return $self->{max_init}; }
sub timeout  ($self) { return $self->{timeout}; }

sub _prepare_vars ($self) {
    my @pfacts   = $self->program->all_pfacts;
    my @pchoices = $self->program->all_pchoices;

    my @all_vars = (
        ( map { { type => 'pfact',   var => $_ } } @pfacts ),
        ( map { { type => 'pchoice', var => $_ } } @pchoices )
    );
    return \@all_vars;
}

sub _random_initial_state ( $self, $all_vars ) {
    my @state;
    for my $v (@$all_vars) {
        if ( $v->{type} eq 'pfact' ) {
            push @state, ( rand() < $v->{var}->probability ) ? 1 : 0;
        }
        else {
            my $r      = rand();
            my $cum    = 0.0;
            my $chosen = -1;
            my $idx    = 0;
            for my $out ( $v->{var}->outcomes ) {
                $cum += $out->{probability};
                if ( $r < $cum ) {
                    $chosen = $idx;
                    last;
                }
                $idx++;
            }
            push @state, $chosen;
        }
    }
    return \@state;
}

sub _clauses_for_state ( $self, $state, $all_vars ) {
    my %active_clauses;
    my $idx = 0;
    for my $v (@$all_vars) {
        my $val = $state->[$idx];
        if ( $v->{type} eq 'pfact' ) {
            if ( $val == 1 ) {
                my $pf = $v->{var};
                $active_clauses{ $pf->key } =
                  [ @{ $active_clauses{ $pf->key } // [] }, $pf->clause ];
            }
        }
        else {
            if ( $val >= 0 ) {
                my @outs = $v->{var}->outcomes;
                if ( $val < scalar(@outs) ) {
                    my $out = $outs[$val];
                    $active_clauses{ $out->{key} } = [
                        @{ $active_clauses{ $out->{key} } // [] },
                        $out->{clause}
                    ];
                }
            }
        }
        $idx++;
    }
    return \%active_clauses;
}

sub _find_initial_state ( $self, $all_vars, $rel_prog, $evidence_goals,
    $generators )
{
    return [ map { 0 } @$all_vars ] unless @$evidence_goals;

    for ( 1 .. $self->max_init ) {
        my $st      = $self->_random_initial_state($all_vars);
        my $clauses = $self->_clauses_for_state( $st, $all_vars );
        my $preds   = $self->program->build_world_predicates($clauses);
        if (
            $self->_check_evidence(
                $rel_prog, $evidence_goals, $preds, $generators
            )
          )
        {
            return $st;
        }
    }

    croak
"MCMC initialization failed: could not find any world satisfying evidence "
      . "after "
      . $self->max_init
      . " attempts. Evidence may have zero probability.";
}

sub _propose_transition ( $self, $state, $all_vars ) {
    return ( $state, 1.0 ) if scalar(@$all_vars) == 0;

    my $var_idx = int( rand( scalar(@$all_vars) ) );
    my $entry   = $all_vars->[$var_idx];
    my @new_st  = @$state;
    my $ratio   = 1.0;

    if ( $entry->{type} eq 'pfact' ) {
        my $p    = $entry->{var}->probability;
        my $curr = $state->[$var_idx];
        my $prop = 1 - $curr;
        $new_st[$var_idx] = $prop;

        if ( $curr == 0 && $prop == 1 ) {
            $ratio = ( 1.0 - $p > 0 ) ? ( $p / ( 1.0 - $p ) ) : 1.0;
        }
        else {
            $ratio = ( $p > 0 ) ? ( ( 1.0 - $p ) / $p ) : 1.0;
        }
    }
    else {
        my $pc          = $entry->{var};
        my @outs        = $pc->outcomes;
        my $num_options = scalar(@outs) + ( $pc->null_prob > 0 ? 1 : 0 );
        my $curr        = $state->[$var_idx];

        my $p_curr =
          ( $curr >= 0 && $curr < scalar(@outs) )
          ? $outs[$curr]->{probability}
          : $pc->null_prob;

        # Pick random alternative outcome
        my $prop = int( rand($num_options) );
        $prop = -1 if $prop == scalar(@outs);    # null outcome

        $new_st[$var_idx] = $prop;

        my $p_prop =
          ( $prop >= 0 && $prop < scalar(@outs) )
          ? $outs[$prop]->{probability}
          : $pc->null_prob;

        $ratio = ( $p_curr > 0 ) ? ( $p_prop / $p_curr ) : 1.0;
    }

    return ( \@new_st, $ratio );
}

sub _resolve_initial_state ( $self, $init_arg, $chain_idx ) {
    return unless defined $init_arg;
    if ( ref $init_arg eq 'ARRAY' && ref $init_arg->[0] eq 'ARRAY' ) {
        return $init_arg->[ $chain_idx - 1 ];
    }
    return $init_arg if $chain_idx == 1;
    return;
}

sub _run_chain (
    $self,       $all_vars,      $rel_prog,          $evidence_goals,
    $query_goal, $generators,    $samples_per_chain, $burn_in,
    $lag,        $initial_state, $ev_cache,          $query_cache,
    $deadline = undef
  )
{
    my $curr_state = $initial_state
      // $self->_find_initial_state( $all_vars, $rel_prog, $evidence_goals,
        $generators );

    my $curr_key = join( ',', @$curr_state );
    $ev_cache->{$curr_key} = 1;

    my $proposals = 0;
    my $accepted  = 0;

    # Burn-in phase
    for ( 1 .. $burn_in ) {
        if ( $deadline && time() > $deadline ) {
            last;
        }
        my ( $prop_state, $ratio ) =
          $self->_propose_transition( $curr_state, $all_vars );
        $proposals++;

        if ( $ratio >= 1.0 || rand() < $ratio ) {
            my $prop_key = join( ',', @$prop_state );
            my $ev_ok    = $ev_cache->{$prop_key};
            if ( !defined $ev_ok ) {
                my $clauses =
                  $self->_clauses_for_state( $prop_state, $all_vars );
                my $preds = $self->program->build_world_predicates($clauses);
                $ev_ok =
                  $self->_check_evidence( $rel_prog, $evidence_goals, $preds,
                    $generators );
                $ev_cache->{$prop_key} = $ev_ok;
            }

            if ($ev_ok) {
                $curr_state = $prop_state;
                $curr_key   = $prop_key;
                $accepted++;
            }
        }
    }

    # Sampling phase
    my @samples;
    my $step      = 0;
    my $successes = 0;

    while ( scalar(@samples) < $samples_per_chain ) {
        if ( $deadline && ( $step & 63 ) == 0 && time() > $deadline ) {
            last;
        }
        $step++;
        my ( $prop_state, $ratio ) =
          $self->_propose_transition( $curr_state, $all_vars );
        $proposals++;

        if ( $ratio >= 1.0 || rand() < $ratio ) {
            my $prop_key = join( ',', @$prop_state );
            my $ev_ok    = $ev_cache->{$prop_key};
            if ( !defined $ev_ok ) {
                my $clauses =
                  $self->_clauses_for_state( $prop_state, $all_vars );
                my $preds = $self->program->build_world_predicates($clauses);
                $ev_ok =
                  $self->_check_evidence( $rel_prog, $evidence_goals, $preds,
                    $generators );
                $ev_cache->{$prop_key} = $ev_ok;
            }

            if ($ev_ok) {
                $curr_state = $prop_state;
                $curr_key   = $prop_key;
                $accepted++;
            }
        }

        if ( ( $step % $lag ) == 0 ) {
            my $q_ok = $query_cache->{$curr_key};
            if ( !defined $q_ok ) {
                my $clauses =
                  $self->_clauses_for_state( $curr_state, $all_vars );
                my $preds = $self->program->build_world_predicates($clauses);
                $q_ok = $self->_check_query( $rel_prog, $query_goal, $preds,
                    $generators );
                $query_cache->{$curr_key} = $q_ok;
            }

            my $val = $q_ok ? 1 : 0;
            push @samples, $val;
            $successes++ if $val;
        }
    }

    return ( \@samples, $successes, $proposals, $accepted );
}

sub query ( $self, %args ) {
    my $raw_query    = $args{query}    // croak "query is required";
    my $raw_evidence = $args{evidence} // $args{given} // [];

    my $query_goal     = $self->program->normalize_goal($raw_query);
    my $evidence_goals = $self->_normalize_goals($raw_evidence);

    my $num_chains = $args{chains} // $self->{chains};
    $num_chains = 1 if $num_chains < 1;

    my $samples_per_chain =
      defined $args{samples_per_chain}
      ? int( $args{samples_per_chain} )
      : int( ( $args{samples} // $self->{samples} ) / $num_chains );
    $samples_per_chain = 1 if $samples_per_chain < 1;

    my $burn_in = $args{burn_in} // $self->{burn_in};
    my $lag     = $args{lag}     // $self->{lag};

    if ( defined $args{seed} ) {
        srand( $args{seed} );
    }

    my $all_vars   = $self->_prepare_vars;
    my $rel_prog   = $self->program->relational_program;
    my $generators = $rel_prog->{generators} // {};

    require Logic::Probabilistic::Result;

    my %query_cache;
    my %ev_cache;
    my ( $total_props, $acc_props, $total_successes, $total_samples ) =
      ( 0, 0, 0, 0 );
    my @chain_samples;

    my $timeout = $args{timeout} // $self->timeout;
    my $deadline =
      ( defined $timeout && $timeout > 0 ) ? ( time() + $timeout ) : undef;

    for my $c ( 1 .. $num_chains ) {
        if ( $deadline && time() > $deadline ) {
            last;
        }
        my $init = $self->_resolve_initial_state( $args{initial_state}, $c );
        my ( $samples, $successes, $props, $accs ) = $self->_run_chain(
            $all_vars,   $rel_prog,     $evidence_goals,
            $query_goal, $generators,   $samples_per_chain,
            $burn_in,    $lag,          $init,
            \%ev_cache,  \%query_cache, $deadline
        );
        push @chain_samples, $samples;
        $total_successes += $successes;
        $total_samples   += scalar(@$samples);
        $total_props     += $props;
        $acc_props       += $accs;
    }

    my $timed_out = ( $deadline && time() > $deadline ) ? 1 : 0;
    if ( $timed_out && $total_samples == 0 ) {
        croak
"MCMC sampling exceeded timeout of $timeout seconds before collecting any samples";
    }

    my ( $r_hat, $ess, $chain_means, $warnings ) =
      $self->_calculate_diagnostics( \@chain_samples, $total_successes,
        $total_samples );

    my $prob = $total_samples > 0 ? ( $total_successes / $total_samples ) : 0.0;
    my $acc_rate = $total_props > 0 ? ( $acc_props / $total_props )       : 0.0;

    return Logic::Probabilistic::Result->new(
        probability          => $prob,
        evidence_probability => 1.0,
        method               => 'mcmc',
        total_samples        => $total_samples,
        accepted_samples     => $total_samples,
        query_success_count  => $total_successes,
        metadata             => {
            acceptance_rate   => $acc_rate,
            burn_in           => $burn_in,
            lag               => $lag,
            chains            => $num_chains,
            samples_per_chain => $samples_per_chain,
            ( $timed_out ? ( timed_out => 1 ) : () ),
            r_hat       => $r_hat,
            ess         => $ess,
            chain_means => $chain_means,
            warnings    => $warnings,
        },
    );
}

sub query_distribution ( $self, %args ) {
    my $raw_query    = $args{query}    // croak "query is required";
    my $raw_evidence = $args{evidence} // $args{given} // [];

    $raw_query = $self->_normalize_dist_query( $raw_query, $args{var} );

    my $query_goal     = $self->program->normalize_goal($raw_query);
    my $evidence_goals = $self->_normalize_goals($raw_evidence);
    my $target_var     = $self->_resolve_target_var( $query_goal, $args{var} );

    my $num_chains = $args{chains} // $self->{chains};
    $num_chains = 1 if $num_chains < 1;

    my $samples_per_chain =
      defined $args{samples_per_chain}
      ? int( $args{samples_per_chain} )
      : int( ( $args{samples} // $self->{samples} ) / $num_chains );
    $samples_per_chain = 1 if $samples_per_chain < 1;

    my $burn_in = $args{burn_in} // $self->{burn_in};
    my $lag     = $args{lag}     // $self->{lag};

    if ( defined $args{seed} ) {
        srand( $args{seed} );
    }

    my $all_vars   = $self->_prepare_vars;
    my $rel_prog   = $self->program->relational_program;
    my $generators = $rel_prog->{generators} // {};

    require Logic::Probabilistic::Distribution;

    my %val_counts;
    my %val_objects;
    my $total_drawn = 0;

    my %ev_cache;
    my %sol_cache;

    my $timeout = $args{timeout} // $self->timeout;
    my $deadline =
      ( defined $timeout && $timeout > 0 ) ? ( time() + $timeout ) : undef;

    for my $c ( 1 .. $num_chains ) {
        if ( $deadline && time() > $deadline ) {
            last;
        }
        my $init = $self->_resolve_initial_state( $args{initial_state}, $c );
        $self->_run_distribution_chain(
            $all_vars,    $rel_prog,     $evidence_goals,
            $query_goal,  $generators,   $samples_per_chain,
            $burn_in,     $lag,          $init,
            $target_var,  \%ev_cache,    \%sol_cache,
            \%val_counts, \%val_objects, \$total_drawn,
            $deadline
        );
    }

    my $timed_out = ( $deadline && time() > $deadline ) ? 1 : 0;
    if ( $timed_out && $total_drawn == 0 ) {
        croak
"MCMC sampling exceeded timeout of $timeout seconds before collecting any samples";
    }

    my %probs;
    if ( $total_drawn > 0 ) {
        for my $k ( keys %val_counts ) {
            $probs{$k} = $val_counts{$k} / $total_drawn;
        }
    }

    return Logic::Probabilistic::Distribution->new(
        probabilities        => \%probs,
        val_map              => \%val_objects,
        evidence_probability => 1.0,
        method               => 'mcmc',
        total_samples        => $total_drawn,
        accepted_samples     => $total_drawn,
        counts               => \%val_counts,
        metadata             => {
            chains            => $num_chains,
            samples_per_chain => $samples_per_chain,
            burn_in           => $burn_in,
            lag               => $lag,
            ( $timed_out ? ( timed_out => 1 ) : () ),
        },
    );
}

sub _run_distribution_chain (
    $self,              $all_vars,   $rel_prog,
    $evidence_goals,    $query_goal, $generators,
    $samples_per_chain, $burn_in,    $lag,
    $initial_state,     $target_var, $ev_cache,
    $sol_cache,         $val_counts, $val_objects,
    $total_drawn_ref,   $deadline = undef
  )
{
    my $curr_state = $initial_state
      // $self->_find_initial_state( $all_vars, $rel_prog, $evidence_goals,
        $generators );

    my $curr_key = join( ',', @$curr_state );
    $ev_cache->{$curr_key} = 1;

    # Burn-in phase
    for ( 1 .. $burn_in ) {
        if ( $deadline && time() > $deadline ) {
            last;
        }
        my ( $prop_state, $ratio ) =
          $self->_propose_transition( $curr_state, $all_vars );

        if ( $ratio >= 1.0 || rand() < $ratio ) {
            my $prop_key = join( ',', @$prop_state );
            my $ev_ok    = $ev_cache->{$prop_key};
            if ( !defined $ev_ok ) {
                my $clauses =
                  $self->_clauses_for_state( $prop_state, $all_vars );
                my $preds = $self->program->build_world_predicates($clauses);
                $ev_ok =
                  $self->_check_evidence( $rel_prog, $evidence_goals,
                    $preds, $generators );
                $ev_cache->{$prop_key} = $ev_ok;
            }

            if ($ev_ok) {
                $curr_state = $prop_state;
                $curr_key   = $prop_key;
            }
        }
    }

    # Sampling phase
    my $step            = 0;
    my $chain_collected = 0;
    while ( $chain_collected < $samples_per_chain ) {
        if ( $deadline && ( $step & 63 ) == 0 && time() > $deadline ) {
            last;
        }
        $step++;
        my ( $prop_state, $ratio ) =
          $self->_propose_transition( $curr_state, $all_vars );

        if ( $ratio >= 1.0 || rand() < $ratio ) {
            my $prop_key = join( ',', @$prop_state );
            my $ev_ok    = $ev_cache->{$prop_key};
            if ( !defined $ev_ok ) {
                my $clauses =
                  $self->_clauses_for_state( $prop_state, $all_vars );
                my $preds = $self->program->build_world_predicates($clauses);
                $ev_ok =
                  $self->_check_evidence( $rel_prog, $evidence_goals,
                    $preds, $generators );
                $ev_cache->{$prop_key} = $ev_ok;
            }

            if ($ev_ok) {
                $curr_state = $prop_state;
                $curr_key   = $prop_key;
            }
        }

        if ( ( $step % $lag ) == 0 ) {
            $chain_collected++;
            $$total_drawn_ref++;

            my $sols = $sol_cache->{$curr_key};
            if ( !defined $sols ) {
                my $clauses =
                  $self->_clauses_for_state( $curr_state, $all_vars );
                my $preds = $self->program->build_world_predicates($clauses);

                require Logic::Relational::Query;
                my $q = Logic::Relational::Query->new(
                    program    => $rel_prog,
                    goals      => [$query_goal],
                    predicates => $preds,
                    generators => $generators,
                );

                my %seen;
                while ( my $sol = $q->next ) {
                    my $val = $sol->value($target_var);
                    my $key = $self->_val_to_key($val);
                    $seen{$key} = $val;
                }
                $sols = \%seen;
                $sol_cache->{$curr_key} = $sols;
            }

            for my $k ( keys %$sols ) {
                $val_counts->{$k}++;
                $val_objects->{$k} //= $sols->{$k};
            }
        }
    }
    return;
}

sub _calculate_diagnostics ( $self, $chain_samples,
    $total_successes, $total_samples )
{
    my $num_chains = scalar @$chain_samples;
    my $n          = ( $num_chains > 0 ) ? scalar @{ $chain_samples->[0] } : 0;
    return ( 1.0, $total_samples, [], [] ) if $total_samples <= 0 || $n <= 0;

    if ( $num_chains == 1 ) {
        return $self->_single_chain_diagnostics( $chain_samples->[0],
            $total_successes, $n );
    }

    return $self->_multi_chain_diagnostics( $chain_samples, $num_chains, $n );
}

sub _single_chain_diagnostics ( $self, $samples, $successes, $n ) {
    my $mean = $successes / $n;
    my $s2 =
      ( $n > 1 ) ? ( ( $n / ( $n - 1 ) ) * $mean * ( 1.0 - $mean ) ) : 0.0;
    my $ess = $n;

    if ( $s2 > 1e-12 ) {
        my $sum_rho = 0.0;
        my $max_lag = ( $n < 50 ) ? int( $n / 2 ) : 50;
        for my $k ( 1 .. $max_lag ) {
            my $cov = 0.0;
            for my $i ( 0 .. $n - 1 - $k ) {
                $cov +=
                  ( $samples->[$i] - $mean ) *
                  ( $samples->[ $i + $k ] - $mean );
            }
            $cov /= ( $n - $k );
            my $rho_k = $cov / $s2;
            last if $rho_k <= 0.05;
            $sum_rho += $rho_k;
        }
        my $act = 1.0 + ( 2.0 * $sum_rho );
        $act = 1.0 if $act < 1.0;
        $ess = int( ( $n / $act ) + 0.5 );
        $ess = 1  if $ess < 1;
        $ess = $n if $ess > $n;
    }

    return ( 1.0, $ess, [$mean], [] );
}

sub _calculate_multi_chain_ess ( $self, $chain_samples, $overall_mean,
    $var_plus, $r_hat, $num_chains, $n )
{
    my $sum_rho = 0.0;
    my $max_lag = ( $n < 50 ) ? int( $n / 2 ) : 50;
    for my $k ( 1 .. $max_lag ) {
        my $cov_sum = 0.0;
        for my $c (@$chain_samples) {
            my $cov = 0.0;
            for my $i ( 0 .. $n - 1 - $k ) {
                $cov +=
                  ( $c->[$i] - $overall_mean ) *
                  ( $c->[ $i + $k ] - $overall_mean );
            }
            $cov     /= ( $n - $k );
            $cov_sum += $cov;
        }
        my $avg_cov = $cov_sum / $num_chains;
        my $rho_k   = $var_plus > 1e-12 ? ( $avg_cov / $var_plus ) : 0.0;
        last if $rho_k <= 0.05;
        $sum_rho += $rho_k;
    }

    my $act = 1.0 + ( 2.0 * $sum_rho );
    $act = 1.0 if $act < 1.0;
    my $ess = ( $num_chains * $n ) / ( $act * ( $r_hat**2 ) );
    $ess = 1                if $ess < 1;
    $ess = $num_chains * $n if $ess > $num_chains * $n;
    return int( $ess + 0.5 );
}

sub _multi_chain_diagnostics ( $self, $chain_samples, $num_chains, $n ) {
    my @chain_means;
    my $sum_means = 0.0;
    for my $chain (@$chain_samples) {
        my $s = 0;
        $s += $_ for @$chain;
        my $m = $s / $n;
        push @chain_means, $m;
        $sum_means += $m;
    }
    my $overall_mean = $sum_means / $num_chains;

    my $ss_b = 0.0;
    for my $m (@chain_means) {
        $ss_b += ( $m - $overall_mean )**2;
    }
    my $b = ( $n / ( $num_chains - 1 ) ) * $ss_b;

    my $ss_w = 0.0;
    for my $m (@chain_means) {
        my $var_m =
          ( $n > 1 ) ? ( ( $n / ( $n - 1 ) ) * $m * ( 1.0 - $m ) ) : 0.0;
        $ss_w += $var_m;
    }
    my $w = $ss_w / $num_chains;

    my ( $r_hat, $ess, @warnings );

    if ( $w <= 1e-12 && $b <= 1e-12 ) {
        $r_hat = 1.0;
        $ess   = $num_chains * $n;
    }
    elsif ( $w <= 1e-12 ) {
        $r_hat = 99.0;
        $ess   = 1;
        push @warnings,
"MCMC chains completely diverged into isolated modes (within-chain variance is zero, between-chain variance > 0).";
    }
    else {
        my $var_plus = ( ( $n - 1 ) / $n ) * $w + ( 1.0 / $n ) * $b;
        $r_hat = sqrt( $var_plus / $w );
        $ess =
          $self->_calculate_multi_chain_ess( $chain_samples, $overall_mean,
            $var_plus, $r_hat, $num_chains, $n );
    }

    if ( $r_hat > 1.05 ) {
        push @warnings,
          sprintf(
            "Chain convergence warning: R-hat (%.4f) exceeds threshold 1.05. "
              . "Chains may not have converged to the stationary distribution. "
              . "Results may be unreliable; consider increasing burn_in, lag, or samples.",
            $r_hat
          );
    }

    if ( $ess < 100 && ( $num_chains * $n ) >= 200 ) {
        push @warnings,
          sprintf(
"Low effective sample size warning: ESS (%d) is low relative to total samples (%d). "
              . "High autocorrelation detected; consider increasing lag.",
            $ess, $num_chains * $n );
    }

    return ( $r_hat, $ess, \@chain_means, \@warnings );
}

1;

__END__

=head1 NAME

Logic::Probabilistic::Inference::MCMC - Markov Chain Monte Carlo (Metropolis-Hastings) inference engine.

=head1 SYNOPSIS

    use Logic::Probabilistic::Inference::MCMC;

    my $mcmc = Logic::Probabilistic::Inference::MCMC->new(
        program => $prob_prog,
        chains  => 4,
        samples => 5000,
        burn_in => 500,
        lag     => 5,
    );
    my $result = $mcmc->query(query => 'burglary', evidence => ['alarm']);
    say "R-hat: " . $result->r_hat;
    say "ESS:   " . $result->ess;

=head1 DESCRIPTION

Samples from conditional distributions using the Metropolis-Hastings algorithm
with multi-chain execution, Gelman-Rubin convergence diagnostics (R-hat), and
Effective Sample Size (ESS) estimation.

=cut
