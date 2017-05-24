use strict;
use warnings;
use Test::More tests => 1; 
use MARC::Batch;

# sometimes the <record> element might have a namespace or other
# attributes on it. We need to make sure that does not mess us up.

my $b = MARC::Batch->new( 'XML', 't/namespace.xml' );
my $r = $b->next();
isa_ok( $r, 'MARC::Record' );

