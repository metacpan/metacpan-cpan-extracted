#!/usr/bin/env perl
# Nothing in the shipped tree points at the private cai-platform suites (ADR 0003).
#
# (1) No "platform#NNN": cai-platform issue numbers, which a hosting platform links
#     to the issues of this repository. Always checked.
# (2) No suite id of the acceptance copy as a word. The ids are the directory names
#     under HOLMGANG_ACCEPTANCE_SUITES (one search directory, or several separated
#     by ':'), read at runtime, so the list itself never enters this repository;
#     skipped without it. A hit names only file and line, never the id.
#
# A few ids are also ordinary words or file names. Such a line is allowed by file
# and line pattern below, never by id: a new use of the same id elsewhere fails.
#
# An id that is also the device type of a built-in simulator (an answer world named
# like the suite it serves) is a public name of this distribution: format 2 states
# name it as their type and load unchanged (ADR 0004), so it is not scanned for (k58).
# Every other id is still scanned, and the test fails if none is left to scan.
use strict;
use warnings;
use Test::More;
use File::Find ();
use File::Spec;
use FindBin ();
use Langertha::Holmgang::Simulators ();

my $root = File::Spec->catdir( $FindBin::Bin, File::Spec->updir );

my @ALLOW = (
  # compose file names docker compose looks for
  [ qr{\Alib/Langertha/Holmgang/Sim/Linux/Docker\.pm\z}, qr{\bcompose\.ya?ml\b} ],
  # the v1 binary, asserted to be absent
  [ qr{\At/sim/docker\.t\z}, qr{compose ps'\), qr/command not found/} ],
);

my @files;
for my $top (qw( lib bin t share docs )) {
  my $dir = File::Spec->catdir( $root, $top );
  next unless -d $dir;
  File::Find::find( { no_chdir => 1, wanted => sub { push @files, $_ if -f $_ } }, $dir );
}
for my $f (qw( README.md Changes CONTEXT.md )) {
  my $p = File::Spec->catfile( $root, $f );
  push @files, $p if -f $p;
}
@files = sort @files;
ok( scalar @files, 'shipped files found' );

sub scan {
  my ( $re ) = @_;
  my @hits;
  for my $path ( @files ) {
    my $rel = File::Spec->abs2rel( $path, $root );
    $rel =~ s{\\}{/}g;
    open my $fh, '<:raw', $path or die "$rel: $!";
    while ( my $line = <$fh> ) {
      next unless $line =~ $re;
      next if grep { $rel =~ $_->[0] && $line =~ $_->[1] } @ALLOW;
      push @hits, "$rel:$.";
    }
    close $fh;
  }
  return @hits;
}

my @issue = scan( qr/platform\#\d/ );
ok( !@issue, 'no cai-platform issue number' ) or diag( join "\n", @issue );

SKIP: {
  my $roots = $ENV{HOLMGANG_ACCEPTANCE_SUITES};
  skip 'set HOLMGANG_ACCEPTANCE_SUITES to a copy of the cai-platform suites', 3 unless $roots;
  my %ids;
  for my $r ( grep { length } split /:/, $roots ) {
    opendir my $dh, $r or die "$r: $!";
    $ids{$_} = 1 for grep { !/\A\./ && -d File::Spec->catdir( $r, $_ ) } readdir $dh;
    closedir $dh;
  }
  ok( scalar keys %ids, 'suite ids read from the acceptance copy' );
  my @types = Langertha::Holmgang::Simulators->new->types;
  my @public = grep { $ids{$_} } @types;
  delete @ids{@public};
  note( scalar(@public).' id(s) are built-in device types, not scanned' );
  ok( scalar keys %ids, 'ids left to scan after the device types' );
  my $alt = join '|', map { quotemeta } sort { length $b <=> length $a } keys %ids;
  my @hits = %ids ? scan( qr/(?<![A-Za-z0-9_])(?:$alt)(?![A-Za-z0-9_])/ ) : ();
  ok( !@hits, 'no suite id of the acceptance copy' ) or diag( join "\n", @hits );
}

done_testing;
