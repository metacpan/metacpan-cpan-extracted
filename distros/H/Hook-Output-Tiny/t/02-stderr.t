#!/usr/bin/perl
use strict;
use warnings;

use Hook::Output::Tiny;
use Test::More;

my $mod = 'Hook::Output::Tiny';
{
    my $h = $mod->new;
    $h->hook('stderr');

    warn "test 1\n";
    warn "test 2\n";

    $h->unhook('stderr');

    my @err = $h->stderr;

    is ($err[0], "test 1", "stderr hook/unhook works line 1");
    is ($err[1], "test 2", "stderr hook/unhook works line 2");

    $h->hook('stderr');

    warn "test 3\n";

    $h->unhook('stderr');

    @err = $h->stderr;

    is ($err[0], "test 1", "stderr re-hook works line 1");
    is ($err[1], "test 2", "stderr re-hook works line 2");
    is ($err[2], "test 3", "stderr re-hook works line 3");
}

done_testing();

