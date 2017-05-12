use Test;
BEGIN { plan tests => 7 }

use Guile;

# create a pair
my $pair = new Guile::SCM pair => [ 1, 2 ];
ok($pair and Guile::car($pair) == 1 and Guile::cdr($pair) == 2);

# create a list
my $list = new Guile::SCM list => [ 1, 2, 3 ];
ok($list and Guile::car($list) == 1);

# test array ref interface
ok($list->[2] == 3);

ok(Guile::cadr([2,4,8]) == 4);

# create a list of pairs
my $pair2 = new Guile::SCM list => [ $pair, $pair ];
ok($pair2 and 
   Guile::caar($pair2) == 1 and
   Guile::cdar($pair2) == 2 and
   Guile::caadr($pair2) == 1 and
   Guile::cdadr($pair2) == 2);
   
# fun with alists
my $alist = Guile::SCM->new([ Guile::SCM->new(pair => [ foo => 1 ]),
                              Guile::SCM->new(pair => [ bar => 2 ]) ]);
ok($alist->[0][1] == 1 and $alist->[1][1] == 2);

# test we can arrayify a list without trying to SVify the contents
my $list2 = Guile::eval_str("
  (catch 'postback
    (lambda ()
      (+ 1 (call-with-current-continuation
        (lambda (kont)
          (throw 'postback kont)))))
    (lambda (key kont)
      (list 3 kont)))");

my $lambda = Guile::eval_str("(lambda (k i) (k i))");

my $contreturn = Guile::apply($lambda, [ $list2->[1], 2 ]);

ok($list2->[0] == 3 and $contreturn == 3);
