use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use JSON::PP;
use ForgeOps::Tracker::PiiScrubber qw(scrub scrub_string REDACTED);

# A byte-identical copy of sdks/pii_scrubbing_vectors.json, generated from the server's own
# PiiScrubber; every SDK checks itself against the same file.
my $vectors = do {
    open my $fh, '<:raw', "$Bin/fixtures/pii_scrubbing_vectors.json" or die "can't read vectors: $!";
    local $/;
    decode_json(<$fh>);
};

subtest 'scrubs every shared card number and IBAN vector exactly as the server does' => sub {
    ok(scalar @{ $vectors->{strings} } > 0, 'string vectors loaded');
    for my $vector (@{ $vectors->{strings} }) {
        my $label = JSON::PP->new->ascii->allow_nonref->encode($vector->{input});
        is(scrub_string($vector->{input}), $vector->{scrubbed}, "scrubbed $label");
    }
};

subtest 'redacts every shared bank-detail key vector exactly as the server does' => sub {
    ok(scalar @{ $vectors->{keys} } > 0, 'key vectors loaded');
    for my $vector (@{ $vectors->{keys} }) {
        my $expected = $vector->{redacted} ? REDACTED : 'x';
        is_deeply(scrub({ $vector->{key} => 'x' }), { $vector->{key} => $expected }, "key $vector->{key}");
    }
};

subtest 'redacts an email address embedded in free text' => sub {
    is(
        scrub_string("undefined method 'name' for user\@example.com"),
        "undefined method 'name' for [EMAIL FILTERED]",
    );
};

subtest 'redacts a formatted credit card number but leaves an ordinary long numeric id alone' => sub {
    is(scrub_string('card 4111-1111-1111-1111 declined'), 'card [CREDIT CARD FILTERED] declined');
    is(
        scrub_string("Couldn't find Invoice with id=8821445199"),
        "Couldn't find Invoice with id=8821445199",
    );
};

subtest 'redacts a formatted SSN' => sub {
    is(scrub_string('ssn on file: 123-45-6789'), 'ssn on file: [SSN FILTERED]');
};

subtest 'redacts known API key and token formats' => sub {
    is(scrub_string('using sk_live_4eC39HqLyjWDarjtT1zdp7dc'), 'using [STRIPE KEY FILTERED]');
    is(scrub_string('Authorization: Bearer abc123.def456'), 'Authorization: [BEARER TOKEN FILTERED]');
    is(scrub_string('key AKIAIOSFODNN7EXAMPLE in use'), 'key [AWS KEY FILTERED] in use');
    is(scrub_string('token ghp_1234567890abcdefghijklmnopqrstuv'), 'token [GITHUB TOKEN FILTERED]');
};

subtest 'redacts the whole value under a sensitive-looking key regardless of type or casing' => sub {
    my $scrubbed = scrub({ password => 'hunter2', 'API-Key' => 'sk_live_abc', count => 3 });

    is_deeply($scrubbed, { password => '[FILTERED]', 'API-Key' => '[FILTERED]', count => 3 });
};

subtest 'recurses into nested hashes and arrays' => sub {
    my $scrubbed = scrub({ user => { email => 'ada@example.com' }, notes => ['no PII here'] });

    is_deeply($scrubbed, { user => { email => '[EMAIL FILTERED]' }, notes => ['no PII here'] });
};

subtest "does not redact a key-based match for an unrelated short substring like 'pin'" => sub {
    my $scrubbed = scrub({ opinion => 'strong', pinned_at => '2026-01-01' });

    is_deeply($scrubbed, { opinion => 'strong', pinned_at => '2026-01-01' });
};

done_testing;
