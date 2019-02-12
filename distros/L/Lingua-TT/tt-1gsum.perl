#!/usr/bin/perl -w

use Getopt::Long qw(:config no_ignore_case);
use strict;

my ($help);
GetOptions('h|help' => \$help);
if ($help) {
  print STDERR <<EOF;

Usage: $0 [LEXSORTED_1GRAM_FILE(s)...]

Description:
  Sums over lexically sorted 1g files (fast, low memory footprint)

EOF
  exit 0;
}


my ($pkey,$pf,$f,$key);
while (<>) {
  chomp;
  next if (/^\s*$/ || /^%%/);
  ($f,$key) = split(/\t/,$_,2);
  if (defined($pkey) && $pkey eq $key) {
    $pf += $f;
    next;
  }
  print $pf, "\t", $pkey, "\n" if (defined($pkey));
  ($pf,$pkey) = ($f,$key);
}
print $pf, "\t", $pkey, "\n" if (defined($pkey));

