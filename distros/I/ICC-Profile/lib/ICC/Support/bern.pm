package ICC::Support::bern;

use strict;
use Carp;

our $VERSION = 0.32;

# revised 2016-06-18
#
# Copyright © 2004-2018 by William B. Birkett

# add development directory
use lib 'lib';

# inherit from Shared
use parent qw(ICC::Shared);

# enable static variables
use feature 'state';

# create new bern object
# array structure: [[input_parameter_array], [output_parameter_array]]
# parameters: ([ref_to_array])
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();

	# create empty bern object
	my $self = [
				{},		# object header
				[],		# parameter array
				[],		# min/max x-values
				[]		# min/max y-values
	];

	# if one parameter supplied
	if (@_ == 1) {
		
		# verify parameter is an array reference
		(ref($_[0]) eq 'ARRAY') || croak('parameter not an array reference');
		
		# build parameter array
		_pars($self, @_);
		
		# check for min/max values
		roots($self);
		
	} elsif (@_) {
		
		# error
		croak('too many parameters');
		
	}

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# fit bern object to data
# uses LAPACK dgels function to perform a least-squares fit
# the parameter array defines the object structure as with the 'new' method
# the parameters to be fitted have the value 'undef' and must all be within the
# output side of the parameter array, e.g. [[0, 100], [undef, undef, undef, undef]]
# the input and output arrays contain the data to be fitted and are simple vectors
# parameters: (ref_to_parameter_array, ref_to_input_array, ref_to_output_array)
# returns: (dgels_info_value)
sub fit {

	# get parameters
	my ($self, $par, $in, $out) = @_;

	# local variables
	my ($m, $n, $d, $t);
	my (@so, $outz, $bern, $nrhs, $info);

	# verify parameter array structure
	(ref($par) eq 'ARRAY' && @{$par} == 2 && ref($par->[0]) eq 'ARRAY' && ref($par->[1]) eq 'ARRAY') || croak('invalid parameter array structure');

	# get number of input parameters
	$n = @{$par->[0]};

	# verify input parameters
	($n != 1 && $n <= 11 && $n == grep {defined($_) && ! ref()} @{$par->[0]}) || croak('invalid input parameters');

	# get number of output parameters
	$n = @{$par->[1]};

	# verify output parameters
	($n != 1 && $n <= 11 && $n == grep {! ref()} @{$par->[1]}) || croak('invalid output parameters');

	# verify input array
	(ref($in) eq 'ARRAY' && @{$in} == grep {! ref()} @{$in}) || croak('invalid input array');

	# verify output array
	(ref($out) eq 'ARRAY' && @{$out} == grep {! ref()} @{$out}) || croak('invalid output array');

	# for each output parameter
	for my $i (0 .. $#{$par->[1]}) {
		
		# if parameter is undefined
		if (! defined($par->[1][$i])) {
			
			# push index
			push(@so, $i);
			
			# set value to 0
			$par->[1][$i] = 0;
			
		}
		
	}

	# copy parameters to object
	$self->[1][0] = [@{$par->[0]}];
	$self->[1][1] = [@{$par->[1]}];

	# check for min/max values
	roots($self);

	# get degree
	$d = $#{$self->[1][1]};

	# for each sample
	for my $i (0 .. $#{$in}) {
		
		# compute output difference
		$outz->[$i] = [$out->[$i] - $self->transform($in->[$i])];
		
		# get intermediate value
		$t = _rev($self->[1][0], $self->[2][0], $self->[3][0], $in->[$i]);
		
		# compute Bernstein values for undefined parameters
		$bern->[$i] = [@{_bernstein($d, $t)}[@so]];
		
	}

	# get array sizes
	$m = @{$bern};
	$n = @{$bern->[0]};
	$nrhs = @{$outz->[0]};

	# fit the data
	$info = ICC::Support::Lapack::dgels('N', $m, $n, $nrhs, $bern, $m, $outz, $m);

	# if fit successful
	if ($info == 0) {
		
		# for each undefined parameter
		for my $i (0 .. $#so) {
			
			# copy parameter value
			$self->[1][1][$so[$i]] = $outz->[$i][0];
			
		}
		
		# calculate min/max values
		roots($self);
		
	}

	# return info value
	return($info);

}

# write bern object to ICC profile
# note: writes an equivalent curv object
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub write_fh {

	# get tag reference
	my $self = shift();

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# write bern data to profile
	_writeICCbern($self, @_);

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

	# insert direction flag
	unshift(@_, 0);

	# call reverse transform, if not identity
	&_revs if (@{$_[1]->[1][0]});

	# call forward transform, if not identity
	&_fwds if (@{$_[1]->[1][1]});

	# return transformed value
	return(pop());

}

# compute inverse curve function
# parameters: (input_value)
# returns: (output_value)
sub inverse {

	# insert direction flag
	unshift(@_, 1);

	# call reverse transform, if not identity
	&_revs if (@{$_[1]->[1][1]});

	# call forward transform, if not identity
	&_fwds if (@{$_[1]->[1][0]});

	# return transformed value
	return(pop());

}

# compute curve derivative
# parameters: (input_value)
# returns: (derivative_value)
sub derivative {

	# get parameters
	my ($self, $in) = @_;

	# return combined forward derivative
	return(_derivative($self, 0, $in));

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
# parameters: ([ref_to_array])
# returns: (ref_to_array)
sub array {

	# get object reference
	my $self = shift();

	# if one parameter supplied
	if (@_ == 1) {
		
		# verify parameter is an array reference
		(ref($_[0]) eq 'ARRAY') || croak('parameter not an array reference');
		
		# build parameter array
		_pars($self, @_);
		
		# check for min/max values
		roots($self);
		
	} elsif (@_) {
		
		# error
		croak('too many parameters');
		
	}

	# return array reference
	return($self->[1]);

}

# find min/max values within the interval (0 - 1)
# used by '_rev' to determine solution regions
# note: should be called after modifying Bernstein parameters
# parameters: (object_reference)
sub roots {

	# get parameter
	my $self = shift();

	# local variables
	my (@x, $t, $d);
	my ($par, $fwd, $fwd2, $drv);

	# for input and output curves
	for my $i (0 .. 1) {
		
		# initialize x-values array
		@x = ();
		
		# get ref to Bernstein parameters
		$par = $self->[1][$i];
		
		# if number of parameters > 2
		if (@{$par} > 2) {
			
			# compute forward differences
			$fwd = [map {$par->[$_] - $par->[$_ - 1]} (1 .. $#{$par})];
			
			# if forward differences have different signs (+/-)
			if (grep {($fwd->[0] < 0) ^ ($fwd->[$_] < 0)} (1 .. $#{$fwd})) {
				
				# compute second forward differences
				$fwd2 = [map {$fwd->[$_] - $fwd->[$_ - 1]} (1 .. $#{$fwd})];
				
				# compute derivative values over range (0 - 1)
				$drv = [map {$#{$par} * _fwd($fwd, $_/(4 * $#{$par}))} (0 .. 4 * $#{$par})];
				
				# for each pair of derivatives
				for my $j (1 .. $#{$drv}) {
					
					# if derivatives have different signs (+/-)
					if (($drv->[$j - 1] < 0) ^ ($drv->[$j] < 0)) {
						
						# estimate root from the derivative values
						$t = ($j * $drv->[$j - 1] - ($j - 1) * $drv->[$j])/(($drv->[$j - 1] - $drv->[$j]) * 4 * $#{$par});
						
						# loop until derivative approaches 0
						while (abs($d = $#{$par} * _fwd($fwd, $t)) > 1E-9) {
							
							# adjust root using Newton's method
							$t -= $d/($#{$fwd} * $#{$par} * _fwd($fwd2, $t));
							
						}
						
						# push root on x-value array
						push(@x, $t) if ($t > 0 && $t < 1);
						
					}
					
				}
				
			}
			
		}
		
		# save root x-values
		$self->[2][$i] = [@x];
		
		# save root y-values
		$self->[3][$i] = [map {_fwd($par, $_)} @x];
		
		# warn if root values were found
		print "curve $i is not monotonic\n" if (@x > 0);
		
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

# normalize transform
# adjusts Bernstein coefficients linearly
# so that end coefficients are either 0 or 1
# parameter: () - adjust both input and output
# parameter: (0) - adjust input only
# parameter: (1) - adjust output only
sub normalize {

	# get object reference
	my $self = shift();

	# local variables
	my ($c0, $c1);

	# if no parameters
	if (@_ == 0) {
		
		# set for both input and output
		@_ = (0, 1);
		
	# if more than one parameter
	} elsif (@_ > 1) {
		
		# error
		croak('too many parameters')
		
	# if parameter not 0 or 1
	} elsif (! ($_[0] == 0 || $_[0] == 1)) {
		
		# error
		croak('invalid parameter');
		
	}
	
	# for input/output
	for my $i (@_) {
		
		# skip empty coefficient array
		next if (@{$self->[1][$i]} == 0);
		
		# get LH coefficient
		$c0 = $self->[1][$i][0];
		
		# get RH coefficient
		$c1 = $self->[1][$i][-1];
		
		# if LH < RH
		if ($c0 < $c1) {
			
			# map coefficients
			@{$self->[1][$i]} = map {($_ - $c0)/($c1 - $c0)} @{$self->[1][$i]};
			
		# if LH > RH
		} elsif ($c0 > $c1) {
			
			# map coefficients
			@{$self->[1][$i]} = map {($_ - $c1)/($c0 - $c1)} @{$self->[1][$i]};
			
		# LH = RH
		} else {
			
			# error
			croak('LH and RH coefficients are equal');
			
		}
		
	}

	# re-calculate min/max values
	roots($self);

}

# print object contents to string
# format is an array structure
# parameter: ([format])
# returns: (string)
sub sdump {

	# get parameters
	my ($self, $p) = @_;

	# local variables
	my ($s, $fmt, $fmt2);

	# resolve parameter to an array reference
	$p = defined($p) ? ref($p) eq 'ARRAY' ? $p : [$p] : [];

	# get format string
	$fmt = defined($p->[0]) && ! ref($p->[0]) ? $p->[0] : 'undef';

	# set string to object ID
	$s = sprintf("'%s' object, (0x%x)\n", ref($self), $self);

	# if input_parameter_array defined
	if (defined($self->[1][0])) {
		
		# set format
		$fmt2 = join(', ', ('%.3f') x @{$self->[1][0]});
		
		# append parameter string
		$s .= sprintf("  input parameters  [$fmt2]\n", @{$self->[1][0]});
		
	}

	# if output_parameter_array defined
	if (defined($self->[1][1])) {
		
		# set format
		$fmt2 = join(', ', ('%.3f') x @{$self->[1][1]});
		
		# append parameter string
		$s .= sprintf("  output parameters [$fmt2]\n", @{$self->[1][1]});
		
	}

	# return
	return($s);

}

# forward transform
# nominal domain (0 - 1)
# parameters: (direction, object_reference, input_value)
# returns: (direction, object_reference, output_value)
sub _fwds {

	# get input value
	my $in = pop();

	# get parameter array
	my $par = $_[1]->[1][1 - $_[0]];

	# if one parameter
	if (@{$par} == 1) {
		
		# return constant
		push(@_, $par->[0]);
		
	# two parameters
	} elsif (@{$par} == 2) {
		
		# return linear interpolated value
		push(@_, (1 - $in) * $par->[0] + $in * $par->[1]);
		
	# three or more parameters
	} else {
		
		# check if ICC::Support::Lapack module is loaded
		state $lapack = defined($INC{'ICC/Support/Lapack.pm'});
		
		# if input < 0
		if ($in < 0) {
			
			# return extrapolated value
			push(@_, $par->[0] + $in * _drv($par, 0));
			
		# if input > 1
		} elsif ($in > 1) {
			
			# return extrapolated value
			push(@_, $par->[-1] + ($in - 1) * _drv($par, 1));
			
		} else {
			
			# if Lapack module loaded
			if ($lapack) {
				
				# return Bernstein interpolated value
				push(@_, ICC::Support::Lapack::bernstein($in, $par));
				
			} else {
				
				# return Bernstein interpolated value
				push(@_, ICC::Shared::dotProduct(_bernstein($#{$par}, $in), $par));
				
			}
			
		}
		
	}
	
}

# reverse transform
# nominal range (0 - 1)
# parameters: (direction, object_reference, input_value)
# returns: (direction, object_reference, output_value)
sub _revs {

	# get input value
	my $in = pop();

	# get parameter array
	my $par = $_[1]->[1][$_[0]];

	# local variables
	my ($xminmax, $yminmax, @xs, @ys, @sol, $ext, $xval, $yval, $slope, $xi, $loop);

	# one parameter
	if (@{$par} == 1) {
		
		# warn if input not equal to constant
		($in == $par->[0]) || print "input value not equal to curve parameter (constant)\n";
		
		# restore input value
		push(@_, $in);
		
	# two parameters
	} elsif (@{$par} == 2) {
		
		# return linear interpolated value
		push(@_, ($in - $par->[0])/($par->[1] - $par->[0]));
		
	# three or more parameters
	} else {
		
		$xminmax = $_[1]->[2][$_[0]];
		$yminmax = $_[1]->[3][$_[0]];
		
		# setup segment arrays
		@xs = (0, @{$xminmax}, 1);
		@ys = ($par->[0], @{$yminmax}, $par->[-1]);
		
		# if slope(0) not 0
		if ($slope = _drv($par, 0)) {
			
			# compute extrapolation from 0
			$ext = ($in - $par->[0])/$slope;
			
			# save if less than 0
			push(@sol, $ext) if ($ext < 0);
			
		}
		
		# test first y-value
		push(@sol, $xs[0]) if ($ys[0] == $in);
		
		# for each array segment
		for my $i (1 .. $#xs) {
			
			# if input value falls within segment
			if (($in > $ys[$i - 1] && $in < $ys[$i]) || ($in < $ys[$i - 1] && $in > $ys[$i])) {
				
				# compute initial x-value, treating segment as linear
				$xval = ($in - $ys[$i - 1]) * ($xs[$i] - $xs[$i - 1])/($ys[$i] - $ys[$i - 1]) + $xs[$i - 1];
				
				# compute initial y-value
				$yval = _fwd($par, $xval);
				
				# init loop counter
				$loop = 0;
				
				# solution loop
				while (abs($in - $yval) > 1E-9 && $loop++ < 100) {
					
					# if slope not 0
					if ($slope = _drv($par, $xval)) {
						
						# adjust x-value
						$xval += ($in - $yval)/$slope;
						
						# if x-value out of range
						if ($xval < 0 || $xval > 1) {
							
							# get a random number
							$xi = rand();
							
							# reset x-value within segment
							$xval = $xs[$i] * $xi + $xs[$i - 1] * (1 - $xi);
							
						}
						
					} else {
						
						# get a random number
						$xi = rand();
						
						# reset x-value within segment
						$xval = $xs[$i] * $xi + $xs[$i - 1] * (1 - $xi);
						
					}
					
					# compute new y-value
					$yval = _fwd($par, $xval);
					
				}
				
				# print warning if failed to converge
				printf("'_revs' function of 'bern' object failed to converge with input of %.2f\n", $in) if ($loop > 100);
				
				# save result
				push(@sol, $xval);
				
			}
			
			# test current y-value
			push(@sol, $xs[$i]) if ($ys[$i] == $in);
			
		}
		
		# if slope(1) not 0
		if ($slope = _drv($par, 1)) {
			
			# compute extrapolation from 1
			$ext = ($in - $par->[-1])/$slope + 1;
			
			# save if greater than 1
			push(@sol, $ext) if ($ext > 1);
			
		}
		
		# warn if multiple values
		(@sol == 1) || print "multiple transform values\n";
		
		# return the first solution
		push(@_, $sol[0]);
		
	}
	
}

# compute parametric partial derivatives
# direction: 0 - normal, 1 - inverse
# parameters: (object_reference, direction, input_value)
# returns: (partial_derivative_array)
sub _parametric {

	# get parameters
	my ($self, $dir, $in) = @_;

	# local variables
	my ($p0, $p1, $p2, $p3);
	my (@t, $t, $di, $do, $bfi, $bfo, @pj);

	# verify input is a scalar
	(! ref($in)) || croak('invalid transform input');

	# get parameter arrays
	$p0 = $self->[1][$dir];
	$p1 = $self->[2][$dir];
	$p2 = $self->[3][$dir];
	$p3 = $self->[1][1 - $dir];

	# compute intermediate value(s)
	@t = _rev($p0, $p1, $p2, $in);

	# warn if multiple values
	(@t == 1) || print "multiple transform values\n";

	# use first value
	$t = $t[0];

	# compute input derivative
	$di = _drv($p0, $t);

	# compute input Bernstein polynomials
	$bfi = @{$p0} > 0 ? _bernstein($#{$p0}, $t) : undef();

	# compute output derivative
	$do = _drv($p3, $t);

	# compute output Bernstein polynomials
	$bfo = @{$p3} > 0 ? _bernstein($#{$p3}, $t) : undef();

	# initialize array
	@pj = ();

	# if there are input parameters
	if (defined($bfi)) {
		
		# for each parameter
		for my $i (0 .. $#{$bfi}) {
			
			# verify non-zero input derivative
			($di) || croak('infinite Jacobian element');
			
			# compute partial derivative
			$pj[$i] = -$bfi->[$i] * $do/$di;
			
		}
		
	}

	# add output parameters (if any)
	push(@pj, @{$bfo}) if (defined($bfo));

	# return array of partial derivatives
	return(@pj);

}

# combined derivative
# nominal domain (0 - 1)
# parameters: (object_reference, direction, input_value)
# returns: (derivative_value)
sub _derivative {

	# get parameters
	my ($self, $dir, $in) = @_;

	# local variables
	my ($p0, $p1, $p2, $p3, @t);
	my ($di, $do);

	# verify input is a scalar
	(! ref($in)) || croak('invalid transform input');

	# get parameter arrays
	$p0 = $self->[1][$dir];
	$p1 = $self->[2][$dir];
	$p2 = $self->[3][$dir];
	$p3 = $self->[1][1 - $dir];

	# compute intermediate value(s)
	@t = _rev($p0, $p1, $p2, $in);

	# warn if multiple values
	(@t == 1) || print "multiple transform values\n";

	# compute input derivative (using first value)
	($di = _drv($p0, $t[0])) || croak('infinite derivative value');

	# compute output derivative (using first value)
	$do = _drv($p3, $t[0]);

	# return combined derivative
	return($do/$di);

}

# combined transform
# nominal domain (0 - 1)
# parameters: (object_reference, direction, input_value)
# returns: (output_value)
sub _transform {

	# get parameters
	my ($self, $dir, $in) = @_;

	# local variables
	my ($p0, $p1, $p2, $p3, @t);

	# verify input is a scalar
	(! ref($in)) || croak('invalid transform input');

	# get parameter arrays
	$p0 = $self->[1][$dir];
	$p1 = $self->[2][$dir];
	$p2 = $self->[3][$dir];
	$p3 = $self->[1][1 - $dir];

	# compute intermediate value(s)
	@t = _rev($p0, $p1, $p2, $in);

	# warn if multiple values
	(@t == 1) || carp('multiple transform values');

	# return first output value
	return(_fwd($p3, $t[0]));

}

# direct forward transform
# nominal domain (0 - 1)
# parameters: (parameter_array_reference, input_value)
# returns: (output_value)
sub _fwd {

	# get parameters
	my ($par, $in) = @_;

	# if no parameters
	if (@{$par} == 0) {
		
		# return input
		return($in);
		
	# one parameter
	} elsif (@{$par} == 1) {
		
		# return constant
		return($par->[0]);
		
	# two parameters
	} elsif (@{$par} == 2) {
		
		# return linear interpolated value
		return((1 - $in) * $par->[0] + $in * $par->[1]);
		
	# three or more parameters
	} else {
		
		# check if ICC::Support::Lapack module is loaded
		state $lapack = defined($INC{'ICC/Support/Lapack.pm'});
		
		# if input < 0
		if ($in < 0) {
			
			# return extrapolated value
			return($par->[0] + $in * _drv($par, 0));
			
		# if input > 1
		} elsif ($in > 1) {
			
			# return extrapolated value
			return($par->[-1] + ($in - 1) * _drv($par, 1));
			
		} else {
			
			# if Lapack module loaded
			if ($lapack) {
				
				# return Bernstein interpolated value
				return(ICC::Support::Lapack::bernstein($in, $par));
				
			} else {
				
				# return Bernstein interpolated value
				return(ICC::Shared::dotProduct(_bernstein($#{$par}, $in), $par));
				
			}
			
		}
		
	}
	
}

# direct reverse transform
# nominal range (0 - 1)
# parameters: (parameter_array_reference, x-min/max_array_reference, y-min/max_array_reference, input_value)
# returns: (output_value -or- array_of_output_values)
sub _rev {

	# get parameters
	my ($par, $xminmax, $yminmax, $in) = @_;

	# local variables
	my (@sol, $ext);
	my ($xval, $yval, $slope, $xi, $loop);
	my (@xs, @ys);

	# if no parameters
	if (@{$par} == 0) {
		
		# return input
		return($in);
		
	# one parameter
	} elsif (@{$par} == 1) {
		
		# warn if input not equal to constant
		($in == $par->[0]) || carp('curve input not equal to constant parameter');
		
		# return input
		return($in);
		
	# two parameters
	} elsif (@{$par} == 2) {
		
		# return linear interpolated value
		return(($in - $par->[0])/($par->[1] - $par->[0]));
		
	# three or more parameters
	} else {
		
		# setup segment arrays
		@xs = (0, @{$xminmax}, 1);
		@ys = ($par->[0], @{$yminmax}, $par->[-1]);
		
		# if slope(0) not 0
		if ($slope = _drv($par, 0)) {
			
			# compute extrapolation from 0
			$ext = ($in - $par->[0])/$slope;
			
			# save if less than 0
			push(@sol, $ext) if ($ext < 0);
			
		}
		
		# test first y-value
		push(@sol, $xs[0]) if ($ys[0] == $in);
		
		# for each array segment
		for my $i (1 .. $#xs) {
			
			# if input value falls within segment
			if (($in > $ys[$i - 1] && $in < $ys[$i]) || ($in < $ys[$i - 1] && $in > $ys[$i])) {
				
				# compute initial x-value, treating segment as linear
				$xval = ($in - $ys[$i - 1]) * ($xs[$i] - $xs[$i - 1])/($ys[$i] - $ys[$i - 1]) + $xs[$i - 1];
				
				# compute initial y-value
				$yval = _fwd($par, $xval);
				
				# init loop counter
				$loop = 0;
				
				# solution loop
				while (abs($in - $yval) > 1E-9 && $loop++ < 100) {
					
					# if slope not 0
					if ($slope = _drv($par, $xval)) {
						
						# adjust x-value
						$xval += ($in - $yval)/$slope;
						
						# if x-value out of range
						if ($xval < 0 || $xval > 1) {
							
							# get a random number
							$xi = rand();
							
							# reset x-value within segment
							$xval = $xs[$i] * $xi + $xs[$i - 1] * (1 - $xi);
							
						}
						
					} else {
						
						# get a random number
						$xi = rand();
						
						# reset x-value within segment
						$xval = $xs[$i] * $xi + $xs[$i - 1] * (1 - $xi);
						
					}
					
					# compute new y-value
					$yval = _fwd($par, $xval);
					
				}
				
				# print warning if failed to converge
				printf("'_rev' function of 'bern' object failed to converge with input of %.2f\n", $in) if ($loop > 100);
				
				# save result
				push(@sol, $xval);
				
			}
			
			# test current y-value
			push(@sol, $xs[$i]) if ($ys[$i] == $in);
			
		}
		
		# if slope(1) not 0
		if ($slope = _drv($par, 1)) {
			
			# compute extrapolation from 1
			$ext = ($in - $par->[-1])/$slope + 1;
			
			# save if greater than 1
			push(@sol, $ext) if ($ext > 1);
			
		}
		
	}

	# return result (array or first solution)
	return(wantarray ? @sol : $sol[0]);

}

# forward derivative
# nominal domain is (0 - 1)
# parameters: (parameter_array_reference, input_value)
# returns: (output_value)
sub _drv {

	# get parameters
	my ($par, $in) = @_;

	# if no parameters
	if (@{$par} == 0) {
		
		# return identity derivative
		return(1);
		
	# one parameter
	} elsif (@{$par} == 1) {
		
		# return constant derivative
		return(0);
		
	# two parameters
	} elsif (@{$par} == 2) {
		
		# return linear derivative
		return($par->[1] - $par->[0]);
		
	# three or more parameters
	} else {
		
		# check if ICC::Support::Lapack module is loaded
		state $lapack = defined($INC{'ICC/Support/Lapack.pm'});
		
		# limit input value (0 - 1) to force linear extrapolation
		$in = $in < 0 ? 0 : ($in > 1 ? 1 : $in);
		
		# compute parameter differences
		my $diff = [map {$par->[$_ + 1] - $par->[$_]} (0 .. $#{$par} - 1)];
		
		# if Lapack module loaded
		if ($lapack) {
			
			# return Bernstein interpolated derivative
			return($#{$par} * ICC::Support::Lapack::bernstein($in, $diff));
			
		} else {
			
			# return Bernstein interpolated derivative
			return($#{$par} * ICC::Shared::dotProduct(_bernstein($#{$diff}, $in), $diff));
			
		}
		
	}
	
}

# compute Bernstein polynomials
# parameters: (bernstein_degree, t)
# returns: (ref_to_bernstein_array)
sub _bernstein {

	# get parameters
	my ($degree, $t0) = @_;

	# local variables
	my ($bern, $t1, $m0, $m1, $n);

	# binomial coefficients
	state $pascal = [
		[1.0],
		[1.0, 1.0],
		[1.0, 2.0, 1.0],
		[1.0, 3.0, 3.0, 1.0],
		[1.0, 4.0, 6.0, 4.0, 1.0],
		[1.0, 5.0, 10.0, 10.0, 5.0, 1.0],
		[1.0, 6.0, 15.0, 20.0, 15.0, 6.0, 1.0],
		[1.0, 7.0, 21.0, 35.0, 35.0, 21.0, 7.0, 1.0],
		[1.0, 8.0, 28.0, 56.0, 70.0, 56.0, 28.0, 8.0, 1.0],
		[1.0, 9.0, 36.0, 84.0, 126.0, 126.0, 84.0, 36.0, 9.0, 1.0],
		[1.0, 10.0, 45.0, 120.0, 210.0, 252.0, 210.0, 120.0, 45.0, 10.0, 1.0]
	];

	# copy binomial coefficients for this degree
	$bern = [@{$pascal->[$degree]}];

	# compute input complement
	$t1 = 1 - $t0;

	# initialize multipliers
	$m0 = $m1 = 1;

	# get polynomial degree
	$n = $#{$bern};

	# for each polynomial
	for (1 .. $n) {
		
		# multiply
		$bern->[$_] *= ($m0 *= $t0);
		$bern->[$n - $_] *= ($m1 *= $t1);
		
	}

	# return array reference
	return($bern);

}

# build parameter array
# parameters: (object_reference, array_reference)
sub _pars {

	# get parameters
	my ($self, $array) = @_;

	# local variables
	my ($n);

	# verify array structure
	(@{$array} == 2 && ref($array->[0]) eq 'ARRAY' && ref($array->[1]) eq 'ARRAY') || croak('invalid array structure');

	# get number of input parameters
	$n = @{$array->[0]};

	# verify input parameters
	($n <= 11 && $n == grep {Scalar::Util::looks_like_number($_)} @{$array->[0]}) || croak('invalid input curve parameters');

	# copy input parameters
	$self->[1][0] = [@{$array->[0]}];

	# get number of output parameters
	$n = @{$array->[1]};

	# verify output parameters
	($n <= 11 && $n == grep {Scalar::Util::looks_like_number($_)} @{$array->[1]}) || croak('invalid output curve parameters');

	# copy output parameters
	$self->[1][1] = [@{$array->[1]}];

}

# write bern object to ICC profile
# note: writes an equivalent curv object
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _writeICCbern {

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