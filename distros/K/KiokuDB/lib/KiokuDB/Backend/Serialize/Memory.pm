package KiokuDB::Backend::Serialize::Memory;
BEGIN {
  $KiokuDB::Backend::Serialize::Memory::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Backend::Serialize::Memory::VERSION = '0.57';
use Moose::Role;

use Storable qw(dclone);

use namespace::clean -except => 'meta';

with qw(
    KiokuDB::Backend::Serialize
    KiokuDB::Backend::Role::UnicodeSafe
    KiokuDB::Backend::Role::BinarySafe
    KiokuDB::Backend::TypeMap::Default::Storable
);

sub serialize {
    my ( $self, $entry ) = @_;

    return dclone($entry);
}

sub deserialize {
    my ( $self, $blob ) = @_;

    return defined($blob) && dclone($blob);
}

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Backend::Serialize::Memory

=head1 VERSION

version 0.57

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
