#!perl -T

use strict;
use warnings;
use Test::More tests => 4;
use Data::Dumper;
use License::Syntax;
my $o = new License::Syntax;
$o->add_alias('foo' => 'bar');
$o->add_alias('baz' => 'foo');
#1
ok('bar' eq lc $o->canonical_name('baz'), 'right extended mapping');
#2
ok(!defined $o->{diagnostics}, 'right extended mapping w/o diag');

$o->{debug}++;
$o->add_alias('foo' => 'final');
$o->{debug}--;
#3
ok('bar' eq lc $o->canonical_name('foo'), 'no re-mapping');

$o->add_alias('bar' => 'final');
#4
ok($o->{diagnostics}[0] =~ m{mapping error}, 'left extend causes diagnostics');
