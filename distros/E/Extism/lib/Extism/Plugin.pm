package Extism::Plugin;

use 5.016;
use strict;
use warnings;
use Carp qw(croak);
use Extism::XS qw(
    plugin_new
    plugin_new_error_free
    plugin_call
    plugin_error
    plugin_output_length
    plugin_output_data
    plugin_free
    plugin_reset
    plugin_id
    plugin_function_exists
    plugin_config
    plugin_cancel_handle
    );
use Extism::Plugin::CallException;
use Extism::Plugin::CancelHandle;
use Data::Dumper qw(Dumper);
use Devel::Peek qw(Dump);
use JSON::PP qw(encode_json);
use Scalar::Util qw(reftype);
use version 0.77;
our $VERSION = qv(v0.2.0);

sub new {
    my ($name, $wasm, $options) = @_;
    my $functions = [];
    my $with_wasi = 0;
    if ($options) {
        if (exists $options->{functions}) {
            $functions = $options->{functions};
        }
        if (exists $options->{wasi}) {
            $with_wasi = $options->{wasi};
        }
    }
    my $errptr = "\x00" x 8;
    my $errptrptr = unpack('Q', pack('P', $errptr));
    my @rawfunctions = map {$$_} @{$functions};
    my $functionsarray = pack('Q*', @rawfunctions);
    my $functionsptr = unpack('Q', pack('P', $functionsarray));
    my $plugin = plugin_new($wasm, length($wasm), $functionsptr, scalar(@rawfunctions), $with_wasi, $errptrptr);
    if (! $plugin) {
        my $errmsg = unpack('p', $errptr);
        plugin_new_error_free(unpack('Q', $errptr));
        croak $errmsg;
    }
    bless \$plugin, $name
}

# call PLUGIN,FUNCNAME,INPUT
# call PLUGIN,FUNCNAME
# If INPUT is provided and is not a reference the contents of the scalar will be
# passed to the plugin. If INPUT is a reference, the referenced item will be
# encoded with json and then passed to the plugin.
sub call {
    my ($self, $func_name, $input) = @_;
    $input //= '';
    my $type = reftype($input);
    if ($type) {
        $input = $$input if($type eq 'SCALAR');
        $input = encode_json($input);
    }
    my $rc = plugin_call($$self, $func_name, $input, length($input));
    if ($rc != 0) {
        die Extism::Plugin::CallException->new($rc, plugin_error($$self));
    }
    my $output_size = plugin_output_length($$self);
    my $output_ptr = plugin_output_data($$self);
    my $output = unpack('P'.$output_size, pack('Q', plugin_output_data($$self)));
    return $output;
}

sub reset {
    my ($self) = @_;
    return plugin_reset($$self);
}

sub id {
    my ($self) = @_;
    return unpack('P16', pack('Q', plugin_id($$self)));
}

sub function_exists {
    my ($self, $funcname) = @_;
    return plugin_function_exists($$self, $funcname);
}

sub config {
    my ($self, $config) = @_;
    return plugin_config($$self, encode_json($config));
}

sub cancel_handle {
    my ($self) = @_;
    my $raw_cancel_handle = plugin_cancel_handle($$self);
    return Extism::Plugin::CancelHandle->new($raw_cancel_handle);
}

sub DESTROY {
    my ($self) = @_;
    $$self or return;
    plugin_free($$self);
}

1; # End of Extism::Plugin
