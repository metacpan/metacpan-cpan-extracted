package Javonet::Core::Protocol::CommandSerializer;
use strict;
use warnings FATAL => 'all';
use Moose;

use lib 'lib';
use aliased 'Javonet::Sdk::Core::PerlCommand' => 'PerlCommand';
use aliased 'Javonet::Sdk::Core::RuntimeLib' => 'RuntimeLib', qw(get_runtime);
use aliased 'Javonet::Sdk::Core::Type' => 'Type', qw(get_type);
use aliased 'Javonet::Core::Protocol::TypeSerializer' => 'TypeSerializer', qw(serializeInt serializeString serializeDouble serializeFloat serializeCommand);
use Javonet::Sdk::Internal::ConnectionType;

use Thread::Queue;
use Scalar::Util::Numeric qw(isint);
use autobox::universal qw(type);

my @byte_buffer = ();
my $queue = Thread::Queue->new();

sub encode {
    my ($self, $root_command, $connection_type, $tcp_address, $runtimeVersion) = @_;
    @byte_buffer = ();
    $queue = Thread::Queue->new();
    $queue->insert(0, $root_command);
    insert_into_buffer(($root_command->{runtime}, $runtimeVersion));
    insert_into_buffer(serialize_tcp_address($connection_type, $tcp_address));
    insert_into_buffer(Javonet::Sdk::Core::RuntimeLib::get_runtime('Perl'), $root_command->{command_type});
    return serialize_recursively();
}

sub serialize_tcp_address {
    my ($connection_type, $tcp_address) = @_;
    my @tcp_byte_array;
    if ( Javonet::Sdk::Internal::ConnectionType::get_connection_type('Tcp') eq $connection_type) {
        my @tcp_array = split(':', $tcp_address);
        my @tcp_ip = split('\\.', $tcp_array[0]);
        my @bytes_port =  unpack "C*", pack "v",  $tcp_array[1];
        @tcp_byte_array = (Javonet::Sdk::Internal::ConnectionType::get_connection_type('Tcp'), @tcp_ip, @bytes_port);
        return @tcp_byte_array;
    }
    else {
        @tcp_byte_array = (Javonet::Sdk::Internal::ConnectionType::get_connection_type('InMemory'), 0, 0, 0, 0, 0, 0);
        return @tcp_byte_array;
    }
}

sub insert_into_buffer {
    my @arguments = @_;
    @byte_buffer = (@byte_buffer, @arguments);
}

sub serialize_primitive {
    my ($payload_item) = @_;
    if(!defined $payload_item) {
        return TypeSerializer->serializeUndef();
    }

    if(isint($payload_item)){
        return TypeSerializer->serializeInt($payload_item);
    }
    if(type($payload_item) eq "FLOAT"){
        return TypeSerializer->serializeDouble($payload_item);
    }
    else{
        return TypeSerializer->serializeString($payload_item);
    }
}

sub serialize_recursively{
    my $left = $queue->pending();
    if ($left == 0){
        return @byte_buffer;
    }
    my $command = $queue->dequeue();
    $queue->insert(0, $command->drop_first_payload_argument());
    my $current_payload_ref = $command->{payload};
    my @cur_payload = @$current_payload_ref;
    my $payload_len = @cur_payload;
    if ($payload_len > 0){
        if (!defined $cur_payload[0]){
            insert_into_buffer(serialize_primitive(undef));
        }
        else {
            if ($cur_payload[0]->isa("Javonet::Sdk::Core::PerlCommand")) {
                my $inner_command = $cur_payload[0];
                insert_into_buffer(TypeSerializer->serializeCommand($inner_command));
                $queue->insert(0, $inner_command);
            }
            else {
                my @result = serialize_primitive($cur_payload[0]);
                insert_into_buffer(@result);
            }
        }
        return serialize_recursively();
    }
    else{
        $queue->dequeue();
    }
    return serialize_recursively();
}

no Moose;
1;