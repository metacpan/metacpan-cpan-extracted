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

Test file in the Developer Dashboard codebase. This file tests runtime environment override behaviour.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to enforce the TDD contract for this behaviour, stop regressions from shipping, and keep the mandatory coverage and release gates honest.

=head1 WHEN TO USE

Use this file when you are reproducing or fixing behaviour in its area, when you want a focused regression check before the full suite, or when you need to extend coverage without waiting for every unrelated test.

=head1 HOW TO USE

Run it directly with C<prove -lv t/06-env-overrides.t> while iterating, then keep it green under C<prove -lr t> before release. Add or update assertions here before changing the implementation that it covers.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by coverage runs, and by release verification before commit or push.

=head1 EXAMPLES

  prove -lv t/06-env-overrides.t

Run that command while working on the behaviour this test owns, then rerun C<prove -lr t> before release.

=for comment FULL-POD-DOC END

=cut
