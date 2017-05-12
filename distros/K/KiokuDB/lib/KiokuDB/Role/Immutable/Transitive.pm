package KiokuDB::Role::Immutable::Transitive;
BEGIN {
  $KiokuDB::Role::Immutable::Transitive::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Role::Immutable::Transitive::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: A role for immutable objects that only point at other such objects.

use namespace::clean -except => 'meta';

with qw(
    KiokuDB::Role::Immutable
    KiokuDB::Role::Cacheable
);


# ex: set sw=4 et:

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Role::Immutable::Transitive - A role for immutable objects that only point at other such objects.

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    with qw(KiokuDB::Role::Immutable::Transitive);

=head1 DESCRIPTION

This role makes a stronger promise than L<KiokuDB::Role::Immutable>, namely
that this object and all objects it points to are immutable.

These objects can be freely cached as live instances, since none of the data
they keep live is ever updated.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
