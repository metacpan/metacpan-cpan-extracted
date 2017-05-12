# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use lib qw(t/lib);
use Test::More tests => 19;
BEGIN { use_ok( 'Lingua::Zompist::Kebreni' ) };

#########################

my $word;
my $out;

$word = Lingua::Zompist::Kebreni->new('kanu');

ok(ref $word, '$word is a reference');


# Try each method once

$out = $word->null;
ok(ref $out, 'null gives a reference');
$out = $word->perfective;
ok(ref $out, 'perfective gives a reference');
$out = $word->volitional;
ok(ref $out, 'volitional gives a reference');
$out = $word->make_polite;
ok(ref $out, 'make_polite gives a reference');
# can't test ->polite here as that requires ->make_polite be run first
$out = $word->benefactive;
ok(ref $out, 'benefactive gives a reference');
# can't test ->dir2 as that needs ->benefactive or ->antiben first
$out = $word->antiben;
ok(ref $out, 'antiben gives a reference');
$out = $word->subordinate;
ok(ref $out, 'subordinate gives a reference');
$out = $word->whodoes;
ok(ref $out, 'whodoes gives a reference');
$out = $word->whodoesf;
ok(ref $out, 'whodoesf gives a reference');
$out = $word->participle;
ok(ref $out, 'participle gives a reference');
$out = $word->action;
ok(ref $out, 'action gives a reference');

# Now test combinations of methods.

# First off, make_polite->polite and (benefactive|antiben)->dir2
$out = $word->make_polite->polite;
ok(ref $out, 'make_polite->polite gives a reference');
$out = $word->benefactive->dir2;
ok(ref $out, 'benefactive->dir2 gives a reference');
$out = $word->antiben->dir2;
ok(ref $out, 'antiben->dir2 gives a reference');

# Test an exact result
$out = $word->null;
ok($out eq 'kanu', 'word is kanu - eq');
is($out, 'kanu', 'word is kanu');

# Test 'base'
$out = $word->benefactive;
is($out->base, 'kanu', 'base of output is kanu');

