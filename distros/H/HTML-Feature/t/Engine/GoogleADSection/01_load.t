use strict;
use warnings;
use HTML::Feature::Engine::GoogleADSection;
use Test::More tests => 2;

my $googleadsection = HTML::Feature::Engine::GoogleADSection->new;

isa_ok($googleadsection, 'HTML::Feature::Engine::GoogleADSection');

can_ok($googleadsection, 'run');