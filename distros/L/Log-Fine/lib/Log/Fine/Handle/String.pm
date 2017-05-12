
=head1 NAME

Log::Fine::Handle::String - formatted output

=head1 SYNOPSIS

Returns the formatted string for testing purposes.

    use Log::Fine;
    use Log::Fine::Handle::String;

    # Get a new logger
    my $log = Log::Fine->logger("foo");

    # register a file handle
    my $handle = Log::Fine::Handle::String->new();

    # get a formatted message
    my $formatted_message = $log->(INFO, "Opened new log handle");

=head1 DESCRIPTION

The string handle returns the formatted message.  This is useful for
general-purpose testing and verification.

=cut

use strict;
use warnings;

package Log::Fine::Handle::String;

use base qw( Log::Fine::Handle );

our $VERSION = $Log::Fine::Handle::VERSION;

=head1 METHODS

=head2 msgWrite

Returns the formatted message

B<Note:> msgWrite() is an I<internal> method to the Log::Fine
framework, meant to be sub-classed.  Use
L<Log::Fine::Logger/log> for actual logging.

=head3 Parameters

=over

=item  * level

Level at which to log

=item  * message

Message to log

=item  * skip

Passed to L<caller|perlfunc/caller> for accurate method logging

=back

=head3 Returns

The formatted message

=cut

sub msgWrite
{

        my $self = shift;
        my $lvl  = shift;
        my $msg  = shift;
        my $skip = shift;          # NOT USED

        # Validate formatter
        eval "require " . ref $self->{formatter};

        # Should we have a formatter defined, then use that,
        # otherwise, just print the raw message
        $msg = $self->{formatter}->format($lvl, $msg, $skip)
            if defined $self->{formatter};

        return $msg;

}          # msgWrite()

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

L<perl>, L<Log::Fine>, L<Log::Fine::Handle>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2008, 2010, 2013 Christopher M. Fuhrman, 
All rights reserved.

This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;          # End of Log::Fine::Handle::String
