use strict;
use warnings;

use Test::More;
my $tests;
plan tests => $tests;

use Log::Dispatch::Socket;

BEGIN { $tests = 2; }

ok(defined $Log::Dispatch::Socket::VERSION);
ok($Log::Dispatch::Socket::VERSION =~ /^\d{1}.\d{6}$/);

BEGIN { $tests += 1; }

can_ok('Log::Dispatch::Socket', qw(new log_message DESTROY));
