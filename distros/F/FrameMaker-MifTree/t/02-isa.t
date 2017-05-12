#!/usr/bin/perl
# $Id: 02-isa.t 1 2005-02-10 21:44:54Z roel $
use strict;
use warnings;
use Test::More 'no_plan';
use lib 'lib';

use FrameMaker::MifTree;

my $a = bless({
  attributes => '0',
  daughters => [
    bless({
      attributes => {},
      daughters => [],
      mother => 'fix',
      name => 'daughter-1',
    }, "FrameMaker::MifTree"),
    bless({
      attributes => {},
      daughters => [],
      mother => 'fix',
      name => 'daughter-2',
    }, "FrameMaker::MifTree"),
  ],
  mother => undef,
  name => 'mother',
}, "FrameMaker::MifTree");
$a->{daughters}[0]{mother} = $a;
$a->{daughters}[1]{mother} = $a;

my $b = FrameMaker::MifTree->new;
isa_ok($b, 'FrameMaker::MifTree');
can_ok($b,  qw(attributes mother daughters walk_down));

is($a->name,                 'mother',     'root->name');
is(($a->daughters)[0]->name, 'daughter-1', 'access to daughter');
$a->remove_daughter(($a->daughters)[0]);
is($a->daughters,            1,             'remove daughters');
$a->Tree::DAG_Node::add_daughters($b); # add_daughters is overridden
is($a->daughters,            2,             'add daughters');
my @sisters = $b->sisters;
is($sisters[0]->name,        'daughter-2',  'check sisters');
my ($i, $j) = (0, 0);
$a->walk_down({callback => sub {$i++; 1;}, callbackback => sub {$j++; 1;}});
is($i,                       3,             'walkdown callback');
is($j,                       3,             'walkdown callbackback');
