use strict;
use warnings;
use utf8;
use Test::More;

use Localizer::Resource;

subtest 'Enable precompiling' => sub {
    my $localizer = Localizer::Resource->new(
        dictionary => +{
            'foo' => 'bar',
        },
        precompile => 1,
    );
    ok $localizer->{compiled}->{foo}, 'Precompiled';
};

subtest 'Not precompile' => sub {
    my $localizer = Localizer::Resource->new(
        dictionary => +{
            'foo' => 'bar',
        },
        precompile => 0,
    );
    ok !$localizer->{compiled}->{foo}, 'Not precompiled';
};

done_testing;

