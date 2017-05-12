#!/usr/bin/env perl
use strict;
use warnings;
use IO::Pty::HalfDuplex;
use Test::More tests => 9;

####

my $pty = IO::Pty::HalfDuplex->new;

$pty->spawn("echo foo");

pass("spawn succeeded");

is($pty->recv, "foo\n", "Initial read came");

ok(!$pty->is_active, "echo foo exited quickly");

$pty->close;

pass("successfully closed an inactivated pty");

####

$pty = IO::Pty::HalfDuplex->new;

$pty->spawn('read REPLY; echo $REPLY');

is($pty->recv, "", "No text written before input");

ok($pty->is_active, "Slave is still running");

$pty->write("bar\n");

is($pty->recv, "bar\n", "Slave responded");

ok(!$pty->is_active, "and quit");

$pty->close;

pass("successfully closed a used pty");
