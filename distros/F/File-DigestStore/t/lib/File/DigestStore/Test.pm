package File::DigestStore::Test;
use Moose::Role;

use File::Temp qw/ :POSIX /;

has tmp => (is => 'ro', isa => 'Str', lazy_build => 1);
has storer => (is => 'rw', isa => 'File::DigestStore', lazy_build => 1);

sub _build_tmp {
    return tmpnam;
}

=head2

 $self->cleanup_storage;

If a storer has been set, this will clear it and remove the backing storage on disk.

=cut

sub cleanup_storage {
    my($self) = @_;

    return unless $self->has_storer;
    system (rm => -rf => $self->storer->root)
        if defined $self->storer->root;
    $self->clear_storer;
}

1;
