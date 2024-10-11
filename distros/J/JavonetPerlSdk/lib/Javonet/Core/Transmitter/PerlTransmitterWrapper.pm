package Javonet::Core::Transmitter::PerlTransmitterWrapper;
use warnings;
use strict;
use lib 'lib';
use FFI::Platypus;
use Path::Tiny;
use File::Spec;
use Config;
use POSIX qw(uname);

my $ffi;

my $send_command_native;
my $read_response_native;
my $activate_native;
my $get_native_error_native;
my $set_config_source_native;

sub initialize {
    my $osname = $^O;
    {
        $ffi = FFI::Platypus->new(api => 1);
        use FFI::Platypus::DL qw(dlopen dlerror RTLD_PLATYPUS_DEFAULT);
        my $dir = File::Spec->rel2abs(__FILE__);
        my $current_dir = path($dir)->parent(3);
        my $perl_native_lib;

        my $arch = do {
            my $uname = (uname())[4];
            if ($uname =~ /64/) {
                "X64";
            } elsif ($uname =~ /arm64|aarch64/) {
                "ARM64";
            } elsif ($uname =~ /arm/) {
                "ARM";
            } else {
                "X86";
            }
        };

        if ($osname eq "linux") {
            $perl_native_lib = "Binaries/Native/Linux/$arch/libJavonetPerlRuntimeNative.so";
        }
        elsif ($osname eq "darwin") {
            $perl_native_lib = "Binaries/Native/MacOs/$arch/libJavonetPerlRuntimeNative.dylib";
        }
        else {
            $perl_native_lib = "Binaries/Native/Windows/$arch/JavonetPerlRuntimeNative.dll";
        }
        $ffi->lib("$current_dir/$perl_native_lib");
        $send_command_native = $ffi->function('SendCommand' => [ 'uchar[]', 'int' ] => 'int');
        $read_response_native = $ffi->function('ReadResponse' => [ 'uchar[]', 'int' ] => 'int');
        $activate_native = $ffi->function('Activate' => ['string', 'string', 'string', 'string' ] => 'int');
        $get_native_error_native = $ffi->function('GetNativeError' => [] => 'string');
        $set_config_source_native = $ffi->function('SetConfigSource' => ['string'] => 'int');
    }
}

sub send_command {
    my ($self, $message_ref) = @_;
    my @message_array = @$message_ref;
    my $response_array_len = $send_command_native->(\@message_array, scalar @message_array);

    if ($response_array_len > 0) {
        my @response_array = (1 .. $response_array_len);
        $read_response_native->(\@response_array, $response_array_len);
        return \@response_array;
    }
    elsif ($response_array_len == 0) {
        my $error_message = "Response is empty";
        die "$error_message";
    }
    else {
        my $error_message = $get_native_error_native->();
        die "Javonet native error code: $response_array_len. $error_message";
    }
}

sub activate {
    my ($self, $licenseKey, $proxyHost, $proxyUserName, $proxyPassword) = @_;
    initialize();
    my $activation_result = $activate_native->($licenseKey, $proxyHost, $proxyUserName, $proxyPassword);
    if ($activation_result < 0) {
        my $error_message = $get_native_error_native->();
        die "Javonet activation result: $activation_result. Native error message: $error_message";
    }
    else {
        return $activation_result;
    }
}

sub set_config_source {
    my ($self, $config_path) = @_;
    initialize();
    my $set_config_result = $set_config_source_native->($config_path);
    if ($set_config_result < 0) {
        my $error_message = $get_native_error_native->();
        die "Javonet set config source result: $set_config_result. Native error message: $error_message";
    }
    else {
        return $set_config_result;
    }
}

1;