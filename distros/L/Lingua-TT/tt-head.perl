#!/usr/bin/perl -w

if (!@ARGV || grep {/^\-h/} @ARGV) {
  print STDERR "Usage: $0 NTOKENS [TT_FILE(s)...]\n";
  exit 1;
}
my $maxtok = shift;

my $ntok = 0;
while (<>) {
  if ($ntok < $maxtok) {
    ++$ntok unless (/^$/ || /^%%/);
    print;
  }
}
