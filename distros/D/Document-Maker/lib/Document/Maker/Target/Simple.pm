package Document::Maker::Target::Simple;

use strict;
use warnings;

use Moose;
use Document::Maker::Dependency;

has script => qw/is ro/;
has name => qw/is ro required 1/;
has dependency => qw/is ro lazy 1/, default => sub {
    return Document::Maker::Dependency->new(maker => shift->maker);
};
has freshness => qw/is ro/, default => 0;

with map { "Document::Maker::Role::$_" } qw/Component Target TargetMaker Dependency/;

sub BUILD {
    my $self = shift;
    $self->log->debug("New simple target: ", $self->name);
}

sub can_make {
    my $self = shift;
    my $name = shift;
    return $self if $name eq $self->name;
    return undef;
}

sub fresh {
    my $self = shift;
    return 0 unless my $freshness = $self->freshness;
    return 0 unless $self->dependency->fresh;
    return $freshness >= $self->dependency->freshness;
}

sub make {
    my $self = shift;
    $self->dependency->make($self);
    $self->execute if $self->script;
    $self->{freshness} = time;
}

sub execute {
    my $self = shift;
    die "Can't make without a script" unless $self->script;
    $self->script->($self);
}

sub should_make {
    my $self = shift;
    return $self->fresh ? 0 : 1;
}


1;
