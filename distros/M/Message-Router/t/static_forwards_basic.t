#!env perl

use strict;use warnings;
use Data::Dumper;

use lib '../lib';
use Test::More;

use_ok('Message::Router', 'mroute', 'mroute_config');


my $message = {
    a => 'b',
    static_forwards => [
        [   {   transform => {
                    hi => 'there'
                },
                forward => {
                    handler => 'main::h1',
                    qname => 'q1',
                    destination => 'd1',
                },
                log_history => 1,
            }
        ]
    ],
};

$main::returns = {};

sub main::h1 {
    my %args = @_;
    #expects
    # $args{message}
    # $args{route}
    # $args{routes}
    # $args{forward}
    $main::returns = \%args;
}
my $config = {
    routes => {
        1 => {
            match => {
                a => 'b',
            },
            forwards => [
                {   handler => 'main::h1',
                    x => 'y',
                },
            ],
            transform => {
                this => 'foo',
            },
        },
        10 => {
            match => {
                a => 'b',
            },
            forwards => [
                {   handler => 'main::h1',
                    x => 'y',
                },
            ],
            transform => {
                this => 'that',
            },
        }
    },
};

ok ((not scalar keys %$main::returns), 'make sure returns starts blank');
ok mroute_config($config), 'set config';
ok mroute($message), 'simplest possible';
ok $main::returns->{message}, 'message set';
ok $main::returns->{message}->{a} eq 'b', 'pass-through valid';
ok !$main::returns->{message}->{this}, 'verify configure rules did not transform';
ok !$main::returns->{route}, 'route not set';
ok $main::returns->{message}->{hi} eq 'there', 'transform correct';
ok !$main::returns->{message}->{static_forwards}, 'forwards structure is gone';
ok $main::returns->{forward}->{qname} eq 'q1', 'correct qname set';
ok $main::returns->{forward}->{destination} eq 'd1', 'correct destination set';
ok $main::returns->{message}->{'.static_forwards_log'}, 'static forwards log structure exists';
ok $main::returns->{message}->{'.static_forwards_log'}->{forward_history}, 'static forwards log forward_history exists';
ok my $h = $main::returns->{message}->{'.static_forwards_log'}->{forward_history}->[0], 'static forwards log forward_history first element exists';
#ok $main::returns->{message}->{'.static_forwards_log'}->{forward_history}->[0]->{, 'static forwards log forward_history first element exists';
ok $h->{transform}, 'forwards_log: transform exists';
ok $h->{transform}->{hi}, 'forwards_log: transform specifics exists';
ok $h->{forward}, 'forwards_log: forward exists';
ok $h->{forward}->{qname}, 'forwards_log: forward specifics exist';
done_testing();
