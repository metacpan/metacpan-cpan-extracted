use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Lego::Part;
use Lego::Part::Image::BricklinkCom;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Lego::Part::Image::BricklinkCom->new(
	'part' => Lego::Part->new(
		'design_id' => '3003',
	),
);
my $image_url = $obj->image_url;
is($image_url, 'https://img.bricklink.com/ItemImage/PL/3003.png',
	'Get image url for lego design 3003.');

# Test.
$obj = Lego::Part::Image::BricklinkCom->new(
	'part' => Lego::Part->new(
		'color' => 3,
		'design_id' => '3003',
	),
);
$image_url = $obj->image_url;
is($image_url, 'https://img.bricklink.com/ItemImage/PN/3/3003.png',
	'Get image url for lego design 3003 and color 3.');

# Test.
eval {
	Lego::Part::Image::BricklinkCom->new(
		'part' => Lego::Part->new,
	)->image_url;
};
is($EVAL_ERROR, "Parameter 'element_id' or 'design_id' is required.\n",
	"Parameter 'element_id' or 'design_id' is required.");
clean();

