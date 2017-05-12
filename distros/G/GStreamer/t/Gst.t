#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 13;

# $Id$

use_ok("GStreamer", qw(
  GST_SECOND
  GST_MSECOND
  GST_USECOND
  GST_NSECOND
  GST_TIME_FORMAT
  GST_TIME_ARGS
  GST_RANK_NONE
  GST_RANK_MARGINAL
  GST_RANK_SECONDARY
  GST_RANK_PRIMARY
));

my $number = qr/^\d+$/;

my ($x, $y, $z) = GStreamer -> GET_VERSION_INFO();
like($x, $number);
like($y, $number);
like($z, $number);

my ($a, $b, $c, $d) = GStreamer -> version();
like($a, $number);
like($b, $number);
like($c, $number);
like($d, $number);

diag 'Testing GStreamer ', $GStreamer::VERSION;
diag '  Compiled against libgstreamer ', join '.', GStreamer -> GET_VERSION_INFO();
diag '   Running against libgstreamer ', join '.', GStreamer -> version();

ok(defined GStreamer -> version_string());

ok(GStreamer -> CHECK_VERSION(0, 0, 0));
ok(!GStreamer -> CHECK_VERSION(100, 100, 100));

ok(GStreamer -> init_check());
GStreamer -> init();

# --------------------------------------------------------------------------- #

my $element = GStreamer::parse_launch(qq(filesrc location="$0" ! filesink location="$0.bak"));
isa_ok($element, "GStreamer::Element");

# Commented since they're too loud.
# eval { $element = GStreamer::parse_launch(qq(!!)); };
# isa_ok($@, "GStreamer::ParseError");
# is($@ -> { domain }, "gst_parse_error");
# is($@ -> { value }, "syntax");

# --------------------------------------------------------------------------- #

GStreamer -> deinit();
