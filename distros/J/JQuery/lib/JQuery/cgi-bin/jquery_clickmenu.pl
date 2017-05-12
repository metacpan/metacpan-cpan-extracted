#! /usr/bin/perl

use strict ; 
use warnings ;
use JQuery::Demo ;
use CGI ; 

package main ;
my $tester =  new JQuery::Demo ; 
$tester->run ; 

package JQuery::Demo ;
use JQuery::ClickMenu ; 

sub start {
    my $my = shift ;
    my $q = new CGI ; 

    $my->{info}{TITLE} = "ClickMenu" ;

    my $jquery = $my->{jquery} ; 

my $list =<<EOD;
File(f)
 Menu1
 sep(s)
 Menu2
Options(f)
 Menu1
 sep(s)
 Menu2
 SubMenu(f)
  Submenu1
  Submenu2
EOD

my $clickmenu = JQuery::ClickMenu->new(list => $list, 
				  id => 'myclickmenu',
				  headerMenu => 1,
				  separator => '/',
				  addToJQuery => $jquery,
				  rm => 'MyClickMenu',
				  remoteProgram => '/cgi-bin/jquery_clickmenu_results.pl') ; 
my $html = $clickmenu->HTML ;
$my->{info}{BODY} =  qq[$html<div id="results">XXX</div><h1>END OF EXAMPLE</h1>] ;
}

