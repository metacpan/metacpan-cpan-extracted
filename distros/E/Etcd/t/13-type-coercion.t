#!perl

use strict;
use warnings;

use Test::More tests => 1;

use Etcd::Node;

subtest node_dir_boolean_serialization => sub {
    is(Etcd::Node->new(key => 'foo', dir => 1)->dir(), 1);
    is(Etcd::Node->new(key => 'foo', dir => 0)->dir(), '');
    is(Etcd::Node->new(key => 'foo')->dir(), undef);

    is(Etcd::Node->new(key => 'foo', dir => true->new())->dir(), 1);
    is(Etcd::Node->new(key => 'foo', dir => false->new())->dir(), '');
};

package true;
use overload '0+' => sub { 1 };
sub new { bless { }, shift }

package false;
use overload '0+' => sub { 0 };
sub new { bless { }, shift }
