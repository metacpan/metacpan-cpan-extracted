#!/usr/bin/perl
# $Id: 03-fold.t 1 2005-02-10 21:44:54Z roel $
use strict;
use warnings;
use Test::More tests => 3;
use lib 'lib';

use FrameMaker::MifTree;

my $new_obj = FrameMaker::MifTree->new();
$new_obj->parse_mif(<<ENDMIF);
<MIFFile 7.00>
<Para 
 <ParaLine 
  <String `Line 1 - remains separate line'>
  <Char HardReturn>
 > # End of ParaLine
 <ParaLine 
  <String `Line 2 - also not folded'>
  <Char HardReturn>
 > # End of ParaLine
 <ParaLine 
  <String `Line 3 '>
  <String `- folded '>
 > # End of ParaLine
 <ParaLine 
  <String `to 1 line'>
 > # End of ParaLine
> # End of Para
# End of MIFFile
ENDMIF

$new_obj->fold_strings;

my @str_obj =$new_obj->daughters_by_name('String', recurse => 1);

is(
  $str_obj[0]->attribute,
  q{`Line 1 - remains separate line\x09 '},
 'fold strings 1'
);

is(
  $str_obj[1]->attribute,
  q{`Line 2 - also not folded\x09 '},
  'fold strings 2'
);

is(
  $str_obj[2]->attribute,
  q{`Line 3 - folded to 1 line'},
  'fold strings 3'
);

__END__
