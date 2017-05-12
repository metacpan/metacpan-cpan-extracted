use strict;
use warnings;
use utf8;

package Dist::Zilla::PluginBundle::ReadmeAnyFromPod;
# ABSTRACT: Just a bundle of multiple ReadmeAnyFromPod plugins

use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';

sub mvp_multivalue_args { qw( readme ) }

sub configure {
    my $self = shift;
    my $readme_names = $self->payload->{readme} || ['TextInBuild'];
    my @plugins = map { [ 'ReadmeAnyFromPod' => $_ ] } @$readme_names;
    $self->add_plugins(@plugins);
}

1;
