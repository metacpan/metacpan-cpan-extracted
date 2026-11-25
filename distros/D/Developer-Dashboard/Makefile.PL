use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::ShareDir::Install qw(install_share);
use Config;
use File::Spec;
use Cwd qw(cwd);

install_share dist => 'share';

# Find a local::lib root with installed modules, preferring the project-local
# tree and then the current user's Perl tree. HOME is common on Unix and
# USERPROFILE is the Windows fallback. This keeps generated test commands able
# to discover developer dependencies without interpolating an unset variable.
my $local_lib_root;
my @local_lib_candidates = ('.perl5');
my $home = $ENV{HOME};
$home = $ENV{USERPROFILE} if !defined $home || $home eq '';
push @local_lib_candidates, File::Spec->catdir( $home, 'perl5' )
  if defined $home && $home ne '';

for my $candidate (@local_lib_candidates) {
    my $lib = File::Spec->catdir( $candidate, 'lib', 'perl5' );
    my @module_dirs = (
        $lib,
        File::Spec->catdir( $lib, $Config{archname} ),
        File::Spec->catdir( $lib, $Config{version} ),
    );
    if ( grep { -d $_ && grep { -f $_ } glob( File::Spec->catfile( $_, '*.pm' ) ) } @module_dirs ) {
        $local_lib_root = $candidate;
        last;
    }
}
$local_lib_root ||= '.perl5';

# TEST_REQUIRES
# Keep Test::Harness available on every platform. Windows CI installs
# Devel::Cover explicitly and fails if coverage instrumentation is unavailable.
# Ordinary Windows builds do not require coverage tools.
# Input: the current Perl operating system name in $^O.
# Output: a hashref of platform-supported test prerequisites for MakeMaker.
my %test_requires = ( 'Test::Harness' => '3.48' );
$test_requires{'Devel::Cover'} = 0 if $^O ne 'MSWin32';

WriteMakefile(
    NAME         => 'Developer::Dashboard',
    MIN_PERL_VERSION => '5.038',
    VERSION_FROM => 'lib/Developer/Dashboard/Version.pm',
    XS           => { 'HtmlEscape.xs' => 'HtmlEscape.c' },
    OBJECT       => 'HtmlEscape$(OBJ_EXT)',
    depend       => {
        'HtmlEscape.c' => 'GoRoutine012.xs GoRoutineProcess.xs GoRoutineEvent.h GoRoutineProcessNative.h Native.xs SystemMenu.xs SystemMenuNative.h',
        'HtmlEscape$(OBJ_EXT)' => 'GoRoutineEvent.h SystemMenuNative.h',
    },
    LIBS         => [ $^O eq 'linux' ? '-ldl' : q{} ],
    CCFLAGS      => $Config{ccflags} . ( $^O eq 'MSWin32' ? q{} : ' -pthread' ),
    ABSTRACT     => 'Project-neutral local developer dashboard runtime',
    AUTHOR       => 'Developer Dashboard Contributors',
    EXE_FILES    => [
        'bin/d2',
    ],
    PREREQ_PM    => {
        'strict'                => 0,
        'warnings'              => 0,
        'Cwd'                   => 0,
        'File::Basename'        => 0,
        'File::Path'            => 0,
        'File::Spec'            => 0,
        'File::Temp'            => 0,
        'File::Find'            => 0,
        'Cpanel::JSON::XS'      => '4.80',
        'Getopt::Long'          => 0,
        'HTML::Parser'          => '3.84',
        'Filter::Simple'        => 0,
        'HTTP::Date'            => '6.08',
        'HTTP::Parser::XS'      => '0.18',
        'HTTP::Tiny'            => '0.096',
        'HTTP::Request'         => 0,
        'JSON::XS'              => '4.04',
        'LWP::Protocol::https'  => '6.07',
        'LWP::UserAgent'        => '6.83',
        'Mozilla::CA'           => '20261020',
        'YAML'                  => '1.30',
        'YAML::XS'              => '0.903.0',
        'TOML::Parser'          => 0,
        'Capture::Tiny'         => '0.24',
        'Digest::MD5'           => '2.25',
        'Crypt::URandom'        => '0.55',
        'Digest::SHA'           => '5.96',
        'String::Compare::ConstantTime' => '0.321',
        'Archive::Tar'          => '3.10',
        'Archive::Zip'          => '1.61',
        'MIME::Base64'          => 0,
        'Compress::Raw::Zlib'   => '2.220',
        'IO::Compress::Gzip'    => '2.220',
        'IO::Uncompress::Gunzip'=> '2.220',
        'Dancer2'               => '2.2.0',
        'Plack'                 => '1.0056',
        'Pod::Text'             => '6.1.1',
        'Socket'                => '2.041',
        'Starman'               => '0.4019',
        'Storable'              => '3.41',
        'Template'              => '3.103',
        'URI'                   => '5.36',
        'URI::Escape'           => '5.36',
        'XML::Parser'           => '2.48',
        'Time::HiRes'           => 0,
        'POSIX'                 => 0,
    },
    LICENSE      => 'mit',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'    => 0,
        'File::ShareDir::Install' => 0,
    },
    TEST_REQUIRES => \%test_requires,
    META_MERGE   => {
        resources => {
            homepage   => 'https://github.mf/manif3station/developer-dashboard',
            bugtracker => {
                web => 'https://github.mf/manif3station/developer-dashboard/issues',
            },
            repository => {
                type => 'git',
                url  => 'git@github.mf:manif3station/developer-dashboard.git',
                web  => 'https://github.mf/manif3station/developer-dashboard',
            },
        },
        prereqs => {
            runtime => {
                recommends => {},
            },
        },
    },
);

package MY;

# _local_lib_perl5_paths()
# Resolves the selected local::lib root to the base, architecture, and active
# Perl-version directories used by the build's generated Perl launcher.
# Input: none; reads the detected root and active Perl Config values.
# Output: an ordered list of absolute module search paths.
sub _local_lib_perl5_paths {
    # An explicit PERL5LIB is the active runtime's dependency contract. Do not
    # append a checkout-local .perl5 tree in that case: it may contain XS
    # binaries built for another Perl ABI and shadow compatible system modules
    # in the spawned test or helper processes.
    return () if defined $ENV{PERL5LIB} && $ENV{PERL5LIB} ne '';

    my $base = File::Spec->catdir( $local_lib_root, 'lib', 'perl5' );
    $base = File::Spec->rel2abs( $base, Cwd::cwd() );
    my @paths = ($base);
    for my $platform_dir ( @Config::Config{qw(archname version)} ) {
        my $path = File::Spec->catdir( $base, $platform_dir );
        push @paths, $path if -d $path;
    }
    return @paths;
}

# _write_local_lib_runner($paths)
# Writes a small Perl launcher that appends local::lib paths after inherited
# PERL5LIB entries before executing the configured Perl with original arguments.
# Existing paths retain precedence, avoiding stale local XS libraries shadowing
# the active interpreter's compatible modules in child processes.
# Input: list of absolute local::lib directories.
# Output: relative generated launcher path; dies if writing or closing fails.
sub _write_local_lib_runner {
    my (@paths) = @_;
    my $runner = '.dd-perl5lib-runner.pl';
    my @quoted_paths = map {
        my $path = $_;
        $path =~ s/\\/\\\\/g;
        $path =~ s/'/\\'/g;
        "    '$path'";
    } @paths;
    my @test_paths = map { File::Spec->rel2abs( File::Spec->catdir( 'blib', $_ ), Cwd::cwd() ) } qw(lib arch);
    my @quoted_test_paths = map {
        my $path = $_;
        $path =~ s/\\/\\\\/g;
        $path =~ s/'/\\'/g;
        "    '$path'";
    } @test_paths;
    open my $fh, '>', $runner or die "Unable to create $runner: $!";
    print {$fh} "use strict;\nuse warnings;\nuse Config;\n\n",
      "my \@local_lib_paths = (\n", join( ",\n", @quoted_paths ), ");\n",
      "my \@test_lib_paths = (\n", join( ",\n", @quoted_test_paths ), ");\n",
      "my \$separator = quotemeta(\$Config{path_sep});\n",
      "my \@inherited = grep { length \$_ } split /\$separator/, \$ENV{PERL5LIB} // '';\n",
      "my \$is_test_harness = grep { \$_ eq '-MTest::Harness' } \@ARGV;\n",
      "my \@prefix = \$is_test_harness ? \@test_lib_paths : ();\n",
      "if (\$^O eq 'darwin') { require Cwd; \@inherited = map { Cwd::abs_path(\$_) // \$_ } \@inherited; \@local_lib_paths = map { Cwd::abs_path(\$_) // \$_ } \@local_lib_paths; \@test_lib_paths = map { Cwd::abs_path(\$_) // \$_ } \@test_lib_paths; }\n",
      "\$ENV{PERL5LIB} = join \$Config{path_sep}, \@prefix, \@inherited, \@local_lib_paths;\n",
      "my \$perl = \$^X;\n",
      "my \$status = system { \$perl } \$perl, \@ARGV;\n",
      "die \"Unable to execute \$perl: \$!\\n\" if \$status == -1;\n",
      "die \"\$perl terminated by signal \" . ( \$status & 127 ) . \"\\n\" if \$status & 127;\n",
      "exit( \$status >> 8 );\n",
      "__END__\n\n=head1 NAME\n\n.dd-perl5lib-runner.pl - portable local Perl library launcher\n\n",
      "=head1 DESCRIPTION\n\nPreserves inherited PERL5LIB entries before optional local::lib fallback paths, then runs the active Perl interpreter as a child process and forwards all arguments, exiting with the child's exit status. When MakeMaker invokes Test::Harness, it prepends the distribution's absolute blib/lib and blib/arch paths so subprocesses load the current build and its matching XS object. Keeping these active paths ahead of local fallbacks prevents stale XS binaries from shadowing modules compatible with the active interpreter. It is generated beside the Makefile and removed by the clean target.\n\n",
      "=head1 EXAMPLE\n\n  perl .dd-perl5lib-runner.pl -MModule::Name -e 'print qq(ok\\n)'\n\n=cut\n",
      or die "Unable to write $runner: $!";
    close $fh or die "Unable to close $runner: $!";
    return $runner;
}

# _program_in_path($name)
# Finds an executable by basename using the current PATH.
# Input: executable basename without directory components.
# Output: executable path, or undef when PATH has no executable match.
sub _program_in_path {
    my ($name) = @_;
    for my $directory ( File::Spec->path ) {
        next if !defined $directory || $directory eq q{};
        my $candidate = File::Spec->catfile( $directory, $name );
        return $candidate if -f $candidate && -x $candidate;
    }
    return;
}

# _linux_menu_helper_unavailable_reason()
# Checks whether the Linux System Menu helper's compile-time pkg-config modules exist.
# Input: none; reads PATH and runs pkg-config when available.
# Output: a visible reason string when the optional helper cannot be built, or undef.
sub _linux_menu_helper_unavailable_reason {
    my $pkg_config = _program_in_path('pkg-config');
    return 'pkg-config was not found on PATH' if !defined $pkg_config;

    my $status = system { $pkg_config } $pkg_config, '--exists',
      'ayatana-appindicator3-0.1', 'gtk+-3.0';
    die "Unable to execute pkg-config at '$pkg_config': $!\n" if $status == -1;
    die "pkg-config terminated by signal " . ( $status & 127 ) . "\n"
      if $status & 127;

    my $exit = $status >> 8;
    return if $exit == 0;
    return "pkg-config could not find ayatana-appindicator3-0.1 and gtk+-3.0 (exit $exit)";
}

# postamble()
# Appends the File::ShareDir::Install postamble so packaged installs refresh
# dist share assets, then adds the home-runtime helper bootstrap hook used by
# checkout and local installs. A Perl launcher provides local module paths to
# MakeMaker commands and their children without make-specific export syntax.
# Input: list of absolute local::lib directories.
# Output: full make postamble text string.
sub postamble {
    my $self = shift;
    my $share_postamble = File::ShareDir::Install::postamble($self);
    my $runner = _write_local_lib_runner( _local_lib_perl5_paths() );
    my $helper_name = $^O eq 'MSWin32'
      ? 'system_menu_helper.exe'
      : 'system_menu_helper';
    my ( $helper_source, $helper_compile, $helper_unavailable_reason );
    if ( $^O eq 'linux' ) {
        $helper_source = 'native/system_menu_helper_linux.c';
        $helper_compile = q{$(CC) $(CCFLAGS) -Werror=deprecated-declarations -o "$@" native/system_menu_helper_linux.c `pkg-config --cflags --libs ayatana-appindicator3-0.1 gtk+-3.0`};
        $helper_unavailable_reason = _linux_menu_helper_unavailable_reason();
    }
    elsif ( $^O eq 'darwin' ) {
        $helper_source = 'native/system_menu_helper_mac.m';
        $helper_compile = q{$(CC) $(CCFLAGS) -fobjc-arc -Werror=deprecated-declarations -o "$@" native/system_menu_helper_mac.m -framework AppKit -framework Foundation};
    }
    elsif ( $^O eq 'MSWin32' ) {
        $helper_source = 'native/system_menu_helper_win.c';
        $helper_compile = q{$(CC) $(CCFLAGS) -o "$@" native/system_menu_helper_win.c -lshell32 -luser32 -lgdi32};
    }
    else {
        die "System Menu native helper is unsupported on $^O\n";
    }
    my $helper_rules = q{};
    if ( defined $helper_unavailable_reason ) {
        my $install_hint = 'Install pkg-config, libayatana-appindicator3-dev, and libgtk-3-dev.';
        if ( ( $ENV{DD_REQUIRE_SYSTEM_MENU_HELPER} // q{} ) eq '1' ) {
            die "Required Linux System Menu helper cannot be built: "
              . "$helper_unavailable_reason. $install_hint\n";
        }
        print "Optional Linux System Menu helper was not built: "
          . "$helper_unavailable_reason. $install_hint\n";
    }
    else {
        my $helper_target = '$(INST_ARCHAUTODIR)/' . $helper_name;
        $helper_rules = join "\n",
          '.PHONY: build-system-menu-helper clean-system-menu-helper',
          'all :: build-system-menu-helper',
          "build-system-menu-helper: $helper_target",
          "$helper_target: $helper_source",
          "\t\$(MKPATH) \$(INST_ARCHAUTODIR)",
          "\t$helper_compile",
          'clean :: clean-system-menu-helper',
          'clean-system-menu-helper:',
          "\t\$(RM_F) $helper_target",
          q{};
    }
    return "FULLPERL = \$(PERL) $runner\n\n"
      . $share_postamble
      . $helper_rules
      . <<'END_POSTAMBLE';
.PHONY: clean-local-perl5lib-runner
clean :: clean-local-perl5lib-runner

clean-local-perl5lib-runner:
	$(RM_F) .dd-perl5lib-runner.pl

.PHONY: install pure_install install-private-cli-tools
install ::
	$(NOECHO) $(PERL) -e "1;"

pure_install :: install-private-cli-tools

install-private-cli-tools :
	$(NOECHO) $(PERL) -e 'use File::Copy; use File::Path qw(make_path); use File::Spec; my $$home = $$ENV{HOME} || $$ENV{USERPROFILE} || eval { (getpwuid($$>))[7] } || die "Unable to resolve a home directory for the private CLI helper staging\n"; my $$cli_dir = File::Spec->catdir($$home, ".developer-dashboard", "cli"); make_path($$cli_dir) unless -d $$cli_dir; for my $$cmd (qw(_dashboard-core jq yq tomq propq iniq csvq xmlq of open-file workspace file files path paths ps1 encode decode indicator collector config auth api ask init cpan page action docker serve stop restart log shell doctor housekeeper skills which upgrade complete)) { my $$src = File::Spec->catfile("share", "private-cli", $$cmd); my $$dst = File::Spec->catfile($$cli_dir, $$cmd); if (-f $$src) { File::Copy::copy($$src, $$dst) or warn "Failed to copy $$src to $$dst: $$!"; chmod(0755, $$dst); print "Installed $$cmd to $$cli_dir\n"; } }'
END_POSTAMBLE
}

__END__

=head1 NAME

Makefile.PL - configure and generate the Developer::Dashboard build Makefile

=head1 DESCRIPTION

This script configures the Developer::Dashboard Perl distribution with
ExtUtils::MakeMaker. It declares runtime and configuration prerequisites,
version metadata, executable scripts, XS extension sources, shared assets, and
repository metadata. Its MakeMaker postamble installs private command helpers
and removes its generated local-library launcher during C<make clean>.

On Linux, the System Menu helper is built when C<pkg-config> can find the
Ayatana AppIndicator3 and GTK3 development modules. If either module is absent,
configuration prints a notice and omits that optional helper target so CPAN
testers can build and test the distribution without desktop development
headers. The System Menu feature still reports a missing helper when invoked.
Set C<DD_REQUIRE_SYSTEM_MENU_HELPER=1> to make missing modules a configuration
failure; the Linux coverage workflow uses this setting so its native helper
check cannot be skipped.

When local::lib modules are present under C<.perl5> or the current user's
C<perl5> directory, the generated Makefile runs Perl commands through a small
generated launcher. The user's directory is resolved from C<HOME> on Unix or
C<USERPROFILE> on Windows; if neither variable exists, only C<.perl5> is
considered. The launcher adds the active local-library directories to
C<PERL5LIB> before running Perl and forwarding the original arguments. Child
commands inherit the same environment. The launcher avoids GNU make-only
assignment and export syntax, so source distributions remain parseable by BSD
and Solaris make.

=head1 WHEN TO USE

Run this configuration script when building or testing a source checkout with
MakeMaker. Dist::Zilla invokes it as part of distribution testing and
installation.

=head1 HOW TO USE

  perl Makefile.PL
  make
  make test
  make clean

The generated Makefile and launcher belong to the build tree; neither is
required as a checked-in source file.

=head1 EXAMPLES

Example 1: configure and test a source checkout:

  perl Makefile.PL && make test

Example 2: remove generated build files after testing:

  make clean

=head1 USERS

Maintainers and source-distribution installers use this file to configure the
distribution. CPAN testers use the generated Makefile with the platform's
native make implementation.

=cut
