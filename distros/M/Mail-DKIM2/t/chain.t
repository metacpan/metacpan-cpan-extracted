use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use MIME::Base64 qw(encode_base64);
use Mail::DKIM2::Chain;

# Mail::DKIM2::Chain: the Message-Instance and DKIM2-Signature fields of a
# message by number, and whether the numbers form a chain -- from the
# fields alone, nothing verified.

my $H = 'sha256:AAAA:AAAA';
sub mi  { my ($m, $r) = @_; "Message-Instance: m=$m; h=$H" . (defined $r ? '; r=' . encode_base64($r, '') : '') . "\r\n" }
sub sig { my ($i, $m, %o) = @_;
          "DKIM2-Signature: i=$i; m=$m; t=1; d=example.com; "
        . (defined $o{nd} ? "nd=$o{nd}; " : 'mf=PD4=; rt=PD4=; ') . "s=sel:rsa-sha256:AAAA\r\n" }
sub chain { Mail::DKIM2::Chain->from_message(join('', @_) . "From: a\@example.com\r\n\r\nbody\r\n") }

subtest 'what is in it' => sub {
    my $c = chain(sig(2, 2), mi(3, '{"b":null}'), sig(1, 1), mi(2), mi(1));
    is_deeply([$c->instance_numbers], [1, 2, 3], 'instance numbers, ascending');
    is_deeply([$c->signature_numbers], [1, 2], 'signature numbers, ascending');
    is(scalar($c->instance_numbers), 3, 'counted in scalar context');
    is($c->top_instance, 3, 'top instance');
    is($c->top_signature_number, 2, 'top signature number');
    is($c->top_signature->sequence, 2, 'top signature');
    is(scalar(my @s = $c->signatures), 2, 'signatures');
    is($c->count('message-instance'), 3, 'count');
    is($c->covered_m, 2, 'covered_m is the highest m= a signature names');
    is_deeply([$c->unsigned_instances], [3], 'the instance above it is unsigned');
    like($c->instance_field(2), qr/\AMessage-Instance: m=2;/, 'the field as it is in the message');
    like($c->signature_field(1), qr/\ADKIM2-Signature: i=1;/, 'and a signature field');
    ok($c->instance(3)->unrecoverable, 'instance() parses');
    is($c->instance(3), $c->instance(3), 'once');
    is($c->structure_error, 'PERMERROR: Message-Instance m=3 is not signed', 'm=3 is not signed');
    is($c->structure_error(AllowUnsigned => 1), undef, 'unless the caller is about to sign it');
    ok(!$c->is_empty, 'not empty');
};

subtest 'an empty chain' => sub {
    my $c = chain();
    ok($c->is_empty, 'is_empty');
    is($c->top_instance, undef, 'no top instance');
    is($c->top_signature, undef, 'no top signature');
    is($c->covered_m, 0, 'covered_m is 0');
    is($c->structure_error, undef, 'and nothing is wrong with it');
};

subtest 'an instance that does not parse' => sub {
    my $c = chain(mi(1, '{nope'));
    my ($mi, $why) = $c->instance(1);
    is($mi, undef, 'no object');
    is($why, 'PERMERROR: Message-Instance m=1 contains invalid JSON', 'the reason, in the Verifier\'s words');
    is_deeply([$c->instance(2)], [undef, 'PERMERROR: Message-Instance m=2 missing'], 'one that is not there');
};

subtest 'faults, in the contract\'s order' => sub {
    my @cases = (
        [ 'a field with no m=', [ "Message-Instance: h=$H\r\n", mi(1) ],
          'PERMERROR: Message-Instance m= tag=m missing' ],
        [ 'm= not a chain number', [ "Message-Instance: m=1x; h=$H\r\n" ],
          'PERMERROR: Message-Instance m=1x syntax error' ],
        [ 'm= twice', [ mi(1), mi('01') ], 'PERMERROR: Message-Instance m=1 is duplicated' ],
        [ 'a signature with no i=', [ mi(1), "DKIM2-Signature: m=1; d=example.com\r\n" ],
          'PERMERROR: DKIM2-Signature i= tag=i missing' ],
        [ 'i= twice', [ mi(1), sig(1, 1), sig(1, 1) ], 'PERMERROR: DKIM2-Signature i=1 is duplicated' ],
        [ 'an instance missing', [ mi(2), sig(1, 2) ], 'PERMERROR: Message-Instance m=1 missing' ],
        [ 'the instance a signature names missing', [ mi(1), sig(1, 2) ],
          'PERMERROR: Message-Instance m=2 missing' ],
        [ 'a signature missing', [ mi(1), sig(2, 1) ], 'PERMERROR: DKIM2-Signature i=1 missing' ],
        [ 'an instance fault before a signature fault',
          [ mi(1), mi(1), "DKIM2-Signature: m=1\r\n" ], 'PERMERROR: Message-Instance m=1 is duplicated' ],
        [ 'too many fields', [ map { mi($_) } 1 .. 33 ], 'PERMERROR: more than 32 Message-Instance fields' ],
    );
    for my $case (@cases) {
        my ($name, $fields, $want) = @$case;
        is(chain(@$fields)->structure_error, $want, $name);
    }
    my $c = chain(mi(1), "DKIM2-Signature: m=1\r\n");
    is($c->structure_error(Signatures => 0), undef, 'Signatures => 0: the instances alone');
    is($c->numbering_error, 'PERMERROR: DKIM2-Signature i= tag=i missing', 'numbering_error');
    is(chain(mi(2), sig(1, 2))->numbering_error, undef, 'a gap is not a numbering error');
};

subtest 'from_fields, and names written oddly' => sub {
    my $c = Mail::DKIM2::Chain->from_fields([
        "MESSAGE-instance : m=1;\r\n\th=$H\r\n", "Subject: x\r\n", sig(1, 1, nd => 'example.net') ]);
    is_deeply([$c->instance_numbers], [1], 'case and WSP before the colon do not matter');
    is($c->top_signature->next_domain, 'example.net', 'the signature is parsed');
    is($c->structure_error, undef, 'a sound chain');
};

done_testing;
