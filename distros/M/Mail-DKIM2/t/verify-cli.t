use strict;
use warnings;
use Test::More;
use Path::Tiny;
use lib 'lib';

# bin/dkim2verify -- the standalone verifier CLI, the counterpart of
# bin/dkim2sign and of the python/go/c dkim2verify tools. Exit status is the
# machine-readable verdict: 0 pass, 1 anything else permanent, 75 (EX_TEMPFAIL)
# temperror.

my $good = path('tests/expected/chain-hop2-mailing-list.eml');

sub run_cli {
    my ($input, @args) = @_;
    my @cmd = ($^X, '-Ilib', 'bin/dkim2verify', @args);
    my $out;
    if (ref $input) {           # scalar ref: feed on stdin
        my $tmp = Path::Tiny->tempfile; $tmp->spew_raw($$input);
        my $cmd = join(' ', map { quotemeta } @cmd, '-') . " < " . quotemeta("$tmp");
        $out = `$cmd`;
    } else {
        push @cmd, $input;
        open my $fh, '-|', @cmd or die "cannot run: $!";
        $out = do { local $/; <$fh> };
        close $fh;
    }
    return ($? >> 8, $out // '');
}

{
    my ($rc, $out) = run_cli("$good", '--dns-json', 't/data/dns.json', '--ignore-timestamps');
    is($rc, 0, 'a good two-hop chain exits 0');
    like($out, qr/^pass\b/, '  ... and prints the result');
}

{
    (my $text = $good->slurp_raw) =~ s/^Subject: /Subject: tampered /m;
    my $tmp = Path::Tiny->tempfile; $tmp->spew_raw($text);
    my ($rc, $out) = run_cli("$tmp", '--dns-json', 't/data/dns.json', '--ignore-timestamps');
    is($rc, 1, 'a tampered message exits 1');
    like($out, qr/^fail\b/, '  ... and says fail');
}

{
    my $text = $good->slurp_raw;
    my ($rc, $out) = run_cli(\$text, '--dns-json', 't/data/dns.json', '--ignore-timestamps');
    is($rc, 0, 'the message can come on stdin');
}

{
    my ($rc, $out) = run_cli("$good", '--dns-json', 't/data/dns.json');
    is($rc, 1, 'without --ignore-timestamps a 2026 fixture is stale');
    like($out, qr/timestamp|expired|old/i, '  ... for that reason');
}

{
    my ($rc, $out) = run_cli(\"Subject: x\r\n\r\nbody\r\n", '--dns-json', 't/data/dns.json');
    is($rc, 1, 'an unsigned message exits 1');
    like($out, qr/^none\b/, '  ... and says none');
}

done_testing;
