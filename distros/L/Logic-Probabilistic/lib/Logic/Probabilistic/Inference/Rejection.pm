package Logic::Probabilistic::Inference::Rejection;

use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';
use Carp         qw(croak);
use Scalar::Util qw(blessed);
use parent 'Logic::Probabilistic::Inference::Base';

our $VERSION         = '0.01';
our $DEFAULT_SAMPLES = 1000;

sub new ( $class, %args ) {
    my $self = $class->SUPER::new(%args);
    $self->{samples}         //= $DEFAULT_SAMPLES;
    $self->{max_attempts}    //= 100_000;
    $self->{target_accepted} //= 0;
    $self->{timeout} = $args{timeout};
    return $self;
}

sub samples         ($self) { return $self->{samples}; }
sub max_attempts    ($self) { return $self->{max_attempts}; }
sub target_accepted ($self) { return $self->{target_accepted}; }
sub timeout         ($self) { return $self->{timeout}; }

sub _sample_active_clauses ( $self, $pfacts, $pchoices ) {
    my %active_clauses;

    for my $pf (@$pfacts) {
        if ( rand() < $pf->probability ) {
            $active_clauses{ $pf->key } =
              [ @{ $active_clauses{ $pf->key } // [] }, $pf->clause ];
        }
    }

    for my $pc (@$pchoices) {
        my $r   = rand();
        my $cum = 0.0;
        for my $out ( $pc->outcomes ) {
            $cum += $out->{probability};
            if ( $r < $cum ) {
                $active_clauses{ $out->{key} } =
                  [ @{ $active_clauses{ $out->{key} } // [] }, $out->{clause} ];
                last;
            }
        }
    }

    return \%active_clauses;
}

sub query ( $self, %args ) {
    my $raw_query    = $args{query}    // croak "query is required";
    my $raw_evidence = $args{evidence} // $args{given} // [];

    my $query_goal     = $self->program->normalize_goal($raw_query);
    my $evidence_goals = $self->_normalize_goals($raw_evidence);

    my $num_samples  = $args{samples}         // $self->{samples};
    my $max_attempts = $args{max_attempts}    // $self->{max_attempts};
    my $target_acc   = $args{target_accepted} // $self->{target_accepted};

    if ( defined $args{seed} ) {
        srand( $args{seed} );
    }

    my @pfacts   = $self->program->all_pfacts;
    my @pchoices = $self->program->all_pchoices;

    require Logic::Probabilistic::Result;

    my $rel_prog   = $self->program->relational_program;
    my $generators = $rel_prog->{generators} // {};

    my $total_draws         = 0;
    my $accepted_samples    = 0;
    my $query_success_count = 0;

    my $timeout = $args{timeout} // $self->timeout;
    my $deadline =
      ( defined $timeout && $timeout > 0 ) ? ( time() + $timeout ) : undef;
    my $timed_out = 0;

    my $should_continue = sub {
        if ($target_acc) {
            return ( $accepted_samples < $num_samples
                  && $total_draws < $max_attempts );
        }
        return ( $total_draws < $num_samples );
    };

    while ( $should_continue->() ) {
        if ( $deadline && ( $total_draws & 63 ) == 0 && time() > $deadline ) {
            $timed_out = 1;
            last;
        }
        $total_draws++;

        my $active_clauses =
          $self->_sample_active_clauses( \@pfacts, \@pchoices );
        my $world_preds =
          $self->program->build_world_predicates($active_clauses);

        next
          unless $self->_check_evidence( $rel_prog, $evidence_goals,
            $world_preds, $generators );

        $accepted_samples++;

        if (
            $self->_check_query(
                $rel_prog, $query_goal, $world_preds, $generators
            )
          )
        {
            $query_success_count++;
        }
    }

    if ( $timed_out && $accepted_samples == 0 ) {
        croak "Rejection sampling exceeded timeout of " . $timeout
          . " seconds before accepting any samples satisfying the evidence";
    }

    if ( @$evidence_goals && $accepted_samples == 0 ) {
        croak "No samples satisfied the evidence after $total_draws attempts"
          . " (evidence may be impossible or extremely rare)";
    }

    my $prob =
      $accepted_samples > 0
      ? ( $query_success_count / $accepted_samples )
      : 0.0;

    my $ev_prob =
      $total_draws > 0
      ? ( $accepted_samples / $total_draws )
      : 0.0;

    return Logic::Probabilistic::Result->new(
        probability          => $prob,
        evidence_probability => $ev_prob,
        method               => 'rejection',
        total_samples        => $total_draws,
        accepted_samples     => $accepted_samples,
        query_success_count  => $query_success_count,
        metadata             => {
            acceptance_rate => (
                $total_draws > 0 ? ( $accepted_samples / $total_draws ) : 0
            ),
            ( $timed_out ? ( timed_out => 1 ) : () ),
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

    my $num_samples  = $args{samples}         // $self->{samples};
    my $max_attempts = $args{max_attempts}    // $self->{max_attempts};
    my $target_acc   = $args{target_accepted} // $self->{target_accepted};

    if ( defined $args{seed} ) {
        srand( $args{seed} );
    }

    my @pfacts   = $self->program->all_pfacts;
    my @pchoices = $self->program->all_pchoices;

    require Logic::Probabilistic::Distribution;

    my $rel_prog   = $self->program->relational_program;
    my $generators = $rel_prog->{generators} // {};

    my $total_draws      = 0;
    my $accepted_samples = 0;
    my %val_counts;
    my %val_objects;

    my $timeout = $args{timeout} // $self->timeout;
    my $deadline =
      ( defined $timeout && $timeout > 0 ) ? ( time() + $timeout ) : undef;
    my $timed_out = 0;

    my $should_continue = sub {
        if ($target_acc) {
            return ( $accepted_samples < $num_samples
                  && $total_draws < $max_attempts );
        }
        return ( $total_draws < $num_samples );
    };

    while ( $should_continue->() ) {
        if ( $deadline && ( $total_draws & 63 ) == 0 && time() > $deadline ) {
            $timed_out = 1;
            last;
        }
        $total_draws++;

        my $active_clauses =
          $self->_sample_active_clauses( \@pfacts, \@pchoices );
        my $world_preds =
          $self->program->build_world_predicates($active_clauses);

        next
          unless $self->_check_evidence( $rel_prog, $evidence_goals,
            $world_preds, $generators );

        $accepted_samples++;

        $self->_record_sample_values(
            $rel_prog,   $query_goal,  $world_preds, $generators,
            $target_var, \%val_counts, \%val_objects
        );
    }

    if ( $timed_out && $accepted_samples == 0 ) {
        croak "Rejection sampling exceeded timeout of " . $timeout
          . " seconds before accepting any samples satisfying the evidence";
    }

    if ( @$evidence_goals && $accepted_samples == 0 ) {
        croak "No samples satisfied the evidence after $total_draws attempts"
          . " (evidence may be impossible or extremely rare)";
    }

    my %probs;
    if ( $accepted_samples > 0 ) {
        for my $k ( keys %val_counts ) {
            $probs{$k} = $val_counts{$k} / $accepted_samples;
        }
    }

    my $ev_prob =
      $total_draws > 0
      ? ( $accepted_samples / $total_draws )
      : 0.0;

    return Logic::Probabilistic::Distribution->new(
        probabilities        => \%probs,
        val_map              => \%val_objects,
        evidence_probability => $ev_prob,
        method               => 'rejection',
        total_samples        => $total_draws,
        accepted_samples     => $accepted_samples,
        counts               => \%val_counts,
        metadata             => {
            acceptance_rate => (
                $total_draws > 0 ? ( $accepted_samples / $total_draws ) : 0
            ),
            ( $timed_out ? ( timed_out => 1 ) : () ),
        },
    );
}

sub _record_sample_values (
    $self,       $rel_prog,   $query_goal, $world_preds,
    $generators, $target_var, $val_counts, $val_objects
  )
{
    require Logic::Relational::Query;
    my $q = Logic::Relational::Query->new(
        program    => $rel_prog,
        goals      => [$query_goal],
        predicates => $world_preds,
        generators => $generators,
    );

    my %seen_in_sample;
    while ( my $sol = $q->next ) {
        my $val = $sol->value($target_var);
        my $key = $self->_val_to_key($val);
        $seen_in_sample{$key} = $val;
    }

    for my $k ( keys %seen_in_sample ) {
        $val_counts->{$k}++;
        $val_objects->{$k} //= $seen_in_sample{$k};
    }
    return;
}

1;

__END__

=head1 NAME

Logic::Probabilistic::Inference::Rejection - Monte Carlo rejection sampling inference engine.

=head1 SYNOPSIS

    use Logic::Probabilistic::Inference::Rejection;

    my $sampler = Logic::Probabilistic::Inference::Rejection->new(
        program => $prob_prog,
        samples => 10_000,
    );
    my $result = $sampler->query(query => 'burglary', evidence => ['alarm']);

=head1 DESCRIPTION

Generates forward samples of possible worlds and rejects samples that violate observed evidence.
Approximates marginal and conditional probabilities with statistical confidence intervals.

=cut
