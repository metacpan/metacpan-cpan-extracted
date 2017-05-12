#!perl -T

use strict;
use warnings;

use Test::More tests => 10252;
use Math::MatrixReal;

BEGIN {
    use_ok('Math::Vector::BestRotation');
}

sub _flip {
    return Math::MatrixReal->new_diag([1, 1, -1]);
}

sub _rms {
    my ($x, $y, $matrix) = @_;
    my $sum              = 0;

    for(my $i=0;$i<@$x;$i++) {
	my $vec_x    = Math::MatrixReal->new_from_cols([$x->[$i]]);
	my $vec_y    = Math::MatrixReal->new_from_cols([$y->[$i]]);
	my $mapped_x = $matrix * $vec_x;
	my $diff     = $mapped_x - $vec_y;

	$sum += $diff->scalar_product($diff);
    }

    return(sqrt($sum));
}

sub _get_rot_matrix {
    my ($euler1, $euler2, $euler3) = @_;

    my $rot1 = Math::MatrixReal->new_from_rows([
	[  cos($euler1),   -sin($euler1),  0   ],
	[  sin($euler1),    cos($euler1),  0   ],
        [  0,               0,             1   ],
					    ]);
    my $rot2 = Math::MatrixReal->new_from_rows([
        [  1,   0,               0             ],
	[  0,   cos($euler2),   -sin($euler2)  ],
	[  0,   sin($euler2),    cos($euler2)  ],
					    ]);
    my $rot3 = Math::MatrixReal->new_from_rows([
	[  cos($euler3),   -sin($euler3),  0   ],
	[  sin($euler3),    cos($euler3),  0   ],
        [  0,               0,             1   ],
					    ]);
    return $rot1 * $rot2 * $rot3;
}

sub _get_vector_pair {
    my ($matrix, $coords) = @_;
    my $mapped;

    $coords = Math::MatrixReal->new_from_cols([$coords])
	if(ref($coords) eq 'ARRAY');
    $mapped = $matrix * $coords;
    return([map { $coords->element($_, 1) } (1, 2, 3)],
	   [map { $mapped->element($_, 1) } (1, 2, 3)]);
}

sub best_orthogonal {
    my $rot = Math::Vector::BestRotation->new;
    my $pi  = atan2(1, 1) * 4;
    my $matrix;
    my $ref;
    my $diff;
    my ($rot1, $rot2, $rot3);

    can_ok($rot, 'best_orthogonal');

    my $flip = _flip;

    $ref = Math::MatrixReal->new_from_string(<<'    MATRIX');
        [  0  -1   0  ]
	[  1   0   0  ]
	[  0   0   1  ]
    MATRIX
    $rot->add_pair([1, 0, 0], [0, 1, 0]);
    $rot->add_pair([0, 1, 0], [-1, 0, 0]);
    $matrix = $rot->best_orthogonal;
    isa_ok($matrix, 'Math::MatrixReal');
    cmp_ok(abs($matrix->det - 1), '<', 1e-9, 'is special orthogonal');
    $diff = $matrix - $ref;
    for(my $i=0;$i<3;$i++) {
	for(my $j=0;$j<3;$j++) {
	    cmp_ok(abs($diff->element($i+1, $j+1)), '<', 1e-9,
		   sprintf("result from scratch %d %d", $i+1, $j+1));
	}
    }
    $matrix = $rot->matrix_u;
    isa_ok($matrix, 'Math::MatrixReal');
    cmp_ok(abs($matrix->det - 1), '<', 1e-9, 'is special orthogonal');
    $diff = $matrix - $ref;
    for(my $i=0;$i<3;$i++) {
	for(my $j=0;$j<3;$j++) {
	    cmp_ok(abs($diff->element($i+1, $j+1)), '<', 1e-9,
		   sprintf("result from scratch %d %d", $i+1, $j+1));
	}
    }

    # another simple one
    $rot->clear;
    $ref = Math::MatrixReal->new_from_string(<<'    MATRIX');
        [  1   0   0  ]
	[  0   0   1  ]
	[  0  -1   0  ]
    MATRIX
    $rot->add_pair(_get_vector_pair($ref, [0, 1, 0]));
    $rot->add_pair(_get_vector_pair($ref, [0, 0, 1]));
    $matrix = $rot->best_orthogonal;
    isa_ok($matrix, 'Math::MatrixReal');
    cmp_ok(abs($matrix->det - 1), '<', 1e-9, 'is special orthogonal');
    $diff = $matrix - $ref;
    for(my $i=0;$i<3;$i++) {
	for(my $j=0;$j<3;$j++) {
	    cmp_ok(abs($diff->element($i+1, $j+1)), '<', 1e-9,
		   sprintf("another simple %d %d", $i+1, $j+1));
	}
    }

    # another simple one
    $rot->clear;
    $ref = _get_rot_matrix(0, $pi / 2, 0);
    $rot->add_pair(_get_vector_pair($ref, [1, 0, 0]));
    $rot->add_pair(_get_vector_pair($ref, [0, 1, 0]));
    $rot->add_pair(_get_vector_pair($ref, [0, 0, 1]));
    $matrix = $rot->best_rotation;
    isa_ok($matrix, 'Math::MatrixReal');
    cmp_ok(abs($matrix->det - 1), '<', 1e-9, 'is special orthogonal');
    $diff = $matrix - $ref;
    for(my $i=0;$i<3;$i++) {
	for(my $j=0;$j<3;$j++) {
	    cmp_ok(abs($diff->element($i+1, $j+1)), '<', 1e-9,
		   sprintf("another simple %d %d", $i+1, $j+1));
	}
    }

    # arbitrary rotation
    $rot->clear;
    $rot1 = Math::MatrixReal->new_from_rows([
        [  1,          0,           0  ],
	[  0,   cos(0.3),   -sin(0.3)  ],
	[  0,   sin(0.3),    cos(0.3)  ],
					    ]);
    $rot2 = Math::MatrixReal->new_from_rows([
	[ cos(2.1),   0,    -sin(2.1)  ],
        [        0,   1,            0  ],
	[ sin(2.1),   0,     cos(2.1)  ],
					    ]);
    $rot3 = Math::MatrixReal->new_from_rows([
	[  cos(-1),   -sin(-1),  0   ],
	[  sin(-1),    cos(-1),  0   ],
        [        0,          0,  1   ],
					    ]);
    $ref = $rot1 * $rot2 * $rot3;
    cmp_ok(abs($ref->det - 1), '<', 1e-9, 'ref is special orthogonal');
    $rot->add_pair(_get_vector_pair($ref, [1, 2, 3]));
    $rot->add_pair(_get_vector_pair($ref, [4, -1, 0]));
    $rot->add_pair(_get_vector_pair($ref, [3, 5, 1]));
    $rot->add_pair(_get_vector_pair($ref, [-7, -0.123, -23.786]));
    $matrix = $rot->best_orthogonal;
    isa_ok($matrix, 'Math::MatrixReal');
    cmp_ok(abs($matrix->det - 1), '<', 1e-9, 'is special orthogonal');
    $diff = $matrix - $ref;
    for(my $i=0;$i<3;$i++) {
	for(my $j=0;$j<3;$j++) {
	    cmp_ok(abs($diff->element($i+1, $j+1)), '<', 1e-9,
		   sprintf("arbitrary with 4 pairs %d %d", $i+1, $j+1));
	}
    }

    # and flipped
    $rot->clear;
    $ref = $ref * $flip;
    cmp_ok(abs($ref->det + 1), '<', 1e-9, 'ref has det -1');
    $rot->add_pair(_get_vector_pair($ref, [1, 2, 3]));
    $rot->add_pair(_get_vector_pair($ref, [4, -1, 0]));
    $rot->add_pair(_get_vector_pair($ref, [3, 5, 1]));
    $rot->add_pair(_get_vector_pair($ref, [-7, -0.123, -23.786]));
    cmp_ok($rot->matrix_r->det, '<', 0, 'R has det < 0');
    $matrix = $rot->best_orthogonal;
    isa_ok($matrix, 'Math::MatrixReal');
    cmp_ok(abs($matrix->det + 1), '<', 1e-9, 'has det -1');
    $diff = $matrix - $ref;
    for(my $i=0;$i<3;$i++) {
	for(my $j=0;$j<3;$j++) {
	    cmp_ok(abs($diff->element($i+1, $j+1)), '<', 1e-9,
		   sprintf("same one flipped %d %d", $i+1, $j+1));
	}
    }
    $matrix = $rot->best_rotation;
    isa_ok($matrix, 'Math::MatrixReal');
    cmp_ok(abs($matrix->det - 1), '<', 1e-9,
	   'best rotation is special orthogonal');
}

sub _compare_all_rotations {
    my ($x, $y, $rms) = @_;
    my $pi            = 4 * atan2(1, 1);
    my $x_rotations   =
	[@{[map { Math::MatrixReal->new_from_rows
		   ([[1, 0, 0],
		     [0, cos($_ * $pi), -sin($_ * $pi)],
		     [0, sin($_ * $pi), cos($_ * $pi)]]) }
	 (0, 0.2, 0.4, 0.6, 0.8, 1.0, 1.2, 1.4, 1.6, 1.8)]}];
    my $y_rotations =
	[@{[map { Math::MatrixReal->new_from_rows
		   ([[cos($_ * $pi), 0, -sin($_ * $pi)],
		     [0, 1, 0],
		     [sin($_ * $pi), 0, cos($_ * $pi)]]) }
	 (0, 0.2, 0.4, 0.6, 0.8, 1.0, 1.2, 1.4, 1.6, 1.8)]}];
    my $z_rotations =
	[@{[map { Math::MatrixReal->new_from_rows
		   ([[cos($_ * $pi), -sin($_ * $pi), 0],
		     [sin($_ * $pi), cos($_ * $pi), 0],
		     [0, 0, 1]]) }
	 (0, 0.2, 0.4, 0.6, 0.8, 1.0, 1.2, 1.4, 1.6, 1.8)]}];
    my $flip        = _flip;

    my $test_rms;
    foreach(@$x_rotations) {
	$test_rms = _rms($x, $y, $_);
	cmp_ok($test_rms, '>=', $rms, "$test_rms >= $rms");
    }
    foreach(@$y_rotations) {
	$test_rms = _rms($x, $y, $_);
	cmp_ok($test_rms, '>=', $rms, "$test_rms >= $rms");
    }
    foreach(@$z_rotations) {
	$test_rms = _rms($x, $y, $_);
	cmp_ok($test_rms, '>=', $rms, "$test_rms >= $rms");
    }
    foreach my $z1 (@$z_rotations) {
	foreach my $x1 (@$x_rotations) {
	    foreach my $z2 (@$z_rotations) {
		my $test_matrix = $z1 * $x1 * $z2;
		$test_rms = _rms($x, $y, $test_matrix);
		cmp_ok($test_rms, '>=', $rms, "$test_rms >= $rms");
		$test_matrix *= $flip;
		$test_rms = _rms($x, $y, $test_matrix);
		cmp_ok($test_rms, '>=', $rms, "$test_rms >= $rms");
	    }
	}
    }
}

sub evidence_for_best {
    my $rot;
    my $x;
    my $y;
    my $matrix;
    my $rms;
    my $ref;
    
    ok(1, "a simple rotation");
    $rot = Math::Vector::BestRotation->new;
    $x   = [[1, 0, 0], [0, 1, 0]];
    $y   = [[0, 1, 0], [-1, 0, 0]];
    $rot->add_many_pairs($x, $y);
    $matrix = $rot->best_orthogonal;
    $rms    = _rms($x, $y, $matrix);
    cmp_ok($rms, '<', 1e-6, 'ortho < 1e-6');
    $matrix = $rot->best_rotation;
    cmp_ok($rms, '<=', _rms($x, $y, $matrix), 'rot <= ortho');
    cmp_ok($rms, '==', _rms($x, $y, $matrix), 'rot == ortho');
    $matrix = $rot->best_flipped_rotation;
    cmp_ok($rms, '<=', _rms($x, $y, $matrix), 'ortho <= flipped');
    _compare_all_rotations($x, $y, $rms);

    ok(1, "an arbitrary rotation");
    $rot->clear;
    $ref = _get_rot_matrix(-0.5, -3, 1.1);
    cmp_ok(abs($ref->det - 1), '<', 1e-9, 'ref is special orthogonal');
    $x = [[1, 2, -4],
	  [0, 3, 1.2],
	  [-0.4, 10, -24],
	  [0.2, 0.2, 0.2]];
    $y = [map { (_get_vector_pair($ref, $_))[1] } @$x];
    $rot->add_many_pairs($x, $y);
    $matrix = $rot->best_orthogonal;
    $rms    = _rms($x, $y, $matrix);
    cmp_ok($rms, '<', 1e-6, 'ortho < 1e-6');
    $matrix = $rot->best_rotation;
    cmp_ok($rms, '<=', _rms($x, $y, $matrix), 'rot <= ortho');
    cmp_ok($rms, '==', _rms($x, $y, $matrix), 'rot == ortho');
    $matrix = $rot->best_flipped_rotation;
    cmp_ok($rms, '<=', _rms($x, $y, $matrix), 'ortho <= flipped');
    _compare_all_rotations($x, $y, $rms);

    ok(1, "an arbitrary flipped rotation");
    $rot->clear;
    $ref = _get_rot_matrix(-0.3, 0.2, 2.6) * _flip;
    cmp_ok(abs($ref->det + 1), '<', 1e-9, 'ref has det -1');
    $x = [[1, 2, -4],
	  [0, 3, 1.2],
	  [-0.4, 10, -24],
	  [0.2, 0.2, 0.2]];
    $y = [map { (_get_vector_pair($ref, $_))[1] } @$x];
    $rot->add_many_pairs($x, $y);
    $matrix = $rot->best_orthogonal;
    $rms    = _rms($x, $y, $matrix);
    cmp_ok($rms, '<', 1e-6, 'ortho < 1e-6');
    $matrix = $rot->best_rotation;
    cmp_ok($rms, '<=', _rms($x, $y, $matrix), 'rot <= ortho');
    $matrix = $rot->best_flipped_rotation;
    cmp_ok($rms, '<=', _rms($x, $y, $matrix), 'ortho <= flipped');
    cmp_ok($rms, '==', _rms($x, $y, $matrix), 'flipped == ortho');
    _compare_all_rotations($x, $y, $rms);

    ok(1, "a rotation with jitter");
    $rot->clear;
    $ref = _get_rot_matrix(2.3, -1.2, -2.1);
    cmp_ok(abs($ref->det - 1), '<', 1e-9, 'ref is special orthogonal');
    $x = [[1, 2, -4],
	  [0, 3, 1.2],
	  [-0.4, 10, -24],
	  [0.2, 0.2, 0.2]];
    $y = [map { (_get_vector_pair($ref, $_))[1] } @$x];
    $y->[0]->[0] += 0.1;
    $y->[0]->[1] += 0.2;
    $y->[0]->[2] -= 0.1;
    $y->[1]->[0] -= 0.3;
    $y->[1]->[1] += 0.1;
    $y->[1]->[2] += 0.3;
    $y->[2]->[0] += 0.3;
    $y->[2]->[1] -= 0.2;
    $y->[2]->[2] += 0.1;
    $y->[3]->[0] -= 0.4;
    $y->[3]->[1] += 0.1;
    $y->[3]->[2] += 0.2;
    $rot->add_many_pairs($x, $y);
    $matrix = $rot->best_orthogonal;
    $rms    = _rms($x, $y, $matrix);
    cmp_ok($rms, '>', 0, 'jittered ortho > 0');
    $matrix = $rot->best_rotation;
    cmp_ok($rms, '<=', _rms($x, $y, $matrix), 'rot <= ortho');
    cmp_ok($rms, '==', _rms($x, $y, $matrix), 'rot == ortho');
    $matrix = $rot->best_flipped_rotation;
    cmp_ok($rms, '<=', _rms($x, $y, $matrix), 'ortho <= flipped');
    _compare_all_rotations($x, $y, $rms);

    ok(1, "a rotation with arbitrary y");
    $rot->clear;
    $ref = _get_rot_matrix(2.3, -1.2, -2.1);
    cmp_ok(abs($ref->det - 1), '<', 1e-9, 'ref is special orthogonal');
    $x = [[1, 2, -4],
	  [0, 3, 1.2],
	  [-0.4, 10, -24],
	  [0.2, 0.2, 0.2]];
    $y = [[10, -3, -4],
	  [11, -7, 6.5],
	  [1.2, -0.7, 13],
	  [-0.2, 3, -5]];
    $rot->add_many_pairs($x, $y);
    $matrix = $rot->best_orthogonal;
    $rms    = _rms($x, $y, $matrix);
    cmp_ok($rms, '>', 0, 'jittered ortho > 0');
    $matrix = $rot->best_rotation;
    cmp_ok($rms, '<=', _rms($x, $y, $matrix), 'rot <= ortho');
    cmp_ok($rms, '==', _rms($x, $y, $matrix), 'rot == ortho');
    $matrix = $rot->best_flipped_rotation;
    cmp_ok($rms, '<=', _rms($x, $y, $matrix), 'ortho <= flipped');
    _compare_all_rotations($x, $y, $rms);
}

best_orthogonal;
evidence_for_best;
