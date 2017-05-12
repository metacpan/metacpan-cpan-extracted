# -*-cperl-*-

BEGIN { $| = 1; $^W = 1 }
use Emacs::Lisp;

#setq { $epl_debugging = \*stderr };
#$Emacs::EPL::debugging = 'stderr';

@tests =
    (
     sub {
	 setq { $narf = "oblert" };
	 &equal (&symbol_value(\*narf), "oblert");
     },

     sub {
	 setq { for (0..1) { $zab{\*rab} = 'oof' } };
	 &get (\*zab, \*rab) eq 'oof';
     },

     sub {
	 defun (\*funnie, 'doc', &interactive(), sub { $_[0] + $_[1] });
	 &funnie(45,60) == 105;
     },

     sub {
	 $x = 1;
	 save_excursion {
	     &set_buffer (&get_buffer_create ("b1"));
	     save_excursion {
		 &set_buffer (&get_buffer_create ("b2"));
		 $x++ unless &eq (&current_buffer(), &get_buffer("b1"));
	     };
	     $x++ if &eq (&current_buffer(), &get_buffer("b1"));
	 } == 2 && $x == 3;
     },

     sub {
	 $x = 0;
	 unwind_protect (sub { $x = 1; return 4; $x = 5; }, sub { $x++ })
	     == 4 && $x == 2;
     },

     sub {
	 $x = 0;
	 ! defined eval {
	     unwind_protect (sub { $x = 1; die "bla"; $x = 5; }, sub { $x++ })
	 } && $x == 2 && $@ =~ /\bbla\b/;
     },
    );

print "1..".@tests."\n";
$test_number = 1;
for my $test (@tests) {
    print (&$test() ? "ok $test_number\n" : "not ok $test_number\n");
    $test_number ++;
}
END { &garbage_collect; 0; }
