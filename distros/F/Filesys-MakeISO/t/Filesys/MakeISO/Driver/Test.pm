package Filesys::MakeISO::Driver::Test;

# test driver

use strict;
use warnings;

use base 'Filesys::MakeISO';


sub new {
    my ($class, %arg) = @_;

    return bless({}, $class);
}

sub make_iso { 1 }


1;
