package Lab::Moose::Instrument::HP34420A;
$Lab::Moose::Instrument::HP34420A::VERSION = '3.682';
#ABSTRACT: HP 34420A nanovolt meter.

# So far only one channel. Could add support for two channels
# by using validated_channel_(setter/getter) in the SCPI/SENSE roles.

use 5.010;

use Moose;
use Moose::Util::TypeConstraints 'enum';
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/validated_getter validated_setter/;
use Carp;
use Lab::Moose::Instrument::Cache;
use namespace::autoclean;

extends 'Lab::Moose::Instrument';

with qw(
    Lab::Moose::Instrument::Common
    Lab::Moose::Instrument::SCPI::Sense::Function
    Lab::Moose::Instrument::SCPI::Sense::Range
    Lab::Moose::Instrument::SCPI::Sense::NPLC
);

sub BUILD {
    my $self = shift;
    $self->clear();
    $self->cls();
}



sub get_value {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => 'READ?', %args );
}


cache route_terminals => ( getter => 'route_terminals_query' );

sub route_terminals_query {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->cached_route_terminals(
        $self->query( command => 'ROUT:TERM?', %args ) );
}

sub route_terminals {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/FRON FRON1 FRON2/] ) }
    );
    $self->write( command => "ROUT:TERM $value" );
    $self->cached_route_terminals($value);
}

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::HP34420A - HP 34420A nanovolt meter.

=head1 VERSION

version 3.682

=head1 SYNOPSIS

 my $dmm = instrument(
    type => 'HP34420A',
    connection_type => 'LinuxGPIB',
    connection_options => {pad => 24},
    );

 # Set properties of channel1:
 $dmm->sense_range(value => 10);
 $dmm->sense_nplc(value => 2);  
  
 my $voltage = $dmm->get_value();

The C<SENSE> methods only support channel 1 so far.

=head1 METHODS

Used roles:

=over

=item L<Lab::Moose::Instrument::SCPI::Sense::Function>

=item L<Lab::Moose::Instrument::SCPI::Sense::Range>

=item L<Lab::Moose::Instrument::SCPI::Sense::NPLC>

=back

=head2 get_value

 my $voltage = $dmm->get_value();

Perform voltage/current measurement.

=head2 route_terminals/route_terminals_query

 $dmm->route_terminals(value => 'FRON2');

Set/get used measurement channel. Allowed values: C<FRON[1], FRON2>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2018       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
