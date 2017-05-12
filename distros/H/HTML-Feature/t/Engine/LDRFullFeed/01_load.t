use strict;
use warnings;
use HTML::Feature::Engine::LDRFullFeed;
use Test::More tests => 3;

my $ldrfullfeed = HTML::Feature::Engine::LDRFullFeed->new;

isa_ok($ldrfullfeed, 'HTML::Feature::Engine::LDRFullFeed');

can_ok($ldrfullfeed, 'run');
can_ok($ldrfullfeed, 'LDRFullFeed');

