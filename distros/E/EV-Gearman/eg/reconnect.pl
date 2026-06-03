#!/usr/bin/perl
# Worker that auto-reconnects: kill gearmand and restart it; the worker
# re-registers its functions and resumes the GRAB loop automatically.
use strict;
use warnings;
use EV;
use EV::Gearman;

my $g = EV::Gearman->new(
    host                  => '127.0.0.1',
    port                  => 4730,
    reconnect             => 1,
    reconnect_delay       => 500,
    max_reconnect_attempts => 0,   # unlimited
    keepalive             => 30,
    on_connect            => sub { warn "connected\n" },
    on_disconnect         => sub { warn "disconnected\n" },
    on_error              => sub { warn "error: @_\n" },
);

$g->register_function(echo => sub { $_[0]->workload });
$g->work;

EV::run;
