use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use DKIM2SignedFixture;
use Mail::DKIM2::Common qw(mi_version_tag extract_mi_version);
use Mail::DKIM2::MessageInstance;

# spec-06 §7: Message-Instance tag identifiers are case insignificant, and
# there MUST be only one of each kind (review R4, R5). We emit lowercase;
# we accept any case, and reject a repeat whatever its case.

my $mi = DKIM2SignedFixture::mi_value();

sub verify_mi {
    my ($value) = @_;
    return DKIM2SignedFixture::verify(DKIM2SignedFixture::signed(mi => $value))
        ->result_detail;
}

like(verify_mi($mi), qr/^pass/, 'lowercase: pass');
(my $up_h = $mi) =~ s/\bh=/H=/;
like(verify_mi($up_h), qr/^pass/, 'H=: pass');
(my $up_m = $mi) =~ s/\bm=/M=/;
like(verify_mi($up_m), qr/^pass/, 'M=: pass');
(my $up_both = $up_h) =~ s/\bm=/M=/;
like(verify_mi($up_both), qr/^pass/, 'M= and H=: pass');

my ($h) = $mi =~ /\bh=([^;]+)/;
like(verify_mi("m=1; h=sha256:AAAA:AAAA; h=$h"),
    qr/^permerror .*Message-Instance m=1 syntax error/,
    'a wrong h= before the right one: syntax error, not pass');
like(verify_mi("m=1; h=$h; H=sha256:AAAA:AAAA"),
    qr/^permerror .*Message-Instance m=1 syntax error/, 'h= and H=: syntax error');
like(verify_mi("m=1; M=1; h=$h"),
    qr/^permerror .*Message-Instance m=1 syntax error/, 'm= and M=: syntax error');

# The parser and the m= helpers directly.
is(mi_version_tag('M=3; h=x'), '3', 'mi_version_tag: M=');
is(mi_version_tag(' m = 4 ; h=x'), '4', 'mi_version_tag: spaced');
is(extract_mi_version('h=x; M=5'), 5, 'extract_mi_version: M= not first');
my $p = Mail::DKIM2::MessageInstance->parse($up_both);
is($p->get_tag('m'), 1, 'parse: M= read as m');
ok($p->body_hash, 'parse: H= read as h');
eval { Mail::DKIM2::MessageInstance->parse("m=1; h=$h; h=$h") };
like($@, qr/Message-Instance m=1 syntax error/, 'parse: identical h= twice dies');

done_testing;
