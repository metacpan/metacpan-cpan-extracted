#!perl

use strict;
use warnings;

use Test::More 'no_plan';

use lib 't/lib';
use My::Manager;
use File::Temp qw(tempdir);

my $dir = tempdir(CLEANUP => 1);

my $mgr = My::Manager->new({
  root => $dir,
});

$mgr->write([
  (map { { id => $_ } } 1..10),
  (map { { id => $_, color => 'red' } } 11..15),
]);

is $mgr->search({ id => 13 })->total_hits, 1, "one hit by id";
is $mgr->search({ color => 'colorless' })->total_hits, 10, "10 by =";
{
  local $TODO = "make negative matching work";
is $mgr->search({ id => { '!=' => 13 } })->total_hits, 5,
  '5 by !=';
}
