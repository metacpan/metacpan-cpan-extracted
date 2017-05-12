#!/usr/bin/env perl

=pod

This test is purely because I tried 1.00 with Try::Tiny for a
blog post and it doesn't work.  It remains to ensure compatibility

=cut

use strict;
use warnings;

use Test::More;
BEGIN {
  unless (require Try::Tiny) {
      Test::More::plan(
          skip_all => "Try::Tiny required for complaining compliance"
      );
      exit;
  }
}

use Try::Tiny;

Test::More::plan tests => 2;
use Mac::Safari::JavaScript qw(safari_js);

eval {
  safari_js("throw 'Bang'");
};
ok("$@" eq "Bang", "banged okay with eval")
  or diag($@);

my $success = 0;
try {
  safari_js("throw 'Bang'");
} catch {
  $success = $_ eq "Bang";
};
ok($success,"banged okay with Try::Tiny");


