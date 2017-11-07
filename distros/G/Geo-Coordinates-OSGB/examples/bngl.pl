#! /usr/bin/perl -w

# Toby Thurston -- 15 Aug 2017 

use strict;
use warnings;

use Geo::Coordinates::OSGB qw/grid_to_ll ll_to_grid/;
use Geo::Coordinates::OSGB::Grid qw/random_grid parse_grid format_grid_landranger/;
use Browser::Open qw(open_browser);
use IO::Interactive qw(is_interactive interactive);

use Scalar::Util qw(looks_like_number);
use Getopt::Long;
use Pod::Usage;

our $VERSION = '2.20';

=pod

=head1 NAME

bngl.pl -- convert coordinates, and compare (possibly random) spots in the UK on Streetmap and Googlemaps

This programme shows off some features of L<Geo::Coordinates::OSGB>.

=head1 SYNOPSIS

  perl bngl.pl [--streetmap] [--googlemap] [--osgb] [ lat lon | grid reference ] 

=head1 ARGUMENTS and OPTIONS

The argument should be 

- either something that represents a grid reference, like 'TQ 123 456' or '314159 271828' 

- or a pair of decimal numbers in the range -20 to 70 representing a latitude
and longitude pair in the UK like: '51.3 -0.01'. Latitude and longitude can be
given in either order. You can leave an optional comma between them if you
like. This allows you to cut and paste from a web page for example. 

The argument will be converted appropriately. So if you supply a grid reference
you will get back a lat/lon pair, and vice versa.

If you supply no argument, then a random grid reference is supplied.

You can also pipe the argument from another program, and pipe the output to something else.
If you connect the output to a pipe you will get just the coordinates, without the fancy message.

=over 4 

=item --streetmap

Open a webpage on Streetmap.co.uk showing the grid point on an online OS map.

=item --googlemap

Open a webpage showing the grid point on Google maps.

=item --osgb

Use the OSGB36 latitude and longitude model instead of the normal WGS84 model

=item --usage, --help, --man

Show increasing amounts of help text, and exit.

=item --version

Print version and exit.

=back

=head1 DESCRIPTION

This script shows off the conversions in this module.  

The argument can be either a grid ref or a lat/lon pair.  A simple heurisistic is used to guess 
which is which.  If the argument is missing, then a random grid point is supplied.

Optionally you can show the chosen point on a map using the Streetmap and/or Googlemap options.
You can combine both so that you can compare the OS and the Google maps side by side for the same
area.  

The Google maps parameters are the result of experimentation rather than any API documentation
so I've no idea what the data parameter does, but it seems to be necessary.  The "14z" controls the 
level of zoom, and makes it roughly 1:50,000 corresponding to the Streetmap display with "&z=3".

=head1 DEPENDENCIES

You may need to install L<Browser::Open> and L<IO::Interactive>.

=head1 AUTHOR

Toby Thurston -- 30 Oct 2017 

toby@cpan.org

=cut

sub format_grid_streetmap {
    my $e = shift;
    my $n = shift;
    return sprintf 'http://www.streetmap.co.uk/map.srf?x=%06d&y=%06d&z=3', $e, $n;
}

sub format_ll_googlemaps {
    my ($lat, $lon) = @_;
    return sprintf 'http://www.google.com/maps/place/@%f,%f,14z/data=!4m2!3m1!1s0x0:0x0', $lat, $lon;
}

sub dms {
    use bignum;
    my ($degrees, $places, $hemisphere_labels ) = @_;
    my $sign = substr $hemisphere_labels, $degrees < 0, 1;
    my $seconds = sprintf "%.${places}f", abs($degrees)*3600;
    my $dd = sprintf "%d", $seconds / 3600; $seconds -= 3600 * $dd;
    my $mm = sprintf "%d", $seconds / 60;   $seconds -= 60 * $mm;
    return qq{$sign $dd° $mm′ $seconds″};
}

sub format_ll_nicely {
    my ($lat, $lon) = @_;
    return sprintf "Lat/Lon: %.7g %.7g = %s %s", 
                   $lat, 
                   $lon, 
                   dms($lat, 4, 'NS'), 
                   dms($lon, 4, 'EW');
}

sub clean_args {
    my $input = "@_";
    $input =~ s/,/ /g;
    return split ' ', $input;
}

my $show_streetmap = 0;
my $show_googlemap = 0;
my $use_osgb = 0;

Getopt::Long::Configure("pass_through");

my $options_ok = GetOptions(
    
    'version'    => sub { warn "$0, version: $VERSION\n"; exit 0; },
    'usage'      => sub { pod2usage(-verbose => 0, -exitstatus => 0) },
    'help'       => sub { pod2usage(-verbose => 1, -exitstatus => 0) },
    'man'        => sub { pod2usage(-verbose => 2, -exitstatus => 0) },
    'streetmap'  => \$show_streetmap,
    'googlemap'  => \$show_googlemap,
    'osgb'       => \$use_osgb,

) or die pod2usage();

my ($e, $n, $lat, $lon, @out);

my $model = $use_osgb ? 'OSGB36' : 'WGS84';

my @input;

if ( is_interactive(*STDIN) ) {
    if (@ARGV) {
        @input = clean_args(@ARGV);
    }
    else {
        @input = random_grid();
    }
}
else {
    @input = clean_args(<STDIN>);
}

if ( scalar @input == 2 && looks_like_number($input[0]) 
                       && looks_like_number($input[1]) 
                       && $input[0] < 72 
                       && $input[1] < 72 ) {
    ($lat, $lon) = @input;    
    @out = ($e, $n) = ll_to_grid($lat, $lon, {shape => $model});
}
else {
    ($e, $n) = parse_grid("@input");
    @out = ($lat, $lon) = grid_to_ll($e, $n, {shape => $model});
} 

if ($show_googlemap) {
    open_browser(format_ll_googlemaps($lat,$lon));
}
if ($show_streetmap) {
    open_browser(format_grid_streetmap($e, $n));
}

if ( is_interactive(*STDOUT) ) {
    printf "Your input: %s, model: $model\n", @ARGV ? "@ARGV" : "(random)";
    printf "Gridref: %s %s == %s\n", $e, $n, scalar format_grid_landranger($e, $n);
    print format_ll_nicely($lat, $lon), "\n";
}
else {
    print "@out\n";
}



