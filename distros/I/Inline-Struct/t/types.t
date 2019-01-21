use strict;
use warnings;
use Test::More;

use Inline C => Config => force_build => 1;
use Inline C => 'DATA', structs => ['aaa_t','bbb_t'];

my $aaa = Inline::Struct::aaa_t->new;
my $bbb = Inline::Struct::bbb_t->new;

$aaa->b(-2);
foo($aaa, $bbb);
is $bbb->b, 2, 'after mutation right';

$aaa->b(3);
foo($aaa, $bbb);
is $bbb->b, 3, 'after mutation right';

done_testing;

__DATA__
__C__

struct aaa_t {
   int a;
   int b;
};

typedef struct aaa_t aaa_t;

struct bbb_t {
   unsigned int a;
   int b;
};

typedef struct bbb_t bbb_t;

void foo(aaa_t *a, bbb_t *b) {
    b->b = a->b < 0 ? - a->b : a->b;
}
