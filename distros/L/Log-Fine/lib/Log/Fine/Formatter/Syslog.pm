
=head1 NAME

Log::Fine::Formatter::Syslog - Formatter for Syslog formatting

=head1 SYNOPSIS

Formats messages in a style similar to syslog(1)

    use Log::Fine::Formatter::Syslog;
    use Log::Fine::Handle::Console;

    # Instantiate a handle
    my $handle = Log::Fine::Handle::Console->new();

    # Instantiate a formatter
    my $formatter = Log::Fine::Formatter::Syslog
        ->new( name => 'syslog0');

    # Set the formatter
    $handle->formatter( formatter => $formatter );

    # Format a msg
    my $str = $formatter->format(INFO, "Resistence is futile", 1);

=head1 DESCRIPTION

The syslog formatter logs messages in a format similar to that
produced by syslog(1).

    <Mon> <Day> <HH:MM:SS> <Hostname> <ProcessName>[<ProcessID>]: <Message>

=cut

use strict;
use warnings;

package Log::Fine::Formatter::Syslog;

use base qw( Log::Fine::Formatter );

use File::Basename;
use Log::Fine;
use Log::Fine::Formatter;

#use Log::Fine::Levels;
use Log::Fine::Logger;
use POSIX qw( strftime );
use Sys::Hostname;

our $VERSION = $Log::Fine::Formatter::VERSION;

# Constant: LOG_TIMESTAMP_FORMAT
#
# strftime(3)-compatible format string
use constant LOG_TIMESTAMP_FORMAT => ($^O eq "MSWin32")
    ? "%b %d %H:%M:%S"
    : "%b %e %T";

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

    <Mon> <Day> <HH:MM:SS> <Hostname> <ProcessName>[<ProcessID>]: <Message>>

=cut

sub format
{

        my $self = shift;
        my $lvl  = shift;
        my $msg  = shift;
        my $skip = (defined $_[0]) ? shift : Log::Fine::Logger->LOG_SKIP_DEFAULT;

        my $host = (split(/\./, hostname))[0];

        return sprintf("%s %s %s[%d]: %s\n", $self->_formatTime(), $host, basename($0), $$, $msg);

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

1;          # End of Log::Fine::Formatter::Syslog
