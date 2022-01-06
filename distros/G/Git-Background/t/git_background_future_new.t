#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use Git::Background::Future;

note('new()');
{
    my $obj = Git::Background::Future->new;
    isa_ok( $obj, 'Git::Background::Future', 'new returned object' );

    # This is wrong usage, but new() doesn't catch that. This test is only
    # to ensure this behavior doesn't change.
    ok( exists $obj->{_run},   '_run exists' );
    ok( !defined $obj->{_run}, '... but is not defined' );
}

note('new()');
{
    my $obj = Git::Background::Future->new('hello world');
    isa_ok( $obj, 'Git::Background::Future', 'new returned object' );

    is( $obj->{_run}, 'hello world', '_run is set' );
}

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
