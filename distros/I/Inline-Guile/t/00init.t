use Test;
BEGIN { plan tests => 1 }

use Inline Guile;
ok(1);

__END__
__Guile__
(define doublestuff (lambda (f x) (f x x)))
(define adder (lambda (x y) (+ x y)))
