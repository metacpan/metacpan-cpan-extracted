package # no_index
    Dist::Zilla::PluginBundle::TestAirplane;
use Moose;

with qw(
    Dist::Zilla::Role::PluginBundle::Easy
    Dist::Zilla::Role::PluginBundle::Airplane
);

has airplane_type => (
    is => 'ro',
    isa => 'Str',
    default => 'single',
);

sub build_network_plugins {
    my $self = shift;
    return [qw(PromptIfStale)];
}

sub configure {
    my $self = shift;

    my @plugins = qw(PromptIfStale);

    if ($self->airplane_type eq 'single') {
        $self->add_plugins(@plugins);
    }
    elsif ($self->airplane_type eq 'array') {
        $self->add_plugins((\@plugins));
    }
    else {
        $self->add_plugins(({not => 'supported'}));
    }
}

__PACKAGE__->meta->make_immutable;
