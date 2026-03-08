use strict;
use warnings;
use EV;
use EV::Future;
use EV::Hiredis;
use feature 'say';

# Initialize Redis client
my $redis = EV::Hiredis->new(
    host => '127.0.0.1',
    port => 6379,
    on_error => sub {
        warn "Redis error: @_";
    }
);

my @keys = map { "key:$_" } 1..5;

say "Setting keys in parallel...";
parallel([
    map {
        my $key = $_;
        sub {
            my $done = shift;
            $redis->set($key, "value_for_$key", sub {
                my ($res, $err) = @_;
                say "  Set $key: " . ($err // 'OK');
                $done->();
            });
        }
    } @keys
], sub {
    say "All SET operations finished.";
    
    say "Getting keys in parallel...";
    my %results;
    parallel([
        map {
            my $key = $_;
            sub {
                my $done = shift;
                $redis->get($key, sub {
                    my ($val, $err) = @_;
                    $results{$key} = $val // "ERROR: $err";
                    say "  Got $key";
                    $done->();
                });
            }
        } @keys
    ], sub {
        say "All GET operations finished.";
        foreach my $key (sort keys %results) {
            say "  $key => $results{$key}";
        }
        EV::break;
    });
});

EV::run;
