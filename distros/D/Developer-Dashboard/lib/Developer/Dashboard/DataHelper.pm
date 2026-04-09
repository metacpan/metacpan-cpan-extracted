package Developer::Dashboard::DataHelper;

use strict;
use warnings;

our $VERSION = '2.02';

use Exporter 'import';

use Developer::Dashboard::JSON qw(json_decode json_encode);

our @EXPORT = qw(j je);

# j($value)
# Encodes a Perl value to canonical JSON text.
# Input: any JSON-encodable Perl value.
# Output: JSON string.
sub j {
    return json_encode( $_[0] );
}

# je($text)
# Decodes JSON text to a Perl value.
# Input: JSON string.
# Output: decoded Perl value.
sub je {
    return json_decode( $_[0] // '' );
}

1;

__END__

=head1 NAME

Developer::Dashboard::DataHelper - older JSON helper compatibility functions

=head1 SYNOPSIS

  use Developer::Dashboard::DataHelper qw(j je);
  my $json = j({ ok => 1 });

=head1 DESCRIPTION

This module provides the small older JSON helper functions used by older
bookmark code blocks.

=head1 FUNCTIONS

=head2 j, je

Encode and decode JSON values.

=for comment FULL-POD-DOC START

=head1 PURPOSE

Perl module in the Developer Dashboard codebase. This file provides shared data shaping, rendering, and utility helpers used across the runtime.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to keep this responsibility in reusable Perl code instead of hiding it in the thin C<dashboard> switchboard, bookmark text, or duplicated helper scripts. That separation makes the runtime easier to test, safer to change, and easier for contributors to navigate.

=head1 WHEN TO USE

Use this file when you are changing the underlying runtime behaviour it owns, when you need to call its routines from another part of the project, or when a failing test points at this module as the real owner of the bug.

=head1 HOW TO USE

Load C<Developer::Dashboard::DataHelper> from Perl code under C<lib/> or from a focused test, then use the public routines documented in the inline function comments and existing SYNOPSIS/METHODS sections. This file is not a standalone executable.

=head1 WHAT USES IT

This file is used by whichever runtime path owns this responsibility: the public C<dashboard> entrypoint, staged private helper scripts under C<share/private-cli/>, the web runtime, update flows, and the focused regression tests under C<t/>.

=head1 EXAMPLES

  perl -Ilib -MDeveloper::Dashboard::DataHelper -e 'print qq{loaded\n}'

That example is only a quick load check. For real usage, follow the public routines already described in the inline code comments and any existing SYNOPSIS section.

=for comment FULL-POD-DOC END

=cut
