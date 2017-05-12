package Mac::iTunes::Library::Item;

use 5.006;
use warnings;
use strict;
use Carp;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );

our $VERSION = '1.0';

=head1 NAME

Mac::iTunes::Library::Item - Perl extension for representing an item
(song, URL, video) within an iTunes library.

=head1 SYNOPSIS

  use Mac::iTunes::Library::Item;

  my $item = Mac::iTunes::Library::Item->new(
        'Track ID' => 1,
        'Name' => 'The Fooiest Song',
        'Artist' => 'The Bar Band',
        );
  $item->genre('Ska');
  print "We are the " . $item->artist() . " and we play " .
  $item->genre() . " music\n";
  print "Enjoy our hit song " . $item->name() . "\n";

=head1 DESCRIPTION

A data structure for representing an item (song, URL, video) within an iTunes
library.  Use this along with Mac::iTunes::Library to create an iTunes library
from which other information can be gleaned.

=head1 EXPORT

None by default.

=head1 METHODS

=head2 new()

Creates a new Mac::iTunes::Library::Item object that can store all of the data
of an iTunes library item.

    my $rec = Mac::iTunes::Library::Item->new();

The constructor can also be called initializing any number of the attributes of
an item

    my $rec = Mac::iTunes::Library::Item->new(
        'Track ID' => '73',
        'Name' => 'Josie',
        'Artist' => 'blink-182',
        'Album Artist' => 'blink-182',
        'Composer' => 'blink-182',
        'Album' => 'Dude Ranch',
        'Grouping' => 'Alternative Rock, 00s Rock'
        'Genre' => 'Pop Punk',
        'Kind' => 'MPEG audio file',
        'Size' => 31337,
        'Total Time' => 31337,
        'Year' => '2007',
        'Date Modified' => '2007-01-01T01:01:01Z',
        'Date Added' => '2007-01-01T01:01:01Z',
        'Bit Rate' => 256,
        'Sample Rate' => 44100,
        'Play Count' => 1,
        'Play Date' => -1167613261,
        'Play Date UTC' => '2007-01-01T01:01:01Z',
        'Skip Count' => 1,
        'Skip Count UTC' => '2007-01-01T01:01:01Z',
        'Rating' => 50,
        'Album Rating' => 50,
        'Album Rating Computed' => 1,
        'Compilation' => 1,
        'Persistent ID' => 'DAC2FC501CCA2031',
        'Track Type' => 'File',
        'Location' => 'file://localhost/Users/dinomite/Music/blink-182/Dude%20Ranch/Josie.mp3',
        'File Folder Count' => 4,
        'Library Folder Count' => 1
    );

=cut

sub new {
    my $class = shift;
    my %params = @_;

    # Initialize
    my $self = {
        'Track ID' => undef,
        'Name' => undef,
        'Artist' => undef,
        'Album Artist' => undef,
        'Composer' => undef,
        'Album' => undef,
        'Grouping' => undef,
        'Genre' => undef,
        'Kind' => undef,
        'Size' => undef,
        'Total Time' => undef,
        'Year' => undef,
        'Date Modified' => undef,
        'Date Added' => undef,
        'Bit Rate' => undef,
        'Comments' => undef,
        'Sample Rate' => undef,
        'Play Count' => undef,
        'Play Date' => undef,
        'Play Date UTC' => undef,
        'Release Date' => undef,
        'Skip Count' => undef,
        'Skip Count UTC' => undef,
        'Rating' => undef,
        'Album Rating' => undef,
        'Album Rating Computed' => undef,
        'Compilation' => undef,
        'Persistent ID' => undef,
        'Track Type' => undef,
        'iTunesU' => undef,
        'Location' => undef,
        'File Folder Count' => undef,
        'Library Folder Count' => undef,
        'Track Count'   => undef,
        'Track Number'  => undef,
    };

    bless $self, $class;

    # Deal with parameters
    foreach my $param (keys %params) {
        next unless (defined $param);

        if ($param eq 'Track ID') { trackID($self, $params{'Track ID'}) }
        elsif ($param eq 'Name') { name($self, $params{'Name'}) }
        elsif ($param eq 'Artist') { artist($self, $params{'Artist'}) }
        elsif ($param eq 'Album Artist') { albumArtist($self, $params{'Album Artist'}) }
        elsif ($param eq 'Composer') { composer($self, $params{'Composer'}) }
        elsif ($param eq 'Album') { album($self, $params{'Album'}) }
        elsif ($param eq 'Grouping') { grouping($self, $params{'Grouping'}) }
        elsif ($param eq 'Genre') { genre($self, $params{'Genre'}) }
        elsif ($param eq 'Kind') { kind($self, $params{'Kind'}) }
        elsif ($param eq 'Size') { size($self, $params{'Size'}) }
        elsif ($param eq 'Total Time') { totalTime($self, $params{'Total Time'}) }
        elsif ($param eq 'Year') { year($self, $params{'Year'}) }
        elsif ($param eq 'Date Modified') { dateModified($self, $params{'Date Modified'}) }
        elsif ($param eq 'Date Added') { dateAdded($self, $params{'Date Added'}) }
        elsif ($param eq 'Bit Rate') { bitRate($self, $params{'Bit Rate'}) }
        elsif ($param eq 'Comments') { comments($self, $params{'Comments'}) }
        elsif ($param eq 'Sample Rate') { sampleRate($self, $params{'Sample Rate'}) }
        elsif ($param eq 'Play Count') { playCount($self, $params{'Play Count'}) }
        elsif ($param eq 'Play Date') { playDate($self, $params{'Play Date'}) }
        elsif ($param eq 'Play Date UTC') { playDateUTC($self, $params{'Play Date UTC'}) }
        elsif ($param eq 'Release Date') { releaseDate($self, $params{'Release Date'}) }
        elsif ($param eq 'Skip Count') { skipCount($self, $params{'Skip Count'}) }
        elsif ($param eq 'Skip Date') { skipDate($self, $params{'Skip Date'}) }
        elsif ($param eq 'Rating') { rating($self, $params{'Rating'}) }
        elsif ($param eq 'Album Rating') { albumRating($self, $params{'Album Rating'}) }
        elsif ($param eq 'Album Rating Computed') { albumRatingComputed($self, $params{'Album Rating Computed'}) }
        elsif ($param eq 'Compilation') { compilation($self, $params{'Compilation'}) }
        elsif ($param eq 'Persistent ID') { persistentID($self, $params{'Persistent ID'}) }
        elsif ($param eq 'Track Type') { trackType($self, $params{'Track Type'}) }
        elsif ($param eq 'iTunesU') { iTunesU($self, $params{'iTunesU'}) }        
        elsif ($param eq 'Location') { location($self, $params{'Location'}) }
        elsif ($param eq 'File Folder Count') { fileFolderCount($self, $params{'File Folder Count'}) }
        elsif ($param eq 'Library Folder Count') { libraryFolderCount($self, $params{'Library Folder Count'}) }
        elsif ($param eq 'Track Count') { trackCount($self, $params{'Track Count'}) }
        elsif ($param eq 'Track Number') { trackNumber($self, $params{'Track Number'}) }
        else { print "Param that I can't handle: $param\n" }
    }

    return $self;
} #new

# Clean up
sub DESTROY {
# Nothing to do.
} #DESTROY

=head2 trackID( $id )

Get/set the Track ID attribute for this item.

=cut

sub trackID {
    my $self = shift;

    if (@_) {
        my $id = shift;
        return carp "$id isn't a valid Track ID" unless _checkNum($id);
        $self->{'Track ID'} = $id;
    }

    return $self->{'Track ID'};
} #trackID

# Get/set the Name for this item
sub name {
    my $self = shift;

    if (@_) {
        my $name = shift;
        return carp "$name isn't a valid Name" unless ($name =~ /.*/);
        $self->{'Name'} = $name;
    }

    return $self->{'Name'};
} #name

=head2 artist( $artist )

Get/set the Artist attribute for this item.

=cut

sub artist {
    my $self = shift;

    if (@_) {
        my $artist = shift;
        return carp "$artist isn't a valid Artist" unless ($artist =~ /.*/);
        $self->{'Artist'} = $artist;
    }

    return $self->{'Artist'};
} #artist

=head2 albumArtist( $albumArtist )

Get/set the Album Artist attribute for this item.

=cut

sub albumArtist {
    my $self = shift;

    if (@_) {
        my $albumArtist = shift;
        return carp "$albumArtist isn't a valid Album Artist"
                unless ($albumArtist =~ /.*/);
        $self->{'Album Artist'} = $albumArtist;
    }

    return $self->{'Album Artist'};
} #albumArtist

=head2 composer( $composer )

Get/set the Composer attribute for this item.

=cut

sub composer {
    my $self = shift;

    if (@_) {
        my $composer = shift;
        return carp "$composer isn't a valid Composer"
                unless ($composer =~ /.*/);
        $self->{'Composer'} = $composer;
    }

    return $self->{'Composer'};
} #composer

=head2 album( $album )

Get/set the Album attribute for this item.

=cut

sub album {
    my $self = shift;

    if (@_) {
        my $album = shift;
        return carp "$album isn't a valid Album" unless ($album =~ /.*/);
        $self->{'Album'} = $album;
    }

    return $self->{'Album'};
} #album

=head2 grouping( $grouping )

Get/set the Grouping attribute for this item.

Note: Grouping is intended to be used as a collection of music items below
the level of an album (such as on a classical music release) where items
are individual movements of a larger work.  They are more commonly
used as a comma delimited list of tags to build smart playlists.

=cut

sub grouping {
    my $self = shift;

    if (@_) {
        my $grouping = shift;
        return carp "$grouping isn't a valid Grouping" unless ($grouping =~ /.*/);
        $self->{'Grouping'} = $grouping;
    }

    return $self->{'Grouping'};
} #grouping

=head2 genre( $genre )

Get/set the Genre attribute for this item.

=cut

sub genre {
    my $self = shift;

    if (@_) {
        my $genre = shift;
        return carp "$genre isn't a valid Genre" unless ($genre =~ /.*/);
        $self->{'Genre'} = $genre;
    }

    return $self->{'Genre'};
} #genre

=head2 kind( $kind )

Get/set the Kind ("MPEG audio file", etc.) attribute for this item.

=cut

sub kind {
    my $self = shift;

    if (@_) {
        my $kind = shift;
        return carp "$kind isn't a valid Kind"
                unless ($kind =~ /(MPEG|AAC|MPEG-4|Audible) ?(audio|video)? (file|stream)/);
        $self->{'Kind'} = $kind;
    }

    return $self->{'Kind'};
} #kind

=head2 size( $size )

Get/set the Size attribute for this item.

=cut

sub size {
    my $self = shift;

    if (@_) {
        my $size = shift;
        return carp "$size isn't a valid Size" unless _checkNum($size);
        $self->{'Size'} = $size;
    }

    return $self->{'Size'};
} #size

=head2 totalTime( $totalTime )

Get/set the Total Time attribute for this item.

=cut

sub totalTime {
    my $self = shift;

    if (@_) {
        my $totalTime = shift;
        return carp "$totalTime isn't a valid Total Time"
                unless _checkNum($totalTime);
        $self->{'Total Time'} = $totalTime;
    }

    return $self->{'Total Time'};
} #totalTime

=head2 year( $year )

Get/set the Year attribute for this item.

=cut

sub year {
    my $self = shift;

    if (@_) {
        my $year = shift;
        return carp "$year isn't a valid Year" unless ($year =~ /\d{4}/);
        $self->{'Year'} = $year;
    }

    return $self->{'Year'};
} #year

=head2 dateModified( $dateModified )

Get/set the Date Modified attribute for this item.

=cut

sub dateModified {
    my $self = shift;

    if (@_) {
        my $dateModified = shift;
        return carp "$dateModified isn't a valid Date Modified"
                unless _checkDate($dateModified);
        $self->{'Date Modified'} = $dateModified;
    }

    return $self->{'Date Modified'};
} #dateModified

=head2 dateAdded( $dateAdded )

Get/set the Date Added attribute for this item.

=cut

sub dateAdded {
    my $self = shift;

    if (@_) {
        my $dateAdded = shift;
        return carp "$dateAdded isn't a valid Date Added"
                unless _checkDate($dateAdded);
        $self->{'Date Added'} = $dateAdded;
    }

    return $self->{'Date Added'};
} #dateAdded

=head2 bitRate( $bitRate )

Get/set the Date Added attribute for this item.

=cut

sub bitRate {
    my $self = shift;

    if (@_) {
        my $bitRate = shift;
        return carp "$bitRate isn't a valid Bit Rate"
                unless ($bitRate =~ /\d{2,3}/);
        $self->{'Bit Rate'} = $bitRate;
    }

    return $self->{'Bit Rate'};
} #bitRate

=head2 comments( $comments )

Get/set the Comments attribute for this item.

=cut

sub comments {
    my $self = shift;

    if (@_) {
        my $comments = shift;
        return carp "$comments isn't a valid Comments" unless ($comments =~ /.*/);
        $self->{'Comments'} = $comments;
    }

    return $self->{'Comments'};
} #comment

=head2 sampleRate( $sampleRate )

Get/set the Sample Rate attribute for this item.

=cut

sub sampleRate {
    my $self = shift;

    if (@_) {
        my $sampleRate = shift;
        return carp "$sampleRate isn't a valid Sample Rate"
            unless ($sampleRate =~ /\d{5}/);
        $self->{'Sample Rate'} = $sampleRate;
    }

    return $self->{'Sample Rate'};
} #sampleRate

=head2 playCount( $playCount )

Get/set the Play Count attribute for this item.

=cut

sub playCount {
    my $self = shift;

    if (@_) {
        my $playCount = shift;
        return carp "$playCount isn't a valid Play Count"
            unless ($playCount =~ /\d{1,2}/);
        $self->{'Play Count'} = $playCount;
    }

    return $self->{'Play Count'};
} #playCount

=head2 playDate( $playDate )

Get/set the Play Date attribute for this item.

=cut

sub playDate {
    my $self = shift;

    if (@_) {
        my $playDate = shift;
        return carp "$playDate isn't a valid Play Date"
                unless ($playDate =~ /-\d{10}/);
        $self->{'Play Date'} = $playDate;
    }

    return $self->{'Play Date'};
} #playDate

=head2 playDateUTC( $playDateUTC )

Get/set the Play Date UTC attribute for this item.

=cut

sub playDateUTC {
    my $self = shift;

    if (@_) {
        my $playDateUTC = shift;
        return carp "$playDateUTC isn't a valid Play Date UTC"
                unless _checkDate($playDateUTC);
        $self->{'Play Date UTC'} = $playDateUTC;
    }

    return $self->{'Play Date UTC'};
} #playDateUTC

=head2 releaseDate( $releaseDate )

Get/set the Release Date attribute for this item.

=cut

sub releaseDate {
    my $self = shift;

    if (@_) {
        my $releaseDate = shift;
        return carp "$releaseDate isn't a valid Release Date"
                unless _checkDate($releaseDate);
        $self->{'Release Date'} = $releaseDate;
    }

    return $self->{'Release Date'};
} #releaseDate

=head2 skipCount( $skipCount )

Get/set the Skip Count attribute for this item.

=cut

sub skipCount {
    my $self = shift;

    if (@_) {
        my $skipCount = shift;
        return carp "$skipCount isn't a valid Skip Count"
                unless ($skipCount =~ /\d{1,2}/);
        $self->{'Skip Count'} = $skipCount;
    }

    return $self->{'Skip Count'};
} #skipCount

=head2 skipDate( $skipDate )

Get/set the Skip Date attribute for this item.

=cut

sub skipDate {
    my $self = shift;

    if (@_) {
        my $skipDate = shift;
        return carp "$skipDate isn't a valid Skip Date"
                unless _checkDate($skipDate);
        $self->{'Skip Date'} = $skipDate;
    }

    return $self->{'Skip Date'};
} #skipDate

=head2 rating( $rating )

Get/set the Rating attribute for this item.

=cut

sub rating {
    my $self = shift;

    if (@_) {
        my $rating = shift;
        return carp "$rating isn't a valid Rating"
                unless ($rating =~ /\d{1,3}/);
        $self->{'Rating'} = $rating;
    }

    return $self->{'Rating'};
} #rating

=head2 albumRating( $albumRating )

Get/set the Album Rating attribute for this item.

=cut

sub albumRating {
    my $self = shift;

    if (@_) {
        my $albumRating = shift;
        return carp "$albumRating isn't a valid Album Rating"
            unless ($albumRating =~ /\d{1,3}/);
        $self->{'Album Rating'} = $albumRating;
    }

    return $self->{'Album Rating'};
} #albumRating

=head2 albumRatingComputed( $albumRatingComputed )

Get/set the Album Rating Computed attribute for this item.

=cut

sub albumRatingComputed {
    my $self = shift;

    if (@_) {
        my $albumRatingComputed = shift;
        $self->{'Album Rating Computed'} = $albumRatingComputed;
    }

    return $self->{'Album Rating Computed'};
} #albumRatingComputed

=head2 compilation( $albumRatingComputed )

Get/set the Compilation attribute for this item.

=cut

sub compilation {
    my $self = shift;

    if (@_) {
        my $compilation = shift;
        $self->{'Compilation'} = $compilation;
    }

    return $self->{'Compilation'};
} #compilation

=head2 persistentID( $persistentID )

Get/set the Persistent ID attribute for this item.

=cut

sub persistentID {
    my $self = shift;

    if (@_) {
        my $persistentID = shift;
        return carp "$persistentID isn't a valid Persistent ID"
                unless ($persistentID =~ /\w{16}/);
        $self->{'Persistent ID'} = $persistentID;
    }

    return $self->{'Persistent ID'};
} #persistentID

=head2 trackType( $trackType )

Get/set the Track Type attribute for this item.

=cut

sub trackType {
    my $self = shift;

    if (@_) {
        my $trackType = shift;
        return carp "$trackType isn't a valid Track Type"
                unless ($trackType =~ /(File|URL)/);
        $self->{'Track Type'} = $trackType;
    }

    return $self->{'Track Type'};
} #trackType

=head2 iTunesU( $trackType )

Get/set the iTunesU attribute for this item.

=cut

sub iTunesU {
    my $self = shift;

    if (@_) {
        my $iTunesU = shift;
        return carp "$iTunesU isn't a valid iTunesU"
                unless ($iTunesU =~ /(Y|N)/);
        $self->{'iTunesU'} = $iTunesU;
    }

    return $self->{'iTunesU'};
} #iTunesU


=head2 location( $location )

Get/set the Location attribute for this item.

=cut

sub location {
    my $self = shift;

    if (@_) {
        my $location = shift;
        return carp "$location isn't a valid Location"
                unless ($location =~ /.*/);
        $self->{'Location'} = $location;
    }

    return $self->{'Location'};
} #location

=head2 fileFolderCount( $fileFolderCount )

Get/set the File Folder Count attribute for this item.

=cut
# Get/set the File Folder Count for this item
sub fileFolderCount {
    my $self = shift;

    if (@_) {
        my $fileFolderCount = shift;
        return carp "$fileFolderCount isn't a valid File Folder Count"
            unless _checkNum($fileFolderCount);
        $self->{'File Folder Count'} = $fileFolderCount;
    }

    return $self->{'File Folder Count'};
} #fileFolderCount

=head2 libraryFolderCount( $libraryFolderCount )

Get/set the Library Folder Count attribute for this item.

=cut

sub libraryFolderCount {
    my $self = shift;

    if (@_) {
        my $libraryFolderCount = shift;
        return carp "$libraryFolderCount isn't a valid Library Folder Count"
                unless _checkNum($libraryFolderCount);
        $self->{'Library Folder Count'} = $libraryFolderCount;
    }

    return $self->{'Library Folder Count'};
} #libraryFolderCount


=head2 trackCount( $trackCount )

Get/set the Track Count attribute for this item.

=cut

sub trackCount {
    my $self = shift;

    if (@_) {
        my $trackCount = shift;
        return carp "$trackCount isn't a valid Track Count"
                unless _checkNum($trackCount);
        $self->{'Track Count'} = $trackCount;
    }

    return $self->{'Track Count'};
} #trackCount


=head2 trackNumber( $trackNumber )

Get/set the Track Number attribute for this item.

=cut

sub trackNumber {
    my $self = shift;

    if (@_) {
        my $trackNumber = shift;
        return carp "$trackNumber isn't a valid Track Number"
                unless _checkNum($trackNumber);
        $self->{'Track Number'} = $trackNumber;
    }

    return $self->{'Track Number'};
} #trackNumber


##### Support methods #####
# Is it a number?
sub _checkNum {
    my $digit = shift;

    return $digit =~ /\d*/;
} #_checkNum

# Is it a date?
sub _checkDate {
    my $date = shift;

    return $date =~ /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/;
} #_checkDate


1;

=head1 SEE ALSO

L<Mac::iTunes::Library>, L<Mac::iTunes::Library::Playlist>,
L<Mac::iTunes::Library::XML>

=head1 AUTHOR

Drew Stephens <drew@dinomite.net>, http://dinomite.net

=head1 CONTRIBUTORS

=over 4

=item *

Mark Allen <mrallen1@yahoo.com>

=item *

Michael G Schwern <mschwern@cpan.org>

=item *

David Rostcheck <davidr@thisisdavidr.net>

=back

=head1 SOURCE REPOSITORY

http://mac-itunes.googlecode.com

=head1 SVN INFO

$Revision: 90 $

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2008 by Drew Stephens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
__END__
