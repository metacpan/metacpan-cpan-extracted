#! /usr/bin/perl -w

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


    my $mainPanelCSS2 = new JQuery::CSS(hash => {'#MySplitter2' => {'min-width' => '30px', 'min-height' => '30px', border => '4px solid #669'}}) ; 
    my $panel1CSS2 = new JQuery::CSS(hash => { '#TopPanel' => {background => 'blue', padding => '8px'}}) ; 
    my $panel2CSS2 = new JQuery::CSS(hash => { '#BottomPanel' => {background => 'yellow', padding => '4px'}}) ; 

    my $mainPanelCSS = new JQuery::CSS(hash => {'#MySplitter1' => {'min-width' => '500px', 'min-height' => '300px', border => '4px solid #669'}}) ; 
    my $panel1CSS = new JQuery::CSS(hash => { '#LeftPanel' => {background => 'blue', padding => '8px'}}) ; 
    my $panel2CSS = new JQuery::CSS(hash => { '#RightPanel' => {background => 'yellow', padding => '4px'}}) ; 
					       
    my $topHTML = "Top HTML" ; 
    my $bottomHTML = "Bottom HTML" ; 					       
    my $splitter2 = JQuery::Splitter->new(id => 'RightPanel', 
					  addToJQuery => $jquery,
					  internalPanel => 1,
					  type => 'h', accessKey => "I",  panel1 => 'TopPanel', panel2 => 'BottomPanel',
					  mainPanelCSS => $mainPanelCSS2,
					  panel1CSS => $panel1CSS2,
					  panel2CSS => $panel2CSS2,
					  panel1Params => {minA => 30, initA => 30, maxA => 1000},
					  panel2Params => {minB => 100},
					  HTML1 => $topHTML, HTML2 => $bottomHTML) ;
					       

					       
    my $htmlSplitter2 = $splitter2->HTML ; 

    my $splitter1 = JQuery::Splitter->new(id => 'MySplitter1', 
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
                                          splitRepeat => 0,
					  HTML1 => $leftHTML, HTML2 => $htmlSplitter2) ;

    $splitter1->setHTML1("This is LEFT HTML<br>" x 30) ;
    my $html = $splitter1->HTML ; 
    $my->{info}{BODY} = qq[$html] ;
}

