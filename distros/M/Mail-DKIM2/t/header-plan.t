#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use MIME::Base64 qw(encode_base64);
use JSON::PP;
use Mail::DKIM2::HeaderPlan;
use Mail::DKIM2::MessageInstance;
use ChainPlanReference qw(reference_walk plan_walk);

# HeaderPlan computes every Message-Instance's header hash from the header
# fields as received and the header Recipes, without rebuilding any
# previous header. Each case is checked against the undo walk
# (MessageInstance->undo + h_digest).

my $JSON = JSON::PP->new->canonical;

sub mi {
    my ($m, $r) = @_;
    my $f = "Message-Instance: m=$m; h=sha256:AAAA:AAAA,sha512:AAAA:AAAA";
    $f .= '; r=' . encode_base64($JSON->encode($r), '') if $r;
    return "$f\r\n";
}

sub message {
    my ($mis, @fields) = @_;
    return join('', @$mis, map { "$_\r\n" } @fields) . "\r\nbody\r\n";
}

sub same {
    my ($name, $raw, %opts) = @_;
    my $want = reference_walk($raw, %opts);
    my $have = plan_walk($raw, undef, %opts);
    is_deeply($have, $want, $name)
        or diag explain { want => $want, have => $have };
}

my @base = ('From: a@example.com', 'To: list@example.org', 'Subject: [list] hi',
            'Date: Sat, 17 Oct 2026 10:00:00 +0000');

same('no header Recipes', message([mi(2, { b => [{ c => [1, 1] }] }), mi(1)], @base));

same('a subject tag removed',
    message([mi(2, { h => { subject => [{ d => ['hi'] }] } }), mi(1)], @base));

same('fields a list added are removed',
    message([mi(2, { h => { 'list-id' => [], 'list-post' => [] } }), mi(1)],
            'List-Id: <list.example.org>', 'List-Post: <mailto:list@example.org>', @base));

same('copies and literals among repeated fields',
    message([mi(2, { h => { comments => [{ c => [1, 1] }, { d => ['old two'] }, { c => [3, 4] }] } }),
             mi(1)],
            @base, map { "Comments: c$_" } 1 .. 4));

same('a field added where there was none',
    message([mi(2, { h => { 'reply-to' => [{ d => ['someone@example.net'] }] } }), mi(1)], @base));

same('three levels, each changing the subject',
    message([mi(3, { h => { subject => [{ d => ['[list] hi'] }] } }),
             mi(2, { h => { subject => [{ d => ['hi'] }], 'reply-to' => [] } }),
             mi(1)],
            'Subject: [other] [list] hi', 'Reply-To: x@example.org',
            grep { !/^Subject/ } @base));

same('a lower level copies a literal the level above put back',
    message([mi(3, { h => { comments => [{ c => [1, 1] }, { d => ['lit'] }] } }),
             mi(2, { h => { comments => [{ c => [2, 2] }] } }),
             mi(1)],
            @base, 'Comments: top'));

same('folded fields and whitespace runs',
    message([mi(2, { h => { subject => [{ d => ["a  \t long   subject"] }] } }), mi(1)],
            "Subject: folded\r\n\tover\r\n   three lines", 'From:   a@example.com  ',
            'To: list@example.org'));

same('a line with no colon continues the field above it',
    message([mi(2, { h => { subject => [{ d => ['x'] }] } }), mi(1)],
            'Subject: one', 'not a field', @base[0, 1]));

same('field names in mixed case are one name',
    message([mi(2, { h => { subject => [{ c => [2, 2] }] } }), mi(1)],
            'SUBJECT: upper', 'subject: lower', @base[0, 1]));

same('Recipe keys in mixed case apply in turn',
    message([mi(2, { h => { Subject => [{ c => [1, 1] }, { d => ['added'] }],
                            subject => [{ c => [2, 2] }] } }), mi(1)],
            'Subject: one', @base[0, 1]));

same('a name with a space before the colon',
    message([mi(2, { h => { subject => [{ d => ['x'] }] } }), mi(1)],
            'Subject : spaced', @base[0, 1]));

same('Recipes for fields outside the hash',
    message([mi(2, { h => { received => [], 'x-list' => [{ d => ['y'] }] } }), mi(1)],
            'Received: from a by b', 'X-List: z', @base));

same('IgnorePrefixes leaves a field out of every hash',
    message([mi(2, { h => { 'list-id' => [] } }), mi(1)],
            'List-Id: <l>', 'Fm-Stamp: 1', @base),
    IgnorePrefixes => ['fm-']);

same('a copy past the fields there are',
    message([mi(2, { h => { subject => [{ c => [1, 2] }] } }), mi(1)], @base));

same('a copy of a field that is not there',
    message([mi(2, { h => { 'reply-to' => [{ c => [1, 1] }] } }), mi(1)], @base));

same('header copies out of order',
    message([mi(2, { h => { comments => [{ c => [2, 2] }, { c => [1, 1] }] } }), mi(1)],
            @base, 'Comments: 1', 'Comments: 2'));

same('the first bad name in key order is the error',
    message([mi(2, { h => { zz => [{ c => [5, 5] }], aa => [{ c => [3, 3] }] } }), mi(1)],
            @base));

same('a body Recipe error comes before a header one',
    message([mi(2, { b => [{ c => [7, 7] }], h => { aa => [{ c => [3, 3] }] } }), mi(1)],
            @base));

same('below a null body Recipe the headers are still checked',
    message([mi(3, { b => undef, h => { subject => [{ d => ['two'] }] } }),
             mi(2, { h => { subject => [{ d => ['one'] }] } }),
             mi(1)],
            @base));

same('a line ending in a lone CR (the Email::Simple parse)',
    message([mi(2, { h => { subject => [{ d => ['x'] }] } }), mi(1)],
            "Subject: a\rb", @base[0, 1]));

# A header Recipe naming Message-Instance changes the instances the walk
# below it sees: the plan says so, for the caller to use the undo walk.
{
    my @mi = map { Mail::DKIM2::MessageInstance->parse($_) }
        "m=2; h=sha256:AAAA:AAAA; r=" . encode_base64($JSON->encode(
            { h => { 'message-instance' => [{ c => [1, 1] }] } }), ''),
        "m=1; h=sha256:AAAA:AAAA";
    my $plan = Mail::DKIM2::HeaderPlan->new("From: a\r\n")->plan(@mi);
    ok($plan->rewrites_instances, 'a Message-Instance header Recipe is flagged');
    ok(!Mail::DKIM2::HeaderPlan->new("From: a\r\n")->plan($mi[1])->rewrites_instances,
       'no Message-Instance Recipe, no flag');
}

done_testing;
