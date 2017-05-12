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
               }},
    input   => { name => 'hixi', mail => 'hixi@cpan.org' },
    expects => { human => { name => 'hixi', mail => 'hixi@cpan.org' } },
    desc    => 'simple',
);

verify(
    rules   => { human => {
                    contain => {
                        name => { from => 'name' },
                        mail => { from => 'mail' },
                    },
               }},
    input   => { name => 'hixi' },
    expects => { human => { name => 'hixi' } },
    desc    => 'any exists',
);

verify(
    rules   => { human => {
                    contain => {
                        name => { from => 'name' },
                        mail => { from => 'mail' },
                    },
               }},
    input   => { },
    expects => { },
    desc    => 'not exists',
);

verify(
    rules   => { human => {
                    contain => {
                        name => {
                            contain=> {
                                first => { from => 'name1' },
                                last  => { from => 'name2' },
                            }
                        },
                        mail => { from => 'mail' },
                    },
               }},
    input   => { name1 => 'hiroyoshi', name2 => 'houchi', mail => 'hixi@cpan.org' },
    expects => { human => { name => { first => 'hiroyoshi', last => 'houchi' }, mail => 'hixi@cpan.org' } },
    desc    => 'nesting contain',
);

done_testing;
