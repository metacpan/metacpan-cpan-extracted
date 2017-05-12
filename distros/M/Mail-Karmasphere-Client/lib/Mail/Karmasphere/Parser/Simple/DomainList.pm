package Mail::Karmasphere::Parser::Simple::DomainList;

use strict;
use warnings;
use base 'Mail::Karmasphere::Parser::Simple::List';

sub _streams { "domain" }

sub _type { "domain" }

sub my_format { "simple.domainlist" } # the source table's "magic" field

1;
