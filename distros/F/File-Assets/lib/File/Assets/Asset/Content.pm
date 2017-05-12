package File::Assets::Asset::Content;

use warnings;
use strict;

use Object::Tiny qw/file/;
use File::Assets::Carp;
use File::Assets::Util;

sub new {
    my $self = bless {}, shift;
    $self->{file} = shift or croak "Can't have content without a file";
    return $self;
}

sub content {
    my $self = shift;

    my $file = $self->file;
    croak "Trying to get content from non-existent file ($file)" unless -e $file;
    if (! $self->{content} || $self->stale) {
        local $/ = undef;
        $self->{content} = \$file->slurp;
        $self->{content_mtime} = $file->stat->mtime;
        $self->{content_size} = length ${ $self->{content} };
    }

    return $self->{content};
}

sub digest {
    my $self = shift;
    return $self->{digest} ||= do {
        File::Assets::Util->digest->add(${ $self->content })->hexdigest;
    }
}

sub file_mtime {
    my $self = shift;
    return (stat($self->file))[9] || 0;
}

sub file_size {
    my $self = shift;
    return (stat($self->file))[7] || 0;
}

sub content_mtime {
    my $self = shift;
    $self->content unless $self->{content};
    return $self->{content_mtime};
}

sub content_size {
    my $self = shift;
    $self->content unless $self->{content};
    return $self->{content_size};
}

sub refresh {
    my $self = shift;
    if ($self->stale) {
        delete $self->{digest};
        delete $self->{content};
        return 1;
    }
    return 0;
}

sub stale {
    my $self = shift;
    return
        ($self->file_mtime > $self->content_mtime) ||
        ($self->file_size != $self->content_size);
}

1;
