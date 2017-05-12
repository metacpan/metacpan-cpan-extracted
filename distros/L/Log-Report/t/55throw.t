#!/usr/bin/env perl
# Test throw()

use warnings;
use strict;

use Test::More tests => 9;

use Log::Report undef, syntax => 'SHORT';

eval
{  use POSIX ':locale_h', 'setlocale';  # avoid user's environment
   setlocale(LC_ALL, 'POSIX');
};

# start a new logger
my $text = '';
open my($fh), '>', \$text;

dispatcher close => 'default';
dispatcher FILE => 'out', to => $fh, accept => 'ALL', format => sub {shift};

cmp_ok(length $text, '==', 0, 'file logger');

try { error "test" };
ok($@, 'caugth rethrown error');

my $e1 = $@->wasFatal;
isa_ok($e1, 'Log::Report::Exception');
is($e1->reason, 'ERROR');

my $m1 = $e1->message;
isa_ok($m1, 'Log::Report::Message');

is("$m1", 'test');

# Now, rethrow the exception
try { $e1->throw(reason => 'ALERT') };
ok(!$@, 'caught rethrown, non fatal');

my @e2 = $@->exceptions;
cmp_ok(scalar @e2, '==', 1);
my $e2 = $e2[0];

is("$e2", "alert: test\n");
