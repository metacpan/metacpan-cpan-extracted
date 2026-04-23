use strict;
use warnings;

use Capture::Tiny qw(capture);
use Developer::Dashboard::JSON qw(json_decode);
use Test::More;

my $has_source_tree_docs = -f 'dist.ini';
my $has_integration_assets = -d 'integration';

if ( $has_source_tree_docs && -d '.git' ) {
    ok( _path_is_git_tracked('doc/integration-test-plan.md'), 'integration test plan document is tracked by git' );
    ok( _path_is_git_tracked('doc/testing.md'), 'testing workflow document is tracked by git' );
    ok( _path_is_git_tracked('doc/windows-testing.md'), 'Windows verification document is tracked by git' );
    ok( _path_is_git_tracked('integration/browser/run-bookmark-browser-smoke.pl'), 'bookmark browser smoke script is tracked by git' );
}

ok( -f 'doc/integration-test-plan.md', 'integration test plan document exists' ) if $has_source_tree_docs;
ok( -f 'doc/testing.md', 'testing workflow document exists' ) if $has_source_tree_docs;
ok( -f 'install.sh', 'repo bootstrap installer exists at the checkout root' ) if $has_source_tree_docs;
ok( -f 'aptfile', 'repo bootstrap apt manifest exists at the checkout root' ) if $has_source_tree_docs;
ok( -f 'apkfile', 'repo bootstrap apk manifest exists at the checkout root' ) if $has_source_tree_docs;
ok( -f 'brewfile', 'repo bootstrap brew manifest exists at the checkout root' ) if $has_source_tree_docs;
ok( -f 'integration/blank-env/Dockerfile', 'blank-environment Dockerfile exists' ) if $has_integration_assets;
ok( -f 'integration/blank-env/docker-compose.yml', 'blank-environment docker compose file exists' ) if $has_integration_assets;
ok( -f 'integration/blank-env/run-integration.pl', 'blank-environment integration runner exists' ) if $has_integration_assets;
ok( -f 'integration/blank-env/run-host-integration.sh', 'host-side blank-environment integration launcher exists' ) if $has_integration_assets;
ok( -f 'integration/browser/run-bookmark-browser-smoke.pl', 'bookmark browser smoke script exists' ) if $has_integration_assets;
ok( -f 'doc/windows-testing.md', 'Windows verification document exists' ) if $has_source_tree_docs;
ok( -f 'integration/windows/run-strawberry-smoke.ps1', 'Windows Strawberry Perl smoke script exists' ) if $has_integration_assets;
ok( -f 'integration/windows/run-qemu-windows-smoke.sh', 'Windows QEMU smoke launcher exists' ) if $has_integration_assets;
ok( -f 'integration/windows/run-host-windows-smoke.sh', 'Windows host rerun helper exists' ) if $has_integration_assets;
ok( -f 't/29-windows-qemu-smoke.t', 'Windows QEMU smoke test exists under t/' );
ok( -x 'integration/windows/run-qemu-windows-smoke.sh', 'Windows QEMU smoke launcher is executable' ) if $has_integration_assets;
ok( -x 'integration/windows/run-host-windows-smoke.sh', 'Windows host rerun helper is executable' ) if $has_integration_assets;

if ($has_source_tree_docs) {
    open my $plan_fh, '<', 'doc/integration-test-plan.md' or die $!;
    my $plan = do { local $/; <$plan_fh> };
    close $plan_fh;
    like( $plan, qr/dzil build/, 'integration plan covers host dzil build' );
    like( $plan, qr/cpanm/, 'integration plan covers cpanm install' );
    like( $plan, qr/installation: `cpanm <tarball>`/, 'integration plan keeps the blank-environment tarball install on plain cpanm' );
    like( $plan, qr/Windows guest currently installs the tarball with\s+`cpanm --notest`/s, 'integration plan documents the Windows-only cpanm --notest exception explicitly' );
    like( $plan, qr/dashboard serve/, 'integration plan covers installed web lifecycle' );
    like( $plan, qr/helper logout/i, 'integration plan covers helper logout cleanup' );
    like( $plan, qr/Chromium|browser/i, 'integration plan covers browser-backed verification' );
    like( $plan, qr/\.developer-dashboard/, 'integration plan covers fake-project local runtime overrides' );
    like( $plan, qr/host-built tarball/i, 'integration plan requires host-built tarball flow' );
    like( $plan, qr/broken collector|broken Perl collector|healthy collector/i, 'integration plan covers collector failure isolation' );
    like( $plan, qr/Runtime::Result/, 'integration plan covers Runtime::Result-based hook verification' );
    like( $plan, qr/run-host-integration\.sh/, 'integration plan points to the host-side launcher' );
    like( $plan, qr/run-bookmark-browser-smoke\.pl/, 'integration plan documents the fast bookmark browser smoke runner' );
    like( $plan, qr/run-strawberry-smoke\.ps1/, 'integration plan documents the Windows Strawberry smoke runner' );
    like( $plan, qr/run-qemu-windows-smoke\.sh/, 'integration plan documents the Windows QEMU smoke launcher' );

    open my $testing_fh, '<', 'doc/testing.md' or die $!;
    my $testing = do { local $/; <$testing_fh> };
    close $testing_fh;
    like( $testing, qr/run-bookmark-browser-smoke\.pl/, 'testing doc documents the bookmark browser smoke runner' );
    like( $testing, qr/headless\s+Chromium/s, 'testing doc explains that the bookmark smoke runner uses headless Chromium' );

    open my $install_fh, '<', 'install.sh' or die $!;
    my $install = do { local $/; <$install_fh> };
    close $install_fh;
    like( $install, qr{#!/bin/sh}, 'bootstrap installer uses a POSIX sh shebang' );
    like( $install, qr/cpanm --notest/, 'bootstrap installer performs the dashboard install through cpanm --notest' );
    like( $install, qr/dashboard init/, 'bootstrap installer initializes the dashboard runtime after installation' );
    like( $install, qr/aptfile/, 'bootstrap installer reads the repo apt manifest' );
    like( $install, qr/apkfile/, 'bootstrap installer reads the repo apk manifest' );
    like( $install, qr/brewfile/, 'bootstrap installer reads the repo brew manifest' );

    open my $windows_doc_fh, '<', 'doc/windows-testing.md' or die $!;
    my $windows_doc = do { local $/; <$windows_doc_fh> };
    close $windows_doc_fh;
    like( $windows_doc, qr/Strawberry Perl/, 'Windows verification doc targets Strawberry Perl explicitly' );
    like( $windows_doc, qr/run-strawberry-smoke\.ps1/, 'Windows verification doc references the host-side Strawberry smoke script' );
    like( $windows_doc, qr/run-qemu-windows-smoke\.sh/, 'Windows verification doc references the QEMU smoke launcher' );
    like( $windows_doc, qr/run-host-windows-smoke\.sh/, 'Windows verification doc references the one-command host rerun helper' );
    like( $windows_doc, qr/qemu-system-x86_64/, 'Windows verification doc documents the QEMU dependency' );
    like( $windows_doc, qr/windows-qemu\.env|WINDOWS_QEMU_ENV_FILE/, 'Windows verification doc explains reusable QEMU environment configuration' );
    like( $windows_doc, qr/Git Bash.*optional|optional.*Git Bash/i, 'Windows verification doc treats Git Bash as optional' );
    like( $windows_doc, qr/Scoop.*optional|optional.*Scoop/i, 'Windows verification doc treats Scoop as optional' );
    like( $windows_doc, qr/PowerShell.*Strawberry Perl.*supported baseline|supported baseline.*PowerShell.*Strawberry Perl/is, 'Windows verification doc defines the supported Windows runtime baseline' );
    unlike( $windows_doc, qr/Developer-Dashboard-1\.\d+\.tar\.gz/, 'Windows verification doc avoids hard-coded release tarball versions' );
}

if ($has_integration_assets) {
    open my $smoke_fh, '<', 'integration/browser/run-bookmark-browser-smoke.pl' or die $!;
    my $smoke = do { local $/; <$smoke_fh> };
    close $smoke_fh;
    like( $smoke, qr/--bookmark-file/, 'bookmark smoke script accepts an explicit bookmark file path' );
    like( $smoke, qr/--expect-ajax-path/, 'bookmark smoke script accepts ajax path assertions' );
    like( $smoke, qr/__END__/, 'bookmark smoke script carries POD trailer' );

    open my $runner_fh, '<', 'integration/blank-env/run-integration.pl' or die $!;
    my $runner = do { local $/; <$runner_fh> };
    close $runner_fh;
    like( $runner, qr/Developer-Dashboard\.tar\.gz/, 'integration runner consumes mounted tarball artifact' );
    like( $runner, qr/tar -xzf/, 'integration runner extracts the tarball inside the container' );
    like( $runner, qr/_versioned_install_tarball_path/, 'integration runner derives a versioned cpanm install tarball path from the extracted distribution version' );
    like( $runner, qr/_copy_file\( \$tarball, \$install_tarball \)/, 'integration runner stages the mounted tarball into a versioned local copy before cpanm install' );
    like( $runner, qr/cpanm install host-built tarball.*\$install_tarball/s, 'integration runner installs the versioned local tarball copy with cpanm' );
    unlike( $runner, qr/cpanm install host-built tarball.*\$tarball/s, 'integration runner does not hand the generic mounted tarball path directly to cpanm' );
    like( $runner, qr/dashboard update/, 'integration runner exercises dashboard update' );
    like( $runner, qr/Runtime::Result/, 'integration runner exercises Runtime::Result-aware hook chaining' );
    like( $runner, qr/dashboard docker compose --project .* --dry-run config/, 'integration runner exercises docker compose dry-run' );
    like( $runner, qr/dashboard auth add-user helper_login helper-login-pass-123/, 'integration runner exercises helper login path' );
    unlike( $runner, qr/cpanm --notest/, 'integration runner installs the tarball without cpanm --notest' );
    like( $runner, qr/broken\.collector/, 'integration runner provisions a broken config collector regression case' );
    like( $runner, qr/healthy\.collector/, 'integration runner provisions a healthy config collector regression case' );
    like( $runner, qr/dashboard indicator list after restart/, 'integration runner checks indicator isolation after restart' );
    like( $runner, qr/_browser_binary|chromium-browser|google-chrome|apt-get install -y --no-install-recommends chromium/s, 'integration runner resolves or bootstraps a headless browser for browser checks' );
    like( $runner, qr/IPC::Open3|open3/, 'integration runner uses a live subprocess bridge for long-running command output' );
    like( $runner, qr/IO::Select/, 'integration runner monitors long-running command streams without fully buffering them first' );
    like( $runner, qr/legacy-ajax-stream|project-stream\.txt/, 'integration runner provisions a long-running saved ajax stream regression case' );
    like( $runner, qr/_capture_stream_prefix/, 'integration runner captures early ajax stream chunks during the long-running saved ajax regression case' );
    like( $runner, qr/_distribution_version/, 'integration runner reads the expected installed version from the extracted tarball instead of hard-coding a release number' );
    like( $runner, qr/\.developer-dashboard/, 'integration runner provisions a fake-project local runtime tree' );
    like( $runner, qr/cpanm install host-built tarball.*dashboard init.*api-dashboard/s, 'integration runner builds the fake-project local runtime only after the tarball install step' );
    like( $runner, qr/dashboard init seeds sql-dashboard page/, 'integration runner expects the sql-dashboard starter page after dashboard init' );
    like( $runner, qr/__END__/, 'integration runner carries POD trailer' );

    open my $docker_fh, '<', 'integration/blank-env/Dockerfile' or die $!;
    my $dockerfile = do { local $/; <$docker_fh> };
    close $docker_fh;
    like( $dockerfile, qr/\bchromium\b/, 'integration Dockerfile installs Chromium for browser verification' );
    unlike( $dockerfile, qr/\bDist::Zilla\b/, 'integration Dockerfile no longer installs Dist::Zilla because host builds the tarball' );

    open my $compose_fh, '<', 'integration/blank-env/docker-compose.yml' or die $!;
    my $compose = do { local $/; <$compose_fh> };
    close $compose_fh;
    like( $compose, qr/DASHBOARD_TARBALL/, 'integration compose file mounts the host-built tarball into the container' );
    unlike( $compose, qr/\.\.\/\.\.:\/workspace/, 'integration compose file does not mount the repo source into the container' );

    open my $host_fh, '<', 'integration/blank-env/run-host-integration.sh' or die $!;
    my $host = do { local $/; <$host_fh> };
    close $host_fh;
    like( $host, qr/\.perl5/, 'host launcher bootstraps a local perl toolchain when needed' );
    like( $host, qr/rm -rf Developer-Dashboard-\* Developer-Dashboard-\*\.tar\.gz/, 'host launcher removes old release build directories and tarballs before building a new one' );
    like( $host, qr/LOCAL_DZIL.*build/s, 'host launcher builds the tarball on the host with Dist::Zilla' );
    like( $host, qr/DASHBOARD_TARBALL/, 'host launcher exports the tarball path for docker compose' );
    like( $host, qr/run --rm blank-env/, 'host launcher runs the blank-environment integration service' );
    unlike( $host, qr/run --build --rm blank-env/, 'host launcher does not rebuild the integration image when using the prebuilt container path' );
    like( $host, qr/integration\/blank-env\/Dockerfile/, 'host launcher POD documents the pinned blank-environment Dockerfile path' );

    open my $windows_smoke_fh, '<', 'integration/windows/run-strawberry-smoke.ps1' or die $!;
    my $windows_smoke = do { local $/; <$windows_smoke_fh> };
    close $windows_smoke_fh;
    like( $windows_smoke, qr/cpanm/, 'Windows Strawberry smoke script installs the tarball with cpanm' );
    like( $windows_smoke, qr/Get-CpanmBin/, 'Windows Strawberry smoke script resolves cpanm explicitly instead of assuming PATH is enough' );
    like( $windows_smoke, qr/App::cpanminus/, 'Windows Strawberry smoke script bootstraps App::cpanminus when cpanm is missing' );
    like( $windows_smoke, qr/PERL_MM_USE_DEFAULT/, 'Windows Strawberry smoke script forces non-interactive CPAN bootstrap defaults' );
    like( $windows_smoke, qr/Set-StrawberryPath/, 'Windows Strawberry smoke script normalizes the Strawberry runtime PATH before invoking wrappers' );
    like( $windows_smoke, qr/c\\bin/, 'Windows Strawberry smoke script adds the Strawberry toolchain bin directory to PATH' );
    like( $windows_smoke, qr/site\\\\bin/, 'Windows Strawberry smoke script adds Strawberry site bin to PATH so installed scripts resolve after cpanm' );
    like( $windows_smoke, qr/Tee-Object -FilePath/, 'Windows Strawberry smoke script captures native command transcripts for failure analysis' );
    like( $windows_smoke, qr/--verbose/, 'Windows Strawberry smoke script installs the tarball with verbose cpanm output for debugging' );
    like( $windows_smoke, qr/Copy-TarballToLocalTemp/, 'Windows Strawberry smoke script stages the tarball to a local temp path before cpanm install' );
    like( $windows_smoke, qr/Copy-Item -Path \$SourceTarball -Destination \$destination -Force/, 'Windows Strawberry smoke script copies shared tarballs off the UNC path before install' );
    like( $windows_smoke, qr/\[switch\]\$SkipCpanmTests/, 'Windows Strawberry smoke script accepts a switch to skip upstream cpanm dependency tests on Windows' );
    like( $windows_smoke, qr/--notest/, 'Windows Strawberry smoke script can install with cpanm --notest when Windows dependency tests are intentionally skipped' );
    like( $windows_smoke, qr/Get-CommandExecutablePath/, 'Windows Strawberry smoke script centralizes command-object to executable-path resolution' );
    like( $windows_smoke, qr/Get-WhereExecutablePath/, 'Windows Strawberry smoke script falls back to where.exe for Windows-native executable path resolution' );
    like( $windows_smoke, qr/foreach \(\$propertyName in \@\("Source", "Path", "Definition"\)\)/, 'Windows Strawberry smoke script falls back across Source, Path, and Definition when resolving executable paths' );
    like( $windows_smoke, qr/where\.exe/, 'Windows Strawberry smoke script uses where.exe when PowerShell command metadata does not expose a real path' );
    like( $windows_smoke, qr/\[AllowEmptyString\(\)\]\[string\]\$ResolvedPerl = ""/, 'Windows Strawberry smoke script allows an empty ResolvedPerl parameter so the fallback resolver can run inside Set-StrawberryPath' );
    like( $windows_smoke, qr/\[string\]::IsNullOrWhiteSpace\(\$ResolvedPerl\)/, 'Windows Strawberry smoke script guards against blank Perl path resolution before calling Test-Path' );
    like( $windows_smoke, qr/Unable to resolve a filesystem path for Perl interpreter/, 'Windows Strawberry smoke script throws an explicit error when a Perl command name cannot be resolved to a filesystem path' );
    like( $windows_smoke, qr/Write-PhaseStatus/, 'Windows Strawberry smoke script reports phase-level progress for long Windows runs' );
    like( $windows_smoke, qr/Copy-StatusArtifact/, 'Windows Strawberry smoke script copies diagnostic artifacts back to the shared status root' );
    like( $windows_smoke, qr/cpanm-install\.log/, 'Windows Strawberry smoke script exports the cpanm transcript into the shared status root' );
    like( $windows_smoke, qr/\$cpanmLog = Join-Path \$StatusRoot "cpanm-install\.log"/, 'Windows Strawberry smoke script writes the cpanm transcript directly into the shared status root when available' );
    like( $windows_smoke, qr/Disable-WindowsFirewallForSmoke/, 'Windows Strawberry smoke script disables the disposable guest firewall before CPAN listener tests run' );
    like( $windows_smoke, qr/Set-NetFirewallProfile|netsh\.exe/, 'Windows Strawberry smoke script uses native Windows firewall controls for the smoke guest' );
    unlike( $windows_smoke, qr/\&\s+\$cmd\.Source/, 'Windows Strawberry smoke script does not incorrectly invoke a cmdlet via its module Source field' );
    unlike( $windows_smoke, qr/Set-NetFirewallProfile failed with exit code/, 'Windows Strawberry smoke script does not assume cmdlets populate LASTEXITCODE' );
    like( $windows_smoke, qr/\$savedErrorActionPreference/, 'Windows Strawberry smoke script saves the caller error preference before native commands' );
    like( $windows_smoke, qr/\$ErrorActionPreference = 'Continue'/, 'Windows Strawberry smoke script avoids PowerShell terminating on native stderr before exit-code checks' );
    like( $windows_smoke, qr/dashboard shell ps/, 'Windows Strawberry smoke script verifies PowerShell shell bootstrap output' );
    like( $windows_smoke, qr/dashboard collector run/, 'Windows Strawberry smoke script exercises collector command execution' );
    like( $windows_smoke, qr/Invoke-WebRequest/, 'Windows Strawberry smoke script verifies browser-facing HTTP routes with PowerShell web requests' );
    like( $windows_smoke, qr/msedge\.exe|chrome\.exe/, 'Windows Strawberry smoke script looks for a Windows browser binary for DOM smoke checks' );
    like( $windows_smoke, qr/__END__/, 'Windows Strawberry smoke script carries POD trailer' );
    unlike( $windows_smoke, qr/Developer-Dashboard-1\.\d+\.tar\.gz/, 'Windows Strawberry smoke script POD avoids hard-coded release tarball versions' );
    unlike( $windows_smoke, qr/\&\s+\$Command\[0\]\s+\@Command\[/, 'Windows Strawberry smoke script avoids invalid inline PowerShell splatting expressions' );
    like( $windows_smoke, qr/\$command_args\s*=\s*@\(\)/, 'Windows Strawberry smoke script stages command arguments into a separate splat array' );

    open my $qemu_fh, '<', 'integration/windows/run-qemu-windows-smoke.sh' or die $!;
    my $qemu = do { local $/; <$qemu_fh> };
    close $qemu_fh;
    like( $qemu, qr/qemu-system-x86_64/, 'Windows QEMU launcher boots a Windows VM with qemu-system-x86_64' );
    like( $qemu, qr/scp|ssh/, 'Windows QEMU launcher copies the tarball and smoke script into the guest over SSH' );
    like( $qemu, qr/run-strawberry-smoke\.ps1/, 'Windows QEMU launcher runs the Strawberry smoke script inside the guest' );
    like( $qemu, qr/'-StatusRoot', \\\$shared/, 'Windows QEMU launcher passes the shared status root into the Windows smoke script' );
    like( $qemu, qr/Dockur Windows container disappeared before reporting success/, 'Windows QEMU launcher fails fast when the Dockur container vanishes before reporting a result' );
    like( $qemu, qr/dockur-host\.log/, 'Windows QEMU launcher persists host-side Dockur failure diagnostics into the shared workdir' );
    like( $qemu, qr/dockur-container\.log/, 'Windows QEMU launcher streams Dockur container logs into the shared workdir for post-mortem analysis' );
    like( $qemu, qr/docker logs -f/, 'Windows QEMU launcher tails Dockur container logs while the guest is running' );
    like( $qemu, qr/WINDOWS_DOCKUR_KEEP_RUNNING/, 'Windows QEMU launcher supports preserving the Dockur VM after the smoke exits' );
    like( $qemu, qr/WINDOWS_DOCKUR_WEB_PORT/, 'Windows QEMU launcher supports an override for the Dockur web console port' );
    like( $qemu, qr/WINDOWS_DOCKUR_RDP_PORT/, 'Windows QEMU launcher supports an override for the Dockur RDP port' );
    like( $qemu, qr/WINDOWS_SKIP_CPANM_TESTS/, 'Windows QEMU launcher supports a Windows-specific cpanm test policy toggle' );
    like( $qemu, qr/reusing existing Dockur Windows container/, 'Windows QEMU launcher can reuse an existing Dockur container instead of always recreating it' );
    like( $qemu, qr/prepare_strawberry_installer/, 'Windows QEMU launcher stages the Strawberry Perl installer from the host ahead of guest bootstrap' );
    like( $qemu, qr/strawberry-perl-installer\.msi/, 'Windows QEMU launcher caches the Strawberry Perl MSI in the OEM folder' );
    like( $qemu, qr/LWP::UserAgent/, 'Windows QEMU launcher downloads the Strawberry Perl installer with LWP::UserAgent on the host' );
    like( $qemu, qr/locate-tarball/, 'Windows QEMU launcher bootstrap publishes the locate-tarball phase for long-running guest setup' );
    like( $qemu, qr/install-strawberry-perl/, 'Windows QEMU launcher bootstrap publishes the install-strawberry-perl phase for long-running guest setup' );
    like( $qemu, qr/run-strawberry-smoke/, 'Windows QEMU launcher bootstrap publishes the run-strawberry-smoke phase before invoking the in-guest smoke script' );
    like( $qemu, qr/-SkipCpanmTests/, 'Windows QEMU launcher bootstrap forwards the Windows cpanm skip-tests switch into the guest smoke when requested' );
    unlike( $qemu, qr/Invoke-WebRequest -UseBasicParsing -Uri "\$WINDOWS_STRAWBERRY_URL"/, 'Windows QEMU launcher bootstrap no longer downloads Strawberry Perl inside the Windows guest' );
    like( $qemu, qr/-p "\$\{WINDOWS_DOCKUR_WEB_PORT\}:8006"/, 'Windows QEMU launcher maps the configurable host web port to Dockur port 8006' );
    like( $qemu, qr/-p "\$\{WINDOWS_DOCKUR_RDP_PORT\}:3389\/tcp"/, 'Windows QEMU launcher maps the configurable host RDP TCP port to Dockur port 3389' );
    like( $qemu, qr/-p "\$\{WINDOWS_DOCKUR_RDP_PORT\}:3389\/udp"/, 'Windows QEMU launcher maps the configurable host RDP UDP port to Dockur port 3389' );
    like( $qemu, qr/windows-qemu\.env|WINDOWS_QEMU_ENV_FILE/, 'Windows QEMU launcher supports a reusable environment file' );
    like( $qemu, qr/\/dev\/kvm|enable-kvm/, 'Windows QEMU launcher manages KVM availability explicitly' );
    like( $qemu, qr/__END__/, 'Windows QEMU launcher carries POD trailer' );
    unlike( $qemu, qr/Developer-Dashboard-1\.\d+\.tar\.gz/, 'Windows QEMU launcher POD avoids hard-coded release tarball versions' );

    open my $windows_host_fh, '<', 'integration/windows/run-host-windows-smoke.sh' or die $!;
    my $windows_host = do { local $/; <$windows_host_fh> };
    close $windows_host_fh;
    like( $windows_host, qr/dzil build/, 'Windows host rerun helper builds a fresh tarball when needed' );
    like( $windows_host, qr/run-qemu-windows-smoke\.sh/, 'Windows host rerun helper delegates to the QEMU launcher' );
    like( $windows_host, qr/windows-qemu\.env|WINDOWS_QEMU_ENV_FILE/, 'Windows host rerun helper supports the reusable environment file' );
    like( $windows_host, qr/Developer-Dashboard-\*\.tar\.gz|\*\.tar\.gz/, 'Windows host rerun helper uses version-agnostic tarball discovery' );
    like( $windows_host, qr/__END__/, 'Windows host rerun helper carries POD trailer' );
    unlike( $windows_host, qr/Developer-Dashboard-1\.\d+\.tar\.gz/, 'Windows host rerun helper POD avoids hard-coded release tarball versions' );
}
else {
    ok( -d 'integration', 'release tarball keeps integration assets for shipped install-time verification' );
    ok( -f 'doc/integration-test-plan.md', 'release tarball keeps the integration test plan document for shipped verification guidance' );
    ok( -f 'doc/testing.md', 'release tarball keeps the general testing workflow document for shipped verification guidance' );
    ok( -f 'doc/windows-testing.md', 'release tarball keeps the Windows testing guide for shipped verification guidance' );
}

if ( -f 'dist.ini' ) {
    open my $dist_fh, '<', 'dist.ini' or die $!;
    my $dist = do { local $/; <$dist_fh> };
    close $dist_fh;
    like( $dist, qr/exclude_filename = Makefile\.PL/, 'dist.ini excludes checked-in Makefile.PL from dzil gather phase' );
    like( $dist, qr/\[AutoPrereqs\]/, 'dist.ini includes AutoPrereqs for built distribution dependencies' );
    like( $dist, qr/^JSON::XS = 0$/m, 'dist.ini pins JSON::XS explicitly for built distribution runtime metadata' );
}
else {
    ok( !-f 'dist.ini', 'release tarball excludes dist.ini from shipped assets' );
    open my $meta_fh, '<', 'META.json' or die $!;
    my $meta = json_decode( do { local $/; <$meta_fh> } );
    close $meta_fh;
    ok( exists $meta->{prereqs}, 'META.json ships generated prerequisite metadata in the tarball' );
    ok( exists $meta->{prereqs}{runtime}, 'META.json keeps runtime prerequisite sections in the tarball' );
    ok( exists $meta->{prereqs}{runtime}{requires}{'JSON::XS'}, 'META.json keeps JSON::XS in shipped runtime prerequisites' );
}

done_testing;

sub _path_is_git_tracked {
    my ($path) = @_;
    return 0 if !defined $path || $path eq '';
    my ( $stdout, $stderr, $status ) = capture {
        system( 'git', 'ls-files', '--error-unmatch', '--', $path );
    };
    return $status == 0 ? 1 : 0;
}

__END__

=head1 NAME

13-integration-assets.t - verify blank-environment integration assets exist

=head1 DESCRIPTION

This test verifies that the blank-environment Docker integration plan and
runner assets are present and cover the intended install and smoke flow.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for This test verifies that the blank-environment Docker integration plan and runner assets are present and cover the intended install and smoke flow. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because This test verifies that the blank-environment Docker integration plan and runner assets are present and cover the intended install and smoke flow has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing This test verifies that the blank-environment Docker integration plan and runner assets are present and cover the intended install and smoke flow, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/13-integration-assets.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. 

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/13-integration-assets.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/13-integration-assets.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
