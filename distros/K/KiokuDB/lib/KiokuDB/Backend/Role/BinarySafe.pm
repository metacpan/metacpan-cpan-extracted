package KiokuDB::Backend::Role::BinarySafe;
BEGIN {
  $KiokuDB::Backend::Role::BinarySafe::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Backend::Role::BinarySafe::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: An informational role for binary data safe backends.

use namespace::clean -except => 'meta';

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Backend::Role::BinarySafe - An informational role for binary data safe backends.

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    package KiokuDB::Backend::MySpecialBackend;
    use Moose;

    use namespace::clean -except => 'meta';

    with qw(KiokuDB::Backend::Role::BinarySafe);

=head1 DESCRIPTION

This backend is an informational role for backends which can store arbitrary
binary strings, especially utf8 data as bytes (without reinterpreting it as
unicode strings when inflating).

This mostly has to do with L<KiokuDB::Backend::Serialize> variants (for example
L<KiokuDB::Backend::Serialize::Storable> is binary safe, while
L<KiokuDB::Backend::Serialize::JSON> is not).

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
