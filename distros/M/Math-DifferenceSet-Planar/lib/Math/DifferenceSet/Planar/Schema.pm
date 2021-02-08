package Math::DifferenceSet::Planar::Schema;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

our $VERSION = '0.011';

__PACKAGE__->load_namespaces;

1;
__END__
=head1 NAME

Math::DifferenceSet::Planar::Schema - data schema for planar difference sets

=head1 VERSION

This documentation refers to version 0.011 of
Math::DifferenceSet::Planar::Schema.

=head1 SYNOPSIS

  use Math::DifferenceSet::Planar::Schema;

  $schema = Math::DifferenceSet::Planar::Schema->connect(...);
  $pds    = $schema->resultset('DifferenceSet')->search(...);

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

=back

=head1 AUTHOR

Martin Becker, E<lt>becker-cpan-mp I<at> cozap.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2019-2021 by Martin Becker, Blaubeuren.

This library is free software; you can distribute it and/or modify it
under the terms of the Artistic License 2.0 (see the LICENSE file).

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of merchantability
or fitness for a particular purpose.

=cut
