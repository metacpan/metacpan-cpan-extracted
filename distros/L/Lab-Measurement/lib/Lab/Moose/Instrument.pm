package Lab::Moose::Instrument;
$Lab::Moose::Instrument::VERSION = '3.682';
#ABSTRACT: Base class for instrument drivers

use 5.010;
use Moose;
use MooseX::StrictConstructor;
use Moose::Util::TypeConstraints qw(enum duck_type);
use MooseX::Params::Validate;
use Module::Load 'load';
use Data::Dumper;
use Exporter 'import';
use Carp;

our @EXPORT_OK = qw(
    timeout_param
    read_length_param
    channel_param
    precision_param
    getter_params
    setter_params
    validated_getter
    validated_setter
    validated_no_param_setter
    validated_channel_getter
    validated_channel_setter
);

# do not make imported functions available as methods.
use namespace::autoclean

    # Need this for Exporter.
    -except => 'import',
    -also   => [@EXPORT_OK];

has connection_type => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_connection_type',
);

has connection_options => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

has connection => (
    is  => 'ro',
    isa => duck_type( [qw/Write Read Query Clear/] ),

    handles => {
        write        => 'Write',
        binary_read  => 'Read',
        binary_query => 'Query',
        clear        => 'Clear',
    },
    writer    => '_connection',
    predicate => 'has_connection',
);

# Can be subclassed in drivers.
sub default_connection_options {
    return {
        any          => {},
        VXI11        => {},
        USB          => {},
        LinuxGPIB    => {},
        'VISA::GPIB' => {},
        'VISA::USB'  => {},
        Socket       => {},
        Zhinst       => {},

    };
}

sub _default_connection_options {
    my $self = shift;

    my $options = $self->default_connection_options();
    $options = $options->{ $self->connection_type() };
    if ($options) {
        return $options;
    }
    else {
        return {};
    }
}

sub BUILD {
    my $self = shift;
    my $error_msg
        = "Give either ready connection or 'connection_type' argument to instrument constructor.";
    if ( $self->has_connection ) {
        if ( $self->has_connection_type ) {
            croak $error_msg ;
        }
        return;
    }
    if ( not $self->has_connection_type ) {
        croak $error_msg;
    }
    my $connection_type = $self->connection_type();
    $connection_type = "Lab::Moose::Connection::$connection_type";

    my $connection_options = {
        %{ $self->_default_connection_options() },
        %{ $self->connection_options() }
    };
    load $connection_type;
    my $connection = $connection_type->new( %{$connection_options} );
    $self->_connection($connection);
}

with 'Lab::Moose::Instrument::Log';



my $ieee488_2_white_space_character = qr/[\x{00}-\x{09}\x{0b}-\x{20}]/;

sub _trim_pmt {
    my ($retval) = pos_validated_list(
        \@_,
        { isa => 'Str' }
    );

    $retval =~ s/${ieee488_2_white_space_character}*\n?\Z//;

    return $retval;
}

sub read {
    my $self = shift;
    return _trim_pmt( $self->binary_read(@_) );
}

sub query {
    my $self = shift;
    return _trim_pmt( $self->binary_query(@_) );
}


sub timeout_param {
    return ( timeout => { isa => 'Num', optional => 1 } );
}


sub read_length_param {
    return ( read_length => { isa => 'Int', optional => 1 } );
}


sub channel_param {
    return ( channel => { isa => 'Int', optional => 1 } );
}


sub precision_param {
    return ( precision =>
            { isa => enum( [qw/single double/] ), default => 'single' } );
}


sub getter_params {
    return ( timeout_param(), read_length_param() );
}


sub setter_params {
    return ( timeout_param() );
}

sub validated_hash_no_cache {
    return validated_hash( @_, MX_PARAMS_VALIDATE_NO_CACHE => 1 );
}


sub validated_getter {
    my $args_ref                  = shift;
    my %additional_parameter_spec = @_;
    return validated_hash_no_cache(
        $args_ref, getter_params(),
        %additional_parameter_spec
    );
}


sub validated_setter {
    my $args_ref                  = shift;
    my %additional_parameter_spec = @_;
    my ( $self, %args ) = validated_hash_no_cache(
        $args_ref, setter_params(),
        value => { isa => 'Str' }, %additional_parameter_spec
    );
    my $value = delete $args{value};
    return ( $self, $value, %args );
}


sub validated_no_param_setter {
    my $args_ref                  = shift;
    my %additional_parameter_spec = @_;
    my ( $self, %args ) = validated_hash_no_cache(
        $args_ref, setter_params(),
        %additional_parameter_spec
    );
    return ( $self, %args );
}

sub get_default_channel {
    my $self = shift;
    if ( $self->can('instrument_nselect') ) {
        my $channel = $self->cached_instrument_nselect();
        return $channel == 1 ? '' : $channel;
    }
    else {
        return '';
    }
}


sub validated_channel_getter {
    my $args_ref                  = shift;
    my %additional_parameter_spec = @_;
    my ( $self, %args ) = validated_hash_no_cache(
        $args_ref,       getter_params(),
        channel_param(), %additional_parameter_spec
    );

    my $channel = delete $args{channel};
    if ( not defined $channel ) {
        $channel = $self->get_default_channel();
    }
    return ( $self, $channel, %args );
}


sub validated_channel_setter {
    my $args_ref                  = shift;
    my %additional_parameter_spec = @_;
    my ( $self, %args ) = validated_hash_no_cache(
        $args_ref, getter_params(), channel_param(),
        value => { isa => 'Str' },
        %additional_parameter_spec,
    );
    my $channel = delete $args{channel};
    if ( not defined $channel ) {
        $channel = $self->get_default_channel();
    }
    my $value = delete $args{value};
    return ( $self, $channel, $value, %args );
}

__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument - Base class for instrument drivers

=head1 VERSION

version 3.682

=head1 SYNOPSIS

A complete device driver based on Lab::Moose::Instrument:

 package Lab::Moose::Instrument::FooBar;
 use Moose;
 
 use Lab::Moose::Instrument qw/validated_getter validated_setter/;

 use namespace::autoclean;
 
 extends 'Lab::Moose::Instrument';

 sub get_foo {
     my ($self, %args) = validated_getter(\@_);
     return $self->query(command => "Foo?", %args);
 }
 
 sub set_foo {
     my ($self, $value, %args) = validated_setter(\@_);
     return $self->write(command => "Foo $value", %args);
 }

 __PACKAGE__->meta->make_immutable();

=head1 DESCRIPTION

The Lab::Moose::Instrument module is a thin wrapper around a connection object.
All other Lab::Moose::Instrument::* drivers inherit from this module.

=head1 METHODS

=head2 new

The constructor requires a connection object, which provides
C<Read>, C<Write>, C<Query> and C<Clear> methods. You can provide any object,
which supports these methods.

=head2 write

 $instrument->write(command => '*RST', timeout => 10);

Call the connection's C<Write> method. The timeout parameter is optional.

=head2 binary_read

 my $data = $instrument->binary_read(timeout => 10);

Call the connection's C<Read> method. The timeout parameter is optional.

=head2 read

Like C<binary_read>, but trim trailing whitespace and newline from the result.

More precisely, this removes the I<PROGRAM MESSAGE TERMINATOR> (IEEE 488.2
section 7.5).

=head2 binary_query

 my $data = $instrument->binary_query(command => '*IDN?', timeout => 10)

Call the connection's C<Query> method. The timeout parameter is optional.

=head2 query

Like C<binary_query>, but trim trailing whitespace and newline from the result.

More precisely, this removes the I<PROGRAM MESSAGE TERMINATOR> (IEEE 488.2
section 7.5).

=head2 clear

 $instrument->clear();

Call the connection's C<Clear> method.

=head1 Functions

The following functions standardise and simplify the use of
L<MooseX::Params::Validate> in instrument drivers. They are only exported on
request.

=head2 timeout_param

Return mandatory validation parameter for timeout.

=head2 read_length_param

Return mandatory validation parameter for read_length.

=head2 channel_param

Return optional validation parameter for channel. A given argument has to be an
'Int'. The default value is the empty string ''.

=head2 precision_param

Return optional validation parameter for floating point precision. The
parameter has to be either 'single' (default) or 'double'.

=head2 getter_params

Return list of validation parameters which shell be used in all query
operations, eg. timeout, ....

=head2 setter_params

Return list of validation parameters which shell be used in all write
operations, eg. timeout, ....

=head2 validated_getter

 my ($self, %args) = validated_getter(\@_, %additional_parameter_spec);

Call C<validated_hash> with the getter_params.

=head2 validated_setter

 my ($self, $value, %args) = validated_setter(\@_, %additional_parameter_spec);

Call C<validated_hash> with the C<setter_params> and a mandatory 'value'
argument, which must be of 'Str' type.

=head2 validated_no_param_setter

 my ($self, %args) = validated_no_param_setter(\@_, %additional_parameter_spec);

Like C<validated_setter> without the 'value' argument.

=head2 validated_channel_getter

 my ($self, $channel, %args) = validated_channel_getter(\@_);

Like C<validated_getter> with an additional C<channel_param> argument. If the
no channel argument is given, try to call
C<$self->cached_instrument_nselect>. If this method is not available, return
the empty string for the channel.

=head2 validated_channel_setter

 my ($self, $channel, $value, %args) = validated_channel_setter(\@_);

Analog to C<validated_channel_getter>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel, Simon Reinhardt
            2018       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
