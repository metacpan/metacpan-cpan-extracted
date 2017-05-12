use Test::More;

use Inline C => 'DATA', structs => ['JA_H'], force_build => 1;

my $o = Inline::Struct::JA_H->new("Perl");
is JAxH($o), 'Just Another Perl Hacker', "call 1";
$o->x("Inline");
is JAxH($o), 'Just Another Inline Hacker', "call 2";

done_testing;

__END__
__C__
struct JA_H {
  char *x;
};
typedef struct JA_H JA_H;

SV *JAxH(JA_H *f) {
  return newSVpvf("Just Another %s Hacker", f->x);
}
