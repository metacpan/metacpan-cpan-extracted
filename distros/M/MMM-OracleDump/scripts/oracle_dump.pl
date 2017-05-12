#!%%FULLPERL%% -s

use %%NAME%%;
use %%NAME%%::Table;
use DBI;
use strict;
use vars qw/ $VERSION /;

$ENV{ORACLE_HOME} ||= '%%ORACLE_HOME%%';
$VERSION = "1,0";

my ($loginpars, $dir) = @ARGV;

if (not ( $loginpars && $dir ) ) {
	die "oracle_dump v. $VERSION\nusage: oracle_dump user/passwd\@sid[:table] outdir\n";
}

if ( ! -d $dir ) {
	die "$dir: $!\n" unless mkdir $dir, 0755;
}

my ($user,$password, $db ,$table ) = split /\/|\@|\s+|:/, $loginpars;

print "Connecting to $user\@$db...\n";
my $dbh = DBI->connect("dbi:Oracle:$db", $user, $password ,  { PrintError => 1 } );
$dbh || die "$DBI::errstr.\n";
print "Connected.\n";

if (! $table) {
	$table = '.*';
}
my @tables = grep /^$table$/i , get_table_list($dbh);

my $outdir = $user . '@' . $db;
my $dumpdir = $dir . "/". $outdir;

if (! -d $dumpdir ) {
	die "$dumpdir: $!\n" unless mkdir $dumpdir, 0755;
}

print "Dumping '$user\@$db:$table' into $dumpdir directory...\n";
for (@tables) {
	my $create_sql_file =  $dumpdir . "/". $_ . ".ddl.sql";
	my $content_sql_file = $dumpdir . "/". $_ . ".data.sql";
	my $tab = new %%NAME%%::Table($dbh,$_);
	open F1, ">$create_sql_file";
	open F2, ">$content_sql_file";
	print "dumping $_ to:\n";
	print " $create_sql_file\n";
	print " $content_sql_file\n";
	print F1 $tab->get_create_sql();
	$tab->dump_sql(\*F2);
	close F1;
	close F2;
}

$dbh->disconnect;

