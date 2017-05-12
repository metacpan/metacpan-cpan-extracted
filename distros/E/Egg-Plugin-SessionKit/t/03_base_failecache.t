use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

eval { require Cache::FileCache };
if ($@) { plan skip_all => "Cache::FileCache is not installed." } else {

plan tests=> 60;

my $tool = Egg::Helper->helper_tools;
my $root = $tool->helper_tempdir. '/Vtest';

$tool->helper_create_file
  ($tool->helper_yaml_load(join '', <DATA>), { root=> $root });

my $e= Egg::Helper->run( vtest=> {
  vtest_root=> $root,
  vtest_config=> { MODEL=> ['Session'] },
  });

can_ok 'Vtest::Model::Session::Test', 'config';
  my $c= Vtest::Model::Session::Test->config;
  ok $c->{filecache}, q{$c->{filecache}};
  ok $c->{filecache}{cache_root}, q{$c->{filecache}{cache_root}};
  is $c->{filecache}{cache_root}, $e->config->{dir}{cache},
     q{$c->{filecache}{cache_root}, $e->config->{dir}{cache}};
  $e->helper_create_dir($c->{filecache}{cache_root});
  ok $c->{filecache}{namespace}, q{$c->{filecache}{namespace}};
  ok $c->{filecache}{cache_depth}, q{$c->{filecache}{cache_depth}};
  ok $c->{filecache}{default_expires_in}, q{$c->{filecache}{default_expires_in}};

ok my $s= $e->model('session_test'), q{my $s= $e->model('session_test')};
  isa_ok $s, 'HASH';
  isa_ok $s, 'Vtest::Model::Session::Test';
  isa_ok $s, 'Egg::Model::Session::Manager::Base';

can_ok $s, 'label_name';
  is $s->label_name, 'session_test', q{$s->label_name, 'session_test'};

can_ok $s, 'context';
  ok my $t= $s->context, q{my $t= $s->context};
  is tied(%$s), $t, q{tied(%$s), $t};
  isa_ok $t, 'ARRAY';
  isa_ok $t, 'Vtest::Model::Session::Test::TieHash';
  isa_ok $t, 'Egg::Model::Session::ID::SHA1';
  isa_ok $t, 'Egg::Model::Session::Bind::Cookie';
  isa_ok $t, 'Egg::Model::Session::Base::FileCache';
  isa_ok $t, 'Egg::Model::Session::Manager::TieHash';
  {
  	no strict 'refs';  ## no critic.
  	my $isa= \@{"Vtest::Model::Session::Test::TieHash::ISA"};
  	is $isa->[-1], 'Egg::Component::Base',
  	   q{$isa->[-1], 'Egg::Component::Base'};
  	is $isa->[-2], 'Egg::Model::Session::Manager::TieHash',
  	   q{$isa->[-2], 'Egg::Model::Session::Manager::TieHash'};
    };

can_ok $t, 'cache';
  isa_ok $t->cache, 'Cache::FileCache';

can_ok $t, 'data';
  isa_ok $t->data, 'HASH';
  is $s->{___session_id}, $t->data->{___session_id},
     q{$s->{___session_id}, $t->data->{___session_id}};
  is $s->{create_time}, $t->data->{create_time},
     q{$s->{create_time}, $t->data->{create_time}};
  is $s->{now_time}, $t->data->{now_time},
     q{$s->{now_time}, $t->data->{now_time}};

can_ok $t, 'attr';
  isa_ok $t->attr, 'HASH';

can_ok $t, 'session_id';
  is $t->session_id, $t->data->{___session_id},
     q{$t->session_id, $t->data->{___session_id}};

can_ok $t, 'e';
  is $e, $t->e, q{$e, $t->e};

can_ok $t, 'is_new';
  ok $t->is_new, q{$t->is_new};

can_ok $t, 'is_update';
  ok ! $t->is_update, q{! $t->is_update};
  ok $s->{test}= 1, q{$s->{test}= 1};
  ok $t->is_update, q{$t->is_update};

can_ok $t, 'change';
  ok my $session_id= $t->session_id, q{my $session_id= $t->session_id};
  ok $t->change, q{$t->change};
  ok $session_id ne $t->session_id, q{$session_id ne $t->session_id};

can_ok $t, 'clear';
  ok $s->{test}, q{$s->{test}};
  ok $s->{test2}= 1, q{$s->{test2}= 1};
  ok $t->clear, q{$t->clear};
  ok ! $s->{test}, q{! $s->{test}};
  ok ! $s->{test2}, q{! $s->{test2}};

can_ok $s, 'close_session';
  $session_id= $s->session_id;
  ok $s->{restore_ok}= 1, q{$s->{restore_ok}= 1};
  ok $s->close_session, q{$s->close_session};

my $s2= $e->model('session_test', $session_id);
  is $s2->session_id, $session_id, q{$s2->session_id, $session_id};
  ok $s2->{restore_ok}, q{$s->{restore_ok}};

can_ok $t, '_finish';

can_ok $t, '_finalize_error';

}


__DATA__
filename: <e.root>/lib/Vtest/Model/Session/Test.pm
value: |
  package Vtest::Model::Session::Test;
  use strict;
  use warnings;
  use base qw/ Egg::Model::Session::Manager::Base /;
  
  __PACKAGE__->config(
    label_name => 'session_test',
    store => {
    
     },
    );
  
  __PACKAGE__->startup qw/
    ID::SHA1
    Bind::Cookie
    Base::FileCache
    /;
  
  package Vtest::Model::Session::Test::TieHash;
  use strict;
  use warnings;
  use base qw/ Egg::Model::Session::Manager::TieHash /;
  
  1;
