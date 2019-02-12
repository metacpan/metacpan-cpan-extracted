#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 4;

BEGIN {
    use Locked::Storage;
    my $ls = Locked::Storage->new();
    ok( $ls, "Load uninitialised" );
    my $ps = $ls->pagesize();
    my $b = $ls->set_pages(1);
    ok( $ps eq $b, "Allocate one page" );
    my $i = $ls->initialize();
    ok( $b eq $i, "Initialize a page" );
    $ls = undef;
    $ls = Locked::Storage->new(1);
    ok( $ls, "Load initialised" );
    $ls = undef;
}
