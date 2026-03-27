use strict;
use warnings;
use Test::More;
use Loo;

# Helper: dump hash with sortkeys for deterministic output
sub dump_hash {
    my ($data, %opts) = @_;
    my $dd = Loo->new([$data]);
    $dd->{use_colour} = 0;
    $dd->Sortkeys(1);
    while (my ($k, $v) = each %opts) {
        my $method = ucfirst($k);
        $dd->$method($v) if $dd->can($method);
    }
    return $dd->Dump;
}

# ── Empty hash ────────────────────────────────────────────────────
is(dump_hash({}), "\$VAR1 = {};\n", 'empty hash ref');

# ── Simple hash ───────────────────────────────────────────────────
is(dump_hash({a => 1, b => 2}),
   "\$VAR1 = {\n  'a' => 1,\n  'b' => 2\n};\n",
   'simple hash sorted');

# ── String values ─────────────────────────────────────────────────
is(dump_hash({x => 'hello'}),
   "\$VAR1 = {\n  'x' => 'hello'\n};\n",
   'hash with string value');

# ── Nested hash ───────────────────────────────────────────────────
is(dump_hash({a => {b => 1}}),
   "\$VAR1 = {\n  'a' => {\n    'b' => 1\n  }\n};\n",
   'nested hash');

# ── Hash with array value ────────────────────────────────────────
is(dump_hash({a => [1, 2]}),
   "\$VAR1 = {\n  'a' => [\n    1,\n    2\n  ]\n};\n",
   'hash with array value');

# ── Hash with undef value ────────────────────────────────────────
is(dump_hash({a => undef}),
   "\$VAR1 = {\n  'a' => undef\n};\n",
   'hash with undef value');

done_testing;
