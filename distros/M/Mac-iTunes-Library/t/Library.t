# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Mac-iTunes-Item.t'

#########################
use lib "./lib";
use 5;
use Test::More tests => 23;
BEGIN {
	use_ok('Mac::iTunes::Library');
	use_ok('Mac::iTunes::Library::Item');
	use_ok('Mac::iTunes::Library::XML');
};
#########################

# Create a new library
my $library = Mac::iTunes::Library->new();

# Check the very basics
ok( defined($library), 'Create object' );
is( $library->isa('Mac::iTunes::Library'), 1, 'Library Object type' );

# Parse the sample library
$library = Mac::iTunes::Library::XML->parse('t/iTunes_Music_Library.xml');

# Check the general values of the library
is($library->num(), 18, 'Number of tracks');
is($library->size(), 90103155, 'Library size');
is($library->time(), 4209362, 'Total time');
is($library->version(), '1.0', 'Library plist version');
is($library->majorVersion(), '1', 'Library Major Version');
is($library->minorVersion(), '1', 'Library Minor Version');
is($library->applicationVersion(), '7.4.2', 'Library Application Version');
is($library->features(), '1', 'Library Features attribute');
is($library->showContentRatings(), 'true', 'Show Content Ratings');
is($library->musicFolder(),
		'file://localhost/Users/dinomite/Music/iTunes/iTunes%20Music/',
		'Library Music Folder');
is($library->libraryPersistentID(), 'E68DAC8D289AF116',
		'Library Persistent ID');

# Check some of the items that ought to be
my %items = $library->items();
isnt(%items, undef, 'Items hash from items()');
is($items{'ATB'}{'Push the Limits'}[0]->playCount(), 5, 'Item playcount');
is($items{'ATB'}{'Push the Limits'}[0]->genre(), 'Trance', 'Item Genre');
is($items{'ATB'}{'Push the Limits'}[0]->persistentID(), 'DAC2FC501CCA2031',
		'Item Persistent ID');
is($items{'ATB'}{'Push the Limits'}[0]->libraryFolderCount(), '1',
		'Item Library Folder Count');
is($items{'Deep Forest'}{'Freedom Cry'}[0]->trackNumber, 8, 'Track Number');
is($items{'Deep Forest'}{'Freedom Cry'}[0]->trackCount, 18, 'Track Count');
