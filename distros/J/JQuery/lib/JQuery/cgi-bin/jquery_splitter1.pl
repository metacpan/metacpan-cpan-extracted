#! /usr/bin/perl 

use strict ; 
use warnings ; 

use JQuery::Demo ;

package main ;
my $tester =  new JQuery::Demo ; 
$tester->run ; 

package JQuery::Demo ;
use JQuery::Splitter ; 
use JQuery::CSS ; 

sub start {
    my $my = shift ;
    $my->{info}{TITLE} = "Splitter" ;

    my $jquery = $my->{jquery} ; 

    my $leftHTML = "Left HTML";
    my $rightHTML = "Right HTML" ; 


    my $splitter1 = JQuery::Splitter->new(id => 'MySplitter', 
					  addToJQuery => $jquery,
					  browserFill => 1,
					  type => 'v',
					  HTML1 => $leftHTML, HTML2 => $rightHTML) ;

    $splitter1->setHTML1("This is LEFT HTML<br>" x 30) ;
    $splitter1->setHTML2("And this is right<br>" x 50) ;
    my $html = $splitter1->HTML ; 
    $my->{info}{BODY} = qq[<h1>START OF SPLITTER EXAMPLE 1</h1>$html<h1>END OF EXAMPLE</h1>] ;
}

