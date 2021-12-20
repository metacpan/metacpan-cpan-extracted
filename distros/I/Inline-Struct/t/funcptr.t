use strict;
use warnings;
use Test::More;

use Inline C => Config => force_build => 1;
use Inline C => 'DATA', structs => [qw(aaa_t bbb_t)];

my $aaa = Inline::Struct::aaa_t->new;
setptr($aaa);
is callptr($aaa, "YO"), "YO", 'call to struct typedef-ed func ptr works';

my $bbb = Inline::Struct::bbb_t->new;
setptr2($bbb);
is callptr2($bbb, "YO"), "YO", 'call to struct raw func ptr works';

done_testing;

__DATA__
__C__

typedef char *(*funcptr_t)(char *z);

char *returnstr(char *z) {
  return z;
}

typedef struct {
  int a;
  funcptr_t fp;
} aaa_t;

void setptr(aaa_t *v1) {
  v1->fp = returnstr;
}

char *callptr(aaa_t *v1, char *s) {
  return v1->fp(s);
}

typedef struct {
  int a;
//  funcptr_t fp;
  char *(*fp)(char *z);
} bbb_t;

void setptr2(bbb_t *v1) {
  v1->fp = returnstr;
}

char *callptr2(bbb_t *v1, char *s) {
  return v1->fp(s);
}
