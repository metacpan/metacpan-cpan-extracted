use strict;

use Test::More tests => 2;

my $CLASS = 'Excel::Template';

use_ok( $CLASS );

my $object = $CLASS->new ();
isa_ok( $object, $CLASS );


