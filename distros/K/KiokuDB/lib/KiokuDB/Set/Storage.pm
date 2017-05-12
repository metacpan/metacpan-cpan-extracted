package KiokuDB::Set::Storage;
BEGIN {
  $KiokuDB::Set::Storage::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Set::Storage::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: Role for KiokuDB::Sets that are tied to storage.

use Set::Object;

use namespace::clean -except => 'meta';

with qw(KiokuDB::Set);

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Set::Storage - Role for KiokuDB::Sets that are tied to storage.

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    # informational role, used internally

=head1 DESCRIPTION

This role is informational, and implemented by L<KiokuDB::Set::Deferred> and
L<KiokuDB::Set::Loaded>

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
