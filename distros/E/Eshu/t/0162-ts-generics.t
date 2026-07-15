use strict;
use warnings;
use Test::More;
use Eshu;

sub r { Eshu->indent_ts($_[0], indent_char => ' ', indent_width => 4) }

# ── generic function — angle brackets don't affect depth ──────────

{
    my $src = <<'END';
function pick<T extends object, K extends keyof T>(obj: T, key: K): T[K] {
return obj[key];
}
END
    my $out = r($src);
    like($out, qr/^function pick</m,      'generic function at depth 0');
    like($out, qr/^    return obj\[key\];$/m, 'body at depth 1');
    like($out, qr/^\}$/m,                 'closing at depth 0');
}

# ── generic interface ─────────────────────────────────────────────

{
    my $src = <<'END';
interface Repository<T> {
findById(id: number): T;
findAll(): T[];
save(entity: T): void;
}
END
    my $out = r($src);
    like($out, qr/^interface Repository<T> \{$/m, 'generic interface');
    like($out, qr/^    findById\(id: number\): T;$/m, 'method at depth 1');
    like($out, qr/^    findAll\(\): T\[\];$/m,    'array return at depth 1');
}

# ── conditional type ──────────────────────────────────────────────

{
    my $src = <<'END';
function process<T>(input: T): T extends string ? number : boolean {
if (typeof input === 'string') {
return input.length as any;
}
return true as any;
}
END
    my $out = r($src);
    like($out, qr/^function process/m, 'generic function');
    like($out, qr/^    if \(typeof/m,  'if at depth 1');
    like($out, qr/^        return input\.length/m, 'body at depth 2');
}

done_testing;
