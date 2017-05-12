#!/usr/bin/perl
use strict;
use warnings;

use Hook::Output::Tiny;
use Test::More;

my $h = Hook::Output::Tiny->new;

$h->hook;

print "**** out 1\n";
warn "***** err 1\n";

$h->unhook;

my @out = $h->stdout;
my @err = $h->stderr;

is (@out, 1, "stdout redir ok with both");
is (@err, 1, "stderr redir ok with both");

$h->hook;

$h->unhook('stdout');

print "out normal\n";

@out = $h->stdout;
is (@out, 1, "unhooking stdout ok");

$h->hook('stdout');

print "out 2\n";

$h->unhook('stdout');

@out = $h->stdout;
is (@out, 2, "re-hooking stdout ok");

{
    my $warn;
    local $SIG{__WARN__} = sub {$warn = shift;};

    $h->unhook('stderr');

    warn "unhooked stderr";

    @err = $h->stderr;
    is (@err, 1, "unhooking stderr ok");
}

$h->hook('stderr');

warn "err 2\n";

$h->unhook;

{
    my $warn;
    local $SIG{__WARN__} = sub {$warn = shift;};
    warn "err 3";
    print "out 3\n";

    @out = $h->stdout;
    @err = $h->stderr;
}

is (@err, 2, "unhooking both stderr ok");
is (@out, 2, "unhooking both stdout ok");

done_testing();
