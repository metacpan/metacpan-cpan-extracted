use strict;
use warnings;
use Test::More;
use Eshu;

sub r { Eshu->indent_ts($_[0], indent_char => ' ', indent_width => 4) }

# ── namespace block ───────────────────────────────────────────────

{
    my $src = <<'END';
namespace Validation {
export interface StringValidator {
isAcceptable(s: string): boolean;
}
export class LettersOnlyValidator implements StringValidator {
isAcceptable(s: string) {
return /^[A-Za-z]+$/.test(s);
}
}
}
END
    my $out = r($src);
    like($out, qr/^namespace Validation \{$/m,       'namespace at depth 0');
    like($out, qr/^    export interface StringValidator \{$/m, 'interface at depth 1');
    like($out, qr/^        isAcceptable\(s: string\): boolean;$/m, 'method at depth 2');
    like($out, qr/^    export class LettersOnlyValidator/m, 'class at depth 1');
    like($out, qr/^        isAcceptable\(s: string\) \{$/m, 'method at depth 2');
    like($out, qr/^            return/m,             'body at depth 3');
}

# ── module block ──────────────────────────────────────────────────

{
    my $src = <<'END';
module MyLib {
export function log(msg: string): void {
console.log(msg);
}
}
END
    my $out = r($src);
    like($out, qr/^module MyLib \{$/m,         'module at depth 0');
    like($out, qr/^    export function log/m,  'function at depth 1');
    like($out, qr/^        console\.log/m,     'body at depth 2');
}

# ── declare global ────────────────────────────────────────────────

{
    my $src = <<'END';
declare global {
interface Window {
myProp: string;
}
}
END
    my $out = r($src);
    like($out, qr/^declare global \{$/m,  'declare global at depth 0');
    like($out, qr/^    interface Window \{$/m, 'interface at depth 1');
    like($out, qr/^        myProp: string;$/m, 'property at depth 2');
}

done_testing;
