package Mail::Karmasphere::Parser::Simple::IPList;

use strict;
use warnings;
use base 'Mail::Karmasphere::Parser::Simple::List';

sub _streams { "ip4" }

sub _type { "ip4" }

sub my_format { "simple.iplist" } # the source table's "magic" field

1;
