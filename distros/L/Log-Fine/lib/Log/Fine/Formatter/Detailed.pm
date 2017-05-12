
=head1 NAME

Log::Fine::Formatter::Detailed - Formatter for detailed logging

=head1 SYNOPSIS

Formats log messages for output in a detailed format.

    use Log::Fine::Formatter::Detailed;
    use Log::Fine::Handle::Console;

    # Instantiate a handle
    my $handle = Log::Fine::Handle::Console->new();

    # Instantiate a formatter
    my $formatter = Log::Fine::Formatter::Detailed
        ->new( name             => 'detail0',
               timestamp_format => "%y-%m-%d %h:%m:%s" );

    # Set the formatter
    $handle->formatter( formatter => $formatter );

    # Format a msg
    my $str = $formatter->format(INFO, "Resistence is futile", 1);

=head1 DESCRIPTION

The detailed formatter logs messages in two different formats,
depending on where the log message came from.

If the log message came from a particular class (e.g. C<MyModule.pm>)
the detailed formatter will format as follows:

    [TIMESTAMP] <LEVEL> (<Package>::Method():<Line Number>) <MESSAGE>

Otherwise, the formatter will return a slightly more basic format:

    [TIMESTAMP] <LEVEL> (<Script Name>:<Line Number>) <MESSAGE>

=cut

use strict;
use warnings;

package Log::Fine::Formatter::Detailed;

use base qw( Log::Fine::Formatter );

use File::Basename;
use Log::Fine;
use Log::Fine::Formatter;
use Log::Fine::Levels;
use Log::Fine::Logger;

use POSIX qw( strftime );

our $VERSION = $Log::Fine::Formatter::VERSION;

=head1 METHODS

=head2 format

Formats the given message for the given level

=head3 Parameters

=over

=item  * level

Level at which to log (see L<Log::Fine::Levels>)

=item  * message

Message to log

=item  * skip

Controls caller skip level

=back

=head3 Returns

The formatted text string in the form:

  [TIMESTAMP] <LEVEL> (<Package>::Method():<Line Number>) <MESSAGE>

or

  [TIMESTAMP] <LEVEL> (<Script Name>:<Line Number>) <MESSAGE>

=cut

sub format
{

        my $self = shift;
        my $lvl  = shift;
        my $msg  = shift;
        my $skip = (defined $_[0]) ? shift : Log::Fine::Logger->LOG_SKIP_DEFAULT;

        # Variable(s)
        my $str;
        my @c = caller($skip);

        # Formatted string returned depends on outcome of caller()
        if (scalar @c == 0) {
                $str = sprintf("[%s] %-4s (%s) %s\n",
                               $self->_formatTime(), $self->levelMap()->valueToLevel($lvl),
                               basename($0), $msg);
        } elsif (defined $c[0] and $c[0] eq "main") {
                $str = sprintf("[%s] %-4s (%s:%d) %s\n",
                               $self->_formatTime(), $self->levelMap()->valueToLevel($lvl),
                               basename($c[1]), $c[2], $msg);
        } else {
                $str = sprintf("[%s] %-4s (%s():%d) %s\n",
                               $self->_formatTime(),
                               $self->levelMap()->valueToLevel($lvl),
                               (caller($skip + 1))[3] || "{undef}",
                               $c[2] || 0, $msg);
        }

        return $str;

}          # format()

=head1 BUGS

Please report any bugs or feature requests to
C<bug-log-fine at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Fine>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::Fine

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-Fine>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Log-Fine>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Fine>

=item * Search CPAN

L<http://search.cpan.org/dist/Log-Fine>

=back

=head1 AUTHOR

Christopher M. Fuhrman, C<< <cfuhrman at pobox.com> >>

=head1 SEE ALSO

L<perl>, L<Log::Fine::Formatter>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2008-2010, 2013 Christopher M. Fuhrman, 
All rights reserved.

This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;          # End of Log::Fine::Formatter::Detailed
