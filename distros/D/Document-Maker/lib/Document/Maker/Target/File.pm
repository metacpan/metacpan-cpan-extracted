package Document::Maker::Target::File;

use strict;
use warnings;

use Moose;
use Document::Maker::Dependency;

with map { "Document::Maker::Role::$_" } qw/Component Target TargetMaker Dependency/;

has script => qw/is ro/;
has name => qw/is ro required 1/;
has file => qw/is ro lazy 1/, default => sub {
    return Path::Class::File->new(shift->name);
};
has dependency => qw/is ro lazy 1/, default => sub {
    return Document::Maker::Dependency->new(maker => shift->maker);
};

sub can_make {
    my $self = shift;
    my $name = shift;
    return $self if $name eq $self->name;
    return undef;
}

sub should_make {
    my $self = shift;
    return $self->fresh ? 0 : 1;
}

sub freshness {
    my $self = shift;
    return 0 unless -e $self->file;
    return $self->file->stat->mtime;
}

sub fresh {
    my $self = shift;
    return 0 unless -e $self->file;
    return 0 unless $self->dependency->fresh;
    return $self->freshness >= $self->dependency->freshness ? 1 : 0;
}

sub make {
    my $self = shift;
    $self->dependency->make($self);
    $self->execute if $self->script;
}

sub execute {
    my $self = shift;
    die "Can't execute without a script" unless $self->script;
    $self->script->($self, $self->file);
}

#sub make {
#    my $self = shift;
#    die "Can't make without a script" unless $self->script;
#    $self->dependency->make($self);
#    $self->script->($self, $self->file);
#}

1;
