#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Path::Tiny qw( path );
use List::MoreUtils qw( first_index );
my ($URI) = @ARGV;

die "clone.pl git@.... " unless @ARGV == 1;

sub ssystem(@) {
  my (@args) = @_;
  my $code = system(@args);
  if ( $code != 0 ) {
    warn "\e[31mFAILED: $code/$?, @args\e[0m";
  }
  return $code == 0;
}
my $target;
if ( $URI =~ qr{[/]([^/]+).git$} ) {
  print "Checkout is $1";
  $target = "$1";
}
else {
  die "Cant determine target";
}

ssystem( 'git', 'clone', $URI ) or die "clone failed, STAHP";
chdir path('.')->child($1)->stringify;
ssystem( 'git', 'checkout', '-b', 'releases',     'origin/releases' );
ssystem( 'git', 'checkout', '-b', 'build/master', 'origin/build/master' );
ssystem( 'git', 'checkout', 'master' );
my $config = path('./.git/config');
my (@lines) = $config->lines_utf8;

if ( my $idx = first_index { $_ =~ /url\s*=\s*git\@github.com:kentfredric/ } @lines ) {
  splice @lines, $idx + 1, 0, ( "\tpush = +refs/heads/*:refs/heads/*\n", "\tpush = +refs/tags/*:refs/tags/*\n", );
}
$config->spew_utf8( \@lines );

