use strict;
use warnings;

use DateTime;
use English;
use Error::Pure::Utils qw(clean);
use MARC::Convert::Wikidata::Object::Utils qw(check_date);
use Test::More 'tests' => 19;
use Test::NoWarnings;

# Test.
my $self = {'date' => '20'};
my $ret = check_date($self, 'date');
is($ret, undef, "Date '20' is right.");

# Test.
$self = {'date' => '200'};
$ret = check_date($self, 'date');
is($ret, undef, "Date '200' is right.");

# Test.
$self = {'date' => '2000'};
$ret = check_date($self, 'date');
is($ret, undef, "Date '2000' is right.");

# Test.
$self = {'date' => '2000-01'};
$ret = check_date($self, 'date');
is($ret, undef, "Date '2000-01' is right.");

# Test.
$self = {'date' => '2000-1'};
$ret = check_date($self, 'date');
is($ret, undef, "Date '2000-1' is right.");

# Test.
$self = {'date' => '2000-01-01'};
$ret = check_date($self, 'date');
is($ret, undef, "Date '2000-01-01' is right.");

# Test.
$self = {'date' => '2000-01-1'};
$ret = check_date($self, 'date');
is($ret, undef, "Date '2000-01-1' is right.");

# Test.
$self = {'date' => '2000-1-1'};
$ret = check_date($self, 'date');
is($ret, undef, "Date '2000-1-1' is right.");

# Test.
$self = {'date' => '-20'};
$ret = check_date($self, 'date');
is($ret, undef, "Date '-20' is right.");

# Test.
$self = {'date' => '-200'};
$ret = check_date($self, 'date');
is($ret, undef, "Date '-200' is right.");

# Test.
$self = {'date' => '-2000'};
$ret = check_date($self, 'date');
is($ret, undef, "Date '-2000' is right.");

# Test.
$self = {'date' => '-2000-01'};
$ret = check_date($self, 'date');
is($ret, undef, "Date '-2000-01' is right.");

# Test.
$self = {'date' => '-2000-1'};
$ret = check_date($self, 'date');
is($ret, undef, "Date '-2000-1' is right.");

# Test.
$self = {'date' => '-2000-01-01'};
$ret = check_date($self, 'date');
is($ret, undef, "Date '-2000-01-01' is right.");

# Test.
$self = {'date' => '-2000-01-1'};
$ret = check_date($self, 'date');
is($ret, undef, "Date '-2000-01-1' is right.");

# Test.
$self = {'date' => '-2000-1-1'};
$ret = check_date($self, 'date');
is($ret, undef, "Date '-2000-1-1' is right.");

# Test.
$self = {'date' => 'foo'};
eval {
	check_date($self, 'date');
	
};
is($EVAL_ERROR, "Parameter 'date' is in bad format.\n",
	"Parameter 'date' is in bad format (foo).");
clean();

# Test.
my $actual_year = DateTime->now->year;
$self = {'date' => $actual_year + 1};
eval {
	check_date($self, 'date');
	
};
is($EVAL_ERROR, "Parameter 'date' has year greater than actual year.\n",
	"Parameter 'date' has year greater than actual year.");
clean();
