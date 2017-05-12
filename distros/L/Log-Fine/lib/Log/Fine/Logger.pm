
=head1 NAME

Log::Fine::Logger - Main logging object

=head1 SYNOPSIS

Provides an object through which to log.

    use Log::Fine;
    use Log::Fine::Logger;

    # Get a new logging object
    my $log = Log::Fine->logger("mylogger");

    # Alternatively, specify a custom map
    my $log = Log::Fine->logger("mylogger", "Syslog");

    # Register a handle
    $log->registerHandle( Log::Fine::Handle::Console->new() );

    # Log a message
    $log->log(DEBG, "This is a really cool module!");

    # Illustrate use of the log skip API
    package Some::Package::That::Overrides::Log::Fine::Logger;

    use base qw( Log::Fine::Logger );

    sub log
    {
        my $self = shift;
        my $lvl  = shift;
        my $msg  = shift;

        # Do some custom stuff to message

        # Make sure the formatter logs the correct calling method.
        $self->incrSkip();
        $self->SUPER::log($lvl, $msg);
        $self->decrSkip();

    } # log()

=head1 DESCRIPTION

The Logger class is the main workhorse of the Log::Fine framework,
providing the main L</log> method from which to log.  In addition,
the Logger class provides means by which the developer can control the
parameter passed to any caller() call so information regarding the
correct stack frame is displayed.

=cut

use strict;
use warnings;

package Log::Fine::Logger;

use base qw( Log::Fine );

use Log::Fine;

our $VERSION = $Log::Fine::VERSION;

# Constant: LOG_SKIP_DEFAULT
#
# By default, calls to caller() will be given a stack frame of 2.

use constant LOG_SKIP_DEFAULT => 2;

# --------------------------------------------------------------------

=head2 decrSkip

Decrements the value of the skip attribute by one

=head3 Returns

The newly decremented value

=cut

sub decrSkip { return --$_[0]->{_skip}; }          # decrSkip()

=head2 incrSkip

Increments the value of the skip attribute by one

=head3 Returns

The newly incremented value

=cut

sub incrSkip { return ++$_[0]->{_skip}; }          # incrSkip()

=head2 log

Logs the message at the given log level

=head3 Parameters

=over

=item  * level

Level at which to log

=item  * message

Message to log

=back

=head3 Returns

The object

=cut

sub log
{

        my $self = shift;
        my $lvl  = shift;
        my $msg  = shift;

        # See if we have any handles defined
        $self->_fatal("No handles defined!")
            unless (    defined $self->{_handles}
                    and ref $self->{_handles} eq "ARRAY"
                    and scalar @{ $self->{_handles} } > 0);

        # Iterate through each handle, logging as appropriate
        foreach my $handle (@{ $self->{_handles} }) {
                $handle->msgWrite($lvl, $msg, $self->{_skip})
                    if $handle->isLoggable($lvl);
        }

        return $self;

}          # log()

=head2 registerHandle

Register one or more L<Log::Fine::Handle> objects with the logging
facility.

=head3 Parameters

=over

=item  * handle

Can either be a valid Log::Fine::Handle object or an array ref
containing one or more Log::Fine::Handle objects

=back

=head3 Returns

The object

=cut

sub registerHandle
{

        my $self = shift;
        my $obj  = shift;

        # Initialize handles if we haven't already
        $self->{_handles} = []
            unless (defined $self->{_handles}
                    and ref $self->{_handles} eq "ARRAY");

        if (     defined $obj
             and ref $obj
             and UNIVERSAL::can($obj, 'isa')
             and $obj->isa('Log::Fine::Handle')) {
                push @{ $self->{_handles} }, $obj;
        } elsif (defined $obj and ref $obj eq 'ARRAY' and scalar @{$obj} > 0) {

                foreach my $handle (@{$obj}) {
                        $self->_fatal("Array ref must contain valid " . "Log::Fine::Handle objects")
                            unless (    defined $handle
                                    and ref $handle
                                    and UNIVERSAL::can($handle, 'isa')
                                    and $handle->isa('Log::Fine::Handle'));
                }

                push @{ $self->{_handles} }, @{$obj};

        } else {
                $self->_fatal(  "first argument must either be a "
                              . "valid Log::Fine::Handle object\n"
                              . "or an array ref containing one or more "
                              . "valid Log::Fine::Handle objects\n");
        }

        return $self;

}          # registerHandle()

=head2 skip

Getter/Setter for the objects skip attribute

See L<perlfunc/caller> for details

=head3 Returns

The objects skip attribute

=cut

sub skip
{

        my $self = shift;
        my $val  = shift;

        # Should we be given a value, then set skip
        $self->{_skip} = $val
            if (defined $val and $val =~ /^\d+$/);

        return $self->{_skip};

}          # skip()

# --------------------------------------------------------------------

##
# Initializes our object

sub _init
{

        my $self = shift;

        # Validate name
        $self->_fatal("Loggers need names!")
            unless (defined $self->{name} and $self->{name} =~ /^\w+$/);

        # Set logskip if necessary
        $self->{_skip} = LOG_SKIP_DEFAULT
            unless ($self->{_skip} and $self->{_skip} =~ /\d+/);

        return $self;

}          # _init()

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
All rights reserved

This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;          # End of Log::Fine::Logger
