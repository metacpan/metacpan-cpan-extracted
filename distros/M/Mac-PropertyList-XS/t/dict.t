# Stolen from Mac::PropertyList (by comdog) for use in Mac::PropertyList::XS (by kulp)

use Test::More tests => 15;

use Mac::PropertyList::XS;

########################################################################
# Test the dict bits
{
my $dict = Mac::PropertyList::dict->new();
isa_ok( $dict, "Mac::PropertyList::dict" );
is( $dict->count, 0, "Empty object has right number of keys" );
}

########################################################################
my $dict =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Mimi</key>
	<string>Roscoe</string>
	<key>Buster</key>
	<string>Juliet</string>
</dict>
</plist>
HERE

$plist = Mac::PropertyList::XS::parse_plist( $dict );
isa_ok( $plist, 'Mac::PropertyList::dict' );
is( $plist->count, 2, "Has right number of keys" );
isnt( $plist->count, 3, "Hasn't wrong number of keys" );

my @keys = sort $plist->keys;
ok( eq_array( \@keys, [qw(Buster Mimi)] ), "Check hash keys" );

my @values = sort $plist->values;
ok( eq_array( \@values, [qw(Juliet Roscoe)] ), "Check hash values" );

ok( $plist->exists( 'Mimi' ),   'Mimi key exists' );
ok( $plist->exists( 'Buster' ), 'Buster key exists' );
is( $plist->exists( 'Juliet' ), 0, 'Juliet key does not exist' );

is( $plist->value( 'Mimi' ),   'Roscoe', "Check Mimi's value" );
is( $plist->value( 'Buster' ), 'Juliet', "Check Buster's value" );

$plist->delete( 'Mimi' );
is( $plist->exists( 'Mimi' ), 0, 'Mimi key does not exist' );
ok( $plist->exists( 'Buster' ), 'Buster key exists after delete' );
is( $plist->count, 1, "Has right count after delete" );


