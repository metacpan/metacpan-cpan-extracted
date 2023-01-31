use strict;
use warnings;
use Test::More;

plan tests => 1 unless  $::NO_PLAN && $::NO_PLAN;

require_ok 'File::HTTP';
File::HTTP->import(':all');
