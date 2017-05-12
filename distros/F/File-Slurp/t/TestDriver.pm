# driver.pm - common test driver code

use Test::More ;

BEGIN {
	*CORE::GLOBAL::syswrite =
	sub($$$;$) { my( $h, $b, $s, $o ) = @_; CORE::syswrite $h, $b, $s, $o} ;
#	sub(*\$$;$) { my( $h, $b, $s, $o ) = @_; CORE::syswrite $h, $b, $s, $o } ;

	*CORE::GLOBAL::sysread =
	sub($$$;$) { my( $h, $b, $s, $o ) = @_; CORE::sysread $h, $b, $s, $o } ;
#	sub(*\$$;$) { my( $h, $b, $s, $o ) = @_; CORE::sysread $h, $b, $s, $o } ;

	*CORE::GLOBAL::rename =
	sub($$) { my( $old, $new ) = @_; CORE::rename $old, $new } ;

	*CORE::GLOBAL::sysopen =
	sub($$$;$) { my( $h, $n, $m, $p ) = @_; CORE::sysopen $h, $n, $m, $p } ;
#	sub(*$$;$) { my( $h, $n, $m, $p ) = @_; CORE::sysopen $h, $n, $m, $p } ;
}

sub test_driver {

	my( $tests ) = @_ ;

use Data::Dumper ;

# plan for one expected ok() call per test

	plan( tests => scalar @{$tests} ) ;

# loop over all the tests

	foreach my $test ( @{$tests} ) {

#print Dumper $test ;

		if ( $test->{skip} ) {
			ok( 1, "SKIPPING $test->{name}" ) ;
			next ;
		}

		my $override = $test->{override} ;

# run any setup sub before this test. this can is used to modify the
# object for this test or create test files and data.

		if( my $pretest = $test->{pretest} ) {

			$pretest->($test) ;
		}

		if( my $sub = $test->{sub} ) {

			my $args = $test->{args} ;

			local( $^W ) ;
			local *{"CORE::GLOBAL::$override"} = sub {}
				if $override ;

			$test->{result} = eval { $sub->( @{$args} ) } ;

			if ( $@ ) {

# if we had an error and expected it, we pass this test

				if ( $test->{error} &&
				     $@ =~ /$test->{error}/ ) {

					$test->{ok} = 1 ;
				}
				else {
					print "unexpected error: $@\n" ;
					$test->{ok} = 0 ;
				}
			}
		}

		if( my $posttest = $test->{posttest} ) {

			$posttest->($test) ;
		}

		ok( $test->{ok}, $test->{name} ) if exists $test->{ok} ;
		is( $test->{result}, $test->{expected}, $test->{name} ) if
			exists $test->{expected} ;

	}
}

1 ;
