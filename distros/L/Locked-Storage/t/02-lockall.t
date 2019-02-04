#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use Locked::Storage;
    my $ls = Locked::Storage->new(1);
    ok( !$ls->lockall() );
    ok( !$ls->unlockall() );
}
