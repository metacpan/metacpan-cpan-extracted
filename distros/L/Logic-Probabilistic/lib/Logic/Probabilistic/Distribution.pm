package Logic::Probabilistic::Distribution;

use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';
use Carp         qw(croak);
use Scalar::Util qw(blessed looks_like_number);

our $VERSION = '0.01';

use overload
  '""'     => sub ( $self, $, $ ) { $self->to_string },
  fallback => 1;

sub new ( $class, %args ) {
    my $raw_probs = $args{probabilities} // croak "probabilities is required";
    my $meth      = $args{method}        // 'exact';

    my %probs;
    for my $k ( keys %$raw_probs ) {
        $probs{$k} = 0.0 + $raw_probs->{$k};
    }

    my @keys       = keys %probs;
    my $is_numeric = 1;
    if ( !@keys ) {
        $is_numeric = 0;
    }
    else {
        for my $k (@keys) {
            if ( !looks_like_number($k) ) {
                $is_numeric = 0;
                last;
            }
        }
    }

    my @sorted_values;
    if ($is_numeric) {
        @sorted_values = sort { $a <=> $b } @keys;
    }
    else {
        @sorted_values = sort { $a cmp $b } @keys;
    }

    my $self = {
        probabilities        => \%probs,
        values               => \@sorted_values,
        is_numeric           => $is_numeric,
        val_map              => $args{val_map} // {},
        evidence_probability => exists $args{evidence_probability}
        ? 0.0 + $args{evidence_probability}
        : 1.0,
        method           => $meth,
        total_samples    => $args{total_samples}    // $args{world_count} // 0,
        accepted_samples => $args{accepted_samples} // 0,
        counts           => $args{counts}           // {},
        metadata         => $args{metadata}         // {},
    };

    return bless $self, $class;
}

sub probabilities ($self) {
    return
      wantarray ? %{ $self->{probabilities} } : { %{ $self->{probabilities} } };
}

sub probability ( $self, $val ) {
    my $key = $self->_val_to_key($val);
    return $self->{probabilities}{$key} // 0.0;
}

sub prob ( $self, $val ) {
    return $self->probability($val);
}

sub pmf ( $self, $val ) {
    return $self->probability($val);
}

sub values ($self) {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    return wantarray ? @{ $self->{values} } : [ @{ $self->{values} } ];
}

sub raw ( $self, $val ) {
    my $key = $self->_val_to_key($val);
    return exists $self->{val_map}{$key} ? $self->{val_map}{$key} : $val;
}

sub object ( $self, $val ) {
    return $self->raw($val);
}

sub objects ($self) {
    my @objs = map { $self->raw($_) } @{ $self->{values} };
    return wantarray ? @objs : \@objs;
}

sub raw_values ($self) {
    return $self->objects;
}

sub outcome ( $self, $val ) {
    require Logic::Probabilistic::Distribution::Outcome;
    my $key = $self->_val_to_key($val);
    return unless exists $self->{probabilities}{$key};
    my $raw  = $self->raw($key);
    my $prob = $self->{probabilities}{$key};
    return Logic::Probabilistic::Distribution::Outcome->new(
        key          => $key,
        raw          => $raw,
        probability  => $prob,
        distribution => $self,
    );
}

sub outcomes ($self) {
    require Logic::Probabilistic::Distribution::Outcome;
    my @outcomes = map { $self->outcome($_) } @{ $self->{values} };
    return wantarray ? @outcomes : \@outcomes;
}

sub support ($self) {
    my @sup = grep { $self->{probabilities}{$_} > 0.0 } @{ $self->{values} };
    return wantarray ? @sup : \@sup;
}

sub evidence_probability ($self) {
    return $self->{evidence_probability};
}

sub method ($self) {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    return $self->{method};
}

sub inference_method ($self) {
    return $self->{method};
}

sub total_samples ($self) {
    return $self->{total_samples};
}

sub world_count ($self) {
    return $self->{total_samples};
}

sub accepted_samples ($self) {
    return $self->{accepted_samples};
}

sub counts ($self) {
    return wantarray ? %{ $self->{counts} } : { %{ $self->{counts} } };
}

sub metadata ($self) {
    return $self->{metadata};
}

sub is_numeric ($self) {
    return $self->{is_numeric};
}

sub mass ($self) {
    my $sum = 0.0;
    for my $v ( @{ $self->{values} } ) {
        $sum += $self->{probabilities}{$v};
    }
    return $sum;
}

sub mean ($self) {
    croak "Cannot calculate mean on non-numeric distribution"
      unless $self->{is_numeric};

    my $sum_p  = 0.0;
    my $sum_vp = 0.0;
    for my $v ( @{ $self->{values} } ) {
        my $p = $self->{probabilities}{$v};
        $sum_p  += $p;
        $sum_vp += ( 0.0 + $v ) * $p;
    }
    return 0.0 if $sum_p <= 0.0;
    return $sum_vp / $sum_p;
}

sub expectation ($self) {
    return $self->mean;
}

sub expected_value ($self) {
    return $self->mean;
}

sub variance ($self) {
    croak "Cannot calculate variance on non-numeric distribution"
      unless $self->{is_numeric};

    my $mu          = $self->mean;
    my $sum_p       = 0.0;
    my $sum_diff_sq = 0.0;
    for my $v ( @{ $self->{values} } ) {
        my $p = $self->{probabilities}{$v};
        $sum_p       += $p;
        $sum_diff_sq += ( ( ( 0.0 + $v ) - $mu )**2 ) * $p;
    }
    return 0.0 if $sum_p <= 0.0;
    return $sum_diff_sq / $sum_p;
}

sub std_dev ($self) {
    return sqrt( $self->variance );
}

sub sd ($self) {
    return $self->std_dev;
}

sub mode ($self) {
    my @values = @{ $self->{values} };
    return unless @values;

    my $max_p = -1.0;
    for my $v (@values) {
        my $p = $self->{probabilities}{$v};
        $max_p = $p if $p > $max_p;
    }

    my @modes =
      grep { abs( $self->{probabilities}{$_} - $max_p ) < 1e-9 } @values;
    return wantarray ? @modes : $modes[0];
}

sub min ($self) {
    croak "Cannot calculate min on non-numeric distribution"
      unless $self->{is_numeric};

    for my $v ( @{ $self->{values} } ) {
        return 0.0 + $v if $self->{probabilities}{$v} > 0.0;
    }
    return;
}

sub max ($self) {
    croak "Cannot calculate max on non-numeric distribution"
      unless $self->{is_numeric};

    for my $v ( reverse @{ $self->{values} } ) {
        return 0.0 + $v if $self->{probabilities}{$v} > 0.0;
    }
    return;
}

sub cdf ( $self, $target ) {
    croak "Cannot calculate cdf on non-numeric distribution"
      unless $self->{is_numeric};

    my $cum = 0.0;
    for my $v ( @{ $self->{values} } ) {
        last if ( 0.0 + $v ) > ( 0.0 + $target );
        $cum += $self->{probabilities}{$v};
    }
    $cum = 1.0 if $cum > 1.0;
    return $cum;
}

sub quantile ( $self, $q ) {
    croak "Cannot calculate quantile on non-numeric distribution"
      unless $self->{is_numeric};
    croak "Quantile q must be between 0.0 and 1.0"
      if $q < 0.0 || $q > 1.0;

    my $cum = 0.0;
    for my $v ( @{ $self->{values} } ) {
        $cum += $self->{probabilities}{$v};
        return 0.0 + $v if $cum >= ( $q - 1e-9 );
    }
    return 0.0 + $self->{values}[-1] if @{ $self->{values} };
    return;
}

sub percentile ( $self, $pct ) {
    return $self->quantile( $pct / 100.0 );
}

sub entropy ( $self, $base = 2 ) {
    my $h        = 0.0;
    my $log_base = log($base);
    for my $v ( @{ $self->{values} } ) {
        my $p = $self->{probabilities}{$v};
        if ( $p > 0.0 ) {
            $h -= $p * ( log($p) / $log_base );
        }
    }
    return $h;
}

sub sample ($self) {
    my $r   = rand();
    my $cum = 0.0;
    for my $v ( @{ $self->{values} } ) {
        $cum += $self->{probabilities}{$v};
        return $self->{val_map}{$v} // $v if $r <= $cum;
    }
    my $last_val = $self->{values}[-1];
    if ( defined $last_val ) {
        return $self->{val_map}{$last_val} // $last_val;
    }
    return;
}

sub to_string ( $self, %opts ) {
    my $bar_width = $opts{bar_width} // 30;
    my $bar_char  = $opts{bar_char}  // '=';
    my $scale     = $opts{scale}     // 'relative';

    my @values = @{ $self->{values} };
    return "Empty Distribution" unless @values;

    my $max_val_len = 5;
    my $max_p       = 0.0;
    for my $v (@values) {
        my $len = length("$v");
        $max_val_len = $len if $len > $max_val_len;
        my $p = $self->{probabilities}{$v};
        $max_p = $p if $p > $max_p;
    }

    my $scale_factor =
        ( $scale eq 'relative' && $max_p > 0.0 )
      ? ( $bar_width / $max_p )
      : $bar_width;

    my $col1_w = $max_val_len + 2;
    my $header =
      sprintf( " %-${max_val_len}s | Probability (Pct)  | Distribution Bar\n",
        "Value" );
    my $sep = sprintf(
        "%s+--------------------+-%s\n",
        '-' x $col1_w,
        '-' x $bar_width
    );

    my $out = $header . $sep;
    for my $v (@values) {
        my $p       = $self->{probabilities}{$v};
        my $pct     = $p * 100.0;
        my $bar_len = int( ( $p * $scale_factor ) + 0.5 );
        $bar_len = $bar_width if $bar_len > $bar_width;
        my $bar = $bar_char x $bar_len;
        $out .= sprintf( " %-${max_val_len}s |   %7.4f (%5.1f%%) | %s\n",
            $v, $p, $pct, $bar );
    }
    $out .= $sep;

    my $meth  = $self->{method};
    my $n     = $self->{total_samples};
    my $units = ( $meth eq 'exact' ) ? 'worlds' : 'samples';

    if ( $self->{is_numeric} ) {
        my @modes    = $self->mode;
        my $mode_str = join( ', ', @modes );
        $out .= sprintf( "Mean: %.4f | Std Dev: %.4f | Mode: %s (%s, %d %s)",
            $self->mean, $self->std_dev, $mode_str, $meth, $n, $units );
    }
    else {
        my @modes    = $self->mode;
        my $mode_str = join( ', ', @modes );
        $out .= sprintf( "Mode: %s (%s, %d %s)", $mode_str, $meth, $n, $units );
    }

    if ( $self->{evidence_probability} < 1.0 ) {
        $out .=
          sprintf( " [P(evidence) = %.4f]", $self->{evidence_probability} );
    }

    return $out;
}

sub _val_to_key ( $self, $val ) {
    return 'undef' unless defined $val;
    if ( blessed($val) ) {
        return $val->key       if $val->can('key');
        return $val->to_string if $val->can('to_string');
        return $val->as_string if $val->can('as_string');
        return "$val";
    }
    if ( ref($val) eq 'ARRAY' ) {
        return '[' . join( ', ', map { $self->_val_to_key($_) } @$val ) . ']';
    }
    return "$val";
}

1;

__END__

=head1 NAME

Logic::Probabilistic::Distribution - Stores discrete probability distributions and statistical moments.

=head1 SYNOPSIS

    my $dist = $prog->query_distribution(call('dice_sum', $total));
    say "Mean:      " . $dist->mean;
    say "Variance:  " . $dist->variance;
    say "Mode:      " . $dist->mode;
    say "P(Sum = 7) " . $dist->probability(7);
    say $dist; # Pretty ASCII table / histogram

=head1 METHODS

=over 4

=item C<probability($val)>

Probability mass of a specific value $P(X = v)$. Aliased as C<prob> and C<pmf>.

=item C<probabilities>

Hashref (scalar context) or hash (list context) of all values to their probabilities.

=item C<values>

Sorted list of all discrete values in the distribution.

=item C<support>

List of values having strictly non-zero probability.

=item C<mean>

Expected value $E[X] = \sum v \cdot P(X = v)$ for numeric distributions.

=item C<variance>

Variance $\text{Var}(X) = E[(X - \mu)^2]$.

=item C<std_dev>

Standard deviation $\sqrt{\text{Var}(X)}$. Aliased as C<sd>.

=item C<mode>

Value(s) with highest probability.

=item C<min>, C<max>

Minimum and maximum values with non-zero probability.

=item C<cdf($val)>

Cumulative distribution function $P(X \le val)$.

=item C<quantile($q)> / C<percentile($pct)>

Quantile function for numeric distributions.

=item C<entropy($base = 2)>

Shannon entropy in bits (default base 2).

=item C<sample>

Draws a random value according to the probability mass function.

=item C<to_string(%opts)>

Formats the distribution as an ASCII table with a distribution histogram bar chart.

=back

=cut
