use Test::Simple 'no_plan';
use strict;
use lib  './lib';
use LEOCHARRE::Database;
use Smart::Comments '###';

my $absdb = './t/test.db';

-f $absdb or die("$absdb not on disk");


my $dbh = DBI::connect_sqlite($absdb);
ok($dbh,"got db connect to $absdb") or die;


# ------------------------------

require Metadata::DB::Search::InterfaceHTML;
my $g = Metadata::DB::Search::InterfaceHTML->new({ DBH => $dbh });



my $form_c;
ok( $form_c = $g->search_form_template_output, 'template output');


save_file('./t/mdw.search.html',$form_c);




exit;

sub save_file {
   my($abs_html, $output) = @_;



   open(FILE,'>',$abs_html) or die;
   print FILE $output;
   close FILE;
   ok(-f $abs_html, "saved [$abs_html], this is a tmp file");
   return $abs_html;

}



