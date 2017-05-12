# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Lego::Part;
use Lego::Part::Image::PeeronCom;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
eval {
	Lego::Part::Image::PeeronCom->new(
		'part' => Lego::Part->new(
			'element_id' => 300303,
		),
	)->image_url;
};
is($EVAL_ERROR, "Color doesn't defined.\n",
	"Color doesn't defined.");
clean();

# Test.
eval {
	Lego::Part::Image::PeeronCom->new(
		'part' => Lego::Part->new(
			'color' => 2,
			'element_id' => 300303,
		),
	)->image_url;
};
is($EVAL_ERROR, "Design ID doesn't defined.\n",
	"Design ID doesn't defined.");
clean();

# Test.
my $obj = Lego::Part::Image::PeeronCom->new(
	'part' => Lego::Part->new(
		'color' => '1',
		'design_id' => 3003,
	),
);
my $image_url = $obj->image_url;
is($image_url, 'http://media.peeron.com/ldraw/images/1/100/3003.png',
	'Get image url for lego design 3003.');
