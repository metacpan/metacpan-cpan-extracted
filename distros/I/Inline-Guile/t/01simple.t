use Test;
BEGIN { plan tests => 2 }

use Inline Guile => <<END;
(define doublestuff (lambda (f x) (f x x)))
(define trick "define tricky2")
END

my $twenty = doublestuff(Guile::lookup("+"), 10);
ok($twenty == 20);

my $hundred = doublestuff(Guile::lookup("*"), 10);
ok($hundred == 100);

