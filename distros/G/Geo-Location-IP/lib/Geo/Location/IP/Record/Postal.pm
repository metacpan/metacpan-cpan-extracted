package Geo::Location::IP::Record::Postal;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Object::Pad;

class Geo::Location::IP::Record::Postal;

our $VERSION = 0.003;

apply Geo::Location::IP::Role::Record::HasConfidence;

field $code :param :reader = undef;

sub _from_hash ($class, $hash_ref) {
    return $class->new(
        code       => $hash_ref->{code}       // undef,
        confidence => $hash_ref->{confidence} // undef,
    );
}

use overload
    q{""} => \&stringify;

sub stringify {
    my $self = shift;

    return $self->code;
}

1;
__END__

=encoding UTF-8

=head1 NAME

Geo::Location::IP::Record::Postal - Postal details

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Geo::Location::IP::Database::Reader;
  my $reader = Geo::Location::IP::Database::Reader->new(
    file => '/path/to/City.mmdb',
  );
  eval {
    my $city_model = $reader->city(ip => '1.2.3.4');
    my $postal     = $city_model->postal;
  };

=head1 DESCRIPTION

This class contains postal details associated with an IP address.

All fields may be undefined.

=head1 SUBROUTINES/METHODS

=head2 new

  my $postal = Geo::Location::IP::Record::Postal->new(
    code       => 'SW1A 0AA'.
    confidence => 100,
  );

Creates a new postal record.

=head2 code

  my $code = $postal->code;

Returns the location's postal code as a string.

=head2 confidence

  my $confidence = $postal->confidence;

Returns a value in the range from 0 to 100 that indicates the confidence that
the postal details are correct.

=for Pod::Coverage DOES META stringify

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
