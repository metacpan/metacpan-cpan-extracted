use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Fedora::RPM::Spec::License;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = Fedora::RPM::Spec::License->new;
my $ret = $obj->parse('MIT');
is($ret, undef, 'Successful parse (MIT).');

# Test.
$obj = Fedora::RPM::Spec::License->new;
$ret = $obj->parse('BAD');
is($ret, undef, 'Successful parse (BAD).');

# Test.
$obj = Fedora::RPM::Spec::License->new;
eval {
	$obj->parse('BAD AND MIT');
};
is($EVAL_ERROR, "License 'BAD' isn't SPDX license.\n",
	"License 'BAD' isn't SPDX license (BAD AND MIT).");
clean();

# Test.
$obj = Fedora::RPM::Spec::License->new;
eval {
	$obj->parse('MIT AND BAD');
};
is($EVAL_ERROR, "License 'BAD' isn't SPDX license.\n",
	"License 'BAD' isn't SPDX license (MIT AND BAD).");
clean();
