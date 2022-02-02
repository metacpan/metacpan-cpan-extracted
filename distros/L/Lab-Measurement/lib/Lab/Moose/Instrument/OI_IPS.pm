package Lab::Moose::Instrument::OI_IPS;
$Lab::Moose::Instrument::OI_IPS::VERSION = '3.803';
#ABSTRACT: Oxford Instruments IPS Intelligent Power Supply

use v5.20;

use Moose;
use Moose::Util::TypeConstraints qw/enum/;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    validated_getter validated_setter validated_no_param_setter setter_params /;
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Countdown 'countdown';
use Carp;
use namespace::autoclean;

extends 'Lab::Moose::Instrument';

# Ideally, max_fields and max_field_rates should be preconfigured in a
# subclass, with values specific for the magnet used at the setup

has max_fields =>
    ( is => 'ro', isa => 'ArrayRef[Lab::Moose::PosNum]', required => 1 );
has max_field_rates =>
    ( is => 'ro', isa => 'ArrayRef[Lab::Moose::PosNum]', required => 1 );

has verbose => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1
);

sub BUILD {
    my $self = shift;

    warn "The IPS driver is work in progress. You have been warned\n";

    # Unlike modern GPIB equipment, this device does not assert the EOI
    # at end of message. The controller shell stop reading when receiving the
    # eos byte.

    $self->connection->set_termchar( termchar => "\r" );
    $self->connection->enable_read_termchar();
    $self->clear();

    # Use extended resolution mode (setpoint 10 μT, rate 100 μT/min)
    $self->set_communications_protocol( value => 4 );

    $self->set_control( value => 3 );

    $self->_check_field_rates();
}

sub _check_field_rates {
    my $self            = shift;
    my @max_fields      = @{ $self->max_fields };
    my @max_field_rates = @{ $self->max_field_rates };
    if ( @max_fields < 1 ) {
        croak "Need at least one element in max_fields array";
    }
    if ( @max_fields != @max_field_rates ) {
        croak "Need as many values in max_fields as in max_field_rates";
    }

    for my $i ( 1 .. $#max_fields ) {
        if ( $max_fields[$i] <= $max_fields[ $i - 1 ] ) {
            croak "values in max_fields must be in increasing order";
        }
        if ( $max_field_rates[$i] > $max_field_rates[ $i - 1 ] ) {
            croak "values in max_field_rates must decrease";
        }
    }
}

sub _check_sweep_parameters {
    my ( $self, %args ) = validated_hash(
        \@_,
        current => { isa => 'Num' },
        target  => { isa => 'Num' },
        rate    => { isa => 'Num' },
    );

    my $current = abs( delete $args{current} );
    my $target  = abs( delete $args{target} );
    my $rate    = abs( delete $args{rate} );

    my $max_field = ( $current > $target ) ? $current : $target;

    my @max_fields            = @{ $self->max_fields };
    my @max_field_rates       = @{ $self->max_field_rates };
    my $maximum_allowed_field = $max_fields[-1];

    my $i = 0;
    while (1) {
        if ( $max_field <= $max_fields[$i] ) {
            last;
        }
        if ( $max_field > $maximum_allowed_field ) {
            croak
                "target field $max_field exceeds absolute maximum field $maximum_allowed_field";
        }
        ++$i;

    }
    my $max_rate = $max_field_rates[$i];
    if ( $rate > $max_rate ) {
        croak "Rate $rate exceeds maximum allowed rate $max_rate";
    }
}


# query wrapper with error checking
around query => sub {
    my $orig = shift;
    my $self = shift;
    my %args = @_;

    my $result = $self->$orig(@_);
    my $cmd    = $args{command};

    # remove trailing "\n" and "\r"
    $result =~ s/\s*$//;
    $cmd =~ s/\s*$//;

    my $cmd_char = substr( $cmd, 0, 1 );

    # IPS query answers always start with the command character
    # if successful.
    # With a question mark and the command char on failure
    my $status = substr( $result, 0, 1 );
    if ( $status eq '?' ) {
        croak "IPS returned error '$result' on command '$cmd'";
    }
    elsif ( defined $cmd_char and ( $status ne $cmd_char ) ) {
        croak "IPS returned unexpected answer. Expected '$cmd_char' prefix,
received '$status' on command '$cmd'";
    }
    return substr( $result, 1 );
};


sub sweep_to_field {
    my ( $self, %args ) = validated_getter(
        \@_,
        target => { isa => 'Num' },
        rate   => { isa => 'Num' },
    );

    my $point = delete $args{target};
    my $rate  = delete $args{rate};

    $self->config_sweep( point => $point, rate => $rate, %args );

    $self->trg(%args);

    $self->wait(%args);
    return $self->get_field(%args);
}


sub config_sweep {
    my ( $self, %args ) = validated_hash(
        \@_,
        point => { isa => 'Num' },
        rate  => { isa => 'Num' },
    );
    my $target = delete $args{point};
    my $rate   = delete $args{rate};

    $self->set_field_sweep_rate( value => $rate, %args );
    $self->set_target_field( value => $target, %args );

    my $current_field = $self->get_field();
    $self->_check_sweep_parameters(
        current => $current_field, target => $target,
        rate    => $rate
    );
    if ( $self->verbose() ) {
        say "config_sweep: target: $target (T), rate: $rate (T/min)";
    }
}


sub set_control {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/0 1 2 3/] ) },
    );
    my $result = $self->query( command => "C$value\r", %args );
    sleep(1);
    return $result;
}


sub set_communications_protocol {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/0 2 4 6/] ) }
    );

    # This command does not produce an echo -> use write, not query.
    $self->write( command => "Q$value\r" );
}


sub examine_status {
    my ( $self, %args ) = validated_getter( \@_ );
    return "X" . $self->query( command => "X\r", %args );
}


sub active {
    my ( $self, %args ) = validated_getter( \@_ );
    my $status = $self->examine_status(@_);
    return substr( $status, 11, 1 );
}


sub in_persistent_mode {
    my ( $self, %args ) = validated_getter( \@_ );
    my $status = $self->examine_status(@_);
    my $n = substr( $status, 8, 1 );
    if ( $n == 0 || $n == 2 ) {

        # heater off
        return 1;
    }
    elsif ( $n == 1 ) {
        return;
    }
    else {
        croak "bad heater status $n";
    }
}

sub set_persistent_mode {
    my ( $self, %args ) = validated_setter(
        \@_,
        mode => { isa => 'Int' }
    );

    my $mode = delete $args{mode};

    # return 0 if not $self->{device_settings}->{has_switchheater};

    my $switch = $self->get_switch_heater();

    #print "We are in mode $current_mode \n";

    if ( $mode == 1 ) {

        $self->hold();
        $self->set_switch_heater( value => 0 );

        $self->to_zero();

        #$current_mode = 1;

    }
    elsif ( $mode == 0 and $switch == 2 ) {

        my $setpoint = $self->get_persistent_field();

        $self->set_target_field( value => $setpoint );

        $self->to_setpoint();

        #print "Try to start switchheater...\n";
        $self->set_switchheater( value => 1 );

        #print "Switchheater has status ".$self->get_switchheater();

    }
    elsif ( $mode == 0 and $switch == 0 ) {
        print "Zero magnetic field. Switch on switchheater.\n";
        $self->set_switchheater( value => 1 );

    }

}

sub get_persistent_field {
    my ( $self, %args ) = validated_getter( \@_ );

    # Are we really in persistent mode?

    return $self->read_parameter( value => 18 );

}


sub wait {
    my ( $self, %args ) = validated_getter( \@_ );
    my $verbose = $self->verbose();

    # enable autoflush
    my $autoflush = STDOUT->autoflush();

    while (1) {
        sleep 1;
        my $field = $self->get_field(%args);
        printf( "Field: %.6f T        \r", $field );
        if ( not $self->active ) {
            last;
        }
    }
    if ($verbose) {
        print " " x 70 . "\r";
    }

    # reset autoflush to previous value
    STDOUT->autoflush($autoflush);
}


sub read_parameter {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [ ( 0 .. 24 ) ] ) },
    );
    my $result = $self->query( command => "R$value\r", %args );

    # device bug: sometimes the value is returned with a leading 'R'
    $result =~ s/^R//;
    return sprintf( "%e", $result );
}


sub get_field {
    my $self = shift;
    return $self->read_parameter( value => 7, @_ );
}


sub get_value {
    my $self = shift;
    return $self->get_field(@_);
}

sub get_field_rate {
    my $self = shift;
    return $self->read_parameter( value => 9, @_ );
}

sub set_activity {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [ 0, 1, 2, 4 ] ) },
    );

    return $self->query( command => "A$value\r", %args );
}

sub hold {
    my $self = shift;
    return $self->set_activity( value => 0, @_ );
}

sub to_setpoint {
    my $self = shift;
    return $self->set_activity( value => 1, @_ );
}

sub trg {
    my $self = shift;
    return $self->to_setpoint(@_);
}

sub to_zero {
    my $self = shift;
    return $self->set_activity( value => 2, @_ );
}

sub set_front_panel_display_parameter {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [ ( 0 .. 24 ) ] ) },
    );
    return $self->query( command => "F$value\r", %args );
}


sub set_switch_heater {
    my ( $self, $value, %args ) = validated_setter(
        \@_,

        # Do not implement "2" (without check)
        value => { isa => enum( [ 0, 1 ] ) },
    );
    return $self->query( command => "H$value\r", %args );
}


sub get_switch_heater {
    my ( $self, %args ) = validated_getter( \@_ );
    my $status = $self->examine_status(@_);
    return substr( $status, 8, 1 );
}

sub set_target_field {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' },
    );
    $value = sprintf( "%.5f", $value );
    return $self->query( command => "J$value\r", %args );
}

sub get_target_field {
    my $self = shift;
    return $self->read_parameter( value => 8, @_ );
}

sub set_mode {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [ 0, 1, 4, 5, 8, 9 ] ) }
    );
    return $self->query( command => "M$value\r", %args );
}

sub set_field_sweep_rate {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Lab::Moose::PosNum' },
    );
    $value = sprintf( "%.4f", $value );
    return $self->query( command => "T$value\r" );
}


__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::OI_IPS - Oxford Instruments IPS Intelligent Power Supply

=head1 VERSION

version 3.803

=head1 SYNOPSIS

 use Lab::Moose;

 # Constructor
 my $ips = instrument(
     type => 'OI_IPS',
     connection_type => 'LinuxGPIB',
     connection_options => {pad => 10},

     # safety limits, should be fixed in a subclass of this driver
     max_fields => [7, 10],          # absolute maximum field of 10T
     max_field_rates => [0.1, 0.05], # 0.1 T/min maximum rate in range 0T..7T
                                     # 0.05 T/min maximum rate in range 7T..10T
 );


 # Get field
 my $field = $ips->get_field();

 # Sweep to 1T with rate 0.1T/min

 $ips->sweep_to_field(target => 1, rate => 0.1);

=head1 METHODS

=head1 sweep_to_field

 my $new_field = $ips->sweep_to_field(
    target => $target_field, # Tesla
    rate => $rate, # Tesla/min
 );

=head1 config_sweep

 $ips->config_sweep(point => $target, rate => $rate);

Only define setpoints, do not start sweep.

=head2 set_control

 $ips->set_control(value => 1);

Set device local/remote mode (0, 1, 2, 3)

=head2 set_communications_protocol

 $ips->set_communications_protocol(value => 0);

Allowed values: C<0, 2, 4, 6>.

This driver sets the protocol to C<4> "Extended Resolution" on startup.

=head2 examine_status

 my $status = $ips->examine_status();

Return status (XmnAnCnHnMmnPmn).

=head2 active

 my $status = $ips->active();

Return true value if IPS is sweeping. Return false when sweep finished.

=head2 in_persistent_mode

 if ($ips->in_persistent_mode()) {
    ...
 }

Return 1 if in persistent mode; otherwise return false.

=head2 wait

 $ips->wait();

Wait until current sweep is finished. Print status messages if C<verbose> attribute was set in constructor (default).

=head2 read_parameter

 my $value = $ips->read_parameter(value => 1);

Allowed values for C<value> are 0..13

=head2 get_field

 my $field = $ips->get_field();

Return current field (Tesla).

=head2 get_value

Alias for L</get_field>

=head2 set_switch_heater

 $ips->set_switch_heater(value => 0); # Heater off
 $ips->set_switch_heater(value => 1); # Heater on (only done if magnet current equals power supply current)

=head2 get_switch_heater

 my $switch = $ips->get_switch_heater();

Return values:

=over

=item 0: Off Magnet at Zero (switch closed)

=item 1: On (switch open)

=item 2: Off Magnet at Field (switch closed)

=item 5: Heater Fault (heater is on but current is low)

=item 8: No Switch Fitted

=back

=head2 Consumed Roles

This driver consumes the following roles:

=over

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by the Lab::Measurement team; in detail:

  Copyright 2019       Simon Reinhardt
            2020       Andreas K. Huettel, Simon Reinhardt
            2021       Andreas K. Huettel, Fabian Weinelt, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
