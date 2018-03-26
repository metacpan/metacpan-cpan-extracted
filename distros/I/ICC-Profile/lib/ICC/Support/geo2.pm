package ICC::Support::geo2;

use strict;
use Carp;

our $VERSION = 0.11;

# revised 2016-05-17
#
# Copyright © 2004-2018 by William B. Birkett

# add development directory
use lib 'lib';

# inherit from Shared
use parent qw(ICC::Shared);

# create new object
# hash keys are:
# 'points' value is an array reference containing two 3-D point coordinate arrays
# parameters: ([ref_to_parameter_hash])
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();

	# create empty geo2 object
	my $self = [
		{},      # object header
		[]       # points array
	];

	# if one parameter, a hash reference
	if (@_ == 1 && ref($_[0]) eq 'HASH') {
		
		# create new object from parameter hash
		_new_from_hash($self, @_);
		
	}

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# compute distance and offset
# optional hash keys:
# 'limit0' limits offset to values >= 0
# 'limit1' limits offset to values <= 1
# parameters: (ref_to_input_array, [hash])
# returns: (distance, offset)
sub transform {

	# get parameters
	my ($self, $in, $hash) = @_;

	# local variables
	my ($v01, $v21, $vx, $s, $t);

	# compute (x0 - x1) and (x2 - x1)
	$v01 = [$in->[0] - $self->[1][0][0], $in->[1] - $self->[1][0][1], $in->[2] - $self->[1][0][2]];
	$v21 = [$self->[1][1][0] - $self->[1][0][0], $self->[1][1][1] - $self->[1][0][1], $self->[1][1][2] - $self->[1][0][2]];

	# compute |(x2 - x1)|^2
	if ($s = $v21->[0]**2 + $v21->[1]**2 + $v21->[2]**2) {
		
		# compute offset
		$t = ICC::Shared::dotProduct($v01, $v21)/$s;
		
		# if offset limited >= 0 and t < 0
		if ($hash->{'limit0'} && $t < 0) {
			
			# return distance and offset
			return(sqrt(($in->[0] - $self->[1][0][0])**2 + ($in->[1] - $self->[1][0][1])**2 + ($in->[2] - $self->[1][0][2])**2), 0);
			
		# if offset limited <= 0 and t > 1
		} elsif ($hash->{'limit1'} && $t > 1) {
			
			# return distance and offset
			return(sqrt(($in->[0] - $self->[1][1][0])**2 + ($in->[1] - $self->[1][1][1])**2 + ($in->[2] - $self->[1][1][2])**2), 1);
			
		} else {
			
			# compute (x0 - x1) x (x2 - x1)
			$vx = ICC::Shared::crossProduct($v01, $v21);
			
			# return distance and offset
			return(sqrt(($vx->[0]**2 + $vx->[1]**2 + $vx->[2]**2)/$s), $t);
			
		}
		
	# identical endpoints
	} else {
		
		# return distance and offset
		return(sqrt(($in->[0] - $self->[1][0][0])**2 + ($in->[1] - $self->[1][0][1])**2 + ($in->[2] - $self->[1][0][2])**2), 0);
		
	}
	
}

# compute Jacobian matrix
# optional hash keys:
# 'limit0' limits offset to values >= 0
# 'limit1' limits offset to values <= 1
# parameters: (ref_to_input_array, [hash])
# returns: (Jacobian_matrix, [distance, offset])
sub jacobian {

	# get parameters
	my ($self, $in, $hash) = @_;

	# local variables
	my ($v01, $v21, $vx, $vr, $s, $t, $d, $jac, $wx);

	# compute (x0 - x1) and (x2 - x1)
	$v01 = [$in->[0] - $self->[1][0][0], $in->[1] - $self->[1][0][1], $in->[2] - $self->[1][0][2]];
	$v21 = [$self->[1][1][0] - $self->[1][0][0], $self->[1][1][1] - $self->[1][0][1], $self->[1][1][2] - $self->[1][0][2]];

	# compute |(x2 - x1)|^2
	if ($s = $v21->[0]**2 + $v21->[1]**2 + $v21->[2]**2) {
		
		# compute offset
		$t = ICC::Shared::dotProduct($v01, $v21)/$s;
		
		# if offset limited >= 0 and t < 0
		if ($hash->{'limit0'} && $t < 0) {
			
			# set offset
			$t = 0;
			
			# compute Jacobian vector and radius
			($jac->[0], $d) = _radjac($self->[1][0], $in);
			
			# complete Jacobian
			$jac->[1] = [0, 0, 0];
			
		# if offset limited <= 0 and t > 1
		} elsif ($hash->{'limit1'} && $t > 1) {
			
			# set offset
			$t = 1;
			
			# compute Jacobian vector and radius
			($jac->[0], $d) = _radjac($self->[1][1], $in);
			
			# complete Jacobian
			$jac->[1] = [0, 0, 0];
			
		} else {
			
			# compute (x0 - x1) x (x2 - x1)
			$vx = ICC::Shared::crossProduct($v01, $v21);
			
			# compute distance
			$d = sqrt(($vx->[0]**2 + $vx->[1]**2 + $vx->[2]**2)/$s);
			
			# compute offset partial derivatives
			$jac->[1] = [$v21->[0]/$s, $v21->[1]/$s, $v21->[2]/$s];
			
			# compute cross product matrix
			$wx = [
				[0, $jac->[1][2]/$d, -$jac->[1][1]/$d],
				[-$jac->[1][2]/$d, 0, $jac->[1][0]/$d],
				[$jac->[1][1]/$d, -$jac->[1][0]/$d, 0]
			];
			
			# compute distance partial derivatives
			$jac->[0] = ICC::Support::Lapack::vec_xplus($wx, $vx, {'trans' => 'T'});
			
		}
		
	# identical endpoints
	} else {
		
		# set offset
		$t = 0;
		
		# compute Jacobian vector and radius
		($jac->[0], $d) = _radjac($self->[1][0], $in);
		
		# complete Jacobian
		$jac->[1] = [0, 0, 0];
		
	}
	
	# bless Jacobian as Math::Matrix object
	bless($jac, 'Math::Matrix');

	# if array wanted
	if (wantarray) {
		
		# return Jacobian, distance and offset
		return($jac, $d, $t);
		
	} else {
		
		# return Jacobian
		return($jac);
		
	}
	
}

# get/set points array
# parameters: ([ref_to_points_array])
# returns: (ref_to_points_array)
sub points {

	# get parameters
	my ($self, $points) = @_;

	# if parameter supplied
	if (defined($points)) {
		
		# verify a 2-D array
		(ref($points) eq 'ARRAY' && @{$points} == grep {ref() eq 'ARRAY'} @{$points}) || croak('\'points\' parameter not a 2-D array');
		
		# verify array has 2 rows
		(@{$points} == 2) || croak('\'points\' parameter must contain 2 points');
		
		# verify point 0 contains 3 coordinates
		(@{$points->[0]} == 3 && 3 == grep {Scalar::Util::looks_like_number($_)} @{$points->[0]}) || croak('\'points\' parameter has invalid point 0');
		
		# verify point 1 contains 3 coordinates
		(@{$points->[1]} == 3 && 3 == grep {Scalar::Util::looks_like_number($_)} @{$points->[1]}) || croak('\'points\' parameter has invalid point 1');
		
		# verify points are unique
		($points->[0][0] != $points->[1][0] || $points->[0][1] != $points->[1][1] || $points->[0][2] != $points->[1][2]) || carp('\'points\' parameter contains identical points');
		
		# copy points array
		$self->[1] = Storable::dclone($points);
		
	}

	# return end point array reference
	return($self->[1]);

}

# print object contents to string
# format is an array structure
# parameter: ([format])
# returns: (string)
sub sdump {

	# get parameters
	my ($self, $p) = @_;

	# local variables
	my ($s, $fmt);

	# resolve parameter to an array reference
	$p = defined($p) ? ref($p) eq 'ARRAY' ? $p : [$p] : [];

	# get format string
	$fmt = defined($p->[0]) && ! ref($p->[0]) ? $p->[0] : 'undef';

	# set string to object ID
	$s = sprintf("'%s' object, (0x%x)\n", ref($self), $self);

	# return
	return($s);

}

# compute radial Jacobian
# parameters: (point_vector, ref_to_input_vector)
# returns: (Jacobian_vector, radius)
sub _radjac {

	# get parameters
	my ($point, $in) = @_;

	# local variables
	my ($jac, $r);

	# for each dimension
	for my $i (0 .. 2) {
		
		# compute Jacobian element
		$jac->[$i] = ($in->[$i] - $point->[$i]);
		
	}

	# compute radius
	$r = sqrt($jac->[0]**2 + $jac->[1]**2 + $jac->[2]**2);

	# if radius is zero
	if ($r == 0) {
		
		# set Jacobian to all ones
		$jac = [1, 1, 1];
		
	} else {
		
		# for each dimension
		for my $i (0 .. 2) {
			
			# divide by radius
			$jac->[$i] /= $r;
			
		}
		
	}

	# return
	return($jac, $r);

}

# populate object from parameter hash
# parameters: (object_reference, ref_to_parameter_hash)
sub _new_from_hash {

	# get parameters
	my ($self, $hash) = @_;

	# local variables
	my ($points);

	# get points array
	if ($points = $hash->{'points'}) {
		
		# verify a 2-D array
		(ref($points) eq 'ARRAY' && @{$points} == grep {ref() eq 'ARRAY'} @{$points}) || croak('\'points\' parameter not a 2-D array');
		
		# verify array has 2 rows
		(@{$points} == 2) || croak('\'points\' parameter must contain 2 points');
		
		# verify point 0 contains 3 coordinates
		(@{$points->[0]} == 3 && 3 == grep {Scalar::Util::looks_like_number($_)} @{$points->[0]}) || croak('\'points\' parameter has invalid point 0');
		
		# verify point 1 contains 3 coordinates
		(@{$points->[1]} == 3 && 3 == grep {Scalar::Util::looks_like_number($_)} @{$points->[1]}) || croak('\'points\' parameter has invalid point 1');
		
		# verify points are unique
		($points->[0][0] != $points->[1][0] || $points->[0][1] != $points->[1][1] || $points->[0][2] != $points->[1][2]) || carp('\'points\' parameter contains identical points');
		
		# copy points array
		$self->[1] = Storable::dclone($points);
		
	}

}

1;