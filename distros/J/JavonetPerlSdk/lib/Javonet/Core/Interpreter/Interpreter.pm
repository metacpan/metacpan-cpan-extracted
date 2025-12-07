package Javonet::Core::Interpreter::Interpreter;
use strict;
use warnings;
use lib 'lib';
use aliased 'Javonet::Core::Handler::PerlHandler' => 'PerlHandler';
use aliased 'Javonet::Core::Protocol::CommandSerializer' => 'CommandSerializer';
use aliased 'Javonet::Core::Protocol::CommandDeserializer' => 'CommandDeserializer';

use Exporter qw(import);
our @EXPORT = qw(execute_ process);

sub execute_ {
    my ($class, $command, $connection_type, $tcp_address) = @_;
    my @serialized_command = Javonet::Core::Protocol::CommandSerializer->serialize($command, $connection_type, $tcp_address, 0);
    my $response_byte_array_ref;
    if ($command->{runtime} eq Javonet::Sdk::Core::RuntimeLib::get_runtime('Perl')) {
        require Javonet::Core::Receiver::Receiver;
        $response_byte_array_ref = Javonet::Core::Receiver::Receiver->send_command(\@serialized_command);
    } else {
        require Javonet::Core::Transmitter::PerlTransmitter;
        $response_byte_array_ref = Javonet::Core::Transmitter::PerlTransmitter->t_send_command(\@serialized_command);
    }

    return CommandDeserializer->deserialize($response_byte_array_ref);
}

sub process {
    my ($class, $message_byte_array_ref) = @_;
    my @message_byte_array = @$message_byte_array_ref;
    my $command = CommandDeserializer->deserialize(\@message_byte_array);
    my $response = PerlHandler->handle_command($command);
    my @response_byte_array = CommandSerializer->serialize($response, 0, 0, 0);
    return @response_byte_array;
}

1;
