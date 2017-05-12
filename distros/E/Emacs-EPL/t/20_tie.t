# -*-perl-*-

BEGIN { $| = 1; $^W = 1 }
use Emacs::Lisp;
use Emacs::Lisp qw ($foo %bar);

@tests =
    (
     sub {
       &set (\*foo, 3);
       $foo == 3;
     },

     sub {
       import Emacs::Lisp '$foo';  # test double import
       $foo = 5;
       &eq (&symbol_value(\*foo), 5);
     },

     sub {
       &put (\*bar, \*baz, 78);
       $bar{\*baz} == 78;
     },

     sub {
       import Emacs::Lisp '%bar';  # test double import
       $bar{\*baz} = 156;
       &get (\*bar, \*baz) == 156;
     },

     sub {
       $bar{\*heh} = 15;
       my (@k) = (values %bar);
       @k == 2 && $k[0] + $k[1] == 171;
     },

     sub {
       exists $bar{\*baz};
     },

     sub {
       delete $bar{\*baz};
       not exists ($bar{\*baz});
     },

     sub {
       %bar = (\*heh, 45);
       &equal (&symbol_plist (\*bar), [\*heh, 45]);
     },
    );

print "1..".@tests."\n";
$test_number = 1;
for my $test (@tests) {
  print (&$test() ? "ok $test_number\n" : "not ok $test_number\n");
  $test_number ++;
}
END { &garbage_collect; }
