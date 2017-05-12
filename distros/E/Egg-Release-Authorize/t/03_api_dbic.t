use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

#
# $ENV{DBIC_TRACE}= 3;
#

# $ENV{EGG_DBI_DSN}       = 'dbi:Pg;:dbname=DATABASE';
# $ENV{EGG_DBI_USER}      = 'db_user';
# $ENV{EGG_DBI_PASSWORD}  = 'db_password';
# $ENV{EGG_DBI_TEST_TABLE}= 'egg_release_dbi_test';

eval{ require Cache::FileCache };
if ($@) {
	plan skip_all=> "Cache::FileCache is not installed."
} else {
	eval{ require Egg::Release::DBIC };
	if ($@) {
		plan skip_all=> "Egg::Release::DBIC is not installed."
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

plan tests=> 86;

my($attr)= @_;

my $tool= Egg::Helper->helper_tools;

my $project= 'Vtest';
my $path   = $tool->helper_tempdir. "/$project";
my $table  = $attr->{table};

$tool->helper_create_files(
  [ $tool->helper_yaml_load( join '', <DATA> ) ],
  { path=> $path, dbname => $table, dbi=> $attr }
  );

my $e= Egg::Helper->run( Vtest => {
#  vtest_plugins=> [qw/ -Debug /],
  vtest_root   => $path,
  vtest_config => { MODEL=> [qw/ DBIC Auth /] },
  });

my $dbh = $e->model('dbic::schema')->storage->dbh;

eval {

$dbh->do(<<END_ST);
CREATE TABLE $table (
  uid      char(32)   primary key,
  psw      char(32),
  a_group  char(8),
  active   int2,
  age      int2
  );
END_ST

my $auth= $e->model('dbic::schema::auth');
{
	my @cols= qw/ uid psw active a_group age /;
	for my $i (
	  [qw/ tester1 %test% 1 admin 20 /],
	  ['tester2', undef, qw/ 1 users 21/],
	  [qw/ tester3 %test% 0 users 22 /],
	  [qw/ tester4 %test% 1 users 23 /],
	  ) {
		$auth->create({ map{ $cols[$_] => $i->[$_] }(0..$#cols) });
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
  is $s->default, 'dbic', q{$s->default, 'dbic'};

can_ok $s, 'api';
  ok my $a= $s->api, q{my $a= $s->api};
  is $a, $s->api('dbic'), q{$a, $s->api('dbic')};
  isa_ok $a, 'Vtest::Model::Auth::Test::API::DBIC';
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
can_ok $a, 'search_attr';
  isa_ok $a->search_attr, 'HASH';
can_ok $a, 'dbic';
##

my $param= $e->request->params;
$param->{__uid}= 'tester1';
$param->{__psw}= '%test%';

can_ok $s, 'login_check';
  ok my $data= $s->login_check, q{my $data= $s->login_check};
  isa_ok $data, 'HASH';

can_ok $s, 'data';
  is $data, $s->data, q{$data, $s->data};
  is $data->{___api_name}, 'dbic', q{$data->{___api_name}, 'dbic'};
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
ok $s->login_check( dbic => qw/ tester1 %test% /), q{$s->login_check( dbic => qw/ tester1 %test% /)};
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

$dbh->do(qq{DROP TABLE $table});
$dbh->disconnect;

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
    dbic=> {
      model_name     => 'dbic::schema::auth',
      id_field       => 'uid',
      password_field => 'psw',
      active_field   => 'active',
      group_field    => 'a_group',
      },
    );
  
  __PACKAGE__->setup_session( FileCache => 'Bind::Cookie' );
  
  __PACKAGE__->setup_api('DBIC');
  
  1;
---
filename: <e.path>/lib/Vtest/Model/DBIC/Schema.pm
value: |
  package Vtest::Model::DBIC::Schema;
  use strict;
  use warnings;
  use base qw/ Egg::Model::DBIC::Schema /;
  
  our $VERSION = '0.01';
  
  __PACKAGE__->config(
    dsn      => '<e.dbi.dsn>',
    user     => '<e.dbi.user>',
    password => '<e.dbi.password>',
    options  => { AutoCommit => 1, RaiseError=> 1 },
    );
  
  __PACKAGE__->load_classes;
  
  1;
---
filename: <e.path>/lib/Vtest/Model/DBIC/Schema/Auth.pm
value: |
  package Vtest::Model::DBIC::Schema::Auth;
  use strict;
  use warnings;
  use base qw/ DBIx::Class /;
  
  our $VERSION = '0.01';
  
  __PACKAGE__->load_components("PK::Auto", "Core");
  __PACKAGE__->table("<e.dbi.table>");
  __PACKAGE__->add_columns(
    "uid",
    {
      data_type => "character",
      default_value => undef,
      is_nullable => 0,
      size => 32,
    },
    "psw",
    {
      data_type => "character",
      default_value => undef,
      is_nullable => 0,
      size => 32,
    },
    "a_group",
    {
      data_type => "character",
      default_value => undef,
      is_nullable => 0,
      size => 8,
    },
    "active",
    {
      data_type => "smallint",
      default_value => undef,
      is_nullable => 0,
    },
    "age",
    {
      data_type => "smallint",
      default_value => undef,
      is_nullable => 0,
    },
  );
  __PACKAGE__->set_primary_key("uid");
  
  1;
