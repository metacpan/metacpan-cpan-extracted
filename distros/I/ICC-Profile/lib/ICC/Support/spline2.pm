package ICC::Support::spline2;

use strict;
use Carp;

our $VERSION = 0.01;

# revised 2017-11-19
#
# Copyright © 2004-2018 by William B. Birkett

# add development directory
use lib 'lib';

# inherit from Shared
use parent qw(ICC::Shared);

# add complex math functions
use Math::Complex qw(root sqrt cbrt Im Re);

# enable static variables
use feature 'state';

# create new spline2 object
# hash keys are: 'input_range' or 'input_values', 'output_values'
# parameters: ([ref_to_attribute_hash])
# returns: (object_reference)
sub new {

	# get object class
	my $class = shift();

	# create empty spline2 object
	my $self = [
		{}, # object header
		[], # input range
		[], # output values
		[], # derivative values
		[], # min/max output values
		[], # parametric derivative matrix
	];

	# if one parameter, a hash reference
	if (@_ == 1 && ref($_[0]) eq 'HASH') {
		
		# set object contents from hash
		_new_from_hash($self, $_[0]);
		
	} elsif (@_) {
		
		# error
		croak('invalid parameter(s)');
		
	}

	# return blessed object
	return(bless($self, $class));

}

# write spline2 object to ICC profile
# note: writes an equivalent curv object
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub write_fh {

	# get tag reference
	my $self = shift();

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# write spline data to profile
	_writeICCspline($self, @_);

}

# get tag size (for writing to profile)
# note: writes an equivalent curv object
# returns: (tag_size)
sub size {

	# get parameters
	my ($self) = @_;

	# get count value (defaults to 4096, the maximum allowed in an 'mft2' tag)
	my $n = $self->[0]{'curv_points'} // 4096;

	# return size
	return(12 + $n * 2);

}

# compute curve function
# parameters: (input_value)
# returns: (output_value)
sub transform {

	# get parameters
	my ($self, $in) = @_;

	# local variable
	my ($low);

	# if an extrapolated solution (s < 0)
	if ($in < $self->[1][0]) {
		
		# return extrapolated value
		return($self->[2][0] + $self->[3][0] * ($in - $self->[1][0]));
		
	# if an extrapolated solution (s >= 1)
	} elsif ($in >= $self->[1][-1]) {
		
		# return extrapolated value
		return($self->[2][-1] + $self->[3][-1] * ($in - $self->[1][-1]));
		
	} else {
		
		# initilize segment
		$low = 0;
		
		# while input value > upper knot value
		while ($in > $self->[1][$low + 1]) {
			
			# increment segment
			$low++;
			
		}
		
		# return interpolated value
		return(_fwd($self, ($self->[1][$low] - $in)/($self->[1][$low] - $self->[1][$low + 1]), $low));
		
	}
	
}

# compute inverse curve function
# note: there may be multiple solutions
# parameters: (input_value)
# returns: (output_value -or- array_of_output_values)
sub inverse {

	# get parameters
	my ($self, $in) = @_;

	# local variables
	my (@sol, @t);

	# if an extrapolated solution (s < 0)
	if (($in < $self->[2][0] && $self->[3][0] > 0) || ($in > $self->[2][0] && $self->[3][0] < 0)) {
		
		# add solution
		push(@sol, $self->[1][0] + ($in - $self->[2][0])/$self->[3][0]);
		
	}

	# for each segment (0 <= s < 1)
	for my $i (0 .. $#{$self->[2]} - 1) {
		
		# if input is lower knot
		if ($in == $self->[2][$i]) {
			
			# add solution
			push(@sol, $self->[1][$i]);
			
		}
		
		# if input lies within the y-value range
		if ($in >= $self->[4][$i][0] && $in <= $self->[4][$i][1]) {
			
			# compute inverse values (t-values)
			@t = _rev($self, $in, $i);
			
			# add solution(s)
			push(@sol, map {(1 - $_) * $self->[1][$i] + $_ * $self->[1][$i + 1]} @t);
			
		}
		
	}

	# if input is last knot (s == 1)
	if ($in == $self->[2][-1]) {
		
		# add solution
		push(@sol, $self->[1][-1]);
		
	}

	# if an extrapolated solution (s > 1)
	if (($in > $self->[2][-1] && $self->[3][-1] > 0) || ($in < $self->[2][-1] && $self->[3][-1] < 0)) {
		
		# add solution
		push(@sol, $self->[1][-1] + ($in - $self->[2][-1])/$self->[3][-1]);
		
	}

	# return result (array or first solution)
	return(wantarray ? @sol : $sol[0]);

}

# compute curve derivative
# parameters: (input_value)
# returns: (derivative_value)
sub derivative {

	# get parameters
	my ($self, $in) = @_;

	# local variable
	my ($low);

	# if an extrapolated solution (s < 0)
	if ($in < $self->[1][0]) {
		
		# return endpoint derivative
		return($self->[3][0]);
		
	# if an extrapolated solution (s >= 1)
	} elsif ($in >= $self->[1][-1]) {
		
		# return endpoint derivative
		return($self->[3][-1]);
		
	} else {
		
		# initilize segment
		$low = 0;
		
		# while input value > upper knot value
		while ($in > $self->[1][$low + 1]) {
			
			# increment segment
			$low++;
			
		}
		
		# return interpolated derivative value
		return(_derv($self, ($self->[1][$low] - $in)/($self->[1][$low] - $self->[1][$low + 1]), $low));
		
	}
	
}

# compute parametric partial derivatives
# parameters: (input_value)
# returns: (partial_derivative_array)
sub parametric {

	# get parameters
	my ($self, $in) = @_;

	# local variables
	my ($low, $dx, $t, $tc, $h00, $h01, $h10, $h11, @pj);

	# update parametric derivative matrix, if necessary
	_objpara($self) if (! defined($self->[5]) || $#{$self->[5]} != $#{$self->[2]});

	# if an extrapolated solution (s < 0)
	if ($in < $self->[1][0]) {
		
		# for each output value (parameter)
		for my $i (0 .. $#{$self->[2]}) {
			
			# compute partial derivative
			$pj[$i] = ($i == 0) + $self->[5][0][$i] * ($in - $self->[1][0]);
			
		}
		
	# if an extrapolated solution (s >= 1)
	} elsif ($in >= $self->[1][-1]) {
		
		# for each output value (parameter)
		for my $i (0 .. $#{$self->[2]}) {
			
			# compute partial derivative
			$pj[$i] = ($i == $#{$self->[2]}) + $self->[5][-1][$i] * ($in - $self->[1][-1]);
			
		}
		
	} else {
		
		# initilize segment
		$low = 0;
		
		# while input value > upper knot value
		while ($in > $self->[1][$low + 1]) {
			
			# increment segment
			$low++;
			
		}
		
		# compute t-value
		$t = ($self->[1][$low] - $in)/($self->[1][$low] - $self->[1][$low + 1]);
		
		# compute delta x-value
		$dx = $self->[1][$low + 1] - $self->[1][$low];
		
		# compute Hermite coefficients
		$tc = 1 - $t;
		$h00 = (1 + 2 * $t) * $tc * $tc;
		$h01 = 1 - $h00;
		$h10 = $t * $tc * $tc;
		$h11 = -$t * $t * $tc;
		
		# for each output value (parameter)
		for my $i (0 .. $#{$self->[2]}) {
			
			# compute partial derivative
			$pj[$i] = $h00 * ($low == $i) + $h01 * ($low + 1 == $i) + $h10 * $dx * $self->[5][$low][$i] + $h11 * $dx * $self->[5][$low + 1][$i];
			
		}
		
	}

	# return
	return(@pj);

}

# get/set reference to header hash
# parameters: ([ref_to_new_hash])
# returns: (ref_to_hash)
sub header {

	# get object reference
	my $self = shift();

	# if there are parameters
	if (@_) {
	
		# if one parameter, a hash reference
		if (@_ == 1 && ref($_[0]) eq 'HASH') {
		
			# set header to copy of hash
			$self->[0] = Storable::dclone(shift());
		
		} else {
		
			# error
			croak('parameter must be a hash reference');
		
		}
	
	}

	# return reference
	return($self->[0]);

}

# get/set input range array reference
# parameters: ([ref_to_array, [flag]])
# returns: (ref_to_array)
sub range {

	# get object reference
	my $self = shift();

	# local variable
	my ($m);

	# if one or two parameters supplied
	if (@_ == 1 || @_ == 2) {
		
		# verify parameter is an array reference
		(ref($_[0]) eq 'ARRAY') || croak('parameter not an array reference');
		
		# verify array contents
		(@{$_[0]} >= 2 && (@{$_[0]} == grep {Scalar::Util::looks_like_number($_)} @{$_[0]})) || croak('array must contain 2 or more numeric values');
		
		# if array contains two values
		if (@{$_[0]} == 2) {
			
			# if flag set
			if ($_[1]) {
				
				# set uniform x-values
				$self->[1] = [map {my $t = $_/$#{$self->[2]}; (1 - $t) * $_[0]->[0] + $t * $_[0]->[1]} (0 .. $#{$self->[2]})];
				
			} else {
				
				# compute slope
				$m = ($_[0]->[0] - $_[0]->[1])/($self->[1][0] - $self->[1][-1]);
				
				# map existing x-values
				@{$self->[1]} = map {$_[0]->[0] + $m * ($_ - $self->[1][0])} @{$self->[1]};
				
			}
			
		} else {
			
			# save supplied x-values
			$self->[1] = [@{$_[0]}];
			
		}
		
		# sort input/output values, if needed
		_sort_values($self) if (@{$_[0]} > 2 || $_[0]->[0] > $_[0]->[1]);
		
		# recompute knot derivatives
		_objderv($self);
		
		# recompute segment min/max y-values
		_minmax($self);
		
		# reset parametric derivative matrix
		$self->[5] = [];
		
	} elsif (@_) {
		
		# error
		croak('too many parameters');
		
	}

	# return array reference
	return($self->[1]);

}

# get/set output value array reference
# parameters: ([ref_to_array])
# returns: (ref_to_array)
sub array {

	# get object reference
	my $self = shift();

	# if one parameter supplied
	if (@_ == 1) {
		
		# verify parameter is an array reference
		(ref($_[0]) eq 'ARRAY') || croak('parameter not an array reference');
		
		# verify array contents
		(@{$_[0]} >= 2 && (@{$_[0]} == grep {Scalar::Util::looks_like_number($_)} @{$_[0]})) || croak('array must contain 2 or more numeric values');
		
		# verify array size
		(@{$_[0]} == @{$self->[1]}) || carp('array size differs from object x-values');
		
		# store output values
		$self->[2] = [@{$_[0]}];
		
		# recompute knot derivatives
		_objderv($self);
		
		# recompute segment min/max y-values
		_minmax($self);
		
	} elsif (@_) {
		
		# error
		croak('too many parameters');
		
	}
	
	# return array reference
	return($self->[2]);

}

# check if monotonic
# returns min/max values
# returns s-values by default
# returns input-values if format is 'x'
# returns output-values if format is 'y'
# curve is monotonic if no min/max values
# parameters: ([format])
# returns: (array_of_values)
sub monotonic {

	# get object reference
	my ($self, $fmt) = @_;

	# if format undefined or 's'
	if (! defined($fmt) || $fmt eq 's') {
		
		# return s-values
		return(_minmax($self));
		
	# if format 'x'
	} elsif ($fmt eq 'x') {
		
		# return x-values
		return(map {(1 - $_/$#{$self->[2]}) * $self->[1][0] + $_/$#{$self->[2]} * $self->[1][1]} _minmax($self));
		
	# if format 'y'
	} elsif ($fmt eq 'y') {
		
		# return y-values
		return(map {_fwd($self, POSIX::modf($_))} _minmax($self));
		
	} else {
		
		# error
		croak("unsupported format for min/max values");
		
	}
	
}

# make table for 'curv' objects
# assumes curve domain/range is (0 - 1)
# parameters: (number_of_table_entries, [direction])
# returns: (ref_to_table_array)
sub table {

	# get parameters
	my ($self, $n, $dir) = @_;

	# local variables
	my ($up, $table);

	# validate number of table entries
	($n == int($n) && $n >= 2) || carp('invalid number of table entries');

	# purify direction flag
	$dir = ($dir) ? 1 : 0;

	# array upper index
	$up = $n - 1;

	# for each table entry
	for my $i (0 .. $up) {
		
		# compute table value
		$table->[$i] = _transform($self, $dir, $i/$up);
		
	}

	# return table reference
	return($table);

}

# make 'curv' object
# assumes curve domain/range is (0 - 1)
# parameters: (number_of_table_entries, [direction])
# returns: (ref_to_curv_object)
sub curv {

	# return 'curv' object reference
	return(ICC::Profile::curv->new(table(@_)));

}

# normalize transform !!!!! needs work
# adjusts object values linearly
# so that endpoint values are 0 or 1
# adjusts input-range and output-values by default
# adjusts input-values if format is 'x'
# adjusts output-values if format is 'y'
# parameters: ([format])
sub normalize {

	# get parameters
	my ($self, $fmt) = @_;

	# local variables
	my ($off, $range);

	# verify flag parameter
	(! defined($fmt) || $fmt eq 'x' || $fmt eq 'y') || croak('invalid normalize format parameter');

	# if range selected
	if (! defined($fmt) || $fmt eq 'x') {
		
		# if range is increasing
		if ($self->[1][1] > $self->[1][0]) {
			
			# set range (0 - 1)
			$self->[1][0] = 0;
			$self->[1][1] = 1;
			
		} else {
			
			# set range (1 - 0)
			$self->[1][0] = 1;
			$self->[1][1] = 0;
			
		}
		
	}

	# if output values selected
	if (! defined($fmt) || $fmt eq 'y') {
		
		# if output values are increasing
		if ($self->[2][-1] > $self->[2][0]) {
			
			# set offset
			$off = $self->[2][0];
			
			# compute range
			$range = ($self->[2][-1] - $self->[2][0]);
			
		} else {
			
			# set offset
			$off = $self->[2][-1];
			
			# compute range
			$range = ($self->[2][0] - $self->[2][-1]);
			
		}
		
		# verify range
		($range != 0) || croak('cannot normalize output values');
		
		# for each output value
		for my $i (0 .. $#{$self->[2]}) {
			
			# adjust using offset and scale factor
			$self->[2][$i] = ($self->[2][$i] - $off)/$range;
			
		}
		
		# recompute knot derivatives
		_objderv($self);
		
		# recompute segment min/max y-values
		_minmax($self);
		
		# clear parametric derivative matrix
		$self->[5] = [];
		
	}
	
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

# compute parametric partial derivatives
# direction: 0 - normal, 1 - inverse
# parameters: (object_reference, direction, input_value)
# returns: (partial_derivative_array)
sub _parametric {

	# get parameters
	my ($self, $dir, $in) = @_;

	# if inverse direction
	if ($dir) {
		
		# unimplemented function error
		croak('unimplemented function');
		
	} else {
		
		# return array of partial derivatives
		return(parametric($self, $in));
		
	}
	
}

# combined derivative
# direction: 0 - normal, 1 - inverse
# parameters: (object_reference, direction, input_value)
# returns: (derivative_value)
sub _derivative {

	# get parameters
	my ($self, $dir, $in) = @_;

	# if inverse direction
	if ($dir) {
		
		# unimplemented function error
		croak('unimplemented function');
		
	} else {
		
		# return derivative
		return(derivative($self, $in));
		
	}
	
}

# combined transform
# direction: 0 - normal, 1 - inverse
# parameters: (object_reference, direction, input_value)
# returns: (output_value)
sub _transform {

	# get parameters
	my ($self, $dir, $in) = @_;

	# if inverse direction
	if ($dir) {
		
		# return inverse
		return(scalar(inverse($self, $in)));
		
	} else {
		
		# return transform
		return(transform($self, $in));
		
	}
	
}

# compute knot derivatives for natural spline
# parameters: (ref_to_object)
sub _objderv {

	# get parameter
	my $self = shift();

	# local variables
	my ($ix, $rhs, $info, $derv);

	# verify object has two or more knots
	(($ix = $#{$self->[2]}) > 0) || croak('object must have two or more knots');

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# make empty Math::Matrix object
	$rhs = bless([], 'Math::Matrix');

	# for each input element
	for my $i (1 .. $ix - 1) {
		
		# compute rhs (6 * (y[i + 1] - y[i - 1])/(x[i + 1] - x[i - 1]))
		$rhs->[$i][0] = 6 * ($self->[2][$i + 1] - $self->[2][$i - 1])/($self->[1][$i + 1] - $self->[1][$i - 1]);
		
	}

	# set rhs endpoint values
	$rhs->[0][0] = 3 * ($self->[2][1] - $self->[2][0])/($self->[1][1] - $self->[1][0]);
	$rhs->[$ix][0] = 3 * ($self->[2][$ix] - $self->[2][$ix - 1])/($self->[1][$ix] - $self->[1][$ix - 1]);

	# if ICC::Support::Lapack module is loaded
	if ($lapack) {
		
		# solve for derivative matrix
		($info, $derv) = ICC::Support::Lapack::trisolve([(1) x $ix], [2, (4) x ($ix - 1), 2], [(1) x $ix], $rhs);
		
	# otherwise, use Math::Matrix module
	} else {
		
		# solve for derivative matrix
		$derv = Math::Matrix->tridiagonal([2, (4) x ($ix - 1), 2])->concat($rhs)->solve();
		
	}

	# for each knot
	for my $i (0 .. $ix) {
		
		# set derivative value
		$self->[3][$i] = $derv->[$i][0];
		
	}

}

# compute partial derivative matrix for natural spline
# parameters: (ref_to_object)
sub _objpara {

	# get parameter
	my $self = shift();

	# local variables
	my ($ix, $rhs, $x, $info, $derv);

	# verify object has two or more knots
	(($ix = $#{$self->[2]}) > 0) || croak('object must have two or more knots');

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# make rhs matrix (filled with zeros)
	$rhs = $lapack ? ICC::Support::Lapack::zeros($ix + 1) : bless([map {[(0) x ($ix + 1)]} (0 .. $ix)], 'Math::Matrix');

	# for each row
	for my $i (1 .. $ix - 1) {
		
		# set rhs diagonal values
		$rhs->[$i][$i - 1] = $x = 6/($self->[1][$i - 1] - $self->[1][$i + 1]);
		$rhs->[$i][$i + 1] = -$x;
		
	}

	# set rhs endpoint values
	$rhs->[0][0] = $x = 3/($self->[1][0] - $self->[1][1]);
	$rhs->[0][1] = -$x;
	$rhs->[$ix][$ix] = $x = 3/($self->[1][$ix] - $self->[1][$ix - 1]);
	$rhs->[$ix][$ix -1] = -$x;

	# if ICC::Support::Lapack module is loaded
	if ($lapack) {
		
		# solve for derivative matrix
		($info, $derv) = ICC::Support::Lapack::trisolve([(1) x $ix], [2, (4) x ($ix - 1), 2], [(1) x $ix], $rhs);
		
		# set object
		$self->[5] = bless($derv, 'Math::Matrix');
		
	# otherwise, use Math::Matrix module
	} else {
		
		# solve for derivative matrix
		$self->[5] = Math::Matrix->tridiagonal([2, (4) x ($ix - 1), 2])->concat($rhs)->solve();
		
	}
	
}

# add local min/max values
# parameters: (ref_to_object)
# returns: (s-value_array)
sub _minmax {

	# get object reference
	my $self = shift();

	# local variables
	my (@t, @y, @s);

	# for each interval
	for my $i (0 .. $#{$self->[2]} - 1) {
		
		# get min/max location(s)
		@t = _local($self, $i);
		
		# compute local min/max y-values
		@y = map {_fwd($self, $_, $i)} @t;
		
		# add the knot values
		push(@y, ($self->[2][$i], $self->[2][$i + 1]));
		
		# sort the values
		@y = sort {$a <=> $b} @y;
		
		# save y-value min/max span
		$self->[4][$i] = [$y[0], $y[-1]];
		
		# add min/max s-values
		push(@s, map {$_ + $i} @t);
		
	}

	# return min/max s-values
	return(sort {$a <=> $b} @s);

}

# compute local min/max value(s)
# values are within the segment (t)
# parameters: (ref_to_object, segment)
# returns: (t-value_array)
sub _local {

	# get parameters
	my ($self, $low) = @_;

	# local variables
	my ($dx, $y1, $y2, $m1, $m2);
	my ($a, $b, $c, $dscr, @t);

	# compute delta x-value
	$dx = $self->[1][$low + 1] - $self->[1][$low];
	
	# get endpoint values
	$y1 = $self->[2][$low];
	$y2 = $self->[2][$low + 1];
	$m1 = $self->[3][$low] * $dx;
	$m2 = $self->[3][$low + 1] * $dx;

	# compute coefficients of quadratic equation  (at^2 + bt + c = 0)
	$a = 6 * ($y1 - $y2) + 3 * ($m1 + $m2);
	$b = -6 * ($y1 - $y2) - 2 * $m2 - 4 * $m1;
	$c = $m1;

	# return if constant
	return() if (abs($a) < 1E-15 && abs($b) < 1E-15);

	# if linear equation (a is zero)
	if (abs($a) < 1E-15) {
		
		# add solution
		push(@t, -$c/$b);
		
	# if quadratic equation
	} else {
		
		# compute discriminant
		$dscr = $b**2 - 4 * $a * $c;
		
		# if discriminant > zero
		if ($dscr > 0) {
			
			# add solutions (critical points)
			push(@t, -($b + sqrt($dscr))/(2 * $a));
			push(@t, -($b - sqrt($dscr))/(2 * $a));
			
		}
		
	}

	# return solution(s) within interval (0 < t < 0)
	return (grep {$_ > 0 && $_ < 1} @t);

}

# compute second derivative for unit spline segment
# parameters: (ref_to_object, t-value, segment)
# returns: (second_derivative)
sub _derv2 {

	# get parameters
	my ($self, $t, $low) = @_;

	# local variables
	my ($dx, $h00, $h01, $h10, $h11);

	# compute delta x-value
	$dx = $self->[1][$low + 1] - $self->[1][$low];
	
	# compute Hermite derivative coefficients
	$h00 = 12 * $t - 6;
	$h01 = - $h00;
	$h10 = 6 * $t - 4;
	$h11 = 6 * $t - 2;

	# interpolate value
	return(($h00 * $self->[2][$low]/$dx + $h01 * $self->[2][$low + 1]/$dx + $h10 * $self->[3][$low] + $h11 * $self->[3][$low + 1])/$dx);

}

# compute derivative for unit spline segment
# parameters: (ref_to_object, t-value, segment)
# returns: (derivative)
sub _derv {

	# get parameters
	my ($self, $t, $low) = @_;

	# local variables
	my ($dx, $tc, $ttc, $h00, $h01, $h10, $h11);

	# compute delta x-value
	$dx = $self->[1][$low + 1] - $self->[1][$low];
	
	# if position is non-zero
	if ($t) {
		
		# compute Hermite derivative coefficients
		$tc = (1 - $t);
		$ttc = -3 * $t * $tc;
		$h00 = 2 * $ttc;
		$h01 = -2 * $ttc;
		$h10 = $ttc + $tc;
		$h11 = $ttc + $t;
		
		# interpolate value
		return($h00 * $self->[2][$low]/$dx + $h01 * $self->[2][$low + 1]/$dx + $h10 * $self->[3][$low] + $h11 * $self->[3][$low + 1]);
		
	} else {
		
		# use lower knot derivative value
		return($self->[3][$low]);
		
	}
	
}

# compute transform value
# parameters: (ref_to_object, t-value, segment)
# returns: (y-value)
sub _fwd {

	# get parameters
	my ($self, $t, $low) = @_;

	# local variables
	my ($dx, $tc, $h00, $h01, $h10, $h11);

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# if position is non-zero
	if ($t) {
		
		# compute delta x-value
		$dx = $self->[1][$low + 1] - $self->[1][$low];
		
		# interpolate value (Lapack XS)
		# if ICC::Support::Lapack module is loaded
		if ($lapack) {
			
			return(ICC::Support::Lapack::hermite($t, $self->[2][$low], $self->[2][$low + 1], $dx * $self->[3][$low], $dx * $self->[3][$low + 1]));
			
		} else {
			
			# compute Hermite coefficients
			$tc = 1 - $t;
			$h00 = (1 + 2 * $t) * $tc * $tc;
			$h01 = 1 - $h00;
			$h10 = $t * $tc * $tc;
			$h11 = -$t * $t * $tc;
			
			# interpolate value (no Lapack XS)
			return($h00 * $self->[2][$low] + $h01 * $self->[2][$low + 1] + $h10 * $dx * $self->[3][$low] + $h11 * $dx * $self->[3][$low + 1]);
			
		}
		
	} else {
		
		# use lower knot output value
		return($self->[2][$low]);
		
	}
	
}

# compute inverse value
# parameters: (ref_to_object, y-value, segment)
# there are 0 to 3 solutions in the range 0 < t < 1
# returns: (t-value_array)
sub _rev {

	# get parameters
	my ($self, $in, $low) = @_;

	# local variables
	my ($dx, $y1, $y2, $m1, $m2);
	my ($a, $b, $c, $d, $dscr, @t);
	my ($d0, $d1, $cs, $cc, @r, $ccr, $sol, $lim0, $lim1);
	
	# compute delta x-value
	$dx = $self->[1][$low + 1] - $self->[1][$low];

	# get endpoint values
	$y1 = $self->[2][$low];
	$y2 = $self->[2][$low + 1];
	$m1 = $self->[3][$low] * $dx;
	$m2 = $self->[3][$low + 1] * $dx;

	# compute coefficients of cubic equation (at^3 + bt^2 + ct + d = 0)
	$a = 2 * ($y1 - $y2) + $m1 + $m2;
	$b = -3 * ($y1 - $y2) -2 * $m1 - $m2; 
	$c = $m1;
	$d = $y1 - $in;

	# constant equation (a, b, c are zero)
	if (abs($a) < 5E-15 && abs($b) < 5E-15 && abs($c) < 5E-15) {
		
		# add solution
		push(@t, 0.5) if ($d == 0);
		
	# linear equation (a, b are zero)
	} elsif (abs($a) < 5E-15 && abs($b) < 5E-15) {
		
		# add solution
		push(@t, -$d/$c);
		
	# quadratic equation (a is zero)
	} elsif (abs($a) < 5E-15) {
		
		# compute discriminant: > 0 two real, == 0 one real, < 0 two complex
		$dscr = $c**2 - 4 * $b * $d;
		
		# if discriminant is zero
		if ($dscr == 0) {
			
			# add solution (double root)
			push(@t, -$c/(2 * $b));
			
		# if discriminant > zero
		} elsif ($dscr > 0) {
			
			# add solutions
			push(@t, -($c + sqrt($dscr))/(2 * $b));
			push(@t, -($c - sqrt($dscr))/(2 * $b));
			
		}
		
	# cubic equation
	} else {
		
		# compute discriminant: > 0 three real, == 0 one or two real, < 0 one real and two complex
		$dscr = 18 * $a * $b * $c * $d - 4 * $b**3 * $d + $b**2 * $c**2 - 4 * $a * $c**3 - 27 * $a**2 * $d**2;
		
		# compute ∆0
		$d0 = $b**2 - 3 * $a * $c;
		
		# if discriminant is zero
		if ($dscr == 0) {
			
			# if ∆0 is zero
			if ($d0 == 0) {
				
				# add solution (triple root)
				push(@t, -$b/(3 * $a));
				
			} else {
				
				# add solutions (double root and single root)
				push(@t, (9 * $a * $d - $b * $c)/(2 * $d0));
				push(@t, (4 * $a * $b * $c - 9 * $a**2 * $d - $b**3)/($a * $d0));
				
			}
			
		} else {
			
			# compute ∆1
			$d1 = 2 * $b**3 - 9 * $a * $b * $c + 27 * $a**2 * $d;
			
			# compute C (a complex number)
			$cs = sqrt($d1**2 - 4 * $d0**3);
			$cc = cbrt($d1 == $cs ? ($d1 + $cs)/2 : ($d1 - $cs)/2);
			
			# compute cube roots of 1 (three complex numbers)
			@r = root(1, 3);
			
			# for each root
			for my $i (0 .. 2) {
				
				# multiply by cube root of 1
				$ccr = $r[$i] * $cc;
				
				# compute solution (a complex number)
				$sol = ($b + $ccr + $d0/$ccr)/(-3 * $a);
				
				# add solution, if real
				push(@t, Re($sol)) if ($dscr > 0 || abs(Im($sol)) < 1E-15);
				
			}
			
		}
		
	}

	# set test limits to avoid duplicates at knots
	$lim0 = ($in == $y1) ? 1E-14 : 0;
	$lim1 = ($in == $y2) ? (1 - 1E-14) : 1;

	# return valid solutions
	return(sort {$ICC::Support::spline2::a <=> $ICC::Support::spline2::b} grep {$_ > $lim0 && $_ < $lim1} @t);

}

# set object contents from parameter hash
# parameters: (object_reference, ref_to_parameter_hash)
sub _new_from_hash {

	# get parameters
	my ($self, $hash) = @_;

	# local variables
	my ($output, $input, $range, @p);

	# if 'output_values' is defined
	if (defined($output = $hash->{'output_values'})) {
		
		# verify 'output_values' (two or more numeric values)
		(ref($output) eq 'ARRAY' && 2 <= @{$output} && (@{$output} == grep {Scalar::Util::looks_like_number($_)} @{$output})) || croak('invalid output values');
		
		# set 'output_values'
		$self->[2] = [@{$output}];
		
	} else {
		
		# use default
		$self->[2] = [0, 1];
		
	}

	# if 'input_values' is defined
	if (defined($input = $hash->{'input_values'})) {
		
		# verify 'input_values' (two or more numeric values)
		(ref($input) eq 'ARRAY' && 2 <= @{$input} && (@{$input} == grep {Scalar::Util::looks_like_number($_)} @{$input})) || croak('invalid input values');
		
		# set 'input_values'
		$self->[1] = [@{$input}];
		
	# if 'input_range' is defined
	} elsif (defined($range = $hash->{'input_range'})) {
		
		# verify 'input_range' (two unequal numeric values)
		(ref($range) eq 'ARRAY' && 2 == @{$range} && (2 == grep {Scalar::Util::looks_like_number($_)} @{$range}) && $range->[0] != $range->[1]) || croak('invalid input range');
		
		# set 'input_values' based on 'input_range'
		$self->[1] = [map {my $t = $_/$#{$self->[2]}; (1 - $t) * $range->[0] + $t * $range->[1]} (0 .. $#{$self->[2]})];
		
	} else {
		
		# use default
		$self->[1] = [map {$_/$#{$self->[2]}} 0 .. $#{$self->[2]}];
		
	}

	# sort input/output values if 'output_values' or 'input_values' or 'input_range' are defined
	_sort_values($self) if (defined($output) || defined($input) || defined($range));

	# compute knot derivatives
	_objderv($self);

	# add segment min/max y-values
	_minmax($self);

}

# sort object input/output values
# parameter: (ref_to_object)
sub _sort_values {

	# get parameter
	my $self = shift();

	# local variable
	my (@p);

	# verify same number of input and output values
	(@{$self->[1]} == @{$self->[2]}) || croak('unequal numbers of input and output values');

	# for each point
	for my $i (0 .. $#{$self->[1]}) {
		
		# copy point values
		$p[$i] = [$self->[1][$i], $self->[2][$i]];
		
	}

	# sort the points by input value
	@p = sort {$a->[0] <=> $b->[0]} @p;
	
	# for each segment
	for my $i (0 .. $#p - 1) {
		
		# error if duplicate input values
		croak('duplicate input values') if ($p[$i]->[0] == $p[$i + 1]->[0]);
		
	}

	# for each point
	for my $i (0 .. $#p) {
		
		# copy point values
		$self->[1][$i] = $p[$i]->[0];
		$self->[2][$i] = $p[$i]->[1];
		
	}
	
}

# write spline2 object to ICC profile
# note: writes an equivalent curv object
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _writeICCspline {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my ($n, $up, @table);

	# get count value (defaults to 4096, the maximum allowed in an 'mft2' tag)
	$n = $self->[0]{'curv_points'} // 4096;

	# validate number of table entries
	($n == int($n) && $n >= 2) || carp('invalid number of table entries');

	# array upper index
	$up = $n - 1;

	# for each table entry
	for my $i (0 .. $up) {
		
		# transform value
		$table[$i] = transform($self, $i/$up);
		
	}

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# write tag type signature and count
	print $fh pack('a4 x4 N', 'curv', $n);

	# write array
	print $fh pack('n*', map {$_ < 0 ? 0 : ($_ > 1 ? 65535 : $_ * 65535 + 0.5)} @table);

}

1;
