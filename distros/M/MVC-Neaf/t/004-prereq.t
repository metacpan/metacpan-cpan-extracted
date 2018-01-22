#!perl -T

use strict;
use warnings;
use Test::More tests => 1;

my @missing = grep { !eval "require $_;" } qw(
    Template
    Digest::MD5
    Digest::SHA
    Getopt::Long
    MIME::Base64
    Sys::Hostname
    Time::HiRes
);

ok !@missing, "Crucial modules loaded (@missing)" or print "Bail out!\n";


