package File::DirObject::File;

use strict;
use warnings;

sub name {
    my $self = shift;
    return ${$self}{'filename'};
}

sub dir {
    my $self = shift;
    return ${$self}{'dir'};
}

sub extension {
    my $self = shift;
    my @parts = split /\./, $self->name;
    
    if (scalar @parts > 1) {
        return lc $parts[-1];
    }

    return '';
}

sub path {
    my $self = shift;
    my $dir = $self->dir;

    return $dir->is_cwd
        ? $self->name
        : $dir->path . $self->name;
}

sub full_path {
    my $self = shift;
    my $dir = $self->dir;
    return $self->name;
}

sub new {
    my ($class, $dir, $filename) = @_;

    if (!(defined $dir)) {
        die "No parent directory found.";
    }

    if (!(defined $filename)) {
        die "No filename supplied.";
    }
    
    my $self = {
        'dir', $dir, 'filename', $filename
    };

    bless $self, $class;
    return $self;
}

1;
