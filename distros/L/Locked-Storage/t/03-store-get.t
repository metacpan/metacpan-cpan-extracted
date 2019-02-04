#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use Locked::Storage;
    my $ls = Locked::Storage->new(1);
    my $t = "Hello World!";
    ok( $ls->store($t, length($t)) );
    my $rs = $ls->get();
    ok( $rs eq $t );
}
