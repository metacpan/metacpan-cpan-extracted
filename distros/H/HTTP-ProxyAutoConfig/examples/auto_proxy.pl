#!/bin/sh
#-*-Perl-*-

exec perl -x $0 "$@"

#!perl

use lib ".";
use HTTP::ProxyAutoConfig;

my $pac = new HTTP::ProxyAutoConfig();

print $pac->FindProxy("https://www.yahoo.com"),"\n";
print $pac->FindProxy("ftp://ftp.redhat.com"),"\n";
print $pac->FindProxy("www.yahoo.com"),"\n";
