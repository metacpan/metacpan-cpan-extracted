#!/usr/bin/env perl
use strict;
use warnings;
use EV::Redis;

$| = 1;

my $redis = EV::Redis->new(
    host     => '127.0.0.1',
    on_error => sub { warn "Redis error: @_\n" },
);

# Bitmaps: track daily active users and feature flags

# Mark users as active today (user_id = bit offset)
my @active_mon = (1, 3, 5, 7, 10, 42, 100);
my @active_tue = (1, 2, 5, 8, 10, 42);

my $set = 0;
my $total = @active_mon + @active_tue;

for my $uid (@active_mon) {
    $redis->setbit('active:mon', $uid, 1, sub {
        report() if ++$set == $total;
    });
}
for my $uid (@active_tue) {
    $redis->setbit('active:tue', $uid, 1, sub {
        report() if ++$set == $total;
    });
}

sub report {
    $redis->bitcount('active:mon', sub {
        my ($n) = @_;
        print "Monday active:  $n users\n";

        $redis->bitcount('active:tue', sub {
            my ($n) = @_;
            print "Tuesday active: $n users\n";

            # Users active BOTH days (AND)
            $redis->bitop('AND', 'active:both', 'active:mon', 'active:tue', sub {
                $redis->bitcount('active:both', sub {
                    my ($n) = @_;
                    print "Both days:      $n users\n";

                    # Users active EITHER day (OR)
                    $redis->bitop('OR', 'active:any', 'active:mon', 'active:tue', sub {
                        $redis->bitcount('active:any', sub {
                            my ($n) = @_;
                            print "Either day:     $n users\n";

                            # Check specific user
                            $redis->getbit('active:mon', 42, sub {
                                my ($bit) = @_;
                                print "\nUser 42 active Monday: " . ($bit ? "yes" : "no") . "\n";
                                $redis->del('active:mon', 'active:tue', 'active:both', 'active:any',
                                    sub { $redis->disconnect });
                            });
                        });
                    });
                });
            });
        });
    });
}

EV::run;
