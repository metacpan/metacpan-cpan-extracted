#!perl

use strict;
use warnings;
use charnames qw(:full);
use Messaging::Message;
use Test::More tests => 70;

our($count, $binstr, $unistr);

#
# helpers
#

sub test_val ($$) {
    my($name, $sub) = @_;

    $@ = "";
    eval { $sub->() };
    # expect failure
    if ($@ and $@ =~ /\b(failed|invalid|which is not|was not listed|did not pass|are mutually exclusive)\b/) {
	# ok
	is($@, $@, $name);
    } else {
	# mismatch
	is($@, "validation error", $name);
    }
}

sub yorn ($) {
    my($flag) = @_;

    return($flag ? "yes" : "no");
}

# test basic things

sub test_basic () {
    my($msg, $body);

    # defaults
    $msg = Messaging::Message->new();
    is(scalar(keys(%{ $msg->header() })), 0, "default header");
    is($msg->body(), "", "default body");
    is(yorn($msg->text()), "no", "default text");

    # simple construction
    $msg = Messaging::Message->new(
	header => { priority => "unknown" },
	body   => "foo",
	text   => 1,
    );
    is(scalar(keys(%{ $msg->header() })), 1, "simple header");
    is($msg->header_field("priority"), "unknown", "simple header field");
    is($msg->body(), "foo", "simple body");
    is(yorn($msg->text()), "yes", "simple text");

    # change
    $msg->header_field("message-id", 123);
    $msg->body("bar");
    $msg->text(0);
    is(scalar(keys(%{ $msg->header() })), 2, "changed header");
    is($msg->header_field("message-id"), "123", "changed header field");
    is($msg->body(), "bar", "changed body");
    is(yorn($msg->text()), "no", "changed text");

    # body reference
    $body = "hellow world";
    $msg->body_ref(\$body);
    is($msg->body_ref(), \$body, "reference body (1)");
    is($msg->body(), $body, "reference body (2)");

    # serialization
    $msg = Messaging::Message->new(body => "smiley=\x{263a}", text => 1);
    ok(!Encode::is_utf8($msg->serialize()), "serialize smiley");
}

# test message -> message

sub test_m2m ($) {
    my($msg1) = @_;
    my($tmp, $msg2);

    $count++;
    # message -> jsonify|stringify|serialize -> message
    $tmp = $msg1->jsonify();
    $msg2 = Messaging::Message->dejsonify($tmp);
    is_deeply($msg2, $msg1, "jsonify + dejsonify ($count)");
    $tmp = $msg1->stringify();
    $msg2 = Messaging::Message->destringify($tmp);
    is_deeply($msg2, $msg1, "stringify + destringify ($count)");
    $tmp = $msg1->serialize();
    $msg2 = Messaging::Message->deserialize($tmp);
    is_deeply($msg2, $msg1, "serialize + deserialize ($count)");
    # message -> copy
    $msg2 = $msg1->copy();
    is_deeply($msg2, $msg1, "copy ($count)");
}

# test deserialization

sub test_ds ($$) {
    my($str1, $msg1) = @_;
    my($msg2);

    $count++;
    $msg2 = Messaging::Message->deserialize($str1);
    is_deeply($msg2, $msg1, "deserialize ($count)");
}

#
# setup
#

$count = 0;
$binstr = join("", map(chr($_ ^ 123), 0 .. 255));
$unistr = "[Déjà Vu] sigma=\N{GREEK SMALL LETTER SIGMA} \N{EM DASH} smiley=\x{263a}";

#
# basic
#

test_basic();

#
# message -> message
#

$count = 0;
test_m2m(Messaging::Message->new());
test_m2m(Messaging::Message->new(header => {}, text => undef));
test_m2m(Messaging::Message->new(body => pack("LL", $$, time()), text => 0));
test_m2m(Messaging::Message->new(body => $binstr, text => 0));
test_m2m(Messaging::Message->new(body => "Théâtre", header => { foo => "Français" }, text => 0));
test_m2m(Messaging::Message->new(body => "Théâtre", header => { foo => "Français" }, text => 1));
test_m2m(Messaging::Message->new(body_ref => \$unistr, header => { $unistr => $unistr }, text => 1));

#
# deserialization
#

$count = 0;
test_ds(q/{}/,                                      Messaging::Message->new());
test_ds(q/{"body":"test"}/,                         Messaging::Message->new(body => "test"));
test_ds(q/{"body":"test","header":{"id":1}}/,       Messaging::Message->new(body => "test", header => { id => 1 }));
test_ds(q/{"body":"test","header":{"id":"1"}}/,     Messaging::Message->new(body => "test", header => { id => "1" }));
test_ds(q/{"header":{"id":"1"}}/,                   Messaging::Message->new(header => { id => "1" }));
test_ds(q/{"body":"aGVsbG8="}/,                     Messaging::Message->new(body => "aGVsbG8="));
test_ds(q/{"body":"aGVsbG8=","encoding":""}/,       Messaging::Message->new(body => "aGVsbG8="));
test_ds(q/{"body":"aGVsbG8=","encoding":"base64"}/, Messaging::Message->new(body => "hello"));
test_ds(q/{"body":"aG9sYQ==","encoding":"base64"}/, Messaging::Message->new(body => "hola"));
test_ds(q/{"body":"PT09","encoding":"base64"}/,     Messaging::Message->new(body => "==="));

#
# validation errors
#

# basic

$count = 0;
test_val("new(".$count++.")", sub { Messaging::Message->new(body => undef) });
test_val("new(".$count++.")", sub { Messaging::Message->new(header => "") });
test_val("new(".$count++.")", sub { Messaging::Message->new(header => { foo => [] }) });
test_val("new(".$count++.")", sub { Messaging::Message->new(body => "foo", body_ref => \$count) });
$count = 0;
test_val("header_field(".$count++.")", sub { Messaging::Message->new()->header_field(undef) });
test_val("header_field(".$count++.")", sub { Messaging::Message->new()->header_field({}) });
test_val("header_field(".$count++.")", sub { Messaging::Message->new()->header_field("id" => {}) });

# deserialization

foreach (
    "",                                                   # empty string
    "\xf1",                                               # not UTF-8
    "{x/",                                                # not JSON
    "[]",                                                 # not a hash
    q/{"text":1,"body":"test","header":{"id":123}}/,      # invalid text
    q/{"text":false,"body":"test","header":123}/,         # invalid header
    q/{"encoding":1,"body":"test"}/,                      # invalid encoding
    q/{"encoding":"base64","body":"1"}/,                  # invalid encoded body (padding)
    q/{"encoding":"base64","body":"1*2:3#4+"}/,           # invalid encoded body (chars)
    q/{"encoding":"base64","body":"AAAA:-))"}/,           # invalid encoded body (noise)
    q/{"text":true,"body":"test","header":{},"extra":0}/, # unexpected extra
    ) {
    test_val("deserialize($_)", sub { Messaging::Message->deserialize($_) });
}
