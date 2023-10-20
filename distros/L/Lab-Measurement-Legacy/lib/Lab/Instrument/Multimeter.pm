package Lab::Instrument::Multimeter;
#ABSTRACT: Generic digital multimeter base class
$Lab::Instrument::Multimeter::VERSION = '3.899';
use v5.20;

use strict;
use Lab::Instrument;

our @ISA = ("Lab::Instrument");

our %fields = (
    supported_connections => [],

    device_settings => {},

);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);
    return $self;
}

# template functions for inheriting classes

sub id {
    die "id not implemented for this instrument\n";
}

sub get_range {
    my $self = shift;

    Lab::Exception::DriverError->throw( "The unimplemented method stub "
            . __PACKAGE__
            . "::get_range() has been called. I can't work like this.\n" );
}

sub set_range {
    my $self = shift;

    Lab::Exception::DriverError->throw( "The unimplemented method stub "
            . __PACKAGE__
            . "::set_range() has been called. I can't work like this.\n" );
}

sub get_level {
    my $self = shift;

    Lab::Exception::DriverError->throw( "The unimplemented method stub "
            . __PACKAGE__
            . "::set_level() has been called. I can't work like this.\n" );
}

sub selftest {
    die "selftest not implemented for this instrument\n";
}

sub configure_voltage_dc {
    die "configure_voltage_dc not implemented for this instrument\n";
}

sub configure_voltage_dc_trigger {
    die "configure_voltage_dc_trigger not implemented for this instrument\n";
}

sub triggered_read {
    die "triggered_read not implemented for this instrument\n";
}

sub get_error {
    die "get_error not implemented for this instrument\n";
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::Multimeter - Generic digital multimeter base class (deprecated)

=head1 VERSION

version 3.899

=head1 DESCRIPTION

This module belongs to a deprecated legacy module stack, frozen and not under development anymore. Please port your code to the new API; its documentation can be found on the Lab::Measurement homepage, L<https://www.labmeasurement.de/>.

The Lab::Instrument::Multmeter class implements a generic interface to
digital all-purpose multimeters. It is intended to be inherited by other
classes, not to be called directly, and provides a set of generic functions.
The class

=head1 CONSTRUCTOR

    my $hp=new(\%options);

=head1 METHODS

=head2 get_value

    $value=$hp->get_value();

Read out the current measurement value, for whatever type of measurement
the multimeter is currently configured.

=head2 id

    $id=$hp->id();

Returns the instruments ID string.

=head2 display_on

    $hp->display_on();

Turn the front-panel display on.

=head2 display_off

    $hp->display_off();

Turn the front-panel display off.

=head2 display_text

    $hp->display_text($text);

Display a message on the front panel. 

=head2 display_clear

    $hp->display_clear();

Clear the message displayed on the front panel.

=head1 CAVEATS/BUGS

none known so far :)

=head1 SEE ALSO

=over 4

=item * L<Lab::Instrument>

=item * L<Lab::Instrument:HP34401A>

=item * L<Lab::Instrument:HP3458A>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2011       Andreas K. Huettel, Florian Olbrich
            2012       Alois Dirnaichner, Florian Olbrich
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
