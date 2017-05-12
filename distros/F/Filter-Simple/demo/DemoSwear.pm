package DemoSwear;
$VERSION = '0.01';
use Regexp::Common;

use Filter::Simple;

FILTER_ONLY
	all    => sub { print "-------\n$_" },
	string => sub { s/$RE{profanity}/darn/g },
	all    => sub { print "-------\n$_" },
	code   => sub { s/$RE{profanity}|[@%#&*]{3,}([-]\S+)?//g },
	all    => sub { print "-------\n$_" },
