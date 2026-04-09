package Developer::Dashboard::JSON;

use strict;
use warnings;

our $VERSION = '2.02';

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

Perl module in the Developer Dashboard codebase. This file centralizes JSON::XS-based encode and decode helpers for the project.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to keep this responsibility in reusable Perl code instead of hiding it in the thin C<dashboard> switchboard, bookmark text, or duplicated helper scripts. That separation makes the runtime easier to test, safer to change, and easier for contributors to navigate.

=head1 WHEN TO USE

Use this file when you are changing the underlying runtime behaviour it owns, when you need to call its routines from another part of the project, or when a failing test points at this module as the real owner of the bug.

=head1 HOW TO USE

Load C<Developer::Dashboard::JSON> from Perl code under C<lib/> or from a focused test, then use the public routines documented in the inline function comments and existing SYNOPSIS/METHODS sections. This file is not a standalone executable.

=head1 WHAT USES IT

This file is used by whichever runtime path owns this responsibility: the public C<dashboard> entrypoint, staged private helper scripts under C<share/private-cli/>, the web runtime, update flows, and the focused regression tests under C<t/>.

=head1 EXAMPLES

  perl -Ilib -MDeveloper::Dashboard::JSON -e 'print qq{loaded\n}'

That example is only a quick load check. For real usage, follow the public routines already described in the inline code comments and any existing SYNOPSIS section.

=for comment FULL-POD-DOC END

=cut
