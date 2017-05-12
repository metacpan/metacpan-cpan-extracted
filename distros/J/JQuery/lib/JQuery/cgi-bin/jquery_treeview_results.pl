#! /usr/bin/perl

use CGI ; 
my $q = new CGI ; 

my $params = $q->Vars ; 

my $env ;
for (sort keys %ENV) { 
    $env .= "$_ = $ENV{$_}<br />" ; 
} 

my $cgiInfo ; 
for (sort keys %$params) { 
    $cgiInfo .= "$_ = $params->{$_}<br />" ; 
} 

my $result=<<EOD;

<taconite> 
    <replaceContent select="#results"> 
        <pre> 
        $cgiInfo
        lorem ipsum dolor sit amet 
        consectetuer adipiscing elit 
        </pre> 
    </replaceContent> 
 
    <slideDown select="#example4" value="100" /> 

</taconite>

EOD
 


print $q->header(-type=>'text/xml');
print $result ; 

