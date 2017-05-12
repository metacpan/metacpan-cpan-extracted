use strict;
use warnings;
use utf8;
use Test::More;
use Distribution::Metadata;
use Distribution::Metadata::Factory;

my $factory = Distribution::Metadata::Factory->new;

my @module = qw(
    Plack Plack::Request Moose::Util
    Ooops App::cpanminus strict warnings
    JSON::PP::Boolean JSON::XS common::sense
    LWP::UserAgent FindBin LWP Amon2::Util
);

for my $module (@module) {
    my $info1 = Distribution::Metadata->new_from_module($module);
    my $info2 = $factory->create_from_module($module);
    for my $method (qw(packlist install_json mymeta_json name author)) {
        is $info1->$method, $info2->$method, "$method check";
    }
}

done_testing;
