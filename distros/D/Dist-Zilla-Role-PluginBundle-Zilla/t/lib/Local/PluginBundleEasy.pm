package Local::PluginBundleEasy;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';
with 'Dist::Zilla::Role::PluginBundle::Zilla';    ## no critic (Moose::ProhibitMultipleWiths)

use namespace::autoclean;

sub configure {
    my ($self) = @_;

    $self->log( 'Hello from ' . __PACKAGE__ . ': name => ' . $self->name );

    die 'Zilla is not a Dist::Zilla' if !$self->zilla->isa('Dist::Zilla');    ## no critic (ErrorHandling::RequireCarping)

    return;
}

__PACKAGE__->meta->make_immutable;

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
