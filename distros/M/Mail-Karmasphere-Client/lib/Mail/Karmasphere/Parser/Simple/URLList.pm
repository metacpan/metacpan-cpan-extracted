package Mail::Karmasphere::Parser::Simple::URLList;

use strict;
use warnings;
use base 'Mail::Karmasphere::Parser::Simple::List';

sub _streams { "url" }

sub _type { "url" }

sub my_format { "simple.urllist" } # the source table's "magic" field

1;
