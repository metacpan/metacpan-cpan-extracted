use strict;
use warnings;

package t::lib::Child1;

use t::lib::Mother -base;

our @EXPORT_OK = 'hi';

sub hi
{
    'Hi!'
}


1;
