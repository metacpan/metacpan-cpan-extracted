#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark ':all';
use Distribution::Metadata;
use Distribution::Metadata::Factory;

my @module = qw(
    Plack Plack::Request Moose::Util
    Ooops App::cpanminus strict warnings
    JSON::PP::Boolean JSON::XS common::sense
    LWP::UserAgent FindBin LWP Amon2::Util
);

my $n = 5;
cmpthese 2, {
    normal => sub {
        for my $m ((@module) x $n) {
            Distribution::Metadata->new_from_module($m);
        }
    },
    factory => sub {
        my $factory = Distribution::Metadata::Factory->new;
        for my $m ((@module) x $n) {
            $factory->create_from_module($m);
        }
    },
};

__END__

s/iter  normal factory
normal    6.42      --    -93%
factory  0.455   1311%      --
