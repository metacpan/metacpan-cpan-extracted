package KiokuDB::Role::UUIDs;
BEGIN {
  $KiokuDB::Role::UUIDs::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Role::UUIDs::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: UUID generation role.

use Try::Tiny;

use namespace::clean -except => 'meta';

if ( defined &KiokuDB::SERIAL_IDS and KiokuDB::SERIAL_IDS() ) {
    with qw(KiokuDB::Role::UUIDs::SerialIDs);
} else {
    my $have_libuuid = try { require Data::UUID::LibUUID; 1 };

    my $backend = $have_libuuid ? "LibUUID" : "DataUUID";

    with "KiokuDB::Role::UUIDs::$backend";
}

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Role::UUIDs - UUID generation role.

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    with qw(KiokuDB::Role::UUIDs);

=head1 DESCRIPTION

This role provides UUID assignment.

Depending on the C<$SERIAL_IDS> variable being true at compile time, and
availability of UUID generation module (L<Data::UUID::LibUUID> falling back to
L<Data::UUID>) an implementation role is selected.

=head1 METHODS

=over 4

=item generate_uuid

Create a new UUID

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
