use strict;
use warnings;
use Test::More;
use IO::Prompt::Simple;

do {
    local $@;
    eval { prompt() };
    like $@, qr/Usage: prompt\([^)]+\) /, 'usage';
};

done_testing;
