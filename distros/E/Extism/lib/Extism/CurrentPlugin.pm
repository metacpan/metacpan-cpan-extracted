package Extism::CurrentPlugin v0.3.0;

use 5.016;
use strict;
use warnings;
use feature 'say';
use Extism::XS qw(current_plugin_memory
    current_plugin_memory_alloc
    current_plugin_memory_length
    current_plugin_memory_free
    current_plugin_host_context
    CopyToPtr);

# These functions are only valid within a host function
# instance is set by Extism::Function::host_function_caller_perl, valid only for
# the host function.

sub memory {
    return current_plugin_memory($Extism::CurrentPlugin::instance);
}

sub memory_alloc {
    return current_plugin_memory_alloc($Extism::CurrentPlugin::instance, $_[0]);
}

sub memory_length {
    return current_plugin_memory_length($Extism::CurrentPlugin::instance, $_[0]);
}

sub memory_free {
    return current_plugin_memory_free($Extism::CurrentPlugin::instance, $_[0]);
}

sub memory_load_from_ptr {
    my ($ptr, $size) = @_;
    my $realptr = memory() + $ptr;;
    return unpack('P'.$size, pack('Q', $realptr));
}

sub memory_load_from_handle {
    my $memory_length = memory_length($_[0]);
    my $scalar = memory_load_from_ptr($_[0], $memory_length);
    return $scalar;
}

sub memory_alloc_and_store {
    my ($scalar) = @_;
    my $ptr = memory_alloc(length($scalar));
    $ptr or return 0;
    CopyToPtr($scalar, memory() + $ptr, length($scalar));
    return $ptr;
}

sub host_context {
    current_plugin_host_context($Extism::CurrentPlugin::instance)
}

1; # End of Extism::CurrentPlugin
