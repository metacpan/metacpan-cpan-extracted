package Graphite::Sender;

use 5.026;
use utf8;
use strict;
use warnings;

our %flushed_metrics;

sub receiver_ok {
    my ($metrics) = @_;
    %flushed_metrics = %$metrics;
    return 1;
}

sub receiver_fail_undef {
    my ($metrics) = @_; 
    %flushed_metrics = %$metrics;
    return undef;
}

sub receiver_fail_hash {
    my ($metrics) = @_;
    %flushed_metrics = %$metrics;
    return undef;
}

sub receiver_fail_array {
    my ($metrics) = @_;
    %flushed_metrics = %$metrics;
    return undef;
}

sub receiver_fail_string {
    my ($metrics) = @_;
    %flushed_metrics = %$metrics;
    return "string";
}

1;

package main;

use 5.026;
use utf8;
use strict;
use warnings;

use Test::LeakTrace qw/ no_leaks_ok /;
use Test::Deep qw/ cmp_deeply num /;
use Test::More ('import' => [qw/ done_testing like is use_ok /]);

BEGIN { use_ok('Graphite::Simple') };

Graphite::Simple->import(qw/ :all /);

my %expected_bulk_metrics = (
    'wrong.avg.my.new.key' => 2,
    'my.new.key' => 12.4,
    'my.key' => 3,
    'avg.my.new.key' => 6.8
);

my %expected_avg_counters = (
    'avg.my.new.key' => 2
);

my %expected_invalid_metrics = (
	"invalid.avg.my.new.key " => 3,
);

my %expected_flushed_metrics = (
    'wrong.avg.my.new.key' => 2,
    'my.new.key' => 12.4,
    'my.key' => 3,
    'avg.my.new.key' => 3.4  # bulk / avg
);

# just to test no failures (warnings) with uninitialized values
{

    my $warns_cnt = 0;

    local $SIG{'__WARN__'} = sub {
        my ($msg) = @_;
        like($msg, qr/The sender must return a number type of status. Using 0 as sender status now/, "Checking the warn message");
        $warns_cnt++;
    };

    Graphite::Simple->new({sender_name => 'Graphite::Sender::receiver_fail_undef'})->send_bulk_delegate();
    Graphite::Simple->new({sender_name => 'Graphite::Sender::receiver_fail_hash'})->send_bulk_delegate();
    Graphite::Simple->new({sender_name => 'Graphite::Sender::receiver_fail_array'})->send_bulk_delegate();
    Graphite::Simple->new({sender_name => 'Graphite::Sender::receiver_fail_string'})->send_bulk_delegate();

    is($warns_cnt, 4, "Asserting amount of checked warns");
};

# just to test common storage
{
    my $graphite = Graphite::Simple->new({
        'host' => 'localhost',
        'port' => 2023,
        'project' => 'test',
        'enabled' => 1,
        'use_common_storage' => 1,
        'store_invalid_metrics' => 1,
    });

    $graphite->incr_bulk("my.key", 2);
    $graphite->incr_bulk("my.key");
    $graphite->incr_bulk("my.new.key", 12.4);
    $graphite->incr_bulk("avg.my.new.key", 4.8);
    $graphite->incr_bulk("avg.my.new.key", 2);
    $graphite->incr_bulk("wrong.avg.my.new.key", 2);
    $graphite->incr_bulk("invalid.avg.my.new.key ", 3); # using trailing space in the path

    cmp_deeply(\%Graphite::Simple::bulk, \%expected_bulk_metrics, "Checking common bulk hash");
    cmp_deeply(\%Graphite::Simple::avg_counters, \%expected_avg_counters, "Checking common avg_counter hash");
    cmp_deeply(\%Graphite::Simple::invalid, \%expected_invalid_metrics, "Checking common invalid hash");

    cmp_deeply($graphite->get_bulk_metrics(), \%expected_bulk_metrics, "Checking bulk hash");
    cmp_deeply($graphite->get_average_counters(), \%expected_avg_counters, "Checking avg_counter hash");
    cmp_deeply($graphite->get_invalid_metrics(), \%expected_invalid_metrics, "Checking invalid hash");

    $graphite->clear_bulk();

    undef $graphite;

    cmp_deeply(\%Graphite::Simple::bulk, {}, "Checking common bulk hash");
    cmp_deeply(\%Graphite::Simple::avg_counters, {}, "Checking common avg_counter hash");
    cmp_deeply(\%Graphite::Simple::invalid, {}, "Checking common invalid hash");
}

{ # just to test segfaults in case of wrong types as arguments

    my $graphite = Graphite::Simple->new({
        'host' => 'localhost',
        'port' => 2023,
        'project' => 'test',
        'enabled' => 1,
    });

    eval {
        $graphite->incr_bulk([]);
        $graphite->incr_bulk({});
        $graphite->incr_bulk(sub {});
    };
}

my $graphite = Graphite::Simple->new({
    'sender_name' => 'Graphite::Sender::receiver_ok',
    'block_metrics_re' => qr/initial\.block/,
    'host' => 'localhost',
    'port' => 2023,
    'project' => 'test',
    'enabled' => 1
});

# testing simple incr_bulk
$graphite->incr_bulk("my.key", 2);
$graphite->incr_bulk("my.key");
$graphite->incr_bulk("my.new.key", 12.4);
$graphite->incr_bulk("avg.my.new.key", 4.8);
$graphite->incr_bulk("avg.my.new.key", 2);
$graphite->incr_bulk("wrong.avg.my.new.key", 2);
cmp_deeply($graphite->get_bulk_metrics(), \%expected_bulk_metrics, "Checking bulk hash");
cmp_deeply($graphite->get_average_counters(), \%expected_avg_counters, "Checking avg_counter hash");

# testing simple result metrics
my $result_metrics = $graphite->get_metrics();
my $status = $graphite->send_bulk_delegate();
cmp_deeply(\%Graphite::Sender::flushed_metrics, \%expected_flushed_metrics, "Checking flushed metrics");
cmp_deeply($result_metrics, \%expected_flushed_metrics, "Checking result metrics");
is($status, 1, "Checking the status");

# testing send_bulk (just test the resetting of structure)
$status = 0;
$graphite->incr_bulk("my.new.key", 12.4);
cmp_deeply($graphite->get_bulk_metrics(), {"my.new.key" => 12.4}, "Checking bulk hash");
cmp_deeply($graphite->get_average_counters(), {}, "Checking avg_counter hash");
$graphite->connect();
$status = $graphite->send_bulk();
$graphite->disconnect();
cmp_deeply($graphite->get_bulk_metrics(), {}, "Checking bulk hash");
cmp_deeply($graphite->get_average_counters(), {}, "Checking avg_counter hash");
is($status, 1, "Checking the status");

# testing simple is_valid_key
is($graphite->is_valid_key("my.key"), 1, "Checking valid key");
is($graphite->is_valid_key("my.key "), 0, "Checking invalid key: space");
is($graphite->is_valid_key(""), 0, "Checking invalid key: empty string");
is($graphite->is_valid_key(undef), 0, "Checking invalid key: undefined");
is($graphite->is_valid_key("my.ключ"), 0, "Checking invalid key: non-latin");
is($graphite->is_valid_key('Bad_UTF' . '%' . chr(0xe2) . '%' . chr(0x80) . '%' . chr(0x99)), 0, "Checking invalid key: invalid UTF-8");
is($graphite->get_invalid_key_counter(), 5, "Checking the invalid key counter");

# just reset everything and check it
$graphite->clear_bulk();
cmp_deeply($graphite->get_bulk_metrics(), {}, "Checking bulk hash after cleaning");
cmp_deeply($graphite->get_average_counters(), {}, "Checking avg_counter hash after cleaning");
is($graphite->get_invalid_key_counter(), 0, "Checking the invalid key counter after cleaning");

# let's test check_and_bump_invalid_metric
$graphite->is_valid_key("");
$graphite->is_valid_key("");
$graphite->check_and_bump_invalid_metric("invalid.key.counter");
cmp_deeply($graphite->get_bulk_metrics(), {'invalid.key.counter' => 2}, "Checking bulk hash");
cmp_deeply($graphite->get_average_counters(), {}, "Checking avg_counter hash");

# just reset everything before new cases
$graphite->clear_bulk();

%expected_bulk_metrics = (
    'my.key1' => 2,
    'my.key2' => 22,
    'avg.key' => 6,
    'combo.key' => '2.908e-05'
);

%expected_avg_counters = (
    'avg.key' => 2
);

# testing append_bulk
$graphite->append_bulk({"my.key1" => 1, "my.key2" => 11, "" => 5, "avg.key" => 3, 'combo.key' => '2.908e-05'});
$graphite->append_bulk({"my.key1" => 1, "my.key2" => 11, "" => 5, "avg.key" => 3});
cmp_deeply($graphite->get_bulk_metrics(), \%expected_bulk_metrics, "Checking bulk hash");
cmp_deeply($graphite->get_average_counters(), \%expected_avg_counters, "Checking avg_counter hash");
is($graphite->get_invalid_key_counter(), 2, "Checking the invalid key counter");

# just reset everything before new cases
$graphite->clear_bulk();

# testing blocking re set previously via constructor
$graphite->append_bulk({"some.initial.block.key" => 1, "my.key" => 11});
cmp_deeply($graphite->get_bulk_metrics(), {'my.key' => 11}, "Checking bulk hash");

# just reset everything before new cases
$graphite->clear_bulk();

# testing set_blocked_metrics_re
$graphite->set_blocked_metrics_re(qr/.+\.block.me\.+/);
$graphite->append_bulk({"key.block.me.please" => 1, "my.key" => 11});
cmp_deeply($graphite->get_bulk_metrics(), {'my.key' => 11}, "Checking bulk hash");

# just reset everything before new cases
$graphite->clear_bulk();

# let's reset blocking re and test it
$graphite->set_blocked_metrics_re();
$graphite->append_bulk({"key.block.me.please" => 1, "my.key" => 11});
cmp_deeply($graphite->get_bulk_metrics(), {'my.key' => 11, 'key.block.me.please' => 1}, "Checking bulk hash");

%expected_bulk_metrics = (
    'my.prefix.my.key1' => 1,
    'my.prefix.my.key2' => 11,
    'my.prefix.avg.key' => 3,
);

# lets' test append_bulk with prefix without dot at the end
$graphite->clear_bulk();
$graphite->append_bulk({"my.key1" => 1, "my.key2" => 11, "avg.key" => 3}, 'my.prefix');
cmp_deeply($graphite->get_bulk_metrics(), \%expected_bulk_metrics, "Checking bulk hash");

# the same, but with dot at the end of prefix
$graphite->clear_bulk();
$graphite->append_bulk({"my.key1" => 1, "my.key2" => 11, "avg.key" => 3}, 'my.prefix.');
cmp_deeply($graphite->get_bulk_metrics(), \%expected_bulk_metrics, "Checking bulk hash");

# just to test no failures (warnings) with uninitialized values
{

    my $warns_cnt = 0;

    local $SIG{'__WARN__'} = sub {
        my ($msg) = @_;
        is($msg, "", "Checking the warn message");
        $warns_cnt++;
    };

    $graphite->set_blocked_metrics_re(undef);
    $graphite->append_bulk({"my.key" => 11}, undef);

    is($warns_cnt, 0, "Asserting amount of checked warns");
}

{

    my $warns_cnt = 0;

    local $SIG{'__WARN__'} = sub {
        my ($msg) = @_;
        like($msg, qr/Value type of key '[a-z]+.metric' is not a number/, "Checking the warn message");
        $warns_cnt++;
    };

    $graphite->append_bulk({'undef.metric' => undef});
    $graphite->append_bulk({'hash.metric' => {}});
    $graphite->append_bulk({'array.metric' => []});

    is($warns_cnt, 3, "Asserting amount of checked warns");
}

# let's be sure that we don't have any memory leaks
no_leaks_ok {
    my $g = Graphite::Simple->new({
        'sender_name' => 'Graphite::Sender::receiver_ok',
        'block_metrics_re' => qr/ignore/,
        'host' => 'localhost',
        'port' => 2023,
        'project' => 'test',
        'enabled' => 1
    });
    $g->incr_bulk("my.key", 2);
    $g->incr_bulk("my.key");
    $g->incr_bulk("avg.my.new.key", 3);
    $g->incr_bulk("avg.my.new.key", 2);
    $g->get_average_counters();
    $g->get_bulk_metrics();
    $g->get_invalid_metrics();
    $g->is_valid_key("my.key");
    $g->get_invalid_key_counter();
    $g->set_blocked_metrics_re(qr/.+\.block.me\.+/);
    $g->check_and_bump_invalid_metric("invalid.key.counter");
    $g->set_blocked_metrics_re();
    $g->append_bulk({"my.key1" => 1, "my.key2" => 11, "" => 5, "avg.key" => 3, "key.block.me.please" => 1});
    my $m = $g->get_metrics();
    my $r = $g->send_bulk_delegate();
    $g->append_bulk({"my.key1" => 1, "my.key2" => 11, "" => 5, "avg.key" => 3, "key.block.me.please" => 1});
    my $s = $g->connect();
    $r = $g->send_bulk();
    $g->disconnect();
    $g->clear_bulk();
};

done_testing();

1;
__END__
