package Logic::Probabilistic::Result;

use v5.38;
use experimental 'signatures';
use Carp qw(croak);

use Scalar::Util qw(blessed);

our $VERSION = '0.01';

use overload
  '""'     => sub ( $self, $, $ ) { $self->to_string },
  '0+'     => sub ( $self, $, $ ) { $self->probability },
  fallback => 1;

sub new ( $class, %args ) {
    my $prob = $args{probability} // croak "probability is required";
    my $meth = $args{method}      // 'exact';

    my $self = {
        probability          => 0.0 + $prob,
        evidence_probability => exists $args{evidence_probability}
        ? 0.0 + $args{evidence_probability}
        : 1.0,
        method              => $meth,
        total_samples       => $args{total_samples} // $args{world_count} // 0,
        accepted_samples    => $args{accepted_samples}    // 0,
        query_success_count => $args{query_success_count} // 0,
        metadata            => $args{metadata}            // {},
    };

    return bless $self, $class;
}

sub probability          ($self) { return $self->{probability}; }
sub evidence_probability ($self) { return $self->{evidence_probability}; }
sub method               ($self) { return $self->{method}; }                 ## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub inference_method     ($self) { return $self->{method}; }
sub total_samples        ($self) { return $self->{total_samples}; }
sub world_count          ($self) { return $self->{total_samples}; }
sub accepted_samples     ($self) { return $self->{accepted_samples}; }
sub query_success_count  ($self) { return $self->{query_success_count}; }
sub metadata             ($self) { return $self->{metadata}; }

sub gradients ($self) {
    return $self->{metadata}{gradients} // {};
}

sub has_gradients ($self) {
    return keys %{ $self->gradients } ? 1 : 0;
}

sub gradient ( $self, $target ) {
    my $grads = $self->gradients;
    return 0.0 unless keys %$grads;

    if ( blessed($target) ) {
        if ( $target->can('id') ) {
            my $id = $target->id;
            return $grads->{$id} if exists $grads->{$id};
        }
        if ( $target->can('predicate') ) {
            my $pred = $target->predicate;
            return $grads->{$pred} if exists $grads->{$pred};
        }
    }
    elsif ( !ref($target) ) {
        return $grads->{$target} if exists $grads->{$target};
        my $canonical = $target;
        $canonical =~ tr/ \t\r\n//d;
        return $grads->{$canonical} if exists $grads->{$canonical};
    }

    return 0.0;
}

sub r_hat ($self) {
    return $self->{metadata}{r_hat};
}

sub ess ($self) {
    return $self->{metadata}{ess} // $self->{accepted_samples};
}

sub chains ($self) {
    return $self->{metadata}{chains} // 1;
}

sub warnings ($self) {
    return @{ $self->{metadata}{warnings} // [] };
}

sub is_converged ( $self, $threshold = 1.05 ) {
    return 1 if $self->{method} ne 'mcmc';
    my $r = $self->r_hat;
    return 1 unless defined $r;
    return ( $r <= $threshold ) ? 1 : 0;
}

# Wilson score interval calculation
sub ci ( $self, $level = 0.95 ) {
    if ( $self->{method} eq 'exact' ) {
        return ( $self->{probability}, $self->{probability} );
    }

    # For MCMC, use Effective Sample Size (ESS) if available to avoid
    # artificially narrow confidence intervals due to autocorrelation
    my $n =
      ( $self->{method} eq 'mcmc' && defined $self->{metadata}{ess} )
      ? $self->{metadata}{ess}
      : $self->{accepted_samples};

    return ( $self->{probability}, $self->{probability} ) if $n <= 0;

    my $p = $self->{probability};

    my $z = 1.95996;    # 95% default
    if    ( $level == 0.90 ) { $z = 1.64485; }
    elsif ( $level == 0.98 ) { $z = 2.32635; }
    elsif ( $level == 0.99 ) { $z = 2.57583; }

    my $z2     = $z * $z;
    my $denom  = 1.0 + ( $z2 / $n );
    my $center = ( $p + ( $z2 / ( 2.0 * $n ) ) ) / $denom;
    my $margin =
      ( $z * sqrt( ( $p * ( 1.0 - $p ) / $n ) + ( $z2 / ( 4.0 * $n * $n ) ) ) )
      / $denom;

    my $low  = $center - $margin;
    my $high = $center + $margin;

    $low  = 0.0 if $low < 0.0;
    $high = 1.0 if $high > 1.0;

    return ( $low, $high );
}

sub ci_low ( $self, $level = 0.95 ) {
    my ($low) = $self->ci($level);
    return $low;
}

sub ci_high ( $self, $level = 0.95 ) {
    my ( undef, $high ) = $self->ci($level);
    return $high;
}

sub to_string ($self) {
    my $p_str = sprintf( "%.4f", $self->{probability} );
    if ( $self->{method} eq 'exact' ) {
        return "P = $p_str (Exact, " . $self->{total_samples} . " worlds)";
    }

    my ( $low, $high ) = $self->ci(0.95);

    if ( $self->{method} eq 'mcmc' ) {
        my $chains            = $self->chains;
        my $samples_per_chain = $self->{metadata}{samples_per_chain}
          // int( $self->{total_samples} / ( $chains || 1 ) );
        my $r_hat = $self->r_hat;
        my $ess   = $self->ess;

        my $diag_str = "";
        if ( defined $r_hat && defined $ess ) {
            $diag_str = sprintf( ", R-hat = %.2f, ESS = %d", $r_hat, $ess );
        }

        my $warn_str = "";
        if ( !$self->is_converged ) {
            $warn_str =
              sprintf( " [WARNING: unconverged, R-hat = %.2f > 1.05]", $r_hat );
        }

        return
          sprintf(
            "P = %s [95%% CI: %.4f .. %.4f] (%d chains x %d samples%s, mcmc)%s",
            $p_str, $low, $high, $chains, $samples_per_chain, $diag_str,
            $warn_str );
    }

    return sprintf(
        "P = %s [95%% CI: %.4f .. %.4f] (%d samples, %s)",
        $p_str, $low, $high, $self->{total_samples},
        $self->{method}
    );
}

1;

__END__

=head1 NAME

Logic::Probabilistic::Result - Stores inference results and statistical measures.

=head1 SYNOPSIS

    my $result = $engine->query(...);
    say "Probability: " . $result->probability;
    say "95% CI: " . $result->ci_low . " .. " . $result->ci_high;

    if ( $result->method eq 'mcmc' ) {
        say "Chains:    " . $result->chains;
        say "R-hat:     " . $result->r_hat;
        say "ESS:       " . $result->ess;
        say "Converged: " . ($result->is_converged ? "yes" : "no");
    }

=head1 METHODS

=over 4

=item C<probability>

Returns the calculated point probability.

=item C<gradients>

Returns a hashref mapping parameter identifiers (e.g. C<'burglary'>, C<'friend(alice,bob)'>)
to their exact partial derivatives C<dP/dp_i>. Empty hashref if inference was run without gradients.

=item C<has_gradients>

Returns true if analytical gradients were computed and are available on this result.

=item C<gradient($target)>

Returns the partial derivative of the query probability with respect to the given target parameter.
C<$target> can be a L<Logic::Probabilistic::PFact> object, an identifier string, or a predicate name.
Returns C<0.0> if not found or if gradients were not computed.

=item C<ci($level)>

Returns the lower and upper bounds of the Wilson score confidence interval (default level 0.95).
For MCMC inference, calculates uncertainty based on the Effective Sample Size (ESS) to prevent
artificially narrow confidence intervals due to autocorrelation.

=item C<r_hat>

Potential scale reduction factor (Gelman-Rubin diagnostic). Values close to 1.0 indicate convergence across chains.

=item C<ess>

Effective Sample Size accounting for autocorrelation and between-chain variance.

=item C<is_converged($threshold)>

Returns boolean indicating whether R-hat is within threshold (default 1.05).

=item C<warnings>

List of diagnostic warning messages generated during inference.

=back

=cut
