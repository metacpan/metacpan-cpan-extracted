#!/usr/bin/env perl
use strict;
use warnings; no warnings 'void';

use lib 'lib';
use lib 't/lib';
use Devel::Chitin::TestRunner;
use Test::More;

run_test(
    6,
    sub {
        my $a;
        $DB::single=1; 14;
        15;
        16;
        $a = 2;
        18;
        $a = 2;
        20;
        21;
        $a = 3;
        23;
        24;
    },
    \&set_watch_expr,
    'continue',
    loc(line => 18),
    'continue',
    loc(line => 23),
    'done'
);

sub set_watch_expr {
    my($db, $loc) = @_;

    ok($db->add_watchexpr('$a'), 'Add watchpoint');
}

my @expected_watchexpr_notifications;
BEGIN {
    @expected_watchexpr_notifications = (
        { line => 17, expr => '$a', old => [ undef ], new => [ 2 ] },
        { line => 22, expr => '$a', old => [ 2 ], new => [ 3 ] },
        # $a goes out of scope when the subref ends
        { line => 24, expr => '$a', old => [ 3 ], new => [ undef ] },
    );
}

sub Devel::Chitin::TestRunner::notify_watch_expr {
    my($self, $location, $expr, $old, $new) = @_;
    $self->Devel::Chitin::step;

    my $expected = shift @expected_watchexpr_notifications;

    if (!$expected) {
        ok(0, 'Got unexpected notify_watch_expr at '.$location->filename.':'.$location->line);
    }

    subtest 'watchexpr for line '.$expected->{line} => sub {
        is($location->line, $expected->{line}, 'line')
            || diag('Was stopped at '.$location->filename.':'.$location->line);
        is($expr, '$a', 'expr');
        is_deeply($old, $expected->{old}, 'old value')
            || diag('Value is [',join(', ', map { defined($_) ? $_ : '<undef>' } @$old),']');
        is_deeply($new, $expected->{new}, 'new value')
            || diag('Value is [',join(', ', map { defined($_) ? $_ : '<undef>' } @$new),']');
    };
}
