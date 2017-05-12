#!/usr/bin/perl -w

# for Math::String::Charset::Wordlist.pm

use Test::More;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../lib'; # to run manually
  unshift @INC, '../blib/arch';
  chdir 't' if -d 't';
  plan tests => 179;
  }

use Math::String::Charset::Wordlist;
use Math::String;

$Math::String::Charset::die_on_error = 0;	# we better catch them
my $a;

my $c = 'Math::String::Charset::Wordlist';

##############################################################################
# creating via Math::String::Charset

$a = Math::String::Charset->new( { type => 2, order => 1,
  file => 'testlist.lst' } );
is ($a->error(),"");
is (ref($a),$c);
is ($a->isa('Math::String::Charset'),1);
is ($a->file(),'testlist.lst');

# create directly
$a = $c->new( { file => 'testlist.lst' } );
is ($a->error(),"");
is (ref($a),$c);
is ($a->isa('Math::String::Charset'),1);
is ($a->file(),'testlist.lst');

##############################################################################
# dictionary tests

#1:dictionary
#2:math
#3:string
#4:test
#5:unsorted
#6:wordlist

is ($a->first(1), 'dictionary');
is ($a->num2str(0), '');
is ($a->num2str(1),'dictionary');
is ($a->num2str(2),'math');
is ($a->num2str(3),'string');
is ($a->num2str(4),'test');
is ($a->num2str(5),'unsorted');
is ($a->num2str(6),'wordlist');

is ($a->char(0),'dictionary');
is ($a->char(-1),'wordlist');
is ($a->char(1),'math');
is ($a->char(-2),'unsorted');

is (join(":",$a->start()),'dictionary:math:string:test:unsorted:wordlist');
is (join(":",$a->end()),'dictionary:math:string:test:unsorted:wordlist');
is (join(":",$a->ones()),'dictionary:math:string:test:unsorted:wordlist');
is (scalar $a->start(), 6);
is (scalar $a->end(), 6);
is (scalar $a->ones(), 6);

# num2str in list mode
my @a = $a->num2str(1);
is ($a[0],'dictionary');
is ($a[1],1);		# one word is one "character"


is ($a->length(),6);
is ($a->count(1),6);

is ($a->str2num('dictionary'),1);
is ($a->str2num('math'),2);
is ($a->str2num('string'),3);
is ($a->str2num('test'),4);
is ($a->str2num('unsorted'),5);
is ($a->str2num('wordlist'),6);

#########################
# test offset()

is ($a->offset(0),0);
is ($a->offset(1),11);
is ($a->offset(2),16);
is ($a->offset(-1),37);
is ($a->offset(-6),0);
is ($a->offset(5),37);
is ($a->offset(6),undef);
is ($a->offset(22),undef);

# test caching and next()/prev()

my $x = Math::String->new('unsorted',$a);
$x++;
is ($x - Math::BigInt->new(6), '');
is ($x,'wordlist');
$x--;
is ($x - Math::BigInt->new(5), '');
is ($x,'unsorted');

# excercise Math::String::Charset::Wordlist::chars()
is ($x->length(),1);

##############################################################################
# creating via Math::String::Charset w/ scale

$a = Math::String::Charset->new( { type => 2, order => 1,
  file => 'testlist.lst', scale => 2, } );
is ($a->error(),"");
is (ref($a),$c);
is ($a->isa('Math::String::Charset'),1);
is ($a->isa('Math::String::Charset::Wordlist'),1);

##############################################################################
# copy()

my $b = $a->copy();

is ($b->error(),"");
is (ref($b),$c);
is ($b->isa('Math::String::Charset'),1);
is ($b->isa('Math::String::Charset::Wordlist'),1);
is ($b->file(),'testlist.lst');

# check that the tied object is not copied
print "different\n" if ref($b->{list}) != ref($a->{list});
print "different\n" if ref(tied $b->{list}) != ref( tied $a->{list});

is ($b->{_obj} eq $a->{_obj}, 1 );

# see if copy and original still work
for my $cs ($a,$b)
  {
  is ($cs->first(1), 'dictionary');
  is ($cs->num2str(0), '');
  is ($cs->num2str(1),'dictionary');
  is ($cs->num2str(2),'math');
  is ($cs->num2str(3),'string');
  is ($cs->num2str(4),'test');
  is ($cs->num2str(5),'unsorted');
  is ($cs->num2str(6),'wordlist');

  is ($cs->str2num('dictionary'),1);
  is ($cs->str2num('math'),2);
  is ($cs->str2num('string'),3);
  is ($cs->str2num('test'),4);
  is ($cs->str2num('unsorted'),5);
  is ($cs->str2num('wordlist'),6);

  }

##############################################################################
# str2num() and 0x0D removal

for my $list (qw/testbig.lst test0d.lst/)
  {
  my $cs = Math::String::Charset::Wordlist->new( { file => $list } );
  is ($cs->error(),"");
  is (ref($cs),$c);
  is ($cs->isa('Math::String::Charset'),1);
  is ($cs->isa('Math::String::Charset::Wordlist'),1);
  is ($cs->file(),$list);

  is ($cs->num2str(1),'Brings World Peace and Cake For All');
  is ($cs->num2str(2),'Just Another Perl Hacker');
  is ($cs->num2str(3),'String');
  is ($cs->num2str(4),'Worldlist');
  is ($cs->num2str(5),'dictionary');
  is ($cs->num2str(6),'entropy');
  is ($cs->num2str(7),'foo');
  is ($cs->num2str(8),'foobar');
  is ($cs->num2str(9),'math');
  is ($cs->num2str(10),'perl');
  is ($cs->num2str(11),'string');
  is ($cs->num2str(12),'test');
  is ($cs->num2str(13),'unsorted');
  is ($cs->num2str(14),'wordlist');

  is ($cs->str2num('Brings World Peace and Cake For All'),1);
  is ($cs->str2num('Just Another Perl Hacker'),2);
  is ($cs->str2num('String'),3);
  is ($cs->str2num('Worldlist'),4);
  is ($cs->str2num('dictionary'),5);
  is ($cs->str2num('entropy'),6);
  is ($cs->str2num('foo'),7);
  is ($cs->str2num('foobar'),8);
  is ($cs->str2num('math'),9);
  is ($cs->str2num('perl'),10);
  is ($cs->str2num('string'),11);
  is ($cs->str2num('test'),12);
  is ($cs->str2num('unsorted'),13);
  is ($cs->str2num('wordlist'),14);
  }

##############################################################################
# big list withmore than 8192 bytes (if size of readbuffer ever increases,
# then # adapt this test!)

$a = $c->new( { file => 'big.lst' } );
is ($a->error(),"");
is (ref($a),$c);
is ($a->isa('Math::String::Charset'),1);
is ($a->file(),'big.lst');

is ($a->first(1),'aachen', 'first in big list');
is ($a->last(1),'abfliegt', 'last in big list');

is ($a->num2str(0),'');
is ($a->num2str(-1),'aachen');
is ($a->num2str(663),'abfliegt');

#abflauendem
#abflauenden
#abflauender
#abfliegend
#abfliegende
#abfliegendem
#abfliegender
#abfliegendes
#abfliegt

is ($a->num2str(655),'abflauendem');
is ($a->num2str(656),'abflauenden');
is ($a->num2str(657),'abflauender');
is ($a->num2str(658),'abfliegend');
is ($a->num2str(659),'abfliegende');
is ($a->num2str(660),'abfliegendem');
is ($a->num2str(661),'abfliegender');
is ($a->num2str(662),'abfliegendes');
is ($a->num2str(663),'abfliegt');


##############################################################################

$a = $c->new( { file => 'empty.lst' } );
is ($a->error(),"");
is (ref($a),$c);
is ($a->isa('Math::String::Charset'),1);
is ($a->file(),'empty.lst');

is ($a->first(1),'', 'first in empty list');
is ($a->last(1),'', 'last in empty list');
is ($a->length(),2, 'len in empty list');

is (join(":", $a->start() ), ':');


