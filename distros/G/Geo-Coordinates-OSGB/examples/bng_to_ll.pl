#! /usr/bin/perl -w

# Toby Thurston -- 20 Jan 2016 
# Parse a National Grid ref and show it as LL coordinates

use strict;
use warnings;

use Geo::Coordinates::OSGB qw/grid_to_ll grid_to_ll_helmert/;
use Geo::Coordinates::OSGB::Grid qw/parse_grid format_grid_landranger/;

use Getopt::Long;
use Pod::Usage;

our $VERSION = '2.17';

=pod

=head1 NAME

bng_to_ll - parse a grid reference and show it as Latitude and Longitude

This programme shows off some features of L<Geo::Coordinates::OSGB>.

=head1 SYNOPSIS

  perl bng_to_ll.pl [--filter] grid ref string

=head1 ARGUMENTS and OPTIONS

The argument should be a string that represents a grid reference, 
like 'TQ 123 456' or '314159 271828'.  No need to use quotes.

=over 4 

=item --filter

Just send the WGS84 result to STDOUT instead of dressing it all up 
in a three line message.

=item --usage, --help, --man

Show increasing amounts of help text, and exit.

=item --version

Print version and exit.

=back

=head1 DESCRIPTION

This section describes how L<Geo::Coordinates::OSGB> functions are used.

=head2 Parsing a grid reference

C<parse_grid> takes more or less any possible string as a grid reference.
Or just a pair of numbers representing metres from the grid origin.
See L<Geo::Coordinates::OSGB::Grid> for full details.  You'll get 
error messages from C<parse_grid> if it fails to understand your input.

=head2 Using C<grid_to_ll>

The example shows how to get a regular WGS84 result as well as an OSGB36
result.  The OSGB36 model is used for the latitude and longitude shown
on the edges of OS maps.

=head2 Formatting a grid reference

C<format_grid_landranger> is used to re-present the grid reference parsed
from the input.  In the scalar form you get a string instead of just the 
GR and a list of maps.

=head2 Formatting a latitude / longitude pair

A simple routine that converts decimal-degrees to degrees-minutes-seconds
is included.  This might be useful in other applications.  

=head1 AUTHOR

Toby Thurston -- 04 Feb 2016 
toby@cpan.org

=cut

my $want_filter = 0;
my $test_me = 0;

my $options_ok = GetOptions(
    'filter!'     => \$want_filter, 
    'test!'       => \$test_me,
    
    'version'     => sub { warn "$0, version: $VERSION\n"; exit 0; }, 
    'usage'       => sub { pod2usage(-verbose => 0, -exitstatus => 0) },                         
    'help'        => sub { pod2usage(-verbose => 1, -exitstatus => 0) },                         
    'man'         => sub { pod2usage(-verbose => 2, -exitstatus => 0) },

) or die pod2usage();
die pod2usage unless @ARGV or $test_me;

# This routine shows how to convert from decimal degrees to DMS format
# Note that it's important to round the number of seconds **BEFORE**
# calculating the integer degrees and minutes, otherwise you can end up
# with a number of seconds that rounds to 60..., and then `use bignum` 
# ensures we keep the same number of decimal places for seconds when subtracting
# the hours and minutes
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
    my ($model, $lat, $lon) = @_;
    return sprintf "In $model, this is %.7g %.7g = %s %s", 
                   $lat, 
                   $lon, 
                   dms($lat, 4, 'NS'), 
                   dms($lon, 4, 'EW');
}

my $gr = "@ARGV";

my ($e, $n) = $gr eq 'test' || $test_me ? (651409.903, 313177.270) : parse_grid($gr);
my ($lat, $lon)   = grid_to_ll($e, $n);

if ($want_filter) {
    print "$lat $lon\n";
}
else {
    my ($olat, $olon) = grid_to_ll($e, $n, { shape => 'OSGB36' } );
    my ($hlat, $hlon) = grid_to_ll_helmert($e, $n);
    printf "Your input: $gr == $e $n == %s\n", scalar format_grid_landranger($e, $n);
    print format_ll_nicely(' WGS84', $lat, $lon), "\n";
    print format_ll_nicely('~WGS84', $hlat, $hlon), "\n";
    print format_ll_nicely('OSGB36', $olat, $olon), "\n";
}
exit 0;
