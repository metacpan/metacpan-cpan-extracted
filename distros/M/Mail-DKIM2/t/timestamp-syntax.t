use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use DKIM2SignedFixture;

# spec-06 §8.4: t= is 1*DIGIT, an unsigned decimal; §11.2 says validate the
# format. A malformed t= is a syntax error whether or not the age check
# runs (review R6) -- it used to numify to 0 and skip the age check.

for my $c (
    [ time,          0, qr/^pass/ ],
    [ time,          1, qr/^pass/ ],
    [ 'garbage',     0, qr/^permerror .*DKIM2-Signature i=1 syntax error/ ],
    [ 'garbage',     1, qr/^permerror .*DKIM2-Signature i=1 syntax error/ ],
    [ '-5',          1, qr/^permerror .*DKIM2-Signature i=1 syntax error/ ],
    [ '1e9',         1, qr/^permerror .*DKIM2-Signature i=1 syntax error/ ],
    [ '0x10',        1, qr/^permerror .*DKIM2-Signature i=1 syntax error/ ],
    [ '12 34',       1, qr/^permerror .*DKIM2-Signature i=1 syntax error/ ],
    [ '0',           0, qr/^fail .*expired/ ],
    [ '0',           1, qr/^pass/ ],
    [ '1000000000000', 0, qr/^fail .*future/ ],   # §8.4: up to 10^12 handled
) {
    my ($t, $skip, $want) = @$c;
    my $v = DKIM2SignedFixture::verify(DKIM2SignedFixture::signed(timestamp => $t),
        SkipTimestampCheck => $skip);
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, @_ };
    like($v->result_detail, $want,
        "t=$t" . ($skip ? ' (SkipTimestampCheck)' : '') . ': ' . $v->result_detail);
}

done_testing;
