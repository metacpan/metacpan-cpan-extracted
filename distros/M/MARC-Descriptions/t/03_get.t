use Test::More tests => 9;

use MARC::Descriptions;
my $td = MARC::Descriptions->new;
my $s = $td->get("245","description");

is( $s, "Title Statement", "Retrieve tag description");

$s = $td->get("010","shortname");
is( $s, "LCCN", "Tag shortname");

$s = $td->get("015","shortname");
is( $s, "", "Tag with no shortname returns empty string");

$s = $td->get("245","subfield","b","description");
is( $s, 
    "Remainder of title",
    "Subfield, all parameters specified"
    );

$s = $td->get("055","ind1","1","description");
is( $s, 
    "Work not held by NLC",
    "Indicator 1, all parameters specified"
    );

$s = $td->get("990","ind2","7","description");
is( $s, 
    "Cross-reference in AACR1 form (not yet authenticated by LC)",
    "Indicator 2, all parameters specified"
    );

$s = $td->get("045","ind2","#","description");
is( $s, 
    "Blank",
    "Indicator is '#'"
    );

$s = $td->get("045","ind1","#","description");
is( $s, 
    "No dates/times recorded (i.e. no subfield \$b or \$c)",
    "String contains \$"
    );

my %subfield = (
		"a" => {
			flags => "",
			description => "Abbreviated title",
			},
		"b" => {
			flags => "",
			description => "Qualifying information",
			},
		"2" => {
			flags => "R",
			description => "Source",
			},
		);
my $href = $td->get("210","subfields");
ok( eq_hash(\%subfield, $href) );

