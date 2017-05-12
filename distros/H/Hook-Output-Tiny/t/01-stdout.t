#!/usr/bin/perl
use strict;
use warnings;

use Hook::Output::Tiny;
use Test::More;

my $mod = 'Hook::Output::Tiny';
{
    my $h = $mod->new;
    $h->hook('stdout');

    print "test 1\n";
    print "test 2\n";

    $h->unhook('stdout');

    my @out = $h->stdout;

    is ($out[0], "test 1", "stdout hook/unhook works line 1");
    is ($out[1], "test 2", "stdout hook/unhook works line 2");

    $h->hook('stdout');

    print "test 3\n";

    $h->unhook('stdout');

    @out = $h->stdout;

    is ($out[0], "test 1", "stdout re-hook works line 1");
    is ($out[1], "test 2", "stdout re-hook works line 2");
    is ($out[2], "test 3", "stdout re-hook works line 3");
}

done_testing();

