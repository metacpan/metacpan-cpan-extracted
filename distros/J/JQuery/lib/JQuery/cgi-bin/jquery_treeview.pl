#! /usr/bin/perl

use strict ; 
use warnings ;
use JQuery::Demo ;
use CGI ; 

package main ;
my $tester =  new JQuery::Demo ; 
$tester->run ; 

package JQuery::Demo ;
use JQuery::Treeview ; 

sub start {
    my $my = shift ;
    my $q = new CGI ; 

    $my->{info}{TITLE} = "Treeview" ;

    my $jquery = $my->{jquery} ; 

my $list =<<EOD;
folder 1(fc)
 file 1.1
 file 1.2 
 file 1.3
 folder 1.2(f)
  file 2.1
  file 2.2 
  file 2.3
  folder 1.3(fc)
   folder 1.4(f)
  file 1.4 
folder 2(f)
   file 2.1
folder 3(f)
EOD

my $tree = JQuery::Treeview->new(list => $list, 
				 id => 'mytree',
				 addToJQuery => $jquery,
				 treeControlId => 'myTreeControl',
				 treeControlText => ['Collapse All','Expand All','Toggle All'],
				 defaultState => 'open', 
				 highlightNodes => 1, 
				 highlightLeaves => 1, 
				 highlightUnderline => 1,
				 type => 'directory',
				 rm => 'MyTreeView',
				 debug => 0,
				 remoteProgram => '/cgi-bin/jquery_treeview_results.pl') ; 
my $htmlControl = $tree->HTMLControl ;
my $html = $tree->HTML ;
$my->{info}{BODY} =  qq[<h1>START OF TREEVIEW EXAMPLE</h1>$htmlControl<br>$html<h1><div id="results"></div>END OF EXAMPLE</h1>] ;
}

