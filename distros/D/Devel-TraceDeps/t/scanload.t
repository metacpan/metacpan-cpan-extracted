#!/usr/bin/perl

use warnings;
use strict;

use Test::More 'no_plan';

use Devel::TraceDeps::Scan;

sub undent {
  my $s = shift;
  $s =~ s/^(\s*)//;
  my $sp = $1;
  $s =~ s/^$sp//gm;
  return($s);
}
{
  my $scan = Devel::TraceDeps::Scan->load(\(undent(<<'  THIS')));
  main
    -----
    req: foo.pm
    file: -e
    line: 1
    -----
    req: bar.pm
    file: -e
    line: 2
    fail: 1
  THIS

  ok($scan, 'loaded');
  is_deeply([$scan->callers], ['main']);

  my @items = $scan->items;
  is(scalar(@items), 2);
  {
    my $i = $items[0];
    is($i->by, 'main');
    is($i->req, 'foo');
    is($i->file, '-e');
    is($i->line, 1);
  }
  {
    my $i = $items[1];
    is($i->by, 'main');
    is($i->req, 'bar');
    is($i->file, '-e');
    is($i->line, 2);
  }
  is(scalar($scan->required), 2);
  my @loaded = $scan->loaded;
  is(scalar(@loaded), 1);
  is($loaded[0]->req, 'foo');
}


# vim:ts=2:sw=2:et:sta
