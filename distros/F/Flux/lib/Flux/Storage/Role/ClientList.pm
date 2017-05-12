package Flux::Storage::Role::ClientList;
{
  $Flux::Storage::Role::ClientList::VERSION = '1.03';
}

# ABSTRACT: common methods for storages with named clients


use Moo::Role;

requires 'client_names';

sub register_client($$) {
}

sub unregister_client($$) {
}

sub has_client {
    my $self = shift;
    my ($name) = @_;

    return grep { $_ eq $name } $self->client_names;
}


1;

__END__

=pod

=head1 NAME

Flux::Storage::Role::ClientList - common methods for storages with named clients

=head1 VERSION

version 1.03

=head1 SYNOPSIS

    @client_names = $storage->client_names;

    $in = $storage->stream($client_name);

    $storage->register_client($client_name);
    $storage->unregister_client($client_name);

    $storage->has_client($client_name);

=head1 DESRIPTION

Some storages are able to generate stream by client's name. This role guarantees that storage implements some common methods for listing and registering storage clients.

=head1 METHODS

=over

=item B<< client_names() >>

Get all storage client names as a plain list.

=item B<< register_client($name) >>

Register a new client in the storage.

Default implementation does nothing.

=item B<< unregister_client($name) >>

Unregister a client from the storage.

Default implementation does nothing.

=item B<< has_client($name) >>

Check whether the storage has a client with given name.

Default implementation uses C<client_names()>, but you can override it for the sake of performance.

=back

=head1 AUTHOR

Vyacheslav Matyukhin <me@berekuk.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
