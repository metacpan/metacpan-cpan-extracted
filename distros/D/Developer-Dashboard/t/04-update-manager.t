use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use Cwd qw(getcwd);
use Developer::Dashboard::JSON qw(json_decode);

use lib 'lib';

use Developer::Dashboard::Collector;
use Developer::Dashboard::CollectorRunner;
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::UpdateManager;

my $repo = getcwd();
local $ENV{HOME} = tempdir(CLEANUP => 1);
local $ENV{DEVELOPER_DASHBOARD_RUNTIME_LAYERS} = $ENV{HOME} . '/.developer-dashboard';
local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS}      = $ENV{HOME} . '/.developer-dashboard/dashboards';
local $ENV{DEVELOPER_DASHBOARD_CONFIGS}        = $ENV{HOME} . '/.developer-dashboard/config';

my $paths = Developer::Dashboard::PathRegistry->new;
my $files = Developer::Dashboard::FileRegistry->new(paths => $paths);
my $config = Developer::Dashboard::Config->new(files => $files, paths => $paths);
my $collector = Developer::Dashboard::Collector->new(paths => $paths);
my $runner = Developer::Dashboard::CollectorRunner->new(
    collectors => $collector,
    files      => $files,
    paths      => $paths,
);
my $updater = Developer::Dashboard::UpdateManager->new(
    config => $config,
    files  => $files,
    paths  => $paths,
    runner => $runner,
);

chdir $repo or die $!;
my $result = $updater->run;
ok(ref($result) eq 'ARRAY', 'update returns array of step results');
ok(@$result >= 3, 'all update steps executed');

ok(-f $files->global_config, 'global config written');
is_deeply( json_decode( $files->read('global_config') ), {}, 'update bootstrap creates an empty config.json instead of seeding example collectors' );
ok(-f $paths->dashboards_root . '/api-dashboard', 'api-dashboard page written');
ok(-f $paths->dashboards_root . '/sql-dashboard', 'sql-dashboard page written');
ok(!-f $paths->dashboards_root . '/welcome', 'welcome page is no longer written');
ok(-f $paths->config_root . '/shell/bashrc.sh', 'shell bootstrap written');

done_testing;

__END__

=head1 NAME

04-update-manager.t - update manager tests

=head1 DESCRIPTION

This test verifies update script execution and runtime bootstrap behavior.

=for comment FULL-POD-DOC START

=head1 PURPOSE

Test file in the Developer Dashboard codebase. This file tests the runtime update manager flow.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to enforce the TDD contract for this behaviour, stop regressions from shipping, and keep the mandatory coverage and release gates honest.

=head1 WHEN TO USE

Use this file when you are reproducing or fixing behaviour in its area, when you want a focused regression check before the full suite, or when you need to extend coverage without waiting for every unrelated test.

=head1 HOW TO USE

Run it directly with C<prove -lv t/04-update-manager.t> while iterating, then keep it green under C<prove -lr t> before release. Add or update assertions here before changing the implementation that it covers.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by coverage runs, and by release verification before commit or push.

=head1 EXAMPLES

  prove -lv t/04-update-manager.t

Run that command while working on the behaviour this test owns, then rerun C<prove -lr t> before release.

=for comment FULL-POD-DOC END

=cut
