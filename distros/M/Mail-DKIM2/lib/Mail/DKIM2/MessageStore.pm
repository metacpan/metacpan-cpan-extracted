package Mail::DKIM2::MessageStore;
use 5.20.0;
use strict;
use warnings;

our $VERSION = '0.17';

use Crypt::Digest::SHA256 qw(sha256_hex);
use File::Path qw(make_path);
use Carp;

sub new {
    my ($class, %args) = @_;
    croak "directory required" unless $args{directory};
    my $self = bless \%args, $class;
    return $self;
}

# Derive a filesystem-safe key from an MI header value
sub _key_for_mi {
    my ($self, $mi_value) = @_;
    # Canonicalize: unfold continuation lines and collapse whitespace
    # so that folded and unfolded forms hash identically.
    $mi_value =~ s/\r?\n[ \t]/ /g;
    $mi_value =~ s/\s+/ /g;
    $mi_value =~ s/^\s+//;
    $mi_value =~ s/\s+$//;
    return sha256_hex($mi_value);
}

# Path with 2-char prefix subdirectory to avoid crowding
sub _path_for_key {
    my ($self, $key) = @_;
    my $prefix = substr($key, 0, 2);
    return "$self->{directory}/$prefix/$key";
}

sub store {
    my ($self, $mi_value, $message_data) = @_;
    croak "mi_value required" unless defined $mi_value;
    croak "message_data required" unless defined $message_data;

    my $key = $self->_key_for_mi($mi_value);
    my $path = $self->_path_for_key($key);

    my $dir = $path;
    $dir =~ s{/[^/]+$}{};
    make_path($dir) unless -d $dir;

    open my $fh, '>:raw', $path
        or croak "Cannot write $path: $!";
    print $fh $message_data;
    close $fh;

    return $key;
}

sub fetch {
    my ($self, $mi_value) = @_;
    croak "mi_value required" unless defined $mi_value;

    my $key = $self->_key_for_mi($mi_value);
    my $path = $self->_path_for_key($key);

    return unless -f $path;

    open my $fh, '<:raw', $path
        or croak "Cannot read $path: $!";
    local $/;
    my $data = <$fh>;
    close $fh;

    return $data;
}

sub rel_path_for_mi {
    my ($self, $mi_value) = @_;
    my $key = $self->_key_for_mi($mi_value);
    my $prefix = substr($key, 0, 2);
    return "$prefix/$key";
}

sub remove {
    my ($self, $mi_value) = @_;
    croak "mi_value required" unless defined $mi_value;

    my $key = $self->_key_for_mi($mi_value);
    my $path = $self->_path_for_key($key);

    return unless -f $path;
    unlink $path or croak "Cannot remove $path: $!";
    return 1;
}

1;

__END__

=encoding utf8

=head1 NAME

Mail::DKIM2::MessageStore - Keep message snapshots keyed by Message-Instance

=head1 SYNOPSIS

    use Mail::DKIM2::MessageStore;

    my $store = Mail::DKIM2::MessageStore->new(
        directory => '/var/spool/dkim2/snapshots',
    );
    $store->store($mi_value, $message_data);     # on the way in
    my $snapshot = $store->fetch($mi_value);     # on the way out
    $store->remove($mi_value);

=head1 DESCRIPTION

A filesystem store used by the C<authentication_milter> handlers. The
inbound handler stores each message under its top Message-Instance value;
when the message leaves again, modified by a list or a forwarder, the
outbound handler fetches the snapshot and has
L<Mail::DKIM2::MessageInstance> compute a Recipe between the two. Keys are
the SHA-256 of the unfolded value, under two-character prefix directories.

=head1 METHODS

=head2 new(directory => $path)

C<directory> is required.

=head2 store($mi_value, $message_data)

Writes the snapshot, creating directories as needed. Returns the key.

=head2 fetch($mi_value)

The stored data, or undef.

=head2 remove($mi_value)

Deletes the snapshot. True if it existed.

=head2 rel_path_for_mi($mi_value)

The path of the snapshot relative to the directory.

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025-2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
