#!/usr/bin/perl

use Devel::Walk;

    my $foo = { biff=>1};
    $foo->{foo} = $foo;
    walk( $foo, sub { print "$_[0]\n"; 1 }, '$foo' );
