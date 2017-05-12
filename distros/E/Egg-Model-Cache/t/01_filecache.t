use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

eval { require Cache::FileCache };
if ($@) { plan skip_all => "Cache::FileCache is not installed." } else {

plan tests=> 16;

my $tool = Egg::Helper->helper_tools;
my $root = $tool->helper_tempdir. '/Vtest';

$tool->helper_create_file
  ($tool->helper_yaml_load(join '', <DATA>), { root=> $root });

my $e= Egg::Helper->run( vtest=> {
#  vtest_plugins => [qw/ -Debug /],
  vtest_root    => $root,
  vtest_config  => { MODEL=> ['Cache'] },
  });

ok $e->is_model('cache_test'), q{$e->is_model('cache_test')};

ok my $m= $e->model('cache_test'), q{my $m= $e->model('cache_test')};

isa_ok $m, 'Vtest::Model::Cache::Test';
isa_ok $m, 'Egg::Model';
isa_ok $m, 'Egg::Component::Base';

can_ok $m, 'cache';
  ok my $cache= $m->cache, q{my $cache= $m->cache};
  isa_ok $cache, 'Cache::FileCache';

ok ! $m->set( test => 'OK' ), q{! $m->set( test => 'OK' )};

ok my $test= $m->get('test'), q{my $test= $m->get('test')};
  is $test, 'OK', q{$test, 'OK'};

ok $m->remove('test'), q{$m->remove('test')};
  ok ! $m->get('test'), q{! $m->get('test')};

ok ! $m->set( test2 => 'OK2' ), q{! $m->set( test2 => 'OK2' )};

delete $m->{cache_context};

ok $test= $m->get('test2'), q{$test= $m->get('test2')};
  is $test, 'OK2', q{$test, 'OK2'};

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
