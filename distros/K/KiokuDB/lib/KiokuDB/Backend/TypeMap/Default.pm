package KiokuDB::Backend::TypeMap::Default;
BEGIN {
  $KiokuDB::Backend::TypeMap::Default::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Backend::TypeMap::Default::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: A role for backends with a default typemap

use namespace::clean -except => 'meta';

has default_typemap => (
    does => "KiokuDB::Role::TypeMap",
    is   => "ro",
    required   => 1,
    lazy_build => 1,
);

requires "_build_default_typemap";

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Backend::TypeMap::Default - A role for backends with a default typemap

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    package MyBackend;

    with qw(
        ...
        KiokuDB::Backend::TypeMap::Default
    );

    sub _build_default_typemap {
        ...
    }

=head1 DESCRIPTION

This role requires that you implement a single method,
C<_build_default_typemap> that will return a L<KiokuDB::TypeMap> instance.

See L<KiokuDB::TypeMap::Default> for details.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
