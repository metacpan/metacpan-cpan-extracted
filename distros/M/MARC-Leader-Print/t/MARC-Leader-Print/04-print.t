use strict;
use warnings;

use MARC::Leader;
use MARC::Leader::Print;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $leader = MARC::Leader->new->parse('     nam a22        4500');
my $obj = MARC::Leader::Print->new(
	'lang' => 'en',
	'mode_ansi' => 0,
);
my @ret = $obj->print($leader);
is_deeply(
	\@ret,
	[
		"Record length: 0",
		"Record status: New",
		"Type of record: Language material",
		"Bibliographic level: Monograph/Item",
		"Type of control: No specified type",
		"Character coding scheme: UCS/Unicode",
		"Indicator count: 2",
		"Subfield code count: 2",
		"Base address of data: 0",
		"Encoding level: Full level",
		"Descriptive cataloging form: Non-ISBD",
		"Multipart resource record level: Not specified or not applicable",
		"Length of the length-of-field portion: 4",
		"Length of the starting-character-position portion: 5",
		"Length of the implementation-defined portion: 0",
		"Undefined: Undefined"
	],
	'Get array of information about MARC leader with value descriptions.',
);

# Test.
$leader = MARC::Leader->new->parse('     nam a22        4500');
$obj = MARC::Leader::Print->new(
	'lang' => 'en',
	'mode_ansi' => 0,
	'mode_desc' => 0,
);
@ret = $obj->print($leader);
is_deeply(
	\@ret,
	[
		"Record length: 0",
		"Record status: n",
		"Type of record: a",
		"Bibliographic level: m",
		"Type of control:  ",
		"Character coding scheme: a",
		"Indicator count: 2",
		"Subfield code count: 2",
		"Base address of data: 0",
		"Encoding level:  ",
		"Descriptive cataloging form:  ",
		"Multipart resource record level:  ",
		"Length of the length-of-field portion: 4",
		"Length of the starting-character-position portion: 5",
		"Length of the implementation-defined portion: 0",
		"Undefined: 0"
	],
	'Get array of information about MARC leader with value.',
);

# Test.
$leader = MARC::Leader->new->parse('     nam a22        4500');
$obj = MARC::Leader::Print->new(
	'lang' => 'en',
	'mode_ansi' => 0,
	'mode_desc' => 0,
);
my $ret = $obj->print($leader);
my $right_ret = <<'END';
Record length: 0
Record status: n
Type of record: a
Bibliographic level: m
Type of control:  
Character coding scheme: a
Indicator count: 2
Subfield code count: 2
Base address of data: 0
Encoding level:  
Descriptive cataloging form:  
Multipart resource record level:  
Length of the length-of-field portion: 4
Length of the starting-character-position portion: 5
Length of the implementation-defined portion: 0
Undefined: 0
END
chomp $right_ret;
is($ret, $right_ret, 'Get scalar with information about MARC leader with value.');
