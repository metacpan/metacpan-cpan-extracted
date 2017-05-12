# -*-perl-*-
# Tests for behavior after nonlocal jumps.

BEGIN { $| = 1; $^W = 1 }
use Emacs::Lisp;

# Avoid warning "used only once":
*arith_error = *arith_error;

## This sort of thing apparently does not work under Perl.
#sub x::DESTROY { &error ("1234") }
#       sub {
#	 my ($x, $y);
#	 $x = bless \$y, 'x';
#	 eval { undef $x };
#	 ($@ =~ /^1234/, $@);
#       },

@tests =
    (
     sub {
	 eval { &error ("314159") };
	 ($@ =~ /^314159/, $@);
     },
    sub {
	eval q(&error ("26535"));
	($@ =~ /^26535/, $@);
    },
    sub {
	eval { &perl_eval (q(die 89793)) };
	($@ =~ /^89793 at /, $@);
    },
    sub {
	eval { &perl_eval (q(&perl_eval (q(die 83279)))) };
	($@ =~ /^83279 at /, $@);
    },
    sub {
	eval { &perl_eval (q(&perl_eval (q(&error ("50288"))))) };
	($@ =~ /^50288/, $@);
    },
    sub {
	use Emacs::Lisp qw($err $x);
	sub signalbla { &signal (\*arith_error, [26, 4, 33]) }
	# note: the following performs two deep copies.
	&eval (&read (q((condition-case var
			 (progn (setq x 8)
			  (perl-call "::signalbla")
			  (setq x 3))
			 (arith-error (setq err (cdr var)))))));
	$x == 8 && "@$err" eq "26 4 33";
    },
    sub {
	eval { &perl_call (sub { die 23846 }) };
	($@ =~ /^23846 at /, $@);
    },
    sub {
	eval { &perl_call (sub { &error ("41971") }) };
	return ($@ =~ /^41971/, $@);

	# FIXME: This works too. weird.
	# $@ appears empty, but the test still passes!
	return ($@ =~ /^419df71/, $@);
    },
    sub {
	69399 == catch \*arith_error, sub {
	    &throw (\*arith_error, 69399);
	};
    },
    sub {
	37510 == catch \*arith_error, sub {
	    &perl_eval (q(&throw (\*arith_error, 37510)));
	};
    },
    sub {
	eval { &perl_eval ("goto L;") };
	return (0, $@);
      L:
	return (1, $@);
    },
    sub {
	local $x = 0;  # btw, $x is tied from above.
	# Cover up "Exiting (eval|subroutine) via last" because that
	# is just the kind of shenanigans we are testing for.
	local $^W = 0;
	eval {
	    # The label is necessary, because otherwise Perl thinks
	    # "last" refers to the message loop.  Or something.
	  F:
	    for (1..10) {
		&perl_eval (q($x = $_; last F if $_>5));
	    }
	};
	($x == 6 && $@ =~ /last/, "$x $@");
    },

    # More tests needed:
    # - die from within condition-case handler
    # - throw/signal from within $SIG{__DIE__}
    # - throw/signal from within FETCH, DESTROY, sort, etc.
    # - uncaught errors (in a subprocess)
    # - during global destruction
    # - variations on existing tests
    );

print "1..".(@tests+2)."\n";
$test_number = 1;
sub report {
    my ($ok, $comment) = @_;
    print (($ok ? "" : "not "), "ok $test_number");
    if (defined $comment) {
	$comment =~ s/\s+/ /g;
	print " # $comment\n";
	} else {
	    print "\n";
	}
    $test_number ++;
}
for my $test (@tests) {
    report &$test();
}

END {
    &garbage_collect;
    # This fails with Perl 5.005 due to EPL.pm thinking the argument to
    # error() should be a Lisp integer.  Changing it to something with
    # non-digits removes the error, but I like to keep it here to remind
    # me of what has to be fixed for 5.005.
    eval { &error ("58209") };
    report ($@ =~ /^58209/ ? 1 : 0, $@);
    &garbage_collect;
    eval {&perl_destruct};

    # FIXME:  Weird.  This works too, but $@ is reported as empty
    #report (($@ =~ /xxxparent/), $@);
    #report (($@ =~ /parent/), $@);
    my $x = $@ =~ m/parent/;
    report ($x, $@);
    &garbage_collect;
    $? = 0;
}
