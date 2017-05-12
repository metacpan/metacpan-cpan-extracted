package Mac::iTunes::Library;

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

Mac::iTunes::Library - Perl extension for representing an iTunes library

=head1 SYNOPSIS

  use Mac::iTunes::Library;

  my $library = Mac::iTunes::Library->new();
  my $item = Mac::iTunes::Library::Item->new(
        'Track ID' => 1,
        'Name' => 'The Fooiest Song',
        'Artist' => 'The Bar Band',
        );
  $library->add($item);
  print "This library has only " . $library->num() . "item.\n";

=head1 DESCRIPTION

A data structure for representing an iTunes library.

The library keeps track of the number of tracks by each artist
(a hash of Artist => num_tracks) and the number of songs in each genre
(Genre => num_tracks).  Additionally, the total playcounts for each artist
(Artist => playcount_of_all_songs) and genre (Genre => playcount_of_all_songs)
are tallied.  Finally, all of the items in the library are available, sorted
by artist.

=head1 EXPORT

None by default.

=head1 METHODS

=head2 new()

Creates a new Mac::iTunes::Library object that can store
Mac::iTunes::Library::Item objects.

=cut

sub new {
    my $class = shift;
    my $self = {
        Num => 0,           # Number of tracks in this library
        Size => 0,          # Size of all tracks
        Time => 0,          # Length of all tracks in milliseconds
        Artist => {},       # Artist counts in tracks
        PArtists => {},     # Artists counts by playcount
        AlbumArtist => {},  # Album Artist counts in tracks
        PAlbumArtists => {},# Album Artists counts by playcount
        Genre => {},        # Genre counts by tracks
        PGenre => {},       # Genre counts by playcount
        Type => {},         # Track types, file or URL
        Items => {},
        Playlists => {},
    };

    bless $self, $class;
    return $self;
} #new

# Clean up
sub DESTROY {
    # Nothing to do.
} #DESTROY

=head2 version()

Get/set the plist version number.

=cut

sub version {
    my $self = shift;

    if (@_) {
        $self->{'plist'}{'version'} = shift;
    } else {
        return $self->{'plist'}{'version'};
    }
} #version

=head2 majorVersion()

Get/set the Major Version number

=cut

sub majorVersion {
    my $self = shift;

    if (@_) {
        $self->{'Major Version'} = shift;
    } else {
        return $self->{'Major Version'};
    }
} #majorVersion

=head2 minorVersion()

Get/set the Minor Version number

=cut

sub minorVersion {
    my $self = shift;

    if (@_) {
        $self->{'Minor Version'} = shift;
    } else {
        return $self->{'Minor Version'};
    }
} #minorVersion

=head2 applicationVersion()

Get/set the Application Version number

=cut

sub applicationVersion {
    my $self = shift;

    if (@_) {
        $self->{'Application Version'} = shift;
    } else {
        return $self->{'Application Version'};
    }
} #applicationVersion

=head2 features()

Get/set the Features attribute

=cut

sub features {
    my $self = shift;

    if (@_) {
        $self->{'Features'} = shift;
    } else {
        return $self->{'Features'};
    }
} #features

=head2 showContentRatings()

Get/set the Show Content Ratings attribute

=cut

sub showContentRatings {
    my $self = shift;

    if (@_) {
        $self->{'Show Content Ratings'} = shift;
    } else {
        return $self->{'Show Content Ratings'};
    }
} #showContentRatings

=head2 musicFolder()

Get/set the Music Folder attribute

=cut

sub musicFolder {
    my $self = shift;

    if (@_) {
        $self->{'Music Folder'} = shift;
    } else {
        return $self->{'Music Folder'};
    }
} #musicFolder

=head2 libraryPersistentID()

Get/set the Library Persistent ID

=cut

sub libraryPersistentID {
    my $self = shift;

    if (@_) {
        $self->{'Library Persistent ID'} = shift;
    } else {
        return $self->{'Library Persistent ID'};
    }
} #libraryPersistentID

=head2 num()

Get the number of tracks in the library

=cut

sub num {
    my $self = shift;
    return $self->{'Num'};
} #num

# Increment the number of tracks in the library
sub _num {
    my $self = shift;
    $self->{'Num'} += 1;
} #_num

=head2 size()

Get the total size of the library

=cut

sub size {
    my $self = shift;
    return $self->{'Size'};
} #size

# Add to the library's total size
sub _size {
    my $self = shift;
    my $num = shift;
    return unless ( defined $num );
    $self->{'Size'} += $num;
} #_size

=head2 time()

Get the total time of the library

=cut

sub time {
    my $self = shift;
    return $self->{'Time'};
} #time

# Add to the library's total time
sub _time {
    my $self = shift;
    my $time = shift;
    return unless ( defined $time );
    $self->{'Time'} += $time if (defined $time);
} #_time

=head2 artist()

Get the hash of the number of tracks for each artist.

=cut

sub artist {
    my $self = shift;
    return %{$self->{'Artist'}};
} #artist

# Increment the track count for the given artist
# ($artist)
sub _artist {
    my $self = shift;
    my $artist = shift;
    return unless ( defined $artist );
    $self->{'Artist'}{ $artist } += 1;
} #_artist

=head2 partist()

Get the hash of the number of plays (playcount) for each artist.

=cut

sub partist {
    my $self = shift;
    return %{$self->{'PArtists'}};
} #partist

# Increment the playcount for the given artist by a given amount
# ($artist, $num)
sub _partist {
    my $self = shift;
    my ($artist, $num) = @_;
    return unless ( defined $artist );
    return unless ( defined $num );
    $self->{'PArtists'}{ $artist } += $num;
} #_partist

=head2 albumArtist()

Get the hash of the number of tracks for each albumArtist.

=cut

sub albumArtist {
    my $self = shift;
    return %{$self->{'AlbumArtist'}};
} #albumArtist

# Increment the track count for the given albumArtist
# ($albumArtist)
sub _albumArtist {
    my $self = shift;
    my $albumArtist = shift;
    return unless ( defined $albumArtist );
    $self->{'AlbumArtist'}{ $albumArtist } += 1;
} #_albumArtist

=head2 palbumArtist()

Get the hash of the number of plays (playcount) for each albumArtist.

=cut

sub palbumArtist {
    my $self = shift;
    return %{$self->{'PAlbumArtists'}};
} #partist

# Increment the playcount for the given albumArtist by a given amount
# ($albumArtist, $num)
sub _palbumArtist {
    my $self = shift;
    my ($albumArtist, $num) = @_;
    return unless ( defined $albumArtist );
    return unless ( defined $num );
    $self->{'PAlbumArtists'}{ $albumArtist } += $num;
} #_palbumArtist

=head2 genre()

Get the hash of the number of tracks in each genre.

=cut

sub genre {
    my $self = shift;
    return %{$self->{'Genre'}};
} #genre

# Incrment the track count for the given genre
# ($genre)
sub _genre {
    my $self = shift;
    my $genre = shift;
    return unless ( defined $genre );
    $self->{'Genre'}{ $genre } += 1;
} #_genre

=head2 pgenre()

Get the hash of the number of plays (playcount) for each genre.

=cut

sub pgenre {
    my $self = shift;
    return %{$self->{'PGenre'}};
} #pgenre

# Increment the playcount for the given genre by a given amount
# ($genre, $playcount)
sub _pgenre {
    my $self = shift;
    my ($genre, $num) = @_;
    return unless ( defined $genre );
    return unless ( defined $num );
    $self->{'PGenre'}{ $genre } += $num;
} #_pgenre

=head2 type()

Get the hash of item types in the library

=cut

sub type {
    my $self = shift;
    return %{$self->{'Type'}};
} #type

# Increment the count of items of the given type
sub _type {
    my $self = shift;
    my $type = shift;
    return unless ( defined $type );
    $self->{'Type'}{ $type } += 1;
} #_type

=head2 items()

Get the hash of Items (Artist->Name->[item, item]) contained in the library;
artist names are the top level keys; accessing one gives you a hash-ref with
keys of song names and array-refs as values.  Those array-refs contain
Mac::iTunes::Library::Item objects.

=over 4

=item Example traversal:

  # Assuming a previously created library
  %items = $library->items();
  while (($artist, $artistSongs) = each %items) {
      while (($songName, artistSongItems) = each %$artistSongs) {
          foreach my $item (@$artistSongItems) {
              # Do something here to every item in the library
              print $song->name() . "\n";
          }
      }
  }

=back

=cut

sub items {
    my $self = shift;
    return %{$self->{'Items'}};
} #items

# Add an item to our collection
sub _item {
    my $self = shift;
    my $item = shift;

    my $artist = $item->artist();
    my $name = $item->name();
    $artist = 'Unknown' unless (defined $artist);
    $name = 'Unknown' unless (defined $name);

    # Finally, add it to our collection of items
    if (exists $self->{'Items'}{$artist}) {
        if (exists $self->{'Items'}{$artist}{$name}) {
            push @{$self->{'Items'}{$artist}{$name}}, $item;
        } else {
            # First occurrence of this title
            $self->{'Items'}{$artist}{$name} = [$item];
        }
    } else {
        # First occurrence of this artist
        $self->{'Items'}{$artist}{$name} = [$item];
    }

    # print "creating item: " . $item->trackID . "\n";
    $self->{'ItemsById'}{$item->trackID} = \$item;  # TODO: this should be a ref

} #_item

=head2 add( Mac::iTunes::Library::Item )

Add an item to the library

=cut

sub add {
    my $self = shift;
    my $item = shift;
    return carp "Not enough arguments." unless (defined $item);
    return carp "Argument isn't a Mac::iTunes::Library::Item."
        unless ($item->isa("Mac::iTunes::Library::Item"));

    my $artist = $item->artist();
    my $albumArtist = $item->albumArtist();
    my $name = $item->name();
    my $genre = $item->genre();
    my $playCount = $item->playCount();

    # Deal with possible null values
    $artist = 'Unknown' unless (defined $artist);
    $albumArtist = 'Unknown' unless (defined $albumArtist);
    $name = 'Unknown' unless (defined $name);
    $genre = 'Unknown' unless (defined $genre);
    $playCount = 0 unless (defined $playCount);

    # Tally up the item's data
    $self->_artist($artist);
    $self->_albumArtist($albumArtist);
    $self->_genre($genre);
    $self->_num();
    $self->_size($item->size()) if (defined $item->size()); # Streams = null
    $self->_time($item->totalTime());
    $self->_partist($item->artist(), $item->playCount());
    $self->_palbumArtist($item->albumArtist(), $item->playCount());
    $self->_pgenre($item->genre(), $item->playCount());
    $self->_type($item->trackType());
    $self->_item($item);
} #add

sub addPlaylist {
    my $self = shift;
    my $playlist = shift;

    $self->{'Playlists'}->{ $playlist->{'Playlist ID'} } = $playlist;
}

sub playlists {
    my $self = shift;
    return %{$self->{'Playlists'}};
}

1;

=head1 SEE ALSO

L<Mac::iTunes::Library::XML>, L<Mac::iTunes::Library::Item>,
L<Mac::iTunes::Library::Playlist>

=head1 AUTHOR

Drew Stephens <drew@dinomite.net>, http://dinomite.net

=head1 CONTRIBUTORS

=over 4

=item *

Mark Grimes <mgrimes@cpan.org>, (L<http://www.peculiarities.com>)

=item *

Scott Lawrence (L<http://linkedin.com/in/scottdlawrence>)

=item *

Garrett Scott <garrett@gothik.org>, (L<http://www.gothik.org>)

=item *

Mark Allen <mrallen1@yahoo.com>

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
