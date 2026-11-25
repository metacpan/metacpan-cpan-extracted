use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::Config;
use Developer::Dashboard::PathRegistry;
use JSON::XS ();

# rejected(%args)
# Calls the adapter with a malformed input and reports whether its error names
# the expected validation rule.
# Input: adapter arguments plus a regex and test description.
# Output: no value; adds one Test::More assertion.
sub rejected {
    my (%case) = @_;
    my $pattern = delete $case{pattern};
    my $name    = delete $case{name};
    my $ok = eval {
        Developer::Dashboard::SystemMenu->items_for_platform(%case);
        1;
    };
    ok( !$ok && $@ =~ $pattern, $name );
}

my $paths = Developer::Dashboard::PathRegistry->new;
my $config = Developer::Dashboard::Config->for_paths($paths);

my $merged = $config->_merge_hashes(
    {
        indicators => [
            {
                name      => 'build',
                indicator => { macos => 1, windows => 0 },
            },
        ],
    },
    {
        indicators => [
            {
                name      => 'build',
                indicator => { windows => 1 },
            },
            {
                name      => 'tests',
                indicator => { macos => 1 },
            },
        ],
    },
);

is_deeply(
    $merged->{indicators},
    [
        { name => 'build', indicator => { macos => 1, windows => 1 } },
        { name => 'tests', indicator => { macos => 1 } },
    ],
    'indicator platform settings merge by name and preserve inherited platform values',
);

{
    my $home = tempdir( CLEANUP => 1 );
    my $layered_paths = Developer::Dashboard::PathRegistry->new( home => $home );
    my $layered_config = Developer::Dashboard::Config->for_paths($layered_paths);
    my $global_file = $layered_config->_global_config_file;
    make_path( dirname($global_file) );
    open my $fh, '>:raw', $global_file or die "Unable to write $global_file: $!";
    print {$fh} JSON::XS->new->canonical->encode( { version => 1 } )
      or die "Unable to write config payload to $global_file: $!";
    close $fh or die "Unable to close $global_file: $!";
    my $loaded = $layered_config->load_global( skill_config_entries => [] );
    is_deeply( $loaded, { version => 1 },
        'global config without indicator entries remains unchanged when the optional system-menu section is absent' );

    open $fh, '>:raw', $global_file or die "Unable to write $global_file: $!";
    print {$fh} JSON::XS->new->canonical->encode( {
        indicators => [
            { name => 'build', indicator => { macos => 1 } },
            { name => 'build', indicator => { ubuntu => 1 } },
        ],
    } ) or die "Unable to write config payload to $global_file: $!";
    close $fh or die "Unable to close $global_file: $!";
    $loaded = $layered_config->load_global( skill_config_entries => [] );
    is_deeply(
        $loaded->{indicators},
        [ { name => 'build', indicator => { macos => 1, ubuntu => 1 } } ],
        'global indicator entries are normalized and merged by name when no skill config overlays them',
    );
}

my $module_loaded = eval { require Developer::Dashboard::SystemMenu; 1 };
ok( $module_loaded, 'SystemMenu adapter module loads without AppKit at compile time' )
  or diag($@ || 'module load failed without an exception');

SKIP: {
    skip 'SystemMenu adapter is not implemented yet', 5 if !$module_loaded;

    my @states = (
        { name => 'build', icon => '✅', status => 'ok' },
        { name => 'tests', icon => '❌', status => 'failed' },
        { name => 'hidden', icon => 'H', status => 'ok' },
    );
    my $valid_config = { indicators => [ { name => 'build', indicator => { macos => 1 } } ] };
    rejected(
        config => 'not-a-config', indicators => \@states, platform => 'macos',
        pattern => qr/config must be a hash reference/, name => 'non-hash config is rejected',
    );
    rejected(
        config => $valid_config, indicators => 'not-an-array', platform => 'macos',
        pattern => qr/indicators must be an array reference/, name => 'non-array state input is rejected',
    );
    rejected(
        config => $valid_config, indicators => \@states,
        pattern => qr/platform must be a non-empty string/, name => 'missing platform is rejected',
    );
    rejected(
        config => $valid_config, indicators => \@states, platform => [],
        pattern => qr/platform must be a non-empty string/, name => 'reference platform is rejected',
    );
    rejected(
        config => $valid_config, indicators => \@states, platform => '',
        pattern => qr/platform must be a non-empty string/, name => 'empty platform is rejected',
    );

    is_deeply(
        Developer::Dashboard::SystemMenu->items_for_platform(
            config => {}, indicators => \@states, platform => 'macos',
        ),
        [], 'missing indicator configuration produces an empty menu',
    );
    my $items = Developer::Dashboard::SystemMenu->items_for_platform(
        config     => $merged,
        indicators => \@states,
        platform   => 'macos',
    );

    is_deeply(
        $items,
        [
            { name => 'build', icon => '✅' },
            { name => 'tests', icon => '❌' },
        ],
        'macOS menu projection contains only enabled configured indicators and current icons',
    );

    is_deeply(
        Developer::Dashboard::SystemMenu->items_for_platform(
            config     => $merged,
            indicators => \@states,
            platform   => 'linux',
        ),
        [],
        'non-macOS platforms do not select the AppKit menu',
    );

    for my $platform (qw(windows ubuntu)) {
        my $platform_config = {
            indicators => [
                { name => 'build', indicator => { $platform => JSON::XS->new->decode('true') } },
                { name => 'tests', indicator => { $platform => 0 } },
            ],
        };
        is_deeply(
            Developer::Dashboard::SystemMenu->items_for_platform(
                config     => $platform_config,
                indicators => \@states,
                platform   => $platform,
            ),
            [ { name => 'build', icon => '✅' } ],
            "$platform menu projection selects enabled configured indicators",
        );
        is_deeply(
            $platform_config->{indicators}[0]{indicator}{$platform},
            JSON::XS->new->decode('true'),
            "$platform projection does not mutate the source configuration",
        );
        rejected(
            config => {
                indicators => [
                    { name => 'build', indicator => { $platform => 'yes' } },
                ],
            },
            indicators => \@states,
            platform   => $platform,
            pattern    => qr/\Q$platform\E selector must be boolean/,
            name       => "$platform selector rejects non-boolean values",
        );
    }

    is_deeply(
        Developer::Dashboard::SystemMenu->items_for_platform(
            config => {
                indicators => [
                    { name => 'build', indicator => { macos => JSON::XS->new->decode('true') } },
                ],
            },
            indicators => \@states,
            platform   => 'macos',
        ),
        [ { name => 'build', icon => '✅' } ],
        'JSON true boolean enables a macOS item',
    );

    is_deeply(
        Developer::Dashboard::SystemMenu->items_for_platform(
            config => {
                indicators => [
                    { name => 'build', indicator => { macos => JSON::XS->new->decode('false') } },
                ],
            },
            indicators => \@states,
            platform   => 'macos',
        ),
        [],
        'JSON false boolean disables a macOS item',
    );

    is_deeply(
        Developer::Dashboard::SystemMenu->items_for_platform(
            config     => { indicators => [ { name => 'missing', indicator => { macos => 1 } } ] },
            indicators => \@states,
            platform   => 'macos',
        ),
        [],
        'enabled config without current state produces no menu item',
    );

    my $invalid = eval {
        Developer::Dashboard::SystemMenu->items_for_platform(
            config     => { indicators => 'not-an-array' },
            indicators => \@states,
            platform   => 'macos',
        );
        1;
    };
    ok( !$invalid, 'invalid top-level indicator configuration is refused' );
    like( $@, qr/indicators.*array/i, 'invalid configuration error names the expected array' );

    my $invalid_platform_config = eval {
        Developer::Dashboard::SystemMenu->items_for_platform(
            config => { indicators => [ { name => 'build', indicator => 'yes' } ] },
            indicators => \@states,
            platform   => 'linux',
        );
        1;
    };
    ok( !$invalid_platform_config, 'invalid platform indicator settings are refused on Linux too' );
    like( $@, qr/settings must be a hash reference/i, 'invalid settings error names the expected hash' );

    my $invalid_state = eval {
        Developer::Dashboard::SystemMenu->items_for_platform(
            config     => $merged,
            indicators => [ 'not-a-state' ],
            platform   => 'macos',
        );
        1;
    };
    ok( !$invalid_state, 'invalid indicator state entries are refused' );
    like( $@, qr/state entries must be hash references/i, 'invalid state error identifies the entry shape' );

    my $duplicate_name = eval {
        Developer::Dashboard::SystemMenu->items_for_platform(
            config => {
                indicators => [
                    { name => 'build', indicator => { macos => 1 } },
                    { name => 'build', indicator => { macos => 0 } },
                ],
            },
            indicators => \@states,
            platform   => 'macos',
        );
        1;
    };
    ok( !$duplicate_name, 'duplicate indicator names are refused' );
    like( $@, qr/duplicate indicator configuration name/i, 'duplicate-name error identifies the conflict' );

    my $bad_platform_flag = eval {
        Developer::Dashboard::SystemMenu->items_for_platform(
            config => {
                indicators => [
                    { name => 'build', indicator => { macos => 'yes' } },
                ],
            },
            indicators => \@states,
            platform   => 'macos',
        );
        1;
    };
    ok( !$bad_platform_flag, 'non-boolean platform selector is refused' );

    rejected(
        config => { indicators => ['not-an-entry'] }, indicators => \@states, platform => 'macos',
        pattern => qr/configuration entries must be hash references/, name => 'non-hash config entry is rejected',
    );
    for my $bad_name (
        [ {}, 'undefined config name' ],
        [ { name => [] }, 'reference config name' ],
        [ { name => '' }, 'empty config name' ],
    ) {
        my ( $entry, $label ) = @{$bad_name};
        $entry->{indicator} = { macos => 1 };
        rejected(
            config => { indicators => [$entry] }, indicators => \@states, platform => 'macos',
            pattern => qr/configuration name must be a non-empty string/, name => "$label is rejected",
        );
    }
    rejected(
        config => { indicators => [ { name => 'build', indicator => [] } ] },
        indicators => \@states, platform => 'macos',
        pattern => qr/settings must be a hash reference/, name => 'non-hash platform settings are rejected',
    );
    rejected(
        config => { indicators => [ { name => 'build', indicator => { macos => [] } } ] },
        indicators => \@states, platform => 'macos',
        pattern => qr/macos selector must be boolean/, name => 'reference platform selector is rejected',
    );
    is_deeply(
        Developer::Dashboard::SystemMenu->items_for_platform(
            config => { indicators => [ { name => 'build', indicator => { macos => undef } } ] },
            indicators => \@states, platform => 'macos',
        ),
        [], 'undefined selector follows the disabled path',
    );
    is_deeply(
        Developer::Dashboard::SystemMenu->items_for_platform(
            config => { indicators => [ { name => 'build', indicator => { macos => '0' } } ] },
            indicators => \@states, platform => 'macos',
        ),
        [], 'string zero is accepted as a false selector',
    );

    rejected(
        config => $valid_config, indicators => ['not-a-state'], platform => 'macos',
        pattern => qr/state entries must be hash references/, name => 'non-hash state entry is rejected',
    );
    for my $bad_state (
        [ { icon => 'x' }, 'undefined state name' ],
        [ { name => [], icon => 'x' }, 'reference state name' ],
        [ { name => '', icon => 'x' }, 'empty state name' ],
    ) {
        my ( $state, $label ) = @{$bad_state};
        rejected(
            config => $valid_config, indicators => [$state], platform => 'macos',
            pattern => qr/state name must be a non-empty string/, name => "$label is rejected",
        );
    }
    rejected(
        config => $valid_config, indicators => [ { name => 'build' } ], platform => 'macos',
        pattern => qr/state icon must be a defined scalar/, name => 'undefined state icon is rejected',
    );
    rejected(
        config => $valid_config, indicators => [ { name => 'build', icon => [] } ], platform => 'macos',
        pattern => qr/state icon must be a defined scalar/, name => 'reference state icon is rejected',
    );
}

done_testing;

__END__

=head1 NAME

t/239-system-menu-config.t - system-menu configuration and platform selection

=head1 PURPOSE

This test protects the configuration contract for optional operating-system
menu indicators. It verifies that named indicator declarations merge across
configuration layers and that the SystemMenu adapter selects only the enabled
indicators for macOS, leaving unsupported platforms and invalid settings
visible and safe.

=head1 WHY IT EXISTS

Configuration overlays must add or change a platform selector without
discarding inherited settings for the same named indicator. The adapter must
then project only explicitly enabled macOS items, and malformed declarations
must fail visibly instead of producing a misleading partial menu. A valid
global configuration without the optional system-menu section remains
unchanged, while configured global indicator entries are normalized by name.

=head1 WHEN TO USE

Run this test in the project C<dev> Docker service whenever configuration
merging, indicator settings, or the SystemMenu adapter changes:

    d2 docker compose exec dev prove -lv t/239-system-menu-config.t

The focused suite runs with the project paths mounted in the container, so it
checks the merge and selection contracts without relying on the host Perl
environment. Pair it with the existing config and indicator-store suites.

=head1 HOW TO USE

Run the focused command from the project root. When changing configuration
merge behavior, also run the config coverage test; when changing indicator
records, also run the indicator-store coverage test. The combined command is:

    d2 docker compose exec --workdir /work dev prove -lv t/50-hunt-config.t t/93-config-coverage.t t/95-indicatorstore-coverage.t t/239-system-menu-config.t

=head1 EXAMPLES

The configuration shape covered by this test is:

    {
        "indicators": [
            { "name": "build", "indicator": { "macos": true } }
        ]
    }

The same named declaration may be extended by a deeper configuration layer,
without replacing platform settings inherited from its parent. Linux tests
cover this data and selection contract; the native AppKit helper is verified
separately on a hosted macOS runner.

=head1 WHAT USES IT

The Developer Dashboard release suite runs this test alongside the config
loader and indicator-store regression tests. It protects the public config
contract used by the macOS system-menu integration and catches Linux-safe
validation regressions before a hosted platform run.

=cut
