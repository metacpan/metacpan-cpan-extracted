#! /usr/bin/perl

use CGI ; 
my $q = new CGI ; 

my $env ;
for (sort keys %ENV) { 
    $env .= "$_ = $ENV{$_}<br />" ; 
} 
my $params = $q->Vars ; 

my $cgiInfo ; 
for (sort keys %$params) { 
    $cgiInfo .= "!!$_!! = !!$params->{$_}!!<br />" ; 
} 

print $q->header(-type=>'text/html');
 

if ($q->param('tab') eq 'tab 1') { 
    print "THIS IS TAB 1" ; 
    exit ; 
} 
if ($q->param('tab') eq 'tab 2') { 
    print "<h1>This is tab 2</h1>" ; 
    exit ; 
} 
if ($q->param('tab') eq 'tab 3') { 
    print "This is tab 3" ; 
    exit ; 
} 

print $cgiInfo ;
