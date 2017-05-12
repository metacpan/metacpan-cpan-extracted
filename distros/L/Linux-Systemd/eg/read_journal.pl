#!/usr/bin/env perl

use v5.10.1;
use strict;
use warnings;
use Linux::Systemd::Journal::Read;

my $jnl = Linux::Systemd::Journal::Read->new;

sub dump_messages {
    my $i = 0;
    while (my $entry = $jnl->get_next_entry) {
        for my $key (sort keys %$entry) {
            say "$key: " . $entry->{$key};
        }
        say '-' x 40;
        last if $i++ == 5;    # limit for the example
    }
}
my $bytes = $jnl->get_usage;
say "Journal size: $bytes bytes";

$jnl->seek_head;
$jnl->next;

say 'MESSAGE: ' . $jnl->get_data('MESSAGE');
say '_EXE: ' . $jnl->get_data('_EXE');

## try filtering on priority
$jnl->match(priority => 2);
say "Showing on priority=2";
dump_messages;
$jnl->flush_matches;

$jnl->match(_systemd_unit => 'gdm.service');
say "Showing gdm.service";
dump_messages;
$jnl->flush_matches;

say 'x' x 24;
$jnl->match(priority => 6, _systemd_unit => 'packagekit.service');
$jnl->match_or(priority => 7);

# $jnl->match_or(_pid => 25811);
dump_messages;
