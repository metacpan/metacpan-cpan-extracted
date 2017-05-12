package Demo_REM;
$VERSION = '0.01';

use Filter::Simple;
use Regexp::Common;
FILTER_ONLY
	regex => sub { print "1a: $_\n"; s/\!\[/[^/g; print "1b: $_\n" },
	all   => sub { print "1c: $_\n" },

	regex => sub { print "2a: $_\n"; s/%d/$RE{num}{int}/g; print "2b: $_\n" },
	all   => sub { print "2c: $_\n" },
	regex => sub { print "3a: $_\n"; s/%f/$RE{num}{real}/g; print "3b: $_\n" },
	all   => sub { print "3c: $_\n" };
