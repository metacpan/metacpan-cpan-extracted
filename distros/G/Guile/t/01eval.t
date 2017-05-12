use Test;
BEGIN { plan tests => 7 };

use Guile;

# check some simple eval_str results
ok(Guile::eval_str('(car (cons "foo" "bar"))') eq 'foo');
ok(Guile::eval_str("(+ 1 1)") == 2);
ok(Guile::eval_str("'foo") eq "foo");
ok(Guile::eval_str("#t"));
ok(not Guile::eval_str("#f"));
ok(Guile::eval_str('#\a') eq "a");

my $a = Guile::eval_str('"a"');
my $b = Guile::eval_str('"b"');
ok($a . $b eq "ab");
