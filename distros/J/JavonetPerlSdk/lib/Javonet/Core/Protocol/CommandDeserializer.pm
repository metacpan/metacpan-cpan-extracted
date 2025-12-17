package Javonet::Core::Protocol::CommandDeserializer;
use strict;
use warnings;
use lib 'lib';
use aliased 'Javonet::Sdk::Core::PerlCommand' => 'PerlCommand';
use aliased 'Javonet::Sdk::Core::Type' => 'Type', qw(get_type);
use aliased 'Javonet::Core::Protocol::TypeDeserializer' => 'TypeDeserializer';

use Exporter qw(import);
our @EXPORT = qw(deserialize);

# Static deserialize method
sub deserialize {
    my ($class, $byte_array_ref) = @_;
    my @buffer = ref $byte_array_ref eq 'ARRAY' ? @$byte_array_ref : @$byte_array_ref;
    my $position = 11;  # Start position after header
    
    my $command = PerlCommand->new(
        runtime => $buffer[0],
        command_type => $buffer[10],
        payload => []
    );
    
    # Use position reference to simulate ref parameter
    my $position_ref = \$position;
    
    while ($position < @buffer) {
        $command = $command->AddArgToPayload(ReadObject(\@buffer, $position_ref));
    }
    
    return $command;
}

# ReadObject
sub ReadObject {
    my ($buffer_ref, $position_ref) = @_;
    my @buffer = @$buffer_ref;
    my $position = $$position_ref;
    
    my $type = $buffer[$position];
    
    if ($type == Type->get_type('Command')) {
        return ReadCommand($buffer_ref, $position_ref);
    }
    elsif ($type == Type->get_type('JavonetString')) {
        return ReadString($buffer_ref, $position_ref);
    }
    elsif ($type == Type->get_type('JavonetInteger')) {
        return ReadInt($buffer_ref, $position_ref);
    }
    elsif ($type == Type->get_type('JavonetBool')) {
        return ReadBool($buffer_ref, $position_ref);
    }
    elsif ($type == Type->get_type('JavonetFloat')) {
        return ReadFloat($buffer_ref, $position_ref);
    }
    elsif ($type == Type->get_type('JavonetByte')) {
        return ReadByte($buffer_ref, $position_ref);
    }
    elsif ($type == Type->get_type('JavonetChar')) {
        return ReadChar($buffer_ref, $position_ref);
    }
    elsif ($type == Type->get_type('JavonetLongLong')) {
        return ReadLong($buffer_ref, $position_ref);
    }
    elsif ($type == Type->get_type('JavonetDouble')) {
        return ReadDouble($buffer_ref, $position_ref);
    }
    elsif ($type == Type->get_type('JavonetUnsignedLongLong')) {
        return ReadULong($buffer_ref, $position_ref);
    }
    elsif ($type == Type->get_type('JavonetUnsignedInteger')) {
        return ReadUInt($buffer_ref, $position_ref);
    }
    elsif ($type == Type->get_type('JavonetNull')) {
        return ReadNull($buffer_ref, $position_ref);
    }
    else {
        die "NotImplementedException: Type not supported: $type";
    }
}

# ReadCommand
sub ReadCommand {
    my ($buffer_ref, $position_ref) = @_;
    my @buffer = @$buffer_ref;
    my $p = $$position_ref;
    
    # Read numberOfElements from bytes p+1 to p+4
    my @int_buffer = @buffer[$p + 1 .. $p + 4];
    my $numberOfElements = TypeDeserializer->deserializeInt(\@int_buffer);
    
    my $runtime = $buffer[$p + 5];
    my $commandType = $buffer[$p + 6];
    
    $$position_ref += 7;
    
    # Read all payload elements at once
    my @payload = ();
    for (my $i = 0; $i < $numberOfElements; $i++) {
        push @payload, ReadObject($buffer_ref, $position_ref);
    }
    
    return PerlCommand->new(
        runtime => $runtime,
        command_type => $commandType,
        payload => \@payload
    );
}

# ReadString
sub ReadString {
    my ($buffer_ref, $position_ref) = @_;
    my @buffer = @$buffer_ref;
    my $p = $$position_ref;
    
    my $mode = $buffer[$p + 1];
    my @int_buffer = @buffer[$p + 2 .. $p + 5];
    my $size = TypeDeserializer->deserializeInt(\@int_buffer);
    
    $$position_ref += 6;
    $p = $$position_ref;
    $$position_ref += $size;
    
    my @string_buffer = @buffer[$p .. $p + $size - 1];
    return TypeDeserializer->deserializeString($mode, \@string_buffer);
}

# ReadInt
sub ReadInt {
    my ($buffer_ref, $position_ref) = @_;
    my @buffer = @$buffer_ref;
    my $size = 4;
    
    $$position_ref += 2;
    my $p = $$position_ref;
    $$position_ref += $size;
    
    my @int_buffer = @buffer[$p .. $p + $size - 1];
    return TypeDeserializer->deserializeInt(\@int_buffer);
}

# ReadBool 
sub ReadBool {
    my ($buffer_ref, $position_ref) = @_;
    my @buffer = @$buffer_ref;
    my $size = 1;
    
    $$position_ref += 2;
    my $p = $$position_ref;
    $$position_ref += $size;
    
    return TypeDeserializer->deserializeBool($buffer[$p]);
}

# ReadFloat 
sub ReadFloat {
    my ($buffer_ref, $position_ref) = @_;
    my @buffer = @$buffer_ref;
    my $size = 4;
    
    $$position_ref += 2;
    my $p = $$position_ref;
    $$position_ref += $size;
    
    my @float_buffer = @buffer[$p .. $p + $size - 1];
    return TypeDeserializer->deserializeFloat(\@float_buffer);
}

# ReadByte 
sub ReadByte {
    my ($buffer_ref, $position_ref) = @_;
    my @buffer = @$buffer_ref;
    my $size = 1;
    
    $$position_ref += 2;
    my $p = $$position_ref;
    $$position_ref += $size;
    
    return TypeDeserializer->deserializeByte($buffer[$p]);
}

# ReadChar
sub ReadChar {
    my ($buffer_ref, $position_ref) = @_;
    my @buffer = @$buffer_ref;
    my $size = 1;
    
    $$position_ref += 2;
    my $p = $$position_ref;
    $$position_ref += $size;
    
    return TypeDeserializer->deserializeChar($buffer[$p]);
}

# ReadLong 
sub ReadLong {
    my ($buffer_ref, $position_ref) = @_;
    my @buffer = @$buffer_ref;
    my $size = 8;
    
    $$position_ref += 2;
    my $p = $$position_ref;
    $$position_ref += $size;
    
    my @longlong_buffer = @buffer[$p .. $p + $size - 1];
    return TypeDeserializer->deserializeLongLong(\@longlong_buffer);
}

# ReadDouble 
sub ReadDouble {
    my ($buffer_ref, $position_ref) = @_;
    my @buffer = @$buffer_ref;
    my $size = 8;
    
    $$position_ref += 2;
    my $p = $$position_ref;
    $$position_ref += $size;
    
    my @double_buffer = @buffer[$p .. $p + $size - 1];
    return TypeDeserializer->deserializeDouble(\@double_buffer);
}

# ReadULong 
sub ReadULong {
    my ($buffer_ref, $position_ref) = @_;
    my @buffer = @$buffer_ref;
    my $size = 8;
    
    $$position_ref += 2;
    my $p = $$position_ref;
    $$position_ref += $size;
    
    my @ulonglong_buffer = @buffer[$p .. $p + $size - 1];
    return TypeDeserializer->deserializeULongLong(\@ulonglong_buffer);
}

# ReadUInt
sub ReadUInt {
    my ($buffer_ref, $position_ref) = @_;
    my @buffer = @$buffer_ref;
    my $size = 4;
    
    $$position_ref += 2;
    my $p = $$position_ref;
    $$position_ref += $size;
    
    my @uint_buffer = @buffer[$p .. $p + $size - 1];
    return TypeDeserializer->deserializeUInt(\@uint_buffer);
}

# ReadNull 
sub ReadNull {
    my ($buffer_ref, $position_ref) = @_;
    my @buffer = @$buffer_ref;
    my $size = 1;
    
    $$position_ref += 2;
    my $p = $$position_ref;
    $$position_ref += $size;
    
    # Note: deserializeUndef doesn't use the buffer, but we match C# structure
    return TypeDeserializer->deserializeUndef();
}

1;