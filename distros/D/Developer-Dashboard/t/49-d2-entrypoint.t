#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;
use Capture::Tiny qw(capture);

my $repo_root = abs_path( File::Spec->catdir( dirname(__FILE__), '..' ) );
my $lib       = File::Spec->catdir( $repo_root, 'lib' );
my $d2        = File::Spec->catfile( $repo_root, 'bin', 'd2' );
my $dashboard = File::Spec->catfile( $repo_root, 'bin', 'dashboard' );

ok( -f $d2, 'bin/d2 is shipped as a real entrypoint' );
ok( -x $d2, 'bin/d2 is executable' );

# d2 must be a real re-exec into the sibling dashboard, not a copy of the
# switchboard body and not a shell alias.
my $source = do {
    open my $fh, '<:raw', $d2 or die "Unable to read $d2: $!";
    local $/;
    <$fh>;
};
like( $source, qr/^#!.*perl/,             'bin/d2 is a real perl script' );
like( $source, qr/\bexec\b/,              'bin/d2 execs rather than aliasing' );
like( $source, qr/catfile\(\s*\$Bin\s*,\s*'dashboard'\s*\)/, 'bin/d2 resolves its sibling dashboard entrypoint' );
unlike( $source, qr/_exec_switchboard_command|_builtin_helper_command/, 'bin/d2 does not duplicate the switchboard body' );

# Functionally identical to dashboard for a representative command.
my ( $d2_out, $d2_err, $d2_exit ) = capture {
    system( $^X, '-I', $lib, $d2, 'version' );
};
my ( $db_out, $db_err, $db_exit ) = capture {
    system( $^X, '-I', $lib, $dashboard, 'version' );
};
is( $d2_exit >> 8, 0,        'd2 version exits cleanly' );
is( $d2_out,       $db_out,  'd2 version output matches dashboard version output' );
like( $d2_out, qr/\A\d+\.\d+\s*\z/, 'd2 version prints the dashboard version number' );

# d2 forwards further arguments to the same command surface.
my ( $help_out, undef, $help_exit ) = capture {
    system( $^X, '-I', $lib, $d2, 'help' );
};
is( $help_exit >> 8, 0, 'd2 help exits cleanly' );
like( $help_out, qr/dashboard/, 'd2 help renders the dashboard command manual' );

# File-specific POD (no generic boilerplate) is present.
like( $source, qr/^=head1 NAME$/m, 'bin/d2 carries POD documentation' );

# The tarball ships the repo Makefile.PL verbatim (there is no [MakeMaker]
# plugin), so d2 only lands on PATH if Makefile.PL lists it in EXE_FILES.
my $makefile_pl = do {
    open my $mf, '<:raw', File::Spec->catfile( $repo_root, 'Makefile.PL' )
      or die "Unable to read Makefile.PL: $!";
    local $/;
    <$mf>;
};
like(
    $makefile_pl,
    qr/EXE_FILES\s*=>\s*\[[^\]]*'bin\/d2'/s,
    'Makefile.PL installs bin/d2 as an executable so d2 is a real command after install',
);

done_testing;

__END__

=pod

=head1 NAME

t/49-d2-entrypoint.t - regression contract for the real d2 short entrypoint

=head1 PURPOSE

This test is the executable regression contract for C<bin/d2>. It verifies that
C<d2> is shipped as a real, executable Perl entrypoint that re-execs its sibling
C<dashboard> command rather than duplicating the switchboard body or existing
only as a shell alias, and that C<d2> and C<dashboard> produce identical output
for a representative command.

=head1 WHY IT EXISTS

C<d2> used to exist only as a shell function defined by the dashboard shell
bootstrap, so it was unavailable in scripts and fresh shells. This test exists
so C<d2> stays a genuine installed command that behaves exactly like
C<dashboard>, and so a future change cannot quietly turn it back into a
shell-only alias or fork the command body.

=head1 WHEN TO USE

Use this file when changing how C<d2> locates and re-enters the main
C<dashboard> entrypoint, or when changing how C<d2> is packaged as an installed
executable.

=head1 HOW TO USE

Run C<prove -lv t/49-d2-entrypoint.t> while iterating on the short entrypoint.
Keep it green under C<prove -lr t> before calling the work complete.

=head1 WHAT USES IT

Developers during TDD, the repository test suite, and the release gate all use
this file to keep C<d2> a real, dashboard-equivalent command.

=head1 EXAMPLES

Example 1:

  prove -lv t/49-d2-entrypoint.t

Run the dedicated d2 entrypoint regression check by itself.

Example 2:

  prove -lr t

Run the d2 entrypoint regression inside the full repository suite before
release.

=cut
