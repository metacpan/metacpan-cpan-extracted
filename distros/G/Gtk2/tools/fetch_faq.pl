#!/usr/bin/perl

use strict;
use warnings;
use LWP;

my $faq_url = 'http://gtk2-perl.sourceforge.net/faq/?op=pod';
my $podi_file = 'build/FAQ.pod';

my $ua = LWP::UserAgent->new;
$ua->agent ("Gtk2-Perl FAQ Fetcher");
$ua->env_proxy;

my $req = HTTP::Request->new (POST => $faq_url);
$req->content_type ('plain/text');
print "Requesting $faq_url...";
my $res = $ua->request ($req);
if ($res->is_success)
{
	open PODI,'>'.$podi_file 
		or die "unable to open ($podi_file) for output\n";
	print PODI $res->content;
	close PODI;
}
else
{
	die "request of ($faq_url) failed\n";
}
print "...Done\n";

1;
