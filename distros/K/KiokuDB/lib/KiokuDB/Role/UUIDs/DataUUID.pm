package KiokuDB::Role::UUIDs::DataUUID;
BEGIN {
  $KiokuDB::Role::UUIDs::DataUUID::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Role::UUIDs::DataUUID::VERSION = '0.57';
use Moose::Role;

use Data::UUID 1.203;

use namespace::clean -except => 'meta';

my $uuid_gen = Data::UUID->new;

sub generate_uuid { $uuid_gen->create_str }

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Role::UUIDs::DataUUID

=head1 VERSION

version 0.57

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
