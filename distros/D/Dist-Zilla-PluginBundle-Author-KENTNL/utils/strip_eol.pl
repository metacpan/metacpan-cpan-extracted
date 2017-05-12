#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Path::Iterator::Rule;
use Path::FindDev qw( find_dev );
use Path::Tiny qw( path );

my $rule = Path::Iterator::Rule->new();

$rule->skip_vcs;
$rule->skip(
  sub {
    return if not -d $_;
    if ( $_[1] =~ qr/^\.build$/ ) {
      *STDERR->print("\e[34mIgnoring \e[33m$_\e[34m ( .build )\e[0m\n");
      return 1;
    }
    if ( $_[1] =~ qr/^[A-Z].*-[0-9.]+(-TRIAL)?$/ ) {
      *STDERR->print("\e[34mIgnoring \e[33m$_\e[34m ( dzil build tree )\e[0m\n");
      return 1;
    }
    return;
  }
);
$rule->file->nonempty;
$rule->file->not_binary;
$rule->file->line_match(qr/\s\n/);

my $start = find_dev('./');

*STDERR->print("searching in $start\n");

my $next = $rule->iter(
  $start => {
    follow_symlinks => 0,
    sorted          => 0,
  }
);

while ( my $file = $next->() ) {
  *STDERR->print("\e[31m$file\e[0m matched.");
  my $path = path($file);
  if ( $ARGV[0] and $ARGV[0] eq '--apply' ) {
    *STDERR->print("\e[32m Applied!");
    system 'sed', '-i', 's/\s*$//', "$path";
  }
  else {
    my (@lines) = $path->lines( { chomp => 1 } );
    print "\n";
    for my $line (@lines) {
      next unless $line =~ /\s$/;
      my ( $before, $eol ) = $line =~ /^(.*?)(\s+)$/;
      print "\e[37m";
      print $before;
      print "\e[0m\e[41m";
      print $eol;
      print "\e[0m";
      print "\n";
    }
  }
  *STDERR->print("\e[0m\n");
}
