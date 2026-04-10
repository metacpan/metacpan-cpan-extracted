use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use Cwd qw(getcwd);
use File::Path qw(make_path);
use Developer::Dashboard::JSON qw(json_decode);
use Developer::Dashboard::SeedSync ();

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

my $stale_sql_dashboard = <<'BOOKMARK';
TITLE: SQL Dashboard
:--------------------------------------------------------------------------------:
BOOKMARK: sql-dashboard
:--------------------------------------------------------------------------------:
HTML: <div id="stale-sql-dashboard">stale update copy</div>
BOOKMARK
my $stale_sql_path = $paths->dashboards_root . '/sql-dashboard';
open my $stale_sql_fh, '>:raw', $stale_sql_path or die "Unable to write $stale_sql_path: $!";
print {$stale_sql_fh} $stale_sql_dashboard;
close $stale_sql_fh or die "Unable to close $stale_sql_path: $!";
my $seed_manifest_path = $paths->config_root . '/seeded-pages.json';
make_path( $paths->config_root ) if !-d $paths->config_root;
open my $seed_manifest_fh, '>:raw', $seed_manifest_path or die "Unable to write $seed_manifest_path: $!";
print {$seed_manifest_fh} qq|{"sql-dashboard":{"asset":"sql-dashboard.page","md5":"|
  . Developer::Dashboard::SeedSync::content_md5($stale_sql_dashboard)
  . qq|"}}\n|;
close $seed_manifest_fh or die "Unable to close $seed_manifest_path: $!";

my $refresh_result = $updater->run;
ok( ref($refresh_result) eq 'ARRAY', 'update rerun still returns the step results array after a stale managed seed is present' );
open my $refreshed_sql_fh, '<:raw', $stale_sql_path or die "Unable to read $stale_sql_path: $!";
my $refreshed_sql_dashboard = do { local $/; <$refreshed_sql_fh> };
close $refreshed_sql_fh or die "Unable to close $stale_sql_path: $!";
unlike( $refreshed_sql_dashboard, qr/stale update copy/, 'update rerun refreshes a stale dashboard-managed sql-dashboard saved page' );
like( $refreshed_sql_dashboard, qr/data-sql-workspace-tab="run"/, 'update rerun refreshes the current SQL workspace subtab layout into sql-dashboard' );
like( $refreshed_sql_dashboard, qr/id="sql-table-filter"/, 'update rerun refreshes the current schema filter UI into sql-dashboard' );

done_testing;

__END__

=head1 NAME

04-update-manager.t - update manager tests

=head1 DESCRIPTION

This test verifies update script execution and runtime bootstrap behavior.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for runtime update, bootstrap, and staged maintenance behavior. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because runtime update, bootstrap, and staged maintenance behavior has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing runtime update, bootstrap, and staged maintenance behavior, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/04-update-manager.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. 

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/04-update-manager.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/04-update-manager.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
