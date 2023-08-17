package Lab::Instrument::TemperatureDiode;
#ABSTRACT: ?????
$Lab::Instrument::TemperatureDiode::VERSION = '3.881';
use v5.20;

use strict;
use Math::Complex;
use Lab::Exception;
use Scalar::Util qw(weaken);
use Carp qw(croak cluck);
use Data::Dumper;
our $AUTOLOAD;

our %fields = (
    instrument => undef,

    device_cache => {
        id => undef,
    },

    device_cache_order => ['id'],
);

our @ISA = ();

sub new {
    my $proto  = shift;
    my $class  = ref($proto) || $proto;
    my $config = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $config = shift;
    }    # try to be flexible about options as hash/hashref
    else { $config = {@_} }
    my $self = {};
    bless( $self, $class );
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    while ( my ( $k, $v ) = each %{$config} ) {
        $self->{$k} = $v;
    }

    if ( not defined $self->instrument() ) {
        Lab::Exception::Error->throw( error => $self->get_id()
                . ": No intrument for temperature measurment defined!" );
    }
    elsif ( not ref( $self->instrument() ) =~ /^(Lab::Instrument)/ ) {
        Lab::Exception::Error->throw( error => $self->get_id()
                . ": Object for temperature measurement is not an instrument!"
        );
    }

    return $self;
}

sub _construct {    # _construct(__PACKAGE__);
    ( my $self, my $package ) = ( shift, shift );
    my $class  = ref($self);
    my $fields = undef;
    {
        no strict 'refs';
        $fields = *${ \( $package . '::fields' ) }{HASH};
    }
    my $twin = undef;

    foreach my $element ( keys %{$fields} ) {
        $self->{_permitted}->{$element} = $fields->{$element};
    }
    @{$self}{ keys %{$fields} } = values %{$fields};
}

# converts given measurementvalue to a temperature in Kelvin

sub config {    # $value = self->config($key);
    ( my $self, my $key ) = ( shift, shift );

    if ( !defined $key ) {
        return $self->{'config'};
    }
    elsif ( ref($key) =~ /HASH/ ) {
        return $self->{'config'} = $key;
    }
    else {
        return $self->{'config'}->{$key};
    }
}

sub set_id {
    my $self = shift;
    my ($id) = $self->_check_args( \@_, ['id'] );
    $self->{'device_cache'}->{'id'} = $id;

}

sub get_id {
    my $self = shift;
    return $self->{'device_cache'}->{'id'};
}

sub get_value {
    my $self = shift;

    return $self->get_T(@_);
}

sub get_T {
    my $self    = shift;
    my $options = undef;
    if   ( ref $_[0] eq 'HASH' ) { $options = shift }
    else                         { $options = {@_} }

    if ( $options->{read_mode} eq 'cache'
        and defined $self->{'device_cache'}->{'T'} ) {
        return $self->{'device_cache'}->{'T'};
    }

    my $value = $self->instrument()->get_value($options);
    if ( defined $value ) {
        return $self->device_cache()->{T} = $self->convert2Kelvin($value);
    }
    else {
        return undef;
    }
}

sub convert2Kelvin {
    my $self = shift;
    return;
}

sub _check_args {
    my $self   = shift;
    my $args   = shift;
    my $params = shift;

    my $arguments;

    my $i          = 0;
    my $tempo_hash = {};

    foreach my $arg ( @{$args} ) {
        if ( ref($arg) ne "HASH" ) {
            if ( defined @{$params}[$i] ) {
                $tempo_hash->{ @{$params}[$i] } = $arg;

            }
            $i++;
        }
        else {
            %{$arguments} = ( %{$tempo_hash}, %{ @{$args}[$i] } );
            last;
        }
    }

    if ( not defined $arguments ) {
        $arguments = $tempo_hash;
    }

    my @return_args = ();

    foreach my $param ( @{$params} ) {

        if ( exists $arguments->{$param} ) {
            push( @return_args, $arguments->{$param} );
            delete $arguments->{$param};
        }
        else {
            push( @return_args, undef );
        }
    }

    foreach my $param ( 'from_device', 'from_cache'
        ) # Delete Standard option parameters from $arguments hash if not defined in device driver function
    {
        if ( exists $arguments->{$param} ) {
            delete $arguments->{$param};
        }
    }

    if ( scalar( keys %{$arguments} ) > 0 ) {
        my $errmess = "Unknown parameter given in $self :";
        while ( my ( $k, $v ) = each %{$arguments} ) {
            $errmess .= $k . " => " . $v . "\t";
        }
        print Lab::Exception::Warning->new( error => $errmess );
    }

    return @return_args;
}

sub AUTOLOAD {

    my $self = shift;
    my $type = ref($self) or croak "$self is not an object";

    my $name = $AUTOLOAD;
    $name =~ s/.*://;    # strip fully qualified portion

    unless ( exists $self->{_permitted}->{$name} ) {
        cluck(    "AUTOLOAD in "
                . __PACKAGE__
                . " couldn't access field '${name}'.\n" );
        Lab::Exception::Error->throw( error => "AUTOLOAD in "
                . __PACKAGE__
                . " couldn't access field '${name}'.\n" );
    }

    if (@_) {
        return $self->{$name} = shift;
    }
    else {
        return $self->{$name};
    }
}

# needed so AUTOLOAD doesn't try to call DESTROY on cleanup and prevent the inherited DESTROY
sub DESTROY {
    my $self = shift;
    $self->SUPER::DESTROY if $self->can("SUPER::DESTROY");
}

# defined sensors

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Instrument::TemperatureDiode - ?????

=head1 VERSION

version 3.881

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2013       Christian Butschkow
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
