package Geo::Location::IP::Error::Generic;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Object::Pad;

class Geo::Location::IP::Error::Generic;

our $VERSION = 0.004;

field $message :param :reader;

sub throw {
    my ($class, @params) = @_;

    die $class->new(@params);
}

use overload
    q{""} => \&stringify;

sub stringify {
    my $self = shift;

    return $self->message;
}

1;
__END__

=encoding UTF-8

=head1 NAME

Geo::Location::IP::Error::Generic - Generic error class

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  use 5.036;
  use Geo::Location::IP::Database::Reader;
  my $reader = Geo::Location::IP::Database::Reader->new(
    file => '/path/to/Country.mmdb'
  );
  local $@;
  eval {
    my $country_model = $reader->country(ip => '192.0.2.1');
  };
  if (my $e = $@) {
    if ($e isa 'Geo::Location::IP::Error::Generic') {
      warn $e->message;
    }
  }

=head1 DESCRIPTION

A generic error class.

=head1 SUBROUTINES/METHODS

=head2 throw

  Geo::Location::IP::Error::Generic->throw(
    message => "We're outta here!",
  );

Raises an exception with the specified message.

=head2 message

  my $message = $e->message;

Returns the message.

Objects also stringify to their message.

=for Pod::Coverage DOES META new stringify

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
