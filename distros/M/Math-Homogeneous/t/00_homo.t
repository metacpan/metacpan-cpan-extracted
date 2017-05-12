use strict;
use Test::More;
use Math::Homogeneous qw/ homo /;

use_ok $_ for qw/ Math::Homogeneous /;

subtest 'function' => sub {
  my $got = homo(2, qw/ a b /);
  my $expect = [['a','a'],['a','b'],['b','a'],['b','b']];
  is_deeply $got, $expect, 'function';
};

subtest 'iterator' => sub {
  my $itr = Math::Homogeneous->new(2, qw/ a b /);
  my $got = <$itr>;
  my $expect = ['a','a'];
  is_deeply $got, $expect, 'iterator';
};

done_testing;
