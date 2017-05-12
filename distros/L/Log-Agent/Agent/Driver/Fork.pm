###########################################################################
#
#   Fork.pm
#
#   Copyright (C) 1999 Raphael Manfredi.
#   Copyright (C) 2002-2015 Mark Rogaski, mrogaski@cpan.org;
#   all rights reserved.
#
#   See the README file included with the
#   distribution for license information.
#
##########################################################################

package Log::Agent::Driver::Fork;

use strict;
require Log::Agent::Driver;

use vars qw(@ISA);
@ISA = qw(Log::Agent::Driver);

###########################################################################
#
# Public Methods
#
###########################################################################

#
# make
#
# constructor method
#
sub make {
    my $class = shift;

    # initialize the dispatcher
    my $self = {
        drivers => []
    };
    bless $self, $class;
    $self->_init('', 0);

    # test for 5.6
    $^W = 0;
    my $new_perl = eval "$^V and $^V ge v5.6.0" || 0;
    $^W = 1;

    # process the arguments
    foreach my $arg (@_) {
        if (ref $arg) {
            # add to the list of drivers
            push(@{$self->{drivers}}, $arg);
        } else {
            require Carp;
            Carp::croak("argument is not an object reference: $arg");
        }
    }

    return $self;
}

#
# prefix_msg
#
# does little of value
#
sub prefix_msg {
    return $_[1];
}

#
# write
#
# pass-through to drivers
#
sub write {
    my($self, $channel, $priority, $str) = @_;
    foreach my $driver (@{$self->{drivers}}) {
        $driver->write($channel, $priority, $str);
    }
}

#
# emit
#
# wrapper for write() that uses dynamically bound priority() and prefix_msg()
# methods
#
sub emit {
    my($self, $channel, $priority, $str) = @_;
    foreach my $driver (@{$self->{drivers}}) {
        $driver->emit($channel, $priority, $str);

        # This is a kludge to make duperr work in file driver,
        # the encapsulation purists should lynch me for this.
        if ($driver->isa('Log::Agent::Driver::File')) {
            if ($driver->duperr) {
                if ($priority eq 'critical') {
                    $driver->emit_output('critical', 'FATAL', $str);
                } elsif ($priority eq 'error') {
                    $driver->emit_output('error', 'ERROR', $str);
                } elsif ($priority eq 'warning') {
                    $driver->emit_output('warning', 'WARNING', $str);
                }
            }
        }

    }
}

#
# emit_carp
#
# A specialized wrapper to hand-off carp/croak messages at a
# specified offset.
#
sub emit_carp {
    my($self, $channel, $priority, $offset, $str) = @_;

    # yet another kludge
    $offset++ if (caller(3))[3] =~ /^main::/;

    foreach my $driver (@{$self->{drivers}}) {
        # construct the message
        require Carp;
        my $msg = $driver->carpmess($offset, $str, \&Carp::shortmess);
        # send it to the driver
        $driver->emit($channel, $priority, $str);
    }
}

#
# channel_eq
#
# exhaustive equality comparison
#
sub channel_eq {
    my $self = shift;
    foreach my $driver (@{$self->{drivers}}) {
        $driver->channel_eq(@_) || return;
    }
    return 1;
}

#
# logconfess
#
# Fatal error, with stack trace
#
sub logconfess {
    my($self, $str) = @_;

    # log error to all drivers
    $self->emit_carp('error', 'critical', 0, $str);

    die;
}

#
# logcroak
#
# Fatal error
#
sub logcroak {
    my($self, $str) = @_;

    #
    # log error to all drivers
    #
    $self->emit_carp('error', 'critical', 0, $str);

    die;
}

#
# logxcroak
#
# Fatal error, from perspective of caller
#
sub logxcroak {
    my($self, $offset, $str) = @_;

    #
    # log error to all drivers
    #
    $self->emit_carp('error', 'critical', $offset, $str);

    die;
}

#
# logdie
#
# Fatal error
#
sub logdie {
    my ($self, $str) = @_;

    #
    # log error to all drivers
    #
    $self->emit('error', 'critical', $str);
    die;
}

#
# logerr
#
# Signal error on stderr
#
sub logerr {
    my ($self, $str) = @_;

    #
    # log error to all drivers
    #
    $self->emit('error', 'error', $str);
}

#
# logwarn
#
# Warn, with "WARNING" clearly emphasized
#
sub logwarn {
    my ($self, $str) = @_;

    #
    # log error to all drivers
    #
    $self->emit('error', 'warning', $str);
}

#
# logcarp
#
# log a warning, carp-style
#
sub logcarp {
    my($self, $str) = @_;

    #
    # log message to all drivers
    #
    $self->emit_carp('error', 'warning', 0, $str);
}

#
# logxcarp
#
# Warn from perspective of caller
#
sub logxcarp {
    my($self, $offset, $str) = @_;

    #
    # log message to all drivers
    #
    $self->emit_carp('error', 'warning', $offset, $str);
}

#
# logsay
#
# Log message to "output" channel at "notice" priority
#
sub logsay {
    my($self, $str) = @_;

    #
    # send message to drivers
    #
    $self->emit('output', 'notice', $str);
}

1;  # for require
__END__

=head1 NAME

Log::Agent::Driver::Fork - dummy driver for forking output to multiple drivers

=head1 SYNOPSIS

 use Log::Agent;
 require Log::Agent::Driver::Fork;
 require Log::Agent::Driver::Foo;
 require Log::Agent::Driver::Bar;

 my $driver = Log::Agent::Driver::Fork->make(
     Log::Agent::Driver::Foo->make( ... ),
     Log::Agent::Driver::Bar->make( ... )
 );
 logconfig(-driver => $driver);

=head1 DESCRIPTION

This driver merely acts a multiplexer for logxxx() calls, duplicating
them and distributing them to other drivers.

The only routine of interest here is the creation routine:

=over 4

=item make(@drivers)

Create a Log::Agent::Driver::Fork driver that duplicates logxxx() calls and
distributes them to the drivers in @drivers.  The arguments must be the return
value of the make() call for the client drivers.

=back

=head1 NOTES

Many thanks go to Daniel Lundin and Jason May who proposed this module
independently.  Eventually, logconfig() will support multiple drivers
directly. But, for now, this solution requires no change to the existing
interface.

=head1 AUTHOR

Mark Rogaski E<lt>mrogaski@pobox.comE<gt>

=head1 LICENSE

Copyright (C) 2002 Mark Rogaski; all rights reserved.

See L<Log::Agent(3)> or the README file included with the distribution for
license information.

=head1 SEE ALSO

L<Log::Agent::Driver(3)>, L<Log::Agent(3)>.

=cut
