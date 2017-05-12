package Mail::Karmasphere::Parser::Simple::EmailList;

use strict;
use warnings;
use base 'Mail::Karmasphere::Parser::Simple::List';

sub _streams { "email" }

sub _type { "email" }

sub my_format { "simple.emaillist" } # the source table's "magic" field

1;
