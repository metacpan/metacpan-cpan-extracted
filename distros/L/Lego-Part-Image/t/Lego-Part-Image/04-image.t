# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Lego::Part;
use Lego::Part::Image;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Lego::Part::Image->new(
	'part' => Lego::Part->new(
		'design_id' => 3003,
	),
);
eval {
	$obj->image;
};
is($EVAL_ERROR, "This is abstract class. image() method not implemented.\n",
	'This is abstract class. image() method not implemented.');
clean();
