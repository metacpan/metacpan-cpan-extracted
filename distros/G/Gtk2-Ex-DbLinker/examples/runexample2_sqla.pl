
use strict;
use warnings;
use lib qw(lib ../lib/ ../../hg_Gtk2-Ex-DbLinker-DbTools/lib/);
use Gtk2 -init;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);
use Forms::Langues2;
use DataAccess::Sqla::Service;
use DBI;
#use Devel::Cycle;

my $dbfile = "./data/ex1_1";

my $dbh = DBI->connect(
    "dbi:SQLite:dbname=$dbfile",
    "", "",
    {
        RaiseError => 1,
        PrintError => 1,
    }
) or die $DBI::errstr;
my $f;
sub load_main_w {
 my $data = DataAccess::Sqla::Service->new({dbh => $dbh }); 
    $f = Forms::Langues2->new( { gladefolder => "./gladefiles", data_broker => $data } );
    #find_cycle($f);

}

&load_main_w;
Gtk2->main;

#find_cycle($f);
#print "Weakened\n";
#find_weakened_cycle($f);

