use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Fedora::RPM::Spec::License;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Fedora::RPM::Spec::License->new;
$obj->parse('MIT');
my $ret = $obj->format;
is($ret, 2, 'Get format after parse() and before reset() (2 - MIT).');
$obj->reset;
eval {
	$obj->format;
};
is($EVAL_ERROR, "No Fedora license string processed.\n",
	"Get format after parse() and after reset() (error - No Fedora license string processed).");
clean();
