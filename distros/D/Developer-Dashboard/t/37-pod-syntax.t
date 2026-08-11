use strict;
use warnings;

use Cwd qw(abs_path);
use File::Spec;
use FindBin qw($RealBin);
use Test::More;

eval { require Test::Pod; 1 }
  or plan skip_all => 'Test::Pod is required for the POD syntax gate';

my $ROOT = abs_path( File::Spec->catdir( $RealBin, File::Spec->updir ) );

# Name the source directories explicitly. Test::Pod's default is blib/ whenever
# that directory exists and only falls back to lib/ otherwise, so in a checkout
# carrying a build tree this gate silently graded a stale snapshot instead of
# the working copy - it passed on blib while the same POD was broken in lib.
my @POD_ROOTS = grep { -d } map { File::Spec->catdir( $ROOT, $_ ) } qw(lib bin script t);

my @pod_files = sort( Test::Pod::all_pod_files(@POD_ROOTS) );
ok( scalar(@pod_files) > 0, 'the POD syntax gate found project source files to check' );
ok( !grep( { m{(?:\A|/)blib/} } @pod_files ), 'the POD syntax gate reads the source tree and never a blib build artifact' );

Test::Pod::pod_file_ok($_) for @pod_files;

done_testing();

__END__

=head1 NAME

t/37-pod-syntax.t - enforce repository POD syntax validity

=head1 SYNOPSIS

  prove -lv t/37-pod-syntax.t

=head1 DESCRIPTION

This test runs the repository POD syntax gate through C<Test::Pod> so release
artifacts do not ship malformed POD that later shows up as a kwalitee failure
or PAUSE indexing warning. It names C<lib>, C<bin>, C<script> and C<t> under the
repository root explicitly, and asserts that no checked path came from a build
tree, so the gate always grades the working copy.

=head1 PURPOSE

This file is the executable regression contract for POD syntax across the
project-owned Perl files. It gives the TDD loop a direct way to catch malformed
or encoding-broken POD before release packaging reports it after the fact.

=head1 WHY IT EXISTS

It exists because POD errors are easy to miss during normal feature work, but
they degrade release quality and show up in kwalitee reports. Keeping the check
in the test suite turns that packaging requirement into a normal local gate.

It also exists in this explicit form because the convenient default was unsafe.
C<Test::Pod::all_pod_files_ok> with no arguments scans C<blib> whenever that
directory exists, so a checkout carrying a build tree graded a stale copy of the
sources: the gate reported a clean pass while three files in the working copy
held POD that C<Pod::Simple> could not parse. Naming the source directories, and
failing outright on any C<blib> path, keeps a build artifact from ever standing
in for the code under test again.

=head1 WHEN TO USE

Use this test whenever you edit inline POD, add a new Perl file, or chase a
release report that mentions malformed POD or encoding warnings.

=head1 HOW TO USE

Run C<prove -lv t/37-pod-syntax.t> for a focused POD syntax check, or let it
ride inside the full C<prove -lr t> gate. When it fails, fix the reported POD
source directly instead of suppressing the parser warning.

=head1 WHAT USES IT

Developers during TDD, the repository test suite, and release verification use
this file to keep inline documentation parseable for installed users and CPAN
tooling.

=head1 EXAMPLES

Example 1:

  prove -lv t/37-pod-syntax.t

Run the focused POD syntax gate after editing inline documentation.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Keep the POD syntax gate inside the full covered suite before release.

=cut
