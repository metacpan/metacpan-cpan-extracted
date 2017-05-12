use Test::More;
use lib qw( ./lib ../lib );
use Egg::Helper;
use DBI;

my $pkg= 'Egg::Helper::Model::DBIC';

# $ENV{EGG_DBI_DSN}       = 'dbi:Pg;:dbname=DATABASE';
# $ENV{EGG_DBI_USER}      = 'db_user';
# $ENV{EGG_DBI_PASSWORD}  = 'db_password';
# $ENV{EGG_DBI_TEST_TABLE}= 'egg_release_dbi_test';

;my $attr= Egg::Helper->helper_get_dbi_attr;
unless ($attr->{dsn})
  { plan skip_all=> "I want setup of environment variable." } else {

plan tests=> 12;

my $name = 'Test';
my $e    = Egg::Helper->run( Vtest => { helper_test=> $pkg });
my $c    = $e->config;
my $p    = $e->project_name;
my $table= $attr->{table};
my $moniker;
   $moniker.= ucfirst($_) for (split /_/, $table);
my $scahema_dir = "$c->{root}/lib/$p/Model/DBIC/$name";
my $scahema_path= "$scahema_dir.pm";

$e->helper_create_dir("$c->{dir}{lib_project}/Model/DBIC");

$attr->{options}{AutoCommit}= 1;

my $dbh= DBI->connect(@{$attr}{qw/ dsn user password options /});
eval{

$dbh->do(<<"END_ST");
CREATE TABLE $table (
  id     int2      primary key,
  test   varchar
  );
END_ST

@ARGV= (
  $name,
  "-d$attr->{dsn}",
  "-u$attr->{user}",
  "-p$attr->{password}",
  );
$c->{helper_option}{project_root}= $c->{root};

ok $e->_start_helper, q{$e->_start_helper};
ok -e $scahema_path,  q{-e $scahema_path};
ok -e $scahema_dir,   q{-e $scahema_dir};
ok -e "$scahema_dir/$moniker.pm", qq{-e "$scahema_dir/$moniker.pm"};
ok my $value= $e->helper_fread($scahema_path),
   q{my $value= $e->helper_fread($scahema_path)};
like $value, qr{\n\s*\#\s*use\s+base\s+\'DBIx\:+Class\:+Schema\'\;\s*\n}s,
   q{$value, qr{\n\s*\#\s*use\s+base\s+\'DBIx\:+Class\:+Schema\'\;\s*\n}s};
like $value, qr{\n\s*use\s+base\s+qw\/\s*Egg\:+Model\:+DBIC\:+Schema\s*\/\;\s*\n}s,
   q{$value, qr{\n\s*use\s+base\s+qw\/\s*Egg\:+Model\:+DBIC\:+Schema\s*\/\;\s*\n}s};
like $value, qr{\n\s*__PACKAGE__\->config\(\s*\n},
   q{$value, qr{\n\s*__PACKAGE__\->config\(\s*\n}};
like $value, qr{\n\s+dsn\s*\=>\s*\'[^\']+\'\,\s*\n}s,
   q{$value, qr{\n\s+dsn\s*\=>\s*\'[^\']+\'\,\s*\n}s};
like $value, qr{\n\s+user\s+\=>\s*\'[^\']+\'\,\s*\n}s,
   q{$value, qr{\n\s+user\s+\=>\s*\'[^\']+\'\,\s*\n}s};
like $value, qr{\n\s+password\s+\=>\s*\'[^\']+\'\,\s*\n}s,
   q{$value, qr{\n\s+password\s+\=>\s*\'[^\']+\'\,\s*\n}s};
like $value, qr{\n\s+options\s*\=>\s*\{\s*\n}s,
   q{$value, qr{\n\s+options\s*\=>\s*\{\s*\n}s};

  };

$@ and warn $@;

$dbh->do("DROP TABLE $table");
$dbh->disconnect;

}

