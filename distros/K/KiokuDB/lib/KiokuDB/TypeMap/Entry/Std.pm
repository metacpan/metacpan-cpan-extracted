package KiokuDB::TypeMap::Entry::Std;
BEGIN {
  $KiokuDB::TypeMap::Entry::Std::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::TypeMap::Entry::Std::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: Role for more easily specifying collapse/expand methods

use KiokuDB::TypeMap::Entry::Compiled;

use namespace::clean -except => 'meta';

with qw(
    KiokuDB::TypeMap::Entry
    KiokuDB::TypeMap::Entry::Std::ID
    KiokuDB::TypeMap::Entry::Std::Compile
    KiokuDB::TypeMap::Entry::Std::Intrinsic
);


__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::TypeMap::Entry::Std - Role for more easily specifying collapse/expand methods

=head1 VERSION

version 0.57

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

This role just integrates other roles into a single place for convenience.  The roles
that it integrates are:

=over 4

=item KiokuDB::TypeMap::Entry

=item KiokuDB::TypeMap::Entry::Std::ID

=item KiokuDB::TypeMap::Entry::Std::Compile

=item KiokuDB::TypeMap::Entry::Std::Intrinsic

=back

=head1 SEE ALSO

L<KiokuDB::TypeMap::Entry>
L<KiokuDB::TypeMap::Entry::Std::ID>
L<KiokuDB::TypeMap::Entry::Std::Compile>
L<KiokuDB::TypeMap::Entry::Std::Intrinsic>

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
