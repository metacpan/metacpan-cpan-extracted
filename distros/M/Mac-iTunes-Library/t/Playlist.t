# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl Mac-iTunes-Library-Playlist.t'

=head1 SVN INFO

$Revision: 90 $

=cut

#########################
use lib ".";
use 5;
use Test::More tests => 11;
BEGIN { use_ok('Mac::iTunes::Library::Item') };
BEGIN { use_ok('Mac::iTunes::Library::Playlist') };
#########################

# Let's create a few simple items
my @items = (
        Mac::iTunes::Library::Item->new('Track ID' => 2),
        Mac::iTunes::Library::Item->new('Track ID' => 3),
        Mac::iTunes::Library::Item->new('Track ID' => 4),
        );
# Create a playlist
my $smartInfo =<< 'EOF';
AQEAAwAAAAIAAAAZAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAA==
EOF

my $smartCriteria =<< 'EOF';
U0xzdAABAAEAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABkAAAABAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABEAAAAAAAAAGQAAAAAAAAAAAAAAAAAAAAB
AAAAAAAAAGQAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAA=
EOF

my %values = (
        'Name' => '5 Stars',
        'Playlist ID' => '10073',
        'Playlist Persistent ID' => '2E2D1396AF1DED73',
        'All Items' => 1,
        'Smart Info' => $smartInfo,
        'Smart Criteria' => $smartCriteria,
        'Playlist Items' => \@items,
        );

my $playlist = Mac::iTunes::Library::Playlist->new(%values);

# Check the very basics
ok(defined($playlist), 'Create object');
is($playlist->isa('Mac::iTunes::Library::Playlist'), 1, 'Object type');
is($playlist->name(), $values{'Name'});
is($playlist->playlistID(), $values{'Playlist ID'});
is($playlist->playlistPersistentID(), $values{'Playlist Persistent ID'});
is($playlist->allItems(), $values{'All Items'});
is($playlist->smartInfo(), $values{'Smart Info'});
is($playlist->smartCriteria(), $values{'Smart Criteria'});

# Add another item to that playlist
my $item = Mac::iTunes::Library::Item->new( 'Track ID' => 7 );
$playlist->addItem( $item );
is($playlist->item(7), $item, 'Adding or retrieving item');
