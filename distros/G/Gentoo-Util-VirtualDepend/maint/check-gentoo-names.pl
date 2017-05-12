#!/usr/bin/env perl
# FILENAME: check-gentoo-names.pl
# CREATED: 10/11/14 06:19:18 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Check gentoo side of map

use strict;
use warnings;
use utf8;

use Path::Tiny;
use Capture::Tiny qw( capture );
use FindBin;

my $cnf = path($FindBin::Bin)->sibling('share')->child('dist-to-gentoo.csv');
my $fh  = $cnf->openr_raw;

while ( my $line = <$fh> ) {
  chomp $line;
  my (@fields) = split /,/, $line;
  my ( $out, $err, $exit ) = capture {
    system( 'eix', '--in-overlay', 'gentoo', '-c', '-e', $fields[1] )
  };
  if ( $exit != 0 and $exit != 1 and $exit != 256 ) {
    die "Halt: $err $exit";
  }
  next if $exit == 0;
  print $fields[1] . qq[ is missing\n];
}
