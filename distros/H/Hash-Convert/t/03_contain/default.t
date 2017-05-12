use strict;
use warnings;
use lib 't/';
require 'util/verify.pl';

use Test::More;

verify(
    rules   => { human => {
                    contain => {
                        name => { from => 'name' },
                        mail => { from => 'mail' },
                    },
                    default => 'unknown',
               }},
    input   => {  },
    expects => { human => 'unknown' },
    desc    => 'default',
);

done_testing;
