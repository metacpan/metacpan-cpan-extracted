use strict;
use warnings;
use Test::More tests => 1; 
use MARC::Batch;

# verify that parser picks up contents of a subfield $0 

my $b = MARC::Batch->new( 'XML', 't/subfield0.xml' );
my $r = $b->next();
is($r->subfield('245', '0'), 'subfield $0 contents', 'subfield $0');

