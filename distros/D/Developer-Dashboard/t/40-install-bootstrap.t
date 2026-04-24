#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny qw(capture);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($RealBin);
use Test::More;

my $root = File::Spec->catdir( $RealBin, File::Spec->updir );
my $install_sh = File::Spec->catfile( $root, 'install.sh' );
my $aptfile    = File::Spec->catfile( $root, 'aptfile' );
my $apkfile    = File::Spec->catfile( $root, 'apkfile' );
my $dnfile     = File::Spec->catfile( $root, 'dnfile' );
my $brewfile   = File::Spec->catfile( $root, 'brewfile' );
my $perlbrew_app_dist_url = 'https://cpan.metacpan.org/authors/id/G/GU/GUGOD/App-perlbrew-1.02.tar.gz';
my $perlbrew_app_dist_basename = 'App-perlbrew-1.02.tar.gz';

ok( -f $install_sh, 'install.sh exists at the repo root' );
ok( -f $aptfile, 'aptfile exists at the repo root' );
ok( -f $apkfile, 'apkfile exists at the repo root' );
ok( -f $dnfile, 'dnfile exists at the repo root' );
ok( -f $brewfile, 'brewfile exists at the repo root' );

{
    my ( $stdout, $stderr, $exit ) = capture {
        system( 'sh', '-n', $install_sh );
    };
    is( $exit >> 8, 0, 'install.sh passes POSIX shell syntax validation' )
      or diag $stdout . $stderr;
}

my @apt_packages  = _manifest_lines($aptfile);
my @apk_packages  = _manifest_lines($apkfile);
my @dnf_packages  = _manifest_lines($dnfile);
my @brew_packages = _manifest_lines($brewfile);
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
            "cpanm --no-wget --notest --local-lib-contained $home/perl5 local::lib App::cpanminus",
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
            "cpanm --no-wget --notest --local-lib-contained $home/perl5 local::lib App::cpanminus",
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
            "cpanm --no-wget --notest --local-lib-contained $home/perl5 local::lib App::cpanminus",
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
            "cpanm --no-wget --notest --local-lib-contained $home/perl5 local::lib App::cpanminus",
            "perl -I $home/perl5/lib/perl5 -Mlocal::lib",
            'cpanm --no-wget --notest Developer::Dashboard',
            'dashboard init',
        ],
        'install.sh avoids the conflicting Debian npm package when nodejs already ships the full Node toolchain',
    );
}

{
    my $home = tempdir( CLEANUP => 1 );
    my $fake_bin = tempdir( CLEANUP => 1 );
    my $log = File::Spec->catfile( $home, 'install.log' );
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
            "cpanm --no-wget --notest --local-lib-contained $home/perl5 local::lib App::cpanminus",
            "perl -I $home/perl5/lib/perl5 -Mlocal::lib",
            'cpanm --no-wget --notest Developer::Dashboard',
            'dashboard init',
        ],
        'install.sh follows the macOS bootstrap flow in manifest order',
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
    my $script_copy = _slurp($install_sh);
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
      );

    my ( $stdout, $stderr, $exit ) = capture {
        open my $pipe, '|-', 'sh', '-c', "$env_prefix sh -s" or die "Unable to start streamed installer: $!";
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
            "cpanm --no-wget --notest --local-lib-contained $home/perl5 local::lib App::cpanminus",
            "perl -I $home/perl5/lib/perl5 -Mlocal::lib",
            'cpanm --no-wget --notest Developer::Dashboard',
            'dashboard init',
        ],
        'streamed install.sh falls back to the embedded Debian-family manifest content',
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
            "cpanm --no-wget --notest --local-lib-contained $home/perl5 local::lib App::cpanminus",
            "perl -I $home/perl5/lib/perl5 -Mlocal::lib",
            'cpanm --no-wget --notest Developer::Dashboard',
            'dashboard init',
        ],
        'install.sh switches to perlbrew before the local::lib bootstrap when Debian ships an older Perl',
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
            "cpanm --no-wget --notest --local-lib-contained $home/perl5 local::lib App::cpanminus",
            "perl -I $home/perl5/lib/perl5 -Mlocal::lib",
            'cpanm --no-wget --notest Developer::Dashboard',
            'dashboard init',
        ],
        'install.sh activates the local App::perlbrew install before invoking perlbrew on Alpine',
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
    _write_executable(
        File::Spec->catfile( $fake_bin, 'brew' ),
        <<"SH",
#!/bin/sh
printf '%s\\n' "brew \$*" >> "$log"
if [ "\$1" = "install" ] && printf '%s ' "\$@" | grep -q ' node '; then
grep -qx 'node' "$node_marker" 2>/dev/null || printf '%s\\n' 'node' >> "$node_marker"
grep -qx 'npm' "$node_marker" 2>/dev/null || printf '%s\\n' 'npm' >> "$node_marker"
grep -qx 'npx' "$node_marker" 2>/dev/null || printf '%s\\n' 'npx' >> "$node_marker"
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
        File::Spec->catfile( $fake_bin, 'curl' ),
        <<"SH",
#!/bin/sh
printf '%s\\n' "curl \$*" >> "$log"
output=''
while [ \$# -gt 0 ]; do
case "\$1" in
  -o)
    output=\$2
    shift 2
    ;;
  *)
    shift
    ;;
esac
done
[ -n "\$output" ] || exit 1
mkdir -p "\$(dirname "\$output")"
printf '%s\\n' 'fake perlbrew tarball' > "\$output"
exit 0
SH
    );
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
