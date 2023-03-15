package Lab::Moose::Instrument::HP83732A;
$Lab::Moose::Instrument::HP83732A::VERSION = '3.860';
#ABSTRACT: HP 83732A Series Synthesized Signal Generator

use v5.20;

use strict;
use Time::HiRes qw (usleep);
use Moose;
use Moose::Util::TypeConstraints qw/enum/;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    validated_getter
    validated_setter
    validated_no_param_setter
    setter_params
/;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;
use Time::HiRes qw/time usleep/;
use Lab::Moose 'linspace';

extends 'Lab::Moose::Instrument';

sub BUILD {
    my $self = shift;
    $self->get_id();
}

sub get_id {
    my $self = shift;
    return $self->query( command => sprintf("*IDN?") );
}



sub reset {
    my $self = shift;
    $self->write( command => sprintf("*RST") );
}


sub set_frq {
	my ( $self, $value, %args ) = validated_setter( \@_,
        value  => { isa => 'Num' },
    );

	$self->write( command => sprintf("FREQuency:CW %d Hz", $value), %args ); 
}


sub get_frq {
    my $self = shift;

    return $self->query( command => sprintf("FREQuency:CW?") );
}

sub set_power {
	my ( $self, $value, %args ) = validated_setter( \@_,
        value  => { isa => 'Num' },
    );

    $self->write( command => sprintf("POWer:LEVel %d DBM", $value) );
}


sub get_power {
    my $self = shift;

    return $self->query( command => sprintf("POWer:LEVel?") );
}

sub power_on {
    my $self = shift;
    $self->write( command => sprintf("OUTP:STATe ON") );
}

sub power_off {
    my $self = shift;
    $self->write( command => sprintf("OUTP:STATe OFF") );
}

sub selftest {
    my $self = shift;
    return $self->query( command => sprintf("*TST?") );
}

sub display_on {
    my $self = shift;
    $self->write( command => sprintf("DISPlay ON") );
}

sub display_off {
    my $self = shift;
    $self->write( command => sprintf("DISPlay OFF") );
}

sub enable_external_am {
    my $self = shift;
    $self->write( command => sprintf("AM:DEPTh MAX") );
    $self->write( command => sprintf("AM:SENSitivity 70PCT/VOLT") );
    $self->write( command => sprintf("AM:TYPE LINear") );
    $self->write( command => sprintf("AM:STATe ON") );
}

sub disable_external_am {
    my $self = shift;
    $self->write( command => sprintf("AM:STATe OFF") );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::HP83732A - HP 83732A Series Synthesized Signal Generator

=head1 VERSION

version 3.860

=head1 SYNOPSIS

 use Lab::Moose;

 # Constructor
 my $HP = instrument(
     type            => 'HP83732A',
     connection_type => 'VISA_GPIB',
     connection_options => {
         pad => 28,
     },
 );

=head1 METHODS

=head2 reset

 $HP->reset();

=head2 set_frq

 $HP->set_frq( value =>  );

 The frequency can range from 10 MHz to 20 GHz.
 TODO: How is the format of the frequency? float?

=head2 get_frq

 $HP->get_frq();

=head2 set_power

 $HP->set_power( value =>  );

 TODO: format of power?

=head2 get_power

 $HP->get_power();

=head2 power_on

 $HP->power_on();

=head2 power_off

 $HP->power_off();

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2022       Mia Schambeck


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
