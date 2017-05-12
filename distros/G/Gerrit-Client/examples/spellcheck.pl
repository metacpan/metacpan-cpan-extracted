#!/usr/bin/env perl
use strict;
use warnings;

use AnyEvent;
use English qw(-no_match_vars);
use Gerrit::Client qw(for_each_patchset);
use Getopt::Long;
use Lingua::EN::CommonMistakes qw(%MISTAKES);

my $workdir = "$ENV{ HOME }/gerrit-spell-check-bot";

sub check_patch {
  my $log = qx(git --no-pager log -n1 --format=format:%B HEAD);
  my @errors;
  foreach my $word (map { lc $_ } split /\b/, $log) {
    if (my $correction = $MISTAKES{$word}) {
      push @errors, "$word -> $correction";
    }
  }
  return unless @errors;

  local $LIST_SEPARATOR = "\n  ";
  print "Likely spelling error(s):$LIST_SEPARATOR@errors\n";
  return -1;
}

sub run {
  $|++;

  my $url;
  GetOptions( 'url=s' => \$url ) || die;
  $url || die 'missing mandatory --url argument';

  my $stream = for_each_patchset(
    url => $url,
    on_patchset => \&check_patch,
    workdir => $workdir,
    review => 1,
  );
  AE::cv()->recv();
}

run() unless caller;
1;
