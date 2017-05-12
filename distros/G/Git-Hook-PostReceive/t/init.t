use strict;
use Test::More tests => 2;

use_ok 'Git::Hook::PostReceive';

my $hook = Git::Hook::PostReceive->new;
isa_ok $hook, 'Git::Hook::PostReceive';

done_testing;
