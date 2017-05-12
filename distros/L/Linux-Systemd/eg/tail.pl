#!/usr/bin/env perl

use v5.16.2;
use strictures;
use Time::Moment;
use Linux::Systemd::Journal::Read;

sub print_entry {
    my $entry = shift;
    if ($entry->{_SOURCE_REALTIME_TIMESTAMP}) {
        my $epoch_ms = $entry->{_SOURCE_REALTIME_TIMESTAMP};
        my $tm       = Time::Moment->from_epoch($epoch_ms / 1_000_000);
        print "$tm ";
    }

    say $entry->{MESSAGE} if $entry->{MESSAGE};
}

my $jnl = Linux::Systemd::Journal::Read->new;
$jnl->seek_tail;
$jnl->previous(10);
while (my $entry = $jnl->get_next_entry) {
    print_entry($entry);
}

while (1) {
    $jnl->wait;
    say "Done waiting";
    while (my $entry = $jnl->get_next_entry) {
        print_entry($entry);
    }
}
