#!/usr/local/bin/perl -w

# $Id: Print.t 1835 2007-03-17 17:36:20Z jonasbn $

use strict;
use Data::Dumper;
use lib qw(../lib lib);

use Test::More tests => 11;

#Test 1-2
BEGIN { use_ok( 'Games::Bingo::Print'); }
require_ok( 'Games::Bingo::Print' );

#Test 3-4 new 
my $bp = Games::Bingo::Print->new();
is(ref $bp, 'Games::Bingo::Print', 'Testing the constructor');

is(ref $bp->{'pdf'}, 'PDFLib', 'Testing the constructor (pdf)');

#test 5-6 _print_row
my $bp2 = Games::Bingo::Print->new();

is(ref $bp->{'pdf'}, 'PDFLib', 'Testing the constructor (pdf)');

ok($bp2->_print_row(
          'x_start_cordinate' => 30,
          'y_start_cordinate' => 50,
          'x_end_cordinate' => 230,
          'size' => 60,
          numbers => [1, 2, 10, 20, 30, 40, 50, 60, 70, 80, 90]
), 'Testing _print_row');

#test 7-8 _print_card
my $bp3 = Games::Bingo::Print->new();

is(ref $bp->{'pdf'}, 'PDFLib', 'Testing the constructor (pdf)');

ok($bp3->_print_card(
          'x_start_cordinate' => 30,
          'y_start_cordinate' => 50,
          'y_end_cordinate' => 230,
          'size' => 60
), 'Testing _print_card');

#Test 9 print_pages
ok($bp->print_pages(1), 'Testing the generation of the PDF file');

#Test 10
my $filename = "bingo.pdf";
ok(-e $filename, 'Testing that the file is there');

#Test 11
my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev, $size, $atime,$mtime,$ctime,$blksize,$blocks)
 = stat($filename);
 
ok($size > 0);
