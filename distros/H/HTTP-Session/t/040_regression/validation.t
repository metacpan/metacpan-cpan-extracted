use strict;
use warnings;
use HTTP::Session;
use Test::More tests => 1;

eval {
    HTTP::Session->new();
};
my $e = $@;
like $e, qr/missing parameter store/;
