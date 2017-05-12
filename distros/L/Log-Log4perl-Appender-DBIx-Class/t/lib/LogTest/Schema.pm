package LogTest::Schema;
use strict;
use warnings;

use base 'DBIx::Class::Schema';

use Carp;
use Text::xSV;

__PACKAGE__->load_classes;

1;
