#!perl

use strict;
use warnings;

use Test::More 0.96 tests => 1;
use Test::CPAN::Changes;
subtest 'changes_ok' => sub {
    changes_file_ok('Changes');
};
done_testing();
