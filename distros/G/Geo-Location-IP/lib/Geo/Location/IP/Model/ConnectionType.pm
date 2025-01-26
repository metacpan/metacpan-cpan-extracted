package Geo::Location::IP::Model::ConnectionType;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Object::Pad;

class Geo::Location::IP::Model::ConnectionType;

our $VERSION = 0.001;

apply Geo::Location::IP::Role::HasIPAddress;

field $connection_type :param :reader = undef;

#<<<
ADJUST :params (:$raw = {}) {
    if (exists $raw->{connection_type}) {
        $connection_type = $raw->{connection_type};
    }
}
#>>>

1;
__END__

=encoding UTF-8

=head1 NAME

Geo::Location::IP::Model::ConnectionType - Details about an IP connection

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Geo::Location::IP::Database::Reader;
  my $reader = Geo::Location::IP::Database::Reader->new(
    file => '/path/to/Connection-Type.mmdb',
  );
  eval {
    my $ct_model = $reader->connection_type(ip => '1.2.3.4');
    my $type     = $ct_model->connection_type;
    printf "connection type is %s\n", $type;
  };

=head1 DESCRIPTION

This class contains details about an IP connection.

=head1 SUBROUTINES/METHODS

=head2 new

  my $ct_model = Geo::Location::IP::Model::ConnectionType->new(
    connection_type => 'Dialup'.
    ip_address      => $ip_address,
  );

Creates a new object with data from an IP address query in a Connection-Type
database.

All fields may contain undefined values.

=head2 connection_type

  my $type = $ct_model->connection_type;

Returns the connection type as a string.

See L<Geo::Location::IP::Record::Traits> for a list of connection types.

=head2 ip_address

  my $ip_address = $ct_model->ip_address;

Returns the IP address the data is for as a L<Geo::Location::IP::Address>
object.

=for Pod::Coverage DOES META

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
