#! perl

use 5.006001;
use strict;
use warnings;
use Geo::OSM::Tiles qw( :all );
use LWP::UserAgent;
use YAML qw( DumpFile LoadFile );
use File::Path;
use File::Basename;
use File::Spec;
use Cwd qw(cwd);
use Getopt::Long;

our $linkrgoffs = 350.0;

our $usage = qq{Usage: 
   $0 --latitude=d[:d] --longitude=d[:d] --zoom=z[:z] [--quiet] [--baseurl=url] [--destdir=dir] [--dumptilelist=filename]
   $0 --link=url [--latitude=d[:d]] [--longitude=d[:d]] [--zoom=z[:z]] [--quiet] [--baseurl=url] [--destdir=dir] [--dumptilelist=filename]
   $0 --loadtilelist=filename
};

our %opt = (
    latitude => undef,
    longitude => undef,
    zoom => undef,
    link => undef,
    quiet => undef,
    baseurl => "http://tile.openstreetmap.org",
    destdir => cwd,
    dumptilelist => undef,
    loadtilelist => undef,
);

die "$usage\n"
    unless GetOptions(\%opt,
		      "latitude=s", "longitude=s", "zoom=s", "link=s",
		      "quiet", "baseurl=s", "destdir=s", 
		      "dumptilelist=s", "loadtilelist=s") &&
	   @ARGV == 0;

sub selecttilescmdline;
sub downloadtiles;
sub parserealopt;
sub parseintopt;
sub downloadtile;


# List of tiles scheduled for download.
# Format:
# $tilelist = {
#     zoomlevel => [
# 	{
# 	    xyz => [ tx, ty, tz ],
# 	},
# 	{
# 	    xyz => [ tx, ty, tz ],
# 	},
# 	...
#     ],
#     zoomlevel => [
# 	{
# 	    xyz => [ tx, ty, tz ],
# 	},
# 	{
# 	    xyz => [ tx, ty, tz ],
# 	},
# 	...
#     ],
#     ...
# };
our $tilelist;

# In the current version we keep things simple, the tiles have to be
# selected either by the command line options --link, --lat, --lon,
# and --zoom or read from the file as given by --loadtilelist.  In a
# future version, it might be possible to combine both ways.
if ($opt{loadtilelist}) {
    $tilelist = LoadFile($opt{loadtilelist});
}
else {
    $tilelist = selecttilescmdline;
}

our $baseurl = $opt{baseurl};
our $destdir = $opt{destdir};

if ($opt{dumptilelist}) {
    DumpFile($opt{dumptilelist}, $tilelist);
}
else {
    downloadtiles($tilelist);
}



# Select tiles from command line options
sub selecttilescmdline
{
    if ($opt{link}) {
	die "Invalid link: $opt{link}\n"
	    unless $opt{link} =~ /^http:\/\/.*\/\?lat=(-?\d+(?:\.\d+)?)\&lon=(-?\d+(?:\.\d+)?)\&zoom=(\d+)/;
	my $lat = $1;
	my $lon = $2;
	my $zoom = $3;
	my $offs = $linkrgoffs / 2**$zoom;

	# Note that ($lat - $offs, $lat + $offs) or
	# ($lon - $offs, $lon + $offs) may get out of the acceptable
	# range of coordinates.  This will eventually get corrected by
	# checklatrange or checklonrange later on.

	$opt{latitude} = [ $lat - $offs, $lat + $offs ]
	    unless defined($opt{latitude});
	$opt{longitude} = [ $lon - $offs, $lon + $offs ]
	    unless defined($opt{longitude});
	$opt{zoom} = $zoom
	    unless defined($opt{zoom});
    }

    my ($latmin, $latmax) = checklatrange(parserealopt("latitude"));
    my ($lonmin, $lonmax) = checklonrange(parserealopt("longitude"));
    my ($zoommin, $zoommax) = parseintopt("zoom");

    my $tl = {};

    for my $zoom ($zoommin..$zoommax) {

	my $txmin = lon2tilex($lonmin, $zoom);
	my $txmax = lon2tilex($lonmax, $zoom);
	# Note that y=0 is near lat=+85.0511 and y=max is near
	# lat=-85.0511, so lat2tiley is monotonically decreasing.
	my $tymin = lat2tiley($latmax, $zoom);
	my $tymax = lat2tiley($latmin, $zoom);

	my $ntx = $txmax - $txmin + 1;
	my $nty = $tymax - $tymin + 1;
	printf "Schedule %d (%d x %d) tiles for zoom level %d for download ...\n",
	       $ntx*$nty, $ntx, $nty, $zoom
	    unless $opt{quiet};
	$tl->{$zoom} = [];    

	for my $tx ($txmin..$txmax) {
	    for my $ty ($tymin..$tymax) {
		push @{$tl->{$zoom}}, 
		    { xyz => [ $tx, $ty, $zoom ] };
	    }
	}
    }

    return $tl;
}


sub downloadtiles
{
    my $tiles = shift;

    my $lwpua = LWP::UserAgent->new;
    $lwpua->env_proxy;

    for my $zoom (sort {$a <=> $b} keys %$tiles) {

	printf "Download %d tiles for zoom level %d ...\n",
	       scalar(@{$tiles->{$zoom}}), $zoom
	    unless $opt{quiet};

	for my $t (@{$tiles->{$zoom}}) {
	    downloadtile($lwpua, @{$t->{xyz}});
	}
    }
}


sub parserealopt
{
    my ($optname) = @_;

    die "$optname must be specified in the command line.\n"
	unless defined($opt{$optname});

    if (ref($opt{$optname})) {
	return @{$opt{$optname}};
    }
    else {
	die "Invalid $optname: $opt{$optname}\n"
	    unless $opt{$optname} =~ /^(-?\d+(?:\.\d+)?)(?::(-?\d+(?:\.\d+)?))?$/;
	my ($min, $max) = ($1, $2);
	$max = $min unless defined($max);

	return ($min, $max);
    }
}


sub parseintopt
{
    my ($optname) = @_;

    die "$optname must be specified in the command line.\n"
	unless defined($opt{$optname});

    if (ref($opt{$optname})) {
	return @{$opt{$optname}};
    }
    else {
	die "Invalid $optname: $opt{$optname}\n"
	    unless $opt{$optname} =~ /^(\d+)(?::(\d+))?$/;
	my ($min, $max) = ($1, $2);
	$max = $min unless defined($max);

	return ($min, $max);
    }
}


sub downloadtile
{
    my ($lwpua, $tilex, $tiley, $zoom) = @_;
    my $path = tile2path($tilex, $tiley, $zoom);
    my $url = "$baseurl/$path";
    my @pathcomp = split /\//, $path;
    my $fname = File::Spec->catfile($destdir, @pathcomp);

    mkpath(dirname($fname));
    my $res = $lwpua->get($url, ':content_file' => $fname);
    die $res->status_line
	unless $res->is_success;
}


__END__
=head1 NAME

downloadosmtiles.pl - Download map tiles from OpenStreetMap

=head1 SYNOPSIS

  downloadosmtiles.pl --lat=49.5611:49.6282 --lon=10.951:11.0574 --zoom=13:14
  downloadosmtiles.pl --link='http://www.openstreetmap.org/?lat=-23.5872&lon=-46.6508&zoom=12&layers=B000FTF'
  downloadosmtiles.pl --loadtilelist=filename

=head1 DESCRIPTION

This script downloads all map tiles from an OpenStreetMap tile server
for some geographic region in a range of zoom levels.  The PNG images
of the tiles are stored in a directory tree that mirrors the paths
from the server.

A bounding box of geographic coordinates and a range of zoom levels
must be selected by command line options.

=head1 COMMAND LINE OPTIONS

Command line options may be abbreviated as long as they remain
unambiguous.

At least either C<--latitude>, C<--longitude>, and C<--zoom> or
C<--link> must be specified.

=head2 C<--latitude=latmin[:latmax]>

Selects the latitude of the bounding box of coordinates to download.
May be one single real value or two real values separated by a colon
in the range C<-85.0511..85.0511>.  If given only one value, just the
tile (or row of tiles) at this latitude will be downloaded.

Default: none

=head2 C<--longitude=lonmin[:lonmax]>

Selects the longitude of the bounding box of coordinates to download.
May be one single real value or two real values separated by a colon
in the range C<-180.0..180.0>.  If given only one value, just the tile
(or column of tiles) at this longitude will be downloaded.

Default: none

=head2 C<--zoom=zoommin[:zoommax]>

Selects the range of zoom levels to download the map tiles for.  May
be one single integer value or two integer values separated by a
colon.  OpenStreetMap supports zoom levels in the range C<0..18>.
(This depends on the base URL and is not enforced by this script.)

Note that the number of tiles to download grows by a factor of up to
four with each zoom level.

Default: none

=head2 C<--link=url>

An URL selecting C<--latitude>, C<--longitude>, and C<--zoom> in one
argument.  The idea is to select the current view of OSM's slippy map
by its permalink.

The argument to C<--link> must be an URL containing the HTTP options
C<?lat=s&lon=s&zoom=s>.  (Actually, the base URL will be ignored.)
The script chooses a box around the latitude and longitude options.
The size of the box depends on the zoom option.

If combined with C<--latitude>, C<--longitude>, or C<--zoom>, these
explicitly specified values override the implicitly specified values
from C<--link>.

Default: none

=head2 C<--baseurl=url>

The base URL of the server to download the tiles from.

Default: L<http://tile.openstreetmap.org>
(This is the base URL for the Mapnik tiles.)

=head2 C<--destdir=dir>

The directory where the tiles will be stored.  The PNG files will be
stored as C<dir/zoom/x/y.png>.

Default: The current working directory.

=head2 C<--quiet>

Do not write any diagnostic messages.  Only fatal errors will be
reported.

=head2 C<--dumptilelist=filename>

Do not download any tiles at all, but write a list of tiles as
selected by other command line options to the file named C<filename>.
See L</TILE LISTS> below.

=head2 C<--loadtilelist=filename>

Read a list of tiles to download from the file C<filename>.  See
L</TILE LISTS> below.

=head1 EXAMPLE

Select the region of interest in OSM's slippy map and follow the
permalink in the lower left of the window.  Lets assume this permalink
to be
L<http://www.openstreetmap.org/?lat=49.5782&lon=11.0076&zoom=12&layers=B000FTF>.
Then

  downloadosmtiles.pl --link='http://www.openstreetmap.org/?lat=49.5782&lon=11.0076&zoom=12&layers=B000FTF' --zoom=5:18

will download all tiles from zoom level 5 to 18 for this region.

=head1 TILE LISTS

A list of tiles may be stored to and retrieved from external files
using the C<--dumptilelist> and C<--loadtilelist> command line
options.  A set of tiles may be selected using the command line
options C<--latitude>, C<--longitude>, C<--zoom>, and C<--link> and
written to a file specified with C<--dumptilelist>.  This list may be
read at a later date using the C<--loadtilelist> option.

This may be useful to postpone the download of the tiles, to edit the
list of tiles, or to use some external tool to generate this list.

The tile lists are read and written in L<YAML> format.  Please note
that this is an experimental feature in the current version.  The file
format is not considered stable yet.  There is no guarantee that a
list of tiles generated by one version of this script may be read in
by a future version.

=head1 ENVIRONMENT

=over

=item http_proxy

=item ftp_proxy

=item xxx_proxy

=item no_proxy

These environment variables can be set to enable communication through
a proxy server.  This is implemented by L<LWP::UserAgent>.

=back

=head1 BUGS

=over

=item *

Ranges in the command line options must always be increasing.  While
this is considered a feature for C<--latitude> and C<--zoom>, it means
that it is impossible for a range in the C<--longitude> argument to
cross the 180 degree line.  A command line option like
C<--longitude=179.5:-179.5> will not work as one should expect.

=item *

The bounding box selected by the C<--link> command line option does
not always correspond to the current view in the slippy map.  The
problem is that the permalink from the slippy map only contains one
position and not the bounds of the current view.  The actual view of
the slippy map depends on many factors, including the size of the
browser window.  Thus, there is not much that can be done about this
issue.

=back

=head1 SEE ALSO

L<http://wiki.openstreetmap.org/wiki/Slippy_Map>

=head1 AUTHOR

Rolf Krahl E<lt>rotkraut@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2008-2010 by Rolf Krahl

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
