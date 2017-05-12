use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

# $ENV{EGG_DBI_DSN}       = 'dbi:Pg;:dbname=DATABASE';
# $ENV{EGG_DBI_USER}      = 'db_user';
# $ENV{EGG_DBI_PASSWORD}  = 'db_password';
# $ENV{EGG_DBI_TEST_TABLE}= 'egg_release_dbi_test';

eval{ require DBI };
if ($@) {
	plan skip_all=> "DBI is not installed."
} else {
	my $env= Egg::Helper->helper_get_dbi_attr;
	unless ($env->{dsn}) {
		plan skip_all=> "I want setup of environment variable.";
	} else {
		test($env);
	}
}

sub test {

plan tests=> 56;

my($attr)= @_;
$attr->{options}{AutoCommit}= 1;
my $e= Egg::Helper->run( Vtest => {
  vtest_name=> 'DBITEST',
  MODEL=> [ [ DBI=> $attr ] ],
  });

ok my $reg= $e->model_manager->regists, q{my $reg= $e->model_manager->regists};
  ok $reg->{dbi}, q{$reg->{dbi}};
  ok $reg->{'dbi::main'}, q{$reg->{'dbi::main'}};

ok my $dbi= $e->model('dbi'), q{my $dbi= $e->model('dbi')};
  isa_ok $dbi, 'Egg::Model::DBI::handler';

my $base= $e->project_name. '::Model::DBI';

can_ok $dbi, 'disconnect_all';

can_ok $base, 'config';
  ok $base->config->{dsn}, q{$base->config->{dsn}};

can_ok $base, 'default';
  is $base->default, 'dbi::main', q{$base->default, 'dbi::main'};

ok $base->isa('Egg::Base'), q{$base->isa('Egg::Base')};

can_ok $base, 'labels';
  isa_ok $base->labels, 'HASH';
  ok my $dc= $base->labels->{'dbi::main'}, q{my $dc= $base->labels->{'dbi::main'}};
  is $dc, "${base}::Main", qq{$dc, "${base}::Main"};

can_ok $base, 'mode';
  if ($base->mode eq 'ima') {
  	ok $dc->isa('Ima::DBI'), q{$dc->isa('Ima::DBI')};
  } else {
  	ok 1, q{DBI};
  }

ok my $handler= $e->model('dbi::main'), q{my $handler= $e->model('dbi::main')};
  isa_ok $handler, 'Egg::Model::DBI::Base';
  isa_ok $handler, 'Egg::Model';
  isa_ok $handler, 'Egg::Base';
  is $handler, $e->model, q{$handler, $e->model};
  is $handler, $dbi->main, q{$handler, $dbi->main};

can_ok $handler, 'connect_db';

can_ok $handler, 'connect';

can_ok $handler, 'disconnect';

can_ok $handler, 'dbh';
  ok my $dbh= $handler->dbh, q{my $dbh= $handler->dbh};

can_ok $dbh, 'dbh';
  if ($base->mode eq 'ima') {
  	isa_ok $dbh->dbh, 'DBIx::ContextualFetch::db';
  } else {
  	isa_ok $dbh->dbh, 'DBI::db';
  }

can_ok $dbi, 'handlers';
  isa_ok $dbi->handlers, 'HASH';
  ok $dbi->handlers->{'dbi::main'}, q{$dbi->handlers->{'dbi::main'}};
  isa_ok $dbi->handlers->{'dbi::main'}, 'Egg::Model::DBI::dbh';
  is $dbi->handlers->{'dbi::main'}, $dbh, q{$dbi->handlers->{'dbi::main'}, $dbh};

my $table= $attr->{table};
eval {

ok $dbh->do(<<"END_ST"), qq{ CREATE TABLE $table };
CREATE TABLE $table (
  id     int2      primary key,
  test   varchar
  );
END_ST

my $result;

ok my $sth= $dbh->prepare(qq{ INSERT INTO $table (id, test) VALUES (?, ?) }),
   q{ INSERT INTO $table (id, test) VALUES (?, ?) };
for my $db ([1, 'foo1'], [2, 'foo2'], [3, 'foo3']) {
	ok $sth->execute(@$db), qq{ \$sth->execute($db) };
}
ok my $count= $dbh->prepare
   (qq{ SELECT count(id) FROM $table }), q{ SELECT count(id) FROM $table };
ok $count->execute, q{ $count->execute };
ok $count->bind_columns(\$result), q{ $count->bind_columns(\$result) };
ok $count->fetch, q{ $count->fetch };
ok $count->finish, q{ $count->finish };
ok $result, q{ $result };
is $result, 3, q{ $result, 3 };

ok $sth= $dbh->prepare
   (qq{ SELECT test FROM $table WHERE id = ? }), q{ SELECT test FROM $table };
ok $sth->execute('2'), q{ $sth->execute('2') };
ok $sth->bind_columns(\$result), q{ $sth->bind_columns(\$result) };
ok $sth->fetch, q{ $sth->fetch };
ok $sth->finish, q{ $sth->finish };
ok $result, q{ $result };
is $result, 'foo2', q{ $result, 'foo2' };

  };

ok $dbh->do(qq{ DROP TABLE $table }), qq{ DROP TABLE $table };

ok $handler->disconnect, q{$handler->disconnect};

}



