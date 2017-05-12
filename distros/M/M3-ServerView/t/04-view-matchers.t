#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 14;

use M3::ServerView::View;

# Empty
my @matchers = M3::ServerView::View::_build_matchers();
is(scalar @matchers, 0);

# Empty
@matchers = M3::ServerView::View::_build_matchers({});
is(scalar @matchers, 0);

# Key must match
@matchers = M3::ServerView::View::_build_matchers({
    foo => 1,
});
is(scalar @matchers, 1);
ok($matchers[0]->({ foo => 1}));
ok($matchers[0]->({ foo => 1}));
ok(!$matchers[0]->({ foo => 2}));
ok(!$matchers[0]->({ bar => 1}));

@matchers = M3::ServerView::View::_build_matchers({
    foo => "bar",
});
is(scalar @matchers, 1);
ok($matchers[0]->({ foo => "bar"}));
ok(!$matchers[0]->({ foo => "baz"}));

@matchers = M3::ServerView::View::_build_matchers({
    foo => [ "<" => "42" ],
});
is(scalar @matchers, 1);
ok($matchers[0]->({foo => 40}));
ok(!$matchers[0]->({foo => 42}));
ok(!$matchers[0]->({foo => 43}));
