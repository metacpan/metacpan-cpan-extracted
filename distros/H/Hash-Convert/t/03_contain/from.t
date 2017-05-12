use strict;
use warnings;
use lib 't/';
require 'util/verify.pl';

use Test::More;

verify(
    rules   => { human => {
                    contain => {
                        name => { from => 'name', default => 'unknown' },
                        mail => { from => 'mail', default => 'unknown@example.com' },
                    },
               }},
    input   => {  },
    expects => { human => { name => 'unknown', mail => 'unknown@example.com' } },
    desc    => 'default',
);

done_testing;
