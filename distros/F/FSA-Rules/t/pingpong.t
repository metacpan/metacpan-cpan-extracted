#!/usr/bin/perl -w

use strict;
use Test::More tests => 16;
#use Test::More 'no_plan';

BEGIN { use_ok('FSA::Rules') }

my @msgs;

ok my $fsa = FSA::Rules->new(
    ping => {
        on_enter => sub { push @msgs, "Entering ping\n" },
        do       => [ sub { push @msgs, "ping!\n" },
                      sub { shift->machine->{goto} = 'pong'; },
                      sub { shift->machine->{count}++ }
                  ],
        on_exit  => sub { push @msgs, "Exiting ping\n" },
        rules     => [
            pong => sub { shift->machine->{goto} eq 'pong' },
        ],
    },

    pong => {
        on_enter => [ sub { push @msgs, "Entering pong\n" },
                      sub { shift->machine->{goto} = 'ping' } ],
        do       => sub { push @msgs, "pong!\n"; },
        on_exit  => sub { push @msgs, "Exiting pong\n" },
        rules     => [
            ping => [ sub { shift->machine->{goto} eq 'ping' },
                      sub { push @msgs, "pong to ping\n" },
                      sub { $_[0]->machine->done($_[0]->machine->{count} == 5 ) },
                  ],
        ],
    },
), "Create the ping pong FSA machine";

ok my $state = $fsa->start, "Start the game";
isa_ok $state, 'FSA::State';
is $state->name, 'ping';
is $fsa->switch, $fsa->curr_state, "Number $fsa->{count}: " . $fsa->curr_state->name
  until $fsa->done;
my @check = <DATA>;
is_deeply \@msgs, \@check, "Check that the messages are in the right order";

__DATA__
Entering ping
ping!
Exiting ping
Entering pong
pong!
Exiting pong
pong to ping
Entering ping
ping!
Exiting ping
Entering pong
pong!
Exiting pong
pong to ping
Entering ping
ping!
Exiting ping
Entering pong
pong!
Exiting pong
pong to ping
Entering ping
ping!
Exiting ping
Entering pong
pong!
Exiting pong
pong to ping
Entering ping
ping!
Exiting ping
Entering pong
pong!
Exiting pong
pong to ping
Entering ping
ping!
