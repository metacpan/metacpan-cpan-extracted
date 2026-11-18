#!/usr/bin/env perl
# Windows: the DLLs a packed binary links that lib-gate.pl would flag as foreign,
# looked up in the given directories only (the packing perl's own), for pp -l.
#   win-dlls.pl <binary> <dir>...
# Prints one <dir>/<file> per line, nothing when nothing is missing. A found DLL's
# own imports are resolved the same way. A name in none of the directories is
# named on STDERR and left out: lib-gate.pl then fails it.
package DzilBinary::WinDlls;
use strict;
use warnings;
use File::Basename ();
use File::Spec ();

# the same judgement as the gate: its inspection, allowlist and foreign()
require(File::Spec->catfile(File::Basename::dirname(File::Spec->rel2abs(__FILE__)), 'lib-gate.pl'))
  unless defined &DzilBinary::LibGate::inspect_binary;

# lc file name => <dir>/<file as spelled on disk>, the first directory holding it
# winning (objdump's names are lower-cased by linked()).
sub index_dirs {
  my (@dirs) = @_;
  my %at;
  for my $d (@dirs) {
    opendir my $dh, $d or do { print STDERR "win-dlls: cannot read $d: $!\n"; next };
    for my $f (sort readdir $dh) {
      my $p = "$d/$f";
      $at{lc $f} //= $p if -f $p;
    }
    closedir $dh;
  }
  return \%at;
}

# Until nothing new is flagged: every name foreign() flags for %$links/@$packed
# is looked up in %$at; a found DLL counts as packed and its own imports join
# %links. Returns ([paths found], [names found nowhere]), both sorted.
sub resolve {
  my ($links, $packed, $at) = @_;
  my %links = %$links;
  my @packed = @$packed;
  my (%tried, %found, @missing);
  while (my @new = grep { !$tried{lc $_}++ }
      DzilBinary::LibGate::foreign(\%links, [DzilBinary::LibGate::allowlist('windows', \%links)], \@packed)) {
    for my $name (@new) {
      my $path = $at->{lc $name};
      if (!defined $path) { push @missing, $name; next }
      $found{$path} = 1;
      push @packed, File::Basename::basename($path);
      $links{$path} = DzilBinary::LibGate::linked('windows', $path);
    }
  }
  return ([sort keys %found], [sort @missing]);
}

sub run {
  my ($archive, @dirs) = @_;
  local $| = 1;
  my $seen = DzilBinary::LibGate::inspect_binary($archive, 'windows', sub { });
  my ($found, $missing) = resolve($seen->{links}, $seen->{packed}, index_dirs(@dirs));
  print STDERR "win-dlls: in none of ", join(', ', @dirs), ": @$missing (lib-gate.pl fails them)\n" if @$missing;
  print "$_\n" for @$found;
  return 0;
}

sub main {
  my ($archive, @dirs) = @_;
  die "usage: win-dlls.pl <binary> <dir>...\n" unless @dirs;
  my $rc = eval { run($archive, @dirs) };
  if ($@) { print STDERR $@; return 2 }
  return $rc;
}

exit main(@ARGV) unless caller;
1;
