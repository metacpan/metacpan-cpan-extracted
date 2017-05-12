use Test::More tests => 331;

use Mac::iTunes::Item;
use Mac::iTunes::Playlist;

my $playlist;
my $item;

my $file     = 'mp3/The_Wee_Kirkcudbright_Centipede.mp3';
my $Title    = 'The Tappan Sisters';

# how many files in the mp3 directory?
my $expected = 7;

isa_ok( $item     = Mac::iTunes::Item->new( {} ),         'Mac::iTunes::Item'     );
isa_ok( $playlist = Mac::iTunes::Playlist->new( $Title ), 'Mac::iTunes::Playlist' );
is( $playlist->items, 0,                                  'Zero items at start'   );
is( $playlist->title, $Title,                             'Title is correct'      );
ok( $playlist->add_item( $item ),                         'Added items'           );
is( $playlist->items, 1,                                  'Count is right'        );

is( $playlist->add_item( 'This is 0 == an item' ), undef, 'Try adding string'     );
is( $playlist->items, 1,                                  'Count is still right'  );
is( $playlist->add_item( ), undef,                        'Try adding nothing'    );
is( $playlist->items, 1,                                  'Count is still right'  );
is( $playlist->add_item( undef ), undef,                  'Try adding undef'      );
is( $playlist->items, 1,                                  'Count is still right'  );
is( $playlist->add_item( {} ), undef,                     'Try adding {}'         );
is( $playlist->items, 1,                                  'Count is still right'  );

isa_ok( $playlist = Mac::iTunes::Playlist->new( $Title, [ $item ] ), 
	'Mac::iTunes::Playlist' );
is( $playlist->items, 1,                                  'Count is still right'  );


my @items = map { Mac::iTunes::Item->_new( $_ ) } 0 .. 10;

isa_ok( $playlist = Mac::iTunes::Playlist->new( $Title, \@items ), 
	'Mac::iTunes::Playlist' );
is( $playlist->items, @items, 'Count is right after fake objects' );	

my $count = $playlist->items;
my %hash;

foreach my $try ( 0 .. 100 )
	{
	my @item  = $playlist->random_item;
	
	ok( ${$item[0]} == $item[1], 'Index is right' );
	ok( $item[2] == $count,      'Count is right' );
		
	$hash{ $item[1] }++;
	}
		
my @keys   = keys %hash;
my @values = values %hash;
	
is( @keys, $count, 'Fetch all items with random' );
		
#my $min = 100_000;
#foreach my $try ( @values ) { $min = $try if $try < $min }

#my @normal = map { sprintf "%.2f", $_ / $min } @values;	

foreach my $try ( 0 .. 100 )
	{
	my $item  = $playlist->random_item;

	isa_ok( $item, 'Mac::iTunes::Item' );
	}


isa_ok( $playlist = Mac::iTunes::Playlist->new_from_directory( $Title, 'mp3' ),
	'Mac::iTunes::Playlist' );
		
is( $playlist->title, $Title,    'Title is correct'                 );
is( $playlist->items, $expected, 'Number of mp3 files in directory' );

my $playlist1 = Mac::iTunes::Playlist->new_from_directory( 'First Playlist', 'mp3' );
isa_ok( $playlist1, 'Mac::iTunes::Playlist' );
is( $playlist1->items, $expected, 'Number of mp3 files in directory' );

my $playlist2 = Mac::iTunes::Playlist->new_from_directory( 'Second Playlist', 'mp3/empty.d' );
isa_ok( $playlist2, 'Mac::iTunes::Playlist' );
is( $playlist2->items, 3, 'Number of mp3 files in directory' );

	
ok( $playlist1->merge( $playlist2 ), 'Merge playlists' );
is( $playlist1->items, 10, 'Merged list has right number of elements' );

