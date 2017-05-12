use strict;
use warnings;

use Test::Simple tests => 1;

use Farly::Builder;

my $builder = Farly::Builder->new();
ok( $builder->isa('Farly::Builder'), "new" );
