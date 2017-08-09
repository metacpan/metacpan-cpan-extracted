# Copyright (c) 2012-2017 Martin Becker, Blaubeuren.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

package Math::Logic::Ternary::Calculator::Version;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.004';
our $NAME    = 'Ternary Calculator';

sub NAME      {  $NAME            }
sub long_name { "$NAME v$VERSION" }

1;
__END__
=head1 NAME

Math::Logic::Ternary::Calculator::Version - calculator name and version

=head1 VERSION

This documentation refers to version 0.004 of
Math::Logic::Ternary::Calculator::Version.

=head1 SYNOPSIS

  use Math::Logic::Ternary::Calculator::Version;

  $version   = Math::Logic::Ternary::Calculator::Version->VERSION;
  $name      = Math::Logic::Ternary::Calculator::Version->NAME;
  $long_name = Math::Logic::Ternary::Calculator::Version->long_name;

=head1 DESCRIPTION

TODO

=head2 Exports

None.

=head1 SEE ALSO

=over 4

=item L<Math::Logic::Ternary::Calculator>

=back

=head1 AUTHOR

Martin Becker E<lt>becker-cpan-mpE<64>cozap.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2017 by Martin Becker, Blaubeuren.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
