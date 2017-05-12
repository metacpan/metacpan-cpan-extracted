#!perl

use strict;
use warnings;
use Test::More;
# pulled in by HTTP::Thin
use HTTP::Tiny;
use File::Spec;

plan tests => 1;

my $xsd = File::Spec->catfile(qw/t ebay.xsd/);
my $url = 'http://developer.ebay.com/webservices/901/ebaySvc.xsd';

unless (-f $xsd) {
    my $res = HTTP::Tiny->new->mirror($url, $xsd);
    die unless $res->{success};
}
ok (-f $xsd, "$xsd found");

