use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

eval{ require Egg::Model::Cache };
if ($@) {
	plan skip_all => "Egg::Model::Cache is not installed.";
} else {
	eval{ require Egg::Plugin::LWP };
	if ($@) {
		plan skip_all => "Egg::Plugin::LWP is not installed.";
	} else {
		eval { require Cache::FileCache };
		if ($@) {
			plan skip_all => "Cache::FileCache is not installed.";
		} else {
			test();
		}
	}
}

sub test {

plan tests=> 16;

my $tool = Egg::Helper->helper_tools;
my $root = $tool->helper_tempdir. '/Vtest';

$tool->helper_create_file
  ($tool->helper_yaml_load(join '', <DATA>), { root=> $root });

ok my $e= Egg::Helper->run( vtest=> {
  vtest_plugins => [qw/ Cache::UA /],
  vtest_root    => $root,
  vtest_config  => {
    MODEL=> ['Cache'],
    plugin_cache_ua => {
      cache_name => 'cache_test',
      allow_hosts=> [qw/ 127.0.0.1 /],
      },
    },
  }), 'Constructor.';

isa_ok $e, 'Egg::Plugin::Cache::UA';
isa_ok $e, 'Egg::Plugin::LWP';

can_ok $e, 'ua';
  ok my $ua= $e->ua, q{my $ua= $e->ua};
  isa_ok $ua, 'Egg::Plugin::LWP::handler';

can_ok $e, 'cache_ua';
  ok my $cu= $e->cache_ua, q{my $cu= $e->cache_ua};
  isa_ok $cu, 'Egg::Plugin::Cache::UA::handler';

can_ok $cu, 'cache';
  ok my $cache= $cu->cache, q{my $cache= $cu->cache};
  isa_ok $cache, 'Vtest::Model::Cache::Test';

can_ok $cu, 'get';

can_ok $cu, 'output';

can_ok $cu, 'delete';

can_ok $cu, 'remove';

}


__DATA__
filename: <e.root>/lib/Vtest/Model/Cache/Test.pm
value: |
  package Vtest::Model::Cache::Test;
  use strict;
  use warnings;
  use base qw/ Egg::Model::Cache::Base /;
  
  __PACKAGE__->config(
    label_name => 'cache_test',
    cache_root => Vtest->path_to('cache'),
    namespace  => 'CacheTest',
    );
  
  __PACKAGE__->setup_cache('Cache::FileCache');
  
  1;
