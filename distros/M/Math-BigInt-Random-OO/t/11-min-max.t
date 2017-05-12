#!/usr/bin/perl
#
# Author:      Peter J. Acklam
# Time-stamp:  2010-02-19 16:19:16 +01:00
# E-mail:      pjacklam@cpan.org
# URL:	       http://home.online.no/~pjacklam

########################

use 5.008;		# required version of Perl
use strict;		# restrict unsafe constructs
use warnings;		# control optional warnings
use utf8;		# enable UTF-8 in source code

########################

local $| = 1;                   # disable buffering

#BEGIN {
#    chdir 't' if -d 't';
#    unshift @INC, '../lib';	 # for running manually
#}

use Math::BigInt::Random::OO;

use Math::BigInt;
use Math::BigFloat;

# Values for the 'min' and 'max' parameters to the 'new' method.

my @minmax =
  (
   [  0,  0 ],

   [  0,  1 ],
   [  1,  2 ],
   [  0,  2 ],
   [ -1,  2 ],

   [ -1,  0 ],
   [ -2, -1 ],
   [ -2,  0 ],
   [ -2,  1 ],

   [ Math::BigInt   -> new(-2), Math::BigInt   -> new(5) ],
   [ Math::BigFloat -> new(-2), Math::BigFloat -> new(5) ],

   [ Math::BigInt   -> new("-2e20"), Math::BigInt   -> new("5e20") ],
   [ Math::BigFloat -> new("-2e20"), Math::BigFloat -> new("5e20") ],

  );

# Arguments to the 'generate' method.

my @genargs = ([ ],
	       [1],
	       [2],
	       [3],
	     );

# Output context.

my @context = ('scalar',
	       'list',
	       'void',
	      );

my $ntests = @minmax * @genargs * @context;

my $class = 'Math::BigInt::Random::OO';

print "1..156\n";

my $testno = 0;

for (my $i = 0 ; $i <= $#minmax ; ++ $i) {
    for (my $j = 0 ; $j <= $#genargs ; ++ $j) {
	for (my $k = 0 ; $k <= $#context ; ++ $k) {

	    ++ $testno;

	    # Arguments to new().

	    my $min = $minmax[$i][0];
	    my $max = $minmax[$i][1];

	    # Arguments to generate().

	    my $genargs = $genargs[$j];

	    # Output context.

	    my $context = $context[$k];

	    # Build a string with the test.

	    my $test = '';
	    $test .= $context eq 'scalar' ? '$x = ' :	# scalar
		     $context eq 'list'	  ? '@x = ' :	# list
					    '';		# void
	    $test .= "$class -> new(min => ";
	    $test .= ref($min) ? ref($min) . qq| -> new("$min")| : $min;
	    $test .= ", max => ";
	    $test .= ref($max) ? ref($max) . qq| -> new("$max")| : $max;
	    $test .= ") -> generate(@$genargs)";

	    # Construct the generator.

	    my $gen = $class -> new(min => $min,
				    max => $max,
				   );

	    # Generate the random numbers.

	    my @out = ();
	    my $n_out_expected;

	    if ($context eq 'scalar') {
		my $x = $gen -> generate(@$genargs);
		@out = $x;
		$n_out_expected = 1;
	    } elsif ($context eq 'list') {
		@out = $gen -> generate(@$genargs);
		$n_out_expected = @$genargs ? $genargs->[0] : 1;
	    } elsif ($context eq 'void') {
		$gen -> generate(@$genargs);
		$n_out_expected = 0;
	    }

	    # Check the number of output arguments.

	    unless (@out == $n_out_expected) {
		print "not ok ", $testno, " - $test\n";
		print "	 wrong number of output arguments\n";
		print "	 actual number .....: ", scalar(@out), "\n";
		print "	 expected number ...: $n_out_expected\n";
		next;
	    }

	    # Check each output argument.

	    for my $x (@out) {

		unless (defined $x) {
		    print "not ok ", $testno, " - $test\n";
		    print "  output was undefined\n";
		    next;
		}

		my $refx = ref $x;
		unless ($refx eq 'Math::BigInt') {
		    print "not ok ", $testno, " - $test\n";
		    print "  output was a ", $refx ? $refx : "Perl scalar", " not a Math::BigInt\n";
		    next;
		}

		unless ($x >= $min) {
		    print "not ok ", $testno, " - $test\n";
		    print "  output was smaller than the minimum value\n";
		    print "  minimum ......: $min\n";
		    print "  output .......: $x\n";
		    next;
		}

		unless ($x <= $max) {
		    print "not ok ", $testno, " - $test\n";
		    print "  output was larger than the maximum value\n";
		    print "  maximum ......: $max\n";
		    print "  output .......: $x\n";
		    next;
		}
	    }

	    print "ok ", $testno, " - $test\n";
	}
    }
}

# Emacs Local Variables:
# Emacs coding: utf-8-unix
# Emacs mode: perl
# Emacs End:
