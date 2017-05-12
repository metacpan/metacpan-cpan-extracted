#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

package Medical::Growth::NHANES_2000;

our ($VERSION) = '1.10';

use Moo::Lax;    # Vanilla Moo considered harmful
use Carp qw(croak);

use Module::Runtime;
use Module::Pluggable
  require     => 1,
  search_path => 'Medical::Growth::NHANES_2000',
  except      => 'Medical::Growth::NHANES_2000::Base';

sub measure_classes {
    shift->plugins;
}

sub measure_class_name_for {
    my ( $self, %criteria ) = @_;
    my ( $measure, $norm, $ages, $sex, $class );

    $criteria{age_group} //= $criteria{age} if exists $criteria{age};
    croak('Need to specify measure, age_group, and sex')
      unless exists $criteria{measure}
      and exists $criteria{age_group}
      and exists $criteria{sex};

    if (   $criteria{measure} =~ /^(\w+)(?:\s+|_)(?:for|by)(?:\s+|_)(\w+)/i
        or $criteria{measure} =~
        /^(Head Circumference)(?:\s+|_)(?:for|by)(?:\s+|_)(Age)/i )
    {
        ( $measure, $norm ) = ( $1, $2 );
    }
    elsif ( $criteria{measure} =~ /(\w+)\s+(\w+)/i ) {
        ( $measure, $norm ) = ( $1, $2 );
    }
    elsif (
        $criteria{measure} =~
        /^(Weight|Wg?t|Height|Hg?t|Stature|Stat|Length|Len|BMI|Head|HC|OFC)
          (Age|Height|Hg?t|Length|Len)/ix
      )
    {
        ( $measure, $norm ) = ( $1, $2 );
    }
    else {
        croak "Don't understand measure spec '$criteria{measure}'";
    }

    if ( $criteria{age_group} =~ /^(?:infant|toddler|recumbent|neonat)/i ) {
        $ages = 'Infant';
    }
    elsif ( $criteria{age_group} =~ /^(?:child|school|adol)/i ) {
        $ages = 'Child';
    }
    elsif ( $criteria{age_group} =~ /^[0-9.]+$/
        and ( $criteria{age_group} eq '0' or $criteria{age_group} > 0 ) )
    {
        $ages = $criteria{age_group} >= 24 ? 'Child' : 'Infant';
    }
    else {
        croak "Don't understand age group '$criteria{age_group}'";
    }

    # Sigh - 5.18 makes this warn
    no if $] >= 5.017011, warnings => 'experimental::smartmatch';

    given ($measure) {
        when (/^W/i)          { $measure = 'Weight'; }
        when (/^O|^Hea|^HC/i) { $measure = 'HC'; }
        when (/^[HLS]/i) { $measure = $ages eq 'Infant' ? 'Length' : 'Height'; }
        when (/^B/i)     { $measure = 'BMI'; }
        default {
            croak "Don't understand measure name '$measure' in "
              . "'$criteria{measure}'";
        }
    }

    given ($norm) {
        when (/^A/i) { $norm = 'Age'; }
        when (/^[HL]/i) { $norm = $ages eq 'Infant' ? 'Length' : 'Height'; }
        default {
            croak "Don't understand norm name in " . "'$criteria{measure}'";
        }
    }

    if ( $criteria{sex} =~ /^[MB1]/i ) {
        $sex = 'Male';
    }
    elsif ( $criteria{sex} =~ /^[FG2]/i ) {
        $sex = 'Female';
    }
    else {
        croak "Don't understand sex '$criteria{sex}'";
    }

    $class =
        'Medical::Growth::NHANES_2000::'
      . $measure . '_for_'
      . $norm . '::'
      . $ages . '::'
      . $sex;
    return $class;
}

sub have_measure_class_for {
    my $self  = shift;
    my $class = $self->measure_class_name_for(@_);
    return unless $class; # Never happens in this class; just kind to subclasses
    eval { Module::Runtime::use_module($class) } or undef;
}

sub measure_class_for {
    my $self  = shift;
    my $class = $self->measure_class_name_for(@_);
    Module::Runtime::use_module($class)->new;
}

1;

__END__

=head1 NAME

Medical::Growth::NHANES_2000 - NHANES 2000 Growth Charts

=head1 SYNOPSIS

  use Medical::Growth::NHANES_2000;
  my $handle = Medical::Growth::NHANES_2000->new;
  my $dset = $handle->measure_class_for(measure => 'WtAge',
                                        age_group => 'Infant',
                                        sex => 'Male')
  foreach my $pt (get_infant_data() ) {
    ...
    my $wfa_pct = $dset->pct_for_value($pt->age_mon, $pt->wt_kg);
  }

=head1 DESCRIPTION

F<Medical::Growth::NHANES_2000> is a measurement system implemented using
the L<Medical::Growth> framework, that allows you to compare growth
measurements for children to the L<National Health and Nutrition
Examination Survey's (NHANES) 2000 infant and child growth
charts|http://www.cdc.gov/growthcharts>.  Measurement classes are
provided for each of the datasets published by the CDC.  These are
typically used to compute the percentile for a particular child's
measurements relative to the NHANES sample.

In order to compare a particular child's growth measurements to the
NHANES 2000 norms (the moral equivalent of plotting the measurement on
the appropriate growth chart), you will need to pick the measure class
for the growth measurement of interest (the moral equivalent of using
the right growth chart).  While you can use a particular measurement
class directly by name, L<Medical::Growth::NHANES_2000> also provides
ways for you to look up the appopriate measurement class using more
flexible syntax, as described below.

Once you have retrieved the measure class, you may use the methods
available to manipulate specific values documented in the common
L<Medical::Growth::NHANES_2000::Base> class; these may be called as
class or instance methods on any of the measurement classes.

=head2 METHODS

=over 4

=item B<measure_classes>

Returns a list of the names of measurement classes in the
L<Medical::Growth::NHANES_2000> system.

=item B<measure_class_name_for>(I<%criteria>)

Returns the name of the measurement class matching I<%criteria>.  No
check is made that the measurement class is actually available (though
this will be the case unless something went awry with installation of
L<Medical::Growth::NHANES_2000>).

The following elements of I<%criteria> are used to identify the
measurement class. Case is not significant for any of the values.

=over 4

=item measure

Growth measurement to be examined and basis for comparison.  This can
be a string of the form I<measure>C< for >I<norm>, where I<measure> is
the measurement (one of C<Weight>, C<Height>, C<Length>, C<Stature>,
C<Head Circumference>, or C<BMI>) and I<norm> is the norm (one of
C<Age>, C<Height>, or C<Length>).  Spaces may be replaced with
underscores, and C<for> may be replaced with C<by>, or the entire
preposition just replaced by spaces.

For convenience, some shorter forms are accepted as well, in the form
I<MeasNorm>.  In this case, I<Meas> can have the values above, but
also C<Wgt>, C<Wt>, C<Hgt>, C<Ht>, C<Stat>, C<Len>, C<Head>, C<HC>, or
C<OFC>, and I<Norm> can have the additional values C<Hgt>, C<Ht>,
or C<Len>.

Finally, any of C<Height>, C<Length>, or C<Stature> are mapped to
C<Length> if an infant I<age_group> is specified (see below), or to
C<Height> if a child age group is specified.

=item age_group

Age range for the norms to be used.  In the NHANES 2000 data, this is
either infants (ages 0-24 months) or children (ages 2-20 years).
Values of C<Infant>, C<Toddler>, C<Recumbent>, C<Neonatal>, and
C<Neonate> are taken as C<Infant>, and values of C<Child>,
C<School-age>, and C<Adolescent> are taken as C<Child>.

If the value looks like a number rather than a label, it is
interpreted as an age in months; values of 0-24 map to C<Infant> and
larger values map to C<Child>.

The key C<age> may be used instead of C<age_group>; if both are present,
C<age_group> is preferred.

=item sex

Sex of the children from whose measurements the desired norms were
constructed.  Values of C<Male>, C<M>, C<Boy>, C<B>, and C<1> map to
C<Male>.  Values of C<Female>, C<F>, C<Girl>, C<G>, and C<2> map to
C<Female>.

=back

If any of these values are missing or can't be interpreted, an
exception is thrown.

=item B<have_measure_class_for>(I<%criteria>)

Finds the measurement class name for I<%criteria> as described above,
and tries to load the measurement class.

Returns the name of the measure class if successful, and C<undef> if
the class cannot be loaded.

=item B<measure_class_for>(I<%criteria>)

Finds the measurement class name for I<%criteria> as described above,
and loads the measurement class.  An exception is thrown if the class
cannot be loaded.

Returns a handle for the measurement class, through which its methods may
be called.

This method can be called directly, or may be called by
delegation from L<Medical::Growth/measure_class_for>, if the C<system>
element of I<%criteria> specifies C<NHANES_2000>.

=back

=head2 USING NHANES_2000 MEASUREMENT CLASSES

Once you have a measurement class in hand, you will typically want to
do one of two things with it:

=over 4

=item Compare a particular child's growth measurements with the NHANES norms.

You can convert growth measurements to percentiles or Z scores by
calling L<pct_for_value|Medical::Growth::NHANES_2000::Base/pct_for_value> or 
L<z_for_value|Medical::Growth::NHANES_2000::Base/z_for_value>, respectively.

=item Reconstruct a growth curve

You can find out what specific growth measurements correspond
to a given percentile or Z score by calling
L<value_for_pct|Medical::Growth::NHANES_2000::Base/value_for_pct> or
L<value_for_z|Medical::Growth::NHANES_2000::Base/value_for_z>, respectively.

=back

=head2 EXPORT

None.

=head1 SEE ALSO

L<Medical::Growth>

L<http://www.cdc.gov/growthcharts>

L<Moo::Lax> (for developers) L<Medical::Growth::NHANES_2000> is
implemented using L<Moo::Lax> and friends to avoid the need for
compiled dependencies; if your code is already using L<Moose>, it
should play nicely.


=head1 DIAGNOSTICS

Any message produced by an included package, as well as

=over 4

=item B<Need to specify measure, age_group, and sex> (F)

One of the required criteria for identifying a measurement class is
missing. 

=item B<Don't understand measure spec> (F)

The value of the C<measure> element in I<%criteria> wasn't in a known
format.

=item B<Don't understand measure name> (F)

The growth measurement part of the C<measure> element in I<%criteria>
wasn't a known growth measurement.

=item B<Don't understand norm name> (F)

The norm (basis for comparison) part of the C<measure> element in I<%criteria>
wasn't a known norm.

=item B<Don't understand age group> (F)

The value of the C<age_group> element in I<%criteria> wasn't a known
growth measurement.

=item B<Don't understand sex> (F)

The value of the C<age_group> element in I<%criteria> wasn't a known
growth measurement.

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
