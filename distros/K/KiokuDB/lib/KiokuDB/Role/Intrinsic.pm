package KiokuDB::Role::Intrinsic;
BEGIN {
  $KiokuDB::Role::Intrinsic::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Role::Intrinsic::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: A role for value objects

use namespace::clean -except => 'meta';



__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Role::Intrinsic - A role for value objects

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    with qw(KiokuDB::Role::Intrinsic);

=head1 DESCRIPTION

When L<KiokuDB> detects this role on objects they are collapsed into their
parent by default, without needing an explicit typemap entry.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
