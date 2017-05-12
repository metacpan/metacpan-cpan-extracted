#!/usr/bin/perl -w

# for Math::String::Charset::Nested.pm

use Test;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../lib'; # to run manually
  chdir 't' if -d 't';
  plan tests => 93;
  }

use Math::String::Charset;
use Math::String::Charset::Nested;

$Math::String::Charset::Nested::die_on_error = 0;	# we better catch them
$Math::String::Charset::die_on_error = 0;		# we better catch all
my $a;

###############################################################################
# some valid input combinations via Charset, and the same directly

my $c = 'Math::String::Charset::Nested';

for my $c (qw/ Math::String::Charset Math::String::Charset::Nested/)
  {
  $a = $c->new( { type => 3 } );
  ok ($a->error(),"Illegal type '3'");

  $a = Math::String::Charset->new( { type => -1 } );
  ok ($a->error(),"Illegal type '-1'");

# Not via grouped
#  $a = $c->new( { order => 2, type => 1 } );
#  ok ($a->error(),"Illegal combination of type '1' and order '2'");

  $a = $c->new( { order => 3, type => 0 } );
  ok ($a->error(),"Illegal order '3'");

  $a = $c->new( { type => 0, sets => 'foo' } );
  ok ($a->error(),"Illegal type '0' used with 'sets'");

#  $a = $c->new( { type => 1, sep => 'foo' } );
#  ok ($a->error(),"Illegal type '1' used with 'sep'");

#  $a = $c->new( { type => 1, bi => 'foo' } );
#  ok ($a->error(),"Illegal type '1' used with 'bi'");

  }

###############################################################################
# bi grams

# check ones (cross from start/end) and restricting of start
$a = Math::String::Charset->new( {
    start => ['b','c','a', 'q' ],
    bi => {
      'a' => [ 'b', 'c', 'a' ],
      'b' => [ 'c', 'b' ],
      'c' => [ 'a', 'c' ],
      'q' => [  ]		# can't be in start
      },
    end => [ 'b','c','a' ],
  } );
ok ($a->error(),"");
ok ($a->isa('Math::String::Charset'));
ok (ref($a),$c);

ok ($a->class(1),4); 			# b,c,a,q

ok (join(' ',$a->ones()),"b c a q");
ok (join(' ',$a->start()),"b c a");	# q can't be in start, has no followers

ok ($a->is_valid('bca'),1);
ok ($a->is_valid('dca'),0);		# illegal start
ok ($a->is_valid('abcd'),0);		# illegal end/character
ok ($a->is_valid('bac'),0);		# illegal bigram 'ba'
ok ($a->is_valid('bcb'),0);		# illegal bigram 'cb'
ok ($a->is_valid('bcabq'),0);		# illegal bigram 'bq'
ok ($a->is_valid('qa'),0);		# illegal bigram 'qa'

ok ($a->error(),"");
$a = Math::String::Charset->new( {
    start => ['b','c','a'],
    bi => {
      'a' => [ 'b', 'c', 'a' ],
      'b' => [ 'c', 'b' ],
      'c' => [ 'a', 'c' ]
      }
  } );
ok ($a->error(),"");
ok ($a->length(),3);
ok (scalar $a->end(),3);

my $ok = 0;
my $aa = [ 'b','c','a' ];
my @ab = $a->start();

for (my $i = 0; $i < @$aa; $i++)
  {
  $ok ++ if $aa->[$i] ne $ab[$i];
  }
ok ($ok,0);

ok ($a->class(1),3); 		# b,c,a
ok ($a->class(2),7); 		# bc
				# bb
				# ca
				# cc
				# ab
				# ac
				# aa
ok ($a->class(3),3*2+2*2+2*3); 	# 7 combos:
		 		# 3 of them end in c => 3 * 2
                       		# 2 of them end in b => 2 * 2
                       		# 2 of them end in a => 2 * 3
				# sum:			16
				# result:
				# bca
				# bcc
				# bbc
				# bbb
				# cab
				# cac
				# caa
				# cca
				# ccc
				# abc
				# abb
				# aca
				# acc
				# aab
				# aac
				# aaa
ok ($a->class(4),5*3+7*2+4*2); 	# 16 combos:
				# 5 times a: 5 * 3
				# 7 times c: 7 * 2
				# 4 times b: 4 * 2
				# sum:       37

ok ($a->str2num(''),0);
ok ($a->str2num('b'),1);
ok ($a->str2num('c'),2);
ok ($a->str2num('a'),3);

# check sum of strings starting with a certain string
$a->_calc(4);

ok ($a->{_scnt}->[1]->{a},1);
ok ($a->{_scnt}->[1]->{c},1);
ok ($a->{_scnt}->[1]->{b},1);

ok ($a->{_scnt}->[2]->{a},3);
ok ($a->{_scnt}->[2]->{b},2);
ok ($a->{_scnt}->[2]->{c},2);

ok ($a->{_scnt}->[3]->{a},7);
ok ($a->{_scnt}->[3]->{b},4);
ok ($a->{_scnt}->[3]->{c},5);

ok ($a->{_scnt}->[4]->{a},16);
ok ($a->{_scnt}->[4]->{b},9);
ok ($a->{_scnt}->[4]->{c},12);

# sum no longer calculated

#print "sum 1\n";
#ok ($a->{_ssum}->[1]->{b},0);
#ok ($a->{_ssum}->[1]->{c},1);
#ok ($a->{_ssum}->[1]->{a},2);

#print "sum 2\n";
#ok ($a->{_ssum}->[2]->{b},0);
#ok ($a->{_ssum}->[2]->{c},2);
#ok ($a->{_ssum}->[2]->{a},4);

##print "sum 3\n";
#ok ($a->{_ssum}->[3]->{b},0);
#ok ($a->{_ssum}->[3]->{c},4);
#ok ($a->{_ssum}->[3]->{a},9);

# print "sum 4\n";
#ok ($a->{_ssum}->[4]->{b},0);
#ok ($a->{_ssum}->[4]->{c},9);
#ok ($a->{_ssum}->[4]->{a},21);

###############################################################################
# restricting ending chars

$a = Math::String::Charset->new( {
    start => ['b','c','a'],
    bi => {
      'a' => [ 'b', 'c', 'a' ],
      'b' => [ 'c', 'b' ],
      'c' => [ 'a', 'c' ],
      'q' => [ ],
      }
  } );
ok ($a->error(),"");
ok ($a->length(),3);		# a,b,c
ok (scalar $a->end(),4);	# a,b,c,q

$a = Math::String::Charset->new( {
    start => ['b','c','a'],
    bi => {
      'a' => [ 'b', 'c', 'a' ],
      'b' => [ 'c', 'b' ],
      'c' => [ 'a', 'c', 'x' ],
      'q' => [ ],
      },
    end => [ 'a', 'b' ],
  } );

ok ($a->error(),"");
ok ($a->length(),2);		# a,b
ok (scalar $a->end(),4);	# a,b,q,x

# check sum of strings starting with a certain string
$a->_calc(4);

ok ($a->{_scnt}->[1]->{a},1);
ok_undef ($a->{_scnt}->[1]->{c});
ok ($a->{_scnt}->[1]->{b},1);

ok ($a->{_scnt}->[2]->{a},2);	# ab, aa 	(ac is invalid)
ok ($a->{_scnt}->[2]->{b},1);	# bb 		(bc is invalid)
ok ($a->{_scnt}->[2]->{c},2);	# ca, cx	(cc is invalid)

# check last(), first()
$a = Math::String::Charset->new( {
    start => ['b','c','a','i'],
    bi => {
      'a' => [ 'c', 'b' ],
      'b' => [ 'c', 'b','j' ],
      'c' => [ 'a', 'c', 'x' ],
      'q' => [ ],
      'j' => [ ],
      },
    end => [ 'a', 'b', 'c', 'j' ],
  } );
ok (ref($a),$c);
ok ($a->isa('Math::String::Charset'));
ok ($a->error(),"");
ok (join(' ',$a->ones()),'b c a');
ok ($a->first(0),'');
ok ($a->last(0), '');
ok ($a->first(1),'b');		# ones: b,c,a
ok ($a->last(1), 'a');		# ones: b,c,a

ok ($a->first(2),'bc');
ok ($a->last(2), 'ab');

ok ($a->first(3),'bca');
ok ($a->last(3), 'abj');

ok ($a->first(4),'bcac');
ok ($a->last(4), 'abbj');

ok ($a->first(5),'bcaca');
ok ($a->last(5), 'abbbj');

$a = Math::String::Charset->new( {
    start => ['b','c','a','i'],
    bi => {
      'a' => [ 'q', 'j', 'b' ],
      'b' => [ 'c', 'b','j' ],
      'c' => [ 'a', 'c', 'x' ],
      'q' => [ ],
      'j' => [ 'b' ],
      },
    end => [ 'a', 'b', 'c', 'j' ],
    minlen => 2, maxlen => 5,
  } );
ok ($a->error(),"");
ok_undef ($a->first(0));
ok_undef ($a->last(0));
ok_undef ($a->first(1));
ok_undef ($a->last(1));
ok ($a->first(2),'bc');
ok ($a->last(2),'ab');
ok ($a->first(3),'bca');
ok ($a->last(3),'abj');
ok ($a->first(4),'bcaq');
ok ($a->first(5),'bcajb');
ok_undef ($a->first(6));

# XXX: counts in class
#ok ($a->class(2),9);	# bc, bb, bj, ca, cc, cj, aq, aj, ab
#ok ($a->class(3),17);
#ok ($a->class(4),36);

###############################################################################
# normalize (no-op)

ok ($a->norm('hocus'),'hocus');

###############################################################################
# scale

$a = $c->new( {
  start => ['b','c','a','i'],
  bi => {
      'a' => [ 'q', 'j', 'b' ],
      'b' => [ 'c', 'b','j' ],
      'c' => [ 'a', 'c', 'x' ],
      'q' => [ ],
      'j' => [ 'b' ],
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

###############################################################################
# Perl 5.005 does not like ok ($x,undef)

sub ok_undef
  {
  my $x = shift;
  $x = $x->bstr() if ref($x);

  ok (1,1) and return if !defined $x;
  ok ($x,'undef');
  }
