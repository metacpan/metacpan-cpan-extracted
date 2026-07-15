use strict;
use warnings;
use Test::More;
use Eshu;

# TSX uses the same TS indentation (brace-based, same as JS).
# The JS engine has no JSX tag awareness; content involving </tag>
# can trigger regex detection. We test brace-depth for TS constructs.

sub r { Eshu->indent_ts($_[0], indent_char => ' ', indent_width => 4) }

# ── TSX-style function component (no JSX content) ─────────────────

{
    my $src = <<'END';
function Button(props: { label: string; onClick: () => void }) {
const { label } = props;
return label;
}
END
    my $out = r($src);
    like($out, qr/^function Button/m, 'component at depth 0');
    like($out, qr/^    const \{ label \} = props;$/m, 'body at depth 1');
    like($out, qr/^    return label;$/m, 'return at depth 1');
    like($out, qr/^\}$/m,              'closing at depth 0');
}

# ── detect_lang for .tsx ──────────────────────────────────────────

{
    is(Eshu->detect_lang('Component.tsx'), 'ts', '.tsx detected as ts');
}

# ── indent_string tsx alias uses tabs by default ──────────────────

{
    my $src = "function f() {\nreturn 1;\n}\n";
    my $out = Eshu->indent_string($src, lang => 'tsx');
    like($out, qr/^\treturn 1;$/m, 'indent_string tsx uses tab by default');
}

# ── indent_string ts alias uses tabs by default ───────────────────

{
    my $src = "function f() {\nreturn 1;\n}\n";
    my $out = Eshu->indent_string($src, lang => 'ts');
    like($out, qr/^\treturn 1;$/m, 'indent_string ts uses tab by default');
}

# ── indent_ts with explicit spaces ────────────────────────────────

{
    my $src = "function f() {\nreturn 1;\n}\n";
    my $out = Eshu->indent_ts($src, indent_char => ' ', indent_width => 2);
    like($out, qr/^  return 1;$/m, 'indent_ts with 2 spaces');
}

done_testing;
