#
#===============================================================================
#
#         FILE:  Games::Go::AGA::Parse::Exceptions.pm
#
#  DESCRIPTION:  Exception classes for AGA parsers
#
#      PODNAME:  Games::Go::AGA::Parse::Exceptions
#     ABSTRACT:  Exceptions classes for AGA Parsers
#
#       AUTHOR:  Reid Augustin (REID), <reid@lucidport.com>
#      COMPANY:  LucidPort Technology, Inc.
#      CREATED:  01/18/2011 01:45:36 PM
#===============================================================================

use strict;
use warnings;

package Games::Go::AGA::Parse::Exceptions;

use Exception::Class (
    'Games::Go::AGA::Parse::Exception' => {
        description => 'base class for AGA parser exceptions',
        fields      => ['filename',         # if we know the filename
                        'handle',           # if we have the file handle
                        'line_number',      # if we know the line_number in the file
                        'source',           # source string that caused error
                        ],
      # alias       => 'parse_exception',   # Sadly, aliasing doesn't seem to work unless
                                            #   Exception::Class is 'use'd in the same
                                            #   module.  Makes it fairly worthless.
    },
);

our $VERSION = '0.042'; # VERSION

# Games::Go::AGA::Parse->Trace(1);     # provide stack trace

sub Games::Go::AGA::Parse::Exception::full_message {
    my ($self) = @_;

    my $msg         = $self->error;
    my $fname       = $self->filename;
    my $handle      = $self->handle;
    my $line_number = $self->line_number;
    my $source      = $self->source;

    $msg .= " while parsing:\n$source\n" if ($source);
    eval {
        $line_number = $handle->input_line_number;
    };
    $msg .= " at line $line_number"      if ($line_number);
    $msg .= " in $fname"                 if ($fname);
    return $msg;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Go::AGA::Parse::Exceptions - Exceptions classes for AGA Parsers

=head1 VERSION

version 0.042

=head1 SYNOPSIS

use Games::Go::AGA::Parse::Exceptions

=head1 DESCRIPTION

Defines an exception class for Games::Go::AGA::Parse modules.

The class stringifies to the normal error message.  If a file is
associated with the exception, the file name and the current line
number are also included in the stringified message.

Fields defined for this exception class are:

    filename         # if we know the filename
    handle           # if we have the file handle
    line_number      # if we know the line_number in the file
    source           # source string that caused error

The fields are optional, but they help to make the error message more
informative.  If the B<Games::Go::AGA::Parsers> are created with
B<filename> and/or B<handle> options (or if they are set with accessor
methods after B<new>), any exceptions thrown by the parser will include
the 'filename' and/or 'handle' fields set appropriately.

Throw a parser exception like this:

    Games::Go::AGA::Parse::Exception->throw(
        error       => 'What the heck just happened?',
        source      => 'line that caused the error',
        filename    => 'name of file, if known',
        handle      => 'file handle, if known',
        line_number => $current_line_number,
    );

Only B<error> is strictly required.  If B<handle> is set, the exception
will attempt to determine the line number by calling
$handle->input_line_number.  Otherwise the line_number field is used (if
set).

=head1 NAME

Games::Go::AGA::Parse::Exceptions

=head1 SEE ALSO

=over

=item Exception::Class

=back

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
