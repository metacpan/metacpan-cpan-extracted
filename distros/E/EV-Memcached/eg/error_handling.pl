#!/usr/bin/env perl
use strict;
use warnings;
use EV::Memcached;

$| = 1;

# Comprehensive error handling patterns.

my $mc = EV::Memcached->new(
    host     => $ENV{MC_HOST} // '127.0.0.1',
    port     => $ENV{MC_PORT} // 11211,
    on_error => sub {
        my ($msg) = @_;
        warn "connection error: $msg\n";
    },
    on_disconnect => sub {
        warn "disconnected\n";
    },
);

$mc->on_connect(sub { EV::break });
my $t = EV::timer 5, 0, sub { die "connect timeout" };
EV::run;
$mc->on_connect(undef);

# 1. Normal error: operation on non-existent key
print "--- 1. delete non-existent key ---\n";
$mc->delete("error_test_nonexistent", sub {
    my ($res, $err) = @_;
    if ($err) {
        print "  Expected error: $err\n";
    }
    EV::break;
});
EV::run;

# 2. Type mismatch: incr on non-numeric value
print "\n--- 2. incr on non-numeric ---\n";
$mc->set("error_test_str", "hello", sub {
    $mc->incr("error_test_str", 1, sub {
        my ($val, $err) = @_;
        if ($err) {
            print "  Expected error: $err\n";
        }
        EV::break;
    });
});
EV::run;

# 3. Key too long
print "\n--- 3. key too long ---\n";
eval { $mc->set("x" x 251, "val") };
if ($@) {
    chomp(my $msg = $@);
    print "  Expected croak: $msg\n";
}

# 4. add existing key
print "\n--- 4. add existing key ---\n";
$mc->set("error_test_exists", "val", sub {
    $mc->add("error_test_exists", "val2", sub {
        my ($res, $err) = @_;
        if ($err) {
            print "  Expected error: $err\n";
        }
        EV::break;
    });
});
EV::run;

# 5. replace non-existent key
print "\n--- 5. replace non-existent ---\n";
$mc->delete("error_test_noreplace", sub {
    $mc->replace("error_test_noreplace", "val", sub {
        my ($res, $err) = @_;
        if ($err) {
            print "  Expected error: $err\n";
        }
        EV::break;
    });
});
EV::run;

# 6. CAS with stale token
print "\n--- 6. CAS conflict ---\n";
$mc->set("error_test_cas", "v1", sub {
    $mc->gets("error_test_cas", sub {
        my ($result, $err) = @_;
        my $cas = $result->{cas};

        # Modify behind CAS's back
        $mc->set("error_test_cas", "v2", sub {
            # Now try CAS with stale token
            $mc->cas("error_test_cas", "v3", $cas, sub {
                my ($res, $err) = @_;
                if ($err) {
                    print "  Expected error: $err\n";
                }
                EV::break;
            });
        });
    });
});
EV::run;

# 7. GET miss (not an error)
print "\n--- 7. GET miss ---\n";
$mc->get("error_test_definitely_missing_xyz", sub {
    my ($val, $err) = @_;
    if (!defined $val && !defined $err) {
        print "  Miss: value=undef, err=undef (correct)\n";
    }
    EV::break;
});
EV::run;

print "\nAll error scenarios handled.\n";
$mc->disconnect;
