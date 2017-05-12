#!perl -T

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use VPIT::TestHelpers;

BEGIN {
 load_or_skip_all('Variable::Magic', undef, [ ]);
}

{
 package Lexical::Types::Test::Str;

 use Variable::Magic qw<wizard cast>;

 our $wiz;
 BEGIN {
  $wiz = wizard data => sub { +{ } },
                get  => sub { ++$_[1]->{get}; () },
                set  => sub { ++$_[1]->{set}; () };
 }

 sub TYPEDSCALAR { cast $_[1], $wiz, $_[2]; () }
}

{ package Str; }

BEGIN {
 plan tests => 2 * 8;
}

use Lexical::Types as => 'Lexical::Types::Test';

sub check (&$$;$) {
 my $got = Variable::Magic::getdata($_[1], $Lexical::Types::Test::Str::wiz);
 my ($test, $exp, $desc) = @_[0, 2, 3];
 my $want = wantarray;
 my @ret;
 {
  local @{$got}{qw<get set>};
  delete @{$got}{qw<get set>};
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

sub zzz {
 my $d = Variable::Magic::getdata($_[0], $Lexical::Types::Test::Str::wiz);
 isnt $d,    undef,  'typed lexicals are tagged';
 is ref($d), 'HASH', 'typed lexicals are correctly tagged';
}

for (1 .. 2) {
 my Str $x = "abc";

 my $y = check { "$x" } $x, { get => 1 }, 'interpolate';
 is $y, 'abc', 'interpolate correctly';

 check { $x .= "foo" } $x, { get => 1, set => 1 }, 'append';
 is $x, 'abcfoo', 'append correctly';

 my Str $z;
 check { $z = "bar" . $x } $z, { set => 1 }, 'scalar assign';
 is $z, 'barabcfoo', 'scalar assign correctly';

 zzz($z);
}
