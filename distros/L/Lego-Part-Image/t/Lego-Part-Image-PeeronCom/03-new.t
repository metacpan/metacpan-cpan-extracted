use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Lego::Part;
use Lego::Part::Image::PeeronCom;
use Test::MockObject;
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
eval {
	Lego::Part::Image::PeeronCom->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", 'Unknown parameter.');
clean();

# Test.
eval {
	Lego::Part::Image::PeeronCom->new('something' => 'value');
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Unknown parameter \'something\'.');
clean();

# Test.
eval {
	Lego::Part::Image::PeeronCom->new;
};
is($EVAL_ERROR, "Parameter 'part' is required.\n",
	"Parameter 'part' is required.");
clean();

# Test.
eval {
	Lego::Part::Image::PeeronCom->new(
		'part' => 'foo',
	);
};
is($EVAL_ERROR, "Parameter 'part' must be Lego::Part object.\n",
	"Parameter 'part' must be Lego::Part object.");
clean();

# Test.
eval {
	Lego::Part::Image::PeeronCom->new(
		'part' => Test::MockObject->new,
	);
};
is($EVAL_ERROR, "Parameter 'part' must be Lego::Part object.\n",
	"Parameter 'part' must be Lego::Part object.");
clean();

# Test.
my $obj = Lego::Part::Image::PeeronCom->new(
	'part' => Lego::Part->new(
		'design_id' => 3003,
	),
);
isa_ok($obj, 'Lego::Part::Image::PeeronCom');
