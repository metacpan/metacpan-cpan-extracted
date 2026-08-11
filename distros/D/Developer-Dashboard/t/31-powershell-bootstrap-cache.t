use strict;
use warnings;
use utf8;

use Capture::Tiny qw(capture);
use Cwd qw(getcwd);
use File::Path ();
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

my $UNDER_COVER = exists $INC{'Devel/Cover.pm'};
my $repo = getcwd();

local $ENV{HOME} = tempdir(CLEANUP => 1);
local $ENV{PERL5LIB} = join ':',
    grep { defined && $_ ne '' }
    '/home/mv/perl5/lib/perl5',
    ( $ENV{PERL5LIB} || () );
local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
local $ENV{DEVELOPER_DASHBOARD_CHECKERS};

# A scalar local::lib option carrying a single quote proves the generator
# escapes values for PowerShell single-quoted strings.
local $ENV{PERL_MB_OPT} = q{--install_base 'C:\dd quoted'};
chdir $ENV{HOME} or die "Unable to chdir to $ENV{HOME}: $!";

my $perl      = $^X;
my $lib       = File::Spec->catdir( $repo, 'lib' );
my $dashboard = File::Spec->catfile( $repo, 'bin', 'dashboard' );

# Run dashboard init first to stage helpers and create the runtime root
{
    my ( $stdout, $stderr, $exit_code ) = capture {
        system $perl, '-I', $lib, $dashboard, 'init';
        $? >> 8;
    };
    is( $exit_code, 0, 'dashboard init stages the private helpers' )
      or die "dashboard init failed: $stderr";
}

# Now run dashboard shell ps — this triggers _cache_powershell_bootstrap
{
    my ( $stdout, $stderr, $exit_code ) = capture {
        system $perl, '-I', $lib, $dashboard, 'shell', 'ps';
        $? >> 8;
    };
    is( $exit_code, 0, 'dashboard shell ps exits successfully' )
      or do {
        diag "STDOUT: $stdout" if $stdout;
        diag "STDERR: $stderr" if $stderr;
    };
}

# Check that the cache directory was created
my $runtime_root = File::Spec->catdir( $ENV{HOME}, '.developer-dashboard' );
my $cache_dir    = File::Spec->catdir( $runtime_root, 'cache' );
ok( -d $cache_dir, 'cache directory was created' );

# Check powershell-bootstrap.ps1 exists and is non-empty
my $bootstrap_cache = File::Spec->catfile( $cache_dir, 'powershell-bootstrap.ps1' );
ok( -f $bootstrap_cache, 'powershell-bootstrap.ps1 cache file exists' );
ok( -s $bootstrap_cache, 'powershell-bootstrap.ps1 cache file is non-empty' );

# Verify it contains the PowerShell prompt function definition
my $bootstrap_content;
{
    open my $fh, '<:raw', $bootstrap_cache or die "Unable to read $bootstrap_cache: $!";
    local $/;
    $bootstrap_content = <$fh>;
    close $fh;
}
like( $bootstrap_content, qr/function prompt \{/, 'powershell-bootstrap.ps1 contains the PowerShell prompt function definition' );
like( $bootstrap_content, qr/function cdr \{/,       'powershell-bootstrap.ps1 contains the cdr function definition' );
like( $bootstrap_content, qr/Register-ArgumentCompleter/, 'powershell-bootstrap.ps1 wires argument completion' );

# Assert atomic-write (no .pending file left behind)
my $pending_count = 0;
opendir my $dh, $cache_dir or die "Unable to read $cache_dir: $!";
for my $entry ( readdir $dh ) {
    $pending_count++ if $entry =~ /\.pending\z/;
}
closedir $dh;
is( $pending_count, 0, 'no .pending files remain after atomic write+rename' );

# Check powershell-env.ps1 exists and has env var assignments
my $env_cache = File::Spec->catfile( $cache_dir, 'powershell-env.ps1' );
ok( -f $env_cache, 'powershell-env.ps1 cache file exists' );
my $env_content;
{
    open my $fh, '<:raw', $env_cache or die "Unable to read $env_cache: $!";
    local $/;
    $env_content = <$fh>;
    close $fh;
}
like( $env_content, qr/^\$env:/m, 'powershell-env.ps1 contains $env: variable assignments' );

# Verify at least one known env var is present (PATH or PERL5LIB)
my $has_known_var = $env_content =~ /^\$env:(?:PATH|PERL5LIB)\b/m ? 1 : 0;
ok( $has_known_var, 'powershell-env.ps1 sets at least one known local::lib environment variable (PATH or PERL5LIB)' );

# The pre-cache profile block re-derived PATH through a live perl local::lib
# subprocess that inherited the session PATH, so entries the session already
# carried survived. A cached absolute snapshot must not clobber them: the
# cached entries are prepended to whatever the live session has.
for my $list_key (qw(PATH PERL5LIB)) {
    like(
        $env_content,
        qr/^\$env:\Q$list_key\E = \(\(\@\(/m,
        "powershell-env.ps1 rebuilds \$env:$list_key from a cached entry list instead of assigning a frozen snapshot"
    );
    like(
        $env_content,
        qr/^\$env:\Q$list_key\E = .*\Q$list_key\E -split /m,
        "powershell-env.ps1 merges the live \$env:$list_key entries behind the cached entries"
    );
    unlike(
        $env_content,
        qr/^\$env:\Q$list_key\E='/m,
        "powershell-env.ps1 never overwrites \$env:$list_key with an install-time snapshot"
    );
}

# Non-list local::lib options stay direct assignments, single-quote escaped.
like(
    $env_content,
    qr/^\$env:PERL_MB_OPT='--install_base ''C:\\dd quoted'''$/m,
    'powershell-env.ps1 assigns scalar local::lib options directly and doubles embedded single quotes'
);

# The managed PowerShell profile always reads $HOME/.developer-dashboard/cache,
# so the generator must write there regardless of which DD-OOP-LAYER the
# refreshing shell happens to be standing in. Writing into a deeper project
# layer would leave the profile reading a cache nothing ever refreshes.
{
    my $home_cache_dir = $cache_dir;
    my $project        = File::Spec->catdir( $ENV{HOME}, 'proj' );
    my $project_cache  = File::Spec->catdir( $project, '.developer-dashboard', 'cache' );
    File::Path::make_path( File::Spec->catdir( $project, '.developer-dashboard' ) );
    File::Path::make_path( File::Spec->catdir( $project, '.git' ) );

    # Remove the home-layer caches so only a fresh write can restore them.
    unlink $bootstrap_cache, $env_cache;
    ok( !-e $bootstrap_cache, 'home-layer bootstrap cache removed before the project-layer refresh' );

    chdir $project or die "Unable to chdir to $project: $!";
    my ( $stdout, $stderr, $exit_code ) = capture {
        system $perl, '-I', $lib, $dashboard, 'shell', 'ps';
        $? >> 8;
    };
    chdir $ENV{HOME} or die "Unable to chdir to $ENV{HOME}: $!";

    is( $exit_code, 0, 'dashboard shell ps exits successfully from inside a project runtime layer' )
      or diag "STDERR: $stderr";
    ok( -s File::Spec->catfile( $home_cache_dir, 'powershell-bootstrap.ps1' ),
        'a project-layer refresh rewrites the home-layer PowerShell bootstrap cache' );
    ok( -s File::Spec->catfile( $home_cache_dir, 'powershell-env.ps1' ),
        'a project-layer refresh rewrites the home-layer PowerShell environment cache' );
    ok( !-e File::Spec->catfile( $project_cache, 'powershell-bootstrap.ps1' ),
        'a project-layer refresh does not strand the PowerShell bootstrap cache in the project layer' );
    ok( !-e File::Spec->catfile( $project_cache, 'powershell-env.ps1' ),
        'a project-layer refresh does not strand the PowerShell environment cache in the project layer' );
}

done_testing;

__END__

=head1 NAME

t/31-powershell-bootstrap-cache.t - PowerShell bootstrap cache integration test

=head1 PURPOSE

Verify that the C<dashboard init> command stages private helper tools and
that C<dashboard shell ps> successfully creates the PowerShell bootstrap
and environment-variable cache files (powershell-bootstrap.ps1,
powershell-env.ps1) under the runtime root.

=head1 WHY IT EXISTS

The dashboard caches a generated PowerShell profile script so that
every new PowerShell session does not need to re-derive the environment
setup.  This test ensures the cache is created, is non-empty, contains
the expected function definitions, and is written atomically (no stale
.pending files).

=head1 WHEN TO USE

Run this test after any change to the PowerShell bootstrap generation
path in the dashboard CLI (typically C<_dashboard-core> or the shell
plugin).  Also run after changes to the atomic-write mechanism used by
the cache layer.

=head1 HOW TO USE

  prove -lv t/31-powershell-bootstrap-cache.t

=head1 WHAT USES IT

L<Developer::Dashboard::Shell::PS> (via the C<dashboard shell ps>
command), the C<dashboard init> command, and the atomic-write helpers
in the runtime layer.

=head1 EXAMPLES

  # Full run with verbose output
  prove -lv t/31-powershell-bootstrap-cache.t

  # Run as part of the full suite
  make test

=cut
