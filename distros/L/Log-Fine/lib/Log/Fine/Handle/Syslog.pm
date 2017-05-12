
=head1 NAME

Log::Fine::Handle::Syslog - Output log messages to syslog

=head1 SYNOPSIS

Provides logging to syslog()

    use Log::Fine;
    use Log::Fine::Handle::Syslog;
    use Sys::Syslog;

    # Get a new logger
    my $log = Log::Fine->logger("foo");

    # Create a new syslog handle
    my $handle = Log::Fine::Handle::Syslog
        ->new( name  => 'syslog0',
               mask  => LOGMASK_EMERG | LOGMASK_ALERT | LOGMASK_CRIT | LOGMASK_ERR | LOGMASK_WARNING | LOGMASK_NOTICE | LOGMASK_INFO,
               ident => $0,
               logopts => 'pid',
               facility => LOG_LEVEL0 );

    # Register the handle
    $log->registerHandle($handle);

    # Log something
    $log->(INFO, "Opened new log handle");

=head1 DESCRIPTION

Log::Fine::Handle::Syslog provides logging via the standard UNIX
syslog facility.  For more information, it is I<highly> recommended
that you read the L<Sys::Syslog> documentation.

=cut

use strict;
use warnings;

package Log::Fine::Handle::Syslog;

use base qw( Log::Fine::Handle );

use File::Basename;
use Log::Fine;
use Sys::Syslog 0.13 qw( :standard :macros );

our $VERSION = $Log::Fine::Handle::VERSION;

# Constant: LOG_MAPPING
#
# Maps Log::Fine LOG_LEVELS to Sys::Syslog equivalents

use constant LOG_MAPPING => {
                              0 => LOG_EMERG,
                              1 => LOG_ALERT,
                              2 => LOG_CRIT,
                              3 => LOG_ERR,
                              4 => LOG_WARNING,
                              5 => LOG_NOTICE,
                              6 => LOG_INFO,
                              7 => LOG_DEBUG,
};

# Private Methods
# --------------------------------------------------------------------

{
        my $flag = 0;

        # Getter/Setter for flag
        sub _flag
        {
                $flag = 1 if (defined $_[0] and $_[0] =~ /\d/ and $_[0] > 0);
                return $flag;
        }
}

# --------------------------------------------------------------------

=head1 METHODS

=head2 msgWrite

See L<Log::Fine::Handle/msgWrite>

Note that this method B<does not> make use of a formatter as this is
handled by the syslog facility.

=cut

sub msgWrite
{

        my $self = shift;
        my $lvl  = shift;
        my $msg  = shift;
        my $skip = shift;               # NOT USED
        my $map  = LOG_MAPPING;

        # Write to syslog
        syslog($map->{$lvl}, $msg);

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

        # Make sure we have one and only one syslog object defined
        $self->_fatal(sprintf("One and _only_ one %s object may be defined", ref $self))
            if _flag();

        # Set ident
        $self->{ident} = basename $0;

        # Set the default logopts (to be passed to Sys::Syslog::openlog()
        $self->{logopts} = "pid"
            unless (defined $self->{logopts} and $self->{logopts} =~ /\w+/);

        # Set the default facility
        $self->{facility} = LOG_LOCAL0
            unless (defined $self->{facility}
                    and $self->{facility} =~ /\w+/);

        # Open the syslog connection and set flag
        openlog($self->{ident}, $self->{logopts}, $self->{facility});
        _flag(1);

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

L<perl>, L<syslog>, L<Sys::Syslog>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2008, 2010, 2013 Christopher M. Fuhrman, 
All rights reserved.

This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;          # End of Log::Fine::Handle::Syslog
