package Lab::Moose::Instrument::Bluefors_Temp;
$Lab::Moose::Instrument::Bluefors_Temp::VERSION = '3.904';
#ABSTRACT: Bluefors temperature control

use v5.20;

use strict;
use Moose;
use Moose::Util::TypeConstraints qw/enum/;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    validated_getter
    validated_setter
    validated_no_param_setter
    setter_params
    /;
use Carp;
use namespace::autoclean;
use Time::HiRes qw/time usleep/;

# HTTP request JSON stuff
use DateTime;
use JSON;
use Data::Dumper;


extends 'Lab::Moose::Instrument';

has default_channel => (
    is  => 'ro',
    isa => 'Num',
    default => 1,
);

has default_heater => (
    is  => 'ro',
    isa => 'Num',
    default => 1,
);

has default_time => (
    is  => 'ro',
    isa => 'Num',
    default => 90,
);

has json => (
    is => 'ro',
    isa => 'Any',
    builder => '_build_json',
);
sub _build_json {
    return JSON->new;
}

around default_connection_options => sub {
	my $orig = shift;
	my $self = shift;
	my $options = $self->$orig();

	$options->{HTTP}{port} = 5001;
	return $options;
};


sub get_measurement {
    my ( $self, %args ) = validated_hash(
        \@_,
        channel_nr => { isa => enum([ (1..12) ]) },
        time => { isa => 'Lab::Moose::PosNum' },
        fields => { isa => 'ArrayRef' },
    );
    my $channel_nr = $args{'channel_nr'};
    my $time = $args{'time'};
    my $fields = $args{'fields'};

    my $time_stop  = DateTime->now."Z"; 
    my $time_start = DateTime->from_epoch(epoch => time()-$time)."Z";

    my %hash_json = ( 'channel_nr'  => $channel_nr,
                      'start_time' => $time_start,
                      'stop_time'  => $time_stop,
                      'fields'     => $fields,
                    );
    my $json = $self->json->encode(\%hash_json);

    my $endpoint = '/channel/historical-data';

    my $response = $self->write( endpoint =>  $endpoint, body => $json);
    my $hashref = $self->json->decode($response->content);

    return $hashref->{'measurements'};
}


sub get_heater_measurement {
    my ( $self, %args ) = validated_hash(
        \@_,
        heater_nr => { isa => enum([ (1..4) ])},
        time => { isa => 'Lab::Moose::PosNum' },
        fields => { isa => 'ArrayRef' },
    );
    my $heater_nr = delete $args{'heater_nr'};
    my $time      = delete $args{'time'};
    my $fields    = delete $args{'fields'};

    my $time_stop  = DateTime->now."Z"; 
    my $time_start = DateTime->from_epoch(epoch => time()-$time)."Z";

    my %hash_json = ( 'heater_nr'  => $heater_nr,
                      'start_time' => $time_start,
                      'stop_time'  => $time_stop,
                      'fields'     => $fields,
                    );
    my $json = $self->json->encode(\%hash_json);

    my $endpoint = '/heater/historical-data';

    my $response = $self->write( endpoint =>  $endpoint, body => $json);
    my $hashref = $self->json->decode($response->content);

    return $hashref->{'measurements'};
}


sub set_heater {
    my ($self, %args) = validated_hash(
        \@_,
        heater_nr                   => { isa => enum([ (1..4) ])                  },
        active                      => { isa => enum( [qw/0 1/]),   optional => 1 },
        pid_mode                    => { isa => enum( [qw/0 1/]),   optional => 1 },
        resistance                  => { isa => 'Num',              optional => 1 },
        power                       => { isa => 'Num',              optional => 1 },
        target_temperature          => { isa => 'Num',              optional => 1 },
        control_algorithm_settings  => { isa => 'HashRef',          optional => 1 },
        setpoint                    => { isa => 'Num',              optional => 1 }, 
    );
    if (exists $args{'active'} and defined $args{'active'}) {
        if ( $args{"active"} eq 1 ) {
            $args{"active"} = JSON::true;
        } else {
            $args{"active"} = JSON::false;
        }
    }
    my $json = $self->json->encode(\%args);

    my $endpoint = '/heater/update';
    my $response = $self->write( endpoint =>  $endpoint, body => $json);
    my $hashref = $self->json->decode($response->content);

    return $hashref;
}


sub set_channel {
    my ($self, %args) = validated_hash(
        \@_,
        channel_nr => { isa => enum([ (1..12) ]) },
        active     => { isa => enum( [qw/0 1/] ), optional => 1 },
        excitation_mode       => { isa => enum( [qw/0 1 2/] ), optional => 1 },
        excitation_current_range => { isa => enum([ (1..22) ]), optional => 1 },
        excitation_cmn_range  => { isa => enum( [qw/1 2/] ), optional => 1 },
        excitation_vmax_range => { isa => enum( [qw/1 2/] ), optional => 1 },
        use_non_default_timeconstants => { isa => enum( [qw/0 1/] ), optional => 1 },
        wait_time  => { isa => 'Num', optional => 1 },
        meas_time  => { isa => 'Num', optional => 1 },
    );
    if (exists $args{'active'} and defined $args{'active'}) {
        if ( $args{"active"} eq 1 ) {
            $args{"active"} = JSON::true;
        } else {
            $args{"active"} = JSON::false;
        }
    }
    my $json = $self->json->encode(\%args);

    my $endpoint = '/channel/update';
    my $response = $self->write( endpoint =>  $endpoint, body => $json);
    my $hashref = $self->json->decode($response->content);

    return $hashref;
}


sub set_statemachine {
    my ($self, %args) = validated_hash(
        \@_,
        wait_time => { isa => enum([ (1..100) ]) },
        meas_time => { isa => enum([ (1..100) ]) },
    );

    my $json = $self->json->encode(\%args);

    my $endpoint = '/statemachine/update';
    my $response = $self->write( endpoint =>  $endpoint, body => $json);
    my $hashref = $self->json->decode($response->content);

    return $hashref;
}


sub idn {
    my $self = shift;

    my $endpoint = '/system';
    my $response = $self->read( endpoint => $endpoint );
    my $hashref = $self->json->decode($response->content);

    my $ret = '';
    $ret = $ret . $hashref->{api_version} . ":";
    $ret = $ret . $hashref->{type} . ":";
    $ret = $ret . $hashref->{serial} . ":";
    $ret = $ret . $hashref->{label} . ":";
    $ret = $ret . $hashref->{addinfo} . ":";
    $ret = $ret . $hashref->{software_version};

    return $ret;
}


sub set_network_config {
    my ($self, %args) = validated_hash(
        \@_,
        ip_configuration => { isa => 'Str' },
        ip_address       => { isa => 'Str', optional => 1 },
        netmask          => { isa => 'Str', optional => 1 },
    );
    my $json = $self->json->encode(\%args);
    say $json;

    my $endpoint = '/system/network/update';
    my $response = $self->write( endpoint => $endpoint, body => $json);
    my $hashref = $self->json->decode($response->content);

    return $hashref;
}


sub set_channel_heater_relation {
        my ($self, %args) = validated_hash(
        \@_,
        channel_nr => { isa => enum([ (0..12) ]) },
        heater_nr  => { isa => enum([ (0..4)  ]) },
    );
    my $json = $self->json->encode(\%args);

    my $endpoint = '/channel/heater/update';
    my $response = $self->write( endpoint => $endpoint, body => $json);
    my $hashref = $self->json->decode($response->content);

    return $hashref;
}


# High level functions for sweeps


sub get_T {
    my ($self, %args) = validated_hash(
        \@_,
        channel_nr => { isa => enum([ (1..12) ]), optional => 1 },
    );

    my $channel;
    if( exists $args{'channel_nr'} and defined $args{'channel_nr'} ) {
        $channel = delete $args{'channel_nr'};
    } else {
        $channel = $self->default_channel;
    }

    my $response = $self->get_measurement( channel_nr => $channel,
                            time => $self->default_time,
                            fields => [ "temperature" ] );
    return $response->{'temperature'}->[-1];

}


sub set_T {
    my ($self, %args) = validated_hash(
        \@_,
        value => { isa => 'Num' },
        heater_nr => { isa => enum([ (1..4) ]), optional => 1 },
    );

    my $heater;
    if( exists $args{'heater_nr'} and defined $args{'heater_nr'} ) {
        $heater = delete $args{'heater_nr'};
    } else {
        $heater = $self->default_heater;
    }
    my $value = delete $args{'value'};

    return $self->set_heater( heater_nr => $heater, active => 1, setpoint => $value );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::Bluefors_Temp - Bluefors temperature control

=head1 VERSION

version 3.904

=head1 SYNOPSIS

 use Lab::Moose;

 # Constructor
 my $tc = instrument(
     type            => 'Bluefors_Temp',
     connection_type => 'HTTP',
     connection_options => {
         ip => '192.32.14.24',
     },
 );

=head1 METHODS

=head2 get_measurement

 my $measurement = $tc->get_measurement( channel_nr => (1..12), time => 60, fields => [ 'temperature', 'resistance' ] );

The get_measurement() function returns the measurements of a specific channel in the specified time.
The option "time" controls how far back the measurements are fetched from the device. 
In the example "time => 60" gets the measurements done in the last 60 seconds.
The last option "fields" controls which measurements are fetched. A full list can be found in the API reference.

This function returns a hash reference with array references of all measurements.
The latest temperature measurement can be retrieved using $measurement->{'temperature'}[-1].

=head2 get_heater_measurement

 my $heater_meas = $tc->get_heater_measurement( heater_nr => (1..4), time => 60, fields => [ 'power', 'current' ] );

The get_heater_measurement() function returns the measurements of a specific heater.
It works the same as the get_measurement() function.

=head2 set_heater

 $tc->set_heater( heater_nr => (1..4), active => 1, power => 0.03, ... );

The set_heater() function controls the settings of a specific heater.
Supported options are:
 - heater_nr
 - active                    
 - pid_mode                  
 - resistance                
 - power                     
 - target_temperature        
 - control_algorithm_settings
 - setpoint

=head2 set_channel

 $tc->set_channel( channel_nr => (1..12), active => 1, ... );

The set_channel() function controls the settings of a specific channel.
Supported options are:
  - channel_nr
  - active
  - excitation_mode
  - excitation_current_range
  - excitation_cmn_range
  - excitation_vmax_range
  - use_non_default_timeconstants
  - wait_time
  - meas_time

=head2 set_statemachine

 my $state = $tc->set_statemachine( wait_time => 2, meas_time => 2 );

The set_statemachine() function controls the wait time after changing channel
and the measurement time. Both values are given in seconds.
The response is a hash reference with all information about the statemachine
described in the API reference.

=head2 idn

 say $tc->idn();

Returns all available system information concatenated as a string.

=head2 set_network_config

 my $configuration = $tc->set_network_config( ip_configuration => 'static', ip_address => '192.168.0.12' );

Supported options:
 - ip_configuration
 - ip_address      
 - netmask

=head2 set_channel_heater_relation

 my $relation = $tc->set_channel_heater_relation( channel_nr => 8, heater_nr => 2 );

Updates the relation between a channel and a heater.

=head2 get_T

 my $temp = $tc->get_T();

Returns the latest temperature measurement of the default channel using the default time parameter.
High level function for the built-in sweep environment.
Use the get_measurement function for all other use cases.

=head2 set_T

 $tc->set_T( value => 1.2 );

Sets the target temperature for the default heater and sets the active state to ON.
High level function for the in-built sweep environment.
Use the set_heater function for all other use cases.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by the Lab::Measurement team; in detail:

  Copyright 2023       Andreas K. Huettel, Mia Schambeck


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
