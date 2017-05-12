package Mason::Plugin::DefaultFilter::Interp;

use Mason::PluginRole;

our $VERSION = '0.003'; # VERSION

has default_filters => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
);

1;
