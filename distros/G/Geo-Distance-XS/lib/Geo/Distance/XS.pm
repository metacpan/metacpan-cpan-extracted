package Geo::Distance::XS;

use strict;
use warnings;

use Carp qw(croak);
use Geo::Distance;
use XSLoader;

our $VERSION    = '0.13';
our $XS_VERSION = $VERSION;
$VERSION = eval $VERSION;

XSLoader::load(__PACKAGE__, $XS_VERSION);

my ($orig_distance_sub, $orig_formula_sub);
BEGIN {
    $orig_distance_sub = \&Geo::Distance::distance;
    $orig_formula_sub  = \&Geo::Distance::formula;
}

my %formulas; @formulas{qw(hsin cos mt tv gcd polar alt)} = (1, 2, 2..6);
our @FORMULAS = sort keys %formulas;

sub import {
    no warnings qw(redefine);
    no strict qw(refs);

    *Geo::Distance::distance = \&{__PACKAGE__.'::distance'};
    *Geo::Distance::formula = sub {
        my $self = shift;
        if (@_) {
            my $formula = shift;
            croak "Invalid formula: $formula"
                unless exists $formulas{$formula};
            $self->{formula} = $formula;
            $self->{formula_index} = $formulas{$formula};
        }
        return $self->{formula};
    };
}

# Fall back to pure perl after calling 'no Geo::Distance::XS'.
sub unimport {
    no warnings qw(redefine);

    *Geo::Distance::formula  = $orig_formula_sub;
    *Geo::Distance::distance = $orig_distance_sub;
}


1;

__END__

=head1 NAME

Geo::Distance::XS - speed up Geo::Distance

=head1 SYNOPSIS

    use Geo::Distance::XS;

    my $geo = Geo::Distance->new;
    my $distance = $geo->distance(mile => $lon1, $lat1 => $lon2, $lat2);

=head1 DESCRIPTION

The C<Geo::Distance::XS> module provides faster C implementations of the
distance calculations found in C<Geo::Distance>.  See the documentation for
that module for usage.

NOTE: As of version 0.13, Geo::Distance automatically uses this module if
it is installed.

=head1 FORMULAS

In addition to the formulas offered in C<Geo::Distance>, this module
implements the additional formulas:

=head2 alt: Andoyer-Lambert-Thomas Formula

This is faster than the Vincenty formula, but trades a bit of accuracy.

=head1 PERFORMANCE

This distribution contains a benchmarking script which compares
C<Geo::Distance::XS> with C<Geo::Distance> and C<GIS::Distance::Fast>. These
are the results on a MacBook 2GHz with Perl 5.14.2:

    ---- [ Formula: hsin ] ------------------------------------
    perl     - distance from LA to NY: 2443.08796228363 miles
    xs       - distance from LA to NY: 2443.08796228363 miles
    gis_fast - distance from LA to NY: 2443.08796228363 miles

                Rate gis_fast     perl       xs
    gis_fast   24802/s       --     -70%     -98%
    perl       81919/s     230%       --     -92%
    xs       1003704/s    3947%    1125%       --

    ---- [ Formula: tv ] ------------------------------------
    perl     - distance from LA to NY: 2448.24135235512 miles
    xs       - distance from LA to NY: 2448.2413523656 miles
    gis_fast - distance from LA to NY: 2448.24135235512 miles

                Rate     perl gis_fast       xs
    perl      18101/s       --     -19%     -95%
    gis_fast  22330/s      23%       --     -94%
    xs       345717/s    1810%    1448%       --

    ---- [ Formula: polar ] ------------------------------------
    perl     - distance from LA to NY: 2766.02509696782 miles
    xs       - distance from LA to NY: 2766.02509696782 miles
    gis_fast - distance from LA to NY: 2766.02509696782 miles

                Rate gis_fast     perl       xs
    gis_fast   19200/s       --     -78%     -98%
    perl       87682/s     357%       --     -93%
    xs       1214700/s    6227%    1285%       --

    ---- [ Formula: cos ] ------------------------------------
    perl     - distance from LA to NY: 2443.08796228363 miles
    xs       - distance from LA to NY: 2443.08796228363 miles
    gis_fast - distance from LA to NY: 2443.08796228363 miles

                Rate gis_fast     perl       xs
    gis_fast   24435/s       --     -69%     -98%
    perl       78913/s     223%       --     -93%
    xs       1147836/s    4597%    1355%       --

    ---- [ Formula: gcd ] ------------------------------------
    perl     - distance from LA to NY: 2443.08796228363 miles
    xs       - distance from LA to NY: 2443.08796228363 miles
    gis_fast - distance from LA to NY: 2443.08796228363 miles

                Rate gis_fast     perl       xs
    gis_fast   18270/s       --     -75%     -98%
    perl       74472/s     308%       --     -93%
    xs       1102769/s    5936%    1381%       --

    ---- [ Formula: mt ] ------------------------------------
    perl     - distance from LA to NY: 2443.08796228363 miles
    xs       - distance from LA to NY: 2443.08796228363 miles
    gis_fast - distance from LA to NY: 2443.08796228363 miles

                Rate gis_fast     perl       xs
    gis_fast   17935/s       --     -75%     -98%
    perl       71739/s     300%       --     -94%
    xs       1135525/s    6231%    1483%       --

This distribution contains another benchmarking script which compares
only the XS formulas over several different coordinates:

            Rate    tv  hsin   alt   cos    mt   gcd polar
    tv     16906/s    --  -90%  -90%  -91%  -91%  -91%  -92%
    hsin  165414/s  878%    --   -4%   -8%  -10%  -13%  -17%
    alt   172032/s  918%    4%    --   -5%   -7%   -9%  -14%
    cos   180326/s  967%    9%    5%    --   -2%   -5%  -10%
    mt    184357/s  991%   11%    7%    2%    --   -3%   -8%
    gcd   189253/s 1019%   14%   10%    5%    3%    --   -6%
    polar 200386/s 1085%   21%   16%   11%    9%    6%    --

    Calculated length for short distance:
        alt  : 40.3740136064528 miles
        cos  : 40.3095459813536 miles
        gcd  : 40.3095459813294 miles
        hsin : 40.3095459813294 miles
        mt   : 40.3095459813536 miles
        polar: 46.7467797109043 miles
        tv   : 40.3740136384531 miles

    Calculated length for long distance:
        alt  : 2448.24135691376 miles
        cos  : 2443.08796228363 miles
        gcd  : 2443.08796228363 miles
        hsin : 2443.08796228363 miles
        mt   : 2443.08796228363 miles
        polar: 2766.02509696782 miles
        tv   : 2448.2413523656 miles

    Calculated length for nearly antipodes:
        alt  : 12340.6455133245 miles
        cos  : 12340.327635068 miles
        gcd  : 12340.327635068 miles
        hsin : 12340.327635068 miles
        mt   : 12340.327635068 miles
        polar: 12368.4764642469 miles
        tv   : 12340.7483034002 miles

    Calculated length for antipodes:
        alt  : 12429.86673988 miles
        cos  : 219.005548031861 miles
        gcd  : 12438.0476860875 miles
        hsin : 12438.0475680956 miles
        mt   : 219.005548031861 miles
        polar: 12438.0476860875 miles
        tv   : 12370.1885059814 miles

    Calculated length for polar antipodes:
        alt  : 12429.86673988 miles
        cos  : 12438.0476860875 miles
        gcd  : 12438.0476860875 miles
        hsin : 12438.0476860875 miles
        mt   : 12438.0476860875 miles
        polar: 12438.0476860875 miles
        tv   : 12429.8667398787 miles

=head1 SEE ALSO

L<Geo::Distance>

L<http://blogs.esri.com/esri/apl/2010/09/28/fast-times-at-geodesic-high/>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Geo-Distance-XS>. I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Distance::XS

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/geo-distance-xs>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-Distance-XS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-Distance-XS>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Distance-XS>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Distance-XS/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2014 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
