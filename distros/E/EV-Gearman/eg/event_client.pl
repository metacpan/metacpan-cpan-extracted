#!/usr/bin/perl
# Foreground client that consumes intermediate WORK_DATA / WORK_STATUS /
# WORK_WARNING events. Pair with eg/async_worker.pl.
use strict;
use warnings;
use EV;
use EV::Gearman;

my $g = EV::Gearman->new(host => '127.0.0.1', port => 4730);

$g->submit_job('slow_echo', "hello", {
    on_data    => sub { print "  data:    $_[0]\n" },
    on_warning => sub { print "  warn:    $_[0]\n" },
    on_status  => sub { printf "  status:  %s/%s\n", @_ },
}, sub {
    my ($result, $err) = @_;
    if ($err) { warn "fail: $err\n" }
    else      { print "result: $result\n" }
    EV::break;
});

EV::run;
