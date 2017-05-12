
=head1 NAME

Log::Fine::Utils - Functional wrapper around Log::Fine

=head1 SYNOPSIS

Provides a functional wrapper around Log::Fine.

    use Log::Fine::Handle;
    use Log::Fine::Handle::File;
    use Log::Fine::Handle::Syslog;
    use Log::Fine::Levels::Syslog;
    use Log::Fine::Utils;
    use Sys::Syslog;

    # Set up some handles as you normally would.  First, a handler for
    # file logging:
    my $handle1 = Log::Fine::Handle::File
        ->new( name      => "file0",
               mask      => Log::Fine::Levels::Syslog->bitmaskAll(),
               formatter => Log::Fine::Formatter::Basic->new() );

    # And now a handle for syslog
    my $handle2 = Log::Fine::Handle::Syslog
        ->new( name      => "syslog0",
               mask      => LOGMASK_EMERG | LOGMASK_CRIT | LOGMASK_ERR,
               ident     => $0,
               logopts   => 'pid',
               facility  => LOG_LEVEL0 );

    # Open the logging subsystem with the default name "GENERIC"
    OpenLog( handles  => [ $handle1, [$handle2], ... ],
             levelmap => "Syslog" );

    # Open new logging object with name "aux".  Note this will switch
    # the current logger to "aux"
    OpenLog( name => "aux",
             handles  => [ $handle1, [[$handle2], [...] ]],
             levelmap => "Syslog" );

    # Grab a ref to active logger
    my $current_logger = CurrentLogger();

    # Get name of current logger
    my $loggername = $current_logger()->name();

    # Switch back to GENERIC logger
    OpenLog( name => "GENERIC" );

    # Grab a list of defined logger names
    my @names = ListLoggers();

    # Log a message
    Log( INFO, "The angels have my blue box" );

=head1 DESCRIPTION

The Utils class provides a functional wrapper for L<Log::Fine> and
friends, thus saving the developer the tedious task of mucking about
in object-oriented land.

=cut

use strict;
use warnings;

package Log::Fine::Utils;

our @ISA = qw( Exporter );

#use Data::Dumper;

use Log::Fine;
use Log::Fine::Levels;
use Log::Fine::Logger;

our $VERSION = $Log::Fine::VERSION;

# Exported functions
our @EXPORT = qw( CurrentLogger ListLoggers Log OpenLog );

# Private Functions
# --------------------------------------------------------------------

{

        my $logfine = undef;          # Log::Fine object
        my $logger  = undef;          # Ptr to current logger

        # Getter/Setter for Log::Fine object
        sub _logfine
        {
                $logfine = $_[0]
                    if (    defined $_[0]
                        and ref $_[0]
                        and UNIVERSAL::can($_[0], 'isa')
                        and $_[0]->isa('Log::Fine'));

                return $logfine;
        }

        # Getter/Setter for current logger
        sub _logger
        {
                $logger = $_[0]
                    if (    defined $_[0]
                        and ref $_[0]
                        and UNIVERSAL::can($_[0], 'isa')
                        and $_[0]->isa('Log::Fine::Logger'));

                return $logger;
        }

}

=head1 FUNCTIONS

The following functions are automatically exported by
Log::Fine::Utils:

=head2 CurrentLogger

Returns the currently "active" L<Log::Fine::Logger> object

=head3 Parameters

None

=head3 Returns

Currently active L<Log::Fine::Logger> object

=cut

sub CurrentLogger { return _logger(); }

=head2 ListLoggers

Provides list of currently defined loggers

=head3 Parameters

None

=head3 Returns

Array containing list of currently defined loggers or undef if no
loggers are defined

=cut

sub ListLoggers
{
        return (defined _logfine()) ? _logfine()->listLoggers() : ();
}

=head2 Log

Logs the message at the given log level

=head3 Parameters

=over

=item  * level

Level at which to log

=item  * message

Message to log

=back

=head3 Returns

1 on success

=cut

sub Log
{

        my $lvl = shift;
        my $msg = shift;
        my $log = _logger();

        # Validate logger has been set
        Log::Fine->_fatal("Logging system has not been set up " . "(See Log::Fine::Utils::OpenLog())")
            unless (    defined $log
                    and ref $log
                    and UNIVERSAL::can($log, 'isa')
                    and $log->isa("Log::Fine::Logger"));

        # Make sure we log the correct calling method
        $log->incrSkip();
        $log->log($lvl, $msg);
        $log->decrSkip();

        return 1;

}          # Log()

=head2 OpenLog

Opens the logging subsystem.  If called with the name of a previously
defined logger object, will switch to that logger, ignoring other
given hash elements.

=head3 Parameters

A hash containing the following keys:

=over

=item * handles

Either a single L<Log::Fine::Handle> object or an array ref containing
one or more L<Log::Fine::Handle> objects

=item * levelmap

B<[optional]> L<Log::Fine::Levels> subclass to use.  Will default to
"Syslog" if not defined.

=item * name

B<[optional]> Name of logger.  If name references an already
registered logger, then will switch to the named logger.  Should the
given name not exist, then will create a new logging object with that
name, provided handles are provided.  Should name not be passed, then
'GENERIC' will be used.  Note that you I<must> provide one or more
valid handles when creating a new object.

=item * no_croak

[default: 0] If true, Log::Fine will not croak under certain
circumstances (see L<Log::Fine>)

=back

=head3 Returns

1 on success

=cut

sub OpenLog
{

        my %data = @_;

        # Set name to a default value if need be
        $data{name} = "GENERIC"
            unless (defined $data{name} and $data{name} =~ /\w/);

        # Should no Log::Fine object be defined, generate one
        _logfine(
                 Log::Fine->new(name     => "Utils",
                                levelmap => $data{levelmap} || Log::Fine::Levels->DEFAULT_LEVELMAP,
                                no_croak => $data{no_croak} || 0
                 ))
            unless (    defined _logfine()
                    and ref _logfine()
                    and UNIVERSAL::can(_logfine(), 'isa')
                    and _logfine()->isa('Log::Fine'));

        # See if we have the given logger name
        if (     defined _logger
             and ref _logger()
             and UNIVERSAL::can(_logger(), 'isa')
             and _logger()->isa('Log::Fine::Logger')
             and defined _logger()->name()
             and _logger()->name() =~ /\w/
             and grep(/$data{name}/, ListLoggers())) {

                # Set the current logger to the given name
                _logger(_logfine()->logger($data{name}));

        } else {

                # Create logger, register handle(s), and store for
                # future use.
                my $logger = _logfine()->logger($data{name});

                # Note that registerHandle() will take care of handle
                # validation.
                $logger->registerHandle($data{handles});
                _logger($logger);

        }

        return 1;

}          # OpenLog()

=head1 BUGS

Please report any bugs or feature requests to
C<bug-log-fine at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Fine>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 CAVEATS

OpenLog() will croak regardless if C<{no_croak}> is set if the
following two conditions are met:

=over

=item * OpenLog() is passed the name of an unknown logger, thus
necessitating the creation of a new logger object

=item * No L<Log::Fine::Handle> objects were passed in the
C<{handles}> array

=back

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

L<perl>, L<Log::Fine>, L<Log::Fine::Handle>, L<Log::Fine::Logger>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2008, 2010-2011, 2013 Christopher M. Fuhrman, 
All rights reserved

This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;          # End of Log::Fine::Utils
