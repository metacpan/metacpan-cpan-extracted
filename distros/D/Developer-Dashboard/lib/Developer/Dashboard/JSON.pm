package Developer::Dashboard::JSON;

use strict;
use warnings;

our $VERSION = '2.34';

use Exporter 'import';
use JSON::XS ();

our @EXPORT_OK = qw(json_encode json_decode);

# json_encode($value)
# Serializes a Perl value into canonical pretty JSON.
# Input: scalar/array/hash reference.
# Output: JSON text string.
sub json_encode {
    return JSON::XS->new->utf8->canonical->pretty->encode( $_[0] );
}

# json_decode($json)
# Parses JSON text into a Perl data structure.
# Input: JSON text string.
# Output: decoded Perl value.
sub json_decode {
    return JSON::XS->new->utf8->decode( $_[0] );
}

1;

__END__

=head1 NAME

Developer::Dashboard::JSON - JSON::XS wrapper for Developer Dashboard

=head1 SYNOPSIS

  use Developer::Dashboard::JSON qw(json_encode json_decode);

=head1 DESCRIPTION

This module centralizes JSON encoding and decoding so the project uses a
single consistent JSON backend and output style.

=head1 FUNCTIONS

=head2 json_encode

Encode a Perl value as canonical pretty JSON.

=head2 json_decode

Decode JSON text into a Perl value.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module centralizes JSON handling on top of C<JSON::XS>. It provides one canonical pretty encoder and one decoder so the runtime, helper scripts, and tests all use the same backend and the same output style.

=head1 WHY IT EXISTS

It exists because the project has a hard rule to use C<JSON::XS> and to avoid drifting JSON styles. By routing JSON encode/decode through one module, the dashboard avoids backend mismatch and keeps test fixtures and CLI output stable.

=head1 WHEN TO USE

Use this file when a feature needs JSON text, when pretty/canonical output expectations change, or when you are auditing the codebase for JSON backend drift.

=head1 HOW TO USE

Import C<json_encode> and C<json_decode> from this module instead of constructing C<JSON::XS> ad hoc in feature code. Small compatibility helpers such as C<Developer::Dashboard::DataHelper> should still route back here.

=head1 WHAT USES IT

It is used across the runtime by config, web, path, collector, skill, and helper flows, as well as by tests that assume canonical JSON output.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::JSON -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/21-refactor-coverage.t t/00-load.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
