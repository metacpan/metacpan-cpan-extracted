package HTTP::MobileAgent::Plugin::Locator::Base;

use strict;
use base qw( Class::Accessor::Fast );

__PACKAGE__->mk_accessors( qw( params ) );

1;
