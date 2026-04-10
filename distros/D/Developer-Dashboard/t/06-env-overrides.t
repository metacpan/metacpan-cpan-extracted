use strict;
use warnings;

use Test::More;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;

my $home = tempdir(CLEANUP => 1);
my $bookmarks = File::Spec->catdir( $home, 'custom-bookmarks' );
my $configs   = File::Spec->catdir( $home, 'custom-configs' );
local $ENV{HOME} = $home;
local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS} = $bookmarks;
local $ENV{DEVELOPER_DASHBOARD_CONFIGS}   = $configs;
local $ENV{DEVELOPER_DASHBOARD_CHECKERS}  = 'only.this';

make_path($configs);

my $config_file = File::Spec->catfile( $configs, 'config.json' );
open my $fh, '>', $config_file or die "Unable to write $config_file: $!";
print {$fh} <<'JSON';
{
  "collectors": [
    {
      "name": "only.this",
      "command": "printf 'ok\n'",
      "cwd": "home",
      "interval": 30
    },
    {
      "name": "skip.this",
      "command": "printf 'skip\n'",
      "cwd": "home",
      "interval": 30
    }
  ]
}
JSON
close $fh;

my $paths = Developer::Dashboard::PathRegistry->new;
is( $paths->dashboards_root, $bookmarks, 'bookmarks root overridden' );
is( $paths->config_root,     $configs,   'config root overridden' );

my $files  = Developer::Dashboard::FileRegistry->new(paths => $paths);
my $config = Developer::Dashboard::Config->new(files => $files, paths => $paths);
my $jobs   = $config->collectors;

is( scalar @$jobs, 1, 'checker filter applied' );
is( $jobs->[0]{name}, 'only.this', 'config collector loaded and filtered' );

done_testing;

__END__

=head1 NAME

06-env-overrides.t - environment override tests

=head1 DESCRIPTION

This test verifies environment-variable overrides for bookmarks, configs, and
checker filtering.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for environment overrides and persisted configuration behavior. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because environment overrides and persisted configuration behavior has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing environment overrides and persisted configuration behavior, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/06-env-overrides.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. 

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/06-env-overrides.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/06-env-overrides.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
