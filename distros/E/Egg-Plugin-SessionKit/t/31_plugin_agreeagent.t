use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

eval { require Cache::FileCache };
if ($@) { plan skip_all => "Cache::FileCache is not installed." } else {
	&test;
}
sub test {

plan tests=> 14;

my $tool = Egg::Helper->helper_tools;
my $root = $tool->helper_tempdir. '/Vtest';

$tool->helper_create_file
  ($tool->helper_yaml_load(join '', <DATA>), { root=> $root });

$ENV{HTTP_USER_AGENT}= 'test_agent1';

my $e= Egg::Helper->run( vtest=> {
  vtest_root=> $root,
  vtest_config=> { MODEL=> ['Session'] },
  });

ok my $ss= $e->model('session_test'), q{$ss= $e->model('session_test')};
  isa_ok $ss->context, 'Egg::Model::Session::Plugin::AgreeAgent';

ok $ss->{user_agent}, q{$ss->{user_agent}};
  is $ss->{user_agent}, $e->request->agent, q{$ss->{user_agent}, $e->request->agent};

ok my $id= $ss->session_id, q{my $id= $ss->session_id};

ok $ss->is_update(1), q{$ss->is_update(1)};
ok $ss->close_session, q{$ss->close_session};
ok $ss= $e->model('session_test', $id), q{$ss= $e->model('session_test', $id)};
  is $id, $ss->session_id, q{$id, $ss->session_id};

ok $ss->is_update(1), q{$ss->is_update(1)};
ok $ss->close_session, q{$ss->close_session};
$ENV{HTTP_USER_AGENT}= 'test_agent2';
ok $ss= $e->model('session_test', $id), q{$ss= $e->model('session_test', $id)};
  ok $id ne $ss->session_id, q{$id ne $ss->session_id};
  is $ss->{user_agent}, $ENV{HTTP_USER_AGENT}, q{$ss->{user_agent}, $ENV{HTTP_USER_AGENT}};

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
    );
  
  __PACKAGE__->startup qw/
    Plugin::AgreeAgent
    ID::SHA1
    Bind::Cookie
    Base::FileCache
    /;
  
  package Vtest::Model::Session::Test::TieHash;
  use strict;
  use warnings;
  use base qw/ Egg::Model::Session::Manager::TieHash /;
  
  1;
