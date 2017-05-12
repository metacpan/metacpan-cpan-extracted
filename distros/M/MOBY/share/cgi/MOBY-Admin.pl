#!/usr/bin/perl -w
# _________________________________________________________________


use SOAP::Transport::HTTP;
use MOBY::Central;
my $x = new SOAP::Transport::HTTP::CGI;
$x->dispatch_to('/var/www/cgi-bin', 'MOBY::Admin');
$x->handle;

