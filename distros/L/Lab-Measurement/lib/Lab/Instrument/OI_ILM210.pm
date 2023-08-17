package Lab::Instrument::OI_ILM210;
#ABSTRACT: Oxford Instruments ILM Intelligent Level Meter
$Lab::Instrument::OI_ILM210::VERSION = '3.881';
use v5.20;

use strict;
use Lab::Instrument;

our @ISA = ("Lab::Instrument");

our %fields = ( supported_connections => ['IsoBus'], );

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    return $self;
}

sub get_level {
    my $self    = shift;
    my $channel = shift;
    $channel = "1" unless defined($channel);

    my $level = $self->query("R$channel");
    $level =~ s/^R//;
    $level /= 10;
    return $level;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::OI_ILM210 - Oxford Instruments ILM Intelligent Level Meter

=head1 VERSION

version 3.881

=head1 SYNOPSIS

    use Lab::Instrument::OI_ILM210;
    
    my $ilm=new Lab::Instrument::OI_ILM210(
      connection_type=>'IsoBus', 
      base_connection=>..., 
      isobus_address=>5,
    );

=head1 DESCRIPTION

The Lab::Instrument::OI_ILM210 class implements an interface to the Oxford Instruments 
ILM helium level meter (tested with the ILM210).

=head1 CONSTRUCTOR

    my $ilm=new Lab::Instrument::OI_ILM210(
      connection_type=>'IsoBus', 
      base_connection=> $iso, 
      isobus_address=> $addr,
    );

Instantiates a new ILM210 object, attached to the GPIB or RS232 connection 
(of type C<Lab::Connection>) C<$iso>, with IsoBus address C<$addr>. 

=head1 METHODS

=head2 get_level

    $perc=$ilm->get_level();
    $perc=$ilm->get_level(1);

Reads out the current helium level in percent. Note that this command does NOT trigger a measurement, but 
only reads out the last value measured by the ILM. This means that in slow mode values may remain constant
for several minutes.

As optional parameter a channel number can be provided. This defaults to 1.

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2011       Andreas K. Huettel, Florian Olbrich
            2012-2013  Andreas K. Huettel
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
