package Lab::Instrument::HP83732A;
our $VERSION = '3.542';

use strict;
use Lab::Instrument;
use Time::HiRes qw (usleep);

our @ISA = ("Lab::Instrument");

our %fields = (
    supported_connections => ['GPIB'],

    # default settings for the supported connections
    connection_settings => {
        gpib_board   => 0,
        gpib_address => undef,
    },

    device_settings => {},

);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);
    return $self;
}

sub id {
    my $self = shift;
    return $self->query('*IDN?');
}

sub reset {
    my $self = shift;
    $self->write('*RST');
}

sub set_frq {
    my $self = shift;
    my ($freq) = $self->_check_args( \@_, ['value'] );

    #my $freq = shift;
    $self->set_cw($freq);

}

sub set_cw {
    my $self = shift;
    my $freq = shift;

    $self->write("FREQuency:CW $freq Hz");
}

sub get_frq {
    my $self = shift;

    my $freq = $self->query("FREQuency:CW?");

    return $freq;

}

sub set_power {
    my $self = shift;
    my ($power) = $self->_check_args( \@_, ['value'] );

    $self->write("POWer:LEVel $power DBM");
}

sub get_power {
    my $self = shift;

    return $self->query("POWer:LEVel?");
}

sub power_on {
    my $self = shift;
    $self->write('OUTP:STATe ON');
}

sub power_off {
    my $self = shift;
    $self->write('OUTP:STATe OFF');
}

sub selftest {
    my $self = shift;
    return $self->query("*TST?");
}

sub display_on {
    my $self = shift;
    $self->write("DISPlay ON");
}

sub display_off {
    my $self = shift;
    $self->write("DISPlay OFF");
}

sub enable_external_am {
    my $self = shift;
    $self->write("AM:DEPTh MAX");
    $self->write("AM:SENSitivity 70PCT/VOLT");
    $self->write("AM:TYPE LINear");
    $self->write("AM:STATe ON");
}

sub disable_external_am {
    my $self = shift;
    $self->write("AM:STATe OFF");
}

1;

=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::HP83732A - HP 83732A Series Synthesized Signal Generator

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head1 METHODS

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item * Lab::Instrument

=back

=head1 AUTHOR/COPYRIGHT

  Copyright 2005 Daniel Schröer (<schroeer@cpan.org>)
            2011 Andreas K. Hüttel

This library is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut
