package Markdent::Types;

use strict;
use warnings;

use base 'MooseX::Types::Combine';

our $VERSION = '0.26';

__PACKAGE__->provide_types_from(
    qw(
        Markdent::Types::Internal
        MooseX::Types::Moose
        )
);

1;
