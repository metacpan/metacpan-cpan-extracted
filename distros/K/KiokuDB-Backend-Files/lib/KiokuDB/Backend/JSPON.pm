#!/usr/bin/perl

package KiokuDB::Backend::JSPON;
use Moose;

use namespace::clean -except => 'meta';

our $VERSION = "0.06";

extends qw(KiokuDB::Backend::Files);

has '+serializer' => ( default => "json" );

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=head1 NAME

KiokuDB::Backend::JSPON - Deprecated, use L<KiokuDB::Backend::Files>

=head1 DESCRIPTION

This is just the L<KiokuDB::Backend::Files> backend with the serializer default
set to C<json> for backwards compatibility.

L<http://www.jspon.org/|JSPON> is a standard for encoding object graphs in
JSON.

The representation is based on explicit ID based references, and so is simple
enough to be stored in JSON.

=cut
