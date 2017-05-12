package Math::Units;

# Copyright 1997, 1998 Ken Fox

# This program is free software; you can redistribute it and/or modify
# it under the terms of either:
#
# a) the GNU General Public License as published by the Free
#    Software Foundation; either version 1, or (at your option) any
#    later version, or
#
# b) the "Artistic License," the text of which is distributed with
#    Perl 5.  If you need a copy of this license, please write to
#    me at <fox@vulpes.com> and I will be happy to send one.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
# the GNU General Public License or the Artistic License for more
# details.

=head1 NAME

Math::Units - Unit conversion

=head1 SYNOPSIS

use Math::Units qw(convert);

my $out_value = convert($in_value, 'in unit', 'out unit');

=head1 DESCRIPTION

The Math::Units module converts a numeric value in one unit of measurement
to some other unit.  The units must be compatible, i.e. length can not be
converted to volume.  If a conversion can not be made an exception is thrown.

A combination chaining and reduction algorithm is used to perform the most
direct unit conversion possible.  Units may be written in several different
styles.  An abbreviation table is used to convert from common long-form unit
names to the (more or less) standard abbreviations that the units module uses
internally.  All multiplicative unit conversions are cached so that future
conversions can be performed very quickly.

Too many units, prefixes and abbreviations are supported to list here.  See
the source code for a complete listing.

=head1 TODO

I beleive this module has great potential, if you have any ideas or patches feel free to submit them to rt.cpan.org.

'units' program test like 'gunits'

other tests

POD about what units/abbr/etc can be used with the function 

general cleanup

Mr. Fox's original TODO:

1. There should be a set of routines for adding new unit formulas,
   reductions and conversions.

2. Some conversions can be automatically generated from a reduction.  (This
   has to be done carefully because conversions are bi-directional while
   reductions *must* be consistently uni-directional.)

3. It would be nice to simplify the default conversions using the
   yet-to-be-written solution to #2.

4. There are many units (several in the GNU unit program for example) that
   aren't defined here.  Since I was (un)fortunately born in the U.S., I
   have a(n) (in)correct belief of what the standard units are.  Please let
   me know if I've messed anything up!

=head1 EXAMPLES

print "5 mm == ", convert(5, 'mm', 'in'), " inches\n";
print "72 degrees Farenheit == ", convert(72, 'F', 'C'), " degrees Celsius\n";
print "1 gallon == ", convert(1, 'gallon', 'cm^3'), " cubic centimeters\n";
print "4500 rpm == ", convert(4500, 'rpm', 'Hz'), " Hertz\n";

=cut

use strict;
use vars qw($VERSION @ISA @EXPORT_OK);

$VERSION = 1.3;

require Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(convert print_conversion);

use Carp;

# Prefixes are used to alter the magnitude of a unit.  They
# can *not* be chained together to form compound prefixes.
# (For special cases of compound prefixes, you can enter an
# abbreviation that rewrites the compound prefix to a single
# prefix of the right magnitude.)

my %prefixes = (
    'T'  => 1e12,
    'G'  => 1e9,
    'M'  => 1e6,
    'k'  => 1000,
    'h'  => 100,
    'da' => 10,
    'd'  => .1,
    'c'  => .01,
    'm'  => .001,
    'µ'  => 1e-6,
    'n'  => 1e-9,
    'dn' => 1e-10,
    'p'  => 1e-12,
    'f'  => 1e-15
);

# Formulas and reductions are carefully chosen expressions that
# define a unit in terms of other units (and constants).  The
# unit conversion algorithm always applies a formula definition,
# but only uses a reduction as a last ditch effort to make the
# conversion.  The reason for this is that reductions can lead
# to very long chains of unit conversions.  However, in most
# conversions a single factor can be used which will skip the
# entire reduction process (and improve accuracy besides).
#
# Always express a unit in terms of more fundamental units.
# Loops are not detected and will cause the conversion algorithm
# to hang.  (Adding units is intended to be easy, but not
# trivial.)
#
# See below for conversion examples.

my %formulas = (
    'are'     => '100 m^2',              # as in hectare
    'l'       => 'm^3/1000',             # liter
    'tonne'   => '1000 kg',              # metric ton
    'N'       => 'kg m/s^2',             # newton
    'dyn'     => 'cm gram/s^2',
    'Pa'      => 'N/m^2',                # pascal
    'bar'     => '1e5 Pa',
    'barye'   => 'dyne/cm^2',
    'kine'    => 'cm/s',
    'bole'    => 'g kine',
    'pond'    => 'gram gee',
    'glug'    => 'pond s^2/cm',
    'J'       => 'N m',                  # joule
    'W'       => 'J/s',                  # watt
    'gee'     => '9.80665 m/s^2',        # Earth gravity
    'atm'     => '101325 Pa',            # Earth atmosphere
    'Hg'      => '13.5951 pond/cm^3',    # mercury (used in: inches Hg)
    'water'   => 'pond/cm^3',            # water (used in: inches water)
    'mach'    => '331.46 m/s',           # speed of sound
    'coulomb' => 'A s',
    'V'       => 'W/A',                  # volt
    'ohm'     => 'V/A',
    'siemens' => 'A/V',
    'farad'   => 'coulomb/V',
    'Wb'      => 'V s',                  # weber
    'henry'   => 'Wb/A',
    'tesla'   => 'Wb/m^2',
    'Hz'      => 'cycle/s',              # hertz

    'lbf'  => 'lb gee',                  # pounds of force
    'tonf' => 'ton gee',                 # tons of force

    'duty' => 'ft lbf',
    'celo' => 'ft/s^2',
    'jerk' => 'ft/s^3',

    'slug' => 'lbf s^2/ft',
    'reyn' => 'psi sec',                 # viscosity

    'psi' => 'lbf/in^2',                 # pounds per square inch
    'tsi' => 'tonf/in^2',                # tons per square inch

    'ouncedal' => 'oz ft/s^2',           # force which accelerates an ounce at 1 ft/s^2
    'poundal'  => 'lb ft/s^2',           # same thing for a pound
    'tondal'   => 'ton ft/s^2',          # and for a ton

    'hp'           => '550 ft lbf/s',    # horse power
    'nauticalmile' => '1852 m',
    'mil'          => '.001 in'
);

# The base units are:
#
# m .............. meter (length) meter^2 (area) meter^3 (volume)
# g .............. gram (mass)
# s .............. second (time)
# deg ............ degree (angular measure)
# A .............. ampere (current)
# C .............. degrees Celsius (temperature)
# Cd ............. Celsius degrees (temperature change)

my %reductions = (
    'in'  => '0.0254 m',    # inches
    'pnt' => 'in/72',       # PostScript points
    'ft'  => '12 in',       # feet
    'yd'  => '3 ft',        # yards
    'mi'  => '5280 ft',     # miles
    'kip' => '1000 lbf',    # kilo pounds

    'barrel' => '42 gal',   # barrels
    'gal'    => '231 in^3', # gallons
    'qt'     => 'gal/4',    # quarts
    'pt'     => 'qt/2',     # pints
    'gill'   => 'pt/4',     # gills
    'floz'   => 'pt/16',    # fluid ounces

    'Fd' => '1.8 Cd',       # Farenheit degrees (change)
    'Kd' => 'Cd',           # Kelvins (change)

    'min' => '60 s',        # minutes
    'hr'  => '60 min',      # hours
    'day' => '24 hr',       # days
    'wk'  => '7 day',       # weeks

    'lb'  => '453.59237 g', # pounds
    'oz'  => 'lb/16',       # ounces
    'dr'  => 'oz/16',       # drams
    'gr'  => 'lb/7000',     # grains
    'ton' => '2000 lb',     # tons

    'cycle' => '360 deg',                           # complete revolution = 1 cycle
    'rad'   => '180 deg/3.14159265358979323846',    # radians
    'grad'  => '9 deg/10',                          # gradians

    'troypound'   => '5760 gr',                     # troy pound
    'troyounce'   => 'troypound/12',                # troy ounce
    'pennyweight' => 'troyounce/20',                # penny weight

    'carat' => '0.2 gm'                             # carat
);

# Abbreviations are simple text conversions that convert a pattern
# expression (i.e. a Perl regular expression) into a different form.
# Usually these convert from the long, spelled out form of a unit
# to the unit's abbreviated form.  Plural forms are also eliminated.
# A few small bows to standard spoken units are also available.
#
# Examples:
#
# meters => m
# kilometers => k-meters => k-m
# grams/cc => grams/cm^3 => g/cm^3
# meters per second => m/s
# cubic inches => cu-in
# feet squared => ft^2
# hectares => h-are
#
# Abbreviation substitutions are applied IN THE GIVEN ORDER to the unit
# until no more abbreviations match.  As in the formula and
# reduction expressions, be careful to avoid rewriting loops.  Also,
# be aware that longer abbreviations should appear first to avoid
# the possibility of an unintended rewrite.

my @abbreviations = (
    '\bper\b'        => '\/',
    '\bsq(uare)?\s+' => 'sq,',
    '\bcu(bic)?\s+'  => 'cu,',
    '\s+squared\b'   => '^2',
    '\s+cubed\b'     => '^3',

    '\bmicrons?\b' => 'µ,m',

    '\bdecinano-?' => 'dn,',
    '\btera-?'     => 'T,',
    '\bgiga-?'     => 'G,',
    '\bmega-?'     => 'M,',
    '\bkilo-?'     => 'k,',
    '\bhecto-?'    => 'h,',
    '\bdeka-?'     => 'da,',
    '\bdeca-?'     => 'da,',
    '\bdeci-?'     => 'd,',
    '\bcenti-?'    => 'c,',
    '\bmilli-?'    => 'm,',
    '\bmicro-?'    => 'µ,',
    '\bnano-?'     => 'n,',
    '\bpico-?'     => 'p,',
    '\bfemto-?'    => 'f,',

    '\bdn-' => 'dn,',
    '\bT-'  => 'T,',
    '\bG-'  => 'G,',
    '\bM-'  => 'M,',
    '\bk-'  => 'k,',
    '\bh-'  => 'h,',
    '\bda-' => 'da,',
    '\bda-' => 'da,',
    '\bd-'  => 'd,',
    '\bc-'  => 'c,',
    '\bm-'  => 'm,',
    '\bµ-'  => 'µ,',
    '\bn-'  => 'n,',
    '\bp-'  => 'p,',
    '\bf-'  => 'f,',

    '\b[Rr][Pp][Mm]\b' => 'cycle\/min',
    '\bhz\b'           => 'Hz',

    '\b[Cc]elsius\b'   => 'C',
    '\b[Ff]arenheit\b' => 'F',
    '\b[Kk]elvins?\b'  => 'K',
    '\bdegs?\s+C\b'    => 'C',
    '\bdegs?\s+F\b'    => 'F',
    '\bC\s+change\b'   => 'Cd',
    '\bF\s+change\b'   => 'Fd',
    '\bK\s+change\b'   => 'Kd',

    '\bdegs\b'      => 'deg',
    '\bdegrees?\b'  => 'deg',
    '\brads\b'      => 'rad',
    '\bradians?\b'  => 'rad',
    '\bgrads\b'     => 'grad',
    '\bgradians?\b' => 'grad',

    '\bangstroms?\b' => 'dn,m',
    '\bcc\b'         => 'cm^3',
    '\bhectares?\b'  => 'h,are',
    '\bmils?\b'      => 'm,in',
    'amperes?\b'     => 'A',
    'amps?\b'        => 'A',
    'days\b'         => 'day',
    'drams?\b'       => 'dr',
    'dynes?\b'       => 'dyn',
    'feet\b'         => 'ft',
    'foot\b'         => 'ft',
    'gallons?\b'     => 'gal',
    'gm\b'           => 'g',
    'grams?\b'       => 'g',
    'grains?\b'      => 'gr',
    'hours?\b'       => 'hr',
    'inch(es)?\b'    => 'in',
    'joules?\b'      => 'J',
    'lbs\b'          => 'lb',
    'lbm\b'          => 'lb',
    'liters?\b'      => 'l',
    'meters?\b'      => 'm',
    'miles?\b'       => 'mi',
    'minutes?\b'     => 'min',
    'newtons?\b'     => 'N',
    'ounces?\b'      => 'oz',
    'pascals?\b'     => 'Pa',
    'pints?\b'       => 'pt',
    'points?\b'      => 'pnt',
    'pounds?\b'      => 'lb',
    'quarts?\b'      => 'qt',
    'seconds?\b'     => 's',
    'secs?\b'        => 's',
    'watts?\b'       => 'W',
    'weeks?\b'       => 'wk',
    'yards?\b'       => 'yd'
);

# The conversion table *must* define unit conversion in terms
# of the base units, not in terms of units with prefixes.  This
# table will be used to generate the initial conversion factors
# used in simple unit to unit conversion.  Inverse factors will
# be automatically generated where possible.  As new unit
# conversion paths are discovered, the combined conversion
# factors will be added to the table.  No conversion factors
# should be entered for units that are defined in the formula
# table.  (Many or all of the reductions will be redundantly
# defined in the conversions table.  The reductions table uses
# a more general format which makes automatic conversion a
# bit tricky.)
#
# The entire purpose of the conversion table is to allow a
# more direct unit conversion path.  The reduction algorithm
# will always find a conversion (if one exists) but it may
# use many more multiplies than if the conversion table is
# used directly.
#
# Here is an example contrasting the two approaches. Given
# the following base facts:
#
#   reductions: in -> m, ft -> in, yd -> ft
#   conversions: in <-> m, ft <-> in, yd <-> ft
#
# convert feet to yards:
#
#   by reduction: ft -> in -> m <- in <- ft <- yd
#   by conversion: ft -> yd
#
# This demonstrates that fewer intermediate multiplies are
# performed in the direct conversion approach over the reduction
# approach.  However, the following problem can not be easily
# solved in the direct conversion approach:
#
# convert square meters to inch * feet:
#
#   by reduction: m^2 -> area <- m m <- m feet <- inch feet
#   by conversion: m^2 -> no match!
#
# Conversion can't solve this problem unless it first breaks up
# square meters into meter * meter.  Simple in this case, but very
# hard to generalize.
#
# In summary, the direct conversion system uses fewer intermediate
# conversions for better accuracy (and possibly performance but
# that isn't really an issue).  The reduction system is more
# general in that it can solve conversion problems that the direct
# conversion system can't.
#
# Examples:
#
# m -> in is solved by m -> in
# in -> m is solved by in -> m (inverses are automatically generated)
# qt -> ft^3 is solved by qt -> gal -> in^3 -> ft^3
# l -> ft^3 is solved by l -> m^3 -> in^3 -> ft^3
# K -> F is solved by K -> C -> F

my %conversions = (
    'in,m'   => 0.0254,
    'in,pnt' => 72,
    'ft,in'  => 12,
    'yd,ft'  => 3,
    'mi,ft'  => 5280,

    'barrel,gal' => 42,
    'gal,in^3'   => 231,
    'gal,qt'     => 4,
    'qt,pt'      => 2,
    'pt,floz'    => 16,
    'pt,gill'    => 4,

    'C,F' => sub { $_[0] * 1.8 + 32 },
    'F,C' => sub { ( $_[0] - 32 ) / 1.8 },
    'K,C' => sub { $_[0] - 273.15 },
    'C,K' => sub { $_[0] + 273.15 },

    'Cd,Fd' => 1.8,
    'Kd,Cd' => 1,

    'wk,day' => 7,
    'day,hr' => 24,
    'hr,min' => 60,
    'min,s'  => 60,

    'dollar,cent' => 100,

    'lb,g'   => 453.59237,
    'lb,oz'  => 16,
    'lb,gr'  => 7000,
    'oz,dr'  => 16,
    'ton,lb' => 2000,

    'cycle,deg' => 360,
    'rad,deg'   => 180 / 3.14159265358979323846,
    'grad,deg'  => 9 / 10,

    'troypound,gr'          => 5760,
    'troypound,troyounce'   => 12,
    'troyounce,pennyweight' => 20,

    'carat,gm' => .2
);

my $factors_computed   = 0;     # have the base conversion factors been computed?
my %factor             = ();    # conversion factors for base units
my %conversion_history = ();    # history of conversion factors for raw unit strings

sub register_factor {
    my ( $u1, $u2, $f ) = @_;

    $factor{$u1}{$u2} = $f;
    $factor{$u2}{$u1} = 1 / $f if ( ref($f) ne "CODE" );
}

sub print_unit($\%) {
    my ( $prefix, $u_group ) = @_;
    my ( $num_str, $den_str, $u, $dim );

    $num_str = "";
    $den_str = "";

    while ( ( $u, $dim ) = each %{$u_group} ) {
        if ( $u eq "1" ) { $prefix *= $dim }
        elsif ( $dim > 1 )   { $num_str .= "$u^$dim " }
        elsif ( $dim == 1 )  { $num_str .= "$u " }
        elsif ( $dim == -1 ) { $den_str .= "$u " }
        elsif ( $dim < -1 ) { $den_str .= join( "", $u, "^", -$dim, " " ) }
    }

    $num_str .= "$prefix " if ( $prefix != 1 );

    chop $num_str;
    chop $den_str;

    $num_str = "1" if ( !$num_str );

    print $num_str;
    print "/", $den_str if ($den_str);
    print "\n";
}

my $current_prefix;
my %current_group;

sub merge_simple_unit {
    my ( $prefix, $u, $dim ) = @_;

    if ( $dim > 1 )  { $current_prefix *= $prefix**$dim }
    if ( $dim == 1 ) { $current_prefix *= $prefix }
    elsif ( $dim == -1 ) { $current_prefix /= $prefix }
    elsif ( $dim < -1 )  { $current_prefix /= $prefix**-$dim }

    if ( $u ne "1" ) {
        if ( defined( $current_group{$u} ) ) { $current_group{$u} += $dim }
        else                                 { $current_group{$u} = $dim }

        delete $current_group{$u} if ( $current_group{$u} == 0 );
    }
}

sub reduce_simple_unit {
    my ( $u, $dim, $apply_reductions ) = @_;
    my ($p);

    if ( defined( $formulas{$u} ) ) {
        reduce_unit( $formulas{$u}, $dim, $apply_reductions );
        return;
    }

    if ( $apply_reductions && defined( $reductions{$u} ) ) {
        reduce_unit( $reductions{$u}, $dim, $apply_reductions );
        return;
    }
    elsif ( defined( $factor{$u} ) ) {
        merge_simple_unit( 1, $u, $dim );
        return;
    }

    foreach $p ( keys %prefixes ) {
        if ( $u =~ /^$p,?(.+)/ ) {
            if ( defined( $formulas{$1} ) ) {
                merge_simple_unit( $prefixes{$p}, "1", $dim );
                reduce_unit( $formulas{$1}, $dim, $apply_reductions );
                return;
            }
            if ( $apply_reductions && defined( $reductions{$1} ) ) {
                merge_simple_unit( $prefixes{$p}, "1", $dim );
                reduce_unit( $reductions{$1}, $dim, $apply_reductions );
                return;
            }
            elsif ( defined( $factor{$1} ) ) {
                merge_simple_unit( $prefixes{$p}, $1, $dim );
                return;
            }
        }
    }

    Carp::croak "unknown unit '$u' used";
}

sub reduce_unit {
    my ( $u_group, $dim, $apply_reductions ) = @_;
    my ($u);

    foreach $u ( keys %{$u_group} ) {
        if ( $u eq "1" ) {
            merge_simple_unit( $u_group->{$u}, $u, $dim );
        }
        else {
            reduce_simple_unit( $u, $dim * $u_group->{$u}, $apply_reductions );
        }
    }
}

sub canonicalize_unit_list (\@$$) {
    my ( $units, $u_group, $denomenator ) = @_;
    my ( $u, $dim );

    foreach $u ( @{$units} ) {
        next if ( !$u );

        if ( $u =~ s/\^(.+)$// ) {    # unit of higher dimension, e.g. "cm^3"
            $dim = $1;
        }
        elsif ( $u =~ /^sq,(.+)/ ) {    # square unit, e.g. "sq-in"
            $u   = $1;
            $dim = 2;
        }
        elsif ( $u =~ /^cu,(.+)/ ) {    # cubic unit, e.g. "cu-in"
            $u   = $1;
            $dim = 3;
        }
        else {
            $dim = 1;
        }

        $dim = -$dim if ($denomenator);

        if ( $u =~ /^-?\d+(?:\.\d+)?(?:e-?\d+)?$/ ) {
            if    ( $dim == 1 )  { $dim = $u }
            elsif ( $dim == -1 ) { $dim = 1 / $u }
            else                 { $dim = $u**$dim }
            $u = "1";
        }

        if ( defined( $u_group->{$u} ) ) {
            if ( $u eq "1" ) { $u_group->{$u} *= $dim }
            else             { $u_group->{$u} += $dim }
        }
        else {
            $u_group->{$u} = $dim;
        }
    }
}

sub canonicalize_unit_string ($$) {
    my ( $units, $u_group ) = @_;
    my ( $num, $den, $u, @units );

    substitute_abbreviations( \$units );
    $units =~ tr [*][ ];
    $units =~ s/\s*\^\s*/\^/g;
    $units =~ s/-\s*(\D)/ $1/g;

    if ( $units =~ m|^([^/]*)/(.*)| ) {
        $num = $1;
        $den = $2;
        $den =~ tr [/][ ];
    }
    else {
        $num = $units;
        $den = "";
    }

    @units = split( /\s+/, $num );
    if ( scalar @units ) {
        canonicalize_unit_list( @units, $u_group, 0 );
    }

    @units = split( /\s+/, $den );
    if ( scalar @units ) {
        canonicalize_unit_list( @units, $u_group, 1 );
    }

    $u_group;
}

sub reduce_toplevel_unit ($\%) {
    my ( $units, $u_group ) = @_;

    canonicalize_unit_string( $units, $u_group );

    $current_prefix = 1;
    %current_group  = ();

    reduce_unit( $u_group, 1, 0 );

    %{$u_group} = %current_group;

    $current_prefix;
}

sub finish_reducing_toplevel_unit (\%) {
    my ($u_group) = @_;

    $current_prefix = 1;
    %current_group  = ();

    reduce_unit( $u_group, 1, 1 );

    %{$u_group} = %current_group;

    $current_prefix;
}

sub get_factor {
    my ( $u1, $u2 ) = @_;

    ( $u1 eq $u2 ) ? 1 : $factor{$u1}{$u2};
}

my $combined_f;
my $combined_f_useless;

sub attempt_direct_conversion {
    my ( $value, $u1, $u1_dim, $u2, $u2_dim ) = @_;
    my ($f);

    if ( $u1_dim != $u2_dim ) {
        $u1 = "$u1^$u1_dim" if ( $u1_dim != 1 );
        $u2 = "$u2^$u2_dim" if ( $u2_dim != 1 );
        $u1_dim = 1;
    }

    if ( $u1_dim < 0 ) {
        $u1_dim = -$u1_dim;
        $f = get_factor( $u2, $u1 );
    }
    else {
        $f = get_factor( $u1, $u2 );
    }

    if ( defined($f) ) {
        if ( ref($f) eq "CODE" ) {
            $value = &$f( $value, $u1_dim );
            $combined_f_useless = 1;
        }
        elsif ( $f != 1 ) {
            $f = $f**$u1_dim if ( $u1_dim > 1 );    # $u1_dim is non-negative
            $value      *= $f;
            $combined_f *= $f;
        }

        return $value;
    }

    undef;
}

my %tmp_u_history;
my @tmp_u_path;
my @tmp_dim_path;

my $tmp_value;
my $tmp_uX;
my $tmp_uX_dim;

sub apply_factor_chain {
    my $chained_f         = 1.0;
    my $chained_f_useless = 0;

    push @tmp_u_path, $tmp_uX;
    my $final          = scalar(@tmp_u_path) - 1;
    my $original_value = $tmp_value;

    my ( $i, $f, $dim );

    for ( $i = 0; $i < $final; ++$i ) {
        $dim = $tmp_dim_path[$i];

        $f = get_factor( $tmp_u_path[$i], $tmp_u_path[ $i + 1 ] );

        if ( defined($f) ) {
            if ( ref($f) eq "CODE" ) {
                if ( $dim < 0 ) {
                    $dim = -$dim;
                    $f = get_factor( $tmp_u_path[ $i + 1 ], $tmp_u_path[$i] );
                }
                $tmp_value = &$f( $tmp_value, $dim );
                $chained_f_useless = 1;
            }
            elsif ( $f != 1 ) {
                $f = $f**$dim if ( $dim != 1 );    # $dim can be either negative or positive
                $tmp_value *= $f;
                $chained_f *= $f;
            }
        }
    }

    if ($chained_f_useless) {
        $combined_f_useless = 1;
    }
    else {
        my $u1 = $tmp_u_path[0];
        if ( exists( $factor{$u1} ) && exists( $factor{$tmp_uX} ) ) {
            my $u1_dim = $tmp_dim_path[0];

            $u1     = "$u1^$u1_dim"         if ( $u1_dim != 1 );
            $tmp_uX = "$tmp_uX^$tmp_uX_dim" if ( $tmp_uX_dim != 1 );

            register_factor( $u1, $tmp_uX, $chained_f );
            $combined_f *= $chained_f;
        }
    }

    die "OK\n";
}

sub breadth_first_factor_search {
    my ( $level, $u, $dim ) = @_;
    my $attempts = 0;

  SEARCH:
    {
        $tmp_u_history{$u} = 1;

        ++$attempts;

        push @tmp_u_path,   $u;
        push @tmp_dim_path, $dim;

        if ( $level == 0 ) {
            if ( $dim == $tmp_uX_dim && defined( $factor{$u}{$tmp_uX} ) ) {
                apply_factor_chain();
            }
        }
        else {
            my $child;
            foreach $child ( keys %{ $factor{$u} } ) {
                if ( !defined( $tmp_u_history{$child} ) ) {
                    breadth_first_factor_search( $level - 1, $child, $dim );
                }
            }
        }

        if ( $attempts < 2 ) {
            if ( $dim == 1 ) {
                if ( $u =~ /^([^^]+)\^(.+)/ ) {
                    $u   = $1;
                    $dim = $2;

                    redo SEARCH if ( !defined( $tmp_u_history{$u} ) );
                }
            }
            else {
                $u   = "$u^$dim";
                $dim = 1;

                redo SEARCH if ( !defined( $tmp_u_history{$u} ) );
            }
        }
    }

    while ( $attempts-- > 0 ) {
        pop @tmp_u_path;
        pop @tmp_dim_path;
    }
}

sub attempt_indirect_conversion {
    my ( $input_value, $u1, $u1_dim, $uX, $uX_dim ) = @_;

    $tmp_value  = $input_value;
    $tmp_uX     = $uX;
    $tmp_uX_dim = $uX_dim;

    eval {
        my $level;
        for ( $level = 0; $level < 4; ++$level ) {
            %tmp_u_history = ();
            @tmp_u_path    = ();
            @tmp_dim_path  = ();

            breadth_first_factor_search( $level, $u1, $u1_dim );
        }
    };

    return undef if ( $@ ne "OK\n" );

    return $tmp_value;
}

sub perform_unit_conversion ($\%\%) {
    my ( $value, $u1_group, $u2_group ) = @_;
    my ( $u1,    $u1_dim );
    my ( $u2,    $u2_dim );
    my ($new_value);

  DIRECT_UNIT_CONVERSION:
    foreach $u1 ( keys %{$u1_group} ) {
        $u1_dim = $u1_group->{$u1};

        foreach $u2 ( keys %{$u2_group} ) {
            $u2_dim = $u2_group->{$u2};

            $new_value = attempt_direct_conversion( $value, $u1, $u1_dim, $u2, $u2_dim );

            if ( defined($new_value) ) {
                $value = $new_value;
                delete $u1_group->{$u1};
                delete $u2_group->{$u2};
                next DIRECT_UNIT_CONVERSION;
            }
        }
    }

  INDIRECT_UNIT_CONVERSION:
    foreach $u1 ( keys %{$u1_group} ) {
        $u1_dim = $u1_group->{$u1};

        foreach $u2 ( keys %{$u2_group} ) {
            $u2_dim = $u2_group->{$u2};

            $new_value = attempt_indirect_conversion( $value, $u1, $u1_dim, $u2, $u2_dim );

            if ( defined($new_value) ) {
                $value = $new_value;
                delete $u1_group->{$u1};
                delete $u2_group->{$u2};
                next INDIRECT_UNIT_CONVERSION;
            }
        }
    }

    if ( scalar keys %{$u1_group} || scalar keys %{$u2_group} ) {
        $tmp_value = $value;
        die "REDUCE\n";
    }

    $value;
}

sub compute_base_factors {

    # register all of the direct unit-to-unit conversion factors

    my ( $pair, $f, $u1, $u2 );
    while ( ( $pair, $f ) = each %conversions ) {
        ( $u1, $u2 ) = split( /,/, $pair );
        register_factor( $u1, $u2, $f );
    }

    # build a fast pattern substitution function by eval'ing a
    # subroutine generated by concatenating all the abbreviation
    # substitution commands together.

    my $code = "sub substitute_abbreviations { my(\$units) = \@_; SUBST: {\n";
    my ( $pattern, $subst );

    my $i = 0;
    while ( $i < scalar @abbreviations ) {
        $pattern = $abbreviations[ $i++ ];
        $subst   = $abbreviations[ $i++ ];

        $code .= " redo SUBST if (\$\$units =~ s/$pattern/$subst/g);\n";
    }

    $code .= "} }";

    eval $code;

    # simplify all the formulas and reductions up front so that
    # multiple rewrite passes aren't required during unit expansion

    foreach $u1 ( keys %formulas ) {
        $formulas{$u1} = canonicalize_unit_string( $formulas{$u1}, {} );
    }

    foreach $u1 ( keys %reductions ) {
        $reductions{$u1} = canonicalize_unit_string( $reductions{$u1}, {} );
    }

    # mark this function completed because it only runs once

    $factors_computed = 1;
}

sub print_conversion {
    my ( $value, $u1, $u2 ) = @_;
    my $my_result = Convert( $value, $u1, $u2 );

    print "$value $u1 == $my_result $u2\n";
    $my_result;
}

sub convert {
    my ( $value, $u1, $u2 ) = @_;
    my ( %u1_group,  %u2_group );
    my ( $u1_prefix, $u2_prefix );
    my ($f);

    return ($value) if ( $u1 eq $u2 );
    if ( defined( $f = $conversion_history{$u1}{$u2} ) ) {
        return ( $value * $f );
    }

    if ( !$factors_computed ) {
        compute_base_factors();
    }

    $u1_prefix = reduce_toplevel_unit( $u1, %u1_group );
    $u2_prefix = reduce_toplevel_unit( $u2, %u2_group );

    $combined_f         = $u1_prefix / $u2_prefix;
    $combined_f_useless = 0;
    $value *= $combined_f;

    eval { $value = perform_unit_conversion( $value, %u1_group, %u2_group ); };

    if ($@) {
        if ( $@ eq "REDUCE\n" ) {
            $u1_prefix = finish_reducing_toplevel_unit(%u1_group);
            $u2_prefix = finish_reducing_toplevel_unit(%u2_group);

            $f = $u1_prefix / $u2_prefix;

            if ( !$combined_f_useless ) {
                $combined_f *= $f;
            }

            $value = $tmp_value * $f;

            eval { $value = perform_unit_conversion( $value, %u1_group, %u2_group ); };

            if ($@) {
                if ( $@ eq "REDUCE\n" ) {
                    Carp::croak "conversion of unit '$u1' to '$u2' failed (incompatible units?)";
                }
                else {
                    Carp::croak $@;
                }
            }
        }
        else {
            Carp::croak "impossible! $@";
        }
    }

    if ( !$combined_f_useless ) {
        $conversion_history{$u1}{$u2} = $combined_f;
    }

    $value;
}

1;
