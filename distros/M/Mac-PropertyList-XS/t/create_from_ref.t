# Stolen from Mac::PropertyList (by comdog) for use in Mac::PropertyList::XS (by kulp)

use Test::More tests => 1;

use Mac::PropertyList::XS;

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

my $string = Mac::PropertyList::XS::create_from_ref($structure);
my $parsed = Mac::PropertyList::XS::parse_plist_string($string);

is_deeply($parsed, $structure, "recursive serialization / deserialization");

