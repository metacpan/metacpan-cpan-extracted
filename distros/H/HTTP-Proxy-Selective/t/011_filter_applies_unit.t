#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 5;

BEGIN { use_ok('HTTP::Proxy::Selective') or BAIL_OUT(); }

my $filter = ['/from/path', '/to/path'];

ok(HTTP::Proxy::Selective::_filter_applies(undef, $filter, '/from/path'));
ok(HTTP::Proxy::Selective::_filter_applies(undef, $filter, '/from/path/and/some/more'));
ok(!HTTP::Proxy::Selective::_filter_applies(undef, $filter, '/different/path'));
ok(!HTTP::Proxy::Selective::_filter_applies(undef, $filter, '/prefixed/from/path'));
