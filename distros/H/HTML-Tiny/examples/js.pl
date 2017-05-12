#!/usr/bin/perl

use strict;
use warnings;
use HTML::Tiny;

$| = 1;

my $h = HTML::Tiny->new;

my $some_perl_data = {
  score   => 45,
  name    => 'Fred',
  history => [ 32, 37, 41, 45 ]
};

# Transfer value to Javascript
print $h->script( { type => 'text/javascript' },
  "\nvar someVar = " . $h->json_encode( $some_perl_data ) . ";\n " );

# Prints
# <script type="text/javascript">
# var someVar = {"history":[32,37,41,45],"name":"Fred","score":45};
# </script>
