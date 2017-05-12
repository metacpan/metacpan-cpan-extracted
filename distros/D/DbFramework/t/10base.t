# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use Test;
use DBI 1.06;
use DbFramework::Util;
use DbFramework::Catalog;
use t::Config;
require "t/util.pl";

BEGIN { 
  plan tests => 1;
}

package Foo;
use strict;
use base qw(DbFramework::Util);

my %fields = (
	      NAME       => undef,
	      CONTAINS_H => undef,
	     );

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = bless { _PERMITTED => \%fields, %fields, }, $class;
  $self->name(shift);
  $self->contains_h(shift);
  return $self;
}

package main;
my $foo = new Foo('foo',['foo','oof','bar','rab','baz','zab']);
my @names = $foo->contains_h_byname('foo','bar');
ok("@names",'oof rab');

