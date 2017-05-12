package Document::Maker::Dependency;

use Moose;

with qw/Document::Maker::Role::Component/;

has dependencies => qw/is ro lazy 1/, default => sub { [] };

sub fresh {
    my $self = shift;
    for my $dependency ($self->_dependencies) {
        return 0 unless $dependency->fresh;
    }
    return 1;
}

sub freshness {
    my $self = shift;
    my $freshest;
    for my $dependency ($self->_dependencies) {
        $freshest = $dependency->freshness if ! defined $freshest || $dependency->freshness > $freshest;
    }
    return $freshest || 0;
}

sub add_dependency {
    my $self = shift;
    push @{ $self->dependencies }, shift;
}

sub _dependencies {
    my $self = shift;
    return map { $self->_dependency($_) } @{ $self->dependencies };
}

sub _dependency {
    my $self = shift;
    my $dependency = shift;
    return $dependency if blessed $dependency;
    my $target;
    return $target if $target = $self->maker->find_target($dependency);
    # So, we'll assume it's a file
    return Document::Maker::Source::File->new(maker => $self->maker, file => $dependency);
}

sub make {
    my $self = shift;
    for my $dependency ($self->_dependencies) {
        next if $dependency->fresh;
        next unless $dependency->can("make"); # TODO Otherwise an error?
        $dependency->make;
    }
}

sub clone {
    my $self = shift;
    my $clone = __PACKAGE__->new(maker => $self->maker, dependencies => [ @{ $self->dependencies } ]);
    return $clone;
}

1;
