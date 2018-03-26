package ICC::Support::rbf;

use strict;
use Carp;

our $VERSION = 0.21;

# revised 2016-05-17
#
# Copyright © 2004-2018 by William B. Birkett

# add development directory
use lib 'lib';

# inherit from Shared
use parent qw(ICC::Shared);

# parameter count by function type
my @Np = (1, 1, 1, 1, 2, 0, 1);

# create new rbf object
# parameters: ([ref_to_parameter_array, ref_to_center_array, [ref_to_covariance_matrix]])
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();
	
	# create empty rbf object
	my $self = [
				{},		# object header
				[],		# parameter array
				[],		# center array
				[]		# inverse covariance matrix
	];

	# if two or three parameters supplied
	if (@_ == 2 || @_ == 3) {
		
		# verify parameter array reference
		(ref($_[0]) eq 'ARRAY') || croak('not an array reference');
		
		# verify function type
		($_[0][0] == int($_[0][0]) && defined($Np[$_[0][0]])) || croak('invalid function type');
		
		# verify number of parameters
		($#{$_[0]} == $Np[$_[0][0]]) || croak('wrong number of parameters');
		
		# copy parameter array
		$self->[1] = [@{shift()}];
		
		# verify center array reference
		(ref($_[0]) eq 'ARRAY') || croak('not an array reference');
		
		# copy center array
		$self->[2] = [@{shift()}];
		
		# if third parameter (covariance matrix) supplied
		if (@_) {
			
			# invert covariance matrix
			(my $info, $self->[3]) = ICC::Support::Lapack::inv(shift());
			
			# quit on error
			($info == 0) || croak("inversion of convariance matrix failed: info= $info");
			
			# verify center and covariance are same size
			($#{$self->[2]} == $#{$self->[3]}) || croak('center and covariance are different sizes');
			
		}
		
	} elsif (@_) {
		
		# wrong number of parameters
		croak('wrong number of parameters');
		
	}

	# bless object
	bless($self, $class);
	
	# return object reference
	return($self);

}

# compute rbf function
# parameters: (ref_to_input_array)
# returns: (output_value)
sub transform {
	
	# get parameters
	my ($self, $in) = @_;

	# local variables
	my ($r, $array, $type);
	
	# compute radius
	$r = radius($self, $in);
	
	# get parameter array reference
	$array = $self->[1];
	
	# get function type
	$type = $array->[0];
	
	# function type 0 (Gaussian)
	if ($type == 0) {
		
		# return value
		return(exp(-($array->[1] * $r)**2));
		
	# function type 1 (multiquadric)
	} elsif ($type == 1) {
		
		# return value
		return(sqrt(1 + ($array->[1] * $r)**2));
		
	# function type 2 (inverse quadratic)
	} elsif ($type == 2) {
		
		# return value
		return(1/(1 + ($array->[1] * $r)**2));
		
	# function type 3 (inverse multiquadric)
	} elsif ($type == 3) {
		
		# return value
		return(1/(sqrt(1 + ($array->[1] * $r)**2)));
		
	# function type 4 (generalized multiquadric)
	} elsif ($type == 4) {

		# return value
		return((1 + ($array->[1] * $r)**2)**$array->[2]);

	# function type 5 (thin plate spline)
	} elsif ($type == 5) {
		
		# if r is 0
		if ($r == 0) {
			
			# return value
			return(0);
			
		} else {
			
			# return value
			return($r**2 * log($r));
			
		}
		
	# function type 6 (polyharmonic spline)
	} elsif ($type == 6) {

		# if k is odd
		if ($array->[1] % 2) {

			# return value
			return($r**$array->[1]);

		} else {
			
			# if r is 0
			if ($r == 0) {
				
				# return value
				return(0);
				
			} else {
				
				# return value
				return($r**$array->[1] * log($r));
				
			}
			
		}

	} else {
		
		# error
		croak('invalid rbf function type');
		
	}
	
}

# compute rbf Jacobian
# parameters: (ref_to_input_array)
# returns: (Jacobian_vector, [output_value])
sub jacobian {
	
	# get parameters
	my ($self, $in) = @_;

	# local variables
	my ($r, $jac, $array, $type);
	my ($er, $beta, $k, $derv, $out);
	
	# compute radius and radial Jacobian
	($r, $jac) = _jacobian($self, $in);
	
	# get parameter array reference
	$array = $self->[1];
	
	# get function type
	$type = $array->[0];
	
	# function type 0 (Gaussian)
	if ($type == 0) {
		
		# compute ɛr
		$er = $array->[1] * $r;
		
		# compute dɸ/dr
		$derv = -2 * $array->[1] * $er * exp(-$er**2);
		
		# compute output value, if requested
		$out = exp(-$er**2) if wantarray;
		
	# function type 1 (multiquadric)
	} elsif ($type == 1) {
		
		# compute ɛr
		$er = $array->[1] * $r;
		
		# compute dɸ/dr
		$derv = $array->[1] * $er/sqrt(1 + $er**2);
		
		# compute output value, if requested
		$out = sqrt(1 + $er**2) if wantarray;
		
	# function type 2 (inverse quadratic)
	} elsif ($type == 2) {
		
		# compute ɛr
		$er = $array->[1] * $r;
		
		# compute dɸ/dr
		$derv = -2 * $array->[1] * $er/(1 + $er**2)**2;
		
		# compute output value, if requested
		$out = 1/(1 + $er**2) if wantarray;
		
	# function type 3 (inverse multiquadric)
	} elsif ($type == 3) {
		
		# compute ɛr
		$er = $array->[1] * $r;
		
		# compute dɸ/dr
		$derv = -$array->[1] * $er/(1 + $er**2)**1.5;
		
		# compute output value, if requested
		$out = 1/(sqrt(1 + $er**2)) if wantarray;
		
	# function type 4 (generalized multiquadric)
	} elsif ($type == 4) {
		
		# compute ɛr
		$er = $array->[1] * $r;
		
		# get β
		$beta = $array->[2];
		
		# compute dɸ/dr
		$derv = 2 * $beta * $array->[1] * $er * (1 + $er**2)**($beta - 1);
		
		# compute output value, if requested
		$out = (1 + $er**2)**$beta if wantarray;
		
	# function type 5 (thin plate spline)
	} elsif ($type == 5) {
		
		# if r is 0
		if ($r == 0) {
			
			# dɸ/dr = 0 
			$derv = 0;
			
			# compute output value, if requested
			$out = 0 if wantarray;
			
		} else {
			
			# compute dɸ/dr
			$derv = $r * (2 * log($r) + 1);
			
			# compute output value, if requested
			$out = $r**2 * log($r) if wantarray;
			
		}
		
	# function type 6 (polyharmonic spline)
	} elsif ($type == 6) {
		
		# get k
		$k = $array->[1];
		
		# if k is odd
		if ($k % 2) {
			
			# compute dɸ/dr
			$derv = $k * $r**($k - 1);
			
			# compute output value, if requested
			$out = $r**$k if wantarray;
			
		} else {
			
			# if r is 0
			if ($r == 0) {
				
				# dɸ/dr = 0 
				$derv = 0;
				
				# compute output value, if requested
				$out = 0 if wantarray;
				
			} else {
				
				# compute dɸ/dr
				$derv = $r**($k - 1) * ($k * log($r) + 1);
				
				# compute output value, if requested
				$out = $r**$k * log($r) if wantarray;
				
			}
			
		}
		
	} else {
		
		# error
		croak('invalid rbf function type');
		
	}
	
	# for each Jacobian element
	for my $i (0 .. $#{$jac}) {
		
		# multiply by dɸ/dr
		$jac->[$i] *= $derv;
		
	}
	
	# if output requested
	if (wantarray) {
		
		# return Jacobian and output
		return($jac, $out);
		
	} else {
		
		# return Jacobian
		return($jac);
		
	}
	
}

# get/set parameter array
# parameters: ([ref_to_parameter_array])
# returns: (ref_to_parameter_array)
sub array {

	# get object reference
	my $self = shift();
	
	# local variables
	my ($array, $type);
	
	# if parameter
	if (@_) {
		
		# get array reference
		$array = shift();
		
		# verify array reference
		(ref($array) eq 'ARRAY') || croak('not an array reference');
		
		# get function type
		$type = $array->[0];
		
		# verify function type
		($type == int($type) && $type >= 0 && defined($Np[$_[0][0]])) || croak('invalid function type');
		
		# verify number of parameters
		($#{$array} == $Np[$type]) || croak('wrong number of parameters');
		
		# set array reference
		$self->[1] = $array;
		
	}
	
	# return center array reference
	return($self->[1]);

}

# get/set center
# parameters: ([ref_to_center_array])
# returns: (ref_to_center_array)
sub center {

	# get object reference
	my $self = shift();
	
	# local variables
	my ($array);
	
	# if parameter
	if (@_) {
		
		# get array reference
		$array = shift();
		
		# verify array reference
		(ref($array) eq 'ARRAY') || croak('not an array reference');
		
		# set array reference
		$self->[2] = $array;
		
	}
	
	# return center array reference
	return($self->[2]);

}

# get/set inverse covariance matrix
# parameters: ([ref_to_inverse_covariance_matrix])
# returns: (ref_to_inverse_covariance_matrix)
sub matrix {

	# get object reference
	my $self = shift();
	
	# local variables
	my ($matrix);
	
	# if parameter
	if (@_) {
		
		# get matrix reference
		$matrix = shift();
		
		# verify matrix reference
		(ref($matrix) eq 'ARRAY' && ref($matrix->[0]) eq 'ARRAY') || croak('not a matrix reference');
		
		# set matrix reference
		$self->[3] = $matrix;
		
	}
	
	# return matrix reference
	return($self->[3]);

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

# compute radius
# note: no error checking
# parameters: (ref_to_input_vector)
# returns: (radius)
sub radius {
	
	# get parameters
	my ($self, $in) = @_;
	
	# if object has covariance matrix
	if (defined($self->[3]) && (0 != @{$self->[3]})) {
		
		# return Mahalanobis distance
		return(ICC::Support::Lapack::mahal($in, $self->[2], $self->[3]));
		
	} else {
		
		# return Euclidean distance
		return(ICC::Support::Lapack::euclid($in, $self->[2]));
		
	}
	
}

# compute radial Jacobian
# note: no error checking
# parameters: (ref_to_object, ref_to_input_vector)
# returns: (radius, jacobian_vector)
sub _jacobian {
	
	# get parameters
	my ($self, $in) = @_;
	
	# local variables
	my ($r, $jac, $wwt);
	
	# for each dimension
	for my $i (0 .. $#{$self->[2]}) {
		
		# compute Jacobian element
		$jac->[$i] = ($in->[$i] - $self->[2][$i]);
		
	}
	
	# if object has covariance matrix
	if (defined($self->[3]) && @{$self->[3]}) {
		
		# radius is Mahalanobis distance
		$r = ICC::Support::Lapack::mahal($in, $self->[2], $self->[3]);
		
		# for each row
		for my $i (0 .. $#{$self->[3]}) {
			
			# for each column
			for my $j (0 .. $#{$self->[3]}) {
				
				# set (W + Wᵀ)/2 matrix element
				$wwt->[$i][$j] = ($self->[3][$i][$j] + $self->[3][$j][$i])/2;
				
			}
			
		}
		
		# multiply Jacobian by inverse covariance matrix
		$jac = ICC::Support::Lapack::vec_xplus($wwt, $jac, {'trans' => 'T'});
		
	} else {
		
		# radius is Euclidean distance
		$r = ICC::Support::Lapack::euclid($in, $self->[2]);
		
	}
	
	# if radius is zero
	if ($r == 0) {
		
		# set Jacobian to all ones
		$jac = [(1) x @{$self->[2]}];
		
	} else {
		
		# for each dimension
		for my $i (0 .. $#{$self->[2]}) {
			
			# divide by radius
			$jac->[$i] /= $r;
			
		}
		
	}
	
	# return radius and Jacobian vector
	return($r, $jac);
	
}

1;