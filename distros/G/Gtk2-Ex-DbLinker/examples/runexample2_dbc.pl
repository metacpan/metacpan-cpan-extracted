
use strict;
use warnings;
use lib qw(lib ../lib/ ../../hg_Gtk2-Ex-DbLinker-DbTools/lib/);
use Gtk2 -init;
use Dbc::Schema;

#use Devel::Cycle;

#use lib "../lib/";
use DataAccess::Dbc::Service;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

use Log::Any::Adapter;
Log::Any::Adapter->set('Log::Log4perl');

use Forms::Langues2;

=for comment
my $dbh = DBI->connect ("dbi:SQLite:dbname=$dbfile","","", {  
		RaiseError       => 1,
        PrintError       => 1,
        }) or die $DBI::errstr;
=cut

sub get_schema {
    my $file = shift;
    my $dsn  = "dbi:SQLite:dbname=$file";

    #$globals->{ConnectionName}= $conn->{Name};
    my $s = Dbc::Schema->connect(
        $dsn,

    );
    return $s;
}
my $f;
sub load_main_w {
   my $data = DataAccess::Dbc::Service->new({schema => get_schema("./data/ex1_1") }); 
  
   $f = Forms::Langues2->new(
        { gladefolder => "./gladefiles", data_broker => $data  } );

}

&load_main_w;
Gtk2->main;

#find_cycle($f);
#print "Weakened\n";
#find_weakened_cycle;

