package Javonet::Javonet;
use strict;
use warnings FATAL => 'all';
use Moose;
use lib 'lib';
use Try::Tiny;
use threads;
use aliased 'Javonet::Sdk::Internal::RuntimeFactory' => 'RuntimeFactory';
use aliased 'Javonet::Core::Transmitter::PerlTransmitter' => 'Transmitter', qw(activate_with_license_file activate_with_credentials activate_with_credentials_and_proxy);
use aliased 'Javonet::Core::Exception::SdkExceptionHelper' => 'SdkExceptionHelper';
use aliased 'Javonet::Sdk::Core::RuntimeLogger' => 'RuntimeLogger', qw(print_runtime_info);

BEGIN {
    try {
        Transmitter->activate_with_license_file();
    } catch {
        SdkExceptionHelper->send_exception_to_app_insights($_,"JavonetStatic");
    };
    RuntimeLogger->print_runtime_info();
}

sub activate {
    if(@_ == 1) {
        try {
            return Transmitter->activate_with_license_file();
        } catch {
            Javonet::Core::Exception::SdkExceptionHelper->send_exception_to_app_insights($_,"licenseFile");
            die($_);
        };
    }
    if(@_ == 2) {
        my($self, $licenseKey) = @_;
        try {
            return Transmitter->activate_with_credentials($licenseKey);
        } catch {
            Javonet::Core::Exception::SdkExceptionHelper->send_exception_to_app_insights($_,$licenseKey);
            die($_);
        };
    } elsif (@_ > 2) {
        my($self, $licenseKey, $proxyHost, $proxyUserName, $proxyPassword) = @_;
        $proxyUserName //="";
        $proxyPassword //="";
        try {
            return Transmitter->activate_with_credentials_and_proxy($licenseKey, $proxyHost, $proxyUserName, $proxyPassword);
        } catch {
            Javonet::Core::Exception::SdkExceptionHelper->send_exception_to_app_insights($_,$licenseKey);
            die($_);
        };
    }
}

sub in_memory {
    return RuntimeFactory->new(Javonet::Sdk::Internal::ConnectionType::get_connection_type('InMemory'), undef, undef);
}

sub tcp {
    my $class = shift;
    my $address = shift;
    return RuntimeFactory->new(Javonet::Sdk::Internal::ConnectionType::get_connection_type('Tcp'), $address, undef);
}

sub with_config {
    my ($self, $config_path) = @_;
    try {
        Transmitter->set_config_source($config_path);
        return RuntimeFactory->new(Javonet::Sdk::Internal::ConnectionType::get_connection_type('WithConfig'), undef, $config_path);
    } catch {
        SdkExceptionHelper->send_exception_to_app_insights($_,"withConfig");
        die $_;
    };
}

1;