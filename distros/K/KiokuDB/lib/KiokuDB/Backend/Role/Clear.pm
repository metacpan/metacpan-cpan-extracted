package KiokuDB::Backend::Role::Clear;
BEGIN {
  $KiokuDB::Backend::Role::Clear::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Backend::Role::Clear::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: Backend clearing api

use namespace::clean -except => 'meta';

requires "clear";

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Backend::Role::Clear - Backend clearing api

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    package KiokuDB::Backend::MySpecialBackend;
    use Moose;

    use namespace::clean -except => 'meta';

    with qw(
        KiokuDB::Backend
        KiokuDB::Backend::Role::Clear
    );

    sub clear {
        ...
    }

=head1 DESCRIPTION

This backend role provides an api for removing all entries from a backend.

This is optionally used by the dump loader script, and parts of the test suite.

=head1 REQUIRED METHODS

=over 4

=item clear

This method should clear all entries in the backend.

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
