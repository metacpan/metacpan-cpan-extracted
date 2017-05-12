# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Mac-iTunes-Item.t'

=head1 SVN INFO

$Revision: 90 $

=cut

#########################
use lib ".";
use 5;
use Test::More tests => 38;
BEGIN { use_ok('Mac::iTunes::Library::Item') };
#########################

# Define the values for a item in a hash
my %values = (
    'Track ID' => 1,
    'Name' => 'Track Name',
    'Artist' => 'Artist Name',
    'Album Artist' => 'Album Artist Name',
    'Composer' => 'Composer Name',
    'Album' => 'Album Name',
    'Grouping' => 'Grouping Name',
    'Genre' => 'Genre Name',
    'Kind' => 'MPEG audio file',
    'Size' => 31337,
    'Total Time' => 31337,
    'Year' => '2007',
    'Date Modified' => '2007-01-01T01:01:01Z',
    'Date Added' => '2007-01-01T01:01:01Z',
    'Bit Rate' => 128,
    'Comments' => 'Foobar',
    'Sample Rate' => 44100,
    'Play Count' => 1,
    'Play Date' => -1167613261,
    'Play Date UTC' => '2007-01-01T01:01:01Z',
    'Release Date' => '2007-01-01T01:01:01Z',
    'Skip Count' => 7,
    'Skip Date' => '2007-01-01T01:01:01Z',
    'Rating' => 50,
    'Album Rating' => 60,
    'Album Rating Computed' => 1,
    'Compilation' => 1,
    'Persistent ID' => 'DAC2FC501CCA2031',
    'Track Type' => 'File',
    'iTunesU' => 'Y',
    'Location' => 'file://localhost/Users/dinomite/Music/Artist%20Name/Track%20Name.mp3',
    'File Folder Count' => 4,
    'Library Folder Count' => 1,
    'Track Number'      => 3,
    'Track Count'       => 21,
);

# Create a new item
my $item = Mac::iTunes::Library::Item->new(%values);

# Check the very basics
ok(defined($item), 'Create object');
is($item->isa('Mac::iTunes::Library::Item'), 1, 'Object type');

# Make sure data is stored properly
is($item->trackID(), $values{'Track ID'}, 'Get Track ID');
is($item->name(), $values{'Name'}, 'Get Name');
is($item->artist(), $values{'Artist'}, 'Get Artist');
is($item->albumArtist(), $values{'Album Artist'}, 'Get Album Artist');
is($item->composer(), $values{'Composer'}, 'Get Composer');
is($item->album(), $values{'Album'}, 'Get Album');
is($item->grouping(), $values{'Grouping'}, 'Get Grouping');
is($item->genre(), $values{'Genre'}, 'Get Genre');
is($item->kind(), $values{'Kind'}, 'Get Kind');
is($item->size(), $values{'Size'}, 'Get Size');
is($item->totalTime(), $values{'Total Time'}, 'Get Total Time');
is($item->year(), $values{'Year'}, 'Get Year');
is($item->dateModified(), $values{'Date Modified'}, 'Get Date Modified');
is($item->dateAdded(), $values{'Date Added'}, 'Get Added');
is($item->bitRate(), $values{'Bit Rate'}, 'Get Bit Rate');
is($item->comments(), $values{'Comments'}, 'Get Comments');
is($item->sampleRate(), $values{'Sample Rate'}, 'Get Sample Rate');
is($item->playCount(), $values{'Play Count'}, 'Get Play Count');
is($item->playDate(), $values{'Play Date'}, 'Get Play Date');
is($item->playDateUTC(), $values{'Play Date UTC'}, 'Get Play Date UTC');
is($item->releaseDate(), $values{'Release Date'}, 'Get Release Date');
is($item->skipCount(), $values{'Skip Count'}, 'Get Skip Count');
is($item->skipDate(), $values{'Skip Date'}, 'Get Skip Date');
is($item->rating(), $values{'Rating'}, 'Get Rating');
is($item->albumRating(), $values{'Album Rating'}, 'Get Alubm Rating');
is($item->albumRatingComputed(), $values{'Album Rating Computed'}, 'Get Album Rating Computed');
is($item->compilation(), $values{'Compilation'}, 'Get Compilation');
is($item->persistentID(), $values{'Persistent ID'}, 'Get Persistent ID');
is($item->trackType(), $values{'Track Type'}, 'Get Track Type');
is($item->iTunesU(), $values{'iTunesU'}, 'Get iTunesU');
is($item->location(), $values{'Location'}, 'Get Location');
is($item->fileFolderCount(), $values{'File Folder Count'}, 'Get File Folder Count');
is($item->libraryFolderCount(), $values{'Library Folder Count'}, 'Get Total Time');
is($item->trackCount(), $values{'Track Count'}, 'Get Track Count');
is($item->trackNumber(), $values{'Track Number'}, 'Get Track Number');
