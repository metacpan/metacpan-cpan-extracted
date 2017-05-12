use Test::More;
use lib qw( ./lib ../lib );
use Egg::Helper;

eval{ require HTTP::BrowserDetect };
if ($@) { plan skip_all=> "HTTP::BrowserDetect is not installed." } else {

plan tests=> 4;

ok my $e= Egg::Helper->run( Vtest=> {
  vtest_plugins=> [qw/ HTTP::BrowserDetect /],
  }), q{load plugin.};

can_ok $e, 'browser';
  isa_ok $e, 'Egg::Plugin::HTTP::BrowserDetect';
  isa_ok $e->browser, 'HTTP::BrowserDetect';

}
