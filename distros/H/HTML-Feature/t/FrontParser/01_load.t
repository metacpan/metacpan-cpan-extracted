use strict;
use warnings;
use HTML::Feature::FrontParser;
use Data::Dumper;
use Test::More tests => 1;

my $parser = HTML::Feature::FrontParser->new;
isa_ok($parser,'HTML::Feature::FrontParser');