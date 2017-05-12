package KiokuDB::Backend::Serialize::Storable;
BEGIN {
  $KiokuDB::Backend::Serialize::Storable::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Backend::Serialize::Storable::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: Storable based serialization of KiokuDB::Entry objects.

use Storable qw(nfreeze thaw nstore_fd fd_retrieve);

use namespace::clean -except => 'meta';

with qw(
    KiokuDB::Backend::Serialize
    KiokuDB::Backend::Role::UnicodeSafe
    KiokuDB::Backend::Role::BinarySafe
    KiokuDB::Backend::TypeMap::Default::Storable
);

sub serialize {
    my ( $self, $entry ) = @_;

    return nfreeze($entry);
}

sub deserialize {
    my ( $self, $blob ) = @_;

    return thaw($blob);
}

sub serialize_to_stream {
    my ( $self, $fh, $entry ) = @_;
    nstore_fd($entry, $fh);
}

sub deserialize_from_stream {
    my ( $self, $fh ) = @_;

    if ( $fh->eof ) {
        return;
    } else {
        return fd_retrieve($fh);
    }
}

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Backend::Serialize::Storable - Storable based serialization of KiokuDB::Entry objects.

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    package MyBackend;

    with qw(KiokuDB::Backend::Serialize::Storable;

=head1 DESCRIPTION

This role provides L<Storable> based serialization of L<KiokuDB::Entry> objects
for a backend, with streaming capabilities.

L<KiokuDB::Backend::Serialize::Delegate> is preferred to using this directly.

=head1 METHODS

=over 4

=item serialize $entry

Uses L<Storable/nstore>

=item deserialize $blob

Uses L<Storable/thaw>

=item serialize_to_stream $fh, $entry

Uses L<Storable/nstore_fd>.

=item deserialize_from_stream $fh

Uses L<Storable/fd_retrieve>.

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
