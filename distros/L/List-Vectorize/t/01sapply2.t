use strict;
use Test::More;

eval 'use Test::Exception';

plan (skip_all => 'Test::Exception not installed') if ($@);

use List::Vectorize;
my $a = [-5..5];
eval qq` dies_ok { List::Vectorize::sapply(\$a, sub {1/\$_[0]}) } "zero can not be divided." `;

done_testing();
