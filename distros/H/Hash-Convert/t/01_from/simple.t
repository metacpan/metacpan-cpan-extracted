use strict;
use warnings;
use lib 't/';
require 'util/verify.pl';

use Test::More;

verify(
    rules   => { created_at => { from => 'time' } },
    input   => { time => '10000' },
    expects => { created_at => '10000' },
    desc    => 'simple',
);

verify(
    rules   => { created_at => { from => 'time' } },
    input   => { time => 0 },
    expects => { created_at => 0 },
    desc    => 'value = 0',
);

verify(
    rules   => { created_at => { from => 'time' } },
    input   => { time => undef },
    expects => { created_at => undef },
    desc    => 'value = undef',
);

verify_error(
    rules => { error => { from => [qw/args0 args1/] } },
    input => {},
    error => "multiple value allowed only 'via' rule.",
    desc  => 'multiple value',
);

done_testing;
