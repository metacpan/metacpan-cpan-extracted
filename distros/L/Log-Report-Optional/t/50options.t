#!/usr/bin/env perl
# Test loading of "Minimal" via "Optional"

use Test::More tests => 5;

BEGIN { use_ok('Log::Report::Optional','log-report') }

my $x = __"test";
is($x, 'test',  '__ returns same');
is(ref $x, '',  'not Log::Report::Message');

my @using = Log::Report::Optional->usedBy;
cmp_ok(scalar @using, '==', 1, 'usedBy');
is($using[0], __PACKAGE__);
