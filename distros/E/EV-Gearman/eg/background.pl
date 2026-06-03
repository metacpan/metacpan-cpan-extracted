#!/usr/bin/perl
# Background submission: fire-and-forget but keep the handle for status.
use strict;
use warnings;
use EV;
use EV::Gearman;

my $g = EV::Gearman->new(host => '127.0.0.1', port => 4730);

my $handle;
$g->submit_job_bg('expensive_job', "payload", sub {
    my ($h, $err) = @_;
    if ($err) { die "submit failed: $err" }
    $handle = $h;
    print "queued: handle=$h\n";

    # Poll status a couple of times
    my $tries = 5;
    my $w; $w = EV::timer 0.5, 0.5, sub {
        $g->get_status($handle, sub {
            my ($info) = @_;
            printf "  known=%s running=%s %s/%s\n",
                $info->{known}, $info->{running},
                $info->{numerator}, $info->{denominator};
            if (!$info->{known} || --$tries <= 0) {
                undef $w;
                EV::break;
            }
        });
    };
});

EV::run;
