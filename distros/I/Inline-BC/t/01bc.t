# Need to suppress warinings ?
BEGIN { $^W = 0; $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use Inline BC;
$loaded = 1;
print "ok 1\n";
print x(4) == 5.3 ? "ok 2\n" : "not ok 2\n";
use Inline BC => <<'END_BC';
define z (a, b) {
  scale = 6
  t = a * .357;
  t = b / t;
  return ( t );
}
END_BC
print z(4, 7) > 4 ? "ok 3\n" : "not ok 3\n";
use Inline BC => './tools/test.dat';
print aa() =~ /[0\n]/s ? "ok 4\n" : "not ok 4\n";
print mye(12) eq "3E9E441.232817A615846A5782D6FAA94DE\n"  ? "ok 5\n" : "not ok 5\n";


__DATA__

__BC__


define x (a) {
  scale = 20
  return (a * 1.5);
}


/* Uses the fact that e^x = (e^(x/2))^2
   When x is small enough, we use the series:
   e^x = 1 + x + x^2/2! + x^3/3! + ...
*/

define mye(x) {
  auto  a, d, e, f, i, m, v, z

  scale = 20

  /* Check the sign of x. */
  if (x<0) {
    m = 1
      x = -x
  }

  /* Precondition x. */
  z = scale;
  scale = 4 + z + .44*x;
  while (x > 1) {
    f += 1;
    x /= 2;
  }

  /* Initialize the variables. */
  v = 1+x
  a = x
  d = 1

  for (i=2; 1; i++) {
    e = (a *= x) / (d *= i)
    if (e == 0) {
      if (f>0) while (f--)  v = v*v;
      scale = z
      if (m) return (1/v);
         return (v/1);
    }
    v += e
  }
}

