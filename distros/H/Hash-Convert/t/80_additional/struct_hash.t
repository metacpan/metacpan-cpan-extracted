use strict;
use warnings;
use lib 't/';
require 'util/verify.pl';

use Test::More;

verify(
    rules   => { name => { from => 'user.name' } },
    input   => { user => { name => 'hixi', mail => 'hixi@cpam.org' } },
    expects => { name => 'hixi' },
    desc    => 'simple',
);

verify(
    rules   => { name => { from => 'user.name.last' } },
    input   => { user => { name => { first => 'hiroyoshi' , last => 'houchi' } } },
    expects => { name => 'houchi' },
    desc    => '2 class',
);

verify(
    rules   => { name => { from => [qw/user.name.first user.name.last/], via => sub { "$_[0] $_[1]" } } },
    input   => { user => { name => { first => 'hiroyoshi' , last => 'houchi' } } },
    expects => { name => 'hiroyoshi houchi' },
    desc    => 'via',
);

done_testing;
