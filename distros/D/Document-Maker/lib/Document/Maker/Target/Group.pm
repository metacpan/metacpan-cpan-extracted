package Document::Maker::Target::Group;

use Moose;

with map { "Document::Maker::Role::$_" } qw/Component TargetMaker Dependency/;

has targets => qw/is ro/, default => sub { [] };
has names => qw/is ro/, default => sub { [] };

sub BUILD {
    my $self = shift;
    my $BUILD = shift;
}

sub can_make {
    my $self = shift;
    my $name = shift;
    for (@{ $self->names }) {
        return $self if $name eq $_;
    }
    return undef;
}

sub should_make {
    my $self = shift;
    return $self->fresh ? 0 : 1;
}

sub fresh {
    my $self = shift;
    for my $target (@{ $self->targets }) {
        return 0 unless $target->fresh;
    }
    return 1;
}

sub freshness {
    my $self = shift;
    my $freshness;
    for my $target (@{ $self->targets }) {
        $freshness = $target->freshness if ! defined $target || $freshness > $target->freshness;
    }
    return $freshness || 0;
}

sub make {
    my $self = shift;
    for my $target (@{ $self->targets }) {
        $target->make;
    }
}

1;
