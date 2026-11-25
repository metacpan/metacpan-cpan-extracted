use strict;
use warnings;

use Capture::Tiny qw(capture);
use Cwd qw(getcwd abs_path);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use Test::More;

my $source_root = abs_path( File::Spec->catdir( $FindBin::Bin, File::Spec->updir ) );
my $http_parser_xs_available = eval {
    require HTTP::Parser::XS;
    ($HTTP::Parser::XS::VERSION || 0) >= 0.18;
} ? 1 : 0;
my @configure_inc_args = map { "-I$_" }
  grep { !ref($_) && File::Spec->file_name_is_absolute($_) && -d $_ } @INC;
my $fixture = tempdir( CLEANUP => 1 );
my $fixture_lib = File::Spec->catdir( $fixture, 'lib', 'Developer', 'Dashboard' );
my $fixture_share = File::Spec->catdir( $fixture, 'share' );
my $fixture_local_lib = File::Spec->catdir( $fixture, '.perl5', 'lib', 'perl5' );

make_path( $fixture_lib, $fixture_share, $fixture_local_lib );
copy(
    File::Spec->catfile( $source_root, 'Makefile.PL' ),
    File::Spec->catfile( $fixture, 'Makefile.PL' ),
) or die "Unable to copy Makefile.PL into fixture: $!";
copy(
    File::Spec->catfile( $source_root, 'lib', 'Developer', 'Dashboard', 'Version.pm' ),
    File::Spec->catfile( $fixture_lib, 'Version.pm' ),
) or die "Unable to copy Version.pm into fixture: $!";

open my $marker, '>', File::Spec->catfile( $fixture_local_lib, 'PortabilityProbe.pm' )
  or die "Unable to create local-lib marker: $!";
print {$marker} "package PortabilityProbe; 1;\n";
close $marker or die "Unable to close local-lib marker: $!";

my $caller_dir = getcwd();
chdir $fixture or die "Unable to enter Makefile fixture: $!";
my ( $stdout, $stderr, $exit ) = capture {
    system( $^X, 'Makefile.PL' );
};
chdir $caller_dir or die "Unable to restore working directory: $!";

is( $exit, 0, 'Makefile.PL generates a Makefile for the portability fixture' );
SKIP: {
    skip 'HTTP::Parser::XS 0.18 is required for warning-free Makefile.PL configuration', 1
      if !$http_parser_xs_available;
    is( $stderr, '', 'Makefile.PL emits no warnings for the portability fixture' );
}

my $makefile_path = File::Spec->catfile( $fixture, 'Makefile' );
ok( -f $makefile_path, 'Makefile.PL created the generated Makefile' );

my $makefile = '';
if ( -f $makefile_path ) {
    open my $makefile_fh, '<', $makefile_path
      or die "Unable to read generated Makefile: $!";
    local $/;
    $makefile = <$makefile_fh> // '';
    close $makefile_fh or die "Unable to close generated Makefile: $!";
}

ok( $makefile !~ qr/^PERL5LIB\s*:=/m,
    'generated Makefile avoids GNU-only PERL5LIB := assignment syntax' );
ok( $makefile !~ qr/^export\s+PERL5LIB\s*$/m,
    'generated Makefile avoids GNU-only export syntax for PERL5LIB' );
ok( $makefile !~ qr/^PERL5LIB\b/m,
    'generated Makefile does not inject local Perl paths into make syntax' );

unlink $makefile_path or die "Unable to remove generated Makefile before no-HOME check: $!";
my ( $no_home_stdout, $no_home_stderr, $no_home_exit ) = do {
    local $ENV{HOME};
    local $ENV{USERPROFILE};
    delete $ENV{HOME};
    delete $ENV{USERPROFILE};
    my $original_dir = getcwd();
    chdir $fixture or die "Unable to enter Makefile fixture for no-HOME check: $!";
    my @captured = capture {
        system( $^X, 'Makefile.PL' );
    };
    chdir $original_dir or die "Unable to restore working directory after no-HOME check: $!";
    @captured;
};

is( $no_home_exit, 0, 'Makefile.PL builds when neither HOME nor USERPROFILE is set' );
SKIP: {
    skip 'HTTP::Parser::XS 0.18 is required for warning-free Makefile.PL configuration', 1
      if !$http_parser_xs_available;
    is( $no_home_stderr, '', 'Makefile.PL does not warn while HOME and USERPROFILE are unset' );
}
ok( -f $makefile_path, 'Makefile.PL still creates the generated Makefile without a home variable' );

my $profile_home = File::Spec->catdir( $fixture, 'profile-home' );
my $profile_local_lib = File::Spec->catdir( $profile_home, 'perl5', 'lib', 'perl5' );
make_path($profile_local_lib);
my $profile_marker = File::Spec->catfile( $profile_local_lib, 'ProfileProbe.pm' );
open my $profile_fh, '>', $profile_marker
  or die "Unable to create profile-local marker: $!";
print {$profile_fh} "package ProfileProbe; 1;\n";
close $profile_fh or die "Unable to close profile-local marker: $!";
unlink File::Spec->catfile( $fixture_local_lib, 'PortabilityProbe.pm' )
  or die "Unable to remove the project-local marker before profile lookup: $!";

my ( $profile_stdout, $profile_stderr, $profile_exit ) = do {
    local $ENV{HOME};
    local $ENV{USERPROFILE} = $profile_home;
    local $ENV{PERL5LIB};
    delete $ENV{HOME};
    # Exercise USERPROFILE fallback itself, not the test runner's inherited
    # module path, which intentionally suppresses local-lib discovery. Keep the
    # already-installed configure prerequisites reachable through explicit -I
    # arguments because Makefile.PL legitimately loads them at configure time.
    delete $ENV{PERL5LIB};
    my $original_dir = getcwd();
    chdir $fixture or die "Unable to enter Makefile fixture for USERPROFILE check: $!";
    my @captured = capture {
        system( $^X, @configure_inc_args, 'Makefile.PL' );
    };
    chdir $original_dir or die "Unable to restore working directory after USERPROFILE check: $!";
    @captured;
};

is( $profile_exit, 0, 'Makefile.PL builds when USERPROFILE is the only home variable' );
SKIP: {
    skip 'HTTP::Parser::XS 0.18 is required for warning-free Makefile.PL configuration', 1
      if !$http_parser_xs_available;
    is( $profile_stderr, '', 'Makefile.PL does not warn when resolving USERPROFILE' );
}
my $runner_path = File::Spec->catfile( $fixture, '.dd-perl5lib-runner.pl' );
my $runner = '';
if ( -f $runner_path ) {
    open my $runner_fh, '<', $runner_path or die "Unable to read generated runner: $!";
    local $/;
    $runner = <$runner_fh> // '';
    close $runner_fh or die "Unable to close generated runner: $!";
}
like( $runner, qr/profile-home/,
    'Makefile.PL selects modules from the USERPROFILE Perl library when HOME is absent' );

done_testing();

__END__

=head1 NAME

805-makefile-portability.t - guard generated Makefiles against GNU-only syntax

=head1 DESCRIPTION

This regression test runs C<Makefile.PL> in a disposable fixture that contains
a project-local Perl library. It inspects the generated Makefile for shell and
make syntax that BSD make and Solaris make rejected in the CPAN Tester reports
for Developer-Dashboard 6.06. The fixture is isolated so the test does not
replace or modify the checkout's own generated Makefile.

=head1 WHY IT EXISTS

The package build must remain usable on non-GNU make implementations. C<Makefile.PL>
adds local Perl library paths for test commands; that convenience must not make
the generated distribution Makefile unparsable before tests can run.

=head1 PURPOSE

This test prevents unsupported make syntax from breaking a distribution before
its Perl tests can begin.

=head1 WHEN TO USE

Run this regression when changing Makefile.PL configuration or investigating
CPAN Tester failures involving generated Makefiles and non-GNU make.

=head1 HOW TO USE

Run this test from the project development container with:

  d2 docker compose exec dev prove -lv t/805-makefile-portability.t

=head1 WHAT USES IT

The test protects maintainers building source distributions, CPAN Testers
running them with BSD or Solaris make, and users installing the distribution
without GNU make.

=head1 EXAMPLES

Example 1:

  d2 docker compose exec dev prove -lv t/805-makefile-portability.t

Run this test directly while changing the MakeMaker postamble.

Example 2:

  d2 docker compose exec dev prove -lr t

Run the full suite, including this generated-Makefile regression.

=cut
