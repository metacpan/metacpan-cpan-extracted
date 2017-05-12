#!env perl

use strict;use warnings;

use lib '../lib';
use Test::More;

use_ok('Message::Router', 'mroute', 'mroute_config');

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
    routes => [
        {   match => {
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
    ],
};

ok ((not scalar keys %$main::returns), 'make sure returns starts blank');
ok mroute_config($config), 'set config';
ok mroute({a => 'b'}), 'simplest possible';
ok $main::returns->{message}, 'message set';
ok $main::returns->{message}->{a} eq 'b', 'pass-through valid';
ok $main::returns->{message}->{this} eq 'that', 'transform valid';
ok $main::returns->{route}, 'route set';
ok $main::returns->{route}->{transform}, 'transform inside of route set';
ok $main::returns->{route}->{transform}->{this} eq 'that', 'transform value inside of route set';

ok $main::returns->{forward}, 'forward set';
ok $main::returns->{forward}->{x} eq 'y', 'argument inside of forward set correctly';

done_testing();
