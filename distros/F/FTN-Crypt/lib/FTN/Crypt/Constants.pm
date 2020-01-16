# FTN::Crypt::Constants - Common constants for the FTN::Crypt module
#
# Copyright (C) 2019 by Petr Antonov
#
# This library is free software; you can redistribute it and/or modify it
# under the same terms as Perl 5.10.0. For more details, see the full text
# of the licenses at https://opensource.org/licenses/Artistic-1.0, and
# http://www.gnu.org/licenses/gpl-2.0.html.
#
# This package is provided "as is" and without any express or implied
# warranties, including, without limitation, the implied warranties of
# merchantability and fitness for a particular purpose.
#

package FTN::Crypt::Constants;

use strict;
use warnings;
use v5.10.1;

#----------------------------------------------------------------------#

=head1 NAME

FTN::Crypt::Constants - Common constants for the L<FTN::Crypt> module.

=head1 SYNOPSIS

    use FTN::Crypt::Constants;

    $FTN::Crypt::Constants::ENC_METHODS{PGP5}; # true

=cut

#----------------------------------------------------------------------#

=head1 CONSTANTS

=over 4

=item * C<%ENC_METHODS> - supported encryption methods.

=item * C<$ENC_NODELIST_FLAG> - nodelist flag.

=item * C<$ENC_MESSAGE_KLUDGE> - message encryption kludge.

=back

=cut

our %ENC_METHODS = (
    'PGP2' => 1,
    'PGP5' => 1,
    'GnuPG' => 1,
);

our $ENC_NODELIST_FLAG = 'ENCRYPT';
our $ENC_MESSAGE_KLUDGE = 'ENC';

1;
__END__

=head1 AUTHOR

Petr Antonov, E<lt>pietro@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Petr Antonov

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses at L<https://opensource.org/licenses/Artistic-1.0>, and
L<http://www.gnu.org/licenses/gpl-2.0.html>.

This package is provided "as is" and without any express or implied
warranties, including, without limitation, the implied warranties of
merchantability and fitness for a particular purpose.
