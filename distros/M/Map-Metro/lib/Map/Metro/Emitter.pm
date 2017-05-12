use 5.10.0;
use strict;
use warnings;

package Map::Metro::Emitter;

# ABSTRACT: Event emitter for hooks
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.2405';

use Map::Metro::Elk;
use List::Util qw/none/;
use Types::Standard qw/ArrayRef Str HashRef/;
use Map::Metro::Hook;

use Module::Pluggable search_path => ['Map::Metro::Plugin::Hook'], require => 1, sub_name => 'found_plugins';

has wanted_hook_plugins => (
    is => 'ro',
    isa => ArrayRef[ Str ],
    traits => ['Array'],
    handles => {
        all_wanted_hook_plugins => 'elements',
    },
);
has registered_hooks => (
    is => 'rw',
    isa => ArrayRef,
    traits => ['Array'],
    handles => {
        add_registered_hook => 'push',
        all_registered_hooks => 'elements',
        filter_registered_hooks => 'grep',
    },
);
has plugins => (
    is => 'rw',
    isa => HashRef,
    traits => ['Hash'],
    handles => {
        add_plugin => 'set',
        get_plugin => 'get',
        plugin_names => 'keys',
    },
);

sub BUILD {
    my $self = shift;

    PLUGIN:
    foreach my $pluginname ($self->found_plugins) {
        (my $actual = $pluginname) =~ s{^Map::Metro::Plugin::Hook::}{};
        next PLUGIN if none { $_ eq $actual } $self->all_wanted_hook_plugins;

        my $plugin = $pluginname->new;
        $self->register($plugin);
        $self->add_plugin($actual => $plugin);
    }
}
sub register {
    my $self = shift;
    my $plugin = shift;

    my %hooks_list = $plugin->register;

    foreach my $event (keys %hooks_list) {
        my $hook = Map::Metro::Hook->new(event => $event, action => $hooks_list{ $event }, plugin => $plugin);
        $self->add_registered_hook($hook);
    }
}

sub before_add_station {
    my $self = shift;
    my $station = shift;

    $self->emit('before_add_station', $station);
}
sub before_add_routing {
    my $self = shift;
    my $routing = shift;

    $self->emit('before_add_routing', $routing);
}
sub before_start_routing {
    my $self = shift;
    $self->emit('before_start_routing');
}

sub emit {
    my $self = shift;
    my $event = shift;
    my @args = @_;

    my @hooks = $self->filter_registered_hooks(sub { $_->event eq $event });

    foreach my $hook (@hooks) {
        $hook->action->($hook->plugin, @args);
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Map::Metro::Emitter - Event emitter for hooks

=head1 VERSION

Version 0.2405, released 2016-07-23.

=head1 SOURCE

L<https://github.com/Csson/p5-Map-Metro>

=head1 HOMEPAGE

L<https://metacpan.org/release/Map-Metro>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
