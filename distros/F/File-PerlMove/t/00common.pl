#! perl

use strict;

our $sz;
our $tf;

my @unlinks;

sub create_testfile {
    my $tf = shift;
    open(my $f, ">", $tf);
    print { $f } ( localtime(time)."\n");
    close($f);
    my $sz = -s $tf;
    ok($sz, "Test file creation");
    @unlinks = ( $tf );
    $sz;
}

sub verify {
    my $tf = shift;
    my $tag = shift;
    push(@unlinks, $tf);
    is(-s $tf, $sz, "$tag check [$tf]");
    $tf;
}

sub cleanup {
    unlink(@unlinks);
}

1;
