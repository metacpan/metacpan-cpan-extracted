package Javonet::Core::Protocol::TypeSerializer;
use strict;
use warnings;
use Encode;
use lib 'lib';

use Scalar::Util::Numeric qw(isint);
use autobox::universal qw(type);
use aliased 'Javonet::Sdk::Core::Type' => 'Type';
use aliased 'Javonet::Sdk::Core::StringEncodingMode' => 'StringEncodingMode';

use Exporter qw(import);
our @EXPORT = qw(serializeCommand serializePrimitive serializeString serializeInt serializeBool serializeFloat serializeByte serializeChar serializeLongLong serializeDouble serializeUllong serializeUint serializeUndef);

sub serializePrimitive {
    my ($class, $payload_item) = @_;
    if(!defined $payload_item) {
        return serializeUndef($class);
    }

    if(isint($payload_item)){
        return serializeInt($class, $payload_item);
    }
    if(type($payload_item) eq "FLOAT"){
        return serializeDouble($class, $payload_item);
    }
    else{
        return serializeString($class, $payload_item);
    }
}

sub serializeCommand {
    my ($class, $command) = @_;
    my $length = @{$command->{payload}};
    my @length =  unpack "C*", pack "V",  $length;
    my @initial_array =(Type->get_type('Command'), @length, $command->{runtime},$command->{command_type});

    return @initial_array;
}

sub serializeString {
    my ($class, $string) = @_;
    my @serialized_string = unpack("C*", Encode::encode("utf8", $string));
    my $length = @serialized_string;

    my @length =  unpack "C*", pack "V",  $length;
    my @initial_array =(Type->get_type('JavonetString'),
        StringEncodingMode->get_string_encoding_mode('UTF8'),
        @length, @serialized_string);

    return @initial_array;
}

sub serializeInt {
    my ($class, $int_value) = @_;
    my $length = 4;
    my @initial_array = (Type->get_type('JavonetInteger'), $length);
    my @bytes =  unpack "C*", pack "i",  $int_value;
    return (@initial_array, @bytes);
}

sub serializeBool {
    my ($class, $bool_value) = @_;
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
    my ($class, $float_value) = @_;
    my $length = 4;
    my @initial_array = (Type->get_type('JavonetFloat'), $length);
    my @bytes = unpack "C*", pack "f",  $float_value;
    return (@initial_array, @bytes);
}

sub serializeByte {
    my ($class, $byte_value) = @_;
    my $length = 1;
    my @initial_array = (Type->get_type('JavonetByte'), $length);
    my @bytes =  ($byte_value);
    return (@initial_array, @bytes);
}

sub serializeChar {
    my ($class, $char_value) = @_;
    my $length = 1;
    my @initial_array = (Type->get_type('JavonetChar'), $length);
    my @bytes =  ($char_value);
    return (@initial_array, @bytes);
}

sub serializeLongLong {
    my ($class, $longlong_value) = @_;
    my $length = 8;
    my @initial_array = (Type->get_type('JavonetLongLong'), $length);
    my @bytes =  unpack "C*", pack "q",  $longlong_value;
    return (@initial_array, @bytes);
}

sub serializeDouble {
    my ($class, $double_value) = @_;
    my $length = 8;
    my @initial_array = (Type->get_type('JavonetDouble'), $length);
    my @bytes =  unpack "C*", pack "d",  $double_value;
    return (@initial_array, @bytes);
}

sub serializeUllong {
    my ($class, $ullong_value) = @_;
    my $length = 8;
    my @initial_array = (Type->get_type('JavonetUnsignedLongLong'), $length);
    my @bytes =  unpack "C*", pack "Q",  $ullong_value;
    return (@initial_array, @bytes);
}

sub serializeUint {
    my ($class, $uint_value) = @_;
    my $length = 4;
    my @initial_array = (Type->get_type('JavonetUnsignedInteger'), $length);
    my @bytes =  unpack "C*", pack "V",  $uint_value;
    return (@initial_array, @bytes);
}

sub serializeUndef {
    my ($class) = @_;
    my $length = 1;
    my @initial_array = (Type->get_type('JavonetNull'), $length);
    my @bytes =  (0);
    return (@initial_array, @bytes);
}


1;