package Lab::Instrument::DummySource;
#ABSTRACT: Dummy voltage source
$Lab::Instrument::DummySource::VERSION = '3.899';
use v5.20;

use warnings;
use strict;

use Data::Dumper;

use parent 'Lab::Instrument::Source';

our %fields = (
    supported_connections => ['DEBUG'],

    connection_settings => {},

    device_settings => {

        # gate_protect            => 1,
        # gp_equal_level          => 1e-5,
        # gp_max_units_per_second  => 0.002,
        # gp_max_units_per_step    => 0.001,
        # gp_max_step_per_second  => 2,

        max_sweep_time => 3600,
        min_sweep_time => 0.1,
    },

    device_cache => {
        function => "Voltage",
        range    => 10,
        level    => 0,
        output   => undef,
    },

    device_cache_order => [ 'function', 'range' ],
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    print "DS: Created dummy instrument with config\n";
    while ( my ( $k, $v ) = each %{ $self->device_settings() } ) {
        $v = 'undef' if !defined($v);
        print "DS:   $k -> $v\n";
    }

    return $self;
}

sub _device_init {
    my $self = shift;
    return;
}

# sub config_sweep {
#     my $self = shift;
#     my ($start, $target, $duration,$sections ,$tail) = $self->check_sweep_config(@_);

#     print "Dummy Source sweep configuration.\n";
#     print "Duration: $duration\n";
#     $self->{'sweeptime'} = $duration;
# }

sub trg {
    print "Dummy Source received trigger.\n";
}

sub wait {
    my $self = shift;
    print "Dummy Source is sweeping.\n";
    sleep( $self->{'sweeptime'} );
}

sub _set_level {
    my $self = shift;
    my ( $value, $tail ) = $self->_check_args( \@_, ['value'] );
    say "DS: setting level to $value";
    return $self->{'device_cache'}->{'level'} = $value;
}

sub set_voltage {
    my $self = shift;
    my ( $voltage, $tail ) = $self->_check_args( \@_, ['voltage'] );
    return $self->set_level( $voltage, $tail );
}

sub get_level {
    my $self = shift;

    return $self->{'device_cache'}->{'level'};
}

sub active {
    return 0;
}

sub abort {
    return 0;
}

sub set_range {
    my $self    = shift;
    my $range   = shift;
    my $args    = {@_};
    my $channel = $args->{'channel'} || $self->default_channel();

    my $tmp = "last_range_$channel";
    $self->{$tmp} = $range;
    print "DS: setting virtual range of channel $channel to $range\n";
}

sub get_range {
    my $self    = shift;
    my $args    = {@_};
    my $channel = $args->{'channel'} || $self->default_channel();

    my $tmp = "last_range_$channel";
    print "DS: getting virtual range: $$self{$tmp}\n";
    return $self->{$tmp};
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::DummySource - Dummy voltage source (deprecated)

=head1 VERSION

version 3.899

=head1 DESCRIPTION

This module belongs to a deprecated legacy module stack, frozen and not under development anymore. Please port your code to the new API; its documentation can be found on the Lab::Measurement homepage, L<https://www.labmeasurement.de/>.

The Lab::Instrument::DummySource class implements a dummy voltage source
that does nothing but can be used for testing purposes.

Only developers will ever make use of this class.

=head1 SEE ALSO

=over 4

=item (L<Lab::Instrument::Source>).

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2011       Andreas K. Huettel, Florian Olbrich
            2012       Alois Dirnaichner
            2015       Alois Dirnaichner
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
