use Test::More;
use lib qw( ./lib ../lib );
use Egg::Helper;

eval{ require HTML::Prototype };
if ($@) { plan skip_all=> "HTML::Prototype is not installed." } else {

plan tests=> 5;

my $pkg= 'Egg::Helper::Build::Prototype';

require_ok($pkg);

my $e= Egg::Helper->run( Vtest => { helper_test=> $pkg } );

my $htdocs= $e->config->{dir}{htdocs};

$e->helper_create_dir($htdocs);

ok $e->_start_helper, q{$e->_start_helper};
ok -e "$htdocs/prototype.js", qq{-e "$htdocs/prototype.js"};
ok -e "$htdocs/controls.js",  qq{-e "$htdocs/controls.js" };
ok -e "$htdocs/dragdrop.js",  qq{-e "$htdocs/dragdrop.js" };

}

