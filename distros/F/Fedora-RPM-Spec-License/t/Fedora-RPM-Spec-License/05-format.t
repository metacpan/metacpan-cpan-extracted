use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Fedora::RPM::Spec::License;
use Test::More 'tests' => 10;
use Test::NoWarnings;

# Test.
my $obj = Fedora::RPM::Spec::License->new;
$obj->parse('MIT');
my $ret = $obj->format;
is($ret, 2, 'Fedora format is 2 (MIT).');

# Test.
$obj = Fedora::RPM::Spec::License->new;
$obj->parse('MIT AND GPL-1.0-only');
$ret = $obj->format;
is($ret, 2, 'Fedora format is 2 (MIT AND GPL-1.0-only).');

# Test.
$obj = Fedora::RPM::Spec::License->new;
$obj->parse('GPL-2.0-or-later AND OFL-1.1-RFN AND Knuth-CTAN');
$ret = $obj->format;
is($ret, 2, 'Fedora format is 2 (GPL-2.0-or-later AND OFL-1.1-RFN AND Knuth-CTAN).');

# Test.
$obj = Fedora::RPM::Spec::License->new;
$obj->parse('(GPL-1.0-or-later OR Artistic-1.0-Perl) AND MIT');
$ret = $obj->format;
is($ret, 2, 'Fedora format is 2 ((GPL-1.0-or-later OR Artistic-1.0-Perl) AND MIT).');

# Test.
$obj = Fedora::RPM::Spec::License->new;
$obj->parse('ASL 2.0 or MIT');
$ret = $obj->format;
is($ret, 1, 'Fedora format is 1 (ASL 2.0 or MIT).');

# Test.
$obj = Fedora::RPM::Spec::License->new;
$obj->parse('GPLv3+ and (ASL 2.0 or MIT)');
$ret = $obj->format;
is($ret, 1, 'Fedora format is 1 (GPLv3+ and (ASL 2.0 or MIT)).');

# Test.
$obj = Fedora::RPM::Spec::License->new;
$obj->parse('MIT and Apache-2.0-WITH-LLVM-exception');
$ret = $obj->format;
is($ret, 1, 'Fedora format is 1 (MIT and Apache-2.0-WITH-LLVM-exception).');

# Test.
$obj = Fedora::RPM::Spec::License->new;
$obj->parse('LGPL-3.0-only WITH LGPL-3.0-linking-exception');
$ret = $obj->format;
is($ret, 2, 'Fedora format is 2 (LGPL-3.0-only WITH LGPL-3.0-linking-exception).');

# Test.
$obj = Fedora::RPM::Spec::License->new;
eval {
	$obj->format;
};
is($EVAL_ERROR, "No Fedora license string processed.\n",
	"No Fedora license string processed.");
clean();
