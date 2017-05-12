package Document::Maker::Source::File;

use Moose;

with qw/Document::Maker::Role::Component Document::Maker::Role::Dependency/;

has file => qw/is ro required 1 isa Path::Class::File coerce 1/;

sub exists {
    my $self = shift;
    return -e $self->file;
}

sub freshness {
    my $self = shift;
    return 0 unless -e $self->file;
    return $self->file->stat->mtime;
}

sub fresh {
    my $self = shift;
    return $self->exists;
}

sub make {
    my $self = shift;
    $self->log->debug("Don't know how to make: ", $self->file) and return 0 unless $self->maker->make($self->file);
}

1;
