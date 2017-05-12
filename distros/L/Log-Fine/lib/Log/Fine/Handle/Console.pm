
=head1 NAME

Log::Fine::Handle::Console - Output messages to C<STDERR> or C<STDOUT>

=head1 SYNOPSIS

Provides logging to either C<STDERR> or C<STDOUT>.

    # Get a new logger
    my $log = Log::Fine->logger("foo");

    # Register a file handle
    my $handle = Log::Fine::Handle::Console
        ->new( name => 'myname',
               mask => LOGMASK_EMERG | LOGMASK_ALERT | LOGMASK_CRIT | LOGMASK_ERR | LOGMASK_WARNING | LOGMASK_NOTICE | LOGMASK_INFO,
               use_stderr => undef );

    # You can set logging to STDERR per preference
    $handle->{use_stderr} = 1;

    # Register the handle
    $log->registerHandle($handle);

    # Log something
    $log->(INFO, "Opened new log handle");

=head1 DESCRIPTION

The console handle provides logging to the console, either via
C<STDOUT> (default) or C<STDERR>.

=cut

use strict;
use warnings;

package Log::Fine::Handle::Console;

use base qw( Log::Fine::Handle );

use Log::Fine;

our $VERSION = $Log::Fine::Handle::VERSION;

=head1 METHODS

=head2 msgWrite

See L<Log::Fine::Handle/msgWrite>

=cut

sub msgWrite
{

        my $self = shift;
        my $lvl  = shift;
        my $msg  = shift;
        my $skip = shift;

        # Should we have a formatter defined, then use that,
        # otherwise, just print the raw message
        $msg = $self->{formatter}->format($lvl, $msg, $skip)
            if defined $self->{formatter};

        # Where do we send the message to?
        if (defined $self->{use_stderr}) {
                print STDERR $msg;
        } else {
                print STDOUT $msg;
        }

        return $self;

}          # msgWrite()

# --------------------------------------------------------------------

##
# Initializes our object

sub _init
{

        my $self = shift;

        # Perform any necessary upper class initializations
        $self->SUPER::_init();

        # By default, we print messages to STDOUT
        $self->{use_stderr} = undef
            unless (exists $self->{use_stderr});

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

L<perl>, L<Log::Fine::Handle>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2008, 2010, 2013 Christopher M. Fuhrman, 
All rights reserved.

This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;          # End of Log::Fine::Handle::Console
