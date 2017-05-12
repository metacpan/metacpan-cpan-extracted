use strict;
use warnings;
use Test::More;
use t::Util;
use Term::ANSIColor qw(colored);

test_prompt(
    input  => 'y',
    answer => 'y',
    opts   => { color => 'red' },
    prompt => colored(['red'], 'prompt ').': ',
    desc   => 'color (scalar)',
);

test_prompt(
    input  => 'y',
    answer => 'y',
    opts   => { color => ['red'] },
    prompt => colored(['red'], 'prompt ').': ',
    desc   => 'color (array)',
);

test_prompt(
    input  => 'a',
    answer => 1,
    opts   => { color => 'red', anyone => { a => 1 }, verbose => 1 },
    prompt => "# a => 1\n".colored(['red'], 'prompt ').': ',
    desc   => 'do not decoration of choices',
);

done_testing;
