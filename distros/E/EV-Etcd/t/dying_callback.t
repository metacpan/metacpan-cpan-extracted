#!/usr/bin/env perl
use strict;
use warnings;
BEGIN { delete @ENV{qw(http_proxy https_proxy grpc_proxy)} }
use Test::More;
use lib 'blib/lib', 'blib/arch';

# A dying callback is reported through $EV::DIED; neither a dying handler nor
# a dying stringification may unwind over XS cleanup or escape the event loop

BEGIN {
    eval { require EV };
    if ($@) {
        plan skip_all => 'EV module not available';
        exit;
    }
}

plan tests => 10;

use_ok('EV::Etcd');

my $client = EV::Etcd->new(
    endpoints => ['127.0.0.1:29999'],
    timeout => 2,
    max_retries => 0,
);

ok($client, 'client created with bad endpoint');

my ($called, $warned);
{
    local $SIG{__WARN__} = sub { $warned .= $_[0] };
    $client->get('/test/key', sub { $called++; EV::break; die "boom\n" });
    my $timer = EV::timer(5, 0, sub { EV::break });
    EV::run;
}

ok($called, 'dying callback ran');
like($warned // '', qr/error in callback.*boom/, 'death reported through the default $EV::DIED');

my $died_with;
{
    local $EV::DIED = sub { $died_with = $@ };
    $client->get('/test/key', sub { EV::break; die "to EV::DIED\n" });
    my $timer = EV::timer(5, 0, sub { EV::break });
    EV::run;
}
is($died_with, "to EV::DIED\n", 'callback deaths go to $EV::DIED');

my $died_warned = '';
{
    local $SIG{__WARN__} = sub { $died_warned .= $_[0] };
    local $EV::DIED = sub { die "handler bug\n" };
    $client->get('/test/key', sub { EV::break; die "cb boom\n" });
    my $timer = EV::timer(5, 0, sub { EV::break });
    EV::run;
}
like($died_warned, qr/\$EV::DIED died on 'cb boom\n': handler bug/, 'a dying $EV::DIED is reported');

my $escaped = '';
{
    local $SIG{__WARN__} = sub { die "warn handler boom\n" };
    $client->get('/test/key', sub { EV::break; die "boom\n" });
    my $timer = EV::timer(5, 0, sub { EV::break });
    eval { EV::run; 1 } or $escaped = $@;
}

is($escaped, '', 'dying __WARN__ handler does not escape EV::run');

{
    package Test::DyingStringify;
    use overload '""' => sub { die "stringify boom\n" };
}
$escaped = '';
my $object_warned = '';
{
    local $SIG{__WARN__} = sub { $object_warned .= $_[0] };
    $client->get('/test/key', sub { EV::break; die bless {}, 'Test::DyingStringify' });
    my $timer = EV::timer(5, 0, sub { EV::break });
    eval { EV::run; 1 } or $escaped = ref($@) ? ref($@) : $@;
}
is($escaped, '', 'exception whose stringification dies does not escape EV::run');
like($object_warned, qr/Test::DyingStringify object/, 'and is still reported');

my $alive = 0;
$client->get('/test/key', sub { $alive = 1; EV::break });
my $timer = EV::timer(5, 0, sub { EV::break });
EV::run;

ok($alive, 'client usable after warn-handler death');

done_testing();
