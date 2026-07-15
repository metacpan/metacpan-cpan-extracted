use strict;
use warnings;
use Test::More;
use Eshu;

sub r { Eshu->indent_ts($_[0], indent_char => ' ', indent_width => 4) }

# ── class with implements ─────────────────────────────────────────

{
    my $src = <<'END';
class Dog implements Animal {
name: string;
constructor(name: string) {
this.name = name;
}
speak(): void {
console.log("Woof");
}
}
END
    my $out = r($src);
    like($out, qr/^class Dog implements Animal \{$/m, 'class at depth 0');
    like($out, qr/^    name: string;$/m,              'property at depth 1');
    like($out, qr/^    constructor\(name: string\) \{$/m, 'constructor at depth 1');
    like($out, qr/^        this\.name = name;$/m,     'body at depth 2');
    like($out, qr/^    speak\(\): void \{$/m,         'method at depth 1');
    like($out, qr/^\}$/m,                             'closing brace at depth 0');
}

# ── interface ─────────────────────────────────────────────────────

{
    my $src = <<'END';
interface Animal {
name: string;
speak(): void;
}
END
    my $out = r($src);
    like($out, qr/^interface Animal \{$/m, 'interface at depth 0');
    like($out, qr/^    name: string;$/m,   'member at depth 1');
    like($out, qr/^\}$/m,                  'closing brace at depth 0');
}

# ── type alias ────────────────────────────────────────────────────

{
    my $src = <<'END';
type Point = {
x: number;
y: number;
};
END
    my $out = r($src);
    like($out, qr/^type Point = \{$/m, 'type alias at depth 0');
    like($out, qr/^    x: number;$/m,  'field at depth 1');
    like($out, qr/^\};$/m,             'closing at depth 0');
}

# ── generic function ──────────────────────────────────────────────

{
    my $src = <<'END';
function identity<T>(arg: T): T {
return arg;
}
END
    my $out = r($src);
    like($out, qr/^function identity<T>\(arg: T\): T \{$/m, 'generic function');
    like($out, qr/^    return arg;$/m,                      'body at depth 1');
}

# ── detect_lang ───────────────────────────────────────────────────

{
    is(Eshu->detect_lang('app.ts'),  'ts',  'detect .ts');
    is(Eshu->detect_lang('app.tsx'), 'ts',  'detect .tsx');
    is(Eshu->detect_lang('app.mts'), 'ts',  'detect .mts');
}

done_testing;
