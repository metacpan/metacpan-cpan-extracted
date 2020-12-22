#!/usr/bin/perl
use strict;
use warnings;

use Hook::Output::Tiny;
use Test::More;

my $mod = 'Hook::Output::Tiny';
my $h = $mod->new;

$h->hook('stderr');

$h->stdout;
$h->stderr;

$h->unhook('stderr');

my @stderr = $h->stderr;

like
    $stderr[0],
    qr/\Qstdout() in non-list context\E/,
    "we warn if stdout() is called in non-list context ok";

like
    $stderr[1],
    qr/\Qstderr() in non-list context\E/,
    "we warn if stderr() is called in non-list context ok";

done_testing();

