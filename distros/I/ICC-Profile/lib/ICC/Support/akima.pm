package ICC::Support::akima;

use strict;
use Carp;

our $VERSION = 0.15;

# revised 2017-03-11
#
# Copyright © 2004-2018 by William B. Birkett

# add development directory
use lib 'lib';

# inherit from Shared
use parent qw(ICC::Shared);

# enable static variables
use feature 'state';

# create new akima object
# arrays are sorted so that input values are increasing
# array structure: [[input_values_array], [output_values_array]]
# flag enables setting endpoint derivatives with least-squares fit
# parameters: ([ref_to_array, [endpoint_flag]])
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();
	
	# create empty akima object
	my $self = [
				{},		# object header
				[],		# x-values
				[],		# y-values
				[]		# derivatives
	];

	# if one or two parameters supplied
	if (@_ == 1 || @_ == 2) {
		
		# verify parameters are array references
		((ref($_[0]) eq 'ARRAY' || UNIVERSAL::isa($_[0], 'Math::Matrix')) && ref($_[0][0]) eq 'ARRAY' && ref($_[0][1]) eq 'ARRAY') || croak('parameter(s) not an array reference');
		
		# verify arrays are same length
		($#{$_[0][0]} == $#{$_[0][1]}) || croak('arrays have different lengths');
		
		# verify arrays contain two or more points
		($#{$_[0][0]} > 0) || croak('arrays must contain two or more points');
		
		# make index array
		my @ix = (0 .. $#{$_[0][0]});
		
		# sort index by x-values, in ascending order
		@ix = sort {$_[0][0][$a] <=> $_[0][0][$b]} @ix;
		
		# store x-values
		$self->[1] = [@{$_[0][0]}[@ix]];
		
		# store y-values
		$self->[2] = [@{$_[0][1]}[@ix]];
		
		# compute object derivatives
		_objderv($self, $_[1]);
		
		# add local min/max values
		_minmax($self);
		
		# compute range of y-values
		_range($self);
		
	} elsif (@_) {
		
		# error
		croak('too many parameters');
		
	}

	# bless object
	bless($self, $class);
	
	# return object reference
	return($self);

}

# write akima object to ICC profile
# note: writes an equivalent curv object
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub write_fh {

	# get tag reference
	my $self = shift();

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# write akima data to profile
	_writeICCakima($self, @_);

}

# get tag size (for writing to profile)
# note: writes an equivalent curv object
# returns: (tag_size)
sub size {
	
	# get parameters
	my ($self) = @_;
	
	# get count value (defaults to 4370)
	my $n = $self->[0]{'curv_points'} || 4370;
	
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
	
	# if input value <= x-min
	if ($in <= $self->[1][0]) {
		
		# return extrapolated value
		return($self->[2][0] + $self->[3][0] * ($in - $self->[1][0]));
		
	# if input value >= x-max
	} elsif ($in >= $self->[1][-1]) {
		
		# return extrapolated value
		return($self->[2][-1] + $self->[3][-1] * ($in - $self->[1][-1]));
		
	} else {
		
		# if x-value not within current interval
		if (! defined($low = $self->[0]{'low'}) || ($in < $self->[1][$low]) || ($in > $self->[1][$low + 1])) {
			
			# locate interval with binary search
			$self->[0]{'low'} = _binsearch($self->[1], $in);
			
		}
		
		# return interpolated value
		return(_fwd($self, $in));
		
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
	my (@sol, @sir, @low);

	# if an extrapolated solution with x < x-min
	if (($in < $self->[2][0] && $self->[3][0] > 0) || ($in > $self->[2][0] && $self->[3][0] < 0)) {
		
		# add solution
		push(@sol, $self->[1][0] - ($self->[2][0] - $in)/$self->[3][0]);
		
	}

	# locate solution interval(s) with x-min <= x <= x-max
	@low = _linsearch($self->[2], $in);

	# for each interval
	for my $i (@low) {
		
		# set interval
		$self->[0]{'low'} = $i;
		
		# add solution
		push(@sol, _rev($self, $in));
		
		# add solution in range
		push(@sir, $sol[-1]);
		
	}

	# if an extrapolated solution with x > x-max
	if (($in > $self->[2][-1] && $self->[3][-1] > 0) || ($in < $self->[2][-1] && $self->[3][-1] < 0)) {
		
		# add solution
		push(@sol, $self->[1][-1] - ($self->[2][-1] - $in)/$self->[3][-1]);
		
	}

	# return result (array or first solution in range, if possible)
	return(wantarray ? @sol : defined($sir[0]) ? $sir[0] : $sol[0]);

}

# compute curve derivative
# parameters: (input_value)
# returns: (derivative_value)
sub derivative {
	
	# get parameters
	my ($self, $in) = @_;
	
	# local variable
	my ($low);
	
	# if input value <= x-min
	if ($in <= $self->[1][0]) {
		
		# return endpoint derivative
		return($self->[3][0]);
		
	# if input value >= x-max
	} elsif ($in >= $self->[1][-1]) {
		
		# return endpoint derivative
		return($self->[3][-1]);
		
	} else {
		
		# if x-value not within current interval
		if (! defined($low = $self->[0]{'low'}) || ($in < $self->[1][$low]) || ($in > $self->[1][$low + 1])) {
			
			# locate interval with binary search
			$self->[0]{'low'} = _binsearch($self->[1], $in);
			
		}
		
		# return derivative
		return(_derv($self, $in));
		
	}
	
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
			
			# set header to new hash
			$self->[0] = shift();
			
		} else {
			
			# error
			croak('parameter must be a hash reference');
			
		}
		
	}
	
	# return reference
	return($self->[0]);
	
}

# get/set array reference
# array contains x-values, y-values and derivatives
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
		((3 == @{$_[0]}) && (3 == grep {ref() eq 'ARRAY'} @{$_[0]})) || croak('invalid array contents');
		
		# store x-values
		$self->[1] = [@{$_[0][0]}];
		
		# store y-values
		$self->[2] = [@{$_[0][1]}];
		
		# store derivatives
		$self->[3] = [@{$_[0][2]}];
		
	} elsif (@_) {
		
		# error
		croak('too many parameters');
		
	}
	
	# return array reference
	return([[@{$self->[1]}], [@{$self->[2]}], [@{$self->[3]}]]);

}

# check if monotonic
# computes number of min/max points (0 if monotonic)
# parameters: ()
# returns: (number)
sub monotonic {
	
	# get object reference
	my $self = shift();
	
	# local variables
	my ($flag);
	
	# init flag
	$flag = 0;
	
	# for each interval
	for my $i (0 .. ($#{$self->[1]} - 1)) {
		
		# set interval
		$self->[0]{'low'} = $i;
		
		# increment flag if a min/max point
		$flag++ if ($self->[3][$i] == 0 && _derv2($self, 0) != 0);
		
	}
	
	# increment flag if a min/max point (last knot)
	$flag++ if ($self->[3][-1] == 0 && _derv2($self, 1) != 0);
	
	# return
	return($flag);
	
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

# normalize transform
# adjusts object values linearly
# so that min/max values are 0/1
# parameter: () - adjust both x-values and y-values
# parameter: (0) - adjust x-values only
# parameter: (1) - adjust y-values only
sub normalize {
	
	# get object reference
	my $self = shift();
	
	# local variables
	my ($flag, $cx0, $cx1, $cy0, $cy1, $dsf);
	
	# if no parameters
	if (@_ == 0) {
		
		# set flag (adjust x-values and y-values)
		$flag = 3;
		
	} elsif (@_ == 1) {
		
		# if valid parameter
		if ($_[0] == 0 || $_[0] == 1) {
			
			# set flag
			$flag = shift() + 1;
			
		} else {
			
			# error
			croak('invalid parameter');
			
		}
		
	} else {
		
		# error
		croak('too many parameters')
		
	}
	
	# initialize scale factors
	$cx1 = $cy1 = 1;
	
	# if x-values adjusted
	if ($flag & 0x01) {
		
		# compute scale factor
		$cx1 = $self->[1][-1] - $self->[1][0];
		
		# compute offset
		$cx0 = $self->[1][0]/$cx1;
		
		# for each x-value
		for my $i (0 .. $#{$self->[1]}) {
			
			# normalize
			$self->[1][$i] = $self->[1][$i]/$cx1 - $cx0;
			
		}
		
	}
	
	# if y-values adjusted
	if ($flag & 0x02) {
		
		# compute scaling coefficient
		$cy1 = abs($self->[2][-1] - $self->[2][0]);
		
		# compute offset
		$cy0 = ($self->[2][-1] < $self->[2][0] ? $self->[2][-1] : $self->[2][0])/$cy1;
		
		# for each y-value
		for my $i (0 .. $#{$self->[2]}) {
			
			# normalize
			$self->[2][$i] = $self->[2][$i]/$cy1 - $cy0;
			
		}
		
		# set range of y-values
		$self->[0]{'ymin'} = $self->[0]{'ymin'}/$cy1 - $cy0;
		$self->[0]{'ymax'} = $self->[0]{'ymax'}/$cy1 - $cy0;
		
	}
	
	# compute derivative scale factor
	$dsf = $cx1/$cy1;
	
	# for each derivative value
	for my $i (0 .. $#{$self->[3]}) {
		
		# normalize
		$self->[3][$i] *= $dsf;
		
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
	
	# unimplemented function error
	croak('unimplemented function');
	
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
		return($self->derivative($in));
		
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
		return(scalar($self->inverse($in)));
		
	} else {
		
		# return transform
		return($self->transform($in));
		
	}
	
}

# compute object derivatives
# for spline knots using Akima's method
# parameters: (ref_to_object, endpoint_flag)
sub _objderv {

	# get parameters
	my ($self, $flag) = @_;
	
	# local variables
	my ($p, @m, $d, $d1, $d2, $dm);

	# get array length
	$p = $#{$self->[1]};
	
	# compute segment slopes
	for my $i (0 .. ($p - 1)) {
	
		# compute and test denominator
		($d = $self->[1][$i] - $self->[1][$i + 1]) || croak('zero x-value interval in spline data');
		
		# now, compute slope
		$m[$i + 2] = ($self->[2][$i] - $self->[2][$i + 1])/$d;
	
	}

	# if 2 points
	if ($p == 1) {
		
		# linear slopes
		$m[0] = $m[1] = $m[3] = $m[4] = $m[2];
		
	# if 3 or more points
	} else {
		
		# quadratic slopes
		$m[1] = 2 * $m[2] - $m[3];
		$m[0] = 2 * $m[1] - $m[2];
		$m[$p + 2] = 2 * $m[$p + 1] - $m[$p];
		$m[$p + 3] = 2 * $m[$p + 2] - $m[$p + 1];
		
	}
	
	# compute Akima derivative
	for my $i (0 .. $p) {
	
		# if denominator not 0
		if ($d = abs($m[$i + 3] - $m[$i + 2]) + abs($m[$i + 1] - $m[$i])) {
		
			# use Akima estimate of slope
			$self->[3][$i] = (abs($m[$i + 3] - $m[$i + 2]) * $m[$i + 1] + abs($m[$i + 1] - $m[$i]) * $m[$i + 2])/$d;
			
		} else {
			
			# otherwise, use average slope of adjoining segments
			$self->[3][$i] = ($m[$i + 1] + $m[$i + 2])/2;
			
		}
		
	}
	
	# if four or more points and flag set
	if ($p >= 3 && $flag) {
		
		# compute endpoint derivatives using weighted least squares
		$self->[3][0] = _endpoint($self, 0);
		$self->[3][-1] = _endpoint($self, -1);
		
	}
	
}

# determine derivative of endpoint
# using weighted least squares method
# endpoint index is either 0 or -1
# parameters: (ref_to_object, endpoint_index)
# returns: (derivative)
sub _endpoint {
	
	# get parameters
	my ($self, $ix) = @_;
	
	# local variables
	my ($x, $y, $v, $r, $w, $info, $c);
	
	# get x and y references
	$x = $self->[1];
	$y = $self->[2];
	
	# for each data point
	for my $i (0 .. $#{$x}) {
		
		# for each cubic coefficient
		for my $j (0 .. 3) {
			
			# add element to Vandermonde matrix
			$v->[$i][$j] = $x->[$i]**$j;
			
		}
		
		# add element to residual matrix
		$r->[$i][0] = $y->[$i];
		
		# add element to weight matrix
		$w->[$i][0] = exp(-5 * abs(($x->[$i] - $x->[$ix])/($x->[0] - $x->[-1])));
		
	}
	
	# solve normal equations
	($info, $c) = ICC::Support::Lapack::normal($v, $r, $w);
	
	# return derivative
	return($c->[1][0] + 2 * $c->[2][0] * $x->[$ix] + 3 * $c->[3][0] * $x->[$ix]**2);
	
}

# compute range of y-values
# parameters: (ref_to_object)
sub _range {
	
	# get object reference
	my $self = shift();
	
	# local variables
	my ($min, $max);
	
	# initialize min/max values
	$min = $max = $self->[2][0];
	
	# for each y-value
	for my $i (1 .. $#{$self->[2]}) {
		
		# update min and max
		$min = $self->[2][$i] if ($min > $self->[2][$i]);
		$max = $self->[2][$i] if ($max < $self->[2][$i]);
		
	}
	
	# save result
	$self->[0]{'ymin'} = $min;
	$self->[0]{'ymax'} = $max;
	
}

# add local min/max values
# parameters: (ref_to_object)
sub _minmax {

	# get object reference
	my $self = shift();

	# local variables
	my (@s, @ix);

	# for each interval
	for my $i (0 .. ($#{$self->[1]} - 1)) {
	
		# if local min/max values
		if (@s = _local($self, $i)) {
		
			# set lower index
			$self->[0]{'low'} = $i;
		
			# add to x-value array
			push(@{$self->[1]}, @s);
			
			# add to y-value array
			push(@{$self->[2]}, map {_fwd($self, $_)} @s);
		
			# add to derivative array
			push(@{$self->[3]}, (0) x @s);
		
		}
	
	}

	# make index array
	@ix = (0 .. $#{$self->[1]});

	# sort index by x-values, in ascending order
	@ix = sort {$self->[1][$a] <=> $self->[1][$b]} @ix;

	# reorder x-values
	$self->[1] = [@{$self->[1]}[@ix]];

	# reorder y-values
	$self->[2] = [@{$self->[2]}[@ix]];

	# reorder derivatives
	$self->[3] = [@{$self->[3]}[@ix]];

}

# compute local min/max value(s)
# note: includes inflection points
# parameters: (ref_to_object, lower_index)
# returns: (value_array)
sub _local {

	# get parameters
	my ($self, $i) = @_;

	# local variables
	my ($x1, $x2, $y1, $y2, $m1, $m2);
	my ($dy, $dx, $t, $a, $b, $c, $d, @s);

	# get endpoint values
	$x1 = $self->[1][$i];
	$x2 = $self->[1][$i + 1];
	$y1 = $self->[2][$i];
	$y2 = $self->[2][$i + 1];
	$m1 = $self->[3][$i];
	$m2 = $self->[3][$i + 1];

	# compute intermediate values
	($dx = $x2 - $x1) || croak('zero interval in spline data');
	$dy = $y1 - $y2;
	$a = 6 * $dy/$dx + 3 * ($m1 + $m2);
	$b = -6 * $dy/$dx - 2 * $m2 - 4 * $m1;
	$c = $m1;
	
	# return if constant
	return() if ($a == 0 && $b == 0);
	
	# if linear equation
	if ($a == 0) {
		
		# compute solution
		$t = -$c/$b;
		
		# push if solution within interval (but not endpoints)
		push(@s, $t * $dx + $x1) if ($t > 0 && $t < 1);
		
	# if quadratic equation
	} else {
		
		# compute discriminant
		$d = $b**2 - 4 * $a * $c;
		
		# return if complex solutions
		return() if ($d < 0);
		
		# compute first solution
		$t = (-$b + sqrt($d))/(2 * $a);
		
		# push if solution within interval (but not endpoints)
		push(@s, $t * $dx + $x1) if ($t > 0 && $t < 1);
		
		# if discriminant > 0 (two real solutions)
		if ($d > 0) {
			
			# compute second solution
			$t = (-$b - sqrt($d))/(2 * $a);
			
			# push if solution within interval (but not endpoints)
			push(@s, $t * $dx + $x1) if ($t > 0 && $t < 1);
			
		}
		
	}
	
	# return solution(s)
	return (@s);
	
}

# compute second derivative
# parameters: (ref_to_object, x-value)
# returns: (second_derivative)
sub _derv2 {

	# get parameters
	my ($self, $in) = @_;

	# local variables
	my ($i, $x1, $x2, $y1, $y2, $m1, $m2);
	my ($dy, $dx, $t, $h1, $h2, $h3);

	# get lower index
	$i = $self->[0]{'low'};

	# get endpoint values
	$x1 = $self->[1][$i];
	$x2 = $self->[1][$i + 1];
	$y1 = $self->[2][$i];
	$y2 = $self->[2][$i + 1];
	$m1 = $self->[3][$i];
	$m2 = $self->[3][$i + 1];

	# compute intermediate values
	($dx = $x2 - $x1) || croak('zero interval in spline data');
	$dy = $y1 - $y2;
	$t = ($in - $x1)/$dx;
	$h1 = 12 * $t - 6;
	$h2 = 6 * $t - 2;
	$h3 = 6 * $t - 4;

	# return second derivative
	return (($h1 * $dy/$dx + $h2 * $m2 + $h3 * $m1)/$dx);

}

# compute derivative
# parameters: (ref_to_object, x-value)
# returns: (derivative)
sub _derv {

	# get parameters
	my ($self, $in) = @_;

	# local variables
	my ($i, $x1, $x2, $y1, $y2, $m1, $m2);
	my ($dy, $dx, $t, $h1, $h2, $h3);

	# get lower index
	$i = $self->[0]{'low'};

	# get endpoint values
	$x1 = $self->[1][$i];
	$x2 = $self->[1][$i + 1];
	$y1 = $self->[2][$i];
	$y2 = $self->[2][$i + 1];
	$m1 = $self->[3][$i];
	$m2 = $self->[3][$i + 1];

	# compute intermediate values
	($dx = $x2 - $x1) || croak('zero interval in spline data');
	$dy = $y1 - $y2;
	$t = ($in - $x1)/$dx;
	$h1 = 6 * $t * ($t - 1);
	$h2 = $t * (3 * $t - 2);
	$h3 = $h2 - 2 * $t + 1;

	# return derivative
	return ($h1 * $dy/$dx + $h2 * $m2 + $h3 * $m1);

}

# compute transform value
# parameters: (ref_to_object, x-value)
# returns: (y-value)
sub _fwd {

	# get parameters
	my ($self, $in) = @_;

	# local variables
	my ($i, $x0, $x1, $y0, $y1, $m0, $m1);
	my ($dx, $t, $tc, $h00, $h01, $h10, $h11);

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# get lower index
	$i = $self->[0]{'low'};

	# get endpoint values
	$x0 = $self->[1][$i];
	$x1 = $self->[1][$i + 1];
	$y0 = $self->[2][$i];
	$y1 = $self->[2][$i + 1];
	$m0 = $self->[3][$i];
	$m1 = $self->[3][$i + 1];

	# compute intermediate values
	($dx = $x1 - $x0) || croak('zero interval in spline data');
	$t = ($in - $x0)/$dx;

	# if ratio is non-zero
	if ($t) {
		
		# if ICC::Support::Lapack module is loaded
		if ($lapack) {
			
			# return interpolated value
			return(ICC::Support::Lapack::hermite($t, $y0, $y1, $m0 * $dx, $m1 * $dx));
			
		} else {
			
			# compute Hermite coefficients
			$tc = 1 - $t;
			$h00 = (1 + 2 * $t) * $tc * $tc;
			$h01 = 1 - $h00;
			$h10 = $t * $tc * $tc;
			$h11 = -$t * $t * $tc;
			
			# return interpolated value
			return($h00 * $x0 + $h01 * $x1 + $h10 * $m0 * $dx + $h11 * $m1 * $dx);
			
		}
		
	} else {
		
		# use lower source value
		return($y0);
		
	}
	
}

# compute inverse value
# parameters: (ref_to_object, y-value)
# returns: (x-value)
sub _rev {

	# get parameters
	my ($self, $in) = @_;

	# local variables
	my ($i, $x, $y, $dydx, $dx);

	# get lower index
	$i = $self->[0]{'low'};
	
	# if input is lower y-value
	if ($self->[2][$i] == $in) {
		
		# return lower x-value
		return($self->[1][$i]);
		
	} else {
		
		# set initial x-value
		$x = ($self->[1][$i] + $self->[1][$i + 1])/2;
		
		# loop
		for (0 .. 10) {
			
			# get y-value
			$y = _fwd($self, $x);
			
			# get derivative
			$dydx = _derv($self, $x);
			
			# compute x-delta
			$dx = ($y - $in)/($dydx ? $dydx : rand);
			
			# adjust x
			$x -= $dx;
			
			# quit if error < limit
			last if (abs($dx) < 1E-12 * ($self->[1][-1] - $self->[1][0]));
			
		}
		
	}
	
	# return
	return($x);

}

# binary search
# finds the array interval containing the value
# note: assumes array values are in ascending order
# parameters: (ref_to_array, value)
# returns: (lower_index)
sub _binsearch {

	# get parameters
	my ($vref, $v) = @_;

	# local variables
	my ($k, $klo, $khi);

	# set low and high indices
	$klo = 0;
	$khi = $#{$vref};

	# repeat until interval is found
	while (($khi - $klo) > 1) {
		
		# compute the midpoint
		$k = int(($khi + $klo)/2);
		
		# if midpoint value > value
		if ($vref->[$k] > $v) {
			
			# set high index to midpoint
			$khi = $k;
			
		} else {
			
			# set low index to midpoint
			$klo = $k;
			
		}
	
	}

	# return low index
	return ($klo);

}

# linear search
# finds the array interval(s) containing the value
# parameters: (ref_to_array, value)
# returns: (lower_index_array)
sub _linsearch {

	# get parameters
	my ($vref, $v) = @_;

	# local variables
	my (@low);

	# for each point
	for my $i (0 .. $#{$vref}) {
		
		# if value equals point
		if ($v == $vref->[$i]) {
			
			# push index
			push(@low, $i);
			
		# if value inside interval (not including end points)
		} elsif ($i < $#{$vref} && (($v > $vref->[$i]) ^ ($v > $vref->[$i + 1])) && (($v < $vref->[$i]) ^ ($v < $vref->[$i + 1]))) {
			
			# push index
			push(@low, $i);
			
		}
		
	}

	# return
	return(@low);

}

# write akima object to ICC profile
# note: writes an equivalent curv object
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _writeICCakima {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my ($n, $up, @table);

	# get count value (defaults to 4096, the maximum allowed in an 'mft2' tag)
	$n = defined($self->[0]{'curv_points'}) ? $self->[0]{'curv_points'} : 4096;

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