#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

package Medical::Growth::NHANES_2000::Base;

our ($VERSION) = '1.00';

use Scalar::Util ();
use Exporter;
use Moo::Lax;    # Vanilla Moo considered harmful

use Statistics::Standard_Normal qw(z_to_pct pct_to_z);
use namespace::clean;

extends 'Medical::Growth::Base';

# Ugly hack here to accommodate the fact that MooX::ClassAttribute
# doesn't handle inheriting/overriding class attrs.
# If you're writing your own, and can afford to use Moose,
# MooseX::ClassAttribute is cleaner.
sub _declare_params_LMS {
    my $class = shift;
    no strict 'refs';
    *{ $class . '::_params_LMS' } = sub {
        state $lms_values = shift->_build_params_LMS;
        $lms_values;
      }
}

sub _build_params_LMS {
    my $class = shift;
    my (@data);

    foreach my $r ( @{ $class->read_data } ) {
        push @data,
          {
            index => $r->[0],
            L     => $r->[1],
            M     => $r->[2],
            S     => $r->[3]
          };
    }
    @data = sort { $a->{index} <=> $b->{index} } @data;
    \@data;
}

sub lookup_LMS {
    my ( $self, $index ) = @_;
    return unless defined $index;
    my $list = $self->_params_LMS;
    my $i    = 0;

    return if $index < $list->[0]->{index} or $index > $list->[-1]->{index};

    $i++ while $list->[$i]->{index} < $index;
    $i-- if $i and $index != $list->[$i]->{index};

    # Exact match, just return current values
    return @{ $list->[$i] }{qw/L M S/} if $index == $list->[$i]->{index};

    # Between two indices; return interpolated values
    my ( $lo_i, $lo_l, $lo_m, $lo_s ) = @{ $list->[$i] }{qw/index L M S/};
    my ( $hi_i, $hi_l, $hi_m, $hi_s ) = @{ $list->[ $i + 1 ] }{qw/index L M S/};
    my $frac = ( $index - $lo_i ) / ( $hi_i - $lo_i );
    return (
        $lo_l + $frac * ( $hi_l - $lo_l ),
        $lo_m + $frac * ( $hi_m - $lo_m ),
        $lo_s + $frac * ( $hi_s - $lo_s )
    );
}

sub z_for_value {
    my ( $self, $value, $index ) = @_;
    my ( $l,    $m,     $s )     = $self->lookup_LMS($index);

    return unless $m;    # Off end of range

    if ($l) {
        return ( ( $value / $m )**$l - 1 ) / ( $l * $s );
    }
    else {
        return log( $value / $m ) / $s;
    }
}

sub pct_for_value {
    my ( $self, $value, $index ) = @_;
    return z_to_pct( $self->z_for_value( $value, $index ) );
}

sub value_for_z {
    my ( $self, $z_score, $index ) = @_;
    my ( $l,    $m,       $s )     = $self->lookup_LMS($index);

    return unless $m;    # Off end of range

    if ($l) {
        return $m * ( 1 + $l * $s * $z_score )**( 1 / $l );
    }
    else {
        return $m * exp( $s * $z_score );
    }
}

sub value_for_pct {
    my ( $self, $pct, $index ) = @_;
    $self->value_for_z( pct_to_z($pct), $index );
}

1;

__END__

=head1 NAME

Medical::Growth::NHANES_2000::Base - Shared infrastructure for Medical::Growth::NHANES_2000

=head1 SYNOPSIS

  # Patient evaluation
  my $handle = Medical::Growth->measure_class_for( system => 'NHANES_2000',
                                                   age_group => 'Infant',
                                                   sex => 'Female', 
                                                   measure => 'Length for Age');
  my $pctile = $handle->pct_for_value($wt, $age);
  my $z_score = $handle->z_for_value($wt, $age);

  # Build 50th percentile line
  foreach my $age (24 .. 240) {
    $plotter->plot_point($age, $handle->value_for_pct(50, $age));
  }

  # Implementing a measure class
  package Medical::Growth::NHANES_2000:Weight_for_Height::Child;
  use Moo::Lax;
  extends 'Medical::Growth::NHANES_2000::Base';


=head1 DESCRIPTION

This class provides the shared machinery to calculate the relationship
of a patient's anthropometric values to the NHANES 2000 norms (see
L<Medical::Growth::NHANES_2000> for further explanation of these
norms, as well as information on how to retrieve a measurement class).

=head2 EVALUATING PATIENT DATA

Once you have identified the right measure class, you may call any of
these methods as either class methods or via an object instance
created via C<new>.  (The latter approach doesn't add anything
substantive, as measure class objects in this system don't carry any
extra state; it's just a question of style.)

=over 4

=item B<z_for_value>(I<$value>, I<$index>)

Returns the Z score for the growth measurement I<$value> (what would
be the Y value on a growth chart) relative to the group of children
having the same I<$index> (what would be the X value on a growth
chart).  For example, to find out how a child's weight compares to
others of the same age, you would pick the appropriate F<Weight_for_Age>
measure class, and pass the weight in kg as I<$value> and the age in
months as I<$index>.

If I<$index> is out of range for the measurement class (e.g. you try
to measure a teenager against an Infant measurement class), returns
C<undef>.  Otherwise, returns the Z-score produced using the C<L>,
C<M>, and C<S> parameters from the Box-Cox model for the the
particular value I<$index>.

=item B<pct_for_value>(I<$value>, I<$index>)

Similar to L</z_for_value>, but returns a percentile rather than a Z
score.  See L<Statistics::Standard_Normal/z_to_pct> for details of the
conversion.

=item B<value_for_z>(I<$z_score>, I<$index>)

Returns the measurement value that would produce a Z score of
I<$z_score> for a child with index value I<$index>.  For example, a
F<Weight_for_Age> measure class would return the weight that would
correspond to I<$z_score> among children of age I<$index>.

If I<$index> is out of range for the measurement class (e.g. you try
to measure a teenager against an Infant measurement class), returns
C<undef>.  Otherwise, returns the value produced using the C<L>,
C<M>, and C<S> parameters from the Box-Cox model for the the
particular value I<$index>.

=item B<value_for_pct>(I<$pctile>, I<$index>)

Similar to L</value_for_z>, but returns the measurement value that
corresponds to the I<$pctile> percentile.

=item B<lookup_LMS>(I<$index>)

Returns the Box-Cox C<L>, C<M>, and C<S> parameters for children with
index value I<$index> in this measurement class (e.g. age for a
F<Weight_for_Age> measure class, height for a F<Weight_for_Height> measure
class).

If I<$index> is less than the minimum index or more than the maximum
index value for the measure class, returns C<undef> or an empty list.

If I<$index> falls between two values in the NHANES data tables,
linear interpolation is used to estimate C<L>, C<M>, and C<S>.

=back

=head2 EXPORT

None.

=head1 SEE ALSO

L<Medical::Growth>, L<http://www.cdc.gov/growthcharts>

=head1 DIAGNOSTICS

Any message produced by an included package, as well as

=over 4

=item B<Type error for LMS parameters> (F)

A subclass tried to load a set of L, M, and S parameters in the wrong
way. 

=back

=head1 BUGS AND CAVEATS

Are there, for certain, but have yet to be cataloged.

=head1 VERSION

version 1.00

=head1 AUTHOR

Charles Bailey <cbail@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2014 Charles Bailey.

This software may be used under the terms of the Artistic License or
the GNU General Public License, as the user prefers.

=head1 ACKNOWLEDGMENT

The code incorporated into this package was originally written with
United States federal funding as part of research work done by the
author at the Children's Hospital of Philadelphia.

=cut
