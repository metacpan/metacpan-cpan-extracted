package KiokuDB::TypeMap::Entry::DBIC::ResultSet;
BEGIN {
  $KiokuDB::TypeMap::Entry::DBIC::ResultSet::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::TypeMap::Entry::DBIC::ResultSet::VERSION = '1.23';
use Moose;
# ABSTRACT: KiokuDB::TypeMap::Entry for DBIx::Class::ResultSet objects

use JSON;
use Scalar::Util qw(weaken);

use namespace::autoclean;

extends qw(KiokuDB::TypeMap::Entry::Naive);

sub compile_collapse_body {
    my ( $self, @args ) = @_;

    my $sub = $self->SUPER::compile_collapse_body(@args);

    return sub {
        my ( $self, %args ) = @_;

        my $rs = $args{object};

        my $clone = $rs->search_rs;

        # clear all cached data
        $clone->set_cache;

        $self->$sub( %args, object => $clone );
    };
}

__PACKAGE__->meta->make_immutable;

# ex: set sw=4 et:

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::TypeMap::Entry::DBIC::ResultSet - KiokuDB::TypeMap::Entry for DBIx::Class::ResultSet objects

=head1 VERSION

version 1.23

=head1 DESCRIPTION

The result set is cloned, the clone will have its cache cleared, and then it is
simply serialized normally. This is the only L<DBIx::Class> related object that
is literally stored in the database, as it represents a memory resident object,
not a database resident one.

=for Pod::Coverage compile_collapse_body

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
