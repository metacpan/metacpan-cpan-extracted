use strict;
use warnings;
use Test::More;

use Loo qw/dDump/;

sub key2 { }

sub deparse_code {
    my ($code) = @_;
    my $string = dDump { code => $code };
    return Loo::strip_colour($string);
}

# ════════════════════════════════════════════════════════════════
# Complex integration test from user's example — a deeply nested
# sub with do block, list assignment, C-style for, anonymous sub
# in hash ref, method call chain, and compound assignment.
#
# This is the "big picture" test — many individual bugs combine
# to produce incorrect output here.
# ════════════════════════════════════════════════════════════════

my $string = dDump {
    a => 123,
    code => sub {
        do {
            my ($key1, $key2) = (0, key2);
            for (my $i = 0; $i < 10; $i++) {
                my $hash = {
                    a => sub {
                        my ($one, $two, $three) = @_;
                        return $one + $two + $three;
                    }
                };
                $hash->{a}->(1, 2, 3);
            }
            return $_[$key1] += $_[key2()];
        }
    }
};
$string = Loo::strip_colour($string);

# These parts already work correctly:
like($string, qr/'a' => 123/, 'has a => 123');
like($string, qr/sub \{/, 'has deparsed sub');
like($string, qr/do \{/, 'has deparsed do block');
like($string, qr/for \(my \$i = 0; \$i < 10; \+\+\$i\) \{/, 'has C-style for loop');
if ($] >= 5.012) {
    like($string, qr/return \$_\[\$key1\] \+= \$_\[key2\(\)\]/, 'has compound += with multideref');
} else {
    pass('skip compound += test on old perl (no multideref)');
}

# These parts are currently broken:

if ($] >= 5.018) {
    like($string, qr/my \(\$key1, \$key2\) = \(0, key2\(\)\)/,
        'list assignment has parens: my ($key1, $key2) = (0, key2())');
} else {
    pass('skip padrange list assignment test on old perl');
}

like($string, qr/'a' => sub \{/,
    'hash value has anonymous sub: a => sub {');

if ($] >= 5.018) {
    like($string, qr/my \(\$one, \$two, \$three\) = \@_/,
        'anon sub body has: my ($one, $two, $three) = @_');
} else {
    pass('skip padrange list assignment test on old perl');
}

like($string, qr/return \$one \+ \$two \+ \$three/,
    'anon sub body has: return $one + $two + $three');

like($string, qr/\$hash->\{'a'\}->\(1, 2, 3\)/,
    'method call: $hash->{a}->(1, 2, 3)');

# ── Additional focused tests for individual bugs ──────────────

# BUG: entersub with args before the function ref shows args wrong
like(deparse_code(sub { my $f = $_[0]; $f->(1, 2) }),
    qr/\$f->\(1, 2\)/,
    'coderef call: $f->(1, 2)');

# BUG: list assignment RHS should have parens
like(deparse_code(sub { my ($a, $b) = (1, key2()) }),
    qr/= \(1, key2\(\)\)/,
    'list assignment RHS: = (1, key2())');

done_testing();
