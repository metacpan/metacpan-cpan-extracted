use strict;
use warnings;

use Test::Simple tests => 1;

use Farly::ASA::Builder;

my $builder = Farly::ASA::Builder->new();
ok( $builder->isa('Farly::ASA::Builder'), "new" );
