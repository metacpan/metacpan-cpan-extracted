use Test::Simple 'no_plan';
use strict;


for my $abs ( 
'./t/mdw.search.html',
'./t/mdwui.conf',
'./t/mdwui.form',
'./t/form_c.mdw_search.html',
'./t/form_h.mdw_search.html',
'./t/mdw_search_results_output.html',
'./t/mdw_search_output.html',
){
   -f $abs or next;
   
   ok( (unlink $abs), " deleted $abs in cleanup ");
}

ok(1,'done');

#'./t/test.db',
