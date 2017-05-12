package KiokuDB::Set::Stored;
BEGIN {
  $KiokuDB::Set::Stored::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Set::Stored::VERSION = '0.57';
use Moose;
# ABSTRACT: Stored representation of KiokuDB::Set objects.

use namespace::clean -except => 'meta';

extends qw(KiokuDB::Set::Base);

has _objects => ( is => "ro" );

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Set::Stored - Stored representation of KiokuDB::Set objects.

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    # used internally by L<KiokuDB::TypeMap::Entry::Set>

=head1 DESCRIPTION

This object is the persisted representation of all L<KiokuDB::Set> objects.

It is used internally after collapsing and before expanding, for simplicity.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
