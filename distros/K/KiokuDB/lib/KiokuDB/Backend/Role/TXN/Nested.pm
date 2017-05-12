package KiokuDB::Backend::Role::TXN::Nested;
BEGIN {
  $KiokuDB::Backend::Role::TXN::Nested::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Backend::Role::TXN::Nested::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: Informational role for backends supporting rollback of nested transactions.

use namespace::clean -except => 'meta';

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Backend::Role::TXN::Nested - Informational role for backends supporting rollback of nested transactions.

=head1 VERSION

version 0.57

=head1 DESCRIPTION

This role is used during testing to run fixtures testing that a rollback of a
nested transaction doesn't affect its parent transaction.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
