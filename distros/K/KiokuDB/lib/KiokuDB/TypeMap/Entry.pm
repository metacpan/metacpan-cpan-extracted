package KiokuDB::TypeMap::Entry;
BEGIN {
  $KiokuDB::TypeMap::Entry::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::TypeMap::Entry::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: Role for KiokuDB::TypeMap entries

use namespace::clean -except => 'meta';

requires "compile";

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::TypeMap::Entry - Role for KiokuDB::TypeMap entries

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    package KiokuDB::TypeMap::Foo;
    use Moose;

    with qw(KiokuDB::TypeMap::Entry);

    # or just use KiokuDB::TypeMap::Entry::Std

    sub compile {
        ...
    }

=head1 DESCRIPTION

This is the role consumed by all typemap entries.

=head1 REQUIRED METHODS

=over 4

=item compile $class

This method is called by L<KiokuDB::TypeMap::Resolver> for a given class, and
should return a L<KiokuDB::TypeMap::Entry::Compiled> object for collapsing and
expanding the object.

L<KiokuDB::TypeMap::Entry::Std> provides a more concise way of defining typemap entries.

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
