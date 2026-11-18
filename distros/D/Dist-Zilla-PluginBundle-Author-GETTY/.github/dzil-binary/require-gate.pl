#!/usr/bin/env perl
# Every module the dist declares in `require` must be inside the binary.
#   require-gate.pl <binary> <Module|Glob::*>...
package DzilBinary::RequireGate;
use strict;
use warnings;
use Archive::Zip qw( AZ_OK );

sub missing {
  my ($archive, @specs) = @_;
  my $zip = Archive::Zip->new;
  die "cannot read $archive as an archive\n" unless $zip->read($archive) == AZ_OK;
  my @names = $zip->memberNames;
  my %have = map { $_ => 1 } @names;
  my @missing;
  for my $spec (@specs) {
    if ($spec =~ /\A(.+)::\*\z/) {
      (my $prefix = "lib/$1/") =~ s{::}{/}g;
      push @missing, "$prefix*" unless grep { /\A\Q$prefix\E.+\.pm\z/ } @names;
    }
    else {
      (my $path = "lib/$spec.pm") =~ s{::}{/}g;
      push @missing, $path unless $have{$path};
    }
  }
  return @missing;
}

sub main {
  my ($archive, @specs) = @_;
  die "usage: require-gate.pl <binary> <module|Glob::*>...\n" unless defined $archive;
  my @m = eval { missing($archive, @specs) };
  if ($@) { print STDERR $@; return 2 }
  return 0 unless @m;
  print STDERR "required but missing from $archive:\n", map({ "  $_\n" } @m);
  return 1;
}

exit main(@ARGV) unless caller;
1;
