#!/usr/bin/perl -w 
#  # A cgi program that do "Mail this page to a friend";
#  # Call this script like this :
#  # script.cgi?email=myfriend@isp.com&url=http://www.go.com
use strict;
use CGI qw/:standard/;
use CGI::Carp qw/fatalsToBrowser/;
use MIME::Lite::HTML;

my $mailHTML = new MIME::Lite::HTML
  From     => 'MIME-Lite@alianwebserver.com',
  To       => param('email'),
  Subject  => 'Your url: '.param('url'), 
  Debug    => 1;


my $MIMEmail = $mailHTML->parse(param('url'));
$MIMEmail->send; # or for win user : $mail->send_by_smtp('smtp.fai.com');
print header,"Mail envoye (", param('url'), " to ", param('email'),")<br>\n";
