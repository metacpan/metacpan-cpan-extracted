package Javonet::Core::Transmitter::PerlTransmitter;
use strict;
use warnings;
use Cwd;
use aliased 'Javonet::Core::Transmitter::PerlTransmitterWrapper' => 'PerlTransmitterWrapper';
use Exporter qw(import);
our @EXPORT = qw(t_send_command t_activate t_set_config_source t_set_javonet_working_directory);

sub t_send_command {
    my ($self, $message_byte_array_ref) = @_;
    return PerlTransmitterWrapper->tw_send_command($message_byte_array_ref);
}

sub t_activate {
    my ($self, $licenseKey) = @_;
    return PerlTransmitterWrapper->tw_activate($licenseKey);
}

sub t_set_config_source {
    my ($self, $config_path) = @_;
    PerlTransmitterWrapper->tw_set_config_source($config_path);
}

sub t_set_javonet_working_directory {
    my ($self, $working_directory) = @_;
    PerlTransmitterWrapper->tw_set_javonet_working_directory($working_directory);
}

1;
