package Math::DifferenceSet::Planar::Schema;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

our $VERSION = '1.002';

__PACKAGE__->load_namespaces;

1;
__END__

=head1 NAME

Math::DifferenceSet::Planar::Schema - data schema for planar difference sets

=head1 VERSION

This documentation refers to version 1.002 of
Math::DifferenceSet::Planar::Schema.

=head1 SYNOPSIS

  use Math::DifferenceSet::Planar::Schema;

  $schema = Math::DifferenceSet::Planar::Schema->connect(...);
  $pds    = $schema->resultset('DifferenceSet')->search(...);
  $spc    = $schema->resultset('DifferenceSetSpace')->search(...);
  $dbv    = $schema->resultset('DatabaseVersion')->search(...);

=head1 DESCRIPTION

This module is the DBIx::Class schema module for the
Math::DifferenceSet::Planar::Data backend.  Application code is not
supposed to use it directly.

=head1 SEE ALSO

=over 4

=item *

L<DBIx::Class::Schema> - base class.

=item *

L<Math::DifferenceSet::Planar::Schema::Result::DifferenceSet> - result class.

=item *

L<Math::DifferenceSet::Planar::Schema::Result::DifferenceSetSpace> -
another result class.

=item *

L<Math::DifferenceSet::Planar::Schema::Result::DatabaseVersion> -
yet another result class.

=back

=head1 AUTHOR

Martin Becker, E<lt>becker-cpan-mp I<at> cozap.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2019-2024 by Martin Becker, Blaubeuren.

This library is free software; you can distribute it and/or modify it
under the terms of the Artistic License 2.0 (see the LICENSE file).

The licence grants freedom for related software development but does
not cover incorporating code or documentation into AI training material.
Please contact the copyright holder if you want to use the library whole
or in part for other purposes than stated in the licence.

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of merchantability
or fitness for a particular purpose.

=cut
