package Lab::Instrument::HP83732A;
#ABSTRACT: HP 83732A Series Synthesized Signal Generator
$Lab::Instrument::HP83732A::VERSION = '3.899';
use v5.20;

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

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::HP83732A - HP 83732A Series Synthesized Signal Generator (deprecated)

=head1 VERSION

version 3.899

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item * Lab::Instrument

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2011       Andreas K. Huettel, Florian Olbrich
            2012       Hermann Kraus
            2013       Alois Dirnaichner, Andreas K. Huettel
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
