use strict;
use warnings;

use Test::More;

eval { require Test::Pod; 1 }
  or plan skip_all => 'Test::Pod is required for the POD syntax gate';

Test::Pod::all_pod_files_ok();

__END__

=head1 NAME

t/37-pod-syntax.t - enforce repository POD syntax validity

=head1 SYNOPSIS

  prove -lv t/37-pod-syntax.t

=head1 DESCRIPTION

This test runs the repository POD syntax gate through C<Test::Pod> so release
artifacts do not ship malformed POD that later shows up as a kwalitee failure
or PAUSE indexing warning.

=head1 PURPOSE

This file is the executable regression contract for POD syntax across the
project-owned Perl files. It gives the TDD loop a direct way to catch malformed
or encoding-broken POD before release packaging reports it after the fact.

=head1 WHY IT EXISTS

It exists because POD errors are easy to miss during normal feature work, but
they degrade release quality and show up in kwalitee reports. Keeping the check
in the test suite turns that packaging requirement into a normal local gate.

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
