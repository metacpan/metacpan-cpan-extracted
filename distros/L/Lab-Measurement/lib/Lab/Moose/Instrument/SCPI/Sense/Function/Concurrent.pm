package Lab::Moose::Instrument::SCPI::Sense::Function::Concurrent;
$Lab::Moose::Instrument::SCPI::Sense::Function::Concurrent::VERSION = '3.682';
#ABSTRACT: Role for the SCPI SENSe:FUNCtion subsystem with support for concurrent sense

use Moose::Role;
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument
    qw/validated_channel_getter validated_channel_setter/;
use MooseX::Params::Validate;
use Carp;

use namespace::autoclean;

excludes 'Lab::Moose::Instrument::SCPI::Sense::Function';


cache sense_function_concurrent =>
    ( getter => 'sense_function_concurrent_query' );

sub sense_function_concurrent_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    my $value = $self->query( command => "SENS${channel}:FUNC:CONC?", %args );
    return $self->cached_sense_function_concurrent($value);
}

sub sense_function_concurrent {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => 'Bool' }
    );

    $self->write( command => "SENS${channel}:FUNC:CONC $value", %args );
    return $self->cached_sense_function_concurrent($value);
}


cache sense_function => ( getter => 'sense_function_query' );

sub sense_function {
    my ( $self, $channel, $value, %args ) = validated_channel_setter( \@_ );
    return $self->cached_sense_function($value);
}


sub sense_function_query {

    # overwrite in instrument driver to get different default.
    return 'CURR';
}


cache sense_function_on =>
    ( isa => 'ArrayRef[Str]', getter => 'sense_function_on_query' );

sub sense_function_on {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => 'ArrayRef[Str]' }
    );
    my @values = @{$value};
    if ( not $self->cached_sense_function_concurrent ) {
        if ( @values != 1 ) {
            croak
                "sense_function_on without concurrent sense only accepts single function";
        }
    }
    @values = map {"'$_'"} @values;
    my $param = join( ',', @values );

    $self->write( command => "SENS${channel}:FUNC:ON $param", %args );
    return $self->sense_function_on_query(%args);
}

sub sense_function_on_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    my $value = $self->query( command => "SENS${channel}:FUNC:ON?", %args );
    $value =~ s/["']//g;
    my @values = split( ',', $value );
    $self->cached_sense_function_on( [@values] );
    return [@values];
}


sub sense_function_off {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(
        \@_,
        value => { isa => 'ArrayRef[Str]' }
    );
    my @values = @{$value};
    @values = map {"'$_'"} @values;
    my $param = join( ',', @values );

    $self->write( command => "SENS${channel}:FUNC:OFF $param", %args );

    # update cached_sense_function_on
    $self->sense_function_on_query(%args);
}

sub sense_function_off_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    my $value = $self->query( command => "SENS${channel}:FUNC:OFF?", %args );
    $value =~ s/["']//g;
    my @values = split( ',', $value );
    return [@values];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::SCPI::Sense::Function::Concurrent - Role for the SCPI SENSe:FUNCtion subsystem with support for concurrent sense

=head1 VERSION

version 3.682

=head1 DESCRIPTION

This role is intended for instruments which support multiple concurrent sense
functions. For example, the Keithley2400 or KeysightB2901A source/measure units
which can measure voltage and current simultaneously.

The set sense function is used by other SENSE: roles, like SENSE:NPLC. For
example, let us enable concurrent measurement of voltage and current and set the integration time for both 
measured parameters:

 $source->sense_function_concurrent(value => 1);
 $source->sense_function_on(value => ['VOLT', 'CURR']); 

 # Set NPLC for current measurement
 $source->sense_function(value => 'CURR');
 $source->sense_nplc(value => 10);

 # Set NPLC for voltage measurement
 $source->sense_function(value => 'VOLT');
 $source->sense_nplc(value => 10); 

=head1 METHODS

=head2 sense_function_concurrent_query/sense_function_concurrent

Set/Get concurrent property of sensor block. Allowed values: C<0> or C<1>.

=head2 sense_function

 $source->sense_function(value => $function);

Unlike the C<sense_function> method from the
L<Lab::Moose::Instrument::SCPI::Sense::Function> method, does not send a command, only used by other SENSE: roles, like SENSE:NPLC

=head2 cached_sense_function/sense_function_query

C<sense_function_query> is only used to initialize the cache.

=head2 sense_function_on

 $source->sense_function_on(value => ['CURR', 'VOLT']);

Enable parameters which should be measured. 

=head2 sense_function_on_query

 my @params = @{$source->sense_function_on_query()};

Query list of parameters which are measured.

=head2 sense_function_off_query/sense_function_off

 $source->sense_function_off(value => ['CURR']);

Query/set list of parameters which should not be measured.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2018       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
