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

my $e= Egg::Helper->run( vtest=> {
  vtest_root=> $root,
  vtest_config=> { MODEL=> ['Session'] },
  });

ok my $ss= $e->model('session_test'), q{$ss= $e->model('session::test')};
  isa_ok $ss->context, 'Egg::Model::Session::Plugin::AbsoluteIP';

ok $ss->{ipaddr}, q{$ss->{ipaddr}};
  is $ss->{ipaddr}, $e->request->address, q{$ss->{ipaddr}, $e->request->address};

ok my $id= $ss->session_id, q{my $id= $ss->session_id};

ok $ss->is_update(1), q{$ss->is_update(1)};
ok $ss->close_session, q{$ss->close_session};
ok $ss= $e->model('session_test', $id), q{$ss= $e->model('session_test', $id)};
  is $id, $ss->session_id, q{$id, $ss->session_id};

ok $ss->is_update(1), q{$ss->is_update(1)};
ok $ss->close_session, q{$ss->close_session};
$ENV{REMOTE_ADDR}= '192.168.22.22';
ok $ss= $e->model('session_test', $id), q{$ss= $e->model('session_test', $id)};
  ok $id ne $ss->session_id, q{$id ne $ss->session_id};
  is $ss->{ipaddr}, $ENV{REMOTE_ADDR}, q{$ss->{ipaddr}, $ENV{REMOTE_ADDR}};

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
    Plugin::AbsoluteIP
    ID::SHA1
    Bind::Cookie
    Base::FileCache
    /;
  
  package Vtest::Model::Session::Test::TieHash;
  use strict;
  use warnings;
  use base qw/ Egg::Model::Session::Manager::TieHash /;
  
  1;
