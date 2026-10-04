package Developer::Dashboard::JSON;

use strict;
use warnings;

our $VERSION = '5.51';

use Exporter 'import';
use JSON::XS ();

our @EXPORT_OK = qw(json_encode json_encode_with_options json_decode json_decode_state);

# json_encode($value)
# Serializes a Perl value into canonical pretty JSON.
# Input: scalar/array/hash reference.
# Output: JSON text string.
sub json_encode {
    return JSON::XS->new->utf8->canonical->pretty->encode( $_[0] );
}

# json_encode_with_options($value, %opts)
# Serializes a Perl value with explicit, named JSON::XS option choices
# (DD-1002) - the option-variant form this module's own POD describes for
# call sites that legitimately need a different combination from
# json_encode()'s fixed utf8+canonical+pretty defaults (e.g. ASCII-safe
# output for embedding in a shell-generated source file, or a compact
# canonical digest input that must never pretty-print so the hash stays
# stable). "canonical" is always on, matching every call site this
# centralizes - there is no known case in this codebase that needs
# non-canonical key ordering. Every other option defaults OFF, matching
# JSON::XS's own default, so a caller only names what it actually needs.
# Input: scalar/array/hash reference, plus optional %opts: "ascii" (escape
# non-ASCII to \uXXXX), "pretty" (indented multi-line output), "utf8"
# (encode the result as UTF-8 bytes rather than a Perl character string).
# Output: JSON text string.
sub json_encode_with_options {
    my ( $value, %opts ) = @_;
    my $json = JSON::XS->new->canonical(1);
    $json = $json->ascii(1)  if $opts{ascii};
    $json = $json->pretty(1) if $opts{pretty};
    $json = $json->utf8(1)   if $opts{utf8};
    return $json->encode($value);
}

# json_decode($json)
# Parses JSON text into a Perl data structure.
# Input: JSON text string.
# Output: decoded Perl value.
sub json_decode {
    return JSON::XS->new->utf8->decode( $_[0] );
}

# json_decode_state($json)
# Parses cached runtime state that a concurrent writer may be replacing.
# Runtime state files are written to a temporary path and renamed into place, so
# a reader can legitimately observe the destination while it is still empty or
# only partially written. Such an observation means "no usable state right now",
# not "corrupt data", so it must not be fatal to the caller.
# Input: JSON text string, possibly undef, empty, or truncated.
# Output: decoded Perl value, or undef when no complete payload is available.
sub json_decode_state {
    my ($json) = @_;
    return undef if !defined $json;
    return undef if $json !~ /\S/;
    my $decoded = eval { JSON::XS->new->utf8->decode($json) };
    return $decoded if !$@;
    return undef;
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

=head2 json_encode_with_options

Encode a Perl value as canonical JSON with explicit C<ascii>/C<pretty>/C<utf8>
option choices (DD-1002), for call sites that need a different combination
than C<json_encode>'s fixed defaults.

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
