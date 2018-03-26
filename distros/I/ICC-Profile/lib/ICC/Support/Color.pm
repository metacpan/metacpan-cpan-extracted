package ICC::Support::Color;

use strict;
use Carp;

our $VERSION = 0.22;

# revised 2017-08-04

# Copyright © 2004-2018 by William B. Birkett

# add development directory
use lib 'lib';

# inherit from Shared
use parent qw(ICC::Shared);

# support modules
use File::Glob;

# enable static variables
use feature 'state';

# spectral range hash
our $srh = {'31' => [400, 700, 10], '36' => [380, 730, 10], '38' => [360, 730, 10], '43' => [360, 780, 10], '81' => [380, 780, 5]};

# create new Color object
# hash keys are: 'illuminant', 'observer', 'increment', 'method', 'imethod', 'bandpass', 'ibandpass', 'status', 'range'
# the method used is determined by the hash keys.
# for ASTM method,
#   'illuminant' value is a scalar, 'A', 'C', 'D50', 'D55', 'D65', 'D75', 'F2', 'F7', or 'F11', default is 'D50'
#   'observer' value is a scalar, '2' or '10', default is '2'
#   'increment' value is a scalar, '10' or '20', default is '10'
#   'bandpass' value is a scalar, 'astm', 'triangle', 'trapezoid' or 'six', default is no bandpass correction
# for CIE method,
#   'illuminant' value is an array reference, [], ['source', 'id'] or ['nm', 'spd']
#     an empty array indicates no illuminant, for emissive measurements
#     'source' values are 'CIE', 'Philips', or a measurement file path
#     'id' values depend on the 'source'
#       'CIE' illuminants are 'A', 'C', 'D50', 'D55', 'D65', 'D75', 'FL1' to 'FL12', 'FL3.1' to 'FL3.15', 'HP1' to 'HP5', and 'E'
#       'Philips' illuminants are '60_A/W', 'C100S54', 'C100S54C', 'F32T8/TL830', 'F32T8/TL835', 'F32T8/TL841', 'F32T8/TL850', 'F32T8/TL865/PLUS', 'F34/CW/RS/EW', 'F34T12WW/RS/EW', 'F40/C50', 'F40/C75', 'F40/CWX', 'F40/DX', 'F40/DXTP', 'F40/N', 'F34T12/LW/RS/EW', 'H38HT-100', 'H38JA-100/DX', 'MHC100/U/MP/3K', 'MHC100/U/MP/4K', and 'SDW-T_100W/LV'
#        for a measurement file path, the 'id' is the sample number
#     'nm' and 'spd' are vectors, wavelength range and spectral power distribution
#   'observer' value is a scalar, '2', '10', '2P' or '10P', default '2'
#   'increment' value is a scalar, '1' or '5', default '1'
#   'method' value is a scalar, 'linear', 'cspline' or 'lagrange', default is 'cspline'
#   'bandpass' value is a scalar, 'astm', 'triangle' or 'trapezoid', default is no bandpass correction
#   'imethod' value is a scalar, 'linear', 'cspline' or 'lagrange', default is 'linear' or 'cspline', based on smoothness of the illuminant SPD
#   'ibandpass' value is a scalar, 'astm', 'triangle' or 'trapezoid', default is no bandpass correction
# for ISO 5-3 method (density),
#   'status' value is a scalar, 'A', 'M', 'T', 'E', or  'I', default 'T'
#   'increment' value is a scalar, '10' or '20', default '10'
# 'range' value is: [start_nm, end_nm, increment], which is added to the spectral range hash ($srh)
# parameters: ([ref_to_attribute_hash])
# returns: (object_reference)
sub new {

	# get object class
	my $class = shift();

	# create empty Color object
	my $self = [
		{}, # object header
		[], # illuminant (CIE)
		[], # color-matching functions (CIE)
		[], # color-weight functions (ASTM and ISO 5-3)
		[], # color-weight functions (adjusted to input range and cached)
		[]  # white-point
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

# get/set reference to header hash
# header contains keys used by 'new'
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

# get/set reference to illuminant structure
# structure: [[start_nm, end_nm, increment], spd_vector]
# note: set updates the color-weight functions
# parameters: ([ref_to_new_structure])
# returns: (ref_to_structure)
sub illuminant {

	# get object reference
	my $self = shift();

	# local variables
	my ($array, $sx);

	# if there are parameters
	if (@_) {
		
		# if one parameter, an array reference
		if (@_ == 1 && ref($_[0]) eq 'ARRAY') {
			
			# get array reference
			$array = shift();
			
			# initialize data array
			$self->[1] = [];
			
			# if array is not empty
			if (@{$array}) {
				
				# verify array size
				(@{$array} == 2) || croak('invalid illuminant array');
				
				# verify wavelength range
				(ref($array->[0]) eq 'ARRAY' && 3 == @{$array->[0]} && (3 == grep {Scalar::Util::looks_like_number($_)} @{$array->[0]}) && $array->[0][2]) || croak('invalid illuminant wavelength range');
				
				# compute upper index of spd array
				(($sx = ICC::Shared::round(($array->[0][1] - $array->[0][0])/$array->[0][2])) > 0) || croak('inconsistent illuminant wavelength range');
				
				# verify spd array
				(ref($array->[1]) eq 'ARRAY' && $#{$array->[1]} == $sx && @{$array->[1]} == grep {Scalar::Util::looks_like_number($_)} @{$array->[1]}) || croak('invalid illuminant spd array');
				
				# copy array contents
				$self->[1] = Storable::dclone($array);
				
				# if observer array defined
				if (defined($self->[2][0])) {
					
					# update color-weight functions
					_make_cwf($self);
					
				}
				
			}
		
		} else {
			
			# error
			croak('parameter must be an array reference');
			
		}
	
	}

	# return reference
	return($self->[1]);

}

# get/set reference to observer structure
# structure: [[start_nm, end_nm, increment], cmf_matrix]
# note: set updates the color-weight functions
# parameters: ([ref_to_new_structure])
# returns: (ref_to_structure)
sub observer {

	# get object reference
	my $self = shift();

	# local variables
	my ($array, $sx);

	# if there are parameters
	if (@_) {
		
		# if one parameter, an array reference
		if (@_ == 1 && ref($_[0]) eq 'ARRAY') {
			
			# get array reference
			$array = shift();
			
			# initialize data array
			$self->[2] = [];
			
			# if array is not empty
			if (@{$array}) {
				
				# verify array size
				(@{$array} == 2) || croak('invalid observer array');
				
				# verify wavelength range
				(ref($array->[0]) eq 'ARRAY' && 3 == @{$array->[0]} && (3 == grep {Scalar::Util::looks_like_number($_)} @{$array->[0]}) && $array->[0][2]) || croak('invalid observer wavelength range');
				
				# compute upper index of observer matrix
				(($sx = ICC::Shared::round(($array->[0][1] - $array->[0][0])/$array->[0][2])) > 0) || croak('inconsistent observer wavelength range');
				
				# verify observer matrix
				((ref($array->[1]) eq 'ARRAY' || UNIVERSAL::isa($array->[1], 'Math::Matrix')) && ref($array->[1][0]) eq 'ARRAY' && $#{$array->[1][0]} == $sx && @{$array->[1][0]} == grep {Scalar::Util::looks_like_number($_)} @{$array->[1][0]}) || croak('invalid observer cmf matrix');
				
				# copy array contents
				$self->[2] = Storable::dclone($array);
				
				# if illuminant array defined
				if (defined($self->[1][0])) {
					
					# update color-weight functions
					_make_cwf($self);
					
				}
				
			}
		
		} else {
			
			# error
			croak('parameter must be an array reference');
			
		}
	
	}

	# return reference
	return($self->[2]);

}

# get/set reference to color-weight function structure
# structure: [[start_nm, end_nm, increment], cwf_matrix]
# parameters: ([ref_to_new_structure])
# returns: (ref_to_structure)
sub cwf {

	# get object reference
	my $self = shift();

	# local variables
	my ($array, $sx);

	# if there are parameters
	if (@_) {
		
		# if one parameter, an array reference
		if (@_ == 1 && ref($_[0]) eq 'ARRAY') {
			
			# get array reference
			$array = shift();
			
			# initialize data array
			$self->[3] = [];
			
			# if array is not empty
			if (@{$array}) {
				
				# verify array size
				(@{$array} == 2) || croak('invalid cwf array');
				
				# verify wavelength range
				(ref($array->[0]) eq 'ARRAY' && 3 == @{$array->[0]} && (3 == grep {Scalar::Util::looks_like_number($_)} @{$array->[0]}) && $array->[0][2]) || croak('invalid cwf wavelength range');
				
				# compute upper index of cwf matrix
				(($sx = ICC::Shared::round(($array->[0][1] - $array->[0][0])/$array->[0][2])) > 0) || croak('inconsistent cwf wavelength range');
				
				# verify cwf matrix
				((ref($array->[1]) eq 'ARRAY' || UNIVERSAL::isa($array->[1], 'Math::Matrix')) && ref($array->[1][0]) eq 'ARRAY' && $#{$array->[1][0]} == $sx && @{$array->[1][0]} == grep {Scalar::Util::looks_like_number($_)} @{$array->[1][0]}) || croak('invalid cwf weight matrix');
				
				# copy array contents
				$self->[3] = Storable::dclone($array);
				
				# for each weight function (XYZ -or- RGBV)
				for my $i (0 .. $#{$array->[1]}) {
					
					# update white point array
					$self->[5][$i] = List::Util::sum(@{$array->[1][$i]});
					
				}
				
			}
		
		} else {
			
			# error
			croak('parameter must be an array reference');
			
		}
	
	}

	# return reference
	return($self->[3]);

}

# get illuminant white point
# encoding specified by 'encoding' hash key
# 'encoding' values are 'XYZ', 'xyz', 'ICC_XYZ', 'ICC_XYZNumber', and 'density'
# parameters: ([hash])
# returns: (XYZ_vector)
sub iwtpt {

	# get parameters
	my ($self, $hash) = @_;

	# local variable
	my ($code);

	# return white point with optional encoding
	return(defined($code = _encoding($self, $hash)) ? [&$code(@{$self->[5]})] : $self->[5]);

}

# transform data
# hash keys are: 'range', and 'encoding'
# 'range' value is: [start_nm, end_nm, increment]
# 'encoding' values are 'XYZ', 'xyz', 'ICC_XYZ', 'ICC_XYZNumber', 'RGBV', 'rgbv' and 'density'
# supported input types:
# parameters: (list, [hash])
# parameters: (vector, [hash])
# parameters: (matrix, [hash])
# parameters: (Math::Matrix_object, [hash])
# parameters: (structure, [hash])
# returns: (same_type_as_input)
sub transform {

	# set hash value (0 or 1)
	my $h = ref($_[-1]) eq 'HASH' ? 1 : 0;

	# verify color weight array
	(defined($_[0]->[3][0]) && defined($_[0]->[3][1])) || croak('color weight array undefined');

	# if input a 'Math::Matrix' object
	if (@_ == $h + 2 && UNIVERSAL::isa($_[1], 'Math::Matrix')) {
		
		# call matrix transform
		&_trans2;
		
	# if input an array reference
	} elsif (@_ == $h + 2 && ref($_[1]) eq 'ARRAY') {
		
		# if array contains numbers (vector)
		if (! ref($_[1][0]) && @{$_[1]} == grep {Scalar::Util::looks_like_number($_)} @{$_[1]}) {
			
			# call vector transform
			&_trans1;
			
		# if array contains vectors (2-D array)
		} elsif (ref($_[1][0]) eq 'ARRAY' && @{$_[1]} == grep {ref($_) eq 'ARRAY' && Scalar::Util::looks_like_number($_->[0])} @{$_[1]}) {
			
			# call matrix transform
			&_trans2;
			
		} else {
			
			# call structure transform
			&_trans3;
			
		}
		
	# if input a list (of numbers)
	} elsif (@_ == $h + 1 + grep {Scalar::Util::looks_like_number($_)} @_) {
		
		# call list transform
		&_trans0;
		
	} else {
		
		# error
		croak('invalid transform input');
		
	}

}

# compute Jacobian matrix
# hash keys are: 'range', and 'encoding'
# 'range' value is: [start_nm, end_nm, increment]
# 'encoding' values are 'XYZ', 'xyz', 'ICC_XYZ', 'ICC_XYZNumber', 'RGBV', 'rgbv' and 'density'
# parameters: (input_vector, [hash])
# returns: (Jacobian_matrix, [output_vector])
sub jacobian {

	# get parameters
	my ($self, $in, $hash) = @_;

	# local variables
	my ($range, $encoding, $jac, $out, $sf);

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# get input spectral range
	($range = $hash->{'range'} || $srh->{@{$in}}) || croak('spectral range must be specified');

	# if data increment == cwf increment
	if ($range->[2] == $self->[3][0][2]) {
		
		# use adjusted cwf
		$jac = Storable::dclone(_adjust_cwf($self, $range));
		
	# if data increment > cwf increment
	} elsif ($range->[2] > $self->[3][0][2]) {
		
		# use reduced cwf
		$jac = Storable::dclone(_reduce_cwf($self, $range));
		
	} else {
		
		# error
		croak('data increment < cwf increment');
		
	}

	# if hash contain 'encoding' other than 'XYZ' or 'RGBV'
	if (defined($encoding = $hash->{'encoding'}) && $encoding ne 'XYZ' && $encoding ne 'RGBV') {
		
		# if encoding is 'ICC_XYZ'
		if ($encoding eq 'ICC_XYZ' && @{$jac} == 3) {
			
			# for each XYZ
			for my $i (0 .. 2) {
				
				# for each spectral value
				for my $j (0 .. $#{$jac->[0]}) {
					
					# adjust value
					$jac->[$i][$j] *= 327.68/65535;
					
				}
				
			}
			
		# if encoding is 'ICC_XYZNumber'
		} elsif ($encoding eq 'ICC_XYZNumber' && @{$jac} == 3) {
			
			# for each XYZ
			for my $i (0 .. 2) {
				
				# for each spectral value
				for my $j (0 .. $#{$jac->[0]}) {
					
					# adjust value
					$jac->[$i][$j] /= 100;
					
				}
				
			}
			
		# if encoding is 'xyz'
		} elsif ($encoding eq 'xyz' && @{$jac} == 3) {
			
			# verify white point
			($self->[5][0] && $self->[5][1] && $self->[5][2]) || croak('invalid illuminant white point');
			
			# for each XYZ
			for my $i (0 .. 2) {
				
				# for each spectral value
				for my $j (0 .. $#{$jac->[0]}) {
					
					# adjust value
					$jac->[$i][$j] /= $self->[5][$i];
					
				}
				
			}
			
		# if encoding is 'unit'
		} elsif ($encoding eq 'unit' && @{$jac} == 4) {
			
			# for each RGBV
			for my $i (0 .. 3) {
				
				# for each spectral value
				for my $j (0 .. $#{$jac->[0]}) {
					
					# adjust value
					$jac->[$i][$j] /= 100;
					
				}
				
			}
		
		# if encoding is 'density'
		} elsif ($encoding eq 'density' && @{$jac} == 4) {
			
			# delete encoding
			delete($hash->{'encoding'});
			
			# get the output values (RGBV)
			$out = _trans1($self, $in, $hash);
			
			# verify output
			($out->[0] && $out->[1] && $out->[2] && $out->[3]) || croak('invalid density value');
			
			# for each RGBV
			for my $i (0 .. 3) {
				
				# compute scale factor
				$sf = - $out->[$i] * ICC::Shared::ln10;
				
				# for each spectral value
				for my $j (0 .. $#{$jac->[0]}) {
					
					# adjust value
					$jac->[$i][$j] /= $sf;
					
				}
				
			}
			
			# restore encoding
			$hash->{'encoding'} = 'density';
			
		} else {
			
			# error
			croak('unsupported XYZ/RGBV encoding');
		}
		
	}

	# if output vector wanted
	if (wantarray) {
		
		# return Jacobian and output vector
		return($jac, _trans1($self, $in, $hash));
		
	} else {
		
		# return Jacobian only
		return($jac);
		
	}
	
}

# print object contents to string !!! needs work !!!
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

# transform list
# parameters: (object_reference, list, [hash])
# returns: (list)
sub _trans0 {

	# local variables
	my ($self, $hash);

	# get object reference
	$self = shift();

	# get optional hash
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# return
	return(@{_trans1($self, \@_, $hash)});

}

# transform vector
# parameters: (object_reference, vector, [hash])
# returns: (vector)
sub _trans1 {

	# get parameters
	my ($self, $in, $hash) = @_;

	# local variables
	my ($range, $cwf, $out, $code);

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# get input spectral range
	($range = $hash->{'range'} || $srh->{@{$in}}) || croak('spectral range must be specified');

	# if data increment == cwf increment
	if ($range->[2] == $self->[3][0][2]) {
		
		# adjust cwf to match data range
		$cwf = _adjust_cwf($self, $range);
		
	# if data increment > cwf increment
	} elsif ($range->[2] > $self->[3][0][2]) {
		
		# adjust cwf to match data range
		$cwf = _reduce_cwf($self, $range);
		
	} else {
		
		# error
		croak('data increment < cwf increment');
		
	}
	
	# if ICC::Support::Lapack module is loaded
	if ($lapack) {
		
		# compute output matrix using BLAS dgemv function
		$out = ICC::Support::Lapack::matf_vec_trans($in, $cwf);
		
	} else {
		
		# for each XYZ or RGBV
		for my $i (0 .. $#{$cwf}) {
			
			# compute dot product
			$out->[$i] = ICC::Shared::dotProduct($in, $cwf->[$i]);
			
		}
		
	}

	# return with optional encoding
	return(defined($code = _encoding($self, $hash)) ? [&$code(@{$out})] : $out);

}

# transform matrix (2-D array -or- Math::Matrix object)
# parameters: (object_reference, matrix, [hash])
# returns: (matrix)
sub _trans2 {

	# get parameters
	my ($self, $in, $hash) = @_;

	# local variables
	my ($range, $cwf, $out, $code);

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# get input spectral range
	($range = $hash->{'range'} || $srh->{@{$in->[0]}}) || croak('spectral range must be specified');

	# if data increment == cwf increment
	if ($range->[2] == $self->[3][0][2]) {
		
		# adjust cwf to match data range
		$cwf = _adjust_cwf($self, $range);
		
	# if data increment > cwf increment
	} elsif ($range->[2] > $self->[3][0][2]) {
		
		# adjust cwf to match data range
		$cwf = _reduce_cwf($self, $range);

	} else {
		
		# error
		croak('data increment < cwf increment');
		
	}

	# if ICC::Support::Lapack module is loaded
	if ($lapack) {
		
		# compute output matrix using BLAS dgemm function
		$out = ICC::Support::Lapack::matf_mat_trans($in, $cwf);
		
	} else {
		
		# for each sample
		for my $i (0 .. $#{$in}) {
			
			# for each XYZ or RGBV
			for my $j (0 .. $#{$cwf}) {
				
				# compute dot product
				$out->[$i][$j] = ICC::Shared::dotProduct($in->[$i], $cwf->[$j]);
				
			}
			
		}
		
	}

	# if encoding enabled
	if ($code = _encoding($self, $hash)) {
		
		# for each sample
		for my $i (0 .. $#{$out}) {
			
			# apply encoding
			@{$out->[$i]} = &$code(@{$out->[$i]});
			
		}
		
	}

	# return output (Math::Matrix object or 2-D array)
	return(UNIVERSAL::isa($in, 'Math::Matrix') ? bless($out, 'Math::Matrix') : $out);

}

# transform structure
# parameters: (object_reference, structure, [hash])
# returns: (structure)
sub _trans3 {

	# get parameters
	my ($self, $in, $hash) = @_;

	# transform the array structure
	_crawl($self, \&_trans1, $in, my $out = [], $hash);

	# return output structure
	return($out);

}

# recursive transform
# array structure is traversed until all vectors are found and transformed
# parameters: (object_reference, subroutine_reference, input_array_reference, output_array_reference, hash)
sub _crawl {

	# get parameters
	my ($self, $sub, $in, $out, $hash) = @_;

	# if input is a vector (reference to a numeric array)
	if (@{$in} == grep {Scalar::Util::looks_like_number($_)} @{$in}) {
		
		# transform input vector and copy to output
		@{$out} = @{$sub->($self, $in, $hash)};
		
	} else {
		
		# for each input element
		for my $i (0 .. $#{$in}) {
			
			# if an array reference
			if (ref($in->[$i]) eq 'ARRAY') {
				
				# transform next level
				_crawl($self, $sub, $in->[$i], $out->[$i] = [], $hash);
				
			} else {
				
				# error
				croak('invalid input structure');
				
			}
			
		}
		
	}
	
}

# reduce cwf matrix to match data range
# the reduced cwf and data range is cached
# parameters: (object_reference, data_range)
# returns: (reduced_cwf)
sub _reduce_cwf {

	# get parameters
	my ($self, $range_data) = @_;

	# local variables
	my ($method, $bandpass, $range_cwf, $cwf, $mat);

	# if cached CWF matches data range
	if (defined($self->[4][0]) && $self->[4][0][0] == $range_data->[0] && $self->[4][0][1] == $range_data->[1] && $self->[4][0][2] == $range_data->[2]) {
		
		# return cached CWF
		return($self->[4][1]);
		
	}

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# get interpolation method
	$method = $self->[0]{'method'} // 'cspline';

	# get bandpass correction
	$bandpass = $self->[0]{'bandpass'} // 0;

	# get cwf range
	$range_cwf = $self->[3][0];

	# if method is linear
	if ($method eq 'linear') {
		
		# compute linear interpolation matrix
		$mat = ICC::Shared::linear_matrix($range_data, $range_cwf, 'copy');
		
	# if method is cubic spline
	} elsif ($method eq 'cspline') {
		
		# compute cubic spline interpolation matrix
		$mat = ICC::Shared::cspline_matrix($range_data, $range_cwf, 'copy');
		
	# if method is Lagrange
	} elsif ($method eq 'lagrange') {
		
		# compute Lagrange interpolation matrix
		$mat = ICC::Shared::lagrange_matrix($range_data, $range_cwf, 'copy');
		
	} else {
		
		# error
		croak('invalid interpolation method');
		
	}
	
	# if ICC::Support::Lapack module is loaded
	if ($lapack) {
		
		# compute cwf using BLAS dgemm function
		$cwf = ICC::Support::Lapack::mat_xplus($self->[3][1], $mat);
		
		# if bandpass correction is enabled
		if ($bandpass) {
			
			# apply correction matrix
			$cwf = ICC::Support::Lapack::mat_xplus($cwf, _bandpass($range_data, $method, $bandpass));
			
		}
		
	} else {
		
		# compute cwf using Math::Matrix module
		$cwf = bless(Storable::dclone($self->[3][1]), 'Math::Matrix') * $mat;
		
		# if bandpass correction is enabled
		if ($bandpass) {
			
			# apply correction matrix
			$cwf = $cwf * _bandpass($range_data, $method, $bandpass);
			
		}
		
	}

	# cache reduced CWF
	$self->[4][0] = $range_data;
	$self->[4][1] = $cwf;

	# return
	return($cwf);

}

# make bandpass correction matrix
# per ASTM E 2729 or deconvolution
# parameters: (data_range, interpolation_method, bandpass_method)
# returns: (matrix)
sub _bandpass {

	# get parameters
	my ($range_data, $method, $bandpass) = @_;

	# local variables
	my ($ix, $jx, $range_mat, $mati, $matc, $bpf, $info, $matrix);

	# compute bandpass matrix upper index
	$ix = ($range_data->[1] - $range_data->[0])/$range_data->[2];
	
	# set bandpass function upper index
	$jx = 20;

	# if bandpass value if 'astm'
	if ($bandpass eq 'astm') {
		
		# return ASTM E 2729 bandpass rectification matrix
		return(_bandpass_astm($ix));
		
	} else {
		
		# compute interpolation matrix range
		$range_mat = [$range_data->[0] - $range_data->[2], $range_data->[1] + $range_data->[2], $range_data->[2]/10];
		
		# if method is linear
		if ($method eq 'linear') {
			
			# compute linear interpolation matrix
			$mati = ICC::Shared::linear_matrix($range_data, $range_mat, 'linear');
			
		# if method is cubic spline
		} elsif ($method eq 'cspline') {
			
			# compute cubic spline interpolation matrix
			$mati = ICC::Shared::cspline_matrix($range_data, $range_mat, 'linear');
			
		# if method is Lagrange
		} elsif ($method eq 'lagrange') {
			
			# compute Lagrange interpolation matrix
			$mati = ICC::Shared::lagrange_matrix($range_data, $range_mat, 'linear');
			
		} else {
			
			# error
			croak('invalid interpolation method');
			
		}
		
		# if bandpass value if 'triangle'
		if ($bandpass eq 'triangle') {
		
			# compute bandpass function array
			$bpf = _bandpass_fn(1, $jx);
		
		# if bandpass value if 'trapezoid' (combination of three triangular sub-bands)
		} elsif ($bandpass eq 'trapezoid') {
		
			# compute bandpass function array
			$bpf = _bandpass_fn(1/3, $jx);
			
		# if bandpass value is an array reference
		} elsif (ref($bandpass) eq 'ARRAY' && $#{$bandpass} == $jx) {
			
			# set value
			$bpf = $bandpass;
		
		} else {
			
			# error
			croak('invalid bandpass correction');
			
		}
		
		# compute convolution matrix
		$matc = _conv_matrix($bpf, $ix);
		
		# check if ICC::Support::Lapack module is loaded
		state $lapack = defined($INC{'ICC/Support/Lapack.pm'});
		
		# if Lapack module loaded
		if ($lapack) {
			
			# multiply matrices and invert using Lapack module
			($info, $matrix) = ICC::Support::Lapack::inv(ICC::Support::Lapack::mat_xplus($matc, $mati));
			
			# return deconvolution matrix
			return(bless($matrix, 'Math::Matrix'));
			
		} else {
			
			# return deconvolution matrix
			return(($matc * $mati)->invert());
			
		}
		
	}
	
}

# make ASTM E 2729 bandpass rectification matrix
# parameter: (upper_index)
# returns: (matrix)
sub _bandpass_astm {

	# get upper index
	my $ix = shift();

	# local variables
	my ($matrix, @zeros);

	# make array of zeros
	@zeros = (0) x ($ix + 1);

	# for each matrix row
	for my $i (0 .. $ix) {
		
		# set the row to zeros
		$matrix->[$i] = [@zeros];
		
		# for each matrix column
		for my $j (0 .. $ix) {
			
			# if main diagonal
			if ($i == $j) {
				
				if ($i == 0 || $i == $ix) {
					
					$matrix->[$i][$j] = 1;
					
				} elsif ($i == 1 || $i == $ix - 1) {
					
					$matrix->[$i][$j] = 1.21;
					
				} else {
					
					$matrix->[$i][$j] = 1.22;
					
				}
				
			# if +/- 1 diagonal, and not the first or last rows
			} elsif (abs($i - $j) == 1 && $i > 0 && $i < $ix) {
				
				if ($j == 0 || $j == $ix) {
					
					$matrix->[$i][$j] = -0.10;
					
				} else {
					
					$matrix->[$i][$j] = -0.12;
					
				}
				
			# if +/- 2 diagonal, and not the first or last rows
			} elsif (abs($i - $j) == 2 && $i > 0 && $i < $ix) {
				
				$matrix->[$i][$j] = 0.01;
				
			}
			
		}
		
	}

	# return Math::Matrix object
	return(bless($matrix, 'Math::Matrix'));

}

# make simple bandpass function
# shape ranges from 0 to 1 (rectangular to triangular)
# upper index must be divisible by 4
# parameters: (shape, upper_index)
# returns: (bandpass_array)
sub _bandpass_fn {

	# get parameters
	my ($shape, $ix) = @_;

	# local variables
	my ($m, $v, @array, $sum);

	# verify shape
	($shape >= 0 && $shape <= 1) || croak('invalid shape parameter');

	# verify upper index
	($ix == int($ix) && ! ($ix % 4)) || croak('invalid upper index');

	# if shape not rectangular
	if ($shape) {
		
		# compute slope
		$m = 2/($shape * $ix);
		
	} else {
		
		# set slope to big number
		$m = 1E100;
		
	}

	# for each array element
	for my $i (0 .. $ix/2) {
		
		# compute value
		$v = ($i - $ix/4) * $m + 0.5;
		
		# set array elements to limited value
		$array[$i] = $array[$ix - $i] = $v < 0 ? 0 : $v > 1 ? 1 : $v;
		
	}

	# compute array sum
	$sum = List::Util::sum(@array);

	# return normalized array
	return([map {$_/$sum} @array]);

}

# make convolution matrix
# parameters: (bandpass_function_vector, row_upper_index)
# returns: (convolution_matrix)
sub _conv_matrix {

	# get parameters
	my ($bpf, $ix) = @_;

	# local variables
	my ($n, $p, @zeros, $mat);

	# verify bandpass function
	(@{$bpf} % 2) || croak('bandpass function must have odd number of elements');

	# verify row upper index
	($ix == int($ix) && $ix >= 0) || croak('row upper index must be an integer >= 0');

	# compute upper column index
	$n = $#{$bpf} * ($ix + 2)/2;

	# compute bandpass increment
	$p = $#{$bpf}/2;

	# make array of zeros
	@zeros = (0) x ($n + 1);

	# for each row
	for my $i (0 .. $ix) {
		
		# add row of zeros
		$mat->[$i] = [@zeros];
		
		# for each bandpass value
		for my $j (0 .. $#{$bpf}) {
			
			# copy bandpass value
			$mat->[$i][$i * $p + $j] = $bpf->[$j];
			
		}
		
	}

	# return
	return(bless($mat, 'Math::Matrix'));

}

# adjust cwf matrix to match data range
# the adjusted cwf and data range is cached
# parameters: (object_reference, data_range)
# returns: (adjusted_cwf)
sub _adjust_cwf {

	# get parameters
	my ($self, $range_data) = @_;

	# local variables
	my ($bandpass, $off, $cwf);

	# if cached CWF matches data range
	if (defined($self->[4][0]) && $self->[4][0][0] == $range_data->[0] && $self->[4][0][1] == $range_data->[1] && $self->[4][0][2] == $range_data->[2]) {
		
		# return cached CWF
		return($self->[4][1]);
		
	}

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# get bandpass correction
	$bandpass = $self->[0]{'bandpass'} // 0;

	# compute range offset
	$off = abs(($range_data->[0] - $self->[3][0][0])/$range_data->[2]);

	# verify offset is an integer
	(abs($off - ICC::Shared::round($off)) < 1E-12) || croak('range offset not an integer');

	# adjust CWF matrix
	$cwf = _adjust_matrix($self->[3][1], $self->[3][0], $range_data);

	# if bandpass correction enabled, and not table 6
	if ($bandpass && $bandpass ne 'six') {
		
		# if ICC::Support::Lapack module is loaded
		if ($lapack) {
			
			# apply correction matrix
			$cwf = ICC::Support::Lapack::mat_xplus($cwf, _bandpass($range_data, 'lagrange', $bandpass));
			
		} else {
			
			# apply correction matrix
			$cwf = bless($cwf, 'Math::Matrix') * _bandpass($range_data, 'lagrange', $bandpass);
			
		}
		
	}

	# cache adjusted CWF
	$self->[4][0] = $range_data;
	$self->[4][1] = $cwf;

	# return
	return($cwf);

}

# adjust matrix to match data range
# parameters: (matrix, matrix_range, data_range)
# returns: (adjusted_matrix)
sub _adjust_matrix {

	# get parameters
	my ($matrix, $range_matrix, $range_data) = @_;

	# local variables
	my ($adj, $j);

	# clone matrix
	$adj = Storable::dclone($matrix);

	# for each function
	for my $i (0 .. $#{$adj}) {
		
		# if cwf start < data start
		if ($range_matrix->[0] < $range_data->[0]) {
			
			# compute number of elements to combine
			$j = int(($range_data->[0] - $range_matrix->[0])/$range_data->[2] + 1.5);
			
			# combine elements
			splice(@{$adj->[$i]}, 0, $j, List::Util::sum(@{$adj->[$i]}[0 .. ($j - 1)]));
			
		# if cwf start > data start
		} elsif ($range_matrix->[0] > $range_data->[0]) {
			
			# compute number of zeros to add
			$j = int(($range_matrix->[0] - $range_data->[0])/$range_data->[2] + 0.5);
			
			# add zeros
			unshift(@{$adj->[$i]}, (0) x $j);
			
		}
		
		# if cwf end > data end
		if ($range_matrix->[1] > $range_data->[1]) {
			
			# compute number of elements to combine
			$j = int(($range_matrix->[1] - $range_data->[1])/$range_data->[2] + 1.5);
			
			# combine elements
			splice(@{$adj->[$i]}, -$j, $j, List::Util::sum(@{$adj->[$i]}[-$j .. -1]));
			
		# if cwf end < data end
		} elsif ($range_matrix->[1] < $range_data->[1]) {
			
			# compute number of zeros to add
			$j = int(($range_data->[1] - $range_matrix->[1])/$range_data->[2] + 0.5);
			
			# add zeros
			push(@{$adj->[$i]}, (0) x $j);
			
		}
		
	}

	# return
	return($adj);

}

# compute CIE color-weight functions
# parameters: (object_reference)
# results are saved in the object
# cwf cache is cleared
sub _make_cwf {

	# get parameters
	my $self = shift();

	# local variables
	my ($range, $obs, $inc, $smooth, $method, $bandpass, $matc, $illum, $spd, $ks, @k, @Wx, @Wy, @Wz);

	# if cwf_range key defined
	if (defined($self->[0]{'cwf_range'})) {
		
		# use supplied range
		$range = $self->[0]{'cwf_range'};
		
		# interpolate observer functions, with linear extrapolation
		$obs = ICC::Support::Lapack::matf_mat_trans($self->[2][1], ICC::Shared::cspline_matrix($self->[2][0], $range, 'linear'));
		
	# if observer requires interpolation
	} elsif ($self->[2][0][2] != ($inc = $self->[0]{'increment'} // 1)) {
		
		# use observer range, changing increment
		$range = [$self->[2][0][0], $self->[2][0][1], $inc];
		
		# interpolate observer functions
		$obs = ICC::Support::Lapack::matf_mat_trans($self->[2][1], ICC::Shared::cspline_matrix($self->[2][0], $range));
		
	} else {
		
		# use observer range
		$range = $self->[2][0];
		
		# get observer functions
		$obs = $self->[2][1];
		
	}

	# if observer requires exponentiation
	if ($self->[0]{'observer_exp'}) {
		
		# for each spectral value
		for my $i (0 .. $#{$obs->[0]}) {
			
			# exponentiate
			$obs->[0][$i] = exp($obs->[0][$i]);
			$obs->[1][$i] = exp($obs->[1][$i]);
			$obs->[2][$i] = exp($obs->[2][$i]);
			
		}
		
	}

	# if illuminant is defined
	if (defined($self->[1][0])) {
		
		# compute illuminant smoothness
		$smooth = _smoothness($self->[1][1]);
		
		# get illuminant interpolation method
		$method = $self->[0]{'imethod'} // ($smooth == 0 || $smooth > 0.001) ? 'linear' : 'cspline';
		
		# if illuminant bandpass correction enabled
		if (defined($bandpass = $self->[0]{'ibandpass'})) {
			
			# compute bandpass correction matrix
			$matc = _bandpass($self->[1][0], $method, $bandpass);
			
			# apply bandpass correction matrix
			$illum = [map {ICC::Shared::dotProduct($self->[1][1], $_)} @{$matc}];
			
		} else {
			
			# use illuminant as is
			$illum = $self->[1][1];
			
		}
		
		# if method is linear
		if ($method eq 'linear') {
			
			# interpolate illuminant data
			$spd = ICC::Shared::linear($illum, $self->[1][0], $range, 'copy');
			
		# if method is cubic spline
		} elsif ($method eq 'cspline') {
			
			# interpolate illuminant data
			$spd = ICC::Shared::cspline($illum, $self->[1][0], $range, 'copy');
			
		# if method is Lagrange -or- ASTM E 2022
		} elsif ($method eq 'lagrange') {
			
			# interpolate illuminant data
			$spd = ICC::Shared::lagrange($illum, $self->[1][0], $range, 'copy');
			
		} else {
			
			# error
			croak('invalid illuminant interpolation method');
			
		}
		
		# get or compute summation constant
		$ks = $self->[0]{'cwf_ks'} // 100/ICC::Shared::dotProduct($spd, $obs->[1]);
		
		# for each spectral value
		for my $i (0 .. $#{$obs->[0]}) {
			
			# compute spectral products (k * illuminant * observer)
			$Wx[$i] = $ks * $spd->[$i] * $obs->[0][$i];
			$Wy[$i] = $ks * $spd->[$i] * $obs->[1][$i];
			$Wz[$i] = $ks * $spd->[$i] * $obs->[2][$i];
			
		}
		
	} else {
		
		# compute summation constants (slightly different for X, Y, Z)
		$k[0] = 100/List::Util::sum(@{$obs->[0]});
		$k[1] = 100/List::Util::sum(@{$obs->[1]});
		$k[2] = 100/List::Util::sum(@{$obs->[2]});
		
		# for each spectral value
		for my $i (0 .. $#{$obs->[0]}) {
			
			# compute spectral products (k * observer)
			$Wx[$i] = $k[0] * $obs->[0][$i];
			$Wy[$i] = $k[1] * $obs->[1][$i];
			$Wz[$i] = $k[2] * $obs->[2][$i];
			
		}
		
	}

	# set wavelength range (start, end, and increment)
	$self->[3][0] = [@{$range}];

	# set color-weight functions
	$self->[3][1][0] = [@Wx];
	$self->[3][1][1] = [@Wy];
	$self->[3][1][2] = [@Wz];

	# set illuminant white point (XYZ)
	$self->[5][0] = List::Util::sum(@Wx);
	$self->[5][1] = List::Util::sum(@Wy);
	$self->[5][2] = List::Util::sum(@Wz);

	# clear adjusted CWF cache
	$self->[4] = [];

}

# read CIE illuminant and color-matching functions
# compute color-weight functions (k * illuminant * observer) and white point
# illuminant, observer and increment specified in hash
# parameters: (object_reference, hash)
# results are saved in the object
sub _cie {

	# get parameters
	my ($self, $hash) = @_;

	# local variables
	my ($array, @files, $illum, $s, $w, $sx);
	my ($inc, $obs, $cmf, $key);

	# get copy of illuminant array
	$array = Storable::dclone($hash->{'illuminant'});

	# if empty array (emissive)
	if (! @{$array}) {
		
		# clear illuminant
		$self->[1] = [];
		
	# if a measured illuminant (file path)
	} elsif (@files = grep {-f} File::Glob::bsd_glob($array->[0])) {
		
		# make new chart object
		$illum = ICC::Support::Chart->new($files[0]);
		
		# get sample from hash (default is 1)
		$s = defined($array->[1]) ? $array->[1] : 1;
		
		# verify sample
		(Scalar::Util::looks_like_number($s) && $s == int($s) && $s > 0 && $s <= $illum->size()) || croak('invalid sample number');
		
		# set wavelength range
		$self->[1][0] = $illum->nm();
		
		# set spectral values
		($self->[1][1] = $illum->spectral([$s])->[0]) || croak('illuminant chart has no spectral data');
		
	# if a standard illuminant (YAML file in data folder)
	} elsif (@files = grep {-f} File::Glob::bsd_glob(ICC::Shared::getICCPath("Data/$array->[0]_illums_*.yml"))) {
		
		# load standard illuminants (YAML format)
		$illum = YAML::Tiny->read($files[0])->[0];
		
		# get wavelength vector
		$w = $illum->{'nm'};
		
		# set wavelength range
		$self->[1][0] = [$w->[0], $w->[-1], $w->[1] - $w->[0]];
		
		# set spectral values
		($self->[1][1] = $illum->{$array->[1]}) || croak('standard illuminant not found');
		
	# if illuminant is two array references (wavelength range and spd vectors)
	} elsif (@{$array} == grep {ref() eq 'ARRAY'} @{$array}) {
		
		# verify wavelength range
		(ref($array->[0]) eq 'ARRAY' && 3 == @{$array->[0]} && (3 == grep {Scalar::Util::looks_like_number($_)} @{$array->[0]}) && $array->[0][2]) || croak('invalid illuminant wavelength range');
		
		# compute upper index of spd array
		(($sx = ICC::Shared::round(($array->[0][1] - $array->[0][0])/$array->[0][2])) > 0) || croak('inconsistent illuminant wavelength range');
		
		# verify spd array
		(ref($array->[1]) eq 'ARRAY' && $#{$array->[1]} == $sx && @{$array->[1]} == grep {Scalar::Util::looks_like_number($_)} @{$array->[1]}) || croak('invalid illuminant spd array');
		
		# copy array contents
		$self->[1] = Storable::dclone($array);
		
	} else {
		
		# error
		croak("invalid illuminant [@{$array}]");
		
	}

	# get increment from hash (default is 1)
	$inc = defined($hash->{'increment'}) ? $hash->{'increment'} : 1;

	# if increment is 1 nm
	if ($inc == 1) {
		
		# set wavelength range
		$self->[2][0] = [360, 830, 1];
		
		# load CIE color matching functions (YAML format)
		$cmf = YAML::Tiny->read(ICC::Shared::getICCPath('Data/CIE_cmfs_360-830_x_1.yml'))->[0];
		
	# if increment is 5 nm
	} elsif ($inc == 5) {
		
		# set wavelength range
		$self->[2][0] = [380, 780, 5];
		
		# load CIE color matching functions (YAML format)
		$cmf = YAML::Tiny->read(ICC::Shared::getICCPath('Data/CIE_cmfs_380-780_x_5.yml'))->[0];
		
	} else {
		
		# error
		croak('invalid spectral increment');
		
	}

	# get observer from hash (default is 2)
	$obs = defined($hash->{'observer'}) ? $hash->{'observer'} : 2;

	# if observer is an array reference
	if (ref($obs) eq 'ARRAY') {
		
		# verify array size
		(@{$obs} == 2) || croak('invalid observer array');
		
		# verify range
		(ref($obs->[0]) eq 'ARRAY' && (@{$obs->[0]} == grep {Scalar::Util::looks_like_number($_)} @{$obs->[0]}) &&
		@{$obs->[0]} == 3 && $obs->[0][2] && ! (($obs->[0][1] - $obs->[0][0]) % $obs->[0][2])) || croak('invalid observer wavelength range');
		
		# compute upper index of observer matrix
		(($sx = ICC::Shared::round(($obs->[0][1] - $obs->[0][0])/$obs->[0][2])) > 0) || croak('inconsistent observer wavelength range');
		
		# verify observer matrix
		((ref($obs->[1]) eq 'ARRAY' || UNIVERSAL::isa($obs->[1], 'Math::Matrix')) && ref($obs->[1][0]) eq 'ARRAY' &&
		$#{$obs->[1][0]} == $sx && @{$obs->[1][0]} == grep {Scalar::Util::looks_like_number($_)} @{$obs->[1][0]}) || croak('invalid observer cmf matrix');
		
		# copy array contents
		$self->[2] = Storable::dclone($obs);
		
	} else {
		
		# get observer key
		($key = {'2' => 'CIE1931', '10' => 'CIE1964', '2P' => 'CIE2012D2', '10P' => 'CIE2012D10'}->{$obs}) || croak('invalid observer key');
		
		# set CIE color-matching functions
		$self->[2][1][0] = $cmf->{$key . 'x'};
		$self->[2][1][1] = $cmf->{$key . 'y'};
		$self->[2][1][2] = $cmf->{$key . 'z'};
		
	}

	# compute color-weight functions
	_make_cwf($self);

	# set object type
	$self->[0]{'type'} = 'CIE';

}

# read ASTM color weight functions and white point
# illuminant, observer, increment and bandpass specified in hash
# parameters: (object_reference, hash)
# results are saved in the object
sub _astm {

	# get parameters
	my ($self, $hash) = @_;

	# local variables
	my ($table, $id, @bpc, @inc, @obs, @illum, @m, $nm);

	# initialize id
	$id = 1;

	# if increment key in hash
	if (defined($hash->{'increment'})) {
		
		# enumerate ASTM increments
		@inc = qw(10 20);
		
		# match observer value
		(@m = grep {$hash->{'increment'} eq $inc[$_]} (0 .. $#inc)) || warn('invalid increment value - using 10 nm');
		
		# adjust id for increment
		$id += @m ? $m[0] : 0;
		
	}

	# if observer key in hash
	if (defined($hash->{'observer'})) {
		
		# enumerate ASTM observers
		@obs = qw(2 10);
		
		# match observer value
		(@m = grep {$hash->{'observer'} eq $obs[$_]} (0 .. $#obs)) || warn('invalid observer value - using 1931 2º');
		
		# adjust id for observer
		$id += @m ? 2 * $m[0] : 0;
		
	}

	# if illuminant key in hash
	if (defined($hash->{'illuminant'})) {
		
		# enumerate ASTM illuminants
		@illum = qw(A C D50 D55 D65 D75 F2 F7 F11);
		
		# match illuminant value
		(@m = grep {$hash->{'illuminant'} eq $illum[$_]} (0 .. $#illum)) || warn('invalid illuminant value - using D50');
		
		# adjust id for illuminant
		$id += @m ? 4 * $m[0] : 8;
		
	} else {
		
		# adjust id for D50 illuminant
		$id += 8;
		
	}

	# set table: 5 (no bpc) -or- 6 (with bpc)
	# note: table 6 is deprecated in ASTM E 2729
	$table = (defined($hash->{'bandpass'}) && $hash->{'bandpass'} eq 'six') ? 6 : 5;

	# combine table and id
	$table .= '.' . $id;

	# load ASTM weight functions (YAML format)
	state $ASTM = YAML::Tiny->read(ICC::Shared::getICCPath('Data/ASTM_E308_data.yml'))->[0];

	# get wavelength vector
	$nm = $ASTM->{$table . 'nm'};

	# set wavelength start, end, and increment
	$self->[3][0] = [$nm->[0], $nm->[-1], $nm->[1] - $nm->[0]];

	# set color-weight functions
	$self->[3][1][0] = $ASTM->{$table . 'x'};
	$self->[3][1][1] = $ASTM->{$table . 'y'};
	$self->[3][1][2] = $ASTM->{$table . 'z'};

	# set illuminant white point
	$self->[5] = $ASTM->{$table . 'wp'};

	# set object type
	$self->[0]{'type'} = 'ASTM';

}

# read ISO 5-3 density weight functions
# status and increment specified in hash
# parameters: (object_reference, hash)
# results are saved in the object
sub _iso {

	# get parameters
	my ($self, $hash) = @_;

	# local variables
	my ($status, $inc, @m, $nm);

	# initialize table selectors
	$status = 'T';
	$inc = '10';

	# if status key in hash
	if (defined($hash->{'status'})) {
		
		# match status value
		(@m = grep {$hash->{'status'} eq $_} qw(A M T E I)) || warn('invalid status value - using T');
		
		# set status
		$status = @m ? $m[0] : 'T';
		
	}

	# if increment key in hash
	if (defined($hash->{'increment'})) {
		
		# match observer value
		(@m = grep {$hash->{'increment'} eq $_} qw(10 20)) || warn('invalid increment value - using 10 nm');
		
		# set increment
		$inc = @m ? $m[0] : '10';
		
	}

	# load ISO 5-3 weight functions (YAML format)
	state $ISO = YAML::Tiny->read(ICC::Shared::getICCPath('Data/ISO_5-3_data.yml'))->[0];

	# get wavelength vector
	$nm = $ISO->{$inc . 'nm'};

	# set wavelength start, end, and increment
	$self->[3][0] = [$nm->[0], $nm->[-1], $nm->[1] - $nm->[0]];

	# set density weight functions
	$self->[3][1][0] = $ISO->{$inc . $status . 'r'};
	$self->[3][1][1] = $ISO->{$inc . $status . 'g'};
	$self->[3][1][2] = $ISO->{$inc . $status . 'b'};
	$self->[3][1][3] = $ISO->{$inc . 'vis'};

	# set density weight function sums
	$self->[5][0] = List::Util::sum(@{$self->[3][1][0]});
	$self->[5][1] = List::Util::sum(@{$self->[3][1][1]});
	$self->[5][2] = List::Util::sum(@{$self->[3][1][2]});
	$self->[5][3] = List::Util::sum(@{$self->[3][1][3]});

	# set object type
	$self->[0]{'type'} = 'ISO';

}

# compute vector smoothness
# (returns 0 if vector is linear)
# parameter: (vector)
# returns: (linearity)
sub _smoothness {

	# get parameter
	my $v = shift();

	# local variables
	my ($d, $s);

	# return if < 3 vector elements
	return(0) if (@{$v} < 3);

	# for each triplet
	for my $i (0 .. $#{$v} - 2) {
		
		# add linear deviation
		$d += (2 * $v->[$i + 1] - $v->[$i] - $v->[$i + 2])**2;
		
		# add outer magnitudes
		$s += abs($v->[$i]) + abs($v->[$i + 2]);
		
	}

	# return relative rms value
	return($s ? sqrt($d)/$s : 0);

}

# get file list
# parameter: (path)
# returns: (ref_to_file_list)
sub _files {

	# get path
	my $path = shift();

	# get list of files and/or directories
	my @files = grep {-e} File::Glob::bsd_glob($path);

	# if list is just one directory
	if (@files == 1 && -d $files[0]) {
	
		# get files in that directory
		@files = grep {-f} File::Glob::bsd_glob("$path/*");
	
	} else {
	
		# filter the files
		@files = grep {-f} @files;
	
	}

	# return file list
	return(\@files);

}

# get encoding CODE reference
# parameter(object_reference, hash)
# returns: (CODE_reference)
sub _encoding {

	# get parameters
	my ($self, $hash) = @_;

	# local variables
	my ($encoding, $size);

	# if hash contain 'encoding' value, but not 'XYZ', 'RGBV' or 'linear'
	if (defined($encoding = $hash->{'encoding'}) && $encoding !~ m/^(XYZ|RGBV|linear)$/) {
		
		# get output size
		$size = @{$self->[3][1]};
		
		# if encoding is 'ICC_XYZ'
		if ($encoding eq 'ICC_XYZ' && $size == 3) {
			
			# return code reference
			return(sub {map {$_ * 327.68/65535} @_});
			
		# if encoding is 'ICC_XYZNumber'
		} elsif ($encoding eq 'ICC_XYZNumber' && $size == 3) {
			
			# return code reference
			return(sub {map {$_/100} @_});
			
		# if encoding is 'xyz'
		} elsif ($encoding eq 'xyz' && $size == 3) {
			
			# verify white point
			($self->[5][0] && $self->[5][1] && $self->[5][2]) || croak('invalid illuminant white point');
			
			# return code reference
			return(sub {$_[0]/$self->[5][0], $_[1]/$self->[5][1], $_[2]/$self->[5][2]});
			
		# if encoding is 'unit'
		} elsif ($encoding eq 'unit' && $size == 4) {
			
			# return code reference
			return(sub {map {$_/100} @_});
			
		# if encoding is 'density'
		} elsif ($encoding eq 'density' && $size == 4) {
			
			# return code reference
			return(sub {map {$_ > 0 ? -POSIX::log10($_/100) : 99} @_});
			
		} else {
			
			# error
			croak('unsupported XYZ/RGBV encoding');
			
		}
		
	} else {
		
		# return empty
		return();
		
	}
	
}

# set object contents from parameter hash
# parameters: (object_reference, ref_to_parameter_hash)
sub _new_from_hash {

	# get parameters
	my ($self, $hash) = @_;

	# local variables
	my ($range, $ox);

	# save colorimetry hash in object header
	$self->[0] = Storable::dclone($hash);

	# if 'range' is defined
	if (defined($range = $hash->{'range'})) {
		
		# verify wavelength range structure
		(ref($range) eq 'ARRAY' && 3 == @{$range} && (3 == grep {Scalar::Util::looks_like_number($_)} @{$range})) || croak('invalid wavelength range structure');
		
		# compute upper index
		$ox = ICC::Shared::round(($range->[1] - $range->[0])/$range->[2]);
		
		# verify wavelength range values
		($ox > 0 && abs($ox * $range->[2] - $range->[1] + $range->[0]) < 1E-12 && $range->[2] > 0) || croak('invalid wavelength range values');
		
		# add range to hash
		$srh->{$ox + 1} = $range;
		
	}

	# if 'status' is defined, a scalar
	if (defined($hash->{'status'}) && ! ref($hash->{'status'})) {
		
		# read ISO 5-3 color-weight functions (density)
		_iso($self, $hash);
		
	# if 'illuminant' is defined, an ARRAY ref
	} elsif (defined($hash->{'illuminant'}) && ref($hash->{'illuminant'}) eq 'ARRAY') {
		
		# read CIE illuminant and color-matching functions, compute color-weight functions
		_cie($self, $hash);
		
	} else {
		
		# read ASTM color-weight functions
		_astm($self, $hash);
		
	}
	
}

1;

