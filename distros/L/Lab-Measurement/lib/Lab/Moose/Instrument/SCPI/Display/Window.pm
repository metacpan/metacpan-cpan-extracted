package Lab::Moose::Instrument::SCPI::Display::Window;
$Lab::Moose::Instrument::SCPI::Display::Window::VERSION = '3.682';
#ABSTRACT: Role for the SCPI DISPlay:WINDow subsystem

use Moose::Role;
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument
    qw/validated_channel_getter validated_channel_setter/;
use MooseX::Params::Validate;
use Carp;

use namespace::autoclean;


cache display_window_trace_y_scale_rlevel =>
    ( getter => 'display_window_trace_y_scale_rlevel_query' );

sub display_window_trace_y_scale_rlevel_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->cached_display_window_trace_y_scale_rlevel(
        $self->query( command => ":DISP:WIN:TRACe:Y:SCALe:RLEV?", %args ) );
}

sub display_window_trace_y_scale_rlevel {
    my ( $self, $channel, $value, %args ) = validated_channel_setter( \@_ );
    $self->write(
        command => sprintf( ":DISP:WIN:TRACe:Y:SCALe:RLEV %.17g", $value ),
        %args
    );
    $self->cached_display_window_trace_y_scale_rlevel($value);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::SCPI::Display::Window - Role for the SCPI DISPlay:WINDow subsystem

=head1 VERSION

version 3.682

=head1 METHODS

=head2 display_window_trace_y_scale_rlevel

 my $refLevel = $self->display_window_trace_y_scale_rlevel_query();

Query the amplitude value of the reference level for the y-axis.

=head2 display_window_trace_y_scale_rlevel

 $self->display_window_trace_y_scale_rlevel(value => -20);

Sets the amplitude value of the reference level for the y-axis.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2018       Eugeniy E. Mikhailov


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
