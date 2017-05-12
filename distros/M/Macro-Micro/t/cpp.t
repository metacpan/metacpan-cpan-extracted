#!perl
use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok("Macro::Micro"); }

my $cpp = Macro::Micro->new(macro_format => qr/^(#(\w+.*))$/m);

$cpp->register_macros(
  qr/\Ainclude\s+.*/i => sub {
    my ($macro_name) = @_;
    my ($file) = $macro_name =~ /\Ainclude\s+["<]([\/\w.]+)[>"]/;
    return "(contents of $file)"
  }
);


my $source = <<END_C;

#include <sys/face.h>
#include "yourface.h"

int i[80];

END_C

my $result = <<END_C;

(contents of sys/face.h)
(contents of yourface.h)

int i[80];

END_C

is($cpp->expand_macros($source), $result, "lame cpp works");
