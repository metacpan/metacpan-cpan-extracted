package Javonet::Core::Protocol::TypeSerializer;
use strict;
use warnings;
use Moose;
use Encode;
use lib 'lib';

use Scalar::Util::Numeric qw(isint);
use autobox::universal qw(type);
use aliased 'Javonet::Sdk::Core::Type' => 'Type', qw(get_type);
use aliased 'Javonet::Sdk::Core::StringEncodingMode' => 'StringEncodingMode', qw(get_string_encoding_mode);

sub serialize_primitive {
    my $self = $_[0];
    my $payload_item = $_[1];
    if(!defined $payload_item) {
        return serializeUndef($self);
    }

    if(isint($payload_item)){
        return serializeInt($self, $payload_item);
    }
    if(type($payload_item) eq "FLOAT"){
        return serializeDouble($self, $payload_item);
    }
    else{
        return serializeString($self, $payload_item);
    }
}

sub serializeCommand {
    my $self = $_[0];
    my $command = $_[1];
    my $length = @{$command->{payload}};
    my @length =  unpack "C*", pack "V",  $length;
    my @initial_array =(Type->get_type('Command'), @length, $command->{runtime},$command->{command_type});

    return @initial_array;
}

sub serializeString {
    my $self = $_[0];
    my $string = $_[1];
    my @serialized_string = unpack("C*", Encode::encode("utf8", $string));
    my $length = @serialized_string;

    my @length =  unpack "C*", pack "V",  $length;
    my @initial_array =(Type->get_type('JavonetString'),
        StringEncodingMode->get_string_encoding_mode('UTF8'),
        @length, @serialized_string);

    return @initial_array;
}

sub serializeInt {
    my ($self, $int_value) = @_;
    my $length = 4;
    my @initial_array = (Type->get_type('JavonetInteger'), $length);
    my @bytes =  unpack "C*", pack "i",  $int_value;
    return (@initial_array, @bytes);
}

sub serializeBool {
    my ($self, $bool_value) = @_;
    my $length = 1;
    my @initial_array = (Type->get_type('JavonetBool'), $length);
    my @bytes;
    if ($bool_value) {
        @bytes =  ($bool_value);
    }
    else{
        @bytes =  ($bool_value);
    }

    return (@initial_array, @bytes);
}

sub serializeFloat {
    my ($self, $float_value) = @_;
    my $length = 4;
    my @initial_array = (Type->get_type('JavonetFloat'), $length);
    my @bytes = unpack "C*", pack "f",  $float_value;
    return (@initial_array, @bytes);
}

sub serializeByte {
    my ($self, $byte_value) = @_;
    my $length = 1;
    my @initial_array = (Type->get_type('JavonetByte'), $length);
    my @bytes =  ($byte_value);
    return (@initial_array, @bytes);
}

sub serializeChar {
    my ($self, $char_value) = @_;
    my $length = 1;
    my @initial_array = (Type->get_type('JavonetChar'), $length);
    my @bytes =  ($char_value);
    return (@initial_array, @bytes);
}

sub serializeLongLong {
    my ($self, $longlong_value) = @_;
    my $length = 8;
    my @initial_array = (Type->get_type('JavonetLongLong'), $length);
    my @bytes =  unpack "C*", pack "q",  $longlong_value;
    return (@initial_array, @bytes);
}

sub serializeDouble {
    my ($self, $double_value) = @_;
    my $length = 8;
    my @initial_array = (Type->get_type('JavonetDouble'), $length);
    my @bytes =  unpack "C*", pack "d",  $double_value;
    return (@initial_array, @bytes);
}

sub serializeUllong {
    my ($self, $ullong_value) = @_;
    my $length = 8;
    my @initial_array = (Type->get_type('JavonetUnsignedLongLong'), $length);
    my @bytes =  unpack "C*", pack "Q",  $ullong_value;
    return (@initial_array, @bytes);
}

sub serializeUint {
    my ($self, $uint_value) = @_;
    my $length = 4;
    my @initial_array = (Type->get_type('JavonetUnsignedInteger'), $length);
    my @bytes =  unpack "C*", pack "V",  $uint_value;
    return (@initial_array, @bytes);
}

sub serializeUndef {
    my $length = 1;
    my @initial_array = (Type->get_type('JavonetNull'), $length);
    my @bytes =  (0);
    return (@initial_array, @bytes);
}


1;