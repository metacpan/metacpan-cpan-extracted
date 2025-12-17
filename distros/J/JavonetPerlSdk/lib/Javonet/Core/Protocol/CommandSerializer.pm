package Javonet::Core::Protocol::CommandSerializer;
use strict;
use warnings FATAL => 'all';

use lib 'lib';
use aliased 'Javonet::Sdk::Core::PerlCommand' => 'PerlCommand';
use aliased 'Javonet::Sdk::Core::RuntimeLib' => 'RuntimeLib', qw(get_runtime);
use aliased 'Javonet::Sdk::Core::Type' => 'Type', qw(get_type);
use aliased 'Javonet::Core::Protocol::TypeSerializer' => 'TypeSerializer';
use aliased 'Javonet::Sdk::Core::TypesHandler' => 'TypesHandler';
use aliased 'Javonet::Core::Handler::ReferencesCache' => 'ReferencesCache';
use aliased 'Javonet::Sdk::Core::PerlCommandType' => 'PerlCommandType';
use Javonet::Sdk::Internal::ConnectionType;

use Exporter qw(import);
our @EXPORT = qw(serialize serialize_connection_data);

sub serialize {
    my ($class, $root_command, $connection_type, $tcp_address, $runtimeVersion) = @_;
    $runtimeVersion = 0 unless defined $runtimeVersion;
    
    # Local buffer instead of global
    my @byte_buffer = ();
    
    # Helper to insert data into buffer
    my $insert_into_buffer = sub {
        my (@data) = @_;
        push @byte_buffer, @data;
    };
    
    # Write runtime and version
    $insert_into_buffer->($root_command->{runtime}, $runtimeVersion);
    
    # Write connection data
    my @connection_data = $class->serialize_connection_data($connection_type, $tcp_address);
    $insert_into_buffer->(@connection_data);
    
    # Write runtime name and command type header for Perl runtime
    $insert_into_buffer->(
        Javonet::Sdk::Core::RuntimeLib::get_runtime('Perl'),
        $root_command->{command_type}
    );
    
    # Serialize payload recursively
    $class->serialize_recursively($root_command, $insert_into_buffer);
    
    return @byte_buffer;
}

sub serialize_connection_data {
    my ($class, $connection_type, $tcp_address) = @_;
    if (defined $connection_type && 
        Javonet::Sdk::Internal::ConnectionType::get_connection_type('Tcp') eq $connection_type) {
        my @tcp_array = split(':', $tcp_address);
        my @tcp_ip = split('\\.', $tcp_array[0]);
        my @bytes_port = unpack "C*", pack "v", $tcp_array[1];
        return (Javonet::Sdk::Internal::ConnectionType::get_connection_type('Tcp'), @tcp_ip, @bytes_port);
    }
    else {
        return (Javonet::Sdk::Internal::ConnectionType::get_connection_type('InMemory'), 0, 0, 0, 0, 0, 0);
    }
}

# Recursively serialize command payload - matches C# SerializeRecursively
sub serialize_recursively {
    my ($class, $command, $insert_into_buffer) = @_;
    
    my $payload_ref = $command->{payload};
    my @payload = @$payload_ref;
    
    foreach my $item (@payload) {
        if (defined $item && ref $item eq 'Javonet::Sdk::Core::PerlCommand') {
            # Item is a Command - serialize it and recurse
            my @command_bytes = TypeSerializer->serializeCommand($item);
            $insert_into_buffer->(@command_bytes);
            $class->serialize_recursively($item, $insert_into_buffer);
        }
        elsif (TypesHandler->is_primitive_or_none($item)) {
            # Item is primitive or null
            my @primitive_bytes = TypeSerializer->serializePrimitive($item);
            $insert_into_buffer->(@primitive_bytes);
        }
        else {
            # Item is a reference - cache it and create a Reference command
            my $reference_cache = ReferencesCache->new();
            my $guid = $reference_cache->cache_reference($item);
            my $reference_command = PerlCommand->new(
                runtime => Javonet::Sdk::Core::RuntimeLib::get_runtime('Perl'),
                command_type => PerlCommandType->get_command_type('Reference'),
                payload => [$guid]
            );
            my @command_bytes = TypeSerializer->serializeCommand($reference_command);
            $insert_into_buffer->(@command_bytes);
            $class->serialize_recursively($reference_command, $insert_into_buffer);
        }
    }
}

1;
