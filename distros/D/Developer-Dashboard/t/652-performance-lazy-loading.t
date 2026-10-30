use strict;
use warnings;

use Capture::Tiny qw(capture);
use Cwd qw(abs_path);
use File::Spec;
use Test::More;

use lib 'lib';
use Developer::Dashboard::CLI::Paths ();

my $repo = abs_path('.');
my $entrypoint = File::Spec->catfile( $repo, 'bin', 'dashboard' );
my $path_registry = File::Spec->catfile( $repo, 'lib', 'Developer', 'Dashboard', 'PathRegistry.pm' );
my $internal_cli = File::Spec->catfile( $repo, 'lib', 'Developer', 'Dashboard', 'InternalCLI.pm' );
my $version_module = File::Spec->catfile( $repo, 'lib', 'Developer', 'Dashboard', 'Version.pm' );
my $paths_helper = File::Spec->catfile( $repo, 'share', 'private-cli', 'paths' );
my $ps1_helper = File::Spec->catfile( $repo, 'share', 'private-cli', 'ps1' );

my $entrypoint_source = _read_file($entrypoint);
ok(
    index( $entrypoint_source, 'use Developer::Dashboard::Platform' ) < 0,
    'the dashboard switchboard does not eagerly load platform helpers',
);
ok(
    index( $entrypoint_source, 'require Developer::Dashboard::Platform' ) >= 0,
    'platform helpers are loaded by the command paths that need them',
);
ok(
    $entrypoint_source =~ /if \( \$cmd eq 'version' \) \{\s*require Developer::Dashboard::Version;/s,
    'the version command reads a lightweight version module instead of loading the application graph',
);
for my $module (qw(Config IO::Handle IO::Select IPC::Open3 Symbol)) {
    ok(
        $entrypoint_source !~ /^use \Q$module\E\b/m,
        "the switchboard does not eagerly import $module",
    );
}
like(
    $entrypoint_source,
    qr/require IO::Handle;/,
    'hook execution loads IO::Handle only on the hook path',
);
like(
    $entrypoint_source,
    qr/require IO::Select;/,
    'hook execution loads IO::Select only on the hook path',
);
like(
    $entrypoint_source,
    qr/require IPC::Open3;/,
    'hook execution loads IPC::Open3 only on the hook path',
);
like(
    $entrypoint_source,
    qr/require Symbol;/,
    'hook execution loads Symbol only on the hook path',
);

my $registry_source = _read_file($path_registry);
ok(
    index( $registry_source, 'use Developer::Dashboard::Platform' ) < 0,
    'PathRegistry does not eagerly load the platform module for ordinary path discovery',
);
ok(
    index( $registry_source, 'require Developer::Dashboard::Platform' ) < 0,
    'PathRegistry keeps its passwd account fallback independent of platform helpers',
);

my $internal_cli_source = _read_file($internal_cli);
ok(
    $internal_cli_source !~ /^use Developer::Dashboard::Platform\b/m,
    'the helper-name registry does not eagerly load platform helpers',
);

my $runtime_probe = q{
use Developer::Dashboard::PathRegistry ();
use Developer::Dashboard::InternalCLI ();
use Developer::Dashboard::Version ();
die "Platform loaded during module metadata lookup\n"
  if exists $INC{'Developer/Dashboard/Platform.pm'};
die "The lightweight version module loaded the application handle\n"
  if exists $INC{'Developer/Dashboard/Handle.pm'};
my $paths = Developer::Dashboard::PathRegistry->new(home => '/tmp');
local @ENV{qw(DD_STATE_ROOT_USER USER LOGNAME USERNAME)} = ('tester', undef, undef, undef);
$paths->_state_root_user;
die "Platform loaded during environment-backed state lookup\n"
  if exists $INC{'Developer/Dashboard/Platform.pm'};
local @ENV{qw(DD_STATE_ROOT_USER USER LOGNAME USERNAME)} = (undef, undef, undef, undef);
$paths->_state_root_user;
die "Platform was loaded for the lightweight passwd fallback\n"
  if exists $INC{'Developer/Dashboard/Platform.pm'};
exit 0;
};
my ( $probe_stdout, $probe_stderr, $probe_exit ) = capture {
    system $^X, '-I' . File::Spec->catdir( $repo, 'lib' ), '-e', $runtime_probe;
    return $? >> 8;
};
is( $probe_exit, 0, 'metadata and passwd fallback lookup avoid the Platform module' );
is( $probe_stdout, '', 'the lazy Platform runtime probe is silent' );
is( $probe_stderr, '', 'the lazy Platform runtime probe has no warnings' );

my $fcntl_probe = q{
use Developer::Dashboard::PathRegistry ();
die "Fcntl was loaded by the lightweight PathRegistry import\n"
  if exists $INC{'Fcntl.pm'};
exit 0;
};
my ( $fcntl_stdout, $fcntl_stderr, $fcntl_exit ) = capture {
    system $^X, '-I' . File::Spec->catdir( $repo, 'lib' ), '-e', $fcntl_probe;
    return $? >> 8;
};
is( $fcntl_exit, 0, 'PathRegistry avoids loading Fcntl for metadata file-type checks' );
is( $fcntl_stdout, '', 'the lazy Fcntl runtime probe is silent' );
is( $fcntl_stderr, '', 'the lazy Fcntl runtime probe has no warnings' );

my $paths_source = _read_file( File::Spec->catfile( $repo, 'lib', 'Developer', 'Dashboard', 'CLI', 'Paths.pm' ) );
ok(
    index( $paths_source, 'use Getopt::Long' ) < 0,
    'the path dispatcher does not eagerly import Getopt::Long',
);
like(
    $paths_source,
    qr/require Getopt::Long;/,
    'path verbs load Getopt::Long only when parsing their options',
);

my $paths_probe = q{
use Developer::Dashboard::CLI::Paths ();
die "Config loaded before lightweight path dispatch\n"
  if exists $INC{'Developer/Dashboard/Config.pm'};
die "FileRegistry loaded before lightweight path dispatch\n"
  if exists $INC{'Developer/Dashboard/FileRegistry.pm'};
die "Getopt::Long loaded before lightweight path dispatch\n"
  if exists $INC{'Getopt/Long.pm'};
my ($stdout, $stderr, $exit) = Capture::Tiny::capture {
    Developer::Dashboard::CLI::Paths::run_paths_command(
        command => 'path',
        args    => ['project-root'],
    );
    return 0;
};
die "lightweight path dispatch wrote stderr: $stderr\n" if $stderr ne '';
die "lightweight path dispatch failed: $exit\n" if $exit;
die "Config loaded for project-root lookup\n"
  if exists $INC{'Developer/Dashboard/Config.pm'};
die "FileRegistry loaded for project-root lookup\n"
  if exists $INC{'Developer/Dashboard/FileRegistry.pm'};
die "Getopt::Long loaded for project-root lookup\n"
  if exists $INC{'Getopt/Long.pm'};
exit 0;
};
my ( $paths_probe_stdout, $paths_probe_stderr, $paths_probe_exit ) = capture {
    system $^X,
      '-I' . File::Spec->catdir( $repo, 'lib' ),
      '-MCapture::Tiny',
      '-e', $paths_probe;
    return $? >> 8;
};
is( $paths_probe_exit, 0, 'project-root dispatch avoids unrelated configuration modules' );
is( $paths_probe_stdout, '', 'lightweight path module probe is silent' );
is( $paths_probe_stderr, '', 'lightweight path module probe emits no warnings' );

my $paths_helper_probe = q{
my ( $repo_lib, $helper ) = @ARGV;
$ENV{DEVELOPER_DASHBOARD_REPO_LIB} = $repo_lib;
@ARGV = ( '-o', 'json' );
my $loaded = do $helper;
die "paths helper failed: $@ $!\n" if !defined $loaded;
die "FindBin loaded although the switchboard supplied the repository library path\n"
  if exists $INC{'FindBin.pm'};
die "TableHelpers loaded on the JSON-only paths route\n"
  if exists $INC{'Developer/Dashboard/CLI/TableHelpers.pm'};
exit 0;
};
my ( $helper_probe_stdout, $helper_probe_stderr, $helper_probe_exit ) = capture {
    system $^X,
      '-I' . File::Spec->catdir( $repo, 'lib' ),
      '-e', $paths_helper_probe,
      File::Spec->catdir( $repo, 'lib' ),
      $paths_helper;
    return $? >> 8;
};
is( $helper_probe_exit, 0, 'the JSON paths helper avoids FindBin and table-rendering imports' );
like( $helper_probe_stdout, qr/^\s*\{.*\}\s*$/s, 'the paths helper still emits its JSON payload' );
is( $helper_probe_stderr, '', 'the paths helper library-path fast path is warning-free' );
my $table_helper_probe = q{
my ( $repo_lib, $helper ) = @ARGV;
$ENV{DEVELOPER_DASHBOARD_REPO_LIB} = $repo_lib;
@ARGV = ( '-o', 'table' );
my $loaded = do $helper;
die "paths helper failed: $@ $!\n" if !defined $loaded;
die "TableHelpers was not loaded for table output\n"
  if !exists $INC{'Developer/Dashboard/CLI/TableHelpers.pm'};
exit 0;
};
my ( $table_probe_stdout, $table_probe_stderr, $table_probe_exit ) = capture {
    system $^X,
      '-I' . File::Spec->catdir( $repo, 'lib' ),
      '-e', $table_helper_probe,
      File::Spec->catdir( $repo, 'lib' ),
      $paths_helper;
    return $? >> 8;
};
is( $table_probe_exit, 0, 'table output lazily loads its renderer' );
like( $table_probe_stdout, qr/Path\s+Value/, 'table output retains its column headings' );
is( $table_probe_stderr, '', 'the table helper path is warning-free' );
my $fallback_probe = q{
my ($helper) = @ARGV;
$0 = $helper;
delete $ENV{DEVELOPER_DASHBOARD_REPO_LIB};
@ARGV = ( '-o', 'json' );
my $loaded = do $helper;
die "paths helper fallback failed: $@ $!\n" if !defined $loaded;
die "FindBin was not loaded by the standalone fallback\n"
  if !exists $INC{'FindBin.pm'};
exit 0;
};
my ( $fallback_stdout, $fallback_stderr, $fallback_exit ) = capture {
    system $^X,
      '-I' . File::Spec->catdir( $repo, 'lib' ),
      '-e', $fallback_probe,
      $paths_helper;
    return $? >> 8;
};
is( $fallback_exit, 0, 'standalone paths helper retains its FindBin library fallback' );
like( $fallback_stdout, qr/^\s*\{.*\}\s*$/s, 'standalone fallback still emits the JSON payload' );
is( $fallback_stdout, $helper_probe_stdout, 'standalone fallback and supplied library path preserve byte-identical output' );
is( $fallback_stderr, '', 'standalone FindBin fallback emits no warnings' );

my $ps1_fast_path_probe = q{
use File::Temp qw(tempdir);
my ($repo_lib, $helper) = @ARGV;
my $home = tempdir(CLEANUP => 1);
$ENV{HOME} = $home;
$ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = "$home/state";
$ENV{DEVELOPER_DASHBOARD_REPO_LIB} = $repo_lib;
delete @ENV{qw(WORKSPACE_REF TICKET_REF TMUX DEVELOPER_DASHBOARD_TMUX_STATUS)};
@ARGV = ('--no-indicators', '--cwd', '/');
my $loaded = do $helper;
die "ps1 helper failed: $@ $!\n" if !defined $loaded;
die "FindBin loaded although the switchboard supplied the repository library path\n"
  if exists $INC{'FindBin.pm'};
die "Getopt::Long loaded for canonical prompt options\n"
  if exists $INC{'Getopt/Long.pm'};
my ( $jobs, $cwd, $mode, $color, $max_age, $width, $no_indicators ) =
  ( 0, '/before', 'compact', 0, 300, 0, 0 );
my @options = qw(--jobs 3 --cwd /tmp/prompt --mode=extended --color --max-age=45 --width 80 --no-indicators);
my $parsed = main::_parse_ps1_options_fast(
    \@options,
    jobs => \$jobs, cwd => \$cwd, mode => \$mode, color => \$color,
    'max-age' => \$max_age, width => \$width, no_indicators => \$no_indicators,
);
die "canonical prompt option parser rejected a supported option\n" if !$parsed;
die "canonical prompt option parser returned incorrect values\n"
  if @options || $jobs != 3 || $cwd ne '/tmp/prompt' || $mode ne 'extended'
  || !$color || $max_age != 45 || $width != 80 || !$no_indicators;
my @unsupported = ('--wid', '81');
die "prompt parser did not request compatibility parsing for an abbreviation\n"
  if main::_parse_ps1_options_fast(
      \@unsupported,
      jobs => \$jobs, cwd => \$cwd, mode => \$mode, color => \$color,
      'max-age' => \$max_age, width => \$width, no_indicators => \$no_indicators,
  );
my @invalid_number = ('--jobs', '2.5');
die "prompt parser accepted a non-integer numeric option\n"
  if main::_parse_ps1_options_fast(
      \@invalid_number,
      jobs => \$jobs, cwd => \$cwd, mode => \$mode, color => \$color,
      'max-age' => \$max_age, width => \$width, no_indicators => \$no_indicators,
  );
die "prompt parser accepted a non-array argument list\n"
  if main::_parse_ps1_options_fast(undef);
my @boolean_options = ('--no-color', '--no-no-indicators');
$color = 1;
$no_indicators = 1;
die "prompt parser rejected canonical negative boolean options\n"
  if !main::_parse_ps1_options_fast(
      \@boolean_options,
      color => \$color, no_indicators => \$no_indicators,
  );
die "prompt parser returned incorrect negative boolean values\n" if $color || $no_indicators;
my @missing_value = ('--jobs');
die "prompt parser accepted a missing option value\n"
  if main::_parse_ps1_options_fast(\@missing_value, jobs => \$jobs);
die "prompt parser consumed input when requesting compatibility parsing\n"
  if join(qq{\0}, @missing_value) ne '--jobs';
my @missing_target = ('--jobs', '5');
die "prompt parser accepted an option without a destination\n"
  if main::_parse_ps1_options_fast(\@missing_target);
exit 0;
};
my ( $ps1_fast_stdout, $ps1_fast_stderr, $ps1_fast_exit ) = capture {
    system $^X,
      '-I' . File::Spec->catdir( $repo, 'lib' ),
      '-e', $ps1_fast_path_probe,
      File::Spec->catdir( $repo, 'lib' ),
      $ps1_helper;
    return $? >> 8;
};
is( $ps1_fast_exit, 0, 'the ps1 helper uses fast paths for supplied library roots and canonical prompt options' );
like( $ps1_fast_stdout, qr/^\(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\) \[[^\]]+\]\n> /, 'the ps1 helper preserves normal prompt output on the library-root fast path' );
is( $ps1_fast_stderr, '', 'the ps1 library-root fast path emits no warnings' );
my $ps1_fallback_probe = q{
use File::Temp qw(tempdir);
my ($helper) = @ARGV;
my $home = tempdir(CLEANUP => 1);
$ENV{HOME} = $home;
$ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = "$home/state";
delete $ENV{DEVELOPER_DASHBOARD_REPO_LIB};
delete @ENV{qw(WORKSPACE_REF TICKET_REF TMUX DEVELOPER_DASHBOARD_TMUX_STATUS)};
$0 = $helper;
@ARGV = ('--no-indicators', '--cwd', '/');
my $loaded = do $helper;
die "ps1 helper fallback failed: $@ $!\n" if !defined $loaded;
die "FindBin was not loaded by the standalone fallback\n"
  if !exists $INC{'FindBin.pm'};
exit 0;
};
my ( $ps1_fallback_stdout, $ps1_fallback_stderr, $ps1_fallback_exit ) = capture {
    system $^X,
      '-I' . File::Spec->catdir( $repo, 'lib' ),
      '-e', $ps1_fallback_probe,
      $ps1_helper;
    return $? >> 8;
};
is( $ps1_fallback_exit, 0, 'standalone ps1 invocation retains the FindBin library fallback' );
my $ps1_fast_stable = $ps1_fast_stdout;
my $ps1_fallback_stable = $ps1_fallback_stdout;
$ps1_fast_stable =~ s/^\(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\)//;
$ps1_fallback_stable =~ s/^\(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\)//;
is( $ps1_fallback_stable, $ps1_fast_stable, 'ps1 fast and fallback paths preserve prompt output apart from its live timestamp' );
is( $ps1_fallback_stderr, '', 'standalone ps1 fallback emits no warnings' );
my $ps1_compat_probe = q{
use File::Temp qw(tempdir);
my ($repo_lib, $helper) = @ARGV;
my $home = tempdir(CLEANUP => 1);
$ENV{HOME} = $home;
$ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = "$home/state";
$ENV{DEVELOPER_DASHBOARD_REPO_LIB} = $repo_lib;
delete @ENV{qw(WORKSPACE_REF TICKET_REF TMUX DEVELOPER_DASHBOARD_TMUX_STATUS)};
@ARGV = ('--wid', '80', '--no-indicators', '--cwd', '/');
my $loaded = do $helper;
die "ps1 compatibility parser failed: $@ $!\n" if !defined $loaded;
die "Getopt::Long was not loaded for an abbreviated option\n"
  if !exists $INC{'Getopt/Long.pm'};
exit 0;
};
my ( $ps1_compat_stdout, $ps1_compat_stderr, $ps1_compat_exit ) = capture {
    system $^X,
      '-I' . File::Spec->catdir( $repo, 'lib' ),
      '-e', $ps1_compat_probe,
      File::Spec->catdir( $repo, 'lib' ),
      $ps1_helper;
    return $? >> 8;
};
is( $ps1_compat_exit, 0, 'unsupported abbreviated prompt options use Getopt::Long compatibility parsing' );
like( $ps1_compat_stdout, qr/^\(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\) \[[^\]]+\]\n> /, 'compatibility option parsing preserves prompt output' );
is( $ps1_compat_stderr, '', 'compatibility option parsing emits no warnings' );

my $option_probe = q{
use Developer::Dashboard::CLI::Paths ();
my @cases = (
    [ [ '-o', 'json', 'filter' ], 'json', ['filter'] ],
    [ [ '--output', 'json' ], 'json', [] ],
    [ [ '--output=json' ], 'json', [] ],
    [ [ '-ojson' ], 'json', [] ],
    [ [ '-o=json' ], 'json', [] ],
    [ [], 'table', [] ],
);
for my $case (@cases) {
    my @args = @{ $case->[0] };
    my $output = 'table';
    my $parsed = Developer::Dashboard::CLI::Paths::_get_options_from_array(
        \\@args, 'o|output=s' => \\$output,
    );
    die "output form produced an unexpected result\\n"
      if !$parsed || $output ne $case->[1]
      || join(qq{\\0}, @args) ne join(qq{\\0}, @{ $case->[2] });
}
die "Getopt::Long loaded for canonical output parsing\n"
  if exists $INC{'Getopt/Long.pm'};
for my $unsupported ( [ '-o' ], ['--'], ['-'] ) {
    my @args = @{$unsupported};
    my $output = 'table';
    die "incomplete or noncanonical option syntax did not request fallback\\n"
      if defined Developer::Dashboard::CLI::Paths::_parse_output_options_fast(
        \\@args, \\$output,
      );
}
my @fallback_args = ('--out', 'table');
my $fallback_output = 'json';
my $fallback_parsed = Developer::Dashboard::CLI::Paths::_get_options_from_array(
    \\@fallback_args, 'o|output=s' => \\$fallback_output,
);
die "noncanonical option did not use the compatibility parser\\n"
  if !$fallback_parsed || $fallback_output ne 'table' || @fallback_args;
die "compatibility parser was not loaded for a noncanonical option\\n"
  if !exists $INC{'Getopt/Long.pm'};
exit 0;
};
my ( $option_stdout, $option_stderr, $option_exit ) = capture {
    system $^X,
      '-I' . File::Spec->catdir( $repo, 'lib' ),
      '-e', $option_probe;
    return $? >> 8;
};
is( $option_exit, 0, 'canonical output-option parsing avoids Getopt::Long' );
is( $option_stdout, '', 'canonical output-option parsing is silent' );
is( $option_stderr, '', 'canonical output-option parsing emits no warnings' );

my $paths_action_probe = q{
use Developer::Dashboard::CLI::Paths ();
use Developer::Dashboard::PathRegistry;
use File::Temp qw(tempdir);
my $home = tempdir(CLEANUP => 1);
my $paths = Developer::Dashboard::PathRegistry->new(
    home => $home, cwd => $home, workspace_roots => [], project_roots => [],
);
my @args = ('-o', 'json');
my ($stdout, $stderr, $exit) = Capture::Tiny::capture {
    Developer::Dashboard::CLI::Paths::_paths_action_paths(
        paths => $paths, load_folder_paths => sub { return 1; }, argv => \\@args,
    );
    return 0;
};
die "path inventory output was empty\\n" if $stdout eq '';
die "path inventory wrote stderr: $stderr\\n" if $stderr ne '';
die "Getopt::Long loaded for canonical paths -o json\\n"
  if exists $INC{'Getopt/Long.pm'};
exit 0;
};
my ( $action_stdout, $action_stderr, $action_exit ) = capture {
    system $^X,
      '-I' . File::Spec->catdir( $repo, 'lib' ),
      '-MCapture::Tiny',
      '-e', $paths_action_probe;
    return $? >> 8;
};
is( $action_exit, 0, 'the complete canonical paths action avoids Getopt::Long' );
is( $action_stdout, '', 'the canonical paths action probe is silent' );
is( $action_stderr, '', 'the canonical paths action probe emits no warnings' );

subtest 'canonical option fast path is covered in the instrumented process' => sub {
    my @cases = (
        [ [ '-o', 'json', 'filter' ], 'json', ['filter'] ],
        [ [ '--output', 'json' ], 'json', [] ],
        [ [ '--output=json' ], 'json', [] ],
        [ [ '-ojson' ], 'json', [] ],
        [ [ '-o=json' ], 'json', [] ],
        [ [ '--output=' ], '', [] ],
        [ [], 'table', [] ],
    );
    for my $case (@cases) {
        my @args = @{ $case->[0] };
        my $output = 'table';
        my $parsed = Developer::Dashboard::CLI::Paths::_get_options_from_array(
            \@args, 'o|output=s' => \$output,
        );
        ok( $parsed, 'a canonical option form parses successfully' );
        is( $output, $case->[1], 'the canonical option value is assigned' );
        is_deeply( \@args, $case->[2], 'remaining positional values are preserved' );
    }

    for my $unsupported ( [ '-o' ], ['--'], ['-'], ['--out'] ) {
        my @args = @{$unsupported};
        my $output = 'table';
        ok(
            !defined Developer::Dashboard::CLI::Paths::_parse_output_options_fast(
                \@args, \$output,
            ),
            'incomplete or noncanonical syntax requests the compatibility parser',
        );
    }

    my @fallback_args = ( '--out', 'table' );
    my $fallback_output = 'json';
    ok(
        Developer::Dashboard::CLI::Paths::_get_options_from_array(
            \@fallback_args, 'o|output=s' => \$fallback_output,
        ),
        'the compatibility parser accepts a Getopt::Long abbreviation',
    );
    is( $fallback_output, 'table', 'the compatibility parser assigns the abbreviation value' );
    is_deeply( \@fallback_args, [], 'the compatibility parser consumes its option pair' );

    my @generic_args = ('--create=0777');
    my $create_mode;
    ok(
        Developer::Dashboard::CLI::Paths::_get_options_from_array(
            \@generic_args, 'c|create=s' => \$create_mode,
        ),
        'a different two-item option specification uses the generic parser',
    );
    is( $create_mode, '0777', 'the generic parser returns the requested create mode' );
    is_deeply( \@generic_args, [], 'the generic parser consumes its option' );

    my @array_destination;
    my @array_destination_args = ( '-o', 'json' );
    ok(
        Developer::Dashboard::CLI::Paths::_get_options_from_array(
            \@array_destination_args, 'o|output=s' => \@array_destination,
        ),
        'a non-scalar output destination uses the generic parser',
    );
    is_deeply( \@array_destination, ['json'], 'the generic parser preserves array destinations' );
    is_deeply( \@array_destination_args, [], 'the generic parser consumes array-destination options' );
};

my $version = _module_version($version_module);
my ( $stdout, $stderr, $exit ) = capture {
    system $^X, '-I' . File::Spec->catdir( $repo, 'lib' ), $entrypoint, 'version';
    return $? >> 8;
};
is( $exit, 0, 'the lightweight version command succeeds' );
is( $stdout, "$version\n", 'lightweight version loading preserves version output' );
is( $stderr, '', 'lazy platform loading adds no version-command warnings' );

done_testing();

sub _read_file {
# _read_file($path)
# Reads one repository source file for the static import assertions above.
# Input: filesystem path string.
# Output: complete file content string.
    my ($path) = @_;
    open my $fh, '<', $path or die "Unable to read $path: $!";
    local $/;
    my $content = <$fh>;
    close $fh or die "Unable to close $path: $!";
    return $content;
}

sub _module_version {
# _module_version($path)
# Extracts the declared Developer Dashboard version from a Perl module.
# Input: filesystem path string to a Perl module.
# Output: version string or a fatal error when no version declaration exists.
    my ($path) = @_;
    my $source = _read_file($path);
    return $1 if $source =~ /^our \$VERSION\s*=\s*'([^']+)'/m;
    die "Unable to read module version from $path\n";
}

__END__

=head1 NAME

t/652-performance-lazy-loading.t - guard lazy loading on lightweight commands

=head1 PURPOSE

Checks the measured lightweight CLI optimization that defers platform helper
module loading until command paths actually need those helpers, and keeps
PathRegistry's built-in passwd fallback independent of that large module.

=head1 WHY IT EXISTS

NYTProf showed avoidable platform-module load time on lightweight command paths.
This test prevents a future eager import from returning unnoticed and checks
that public version output and the PathRegistry passwd fallback remain stable.
It also protects the project-root-only path dispatch from loading config and
file-registry modules it does not use. For the `paths` helper, it verifies the
switchboard-provided repository library root avoids FindBin initialization and
that direct helper invocation retains the previous FindBin fallback with exact
output parity. JSON-only paths must also avoid loading TableHelpers, while
human table output continues to load its renderer on demand. The prompt helper receives the same checks: its public dispatch
avoids loading FindBin when the repository library root is supplied, and
standalone fallback output remains equal apart from the live timestamp. A
local parser handles the standard generated-prompt options without loading
C<Getopt::Long>, while abbreviated options retain the previous compatibility
parser behavior.

=head1 WHEN TO USE

Run this test when changing lightweight imports in C<bin/dashboard>,
C<Developer::Dashboard::CLI::Paths>, or C<Developer::Dashboard::PathRegistry>,
or C<share/private-cli/paths>, or when investigating startup-time regressions
in those paths.

=head1 HOW TO USE

From the repository, run:

  prove -lv t/652-performance-lazy-loading.t

Run it inside the dedicated Docker test service for repository verification.

=head1 WHAT USES IT

The repository test suite and performance-regression reviews use this test to
protect lazy imports and lightweight CLI output behavior.

=head1 EXAMPLES

Example 1:

  prove -lv t/652-performance-lazy-loading.t

Checks the import contracts and version-command behavior.

Example 2:

  NYTPROF=file=nytprof.out:stmts=0:subs=1 perl -d:NYTProf bin/dashboard version

Profiles a lightweight command after the test protects its expected dispatch
behavior.

Example 3:

  dashboard paths -o json

Emits machine-readable paths without loading terminal table renderers. Default
human-readable paths output continues to load its renderer lazily.

=cut
