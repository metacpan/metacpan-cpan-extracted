#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny qw(capture);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($RealBin);
use Test::More;

use lib File::Spec->catdir( $RealBin, File::Spec->updir, 'lib' );
use Developer::Dashboard::InternalCLI ();

my $root = File::Spec->catdir( $RealBin, File::Spec->updir );
my $install_sh = File::Spec->catfile( $root, 'install.sh' );
my $install_ps = File::Spec->catfile( $root, 'install.ps1' );
my $aptfile    = File::Spec->catfile( $root, 'aptfile' );
my $apkfile    = File::Spec->catfile( $root, 'apkfile' );
my $dnfile     = File::Spec->catfile( $root, 'dnfile' );
my $brewfile   = File::Spec->catfile( $root, 'brewfile' );
my $default_bootstrap_repository = 'https://github.com/manif3station/developer-dashboard.git';
my $perlbrew_app_dist_url = 'https://cpan.metacpan.org/authors/id/G/GU/GUGOD/App-perlbrew-1.02.tar.gz';
my $perlbrew_app_dist_basename = 'App-perlbrew-1.02.tar.gz';

ok( -f $install_sh, 'install.sh exists at the repo root' );
ok( -f $install_ps, 'install.ps1 exists at the repo root' );
ok( -f $aptfile, 'aptfile exists at the repo root' );
ok( -f $apkfile, 'apkfile exists at the repo root' );
ok( -f $dnfile, 'dnfile exists at the repo root' );
ok( -f $brewfile, 'brewfile exists at the repo root' );
like( _slurp(File::Spec->catfile( $root, 'Makefile.PL' )), qr/VERSION_FROM\s*=>\s*'lib\/Developer\/Dashboard\.pm'/, 'Makefile.PL uses a filesystem path for VERSION_FROM so checkout installs work on Windows' );
like( _slurp(File::Spec->catfile( $root, 'Makefile.PL' )), qr/use\s+File::ShareDir::Install\s+qw\(install_share\);/, 'Makefile.PL loads File::ShareDir::Install so packaged installs can refresh shipped helper assets under auto/share/dist' );
like( _slurp(File::Spec->catfile( $root, 'Makefile.PL' )), qr/install_share\s+dist\s*=>\s*'share';/, 'Makefile.PL explicitly installs the repo share tree so packaged helper assets stay in sync with the tarball' );
like( _slurp(File::Spec->catfile( $root, 'Makefile.PL' )), qr/package\s+MY;\s*use\s+File::ShareDir::Install\s+qw\(postamble\);/s, 'Makefile.PL exports the File::ShareDir::Install postamble into package MY so share assets actually install' );
like( _slurp(File::Spec->catfile( $root, 'Makefile.PL' )), qr/File::ShareDir::Install::postamble\(\s*\$self\s*\)/, 'Makefile.PL chains the share-dir installer postamble before its checkout bootstrap hook' );
like( _slurp(File::Spec->catfile( $root, 'Makefile.PL' )), qr/install\s+::\s*\n\t\$\(NOECHO\)\s+\$\(PERL\)\s+-e\s+"1;"/, 'Makefile.PL gives the Windows gmake install target an explicit no-op recipe so it does not synthesize install from install.sh' );
like( _slurp(File::Spec->catfile( $root, 'Makefile.PL' )), qr/pure_install\s+::\s+install-private-cli-tools/, 'Makefile.PL runs the private helper staging hook from pure_install instead of a recipe-less install target' );
{
    my $makefile_text = _slurp( File::Spec->catfile( $root, 'Makefile.PL' ) );
    like(
        $makefile_text,
        qr/for my \$\$cmd \(qw\(([^)]*)\)\)/s,
        'Makefile.PL declares the checkout bootstrap helper seed list explicitly',
    );
    my ($helper_list) = $makefile_text =~ /for my \$\$cmd \(qw\(([^)]*)\)\)/s;
    my @seeded_helpers = split /\s+/, $helper_list || '';
    my @expected_helpers = ( '_dashboard-core', Developer::Dashboard::InternalCLI::helper_names() );
    is_deeply(
        \@seeded_helpers,
        \@expected_helpers,
        'Makefile.PL checkout bootstrap seeds the full current private helper set into the home runtime',
    );
}

{
    my ( $stdout, $stderr, $exit ) = capture {
        system( 'sh', '-n', $install_sh );
    };
    is( $exit >> 8, 0, 'install.sh passes POSIX shell syntax validation' )
      or diag $stdout . $stderr;
}

{
    my $install_sh_text = _slurp($install_sh);
    unlike(
        $install_sh_text,
        qr/CPAN_TARGET="\$\{DD_INSTALL_CPAN_TARGET:-Developer::Dashboard\}"/,
        'install.sh no longer defaults Unix-like streamed installs to the stale CPAN module name',
    );
    like(
        $install_sh_text,
        qr{\Q$default_bootstrap_repository\E},
        'install.sh knows the canonical GitHub repository for the default streamed Unix-like checkout target',
    );
    like(
        $install_sh_text,
        qr/git clone --depth 1 --branch master/,
        'install.sh clones the current GitHub master checkout when no explicit Unix-like install target override is set',
    );
    like(
        $install_sh_text,
        qr/run_cpanm --notest \./,
        'install.sh installs the resolved local checkout with cpanm dot for default Unix-like bootstrap targets',
    );
}

{
    my $install_ps_text = _slurp($install_ps);
    like( $install_ps_text, qr/Set-StrictMode -Version Latest/, 'install.ps1 enables strict PowerShell mode' );
    like( $install_ps_text, qr/\$ErrorActionPreference = 'Stop'/, 'install.ps1 treats PowerShell errors as fatal' );
    like( $install_ps_text, qr/^\& \{/m, 'install.ps1 wraps its body in a script block so the streamed irm ... | iex path stays valid' );
    like( $install_ps_text, qr/Developer Dashboard install progress/, 'install.ps1 prints the Windows progress board title' );
    like( $install_ps_text, qr/winget/, 'install.ps1 uses winget to bootstrap missing Windows packages' );
    like( $install_ps_text, qr/--source',\s*'winget'/, 'install.ps1 pins Windows package installs to the winget source so a broken msstore source does not block bootstrap installs' );
    like( $install_ps_text, qr/source\s+reset|winget source reset/s, 'install.ps1 includes a winget source repair path for bootstrap failures' );
    like( $install_ps_text, qr/Format-ExitCode/, 'install.ps1 formats native Windows exit codes so winget failures show their HRESULT value' );
    like( $install_ps_text, qr/System\.BitConverter.*ToUInt32/s, 'install.ps1 formats negative HRESULT exit codes through BitConverter instead of a failing direct uint32 cast' );
    like( $install_ps_text, qr/function Set-TlsSecurityProtocol/, 'install.ps1 defines a shared TLS hardening helper for Windows bootstrap downloads' );
    like( $install_ps_text, qr/SecurityProtocolType\]::Tls12/, 'install.ps1 explicitly enables TLS 1.2 for bootstrap web requests' );
    like( $install_ps_text, qr/function Download-RemoteFile/, 'install.ps1 defines a shared resilient file downloader for Windows bootstrap assets' );
    like( $install_ps_text, qr/function Get-RemoteJson/, 'install.ps1 defines a shared resilient JSON downloader for Windows bootstrap metadata' );
    like( $install_ps_text, qr/function Invoke-InstallerCommand/, 'install.ps1 defines a dedicated installer runner for GUI and MSI bootstrap packages' );
    like( $install_ps_text, qr/Start-Process\s+-FilePath\s+\$FilePath\s+-ArgumentList\s+\$Arguments\s+-PassThru\s+-Wait/s, 'install.ps1 waits for GUI and MSI installers through Start-Process instead of piping them like console commands' );
    like( $install_ps_text, qr/curl\.exe|curl/, 'install.ps1 can fall back to curl when Invoke-WebRequest is unreliable inside the Windows guest' );
    like( $install_ps_text, qr/WebClient/, 'install.ps1 can fall back to System\.Net\.WebClient when both Invoke-WebRequest and curl are unavailable or broken' );
    like( $install_ps_text, qr/Install-WindowsPackageFallback/, 'install.ps1 defines an explicit fallback installer path when winget source repair still cannot install a required package' );
    like( $install_ps_text, qr/function Resolve-GitForWindowsInstallerUrl/, 'install.ps1 resolves the latest Git for Windows installer URL dynamically instead of trusting a brittle static redirect' );
    like( $install_ps_text, qr/git-for-windows\/git\/releases\/latest/, 'install.ps1 uses the official Git for Windows latest release page as the source of truth for the fallback installer asset' );
    like( $install_ps_text, qr/git-for-windows\/git\/releases\/download/, 'install.ps1 builds the final Git for Windows fallback asset URL from the resolved release tag and installer filename' );
    like( $install_ps_text, qr/Git-64-bit\.exe/, 'install.ps1 can fall back to the official Git for Windows installer download when winget remains broken' );
    like( $install_ps_text, qr/strawberryperl\.com\/releases\.json/, 'install.ps1 resolves Strawberry Perl fallback installers from the official release feed' );
    like( $install_ps_text, qr/nodejs\.org\/dist\/index\.json/, 'install.ps1 resolves Node.js LTS fallback installers from the official Node release index' );
    unlike( $install_ps_text, qr/Invoke-RestMethod\s+-Uri\s+'https:\/\/strawberryperl\.com\/releases\.json'/, 'install.ps1 no longer hard-codes Invoke-RestMethod for the Strawberry Perl release feed' );
    unlike( $install_ps_text, qr/Invoke-RestMethod\s+-Uri\s+'https:\/\/nodejs\.org\/dist\/index\.json'/, 'install.ps1 no longer hard-codes Invoke-RestMethod for the Node.js release index' );
    unlike( $install_ps_text, qr/Invoke-WebRequest\s+-Uri\s+'https:\/\/github\.com\/git-for-windows\/git\/releases\/latest\/download\/Git-64-bit\.exe'/, 'install.ps1 no longer hard-codes Invoke-WebRequest for the stale Git fallback installer download URL' );
    unlike( $install_ps_text, qr/Invoke-WebRequest\s+-Uri\s+'https:\/\/cpanmin\.us\/'/, 'install.ps1 no longer hard-codes Invoke-WebRequest for the cpanm bootstrap script download' );
    like( $install_ps_text, qr/msiexec\.exe/, 'install.ps1 uses msiexec for MSI-based Windows fallback installers' );
    like( $install_ps_text, qr/2>&1 \| ForEach-Object \{ Write-Host \$\_ \}/, 'install.ps1 streams native command output to the host instead of leaking it into helper return values' );
    like( $install_ps_text, qr/\$previousErrorActionPreference\s*=\s*\$ErrorActionPreference/s, 'install.ps1 snapshots PowerShell error handling before streaming native command stderr' );
    like( $install_ps_text, qr/\$ErrorActionPreference\s*=\s*'Continue'/s, 'install.ps1 downgrades native stderr records while streaming command output so git and winget progress do not abort the bootstrap' );
    like( $install_ps_text, qr/Refresh-ProcessPathFromEnvironment/, 'install.ps1 refreshes the current PATH after winget installs new tools' );
    like( $install_ps_text, qr/cpanmin\.us/, 'install.ps1 bootstraps cpanm for Windows installs from the standalone cpanmin.us script' );
    unlike( $install_ps_text, qr/'local::lib'\s*,\s*'App::cpanminus'/, 'install.ps1 no longer tries to self-install App::cpanminus while the downloaded cpanm script is still running on Windows' );
    like( $install_ps_text, qr{https://github\.com/manif3station/developer-dashboard\.git}, 'install.ps1 knows the canonical GitHub repository for the streamed Windows bootstrap source' );
    like( $install_ps_text, qr/git\s+clone/s, 'install.ps1 clones the current GitHub master source for the default streamed Windows install target' );
    like( $install_ps_text, qr/Push-Location\s+\$effectiveCpanTarget/s, 'install.ps1 installs the default cloned Windows checkout from inside the local checkout directory' );
    like( $install_ps_text, qr/Sync-LocalLibEnvironmentFromPerl/, 'install.ps1 delegates local::lib environment setup to perl so Windows install paths stay canonical' );
    like(
        $install_ps_text,
        qr/'--notest',\s*'--local-lib-contained',\s*\$InstallRoot,\s*'local::lib',\s*'File::ShareDir::Install'/s,
        'install.ps1 bootstraps the checkout configure prerequisite into the private Windows install root before it installs the checkout',
    );
    like( $install_ps_text, qr/--notest',\s*'--local-lib-contained',\s*\$InstallRoot,\s*'\.'/s, 'install.ps1 runs cpanm against dot with an explicit local-lib target for the default cloned Windows checkout' );
    like( $install_ps_text, qr/--notest',\s*'--local-lib-contained',\s*\$InstallRoot,\s*\$effectiveCpanTarget/s, 'install.ps1 runs cpanm against explicit Windows targets with the same local-lib target' );
    like( $install_ps_text, qr/Sync-LocalLibEnvironmentFromPerl\s+-PerlPath\s+\$perlPath\s+-TargetInstallRoot\s+\$InstallRoot/s, 'install.ps1 reapplies the perl-reported local::lib environment after bootstrapping local::lib on Windows' );
    like( $install_ps_text, qr/Ensure-ProfileContains\s+-TargetProfile\s+\$ProfilePath\s+-Block\s+\$profileBlock\s+-Marker\s+'Developer Dashboard bootstrap'/s, 'install.ps1 replaces the managed Developer Dashboard profile block instead of appending duplicate stale Windows bootstrap chunks' );
    like( $install_ps_text, qr/# >>> Developer Dashboard bootstrap >>>/, 'install.ps1 wraps the managed PowerShell profile block in a stable begin marker' );
    like( $install_ps_text, qr/# <<< Developer Dashboard bootstrap <<</, 'install.ps1 wraps the managed PowerShell profile block in a stable end marker' );
    like( $install_ps_text, qr/\[Regex\]::Escape\(\$beginMarker\)/, 'install.ps1 escapes the managed begin marker with the .NET regex API before replacing older profile blocks' );
    like( $install_ps_text, qr/\[Regex\]::Escape\(\$endMarker\)/, 'install.ps1 escapes the managed end marker with the .NET regex API before replacing older profile blocks' );
    unlike( $install_ps_text, qr/\\Q\$beginMarker\\E|\\Q\$endMarker\\E/, 'install.ps1 avoids Perl-style \\Q...\\E regex quoting that PowerShell does not support in [Regex]::Replace' );
    like( $install_ps_text, qr/legacyManagedPattern/, 'install.ps1 strips legacy unmarked Developer Dashboard profile blocks from earlier Windows bootstrap failures' );
    like( $install_ps_text, qr/Join-Path\s+\`\$HOME\s+'.developer-dashboard\\cli\\dd\\_dashboard-core'/s, 'install.ps1 only asks dashboard shell ps for profile bootstrap when the staged home helper runtime is present' );
    like( $install_ps_text, qr/\$profilePerlRuntimePaths\s*=\s*\@/s, 'install.ps1 captures the resolved Strawberry Perl runtime directories before writing the managed PowerShell profile block' );
    like( $install_ps_text, qr/\`\$ddPerlRuntimePaths\s*=\s*\@/s, 'install.ps1 writes the Strawberry Perl runtime directories into the managed PowerShell profile block for future sessions' );
    like( $install_ps_text, qr/foreach\s+\(\`\$ddPerlRuntimePath in \`\$ddPerlRuntimePaths\)/s, 'install.ps1 prepends the persisted Strawberry Perl runtime directories in future PowerShell sessions before resolving dashboard' );
    like( $install_ps_text, qr/\$ddShellBootstrap\s*=\s*&\s+dashboard\s+shell\s+ps/s, 'install.ps1 captures dashboard shell ps output before invoking it in the profile' );
    unlike( $install_ps_text, qr/\$ddShellBootstrapText\s*=\s*Join-ScriptText\s+-Value\s+\`\$ddShellBootstrap/s, 'install.ps1 does not leak installer-only Join-ScriptText helper calls into the generated PowerShell profile block' );
    like( $install_ps_text, qr/\$ddShellBootstrapText\s*=\s*\(\(@\(\`\$ddShellBootstrap \| Where-Object \{ .*? \} \| ForEach-Object \{ .*? \}\)\) -join \[Environment\]::NewLine\)/s, 'install.ps1 normalizes dashboard shell ps output arrays inline inside the generated PowerShell profile block' );
    like( $install_ps_text, qr/if\s+\(-not\s+\[string\]::IsNullOrWhiteSpace\(\`\$ddShellBootstrapText\)\)\s*\{\s*Invoke-Expression\s+\`\$ddShellBootstrapText/s, 'install.ps1 skips Invoke-Expression when the normalized profile bootstrap is empty' );
    like( $install_ps_text, qr/Invoke-NativeCommand\s+-Label\s+'dashboard init'\s+-FilePath\s+\$dashboardCommand\s+-Arguments\s+\@\(\'init\'\).*?&\s+\$dashboardCommand\s+shell\s+ps/s, 'install.ps1 initializes the dashboard runtime before asking the installed dashboard command for its PowerShell bootstrap' );
    like( $install_ps_text, qr/\$dashboardShellBootstrapText\s*=\s*Join-ScriptText\s+-Value\s+\$dashboardShellBootstrap/s, 'install.ps1 normalizes the current-session dashboard shell ps output into one script string' );
    unlike( $install_ps_text, qr/Invoke-Expression\s+\(&\s+\$dashboardCommand\s+shell\s+ps\)/, 'install.ps1 no longer invokes dashboard shell ps directly without checking for empty output' );
    unlike( $install_ps_text, qr/\$CpanTarget\s*=\s*if\s*\(\[string\]::IsNullOrWhiteSpace\(\$env:DD_INSTALL_CPAN_TARGET\)\)\s*\{\s*'Developer::Dashboard'\s*\}/, 'install.ps1 no longer defaults streamed Windows installs to the stale CPAN module name' );
    like( $install_ps_text, qr/cpanm.*--notest/s, 'install.ps1 installs Developer Dashboard with cpanm --notest on Windows' );
    like( $install_ps_text, qr/dashboard init/, 'install.ps1 initializes the dashboard runtime after the Windows install' );
    like( $install_ps_text, qr/dashboard shell ps/, 'install.ps1 activates the PowerShell bootstrap after installation' );
    like( $install_ps_text, qr/Set-ExecutionPolicy\s+-Scope\s+CurrentUser\s+-ExecutionPolicy\s+RemoteSigned\s+-Force/s, 'install.ps1 enables a CurrentUser PowerShell execution policy that can load the generated profile in future sessions' );
    like( $install_ps_text, qr/ExecutionPolicyOverride/, 'install.ps1 treats the benign CurrentUser execution-policy override warning explicitly during streamed bootstrap runs' );
    like( $install_ps_text, qr/kept the saved CurrentUser policy and continued/s, 'install.ps1 explains when a more specific PowerShell execution-policy scope keeps the current session in Bypass while the saved CurrentUser policy still succeeds' );
    like( $install_ps_text, qr/Get-ExecutionPolicy\s+-Scope\s+CurrentUser/s, 'install.ps1 inspects the current-user execution policy before changing it' );
    like( $install_ps_text, qr/-Mlocal::lib=\$normalizedInstallRoot/s, 'install.ps1 asks perl local::lib for canonical Windows environment values instead of composing INSTALL_BASE manually' );
    like( $install_ps_text, qr/-Mlocal::lib=\`\$ddInstallRootForward/s, 'install.ps1 writes a profile block that refreshes local::lib from perl in future PowerShell sessions' );
}

my @apt_packages  = _manifest_lines($aptfile);
my @apk_packages  = _manifest_lines($apkfile);
my @dnf_packages  = _manifest_lines($dnfile);
my @brew_packages = _manifest_lines($brewfile);
ok( scalar grep { $_ eq 'tmux' } @apt_packages,  'aptfile includes tmux because dashboard workspace depends on it' );
ok( scalar grep { $_ eq 'tmux' } @apk_packages,  'apkfile includes tmux because dashboard workspace depends on it' );
ok( scalar grep { $_ eq 'tmux' } @dnf_packages,  'dnfile includes tmux because dashboard workspace depends on it' );
ok( scalar grep { $_ eq 'tmux' } @brew_packages, 'brewfile includes tmux because dashboard workspace depends on it' );
my @expected_apt_bootstrap_steps = _expected_apt_bootstrap_steps(
    packages => \@apt_packages,
);
my @expected_apk_bootstrap_steps = _expected_apk_bootstrap_steps(
    packages => \@apk_packages,
);
my @expected_dnf_bootstrap_steps = _expected_dnf_bootstrap_steps(
    packages => \@dnf_packages,
);

{
    my $home = tempdir( CLEANUP => 1 );
    my $fake_bin = tempdir( CLEANUP => 1 );
    my $log = File::Spec->catfile( $home, 'install.log' );
    my $target = File::Spec->catfile( $home, 'Developer-Dashboard.tar.gz' );
    my $fake_perl = File::Spec->catfile( $fake_bin, 'perl' );
    _seed_fake_install_commands(
        fake_bin => $fake_bin,
        log      => $log,
    );

    my $env_prefix = join ' ',
      map { sprintf q{%s='%s'}, $_->{key}, $_->{value} } (
        { key => 'HOME',                   value => $home },
        { key => 'PATH',                   value => $fake_bin . ':' . ( $ENV{PATH} || '' ) },
        { key => 'SHELL',                  value => '/bin/bash' },
        { key => 'DD_INSTALL_OS_OVERRIDE', value => 'fedora' },
        { key => 'DD_INSTALL_CPAN_TARGET', value => $target },
      );

    my ( $stdout, $stderr, $exit ) = capture {
        system( 'sh', '-c', "$env_prefix '$install_sh'" );
    };
    is( $exit >> 8, 0, 'install.sh succeeds on Fedora hosts with mocked system commands' )
      or diag $stdout . $stderr;

    my @log_lines = _log_lines($log);
    is_deeply(
        \@log_lines,
        [
            @expected_dnf_bootstrap_steps,
            'perl -e exit(($] >= 5.038) ? 0 : 1)',
            "cpanm --no-wget --notest --local-lib-contained $home/perl5 local::lib App::cpanminus File::ShareDir::Install",
            "perl -I $home/perl5/lib/perl5 -Mlocal::lib",
            "cpanm --no-wget --notest $target",
            'dashboard init',
        ],
        'install.sh follows the Fedora bootstrap flow in manifest order',
    );

    my $bashrc = File::Spec->catfile( $home, '.bashrc' );
    my $profile = File::Spec->catfile( $home, '.profile' );
    ok( -f $bashrc, 'install.sh creates or updates ~/.bashrc for Fedora bash users' );
    ok( -f $profile, 'install.sh creates ~/.profile as the activation entry point for Fedora bash users' );
    my $bashrc_text = _slurp($bashrc);
    my $local_lib_line = qq{eval "\$("$fake_perl" -I "$home/perl5/lib/perl5" -Mlocal::lib)"};
    like(
        $bashrc_text,
        qr/\Q$local_lib_line\E/,
        'install.sh wires the local::lib bootstrap into ~/.bashrc for Fedora bash users',
    );
    like(
        $bashrc_text,
        qr/eval "\$\(\"[^\"]*\/dashboard" shell bash\)"/,
        'install.sh appends the Developer Dashboard bash shell bootstrap to ~/.bashrc on Fedora',
    );
}

{
    my $home = tempdir( CLEANUP => 1 );
    my $fake_bin = tempdir( CLEANUP => 1 );
    my $log = File::Spec->catfile( $home, 'install.log' );
    my $target = File::Spec->catfile( $home, 'Developer-Dashboard.tar.gz' );
    my $fake_perl = File::Spec->catfile( $fake_bin, 'perl' );
    _seed_fake_install_commands(
        fake_bin => $fake_bin,
        log      => $log,
    );

    my $env_prefix = join ' ',
      map { sprintf q{%s='%s'}, $_->{key}, $_->{value} } (
        { key => 'HOME',                   value => $home },
        { key => 'PATH',                   value => $fake_bin . ':' . ( $ENV{PATH} || '' ) },
        { key => 'SHELL',                  value => '/bin/sh' },
        { key => 'DD_INSTALL_OS_OVERRIDE', value => 'alpine' },
        { key => 'DD_INSTALL_CPAN_TARGET', value => $target },
      );

    my ( $stdout, $stderr, $exit ) = capture {
        system( 'sh', '-c', "$env_prefix '$install_sh'" );
    };
    is( $exit >> 8, 0, 'install.sh succeeds on Alpine hosts with mocked system commands' )
      or diag $stdout . $stderr;

    my @log_lines = _log_lines($log);
    is_deeply(
        \@log_lines,
        [
            @expected_apk_bootstrap_steps,
            'perl -e exit(($] >= 5.038) ? 0 : 1)',
            "cpanm --no-wget --notest --local-lib-contained $home/perl5 local::lib App::cpanminus File::ShareDir::Install",
            "perl -I $home/perl5/lib/perl5 -Mlocal::lib",
            "cpanm --no-wget --notest $target",
            'dashboard init',
        ],
        'install.sh follows the Alpine bootstrap flow in manifest order',
    );

    my $profile = File::Spec->catfile( $home, '.profile' );
    ok( -f $profile, 'install.sh creates ~/.profile for Alpine sh users' );
    my $profile_text = _slurp($profile);
    my $local_lib_line = qq{eval "\$("$fake_perl" -I "$home/perl5/lib/perl5" -Mlocal::lib)"};
    like(
        $profile_text,
        qr/\Q$local_lib_line\E/,
        'install.sh wires the local::lib bootstrap into ~/.profile for Alpine sh users',
    );
    like(
        $profile_text,
        qr/eval "\$\(\"[^\"]*\/dashboard" shell sh\)"/,
        'install.sh appends the Developer Dashboard sh shell bootstrap to ~/.profile on Alpine',
    );
    like(
        $stdout,
        qr/Shell setup was written to: \Q$profile\E/s,
        'install.sh reports the Alpine rc file it updated',
    );
}

{
    my $home = tempdir( CLEANUP => 1 );
    my $fake_bin = tempdir( CLEANUP => 1 );
    my $log = File::Spec->catfile( $home, 'install.log' );
    my $target = File::Spec->catfile( $home, 'Developer-Dashboard.tar.gz' );
    my $fake_perl = File::Spec->catfile( $fake_bin, 'perl' );
    _seed_fake_install_commands(
        fake_bin => $fake_bin,
        log      => $log,
    );

    my $env_prefix = join ' ',
      map { sprintf q{%s='%s'}, $_->{key}, $_->{value} } (
        { key => 'HOME',                   value => $home },
        { key => 'PATH',                   value => $fake_bin . ':' . ( $ENV{PATH} || '' ) },
        { key => 'SHELL',                  value => '/bin/bash' },
        { key => 'DD_INSTALL_OS_OVERRIDE', value => 'ubuntu' },
        { key => 'DD_INSTALL_CPAN_TARGET', value => $target },
      );

    my $existing_bashrc = File::Spec->catfile( $home, '.bashrc' );
    open my $existing_bashrc_fh, '>', $existing_bashrc or die "Unable to seed $existing_bashrc: $!";
    print {$existing_bashrc_fh} <<'BASHRC';
[ -z "$PS1" ] && return
BASHRC
    close $existing_bashrc_fh or die "Unable to close $existing_bashrc: $!";

    my ( $stdout, $stderr, $exit ) = capture {
        system( 'sh', '-c', "$env_prefix '$install_sh'" );
    };
    is( $exit >> 8, 0, 'install.sh succeeds on Debian-family hosts with mocked system commands' )
      or diag $stdout . $stderr;
    like(
        $stdout,
        qr/Developer Dashboard install progress/,
        'install.sh prints a visible progress board before running Debian-family bootstrap work',
    );
    is(
        scalar( () = $stdout =~ /Developer Dashboard install progress/g ),
        1,
        'install.sh prints the progress board header once and then emits step transitions without redrawing the whole board',
    );
    if ( ( $> || 0 ) == 0 ) {
        unlike(
            $stdout,
            qr/sudo will ask for your operating-system account password, not a Developer Dashboard password/s,
            'install.sh skips the sudo password explanation when it is already running as root',
        );
    }
    else {
        like(
            $stdout,
            qr/sudo will ask for your operating-system account password, not a Developer Dashboard password/s,
            'install.sh explains the sudo password prompt before requesting system package access',
        );
    }

    my @log_lines = _log_lines($log);
    is_deeply(
        \@log_lines,
        [
            @expected_apt_bootstrap_steps,
            'perl -e exit(($] >= 5.038) ? 0 : 1)',
            "cpanm --no-wget --notest --local-lib-contained $home/perl5 local::lib App::cpanminus File::ShareDir::Install",
            "perl -I $home/perl5/lib/perl5 -Mlocal::lib",
            "cpanm --no-wget --notest $target",
            'dashboard init',
        ],
        'install.sh follows the Debian-family bootstrap flow in manifest order',
    );

    my $bashrc = File::Spec->catfile( $home, '.bashrc' );
    my $profile = File::Spec->catfile( $home, '.profile' );
    ok( -f $bashrc, 'install.sh creates or updates ~/.bashrc for bash users' );
    ok( -f $profile, 'install.sh creates ~/.profile as the activation entry point for bash users' );
    my $bashrc_text = _slurp($bashrc);
    my $profile_text = _slurp($profile);
    my $local_lib_line = qq{eval "\$("$fake_perl" -I "$home/perl5/lib/perl5" -Mlocal::lib)"};
    like(
        $bashrc_text,
        qr/\Q$local_lib_line\E/,
        'install.sh wires the local::lib bootstrap through the resolved Perl interpreter on PATH',
    );
    like(
        $bashrc_text,
        qr/eval "\$\(\"[^\"]*\/dashboard" shell bash\)"/,
        'install.sh appends the Developer Dashboard bash shell bootstrap to ~/.bashrc',
    );
    ok(
        $bashrc_text =~ qr/\Q$local_lib_line\E\n.*eval "\$\(\"[^\"]*\/dashboard" shell bash\)".*\ncase \$- in/s
          || $bashrc_text =~ qr/\Q$local_lib_line\E\n.*eval "\$\(\"[^\"]*\/dashboard" shell bash\)".*\n\[ -z "\$PS1" \] && return/s,
        'install.sh keeps dashboard-managed bash bootstrap lines ahead of the non-interactive return guard in ~/.bashrc',
    );
    like(
        $profile_text,
        qr/if \[ -f "\$HOME\/\.bashrc" \]; then\s+\. "\$HOME\/\.bashrc"\s+fi/s,
        'install.sh bridges ~/.profile to ~/.bashrc for future bash shells',
    );
    like(
        $stdout,
        qr/Shell setup was written to: \Q$bashrc\E/s,
        'install.sh reports the exact rc file it updated',
    );
    like(
        $stdout,
        qr/Shell activation entry point: \Q$profile\E/s,
        'install.sh reports the shell entry point to source after a piped install',
    );
    like(
        $stdout,
        qr/This installer ran in a child sh process, so your current shell has not loaded the new PATH yet\./s,
        'install.sh explains why the parent shell cannot see dashboard immediately after a piped run',
    );
    like(
        $stdout,
        qr/Run this now in your current shell:\s+\. "\Q$profile\E"/s,
        'install.sh prints the exact source command for the caller shell',
    );
    like(
        $stdout,
        qr/Then verify with:\s+dashboard version/s,
        'install.sh tells the user how to verify the command is available after activation',
    );
    unlike(
        $stdout . $stderr,
        qr{/dev/tty: No such device or address},
        'install.sh does not probe /dev/tty during piped installs',
    );

    my ( $again_out, $again_err, $again_exit ) = capture {
        system( 'sh', '-c', "$env_prefix '$install_sh'" );
    };
    is( $again_exit >> 8, 0, 'install.sh remains idempotent for the selected shell rc file' )
      or diag $again_out . $again_err;
    my $bashrc_again = _slurp($bashrc);
    is(
        scalar( () = $bashrc_again =~ /\Q$local_lib_line\E/g ),
        1,
        'install.sh does not duplicate the local::lib bootstrap line on repeat runs',
    );
}

{
    my $home = tempdir( CLEANUP => 1 );
    my $fake_bin = tempdir( CLEANUP => 1 );
    my $log = File::Spec->catfile( $home, 'install.log' );
    my $checkout = File::Spec->catfile( $home, 'default-dashboard-checkout' );
    _seed_fake_install_commands(
        fake_bin => $fake_bin,
        log      => $log,
    );

    my $shell_runner = File::Spec->catfile( $fake_bin, 'shell-runner' );
    _write_executable(
        $shell_runner,
        <<"SH",
#!/bin/sh
printf '%s\\n' "shell-runner \$*" >> "$log"
exit 0
SH
    );

    my $env_prefix = join ' ',
      map { sprintf q{%s='%s'}, $_->{key}, $_->{value} } (
        { key => 'HOME',                     value => $home },
        { key => 'PATH',                     value => $fake_bin . ':' . ( $ENV{PATH} || '' ) },
        { key => 'SHELL',                    value => '/bin/bash' },
        { key => 'DD_INSTALL_OS_OVERRIDE',   value => 'ubuntu' },
        { key => 'DD_INSTALL_SHELL_COMMANDS', value => 'dashboard version; d2 version; dashboard skills install browser' },
        { key => 'DD_INSTALL_SHELL_BIN',     value => $shell_runner },
      );

    my ( $stdout, $stderr, $exit ) = capture {
        system( 'sh', '-c', "$env_prefix '$install_sh'" );
    };
    is( $exit >> 8, 0, 'install.sh can run post-install commands through the activated shell environment' )
      or diag $stdout . $stderr;

    my @log_lines = _log_lines($log);
    like(
        join( "\n", @log_lines ),
        qr/shell-runner -ilc \. "\Q$home\/.profile\E" .*dashboard version; d2 version; dashboard skills install browser/s,
        'install.sh dispatches post-install commands through the activated bash shell entry point',
    );
    like(
        $stdout,
        qr/Running post-install activation commands through bash\./,
        'install.sh explains that it is executing the post-install shell commands',
    );
    like(
        $stdout,
        qr/Post-install activation commands completed\./,
        'install.sh confirms that the post-install shell commands completed',
    );
}

{
    my $home = tempdir( CLEANUP => 1 );
    my $fake_bin = tempdir( CLEANUP => 1 );
    my $log = File::Spec->catfile( $home, 'install.log' );
    my $checkout = File::Spec->catfile( $home, 'default-dashboard-checkout' );
    _seed_fake_install_commands(
        fake_bin => $fake_bin,
        log      => $log,
    );

    my $shell_runner = File::Spec->catfile( $fake_bin, 'shell-runner' );
    _write_executable(
        $shell_runner,
        <<"SH",
#!/bin/sh
printf '%s\\n' "shell-runner \$*" >> "$log"
exit 0
SH
    );

    my $env_prefix = join ' ',
      map { sprintf q{%s='%s'}, $_->{key}, $_->{value} } (
        { key => 'HOME',                      value => $home },
        { key => 'PATH',                      value => $fake_bin . ':' . ( $ENV{PATH} || '' ) },
        { key => 'SHELL',                     value => '/bin/sh' },
        { key => 'DD_INSTALL_OS_OVERRIDE',    value => 'alpine' },
        { key => 'DD_INSTALL_SHELL_COMMANDS', value => 'dashboard version; d2 version' },
        { key => 'DD_INSTALL_SHELL_BIN',      value => $shell_runner },
      );

    my ( $stdout, $stderr, $exit ) = capture {
        system( 'sh', '-c', "$env_prefix '$install_sh'" );
    };
    is( $exit >> 8, 0, 'install.sh can run post-install commands through the activated sh environment' )
      or diag $stdout . $stderr;

    my @log_lines = _log_lines($log);
    like(
        join( "\n", @log_lines ),
        qr/shell-runner -ic \. "\Q$home\/.profile\E" .*dashboard version; d2 version/s,
        'install.sh dispatches post-install commands through the activated sh shell entry point',
    );
    like(
        $stdout,
        qr/Running post-install activation commands through sh\./,
        'install.sh explains that it is executing the post-install shell commands for sh users',
    );
    like(
        $stdout,
        qr/Post-install activation commands completed\./,
        'install.sh confirms that the sh post-install shell commands completed',
    );
}

{
    my $home = tempdir( CLEANUP => 1 );
    my $fake_bin = tempdir( CLEANUP => 1 );
    my $log = File::Spec->catfile( $home, 'install.log' );
    my $checkout = File::Spec->catfile( $home, 'default-dashboard-checkout' );
    _seed_fake_install_commands(
        fake_bin => $fake_bin,
        log      => $log,
    );

    my $env_prefix = join ' ',
      map { sprintf q{%s='%s'}, $_->{key}, $_->{value} } (
        { key => 'HOME',                      value => $home },
        { key => 'PATH',                      value => $fake_bin . ':' . ( $ENV{PATH} || '' ) },
        { key => 'SHELL',                     value => '/bin/bash' },
        { key => 'DD_INSTALL_OS_OVERRIDE',    value => 'ubuntu' },
        { key => 'DD_INSTALL_BOOTSTRAP_CHECKOUT_DIR', value => $checkout },
        { key => 'FAKE_NODEJS_PROVIDES_NPM',  value => '1' },
        { key => 'FAKE_NPM_PACKAGE_CONFLICTS', value => '1' },
      );

    my ( $stdout, $stderr, $exit ) = capture {
        system( 'sh', '-c', "$env_prefix '$install_sh'" );
    };
    is( $exit >> 8, 0, 'install.sh skips the distro npm package when nodejs already provides npm and npx' )
      or diag $stdout . $stderr;

    my @log_lines = _log_lines($log);
    is_deeply(
        \@log_lines,
        [
            _expected_apt_bootstrap_steps(
                packages             => \@apt_packages,
                nodejs_provides_npm => 1,
            ),
            'perl -e exit(($] >= 5.038) ? 0 : 1)',
            "cpanm --no-wget --notest --local-lib-contained $home/perl5 local::lib App::cpanminus File::ShareDir::Install",
            "perl -I $home/perl5/lib/perl5 -Mlocal::lib",
            'cpanm --no-wget --notest .',
            'dashboard init',
        ],
        'install.sh avoids the conflicting Debian npm package when nodejs already ships the full Node toolchain and installs the local checkout directly',
    );
}

{
    my $home = tempdir( CLEANUP => 1 );
    my $fake_bin = tempdir( CLEANUP => 1 );
    my $log = File::Spec->catfile( $home, 'install.log' );
    my $checkout = File::Spec->catfile( $home, 'default-dashboard-checkout' );
    _seed_fake_install_commands(
        fake_bin => $fake_bin,
        log      => $log,
    );

    my $env_prefix = join ' ',
      map { sprintf q{%s='%s'}, $_->{key}, $_->{value} } (
        { key => 'HOME',                   value => $home },
        { key => 'PATH',                   value => $fake_bin . ':' . ( $ENV{PATH} || '' ) },
        { key => 'SHELL',                  value => '/bin/zsh' },
        { key => 'DD_INSTALL_OS_OVERRIDE', value => 'darwin' },
        { key => 'DD_INSTALL_BOOTSTRAP_CHECKOUT_DIR', value => $checkout },
      );

    my ( $stdout, $stderr, $exit ) = capture {
        system( 'sh', '-c', "$env_prefix '$install_sh'" );
    };
    is( $exit >> 8, 0, 'install.sh succeeds on macOS hosts with mocked Homebrew commands' )
      or diag $stdout . $stderr;

    my @log_lines = _log_lines($log);
    is_deeply(
        \@log_lines,
        [
            'brew install ' . join( ' ', @brew_packages ),
            'brew --prefix perl',
            'perl -e exit(($] >= 5.038) ? 0 : 1)',
            "cpanm --no-wget --notest --local-lib-contained $home/perl5 local::lib App::cpanminus File::ShareDir::Install",
            "perl -I $home/perl5/lib/perl5 -Mlocal::lib",
            'cpanm --no-wget --notest .',
            'dashboard init',
        ],
        'install.sh follows the macOS bootstrap flow in manifest order and installs the local checkout directly',
    );

    my $zshrc = File::Spec->catfile( $home, '.zshrc' );
    ok( -f $zshrc, 'install.sh creates or updates ~/.zshrc for zsh users' );
    like(
        _slurp($zshrc),
        qr/eval "\$\(\"[^\"]*\/dashboard" shell zsh\)"/,
        'install.sh appends the Developer Dashboard zsh shell bootstrap to ~/.zshrc',
    );
}

{
    my $home = tempdir( CLEANUP => 1 );
    my $fake_bin = tempdir( CLEANUP => 1 );
    my $log = File::Spec->catfile( $home, 'install.log' );
    my $checkout = File::Spec->catfile( $home, 'default-dashboard-checkout' );
    _seed_fake_install_commands(
        fake_bin         => $fake_bin,
        log              => $log,
        fake_brew_on_path => 0,
    );

    my $env_prefix = join ' ',
      map { sprintf q{%s='%s'}, $_->{key}, $_->{value} } (
        { key => 'HOME',                   value => $home },
        { key => 'PATH',                   value => $fake_bin . ':' . ( $ENV{PATH} || '' ) },
        { key => 'SHELL',                  value => '/bin/zsh' },
        { key => 'DD_INSTALL_OS_OVERRIDE', value => 'darwin' },
        { key => 'DD_INSTALL_BOOTSTRAP_CHECKOUT_DIR', value => $checkout },
      );

    my ( $stdout, $stderr, $exit ) = capture {
        system( 'sh', '-c', "$env_prefix '$install_sh'" );
    };
    is( $exit >> 8, 0, 'install.sh bootstraps Homebrew on blank macOS hosts before installing brew packages' )
      or diag $stdout . $stderr;

    my @log_lines = _log_lines($log);
    is_deeply(
        \@log_lines,
        [
            'curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o /tmp/developer-dashboard-homebrew-install.sh',
            '/bin/bash -c /tmp/developer-dashboard-homebrew-install.sh',
            'brew install ' . join( ' ', @brew_packages ),
            'brew --prefix perl',
            'perl -e exit(($] >= 5.038) ? 0 : 1)',
            "cpanm --no-wget --notest --local-lib-contained $home/perl5 local::lib App::cpanminus File::ShareDir::Install",
            "perl -I $home/perl5/lib/perl5 -Mlocal::lib",
            'cpanm --no-wget --notest .',
            'dashboard init',
        ],
        'install.sh downloads and runs the Homebrew bootstrap before the normal macOS package flow and installs the local checkout directly when brew is missing',
    );
    like(
        $stdout,
        qr/Bootstrapping Homebrew because brew is missing on this macOS host\./,
        'install.sh explains the Homebrew bootstrap step on blank macOS hosts',
    );
}

{
    my $home = tempdir( CLEANUP => 1 );
    my $fake_bin = tempdir( CLEANUP => 1 );
    my $log = File::Spec->catfile( $home, 'install.log' );
    my $checkout = File::Spec->catfile( $home, 'default-dashboard-checkout' );
    _seed_fake_install_commands(
        fake_bin => $fake_bin,
        log      => $log,
    );

    my $env_prefix = join ' ',
      map { sprintf q{%s='%s'}, $_->{key}, $_->{value} } (
        { key => 'HOME',                       value => $home },
        { key => 'PATH',                       value => $fake_bin . ':' . ( $ENV{PATH} || '' ) },
        { key => 'SHELL',                      value => '/bin/sh' },
        { key => 'DD_INSTALL_PREFERRED_SHELL', value => '/bin/zsh' },
        { key => 'DD_INSTALL_OS_OVERRIDE',     value => 'darwin' },
      );

    my ( $stdout, $stderr, $exit ) = capture {
        system( 'sh', '-c', "$env_prefix '$install_sh'" );
    };
    is( $exit >> 8, 0, 'install.sh succeeds when sh runs the installer for a zsh user' )
      or diag $stdout . $stderr;

    my $zshrc = File::Spec->catfile( $home, '.zshrc' );
    my $profile = File::Spec->catfile( $home, '.profile' );
    ok( -f $zshrc, 'install.sh still targets ~/.zshrc when the preferred shell is zsh even if sh runs the installer' );
    like(
        _slurp($zshrc),
        qr/eval "\$\(\"[^\"]*\/dashboard" shell zsh\)"/,
        'install.sh appends the zsh bootstrap to ~/.zshrc when the preferred shell is zsh',
    );
    unlike(
        ( -f $profile ? _slurp($profile) : '' ),
        qr/eval "\$\(\"[^\"]*\/dashboard" shell sh\)"/,
        'install.sh does not leak the fallback sh bootstrap into ~/.profile for zsh users',
    );
    like(
        $stdout,
        qr/Shell setup was written to: \Q$zshrc\E/s,
        'install.sh reports the zsh rc file when the preferred shell is zsh',
    );
}

{
    my $home = tempdir( CLEANUP => 1 );
    my $fake_bin = tempdir( CLEANUP => 1 );
    my $log = File::Spec->catfile( $home, 'install.log' );
    my $checkout = File::Spec->catfile( $home, 'default-dashboard-checkout' );
    _seed_fake_install_commands(
        fake_bin => $fake_bin,
        log      => $log,
    );

    my $env_prefix = join ' ',
      map { sprintf q{%s='%s'}, $_->{key}, $_->{value} } (
        { key => 'HOME',                   value => $home },
        { key => 'PATH',                   value => $fake_bin . ':' . ( $ENV{PATH} || '' ) },
        { key => 'SHELL',                  value => '/bin/sh' },
        { key => 'DD_INSTALL_OS_OVERRIDE', value => 'debian' },
      );

    my ( $stdout, $stderr, $exit ) = capture {
        system( 'sh', '-c', "$env_prefix '$install_sh'" );
    };
    is( $exit >> 8, 0, 'install.sh succeeds with POSIX sh users' )
      or diag $stdout . $stderr;

    my $profile = File::Spec->catfile( $home, '.profile' );
    ok( -f $profile, 'install.sh falls back to ~/.profile for generic POSIX sh users' );
    like(
        _slurp($profile),
        qr/eval "\$\(\"[^\"]*\/dashboard" shell sh\)"/,
        'install.sh appends the Developer Dashboard POSIX shell bootstrap to ~/.profile',
    );
}

{
    my $home = tempdir( CLEANUP => 1 );
    my $fake_bin = tempdir( CLEANUP => 1 );
    my $log = File::Spec->catfile( $home, 'install.log' );
    my $checkout = File::Spec->catfile( $home, 'default-dashboard-checkout' );
    my $script_copy = _slurp($install_sh);
    my $scratch = tempdir( CLEANUP => 1 );
    _seed_fake_install_commands(
        fake_bin => $fake_bin,
        log      => $log,
    );

    my $env_prefix = join ' ',
      map { sprintf q{%s='%s'}, $_->{key}, $_->{value} } (
        { key => 'HOME',                   value => $home },
        { key => 'PATH',                   value => $fake_bin . ':' . ( $ENV{PATH} || '' ) },
        { key => 'SHELL',                  value => '/bin/bash' },
        { key => 'DD_INSTALL_OS_OVERRIDE', value => 'ubuntu' },
        { key => 'DD_INSTALL_BOOTSTRAP_CHECKOUT_DIR', value => $checkout },
      );

    my ( $stdout, $stderr, $exit ) = capture {
        open my $pipe, '|-', 'sh', '-c', "cd '$scratch' && $env_prefix sh -s" or die "Unable to start streamed installer: $!";
        print {$pipe} $script_copy;
        close $pipe or die "Streamed installer exited non-zero: $?";
    };
    is( $exit >> 8, 0, 'install.sh succeeds when streamed through sh stdin without repo manifests on disk' )
      or diag $stdout . $stderr;

    my @log_lines = _log_lines($log);
    is_deeply(
        \@log_lines,
        [
            @expected_apt_bootstrap_steps,
            'perl -e exit(($] >= 5.038) ? 0 : 1)',
            "cpanm --no-wget --notest --local-lib-contained $home/perl5 local::lib App::cpanminus File::ShareDir::Install",
            "perl -I $home/perl5/lib/perl5 -Mlocal::lib",
            "git clone --depth 1 --branch master $default_bootstrap_repository $checkout",
            'cpanm --no-wget --notest .',
            'dashboard init',
        ],
        'streamed install.sh falls back to the embedded Debian-family manifest content and installs the default dashboard checkout from GitHub master',
    );
    like(
        $stdout,
        qr/Run this now in your current shell:\s+\. "\Q$home\/.profile\E"/s,
        'streamed install.sh prints an activation command that targets the shell entry point',
    );
}

{
    my $home = tempdir( CLEANUP => 1 );
    my $fake_bin = tempdir( CLEANUP => 1 );
    my $log = File::Spec->catfile( $home, 'install.log' );
    my $checkout = File::Spec->catfile( $home, 'default-dashboard-checkout' );
    _seed_fake_install_commands(
        fake_bin => $fake_bin,
        log      => $log,
    );

    my $env_prefix = join ' ',
      map { sprintf q{%s='%s'}, $_->{key}, $_->{value} } (
        { key => 'HOME',                   value => $home },
        { key => 'PATH',                   value => $fake_bin . ':' . ( $ENV{PATH} || '' ) },
        { key => 'SHELL',                  value => '/bin/bash' },
        { key => 'DD_INSTALL_OS_OVERRIDE', value => 'debian' },
        { key => 'FAKE_PERL_MEETS_MIN',    value => '0' },
        { key => 'DD_INSTALL_BOOTSTRAP_CHECKOUT_DIR', value => $checkout },
      );

    my ( $stdout, $stderr, $exit ) = capture {
        system( 'sh', '-c', "$env_prefix '$install_sh'" );
    };
    is( $exit >> 8, 0, 'install.sh bootstraps perlbrew when the system Perl is too old on Debian-family hosts' )
      or diag $stdout . $stderr;
    unlike(
        $stdout,
        qr/Append the following piece of code to the end of your ~\/\.profile/s,
        'install.sh suppresses raw perlbrew profile instructions and keeps shell setup guidance in its own output',
    );
    like(
        $stdout,
        qr/Updated \Q$home\/.bashrc\E so perlbrew metadata and perl-5\.38\.5 load automatically in new shells\./,
        'install.sh reports which rc file it updated for perlbrew bootstrap',
    );

    my @log_lines = _log_lines($log);
    is_deeply(
        \@log_lines,
        [
            @expected_apt_bootstrap_steps,
            'perl -e exit(($] >= 5.038) ? 0 : 1)',
            'perl -MConfig -e print $Config{archname}',
            'perlbrew init',
            'perlbrew list',
            'perlbrew --notest install perl-5.38.5',
            'perlbrew install-cpanm',
            "cpanm --no-wget --notest --local-lib-contained $home/perl5 local::lib App::cpanminus File::ShareDir::Install",
            "perl -I $home/perl5/lib/perl5 -Mlocal::lib",
            'cpanm --no-wget --notest .',
            'dashboard init',
        ],
        'install.sh switches to perlbrew before the local::lib bootstrap when Debian ships an older Perl and then installs the local checkout directly',
    );

    my $bashrc = File::Spec->catfile( $home, '.bashrc' );
    my $profile = File::Spec->catfile( $home, '.profile' );
    my $bashrc_text = _slurp($bashrc);
    my $profile_text = _slurp($profile);
    like(
        $bashrc_text,
        qr/export PERLBREW_HOME="\Q$home\E\/perl5\/perlbrew"/,
        'install.sh records PERLBREW_HOME in the active shell rc file',
    );
    like(
        $bashrc_text,
        qr/export PATH="\Q$home\E\/perl5\/perlbrew\/perls\/perl-5\.38\.5\/bin:\$PATH"/,
        'install.sh records the perlbrew Perl path in the active shell rc file',
    );
    like(
        $bashrc_text,
        qr/eval "\$\(\"[^\"]*\/dashboard" shell bash\)"/,
        'install.sh appends the Developer Dashboard bash shell bootstrap after the perlbrew rescue path',
    );
    like(
        $profile_text,
        qr/if \[ -f "\$HOME\/\.bashrc" \]; then\s+\. "\$HOME\/\.bashrc"\s+fi/s,
        'install.sh keeps the bash login shell entry point wired to ~/.bashrc when perlbrew is needed',
    );
}

{
    my $home = tempdir( CLEANUP => 1 );
    my $fake_bin = tempdir( CLEANUP => 1 );
    my $log = File::Spec->catfile( $home, 'install.log' );
    my $checkout = File::Spec->catfile( $home, 'default-dashboard-checkout' );
    _seed_fake_install_commands(
        fake_bin                        => $fake_bin,
        log                             => $log,
        fake_perlbrew_on_path           => 0,
        fake_cpanm_installs_local_perlbrew => 1,
    );

    my $env_prefix = join ' ',
      map { sprintf q{%s='%s'}, $_->{key}, $_->{value} } (
        { key => 'HOME',                   value => $home },
        { key => 'PATH',                   value => $fake_bin . ':' . ( $ENV{PATH} || '' ) },
        { key => 'SHELL',                  value => '/bin/sh' },
        { key => 'DD_INSTALL_OS_OVERRIDE', value => 'alpine' },
        { key => 'FAKE_PERL_MEETS_MIN',    value => '0' },
        { key => 'DD_INSTALL_BOOTSTRAP_CHECKOUT_DIR', value => $checkout },
      );

    my ( $stdout, $stderr, $exit ) = capture {
        system( 'sh', '-c', "$env_prefix '$install_sh'" );
    };
    is( $exit >> 8, 0, 'install.sh can invoke a locally bootstrapped perlbrew on Alpine without losing @INC' )
      or diag $stdout . $stderr;
    unlike(
        $stdout . $stderr,
        qr/Can't locate App\/perlbrew\.pm/,
        'install.sh no longer loses the local App::perlbrew install when bootstrapping Perl on Alpine',
    );
    unlike(
        $stdout . $stderr,
        qr/Use of uninitialized value \$err in numeric eq \(==\) at .*IO\/Socket\/IP\.pm line 739\./,
        'install.sh avoids the Alpine IO::Socket::IP warning while bootstrapping App::perlbrew',
    );
    unlike(
        $stdout . $stderr,
        qr/retry-connrefused|BusyBox v[0-9.]+ .*multi-call binary|unrecognized option: retry-connrefused/,
        'install.sh avoids BusyBox wget when Alpine cpanm resolves bootstrap modules',
    );

    my @log_lines = _log_lines($log);
    is_deeply(
        \@log_lines,
        [
            _expected_apk_bootstrap_steps( packages => \@apk_packages ),
            'perl -e exit(($] >= 5.038) ? 0 : 1)',
            'perl -MConfig -e print $Config{archname}',
            "curl -fsSL $perlbrew_app_dist_url -o $home/perl5/bootstrap-cache/$perlbrew_app_dist_basename",
            "cpanm --no-wget --notest --local-lib-contained $home/perl5 $home/perl5/bootstrap-cache/$perlbrew_app_dist_basename",
            'perlbrew init',
            'perlbrew list',
            'perlbrew --notest install perl-5.38.5',
            'patchperl apply perl-5.38.5',
            'perlbrew install-cpanm',
            "cpanm --no-wget --notest --local-lib-contained $home/perl5 local::lib App::cpanminus File::ShareDir::Install",
            "perl -I $home/perl5/lib/perl5 -Mlocal::lib",
            'cpanm --no-wget --notest .',
            'dashboard init',
        ],
        'install.sh activates the local App::perlbrew install before invoking perlbrew on Alpine and then installs the local checkout directly',
    );

    my $profile = File::Spec->catfile( $home, '.profile' );
    my $profile_text = _slurp($profile);
    like(
        $profile_text,
        qr/eval "\$\(\"[^\"]*\/dashboard" shell sh\)"/,
        'install.sh keeps the shell bootstrap in the active Alpine profile after the perlbrew rescue path',
    );
    unlike(
        $profile_text,
        qr/\. "\Q$home\E\/perl5\/perlbrew\/etc\/bashrc"/,
        'install.sh keeps the Alpine sh profile free of the perlbrew bashrc snippet',
    );
}

done_testing;

sub _expected_apt_bootstrap_steps {
    my (%args) = @_;
    my @packages = @{ $args{packages} || [] };
    my @non_node_packages = grep { $_ ne 'nodejs' && $_ ne 'npm' } @packages;
    my @install_lines;
    push @install_lines, 'apt-get install -y ' . join( ' ', @non_node_packages )
      if @non_node_packages;
    push @install_lines, 'apt-get install -y nodejs'
      if grep { $_ eq 'nodejs' } @packages;
    push @install_lines, 'apt-get install -y npm'
      if ( grep { $_ eq 'npm' } @packages ) && !$args{nodejs_provides_npm};
    return (
        'apt-get update',
        @install_lines,
    ) if ( $> || 0 ) == 0;
    return (
        'sudo apt-get update',
        'apt-get update',
        map( { ( "sudo $_", $_ ) } @install_lines ),
    );
}

sub _expected_apk_bootstrap_steps {
    my (%args) = @_;
    my @packages = @{ $args{packages} || [] };
    my $install_line = 'apk add --no-cache ' . join( ' ', @packages );
    return ($install_line) if ( $> || 0 ) == 0;
    return (
        "sudo $install_line",
        $install_line,
    );
}

sub _expected_dnf_bootstrap_steps {
    my (%args) = @_;
    my @packages = @{ $args{packages} || [] };
    my $install_line = 'dnf install -y ' . join( ' ', @packages );
    return ($install_line) if ( $> || 0 ) == 0;
    return (
        "sudo $install_line",
        $install_line,
    );
}

sub _manifest_lines {
    my ($path) = @_;
    my $text = _slurp($path);
    return grep { defined && $_ ne '' }
      map {
        s/\s+#.*$//r =~ s/^\s+|\s+$//gr
      }
      grep { $_ !~ /^\s*(?:#|$)/ }
      split /\n/, $text;
}

sub _seed_fake_install_commands {
    my (%args) = @_;
    my $fake_bin = $args{fake_bin};
    my $log      = $args{log};
    my $node_marker = File::Spec->catfile( $fake_bin, 'node-toolchain.marker' );
    my $fake_brew_on_path = exists $args{fake_brew_on_path} ? $args{fake_brew_on_path} : 1;
    my $fake_perlbrew_on_path = exists $args{fake_perlbrew_on_path} ? $args{fake_perlbrew_on_path} : 1;
    my $fake_cpanm_installs_local_perlbrew = $args{fake_cpanm_installs_local_perlbrew} ? 1 : 0;
    make_path($fake_bin);

    _write_executable(
        File::Spec->catfile( $fake_bin, 'sudo' ),
        <<"SH",
#!/bin/sh
printf '%s\\n' "sudo \$*" >> "$log"
exec "\$@"
SH
    );
    _write_executable(
        File::Spec->catfile( $fake_bin, 'apt-get' ),
        <<"SH",
#!/bin/sh
printf '%s\\n' "apt-get \$*" >> "$log"
append_marker() {
tool=\$1
grep -qx "\$tool" "$node_marker" 2>/dev/null || printf '%s\\n' "\$tool" >> "$node_marker"
}
if [ "\$1" = "install" ]; then
case " \$* " in
  *" nodejs "*)
    append_marker node
    if [ "\${FAKE_NODEJS_PROVIDES_NPM:-0}" = "1" ]; then
      append_marker npm
      append_marker npx
    fi
    ;;
esac
case " \$* " in
  *" npm "*)
    if [ "\${FAKE_NPM_PACKAGE_CONFLICTS:-0}" = "1" ]; then
      printf '%s\\n' 'E: nodejs conflicts with npm' >&2
      exit 1
    fi
    append_marker npm
    append_marker npx
    ;;
esac
fi
exit 0
SH
    );
    my $brew_script = <<"SH";
#!/bin/sh
printf '%s\\n' "brew \$*" >> "$log"
if [ "\$1" = "install" ] && printf '%s ' "\$@" | grep -q ' node '; then
grep -qx 'node' "$node_marker" 2>/dev/null || printf '%s\\n' 'node' >> "$node_marker"
grep -qx 'npm' "$node_marker" 2>/dev/null || printf '%s\\n' 'npm' >> "$node_marker"
grep -qx 'npx' "$node_marker" 2>/dev/null || printf '%s\\n' 'npx' >> "$node_marker"
fi
if [ "\$1" = "--prefix" ] && [ "\$2" = "perl" ]; then
  printf '%s\\n' "\$HOME/.homebrew/opt/perl"
fi
exit 0
SH
    _write_executable(
        File::Spec->catfile( $fake_bin, 'bash' ),
        <<"SH",
#!/bin/sh
printf '%s\\n' "/bin/bash \$*" >> "$log"
if [ "\$1" = "-c" ] && printf '%s' "\$2" | grep -q 'developer-dashboard-homebrew-install.sh'; then
mkdir -p "\$HOME/.homebrew/bin" "\$HOME/.homebrew/opt/perl/bin"
cat > "\$HOME/.homebrew/bin/brew" <<'EOS'
$brew_script
EOS
chmod 0755 "\$HOME/.homebrew/bin/brew"
fi
exit 0
SH
    );
    _write_executable(
        File::Spec->catfile( $fake_bin, 'apk' ),
        <<"SH",
#!/bin/sh
printf '%s\\n' "apk \$*" >> "$log"
append_marker() {
tool=\$1
grep -qx "\$tool" "$node_marker" 2>/dev/null || printf '%s\\n' "\$tool" >> "$node_marker"
}
if [ "\$1" = "add" ]; then
case " \$* " in
  *" nodejs "*)
    append_marker node
    ;;
esac
case " \$* " in
  *" npm "*)
    append_marker npm
    append_marker npx
    ;;
esac
fi
exit 0
SH
    );
    _write_executable(
        File::Spec->catfile( $fake_bin, 'dnf' ),
        <<"SH",
#!/bin/sh
printf '%s\\n' "dnf \$*" >> "$log"
if [ "\$1" = "install" ] && printf '%s ' "\$@" | grep -q ' nodejs '; then
grep -qx 'node' "$node_marker" 2>/dev/null || printf '%s\\n' 'node' >> "$node_marker"
grep -qx 'npm' "$node_marker" 2>/dev/null || printf '%s\\n' 'npm' >> "$node_marker"
grep -qx 'npx' "$node_marker" 2>/dev/null || printf '%s\\n' 'npx' >> "$node_marker"
fi
exit 0
SH
    );
    _write_executable(
        File::Spec->catfile( $fake_bin, 'cpanm' ),
        <<"SH",
#!/bin/sh
printf '%s\\n' "cpanm \$*" >> "$log"
if [ "$fake_cpanm_installs_local_perlbrew" = "1" ] && printf '%s ' "\$*" | grep -Eq ' App::perlbrew|App-perlbrew-1\\.02\\.tar\\.gz'; then
mkdir -p "\$HOME/perl5/bin" "\$HOME/perl5/lib/perl5/App"
cat > "\$HOME/perl5/bin/perlbrew" <<'EOS'
#!/bin/sh
printf '%s\\n' "perlbrew \$*" >> "__LOG__"
case ":\${PERL5LIB:-}:" in
  *:"__HOME__/perl5/lib/perl5":* ) ;;
  *)
    printf '%s\\n' "Can't locate App/perlbrew.pm in \@INC" >&2
    exit 2
    ;;
esac
if [ "\$1" = "--notest" ]; then
shift
fi
case "\$1" in
init)
mkdir -p "\${PERLBREW_ROOT:-\$HOME/perl5/perlbrew}/perls"
mkdir -p "\${PERLBREW_ROOT:-\$HOME/perl5/perlbrew}/etc"
cat > "\${PERLBREW_ROOT:-\$HOME/perl5/perlbrew}/etc/bashrc" <<'INNER'
# fake perlbrew shell bootstrap
INNER
exit 0
;;
list)
exit 0
;;
install)
root="\${PERLBREW_ROOT:-\$HOME/perl5/perlbrew}"
PERL5LIB='' "\$HOME/perl5/bin/patchperl" apply "\$2" || exit \$?
mkdir -p "\$root/perls/\$2/bin"
cat > "\$root/perls/\$2/bin/perl" <<'INNER'
#!/bin/sh
printf '%s\\n' "perl \$*" >> "__LOG__"
printf 'export PATH="__HOME__/perl5/bin:\$PATH"; export PERL5LIB="__HOME__/perl5/lib/perl5\${PERL5LIB:+:\$PERL5LIB}"\\n'
exit 0
INNER
perl_path="\$root/perls/\$2/bin/perl"
sed -i "s|__LOG__|$log|g; s|__HOME__|\$HOME|g" "\$perl_path"
chmod 0755 "\$perl_path"
exit 0
;;
install-cpanm)
root="\${PERLBREW_ROOT:-\$HOME/perl5/perlbrew}"
mkdir -p "\$root/bin"
cat > "\$root/bin/cpanm" <<'INNER'
#!/bin/sh
printf '%s\\n' "cpanm \$*" >> "__LOG__"
exit 0
INNER
sed -i "s|__LOG__|$log|g" "\$root/bin/cpanm"
chmod 0755 "\$root/bin/cpanm"
exit 0
;;
esac
exit 0
EOS
sed -i "s|__LOG__|$log|g; s|__HOME__|\$HOME|g" "\$HOME/perl5/bin/perlbrew"
chmod 0755 "\$HOME/perl5/bin/perlbrew"
cat > "\$HOME/perl5/bin/patchperl" <<'EOS'
#!/bin/sh
printf '%s\\n' "patchperl \$*" >> "__LOG__"
case ":\${PERL5LIB:-}:" in
  *:"__HOME__/perl5/lib/perl5":* ) ;;
  *)
    printf '%s\\n' "Can't locate Devel/PatchPerl.pm in \@INC" >&2
    exit 2
    ;;
esac
exit 0
EOS
sed -i "s|__LOG__|$log|g; s|__HOME__|\$HOME|g" "\$HOME/perl5/bin/patchperl"
chmod 0755 "\$HOME/perl5/bin/patchperl"
cat > "\$HOME/perl5/lib/perl5/App/perlbrew.pm" <<'EOS'
package App::perlbrew;
1;
EOS
mkdir -p "\$HOME/perl5/lib/perl5/Devel"
cat > "\$HOME/perl5/lib/perl5/Devel/PatchPerl.pm" <<'EOS'
package Devel::PatchPerl;
1;
EOS
fi
exit 0
SH
    );
    _write_executable(
        File::Spec->catfile( $fake_bin, 'git' ),
        <<"SH",
#!/bin/sh
printf '%s\\n' "git \$*" >> "$log"
if [ "\$1" = "clone" ]; then
target=''
for arg in "\$@"; do
target=\$arg
done
mkdir -p "\$target/lib/Developer"
printf '%s\\n' 'version = 3.44' > "\$target/dist.ini"
printf '%s\\n' 'package Developer::Dashboard; 1;' > "\$target/lib/Developer/Dashboard.pm"
fi
exit 0
SH
    );
    _write_executable(
        File::Spec->catfile( $fake_bin, 'curl' ),
        <<"SH",
#!/bin/sh
printf '%s\\n' "curl \$*" >> "$log"
output=''
stdout=0
while [ \$# -gt 0 ]; do
case "\$1" in
  -o)
    output=\$2
    shift 2
    ;;
  -fsSL|-f|-s|-S|-L)
    shift
    ;;
  *)
    url=\$1
    shift
    ;;
esac
done
[ -n "\$url" ] || exit 1
if [ -n "\$output" ]; then
mkdir -p "\$(dirname "\$output")"
printf '%s\\n' 'fake perlbrew tarball' > "\$output"
else
printf '%s\\n' '#!/bin/sh'
printf '%s\\n' 'echo fake homebrew install'
fi
exit 0
SH
    );
    if ($fake_brew_on_path) {
        _write_executable(
            File::Spec->catfile( $fake_bin, 'brew' ),
            $brew_script,
        );
    }
    _write_executable(
        File::Spec->catfile( $fake_bin, 'perl' ),
        <<"SH",
#!/bin/sh
if [ "\$1" = "-e" ] && [ "\$2" = "exit((\$] >= 5.038) ? 0 : 1)" ]; then
printf '%s\\n' "perl \$*" >> "$log"
if [ "\${FAKE_PERL_MEETS_MIN:-1}" = "1" ]; then
exit 0
fi
exit 1
fi
printf '%s\\n' "perl \$*" >> "$log"
printf 'export PATH="%s/perl5/bin:\$PATH"; export PERL5LIB="%s/perl5/lib/perl5\${PERL5LIB:+:\$PERL5LIB}"\\n' "\$HOME" "\$HOME"
exit 0
SH
    );
    _write_executable(
        File::Spec->catfile( $fake_bin, 'dashboard' ),
        <<"SH",
#!/bin/sh
printf '%s\\n' "dashboard \$*" >> "$log"
exit 0
SH
    );
    _write_executable(
        File::Spec->catfile( $fake_bin, 'node' ),
        <<"SH",
#!/bin/sh
grep -qx 'node' "$node_marker" 2>/dev/null || exit 1
printf '%s\\n' 'v22.0.0'
SH
    );
    _write_executable(
        File::Spec->catfile( $fake_bin, 'npm' ),
        <<"SH",
#!/bin/sh
grep -qx 'npm' "$node_marker" 2>/dev/null || exit 1
printf '%s\\n' '10.0.0'
SH
    );
    _write_executable(
        File::Spec->catfile( $fake_bin, 'npx' ),
        <<"SH",
#!/bin/sh
grep -qx 'npx' "$node_marker" 2>/dev/null || exit 1
printf '%s\\n' '10.0.0'
SH
    );
    if ($fake_perlbrew_on_path) {
        _write_executable(
            File::Spec->catfile( $fake_bin, 'perlbrew' ),
            <<"SH",
#!/bin/sh
printf '%s\\n' "perlbrew \$*" >> "$log"
if [ "\$1" = "--notest" ]; then
shift
fi
case "\$1" in
init)
mkdir -p "\${PERLBREW_ROOT:-\$HOME/perl5/perlbrew}/perls"
mkdir -p "\${PERLBREW_ROOT:-\$HOME/perl5/perlbrew}/etc"
cat > "\${PERLBREW_ROOT:-\$HOME/perl5/perlbrew}/etc/bashrc" <<'EOS'
# fake perlbrew shell bootstrap
EOS
cat <<'EOS'
perlbrew root (~/perl5/perlbrew) is initialized.

Append the following piece of code to the end of your ~/.profile and start a
new shell, perlbrew should be up and fully functional from there:

    export PERLBREW_HOME=~/perl5/perlbrew
    source ~/perl5/perlbrew/etc/bashrc
EOS
exit 0
;;
list)
exit 0
;;
install)
root="\${PERLBREW_ROOT:-\$HOME/perl5/perlbrew}"
mkdir -p "\$root/perls/\$2/bin"
cat > "\$root/perls/\$2/bin/perl" <<'EOS'
#!/bin/sh
printf '%s\\n' "perl \$*" >> "__LOG__"
printf 'export PATH="__HOME__/perl5/bin:\$PATH"; export PERL5LIB="__HOME__/perl5/lib/perl5\${PERL5LIB:+:\$PERL5LIB}"\\n'
exit 0
EOS
perl_path="\$root/perls/\$2/bin/perl"
sed -i "s|__LOG__|$log|g; s|__HOME__|\$HOME|g" "\$perl_path"
chmod 0755 "\$perl_path"
exit 0
;;
install-cpanm)
root="\${PERLBREW_ROOT:-\$HOME/perl5/perlbrew}"
mkdir -p "\$root/bin"
cat > "\$root/bin/cpanm" <<'EOS'
#!/bin/sh
printf '%s\\n' "cpanm \$*" >> "__LOG__"
exit 0
EOS
sed -i "s|__LOG__|$log|g" "\$root/bin/cpanm"
chmod 0755 "\$root/bin/cpanm"
exit 0
;;
esac
exit 0
SH
        );
    }
}

sub _log_lines {
    my ($path) = @_;
    return () if !-f $path;
    my $text = _slurp($path);
    return grep { defined && $_ ne '' } split /\n/, $text;
}

sub _slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Unable to read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh;
    return $text;
}

sub _write_executable {
    my ( $path, $body ) = @_;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $body;
    close $fh;
    chmod 0755, $path or die "Unable to chmod $path: $!";
    return 1;
}

__END__

=head1 NAME

t/40-install-bootstrap.t - regression coverage for the repo bootstrap installer

=head1 PURPOSE

This test locks the repo-root bootstrap installer contract so the plain
F<install.sh> entrypoint, F<aptfile>, F<apkfile>, and F<brewfile> stay aligned
while the project evolves.

=head1 WHAT IT CHECKS

It verifies that the installer remains valid POSIX shell, that Debian-family
and macOS package installation flows use the repo manifests in order, that the
user-space Perl bootstrap goes through C<local::lib>, and that the correct
shell rc file receives exactly one bootstrap line.

=head1 WHY IT EXISTS

The installation path now has to work from a blank machine, so this file
protects the most important bootstrap assumptions before the heavier Docker
acceptance gates run.

=head1 WHEN TO USE

Use this test when changing the checkout bootstrap flow, the repo-root package
manifests, the user-space Perl bootstrap contract, or the shell rc file update
policy.

=head1 HOW TO USE

Run it directly through the Perl test harness during focused bootstrap work or
let it run as part of the full suite.

=head1 WHAT USES IT

It is used by the local regression suite and the release metadata gate so the
shipped bootstrap installer cannot drift away from the documented install path.

=head1 HOW TO RUN

Run it through the normal suite:

  prove -lv t/40-install-bootstrap.t

=head1 EXAMPLES

Example:

  prove -lv t/40-install-bootstrap.t

=cut
