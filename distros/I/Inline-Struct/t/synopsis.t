use Test::More;

use Inline C => 'DATA', structs => ['Foo'], force_build => 1;

my $obj = Inline::Struct::Foo->new;
$obj->num(10);
$obj->str("Hello");

is myfunc($obj), q{myfunc: num=10, str='Hello'};

done_testing;

__END__
__C__
struct Foo {
  int num;
  char *str;
};
typedef struct Foo Foo;

SV *myfunc(Foo *f) {
  return newSVpvf("myfunc: num=%i, str='%s'", f->num, f->str);
}
