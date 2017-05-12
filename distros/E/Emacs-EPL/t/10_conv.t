# -*-cperl-*-

BEGIN { $| = 1; $^W = 1 }
use Emacs::Lisp;

# Avoid warning "used only once":
*string = *string;
*float = *float;
*perl_scalar = *perl_scalar;
*cons = *cons;
*perl_array = *perl_array;

@tests =
    (
     sub { &eq (1, 1) },
     sub { ! &eq (1, "1") },
     sub { &eq (&intern("integer"), \*integer) },
     sub { &eq (&type_of (1), \*integer) },
     sub { &eq (&type_of ("1"), \*string) },
     sub { &eq (&type_of (1.0), \*float) },
     sub { &type_of ([1]) eq \*cons },

     sub {
	 my $x = &cdr ([1, 2, 3]);
	 $#$x == 1 && $x->[0] == 2 && $x->[1] == 3;
     },
     sub { "@{Emacs::Lisp->can('list')->(5,2)}" eq "5 2" },
     sub { "@{Emacs::Lisp::Object->can('list')->(3,4)->to_perl}" eq "3 4" },
     sub { &aref (\ [8, 7, 6], 2) == 6 },
     sub { $#${&make_vector (5, undef)} == 4 },
     sub { &copy_sequence ("d'oh") eq "d'oh" },
    );

print "1..".@tests."\n";
$test_number = 1;
for my $test (@tests) {
  print (&$test() ? "ok $test_number\n" : "not ok $test_number\n");
  $test_number ++;
}
END { &garbage_collect; }
