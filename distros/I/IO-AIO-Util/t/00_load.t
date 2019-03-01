use strict;
use warnings;
use Test::More;

BEGIN { use_ok('IO::AIO::Util'); }

can_ok('IO::AIO::Util', qw(aio_mkpath aio_mktree));

done_testing;
