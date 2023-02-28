use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Fedora::RPM::Spec::License;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Fedora::RPM::Spec::License->new;
$obj->parse('LGPL-3.0-only');
my @ret = $obj->exceptions;
is_deeply(
	\@ret,
	[],
	'No license exception 2 format (LGPL-3.0-only).',
);

# Test.
$obj = Fedora::RPM::Spec::License->new;
$obj->parse('LGPL-3.0-only WITH LGPL-3.0-linking-exception');
@ret = $obj->exceptions;
is_deeply(
	\@ret,
	[
		'LGPL-3.0-linking-exception',
	],
	'One license exception in 2 format (LGPL-3.0-only WITH LGPL-3.0-linking-exception).',
);

# Test.
$obj = Fedora::RPM::Spec::License->new;
eval {
	$obj->exceptions;
};
is($EVAL_ERROR, "No Fedora license string processed.\n",
	"No Fedora license string processed.");
clean();
