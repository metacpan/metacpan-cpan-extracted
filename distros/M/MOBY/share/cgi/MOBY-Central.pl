#!/usr/bin/perl -w
# _________________________________________________________________


use SOAP::Transport::HTTP;
use MOBY::Central;
use MOBY::SOAP::Serializer;

my $x = new SOAP::Transport::HTTP::CGI;
$x->serializer(MOBY::SOAP::Serializer->new);
$x->dispatch_to('/var/www/cgi-bin', 'MOBY::Central');
$x->handle;

