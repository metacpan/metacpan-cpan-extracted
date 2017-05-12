#! /usr/bin/perl -w

use strict ; 

use JQuery::Demo ;

package main ;
my $tester =  new JQuery::Demo ; 
$tester->run ; 

package JQuery::Demo ;
use JQuery::Heartbeat ; 

sub start {
    my $my = shift ;
    $my->{info}{TITLE} = "Heartbeat Example" ;

    my $jquery = $my->{jquery} ; 
    JQuery::Heartbeat->new(remoteProgram => '/cgi-bin/jquery_heartbeat.pl', rm => 'reply', addToJQuery => $jquery, delay => 1000) ; 
#    JQuery::Heartbeat->new(remoteProgram => '/cgi-bin/jquery_heartbeat_results.pl', rm => 'reply', addToJQuery => $jquery, delay => 1000) ; 

    my $html =<<EOD; 
                <h1>Heartbeat Demo</h1>
                <div id="updateText">Start text here</div>   

EOD
    
    $my->{info}{BODY} =  "<h1>START OF HEARTBEAT EXAMPLE</h1>$html<h1>END OF EXAMPLE</h1>" ;
}

sub reply { 
    my $my = shift ;
    my $date = `date` ; 
    my $result=<<EOD;
    <taconite>
    <replaceContent select="#updateText">
	$date
    </replaceContent>	
   </taconite>
EOD
    my $q = new CGI ; 
    print $q->header(-type=>'text/xml');
    print $result ; 
    exit(0) ; 
}
