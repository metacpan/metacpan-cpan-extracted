package Extism::XS;

use 5.016;
use strict;
use warnings;
use Exporter 'import';

use version 0.77;
our $VERSION = qv(v0.2.0);

require XSLoader;
XSLoader::load('Extism::XS', $VERSION);

our @EXPORT_OK = qw(
    version
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
    plugin_cancel
    function_new
    function_free
    function_set_namespace
    current_plugin_memory
    current_plugin_memory_alloc
    current_plugin_memory_length
    current_plugin_memory_free
    log_file
    log_custom
    log_drain
    CopyToPtr
);

our %EXPORT_TAGS;
$EXPORT_TAGS{all} = [@EXPORT_OK];

1; # End of Extism::XS
