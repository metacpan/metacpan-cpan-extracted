#! /usr/bin/perl -w

use strict ; 
use JQuery::Demo ;
use JQuery::CSS ; 
use CGI ; 

package main ;
my $tester =  new JQuery::Demo ;  
$tester->run ; 

package JQuery::Demo ;
use JQuery::Tabs ; 

sub start {
    my $my = shift ;
    my $q = new CGI ; 

    $my->{info}{TITLE} = "Tabs" ;

    my $jquery = $my->{jquery} ; 

    my @tabs = ("tab 1","tab 2","tab 3","tab 4") ; 
    my @texts = ("line 1","line 2","line 3","line4") ; 


# Add css to override defaults - to be added at the end of the css stack

my $tab = JQuery::Tabs->new(id => 'myTab',
			    addToJQuery => $jquery,
			    tabs => \@tabs,
                            texts => \@texts,
			   ) ;

my $html = $tab->HTML ;
$my->{info}{BODY} =  qq[<h1>START OF TAB EXAMPLE</h1>$html</div>END OF EXAMPLE</h1>] ;
}

