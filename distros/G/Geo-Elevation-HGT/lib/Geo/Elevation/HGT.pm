package Geo::Elevation::HGT;

use 5.010;
use strict;
use warnings;
use POSIX ();
use Carp;
# set the version for version checking
our $VERSION     = '0.05';
# file-private lexicals
my $grid_size; # .hgt grid size = 3601x3601 for 1-minute DEMs or 1201x1201 for 3-minute DEMs
my @DEMnames;
my @default_DEMs;
my @want_DEMnames;
my $status_descr;
my $url;
my $folder;
my $cache_folder;
my $debug;
my $switch;
my $cache;
my $fail;

sub new {
  my ($class, %params) = @_;
  %params = (
    url => "https://elevation-tiles-prod.s3.amazonaws.com/skadi",    # info at https://registry.opendata.aws/terrain-tiles/
    folder => "https://elevation-tiles-prod.s3.amazonaws.com/skadi",
    cache_folder => "",
    debug => 0,
    %params
  );
  my $self = {};
  while ( my($key,$value) = each %params ) {
    $self->{$key} = $value;
  }
  bless $self, $class;
  return $self;
}

sub get_elevation_batch_hgt {
  my ($self, $batch_latlon) = @_;
  my @elegeh;
  for my $latlon ( @$batch_latlon ) {
    my ($lat, $lon) = @$latlon;
    push (@elegeh, $self->get_elevation_hgt ($lat, $lon));
  }
  return \@elegeh;
}

sub get_elevation_hgt {
  my ($self, $lat, $lon) = @_;
  $folder = $self->{folder};
  $url = $self->{url};
  $cache_folder = $self->{cache_folder};
  $debug = $self->{debug};
  $status_descr = "Memory";
  say STDERR "get_elevation_hgt" if $debug;
  say STDERR "  Parameters: folder=>'$folder', url=>'$url', cache_folder=>'$cache_folder', debug=>$debug" if $debug;
  say STDERR "  Input lat lon: $lat  $lon" if $debug;
  my $flat = POSIX::floor $lat;
  my $flon = POSIX::floor $lon;
  my $ns = $flat < 0 ? "S" : "N";
  my $ew = $flon < 0 ? "W" : "E";
  my $lt = sprintf ("%02s", abs($flat));
  my $ln = sprintf ("%03s", abs($flon));
  my $DEMname = "$ns$lt$ew$ln";
  say STDERR "  Tile lat lon: $flat  $flon" if $debug;
  # read DEM unless already defined
  say STDERR "  Using DEM in memory: '$flat  $flon'" if ($debug and defined $self->{DEMs}{$DEMname}{DEM});
  $self->{DEMs}{$DEMname}{DEM} //= $self->_readDEM($DEMname);  # //= Logical Defined-Or Assignment Operator
  my $dem = $self->{DEMs}{$DEMname}{DEM};
  say STDERR "  Status: $status_descr" if $debug;
  $self->{lat} = $lat;
  $self->{lon} = $lon;
  $self->{status_descr} = $status_descr;
  $self->{switch} = $switch;
  $self->{cache} = $cache;
  $self->{fail} = $fail;
  $self->{DEMname} = $DEMname;
  if (ref($dem) eq "") {
    say STDERR "  No data in DEM: '$flat  $flon' returning elevation 0" if $debug;
    $self->{grid_size} = 0;
    $self->{elevation} = 0;
    return $self->{elevation};
  }
  $grid_size = sqrt (length ($$dem)/2);    # grid size of DEM
  unless ($grid_size == 3601 or $grid_size == 1201) {
    croak "Unknown tile format for '$self->{DEMs}{$DEMname}{DEMpath}': grid size is '$grid_size', should be 3601 or 1201";
  }
  # the DEMs start in the NW corner with $grid_size - 1 intervals
  my $ilat = (1 - ($lat - $flat)) * ($grid_size - 1);
  my $ilon =      ($lon - $flon)  * ($grid_size - 1);
  say STDERR "  Grid size lat lon: $grid_size  $ilat  $ilon" if $debug;
  $self->{grid_size} = $grid_size;
  $self->{elevation} = _interpolate ($dem, $ilat, $ilon);
  return $self->{elevation};
}

sub _interpolate {
  my ($f, $x, $y) = @_;
  my $x1 = POSIX::floor $x;
  my $x2 = POSIX::ceil  $x;
  my $y1 = POSIX::floor $y;
  my $y2 = POSIX::ceil  $y;
  my $f11 = unpack ("s>*", substr ($$f, 2*($x1*$grid_size+$y1), 2));    # unpack signed big-endian 16-bit integer to elevation value
  my $f21 = unpack ("s>*", substr ($$f, 2*($x2*$grid_size+$y1), 2));    # unpack signed big-endian 16-bit integer to elevation value
  my $f12 = unpack ("s>*", substr ($$f, 2*($x1*$grid_size+$y2), 2));    # unpack signed big-endian 16-bit integer to elevation value
  my $f22 = unpack ("s>*", substr ($$f, 2*($x2*$grid_size+$y2), 2));    # unpack signed big-endian 16-bit integer to elevation value
  say STDERR "  Grid corners: ($x1,$y1)  ($x2,$y1)  ($x1,$y2)  ($x2,$y2)" if $debug;
  say STDERR "  Elevation at corners: $f11  $f21  $f12  $f22" if $debug;
  # bilinear interpolation as per https://github.com/racemap/elevation-service/blob/master/hgt.js
  # using the simplifying fact that ($x2-$x1)==1 and ($y2-$y1)==1
  my $xx = $x - $x1;
  my $yy = $y - $y1;
  my $f1 = _avg ($f11, $f21, $xx);
  my $f2 = _avg ($f12, $f22, $xx);
  say STDERR "  Interpolated elevation: "._avg ($f1, $f2, $yy) if $debug;
  return _avg ($f1, $f2, $yy);
}

sub _avg {
  my ($f1, $f2, $x) = @_;
  return $f1 + ($f2 - $f1) * $x;
}

sub _readDEM {
  use IO::Uncompress::AnyUncompress qw(anyuncompress $AnyUncompressError);
  use HTTP::Tiny;
  my ($self, $DEMname) = @_;
  my $nslt = substr($DEMname,0,3);
  my $path_to_hgt_gz = "$nslt/$DEMname.hgt.gz";
  $switch = 0;
  $cache = 0;
  $fail = 0;
  @default_DEMs = ("$path_to_hgt_gz", "$DEMname.zip");
  @want_DEMnames = ("$DEMname.hgt.gz", "$DEMname.zip");
  my $dem;
  $status_descr = -d $folder ? "Folder" : "Url";
  my $path = -d $folder ? _findDEM ($folder) : "$folder/$path_to_hgt_gz";
  if (-e $path) {
    say STDERR "  Reading DEM '$path'" if $debug;
    $self->{DEMs}{$DEMname}{DEMpath}=$path;
    anyuncompress $path => \$dem or croak "anyuncompress failed on '$path': $AnyUncompressError";
    return \$dem;
  }
  unless ($path =~ m/^https?:\/\//) {
    say STDERR "  DEM '$path' not found -> switch to '$url'" if $debug;
    $status_descr .= "->Switch";
    $switch = 1;
  }
  my $cache_path = $cache_folder ne "" ? _findDEM ($cache_folder) : undef;
  if (defined $cache_path and -e $cache_path) {
    say STDERR "  Reading DEM from cache '$cache_path'" if $debug;
    $self->{DEMs}{$DEMname}{DEMpath}=$cache_path;
    $status_descr .= "->Cached";
    $cache = 1;
    anyuncompress $cache_path => \$dem or croak "anyuncompress failed on '$cache_path': $AnyUncompressError";
    return \$dem;
  }
  $path = "$url/$path_to_hgt_gz";
  say STDERR "  Getting DEM '$path'" if $debug;
  $status_descr .= "->Url" unless ($status_descr eq "Url");
  my $response = HTTP::Tiny->new->get($path);    # get gzip archive file .hgt.gz
  unless ($response->{success}) {
    # no success
    carp "  DEM '$path'- $response->{status} $response->{reason}. All of its elevations will read as 0";
    $status_descr .= "->Failed";
    $fail = 1;
    return 0;
  }
  if ($cache_folder ne "" and -d $cache_folder) {
    unless (-d "$cache_folder/$nslt") {mkdir "$cache_folder/$nslt", 0755}
    open my $file_handle, '>', "$cache_path" or croak "'$cache_path' error opening: $!";
    binmode $file_handle;
    print $file_handle $response->{content};
    close $file_handle;
    $status_descr .= "->Saved";
    say STDERR "  Saved DEM cache file '$cache_path'" if $debug;
  }
  $self->{DEMs}{$DEMname}{DEMpath}=$path;
  anyuncompress \$response->{content} => \$dem or croak "anyuncompress failed on '$path': $AnyUncompressError";
  return \$dem;
}

sub _findDEM {
  use File::Find;
  my ($folder) = @_;
  for my $default (@default_DEMs) {
    say STDERR "  Found default DEM '$folder/$default'" if ($debug and -e "$folder/$default");
    return "$folder/$default" if (-e "$folder/$default");
  }
  splice (@DEMnames,0);
  find(\&_wanted, $folder);
  say STDERR "  Found wanted DEM '$DEMnames[0]'" if ($debug and defined $DEMnames[0]);
  return $DEMnames[0] // "$folder/$default_DEMs[0]";
}

sub _wanted {
  use List::Util 'any';
  my $filename = $_;
  push (@DEMnames, $File::Find::name) if any {$_ =~ m/^$filename$/i} @want_DEMnames;     # add file to list if matched
}

1; # End of Geo::Elevation::HGT

__END__

=pod

=encoding utf8

=head1 Name

Geo::Elevation::HGT - Elevation service with terrain data provided by L<Mapzen and Amazon AWS S3|https://registry.opendata.aws/terrain-tiles/>

=head1 Version

Version 0.05

=head1 Synopsis

 use Geo::Elevation::HGT;
 my ($lat, $lon) = (45.8325, 6.86444444444444);    # MontBlanc
 my $geh = Geo::Elevation::HGT->new();
 print $geh->get_elevation_hgt ($lat, $lon)."\n";
 # 4790.99999999998

=head1 Description

This module implements an elevation service with terrain data provided by L<Mapzen and Amazon AWS S3|https://registry.opendata.aws/terrain-tiles/>.

You provide the latitude and longitude in decimal degrees, with south latitude and west longitude being negative.

The return is the elevation for this latitude and longitude in meters.
Bilinear interpolation is applied to the elevations at the four grid points adjacent to the latitude plus longitude pair.

You can also use your own terrain tiles by providing the corresponding path, see below.
A good source for Europe that I am using was compiled by Sonny -- many thanks to him; found at L<https://data.opendataportal.at/dataset/dtm-europe>

In addition you can specify a cache folder for subsequent use of downloaded tiles, see below.

There are only core dependencies

 Carp
 IO::Uncompress::AnyUncompress
 HTTP::Tiny
 POSIX
 File::Find
 List::Util

=head1 Notice

Geo::Elevation::HGT loads the required terrain tiles (from .HGT format files, see below) into the returned object, i.e. into memory.

Any following query requiring the same tile will be much faster since it only involves memory access, instead of a download from the internet.

In a typical application of getting elevations for a gpx track of an outdoor activity, all track points are normally on one tile, maybe two.

To get the elevations of a few thousand gpx track points is therefore normally quite fast.

Here is a benchmark I did on my 2015 NUC5i3RYK with Intel 5010U dual-core processor

=for :list

- 4.5 s for the first elevation with download of the terrain tile from Amazon AWS S3

- 0.5 s for the first elevation with the terrain tile stored on my NAS

- 50,000 elevations per second with the terrain tile in memory

It is the user's responsibility to respect the license and terms of use for the data provided by Mapzen and Amazon AWS S3.

=head1 Example

Get elevation in meters of any latitude plus longitude pair by the 'get_elevation_hgt' method.

Pass latitude and longitude in decimal notation, i.e. 45.8325, 6.86444444444444 for MontBlanc.

  use Geo::Elevation::HGT;

  # Latitude, longitude, elevation of some famous mountains (Wikipedia)
  my @mountains = ( {Denali    => {lat =>   63+( 4*60+ 7)/3600,  lon => -(151+( 0*60+28)/3600), ele_wiki => 6190  } },
                    {Everest   => {lat =>   27+(59*60+16)/3600,  lon =>    86+(55*60+29)/3600 , ele_wiki => 8848  } },
                    {MontBlanc => {lat =>   45+(49*60+57)/3600,  lon =>     6+(51*60+52)/3600 , ele_wiki => 4810  } },
                    {Aconcagua => {lat => -(32+(39*60+13)/3600), lon =>  -(70+(00*60+40)/3600), ele_wiki => 6960.8} } );

  # Get elevations of these famous mountains
  my $geh = Geo::Elevation::HGT->new();
  for my $mountain ( @mountains ) {
    my ($name) = %$mountain;
    my ($lat, $lon, $ele_wiki) = ($mountain->{$name}{'lat'}, $mountain->{$name}{'lon'}, $mountain->{$name}{'ele_wiki'});
    my $ele_geh = $geh->get_elevation_hgt ($lat, $lon);
    print join( ' ', $name, $lat, $lon, $ele_wiki, $ele_geh, $ele_geh-$ele_wiki, "\n");
  }

  # returns
  # Denali 63.0686111111111 -151.007777777778 6190 6126.9999999999 -63.0000000000955
  # Everest 27.9877777777778 86.9247222222222 8848 8713.0000000001 -134.999999999898
  # MontBlanc 45.8325 6.86444444444444 4810 4791.00000000002 -18.9999999999764
  # Aconcagua -32.6536111111111 -70.0111111111111 6960.8 6923.00000000011 -37.7999999998856

The elevations returned for these famous mountains are lower than their effective ones since the underlying data, which originate from SRTM (Shuttle Radar Topography Mission) and other sources, smooth peaks and thereby show them lower than commonly known.

Nevertheless the elevations returned should be useful to obtain a good representation of the elevation profile of a gpx track.

According to my experience these are much better than elevations recorded by a gps logger on a mobile phone.
Such elevation data include a lot of noise with erratic jumps by 100 m.

=head1 Methods

=head2 new

C<$geh = Geo::Elevation::HGT-E<gt>new( %parameters )>

Constructor, returns a new Geo::Elevation::HGT object.

Valid parameters, all optional:

=for :list

* C<folder> - the path to a folder where the terrain tiles to use are stored; no default

* C<url> - the url of the terrain tiles to use; default C<https://elevation-tiles-prod.s3.amazonaws.com/skadi>

* C<cache_folder> path to an existing folder where the terrain tiles downloaded from C<$geh-E<gt>{url}> will be stored for subsequent use; no default

Note that cache will not expire and will have to be cleared from outside of C<Geo::Elevation::HGT>. Thinking is that terrain data will not change very frequently.

* C<debug> - set to 1 to get some debug output to STDERR; default 0

=head2 get_elevation_hgt

C<$ele_geh = $geh-E<gt>get_elevation_hgt ($lat, $lon)>

Arguments: latitude and longitude in decimal degrees, with south latitude and west longitude being negative

Returns the elevation for this latitude and longitude in meters

=head3 Flags

=for :list

* C<$geh-E<gt>{switch}> - is set to 1 in case a required tile is not found under the C<$geh-E<gt>{folder}> path in which case the data source is switched to C<$geh-E<gt>{url}>; otherwise 0

* C<$geh-E<gt>{cache}> - is set to 1 in case a required tile is used from C<$geh-E<gt>{cache_folder}>; otherwise 0

* C<$geh-E<gt>{fail}> - is set to 1 in case access to a required tile under C<$geh-E<gt>{url}> fails in which case all corresponding elevations will be set to 0; otherwise 0.

=head3 Status Description

=for :list

* C<$geh-E<gt>{status_descr}> - is set to a string describing how the terrain tile was found, using the following key words, or a combination thereof

- C<Memory> - the tile was in memory from a previous call

- C<Folder> - the user provided a valid folder path, if nothing follows the tile was found and used

- C<Switch> - the tile was not found under the C<$geh-E<gt>{folder}> path

- C<Cached> - the tile was found under the C<$geh-E<gt>{cache_folder}> path

- C<Url>    - the tile was downloaded from the C<$geh-E<gt>{url}> path, unless subsequent C<Failed> indicates failure

- C<Failed> - access to the tile under C<$geh-E<gt>{url}> failed

- C<Saved>  - the downloaded tile was saved to cache under the C<$geh-E<gt>{cache_folder}> path

=head2 get_elevation_batch_hgt

C<$ele_geh = $geh-E<gt>get_elevation_batch_hgt ($latlon)>

Argument: an array reference with arrays of latitude-longitude pairs, i.e. C<[[lat1, lon1], [lat2, lon2], ...]>

Returns an array reference with the associated elevations C<[ele1, ele2, ...]>

Provided for user convenience. Calls method C<get_elevation_hgt> in turn for every latitude-longitude pair.

Flags and Status Description reflect the state after the call with the last latitude-longitude pair.

=head1 HGT DEM (digital elevation model) files

The names of individual DEM files refer to the latitude and longitude of the lower-left (south-west) corner of the tile.

e.g. N37W105 has its lower left corner at 37 degrees north latitude and 105 degrees west longitude.

The DEM is provided as 16-bit signed integer data in a simple binary raster.

There are no header or trailer bytes embedded in the file.

Each file is a series of signed 16-bit integers (two bytes) giving the height of each cell in meters arranged from west to east and then north to south.

Elevations are in meters referenced to the WGS84/EGM96 geoid.

Byte order is Motorola ("big-endian") standard with the most significant byte first.

Grid size is 3601x3601 for 1-minute DEMs or 1201x1201 for 3-minute DEMs.

The rows at the north and south edges as well as the columns at the east and west edges of each cell overlap and are identical to the edge rows and columns in the adjacent cell.

=head1 HGT directory tree

C<https://elevation-tiles-prod.s3.amazonaws.com/skadi> stores HGT files in subdirectories by their latitude

 ...
 ├── N45
 │   ├── N45E000.hgt.gz
 │   ├── N45E001.hgt.gz
 │   ├── N45E002.hgt.gz
 ...
 ├── N46
 │   ├── N46E000.hgt.gz
 │   ├── N46E001.hgt.gz
 │   ├── N46E002.hgt.gz
 ...
 ├── S46
 │   ├── S46W000.hgt.gz
 │   ├── S46W001.hgt.gz
 │   ├── S46W002.hgt.gz
 ...

C<$geh-E<gt>{folder}> will work without following the above storage pattern, as long as a file with the correct name is found somewhere under that path.

Similarly, C<$geh-E<gt>{cache}> will be built to the above storage pattern, but will also work if files are stored in any other way under that path.

HGT files need to be compressed to GNU zip (gzip) or ZIP (zip) compression format with .hgt.gz or .zip file extension, respectively.

=head1 Author

Ulrich Buck, C<< <ulibuck at cpan.org> >>

=head1 Bugs

Please report any bugs or feature requests to C<bug-geo-elevation-hgt at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Elevation-HGT>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 Support

You can find documentation for this module with the perldoc command.

    perldoc Geo::Elevation::HGT

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Elevation-HGT>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-Elevation-HGT>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Geo-Elevation-HGT>

=item * Search CPAN

L<https://metacpan.org/release/Geo-Elevation-HGT>

=back

=head1 Acknowledgements

Inspired by

L<racemap Elevation service|https://github.com/racemap/elevation-service>

L<Using DEMs to get GPX elevation profiles|http://notes.secretsauce.net/notes/2014/03/18_using-dems-to-get-gpx-elevation-profiles.html>

plus others

=head1 License and Copyright

This software is Copyright (c) 2020 by Ulrich Buck.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

