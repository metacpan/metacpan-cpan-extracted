package KiokuDB::Role::UUIDs::LibUUID;
BEGIN {
  $KiokuDB::Role::UUIDs::LibUUID::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Role::UUIDs::LibUUID::VERSION = '0.57';
use Moose::Role;

use Data::UUID::LibUUID 0.05;

use namespace::clean -except => 'meta';

sub generate_uuid { Data::UUID::LibUUID::new_uuid_string() }

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Role::UUIDs::LibUUID

=head1 VERSION

version 0.57

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
