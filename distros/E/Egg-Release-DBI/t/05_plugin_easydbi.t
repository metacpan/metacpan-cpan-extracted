use Test::More;
use strict;
use warnings;
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

plan tests=> 15;

my($dbi)= @_;
$dbi->{options}{AutoCommit}= 1;

my $e= Egg::Helper->run( Vtest=> {
  vtest_plugins=> [qw/ EasyDBI /],
  MODEL=> [ [ DBI=> $dbi ] ],
  plugin_easydbi=> {
    debug      => 1,
    upgrade_ok => 1,
    clear_ok   => 1,
    },
  });

my $table= $dbi->{table};

can_ok $e, 'dbh';
  ok my $dbh= $e->dbh, q{my $dbh= $e->dbh};
  isa_ok $dbh, 'Egg::Plugin::EasyDBI::handler';
  isa_ok $dbh, 'Egg::Mod::EasyDBI';
  can_ok $dbh, 'dbh';
  can_ok $dbh, 'db';
  can_ok $dbh, 'commit_ok';
  can_ok $dbh, 'rollback_ok';

can_ok $e, 'db';
  ok my $db= $e->db, q{my $db= $e->db};
  isa_ok $db, 'Egg::Mod::EasyDBI::db';

ok my $tb= $db->$table, qq{my \$tb= \$db->$table};
  isa_ok $tb, "Egg::Mod::EasyDBI::db::$table",
     qq{\$tb, "Egg::Mod::EasyDBI::db::$table"};
  isa_ok $tb, "Egg::Mod::EasyDBI::table",
     q{$tb, "Egg::Mod::EasyDBI::table"};

can_ok $e, 'close_dbh';

}
