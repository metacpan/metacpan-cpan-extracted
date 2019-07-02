package Lab::Moose::Instrument::OI_Common;
$Lab::Moose::Instrument::OI_Common::VERSION = '3.682';
#ABSTRACT: Role for handling Oxfords Instruments pseudo-SCPI commands

use Moose::Role;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/validated_getter validated_setter/;

use Carp;
use namespace::autoclean;


sub get_temperature_channel {
    my ( $self, %args ) = validated_getter(
        \@_,
        channel => { isa => 'Str' }
    );

    my $channel = delete $args{channel};

    my $rv
        = $self->oi_getter( cmd => "READ:DEV:$channel:TEMP:SIG:TEMP", %args );
    $rv =~ s/K.*$//;
    return $rv;
}

sub get_temperature_channel_resistance {
    my ( $self, %args ) = validated_getter(
        \@_,
        channel => { isa => 'Str' }
    );

    my $channel = delete $args{channel};

    my $rv
        = $self->oi_getter( cmd => "READ:DEV:$channel:TEMP:SIG:RES", %args );
    $rv =~ s/Ohm.*$//;
    return $rv;
}

sub _parse_setter_retval {
    my $self = shift;
    my ( $header, $retval ) = @_;

    $header = 'STAT:' . $header;
    if ( $retval !~ /^\Q$header\E:([^:]+):VALID$/ ) {
        croak "Invalid return value of setter for header $header:\n $retval";
    }
    return $1;
}

sub _parse_getter_retval {
    my $self = shift;
    my ( $header, $retval ) = @_;

    $header =~ s/^READ:/STAT:/;

    if ( $retval !~ /^\Q$header\E:(.+)/ ) {
        croak "Invalid return value of getter for header $header:\n $retval";
    }
    return $1;
}


sub oi_getter {
    my ( $self, %args ) = validated_getter(
        \@_,
        cmd => { isa => 'Str' }
    );
    my $cmd = delete $args{cmd};
    my $rv = $self->query( command => $cmd, %args );
    return $self->_parse_getter_retval( $cmd, $rv );
}


sub oi_setter {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        cmd => { isa => 'Str' }
    );
    my $cmd = delete $args{cmd};
    my $rv = $self->query( command => "$cmd:$value", %args );
    return $self->_parse_setter_retval( $cmd, $rv );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::OI_Common - Role for handling Oxfords Instruments pseudo-SCPI commands

=head1 VERSION

version 3.682

=head1 DESCRIPTION

=head1 METHODS

=head2 get_temperature

 $t = $m->get_temperature_channel(channel => 'MB1.T1');

Read out the designated temperature channel. The result is in Kelvin.

=head2 get_temperature_channel_resistance

 $r = $m->get_temperature_channel_resistance(channel => 'MB1.T1');

Read out the designated temperature channel resistance. The result is in Ohm.

=head2 oi_getter

 my $current = $self->oi_getter(cmd => "READ:DEV:$channel:PSU:SIG:CURR", %args);
 $current =~ s/A$//;

Perform query with I<READ:*> command and parse return value.

=head2 oi_setter

  $self->oi_setter(
        cmd => "SET:DEV:$channel:PSU:SIG:SWHT",
        value => $value,
        %args);

Perform set/query with I<SET:*> command and parse return value.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2018       Andreas K. Huettel, Simon Reinhardt
            2019       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
