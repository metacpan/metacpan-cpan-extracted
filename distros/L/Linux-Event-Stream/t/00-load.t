use strict;
use warnings;
use Test::More;

ok(eval { require Linux::Event::Stream; 1 }, 'require Linux::Event::Stream') or diag $@;
ok(eval { require Linux::Event::Stream::Codec; 1 }, 'require Linux::Event::Stream::Codec') or diag $@;
ok(eval { require Linux::Event::Stream::Codec::Line; 1 }, 'require Line codec') or diag $@;
ok(eval { require Linux::Event::Stream::Codec::Netstring; 1 }, 'require Netstring codec') or diag $@;
ok(eval { require Linux::Event::Stream::Codec::U32BE; 1 }, 'require U32BE codec') or diag $@;

done_testing;
