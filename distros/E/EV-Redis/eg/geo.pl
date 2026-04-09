#!/usr/bin/env perl
use strict;
use warnings;
use EV::Redis;

$| = 1;

my $redis = EV::Redis->new(
    host     => '127.0.0.1',
    on_error => sub { warn "Redis error: @_\n" },
);

my $key = 'places';

# Add locations (longitude, latitude, name)
my @places = (
    [-73.9857, 40.7484, 'empire_state'],
    [-73.9712, 40.7831, 'central_park'],
    [-74.0445, 40.6892, 'statue_of_liberty'],
    [-73.9680, 40.7614, 'moma'],
    [-73.9855, 40.7580, 'times_square'],
);

my $added = 0;
for my $p (@places) {
    $redis->geoadd($key, $p->[0], $p->[1], $p->[2], sub {
        if (++$added == @places) {
            query_nearby();
        }
    });
}

sub query_nearby {
    # Distance between two landmarks
    $redis->geodist($key, 'empire_state', 'central_park', 'km', sub {
        my ($dist, $err) = @_;
        printf "Empire State -> Central Park: %s km\n", $dist;

        # Places within 5km of Times Square
        $redis->geosearch($key, 'FROMMEMBER', 'times_square',
            'BYRADIUS', 5, 'km', 'ASC', 'WITHDIST', sub {
            my ($res, $err) = @_;
            if ($err) {
                # GEOSEARCH requires Redis >= 6.2; fall back to GEORADIUS
                $redis->georadiusbymember($key, 'times_square', 5, 'km',
                    'ASC', 'WITHDIST', sub {
                    my ($res, $err) = @_;
                    die "GEO query failed: $err\n" if $err;
                    print_nearby($res);
                });
                return;
            }
            print_nearby($res);
        });
    });
}

sub print_nearby {
    my ($res) = @_;
    print "\nWithin 5km of Times Square:\n";
    for my $entry (@$res) {
        printf "  %-20s %.2f km\n", $entry->[0], $entry->[1];
    }
    $redis->del('places', sub { $redis->disconnect });
}

EV::run;
