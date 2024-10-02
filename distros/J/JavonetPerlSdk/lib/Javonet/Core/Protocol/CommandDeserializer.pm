package Javonet::Core::Protocol::CommandDeserializer;
use strict;
use warnings;
use Moose;
use lib 'lib';
use aliased 'Javonet::Sdk::Core::PerlCommand' => 'PerlCommand';
use aliased 'Javonet::Sdk::Core::Type' => 'Type', qw(get_type);
use aliased 'Javonet::Core::Protocol::TypeDeserializer' => 'TypeDeserializer', qw(deserializeInt deserializeString deserializeDouble deserializeFloat);


our $position = 0;
our @buffer = [];
our $command;

sub new {
    my ($self, $array_ref) = @_;
    @buffer = @$array_ref;
    $command = PerlCommand->new(runtime =>$buffer[0],
        command_type => $buffer[10], payload=>[]);
    $position = 11;
    return $self;
}

sub isAtEnd {
    my $length = @buffer;
    return $position == $length;
}

sub decode {
    while (!isAtEnd()) {
        $command = $command->addArgumentToPayload([readObject($buffer[$position])]);
    }
    return $command;
}

sub readObject {
    my $type_num = $_[0];
    if($type_num == Type->get_type('Command')){
        return readCommand();
    }
    elsif($type_num == Type->get_type('JavonetString')){
        return readString();
    }
    elsif($type_num == Type->get_type('JavonetInteger')){
        return readInt();
    }
    elsif($type_num == Type->get_type('JavonetBool')){
        return readBool();
    }
    elsif($type_num == Type->get_type('JavonetFloat')){
        return readFloat();
    }
    elsif($type_num == Type->get_type('JavonetByte')){
        return readByte();
    }
    elsif($type_num == Type->get_type('JavonetChar')){
        return readChar();
    }
    elsif($type_num == Type->get_type('JavonetLongLong')){
        return readLongLong();
    }
    elsif($type_num == Type->get_type('JavonetDouble')){
        return readDouble();
    }
    elsif($type_num == Type->get_type('JavonetUnsignedLongLong')){
        return readUnsignedLongLong();
    }
    elsif($type_num == Type->get_type('JavonetUnsignedInteger')){
        return readUnsignedInt();
    }
    elsif($type_num == Type->get_type('JavonetNull')){
        return readUndef();
    }
    else{
        die "Type is not supported: $type_num";
    }
}

sub readCommand{
    my $p = $position;
    my @int_buffer = @buffer[$p + 1 .. $p + 4];
    my $numberOfArgumentInPayload = TypeDeserializer->deserializeInt(\@int_buffer);
    my $runtime = $buffer[$p + 5];
    my $commandType = $buffer[$p + 6];

    $position += 7;
    my $returnCommand = PerlCommand->new(runtime => $runtime, command_type => $commandType);
    return readCommandRecursively($numberOfArgumentInPayload, $returnCommand);
}

sub readCommandRecursively {
    my $numberOfArgumentInPayloadLeft = $_[0];
    my $cmd = $_[1];

    if ($numberOfArgumentInPayloadLeft == 0) {
        return $cmd;
    }
    else {
        my $p = $position;
        my @int_buffer = @buffer[$p + 1 .. $p + 4];
        my $argSize = TypeDeserializer->deserializeInt(\@int_buffer);
        $cmd = $cmd->addArgumentToPayload([readObject($buffer[$p])]);
        return readCommandRecursively($numberOfArgumentInPayloadLeft - 1, $cmd);
    }
}

sub readString{
    my $p = $position;
    my $string_encoding_mode = $buffer[$p + 1];
    my @int_buffer = @buffer[$p + 2 .. $p + 5];
    my $size = TypeDeserializer->deserializeInt(\@int_buffer);
    $position += 6;
    $p = $position;
    $position += $size;
    my @string_buffer = @buffer[$p .. $p + $size - 1];
    my $decodedString = TypeDeserializer->deserializeString($string_encoding_mode, \@string_buffer);

    return $decodedString
}

sub readInt{
    $position += 2;
    my $p = $position;
    $position += 4;
    my @int_buffer = @buffer[$p .. $p + 3];
    return TypeDeserializer->deserializeInt(\@int_buffer);
}

sub readBool{
    $position += 2;
    my $p = $position;
    $position += 1;
    my $bool_buffer = $buffer[$p];
    return TypeDeserializer->deserializeBool($bool_buffer);
}

sub readFloat{
    $position += 2;
    my $p = $position;
    $position += 4;
    my @float_buffer = @buffer[$p .. $p + 3];
    return TypeDeserializer->deserializeFloat(\@float_buffer);
}

sub readByte {
    $position += 2;
    my $p = $position;
    $position += 1;
    my $byte_buffer = $buffer[$p];
    return TypeDeserializer->deserializeByte($byte_buffer);
}

sub readChar {
    $position += 2;
    my $p = $position;
    $position += 1;
    my $char_buffer = $buffer[$p];
    return TypeDeserializer->deserializeChar($char_buffer);
}

sub readLongLong {
    $position += 2;
    my $p = $position;
    $position += 8;
    my @longlong_buffer = @buffer[$p .. $p + 7];
    return TypeDeserializer->deserializeLongLong(\@longlong_buffer);
}

sub readDouble{
    $position += 2;
    my $p = $position;
    $position += 8;
    my @double_buffer = @buffer[$p .. $p + 7];
    return TypeDeserializer->deserializeDouble(\@double_buffer);
}

sub readUnsignedLongLong {
    $position += 2;
    my $p = $position;
    $position += 8;
    my @ulonglong_buffer = @buffer[$p .. $p + 7];
    return TypeDeserializer->deserializeULongLong(\@ulonglong_buffer);
}

sub readUnsignedInt {
    $position += 2;
    my $p = $position;
    $position += 4;
    my @uint_buffer = @buffer[$p .. $p + 3];
    return TypeDeserializer->deserializeUInt(\@uint_buffer);
}

sub readUndef {
    $position += 2;
    my $p = $position;
    $position += 1;
    my $undef_buffer = $buffer[$p];
    return TypeDeserializer->deserializeUndef($undef_buffer);
}


no Moose;
1;