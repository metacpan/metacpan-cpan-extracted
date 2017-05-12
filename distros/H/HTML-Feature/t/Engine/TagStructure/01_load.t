use strict;
use warnings;
use HTML::Feature::Engine::TagStructure;
use Test::More tests => 2;

my $tagstructure = HTML::Feature::Engine::TagStructure->new;

isa_ok($tagstructure, 'HTML::Feature::Engine::TagStructure');

can_ok($tagstructure, 'run');
