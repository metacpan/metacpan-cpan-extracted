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

# ── Terse mode: no $VARn = prefix ─────────────────────────────────
is(dd(42, terse => 1), "42\n", 'terse scalar');
is(dd('hello', terse => 1), "'hello'\n", 'terse string');
is(dd([1, 2], terse => 1), "[\n  1,\n  2\n]\n", 'terse array');
is(dd({a => 1}, terse => 1), "{\n  'a' => 1\n}\n", 'terse hash');

# ── Terse with indent 0 ──────────────────────────────────────────
is(dd([1, 2], terse => 1, indent => 0), "[1, 2]\n", 'terse indent 0');

# ── Non-terse: $VARn prefix present ──────────────────────────────
like(dd(42), qr/^\$VAR1 = 42;/, 'non-terse has $VAR assignment');

done_testing;
