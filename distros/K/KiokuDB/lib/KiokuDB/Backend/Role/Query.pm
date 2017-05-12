package KiokuDB::Backend::Role::Query;
BEGIN {
  $KiokuDB::Backend::Role::Query::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Backend::Role::Query::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: Backend specific query API

use namespace::clean -except => 'meta';

requires "search";

sub search_filter {
    my ( $self, $stream, @args ) = @_;
    return $stream;
}

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Backend::Role::Query - Backend specific query API

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    with qw(KiokuDB::Backend::Role::Query);

    sub search {
        my ( $self, @args ) = @_;

        # return all entries in the root set matching @args (backend specific)
        return Data::Stream::Bulk::Foo->new(...);
    }

=head1 DESCRIPTION

This role is for backend specific searching. Anything that is not
L<KiokuDB::Backend::Role::Query::Simple> is a backend specific search, be it a
L<Search::GIN::Query>, or something else.

The backend is expected to interpret the search arguments which are passed
through from L<KiokuDB/search> as is, and return a L<Data::Stream::Bulk> of
matching entries.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
