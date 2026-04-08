#!/usr/bin/env perl
use strict;
use warnings;
use EV::Memcached;

$| = 1;

# N workers each acquire a unique ID (0..65534) via ADD-based slot claiming.
# Round-robin: each worker tries ADD on "wid:<id>" — first to succeed owns it.
# Uses a shared cursor with CAS to advance the next-ID pointer atomically.
#
# Pattern:
#   1. GETS "wid:cursor" to read current candidate + CAS token
#   2. ADD "wid:<candidate>" to claim the slot (atomic, fails if taken)
#   3. CAS "wid:cursor" to advance pointer (retry on contention)

my $n_workers  = 8;
my $max_id     = 65535;  # unsigned short range: 0..65534

my @workers;   # (mc, assigned_id) pairs
my $done = 0;

# Each worker gets its own connection (simulating separate processes)
for my $w (1 .. $n_workers) {
    my $mc = EV::Memcached->new(
        host     => $ENV{MC_HOST} // '127.0.0.1',
        port     => $ENV{MC_PORT} // 11211,
        on_error => sub { warn "worker $w error: @_\n" },
    );
    push @workers, { mc => $mc, id => undef, num => $w };
}

# Wait for all connections
my $connected = 0;
for my $wk (@workers) {
    $wk->{mc}->on_connect(sub {
        if (++$connected == $n_workers) {
            init_and_start();
        }
    });
}

sub init_and_start {
    # Initialize cursor to 0 (delete first to reset)
    my $mc0 = $workers[0]{mc};
    $mc0->delete("wid:cursor", sub {
        $mc0->set("wid:cursor", "0", sub {
            # Clean up any previous slots
            for my $id (0 .. $n_workers + 2) {
                $mc0->delete("wid:$id");
            }
            $mc0->noop(sub {
                # All workers start claiming simultaneously
                acquire_id($_) for @workers;
            });
        });
    });
}

sub acquire_id {
    my ($wk) = @_;
    my $mc = $wk->{mc};
    my $w  = $wk->{num};

    # Step 1: read cursor with CAS
    $mc->gets("wid:cursor", sub {
        my ($result, $err) = @_;
        if ($err || !$result) {
            warn "worker $w: cursor read failed: $err\n";
            return;
        }

        my $candidate = $result->{value} + 0;
        my $cas       = $result->{cas};

        # Step 2: try to claim this slot
        $mc->add("wid:$candidate", $$, 300, sub {
            my ($res, $add_err) = @_;

            if ($add_err) {
                # Slot taken by another worker — retry
                acquire_id($wk);
                return;
            }

            # Step 3: advance cursor atomically via CAS
            my $next = ($candidate + 1) % $max_id;
            $mc->cas("wid:cursor", "$next", $cas, sub {
                my ($res, $cas_err) = @_;
                # CAS failure is OK — another worker advanced it.
                # Our slot is already claimed via ADD.
            });

            # Claimed!
            $wk->{id} = $candidate;
            printf "Worker %2d => ID %d\n", $w, $candidate;

            if (++$done == $n_workers) {
                finish();
            }
        });
    });
}

sub finish {
    print "\nAll workers assigned:\n";
    for my $wk (sort { $a->{id} <=> $b->{id} } @workers) {
        printf "  Worker %2d => ID %d\n", $wk->{num}, $wk->{id};
    }

    # Verify uniqueness
    my %seen;
    $seen{$_->{id}}++ for @workers;
    my @dups = grep { $seen{$_} > 1 } keys %seen;
    if (@dups) {
        printf "\nERROR: duplicate IDs: %s\n", join(', ', @dups);
    } else {
        printf "\nAll %d IDs unique (range 0..%d)\n", $n_workers, $max_id - 1;
    }

    $_->{mc}->disconnect for @workers;
}

EV::run;
