# -*- cperl; cperl-indent-level: 4 -*-
# Copyright (C) 2020, Roland van Ipenburg
package Geo::METAR::Deduced v0.0.4;
use Moose;
use MooseX::NonMoose;
use Geo::METAR;
extends 'Geo::METAR';

use Class::Measure::Scientific::FX_992vb;
use Geo::ICAO qw( :all );
use Set::Scalar;
use Data::Dumper;
use Log::Log4perl qw(:easy get_logger);

use utf8;
use 5.016000;

use English qw( -no_match_vars );

use Readonly;
## no critic (ProhibitCallsToUnexportedSubs)
Readonly::Scalar my $ICAO_MAX_CEILING => 200;
Readonly::Scalar my $HECTO            => 100;
Readonly::Scalar my $INF              => q{inf};
Readonly::Scalar my $METER            => q{m};
Readonly::Scalar my $FT               => q{ft};
Readonly::Scalar my $MI               => q{mile};
Readonly::Scalar my $PA               => q{pa};
Readonly::Scalar my $INHG             => q{inhg};
Readonly::Scalar my $CELSIUS          => q{C};
Readonly::Scalar my $KNOTS            => q{kn};
Readonly::Scalar my $DEG              => q{deg};
Readonly::Scalar my $VFR              => 3;
Readonly::Scalar my $MVFR             => 2;
Readonly::Scalar my $IFR              => 1;
Readonly::Scalar my $LIFR             => 0;
Readonly::Scalar my $HG               => 33.863886;
Readonly::Scalar my $AVERAGE          => 2;
Readonly::Scalar my $MINUS            => q{-};
Readonly::Scalar my $DEFAULT_RULES    => q{ICAO};

Readonly::Hash my %VIS_MIN => (
    'VFR'  => 5,
    'MVFR' => 3,
    'IFR'  => 1,
);
Readonly::Hash my %CEIL_MIN => (
    'VFR'  => 3000,
    'MVFR' => 1000,
    'IFR'  => 500,
);

# Re-use the %_weather_types lookup table from Geo::METAR:
Readonly::Hash my %WX => (
    'MI' => q{shallow},
    'PI' => q{partial},
    'BC' => q{patches},
    'BL' => q{blowing},
    'SH' => q{shower(s)},
    'TS' => q{thunderstorm},
    'FZ' => q{freezing},

    'DZ' => q{drizzle},
    'RA' => q{rain},
    'SN' => q{snow},
    'SG' => q{snow grains},
    'IC' => q{ice crystals},
    'PE' => q{ice pellets},
    'GR' => q{hail},
    'GS' => q{small hail/snow pellets},
    'UP' => q{unknown precip},

    'BR'   => q{mist},
    'FG'   => q{fog},
    'PRFG' => q{fog banks},      # officially PR is a modifier of FG
    'FU'   => q{smoke},
    'VA'   => q{volcanic ash},
    'DU'   => q{dust},
    'SA'   => q{sand},
    'HZ'   => q{haze},
    'PY'   => q{spray},

    'PO' => q{dust/sand whirls},
    'SQ' => q{squalls},
    'FC' => q{funnel cloud(tornado/waterspout)},
    'SS' => q{sand storm},
    'DS' => q{dust storm},

);
Readonly::Hash my %RULES => (
    'US' => q{USA},
    'UK' => q{United Kingdom},
);
Readonly::Hash my %LOG => (
    'RESET' => q{Reset properties for population from new METAR string '%s'},
    'RESET_PROP'    => q{Resetting property '%s' to '%s'},
    'RULES_CHANGED' => q{Rules changed to '%s' based on ICAO '%s'},
    'INTERSECTION'  => q{Overlapping rules for ICAO code '%s'},
    'UNKNOWN_RULES' => q{Unknown rules '%s'},
);
## use critic

Log::Log4perl->easy_init($ERROR);
my $log = get_logger();

my %rules = ();

sub _len {
    my ( $amount, $unit ) = @_;
    return Class::Measure::Scientific::FX_992vb->length( $amount, $unit );
}

my %vis_min = ();
for my $k ( keys %VIS_MIN ) {
    $vis_min{$k} = _len( $VIS_MIN{$k}, $MI );
}

my %ceil_min = ();
for my $k ( keys %CEIL_MIN ) {
    $ceil_min{$k} = _len( $CEIL_MIN{$k}, $FT );
}

my $combined = Set::Scalar->new;
for my $k ( keys %RULES ) {
## no critic (ProhibitCallsToUnexportedSubs)
    $rules{$k} = Set::Scalar->new( Geo::ICAO::country2code( $RULES{$k} ) );
## use critic
    $combined->insert( $rules{$k}->members );
}
if ( !$combined->is_universal ) {
    $log->warn( sprintf $LOG{'INTERSECTING'},
        $combined->difference( $combined->universe ) );
}

has 'rules' => ( 'isa' => 'Str', 'is' => 'rw', 'default' => $DEFAULT_RULES );

before 'metar' => sub {
    my $self = shift;
    my $args = shift;
    if ($args) {

        # Reset the object when a new METAR string is loaded because the parent
        # doesn't do that for us:
        my $PRISTINE = Geo::METAR->new();
        $log->debug( sprintf $LOG{'RESET'}, $args );
        for my $k ( keys %{$PRISTINE} ) {
            $log->trace( sprintf $LOG{'RESET_PROP'},
                $k, Data::Dumper::Dumper( ${$PRISTINE}{$k} ) );
            $self->{$k} = ${$PRISTINE}{$k};
        }
        $log->debug( join q{,}, @{ $self->{'sky'} } );
    }
};

after 'metar' => sub {
    my $self = shift;
    $self->rules($DEFAULT_RULES);
    for my $k ( keys %rules ) {
        while ( defined( my $code = $rules{$k}->each ) ) {
            if ( 0 == rindex $self->{'SITE'}, $code, 0 ) {
                $log->debug( sprintf $LOG{'RULES_CHANGED'},
                    $k, $self->{'SITE'} );
                $self->rules($k);
            }
        }
    }
};

sub date {
    my $self = shift;
    return $self->{'DATE'};
}

## no critic (ProhibitBuiltinHomonyms)
sub time {
## use critic
    my $self = shift;
    return $self->{'TIME'};
}

sub mode {
    my $self = shift;
    return $self->{'modifier'};
}

sub wind_dir {
    my $self = shift;
    return Class::Measure::Scientific::FX_992vb->angle( $self->{'WIND_DIR_DEG'},
        $DEG );
}

sub wind_dir_eng {
    my $self = shift;
    return $self->{'WIND_DIR_ENG'};
}

sub wind_dir_abb {
    my $self = shift;
    return $self->{'WIND_DIR_ABB'};
}

sub wind_var {
    my $self = shift;
    return defined $self->{'WIND_VAR'} ? 1 : 0;
}

sub wind_low {
    my $self = shift;
    return
      defined $self->{'WIND_VAR_1'}
      ? Class::Measure::Scientific::FX_992vb->angle( $self->{'WIND_VAR_1'},
        $DEG )
      : undef;
}

sub wind_high {
    my $self = shift;
    return
      defined $self->{'WIND_VAR_2'}
      ? Class::Measure::Scientific::FX_992vb->angle( $self->{'WIND_VAR_2'},
        $DEG )
      : undef;
}

sub wind_speed {
    my $self = shift;
    my $wind = $self->{'WIND_KTS'};
    $wind =~ s{^0*}{}msx;
    return Class::Measure::Scientific::FX_992vb->speed( $wind, $KNOTS );
}

sub wind_gust {
    my $self = shift;
    my $gust = $self->{'WIND_GUST_KTS'};
    if ($gust) {
        $gust =~ s{^0*}{}msx;
    }
    else {
        $gust = 0;
    }
    return Class::Measure::Scientific::FX_992vb->speed( $gust, $KNOTS );
}

sub temp {
    my $self = shift;
    return Class::Measure::Scientific::FX_992vb->temperature( $self->{'TEMP_C'},
        $CELSIUS );
}

sub dew {
    my $self = shift;
    return Class::Measure::Scientific::FX_992vb->temperature( $self->{'DEW_C'},
        $CELSIUS );
}

sub alt {
    my $self = shift;
    return Class::Measure::Scientific::FX_992vb->pressure(
        $self->{'pressure'} * $HECTO, $PA );
}

sub pressure {
    my $self = shift;
    return Class::Measure::Scientific::FX_992vb->pressure(
        $self->{'pressure'} * $HECTO, $PA );
}

# TODO: This isn't handled in Geo::METAR, it's just tokenized for the parser
sub _vertical_visibility {
    my $self = shift;
    my $vv   = $INF;
    $self->{'METAR'} =~ m{.*\bVV(?<vv>\d{3})\b.*}msx;
    if ( defined $LAST_PAREN_MATCH{'vv'} ) {
        $vv = $LAST_PAREN_MATCH{'vv'} * $HECTO;
    }
    return _len( $vv, $FT );
}

# https://en.wikipedia.org/wiki/Ceiling_(cloud)
# Rules say 20000ft is 6000m so we use ft to avoid rounding errors.
sub ceiling {
    my $self = shift;

    my $cloud_ceiling = $INF;
    my %TEST          = (
        'ICAO' => sub {
            my ($base) = @_;
            return $base < $ICAO_MAX_CEILING;
        },
        'UK' => sub {
            my ($base) = @_;
            return 1;
        },
        'US' => sub {
            my ($base) = @_;
            return 1;
        },
    );
    for my $layer ( @{ $self->{'sky'} } ) {
        $log->trace($layer);
        ## no critic (ProhibitUnusedCapture)
        if ( $layer =~ m{(?:BKN|OVC)(?<base>\d{3})}igmsx ) {
            ## use critic
            my $cloud_base = $LAST_PAREN_MATCH{'base'};
            if ( exists $TEST{ $self->rules } ) {
                if (   $cloud_base < $cloud_ceiling
                    && $TEST{ $self->rules }($cloud_base) )
                {
                    $cloud_ceiling = $cloud_base;
                }
            }
            else {
                $log->error( sprintf $LOG{'UNKNOWN_RULES'}, $self->rules );
            }
        }
    }
    if ( q{US} eq $self->rules ) {
        my $vv = $self->_vertical_visibility()->ft() / $HECTO;
        if ( $vv < $cloud_ceiling ) {
            $cloud_ceiling = $vv;
        }
    }
    return ( $INF eq $cloud_ceiling )
      ? _len( $cloud_ceiling,          $FT )
      : _len( $cloud_ceiling * $HECTO, $FT );
}

sub visibility {
    my $self  = shift;
    my $vis   = $self->{'visibility'};
    my $whole = qr{(?:(?<whole>[[:digit:]]+)[ ])*}smx;
    $vis =~ m{$whole(?<amount>[[:digit:]/]+)(?<unit>SM)*$}msx;
    my $unit = $METER;
    if ( $LAST_PAREN_MATCH{'unit'} ) {
        $unit = $MI;
    }
    my $amount = $LAST_PAREN_MATCH{'amount'};
    my $total  = 0;
    if ( $LAST_PAREN_MATCH{'whole'} ) {
        $total = $LAST_PAREN_MATCH{'whole'};
    }
    if ( $amount =~ m{(?<num>[[:digit:]]+)[/](?<den>[[:digit:]]+)}msx ) {
        $total += $LAST_PAREN_MATCH{'num'} / $LAST_PAREN_MATCH{'den'};
    }
    else {
        $total = $amount;
    }
    return _len( $total, $unit );
}

# https://en.wikipedia.org/wiki/METAR#Flight_categories_in_the_U.S.
# https://www.experimentalaircraft.info/wx/colors-metar-taf.php
sub flight_rule {
    my $self = shift;
    my $lvl;
## no critic (ProhibitCascadingIfElse)
    if (   $self->visibility()->mile() < $vis_min{'IFR'}->mile()
        || $self->ceiling()->ft() < $ceil_min{'IFR'}->ft() )
    {
        $lvl = $LIFR;
    }
    elsif ($self->visibility()->mile() >= $vis_min{'IFR'}->mile()
        && $self->visibility()->mile() < $vis_min{'MVFR'}->mile()
        || $self->ceiling()->ft() >= $ceil_min{'IFR'}->ft()
        && $self->ceiling()->ft() < $ceil_min{'MVFR'}->ft() )
    {
        $lvl = $IFR;
    }
    elsif ($self->visibility()->mile() >= $vis_min{'MVFR'}->mile()
        && $self->visibility()->mile() <= $vis_min{'VFR'}->mile()
        || $self->ceiling()->ft() >= $ceil_min{'MVFR'}->ft()
        && $self->ceiling()->ft() <= $ceil_min{'VFR'}->ft() )
    {
        $lvl = $MVFR;
    }
    elsif ($self->visibility()->mile() > $vis_min{'VFR'}->mile()
        && $self->ceiling()->ft() > $ceil_min{'VFR'}->ft() )
    {
        $lvl = $VFR;
    }

    # use critic
    return $lvl;
}

# Make it possible to check for weather types and make it return:
# 0 when not observed
# 1 observed as light
# 2 observed as normal
# 3 observed as heavy
for my $k ( keys %WX ) {

    sub _nom {
        my $label = shift;
        $label =~ s{[(].*[)]}{}gmsx;
        $label =~ s{(\s|/)+}{_}gmsx;
        return $label;
    }
    ## no critic (ProhibitNoStrict)
    no strict q{refs};
    ## use critic
    *{ _nom( $WX{$k} ) } = sub {
        my $self = shift;
        my $wx   = Set::Scalar->new( @{ $self->weather } );
        my $lvl  = 0;
        my $RE   = qr{^(?<modifier>[+-]*)$k}msx;
        while ( defined( my $w = $wx->each ) ) {
            if ( $w =~ $RE ) {
                $lvl = $AVERAGE;
                if ( $LAST_PAREN_MATCH{'modifier'} ) {
                    ( $LAST_PAREN_MATCH{'modifier'} eq $MINUS )
                      ? $lvl--
                      : $lvl++;
                }
            }
        }
        return $lvl;
    };
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=for stopwords Ipenburg merchantability METAR

=head1 NAME

Geo::METAR::Deduced - deduce aviation information from parsed METAR data

=head1 VERSION

This document describes Geo::METAR::Deduced v0.0.4.

=head1 SYNOPSIS

    use Geo::METAR::Deduced;
    $m = new Geo::METAR::Deduced;
    $m->metar("KFDY 251450Z 21012G21KT 8SM OVC065 04/M01 A3010 RMK 57014");
    $m->alt();
    $m->pressure();
    $m->date();
    $m->dew();
    $m->ice_crystals();
    $m->mode();
    $m->temp();
    $m->time();
    $m->ceiling();
    $m->flight_rule();
    $m->wind_dir();
    $m->wind_speed();
    $m->wind_gust();
    $m->wind_var();
    $m->wind_high();
    $m->wind_low();
    $m->snow();
    $m->dust();
    $m->rain();
    $m->ice_pellets();
    $m->drizzle();
    $m->funnel_cloud();
    $m->hail();
    $m->squalls();
    $m->partial();
    $m->patches();
    $m->dust_storm();
    $m->small_hail_snow_pellets();
    $m->volcanic_ash();
    $m->freezing();
    $m->fog();
    $m->spray();
    $m->mist();
    $m->fog_banks();
    $m->shallow();
    $m->sand();
    $m->sand_storm();
    $m->smoke();
    $m->haze();
    $m->shower();
    $m->dust_sand_whirls();
    $m->thunderstorm();
    $m->snow_grains();
    $m->blowing();
    $m->unknown_precip();
    $m->visibility();

=head1 DESCRIPTION

Get information from METAR that isn't explicitly in the METAR.

=head1 SUBROUTINES/METHODS

Methods that return a measurement return that as a
L<Class::Measure::Scientific::FX_992vb> object so the value can be converted
to other units, like from feet to meters or from miles to kilometers.

=over 4

=item C<Geo::METAR::Deduced-E<gt>new()>

Constructs a new Geo::METAR::Deduced object.

=item C<$m-E<gt>metar()>

Gets or sets the METAR string.

=item C<$m-E<gt>mode()>

Returns the METAR mode.

=item C<$m-E<gt>date()>

Returns the day of the month of the METAR. It doesn't return a date object
because we don't want to make the implied month and year explicit.

=item C<$m-E<gt>time()>

Returns the time of the METAR as string. It doesn't return a date object
because we don't want to make the implied month and year explicit.

=item C<$m-E<gt>ceiling()>

Returns the ceiling based on cloud level or vertical visibility data as
measurement.

=item C<$m-E<gt>visibility()>

Returns the visibility as measurement.

=item C<$m-E<gt>flight_rule()>

Returns the flight rule based on ceiling and visibility as 0 for low C<IFR>, 1
for C<IFR>, 2 for C<marginal VFR> and 3 for C<VFR>. 

=item C<$m-E<gt>alt()>

Returns the altimeter setting as pressure measurement.

=item C<$m-E<gt>pressure()>

Returns the pressure as measurement.

=item C<$m-E<gt>dew()>

Returns the dew temperature as measurement.

=item C<$m-E<gt>temp()>

Returns the temperature as measurement.

=item C<$m-E<gt>wind_dir()>

Returns the wind direction as angle measurement.

=item C<$m-E<gt>wind_dir_eng()>

Returns the wind direction in English, like C<Northwest>.

=item C<$m-E<gt>wind_dir_abb()>

Returns the wind direction abbreviation in English, like C<NW>.

=item C<$m-E<gt>wind_speed()>

Returns the wind speed as speed measurement.

=item C<$m-E<gt>wind_gust()>

Returns the wind gust speed as speed measurement.

=item C<$m-E<gt>wind_var()>

Returns if the wind is varying.

=item C<$m-E<gt>wind_high()>

Returns the highest direction of the varying wind as angle measurement.

=item C<$m-E<gt>wind_low()>

Returns the lowest direction of the varying wind as angle measurement.

=item Weather types 

The following weather types return 0 when they are not observed, 1 when in a
light condition, 2 for a normal condition and 3 for heavy:

=over 8

=item C<$m-E<gt>snow()>

=item C<$m-E<gt>dust()>

=item C<$m-E<gt>rain()>

=item C<$m-E<gt>ice_crystals()>

=item C<$m-E<gt>ice_pellets()>

=item C<$m-E<gt>drizzle()>

=item C<$m-E<gt>funnel_cloud()>

=item C<$m-E<gt>hail()>

=item C<$m-E<gt>squalls()>

=item C<$m-E<gt>partial()>

=item C<$m-E<gt>patches()>

=item C<$m-E<gt>dust_storm()>

=item C<$m-E<gt>small_hail_snow_pellets()>

=item C<$m-E<gt>volcanic_ash()>

=item C<$m-E<gt>freezing()>

=item C<$m-E<gt>fog()>

=item C<$m-E<gt>spray()>

=item C<$m-E<gt>mist()>

=item C<$m-E<gt>fog_banks()>

=item C<$m-E<gt>shallow()>

=item C<$m-E<gt>sand()>

=item C<$m-E<gt>sand_storm()>

=item C<$m-E<gt>smoke()>

=item C<$m-E<gt>haze()>

=item C<$m-E<gt>shower()>

=item C<$m-E<gt>dust_sand_whirls()>

=item C<$m-E<gt>thunderstorm()>

=item C<$m-E<gt>snow_grains()>

=item C<$m-E<gt>blowing()>

=item C<$m-E<gt>unknown_precip()>

=back

=back

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

=over 4

=item * Perl 5.16

=item * L<Geo::METAR>

=item * L<Geo::ICOA>

=item * L<Moose>

=item * L<MooseX::NonMoose>

=item * L<Set::Scalar>

=item * L<Class::Measure::Scientific::FX_992vb>

=item * L<Data::Dumper>

=item * L<English>

=back

=head1 INCOMPATIBILITIES

This module has the same limits as L<Geo::METAR>.

=head1 DIAGNOSTICS

This module uses L<Log::Log4perl> for logging.

=head1 BUGS AND LIMITATIONS

There is still plenty to deduce from the format that METAR has to offer in
it's fullest form.

Please report any bugs or feature requests at L<RT for
rt.cpan.org|https://rt.cpan.org/Public/Dist/Display.html?Name=Geo-METAR-Deduced>

=head1 AUTHOR

Roland van Ipenburg, E<lt>roland@rolandvanipenburg.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2020 by Roland van Ipenburg
This program is free software; you can redistribute it and/or modify
it under the GNU General Public License v3.0.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
