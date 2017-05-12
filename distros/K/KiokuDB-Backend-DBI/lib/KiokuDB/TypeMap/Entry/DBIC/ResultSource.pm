package KiokuDB::TypeMap::Entry::DBIC::ResultSource;
BEGIN {
  $KiokuDB::TypeMap::Entry::DBIC::ResultSource::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::TypeMap::Entry::DBIC::ResultSource::VERSION = '1.23';
use Moose;
# ABSTRACT: KiokuDB::TypeMap::Entry for DBIx::Class::ResultSource objects.

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

                    if ( refaddr($collapser->backend->schema) == refaddr($args{object}->schema) ) {
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

            my $rs = $schema->source(substr($entry->id, length('dbic:schema:rs:')));

            $linker->register_object( $entry => $rs, immortal => 1 );

            return $rs;
        },
        id_method => sub {
            my ( $self, $object ) = @_;

            return 'dbic:schema:rs:' . $object->source_name;
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

KiokuDB::TypeMap::Entry::DBIC::ResultSource - KiokuDB::TypeMap::Entry for DBIx::Class::ResultSource objects.

=head1 VERSION

version 1.23

=head1 DESCRIPTION

This tyepmap entry resolves result source handles symbolically by name.

References to the handle receive a special ID in the form:

    dbic:schema:rs:$name

and are not actually written to storage.

Looking up such an ID causes the backend to dynamically search for such a
resultset in the L<DBIx::Class::Schema>.

=for Pod::Coverage compile

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
