use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;

# Test 1: web_settings() returns default when nothing saved
{
    my $temp_home = tempdir(CLEANUP => 1);
    my $temp_config = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $temp_home;
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS} = $temp_config;

    my $paths = Developer::Dashboard::PathRegistry->new;
    my $files = Developer::Dashboard::FileRegistry->new(paths => $paths);
    my $config = Developer::Dashboard::Config->new(files => $files, paths => $paths);

    my $settings = $config->web_settings;
    ok($settings, 'web_settings returns hash');
    is($settings->{host}, '0.0.0.0', 'default host is 0.0.0.0');
    is($settings->{port}, 7890, 'default port is 7890');
    is($settings->{workers}, 1, 'default workers is 1');
    is($settings->{ssl}, 0, 'default ssl is 0 (disabled)');
}

# Test 2: save_global_web_settings() saves all settings
{
    my $temp_home = tempdir(CLEANUP => 1);
    my $temp_config = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $temp_home;
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS} = $temp_config;

    my $paths = Developer::Dashboard::PathRegistry->new;
    my $files = Developer::Dashboard::FileRegistry->new(paths => $paths);
    my $config = Developer::Dashboard::Config->new(files => $files, paths => $paths);

    my $result = $config->save_global_web_settings(
        host    => '127.0.0.1',
        port    => 8000,
        workers => 4,
        ssl     => 1,
    );

    ok($result, 'save_global_web_settings returns result');
    is($result->{host}, '127.0.0.1', 'returned host matches');
    is($result->{port}, 8000, 'returned port matches');
    is($result->{workers}, 4, 'returned workers matches');
    is($result->{ssl}, 1, 'returned ssl matches');
}

# Test 3: web_settings() retrieves saved settings
{
    my $temp_home = tempdir(CLEANUP => 1);
    my $temp_config = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $temp_home;
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS} = $temp_config;

    my $paths = Developer::Dashboard::PathRegistry->new;
    my $files = Developer::Dashboard::FileRegistry->new(paths => $paths);
    my $config = Developer::Dashboard::Config->new(files => $files, paths => $paths);

    $config->save_global_web_settings(
        host    => '192.168.1.100',
        port    => 9000,
        workers => 2,
        ssl     => 1,
    );

    # Create new config object (simulates restart reading config)
    my $config2 = Developer::Dashboard::Config->new(files => $files, paths => $paths);
    my $settings = $config2->web_settings;

    is($settings->{host}, '192.168.1.100', 'loaded host matches saved');
    is($settings->{port}, 9000, 'loaded port matches saved');
    is($settings->{workers}, 2, 'loaded workers matches saved');
    is($settings->{ssl}, 1, 'loaded ssl matches saved');
}

# Test 4: partial save updates only specified settings
{
    my $temp_home = tempdir(CLEANUP => 1);
    my $temp_config = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $temp_home;
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS} = $temp_config;

    my $paths = Developer::Dashboard::PathRegistry->new;
    my $files = Developer::Dashboard::FileRegistry->new(paths => $paths);
    my $config = Developer::Dashboard::Config->new(files => $files, paths => $paths);

    $config->save_global_web_settings(
        host    => '192.168.1.100',
        port    => 9000,
        workers => 2,
        ssl     => 1,
    );

    # Save only ssl without others
    $config->save_global_web_settings(ssl => 0);

    my $config2 = Developer::Dashboard::Config->new(files => $files, paths => $paths);
    my $settings = $config2->web_settings;

    is($settings->{ssl}, 0, 'ssl updated to 0');
    is($settings->{host}, '192.168.1.100', 'host preserved from previous save');
    is($settings->{port}, 9000, 'port preserved from previous save');
}

# Test 5: ssl flag validation
{
    my $temp_home = tempdir(CLEANUP => 1);
    my $temp_config = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $temp_home;
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS} = $temp_config;

    my $paths = Developer::Dashboard::PathRegistry->new;
    my $files = Developer::Dashboard::FileRegistry->new(paths => $paths);
    my $config = Developer::Dashboard::Config->new(files => $files, paths => $paths);

    # ssl must be 0 or 1 if provided
    my $result = $config->save_global_web_settings(ssl => 1);
    is($result->{ssl}, 1, 'ssl => 1 saved correctly');

    $result = $config->save_global_web_settings(ssl => 0);
    is($result->{ssl}, 0, 'ssl => 0 saved correctly');
}

# Test 6: port validation
{
    my $temp_home = tempdir(CLEANUP => 1);
    my $temp_config = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $temp_home;
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS} = $temp_config;

    my $paths = Developer::Dashboard::PathRegistry->new;
    my $files = Developer::Dashboard::FileRegistry->new(paths => $paths);
    my $config = Developer::Dashboard::Config->new(files => $files, paths => $paths);

    # port must be numeric and in valid range
    my $result = $config->save_global_web_settings(port => 8080);
    is($result->{port}, 8080, 'valid port saved');

    eval {
        $config->save_global_web_settings(port => -1);
    };
    ok($@, 'negative port rejected');

    eval {
        $config->save_global_web_settings(port => 'invalid');
    };
    ok($@, 'non-numeric port rejected');
}

# Test 7: workers validation
{
    my $temp_home = tempdir(CLEANUP => 1);
    my $temp_config = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $temp_home;
    local $ENV{DEVELOPER_DASHBOARD_CONFIGS} = $temp_config;

    my $paths = Developer::Dashboard::PathRegistry->new;
    my $files = Developer::Dashboard::FileRegistry->new(paths => $paths);
    my $config = Developer::Dashboard::Config->new(files => $files, paths => $paths);

    my $result = $config->save_global_web_settings(workers => 4);
    is($result->{workers}, 4, 'valid workers saved');

    eval {
        $config->save_global_web_settings(workers => 0);
    };
    ok($@, 'zero workers rejected');

    eval {
        $config->save_global_web_settings(workers => 'invalid');
    };
    ok($@, 'non-numeric workers rejected');
}

done_testing();

__END__

=head1 NAME

t/18-web-service-config.t - Configuration persistence tests for web service settings

=head1 DESCRIPTION

Tests that host, port, workers, and ssl settings are properly saved to and loaded from
the global configuration, so dashboard restart inherits the previous serve session settings.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for the local web application and server-facing routes. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because the local web application and server-facing routes has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing the local web application and server-facing routes, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/18-web-service-config.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. 

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/18-web-service-config.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/18-web-service-config.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
