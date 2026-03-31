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
my $startup   = File::Spec->catdir( $home, 'custom-startup' );

local $ENV{HOME} = $home;
local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS} = $bookmarks;
local $ENV{DEVELOPER_DASHBOARD_CONFIGS}   = $configs;
local $ENV{DEVELOPER_DASHBOARD_STARTUP}   = $startup;
local $ENV{DEVELOPER_DASHBOARD_CHECKERS}  = 'only.this';

make_path($startup);

my $startup_file = File::Spec->catfile( $startup, 'collectors.json' );
open my $fh, '>', $startup_file or die "Unable to write $startup_file: $!";
print {$fh} <<'JSON';
[
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
JSON
close $fh;

my $paths = Developer::Dashboard::PathRegistry->new;
is( $paths->dashboards_root, $bookmarks, 'bookmarks root overridden' );
is( $paths->config_root,     $configs,   'config root overridden' );
is( $paths->startup_root,    $startup,   'startup root overridden' );

my $files  = Developer::Dashboard::FileRegistry->new(paths => $paths);
my $config = Developer::Dashboard::Config->new(files => $files, paths => $paths);
my $jobs   = $config->collectors;

is( scalar @$jobs, 1, 'checker filter applied' );
is( $jobs->[0]{name}, 'only.this', 'startup collector loaded and filtered' );

done_testing;

__END__

=head1 NAME

06-env-overrides.t - environment override tests

=head1 DESCRIPTION

This test verifies environment-variable overrides for bookmarks, configs,
startup definitions, and checker filtering.

=cut
