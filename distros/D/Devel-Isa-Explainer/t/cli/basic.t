use strict;
use warnings;

use Test::More;

# ABSTRACT: A basic cli test

use App::Isa::Splain;

my $self = App::Isa::Splain->new_from_ARGV( ['App::Isa::Splain'] );
pass("Basic invocation ok");

done_testing;

