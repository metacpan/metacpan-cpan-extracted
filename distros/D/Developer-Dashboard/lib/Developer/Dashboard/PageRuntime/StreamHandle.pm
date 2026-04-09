package Developer::Dashboard::PageRuntime::StreamHandle;

use strict;
use warnings;

our $VERSION = '2.02';

# TIEHANDLE(%args)
# Creates a tied handle that forwards printed chunks to a callback.
# Input: writer code reference.
# Output: tied handle object hash reference.
sub TIEHANDLE {
    my ( $class, %args ) = @_;
    return bless { writer => $args{writer} || sub { } }, $class;
}

# PRINT(@parts)
# Forwards printed output chunks to the configured callback.
# Input: string parts from print.
# Output: true value.
sub PRINT {
    my ( $self, @parts ) = @_;
    $self->{writer}->( join '', map { defined $_ ? $_ : '' } @parts );
    return 1;
}

# PRINTF($format, @parts)
# Formats output and forwards it to the configured callback.
# Input: sprintf format plus values.
# Output: true value.
sub PRINTF {
    my ( $self, $format, @parts ) = @_;
    $self->{writer}->( sprintf( defined $format ? $format : '', @parts ) );
    return 1;
}

# CLOSE()
# Accepts close calls on the tied stream handle.
# Input: none.
# Output: true value.
sub CLOSE { return 1 }

1;

__END__

=head1 NAME

Developer::Dashboard::PageRuntime::StreamHandle - tied output handle for streamed bookmark runtime output

=head1 SYNOPSIS

  tie *STDOUT, 'Developer::Dashboard::PageRuntime::StreamHandle',
    writer => sub { my ($chunk) = @_; ... };

=head1 DESCRIPTION

This helper turns C<print> and C<printf> calls inside streamed bookmark CODE
execution into callback writes so the web server can forward output to the
browser incrementally.

=head1 METHODS

=head2 TIEHANDLE, PRINT, PRINTF, CLOSE

Implement the tied-handle contract used by streamed bookmark Ajax execution.

=for comment FULL-POD-DOC START

=head1 PURPOSE

Perl module in the Developer Dashboard codebase. This file adapts streaming handles used by bookmark runtime and saved Ajax execution.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to keep this responsibility in reusable Perl code instead of hiding it in the thin C<dashboard> switchboard, bookmark text, or duplicated helper scripts. That separation makes the runtime easier to test, safer to change, and easier for contributors to navigate.

=head1 WHEN TO USE

Use this file when you are changing the underlying runtime behaviour it owns, when you need to call its routines from another part of the project, or when a failing test points at this module as the real owner of the bug.

=head1 HOW TO USE

Load C<Developer::Dashboard::PageRuntime::StreamHandle> from Perl code under C<lib/> or from a focused test, then use the public routines documented in the inline function comments and existing SYNOPSIS/METHODS sections. This file is not a standalone executable.

=head1 WHAT USES IT

This file is used by whichever runtime path owns this responsibility: the public C<dashboard> entrypoint, staged private helper scripts under C<share/private-cli/>, the web runtime, update flows, and the focused regression tests under C<t/>.

=head1 EXAMPLES

  perl -Ilib -MDeveloper::Dashboard::PageRuntime::StreamHandle -e 'print qq{loaded\n}'

That example is only a quick load check. For real usage, follow the public routines already described in the inline code comments and any existing SYNOPSIS section.

=for comment FULL-POD-DOC END

=cut
