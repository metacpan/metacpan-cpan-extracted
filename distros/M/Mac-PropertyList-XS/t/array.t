# Stolen from Mac::PropertyList (by comdog) for use in Mac::PropertyList::XS (by kulp)

use Test::More tests => 5;

use Mac::PropertyList::XS;

########################################################################
# Test the array bits
{
my $array = Mac::PropertyList::array->new();
isa_ok( $array, "Mac::PropertyList::array", 'Make empty object' );
is( $array->count, 0, 'Empty object has no elements' );
}

my $array =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<array>
	<string>Mimi</string>
	<string>Roscoe</string>
	<string>Juliet</string>
	<string>Buster</string>
</array>
</plist>
HERE

$plist = Mac::PropertyList::XS::parse_plist( $array );
isa_ok( $plist, "Mac::PropertyList::array", "Make object  from plist string" );
is( $plist->count, 4, "Object has right number of values" );

my @values = $plist->values;
ok( eq_array( \@values, [qw(Mimi Roscoe Juliet Buster)] ), 
	"Object has right values" );

