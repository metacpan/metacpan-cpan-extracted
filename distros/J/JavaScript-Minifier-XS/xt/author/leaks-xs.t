#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use JavaScript::Minifier::XS qw(minify);

BEGIN {
  eval "use Linux::Smaps";
  plan skip_all => "Linux::Smaps required for XS leak testing" if $@;
}
use Linux::Smaps;

###############################################################################
my $ITERS_WARMUP  = 2_000;
my $ITERS_TESTING = 50_000;

###############################################################################
# A small snippet exercising several token types: identifiers, whitespace,
# sigils, a literal, and a comment.  Each becomes a node whose content could
# leak.
my $js = <<'END_JS';
var foo = 1;   // a comment
function bar() {
    return foo + "baz";
}
END_JS

###############################################################################
# Sanity check: minify actually does something.
ok minify($js), 'minify() returned minified JS';

###############################################################################
# Warm things up.  Runs a handful of iterations so that our memory allocator
# can reach a steady state.
minify($js) for (1 .. $ITERS_WARMUP);

###############################################################################
# Measure RSS growth over repeated calls to the minifier.  If the XS code is
# leaking any memory, our RSS should grow.
my $smaps = Linux::Smaps->new;

my $rss_before = $smaps->update->rss;
minify($js) for (1 .. $ITERS_TESTING);
my $rss_after = $smaps->update->rss;

my $rss_growth = $rss_after - $rss_before;
note sprintf(
  "RSS before: %d KB, after: %d KB, growth: %d KB over %d calls (%.3f KB/call)",
  $rss_before,
  $rss_after,
  $rss_growth,
  $ITERS_TESTING,
  $rss_growth / $ITERS_TESTING,
);

###############################################################################
# Allow for some memory allocator noise and fragmentation.
#
# If total growth exceeds this threshold, odds are high that we're leaking.
my $THRESHOLD_KB = 4_000;
cmp_ok $rss_growth, '<', $THRESHOLD_KB,
  "minify() does not leak memory (RSS growth $rss_growth KB < $THRESHOLD_KB KB)";

###############################################################################
done_testing();
