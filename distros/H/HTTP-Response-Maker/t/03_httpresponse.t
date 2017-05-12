use strict;
use warnings;
use Test::More tests => 3;
use Test::Requires 'HTTP::Response';

BEGIN {
    use_ok 'HTTP::Response::Maker::HTTPResponse';
}

my $gone = GONE;
isa_ok $gone,       'HTTP::Response';
is     $gone->code, 410;
