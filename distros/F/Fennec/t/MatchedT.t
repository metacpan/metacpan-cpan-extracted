#!/usr/bin/perl
use strict;
use warnings;

use lib 't/lib';
BEGIN {
    return unless $^O =~ m/MSWin32/i;
    require Test::More;
    Test::More->import(
        skip_all => "feature broken on win32, but also deprecated so we do not care."
    );
    exit(0);
}
use Fennec::Runner qw/FinderTest/;
use Test::More;

my $found = grep { m/FinderTest/ } @{Fennec::Runner->new->test_classes};
ok( $found, "Found test!" );

run(
    sub {
        my $runner = Fennec::Runner->new();
        my $want   = 3;
        my $got    = $runner->collector->test_count;
        return if $runner->collector->ok( $got == $want, "Got expected test count" );
        $runner->collector->diag("Got:  $got\nWant: $want");
    }
);

1;
