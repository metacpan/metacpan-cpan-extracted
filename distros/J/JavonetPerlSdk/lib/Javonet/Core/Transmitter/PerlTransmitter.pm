package Javonet::Core::Transmitter::PerlTransmitter;
use strict;
use warnings;
use Cwd;
use aliased 'Javonet::Core::Transmitter::PerlTransmitterWrapper' => 'PerlTransmitterWrapper' , qw(send_command activate set_config_source set_javonet_working_directory);

sub send_command {
    my ($self, $message_byte_array_ref) = @_;
    my $response_byte_array_ref = PerlTransmitterWrapper->send_command($message_byte_array_ref);
    return $response_byte_array_ref;
}

sub activate {
    my ($self, $licenseKey) = @_;
    return PerlTransmitterWrapper->activate($licenseKey);
}

sub set_config_source {
    my ($self, $config_path) = @_;
    PerlTransmitterWrapper->set_config_source($config_path);
}

sub set_javonet_working_directory {
    my ($self, $working_directory) = @_;
    PerlTransmitterWrapper->set_javonet_working_directory($working_directory);
}

1;
