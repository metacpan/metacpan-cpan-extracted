package ICC::Support::geo1;

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
# 'points' value is an array reference containing center coordinates
# 'matrix' value is an optional weight matrix, sometimes the inverse covariance matrix
# the weight matrix must have the same dimension as the center coordinate
# parameters: ([ref_to_parameter_hash])
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();

	# create empty geo1 object
	my $self = [
		{},      # object header
		[],      # points array
		[]       # weight matrix
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

# compute radius
# parameters: (ref_to_input_array)
# returns: (radius)
sub transform {

	# get parameters
	my ($self, $in) = @_;

	# if object has covariance matrix
	if (defined($self->[2]) && (0 != @{$self->[2]})) {
		
		# return Mahalanobis distance
		return(ICC::Support::Lapack::mahal($in, $self->[1], $self->[2]));
		
	} else {
		
		# return Euclidean distance
		return(ICC::Support::Lapack::euclid($in, $self->[1]));
		
	}
	
}

# compute Jacobian matrix
# parameters: (ref_to_input_array)
# returns: (Jacobian_matrix, [radius])
sub jacobian {

	# get parameters
	my ($self, $in) = @_;

	# compute radial Jacobian
	my ($jac, $r) = _radjac($self, $in);

	# if array wanted
	if (wantarray) {
		
		# return Jacobian matrix and radius
		return(Math::Matrix->new($jac), $r);
		
	} else {
		
		# return Jacobian matrix
		return(Math::Matrix->new($jac));
		
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
		
		# verify an array reference
		(ref($points) eq 'ARRAY') || croak('\'points\' parameter not an array');
		
		# verify point coordinates
		(@{$points} == grep {Scalar::Util::looks_like_number($_)} @{$points}) || croak('\'points\' array contains invalid coordinates');
		
		# copy points array
		$self->[1] = [@{$points}];
		
	}

	# return end point array reference
	return($self->[1]);

}

# get/set weight matrix
# parameters: ([ref_to_weight_matrix])
# returns: (ref_to_weight_matrix)
sub matrix {

	# get parameters
	my ($self, $matrix) = @_;

	# if parameter supplied
	if (defined($matrix)) {
		
		# verify a 2-D array or Math::Matrix object
		((ref($matrix) eq 'ARRAY' && @{$matrix} == grep {ref() eq 'ARRAY'} @{$matrix}) || UNIVERSAL::isa($matrix, 'Math::Matrix')) || croak('\'matrix\' parameter not a 2-D array or Math::Matrix object');
		
		# verify first row contains only numeric values
		(@{$matrix->[0]} == grep {Scalar::Util::looks_like_number($_)} @{$matrix->[0]}) || croak('\'matrix\' parameter contains non-numeric values');
		
		# verify matrix is square
		(@{$matrix} == @{$matrix->[0]}) || croak('\'matrix\' parameter not square matrix');
		
		# copy weight matrix
		$self->[2] = Storable::dclone($matrix);
		
	}

	# return matrix reference
	return($self->[2]);

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
# parameters: (ref_to_object, ref_to_input_vector)
# returns: (Jacobian_vector, radius)
sub _radjac {

	# get parameters
	my ($self, $in) = @_;

	# local variables
	my ($jac, $r, $wwt);

	# for each dimension
	for my $i (0 .. $#{$self->[1]}) {
		
		# compute input vector element
		$jac->[$i] = ($in->[$i] - $self->[1][$i]);
		
	}

	# if object has weight matrix
	if (defined($self->[2]) && @{$self->[2]}) {
		
		# radius is Mahalanobis distance
		$r = ICC::Support::Lapack::mahal($in, $self->[1], $self->[2]);
		
		# for each row
		for my $i (0 .. $#{$self->[2]}) {
			
			# for each column
			for my $j (0 .. $#{$self->[2][0]}) {
				
				# set matrix element (W + Wᵀ)/2
				$wwt->[$i][$j] = ($self->[2][$i][$j] + $self->[2][$j][$i])/2;
				
			}
			
		}
		
		# multiply Jacobian by (W + Wᵀ)/2 matrix
		$jac = ICC::Support::Lapack::vec_xplus($wwt, $jac, {'trans' => 'T'});
		
	} else {
		
		# radius is Euclidean distance
		$r = ICC::Support::Lapack::euclid($in, $self->[1]);
		
	}

	# if radius is zero
	if ($r == 0) {
		
		# set Jacobian to all ones
		$jac = [(1) x @{$self->[1]}];
		
	} else {
		
		# for each dimension
		for my $i (0 .. $#{$self->[1]}) {
			
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
	my ($points, $matrix, $info);

	# get points array
	if ($points = $hash->{'points'}) {
		
		# verify an array reference
		(ref($points) eq 'ARRAY') || croak('\'points\' parameter not an array');
		
		# verify point coordinates
		(@{$points} == grep {Scalar::Util::looks_like_number($_)} @{$points}) || croak('\'points\' array contains invalid coordinates');
		
		# copy points array
		$self->[1] = [@{$points}];
		
	}

	# get weight matrix
	if ($matrix = $hash->{'matrix'}) {
		
		# verify a 2-D array or Math::Matrix object
		((ref($matrix) eq 'ARRAY' && @{$matrix} == grep {ref() eq 'ARRAY'} @{$matrix}) || UNIVERSAL::isa($matrix, 'Math::Matrix')) || croak('\'matrix\' parameter not a 2-D array or Math::Matrix object');
		
		# verify first row contains only numeric values
		(@{$matrix->[0]} == grep {Scalar::Util::looks_like_number($_)} @{$matrix->[0]}) || croak('\'matrix\' parameter contains non-numeric values');
		
		# verify matrix is square
		(@{$matrix} == @{$matrix->[0]}) || croak('\'matrix\' parameter not square matrix');
		
		# verify matrix and center have same dimensions
		(@{$matrix} == @{$self->[1]}) || croak('\'matrix\' and \'center\' have different dimensions');
		
		# copy weight matrix
		$self->[2] = Storable::dclone($matrix);
		
	}

}

1;