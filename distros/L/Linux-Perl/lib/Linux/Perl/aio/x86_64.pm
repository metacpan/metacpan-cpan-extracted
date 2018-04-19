package Linux::Perl::aio::x86_64;

use strict;
use warnings;

use parent (
    'Linux::Perl::aio::bits64',
);

use constant {
    NR_io_setup => 206,
    NR_io_destroy => 207,
    NR_io_getevents => 208,
    NR_io_submit    => 209,
    NR_io_cancel    => 210,
};

#----------------------------------------------------------------------

package Linux::Perl::aio::Control::x86_64;

use parent -norequire => 'Linux::Perl::aio::Control::bits64';

1;
