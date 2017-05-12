package KiokuDB::Backend::Role::UnicodeSafe;
BEGIN {
  $KiokuDB::Backend::Role::UnicodeSafe::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Backend::Role::UnicodeSafe::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: An informational role for binary data safe backends.

use namespace::clean -except => 'meta';

# informative

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Backend::Role::UnicodeSafe - An informational role for binary data safe backends.

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    package KiokuDB::Backend::MySpecialBackend;
    use Moose;

    use namespace::clean -except => 'meta';

    with qw(KiokuDB::Backend::Role::UnicodeSafe);

=head1 DESCRIPTION

This backend role is an informational role for backends which can
store unicode perl strings safely.

This means that B<character> strings inserted to the database will not be
retreived as B<byte> strings upon deserialization.

This mostly has to do with L<KiokuDB::Backend::Serialize> variants.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
