use strict;

use Test::More tests => 3;

use Method::Cascade;
{
  package TestPkg;
  sub new { bless { count => 0 }, shift};
  sub inc { shift()->{count}++ }
  sub get { shift()->{count} }
}

is(ref(cascade(TestPkg->new())), 'Method::Cascade::Wrapper');
is(ref(cascade(TestPkg->new())->inc->inc), 'Method::Cascade::Wrapper');

my $tp = TestPkg->new;

cascade($tp)->inc
            ->inc
            ->inc
            ->inc;

is($tp->get(), 4);
