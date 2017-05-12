#!/usr/bin/perl -w

# for Math::String::Charset.pm (simple set)

use Test;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../lib'; # to run manually
  chdir 't' if -d 't';
  plan tests => 22;
  }

use Math::String::Charset qw/analyze/;

$Math::String::Charset::die_on_error = 0;	# we better catch them
my $a;

###############################################################################
# study/analyze

my $words = [ 'test', 'toast', 'froesche', 'taste', 'fast' ];
my $hash = Math::String::Charset::study ( order => 2, words => $words);

ok ($hash->{start}->[0],'t');
ok ($hash->{start}->[1],'f');
ok ($hash->{end}->[0],'t');
ok ($hash->{end}->[1],'e');
ok ($hash->{bi}->{t}->[0],'e');
ok ($hash->{bi}->{t}->[1],'a');
ok ($hash->{bi}->{t}->[2],'o');

Math::String::Charset::study(
  order => 2, words => [ qw/test blattlaus haus laus tausende tausend/ ] );
$a = Math::String::Charset->new( Math::String::Charset::study(
  order => 2, words => [ qw/test blattlaus haus laus tausende tausend/ ],
  ) );
# result should be equal to doing the following:
#$a = Math::String::Charset->new( {
# bi => {
#  e => ['n', 's', ]
#  n => ['d', ]
#  a => ['u', 't', ]
#  d => ['e', ]
#  s => ['e', 't', ]
#  l => ['a', ]
#  u => ['s', ]
#  h => ['a', ]
#  b => ['l', ]
#  t => ['a', 'e', 'l', 't', ]
# },
# start => [ 't', 'l', 'h', 'b' ],
# end => [ 'e','d','s','t']
# } );

ok ($a->isa('Math::String::Charset'));
ok (ref($a),'Math::String::Charset::Nested');
ok ($a->error(),"");
ok ($a->class(0),1);    # ''
ok ($a->class(1),1);    # t
ok ($a->class(2),2);    # te, tt
ok ($a->class(2),2);    # te, tt
ok ($a->class(3),6);    # tat, tes, tte, ttt, lat, hat

# another test to catch bugs in first/last (with study), test export study
$a = Math::String::Charset->new( analyze(
  order => 2, words => [ qw/hocuspocus/ ],
  ) );
ok ($a->error(),"");
# the following could be calulated to 5 automatically (minimum path length)
ok ($a->minlen(),'-inf');       # no ones, no twos => at least 3
ok ($a->class(1),0);            # h
ok ($a->class(2),0);            # ho
ok ($a->class(3),0);            # hoc
ok ($a->class(4),0);            # hocu
ok ($a->class(5),1);            # hocus

###############################################################################
# Perl 5.005 does not like ok ($x,undef)

sub ok_undef
  {
  my $x = shift;

  ok (1,1) and return if !defined $x;
  ok ($x,'undef');
  }
