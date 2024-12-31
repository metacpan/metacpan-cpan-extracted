use strict;
use Math::Symbolic qw/:all/;
use Math::Symbolic::MiscAlgebra qw/:all/;
use Math::Symbolic::Custom::Matrix 0.2;
use Math::Symbolic::Custom::CollectSimplify 0.2;
Math::Symbolic::Custom::CollectSimplify->register();

use Test::Simple 'no_plan';

# test with some problems from various textbooks.
# determinants. Will be tested as part of Math::Symbolic installation but pretty important for matrices so test again
ok( determinant_4B_3a()->value() == 1, "determinant_4B_3a (Pure Mathematics 4 - Problem 4B.3a)" );
ok( determinant_4B_3e()->value() == -9, "determinant_4B_3e (Pure Mathematics 4 - Problem 4B.3e)" );
ok( determinant_4B_3f()->value() == 0, "determinant_4B_3f (Pure Mathematics 4 - Problem 4B.3f)" );
ok( determinant_4B_3g()->value() == 29, "determinant_4B_3g (Pure Mathematics 4 - Problem 4B.3g)" );
ok( determinant_4B_3h()->value() == 2, "determinant_4B_3h (Pure Mathematics 4 - Problem 4B.3h)" );
ok( determinant_LA_p23()->value() == -6930, "determinant_LA_p23 (example page 23 'Linear Algebra', Shen, Wang, Wojdylo, 2019 Mercury)" );

ok( determinant_16_2c()->value() == 0, "determinant_16_2c (Mathematical Methods for Science Students - Problem 16.2c)" );
ok( determinant_16_3()->value(lambda => 2) eq "0", "determinant_16_3 (2) (Mathematical Methods for Science Students - Problem 16.3)" );
ok( determinant_16_3()->value(lambda => 5) eq "0", "determinant_16_3 (5) (Mathematical Methods for Science Students - Problem 16.3)" );
ok( determinant_16_3()->value(lambda => 17) eq "0", "determinant_16_3 (17) (Mathematical Methods for Science Students - Problem 16.3)" );
ok( determinant_16_4()->value(lambda => 0) eq "0", "determinant_16_4 (0) (Mathematical Methods for Science Students - Problem 16.4)" );

ok( sprintf("%.10f", determinant_16_4()->value(lambda => sqrt(2))) == 0, "determinant_16_4 (sqrt(2)) (Mathematical Methods for Science Students - Problem 16.4)" );
ok( sprintf("%.10f", determinant_16_4()->value(lambda => -sqrt(2))) == 0, "determinant_16_4 (-sqrt(2)) (Mathematical Methods for Science Students - Problem 16.4)" );

# constant matrices
my $A_17_1 = make_symbolic_matrix([[2,1,2],[3,5,7],[1,0,1]]);
my $B_17_1 = make_symbolic_matrix([[-3,1,0],[6,2,1],[1,-1,2]]);

ok( is_equals_matrix(add_matrix($A_17_1,$B_17_1),make_symbolic_matrix([[-1,2,2],[9,7,8],[2,-1,3]])), "add_matrix (Mathematical Methods for Science Students - Problem 17.1a)");
ok( is_equals_matrix(sub_matrix($A_17_1,$B_17_1),make_symbolic_matrix([[5,0,2,],[-3,3,6],[0,1,-1]])), "sub_matrix (Mathematical Methods for Science Students - Problem 17.1b)");
ok( is_equals_matrix(sub_matrix($B_17_1,$A_17_1),make_symbolic_matrix([[-5,0,-2],[3,-3,-6],[0,-1,1]])), "sub_matrix (Mathematical Methods for Science Students - Problem 17.1c)");
ok( is_equals_matrix(multiply_matrix($A_17_1,$B_17_1),make_symbolic_matrix([[2,2,5],[28,6,19],[-2,0,2]])), "multiply_matrix (Mathematical Methods for Science Students - Problem 17.1d)");
ok( is_equals_matrix(multiply_matrix($B_17_1,$A_17_1),make_symbolic_matrix([[-3,2,1],[19,16,27],[1,-4,-3]])), "multiply_matrix (Mathematical Methods for Science Students - Problem 17.1e)");
ok( is_equals_matrix(multiply_matrix(make_symbolic_matrix([[1,0,0,0],[1,-1,0,0],[1,-2,1,0],[1,-3,3,-1]]),make_symbolic_matrix([[1,0,0,0],[1,-1,0,0],[1,-2,1,0],[1,-3,3,-1]])),identity_matrix(4)), "multiply_matrix (Mathematical Methods for Science Students - Problem 17.5)");
ok( is_equals_matrix(multiply_matrix(make_symbolic_matrix([[1,2,3],[4,5,6]]),make_symbolic_matrix([[7,8,9,10],[11,12,13,14],[15,16,17,18]])),make_symbolic_matrix([[74,80,86,92],[173,188,203,218]])), "multiply_matrix 1");

# Some constant inverse matrices
ok( is_equals_matrix(invert_matrix(make_symbolic_matrix([[2,5],[-1,4]])), make_symbolic_matrix([['4/13','-5/13'],['1/13','2/13']])), "invert_matrix (Pure Mathematics 4 - Problem 4B.4a)");
ok( is_equals_matrix(invert_matrix(make_symbolic_matrix([[-3,2],[-1,7]])), make_symbolic_matrix([['-7/19','2/19'],['-1/19','3/19']])), "invert_matrix (Pure Mathematics 4 - Problem 4B.4b)");
ok( is_equals_matrix(invert_matrix(make_symbolic_matrix([[2,-3],[1,-4]])), make_symbolic_matrix([['4/5','-3/5'],['1/5','-2/5']])), "invert_matrix (Pure Mathematics 4 - Problem 4B.4c)");
ok( is_equals_matrix(invert_matrix(make_symbolic_matrix([[0,1],[-3,2]])), make_symbolic_matrix([['2/3','-1/3'],['1','0']])), "invert_matrix (Pure Mathematics 4 - Problem 4B.4d)");
ok( is_equals_matrix(invert_matrix(make_symbolic_matrix([[-3,7],[9,22]])), make_symbolic_matrix([['-22/129','7/129'],['9/129','3/129']])), "invert_matrix (Pure Mathematics 4 - Problem 4B.4e)");
ok( is_equals_matrix(invert_matrix(make_symbolic_matrix([[2,1,-5],[1,0,-2],[0,0,3]])), make_symbolic_matrix([['0','1','2/3'],['1','-2','1/3'],['0','0','1/3']])), "invert_matrix (Pure Mathematics 4 - Problem 4B.4f)");
ok( is_equals_matrix(invert_matrix(make_symbolic_matrix([[-1,2,1],[0,0,-2],[1,-5,4]])), make_symbolic_matrix([['-10/6','-13/6','-4/6'],['-2/6','-5/6','-2/6'],['0','-3/6','0']])), "invert_matrix (Pure Mathematics 4 - Problem 4B.4g)");
ok( is_equals_matrix(invert_matrix(make_symbolic_matrix([[-1,2,3],[1,1,2],[5,-1,4]])), make_symbolic_matrix([['-6/12','11/12','-1/12'],['-6/12','19/12','-5/12'],['6/12','-9/12','3/12']])), "invert_matrix (Pure Mathematics 4 - Problem 4B.4h)");
ok( is_equals_matrix(invert_matrix(make_symbolic_matrix([[-2,3,-4],[1,2,-3],[-3,0,-2]])), make_symbolic_matrix([['-4/17','6/17','-1/17'],['11/17','-8/17','-10/17'],['6/17','-9/17','-7/17']])), "invert_matrix (Pure Mathematics 4 - Problem 4B.4i)");
ok( is_equals_matrix(invert_matrix(make_symbolic_matrix([[2,-1,2],[1,-1,1],[2,1,-3]])), make_symbolic_matrix([['2/5','-1/5','1/5'],['1','-10/5','0'],['3/5','-4/5','-1/5']])), "invert_matrix (Pure Mathematics 4 - Problem 4B.4j)");
ok( is_equals_matrix(invert_matrix(make_symbolic_matrix([[3,2,-6],[1,1,-2],[2,2,-1]])), make_symbolic_matrix([['1','-10/3','2/3'],['-1','3','0'],['0','-2/3','1/3']])), "invert_matrix (Pure Mathematics 4 - Problem 4B.4k)");
ok( is_equals_matrix(invert_matrix(make_symbolic_matrix([[4,-5,2],[0,1,-7],[1,1,-2]])), make_symbolic_matrix([['5/53','-8/53','33/53'],['-7/53','-10/53','28/53'],['-1/53','-9/53','4/53']])), "invert_matrix (Pure Mathematics 4 - Problem 4B.4l)");
ok( is_equals_matrix(invert_matrix(make_symbolic_matrix([[3,2,-3],[1,1,-4],[2,2,-6]])), make_symbolic_matrix([['1','3','-5/2'],['-1','-6','9/2'],['0','-1','1/2']])), "invert_matrix (Pure Mathematics 4 - Problem 4B.4m)");
ok( is_equals_matrix(invert_matrix(make_symbolic_matrix([[1,2,3],[1,3,5],[1,5,12]])), make_symbolic_matrix([['11/3','-3','1/3'],['-7/3','3','-2/3'],['2/3','-1','1/3']])), "invert_matrix (Mathematical Methods for Science Students - Ch. 17.3 eq 71)");
ok( is_equals_matrix(invert_matrix(make_symbolic_matrix([[1,4,0],[-1,2,2],[0,0,2]])),make_symbolic_matrix([['1/3','-2/3','2/3'],['1/6','1/6','-1/6'],['0','0','1/2']])), "invert_matrix (Mathematical Methods for Science Students - Problem 17.7)");
ok( is_equals_matrix(invert_matrix(make_symbolic_matrix([[1,2,3,4],[0,1,2,3],[0,0,1,2],[0,0,0,1]])),make_symbolic_matrix([[1,-2,1,0],[0,1,-2,1],[0,0,1,-2],[0,0,0,1]])), "invert_matrix (Mathematical Methods for Science Students - Problem 17.8)");

# multiplying a matrix by its inverse should result in the identity matrix
ok( is_equals_matrix(multiply_matrix(make_symbolic_matrix([[2,5],[-1,4]]),invert_matrix(make_symbolic_matrix([[2,5],[-1,4]]))), identity_matrix(2)), "product of matrix with inverse equals identity (Pure Mathematics 4 - Problem 4B.4a)" );
ok( is_equals_matrix(multiply_matrix(make_symbolic_matrix([[-3,2],[-1,7]]),invert_matrix(make_symbolic_matrix([[-3,2],[-1,7]]))), identity_matrix(2)), "product of matrix with inverse equals identity (Pure Mathematics 4 - Problem 4B.4b)" );
ok( is_equals_matrix(multiply_matrix(make_symbolic_matrix([[2,-3],[1,-4]]),invert_matrix(make_symbolic_matrix([[2,-3],[1,-4]]))), identity_matrix(2)), "product of matrix with inverse equals identity (Pure Mathematics 4 - Problem 4B.4c)" );
ok( is_equals_matrix(multiply_matrix(make_symbolic_matrix([[0,1],[-3,2]]),invert_matrix(make_symbolic_matrix([[0,1],[-3,2]]))), identity_matrix(2)), "product of matrix with inverse equals identity (Pure Mathematics 4 - Problem 4B.4d)" );
ok( is_equals_matrix(multiply_matrix(make_symbolic_matrix([[-3,7],[9,22]]),invert_matrix(make_symbolic_matrix([[-3,7],[9,22]]))), identity_matrix(2)), "product of matrix with inverse equals identity (Pure Mathematics 4 - Problem 4B.4e)" );
ok( is_equals_matrix(multiply_matrix(make_symbolic_matrix([[2,1,-5],[1,0,-2],[0,0,3]]),invert_matrix(make_symbolic_matrix([[2,1,-5],[1,0,-2],[0,0,3]]))), identity_matrix(3)), "product of matrix with inverse equals identity (Pure Mathematics 4 - Problem 4B.4f)" );
ok( is_equals_matrix(multiply_matrix(make_symbolic_matrix([[-1,2,1],[0,0,-2],[1,-5,4]]),invert_matrix(make_symbolic_matrix([[-1,2,1],[0,0,-2],[1,-5,4]]))), identity_matrix(3)), "product of matrix with inverse equals identity (Pure Mathematics 4 - Problem 4B.4g)" );
ok( is_equals_matrix(multiply_matrix(make_symbolic_matrix([[-1,2,3],[1,1,2],[5,-1,4]]),invert_matrix(make_symbolic_matrix([[-1,2,3],[1,1,2],[5,-1,4]]))), identity_matrix(3)), "product of matrix with inverse equals identity (Pure Mathematics 4 - Problem 4B.4h)" );
ok( is_equals_matrix(multiply_matrix(make_symbolic_matrix([[-2,3,-4],[1,2,-3],[-3,0,-2]]),invert_matrix(make_symbolic_matrix([[-2,3,-4],[1,2,-3],[-3,0,-2]]))), identity_matrix(3)), "product of matrix with inverse equals identity (Pure Mathematics 4 - Problem 4B.4i)" );
ok( is_equals_matrix(multiply_matrix(make_symbolic_matrix([[2,-1,2],[1,-1,1],[2,1,-3]]),invert_matrix(make_symbolic_matrix([[2,-1,2],[1,-1,1],[2,1,-3]]))), identity_matrix(3)), "product of matrix with inverse equals identity (Pure Mathematics 4 - Problem 4B.4j)" );
ok( is_equals_matrix(multiply_matrix(make_symbolic_matrix([[3,2,-6],[1,1,-2],[2,2,-1]]),invert_matrix(make_symbolic_matrix([[3,2,-6],[1,1,-2],[2,2,-1]]))), identity_matrix(3)), "product of matrix with inverse equals identity (Pure Mathematics 4 - Problem 4B.4k)" );
ok( is_equals_matrix(multiply_matrix(make_symbolic_matrix([[4,-5,2],[0,1,-7],[1,1,-2]]),invert_matrix(make_symbolic_matrix([[4,-5,2],[0,1,-7],[1,1,-2]]))), identity_matrix(3)), "product of matrix with inverse equals identity (Pure Mathematics 4 - Problem 4B.4l)" );
ok( is_equals_matrix(multiply_matrix(make_symbolic_matrix([[3,2,-3],[1,1,-4],[2,2,-6]]),invert_matrix(make_symbolic_matrix([[3,2,-3],[1,1,-4],[2,2,-6]]))), identity_matrix(3)), "product of matrix with inverse equals identity (Pure Mathematics 4 - Problem 4B.4m)" );

# in the symbolic case we have to evaluate with parameter/variable values that don't take the determinant to 0 
ok(
    is_equals_matrix(
        make_symbolic_matrix(
            evaluate_matrix(
                multiply_matrix(
                    make_symbolic_matrix([['a','b'],['c','d']]),
                    invert_matrix(
                        make_symbolic_matrix([['a','b'],['c','d']])
                    )
                ),
                { 'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4 }
            )
        ),
        identity_matrix(2)
    ),
    "product of matrix with inverse equals identity M=(['a','b'],['c','d'])"
);

ok(
    is_equals_matrix(
        make_symbolic_matrix(
            evaluate_matrix(
                multiply_matrix(
                    make_symbolic_matrix([['10-lambda',-6],[-2,'9-lambda']]),
                    invert_matrix(
                        make_symbolic_matrix([['10-lambda',-6],[-2,'9-lambda']])
                    )
                ),
                { 'lambda' => 42 }
            )
        ),
        identity_matrix(2)
    ),
    "product of matrix with inverse equals identity M=(['10-lambda',-6],[-2,'9-lambda'])"
);

ok(
    is_equals_matrix(
        make_symbolic_matrix(
            evaluate_matrix(
                multiply_matrix(
                    make_symbolic_matrix([['10-x',-6,2],[-6,'9-x',-4],[2,-4,'5-x']]),
                    invert_matrix(
                        make_symbolic_matrix([['10-x',-6,2],[-6,'9-x',-4],[2,-4,'5-x']])
                    )
                ),
                { 'x' => 42 }
            )
        ),
        identity_matrix(3)
    ),
    "product of matrix with inverse equals identity M=(['10-x',-6,2],[-6,'9-x',-4],[2,-4,'5-x'])"
);

# solving using inverse matrix
ok( is_equals_matrix(multiply_matrix(invert_matrix(make_symbolic_matrix([[1,1,1],[1,2,3],[1,4,9]])),make_symbolic_matrix([[6],[14],[36]])),make_symbolic_matrix([[1],[2],[3]])), "Linear solve with inverse matrix (Mathematical Methods for Science Students - Ch. 17.4 eq 90)");
ok( is_equals_matrix(multiply_matrix(invert_matrix(make_symbolic_matrix([[4,-3,1],[2,1,-4],[1,2,-2]])),make_symbolic_matrix([[11],[-1],[1]])),make_symbolic_matrix([[3],[1],[2]])), "Linear solve with inverse matrix (Mathematical Methods for Science Students - Problem 17.9a)");
ok( is_equals_matrix(multiply_matrix(invert_matrix(make_symbolic_matrix([[1,1,1],[1,2,3],[1,4,9]])),make_symbolic_matrix([[1,2],[3,4],[5,6]])),make_symbolic_matrix([[-2,-1],[4,4],[-1,-1]])), "Linear solve with inverse matrix (example page 21 'Linear Algebra', Shen, Wang, Wojdylo, 2019 Mercury)");

# done

sub determinant_4B_3a {
    # Pure Mathematics 4 4B.3a

    my @mat = (     [ 1, 2 ],
                    [ 1, 3 ],
                    );

    my $det = det @mat;

    if ( defined(my $c = $det->simplify()) ) {
        return $c;
    }

    return q{};
}

sub determinant_4B_3e {
    # Pure Mathematics 4 4B.3e

    my @mat = (     [ 1, 2, -3 ],
                    [ 1, 1, 0  ],
                    [ -1, 4, -6 ],
                    );

    my $det = det @mat;

    if ( defined(my $c = $det->simplify()) ) {
        return $c;
    }

    return q{};
}

sub determinant_4B_3f {
    # Pure Mathematics 4 4B.3f

    my @mat = (     [ -2, 7, 3 ],
                    [ 1, 2, 4  ],
                    [ -1, 2, 0 ],
                    );

    my $det = det @mat;

    if ( defined(my $c = $det->simplify()) ) {
        return $c;
    }

    return q{};
}

sub determinant_4B_3g {
    # Pure Mathematics 4 4B.3g

    my @mat = (     [ 2, -3, 6 ],
                    [ -2, 4, 5  ],
                    [ -1, 0, -5 ],
                    );

    my $det = det @mat;

    if ( defined(my $c = $det->simplify()) ) {
        return $c;
    }

    return q{};
}

sub determinant_4B_3h {
    # Pure Mathematics 4 4B.3h

    my @mat = (     [ 1, 2, -3 ],
                    [ 2, 2, -4 ],
                    [ -4, 2, 1 ],
                    );

    my $det = det @mat;

    if ( defined(my $c = $det->simplify()) ) {
        return $c;
    }

    return q{};
}

sub determinant_16_2c {
    # Mathematical Methods for Science Students - Problem 16.2c

    my @mat = (     [ 1, 'a', 'a^2', 'a^3+b*c*d' ], 
                    [ 1, 'b', 'b^2', 'b^3+c*d*a' ],
                    [ 1, 'c', 'c^2', 'c^3+a*b*d' ],
                    [ 1, 'd', 'd^2', 'd^3+a*b*c' ],
                    );

    my $det = det @mat;

    if ( defined(my $c = $det->simplify()) ) {
        return $c;
    }

    return q{};
}

sub determinant_16_3 {
   # Mathematical Methods for Science Students - Problem 16.3

    my @mat = (     [ '10-lambda',  -6,         2           ],
                    [ -6,           '9-lambda', -4          ],
                    [ 2,            -4,         '5-lambda'  ]
                    );

    my $det = det @mat;

    if ( defined(my $c = $det->simplify()) ) {
        return $c;
    }

    return q{};  
}

sub determinant_16_4 {
   # Mathematical Methods for Science Students - Problem 16.4

    my @mat = (     [ '-1*lambda',   1,           0          ],
                    [ 1,           '-1*lambda',   1          ],
                    [ 0,           1,           '-1*lambda'  ]
                    );

    my $det = det @mat;

    if ( defined(my $c = $det->simplify()) ) {
        return $c;
    }

    return q{};  
}

sub determinant_LA_p23 {
    # example page 23 'Linear Algebra'

    my @mat = ( [7, 8, 2, -3],
                [4, 4, 6, 6],
                [6, 7, 3, -17],
                [3, 15, 9, 3],
                );

    my $det = det @mat;

    if ( defined(my $c = $det->simplify()) ) {
        return $c;
    }

    return q{};
}

