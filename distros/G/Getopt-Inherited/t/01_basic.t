#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 2;

package Foo;
use parent 'Getopt::Inherited';
use constant GETOPT => qw(myopt1=s);
use constant GETOPT_DEFAULTS => (myopt1 => 'myval1');

package main;
our @ISA = qw(Foo);
getopt_ok([qw(-v --myopt otherval)], { verbose => 1, myopt1 => 'otherval' });
getopt_ok([qw(-v --log /tmp/log.txt)],
    { verbose => 1, logfile => '/tmp/log.txt', myopt1 => 'myval1' });

sub getopt_ok {
    my ($options, $expect) = @_;
    @ARGV = @$options;
    my $o = main->new;
    $o->do_getopt;
    our $count;
    is_deeply(scalar($o->opt), $expect, 'getopt ' . ++$count)
      or diag explain scalar $o->opt;
}
