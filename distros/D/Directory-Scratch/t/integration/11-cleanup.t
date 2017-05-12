#!/usr/bin/perl
# 11-cleanup.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>


use strict;
use warnings;
use Test::More tests=>8;
use Directory::Scratch;
use File::Path;

my $tmp = Directory::Scratch->new;
isa_ok($tmp, 'Directory::Scratch');
my $base_1 = $tmp->base;
$tmp->touch('foo');
ok(-e $base_1);
undef $tmp;
diag("Manually verify that $base_1 got cleaned up.");

$tmp = Directory::Scratch->new;
isa_ok($tmp, 'Directory::Scratch');
my $base = $tmp->base;
ok(-e $base);
$tmp->cleanup;
ok(!-e $base, 'explicitly cleaned up OK'); 

$tmp = Directory::Scratch->new(CLEANUP => 0);
isa_ok($tmp, 'Directory::Scratch');
$base = $tmp->base;
$SIG{__WARN__} = sub {};
ok(-e $base);
undef $tmp;
File::Path::rmtree($base->stringify, 0, 1);
ok(!-e $base, 'cleaned up manually OK');

