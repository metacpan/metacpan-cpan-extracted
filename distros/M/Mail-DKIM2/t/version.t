use strict; use warnings;
use Test::More;
use Mail::DKIM2;
use Mail::DKIM2::Common qw(DKIM2_DRAFT DKIM2_DATE);
is(DKIM2_DRAFT, 'ietf-dkim-dkim2-spec-08', 'draft constant is -08');
is($Mail::DKIM2::VERSION, '0.28', 'the distribution is 0.28');
is(DKIM2_DATE, '2026-10-28', 'software date is the last DKIM2 behaviour change (draft -08)');

# One distribution version, carried by every module.
ok($Mail::DKIM2::VERSION, 'Mail::DKIM2 has a version');
for my $m (qw(BodyHasher BodyPlan Common Digest DSN Gate HeaderParser HeaderPlan MessageInstance MessageStore Reflector Signature
              Signer Split TagValueList Validate Verifier Wrap)) {
    my $pkg = "Mail::DKIM2::$m";
    eval "require $pkg; 1" or die $@;
    is($pkg->VERSION, $Mail::DKIM2::VERSION, "$pkg carries the distribution version");
}
# No pointer to draft -06 or -07 may remain in lib/, bin/ or t/ (the code
# targets -08; final review M3), except these history notes, which name the
# draft that made a change. A "-07 contract" (its C1-C9 and decisions) is
# history by name and is not matched.
{
    use File::Find ();
    my %history = (
        'lib/Mail/DKIM2/Validate.pm' => ['Prior to spec-06'],
        'bin/dkim2sign'              => ['pre-spec-06 output'],
        't/validate-report.t'        => ['spec-06 §4 added a "received-" prefix rule'],
        't/hash-agility.t'           => ['pre-spec-06 wire form'],
        't/check-order.t'            => ['2026-10-18-dkim2-spec-07-design.md'],
    );
    my @files;
    File::Find::find({ no_chdir => 1, wanted => sub {
        push @files, $File::Find::name if -f && /\.(?:pm|t)\z/;
    } }, grep { -d } qw(lib t));
    push @files, grep { -f } glob 'bin/*';
    my @stale;
    for my $f (sort @files) {
        next if $f eq 't/version.t';
        open my $fh, '<', $f or die "$f: $!";
        while (my $line = <$fh>) {
            next unless $line =~ /\b(?:spec|draft)-0[67]\b|-0[67] (?:§|sections?\b)/;
            next if grep { index($line, $_) >= 0 } @{ $history{$f} || [] };
            push @stale, "$f:$.";
        }
    }
    is_deeply(\@stale, [], 'no draft -06/-07 pointer in lib/, bin/ or t/ but the history notes')
        or diag(join "\n", @stale);
}

done_testing;
