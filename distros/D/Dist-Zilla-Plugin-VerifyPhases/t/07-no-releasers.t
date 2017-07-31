use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;

my @tests = (
    [
        name => 'standard Dist::Zilla failure with no releasers',
        config => [],
        exception => qr/^you can't release without any Releaser plugins/,
    ],
    [
        name => 'only [VerifyPhases] - mimic standard check',
        config => [
            [ VerifyPhases => ],
        ],
        exception => qr/^you can't release without any Releaser plugins/,
    ],
    [
        name => '[VerifyPhases] and another releaser - release is ok',
        config => [
            [ FakeRelease => ],
            [ VerifyPhases => ],
        ],
        exception => undef,
    ],
);

foreach my $test (@tests)
{
    my %params = @$test;
    note ''; note $params{name};

    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    @{ $params{config} },
                ),
            },
        },
    );

    if ($params{exception})
    {
        like(
            exception { $tzil->release },
            $params{exception},
            'release failed',
        );
    }
    else
    {
        is(
            exception { $tzil->release },
            undef,
            'release succeeded',
        );
    }
}

done_testing;
