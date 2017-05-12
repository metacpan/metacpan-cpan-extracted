package t::MyCon;

use strict;
use warnings;
use parent 'Micro::Container';

__PACKAGE__->register(
    't::Bar' => [],
);

1;
