package KiokuDB::Error;
BEGIN {
  $KiokuDB::Error::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Error::VERSION = '0.57';
use Moose::Role;

use namespace::clean -except => 'meta';

with qw(Throwable);

requires qw(as_string);

# ex: set sw=4 et:

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Error

=head1 VERSION

version 0.57

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
