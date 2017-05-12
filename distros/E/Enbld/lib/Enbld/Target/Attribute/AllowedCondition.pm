package Enbld::Target::Attribute::AllowedCondition;

use strict;
use warnings;

use parent qw/Enbld::Target::AttributeExtension::Word/;

sub is_omitable {
    return 1;
}

1;
