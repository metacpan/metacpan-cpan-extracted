
use strict;
use warnings;
use lib qw(lib ../lib/ ../../hg_Gtk2-Ex-DbLinker-DbTools/lib/);
use Gtk2 -init;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);


use Log::Any::Adapter;
Log::Any::Adapter->set('Log::Log4perl');

use Forms::Langues2;
use DBI;
use DataAccess::Rdb::Service;
#use Devel::Cycle;

my $f;

sub load_main_w {
 my $data = DataAccess::Rdb::Service->new(); 
  
    $f = Forms::Langues2->new( { gladefolder => "./gladefiles", data_broker => $data } );

}

&load_main_w;
Gtk2->main;

#find_cycle($f);
#print "Weakened\n";
#find_weakened_cycle($f);
