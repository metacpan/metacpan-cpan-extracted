use Test::Simple 'no_plan';
use strict;
use lib  './lib';
use LEOCHARRE::Database;
use Smart::Comments '###';

my $absdb = './t/test.db';
-f $absdb or die("$absdb not on disk");
my $dbh = DBI::connect_sqlite($absdb);
ok($dbh,"got db connect $absdb") or die;




# ------------------------------

require Metadata::DB::Search::InterfaceHTML;
my $g = Metadata::DB::Search::InterfaceHTML->new({ DBH => $dbh });


for my $method( 
   'search_form_template_code', 
   'search_form_field_prepend',
){
   ok($g->$method, "method $method returns");
}

my $atts = $g->search_attributes_selected;
ok( scalar @$atts );

for ( 0 .. 5 ){
   my $att = $atts->[$_];
   my $varhash = $g->generate_search_attribute_params($att);
   ok($varhash,'generate_search_attribute_params');
   ### $varhash
}








ok( $g->generate_search_interface_loop );




ok( $g->tmpl, 'got tmpl()') or die;


ok( scalar @{$g->search_attributes_selected},'search attributes selected has a count') or die;


ok( $g->generate_search_interface_loop, 'can generate default loop') or die;
ok( scalar @{ $g->generate_search_interface_loop }, 'can generate default loop WITH content inside');




my $form_h;
ok( $form_h = $g->search_form_template_code, 'template code' );

my $form_c;
ok( $form_c = $g->search_form_template_output, 'template output');


save_file('./t/form_h.mdw_search.html',$form_h);
save_file('./t/form_c.mdw_search.html',$form_c);



ok(1,"\n\n\n# # # PART 3 # # # \n\n");
# choose our own ...
# SET LARGER LIMIT
$g->attribute_option_list_limit_set(400);












exit;

sub save_file {
   my($abs_html, $output) = @_;



   open(FILE,'>',$abs_html) or die;
   print FILE $output;
   close FILE;
   ok(-f $abs_html, "saved [$abs_html], this is a temp file");
   return $abs_html;

}



