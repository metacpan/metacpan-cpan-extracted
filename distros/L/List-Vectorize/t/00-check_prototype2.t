use strict;
use Test::More;

eval 'use Test::Exception';

if ($@) {
	plan (skip_all => 'Test::Exception not installed') ;
}


use List::Vectorize;
# test check_prototype
eval q` lives_ok { List::Vectorize::check_prototype(1, '$') } `;
eval q` lives_ok { List::Vectorize::check_prototype(1,1,1,1, '$+') } `;
eval q` lives_ok { List::Vectorize::check_prototype(1,1,1,1, '${1,5}') } `;
eval q` lives_ok { List::Vectorize::check_prototype([1,2], '\@') } `;
eval q` lives_ok { List::Vectorize::check_prototype({}, '\%') } `;
eval q` lives_ok { List::Vectorize::check_prototype(\1, '\$') } `;
eval q` lives_ok { List::Vectorize::check_prototype(\\1, '\$') } `;
eval q` lives_ok { List::Vectorize::check_prototype(sub{1}, '\&') } `;
eval q` lives_ok { List::Vectorize::check_prototype(\*STDIN, '\*') } `;
eval q` lives_ok { List::Vectorize::check_prototype(*STDIN, '*') } `;
eval q` lives_ok { List::Vectorize::check_prototype(1, {}, '$\%') } `;
eval q` lives_ok { List::Vectorize::check_prototype([], {}, '($|\@)\%') } `;
eval q` dies_ok { List::Vectorize::check_prototype([], '$') } 'prototype unmatch' `;

done_testing();
