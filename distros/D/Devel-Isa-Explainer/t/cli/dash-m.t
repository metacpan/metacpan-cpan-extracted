use strict;
use warnings;

use Test::More;

# ABSTRACT: A basic cli test

use App::Isa::Splain;

my $self = App::Isa::Splain->new_from_ARGV( [ '-MB', 'B::CV' ] );
pass("isa-splain -MB B::CV : Init OK");

done_testing;

