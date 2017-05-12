use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

# $ENV{EGG_DBI_DSN}       = 'dbi:Pg;:dbname=DATABASE';
# $ENV{EGG_DBI_USER}      = 'db_user';
# $ENV{EGG_DBI_PASSWORD}  = 'db_password';
# $ENV{EGG_DBI_TEST_TABLE}= 'egg_release_dbi_test';

eval{ require Egg::Release::DBI };
if ($@) {
	plan skip_all=> "Egg::Release::DBI is not installed.";
} else {
	my $env= Egg::Helper->helper_get_dbi_attr;
	unless ($env->{dsn}) {
		plan skip_all=> "I want setup of environment variable.";
	} else {
		test($env);
	}
}

sub test {

plan tests=> 68;

my($attr)= @_;

my $tool = Egg::Helper->helper_tools;
my $root = $tool->helper_tempdir. '/Vtest';
my $table= $attr->{table};

$tool->helper_create_file(
  $tool->helper_yaml_load(join '', <DATA>), {
    root   => $root,
    dbname => $table,
    });

$attr->{options}{AutoCommit}= 1;
$attr->{options}{RaiseError}= 1;
my $e= Egg::Helper->run( Vtest => {
#  vtest_plugins=> [qw/ -Debug /],
  vtest_root=> $root,
  vtest_config=> { MODEL=> [ [ DBI=> $attr ], 'Session' ] },
  });

my $dbh= $e->model('dbi::main')->dbh;

eval {

$dbh->do(<<"END_ST");
CREATE TABLE $table (
  id         char(32)    primary key,
  lastmod    timestamp,
  a_session  text
  );
END_ST

can_ok 'Vtest::Model::Session::Test', 'config';
  my $c= Vtest::Model::Session::Test->config;
  ok $c->{dbi}, q{$c->{dbi}};

ok my $s= $e->model('session_test'), q{my $s= $e->model('session_test')};
  isa_ok $s, 'HASH';
  isa_ok $s, 'Vtest::Model::Session::Test';
  isa_ok $s, 'Egg::Model::Session::Manager::Base';

can_ok $s, 'label_name';
  is $s->label_name, 'session_test', q{$s->label_name, 'session_test'};

my $t_class= "Vtest::Model::Session::Test::TieHash";

can_ok $s, 'context';
  ok my $t= $s->context, q{my $t= $s->context};
  is tied(%$s), $t, q{tied(%$s), $t};
  isa_ok $t, 'ARRAY';
  isa_ok $t, $t_class;
  isa_ok $t, 'Egg::Model::Session::ID::SHA1';
  isa_ok $t, 'Egg::Model::Session::Bind::Cookie';
  isa_ok $t, 'Egg::Model::Session::Store::Base64';
  isa_ok $t, 'Egg::Model::Session::Base::DBI';
  isa_ok $t, 'Egg::Model::Session::Manager::TieHash';
  {
  	no strict 'refs';  ## no critic.
  	my $isa= \@{"${t_class}::ISA"};
  	is $isa->[-1], 'Egg::Component::Base',
  	   q{$isa->[-1], 'Egg::Component::Base'};
  	is $isa->[-2], 'Egg::Model::Session::Manager::TieHash',
  	   q{$isa->[-2], 'Egg::Model::Session::Manager::TieHash'};
    };

can_ok $t, '_label';
  is $t->_label, 'dbi::main', q{$t->_label, 'dbi::main'};

can_ok $t, '_insert';
  like $t->_insert, qr{^\s*INSERT\s+INTO\s+$table\s+\(id\,\s+a_session\,\s+lastmod\s*\)\s+VALUES\s+\(\s*\?\,\s+\?\,\s+\?\s*\)\s*$},
       q{$t->_insert, qr{^\s*INSERT\s+INTO\s+ ... }};
can_ok $t, '_update';
  like $t->_update, qr{^\s*UPDATE\s+$table\s+SET\s+a_session\s+\=\s+\?\,\s+lastmod\s+\=\s+\?\s+WHERE\s+id\s+\=\s+\?\s*$},
       q{$t->_update, qr{^\s*UPDATE\s+$table ... }};
can_ok $t, '_delete';
  like $t->_delete, qr{^\s*DELETE\s+FROM\s+$table\s+WHERE\s+id\s+\=\s+\?\s*$},
       q{$t->_delete, qr{^\s*DELETE\s+FROM\s+ ...}};
can_ok $t, '_clear';
  like $t->_clear, qr{^\s*DELETE\s+FROM\s+$table\s+WHERE\s+lastmod\s+\<\s+\?\s*$},
       q{$t->_clear, qr{^\s*DELETE\s+FROM\s+ ... }};

can_ok $t_class, '_restore';

can_ok $t_class, '_commit';

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
  ok $s2->{end}= 1, q{$s2->{end}= 1};

can_ok $t, '_finish';

can_ok $t, '_finalize_error';

ok $s2->close_session, q{$s->close_session};

$e->debug_end;

  };

$@ and warn $@;

$dbh->do(qq{ DROP TABLE $table });
$dbh->disconnect;

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
    dbi=> {
     dbname => '<e.dbname>',
     },
    );
  
  __PACKAGE__->startup qw/
    ID::SHA1
    Bind::Cookie
    Store::Base64
    Base::DBI
    /;
  
  package Vtest::Model::Session::Test::TieHash;
  use strict;
  use warnings;
  use base qw/ Egg::Model::Session::Manager::TieHash /;
  
  1;
