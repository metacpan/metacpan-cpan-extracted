#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use MIME::Base64 qw(encode_base64);
use JSON::PP;
use Mail::DKIM2::BodyPlan;
use ChainPlanReference qw(reference_walk plan_walk);

# BodyPlan computes every Message-Instance's body hash in one forward pass
# over the current body, from the body Recipes alone. Each case here is
# checked against the undo walk (MessageInstance->undo + b_digest), which
# rebuilds every previous body in full.

my $JSON = JSON::PP->new->canonical;

# A Message-Instance field: m=$m, both hash algorithms (placeholder values:
# only the body hashes are compared, and those are computed), and $r as the
# Recipe object when given.
sub mi {
    my ($m, $r) = @_;
    my $h = 'h=sha256:AAAA:AAAA,sha512:AAAA:AAAA';
    my $f = "Message-Instance: m=$m; $h";
    $f .= '; r=' . encode_base64($JSON->encode($r), '') if $r;
    return "$f\r\n";
}

sub message {
    my ($mis, @body) = @_;
    return join('', @$mis) . "From: a\@example.com\r\nSubject: t\r\n\r\n"
         . join('', @body);
}

sub same {
    my ($name, $raw, %opts) = @_;
    my $want = reference_walk($raw);
    my $have = plan_walk($raw, $opts{chunks});
    is_deeply($have, $want, $name)
        or diag explain { want => $want, have => $have };
}

same('one instance, no Recipe',
    message([mi(1)], "a\r\n", "b\r\n"));

same('footer appended',
    message([mi(2, { b => [{ c => [1, 3] }] }), mi(1)],
            "one\r\n", "two\r\n", "three\r\n", "--\r\n", "footer\r\n"));

same('MIME wrap: the old body is a middle range',
    message([mi(2, { b => [{ c => [4, 6] }] }), mi(1)],
            "--b\r\n", "Content-Type: text/plain\r\n", "\r\n",
            "x\r\n", "y\r\n", "z\r\n", "--b--\r\n"));

same('literals before, between and after copies',
    message([mi(2, { b => [{ d => ['new'] }, { c => [2, 3] },
                           { d => ['', 'tail', ''] }] }), mi(1)],
            "1\r\n", "2\r\n", "3\r\n", "4\r\n"));

same('three levels; a lower instance copies a literal of the one above',
    message([mi(3, { b => [{ c => [1, 2] }, { d => ['L1', 'L2'] }] }),
             mi(2, { b => [{ c => [2, 3] }] }),
             mi(1)],
            "a\r\n", "b\r\n", "c\r\n"));

same('an instance with no body Recipe has the body above it',
    message([mi(3, { h => { subject => [{ d => ['old'] }] } }),
             mi(2, { b => [{ c => [1, 1] }] }),
             mi(1)],
            "a\r\n", "b\r\n"));

same('trailing blank lines are not hashed, middle ones are',
    message([mi(2, { b => [{ c => [1, 2] }, { d => ['', ''] }] }), mi(1)],
            "a\r\n", "\r\n", "b\r\n", "\r\n", "\r\n"));

same('a blank run spanning a body line and a literal',
    message([mi(2, { b => [{ c => [1, 2] }, { d => ['', 'z'] }] }), mi(1)],
            "a\r\n", "\r\n", "b\r\n"));

same('blank literals at the end of the body are trailing blanks',
    message([mi(2, { b => [{ c => [1, 1] }, { d => ['', ''] }] }), mi(1)],
            "a\r\n", "b\r\n"));

same('a copy into the trailing blank lines (they are lines)',
    message([mi(2, { b => [{ c => [1, 3] }] }), mi(1)],
            "a\r\n", "b\r\n", "\r\n", "\r\n"));

same('a copy past the end of the body is out of range',
    message([mi(2, { b => [{ c => [2, 9] }] }), mi(1)],
            "a\r\n", "b\r\n"));

same('a copy past the end of a rebuilt body is out of range',
    message([mi(3, { b => [{ c => [1, 1] }, { d => ['x', ''] }] }),
             mi(2, { b => [{ c => [1, 3] }] }),
             mi(1)],
            "a\r\n", "b\r\n"));

same('copies out of order',
    message([mi(2, { b => [{ c => [2, 2] }, { c => [1, 1] }] }), mi(1)],
            "a\r\n", "b\r\n"));

same('overlapping copies',
    message([mi(2, { b => [{ c => [1, 2] }, { c => [2, 3] }] }), mi(1)],
            "a\r\n", "b\r\n", "c\r\n"));

same('a null body Recipe: nothing below it has a body',
    message([mi(3, { b => [{ c => [1, 1] }] }),
             mi(2, { b => undef }),
             mi(1, { b => [{ c => [1, 1] }] })],
            "a\r\n", "b\r\n"));

same('an unterminated last line',
    message([mi(2, { b => [{ c => [2, 2] }] }), mi(1)],
            "a\r\n", "b"));

same('an empty body',
    message([mi(2, { b => [{ d => ['x'] }] }), mi(1)]));

same('a body of blank lines only',
    message([mi(2, { b => [{ c => [1, 1] }] }), mi(1)],
            "\r\n", "\r\n"));

same('everything copied out of an empty body is out of range',
    message([mi(2, { b => [{ c => [1, 1] }] }), mi(1)]));

same('a lone CR is part of its line',
    message([mi(2, { b => [{ c => [1, 2] }] }), mi(1)],
            "a\rb\r\n", "\r\r\n", "c\r\n"));

same('instances numbered with leading zeros',
    message([mi('02', { b => [{ c => [1, 1] }], h => { subject => [{ d => ['x'] }] } }),
             mi('001')],
            "a\r\n", "b\r\n"));

same('a recipe that rebuilds nothing',
    message([mi(2, { b => [] }), mi(1)], "a\r\n"));

# The same message cut at every byte: a line, a CRLF or the end of the
# headers split across two chunks.
{
    my $raw = message(
        [mi(3, { b => [{ c => [1, 2] }, { d => ['L1', ''] }, { c => [5, 5] }] }),
         mi(2, { b => [{ d => ['top'] }, { c => [2, 4] }] }),
         mi(1)],
        "a\r\n", "\r\n", "b\r\n", "\r\n", "c\r\n", "\r\n");
    my $want = reference_walk($raw);
    my ($bad) = grep {
        !eq_deeply_quiet(plan_walk($raw, [substr($raw, 0, $_), substr($raw, $_)]), $want)
    } 1 .. length($raw) - 1;
    ok(!defined $bad, 'every two-chunk split gives the same hashes')
        or diag "first bad split at byte $bad";
    is_deeply(plan_walk($raw, [split //, $raw]), $want, 'one byte at a time');
}

sub eq_deeply_quiet {
    my ($x, $y) = @_;
    return $JSON->encode($x) eq $JSON->encode($y);
}

done_testing;
