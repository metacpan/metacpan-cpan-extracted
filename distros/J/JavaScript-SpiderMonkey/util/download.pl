#!/usr/bin/perl
############################################################
# Automatically download and install the SpiderMonkey lib
############################################################

use strict;
use warnings;

my $JS_DIR_URL = "ftp://sunsite.rediris.es/pub/mozilla.org/js/";

use URI::URL;
use Net::FTP;
use File::Listing;

my $url = URI::URL->new($JS_DIR_URL);
my $ftp = Net::FTP->new($url->host());
die "Cannot connect: ", $ftp->message unless $ftp;
$ftp->login("anonymous",'-anonymous@') or
    die "Cannot login: ", $ftp->message;
$ftp->cwd($url->path) or 
    die "Cannot change working directory: ", $ftp->message;
my $candidate;
foreach(File::Listing::parse_dir($ftp->dir())) {
    my ($name) = @$_;
    $candidate = $name if $name =~ /^js-1.*tar.gz$/;
}
$ftp->binary();
print "Downloading $candidate\n";
$ftp->get($candidate);
$ftp->quit;
