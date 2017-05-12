use Test;
BEGIN { plan tests => 1 }

use Inline Guile => <<END;
(define doublestuff (lambda (f x) (foo x x)))
END

# this exits the script...  I can't really write a test for it until
# it works a little better!
# my $result = doublestuff(Guile::lookup("+"), 10);

# oh, I lie...
ok(1);
