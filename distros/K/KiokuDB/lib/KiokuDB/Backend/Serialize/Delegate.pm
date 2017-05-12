package KiokuDB::Backend::Serialize::Delegate;
BEGIN {
  $KiokuDB::Backend::Serialize::Delegate::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Backend::Serialize::Delegate::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: Use a KiokuDB::Serializer object instead of a role to handle serialization in a backend.

use KiokuDB::Serializer;

use namespace::clean -except => 'meta';

#with qw(KiokuDB::Backend::Serialize);

has serializer => (
    does    => "KiokuDB::Backend::Serialize",
    is      => "ro",
    coerce  => 1,
    default => "storable",
    handles => [qw(serialize deserialize)],
);

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Backend::Serialize::Delegate - Use a KiokuDB::Serializer object instead of a role to handle serialization in a backend.

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    package MyBackend;
    use Moose;

    with qw(
        ...
        KiokuDB::Backend::Serialize::Delegate
    );



    MyBackend->new(
        serializer => "yaml",
    );

=head1 DESCRIPTION

This role provides a C<serialzier> attribute (by default
L<KiokuDB::Serializer::Storable>) with coercions from a moniker string for easy
serialization format selection.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
