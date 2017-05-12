package Flux::Format;
{
  $Flux::Format::VERSION = '1.03';
}

# ABSTRACT: interface for symmetric two-way formatting of any storage.


use Moo::Role;

use Flux::Storage::Formatted;

requires 'encoder';

requires 'decoder';

sub wrap {
    my $self = shift;
    my ($storage) = @_;

    return Flux::Storage::Formatted->new({ format => $self, storage => $storage });
}


1;

__END__

=pod

=head1 NAME

Flux::Format - interface for symmetric two-way formatting of any storage.

=head1 VERSION

version 1.03

=head1 SYNOPSIS

    $json_storage = $json_format->wrap($storage);
    $json_storage->write({ a => "b" });
    $in = $json_storage->in("client1");
    $data = $in->read(); # data is decoded again

=head1 DESCRIPTION

There's a common need to store complex data into storages which can only store strings.

Simple C<Flux::Mapper> is not enough, because storage should both serialize and deserialize data in the same way. C<Flux::Format> provides the common interface for objects which can decorate C<Flux::Storage> objects into storages which can both write data through a serializing mapper and create reading streams which deserialize that data on reads.

Usual method to create new formatters is to apply this role and implement C<encoder> and C<decoder> methods.

=head1 METHODS

=over

=item B<< encoder() >>

This method should return a mapper which will be applied to any item written into wrapped storage.

Mapper is expected to support C<Flux::Mapper> interface and to transform data in 1-to-1 fashion.

=item B<< decoder() >>

This method should return a mapper which will be applied to any item read from an input stream created from a wrapped storage.

Mapper is expected to support C<Flux::Mapper> interface to transform data in 1-to-1 fashion.

=item B<< wrap($storage) >>

Construct a formatted storage. Returns a new storage object.

Resulting object will transform all writes using C<encoder> and generate input streams which are pre-decoded by C<decoder>.

Unlike C<encoder> and C<decoder>, this method is provided by this role.

=back

=head1 AUTHOR

Vyacheslav Matyukhin <me@berekuk.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
