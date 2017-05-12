use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

eval{ require Cache::FileCache };

if ($@) {
	plan skip_all=> "Cache::FileCache is not installed."
} else {
	test();
}

sub test {

plan tests=> 89;

my $tool= Egg::Helper->helper_tools;

my $project= 'Vtest';
my $path   = $tool->helper_tempdir. "/$project";

$tool->helper_create_files(
  [ $tool->helper_yaml_load( join('', <DATA>)) ],
  { path => $path },
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

can_ok 'Vtest::Model::Auth::Test', 'config';
  ok my $c= Vtest::Model::Auth::Test->config, q{my $c= Vtest::Model::Auth::Test->config};
  $e->helper_create_dir($c->{filecache}{cache_root});

can_ok $s, 'e';
  is $s->e, $e, q{$s->e, $e};

can_ok $s, 'default';
  is $s->default, 'file', q{$s->default, 'file'};

can_ok $s, 'api';
  ok my $a= $s->api, q{my $a= $s->api};
  is $a, $s->api('file'), q{$a, $s->api('file')};
  isa_ok $a, 'Vtest::Model::Auth::Test::API::File';
  isa_ok $a, 'Egg::Model::Auth::Base::API';
  isa_ok $a, 'Egg::Component::Base';

can_ok $a, 'id_col';
  is $a->id_col, 'uid', q{$a->id_col, 'uid'};
can_ok $a, 'psw_col';
  is $a->psw_col, 'psw', q{$a->psw_col, 'psw'};
can_ok $a, 'act_col';
  is $a->act_col, 'active', q{$a->act_col, 'active'};
can_ok $a, 'grp_col';
  is $a->grp_col, 'a_group', q{$a->grp_col, 'a_group'};

##
can_ok $s, 'session_id';
can_ok $a, 'path';
  is $a->path, "$path/etc/members", q{$a->path, "$path/etc/members"};
can_ok $a, 'columns';
  isa_ok $a->columns, 'ARRAY';
  is $a->columns->[0], 'uid', q{$a->columns->[0], 'uid'};
can_ok $a, 'delimiter';
##

my $param= $e->request->params;
$param->{__uid}= 'tester1';
$param->{__psw}= '%test%';

can_ok $s, 'login_check';
  ok my $data= $s->login_check, q{my $data= $s->login_check};
  isa_ok $data, 'HASH';

can_ok $s, 'data';
  is $data, $s->data, q{$data, $s->data};
  is $data->{___api_name}, 'file', q{$data->{___api_name}, 'file'};
  is $data->{___user}, 'tester1', q{$data->{___user}, 'tester1'};
  is $data->{___password}, '%test%', q{$data->{___password}, '%test%'};
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

ok $s->login_check(qw/ tester1 %test% /), q{$s->login_check(qw/ tester1 %test% /)};
ok $s->logout, q{$s->logout};
ok $s->login_check( file => qw/ tester1 %test% /), q{$s->login_check( file => qw/ tester1 %test% /)};
ok $s->logout, q{$s->logout};

can_ok $s, 'error';
can_ok $s, 'is_error';
can_ok $s, 'error_message';
$param->{__uid}= $param->{__psw}= '';

ok ! $s->login_check('tester2', undef), q{! $s->login_check(qw/ tester2 /)};
  ok ! $s->is_login, q{! $s->is_login};
  is $s->is_error, 200, q{$s->is_error, 200};

ok ! $s->login_check(qw/ tester2 %test% /), q{! $s->login_check(qw/ tester2 %test% /)};
  ok ! $s->is_login, q{! $s->is_login};
  is $s->is_error, 220, q{$s->is_error, 220};

ok ! $s->login_check(qw/ tester3 %test% /), q{! $s->login_check(qw/ tester3 %test% /)};
  ok ! $s->is_login, q{! $s->is_login};
  is $s->is_error, 140, q{$s->is_error, 140};

ok ! $s->login_check(qw/ tester4 %bad% /), q{! $s->login_check(qw/ tester4 %bad% /)};
  ok ! $s->is_login, q{! $s->is_login};
  is $s->is_error, 230, q{$s->is_error, 230};

ok $s->login_check(qw/ tester4 %test% /), q{$s->login_check(qw/ tester4 %test% /)};
  ok $s->is_login, q{$s->is_login};
  ok ! $s->is_error, q{! $s->is_error};
  ok $s->group_check('users'), q{$s->group_check('users')};
  ok $s->logout, q{$s->logout};
  ok ! $s->is_login, q{! $s->is_login};

ok ! $s->login_check(qw/ tester5 %test% /), q{! $s->login_check(qw/ tester5 %test% /)};
  ok ! $s->is_login, q{! $s->is_login};
  is $s->is_error, 120, q{$s->is_error, 120};

ok $s->_finish, q{$s->_finish};
ok $s->_finalize_error, q{$s->_finalize_error};

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
    label_name => 'a_test',
    login_get_ok => 1,
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
  
  __PACKAGE__->setup_api('File');
  
  1;
---
filename: <e.path>/etc/members
value: |
  tester1	%test%	1	admin	20
  tester2		1	users	21
  tester3	%test%	0	users	22
  tester4	%test%	1	users	23

