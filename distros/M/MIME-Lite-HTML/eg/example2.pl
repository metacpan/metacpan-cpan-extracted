#!/usr/bin/perl

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use strict;
use MIME::Lite;
use MIME::Lite::HTML;

my $cgi = new CGI;

print $cgi->header;

open(FILE, "titlebar.gif");
binmode FILE;
my @data = <FILE>;
close(FILE);
my %hash;
$hash{"http://localhost/testing/titlebar.gif"} = \@data;
$hash{'test'} = "test";

  my $msg = new MIME::Lite::HTML (
       From     => 'MIME-Lite@alianwebserver.com',
     To       => 'alian@jupiter',
     Debug => 1,
     HashTemplate => \%hash,
     Subject => 'Mail in HTML with images',
);

     my $html = qq~<b>This is a <? \$test ?></b>:<p><img src="http://localhost/testing/titlebar.gif"><br>Hoi!   ~;
     #$html = "http://jupiter";
     my   $txt = qq~     Testing!!     ~;

my $MMail = $msg->parse($html, $txt);
#$MMail->send;
#$MMail->send_by_smtp('jupiter');
#exit;
open(EMAIL, ">email.eml");
print EMAIL $MMail->as_string;
close(EMAIL);

print "Done!";
print join "<br>", $msg->errstr;