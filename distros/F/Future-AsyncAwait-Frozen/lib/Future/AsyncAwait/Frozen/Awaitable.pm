#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019 -- leonerd@leonerd.org.uk

package Future::AsyncAwait::Frozen::Awaitable;

use strict;
use warnings;

our $VERSION = '0.36';

if( defined eval { require Role::Tiny } ) {
   Role::Tiny->import;

   requires( qw(
      AWAIT_CLONE AWAIT_NEW_DONE AWAIT_NEW_FAIL

      AWAIT_DONE AWAIT_FAIL AWAIT_GET
      AWAIT_IS_READY AWAIT_ON_READY
      AWAIT_IS_CANCELLED AWAIT_ON_CANCEL
   ) );
}

0x55AA;
