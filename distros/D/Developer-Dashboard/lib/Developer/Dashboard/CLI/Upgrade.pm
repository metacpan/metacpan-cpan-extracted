package Developer::Dashboard::CLI::Upgrade;

use strict;
use warnings;

our $VERSION = '4.26';

use Developer::Dashboard::Platform ();
use File::Temp qw(tempfile);
use LWP::UserAgent;

my $UNIX_INSTALLER_URL = 'https://raw.githubusercontent.com/manif3station/developer-dashboard/master/install.sh';
my $WINDOWS_INSTALLER_URL = 'https://raw.githubusercontent.com/manif3station/developer-dashboard/master/install.ps1';

# run_upgrade(%args)
# Downloads, validates, and runs the canonical Developer Dashboard installer for
# the current platform, or prints the planned action without changing the host.
# Input: args array reference plus optional platform, user agent, runner, and
# output stream seams for deterministic tests.
# Output: numeric process exit code from the installer, or zero for dry-run.
sub run_upgrade {
    my (%args) = @_;
    my $argv = $args{args} || die "Missing upgrade arguments\n";
    die "Upgrade arguments must be an array reference\n" if ref($argv) ne 'ARRAY';

    my @argv = @{$argv};
    my $dry_run = @argv == 1 && $argv[0] eq '--dry-run' ? 1 : 0;
    die _usage() if @argv && !$dry_run;

    my $platform = $args{platform} || _platform_name();    # uncoverable condition false
    die "Unsupported upgrade platform '$platform'\n"
      if $platform ne 'unix' && $platform ne 'windows';
    my $url = $platform eq 'windows' ? $WINDOWS_INSTALLER_URL : $UNIX_INSTALLER_URL;
    my $out = $args{out} || \*STDOUT;

    if ($dry_run) {
        print {$out} "Developer Dashboard upgrade plan\n";
        print {$out} "Platform: $platform\n";
        print {$out} "Installer: $url\n";
        print {$out} $platform eq 'windows'
          ? "Command: pwsh|powershell -NoProfile -ExecutionPolicy Bypass -File <downloaded-install.ps1>\n"
          : "Command: sh <downloaded-install.sh>\n";
        return 0;
    }

    my $ua = $args{ua} || _user_agent();    # uncoverable condition false
    my $response = $ua->get($url);
    die sprintf "Unable to download Developer Dashboard installer from %s: %s %s\n",
      $url, $response->code, $response->message
      if !$response->is_success;
    die "Downloaded Developer Dashboard installer exceeds 512000 bytes\n"
      if ( $response->header('Client-Aborted') || '' ) eq 'max_size';

    my $content = $response->decoded_content;
    _validate_installer( $platform, $content );

    my $suffix = $platform eq 'windows' ? '.ps1' : '.sh';
    my ( $fh, $path ) = tempfile( 'developer-dashboard-upgrade-XXXXXX', SUFFIX => $suffix, TMPDIR => 1, UNLINK => 1 );
    binmode $fh, ':raw';
    print {$fh} $content;
    close $fh or die "Unable to close downloaded Developer Dashboard installer $path: $!\n";    # uncoverable branch true
    chmod 0600, $path or die "Unable to secure downloaded Developer Dashboard installer $path: $!\n";    # uncoverable branch true

    my @command = $platform eq 'windows'
      ? ( _powershell_command(), '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $path )
      : ( 'sh', $path );
    my $runner = $args{runner} || \&_run_command;
    return $runner->(\@command);
}

# _platform_name()
# Maps the active runtime platform to the installer family used by self-upgrade.
# Input: none; reads the shared Developer Dashboard platform detector so tests
# and forced-platform runs resolve the same way the rest of the runtime does.
# Output: "windows" on Windows runtimes, otherwise "unix" (Linux and macOS).
sub _platform_name {
    return Developer::Dashboard::Platform::is_windows() ? 'windows' : 'unix';
}

# _user_agent()
# Builds the HTTPS client used to fetch the canonical installer.
# Input: none.
# Output: configured LWP::UserAgent instance.
sub _user_agent {
    my $ua = LWP::UserAgent->new(
        agent      => "Developer-Dashboard/$VERSION upgrade",
        timeout    => 60,
        max_size   => 512_000,
        max_redirect => 3,
    );
    $ua->protocols_allowed( ['https'] );
    return $ua;
}

# _validate_installer($platform, $content)
# Rejects empty, oversized, or unexpected remote content before execution.
# Input: platform family and decoded response body.
# Output: true when the response matches the canonical installer shape; dies
# with an actionable error otherwise.
sub _validate_installer {
    my ( $platform, $content ) = @_;
    die "Downloaded Developer Dashboard installer is empty\n"
      if !defined $content || $content eq '';
    die "Downloaded Developer Dashboard installer exceeds 512000 bytes\n"
      if length($content) > 512_000;

    my $valid = $platform eq 'windows'
      ? $content =~ /Set-StrictMode -Version Latest/
        && $content =~ /Developer Dashboard install progress/
        && $content =~ /manif3station\/developer-dashboard\.git/
      : $content =~ /\A#!\/bin\/sh\r?\n/
        && $content =~ /Developer Dashboard install progress/
        && $content =~ /manif3station\/developer-dashboard\.git/;
    die "Downloaded content is not the expected Developer Dashboard $platform installer\n"
      if !$valid;
    return 1;
}

# _powershell_command()
# Resolves the supported PowerShell executable for a Windows upgrade.
# Input: current PATH.
# Output: pwsh or powershell executable name; dies when neither is available.
sub _powershell_command {
    return 'pwsh' if Developer::Dashboard::Platform::command_in_path('pwsh');
    return 'powershell' if Developer::Dashboard::Platform::command_in_path('powershell');
    die "Unable to upgrade on Windows: neither pwsh nor powershell is available\n";
}

# _run_command($argv)
# Executes the validated installer using an argv list and returns its true exit
# code without interpolating remote content through a command string.
# Input: command argv array reference.
# Output: numeric child exit code, or dies when process creation fails.
sub _run_command {
    my ($argv) = @_;
    system @{$argv};
    die "Unable to start Developer Dashboard installer: $!\n" if $? == -1;
    return 128 + ( $? & 127 ) if $? & 127;
    return $? >> 8;
}

# _usage()
# Returns the concise user-facing upgrade command syntax.
# Input: none.
# Output: usage message string ending in a newline.
sub _usage {
    return "Usage: dashboard upgrade [--dry-run]\n";
}

1;

__END__

=pod

=head1 NAME

Developer::Dashboard::CLI::Upgrade - safe cross-platform dashboard self-upgrade

=head1 SYNOPSIS

  use Developer::Dashboard::CLI::Upgrade;
  exit Developer::Dashboard::CLI::Upgrade::run_upgrade(args => \@ARGV);

=head1 DESCRIPTION

This module implements the first-class C<dashboard upgrade> and C<d2 upgrade>
behavior outside the thin public switchboard. It downloads the canonical HTTPS
bootstrap installer for the active platform, validates that the response has
the expected Developer Dashboard installer shape, writes it to a private
temporary file, and executes it using an argv list.

=for comment FULL-POD-DOC START

=head1 PURPOSE

Provide an explicit self-upgrade path that reuses the project's established
cross-platform bootstrap behavior while keeping remote content validation and
process status visible.

=head1 WHY IT EXISTS

Requiring users to remember and retype a remote installer pipeline makes
upgrades harder to discover and easier to perform inconsistently. A built-in
command gives both public entrypoints one tested, auditable route without
embedding installer logic in C<bin/dashboard>.

=head1 WHEN TO USE

Use this module when changing installer selection, HTTPS download behavior,
remote-content validation, dry-run reporting, or platform process invocation
for dashboard self-upgrades.

=head1 HOW TO USE

Call C<run_upgrade(args =E<gt> \@ARGV)> from the staged built-in helper. Users
run C<dashboard upgrade> or C<d2 upgrade>; C<--dry-run> prints the platform and
installer URL without downloading or executing anything.

=head1 WHAT USES IT

The staged C<upgrade> helper, both public CLI entrypoints, focused acceptance
tests, and the cross-platform install E2E matrix use this module.

=head1 EXAMPLES

  dashboard upgrade --dry-run
  dashboard upgrade
  d2 upgrade

=for comment FULL-POD-DOC END

=cut
