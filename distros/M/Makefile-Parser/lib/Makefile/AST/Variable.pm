package Makefile::AST::Variable;

use strict;
use warnings;
use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw{
    name value flavor origin
    lineno file
});

1;

