#! /usr/bin/perl -w

# Toby Thurston ---  6 May 2009
# Parse LL and show as National Grid ref

use strict;
use warnings;

use Geo::Coordinates::OSGB qw/ll_to_grid/;
use Geo::Coordinates::OSGB::Grid qw/format_grid_landranger/;

use Getopt::Long;
use Pod::Usage;

our $VERSION = '2.16';

=pod

=head1 NAME

ll_to_bng - parse Latitude and Longitude and show them as a grid reference 

This programme shows off some features of L<Geo::Coordinates::OSGB>.

=head1 SYNOPSIS

  perl ll_to_bng.pl [--filter] lat lon

=head1 ARGUMENTS and OPTIONS

The argument should be a string that represents a latitude
and longitude in the UK like '51.3 -0.01'
No need to use quotes.  Latitude and longitude can be given in 
either order.

=over 4 

=item --filter

Just send the result to STDOUT instead of dressing it up 
in a message.

=item --usage, --help, --man

Show increasing amounts of help text, and exit.

=item --version

Print version and exit.

=back

=head1 DESCRIPTION

This section describes how L<Geo::Coordinates::OSGB> functions are used.

=head2 Parsing latitude and longitude

No special facilities are provided for extracting ll from a string.
You just need to supply regular decimal numbers.  In the UK latitude
is always larger than longitude, so if you get them the wrong way round
C<ll_to_grid> will silently swap them round. 

=head2 Using C<ll_to_grid>

The example shows how to get a regular WGS84 result as well as an OSGB36
result.  The OSGB36 model is used for the latitude and longitude shown
on the edges of OS maps.

=head2 Formatting a grid reference

C<format_grid_landranger> is used to re-present the grid references calculated
from the input.  In the scalar form you get a string instead of just the 
GR and a list of maps.

=head1 AUTHOR

Toby Thurston -- 04 Feb 2016 
toby@cpan.org

=cut

my $want_filter = 0;
my $test_me = 0;

Getopt::Long::Configure("pass_through");

my $options_ok = GetOptions(
    'filter!'     => \$want_filter, 
    'test!'       => \$test_me,
    
    'version'     => sub { warn "$0, version: $VERSION\n"; exit 0; }, 
    'usage'       => sub { pod2usage(-verbose => 0, -exitstatus => 0) },                         
    'help'        => sub { pod2usage(-verbose => 1, -exitstatus => 0) },                         
    'man'         => sub { pod2usage(-verbose => 2, -exitstatus => 0) },

) or die pod2usage();

die pod2usage() unless @ARGV>1 or $test_me;

my ($lat, $lon);
if ( $test_me or $ARGV[0] eq 'test' ) {
    $lat = 52 + ( 39 + 27.2531/60 )/60;
    $lon =  1 + ( 43 +  4.5177/60 )/60;
} 
else {
    ($lat, $lon) = @ARGV;
}

my ($e,  $n)  = ll_to_grid($lat, $lon);

if ( $want_filter ) {
    print "$e $n\n";
}
else {
    printf "Your input: %s %s\n", $lat, $lon;
    printf "In  WGS84 is %s %s == %s\n", $e, $n, scalar format_grid_landranger($e, $n);
    ($e, $n) = ll_to_grid($lat, $lon, {shape => 'OSGB36'});
    printf "In OSGB36 is %s %s == %s\n", $e, $n, scalar format_grid_landranger($e, $n);
}

