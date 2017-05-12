# Stolen from Mac::PropertyList (by comdog) for use in Mac::PropertyList::SAX (by kulp)

use Test::More tests => 2;

use Mac::PropertyList::SAX;

########################################################################
# Test the dict bits
my $dict = Mac::PropertyList::dict->new();
isa_ok( $dict, "Mac::PropertyList::dict" );

########################################################################
# Test the array bits
my $array = Mac::PropertyList::array->new();
isa_ok( $array, "Mac::PropertyList::array" );
