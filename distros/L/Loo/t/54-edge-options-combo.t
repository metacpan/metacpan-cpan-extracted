use strict;
use warnings;
use Test::More;
use Loo;

sub dd {
    my ($data, %opts) = @_;
    my $dd = Loo->new(ref $data eq 'ARRAY' ? $data : [$data]);
    $dd->{use_colour} = 0;
    while (my ($k, $v) = each %opts) {
        my $method = ucfirst($k);
        $dd->$method($v) if $dd->can($method);
    }
    return $dd->Dump;
}

# ── Terse + Indent 0 with scalar ────────────────────────────────
{
    my $out = dd(42, terse => 1, indent => 0);
    is($out, "42\n", 'terse + indent 0: scalar');
}

# ── Terse + Indent 0 with hash ──────────────────────────────────
{
    my $out = dd({a => 1}, terse => 1, indent => 0, sortkeys => 1);
    like($out, qr/'a' => 1/, 'terse + indent 0: hash has content');
}

# ── Useqq + Sortkeys ────────────────────────────────────────────
{
    my $out = dd({"b\n" => 1, "a\t" => 2}, useqq => 1, sortkeys => 1);
    like($out, qr/"a\\t" =>.*"b\\n" =>/s, 'useqq + sortkeys: sorted double-quoted keys');
}

# ── Trailingcomma with array (via OO to pass arrayref correctly) ─
{
    my $dd = Loo->new([[1, 2]]);
    $dd->{use_colour} = 0;
    $dd->Trailingcomma(1);
    my $out = $dd->Dump;
    like($out, qr/2,\n/, 'trailingcomma: trailing comma on last element');
}

# ── Trailingcomma with hash ─────────────────────────────────────
{
    my $out = dd({a => 1}, trailingcomma => 1, sortkeys => 1);
    like($out, qr/'a' => 1,\n/, 'trailingcomma with hash');
}

# ── Maxdepth 1 ──────────────────────────────────────────────────
{
    my $out = dd({a => [1]}, maxdepth => 1, sortkeys => 1);
    like($out, qr/'a' =>/, 'maxdepth 1: key present');
    like($out, qr/DUMMY/, 'maxdepth 1: truncated at depth 1');
}

# ── Maxdepth 0 (unlimited) ─────────────────────────────────────
{
    my $deep = {a => {b => {c => {d => 1}}}};
    my $out = dd($deep, maxdepth => 0, sortkeys => 1);
    like($out, qr/'d' => 1/, 'maxdepth 0: deeply nested value present');
}

# ── Pad option with nested structure ────────────────────────────
{
    my $out = dd({a => [1]}, pad => '# ', sortkeys => 1);
    my @lines = split /\n/, $out;
    for my $line (@lines) {
        next if $line eq '';
        like($line, qr/^# /, "pad: line starts with '# '");
    }
}

# ── Quotekeys off with various key types ────────────────────────
{
    my $out = dd({'_priv' => 1, 'with space' => 2, '' => 3}, quotekeys => 0, sortkeys => 1);
    like($out, qr/^  _priv =>/m, 'quotekeys off: bareword underscore key');
    like($out, qr/'with space' =>/, 'quotekeys off: spaced key still quoted');
    like($out, qr/'' =>/, 'quotekeys off: empty key still quoted');
}

# ── Indent 3 ────────────────────────────────────────────────────
{
    my $out = dd({a => 1}, indent => 3, sortkeys => 1);
    like($out, qr/'a'/, 'indent 3: key present');
}

# ── Custom pair with arrow ──────────────────────────────────────
{
    my $out = dd({a => 1}, pair => ' -> ', sortkeys => 1);
    like($out, qr/'a' -> 1/, 'custom pair arrow');
}

# ── Pair with colon (JSON-like) ─────────────────────────────────
{
    my $out = dd({a => 1}, pair => ': ', sortkeys => 1);
    like($out, qr/'a': 1/, 'colon pair separator');
}

# ── Sortkeys with coderef (reverse sort) ────────────────────────
{
    my $dd = Loo->new([{a => 1, b => 2, c => 3}]);
    $dd->{use_colour} = 0;
    $dd->Sortkeys(sub { [reverse sort keys %{$_[0]}] });
    my $out = $dd->Dump;
    like($out, qr/'c'.*'b'.*'a'/s, 'sortkeys coderef: reverse sorted');
}

# ── Multiple values with custom names ───────────────────────────
{
    my $dd = Loo->new([42, 'hello'], ['$num', '$str']);
    $dd->{use_colour} = 0;
    my $out = $dd->Dump;
    like($out, qr/\$num = 42/, 'custom name: $num');
    like($out, qr/\$str = 'hello'/, 'custom name: $str');
}

# ── Names with sigils ───────────────────────────────────────────
{
    my $dd = Loo->new([[1, 2]], ['@arr']);
    $dd->{use_colour} = 0;
    my $out = $dd->Dump;
    like($out, qr/\@arr/, 'array name with @ sigil');
}

done_testing;
