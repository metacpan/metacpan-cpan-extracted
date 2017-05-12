use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

eval{ require Cache::FileCache };
if ($@) {
	plan skip_all=> "Cache::FileCache is not installed."
} else {
	eval{ require Digest::SHA1 };
	if ($@) {
		plan skip_all=> "Digest::SHA1 is not installed."
	} else {
		test();
	}
}

sub test {

plan tests=> 41;

my $tool= Egg::Helper->helper_tools;

my $project= 'Vtest';
my $path   = $tool->helper_tempdir. "/$project";
my $psw    = '%test%';
my $salt   = '12345';
my $passwd = Digest::SHA1::sha1_hex($psw. $salt);

$tool->helper_create_files(
  [ $tool->helper_yaml_load( join('', <DATA>)) ],
  { path => $path, salt=> $salt, passwd=> $passwd },
  );

my $e= Egg::Helper->run( Vtest => {
#  vtest_plugins=> [qw/ -Debug /],
  vtest_root   => $path,
  vtest_config => { MODEL=> ['Auth'] },
  });

ok $e->is_model('auth'), q{$e->is_model('auth')};
ok $e->is_model('a_test'), q{$e->is_model('a_test')};

ok my $s= $e->model('a_test'), q{$s= $e->model('a_test')};
is $s, $e->model('auth'), q{$s, $e->model('auth')};

isa_ok $s, 'Vtest::Model::Auth::Test';
isa_ok $s, 'Egg::Model::Auth::Session::FileCache';
isa_ok $s, 'Egg::Model::Auth::Bind::Cookie';
isa_ok $s, 'Egg::Model::Auth::Base';
isa_ok $s, 'Egg::Base';
isa_ok $s, 'Egg::Component';
isa_ok $s, 'Egg::Component::Base';

ok my $a= $s->api, q{my $a= $s->api};
isa_ok $a, 'Vtest::Model::Auth::Test::API::File';
isa_ok $a, 'Egg::Model::Auth::Crypt::SHA1';
isa_ok $a, 'Egg::Model::Auth::Base::API';
isa_ok $a, 'Egg::Component::Base';

$e->helper_create_dir($e->path_to('cache'));

##
can_ok $a, 'create_password';
  is $a->create_password($psw), $passwd, qq{$a->create_password('$psw')};
can_ok $a, 'valid_crypt';
  ok $a->valid_crypt($passwd), q{$a->valid_crypt($passwd)};
##

my $param= $e->request->params;
$param->{__uid}= 'tester1';
$param->{__psw}= $psw;

can_ok $s, 'login_check';
  ok my $data= $s->login_check, q{my $data= $s->login_check};
  isa_ok $data, 'HASH';

can_ok $s, 'data';
  is $data, $s->data, q{$data, $s->data};
  is $data->{___api_name}, 'file', q{$data->{___api_name}, 'file'};
  is $data->{___user}, 'tester1', q{$data->{___user}, 'tester1'};
  is $data->{___password}, $passwd, q{$data->{___password}, $passwd};
  is $data->{___active}, 1, q{$data->{___active}, 1};
  is $data->{___group}, 'admin', q{$data->{___group}, 'admin'};
  is $data->{age}, 20, q{$data->{age}, 20};

ok my $cookie= $e->response->cookies->{as}, q{my $cookie= $e->response->cookies->{as}};
  is $cookie->value, $s->session_id, q{$cookie->value, $s->session_id};

can_ok $s, 'is_login';
  ok $s->is_login, q{$s->is_login};
  is $data, $s->is_login, q{$data, $s->is_login};

can_ok $s, 'group_check';
  ok $s->group_check('admin'), q{$s->group_check('admin')};

can_ok $s, 'logout';
  ok $s->logout, q{$s->logout};
  ok ! $s->is_login, q{! $s->is_login};

}
__DATA__
---
filename: <e.path>/lib/Vtest/Model/Auth/Test.pm
value: |
  package Vtest::Model::Auth::Test;
  use strict;
  use warnings;
  use base qw/ Egg::Model::Auth::Base /;
  
  __PACKAGE__->config(
    label_name      => 'a_test',
    login_get_ok    => 1,
    crypt_sha1_salt => '<e.salt>',
    file=> {
      path   => Vtest->path_to(qw/ etc members /),
      fields => [qw/ uid psw active a_group age /],
      id_field       => 'uid',
      password_field => 'psw',
      active_field   => 'active',
      group_field    => 'a_group',
      delimiter      => qr{ *\t *},
      },
    );
  
  __PACKAGE__->setup_session( FileCache => 'Bind::Cookie' );
  
  __PACKAGE__->setup_api( File => 'Crypt::SHA1' );
  
  1;
---
filename: <e.path>/etc/members
value: |
  tester1	<e.passwd>	1	admin	20
  tester2		1	users	21
  tester3	<e.passwd>	0	users	22
  tester4	<e.passwd>	1	users	23

