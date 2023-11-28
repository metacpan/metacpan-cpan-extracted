use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Lego::Part;
use Lego::Part::Image::LegoCom;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
eval {
	Lego::Part::Image::LegoCom->new(
		'part' => Lego::Part->new(
			'design_id' => 3003,
		),
	)->image_url;
};
is($EVAL_ERROR, "Element ID doesn't defined.\n",
	"Element ID doesn't defined.");
clean();

# Test.
my $obj = Lego::Part::Image::LegoCom->new(
	'part' => Lego::Part->new(
		'element_id' => 300302,
	),
);
my $image_url = $obj->image_url;
is($image_url, 'https://www.lego.com/cdn/product-assets/element.img.lod5photo.192x192/300302.jpg',
	'Get image url for lego element 300302.');
