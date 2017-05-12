# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Lego::Part;
use Lego::Part::Image::LugnetCom;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
eval {
	Lego::Part::Image::LugnetCom->new(
		'part' => Lego::Part->new(
			'element_id' => 300303,
		),
	)->image_url;
};
is($EVAL_ERROR, "Design ID doesn't defined.\n",
	"Design ID doesn't defined.");
clean();

# Test.
my $obj = Lego::Part::Image::LugnetCom->new(
	'part' => Lego::Part->new(
		'design_id' => 3003,
	),
);
my $image_url = $obj->image_url;
is($image_url, 'http://img.lugnet.com/ld/3003.gif',
	'Get image url for lego design 3003.');
