package Extism::XS v0.3.0;
use 5.016;
use strict;
use warnings;
use Exporter 'import';

require XSLoader;
our $VERSION;
XSLoader::load('Extism::XS', $VERSION);

our @EXPORT_OK = qw(
    version
    plugin_new
    plugin_new_with_fuel_limit
    plugin_allow_http_response_headers
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
    plugin_cancel
    function_new
    function_free
    function_set_namespace
    current_plugin_memory
    current_plugin_memory_alloc
    current_plugin_memory_length
    current_plugin_memory_free
    current_plugin_host_context
    log_file
    log_custom
    log_drain
    compiled_plugin_new
    compiled_plugin_free
    plugin_new_from_compiled
    CopyToPtr
);

our %EXPORT_TAGS;
$EXPORT_TAGS{all} = [@EXPORT_OK];

1; # End of Extism::XS
