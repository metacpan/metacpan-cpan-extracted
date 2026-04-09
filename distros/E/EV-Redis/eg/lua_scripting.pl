#!/usr/bin/env perl
use strict;
use warnings;
use EV::Redis;

$| = 1;

my $redis = EV::Redis->new(
    host     => '127.0.0.1',
    on_error => sub { warn "Redis error: @_\n" },
);

# Atomic compare-and-swap via Lua
my $cas_script = <<'LUA';
if redis.call('GET', KEYS[1]) == ARGV[1] then
    redis.call('SET', KEYS[1], ARGV[2])
    return 1
else
    return 0
end
LUA

$redis->set('balance', '100', sub {
    my ($res, $err) = @_;

    # Try CAS: set balance to 80 only if current value is 100
    $redis->eval($cas_script, 1, 'balance', '100', '80', sub {
        my ($ok, $err) = @_;
        die "EVAL failed: $err\n" if $err;
        print "CAS 100->80: " . ($ok ? "success" : "failed") . "\n";

        # Try again — should fail since balance is now 80
        $redis->eval($cas_script, 1, 'balance', '100', '60', sub {
            my ($ok, $err) = @_;
            die "EVAL failed: $err\n" if $err;
            print "CAS 100->60: " . ($ok ? "success" : "failed") . "\n";

            $redis->get('balance', sub {
                my ($val, $err) = @_;
                print "Final balance: $val\n";
                $redis->del('balance', sub { $redis->disconnect });
            });
        });
    });
});

EV::run;
