package Javonet::Core::Protocol::CommandDeserializer;
use strict;
use warnings;
use lib 'lib';
use aliased 'Javonet::Sdk::Core::PerlCommand' => 'PerlCommand';
use aliased 'Javonet::Sdk::Core::Type' => 'Type', qw(get_type);
use aliased 'Javonet::Core::Protocol::TypeDeserializer' => 'TypeDeserializer';

use Exporter qw(import);
our @EXPORT = qw(deserialize);

# Static deserialize method - takes byte array and returns Command
sub deserialize {
    my ($class, $byte_array_ref) = @_;
    my @buffer = ref $byte_array_ref eq 'ARRAY' ? @$byte_array_ref : @$byte_array_ref;
    my $position = 11;  # Start position after header
    my $command = PerlCommand->new(
        runtime => $buffer[0],
        command_type => $buffer[10],
        payload => []
    );
    
    # Helper function to check if at end
    my $isAtEnd = sub {
        my $length = @buffer;
        return $position == $length;
    };
    
    # Define read functions first (they will be referenced by readObject and readCommand)
    my $readString = sub {
        my $p = $position;
        my $string_encoding_mode = $buffer[$p + 1];
        my @int_buffer = @buffer[$p + 2 .. $p + 5];
        my $size = TypeDeserializer->deserializeInt(\@int_buffer);
        $position += 6;
        $p = $position;
        $position += $size;
        my @string_buffer = @buffer[$p .. $p + $size - 1];
        my $decodedString = TypeDeserializer->deserializeString($string_encoding_mode, \@string_buffer);
        return $decodedString;
    };
    
    my $readInt = sub {
        $position += 2;
        my $p = $position;
        $position += 4;
        my @int_buffer = @buffer[$p .. $p + 3];
        return TypeDeserializer->deserializeInt(\@int_buffer);
    };
    
    my $readBool = sub {
        $position += 2;
        my $p = $position;
        $position += 1;
        my $bool_buffer = $buffer[$p];
        return TypeDeserializer->deserializeBool($bool_buffer);
    };
    
    my $readFloat = sub {
        $position += 2;
        my $p = $position;
        $position += 4;
        my @float_buffer = @buffer[$p .. $p + 3];
        return TypeDeserializer->deserializeFloat(\@float_buffer);
    };
    
    my $readByte = sub {
        $position += 2;
        my $p = $position;
        $position += 1;
        my $byte_buffer = $buffer[$p];
        return TypeDeserializer->deserializeByte($byte_buffer);
    };
    
    my $readChar = sub {
        $position += 2;
        my $p = $position;
        $position += 1;
        my $char_buffer = $buffer[$p];
        return TypeDeserializer->deserializeChar($char_buffer);
    };
    
    my $readLongLong = sub {
        $position += 2;
        my $p = $position;
        $position += 8;
        my @longlong_buffer = @buffer[$p .. $p + 7];
        return TypeDeserializer->deserializeLongLong(\@longlong_buffer);
    };
    
    my $readDouble = sub {
        $position += 2;
        my $p = $position;
        $position += 8;
        my @double_buffer = @buffer[$p .. $p + 7];
        return TypeDeserializer->deserializeDouble(\@double_buffer);
    };
    
    my $readUnsignedLongLong = sub {
        $position += 2;
        my $p = $position;
        $position += 8;
        my @ulonglong_buffer = @buffer[$p .. $p + 7];
        return TypeDeserializer->deserializeULongLong(\@ulonglong_buffer);
    };
    
    my $readUnsignedInt = sub {
        $position += 2;
        my $p = $position;
        $position += 4;
        my @uint_buffer = @buffer[$p .. $p + 3];
        return TypeDeserializer->deserializeUInt(\@uint_buffer);
    };
    
    my $readUndef = sub {
        $position += 2;
        my $p = $position;
        $position += 1;
        my $undef_buffer = $buffer[$p];
        return TypeDeserializer->deserializeUndef($undef_buffer);
    };
    
    # Declare readObject first for mutual recursion
    my $readObject;
    
    # Helper function to read command recursively (needs readObject)
    my $readCommandRecursively;
    $readCommandRecursively = sub {
        my ($numberOfArgumentInPayloadLeft, $cmd) = @_;
        
        if ($numberOfArgumentInPayloadLeft == 0) {
            return $cmd;
        }
        else {
            my $p = $position;
            my @int_buffer = @buffer[$p + 1 .. $p + 4];
            my $argSize = TypeDeserializer->deserializeInt(\@int_buffer);
            $cmd = $cmd->AddArgToPayload($readObject->($buffer[$p]));
            return $readCommandRecursively->($numberOfArgumentInPayloadLeft - 1, $cmd);
        }
    };
    
    # Helper function to read command (needs readCommandRecursively and readObject)
    my $readCommand = sub {
        my $p = $position;
        my @int_buffer = @buffer[$p + 1 .. $p + 4];
        my $numberOfArgumentInPayload = TypeDeserializer->deserializeInt(\@int_buffer);
        my $runtime = $buffer[$p + 5];
        my $commandType = $buffer[$p + 6];
        
        $position += 7;
        my $returnCommand = PerlCommand->new(runtime => $runtime, command_type => $commandType);
        return $readCommandRecursively->($numberOfArgumentInPayload, $returnCommand);
    };
    
    # Helper function to read object (references all read functions)
    $readObject = sub {
        my ($type_num) = @_;
        if ($type_num == Type->get_type('Command')) {
            return $readCommand->();
        }
        elsif ($type_num == Type->get_type('JavonetString')) {
            return $readString->();
        }
        elsif ($type_num == Type->get_type('JavonetInteger')) {
            return $readInt->();
        }
        elsif ($type_num == Type->get_type('JavonetBool')) {
            return $readBool->();
        }
        elsif ($type_num == Type->get_type('JavonetFloat')) {
            return $readFloat->();
        }
        elsif ($type_num == Type->get_type('JavonetByte')) {
            return $readByte->();
        }
        elsif ($type_num == Type->get_type('JavonetChar')) {
            return $readChar->();
        }
        elsif ($type_num == Type->get_type('JavonetLongLong')) {
            return $readLongLong->();
        }
        elsif ($type_num == Type->get_type('JavonetDouble')) {
            return $readDouble->();
        }
        elsif ($type_num == Type->get_type('JavonetUnsignedLongLong')) {
            return $readUnsignedLongLong->();
        }
        elsif ($type_num == Type->get_type('JavonetUnsignedInteger')) {
            return $readUnsignedInt->();
        }
        elsif ($type_num == Type->get_type('JavonetNull')) {
            return $readUndef->();
        }
        else {
            die "Type is not supported: $type_num";
        }
    };
    
    
    # Decode the command
    while (!$isAtEnd->()) {
        $command = $command->AddArgToPayload($readObject->($buffer[$position]));
        # Note: position is managed inside readObject and helper functions
    }
    
    return $command;
}

1;