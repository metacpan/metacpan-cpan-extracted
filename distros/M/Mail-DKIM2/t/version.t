use strict; use warnings;
use Test::More;
use Mail::DKIM2;
use Mail::DKIM2::Common qw(DKIM2_DRAFT DKIM2_DATE);
is(DKIM2_DRAFT, 'ietf-dkim-dkim2-spec-07', 'draft constant is -07');
is($Mail::DKIM2::VERSION, '0.27', 'the distribution is 0.27');
is(DKIM2_DATE, '2026-10-18', 'software date is the last DKIM2 behaviour change (draft -07)');

# One distribution version, carried by every module.
ok($Mail::DKIM2::VERSION, 'Mail::DKIM2 has a version');
for my $m (qw(BodyHasher BodyPlan Common Digest DSN Gate HeaderParser HeaderPlan MessageInstance MessageStore Reflector Signature
              Signer Split TagValueList Validate Verifier Wrap)) {
    my $pkg = "Mail::DKIM2::$m";
    eval "require $pkg; 1" or die $@;
    is($pkg->VERSION, $Mail::DKIM2::VERSION, "$pkg carries the distribution version");
}
# No reference to draft -06 may remain in lib/, bin/ or t/ (the code
# targets -07; final review M3), except these history notes, which name the
# draft that made a change.
{
    use File::Find ();
    my %history = (
        'lib/Mail/DKIM2/Validate.pm' => ['Prior to spec-06'],
        'bin/dkim2sign'              => ['pre-spec-06 output'],
        't/validate-report.t'        => ['spec-06 §4 added a "received-" prefix rule'],
        't/hash-agility.t'           => ['pre-spec-06 wire form'],
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
            next unless $line =~ /\b(?:spec|draft)-06\b/;
            next if grep { index($line, $_) >= 0 } @{ $history{$f} || [] };
            push @stale, "$f:$.";
        }
    }
    is_deeply(\@stale, [], 'no draft -06 reference in lib/, bin/ or t/ but the history notes')
        or diag(join "\n", @stale);
}

done_testing;
