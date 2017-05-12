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


    my $mainPanelCSS = new JQuery::CSS(hash => {'#MySplitter' => {'min-width' => '500px', 'min-height' => '300px', border => '4px solid #669'}}) ; 
    my $panel1CSS = new JQuery::CSS(hash => { '#LeftPanel' => {background => 'blue', padding => '8px'}}) ; 
    my $panel2CSS = new JQuery::CSS(hash => { '#RightPanel' => {background => 'yellow', padding => '4px'}}) ; 
    my $splitter1 = JQuery::Splitter->new(id => 'MySplitter', 
					  addToJQuery => $jquery,
					  browserFill => 1,
					  type => 'v', accessKey => "I",  panel1 => 'LeftPanel', panel2 => 'RightPanel',
					  mainPanelCSS => $mainPanelCSS,
					  panel1CSS => $panel1CSS,
					  panel2CSS => $panel2CSS,
					  panel1Params => {minA => 100, initA => 100, maxA => 1000},
                                          splitBackGround => 'pink',
                                          splitActive => 'red',
                                          splitHeight => '6px',
                                          splitRepeat => 1,
					  HTML1 => $leftHTML, HTML2 => $rightHTML) ;

    $splitter1->setHTML1("This is LEFT HTML<br>" x 30) ;
    $splitter1->setHTML2("And this is right<br>" x 50) ;
    my $html = $splitter1->HTML ; 
    $my->{info}{BODY} = qq[<h1>START OF SPLITTER EXAMPLE 1</h1>$html<h1>END OF EXAMPLE</h1>] ;
}

