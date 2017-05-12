
use strict;
use warnings;
use lib qw(lib ../lib/ ../../hg_Gtk2-Ex-DbLinker-DbTools/lib/);
use Gtk2 -init;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);
#use Devel::Cycle;
#use lib "../lib/";

use Forms::Langues1;

use DBI;

my $dbfile = "./data/ex1";

my $dbh = DBI->connect(
    "dbi:SQLite:dbname=$dbfile",
    "", "",
    {
        RaiseError => 1,
        PrintError => 1,
    }
) or die $DBI::errstr;

sub load_main_w {

   Forms::Langues1->new( { gladefolder => "./gladefiles", dbh => $dbh } );

}

&load_main_w;
Gtk2->main;

