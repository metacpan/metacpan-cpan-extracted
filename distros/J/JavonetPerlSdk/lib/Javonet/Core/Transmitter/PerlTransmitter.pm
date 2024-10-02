package Javonet::Core::Transmitter::PerlTransmitter;
use strict;
use warnings;
use Cwd;
use aliased 'Javonet::Core::Transmitter::PerlTransmitterWrapper' => 'PerlTransmitterWrapper' , qw(send_command_ activate_);

sub send_command {
    my ($self, $message_byte_array_ref) = @_;
    my $response_byte_array_ref = PerlTransmitterWrapper->send_command($message_byte_array_ref);
    return $response_byte_array_ref;
}

sub activate_with_license_file {
    return __activate();
}

sub activate_with_credentials {
    my($self, $licenseKey) = @_;
    return __activate($licenseKey);
}

sub activate_with_credentials_and_proxy {
    my($self,  $licenseKey, $proxyHost, $proxyUserName, $proxyPassword) = @_;
    return __activate($licenseKey, $proxyHost, $proxyUserName, $proxyPassword);
}

sub __activate {
    my($licenseKey, $proxyHost, $proxyUserName, $proxyPassword) = @_;
    #set default values
    $licenseKey //="";
    $proxyHost //="";
    $proxyUserName //="";
    $proxyPassword //="";
    return PerlTransmitterWrapper->activate($licenseKey, $proxyHost, $proxyUserName, $proxyPassword);
}

sub set_config_source {
    my ($self, $config_path) = @_;
    PerlTransmitterWrapper->set_config_source($config_path);
}

1;
