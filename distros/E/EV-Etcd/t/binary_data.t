#!/usr/bin/env perl
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Test::More;
use Encode qw(encode_utf8);

BEGIN {
    eval { require EV };
    plan skip_all => 'EV required' if $@;
}

use EV;
use EV::Etcd;

my $etcd_available = 0;
eval {
    my $client = EV::Etcd->new(
        endpoints => ['127.0.0.1:2379'],
        timeout => 2,
    );
    $client->status(sub {
        my ($resp, $err) = @_;
        $etcd_available = 1 if !$err;
        EV::break;
    });
    my $t = EV::timer(3, 0, sub { EV::break });
    EV::run;
};

plan skip_all => 'etcd not available on 127.0.0.1:2379' unless $etcd_available;

plan tests => 18;

my $client = EV::Etcd->new(
    endpoints => ['127.0.0.1:2379'],
);

my $prefix = "/test-binary-$$-" . time();

{
    my $utf8_key = "$prefix/utf8-\x{4e2d}\x{6587}";
    my $utf8_value = "value-\x{65e5}\x{672c}\x{8a9e}";

    my $put_ok = 0;
    $client->put(encode_utf8($utf8_key), encode_utf8($utf8_value), sub {
        my ($resp, $err) = @_;
        $put_ok = !$err && $resp->{header};
        EV::break;
    });
    my $t1 = EV::timer(5, 0, sub { EV::break });
    EV::run;

    ok($put_ok, 'put with UTF-8 key and value succeeded');

    my $get_value;
    $client->get(encode_utf8($utf8_key), sub {
        my ($resp, $err) = @_;
        if (!$err && $resp->{kvs} && @{$resp->{kvs}}) {
            $get_value = $resp->{kvs}[0]{value};
        }
        EV::break;
    });
    my $t2 = EV::timer(5, 0, sub { EV::break });
    EV::run;

    ok(defined $get_value, 'get UTF-8 key succeeded');
    is($get_value, encode_utf8($utf8_value), 'UTF-8 value round-trips correctly');
    diag("UTF-8 test: stored and retrieved CJK characters");
}

{
    my $binary_key = "$prefix/binary-key";
    my $binary_value = "before\x00middle\x00after";

    my $put_ok = 0;
    $client->put($binary_key, $binary_value, sub {
        my ($resp, $err) = @_;
        $put_ok = !$err && $resp->{header};
        EV::break;
    });
    my $t3 = EV::timer(5, 0, sub { EV::break });
    EV::run;

    ok($put_ok, 'put with binary value (null bytes) succeeded');

    my $get_value;
    $client->get($binary_key, sub {
        my ($resp, $err) = @_;
        if (!$err && $resp->{kvs} && @{$resp->{kvs}}) {
            $get_value = $resp->{kvs}[0]{value};
        }
        EV::break;
    });
    my $t4 = EV::timer(5, 0, sub { EV::break });
    EV::run;

    ok(defined $get_value, 'get binary key succeeded');
    is($get_value, $binary_value, 'binary value with null bytes round-trips correctly');
    is(length($get_value), length($binary_value), 'binary value length preserved');
    diag("Binary test: stored and retrieved value with embedded nulls");
}

{
    my $high_key = "$prefix/high-bytes";
    my $high_value = "\x80\x81\xFE\xFF";

    my $put_ok = 0;
    $client->put($high_key, $high_value, sub {
        my ($resp, $err) = @_;
        $put_ok = !$err && $resp->{header};
        EV::break;
    });
    my $t5 = EV::timer(5, 0, sub { EV::break });
    EV::run;

    ok($put_ok, 'put with high-byte values succeeded');

    my $get_value;
    $client->get($high_key, sub {
        my ($resp, $err) = @_;
        if (!$err && $resp->{kvs} && @{$resp->{kvs}}) {
            $get_value = $resp->{kvs}[0]{value};
        }
        EV::break;
    });
    my $t6 = EV::timer(5, 0, sub { EV::break });
    EV::run;

    ok(defined $get_value, 'get high-byte key succeeded');
    is($get_value, $high_value, 'high-byte values round-trip correctly');
    diag("High-byte test: stored and retrieved 0x80-0xFF range");
}

{
    my $emoji_key = "$prefix/emoji";
    my $emoji_value = encode_utf8("\x{1F600}\x{1F60D}\x{1F389}");

    my $put_ok = 0;
    $client->put($emoji_key, $emoji_value, sub {
        my ($resp, $err) = @_;
        $put_ok = !$err && $resp->{header};
        EV::break;
    });
    my $t7 = EV::timer(5, 0, sub { EV::break });
    EV::run;

    ok($put_ok, 'put with emoji value succeeded');

    my $get_value;
    $client->get($emoji_key, sub {
        my ($resp, $err) = @_;
        if (!$err && $resp->{kvs} && @{$resp->{kvs}}) {
            $get_value = $resp->{kvs}[0]{value};
        }
        EV::break;
    });
    my $t8 = EV::timer(5, 0, sub { EV::break });
    EV::run;

    ok(defined $get_value, 'get emoji key succeeded');
    is($get_value, $emoji_value, 'emoji (4-byte UTF-8) round-trips correctly');
    diag("Emoji test: stored and retrieved 4-byte UTF-8 sequences");
}

{
    my $mixed_key = "$prefix/mixed";
    my $mixed_value = "text\x00\xFF\x{00}binary\xFEend";

    my $put_ok = 0;
    $client->put($mixed_key, $mixed_value, sub {
        my ($resp, $err) = @_;
        $put_ok = !$err && $resp->{header};
        EV::break;
    });
    my $t9 = EV::timer(5, 0, sub { EV::break });
    EV::run;

    ok($put_ok, 'put with mixed binary/text succeeded');

    my $get_value;
    $client->get($mixed_key, sub {
        my ($resp, $err) = @_;
        if (!$err && $resp->{kvs} && @{$resp->{kvs}}) {
            $get_value = $resp->{kvs}[0]{value};
        }
        EV::break;
    });
    my $t10 = EV::timer(5, 0, sub { EV::break });
    EV::run;

    ok(defined $get_value, 'get mixed key succeeded');
    is($get_value, $mixed_value, 'mixed binary/text round-trips correctly');
    diag("Mixed test: stored and retrieved mixed binary/text data");
}

$client->delete("$prefix/", { prefix => 1 }, sub {
    my ($resp, $err) = @_;
    ok(!$err, 'cleanup succeeded');
    my $deleted = $resp->{deleted} || 0;
    ok($deleted >= 5, "cleaned up $deleted keys");
    diag("Cleanup: deleted $deleted test keys");
    EV::break;
});
my $t_cleanup = EV::timer(5, 0, sub { EV::break });
EV::run;

done_testing();
