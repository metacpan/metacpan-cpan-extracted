use strict;
use warnings;
use HTML::Feature::Result;
use Test::More tests => 2;

my $result = HTML::Feature::Result->new;
isa_ok($result, 'HTML::Feature::Result');

can_ok($result, 'element_delete');
