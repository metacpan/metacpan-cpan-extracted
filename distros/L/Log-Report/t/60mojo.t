#!/usr/bin/env perl
# Test MojoX::Log::Report

use warnings;
use strict;
use lib 'lib', '../lib';

use Test::More;
use Log::Report undef;

use Data::Dumper;

BEGIN
{   eval "require Mojolicious";
    plan skip_all => 'Mojolicious is not installed'
        if $@;

    plan skip_all => 'installed Mojolicious too old (requires 2.16)'
        if $Mojolicious::VERSION < 2.16;
    plan tests => 7;
}

use_ok('MojoX::Log::Report');

my $log = MojoX::Log::Report->new;
isa_ok($log, 'MojoX::Log::Report');
isa_ok($log, 'Mojo::Log');

my $tmp;
dispatcher close => 'default';
try { $log->error("going to die"); $tmp = 42 } mode => 3;
my $err = $@;
#warn Dumper $err;

cmp_ok($tmp, '==', 42, 'errors not cast directly');
ok($err->success, 'block continued succesfully');

my @exc = $err->exceptions;
cmp_ok(scalar @exc, '==', 1, "caught 1");
is("$exc[0]", "error: going to die\n");
