use Test::More tests => 17;
use Devel::Profiler::Test qw(profile_code check_tree get_times);

# make sure the module works
profile_code(<<END, "profile basic code");
sub bar { 1; }
sub foo { bar(); }
foo();
END

# make sure the call tree looks right
check_tree(<<END, "checking tree");
main::foo
   main::bar
END

# test some repeated calls
profile_code(<<END, "profile repeated calls");
sub bar { 1; }
sub foo { bar() for (1 .. 10) }
foo();
END

check_tree(<<END, "checking tree");
main::foo
   main::bar
   main::bar
   main::bar
   main::bar
   main::bar
   main::bar
   main::bar
   main::bar
   main::bar
   main::bar
END

# test a deep call tree
profile_code(<<'END', "profile deep calls");
sub bar { my $x = shift; $x-- and foo($x); }
sub foo { my $x = shift; $x-- and bar($x); }
foo(20);
END

check_tree(<<END, "checking deep call tree");
main::foo
   main::bar
      main::foo
         main::bar
            main::foo
               main::bar
                  main::foo
                     main::bar
                        main::foo
                           main::bar
                              main::foo
                                 main::bar
                                    main::foo
                                       main::bar
                                          main::foo
                                             main::bar
                                                main::foo
                                                   main::bar
                                                      main::foo
                                                         main::bar
                                                            main::foo
END

# test code that uses some time
profile_code(<<'END', "profile calls that take some time");
sub long { sleep 1; }
long()  for (0 .. 3);
END

check_tree(<<END, "check call tree");
main::long
main::long
main::long
main::long
END

# make sure that regsitered at least 3 real seconds of runtime
($real, $sys, $user) = get_times();
ok($real >= 3, "check real time >= 3 seconds");

# test code that does some real processing
profile_code(<<'END', "profile calls that uses the CPU");
sub cpu { my $start = time; while (time <= ($start + 2)) { $_++ } }
cpu();
END

check_tree(<<END, "check call tree");
main::cpu
END

# make sure that regsitered at least 1 seconds of runtime
($real, $sys, $user) = get_times();
ok($real >= 1, "check real time >= 1 seconds");

# make sure that regsitered at least 1 second of user time
($real, $sys, $user) = get_times();
ok($user >= 1, "check user time >= 1 seconds");

# taken from Devel::DProf's tests - tests various uses of @_
profile_code(<<'END', 'check safe handling of @_');
sub foo1 {
	bar(@_);
}
sub foo2 {
	&bar;
}
sub bar {
	if( @_ > 0 ){
		&yeppers;
	}
}
sub yeppers { @_ }       

&foo1( A );
&foo2( B );
END


check_tree(<<END, "check tree");
main::foo1
   main::bar
      main::yeppers
main::foo2
   main::bar
      main::yeppers
END


# taken from Devel::DProf's tests
profile_code(<<'END', 'check die handling');
sub foo {
	my $x;
	my $y;
	for( $x = 1; $x < 100; ++$x ){
		bar();
		for( $y = 1; $y < 100; ++$y ){
		}
	}
}

sub bar {
	my $x;
	for( $x = 1; $x < 100; ++$x ){
	}
	die "bar exiting";
}

sub baz {
	eval { bar(); };
	eval { foo(); };
}

eval { bar(); };
baz();
eval { foo(); };
END

check_tree(<<END, "check tree");
main::bar
main::baz
   main::bar
   main::foo
      main::bar
main::foo
   main::bar
END


