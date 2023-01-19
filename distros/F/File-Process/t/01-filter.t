#!/usr/bin/env perl

use strict;
use warnings;

use lib qw{.};

use Test::More tests => 6;
use Data::Dumper;

use_ok('File::Process');

my $fh    = *DATA;
my $start = tell $fh;

my $lines;
my %args;

########################################################################
subtest 'skip_blank_lines => 1' => sub {
########################################################################

  ( $lines, %args ) = process_file(
    $fh,
    chomp            => 1,
    keep_open        => 1,
    skip_blank_lines => 1,
  );

  ok( @{$lines} == 5, 'skip blanks' )
    or diag( Dumper [$lines] );

};

########################################################################
subtest 'skip_comments => 1' => sub {
########################################################################
  seek $fh, $start, 0;

  ( $lines, %args ) = process_file(
    $fh,
    chomp         => 1,
    keep_open     => 1,
    skip_comments => 1,
  );

  ok( ( @{$lines} == 5 && !map { $_ =~ /^[#]/xsm ? $_ : () } @{$lines} ),
    'skip comments' )
    or diag( Dumper [$lines] );
};

########################################################################
subtest 'trim => "front"' => sub {
########################################################################

  seek $fh, $start, 0;

  ( $lines, %args ) = process_file(
    $fh,
    chomp     => 1,
    keep_open => 1,
    trim      => 'front',
  );

  ok( ( @{$lines} == 6 && !map { $_ =~ /^\s+/xsm ? $_ : () } @{$lines} ),
    'trim front' )
    or diag( Dumper [$lines] );
};

########################################################################
subtest 'trim => "back"' => sub {
########################################################################
  seek $fh, $start, 0;

  ( $lines, %args ) = process_file(
    $fh,
    chomp     => 1,
    keep_open => 1,
    trim      => 'back',
  );

  ok( ( @{$lines} == 6 && !map { $_ =~ /\s+$/xsm ? $_ : () } @{$lines} ),
    'trim back' )
    or diag( Dumper [$lines] );
};

########################################################################
subtest 'trim => "both"' => sub {
########################################################################

  seek $fh, $start, 0;

  ( $lines, %args ) = process_file(
    $fh,
    chomp     => 1,
    keep_open => 1,
    trim      => 'both',
  );

  ok(
    ( @{$lines} == 6 && !map { $_ =~ /^\s+.*\s+$/xsm ? $_ : () } @{$lines} ),
    'trim both'
  ) or diag( Dumper [$lines] );
};

__DATA__
# comment
line2
  line3 

line5
line6
