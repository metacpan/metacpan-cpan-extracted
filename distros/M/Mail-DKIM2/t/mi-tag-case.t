use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use DKIM2SignedFixture;
use Mail::DKIM2::Common qw(mi_version_tag extract_mi_version);
use Mail::DKIM2::MessageInstance;

# -08 §9: Message-Instance tag-names MUST be lowercase, and §8 makes them
# case-sensitive. Under the -08 contract (decision 4, D10) a tag-name that
# is not lowercase is an unknown tag: ignored, so "M=1" alone is a missing
# m=, and "m=1; M=2" is not a duplicate. There MUST be only one of each kind.

my $mi = DKIM2SignedFixture::mi_value();

sub verify_mi {
    my ($value) = @_;
    return DKIM2SignedFixture::verify(DKIM2SignedFixture::signed(mi => $value))
        ->result_detail;
}

like(verify_mi($mi), qr/^pass/, 'lowercase: pass');
(my $up_h = $mi) =~ s/\bh=/H=/;
like(verify_mi($up_h), qr/^permerror .*Message-Instance m=1 tag=h missing/,
    'H= is an unknown tag: h= missing');
(my $up_m = $mi) =~ s/\bm=/M=/;
like(verify_mi($up_m), qr/^permerror .*Message-Instance m= tag=m missing/,
    'M= is an unknown tag: m= missing');

my ($h) = $mi =~ /\bh=([^;]+)/;
like(verify_mi("m=1; h=sha256:AAAA:AAAA; h=$h"),
    qr/^permerror .*Message-Instance m=1 syntax error/,
    'a wrong h= before the right one: syntax error, not pass');
like(verify_mi("m=1; h=$h; H=sha256:AAAA:AAAA"), qr/^pass/,
    'h= and H=: H= ignored, pass');
like(verify_mi("m=1; M=7; h=$h"), qr/^pass/, 'm= and M=: M= ignored, pass');

# The parser and the m= helpers directly.
is(mi_version_tag('M=3; h=x'), undef, 'mi_version_tag: M= is not m=');
is(mi_version_tag('M=3; m=2; h=x'), '2', 'mi_version_tag: m= after M=');
is(mi_version_tag(' m = 4 ; h=x'), '4', 'mi_version_tag: spaced');
is(extract_mi_version('h=x; m=5'), 5, 'extract_mi_version: m= not first');
my $p = Mail::DKIM2::MessageInstance->parse("m=1; h=$h; H=sha256:AAAA:AAAA");
is($p->get_tag('m'), 1, 'parse: m= read');
is($p->body_hash, (split /:/, $h)[2], 'parse: H= ignored, h= read');
eval { Mail::DKIM2::MessageInstance->parse("m=1; h=$h; h=$h") };
like($@, qr/Message-Instance m=1 syntax error/, 'parse: identical h= twice dies');

done_testing;
