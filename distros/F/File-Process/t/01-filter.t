#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 6;
use ReadonlyX;
use Data::Dumper;

Readonly my $TRUE => 1;

use_ok('File::Process');

my $fh    = *DATA;
my $start = tell $fh;

my $lines;
my %args;

( $lines, %args ) = process_file(
  $fh,
  chomp            => $TRUE,
  keep_open        => $TRUE,
  skip_blank_lines => $TRUE,
);

ok( @{$lines} == 5, 'skip blanks' )
  or diag( Dumper [$lines] );

seek $fh, $start, 0;

( $lines, %args ) = process_file(
  $fh,
  chomp         => $TRUE,
  keep_open     => $TRUE,
  skip_comments => $TRUE,
);

ok( ( @{$lines} == 5 && !map { $_ =~ /^#/ ? $_ : () } @{$lines} ),
  'skip comments' )
  or diag( Dumper [$lines] );

seek $fh, $start, 0;

( $lines, %args ) = process_file(
  $fh,
  chomp     => $TRUE,
  keep_open => $TRUE,
  trim      => 'front',
);

ok( ( @{$lines} == 6 && !map { $_ =~ /^\s+/ ? $_ : () } @{$lines} ),
  'trim front' )
  or diag( Dumper [$lines] );

seek $fh, $start, 0;

( $lines, %args ) = process_file(
  $fh,
  chomp     => $TRUE,
  keep_open => $TRUE,
  trim      => 'back',
);

ok( ( @{$lines} == 6 && !map { $_ =~ /\s+$/ ? $_ : () } @{$lines} ),
  'trim back' )
  or diag( Dumper [$lines] );

seek $fh, $start, 0;

( $lines, %args ) = process_file(
  $fh,
  chomp     => $TRUE,
  keep_open => $TRUE,
  trim      => 'both',
);

ok( ( @{$lines} == 6 && !map { $_ =~ /^\s+.*\s+$/ ? $_ : () } @{$lines} ),
  'trim both' )
  or diag( Dumper [$lines] );

__DATA__
# comment
line2
  line3 

line5
line6
