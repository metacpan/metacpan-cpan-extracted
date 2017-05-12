use Test::More tests => 3;
use lib qw( ./lib ../lib );
use Egg::Helper;

my $pkg= 'Egg::Helper::Build::Plugin';

require_ok($pkg);

my $e= Egg::Helper->run( Vtest => { helper_test=> $pkg });
my $c= $e->config;

@ARGV= 'Test';
$c->{helper_option}{project_root}= $c->{root};

ok $e->_start_helper, q{$e->_start_helper};
ok -e "$c->{dir}{lib}/Egg/Plugin/Test.pm", qq{-e "$c->{dir}{lib}/Egg/Plugin/Test.pm"};

