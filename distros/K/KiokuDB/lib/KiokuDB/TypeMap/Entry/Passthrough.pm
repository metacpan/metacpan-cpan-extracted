package KiokuDB::TypeMap::Entry::Passthrough;
BEGIN {
  $KiokuDB::TypeMap::Entry::Passthrough::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::TypeMap::Entry::Passthrough::VERSION = '0.57';
use Moose;
# ABSTRACT: A typemap entry of objects that will be serialized by the backend.

use Carp qw(croak);

use KiokuDB::TypeMap::Entry::Compiled;

no warnings 'recursion';

use namespace::clean -except => 'meta';

with qw(KiokuDB::TypeMap::Entry);

has intrinsic => (
    isa => "Bool",
    is  => "ro",
    default => 0,
);

sub compile {
    my ( $self, $class ) = @_;

    if ( $self->intrinsic ) {
        return KiokuDB::TypeMap::Entry::Compiled->new(
            collapse_method => sub { $_[1] },
            expand_method   => sub { $_[1]->data }, # only called on an Entry, if the object is just an object, this won't be called
            id_method       => "generate_uuid",
            refresh_method => sub {
                croak "Refreshing Passthrough typemap entries is not supported ($class)";
            },
            entry           => $self,
            class           => $class,
        );
    } else {
        return KiokuDB::TypeMap::Entry::Compiled->new(
            collapse_method => sub {
                my ( $collapser, @args ) = @_;

                $collapser->collapse_first_class(
                    sub {
                        my ( $collapser, %args ) = @_;
                        return $collapser->make_entry(
                            %args,
                            data => $args{object},
                        );
                    },
                    @args,
                );
            },
            expand_method => sub {
                my ( $linker, $entry ) = @_;

                my $obj = $entry->data;

                $linker->register_object( $entry => $obj );

                return $obj;
            },
            id_method => "generate_uuid",
            refresh_method => sub {
                croak "Refreshing Passthrough typemap entries is not supported ($class)";
            },
            entry     => $self,
            class     => $class,
        );
    }
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::TypeMap::Entry::Passthrough - A typemap entry of objects that will be serialized by the backend.

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    KiokuDB::TypeMap->new(
        entires => {
            'Value::Object' => KiokuDB::TypeMap::Entry::Naive->new,
        },
    );

=head1 DESCRIPTION

This typemap entry delegates the handling of certain objects to the backend.

A prime example is L<DateTime> being handled by
L<KiokuDB::Backend::Serialize::Storable>. L<DateTime> has efficient L<Storable>
hooks, and does not refer to any domain objects, so it is safe to assume that
it can just be passed through for serialization.

=head1 ATTRIBUTES

=over 4

=item intrinsic

If true the object will be just left in place.

If false, the object will get its own ID and entry, and the object will be in
the C<data> field of that entry.

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
