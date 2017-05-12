#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015 -- leonerd@leonerd.org.uk

package IO::Async::Resolver::DNS::Constants;

use strict;
use warnings;

our $VERSION = '0.06';

my %constants = (
   ERR_NO_HOST       => 1,
   ERR_NO_ADDRESS    => 2,
   ERR_TEMPORARY     => 3,
   ERR_UNRECOVERABLE => 4,
);

require constant;
constant->import( \%constants );

use Exporter 'import';
our @EXPORT_OK = keys %constants;

0x55AA;
