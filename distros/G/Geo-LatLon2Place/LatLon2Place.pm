=head1 NAME

Geo::LatLon2Place - convert latitude and longitude to nearest place

=head1 SYNOPSIS

 use Geo::LatLon2Place;

 my $db = Geo::LatLon2Place->new ("/var/lib/mydb.cdb");

=head1 DESCRIPTION

This is a single-purpose module that tries to do one job: find the nearest
placename for a point on earth. It doesn't claim to do a perfect job, but
it tries to be simple to set up, simple to use and be fast. It doesn't
attempt to provide many features or nifty algorithms, and is meant to be
used in situations where you simply need a name for a coordinate without
becoming a GIS expert first.

=head2 BUILDING, SETTING UP AND USAGE

To build this module, you need tinycdb, a cdb implementation by Michael
Tokarev, or a compatible library. On GNU/Debian-based systems you can get
this by executing F<apt-get install libcdb-dev>.

After install the module, you need to generate a database using the
F<geo-latlon2place-makedb> command.

Currently, it accepts various databases from geonames
(L<https://www.geonames.org/export/>, note the license), for example,
F<cities500.zip>, which lists all places with population 500 or more:

   wget https://download.geonames.org/export/dump/cities500.zip
   unzip cities500.zip
   geo-latlon2place-makedb cities500.txt cities500.ll2p

This will create a file F<ll2p.cdb> that you can use for lookups
with this module. At the time of this writing, the F<cities500> database
results in about a 10MB file while the F<allCountries> database results in
about 120MB.

Lookups will return a string of the form C<placename, countrycode>.

If you want to use the geonames postal code database (from
L<https://www.geonames.org/zip/>), use these commands:

   wget https://download.geonames.org/export/zip/allCountries.zip
   unzip allCountries.zip
   geo-latlon2place-makedb --extract geonames-postalcodes allCountries.txt allCountries.ll2p

You can then use the resulting database like this:

   my $lookup = Geo::LatLon2Place->new ("allCountries.ll2p");

   # and then do as many queries as you wish:
   my $res = $lookup->(49, 8.4);
   if (defined $res) {
      utf8::decode $res; # convert $res from utf-8 to unicode
      print "49, 8.4 found $res\n"; # should be Karlsruhe, DE for geonames
   } else {
      print "nothing found at 49, 8.4\n";
   }

=head1 THE Geo::LatLon2Place CLASS

=over

=cut

package Geo::LatLon2Place;

use common::sense;

use Carp ();

BEGIN {
   our $VERSION = '1.0';

   require XSLoader;
   XSLoader::load (__PACKAGE__, $VERSION);

   eval 'sub TORAD() { ' . ((atan2 1,0) / 90) . ' }';
}

=item $lookup = Geo::LatLon2Place->new ($path)

Opens a database created by F<geo-latlon2place-makedb> and return an
object that allows you to run queries against it.

The database will be mmaped, so it will not be loaded into memory, but
your operating system will cache it appropriately.

=cut

sub new {
   my ($class, $path) = @_;

   open my $fh, "<", $path
      or Carp::croak "$path: $!\n";

   my $self = bless [$fh, ""], $class;

   cdb_init $self->[1], fileno $self->[0]
      and Carp::croak "$path: unable to open as cdb file\n";

   (my ($magic, $version), $self->[2], $self->[3]) = unpack "a4VVV", cdb_get $self->[1], "";

   $magic eq "SRGL"
      or Carp::croak "$path: not a Geo::LatLon2Place file";

   $version == 2
      or Carp::croak "$path: version mismatch (got $version, expected 2)";

   $self
}

sub DESTROY {
   my ($self) = @_;

   cdb_free $self->[1];
}

=item $res = $lookup->lookup ($lat $lon[, $radius])

Looks up the point in the database that is "nearest" to C<$lat, $lon>,
search at leats up to C<$radius> kilometres. The default for C<$radius> is
the cell size the database is built with, and this usually works best, so
you usually do not specify this parameter.

If something is found, the associated data blob (always a binary string)
is returned, otherwise you receive C<undef>.

Unless you specify a custom format/extractor when building your database,
the data blob is actually a UTF-8 string, so you might want to call
C<utf8::decode> on it to get a unicode string:

   my $res = $db->lookup (47, 37); # near mariupol, UA
   if (defined $res) {
      utf8::decode $res;
      # $res now contains the unicode result
   }

=cut

sub lookup {
   my ($self, $lat, $lon, $radius) = @_;

   lookup_ext_ $self->[1], $self->[2], $self->[3], $lat, $lon, 0, $radius, 0
}

=back

=head1 ALGORITHM

The algorithm that this module implements consists of two parts: binning
and weighting (done when writing the database) and then finding the
nearest point.

The first part bins all data points into a grid which has its minimum cell
size at the equator and poles, with somewhat larger cells in between.

The lookup part will then read the cell that the coordinate is in and some
neighbouring cells (depending on the search radius, by default it will
read the eight cells around it).

It will then calculate the (squared) distance to the search coordinate
using an approximate euclidean distance on an equireactangular
projection. The squared distance is multiplied with a weight (1..25 for
the geonames database, based on population and adminstrative status,
always 1 for postal codes), and the minimum distance wins.

Binning should not introduce errors, but bigger bins can slow down lookup
times due to having to look at more places. The lookup assumes a spherical
shape for the earth, the equirectangular projection stretches distances
unevenly and the euclidean distance calculation introduces further
errors. For typical distance (<< 100km) and the intended usage, these
errors should be considered negligible.

=head1 SPEED

On my machine, C<lookup> typically does more than a million lookups per
second - performance varies depending on result density and number of
indexed points.

=head1 TENTATIVE ROADMAP

The database writer should be accessible via a module, so you can easily
generate your own databases without having to run an external command.

The API might be extended to allow for multiple lookups, multiple
returns, or nearest neighbour search, or more return values (distance,
coordinates).

Longer lookups will take advantage of perlmulticore.

=head1 PERL MULTICORE SUPPORT

This is not yet implemented:

This module supports the perl multicore specification
(L<http://perlmulticore.schmorp.de/>) when doing lookups.

=head1 SEE ALSO

L<geo-latlon2place-makedb> to create databases from common formats.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

