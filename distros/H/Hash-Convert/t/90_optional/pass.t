use strict;
use warnings;
use lib 't/';
require 'util/verify.pl';

use Test::More;

verify(
    rules   => { visited_at => { from => 'time' } },
    options => { pass => 'name' },
    input   => { name => 'hiroyoshi houchi', time => '1' },
    expects => { name => 'hiroyoshi houchi', visited_at => '1' },
    desc    => 'single',
);

verify(
    rules   => { visited_at => { from => 'time' } },
    options => { pass => [qw/name mail/] },
    input   => { name => 'hiroyoshi houchi', mail => 'hixi@cpan.org', time => '1' },
    expects => { name => 'hiroyoshi houchi', mail => 'hixi@cpan.org', visited_at => '1' },
    desc    => 'multi',
);

done_testing;
