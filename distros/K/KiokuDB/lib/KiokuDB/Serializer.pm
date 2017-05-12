package KiokuDB::Serializer;
BEGIN {
  $KiokuDB::Serializer::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Serializer::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: Standalone serializer object

use Carp qw(croak);

use Class::Load ();
use Moose::Util::TypeConstraints;

use namespace::clean -except => 'meta';

with qw(KiokuDB::Backend::Serialize);

requires "serialize_to_stream";
requires "deserialize_from_stream";

my %types = (
    storable => "KiokuDB::Serializer::Storable",
    json     => "KiokuDB::Serializer::JSON",
    yaml     => "KiokuDB::Serializer::YAML",
);

coerce( __PACKAGE__,
    from Str => via {
        my $class = $types{lc($_)} or croak "unknown format: $_";;
        Class::Load::load_class($class);
        $class->new;
    },
    from HashRef => via {
        my %args = %$_;
        my $class = $types{lc(delete $args{format})} or croak "unknown format: $args{format}";
        Class::Load::load_class($class);
        $class->new(%args);
    },
);

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Serializer - Standalone serializer object

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    Backend->new(
        serializer => KiokuDB::Serializer::Storable->new( ... ),
    );

=head1 DESCRIPTION

This role is for objects which perform the serialization roles (e.g.
L<KiokuDB::Backend::Serialize::Storable>) but can be used independently.

This is used by L<KiokuDB::Backend::Serialize::Delegate> and
L<KiokuDB::Cmd::DumpFormatter>.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
