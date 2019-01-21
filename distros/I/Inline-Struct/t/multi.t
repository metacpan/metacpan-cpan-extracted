use strict;
use warnings;
use Test::More;

use Inline C => Config => force_build => 1;
use Inline C => 'DATA', structs => ['aaa_t','bbb_t'];

my $aaa = Inline::Struct::aaa_t->new;
my $bbb = Inline::Struct::bbb_t->new;

$aaa->b(1.0);
$bbb->b(2.0);
isnt $aaa->b, $bbb->b, 'before mutation different';

foo($aaa, $bbb);
is $aaa->b, $bbb->b, 'after mutation same';

done_testing;

__DATA__
__C__

struct aaa_t {
   int a;
   double b;
};

typedef struct aaa_t aaa_t;

struct bbb_t {
    float b;
    float c;
};

typedef struct bbb_t bbb_t;

void foo(aaa_t *v1, bbb_t *v2) {
    v2->b = v1->b;
};
