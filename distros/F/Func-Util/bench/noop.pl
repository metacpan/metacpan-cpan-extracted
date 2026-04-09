#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Func::Util qw(noop);

print "=" x 60, "\n";
print "noop - No-Operation Benchmark\n";
print "=" x 60, "\n\n";

# Pure Perl noop
sub pure_noop { undef }

print "=== Call noop ===\n";
cmpthese(-2, {
    'util::noop'  => sub { noop() },
    'pure_noop'   => sub { pure_noop() },
    'sub_undef'   => sub { sub { undef }->() },
});

print "\n=== Call with arguments (ignored) ===\n";
cmpthese(-2, {
    'util::noop'  => sub { noop(1, 2, 3) },
    'pure_noop'   => sub { pure_noop(1, 2, 3) },
});

print "\nDONE\n";
