package Geo::Location::IP::Role::HasIPAddress;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Object::Pad;

role Geo::Location::IP::Role::HasIPAddress;

our $VERSION = 0.004;

field $ip_address :param :reader;

1;
__END__

=encoding UTF-8

=head1 NAME

Geo::Location::IP::Role::HasIPAddress - Add an "ip_address" field

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  apply Geo::Location::IP::Role::HasIPAddress;

=head1 DESCRIPTION

A mixin that adds the field C<ip_address> to a class.

=head1 SUBROUTINES/METHODS

=head2 ip_address

  my $ip_address = $obj->ip_address;

Returns the IP address as a L<Geo::Location::IP::Address> object.

=for Pod::Coverage DOES META new

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None.

=head1 BUGS AND LIMITATIONS

None known.

=head1 AUTHOR

Andreas Vögele E<lt>voegelas@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2025 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
