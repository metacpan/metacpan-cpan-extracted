#!perl -T

use strict;
use warnings;

use Test::More tests => 10;

BEGIN {
    use_ok('Math::Vector::BestRotation');
}

sub _flip {
    return Math::MatrixReal->new_diag([1, 1, -1]);
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

sub rotation_axis {
    my $rot;
    my $ref;
    my $matrix;
    my $pi;
    my $axis;

    $pi  = atan2(1, 1) * 4;
    $rot = Math::Vector::BestRotation->new;

    # a simple one
    $ref = _get_rot_matrix(0, 0, $pi / 2);
    $rot->add_pair(_get_vector_pair($ref, [1, 0, 0]));
    $rot->add_pair(_get_vector_pair($ref, [0, 1, 0]));
    $rot->add_pair(_get_vector_pair($ref, [0, 0, 1]));
    $rot->best_rotation;

    $axis = $rot->rotation_axis;
    cmp_ok(abs($axis->length - 1), '<', 1e-6, 'axis is unit vector');
    $ref  = Math::MatrixReal->new_from_cols([[0, 0, 1]]);
    ok(($axis - $ref)->length < 1e-6 || ($axis + $ref)->length < 1e-6,
       'axis == ref or axis == -ref');
    $rot->clear;    

    # another simple one
    $ref = _get_rot_matrix(0, $pi / 2, 0);
    $rot->add_pair(_get_vector_pair($ref, [1, 0, 0]));
    $rot->add_pair(_get_vector_pair($ref, [0, 1, 0]));
    $rot->add_pair(_get_vector_pair($ref, [0, 0, 1]));
    $rot->best_rotation;

    $axis = $rot->rotation_axis;
    cmp_ok(abs($axis->length - 1), '<', 1e-6, 'axis is unit vector');
    $ref  = Math::MatrixReal->new_from_cols([[1, 0, 0]]);
    ok(($axis - $ref)->length < 1e-6 || ($axis + $ref)->length < 1e-6,
       'axis == ref or axis == -ref');
    $rot->clear;    

    # arbitrary
    $ref = _get_rot_matrix(1.1, 2, 0.7) * 
	_get_rot_matrix(0, 0, $pi / 2) *
	~(_get_rot_matrix(1.1, 2, 0.7));
    $rot->add_pair(_get_vector_pair($ref, [1, 0, 0]));
    $rot->add_pair(_get_vector_pair($ref, [0, 1, 0]));
    $rot->add_pair(_get_vector_pair($ref, [0, 0, 1]));
    $rot->best_rotation;

    $axis = $rot->rotation_axis;
    cmp_ok(abs($axis->length - 1), '<', 1e-6, 'axis is unit vector');
    $ref  = _get_rot_matrix(1.1, 2, 0.7)->col(3);
    ok(($axis - $ref)->length < 1e-6 || ($axis + $ref)->length < 1e-6,
       'axis == ref or axis == -ref');
    $rot->clear;    
}

sub rotation_angle {
    my $rot;
    my $ref;
    my $matrix;
    my $pi;
    my $angle;

    $pi  = atan2(1, 1) * 4;
    $rot = Math::Vector::BestRotation->new;

    # a simple one
    $ref = _get_rot_matrix(0, 0, $pi / 2);
    $rot->add_pair(_get_vector_pair($ref, [1, 0, 0]));
    $rot->add_pair(_get_vector_pair($ref, [0, 1, 0]));
    $rot->add_pair(_get_vector_pair($ref, [0, 0, 1]));
    $rot->best_rotation;

    $angle = $rot->rotation_angle;
    cmp_ok(abs($angle - $pi / 2), '<', 1e-6, 'angle pi/2');
    $rot->clear;    

    # another simple one
    $ref = _get_rot_matrix(0, $pi / 2, 0);
    $rot->add_pair(_get_vector_pair($ref, [1, 0, 0]));
    $rot->add_pair(_get_vector_pair($ref, [0, 1, 0]));
    $rot->add_pair(_get_vector_pair($ref, [0, 0, 1]));
    $rot->best_rotation;

    $angle = $rot->rotation_angle;
    cmp_ok(abs($angle - $pi / 2), '<', 1e-6, 'angle pi/2');
    $rot->clear;    

    # arbitrary
    $ref = _get_rot_matrix(3.1, -2, 0.31) * 
	_get_rot_matrix(0, 0, 2.3) *
	~(_get_rot_matrix(3.1, -2, 0.31));
    $rot->add_pair(_get_vector_pair($ref, [1, 0, 0]));
    $rot->add_pair(_get_vector_pair($ref, [0, 1, 0]));
    $rot->add_pair(_get_vector_pair($ref, [0, 0, 1]));
    $rot->best_rotation;

    $angle = $rot->rotation_angle;
    cmp_ok(abs($angle - 2.3), '<', 1e-6, 'angle 2.3');
    $rot->clear;    
}

rotation_axis;
rotation_angle;
