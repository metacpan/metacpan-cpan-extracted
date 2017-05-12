#! /usr/bin/perl
#---------------------------------------------------------------------
# 20-open.t
# Copyright 2012 Christopher J. Madsen
#
# Test the html_outfile function
#---------------------------------------------------------------------

use strict;
use warnings;

use Test::More 0.88;

plan tests => 6;

use IO::HTML ':rw';
use Encode 'find_encoding';
use File::Temp;

#---------------------------------------------------------------------
sub test
{
  my ($encoding, $bom, $expected) = @_;

  my $name = ref $encoding ? $encoding->name . " object" : $encoding;
  $name .= ($bom ? ' with BOM' : ' without BOM') if defined $bom;

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $tmp = File::Temp->new(UNLINK => 1);
  $tmp->close;

  my $fh = html_outfile("$tmp", $encoding, $bom);

  print $fh "\xA0\x{2014}";

  close $fh;

  open(my $in, '<:raw', "$tmp") or die $!;

  my $got = do { local $/; <$in> };

  close $in;

  is(unpack('H*', $got), $expected, $name);
} # end test

#---------------------------------------------------------------------
test 'utf-8-strict', 0, 'c2a0e28094';

test 'utf-8-strict', 1, 'efbbbfc2a0e28094';

test cp1252 => undef, 'a097';

test 'UTF-16BE', 1, 'feff00a02014';

test 'UTF-16LE', 1, 'fffea0001420';

test find_encoding('UTF-8'), 0, 'c2a0e28094';

done_testing;
