use v5.36;
use strict;
use warnings;

use Test::More;

for my $m (qw(Linux::Event::Clock Linux::Event::Timer)) {
  eval "require $m; 1" or plan skip_all => "$m not available: $@";
}

use Linux::Event::Loop;

my $loop = Linux::Event::Loop->new(backend => 'epoll');
is($loop->backend_name, 'epoll', 'epoll backend selected');
ok($loop->can('watch'), 'watch surface available');
ok(!$loop->can('read'), 'completion read surface absent');
ok(!$loop->can('live_op_count'), 'operation accounting surface absent');

my $default = Linux::Event::Loop->new;
is($default->backend_name, 'epoll', 'default backend is epoll');

my $ok = eval { Linux::Event::Loop->new(model => 'reactor'); 1 };
ok(!$ok, 'model argument dies');
like($@, qr/model is no longer supported/, 'model error is clear');

done_testing;
