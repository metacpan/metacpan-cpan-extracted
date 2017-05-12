package KiokuDB::Backend::Serialize;
BEGIN {
  $KiokuDB::Backend::Serialize::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Backend::Serialize::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: Serialization role for backends

use Class::Load ();
use Moose::Util::TypeConstraints;

use namespace::clean -except => 'meta';

requires qw(serialize deserialize);

my %types = (
    storable => "KiokuDB::Serializer::Storable",
    json     => "KiokuDB::Serializer::JSON",
    yaml     => "KiokuDB::Serializer::YAML",
    memory   => "KiokuDB::Serializer::Memory",
);

coerce( __PACKAGE__,
    from Str => via {
        my $class = $types{lc($_)};
        Class::Load::load_class($class);
        $class->new;
    },
    from HashRef => via {
        my %args = %$_;
        my $class = $types{lc(delete $args{format})};
        Class::Load::load_class($class);
        $class->new(%args);
    },
);

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Backend::Serialize - Serialization role for backends

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    package KiokuDB::Backend::Serialize::Foo;
    use Moose::Role;

    use Foo;

    use namespace::clean -except => 'meta';

    with qw(KiokuDB::Backend::Serialize);

    sub serialize {
        my ( $self, $entry ) = @_;

        Foo::serialize($entry)
    }

    sub deserialize {
        my ( $self, $blob ) = @_;

        Foo::deserialize($blob);
    }

=head1 DESCRIPTION

This role provides provides a consistent way to use serialization modules to
handle backend serialization.

See L<KiokuDB::Backend::Serialize::Storable>,
L<KiokuDB::Backend::Serialize::YAML> and L<KiokuDB::Backend::Serialize::JSON>
for examples.

=head1 REQUIRED METHODS

=over 4

=item serializate $entry

Takes a L<KiokuDB::Entry> as an argument. Should return a value suitable for
storage by the backend.

=item deserialize $blob

Takes whatever C<serializate> returned and should inflate and return a
L<KiokuDB::Entry>.

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
