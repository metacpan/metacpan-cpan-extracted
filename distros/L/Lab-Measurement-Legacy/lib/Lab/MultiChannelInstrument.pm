package Lab::MultiChannelInstrument;
$Lab::MultiChannelInstrument::VERSION = '3.899';
#ABSTRACT: Multi-channel instrument base class

use v5.20;

use strict;
use Lab::Generic;
use List::MoreUtils qw{ any };
use Carp qw(cluck croak);
use Class::ISA qw(self_and_super_path);
use Clone qw(clone);
use Data::Dumper;

our $AUTOLOAD;
our @ISA = ('Lab::Generic');

our %fields = (
    supported_connections => [],

    connection_settings => {},

    device_settings => {
        channels => {
            'A' => undef,
            'B' => undef,
        },
        channel_default => undef,

    },

    device_cache => {},

    device_cache_order => [],
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    # create generic class:
    my $self = ${ \(__PACKAGE__) }->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }( __PACKAGE__, $class );

    # merge user config data with default config
    my $config = {};
    if ( ref $_[0] eq 'HASH' ) { %{$config} = ( %{$config}, %{ $_[0] } ) }
    else                       { $config = {@_} }
    $self->{config} = $config;
    $self->_construct( $self->{config} );

    # load parent class lib
    my @isa = Class::ISA::super_path($class);
    our @ISA = $isa[2];
    eval "require $ISA[0]; @ISA->import(); 1;"
        or do Lab::Exception::Warning->throw( error => $@ );

    # create instrument channels:
    while ( my ( $channel, $value )
        = each %{ $self->{device_settings}->{channels} } ) {
        $self->{channels}->{$channel} = $class->SUPER::new( $self->{config} );

        $self->{channels}->{$channel}->${ \( $ISA[0] . '::_construct' ) }
            ($class);

        $self->{channels}->{$channel}->{channel} = $value;

        # link shared cache values to the same cache-address in order to keep these parameters up to date for all channels (using a tied Hash):
        my $device_cache;
        tie %$device_cache, 'Lab::MultiChannelInstrument::DeviceCache', $self;

        while ( my ( $k, $v )
            = each %{ $self->{channels}->{$channel}->device_cache() } ) {
            $device_cache->{$k} = $v;
        }
        $self->{channels}->{$channel}->{device_cache} = $device_cache;

        $self->{channels}->{$channel}->unregister_instrument();

    }

    if (   not defined $self->{device_settings}->{channel_default}
        or not exists $self->{channels}
        ->{ $self->{device_settings}->{channel_default} } ) {
        Lab::Exception::Warning->throw(
                  error => "\n\nMultiChannelDevice: default channel '"
                . $self->{device_settings}->{channel_default}
                . "' is not defined or does not exist!\n\n" );
    }

    $self->register_instrument();

    our @ISA = ('Lab::Generic');
    return $self;
}

sub _construct {    # _construct(__PACKAGE__);
    ( my $self, my $package ) = ( shift, shift );
    my $class  = shift;
    my $fields = undef;

    if ( ref($package) ne 'HASH' ) {
        my @isa          = Class::ISA::self_and_super_path($class);
        my $device_class = $isa[0];
        {
            no strict 'refs';
            $fields = *${ \( $package . '::fields' ) }{HASH};
            $fields
                = ( $fields, *${ \( $device_class . '::fields' ) }{HASH} );
        }
    }
    else {
        $fields = $package;
    }

    foreach my $element ( keys %{$fields} ) {

        # handle special subarrays
        if ( $element eq 'device_settings' ) {

            # # don't overwrite filled hash from ancestor
            $self->{device_settings} = {}
                if !exists( $self->{device_settings} );
            for my $s_key ( keys %{ $fields->{'device_settings'} } ) {
                $self->{device_settings}->{$s_key}
                    = clone( $fields->{device_settings}->{$s_key} );
            }
        }
        elsif ( $element eq 'connection_settings' ) {

            # don't overwrite filled hash from ancestor
            $self->{connection_settings} = {}
                if !exists( $self->{connection_settings} );
            for my $s_key ( keys %{ $fields->{connection_settings} } ) {
                $self->{connection_settings}->{$s_key}
                    = clone( $fields->{connection_settings}->{$s_key} );
            }
        }
        elsif ( $element eq 'channels' ) {
            $self->{device_settings}->{channels} = $fields->{$element};
        }
        else {
            # handle the normal fields - can also be hash refs etc, so use clone to get a deep copy
            $self->{$element} = clone( $fields->{$element} );

            #warn "here comes\n" if($element eq 'device_cache');
            #warn Dumper($Lab::Instrument::DummySource::fields) if($element eq 'device_cache');
        }
        $self->{_permitted}->{$element} = 1;
    }

}

sub channel {
    my $self    = shift;
    my $channel = shift;

    if ( exists $self->{channels}->{$channel} ) {
        return $self->{channels}->{$channel};
    }
    else {
        Lab::Exception::CorruptParameter->throw(
                  error => "\n\nMultiChannelInstrument: Channel '"
                . $channel
                . "' is not defined.\n\n" );
    }
}

sub sprint_config {
    my $self = shift;
    my $config;

    my $device_cache;
    $Data::Dumper::Varname = "device_cache_";

    while ( my ( $k, $v ) = each %{ $self->{device_cache} } ) {
        if ( any { $_ eq $k } @{ $self->{multichannel_shared_cache} } ) {
            $device_cache->{'shared_variables'}->{$k} = $v;
        }
    }

    while ( my ( $chk, $chv ) = each %{ $self->{channels} } ) {
        $device_cache->{'multichannel_variables'}->{$chk}->{'name'}
            = $chv->get_name();
        while ( my ( $k, $v )
            = each %{ $self->{channels}->{$chk}->{device_cache} } ) {
            if ( any { $_ eq $k } @{ $self->{multichannel_shared_cache} } ) {

            }
            else {
                $device_cache->{'multichannel_variables'}->{$chk}->{$k} = $v;
            }
        }
    }

    $config .= Dumper $device_cache;

    $Data::Dumper::Varname  = "connection_settings_";
    $Data::Dumper::Maxdepth = 1;
    if ( defined $self->connection() ) {
        $config .= Dumper $self->connection();
    }
    return $config;
}

sub register_instrument {
    my $self = shift;

    push( @{Lab::Instrument::REGISTERED_INSTRUMENTS}, $self );

}

sub unregister_instrument {
    my $self = shift;

    @{Lab::Instrument::REGISTERED_INSTRUMENTS}
        = grep { $_ ne $self } @{Lab::Instrument::REGISTERED_INSTRUMENTS};

}

sub AUTOLOAD {
    my $self  = shift;
    my $type  = ref($self) or croak "\$self is not an object";
    my $value = undef;

    my $name = $AUTOLOAD;
    $name =~ s/.*://;    # strip fully qualified portion

    if ( exists $self->{_permitted}->{$name} ) {

        if (@_) {
            return $self->{$name} = shift;
        }
        else {
            return $self->{$name};
        }
    }
    elsif ( exists $self->{channels}->{$name} ) {
        return $self->{channels}->{$name};
    }
    elsif ( exists $self->{'device_settings'}->{$name} ) {
        if (@_) {
            return $self->{'device_settings'}->{$name} = shift;
        }
        else {
            return $self->{'device_settings'}->{$name};
        }
    }
    elsif (
        defined $self->{channels}
        ->{ $self->{device_settings}->{channel_default} }
        and $self->{channels}->{ $self->{device_settings}->{channel_default} }
        ->can($name) ) {
        return $self->{channels}
            ->{ $self->{device_settings}->{channel_default} }->$name(@_);
    }
    elsif (
        defined $self->{channels}
        ->{ $self->{device_settings}->{channel_default} }
        and exists $self->{channels}
        ->{ $self->{device_settings}->{channel_default} }->{$name} ) {
        return $self->{channels}
            ->{ $self->{device_settings}->{channel_default} }->{$name};
    }
    else {
        Lab::Exception::Warning->throw( error => "AUTOLOAD in "
                . __PACKAGE__
                . " couldn't access field '${name}'.\n" );
    }
}

sub device_cache {
    my $self  = shift;
    my $value = undef;

    #warn "device_cache got this:\n" . Dumper(@_) . "\n";

    if ( scalar(@_) == 0 )
    {    # empty parameters - return whole device_settings hash
        return $self->{'device_cache'};
    }
    elsif ( scalar(@_) == 1 )
    {    # one parm - either a scalar (key) or a hashref (try to merge)
        $value = shift;
    }
    elsif ( scalar(@_) > 1 && scalar(@_) % 2 == 0 )
    {    # even sized list - assume it's keys and values and try to merge it
        $value = {@_};
    }
    else {    # uneven sized list - don't know what to do with that one
        Lab::Exception::CorruptParameter->throw(
                  error => "Corrupt parameters given to "
                . __PACKAGE__
                . "::device_cache().\n" );
    }

    #warn "Keys present: \n" . Dumper($self->{device_settings}) . "\n";

    if ( ref($value) =~ /HASH/ ) { # it's a hash - merge into current settings
        for my $ext_key ( keys %{$value} ) {
            $self->{'device_cache'}->{$ext_key} = $value->{$ext_key}
                ;    # if( exists($self->device_cache()->{$ext_key}) );
        }
        return $self->{'device_cache'};
    }
    else {           # it's a key - return the corresponding value
        return $self->{'device_cache'}->{$value};
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::MultiChannelInstrument - Multi-channel instrument base class (deprecated)

=head1 VERSION

version 3.899

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2013       Christian Butschkow, Stefan Geissler
            2014       Andreas K. Huettel, Christian Butschkow
            2015       Andreas K. Huettel
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2019       Simon Reinhardt
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
