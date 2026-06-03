#!/usr/bin/perl
# EV::Gearman works inside AnyEvent applications when EV is loaded first
# (or installed as the AnyEvent backend).
use strict;
use warnings;
use EV;
use AnyEvent;
use EV::Gearman;

my $cv = AE::cv;
my $g  = EV::Gearman->new(host => '127.0.0.1', port => 4730);

$g->submit_job(reverse => "AnyEvent", sub {
    my ($r, $e) = @_;
    if ($e) { warn $e } else { print "result: $r\n" }
    $cv->send;
});

$cv->recv;
