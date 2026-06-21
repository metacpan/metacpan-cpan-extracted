#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

# Optional chaining / safe navigation `?->` implemented as a custom infix
# operator with a BAREWORD method name on the right (method => 1). `LHS ?-> meth`
# yields undef when LHS is undef, otherwise calls $LHS->meth. Being a
# left-associative operator it chains and short-circuits at the first undef --
# under `use strict`, with no quotes -- just like a built-in `?->` would.

BEGIN {
    plan skip_all => "custom infix operators require perl 5.38+ (have $])"
        unless "$]" >= 5.038;
}

plan tests => 9;

# The whole operator: one small sub, plus method => 1 so the RHS is read as a
# bareword method name rather than parsed as an operand (which strict would
# reject) -- the parse stage captures the identifier instead.
sub safe_nav {
    my ($obj, $method) = @_;
    return undef unless defined $obj;
    return $obj->$method;
}

use Infix::Custom op => '?->', call => \&safe_nav, method => 1, prec => 'mul';

{
    package Node;
    sub new   { my ($c, %a) = @_; bless { %a }, $c }
    sub name  { $_[0]{name} }
    sub child { $_[0]{child} }
}

my $tree = Node->new(
    name  => 'root',
    child => Node->new(name => 'kid'),     # kid has no child
);

# --- bareword method name, under strict, no quotes -------------------------
is($tree ?-> name, 'root', 'bareword method name dispatches');

# --- short-circuit on undef (no "method on undef" crash) -------------------
my $nobody;
is($nobody ?-> name, undef, 'undef invocant short-circuits to undef');

# --- chaining barewords left-to-right --------------------------------------
is($tree ?-> child ?-> name, 'kid', 'chains barewords through children');

# --- mid-chain undef short-circuits the rest -------------------------------
is($tree?->child?->child?-> name, undef,
    'an undef partway along the chain short-circuits the whole tail');

# --- the idiomatic "optional chain or default" -----------------------------
is($nobody ?-> name // 'default', 'default', '?-> meth // default works');
is($tree ?-> child ?-> name // 'default', 'kid', 'default not used when present');

# --- precedence: `?->` binds tighter than a lower-precedence operator ------
my $p = 0 || $tree ?-> name;
is($p, 'root', '?-> binds tighter than ||');

# --- does not disturb the real ternary operator ----------------------------
my $tern = 1 ? 'yes' : 'no';
is($tern, 'yes', 'plain ternary ?: is unaffected');

# --- still strict about real method errors ---------------------------------
my $died = !eval { $tree ?-> no_such_method; 1 };
ok($died, 'an unknown method still dies (typos are not silently swallowed)');
