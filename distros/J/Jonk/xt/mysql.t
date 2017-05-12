use strict;
use warnings;
use xt::Utils::mysql;
use Test::More;

subtest 'client' => sub { do "t/client.t" };
subtest 'worker' => sub { do "t/worker.t" };
done_testing;
