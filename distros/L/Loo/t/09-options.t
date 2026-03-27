use strict;
use warnings;
use Test::More;
use Loo;

sub dd {
    my ($data, %opts) = @_;
    my $dd = Loo->new([$data]);
    $dd->{use_colour} = 0;
    while (my ($k, $v) = each %opts) {
        my $method = ucfirst($k);
        $dd->$method($v) if $dd->can($method);
    }
    return $dd->Dump;
}

# ── Pair separator ────────────────────────────────────────────────
my $colon = dd({a => 1}, pair => ': ');
like($colon, qr/'a': 1/, 'custom pair separator');

# ── Quotekeys off ─────────────────────────────────────────────────
my $nq = dd({abc => 1}, quotekeys => 0);
like($nq, qr/abc =>/, 'quotekeys off: bare key');

# ── Quotekeys on (default) ───────────────────────────────────────
my $q = dd({abc => 1});
like($q, qr/'abc' =>/, 'quotekeys on: quoted key');

# ── Useqq ─────────────────────────────────────────────────────────
my $qq = dd("hello\nworld", useqq => 1);
like($qq, qr/"hello\\nworld"/, 'useqq: double-quoted with \\n');

my $sq = dd("hello\nworld", useqq => 0);
like($sq, qr/'hello/, 'useqq off: single-quoted');

# ── Trailingcomma ─────────────────────────────────────────────────
my $tc = dd([1, 2], trailingcomma => 1);
like($tc, qr/2,\n\]/, 'trailingcomma: comma before closing bracket');

my $ntc = dd([1, 2], trailingcomma => 0);
like($ntc, qr/2\n\]/, 'no trailingcomma: no comma before closing bracket');

# ── Maxdepth ──────────────────────────────────────────────────────
my $md = dd({a => {b => {c => 1}}}, maxdepth => 2);
like($md, qr/DUMMY/, 'maxdepth truncates');
like($md, qr/'b'/, 'maxdepth: level 2 present');

# ── Varname ───────────────────────────────────────────────────────
{
    my $dd = Loo->new([1, 2]);
    $dd->{use_colour} = 0;
    $dd->Varname('FOO');
    my $out = $dd->Dump;
    like($out, qr/\$FOO1/, 'varname: FOO1');
    like($out, qr/\$FOO2/, 'varname: FOO2');
}

done_testing;
