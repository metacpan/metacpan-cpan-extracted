package KiokuDB::TypeMap::Shadow;
BEGIN {
  $KiokuDB::TypeMap::Shadow::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::TypeMap::Shadow::VERSION = '0.57';
use Moose;
# ABSTRACT: Try a list of KiokuDB::TypeMaps in order

use namespace::clean -except => 'meta';

with qw(KiokuDB::Role::TypeMap);

has typemaps => (
    does => "ArrayRef[KiokuDB::Role::TypeMap]",
    is   => "ro",
    required => 1,
);

sub resolve {
    my ( $self, @args ) = @_;

    foreach my $typemap ( @{ $self->typemaps } ) {
        if ( my $entry = $typemap->resolve(@args) ) {
            return $entry;
        }
    }

    return;
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::TypeMap::Shadow - Try a list of KiokuDB::TypeMaps in order

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    KiokuDB->new(
        backend => ...,
        typemap => KiokuDB::TypeMap::Shadow->new(
            typemaps => [
                $first,
                $second,
            ],
        ),
    );

=head1 DESCRIPTION

This class is useful for performing mixin inheritance like merging of typemaps,
by shadowing an ordered list.

This is used internally to overlay the user typemap on top of the
L<KiokuDB::TypeMap::Default> instance provided by the backend.

This differs from using C<includes> in L<KiokuDB::TypeMap> because that
inclusion is computed symmetrically, like roles.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
