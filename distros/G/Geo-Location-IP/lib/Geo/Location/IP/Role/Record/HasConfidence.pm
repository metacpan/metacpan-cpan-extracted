package Geo::Location::IP::Role::Record::HasConfidence;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Object::Pad;

role Geo::Location::IP::Role::Record::HasConfidence;

our $VERSION = 0.002;

field $confidence :param :reader = undef;

1;
__END__

=encoding UTF-8

=head1 NAME

Geo::Location::IP::Role::Record::HasConfidence - Add a "confidence" field

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  apply Geo::Location::IP::Role::Record::HasConfidence;

=head1 DESCRIPTION

A mixin that adds the numeric field C<confidence> to a class.

=head1 SUBROUTINES/METHODS

=head2 confidence

  my $confidence = $obj->confidence;

Returns a value in the range from 0 to 100 that indicates the confidence that
the object has been correctly located.  Returns the undefined value if the
confidence is not available.

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
