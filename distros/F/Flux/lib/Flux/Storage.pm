package Flux::Storage;
{
  $Flux::Storage::VERSION = '1.03';
}

# ABSTRACT: interface to any flux storage.

use Moo::Role;
with 'Flux::Out';

requires 'in';


1;

__END__

=pod

=head1 NAME

Flux::Storage - interface to any flux storage.

=head1 VERSION

version 1.03

=head1 SYNOPSIS

    $storage->write($line);
    $storage->write_chunk(\@lines);

    $stream = $storage->in($cursor_or_client_name);

=head1 DESCRIPTION

C<Flux::Storage> is the role which every stream storage must implement.

Objects implementing this role can act as output streams, and they can also generate associated input stream with C<in> method.

=head1 INTERFACE

=over

=item B<in(...)>

Construct an input stream for this storage.

Most storages are able to have several different input streams with different positions in the storage.

C<in> method usually accepts either client's name (as plain string), or, in some cases, a more complicated cursor object which identifies an appropricate input stream.

=back

=head1 AUTHOR

Vyacheslav Matyukhin <me@berekuk.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
