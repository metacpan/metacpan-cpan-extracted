use v5.36;
use strict;
use warnings;

use Test::More;

for my $m (qw(Linux::Epoll Linux::Event::Clock Linux::Event::Timer)) {
  eval "require $m; 1" or plan skip_all => "$m not available: $@";
}

use Linux::Event::Loop;

my $reactor = Linux::Event::Loop->new(model => 'reactor', backend => 'epoll');
is($reactor->model, 'reactor', 'selector uses reactor model');
is($reactor->backend_name, 'epoll', 'reactor backend name');
ok($reactor->can('watch'), 'reactor surface available');

my $proactor = Linux::Event::Loop->new(model => 'proactor', backend => 'fake');
is($proactor->model, 'proactor', 'selector uses proactor model');
is($proactor->backend_name, 'fake', 'proactor backend name');
ok($proactor->can('read'), 'proactor surface available');

my $ok = eval { Linux::Event::Loop->new(); 1 };
ok(!$ok, 'missing model dies');
like($@, qr/model is required/, 'missing model error is clear');

done_testing;
