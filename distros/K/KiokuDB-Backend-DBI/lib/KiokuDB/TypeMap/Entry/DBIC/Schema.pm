package KiokuDB::TypeMap::Entry::DBIC::Schema;
BEGIN {
  $KiokuDB::TypeMap::Entry::DBIC::Schema::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::TypeMap::Entry::DBIC::Schema::VERSION = '1.23';
use Moose;
# ABSTRACT: KiokuDB::TypeMap::Entry for DBIx::Class::Schema objects.

use Scalar::Util qw(weaken refaddr);

use namespace::autoclean;

with qw(KiokuDB::TypeMap::Entry);

sub compile {
    my ( $self, $class ) = @_;

    return KiokuDB::TypeMap::Entry::Compiled->new(
        collapse_method => sub {
            my ( $collapser, @args ) = @_;

            $collapser->collapse_first_class(
                sub {
                    my ( $collapser, %args ) = @_;

                    if ( refaddr($collapser->backend->schema) == refaddr($args{object}) ) {
                        return $collapser->make_entry(
                            %args,
                            data => undef,
                            meta => {
                                immortal => 1,
                            },
                        );
                    } else {
                        croak("Referring to foreign DBIC schemas is unsupported");
                    }
                },
                @args,
            );
        },
        expand_method => sub {
            my ( $linker, $entry ) = @_;

            my $schema = $linker->backend->schema;

            $linker->register_object( $entry => $schema, immortal => 1 );

            return $schema;
        },
        id_method => sub {
            my ( $self, $object ) = @_;

            return 'dbic:schema'; # singleton
        },
        refresh_method => sub { },
        entry => $self,
        class => $class,
    );
}

__PACKAGE__->meta->make_immutable;

# ex: set sw=4 et:

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::TypeMap::Entry::DBIC::Schema - KiokuDB::TypeMap::Entry for DBIx::Class::Schema objects.

=head1 VERSION

version 1.23

=head1 DESCRIPTION

This typemap entry handles references to L<DBIx::Class::Schema> as a scoped
singleton.

The ID of the schema is always C<dbic:schema>.

References to L<DBIx::Class::Schema> objects which are not a part of the
underlying L<DBIx::Class> layout are currently not supported, but may be in the
future.

=for Pod::Coverage compile

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
