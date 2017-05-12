use strict;
use warnings;

use Test::Simple tests => 1;

use Farly::Director;

my $director = Farly::Director->new();
ok( $director->isa('Farly::Director'), "new" );
