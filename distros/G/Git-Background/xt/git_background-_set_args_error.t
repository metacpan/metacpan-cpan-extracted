#!perl

use 5.006;
use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;

use Git::Background;

{
    my $target = {};
    my $args   = { invalid_arg => 1 };
    like( exception { Git::Background::_set_args( $target, $args ); }, qr{\A\QUnknown argument: 'invalid_arg' \E}, 'throws an exception on an invalid argument' );
}

{
    my $target = {};
    my $args   = { invalid_arg => 1, another_arg => 1 };
    like( exception { Git::Background::_set_args( $target, $args ); }, qr{\A\QUnknown arguments: 'another_arg', 'invalid_arg' \E}, '... or multiple' );
}

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
