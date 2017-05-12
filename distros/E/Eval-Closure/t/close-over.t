#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

use B;
use Eval::Closure;

use Test::Requires 'PadWalker';

{
    my $foo = [];
    my $env = { '$foo' => \$foo };

    my $code = eval_closure(
        source      => 'sub { push @$foo, @_ }',
        environment => $env,
    );
    is_deeply(scalar(PadWalker::closed_over($code)), $env,
              "closed over the right things");
}

{
    my $foo = {};
    my $bar = [];
    my $env = { '$foo' => \$bar, '$bar' => \$foo };

    my $code = eval_closure(
        source      => 'sub { push @$foo, @_; $bar->{foo} = \@_ }',
        environment => $env,
    );
    is_deeply(scalar(PadWalker::closed_over($code)), $env,
              "closed over the right things");
}

{
    # i feel dirty
    my $c = eval_closure(source => 'sub { }');
    my $b = B::svref_2object($c);
    my @scopes;
    while ($b->isa('B::CV')) {
        push @scopes, $b;
        $b = $b->OUTSIDE;
    }
    my @visible_in_outer_scope
        = grep { defined && length && $_ ne '&' }
          map  { $_->PV }
          grep { $_->can('PV') }
          map  { $_->PADLIST->ARRAYelt(0)->ARRAY }
          @scopes;

    # test to ensure we don't inadvertently screw up this test by rearranging
    # code. if the scope that encloses the eval ends up not declaring $e, then
    # change this test.
    ok(scalar(grep { $_ eq '$e' } @visible_in_outer_scope),
       "visible list is sane");

    for my $outer_scope_pad_entry (@visible_in_outer_scope) {
        like(
            exception {
                eval_closure(
                    source => "sub { $outer_scope_pad_entry }",
                );
            },
            qr/Global symbol "\Q$outer_scope_pad_entry/,
            "we don't close over $outer_scope_pad_entry"
        );
    }
}

done_testing;
