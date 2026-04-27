use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use MARC::Field008::Print;
use Test::More 'tests' => 14;
use Test::NoWarnings;

# Test.
delete $ENV{'COLOR'};
delete $ENV{'NO_COLOR'};
my $obj = MARC::Field008::Print->new;
isa_ok($obj, 'MARC::Field008::Print');
is($obj->{'mode_ansi'}, 0, "Get autodetected 'mode_ansi' pameter (0).");

# Test.
$ENV{'COLOR'} = 1;
delete $ENV{'NO_COLOR'};
$obj = MARC::Field008::Print->new;
isa_ok($obj, 'MARC::Field008::Print');
is($obj->{'mode_ansi'}, 1, "Get autodetected 'mode_ansi' pameter (1).");

# Test.
$ENV{'COLOR'} = 'always';
delete $ENV{'NO_COLOR'};
$obj = MARC::Field008::Print->new;
isa_ok($obj, 'MARC::Field008::Print');
is($obj->{'mode_ansi'}, 1, "Get autodetected 'mode_ansi' pameter (1).");

# Test.
$ENV{'COLOR'} = 'never';
delete $ENV{'NO_COLOR'};
$obj = MARC::Field008::Print->new;
isa_ok($obj, 'MARC::Field008::Print');
is($obj->{'mode_ansi'}, 0, "Get autodetected 'mode_ansi' pameter (0).");

# Test.
delete $ENV{'COLOR'};
$ENV{'NO_COLOR'} = 1;
$obj = MARC::Field008::Print->new;
isa_ok($obj, 'MARC::Field008::Print');
is($obj->{'mode_ansi'}, 0, "Get autodetected 'mode_ansi' pameter (0).");

# Test.
eval {
	MARC::Field008::Print->new(
		'lang' => 'xx',
	);
};
is($EVAL_ERROR, "Parameter 'lang' doesn't contain valid ISO 639-1 code.\n",
	"Parameter 'lang' doesn't contain valid ISO 639-1 code (xx).");
clean();

# Test.
eval {
	MARC::Field008::Print->new(
		'mode_ansi' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'mode_ansi' must be a bool (0/1).\n",
	"Parameter 'mode_ansi' must be a bool (0/1) (bad).");
clean();

# Test.
eval {
	MARC::Field008::Print->new(
		'mode_desc' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'mode_desc' must be a bool (0/1).\n",
	"Parameter 'mode_desc' must be a bool (0/1) (bad).");
clean();
