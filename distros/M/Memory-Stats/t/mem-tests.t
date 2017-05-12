#!perl
#
# This file is part of Memory-Stats
#
# This software is copyright (c) 2014 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use strict;
use warnings;
use Test::More;
use Test::Trap;
use Memory::Stats;
use DDP;

plan skip_all => "Skip Test, incompatible system !"
    if Memory::Stats->_get_current_memory_usage < 0;

my $mu = Memory::Stats->new;

ok !eval { $mu->stop;       1 }, 'we have to start first';
ok !eval { $mu->checkpoint; 1 }, 'we have to start first';

my %c;
my $delta_usage;

$mu->start;
%c = map { $_ => 1 } ( 1 .. 100_000 );
$delta_usage = $mu->delta_usage;
$mu->checkpoint('step1');

%c = map { $_ => 1 } ( 1 .. 200_000 );
ok $mu->delta_usage > $delta_usage, 'usage grow up';
$delta_usage = $mu->delta_usage;
$mu->checkpoint('step2');

%c = map { $_ => 1 } ( 1 .. 300_000 );
ok $mu->delta_usage > $delta_usage, 'usage grow up';
$delta_usage = $mu->delta_usage;

ok !eval { $mu->usage; 1 }, 'usage only usable after a stop';

$mu->stop;

like $mu->usage, qr/\d+/, 'usage ok';

ok !eval { $mu->stop;       1 }, 'we have to start first';
ok !eval { $mu->checkpoint; 1 }, 'we have to start first';

my $report = trap { $mu->report };
like $trap->stdout, qr{
start:\s\d+\n
step1:\s\d+\s\-\sdelta:\s\d+\s\-\stotal:\s\d+\n
step2:\s\d+\s\-\sdelta:\s\d+\s\-\stotal:\s\d+\n
stop:\s\d+\s\-\sdelta:\s\d+\s\-\stotal:\s\d+\n
}x, 'report ok';

done_testing;
