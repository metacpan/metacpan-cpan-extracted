use Test::More tests=> 14;
use lib qw( ../lib ./lib );
use Egg::Helper;

my $e= Egg::Helper->run( Vtest=> {
  vtest_name    => 'LOADER',
  vtest_plugins => [qw/ ConfigLoader /],
  } );

$e->helper_create_files([$e->helper_yaml_load(join '', <DATA>)]);

my $conf= $e->config;

can_ok $e, '_load_config';
  ok my $c= $e->_load_config(\"any.yaml"),
     q{my $c= $e->_load_config(\"any.yaml")};
  isa_ok $c, 'HASH';
  is $c->{test}, 'good', q{$c->{test}, 'good'};
  ok $c= $e->_load_config(\"$conf->{root}"),
     q{$c= $e->_load_config(\"$conf->{root}")};
  isa_ok $c, 'HASH';
  is $c->{test}, 'good', q{$c->{test}, 'good'};
  ok $e->helper_remove_dir('loader.yaml'),
     q{$e->helper_remove_dir('loader.yaml')};
  ok $c= $e->_load_config(\"$conf->{root}"),
     q{$c= $e->_load_config(\"$conf->{root}")};
  isa_ok $c, 'HASH';
  is $c->{test}, 'good', q{$c->{test}, 'good'};
  ok $c= $e->_load_config, q{$c= $e->_load_config};
  isa_ok $c, 'HASH';
  is $c->{test}, 'good', q{$c->{test}, 'good'};

__DATA__
---
filename: any.yaml
value: |
  root: good
  test: <e.root>
---
filename: loader.yaml
value: |
  root: good
  test: <e.root>
---
filename: etc/loader.yaml
value: |
  root: good
  test: <e.root>
---
filename: lib/LOADER/config.pm
value: |
  package LOADER::config;
  sub out { {
  root=> 'good',
  test=> '<e.root>',
  } }
  
  1;
