#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use TestBadges;

for my $name ( qw(
  README.md
  README.mkdn
  README.markdown
  narf.txt
) ){
  my $test = eval {
    build_dist({}, { name => $name });
  };
  my $e = $@;
  if ($name =~ /narf/) {
    like $e, qr/README file not found/, 'fail with message if file not found';
    next;
  }

  is $test->{readme}->basename, $name, "file named $name";

  my $content = $test->{readme}->slurp_raw;
  my $pattern = qr/\[!/;

  like $content, $pattern, "badges in $name";
}

done_testing;
