use strict;
use warnings;
use Test::More tests => 4;
use Log::Handler;

local $SIG{__WARN__} = sub { die @_ };

sub forward { length($_[0]->{message}) }

my $log = Log::Handler->new();
ok(1, 'new');

$log->add(forward => { forward_to => \&forward });
ok(1, 'add');

ok($log->error('foo', undef, 'bar'), 'checking undef 1');
ok($log->error(undef), 'checking undef 2');

