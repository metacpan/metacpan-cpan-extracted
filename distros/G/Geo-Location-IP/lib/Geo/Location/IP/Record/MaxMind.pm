package Geo::Location::IP::Record::MaxMind;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Object::Pad;

class Geo::Location::IP::Record::MaxMind;

our $VERSION = 0.005;

field $queries_remaining :param :reader = undef;

sub _from_hash ($class, $hash_ref) {
    return $class->new(queries_remaining => $hash_ref->{queries_remaining}
            // undef);
}

1;
__END__

=encoding UTF-8

=head1 NAME

Geo::Location::IP::Record::MaxMind - MaxMind account data

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  my $maxmind = Geo::Location::IP::Record::MaxMind->new(
    queries_remaining => 9999,
  );

=head1 DESCRIPTION

This class contains data returned from a web service query.

All fields may be undefined.

=head1 SUBROUTINES/METHODS

=head2 new

  my $maxmind = Geo::Location::IP::Record::MaxMind->new(
    queries_remaining => 9999,
  );

Creates a new MaxMind record.

=head2 queries_remaining

  my $queries_remaining = $maxmind->queries_remaining;

Returns the number of queries remaining for a web service end point.

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
