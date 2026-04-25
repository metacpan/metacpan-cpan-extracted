package Developer::Dashboard::PageRuntime::StreamHandle;

use strict;
use warnings;

our $VERSION = '3.14';

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

This module is the small stream object used by page runtime and web streaming code. It presents one consistent write interface for incremental output so bookmark runtime code and server-side streaming can push chunks without depending on a specific PSGI responder implementation.

=head1 WHY IT EXISTS

It exists because streaming output is easier to test when the stream sink is a small object instead of a raw callback buried in transport code. That separation also keeps disconnect handling and chunk capture explicit.

=head1 WHEN TO USE

Use this file when changing streaming write semantics, buffering behavior, or tests around incremental page output and broken-pipe handling.

=head1 HOW TO USE

Construct it with the callback or sink expected by the caller, then pass it into the part of the runtime that wants to emit streaming content. Keep transport-neutral streaming behavior here rather than tying it to one web-server code path.

=head1 WHAT USES IT

It is used by page-runtime streaming helpers, by web response code that needs incremental output, and by coverage tests around streamed bookmark and Ajax behavior.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::PageRuntime::StreamHandle -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/07-core-units.t t/21-refactor-coverage.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
