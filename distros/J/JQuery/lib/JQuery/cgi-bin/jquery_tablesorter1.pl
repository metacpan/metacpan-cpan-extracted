#! /usr/bin/perl -w

use strict ; 
use JQuery::Demo ;
use JQuery::CSS ; 
use CGI ; 

package main ;
my $tester =  new JQuery::Demo ; 
$tester->run ; 

package JQuery::Demo ;
use JQuery::TableSorter ; 

sub start {
    my $my = shift ;
    my $q = new CGI ; 

    $my->{info}{TITLE} = "Table Sorter" ;

    my $jquery = $my->{jquery} ; 
    # Create data for the table
    my $data = [['Id','Total','Ip','Time','UK Short Date','UK Long Date'],
		['66672',  '$22.79','172.78.200.124','08:02','24-12-2000','Jul 6, 2006 8:14 AM'],
		['66672','$2482.79','172.78.200.124','15:10','12-12-2001','Jan 6, 2006 8:14 AM'],
		['66672',  '$22.79','172.78.200.124','08:02','24-12-2000','Jul 6, 2006 8:14 AM'],
		['66672','$2482.79','172.78.200.124','15:10','12-12-2001','Jan 6, 2006 8:14 AM']
	       ] ;

        # Create a TableSorter, add it to JQuery, and get the result as HTML
    my $table= JQuery::TableSorter->new(id => 'table1', 
					addToJQuery => $jquery,
					data => $data, 
					dateFormat=>'dd/mm/yyyy', 
					sortColumn => 'Total', 
					sortClassAsc => 'headerSortUp', 
					sortClassDesc => 'headerSortDown',
					headerClass => 'header',
					stripingRowClass =>  ['even','odd'],
					stripRowsOnStartUp => 'true',
					#highlightClass => 'highlight', 
					disableHeader => 'true'
				       ) ; 
    my $html = $table->HTML ; 
    $my->{info}{BODY} =  qq[<h1>START OF TABLE SORTER EXAMPLE</h1>$html</div>END OF EXAMPLE</h1>] ;
}

