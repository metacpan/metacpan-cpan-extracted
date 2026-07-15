use strict;
use warnings;
use Test::More;
use Eshu;

sub r { Eshu->indent_ts($_[0], indent_char => ' ', indent_width => 4) }

# ── regular enum ──────────────────────────────────────────────────

{
    my $src = <<'END';
enum Direction {
Up,
Down,
Left,
Right,
}
END
    my $out = r($src);
    like($out, qr/^enum Direction \{$/m, 'enum at depth 0');
    like($out, qr/^    Up,$/m,           'member at depth 1');
    like($out, qr/^    Down,$/m,         'member at depth 1');
    like($out, qr/^\}$/m,               'closing at depth 0');
}

# ── const enum ────────────────────────────────────────────────────

{
    my $src = <<'END';
const enum Status {
Active = 'ACTIVE',
Inactive = 'INACTIVE',
}
END
    my $out = r($src);
    like($out, qr/^const enum Status \{$/m,      'const enum at depth 0');
    like($out, qr/^    Active = 'ACTIVE',$/m,    'member at depth 1');
    like($out, qr/^    Inactive = 'INACTIVE',$/m,'member at depth 1');
}

# ── enum inside function — JS engine case-extra depth ─────────────
# The JS engine places case/default at the switch brace depth,
# and case body lines get one extra level (case_extra=1).
# switch { is at depth 1, so: switch { opens to depth 2,
# case labels are at depth 2, case bodies at depth 3.

{
    my $src = <<'END';
function getLabel(d: Direction): string {
switch (d) {
case Direction.Up:
return 'Up';
default:
return 'Other';
}
}
END
    my $out = r($src);
    like($out, qr/^function getLabel/m,           'function at depth 0');
    like($out, qr/^    switch \(d\) \{$/m,        'switch at depth 1');
    like($out, qr/^        case Direction\.Up:$/m, 'case at switch brace depth');
    like($out, qr/^            return 'Up';$/m,   'case body one level deeper');
    like($out, qr/^    \}$/m,                     'switch closing at depth 1');
    like($out, qr/^\}$/m,                         'function closing at depth 0');
}

done_testing;
