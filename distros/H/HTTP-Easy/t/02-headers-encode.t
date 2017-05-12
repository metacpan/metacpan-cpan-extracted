#!/usr/bin/perl

use strict;
use lib::abs '../lib';
use Test::More tests => 13;

my $mod = 'HTTP::Easy::Headers';
{no strict; ${$mod.'::NO_XS'} = 1;}
use_ok $mod;

my $hdr;
my $h = {
	connection => 'close',
	ExPeCt => 'continue-100',
	'content-type' => 'text/html',
	date => undef,
};

# Static method

$hdr = $mod->encode($h);
my @lines = split /\015\012/, $hdr;

is 0+@lines, 3, '3 lines' or diag $hdr;
ok + (1 == grep { $_ eq 'Connection: close' } @lines), 'connection' or diag $hdr;
ok + (1 == grep { $_ eq 'Expect: continue-100' } @lines), 'expect' or diag $hdr;
ok + (1 == grep { $_ eq 'Content-type: text/html' } @lines), 'content-type' or diag $hdr;

# Static method on object

$h = $mod->new($h);

$hdr = $mod->encode($h);
my @lines = split /\015\012/, $hdr;

is 0+@lines, 3, '3 lines' or diag $hdr;
ok + (1 == grep { $_ eq 'Connection: close' } @lines), 'connection' or diag $hdr;
ok + (1 == grep { $_ eq 'Expect: continue-100' } @lines), 'expect' or diag $hdr;
ok + (1 == grep { $_ eq 'Content-type: text/html' } @lines), 'content-type' or diag $hdr;

# Object method

$hdr = $h->encode();
my @lines = split /\015\012/, $hdr;

is 0+@lines, 3, '3 lines' or diag $hdr;
ok + (1 == grep { $_ eq 'Connection: close' } @lines), 'connection' or diag $hdr;
ok + (1 == grep { $_ eq 'Expect: continue-100' } @lines), 'expect' or diag $hdr;
ok + (1 == grep { $_ eq 'Content-type: text/html' } @lines), 'content-type' or diag $hdr;
