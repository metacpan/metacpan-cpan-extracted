package Local::DevelCoverSwitch;

use strict;
use warnings;
use Exporter qw(import);

our @EXPORT_OK = qw(devel_cover_switches);

# devel_cover_switches($harness_switches)
# Return the complete Devel::Cover module switch from a harness option string.
# Input: optional HARNESS_PERL_SWITCHES string containing Perl -M options.
# Output: a one-element list containing the exact Devel::Cover switch, or an
#         empty list when coverage is not enabled.
sub devel_cover_switches {
    my ($harness_switches) = @_;
    return if !defined $harness_switches;
    return ($1)
      if $harness_switches =~ /(?:\A|\s)(-MDevel::Cover(?:=[^\s]+)?)(?=\s|\z)/;
    return;
}

1;

__END__

=pod

=head1 NAME

Local::DevelCoverSwitch - preserve coverage options for test subprocesses

=head1 PURPOSE

This test-only helper extracts the complete C<-MDevel::Cover> argument from
C<HARNESS_PERL_SWITCHES>. Coverage-focused tests use it when starting a Perl
child process so that the child writes to the same coverage database and uses
the same instrumentation exclusions as the parent.

=head1 WHY IT EXISTS

The repository coverage gate supplies C<-MDevel::Cover> with database and
ignore options attached after an equals sign. Forwarding only the bare module
name loses that configuration; a child can then write to a different
database, leaving its production call path uncovered in the gate report. This
helper recognizes both the bare module form and the configured form while
returning the exact original token.

=head1 WHEN TO USE

Use this helper from a test that launches a Perl subprocess whose production
code must contribute to the parent test's Devel::Cover report. Do not use it
for ordinary application code or to construct shell commands; its result is
an argument-list element for a Perl process.

=head1 HOW TO USE

Add C<t/lib> to the test library path and import the function:

  use lib 't/lib';
  use Local::DevelCoverSwitch qw(devel_cover_switches);

Then append its result directly to the child argument list:

  my @coverage_switch = devel_cover_switches($ENV{HARNESS_PERL_SWITCHES});
  my $pid = Developer::Dashboard::GoRoutine::spawn(
      [$^X, @coverage_switch, '-e', 'run_coverage_probe()'],
      { cwd => $repository },
  );

=head1 WHAT USES IT

C<t/75-cli-which-coverage.t>, C<t/80-cli-query-coverage.t>,
C<t/91-cli-ticket-coverage.t>, and C<t/98-cli-openfile-coverage.t> use this
function for child processes that exercise command handoffs or exit helpers.
Their focused tests and the repository-wide coverage gate invoke those child
paths through the same argument-preserving routine API.

=head1 EXAMPLES

Example 1, preserving an explicit database:

  my @switch = devel_cover_switches(
      '-MDevel::Cover=-db,/work/cover_db,-blib,0'
  );
  # @switch contains the exact configured module argument.

Example 2, accepting the simple harness form:

  my @switch = devel_cover_switches('-Mstrict -MDevel::Cover -w');
  # @switch contains only '-MDevel::Cover'.

Example 3, leaving normal runs uninstrumented:

  my @switch = devel_cover_switches('-Mstrict -w');
  # @switch is empty.

=cut
