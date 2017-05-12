###########################################
package Device::MAS345;
###########################################
use strict;
use warnings;
use Device::SerialPort;
use Log::Log4perl qw(:easy);

our $VERSION = "0.03";

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        port     => "/dev/ttyS0",
        baudrate => 600,
        bytes    => 14,
        pause    => 1,
        databits => 7,
        %options,
    };

    bless $self, $class;
    $self->reset();

    return $self;
}

###########################################
sub error {
###########################################
    my($self, $err) = @_;

    $self->{error} = $err if defined $err;
    return $self->{error};
}

###########################################
sub read {
###########################################
    my($self) = @_;

    my $data;

    $data = $self->read_raw();

    my $valrx = qr/-?[\w.]+/;

    if($data =~ /(\w+)\s+($valrx)\s+(\w+)/) {
        return ($2, $3, $1);
    } elsif($data =~ /(\w+)\s+($valrx)(kOhm|MOhm)/) {   # for bunched lines
        return ($2, $3, $1);                            
    } elsif($data =~ /($valrx)/) {
        return ($1, "", "");
    }

    LOGDIE "Unrecognized response: $data";
}

###########################################
sub read_raw {
###########################################
    my($self) = @_;

    DEBUG "Purging";
    $self->{serial}->purge_all() || 
        LOGDIE "Purge failed ($!)";

    $self->{serial}->rts_active(0);
    $self->{serial}->dtr_active(1);

    DEBUG "Sending newline";
    $self->{serial}->write("\n") || 
        LOGDIE "Send of newline failed";

    DEBUG "Waiting $self->{pause} seconds";
    select(undef, undef, undef, $self->{pause});

    DEBUG "Reading response";
    my($count, $data) = $self->{serial}->read($self->{bytes});

    DEBUG "Received $count bytes";
    if($count != $self->{bytes}) {
        LOGDIE "Read $self->{bytes}, got only $count";
    }

    return $data;
}

###########################################
sub reset {
###########################################
    my($self) = @_;

    $self->{serial} = Device::SerialPort->new(
            $self->{port}, undef);

    $self->{serial}->baudrate($self->{baudrate}) or
        LOGDIE "Setting baudrate to $self->{baudrate} failed";

    $self->{serial}->databits($self->{databits}) or
        LOGDIE "Setting databits to $self->{databits} failed";

}

1;

__END__

=head1 NAME

Device::MAS345 - Reading the Mastech MAS-345 Multimeter

=head1 SYNOPSIS

  use Device::MAS345;

  my $mas = Device::MAS345->new( port => "/dev/ttyS0" );

  my($val, $unit, $mode) = $mas->read();

=head1 DESCRIPTION

C<Device::MAS345> reads data from a Mastech MAS-345 multimeter
connected to the computer's serial port.

This cheap (less than $50) multimeter measures voltage, current, 
temperature, resistance, capacity, and features a serial cable
to hook it up to a PC.

Using C<Device::MAS345>, you can connect to the multimeter and 
read out the currently displayed value, along with the selected
mode and a units character.

Reading data returns three values:

  my($val, $unit, $mode) = $mas->read();

C<$val> is the numeric value displayed on the multimeter (e.g. C<-0.015>),
C<$unit> holds the measurement unit (e.g. C<V>) and C<$mode> adds
an additional mode setting (e.g. C<DC>).

On error, C<Device::MAS345> throws exceptions. If you want to catch
them, use C<eval {}>. The cause for the error can be seen by calling
the object's C<error> message, which returns the string of the last
exception.

=head2 Debugging

C<Device::MAS345> is C<Log::Log4perl>-enabled. To turn on debugging,
just add

    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init($DEBUG);

at the start of your code.

=head2 Serial Ports

The constructor can be called without arguments. The optional
C<ports> parameter defaults to C</dev/ttyS0>, the first
serial port.

=head2 Gotchas

If you want to run this as a non-root user, make sure that

    ls -l /dev/ttyS0

(or whatever serial port the multimeter is connected to) is
read/writeable by the user.

The multimeter has to be turned on for the connection to succeed.

=head1 LEGALESE

Copyright 2007 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2007, Mike Schilli <cpan@perlmeister.com>
