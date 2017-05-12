package DBIx::Class::KiokuDB::EntryProxy;
BEGIN {
  $DBIx::Class::KiokuDB::EntryProxy::AUTHORITY = 'cpan:NUFFIN';
}
# ABSTRACT: A proxying result class for KiokuDB objects
$DBIx::Class::KiokuDB::EntryProxy::VERSION = '1.23';
use strict;
use warnings;

use namespace::clean;

use base qw(DBIx::Class);

sub inflate_result {
    my ( $self, $source, $data ) = @_;

    my $handle = $source->schema->kiokudb_handle;

    if ( ref( my $obj = $handle->id_to_object( $data->{id} ) )  ) {
        return $obj;
    } else {
        my $entry = $handle->backend->deserialize($data->{data});
        return $handle->linker->expand_object($entry);
    }
}

sub new {
    croak("Creating new rows via the result set makes no sense, insert them with KiokuDB::insert instead");
}

# ex: set sw=4 et:

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::KiokuDB::EntryProxy - A proxying result class for KiokuDB objects

=head1 VERSION

version 1.23

=head1 SYNOPSIS

    my $kiokudb_object = $schema->resultset("entries")->find($id);

=head1 DESCRIPTION

This class implements the necessary glue to properly inflate resultsets for
L<KiokuDB> object into proper instances using L<KiokuDB>.

=for Pod::Coverage new
inflate_result

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
