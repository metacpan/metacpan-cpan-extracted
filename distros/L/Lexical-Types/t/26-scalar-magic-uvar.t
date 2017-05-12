#!perl -T

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use VPIT::TestHelpers;

BEGIN {
 load_or_skip_all('Variable::Magic', '0.35', [ ]);
 plan skip_all => 'perl 5.10 required to test uvar magic'
                                             unless Variable::Magic::VMG_UVAR();
}

{
 package Lexical::Types::Test::Ref;

 use Variable::Magic qw<wizard cast>;

 our $wiz;
 BEGIN {
  $wiz = wizard data  => sub { +{ } },
                fetch => sub { ++$_[1]->{fetch}; () },
                store => sub { ++$_[1]->{store}; () };
 }

 sub TYPEDSCALAR {
  my %h = ("_\L$_[2]" => (caller(0))[2]);
  cast %h, $wiz;
  $_[1] = \%h;
  ();
 }
}

{ package Ref; }

BEGIN {
 plan tests => 2 * 11;
}

use Lexical::Types as => 'Lexical::Types::Test';

sub check (&$$;$) {
 my $got = Variable::Magic::getdata(%{$_[1]}, $Lexical::Types::Test::Ref::wiz);
 my ($test, $exp, $desc) = @_[0, 2, 3];
 my $want = wantarray;
 my @ret;
 {
  local @{$got}{qw<fetch store>};
  delete @{$got}{qw<fetch store>};
  if ($want) {
   @ret = eval { $test->() };
  } elsif (defined $want) {
   $ret[0] = eval { $test->() };
  } else {
   eval { $test->() };
  }
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  is_deeply $got, $exp, $desc;
 }
 return $want ? @ret : $ret[0];
}

for (1 .. 2) {
 my Ref $x; my $lx = __LINE__;

 my $y = check { $x->{_ref} } $x, { fetch => 1 }, 'fetch';
 is $y, $lx, 'fetch correctly';

 check { $x->{wat} = __LINE__ } $x, { store => 1 }, 'store'; my $l0 = __LINE__;
 is $x->{wat}, $l0, 'store correctly';

 my Ref $z = $x; my $lz = __LINE__;

 $y = check { $x->{_ref} } $x, { fetch => 1 }, 'fetch after being assigned';
 is $y, $lx, 'fetch after being assigned correctly';

 $y = check { $z->{_ref} } $z, { fetch => 1 }, 'fetch after being assigned to';
 is $y, $lx, 'fetch after being assigned to correctly';

 check { $z->{wat} = $x->{wat} + __LINE__ - $l0 } $z, { fetch => 1, store => 1 }, 'fetch/store';
 is $z->{wat}, __LINE__-1, 'fetch/store correctly';
 is $x->{wat}, __LINE__-2, 'fetch/store correctly';
}
