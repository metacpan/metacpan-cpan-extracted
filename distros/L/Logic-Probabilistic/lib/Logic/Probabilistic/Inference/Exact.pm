package Logic::Probabilistic::Inference::Exact;

use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';
use Carp         qw(croak);
use Scalar::Util qw(blessed);
use parent 'Logic::Probabilistic::Inference::Base';

our $VERSION            = '0.01';
our $DEFAULT_MAX_WORLDS = 4096;

sub new ( $class, %args ) {
    my $self = $class->SUPER::new(%args);
    $self->{max_worlds} =
      exists $args{max_worlds} ? $args{max_worlds} : $DEFAULT_MAX_WORLDS;
    $self->{timeout} = $args{timeout};
    return $self;
}

sub max_worlds ($self) { return $self->{max_worlds}; }
sub timeout    ($self) { return $self->{timeout}; }

sub _calculate_world_count ( $self, $pfacts, $pchoices ) {
    my $num_worlds = 1;
    for my $pf (@$pfacts) {
        $num_worlds *= 2;
    }
    for my $pc (@$pchoices) {
        my $num_outs = scalar( $pc->outcomes );
        $num_outs++ if $pc->null_prob > 0;
        $num_worlds *= $num_outs;
    }
    return $num_worlds;
}

sub _build_all_vars ( $self, $pfacts, $pchoices ) {
    return [
        ( map { { type => 'pfact',   var => $_, id => $_->id } } @$pfacts ),
        ( map { { type => 'pchoice', var => $_, id => $_->id } } @$pchoices ),
    ];
}

sub _build_target_ids ( $self, $all_vars ) {
    my %ids;
    for my $v (@$all_vars) {
        if ( $v->{type} eq 'pfact' ) {
            $ids{ $v->{id} } = 1;
        }
        else {
            my $pc = $v->{var};
            for my $out ( $pc->outcomes ) {
                my $out_val = $out->{value};
                my $val_str =
                  ref($out_val) eq 'ARRAY'
                  ? join( ',', @$out_val )
                  : "$out_val";
                $ids{ $pc->predicate . "($val_str)" } = 1;
            }
        }
    }
    return \%ids;
}

sub _compute_world_derivs ( $self, $all_vars, $factors, $decisions ) {
    my $n_vars = scalar(@$all_vars);
    my @prefix = (1.0);
    for ( my $i = 0 ; $i < $n_vars - 1 ; $i++ ) {
        $prefix[ $i + 1 ] = $prefix[$i] * $factors->[$i];
    }

    my @suffix;
    $suffix[ $n_vars - 1 ] = 1.0;
    for ( my $i = $n_vars - 1 ; $i > 0 ; $i-- ) {
        $suffix[ $i - 1 ] = $suffix[$i] * $factors->[$i];
    }

    my %world_derivs;
    for ( my $k = 0 ; $k < $n_vars ; $k++ ) {
        my $other_prod = $prefix[$k] * $suffix[$k];
        my $item       = $all_vars->[$k];

        if ( $item->{type} eq 'pfact' ) {
            my $var_id = $item->{id};
            $world_derivs{$var_id} =
              ( $decisions->[$k] ? 1.0 : -1.0 ) * $other_prod;
        }
        else {
            my $pc         = $item->{var};
            my $chosen_idx = $decisions->[$k];
            my @outs       = $pc->outcomes;
            if ( $chosen_idx >= 0 ) {
                my $out_val = $outs[$chosen_idx]{value};
                my $val_str =
                  ref($out_val) eq 'ARRAY'
                  ? join( ',', @$out_val )
                  : "$out_val";
                my $out_id = $pc->predicate . "($val_str)";
                $world_derivs{$out_id} = 1.0 * $other_prod;
            }
            else {
                for my $out (@outs) {
                    my $out_val = $out->{value};
                    my $val_str =
                      ref($out_val) eq 'ARRAY'
                      ? join( ',', @$out_val )
                      : "$out_val";
                    my $out_id = $pc->predicate . "($val_str)";
                    $world_derivs{$out_id} = -1.0 * $other_prod;
                }
            }
        }
    }

    return \%world_derivs;
}

sub _process_world_gradient (
    $self,           $world_prob, $active_clauses, $factors,
    $decisions,      $all_vars,   $rel_prog,       $generators,
    $evidence_goals, $query_goal, $state
  )
{
    my $world_preds = $self->program->build_world_predicates($active_clauses);
    return
      unless $self->_check_evidence( $rel_prog, $evidence_goals,
        $world_preds, $generators );

    $state->{accepted_worlds}++;
    $state->{total_evidence_weight} += $world_prob;

    my $world_derivs =
      $self->_compute_world_derivs( $all_vars, $factors, $decisions );

    for my $var_id ( keys %$world_derivs ) {
        $state->{grad_E}{$var_id} += $world_derivs->{$var_id};
    }

    if (
        $self->_check_query(
            $rel_prog, $query_goal, $world_preds, $generators
        )
      )
    {
        $state->{query_success_weight} += $world_prob;
        $state->{query_success_count}++;
        for my $var_id ( keys %$world_derivs ) {
            $state->{grad_QE}{$var_id} += $world_derivs->{$var_id};
        }
    }
    return;
}

sub _recurse_gradients (
    $self,       $var_idx,        $world_prob, $active_clauses,
    $factors,    $decisions,      $all_vars,   $rel_prog,
    $generators, $evidence_goals, $query_goal, $state
  )
{
    if ( $var_idx >= scalar(@$all_vars) ) {
        $state->{evaluated_worlds}++;
        if ( $state->{deadline} && ( $state->{evaluated_worlds} & 255 ) == 0 ) {
            if ( time() > $state->{deadline} ) {
                croak "Exact inference exceeded timeout of "
                  . $state->{timeout}
                  . " seconds after evaluating "
                  . $state->{evaluated_worlds}
                  . " worlds";
            }
        }
        $self->_process_world_gradient(
            $world_prob, $active_clauses, $factors,    $decisions,
            $all_vars,   $rel_prog,       $generators, $evidence_goals,
            $query_goal, $state
        );
        return;
    }

    my $entry = $all_vars->[$var_idx];
    if ( $entry->{type} eq 'pfact' ) {
        my $pf = $entry->{var};
        my $p  = $pf->probability;

        my %true_clauses = %$active_clauses;
        $true_clauses{ $pf->key } =
          [ @{ $true_clauses{ $pf->key } // [] }, $pf->clause ];

        $self->_recurse_gradients(
            $var_idx + 1,       $world_prob * $p,
            \%true_clauses,     [ @$factors, $p ],
            [ @$decisions, 1 ], $all_vars,
            $rel_prog,          $generators,
            $evidence_goals,    $query_goal,
            $state
        );

        $self->_recurse_gradients(
            $var_idx + 1,       $world_prob * ( 1.0 - $p ),
            $active_clauses,    [ @$factors, 1.0 - $p ],
            [ @$decisions, 0 ], $all_vars,
            $rel_prog,          $generators,
            $evidence_goals,    $query_goal,
            $state
        );
    }
    else {
        my $pc  = $entry->{var};
        my $idx = 0;
        for my $out ( $pc->outcomes ) {
            my %out_clauses = %$active_clauses;
            $out_clauses{ $out->{key} } =
              [ @{ $out_clauses{ $out->{key} } // [] }, $out->{clause} ];

            $self->_recurse_gradients(
                $var_idx + 1,          $world_prob * $out->{probability},
                \%out_clauses,         [ @$factors, $out->{probability} ],
                [ @$decisions, $idx ], $all_vars,
                $rel_prog,             $generators,
                $evidence_goals,       $query_goal,
                $state
            );
            $idx++;
        }

        if ( $pc->null_prob > 0.0 ) {
            $self->_recurse_gradients(
                $var_idx + 1,        $world_prob * $pc->null_prob,
                $active_clauses,     [ @$factors, $pc->null_prob ],
                [ @$decisions, -1 ], $all_vars,
                $rel_prog,           $generators,
                $evidence_goals,     $query_goal,
                $state
            );
        }
    }
    return;
}

sub _recurse_fast (
    $self,       $var_idx,  $world_prob, $active_clauses,
    $all_vars,   $rel_prog, $generators, $evidence_goals,
    $query_goal, $state
  )
{
    if ( $var_idx >= scalar(@$all_vars) ) {
        $state->{evaluated_worlds}++;
        if ( $state->{deadline} && ( $state->{evaluated_worlds} & 255 ) == 0 ) {
            if ( time() > $state->{deadline} ) {
                croak "Exact inference exceeded timeout of "
                  . $state->{timeout}
                  . " seconds after evaluating "
                  . $state->{evaluated_worlds}
                  . " worlds";
            }
        }
        return if $world_prob <= 0.0;

        my $world_preds =
          $self->program->build_world_predicates($active_clauses);
        return
          unless $self->_check_evidence( $rel_prog, $evidence_goals,
            $world_preds, $generators );

        $state->{accepted_worlds}++;
        $state->{total_evidence_weight} += $world_prob;

        if (
            $self->_check_query(
                $rel_prog, $query_goal, $world_preds, $generators
            )
          )
        {
            $state->{query_success_weight} += $world_prob;
            $state->{query_success_count}++;
        }
        return;
    }

    my $entry = $all_vars->[$var_idx];
    if ( $entry->{type} eq 'pfact' ) {
        my $pf = $entry->{var};
        my $p  = $pf->probability;

        if ( $p > 0.0 ) {
            my %new_clauses = %$active_clauses;
            $new_clauses{ $pf->key } =
              [ @{ $new_clauses{ $pf->key } // [] }, $pf->clause ];
            $self->_recurse_fast(
                $var_idx + 1,    $world_prob * $p, \%new_clauses,
                $all_vars,       $rel_prog,        $generators,
                $evidence_goals, $query_goal,      $state
            );
        }
        if ( ( 1.0 - $p ) > 0.0 ) {
            $self->_recurse_fast(
                $var_idx + 1,    $world_prob * ( 1.0 - $p ),
                $active_clauses, $all_vars,
                $rel_prog,       $generators,
                $evidence_goals, $query_goal,
                $state
            );
        }
    }
    else {
        my $pc = $entry->{var};
        for my $out ( $pc->outcomes ) {
            next if $out->{probability} <= 0.0;
            my %new_clauses = %$active_clauses;
            $new_clauses{ $out->{key} } =
              [ @{ $new_clauses{ $out->{key} } // [] }, $out->{clause} ];
            $self->_recurse_fast(
                $var_idx + 1,    $world_prob * $out->{probability},
                \%new_clauses,   $all_vars,
                $rel_prog,       $generators,
                $evidence_goals, $query_goal,
                $state
            );
        }
        if ( $pc->null_prob > 0.0 ) {
            $self->_recurse_fast(
                $var_idx + 1,    $world_prob * $pc->null_prob,
                $active_clauses, $all_vars,
                $rel_prog,       $generators,
                $evidence_goals, $query_goal,
                $state
            );
        }
    }
    return;
}

sub _finalize_probabilities ( $self, $has_evidence, $state ) {
    my $final_prob;
    if ($has_evidence) {
        croak
"Zero probability evidence: evidence cannot be satisfied in any possible world"
          if $state->{total_evidence_weight} <= 0.0;
        $final_prob =
          $state->{query_success_weight} / $state->{total_evidence_weight};
    }
    else {
        $final_prob = $state->{query_success_weight};
        $state->{total_evidence_weight} = 1.0;
    }

    $final_prob = 1.0 if $final_prob > 1.0;
    $final_prob = 0.0 if $final_prob < 0.0;

    return $final_prob;
}

sub _compute_final_gradients ( $self, $has_evidence, $target_ids, $state ) {
    my %final_gradients;
    if ($has_evidence) {
        my $w_e    = $state->{total_evidence_weight};
        my $w_qe   = $state->{query_success_weight};
        my $w_e_sq = $w_e * $w_e;

        for my $var_id ( keys %$target_ids ) {
            my $g_qe = $state->{grad_QE}{$var_id} // 0.0;
            my $g_e  = $state->{grad_E}{$var_id}  // 0.0;
            $final_gradients{$var_id} =
              $w_e_sq > 0.0
              ? ( ( $g_qe * $w_e - $w_qe * $g_e ) / $w_e_sq )
              : 0.0;
        }
    }
    else {
        for my $var_id ( keys %$target_ids ) {
            $final_gradients{$var_id} = $state->{grad_QE}{$var_id} // 0.0;
        }
    }
    return \%final_gradients;
}

sub query ( $self, %args ) {
    my $raw_query    = $args{query}    // croak "query is required";
    my $raw_evidence = $args{evidence} // $args{given} // [];

    my $query_goal     = $self->program->normalize_goal($raw_query);
    my $evidence_goals = $self->_normalize_goals($raw_evidence);

    my @pfacts     = $self->program->all_pfacts;
    my @pchoices   = $self->program->all_pchoices;
    my $num_worlds = $self->_calculate_world_count( \@pfacts, \@pchoices );

    my $max_worlds =
      exists $args{max_worlds} ? $args{max_worlds} : $self->max_worlds;

    if ( defined $max_worlds && $max_worlds > 0 && $num_worlds > $max_worlds ) {
        croak
"Model has $num_worlds possible worlds, which exceeds exact inference limit of $max_worlds. "
          . "To proceed with exact enumeration, specify 'max_worlds => $num_worlds' (or max_worlds => 0 for unlimited). "
          . "Alternatively, use Monte Carlo sampling instead (e.g. method => 'rejection').";
    }

    require Logic::Probabilistic::Result;

    my $with_gradients = $args{with_gradients} // $args{gradients} // 0;
    my $rel_prog       = $self->program->relational_program;
    my $generators     = $rel_prog->{generators} // {};
    my $all_vars       = $self->_build_all_vars( \@pfacts, \@pchoices );
    my $target_ids     = $self->_build_target_ids($all_vars);

    my $timeout = $args{timeout} // $self->timeout;
    my $deadline =
      ( defined $timeout && $timeout > 0 ) ? ( time() + $timeout ) : undef;

    my %state = (
        total_evidence_weight => 0.0,
        query_success_weight  => 0.0,
        evaluated_worlds      => 0,
        accepted_worlds       => 0,
        query_success_count   => 0,
        grad_E                => {},
        grad_QE               => {},
        deadline              => $deadline,
        timeout               => $timeout,
    );

    if ($with_gradients) {
        $self->_recurse_gradients( 0, 1.0, {}, [], [],
            $all_vars, $rel_prog, $generators, $evidence_goals, $query_goal,
            \%state );
    }
    else {
        $self->_recurse_fast(
            0, 1.0, {}, $all_vars,
            $rel_prog, $generators, $evidence_goals, $query_goal,
            \%state
        );
    }

    my $has_evidence = scalar(@$evidence_goals) > 0 ? 1 : 0;
    my $final_prob   = $self->_finalize_probabilities( $has_evidence, \%state );

    my %meta = ( evaluated_worlds => $state{evaluated_worlds} );
    if ($with_gradients) {
        $meta{gradients} =
          $self->_compute_final_gradients( $has_evidence, $target_ids,
            \%state );
    }

    return Logic::Probabilistic::Result->new(
        probability          => $final_prob,
        evidence_probability => $state{total_evidence_weight},
        method               => 'exact',
        total_samples        => $num_worlds,
        accepted_samples     => $state{accepted_worlds},
        query_success_count  => $state{query_success_count},
        metadata             => \%meta,
    );
}

sub _recurse_distribution (
    $self,       $var_idx,    $world_prob, $active_clauses,
    $all_vars,   $rel_prog,   $generators, $evidence_goals,
    $query_goal, $target_var, $state
  )
{
    if ( $var_idx >= scalar(@$all_vars) ) {
        $state->{evaluated_worlds}++;
        if ( $state->{deadline} && ( $state->{evaluated_worlds} & 255 ) == 0 ) {
            if ( time() > $state->{deadline} ) {
                croak "Exact inference exceeded timeout of "
                  . $state->{timeout}
                  . " seconds after evaluating "
                  . $state->{evaluated_worlds}
                  . " worlds";
            }
        }
        return if $world_prob <= 0.0;

        my $world_preds =
          $self->program->build_world_predicates($active_clauses);
        return
          unless $self->_check_evidence( $rel_prog, $evidence_goals,
            $world_preds, $generators );

        $state->{accepted_worlds}++;
        $state->{total_evidence_weight} += $world_prob;

        require Logic::Relational::Query;
        my $q = Logic::Relational::Query->new(
            program    => $rel_prog,
            goals      => [$query_goal],
            predicates => $world_preds,
            generators => $generators,
        );

        my %seen_in_world;
        while ( my $sol = $q->next ) {
            my $val = $sol->value($target_var);
            my $key = $self->_val_to_key($val);
            $seen_in_world{$key} = $val;
        }

        for my $k ( keys %seen_in_world ) {
            $state->{val_weights}{$k} += $world_prob;
            $state->{val_objects}{$k} //= $seen_in_world{$k};
        }
        return;
    }

    my $entry = $all_vars->[$var_idx];
    if ( $entry->{type} eq 'pfact' ) {
        my $pf = $entry->{var};
        my $p  = $pf->probability;

        if ( $p > 0.0 ) {
            my %new_clauses = %$active_clauses;
            $new_clauses{ $pf->key } =
              [ @{ $new_clauses{ $pf->key } // [] }, $pf->clause ];
            $self->_recurse_distribution(
                $var_idx + 1,    $world_prob * $p, \%new_clauses,
                $all_vars,       $rel_prog,        $generators,
                $evidence_goals, $query_goal,      $target_var,
                $state
            );
        }
        if ( ( 1.0 - $p ) > 0.0 ) {
            $self->_recurse_distribution(
                $var_idx + 1,    $world_prob * ( 1.0 - $p ),
                $active_clauses, $all_vars,
                $rel_prog,       $generators,
                $evidence_goals, $query_goal,
                $target_var,     $state
            );
        }
    }
    else {
        my $pc = $entry->{var};
        for my $out ( $pc->outcomes ) {
            next if $out->{probability} <= 0.0;
            my %new_clauses = %$active_clauses;
            $new_clauses{ $out->{key} } =
              [ @{ $new_clauses{ $out->{key} } // [] }, $out->{clause} ];
            $self->_recurse_distribution(
                $var_idx + 1,    $world_prob * $out->{probability},
                \%new_clauses,   $all_vars,
                $rel_prog,       $generators,
                $evidence_goals, $query_goal,
                $target_var,     $state
            );
        }
        if ( $pc->null_prob > 0.0 ) {
            $self->_recurse_distribution(
                $var_idx + 1,    $world_prob * $pc->null_prob,
                $active_clauses, $all_vars,
                $rel_prog,       $generators,
                $evidence_goals, $query_goal,
                $target_var,     $state
            );
        }
    }
    return;
}

sub query_distribution ( $self, %args ) {
    my $raw_query    = $args{query}    // croak "query is required";
    my $raw_evidence = $args{evidence} // $args{given} // [];

    if ( !ref($raw_query) && defined $args{var} ) {
        my $var = $args{var};
        if ( blessed($var) && $var->isa('Logic::Relational::Variable') ) {
            require Logic::Relational::Goal::Call;
            $raw_query =
              Logic::Relational::Goal::Call->new( $raw_query, [$var] );
        }
    }

    my $query_goal     = $self->program->normalize_goal($raw_query);
    my $evidence_goals = $self->_normalize_goals($raw_evidence);
    my $target_var     = $self->_resolve_target_var( $query_goal, $args{var} );

    my @pfacts     = $self->program->all_pfacts;
    my @pchoices   = $self->program->all_pchoices;
    my $num_worlds = $self->_calculate_world_count( \@pfacts, \@pchoices );

    my $max_worlds =
      exists $args{max_worlds} ? $args{max_worlds} : $self->max_worlds;

    if ( defined $max_worlds && $max_worlds > 0 && $num_worlds > $max_worlds ) {
        croak
"Model has $num_worlds possible worlds, which exceeds exact inference limit of $max_worlds. "
          . "To proceed with exact enumeration, specify 'max_worlds => $num_worlds' (or max_worlds => 0 for unlimited). "
          . "Alternatively, use Monte Carlo sampling instead (e.g. method => 'rejection').";
    }

    require Logic::Probabilistic::Distribution;

    my $rel_prog   = $self->program->relational_program;
    my $generators = $rel_prog->{generators} // {};
    my $all_vars   = $self->_build_all_vars( \@pfacts, \@pchoices );

    my $timeout = $args{timeout} // $self->timeout;
    my $deadline =
      ( defined $timeout && $timeout > 0 ) ? ( time() + $timeout ) : undef;

    my %state = (
        total_evidence_weight => 0.0,
        val_weights           => {},
        val_objects           => {},
        evaluated_worlds      => 0,
        accepted_worlds       => 0,
        deadline              => $deadline,
        timeout               => $timeout,
    );

    $self->_recurse_distribution(
        0,           1.0, {},     $all_vars,
        $rel_prog,   $generators, $evidence_goals, $query_goal,
        $target_var, \%state
    );

    my $has_evidence = scalar(@$evidence_goals) > 0 ? 1 : 0;
    if ($has_evidence) {
        croak
"Zero probability evidence: evidence cannot be satisfied in any possible world"
          if $state{total_evidence_weight} <= 0.0;
    }
    else {
        $state{total_evidence_weight} = 1.0;
    }

    my $w_e = $state{total_evidence_weight};
    my %probs;
    for my $k ( keys %{ $state{val_weights} } ) {
        $probs{$k} = $state{val_weights}{$k} / $w_e;
    }

    return Logic::Probabilistic::Distribution->new(
        probabilities        => \%probs,
        val_map              => $state{val_objects},
        evidence_probability => ( $has_evidence ? $w_e : 1.0 ),
        method               => 'exact',
        total_samples        => $num_worlds,
        accepted_samples     => $state{accepted_worlds},
        metadata => { evaluated_worlds => $state{evaluated_worlds} },
    );
}

1;

__END__

=head1 NAME

Logic::Probabilistic::Inference::Exact - Exact possible world enumeration solver with analytical gradients.

=head1 SYNOPSIS

    use Logic::Probabilistic::Inference::Exact;

    my $exact = Logic::Probabilistic::Inference::Exact->new(program => $prob_prog);

    # Standard forward inference
    my $result = $exact->query(query => 'burglary', evidence => ['alarm']);
    say "P(burglary | alarm) = " . $result->probability;

    # Differentiable inference with analytical gradients
    my $diff_result = $exact->query(
        query          => 'burglary',
        evidence       => ['alarm'],
        with_gradients => 1,
    );

    my $dP_dearthquake = $diff_result->gradient('earthquake');
    say "dP/d(earthquake) = $dP_dearthquake";

=head1 DESCRIPTION

Enumerates all possible worlds and computes exact marginal and conditional
probabilities under the Distribution Semantics.

When requested via C<with_gradients =E<gt> 1> (or C<gradients =E<gt> 1>), calculates
exact analytical partial derivatives C<dP(Q | E) / dp_i> for every probabilistic fact
and choice outcome in the program. This enables neurosymbolic backpropagation and
parameter learning via gradient descent.

=head1 METHODS

=over 4

=item C<max_worlds>

Returns the maximum number of worlds allowed for exact enumeration before croaking (default: 65,536).

=item C<query(%args)>

Executes exact inference for a given query and optional evidence goals.
Arguments:

=over 4

=item * C<query> (required): Predicate name or goal term.

=item * C<evidence> or C<given> (optional): Arrayref of conditioning evidence goals.

=item * C<with_gradients> (optional): Boolean flag. If true, computes exact partial derivatives for all facts and choices.

=back

=back

=cut
