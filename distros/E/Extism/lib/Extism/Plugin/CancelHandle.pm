package Extism::Plugin::CancelHandle;

use 5.016;
use strict;
use warnings;
use Extism::XS qw(plugin_cancel);
use version 0.77; our $VERSION = qv(v0.0.1);

sub new {
    my ($name, $raw_cancel_handle) = @_;
    return bless \$raw_cancel_handle, $name;
}

sub cancel {
    my ($self) = @_;
    return plugin_cancel($$self);
}

1; # End of Extism::Plugin::CancelHandle
