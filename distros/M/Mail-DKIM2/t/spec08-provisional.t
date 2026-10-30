use 5.020;
use strict;
use warnings;
use Test::More;
use lib 'lib', 't/lib';
use Spec07Fixture;

# -08 section 13.2: a message is Provisionally Verified when the top
# DKIM2-Signature and the top Message-Instance pass five checks: (1) the
# signature's m= is the top instance's; (2) its s= passes; (3) the
# instance's h= passes; (4) MAIL FROM and RCPT TO match its mf= and rt=
# (the SMTP layer's to check: the Verifier is not given the envelope); and
# (5) its d= relaxed-matches its mf=, unless mf= is null. Timestamps are
# not among them.

sub pv { Spec07Fixture::verify($_[0])->provisionally_verified }

my $base = Spec07Fixture::add_mi(Spec07Fixture::message());

ok(pv(Spec07Fixture::add_sig($base, d => 'example.com', mf => '<a@example.com>',
    rt => ['<list@lists.example.org>'])), 'a good top signature: PV');

my $mismatch = Spec07Fixture::add_sig($base, d => 'example.com', mf => '<a@example.net>',
    rt => ['<list@lists.example.org>']);
ok(!pv($mismatch), 'step 5: d= does not match mf=: not PV');

ok(pv(Spec07Fixture::add_sig($base, d => 'example.com', mf => '<>',
    rt => ['<list@lists.example.org>'])), 'step 5: a null mf= is not compared: PV');

my $old = Spec07Fixture::add_sig($base, d => 'example.com', mf => '<a@example.com>',
    rt => ['<list@lists.example.org>'], t => time - 20 * 86400);
my $v = Spec07Fixture::verify($old);
is($v->result, 'fail', 'a signature 20 days old fails');
ok($v->provisionally_verified, '... but timestamps are not a section 13.2 check: PV');

done_testing;
