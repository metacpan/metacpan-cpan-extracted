#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Eval::Closure;

{
    my $code = eval_closure(
        source => 'no strict "refs"; sub { keys %{__PACKAGE__ . "::"} }',
    );

    # defining the sub { } creates __ANON__, calling 'no strict' creates BEGIN
    my @stash_keys = grep { $_ ne '__ANON__' && $_ ne 'BEGIN' } $code->();

    is_deeply([@stash_keys], [], "compiled in an empty package");
}

{
    # the more common case where you'd run into this is imported subs
    # for instance, Bread::Board::as vs Moose::Util::TypeConstraints::as
    my $c1 = eval_closure(
        source => 'no strict "vars"; sub { ++$foo }',
    );
    my $c2 = eval_closure(
        source => 'no strict "vars"; sub { --$foo }',
    );
    is($c1->(), 1);
    is($c1->(), 2);
    is($c2->(), -1);
    is($c2->(), -2);
}

{
    my $source = 'no strict "vars"; sub { ++$foo }';
    my $c1 = eval_closure(source => $source);
    my $c2 = eval_closure(source => $source);
    is($c1->(), 1);
    is($c1->(), 2);
    is($c2->(), 1);
    is($c2->(), 2);
}

done_testing;
