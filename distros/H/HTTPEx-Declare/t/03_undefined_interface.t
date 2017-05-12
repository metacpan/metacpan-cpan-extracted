use strict;
use warnings;
use lib '.';
use HTTPEx::Declare;
use Test::More tests => 1;

eval {
    my $response = run {} => HTTP::Request->new( GET => 'http://localhost/' );
};
like $@, qr/please define interface previously/;
