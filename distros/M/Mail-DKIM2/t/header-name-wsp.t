#!/usr/bin/perl -w
# RFC 5322's obsolete syntax lets WSP sit between a field name and its colon
# ("From : x"), and -09 section 6.2 deletes it: the name is the name without
# it. Taking the WSP as part of the name made "From : ceo@paypal.example" a
# field called "from " -- hashed, so intact, but invisible to the From check,
# which saw only the other From. A reader that shows the first From showed
# paypal.example as authenticated.
use 5.020;
use strict;
use warnings;
use Test::More;
use lib 'lib', 't/lib';
use DKIM2TestKeys;
use Mail::DKIM2::Common qw(dkim2_canonicalize_header);
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Signer;
use Mail::DKIM2::Verifier;
use UndoWalkVerifier;

is(dkim2_canonicalize_header("Subject : hi\r\n"), "subject:hi\r\n",
   'canonical form: WSP before the colon is deleted');
is(dkim2_canonicalize_header("Subject\t:  hi\r\n"), "subject:hi\r\n", '  ... tab too');

# Sign as test1.dkim2.com with its own From check off, as a signer that does
# not check (or another implementation) would.
sub signed {
    my ($raw) = @_;
    my $mi  = Mail::DKIM2::MessageInstance->calculate($raw);
    my $msg = "Message-Instance: " . $mi->as_string . "\r\n$raw";
    no warnings 'redefine';
    no warnings 'redefine';
    local *Mail::DKIM2::Address::from_pair_error = sub { undef };
    my $s = Mail::DKIM2::Signer->new(
        Domain => 'test1.dkim2.com', Selector => 'sel1',
        Key => DKIM2TestKeys::private_key('test1.dkim2.com', 'sel1'),
        MailFrom => 'a@test1.dkim2.com', RcptTo => ['b@test2.dkim2.com'],
        Timestamp => 1740000000,
    );
    $s->PRINT($msg); $s->CLOSE;
    (my $sig = $s->as_string) =~ s/\r?\n\z//;
    return "$sig\r\n$msg";
}

sub verify {
    my ($msg, $stream) = @_;
    my $v = ($stream ? "Mail::DKIM2::Verifier" : "UndoWalkVerifier")->new(
        PubkeyCallback => DKIM2TestKeys::pubkey_callback());
    $v->skip_timestamp_check(1);
    $v->PRINT($msg); $v->CLOSE;
    return ($v->result, $v->result_detail);
}

for my $ws (' ', "\t") {
    my $label = $ws eq ' ' ? 'space' : 'tab';
    my $msg = signed("From${ws}: CEO <ceo\@paypal.example>\r\n"
                   . "From: a\@test1.dkim2.com\r\nTo: b\@test2.dkim2.com\r\n"
                   . "Subject: pay\r\n\r\nbody\r\n");
    for my $stream (1, 0) {
        my $walk = $stream ? "plans" : "undo walk";
        my ($r, $d) = verify($msg, $stream);
        isnt($r, 'pass', "From${label}: is a second From ($walk)");
        like($d, qr/From/, '  ... and the From check says so') or diag $d;
    }
}

# The name without its WSP is the name: "Subject :" hashes as Subject, so a
# Subject written either way verifies, and either way written by a hop
# that rewrote it is the same field.
{
    my $msg = signed("From: a\@test1.dkim2.com\r\nTo: b\@test2.dkim2.com\r\n"
                   . "Subject : hello\r\n\r\nbody\r\n");
    for my $stream (1, 0) {
        my $walk = $stream ? "plans" : "undo walk";
        my ($r, $d) = verify($msg, $stream);
        is($r, 'pass', "Subject with WSP before the colon verifies ($walk)") or diag $d;
    }
    (my $respelled = $msg) =~ s/^Subject : hello/Subject: hello/m;
    my ($r, $d) = verify($respelled, 1);
    is($r, 'pass', 'and is the same field without the WSP') or diag $d;
}

# A hop's own Recipe over such a field: the key is the field's name, as
# hashing and undo group it ("comments", not "comments "), so the chain the
# hop signs reverses -- through the undo walk and the plan alike.
use Mail::DKIM2::Common qw(parse_mime);
use Mail::DKIM2::HeaderPlan;
sub hop {
    my ($prev_raw, $edit) = @_;
    my $prev = parse_mime($prev_raw);
    $prev->header_raw_prepend('Message-Instance', Mail::DKIM2::MessageInstance->calculate($prev)->as_string);
    my $cur = parse_mime($prev->as_string);
    $edit->($cur);
    my $mi2 = Mail::DKIM2::MessageInstance->calculate($cur, $prev);
    $cur->header_raw_prepend('Message-Instance', $mi2->as_string);
    my ($h) = split /\r\n\r\n/, $cur->as_string, 2;
    my $hp = Mail::DKIM2::HeaderPlan->new("$h\r\n");
    my @mis = map { Mail::DKIM2::MessageInstance->parse($_) }
              sort { $b cmp $a } $hp->values('Message-Instance');
    $hp->plan(@mis);
    my ($plan_ok) = $mis[-1]->_check_hashes(1, sub { $hp->header_hash(1, $_[0]) // '' }, undef);
    my ($undo_ok, $why) = Mail::DKIM2::MessageInstance->chain_verifies($cur->as_string);
    return ([ sort keys %{ $mi2->{bits}{rh} || {} } ], $undo_ok, $plan_ok, $why);
}
{
    my ($keys, $undo, $plan, $why) = hop("From: a\@x.example\r\nComments : one\r\nSubject: s\r\n\r\nbody\r\n",
        sub { $_[0]->header_raw_prepend('Comments', 'two') });
    is_deeply($keys, ['comments'], 'a field added beside "Comments :": key "comments"');
    ok($undo, '  ... and the chain reverses on the undo walk') or diag $why;
    ok($plan, '  ... and on the plan');
}
{
    my ($keys, $undo, $plan, $why) = hop("From: a\@x.example\r\nSubject : old\r\n\r\nbody\r\n", sub {
        my $hdrs = $_[0]->header_obj->{headers};
        $hdrs->[$_ + 1] = ' new' for grep { $hdrs->[$_] eq 'Subject ' } map { 2 * $_ } 0 .. $#$hdrs / 2;
    });
    is_deeply($keys, ['subject'], '"Subject :" edited in place: key "subject"');
    ok($undo, '  ... and the chain reverses on the undo walk') or diag $why;
    ok($plan, '  ... and on the plan');
}

# A Recipe key is a header field name (-09 section 5): one with WSP in it
# ("message-instance ") is not, and is invalid JSON -- it must not reach the
# name matching, where it would be taken for Message-Instance and rewrite
# the instances below (the forged history of t/fraud-detection.t).
for my $key ("message-instance ", "message-instance\t", "subject ") {
    my $r = MIME::Base64::encode_base64(JSON::PP->new->canonical->encode(
        { h => { $key => [{ d => [' m=1; h=sha256:AAAA:AAAA'] }] } }), '');
    my $mi = eval { Mail::DKIM2::MessageInstance->parse("m=2; h=sha256:AAAA:AAAA; r=$r") };
    like($@, qr/m=2 contains invalid JSON/, "Recipe key \"\Q$key\E\" is invalid JSON");
}
use JSON::PP; use MIME::Base64 ();

# Nor does a signer write one: a hop that changes a field Email::Simple read
# under a name that is no field name ("Y Bad:") cannot record the change, and
# says so, rather than sign a Recipe no verifier accepts.
for my $name ("Y Bad", "Bad\x01", "Bad\x7f") {
    my $prev = parse_mime("From: a\@x.example\r\n$name: one\r\nSubject: s\r\n\r\nbody\r\n");
    $prev->header_raw_prepend('Message-Instance', Mail::DKIM2::MessageInstance->calculate($prev)->as_string);
    my $cur = parse_mime($prev->as_string);
    $cur->header_obj->header_raw_set($name);   # the hop drops it
    eval { Mail::DKIM2::MessageInstance->calculate($cur, $prev) };
    like($@, qr/cannot record a change to the field .*not a header field name/,
         'a change to "' . ($name =~ s/([^\x20-\x7e])/sprintf '\\x%02x', ord $1/ger) . '" is refused');
}

done_testing;
