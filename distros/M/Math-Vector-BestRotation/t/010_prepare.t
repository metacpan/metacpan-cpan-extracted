#!perl -T

use strict;
use warnings;

use Test::More tests => 120;

BEGIN {
    use_ok('Math::Vector::BestRotation');
    eval "use Test::Exception";
}

sub clear {
    my $rot      = Math::Vector::BestRotation->new;
    my $matrix_r = $rot->matrix_r;
    my $ref;

    can_ok($rot, 'clear', 'add_pair');
    isa_ok($matrix_r, 'Math::MatrixReal');
    for(my $i=0;$i<3;$i++) {
	for(my $j=0;$j<3;$j++) {
	    is($matrix_r->element($i+1, $j+1), 0, 'matrix_r init');
	}
    }
    $rot->add_pair([3, 4, 1], [2, -2, 1]);
    $matrix_r = $rot->matrix_r;
    isa_ok($matrix_r, 'Math::MatrixReal');
    for(my $i=0;$i<3;$i++) {
	for(my $j=0;$j<3;$j++) {
	    isnt($matrix_r->element($i+1, $j+1), 0,
		 'matrix_r non-zero');
	}
    }
    $rot->clear;
    $matrix_r = $rot->matrix_r;
    isa_ok($matrix_r, 'Math::MatrixReal');
    for(my $i=0;$i<3;$i++) {
	for(my $j=0;$j<3;$j++) {
	    is($matrix_r->element($i+1, $j+1), 0, 'matrix_r cleared');
	}
    }
}

sub add_pair {
    my $rot      = Math::Vector::BestRotation->new;
    my $matrix_r = $rot->matrix_r;
    my $ref;

    can_ok($rot, 'add_pair');
    for(my $i=0;$i<3;$i++) {
	for(my $j=0;$j<3;$j++) {
	    is($matrix_r->element($i+1, $j+1), 0, 'matrix_r init');
	}
    }
    $rot->add_pair([3, 4, 1], [2, -2, 1]);
    $ref = Math::MatrixReal->new_from_string(<<'    MATRIX');
        [   6   8   2  ]
	[  -6  -8  -2  ]
	[   3   4   1  ]
    MATRIX
    $matrix_r = $rot->matrix_r;
    for(my $i=0;$i<3;$i++) {
	for(my $j=0;$j<3;$j++) {
	    is($matrix_r->element($i+1, $j+1),
	       $ref->element($i+1, $j+1),
	       , 'matrix_r one pair');
	}
    }
    $rot->add_pair([2, -1, 5], [6, 3, 0]);
    $ref = Math::MatrixReal->new_from_string(<<'    MATRIX');
        [  18   2  32  ]
	[   0 -11  13  ]
	[   3   4   1  ]
    MATRIX
    $matrix_r = $rot->matrix_r;
    for(my $i=0;$i<3;$i++) {
	for(my $j=0;$j<3;$j++) {
	    is($matrix_r->element($i+1, $j+1),
	       $ref->element($i+1, $j+1),
	       , 'matrix_r two pairs');
	}
    }

    $rot->clear;
    $rot->add_pair([1, 0, 0], [0, 1, 0]);
    $rot->add_pair([0, 1, 0], [-1, 0, 0]);
    $ref = Math::MatrixReal->new_from_string(<<'    MATRIX');
        [  0 -1  0 ]
	[  1  0  0 ]
	[  0  0  0 ]
    MATRIX
    $matrix_r = $rot->matrix_r;
    for(my $i=0;$i<3;$i++) {
	for(my $j=0;$j<3;$j++) {
	    is($matrix_r->element($i+1, $j+1),
	       $ref->element($i+1, $j+1),
	       , 'matrix_r simple');
	}
    }

    $rot->clear;
    $rot->add_pair([0, 1, 0], [0, 0, -1]);
    $rot->add_pair([0, 0, 1], [0, 1, 0]);
    $ref = Math::MatrixReal->new_from_string(<<'    MATRIX');
        [  0  0  0 ]
	[  0  0  1 ]
	[  0 -1  0 ]
    MATRIX
    $matrix_r = $rot->matrix_r;
    for(my $i=0;$i<3;$i++) {
	for(my $j=0;$j<3;$j++) {
	    is($matrix_r->element($i+1, $j+1),
	       $ref->element($i+1, $j+1),
	       , 'matrix_r simple');
	}
    }
}

sub add_many_pairs {
    my $rot      = Math::Vector::BestRotation->new;
    my $matrix_r = $rot->matrix_r;
    my $ref;

    can_ok($rot, 'add_many_pairs');
    for(my $i=0;$i<3;$i++) {
	for(my $j=0;$j<3;$j++) {
	    is($matrix_r->element($i+1, $j+1), 0, 'matrix_r init');
	}
    }
    $rot->add_many_pairs([[3, 4, 1]], [[2, -2, 1]]);
    $ref = Math::MatrixReal->new_from_string(<<'    MATRIX');
        [   6   8   2  ]
	[  -6  -8  -2  ]
	[   3   4   1  ]
    MATRIX
    $matrix_r = $rot->matrix_r;
    for(my $i=0;$i<3;$i++) {
	for(my $j=0;$j<3;$j++) {
	    is($matrix_r->element($i+1, $j+1),
	       $ref->element($i+1, $j+1),
	       , 'matrix_r one pair');
	}
    }

    $rot->clear;
    $rot->add_many_pairs([[3, 4, 1], [2, -1, 5]],
			 [[2, -2, 1], [6, 3, 0]]);
    $ref = Math::MatrixReal->new_from_string(<<'    MATRIX');
        [  18   2  32  ]
	[   0 -11  13  ]
	[   3   4   1  ]
    MATRIX
    $matrix_r = $rot->matrix_r;
    for(my $i=0;$i<3;$i++) {
	for(my $j=0;$j<3;$j++) {
	    is($matrix_r->element($i+1, $j+1),
	       $ref->element($i+1, $j+1),
	       , 'matrix_r two pairs');
	}
    }

    $rot->clear;
    $rot->add_many_pairs([[0, 1, 0], [0, 0, 1]],
			 [[0, 0, -1], [0, 1, 0]]);
    $ref = Math::MatrixReal->new_from_string(<<'    MATRIX');
        [  0  0  0 ]
	[  0  0  1 ]
	[  0 -1  0 ]
    MATRIX
    $matrix_r = $rot->matrix_r;
    for(my $i=0;$i<3;$i++) {
	for(my $j=0;$j<3;$j++) {
	    is($matrix_r->element($i+1, $j+1),
	       $ref->element($i+1, $j+1),
	       , 'matrix_r simple');
	}
    }
}

sub matrix_u {
    my $rot = Math::Vector::BestRotation->new;

    can_ok($rot, 'matrix_u');
    ok(!defined($rot->matrix_u), 'matrix_u undefined');
    $rot->{matrix_u} = 'foo';
    ok(defined($rot->matrix_u), 'matrix_u defined');
    $rot->clear;
    ok(!defined($rot->matrix_u), 'matrix_u undefined');

  SKIP: {
      skip('Test::Exception unavailable', 1)
	  if(!$Test::Exception::VERSION);

      throws_ok(sub { $rot->matrix_u('foo') },
		qr/matrix_u.*readonly/,
		'croak on argument for matrix_u');
    }
}

clear;
add_pair;
add_many_pairs;
matrix_u;
