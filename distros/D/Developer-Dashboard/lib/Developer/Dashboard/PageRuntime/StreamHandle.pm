package Developer::Dashboard::PageRuntime::StreamHandle;

use strict;
use warnings;

our $VERSION = '1.33';

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

=cut
