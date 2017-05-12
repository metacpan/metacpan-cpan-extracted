#! /usr/bin/perl
# $Id: 05_condvar.t,v 1.6 2009/01/08 15:23:27 dk Exp $

use strict;
use warnings;
use Time::HiRes qw(time);
use Test::More tests => 5;
use IO::Lambda qw(:lambda);

package PseudoLoop;

sub yield  { 0 }
sub remove { $_[0]-> {q} = $_[1] }
sub new    { bless {}, shift  }

package main;

my $q    = IO::Lambda-> new;
my $cond = $q-> bind;
my $q2   = lambda {
	context 0.1;
	ok( not( $q-> is_stopped), 'bind');
	timeout { $q-> resolve($cond) }
};
$q2-> start;
$q-> wait;
ok( $q-> is_stopped, 'resolve');

my $loop = PseudoLoop-> new;

IO::Lambda::add_loop( $loop );

$q-> reset;
$q-> bind;
$q-> reset;
ok(( defined($loop-> {q}) and ( $loop->{q} eq $q)), 'custom event loop');
ok( $q-> is_passive, 'reset with custom loop');

IO::Lambda::remove_loop( $loop);
$q-> bind;
$q-> reset;
ok( $q-> is_passive, 'reset without custom loop');
