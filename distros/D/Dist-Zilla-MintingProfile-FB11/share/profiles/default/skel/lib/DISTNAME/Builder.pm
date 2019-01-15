{{
    $name = $dist->name =~ s/-/::/gr; ''
}}package {{ $name }}::Builder;

use Moose;
use File::ShareDir;
extends 'OpusVL::FB11::Builder';

use Try::Tiny;

# ABSTRACT: Builds {{ $name }} app
our $VERSION = '0';

override _build_plugins => sub {
    my $plugins = super();

    # Add other FB11X plugins here
    push @$plugins, qw(
    );

    return $plugins;
};

1;
