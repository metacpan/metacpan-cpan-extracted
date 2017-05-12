package Directory::Deploy::Maker;

use Moose;

use Directory::Deploy::Carp;

has deploy => qw/is ro required 1/;

sub make {
    my $self = shift;
    my $entry = shift;

    if ($entry->is_file) {
        $self->_make_file( $entry );
    }
    else {
        $self->_make_dir( $entry );
    }
}

sub _make_file {
    my $self = shift;
    my $entry = shift;

    my $file = $self->deploy->file( $entry->path );
    my $content = $entry->content;

    $file->parent->mkpath unless -d $file->parent;
    my $file_handle = $file->openw or croak "Couldn't open write file handle for ($file) since: $!";

    if (! defined $content) {
    }
    elsif ( ref $content eq 'SCALAR' ) {
        $file_handle->print( $$content );
    }
    elsif ( ! ref $content ) { # && $content =~ m/\n/ ) {
        $file_handle->print( $content );
    }
    else {
        croak "Don't know how to make $content";
    }

    my $mode;
    chmod $mode, "$file" or carp "Unable to set mode ($mode) on file ($file)" if $mode = $entry->mode;
}

sub _make_dir {
    my $self = shift;
    my $entry = shift;

    my $dir = $self->deploy->dir( $entry->path );

    $dir->mkpath;

    my $mode;
    chmod $mode, "$dir" or carp "Unable to set mode ($mode) on dir ($dir)" if $mode = $entry->mode;
}

1;
