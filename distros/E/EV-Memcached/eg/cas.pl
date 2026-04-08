#!/usr/bin/env perl
use strict;
use warnings;
use EV::Memcached;

$| = 1;

# Compare-and-swap (CAS): atomic read-modify-write pattern.
# 1. gets() returns value + CAS token
# 2. cas() stores new value only if CAS token matches
# 3. If another client modified the key, CAS fails with EXISTS

my $mc = EV::Memcached->new(
    host     => $ENV{MC_HOST} // '127.0.0.1',
    port     => $ENV{MC_PORT} // 11211,
    on_error => sub { warn "error: @_\n" },
);

# Initialize a counter
$mc->set('cas_counter', '0', sub {
    my ($res, $err) = @_;
    die "SET failed: $err" if $err;
    print "Initialized cas_counter = 0\n";

    # Read with CAS
    $mc->gets('cas_counter', sub {
        my ($result, $err) = @_;
        die "GETS failed: $err" if $err;

        my $val = $result->{value};
        my $cas = $result->{cas};
        printf "GETS: value=%s, flags=%d, cas=%d\n",
            $val, $result->{flags}, $cas;

        # Increment and write back atomically
        my $new_val = $val + 1;
        $mc->cas('cas_counter', "$new_val", $cas, sub {
            my ($res, $err) = @_;
            if ($err) {
                print "CAS failed (concurrent modification?): $err\n";
            } else {
                print "CAS succeeded: cas_counter = $new_val\n";
            }

            # Try CAS with a stale token (should fail)
            $mc->cas('cas_counter', "999", $cas, sub {
                my ($res, $err) = @_;
                if ($err) {
                    print "CAS with stale token correctly failed: $err\n";
                } else {
                    print "Unexpected: CAS with stale token succeeded\n";
                }

                $mc->disconnect;
            });
        });
    });
});

EV::run;
