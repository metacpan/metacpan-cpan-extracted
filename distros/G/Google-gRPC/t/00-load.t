use strict;
use warnings;
use Test::More;

BEGIN {
    plan tests => 1;
    use_ok('Google::gRPC::Client') || print "Bail out!\n";
}

note("Testing Google::gRPC::Client $Google::gRPC::Client::VERSION, Perl $], $^X");
