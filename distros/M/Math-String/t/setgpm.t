#!/usr/bin/perl -w

# for Math::String::Charset::Grouped.pm

use Test;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../lib'; # to run manually
  chdir 't' if -d 't';
  plan tests => 95;
  }

use Math::String::Charset;
use Math::String::Charset::Grouped;

$Math::String::Charset::Grouped::die_on_error = 0;	# we better catch them
$Math::String::Charset::die_on_error = 0;		# we better catch all

my $a;

###############################################################################
# grouped charsets

my $c = 'Math::String::Charset::Grouped';

$a = Math::String::Charset->new( { sets =>
  {
   0 => ['a'..'f'],
   1 => ['A'..'Z'],
  -1 => ['0'..'9'],
  } } );

ok ($a->error(),"");
ok ($a->isa('Math::String::Charset'));
ok (ref($a),$c);
ok ($a->error(),"");

ok ($a->order(),1); ok ($a->type(),1);

ok ($a->class(1),0);			# none
ok ($a->class(2),26*10);		# A-Z * 0-9
ok ($a->class(3),26*6*10);		# A-Z * a-f * 0-9
ok ($a->class(4),26*6*6*10);		# A-Z * a-f * a-f * 0-9
ok ($a->class(5),26*6*6*6*10);		# A-Z * a-f * a-f * a-f * 0-9

$a = Math::String::Charset->new( { sets =>
  {
   0 => ['a'..'f'],
   1 => ['A'..'Z','0'..'4'],
  -1 => ['0'..'9'],
  } } );

# '', '0', '1', '2', '3', '4', 'A0', 'A1', ...
#  0    1    2    3    4    5     6     7  ...

ok ($a->class(1),5);			# '0'..'4'
ok ($a->class(2),31*10);		# A-Z,0..4 * 0-9
ok ($a->class(3),31*6*10);		# A-Z,0..4 * a-f * 0-9
ok ($a->class(4),31*6*6*10);		# A-Z,0..4 * a-f * a-f * 0-9
ok ($a->class(5),31*6*6*6*10);		# A-Z,0..4 * a-f * a-f * a-f * 0-9

# str2num and reverse
ok ($a->str2num(''),0);
ok ($a->str2num('0'),1);
ok ($a->str2num('1'),2);
ok ($a->str2num('2'),3);
ok ($a->str2num('3'),4);
ok ($a->str2num('4'),5);
ok ($a->str2num('A0'),6);
ok ($a->str2num('A9'),15);
ok ($a->str2num('B0'),16);
ok ($a->str2num('Aa0'),5+31*10+1);

ok ($a->num2str(0),''); my ($x,$y) = $a->num2str(0); ok ($x,''); ok ($y,0);
ok ($a->num2str(1),'0');
ok ($a->num2str(2),'1');
ok ($a->num2str(3),'2');
ok ($a->num2str(4),'3');
ok ($a->num2str(5),'4');
ok ($a->num2str(6),'A0');
ok ($a->num2str(7),'A1');
ok ($a->num2str(15),'A9');
ok ($a->num2str(16),'B0');
ok ($a->num2str(5+31*10),'49');		# A..Z,0..4 => 4, 0..9 => 9: 49
ok ($a->num2str(5+31*10+1),'Aa0');
ok ($a->num2str(5+31*10+2),'Aa1');
ok ($a->num2str(5+31*10+31*6*10+1),'Aaa0');

# is_valid
ok ($a->is_valid(''),1);
ok ($a->is_valid('A'),1);
ok ($a->is_valid('-'),0);
ok ($a->is_valid('A9'),1);
ok ($a->is_valid('A9'),1);
ok ($a->is_valid('Aa0,'),0);
ok ($a->is_valid('Aa9,'),0);
ok ($a->is_valid('A-+,'),0);
ok ($a->is_valid('Aaa0'),1);
ok ($a->is_valid('Zzf1'),0);
ok ($a->is_valid('Zff1'),1);
ok ($a->is_valid('4ff9'),1);
ok ($a->is_valid('Aaa-'),0);

# first/last
ok ($a->first(),'');
ok ($a->last(),'');
ok ($a->first(1),'0');
ok ($a->last(1),'4');
ok ($a->first(2),'A0');
ok ($a->last(2),'49');
ok ($a->first(3),'Aa0');
ok ($a->last(3),'4f9');

###############################################################################
# test whether new() destroys {sets} key

my $sets = { 0 => ['a'..'z'], };

$a = Math::String::Charset->new( { sets => $sets, start => [ 'a' .. 'z' ], } );
ok ($a->error(),"");
ok ($a->isa('Math::String::Charset'));
ok (ref($a),$c);
ok (scalar keys %$sets,1);

###############################################################################
# chars

$a = Math::String::Charset->new( { sets =>
  {
   0 => ['a'..'z'],
   1 => ['0'..'9','a'..'z','A'..'Z'],
  -1 => ['!',' ','0'..'9','a'..'z'],
  -2 => ['!',' ','0'..'9','a'..'z'],
  } } );

foreach (qw/ abcdef hans Hans hans1 hans99 Hans99 hans!/,'hans ')
  {
  ok ($a->chars($a->str2num($_)),length($_));
  }

###############################################################################
# normalize

ok ($a->norm('abz'),'abz');

###############################################################################
# grouped with sep char charsets

$a = Math::String::Charset->new( { sep => ' ', sets =>
  {
   0 => Math::String::Charset->new( { sep => ' ', start => [ 'a','aa' ] } ),
   1 => Math::String::Charset->new( { sep => ' ', start => [ 'Z','ZZ' ] } ),
  } } );
ok ($a->error(),'');

ok ($a->class(0),1);
ok ($a->class(1),0);
ok ($a->class(2),4);
ok ($a->class(3),8);

ok ($a->str2num(''),     0);
ok ($a->str2num('Z a'),  1);	# no ones, since Z ZZ and a aa don't cross
ok ($a->str2num('Z aa'), 2);
ok ($a->str2num('ZZ a'), 3);
ok ($a->str2num('ZZ aa'),4);

###############################################################################
# bug in is_valid() not calling _calc() early enough

$a = Math::String::Charset->new( { sep => ' ', sets =>
  {
   0 => Math::String::Charset->new( { sep => ' ', start => [ 'a','aa' ] } ),
   1 => Math::String::Charset->new( { sep => ' ', start => [ 'Z','ZZ' ] } ),
   -1 => Math::String::Charset->new( { sep => ' ', start => [ '0','99' ] } ),
  } } );
ok ($a->error(),'');

$a = eval '$a->is_valid("Z a a 99");';
ok ($a,1);

###############################################################################
# scale

$a = Math::String::Charset->new( { sets =>
  {
   0 => ['a'..'f'],
   1 => ['A'..'Z'],
  -1 => ['0'..'9'],
  },
  scale => 2 } );
ok ($a->error(),"");
ok ($a->scale(),2);

###############################################################################
# copy

$b = $a->copy();

ok (ref($b), $c);
ok ($b->error(),"");
ok ($b->isa('Math::String::Charset'));
ok ($b->isa($c));

my $expected = <<HERE
type: GROUPED
 1 => type SIMPLE:
   start: A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
   end  : A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
   ones : A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
 0 => type SIMPLE:
   start: a b c d e f
   end  : a b c d e f
   ones : a b c d e f
 -1 => type SIMPLE:
   start: 0 1 2 3 4 5 6 7 8 9
   end  : 0 1 2 3 4 5 6 7 8 9
   ones : 0 1 2 3 4 5 6 7 8 9
ones :

HERE
;

my $got = $b->dump(); $got =~ s/\s$//; $expected =~ s/\s$//;

ok ($got, $expected);

###############################################################################
# Perl 5.005 does not like ok ($x,undef)

sub ok_undef
  {
  my $x = shift;

  ok (1,1) and return if !defined $x;
  ok ($x,'undef');
  }
