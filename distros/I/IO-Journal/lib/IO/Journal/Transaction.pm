# IO::Journal::Transaction
#  Provides support for atomic transactions
#
# $Id: Transaction.pm 8239 2009-07-26 03:28:55Z FREQUENCY@cpan.org $

package IO::Journal::Transaction;

use strict;
use warnings;
use Carp ();

=head1 NAME

IO::Journal::Transaction - Perl interface to IO::Journal transactions

=head1 VERSION

Version 0.2 ($Id: Transaction.pm 8239 2009-07-26 03:28:55Z FREQUENCY@cpan.org $)

=cut

use version; our $VERSION = qv('0.2');

=head1 DESCRIPTION

This module provides the facilities for handling C<IO::Journal> transactions.
Operations can be added to the transaction object via the exposed interface;
they can then be either saved to file (commit) or simply discarded (rollback).

=head1 SYNOPSIS

  my $trans = $journal->begin_transaction();
  $trans->write("Hello ");
  $trans->write("World\n");
  $trans->commit(); # may die
  # File either contains "Hello World\n" or nothing

  # Transactions can be rolled back even after committing! (But only if we
  # have a current handle to the transaction)
  $trans->rollback();

=cut

# This is the code that actually bootstraps the module and exposes
# the interface for the user. XSLoader is believed to be more
# memory efficient than DynaLoader.
use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

=head1 METHODS

=head1 AUTHOR

Jonathan Yu E<lt>frequency@cpan.orgE<gt>

=head1 SEE ALSO

L<IO::Journal>

=head1 SUPPORT

Please file bugs for this module under the C<IO::Journal> distribution. For
more information, see L<IO::Journal>'s perldoc.

=head1 LICENSE

This has the same copyright and licensing terms as L<IO::Journal>.

=head1 DISCLAIMER OF WARRANTY

The software is provided "AS IS", without warranty of any kind, express or
implied, including but not limited to the warranties of merchantability,
fitness for a particular purpose and noninfringement. In no event shall the
authors or copyright holders be liable for any claim, damages or other
liability, whether in an action of contract, tort or otherwise, arising from,
out of or in connection with the software or the use or other dealings in
the software.

=cut

1;
