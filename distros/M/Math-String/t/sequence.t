#!/usr/bin/perl -w

use strict;
use Test;

BEGIN
  {
  $| = 1;
  chdir 't' if -d 't';
  unshift @INC, '../lib'; # to run manually
  plan tests => 31;
  }

use Math::String::Sequence;
use Math::String;
use Math::BigInt;

my ($seq,$first,$last);

##############################################################################
# check new()

$seq = Math::String::Sequence->new( 'a', 'z' );

ok (ref($seq),'Math::String::Sequence');
ok ($seq->first(),'a');
ok ($seq->last(),'z');
ok ($seq->string(2),'c');
ok ($seq->string(0),'a');
ok ($seq->string(-1),'z');
ok ($seq->string(-2),'y');

my @set = split //,reverse 'abcdefghijklmnopqrstuvwxyz';

$seq = Math::String::Sequence->new( 'z', 'a', \@set );
ok (ref($seq),'Math::String::Sequence');
ok ($seq->first(),'z');
ok ($seq->last(),'a');
ok ($seq->string(24),'b');
ok ($seq->string(-1),'a');
ok ($seq->string(-2),'b');

##############################################################################
# check is_reversed() and reversed sequences

$seq = Math::String::Sequence->new( 'a', 'z' );
ok ($seq->is_reversed(),0);

$seq = Math::String::Sequence->new( 'z', 'a' );
ok ($seq->is_reversed(),1);

$seq = Math::String::Sequence->new( 'z', 'a' );
ok ($seq->first(), 'z');
ok ($seq->last(), 'a');
ok ($seq->length(),26);
ok ($seq->string(0),'z');
ok ($seq->string(1),'y');
ok ($seq->string(-1),'a');
ok ($seq->string(-2),'b');

my @a = $seq->as_array();
ok ($a[0],'z');
ok ($a[-1],'a');
ok ($a[-2],'b');
ok ($a[1],'y');

$seq = Math::String::Sequence->new( 'aa', 'cc' );
@a = $seq->as_array();
ok ($a[0],'aa');
ok ($a[-1],'cc');
ok ($a[-2],'cb');
ok ($a[1],'ab');

# test error()
ok ($seq->error(),'');
