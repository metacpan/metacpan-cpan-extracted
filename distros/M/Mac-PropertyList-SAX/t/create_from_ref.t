# Adapted from Mac::PropertyList (by brian d foy) for use in Mac::PropertyList::SAX (by kulp)

use Test::More tests => 4;

use Mac::PropertyList::SAX;

my $structure = {
	a => 'b',
	c => [ 'd', 'e' ],
	f => {
		g => Mac::PropertyList::SAX::true->new,
		i => 1,
		j => [
			{ a => 'b' },
			2,
			"x",
		],
	},
};

my $string = Mac::PropertyList::SAX::create_from_ref($structure);
my $parsed = Mac::PropertyList::SAX::parse_plist_string($string);

is_deeply($parsed, $structure, "recursive serialization / deserialization");

my $str2 = Mac::PropertyList::SAX::create_from($structure);
is($string, $str2, "create_from dispatches a ref");
my $p2 = Mac::PropertyList::SAX::parse_plist($str2);
is_deeply($p2, $structure, "dispatched serialization / deserialization");

my $string_only = Mac::PropertyList::SAX::create_from("hello, world");
my $expected = Mac::PropertyList::create_from_string("hello, world");
is($string_only, $expected);
