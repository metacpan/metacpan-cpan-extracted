use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Fedora::RPM::Spec::License;
use Test::More 'tests' => 8;
use Test::NoWarnings;

# Test.
my $obj = Fedora::RPM::Spec::License->new;
$obj->parse('MIT');
my @ret = $obj->licenses;
is_deeply(
	\@ret,
	[
		'MIT',
	],
	'Simple license in 2 format (MIT).',
);

# Test.
$obj = Fedora::RPM::Spec::License->new;
$obj->parse('MIT AND GPL-1.0-only');
@ret = $obj->licenses;
is_deeply(
	\@ret,
	[
		'GPL-1.0-only',
		'MIT',
	],
	'Two licenses with AND in 2 format (MIT AND GPL-1.0-only).',
);

# Test.
$obj = Fedora::RPM::Spec::License->new;
$obj->parse('GPL-2.0-or-later AND OFL-1.1-RFN AND Knuth-CTAN');
@ret = $obj->licenses;
is_deeply(
	\@ret,
	[
		'GPL-2.0-or-later',
		'Knuth-CTAN',
		'OFL-1.1-RFN',
	],
	'Three licenses with AND in 2 format (GPL-2.0-or-later AND OFL-1.1-RFN AND Knuth-CTAN).',
);

# Test.
$obj = Fedora::RPM::Spec::License->new;
$obj->parse('(GPL-1.0-or-later OR Artistic-1.0-Perl) AND MIT');
@ret = $obj->licenses;
is_deeply(
	\@ret,
	[
		'Artistic-1.0-Perl',
		'GPL-1.0-or-later',
		'MIT',
	],
	'Three licenses with AND in 2 format ((GPL-1.0-or-later OR Artistic-1.0-Perl) AND MIT).',
);

# Test.
$obj = Fedora::RPM::Spec::License->new;
$obj->parse('ASL 2.0 or MIT');
@ret = $obj->licenses;
is_deeply(
	\@ret,
	[
		'ASL 2.0',
		'MIT',
	],
	'Two licenses with or in 1 format (ASL 2.0 or MIT).',
);

# Test.
$obj = Fedora::RPM::Spec::License->new;
$obj->parse('GPLv3+ and (ASL 2.0 or MIT)');
@ret = $obj->licenses;
is_deeply(
	\@ret,
	[
		'ASL 2.0',
		'GPLv3+',
		'MIT',
	],
	'Three licenses with or in 1 format (GPLv3+ and (ASL 2.0 or MIT)).',
);

# Test.
$obj = Fedora::RPM::Spec::License->new;
eval {
	$obj->licenses;
};
is($EVAL_ERROR, "No Fedora license string processed.\n",
	"No Fedora license string processed.");
clean();
