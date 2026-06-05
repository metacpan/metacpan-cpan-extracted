#!/usr/bin/env perl
use strict;
use warnings;

use Cwd qw(getcwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';
use Developer::Dashboard::PerlEnv;

my $repo_root = getcwd();
my $dashboard = File::Spec->catfile( $repo_root, 'bin', 'dashboard' );
my $source = _slurp($dashboard);

like( $source, qr/\A#!\/usr\/bin\/env perl\b/, 'dashboard entrypoint uses /usr/bin/env perl' );
unlike( $source, qr/BOOKMARK:\s+\S+-dashboard/, 'dashboard entrypoint no longer embeds extracted dashboard bookmark ids' );
unlike( $source, qr/Developer::Dashboard::CLI::SeededPages/, 'dashboard entrypoint no longer loads the seeded bookmark loader directly' );
unlike( $source, qr/Developer::Dashboard::CLI::Query/, 'dashboard entrypoint no longer loads the query CLI module directly' );
unlike( $source, qr/Developer::Dashboard::CLI::OpenFile/, 'dashboard entrypoint no longer loads the open-file CLI module directly' );
unlike( $source, qr/Developer::Dashboard::CLI::Ticket/, 'dashboard entrypoint no longer loads the ticket CLI module directly' );
unlike( $source, qr/\bif\s*\(\s*\$cmd\s+eq\s+'(?:encode|decode|indicator|collector|config|auth|init|cpan|page|action|docker|serve|stop|restart|shell|doctor|skills|skill)'\s*\)/, 'dashboard entrypoint no longer embeds built-in command implementation branches' );
like( $source, qr/Developer::Dashboard::InternalCLI/, 'dashboard entrypoint delegates built-in commands through InternalCLI staging' );
like( $source, qr/_exec_switchboard_command/, 'dashboard entrypoint only resolves and execs staged commands' );
like( $source, qr/_custom_command_path/, 'dashboard entrypoint resolves layered custom commands' );
like( $source, qr/_builtin_helper_path/, 'dashboard entrypoint resolves staged private built-in helpers' );
like( $source, qr/_builtin_helper_path\('skills'\)/, 'dashboard dotted skill dispatch reuses the staged skills helper' );
like( $source, qr/_exec_switchboard_command\( \$helper_path, '_exec', \$skill_name, \$skill_command, \@ARGV \)/, 'dashboard dotted skill dispatch hands skill commands through the internal skills exec route' );
like( $source, qr/Developer::Dashboard::PerlEnv->bootstrap_perl5lib/, 'dashboard entrypoint bootstraps a safe Perl library order before helper dispatch' );

my $private_core = _slurp( File::Spec->catfile( $repo_root, 'share', 'private-cli', '_dashboard-core' ) );
like( $private_core, qr/Developer::Dashboard::PerlEnv->bootstrap_perl5lib/, 'private helper core bootstraps a safe Perl library order before loading command modules' );

my $share_seeded_root = File::Spec->catdir( $repo_root, 'share', 'seeded-pages' );
ok(
    !-e $share_seeded_root || -d $share_seeded_root,
    'share/seeded-pages is either omitted from the dist or present as a directory outside the dashboard entrypoint',
);
is_deeply(
    [ sort glob( File::Spec->catfile( $share_seeded_root, '*' ) ) ],
    [],
    'share/seeded-pages no longer ships extracted starter dashboard pages in core',
);

my $lib = File::Spec->catdir( $repo_root, 'lib' );
my $fake_lib = tempdir( CLEANUP => 1 );
my $fake_web_dir = File::Spec->catdir( $fake_lib, 'Developer', 'Dashboard', 'Web' );
make_path($fake_web_dir);
my $fake_web_app = File::Spec->catfile( $fake_web_dir, 'App.pm' );
open my $fake_web_fh, '>', $fake_web_app or die "Unable to write $fake_web_app: $!";
print {$fake_web_fh} <<'PERL';
package Developer::Dashboard::Web::App;
die "lazy-loader-regression: heavy web runtime was loaded for a lightweight command\n";
PERL
close $fake_web_fh;

local $ENV{HOME} = tempdir( CLEANUP => 1 );
local $ENV{PERL5OPT} = '-I' . $fake_lib;
my $jq_json = File::Spec->catfile( $ENV{HOME}, 'sample.json' );
open my $jq_fh, '>', $jq_json or die "Unable to write $jq_json: $!";
print {$jq_fh} qq|{"alpha":1}\n|;
close $jq_fh;

my $jq_output = qx{$^X -I$lib $dashboard jq .alpha "$jq_json" 2>&1};
my $jq_exit = $? >> 8;
is( $jq_exit, 0, 'dashboard jq stays on the lazy lightweight path without loading heavy web modules' )
  or diag $jq_output;
like( $jq_output, qr/\b1\b/, 'dashboard jq still returns the requested value' );

my $version_output = qx{$^X -I$lib $dashboard version 2>&1};
my $version_exit = $? >> 8;
is( $version_exit, 0, 'dashboard version also stays on the lightweight path without loading heavy web modules' )
  or diag $version_output;
like( $version_output, qr/^\d+\.\d+\s*\z/, 'dashboard version still prints the package version' );

my $lazy_home = tempdir( CLEANUP => 1 );
{
    local $ENV{HOME} = $lazy_home;
    my $init_output = qx{$^X -I$lib $dashboard init 2>&1};
    my $init_exit = $? >> 8;
    is( $init_exit, 0, 'dashboard init stages private helpers before the prompt lazy-load check' )
      or diag $init_output;
}
my $lazy_lib = tempdir( CLEANUP => 1 );
my $lazy_cli_dir = File::Spec->catdir( $lazy_lib, 'Developer', 'Dashboard', 'CLI' );
my $lazy_skill_dir = File::Spec->catdir( $lazy_lib, 'Developer', 'Dashboard' );
my $lazy_file_dir = File::Spec->catdir( $lazy_lib, 'File' );
make_path( $lazy_cli_dir, $lazy_skill_dir, $lazy_file_dir );
_write_perl_module(
    File::Spec->catfile( $lazy_cli_dir, 'Suggest.pm' ),
    "package Developer::Dashboard::CLI::Suggest;\ndie qq(lazy-loader-regression: suggestion runtime loaded during dashboard ps1\\n);\n",
);
_write_perl_module(
    File::Spec->catfile( $lazy_skill_dir, 'SkillManager.pm' ),
    "package Developer::Dashboard::SkillManager;\ndie qq(lazy-loader-regression: skill manager loaded during dashboard ps1\\n);\n",
);
_write_perl_module(
    File::Spec->catfile( $lazy_skill_dir, 'SeedSync.pm' ),
    "package Developer::Dashboard::SeedSync;\ndie qq(lazy-loader-regression: seed sync loaded during dashboard ps1\\n);\n",
);
_write_perl_module(
    File::Spec->catfile( $lazy_file_dir, 'ShareDir.pm' ),
    "package File::ShareDir;\ndie qq(lazy-loader-regression: File::ShareDir loaded during dashboard ps1\\n);\n",
);

{
    local $ENV{HOME} = $lazy_home;
    local $ENV{PERL5OPT} = '-I' . $lazy_lib;
    my $ps1_output = qx{$^X -I$lib $dashboard ps1 --cwd "$lazy_home" --mode compact --no-indicators 2>&1};
    my $ps1_exit = $? >> 8;
    is( $ps1_exit, 0, 'dashboard ps1 stays on the lightweight helper path once helpers are already staged' )
      or diag $ps1_output;
    unlike( $ps1_output, qr/lazy-loader-regression:/, 'dashboard ps1 does not load suggestion, skill, or helper-staging-only modules on the hot path' );
}

{
    my $compat_home = tempdir( CLEANUP => 1 );
    {
        local $ENV{HOME} = $compat_home;
        my $init_output = qx{$^X -I$lib $dashboard init 2>&1};
        my $init_exit = $? >> 8;
        is( $init_exit, 0, 'dashboard init stages private helpers before the ps1 compatibility check' )
          or diag $init_output;
    }

    my $compat_lib = tempdir( CLEANUP => 1 );
    my $compat_dd_dir = File::Spec->catdir( $compat_lib, 'Developer', 'Dashboard' );
    make_path($compat_dd_dir);
    _write_perl_module(
        File::Spec->catfile( $compat_dd_dir, 'Config.pm' ),
        <<'PERL',
package Developer::Dashboard::Config;
sub new { bless {}, shift }
sub collectors { return [] }
1;
PERL
    );
    _write_perl_module(
        File::Spec->catfile( $compat_dd_dir, 'FileRegistry.pm' ),
        <<'PERL',
package Developer::Dashboard::FileRegistry;
sub new { bless {}, shift }
1;
PERL
    );
    _write_perl_module(
        File::Spec->catfile( $compat_dd_dir, 'IndicatorStore.pm' ),
        <<'PERL',
package Developer::Dashboard::IndicatorStore;
sub new { bless { synced => 0, refreshed => 0 }, shift }
sub sync_collectors { $_[0]{synced}++; return [] }
sub refresh_core_indicators { $_[0]{refreshed}++; return 1 }
1;
PERL
    );
    _write_perl_module(
        File::Spec->catfile( $compat_dd_dir, 'PathRegistry.pm' ),
        <<'PERL',
package Developer::Dashboard::PathRegistry;
sub new { bless {}, shift }
1;
PERL
    );
    _write_perl_module(
        File::Spec->catfile( $compat_dd_dir, 'Prompt.pm' ),
        <<'PERL',
package Developer::Dashboard::Prompt;
sub new { bless {}, shift }
sub render { return "compat-ps1\n" }
sub render_tmux_status { return "compat-tmux\n" }
1;
PERL
    );

    my $compat_ps1 = File::Spec->catfile( $compat_home, '.developer-dashboard', 'cli', 'dd', 'ps1' );
    my $compat_output = qx{$^X -I$compat_lib -I$lib $compat_ps1 --cwd "$compat_home" --mode compact --no-indicators 2>&1};
    my $compat_exit = $? >> 8;
    is( $compat_exit, 0, 'staged ps1 remains compatible when the installed IndicatorStore predates collectors_need_sync' )
      or diag $compat_output;
    is( $compat_output, "compat-ps1\n", 'staged ps1 falls back cleanly to an unconditional collector sync when collectors_need_sync is unavailable' );
}

{
    my $dashboard_lib = tempdir( CLEANUP => 1 );
    my $local_shadow  = tempdir( CLEANUP => 1 );
    my $extra_runtime = tempdir( CLEANUP => 1 );
    my $core_arch     = tempdir( CLEANUP => 1 );
    my $core_lib      = tempdir( CLEANUP => 1 );
    no warnings 'redefine';
    local *Developer::Dashboard::PerlEnv::core_inc_paths = sub { return ( $core_arch, $core_lib, $core_lib ) };
    local $ENV{PERL5LIB} = join( Developer::Dashboard::PerlEnv::path_separator(), $local_shadow, '/missing-shadow' );

    my @perl5lib = Developer::Dashboard::PerlEnv->perl5lib_list(
        dashboard_lib => $dashboard_lib,
        extra         => [ $extra_runtime, $extra_runtime, '/missing-extra' ],
    );
    is_deeply(
        \@perl5lib,
        [ $dashboard_lib, $extra_runtime, $core_arch, $core_lib, $local_shadow ],
        'PerlEnv keeps dashboard and runtime libs ahead of core dirs and inherited shadowing local libs while removing duplicates',
    );

    my @explicit_existing = Developer::Dashboard::PerlEnv->perl5lib_list(
        dashboard_lib => $dashboard_lib,
        extra         => [$extra_runtime],
        existing      => [ $local_shadow, $extra_runtime, '/missing-shadow' ],
    );
    is_deeply(
        \@explicit_existing,
        [ $dashboard_lib, $extra_runtime, $core_arch, $core_lib, $local_shadow ],
        'PerlEnv accepts an explicit existing path list without reparsing PERL5LIB from the environment',
    );

    is(
        Developer::Dashboard::PerlEnv->perl5lib_env(
            dashboard_lib => $dashboard_lib,
            extra         => [$extra_runtime],
        ),
        join( Developer::Dashboard::PerlEnv::path_separator(), $dashboard_lib, $extra_runtime, $core_arch, $core_lib, $local_shadow ),
        'PerlEnv joins the normalized path list back into one PERL5LIB string',
    );

    local %ENV = ( PERL5LIB => $local_shadow );
    my $bootstrapped = Developer::Dashboard::PerlEnv->bootstrap_perl5lib(
        dashboard_lib => $dashboard_lib,
        extra         => [$extra_runtime],
    );
    is( $ENV{PERL5LIB}, $bootstrapped, 'PerlEnv bootstrap writes the normalized PERL5LIB back into the environment' );

    local %ENV = ( PATH => join( Developer::Dashboard::PerlEnv::path_separator(), '/bin', '/usr/bin' ) );
    my $path = Developer::Dashboard::PerlEnv->path_with_current_perl;
    like(
        $path,
        qr/^\Q@{[ Developer::Dashboard::PerlEnv->current_perl_bin_dir ]}\E(?:\Q@{[ Developer::Dashboard::PerlEnv::path_separator() ]}\E|$)/,
        'PerlEnv keeps the current Perl interpreter directory at the front of PATH for child processes',
    );
    like(
        $path,
        qr/(?:^|\Q@{[ Developer::Dashboard::PerlEnv::path_separator() ]}\E)\Q@{[ Developer::Dashboard::PerlEnv->current_shell_bin_dir ]}\E(?:\Q@{[ Developer::Dashboard::PerlEnv::path_separator() ]}\E|$)/,
        'PerlEnv also keeps the active shell directory in PATH for shell-based child commands',
    );
    my $child_env = Developer::Dashboard::PerlEnv->dashboard_child_env(
        dashboard_lib => $dashboard_lib,
        extra         => [$extra_runtime],
    );
    is( $child_env->{PATH}, $path, 'PerlEnv child env reuses the PATH override that keeps the current Perl first' );
    like( $child_env->{PERL5LIB}, qr/\Q$dashboard_lib\E/, 'PerlEnv child env also carries the normalized PERL5LIB override' );
}

{
    my $dashboard_install_root = tempdir( CLEANUP => 1 );
    my $dashboard_perl5_root = File::Spec->catdir( $dashboard_install_root, 'perl5' );
    my $dashboard_arch_root = File::Spec->catdir( $dashboard_perl5_root, $Config::Config{archname} );
    make_path( $dashboard_perl5_root, $dashboard_arch_root );

    is_deeply(
        [ Developer::Dashboard::PerlEnv->dashboard_lib_roots($dashboard_install_root) ],
        [ $dashboard_install_root, $dashboard_perl5_root, $dashboard_arch_root ],
        'PerlEnv expands local::lib style dashboard installs into root, perl5, and arch library prefixes',
    );

    my @installed_perl5lib = Developer::Dashboard::PerlEnv->perl5lib_list(
        dashboard_lib => $dashboard_install_root,
        existing      => [],
    );
    is_deeply(
        [ @installed_perl5lib[ 0 .. 2 ] ],
        [ $dashboard_install_root, $dashboard_perl5_root, $dashboard_arch_root ],
        'PerlEnv keeps local::lib style dashboard install library roots at the front of PERL5LIB bootstrap ordering',
    );
}

{
    my @core_inc = Developer::Dashboard::PerlEnv->core_inc_paths;
    ok( @core_inc > 0, 'PerlEnv reports at least one existing core Perl library path for the active interpreter' );
}

my @perl_scripts = (
    File::Spec->catfile( $repo_root, 'bin', 'dashboard' ),
    File::Spec->catfile( $repo_root, 'app.psgi' ),
    (
    map { File::Spec->catfile( $repo_root, 'share', 'private-cli', $_ ) } qw(
      jq
      yq
      tomq
      propq
      iniq
      csvq
      xmlq
      of
      open-file
      ticket
      file
      files
      path
      paths
      ps1
      _dashboard-core
      encode
      decode
      indicator
      collector
      config
      auth
      init
      cpan
      page
      action
      docker
      serve
      stop
      restart
      shell
      doctor
      skills
      which
    ),
    ),
    (
    map { File::Spec->catfile( $repo_root, 't', $_ ) } qw(
      19-skill-system.t
      20-skill-web-routes.t
    ),
    ),
);

push @perl_scripts,
  map { File::Spec->catfile( $repo_root, 'updates', $_ ) } qw(
    01-bootstrap-runtime.pl
    02-install-deps.pl
    03-shell-bootstrap.pl
  )
  if -d File::Spec->catdir( $repo_root, 'updates' );

push @perl_scripts, File::Spec->catfile( $repo_root, 'integration', 'blank-env', 'run-integration.pl' )
  if -d File::Spec->catdir( $repo_root, 'integration' );

for my $path (@perl_scripts) {
    my $content = _slurp($path);
    like( $content, qr/\A#!\/usr\/bin\/env perl\b/, "$path uses /usr/bin/env perl" );
}

done_testing();

sub _slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Unable to read $path: $!";
    my $content = do { local $/; <$fh> };
    close $fh;
    return $content;
}

sub _write_perl_module {
    my ( $path, $content ) = @_;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh;
    return 1;
}

__END__

=head1 NAME

30-dashboard-loader.t - verify dashboard stays thin, lazy, and env-perl based

=head1 DESCRIPTION

This test keeps the public dashboard entrypoint free from embedded bookmark
source, verifies lightweight commands avoid the heavy web runtime, and enforces
the C</usr/bin/env perl> shebang for shipped Perl scripts.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for the thin CLI, helper staging, and low-level runtime contracts. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because the thin CLI, helper staging, and low-level runtime contracts has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing the thin CLI, helper staging, and low-level runtime contracts, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/30-dashboard-loader.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. 

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/30-dashboard-loader.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/30-dashboard-loader.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
