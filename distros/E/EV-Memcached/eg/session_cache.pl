#!/usr/bin/env perl
use strict;
use warnings;
use EV::Memcached;

$| = 1;

# Practical example: session cache with expiration.
# Demonstrates set with expiry, get, touch (extend TTL), and delete.

my $mc = EV::Memcached->new(
    host     => $ENV{MC_HOST} // '127.0.0.1',
    port     => $ENV{MC_PORT} // 11211,
    on_error => sub { warn "error: @_\n" },
);

my $session_id   = "sess:" . int(rand(100000));
my $session_data = '{"user":"alice","role":"admin","login_at":' . time() . '}';
my $ttl          = 30; # 30 seconds

print "Session cache demo\n";
print "Session: $session_id\n\n";

# Create session with TTL
$mc->set($session_id, $session_data, $ttl, sub {
    my ($res, $err) = @_;
    die "create session: $err" if $err;
    print "1. Created session (TTL=${ttl}s)\n";

    # Read session
    $mc->gets($session_id, sub {
        my ($result, $err) = @_;
        die "read session: $err" if $err;
        printf "2. Read session: %s (flags=%d, cas=%d)\n",
            $result->{value}, $result->{flags}, $result->{cas};

        # Extend TTL without fetching (touch)
        $mc->touch($session_id, 60, sub {
            my ($res, $err) = @_;
            die "touch: $err" if $err;
            print "3. Extended TTL to 60s\n";

            # Get-and-touch: read + extend in one call
            $mc->gat($session_id, 120, sub {
                my ($val, $err) = @_;
                die "gat: $err" if $err;
                print "4. GAT: $val (TTL now 120s)\n";

                # Destroy session (logout)
                $mc->delete($session_id, sub {
                    my ($res, $err) = @_;
                    die "delete: $err" if $err;
                    print "5. Deleted session (logout)\n";

                    # Verify gone
                    $mc->get($session_id, sub {
                        my ($val, $err) = @_;
                        print "6. Verify: ",
                            defined($val) ? "still exists!" : "gone (correct)",
                            "\n";
                        $mc->disconnect;
                    });
                });
            });
        });
    });
});

EV::run;
