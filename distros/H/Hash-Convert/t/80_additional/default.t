use strict;
use warnings;
use lib 't/';
require 'util/verify.pl';

use Test::More;

verify(
    rules   => { human => { from => 'human', default => undef } },
    input   => {},
    expects => { human => undef },
    desc    => 'undef',
);

verify(
    rules   => { version => { from => 'version', default => 1 } },
    input   => {},
    expects => { version => 1 },
    desc    => 'scalar',
);

verify(
    rules   => { ids => { from => 'ids', default => [qw/1 2 3/] } },
    input   => {},
    expects => { ids => [qw/1 2 3/] },
    desc    => 'ref ARRAY',
);

verify(
    rules   => { time => { from => 'time', default => sub { 1 } } },
    input   => {},
    expects => { time => 1 },
    desc    => 'ref code',
);

verify(
    rules   => { human => {
                    contain => {
                        name => { from => 'name' },
                        mail => { from => 'mail' },
                    },
                    default => {
                        name => 'NO NAME',
                        mail => 'xxxx@example.com',
                    },
               }},
    input   => {},
    expects => {
        human => {
            name => 'NO NAME',
            mail => 'xxxx@example.com',
        }
    },
    desc    => 'ref HASH',
);

done_testing;
