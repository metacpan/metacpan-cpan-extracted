package Javonet::Javonet;
use strict;
use warnings FATAL => 'all';
use Moose;
use lib 'lib';
use Try::Tiny;
use threads;
use aliased 'Javonet::Sdk::Internal::RuntimeFactory' => 'RuntimeFactory';
use aliased 'Javonet::Core::Transmitter::PerlTransmitter' => 'Transmitter';
use aliased 'Javonet::Core::Exception::SdkExceptionHelper' => 'SdkExceptionHelper';
use aliased 'Javonet::Sdk::Core::RuntimeLogger' => 'RuntimeLogger';
use Exporter qw(import);
our @EXPORT = qw(activate in_memory tcp with_config get_runtime_info set_config_source set_javonet_working_directory);

BEGIN {
    SdkExceptionHelper->send_exception_to_app_insights("SdkMessage", "Javonet Sdk initialized");
}

sub activate {
    my($self, $licenseKey) = @_;
    try {
        return Transmitter->t_activate($licenseKey);
    } catch {
        Javonet::Core::Exception::SdkExceptionHelper->send_exception_to_app_insights($_,"licenseFile");
        die($_);
    };
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
        Transmitter->t_set_config_source($config_path);
        return RuntimeFactory->new(Javonet::Sdk::Internal::ConnectionType::get_connection_type('WithConfig'), undef, $config_path);
    } catch {
        SdkExceptionHelper->send_exception_to_app_insights("SdkException", $_);
        die $_;
    };
}

sub get_runtime_info() {
    RuntimeLogger->rl_get_runtime_info();
}

sub set_config_source {
    my ($self, $config_path) = @_;
    try {
        Transmitter->t_set_config_source($config_path);
    } catch {
        SdkExceptionHelper->send_exception_to_app_insights("SdkException", $_);
        die $_;
    };
}

# Sets the working directory for the Javonet SDK.
# @param $path [String] The working directory path.
sub set_javonet_working_directory {
    my ($self, $path) = @_;
    try {
        $path =~ s{\\}{/}g;
        $path .= '/' unless $path =~ m{/$};
        mkdir $path, 0700 unless -d $path;
        #ActivationHelper->working_directory($path);
        Transmitter->t_set_javonet_working_directory($path);
    } catch {
        SdkExceptionHelper->send_exception_to_app_insights("SdkException", $_);
        die $_;
    };
}



1;