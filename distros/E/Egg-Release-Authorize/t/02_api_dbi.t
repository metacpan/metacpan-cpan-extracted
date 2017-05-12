use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

# $ENV{EGG_DBI_DSN}       = 'dbi:Pg;:dbname=DATABASE';
# $ENV{EGG_DBI_USER}      = 'db_user';
# $ENV{EGG_DBI_PASSWORD}  = 'db_password';
# $ENV{EGG_DBI_TEST_TABLE}= 'egg_release_dbi_test';

eval{ require Cache::FileCache };
if ($@) {
	plan skip_all=> "Cache::FileCache is not installed."
} else {
	eval{ require Egg::Release::DBI };
	if ($@) {
		plan skip_all=> "Egg::Release::DBI is not installed."
	} else {
		my $env= Egg::Helper->helper_get_dbi_attr;
		unless ($env->{dsn}) {
			plan skip_all=> "I want setup of environment variable.";
		} else {
			test($env);
		}
	}
}

sub test {

plan tests=> 87;

my($attr)= @_;

my $tool= Egg::Helper->helper_tools;

my $project= 'Vtest';
my $path   = $tool->helper_tempdir. "/$project";
my $table  = $attr->{table};

$tool->helper_create_file(
  $tool->helper_yaml_load( join '', <DATA> ),
  { path=> $path, dbname => $table }
  );

$attr->{options}{AutoCommit}= 1;
my $e= Egg::Helper->run( Vtest => {
#  vtest_plugins=> [qw/ -Debug /],
  vtest_root   => $path,
  vtest_config => {
    MODEL=> [ [ DBI=> $attr ], 'Auth' ],
    },
  });

my $dbh= $e->model('dbi::main')->dbh;

eval{

$dbh->do(<<END_CREATE);
CREATE TABLE $table (
  uid      char(16)      primary key,
  psw      char(16),
  a_group  char(8),
  active   int2,
  age      int2
  );
END_CREATE

{
	my $sth= $dbh->prepare
	(qq{INSERT INTO $table (uid, psw, active, a_group, age) VALUES (?, ?, ?, ?, ?)});
	for (
	  [qw/ tester1 %test% 1 admin 20 /],
	  ['tester2', undef, qw/ 1 users 21/],
	  [qw/ tester3 %test% 0 users 22 /],
	  [qw/ tester4 %test% 1 users 23 /],
	  ) {
		$sth->execute(@$_);
	}
  };

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
  is $s->default, 'dbi', q{$s->default, 'dbi'};

can_ok $s, 'api';
  ok my $a= $s->api, q{my $a= $s->api};
  is $a, $s->api('dbi'), q{$a, $s->api('dbi')};
  isa_ok $a, 'Vtest::Model::Auth::Test::API::DBI';
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
can_ok $a, 'dbi_label';
  is $a->dbi_label, "dbi::main", q{$a->dbi_label, "dbi::main"};
can_ok $a, 'statement';
can_ok $a, '__prepare';
##

my $param= $e->request->params;
$param->{__uid}= 'tester1';
$param->{__psw}= '%test%';

can_ok $s, 'login_check';
  ok my $data= $s->login_check, q{my $data= $s->login_check};
  isa_ok $data, 'HASH';

can_ok $s, 'data';
  is $data, $s->data, q{$data, $s->data};
  is $data->{___api_name}, 'dbi', q{$data->{___api_name}, 'dbi'};
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
ok $s->login_check( dbi => qw/ tester1 %test% /), q{$s->login_check( dbi => qw/ tester1 %test% /)};
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

  };

$@ and warn $@;

$e->_finish;
$dbh->do(qq{ DROP TABLE $table });
$dbh->disconnect;

}

__DATA__
filename: <e.path>/lib/Vtest/Model/Auth/Test.pm
value: |
  package Vtest::Model::Auth::Test;
  use strict;
  use warnings;
  use base qw/ Egg::Model::Auth::Base /;
  
  __PACKAGE__->config(
    label_name => 'a_test',
    login_get_ok => 1,
    dbi=> {
      label          => 'dbi::main',
      dbname         => '<e.dbname>',
      id_field       => 'uid',
      password_field => 'psw',
      active_field   => 'active',
      group_field    => 'a_group',
      },
    );
  
  __PACKAGE__->setup_session( FileCache => 'Bind::Cookie' );
  
  __PACKAGE__->setup_api('DBI');
  
  1;
