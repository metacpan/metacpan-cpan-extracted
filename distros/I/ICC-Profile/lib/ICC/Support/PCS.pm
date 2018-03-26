package ICC::Support::PCS;

use strict;
use Carp;

our $VERSION = 0.73;

# revised 2017-07-08
#
# Copyright © 2004-2018 by William B. Birkett

# add development directory
use lib 'lib';

# inherit from Shared
use parent qw(ICC::Shared);

=encoding utf8

list of supported PCS connection spaces

    0 - 8-bit ICC CIELAB (100, 0, 0 => 255/255, 128/255, 128/255 = 1, 0.50196, 0.50196)
    0 - 16-bit ICC CIELAB (100, 0, 0 => 65535/65535, 32896/65535, 32896/65535 = 1, 0.50196, 0.50196)
    1 - 16-bit ICC legacy L*a*b* (100, 0, 0 => 65280/65535, 32768/65535, 32768/65535 = 0.99611, 0.50001, 0.50001)
    2 - 16-bit EFI/Monaco L*a*b* (100, 0, 0 => 65535/65535, 32768/65535, 32768/65535 = 1, 0.50001, 0.50001)
    3 - L*a*b* (100, 0, 0 => 100, 0, 0)
    4 - LxLyLz (100, 0, 0 => 100, 100, 100)
    5 - unit LxLyLz (100, 0, 0 => 1, 1, 1)
    6 - xyY (100, 0, 0 => 0.34570, 0.35854, 100)
    7 - 16-bit ICC XYZ (100, 0, 0 => 0.9642 * 32768/65535, 32768/65535, 0.8249 * 32768/65535 = 0.48211, 0.50001, 0.41246)
    8 - 32-bit ICC XYZNumber (100, 0, 0 => 0.9642, 1.0, 0.8249)
    9 - xyz (100, 0, 0 => 1, 1, 1)
    10 - XYZ (100, 0, 0 => 96.42, 100, 82.49)

explanation and application

    option 0 is for both 8-bit and 16-bit CIELAB encoding. it is listed twice to show the equivalence.
    option 1 is the 16-bit L*a*b* encoding from the v2 specification. option 1 also applies to mft2 and ncl2 tags within v4 profiles.
    option 2 is a non-standard L*a*b* encoding used by EFI and Monaco.
    option 3 is standard L*a*b* encoding, used in measurement files and floating point tags (e.g. D2Bx, B2Dx).
    option 4 is L* encoding of the xyz channels.
    option 5 is unit L* encoding of the xyz channels.
    option 6 is chromaticity plus Y.
    option 7 is the 16-bit XYZ encoding used by v2 and v4. 8-bit XYZ encoding is undefined by the ICC specification.
    option 8 is the 32-bit format used by XYZ tags, and the format used to set absolute colorimetry when creating PCS objects.
    option 9 is X/Xn, Y/Yn, Z/Zn, as defined in ISO 13655.
    option 10 is standard XYZ encoding, used in measurement files.

=cut

# make PCS connection object
# structure of the input/output parameter arrays is: (pcs_connection_space, [white_point, [black_point]])
# white point and black point values are optional. default values are D50 for white point and (0, 0, 0) for black point.
# white point and black point are encoded as ICC XYZNumbers, which is how they are stored within ICC profiles.
# for explanation of tone compression linearity, see 'tone_compression_notes.txt'.
# default tone compression linearity = 0 (linear tone compression).
# parameters: ()
# parameters: (ref_to_input_parameter_array, ref_to_output_parameter_array, [tone_compression_linearity])
sub new {

	# get object class
	my $class = shift();
	
	# create empty PCS object
	my $self = [
			{},		# object header
			[],		# parameter array
			[],		# tone compression array
			0		# clipping flag
	];
	
	# if 2 or 3 parameters
	if (@_ == 2 || @_ == 3) {
		
		# create new object from parameters
		_new_pcs($self, @_);
	
	# if any parameters
	} elsif (@_) {
		
		# error
		croak('wrong number of parameters');
		
	}
	
	# bless object
	bless($self, $class);
	
	# return object reference
	return($self);
	
}

# get/set clipping flag
# if flag is true, values are clipped
# parameters: ([new_flag_value])
# returns: (flag_value)
sub clip {
	
	# get object reference
	my $self = shift();
	
	# if there are parameters
	if (@_) {
		
		# if one parameter
		if (@_ == 1) {
			
			# set object clipping mask value
			$self->[3] = shift();
			
		} else {
			
			# error
			croak('more than one parameter');
			
		}
		
	}
	
	# return clipping mask value
	return($self->[3]);
	
}

# get/set tone compression linearity
# parameters: ([new_linearity_value])
# returns: (linearity_value)
sub linearity {
	
	# get object reference
	my $self = shift();
	
	# if there are parameters
	if (@_) {
		
		# if one parameter
		if (@_ == 1) {
			
			# set linearity value
			$self->[2][1] = shift();
			
			# update tone compression coefficients
			tc_pars($self);
			
		} else {
			
			# error
			croak('more than one parameter');
			
		}
		
	}
	
	# return linearity value
	return($self->[2][1]);
	
}

# set input/output gamut scale
# sets input/output black point vector to the white point vector x (1 - scale)
# a zero value leaves the corresponding black point unchanged
# parameters: (input_gamut_scale_factor, output_gamut_scale_factor)
sub scale {
	
	# get object reference
	my $self = shift();
	
	# verify parameters
	(@_ == 2 && 2 == grep {! ref()} @_) || croak('invalid scale inputs');
	
	# for input and output
	for my $i (0 .. 1) {
		
		# if gamut scale factor != 0, and white point defined
		if ($_[$i] != 0 && defined($self->[1][$i][1])) {
			
			# for XYZ
			for my $j (0 .. 2) {
				
				# set black point to scaled white point value
				$self->[1][$i][2][$j] = (1 - $_[$i]) * $self->[1][$i][1][$j];
				
			}
			
		}
		
	}
	
	# update tone compression coefficients
	tc_pars($self);
	
}

# transform data
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

# invert data
# supported input types:
# parameters: (list, [hash])
# parameters: (vector, [hash])
# parameters: (matrix, [hash])
# parameters: (Math::Matrix_object, [hash])
# parameters: (structure, [hash])
# returns: (same_type_as_input)
sub inverse {

	# set hash value (0 or 1)
	my $h = ref($_[-1]) eq 'HASH' ? 1 : 0;

	# if input a 'Math::Matrix' object
	if (@_ == $h + 2 && UNIVERSAL::isa($_[1], 'Math::Matrix')) {
		
		# call matrix transform
		&_inv2;
		
	# if input an array reference
	} elsif (@_ == $h + 2 && ref($_[1]) eq 'ARRAY') {
		
		# if array contains numbers (vector)
		if (! ref($_[1][0]) && @{$_[1]} == grep {Scalar::Util::looks_like_number($_)} @{$_[1]}) {
			
			# call vector transform
			&_inv1;
			
		# if array contains vectors (2-D array)
		} elsif (ref($_[1][0]) eq 'ARRAY' && @{$_[1]} == grep {ref($_) eq 'ARRAY' && Scalar::Util::looks_like_number($_->[0])} @{$_[1]}) {
			
			# call matrix transform
			&_inv2;
			
		} else {
			
			# call structure transform
			&_inv3;
			
		}
		
	# if input a list (of numbers)
	} elsif (@_ == $h + 1 + grep {Scalar::Util::looks_like_number($_)} @_) {
		
		# call list transform
		&_inv0;
		
	} else {
		
		# error
		croak('invalid transform input');
		
	}

}

# compute Jacobian matrix
# parameters: (input_vector, [hash])
# returns: (Jacobian_matrix, [output_vector])
sub jacobian {

	# get parameters
	my ($self, $in, $hash) = @_;

	# local variables
	my ($pcsi, $pcso, @t, @d, $jac);

	# verify 3 channels
	(@{$in} == 3) || croak('PCS object input not 3 channels');

	# get input PCS
	$pcsi = $self->[1][0][0];

	# get output PCS
	$pcso = $self->[1][1][0];

	# convert from input PCS
	@t = _rev($pcsi, @{$in});

	# compute _rev Jacobian
	$jac = _rev_jac($pcsi, @{$in});

	# if tone compression is required
	if ($self->[2][0]) {
		
		# if input PCS is L*a*b*
		if ($pcsi <= 5) {
			
			# apply Lab2xyz Jacobian
			$jac = ICC::Shared::Lab2xyz_jac(@t) * $jac;
			
			# convert to xyz
			@t = ICC::Shared::_Lab2xyz(@t);
			
		}
		
		# compute forward derivatives
		@d = _tc_derv($self, 0, @t);
		
		# for each output
		for my $i (0 .. 2) {
			
			# for each input
			for my $j (0 .. 2) {
				
				# adjust Jacobian
				$jac->[$i][$j] *= $d[$i];
				
			}
			
		}
		
		# compute forward tone compression
		@t = _tc($self, 0, @t);
		
		# if output PCS is L*a*b*
		if ($pcso <= 5) {
			
			# apply xyz2Lab Jacobian
			$jac = ICC::Shared::xyz2Lab_jac(@t) * $jac;
			
			# convert to L*a*b*
			@t = ICC::Shared::_xyz2Lab(@t);
			
		}
		
	# if input PCS is L*a*b* and output PCS is xyz
	} elsif ($pcsi <= 5 && $pcso >= 6) {
		
		# apply Lab2xyz Jacobian
		$jac = ICC::Shared::Lab2xyz_jac(@t) * $jac;
		
		# convert to xyz
		@t = ICC::Shared::_Lab2xyz(@t);
		
	# if input PCS is xyz and output PCS is L*a*b*
	} elsif ($pcsi >= 6 && $pcso <= 5) {
		
		# apply xyz2Lab Jacobian
		$jac = ICC::Shared::xyz2Lab_jac(@t) * $jac;
		
		# convert to L*a*b*
		@t = ICC::Shared::_xyz2Lab(@t);
		
	}

	# apply forward Jacobian
	$jac = _fwd_jac($pcso, @t) * $jac;

	# if output values wanted
	if (wantarray) {
		
		# return Jacobian and output values
		return($jac, [_fwd($pcso, $self->[3], @t)]);
		
	} else {
		
		# return Jacobian only
		return($jac);
		
	}
	
}

# compute tone compression coefficients
# parameters: (object_reference)
sub tc_pars {
	
	# get object reference
	my $self = shift();
	
	# local variables
	my ($lin, $elin);
	
	# set tc flag (true if tc required) 
	$self->[2][0] = grep {$self->[1][0][1][$_] != $self->[1][1][1][$_] || $self->[1][0][2][$_] != $self->[1][1][2][$_]} (0 .. 2);
	
	# if non-linear tone compression
	if ($lin = $self->[2][1]) {
		
		# compute value
		$elin = exp($lin);
		
		# for each xyz
		for my $i (0 .. 2) {
		
			# compute a = (exp(r) - exp(r * y0/y1))/(exp(r) - exp(r * x0/x1))
			$self->[2][2][$i] = ($elin - exp($lin * $self->[1][1][2][$i]/$self->[1][1][1][$i]))/($elin - exp($lin * $self->[1][0][2][$i]/$self->[1][0][1][$i]));
			
			# compute b = (1 - a) * exp(r)
			$self->[2][3][$i] = (1 - $self->[2][2][$i]) * $elin;
			
		}
		
	# else linear tone compression
	} else {
		
		# for each xyz
		for my $i (0 .. 2) {
			
			# compute a = (y1 - y0)/(x1 - x0)
			$self->[2][2][$i] = ($self->[1][1][1][$i] - $self->[1][1][2][$i])/($self->[1][0][1][$i] - $self->[1][0][2][$i]);
			
			# compute b = y1 - a * x1
			$self->[2][3][$i] = $self->[1][1][1][$i] - $self->[2][2][$i] * $self->[1][0][1][$i];
			
		}
		
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

	# transform single value
	return(_transform($self, 0, @_));

}

# transform vector
# parameters: (object_reference, vector, [hash])
# returns: (vector)
sub _trans1 {

	# get parameters
	my ($self, $in, $hash) = @_;

	# transform vector
	return([_transform($self, 0, @{$in})]);

}

# transform matrix (2-D array -or- Math::Matrix object)
# parameters: (object_reference, matrix, [hash])
# returns: (matrix)
sub _trans2 {

	# get parameters
	my ($self, $in, $hash) = @_;

	# local variable
	my ($out);

	# for each sample
	for my $i (0 .. $#{$in}) {
		
		# transform sample
		$out->[$i] = [_transform($self, 0, @{$in->[$i]})];
		
	}

	# return
	return(UNIVERSAL::isa($in, 'Math::Matrix') ? bless($out, 'Math::Matrix') : $out);

}

# transform structure
# parameters: (object_reference, structure, [hash])
# returns: (structure)
sub _trans3 {

	# get parameters
	my ($self, $in, $hash) = @_;

	# transform the array structure
	_crawl($self, $in, my $out = [], $hash);

	# return
	return($out);

}

# recursive transform
# array structure is traversed until scalar arrays are found and transformed
# parameters: (ref_to_object, ref_to_input_array, ref_to_output_array, hash)
sub _crawl {

	# get parameters
	my ($self, $in, $out, $hash) = @_;

	# if input is a vector (reference to a scalar array)
	if (@{$in} == grep {! ref()} @{$in}) {
		
		# transform input vector and copy to output
		@{$out} = @{_trans1($self, $in, $hash)};
		
	} else {
		
		# for each input element
		for my $i (0 .. $#{$in}) {
			
			# if an array reference
			if (ref($in->[$i]) eq 'ARRAY') {
				
				# transform next level
				_crawl($self, $in->[$i], $out->[$i] = [], $hash);
				
			} else {
				
				# error
				croak('invalid transform input');
				
			}
			
		}
		
	}
	
}

# invert list
# parameters: (object_reference, list, [hash])
# returns: (list)
sub _inv0 {

	# local variables
	my ($self, $hash);

	# get object reference
	$self = shift();

	# get optional hash
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# invert single value
	return(_transform($self, 1, @_));

}

# invert vector
# parameters: (object_reference, vector, [hash])
# returns: (vector)
sub _inv1 {

	# get parameters
	my ($self, $in, $hash) = @_;

	# invert vector
	return([_transform($self, 1, @{$in})]);

}

# invert matrix (2-D array -or- Math::Matrix object)
# parameters: (object_reference, matrix, [hash])
# returns: (matrix)
sub _inv2 {

	# get parameters
	my ($self, $in, $hash) = @_;

	# local variable
	my ($out);

	# for each sample
	for my $i (0 .. $#{$in}) {
		
		# invert sample
		$out->[$i] = [_transform($self, 1, @{$in->[$i]})];
		
	}

	# return
	return(UNIVERSAL::isa($in, 'Math::Matrix') ? bless($out, 'Math::Matrix') : $out);

}

# invert structure
# parameters: (object_reference, structure, [hash])
# returns: (structure)
sub _inv3 {

	# get parameters
	my ($self, $in, $hash) = @_;

	# invert the array structure
	_crawl2($self, $in, my $out = [], $hash);

	# return
	return($out);

}

# recursive transform
# array structure is traversed until scalar arrays are found and inverted
# parameters: (ref_to_object, ref_to_input_array, ref_to_output_array, hash)
sub _crawl2 {

	# get parameters
	my ($self, $in, $out, $hash) = @_;

	# if input is a vector (reference to a scalar array)
	if (@{$in} == grep {! ref()} @{$in}) {
		
		# invert input vector and copy to output
		@{$out} = @{_inv1($in, $hash)};
		
	} else {
		
		# for each input element
		for my $i (0 .. $#{$in}) {
			
			# if an array reference
			if (ref($in->[$i]) eq 'ARRAY') {
				
				# invert next level
				_crawl($self, $in->[$i], $out->[$i] = [], $hash);
				
			} else {
				
				# error
				croak('invalid inverse input');
				
			}
			
		}
		
	}
	
}

# transform sample data
# direction: 0 - normal, 1 - inverse
# parameters: (object_reference, direction, array_of_input_values)
# returns: (array_of_output_values)
sub _transform {

	# get parameters
	my ($self, $dir, @in) = @_;

	# local variables
	my ($i, $pcsi, $pcso, @t);

	# verify 3 input channels
	(@in == 3) || croak('PCS object input not 3 channels');

	# get input PCS
	$pcsi = $self->[1][$dir][0];

	# get output PCS
	$pcso = $self->[1][1 - $dir][0];

	# convert from input PCS
	@t = _rev($pcsi, @in);

	# if tone compression required
	if ($self->[2][0]) {
		
		# convert to xyz if input PCS is L*a*b*
		@t = ICC::Shared::_Lab2xyz(@t) if ($pcsi <= 5);
		
		# tone compression
		@t = _tc($self, $dir, @t);
		
		# convert to L*a*b* if output PCS is L*a*b*
		@t = ICC::Shared::_xyz2Lab(@t) if ($pcso <= 5);
		
	# if input PCS is L*a*b* and output PCS is xyz
	} elsif ($pcsi <= 5 && $pcso >= 6) {
		
		# convert to xyz
		@t = ICC::Shared::_Lab2xyz(@t);
		
	# if input PCS is xyz and output PCS is L*a*b*
	} elsif ($pcsi >= 6 && $pcso <= 5) {
		
		# convert to L*a*b*
		@t = ICC::Shared::_xyz2Lab(@t);
		
	}

	# convert to output PCS and return
	return(_fwd($pcso, $self->[3], @t));

}

# convert to output PCS
# input values are either L*a*b* or xyz, depending on PCS
# parameters: (PCS, clipping_flag, array_of_input_values)
# returns: (array_of_output_values)
sub _fwd {

	# get parameters
	my ($pcs, $clip, @in) = @_;

	# local variable
	my ($denom);

	# if 8-bit ICC CIELAB or 16-bit ICC CIELAB
	if ($pcs == 0) {
		
		# if clipping flag set
		if ($clip) {
			
			# return clipped ICC CIELAB values
			return(map {$_ < 0 ? 0 : ($_ > 1 ? 1 : $_)} $in[0]/100, ($in[1] + 128)/255, ($in[2] + 128)/255);
			
		} else {
			
			# return ICC CIELAB values
			return($in[0]/100, ($in[1] + 128)/255, ($in[2] + 128)/255);
			
		}
		
	# if 16-bit ICC legacy L*a*b*
	} elsif ($pcs == 1) {
		
		# if clipping flag set
		if ($clip) {
			
			# clip L* value
			$in[0] = $in[0] > 100 ? 100 : $in[0];
			
			# return clipped 16-bit ICC legacy L*a*b* values
			return(map {$_ < 0 ? 0 : ($_ > 1 ? 1 : $_)} $in[0] * 256/25700, ($in[1] + 128) * 256/65535, ($in[2] + 128) * 256/65535);
			
		} else {
			
			# return 16-bit ICC legacy L*a*b* values
			return($in[0] * 256/25700, ($in[1] + 128) * 256/65535, ($in[2] + 128) * 256/65535);
			
		}
		
	# if 16-bit ICC EFI/Monaco L*a*b*
	} elsif ($pcs == 2) {
		
		# if clipping flag set
		if ($clip) {
			
			# return clipped 16-bit ICC EFI/Monaco L*a*b* values
			return(map {$_ < 0 ? 0 : ($_ > 1 ? 1 : $_)} $in[0]/100, ($in[1] + 128) * 256/65535, ($in[2] + 128) * 256/65535);
			
		} else {
			
			# return 16-bit ICC EFI/Monaco L*a*b* values
			return($in[0]/100, ($in[1] + 128) * 256/65535, ($in[2] + 128) * 256/65535);
			
		}
		
	# if L*a*b*
	} elsif ($pcs == 3) {
		
		# return L*a*b* values
		return(@in);
		
	# if LxLyLz
	} elsif ($pcs == 4) {
		
		# return LxLyLz values
		return($in[0] + 116 * $in[1]/500, $in[0], $in[0] - 116 * $in[2]/200);
		
	# if unit LxLyLz
	} elsif ($pcs == 5) {
		
		# return unit LxLyLz values
		return(map {$_/100} ($in[0] + 116 * $in[1]/500, $in[0], $in[0] - 116 * $in[2]/200));
		
	# if xyY
	} elsif ($pcs == 6) {
		
		# compute denominator (X + Y + Z)
		$denom = (96.42 * $in[0] + 100 * $in[1] + 82.49 * $in[2]);
		
		# return xyY values
		return($denom ? (96.42 * $in[0]/$denom, 100 * $in[1]/$denom, 100 * $in[1]) : (0, 0, 0));
		
	# if 16-bit ICC XYZ
	} elsif ($pcs == 7) {
		
		# if clipping flag set
		if ($clip) {
			
			# return clipped 16-bit ICC XYZ values
			return(map {$_ < 0 ? 0 : ($_ > 1 ? 1 : $_)} $in[0] * 0.482107356374456, $in[1] * 0.500007629510948, $in[2] * 0.412456293583581);
			
		} else {
			
			# return 16-bit ICC XYZ values
			return($in[0] * 0.482107356374456, $in[1] * 0.500007629510948, $in[2] * 0.412456293583581);
			
		}
		
	# if 32-bit ICC XYZNumber
	} elsif ($pcs == 8) {
		
		# return 32-bit ICC XYZNumber
		return($in[0] * 0.9642, $in[1], $in[2] * 0.8249);
		
	# if xyz
	} elsif ($pcs == 9) {
		
		# return xyz values
		return(@in);
		
	# if XYZ
	} elsif ($pcs == 10) {
		
		# return XYZ values
		return($in[0] * 96.42, $in[1] * 100, $in[2] * 82.49);
		
	} else {
		
		# error
		croak('unsupported PCS color space');
		
	}
	
}

# convert from input PCS
# output values are either L*a*b* or xyz, depending on PCS
# parameters: (PCS, array_of_input_values)
# returns: (array_of_output_values)
sub _rev {

	# get parameters
	my ($pcs, @in) = @_;

	# local variable
	my ($denom);

	# if 8-bit ICC CIELAB or 16-bit ICC CIELAB
	if ($pcs == 0) {
		
		# return L*a*b*
		return($in[0] * 100, $in[1] * 255 - 128, $in[2] * 255 - 128);
		
	# if 16-bit ICC legacy L*a*b*
	} elsif ($pcs == 1) {
		
		# return L*a*b*
		return($in[0] * 25700/256, $in[1] * 65535/256 - 128, $in[2] * 65535/256 - 128);
		
	# if 16-bit EFI/Monaco L*a*b*
	} elsif ($pcs == 2) {
		
		# return L*a*b*
		return($in[0] * 100, $in[1] * 65535/256 - 128, $in[2] * 65535/256 - 128);
		
	# if L*a*b*
	} elsif ($pcs == 3) {
		
		# return L*a*b*
		return(@in);
		
	# if LxLyLz
	} elsif ($pcs == 4) {
		
		# return L*a*b*
		return($in[1], 500 * ($in[0] - $in[1])/116, 200 * ($in[1] - $in[2])/116);
		
	# if unit LxLyLz
	} elsif ($pcs == 5) {
		
		# return L*a*b*
		return(map {$_ * 100} ($in[1], 500 * ($in[0] - $in[1])/116, 200 * ($in[1] - $in[2])/116));
		
	# if xyY
	} elsif ($pcs == 6) {
		
		# compute denominator (X + Y + Z)
		$denom = $in[1] ? $in[2]/$in[1] : 0;
		
		# return xyz
		return($in[0] * $denom/96.42, $in[1] * $denom/100, (1 - $in[0] - $in[1]) * $denom/82.49);
		
	# if 16-bit ICC XYZ
	} elsif ($pcs == 7) {
		
		# return xyz
		return($in[0]/0.482107356374456, $in[1]/0.500007629510948, $in[2]/0.412456293583581);
		
	# if ICC XYZNumber
	} elsif ($pcs == 8) {
		
		# return xyz
		return($in[0]/0.9642, $in[1], $in[2]/0.8249);
		
	# if xyz
	} elsif ($pcs == 9) {
		
		# return xyz
		return(@in);
		
	# if XYZ
	} elsif ($pcs == 10) {
		
		# return xyz
		return($in[0]/96.42, $in[1]/100, $in[2]/82.49);
		
	} else {
		
		# error
		croak('unsupported PCS color space');
		
	}
	
}

# compute Jacobian matrix for forward transform
# input values are either L*a*b* or xyz, depending on PCS
# parameters: (PCS, array_of_input_values)
# returns: (Jacobian_matrix)
sub _fwd_jac {

	# get parameters
	my ($pcs, @in) = @_;

	# local variables
	my ($denom, @out);

	# if 8-bit ICC CIELAB or 16-bit ICC CIELAB
	if ($pcs == 0) {
		
		# return Jacobian matrix
		return(Math::Matrix->new(
			[1/100, 0, 0],
			[0, 1/255, 0],
			[0, 0, 1/255]
		));
		
	# if 16-bit ICC legacy L*a*b*
	} elsif ($pcs == 1) {
		
		# return Jacobian matrix
		return(Math::Matrix->new(
			[256/25700, 0, 0],
			[0, 256/65535, 0],
			[0, 0, 256/65535]
		));
		
	# if 16-bit ICC EFI/Monaco L*a*b*
	} elsif ($pcs == 2) {
		
		# return Jacobian matrix
		return(Math::Matrix->new(
			[1/100, 0, 0],
			[0, 256/65535, 0],
			[0, 0, 256/65535]
		));
		
	# if L*a*b*
	} elsif ($pcs == 3) {
		
		# return Jacobian matrix
		return(Math::Matrix->new(
			[1, 0, 0],
			[0, 1, 0],
			[0, 0, 1]
		));
		
	# if LxLyLz
	} elsif ($pcs == 4) {
		
		# return Jacobian matrix
		return(Math::Matrix->new(
			[1, 116/500, 0],
			[1, 0, 0],
			[1, 0, -116/200]
		));
		
	# if unit LxLyLz
	} elsif ($pcs == 5) {
		
		# return Jacobian matrix
		return(Math::Matrix->new(
			[1/100, 116/50000, 0],
			[1/100, 0, 0],
			[1/100, 0, -116/20000]
		));
		
	# if xyY
	} elsif ($pcs == 6) {
		
		# if denominator (X + Y + Z) is non-zero
		if ($denom = (96.42 * $in[0] + 100 * $in[1] + 82.49 * $in[2])) {
			
			# compute output vector
			@out = (96.42 * $in[0]/$denom, 100 * $in[1]/$denom, 100 * $in[1]);
		
			# return Jacobian matrix
			return(Math::Matrix->new(
				[96.42 * (1 - $out[0])/$denom, -100 * $out[0]/$denom, -82.49 * $out[0]/$denom],
				[-96.42 * $out[1]/$denom, 100 * (1 - $out[1])/$denom, -82.49 * $out[1]/$denom],
				[0, 100, 0]
			));
			
		} else {
			
			# print warning
			print "Jacobian matrix overflow!\n";
			
			# return Jacobian matrix
			return(Math::Matrix->new(
				['inf', '-inf', '-inf'],
				['-inf', 'inf', '-inf'],
				[0, 100, 0]
			));
			
		}
		
	# if 16-bit ICC XYZ
	} elsif ($pcs == 7) {
		
		# return Jacobian matrix
		return(Math::Matrix->new(
			[0.482107356374456, 0, 0],
			[0, 0.500007629510948, 0],
			[0, 0, 0.412456293583581]
		));
		
	# if 32-bit ICC XYZNumber
	} elsif ($pcs == 8) {
		
		# return Jacobian matrix
		return(Math::Matrix->new(
			[0.9642, 0, 0],
			[0, 1, 0],
			[0, 0, 0.8249]
		));
		
	# if xyz
	} elsif ($pcs == 9) {
		
		# return Jacobian matrix
		return(Math::Matrix->new(
			[1, 0, 0],
			[0, 1, 0],
			[0, 0, 1]
		));
		
	# if XYZ
	} elsif ($pcs == 10) {
		
		# return Jacobian matrix
		return(Math::Matrix->new(
			[96.42, 0, 0],
			[0, 100, 0],
			[0, 0, 82.49]
		));
		
	} else {
		
		# error
		croak('unsupported PCS color space');
		
	}
	
}

# compute Jacobian matrix for reverse transform
# output values are either L*a*b* or xyz, depending on PCS
# parameters: (PCS, array_of_input_values)
# returns: (Jacobian_matrix)
sub _rev_jac {

	# get parameters
	my ($pcs, @in) = @_;

	# local variables
	my ($denom, $xr, $zr);

	# if 8-bit ICC CIELAB or 16-bit ICC CIELAB
	if ($pcs == 0) {
		
		# return Jacobian matrix
		return(Math::Matrix->new(
			[100, 0, 0],
			[0, 255, 0],
			[0, 0, 255]
		));
		
	# if 16-bit ICC legacy L*a*b*
	} elsif ($pcs == 1) {
		
		# return Jacobian matrix
		return(Math::Matrix->new(
			[25700/256, 0, 0],
			[0, 65535/256, 0],
			[0, 0, 65535/256]
		));
		
	# if 16-bit EFI/Monaco L*a*b*
	} elsif ($pcs == 2) {
		
		# return Jacobian matrix
		return(Math::Matrix->new(
			[100, 0, 0],
			[0, 65535/256, 0],
			[0, 0, 65535/256]
		));
		
	# if L*a*b*
	} elsif ($pcs == 3) {
		
		# return Jacobian matrix
		return(Math::Matrix->new(
			[1, 0, 0],
			[0, 1, 0],
			[0, 0, 1]
		));
		
	# if LxLyLz
	} elsif ($pcs == 4) {
		
		# return Jacobian matrix
		return(Math::Matrix->new(
			[0, 1, 0],
			[500/116, -500/116, 0],
			[0, 200/116, -200/116]
		));
		
	# if unit LxLyLz
	} elsif ($pcs == 5) {
		
		# return Jacobian matrix
		return(Math::Matrix->new(
			[0, 100, 0],
			[50000/116, -50000/116, 0],
			[0, 20000/116, -20000/116]
		));
		
	# if xyY
	} elsif ($pcs == 6) {
		
		# if y not zero
		if ($in[1]) {
			
			# compute denominator (X + Y + Z)
			$denom = $in[2]/$in[1];
			
			# compute ratios
			$xr = $in[0]/$in[1];
			$zr = (1 - $in[0])/$in[1];
			
			# return Jacobian matrix
			return(Math::Matrix->new(
				[$denom/96.42, -$denom * $xr/96.42, $xr/96.42],
				[0, 0, 1/100],
				[-$denom/82.49, -$denom * $zr/82.49, ($zr - 1)/82.49]
			));
			
		} else {
			
			# print warning
			print "Jacobian matrix overflow!\n";
			
			# return Jacobian matrix
			return(Math::Matrix->new(
				['inf', '-inf', 'inf'],
				[0, 0, 1/100],
				['-inf', '-inf', 'inf']
			));
			
		}
		
	# if 16-bit ICC XYZ
	} elsif ($pcs == 7) {
		
		# return Jacobian matrix
		return(Math::Matrix->new(
			[2.074226801931005, 0, 0],
			[0, 1.999969482421875, 0],
			[0, 0, 2.424499311943114]
		));
		
	# if ICC XYZNumber
	} elsif ($pcs == 8) {
		
		# return Jacobian matrix
		return(Math::Matrix->new(
			[1/0.9642, 0, 0],
			[0, 1, 0],
			[0, 0, 1/0.8249]
		));
		
	# if xyz
	} elsif ($pcs == 9) {
		
		# return Jacobian matrix
		return(Math::Matrix->new(
			[1, 0, 0],
			[0, 1, 0],
			[0, 0, 1]
		));
		
	# if XYZ
	} elsif ($pcs == 10) {
		
		# return Jacobian matrix
		return(Math::Matrix->new(
			[1/96.42, 0, 0],
			[0, 1/100, 0],
			[0, 0, 1/82.49]
		));
		
	} else {
		
		# error
		croak('unsupported PCS color space');
		
	}
	
}

# forward tone compression derivative
# input and output values are xyz
# parameters: (object_reference, direction, array_of_input_values)
# returns: (array_of_output values)
sub _tc_derv {
	
	# get parameters
	my ($self, $dir, @in) = @_;
	
	# local variables
	my ($lin, @out, $t, $u);
	
	# if non-linear tone compression
	if ($lin = $self->[2][1]) {
		
		# if reverse direction
		if ($dir) {
			
			# for each xyz
			for my $i (0 .. 2) {
				
				# compute t = (exp(r * y/y1) - b)/a
				$t = (exp($lin * $in[$i]/$self->[1][1][1][$i]) - $self->[2][3][$i])/$self->[2][2][$i];
				
				# compute u = x1/y1
				$u = $self->[1][0][1][$i]/$self->[1][1][1][$i];
				
				# compute x = u * a * exp(r * y/y1)/exp(r * x/x1)
				$out[$i] = $t == 0 ? 1E99 : $u * $self->[2][2][$i] * exp($lin * $in[$i]/$self->[1][1][1][$i])/$t;
				
			}
			
		} else {
			
			# for each xyz
			for my $i (0 .. 2) {
				
				# compute t = exp(r * x/x1) * a + b
				$t = exp($lin * $in[$i]/$self->[1][0][1][$i]) * $self->[2][2][$i] + $self->[2][3][$i];
				
				# compute u = y1/x1
				$u = $self->[1][1][1][$i]/$self->[1][0][1][$i];
				
				# compute x = u * a * (exp(r * x/x1)/exp(r * y/y1))
				$out[$i] = $t == 0 ? 1E99 : $u * $self->[2][2][$i] * exp($lin * $in[$i]/$self->[1][0][1][$i])/$t;
				
			}
			
		}
		
	# if linear tone compression
	} else {
		
		# if reverse direction
		if ($dir) {
			
			# for each xyz
			for my $i (0 .. 2) {
				
				# compute y = 1/a
				$out[$i] = $self->[2][2][$i] == 0 ? 1E99 : 1/$self->[2][2][$i];
				
			}
			
		} else {
			
			# for each xyz
			for my $i (0 .. 2) {
				
				# compute y = a
				$out[$i] = $self->[2][2][$i];
				
			}
			
		}
		
	}

	# return
	return(@out);
	
}

# tone compression transform
# input and output values are xyz
# parameters: (object_reference, direction, array_of_input_values)
# returns: (array_of_output values)
sub _tc {
	
	# get parameters
	my ($self, $dir, @in) = @_;
	
	# local variables
	my ($lin, @out, $t);
	
	# if non-linear tone compression
	if ($lin = $self->[2][1]) {
		
		# if reverse direction
		if ($dir) {
			
			# for each xyz
			for my $i (0 .. 2) {
				
				# compute t = (exp(r * y/y1) - b)/a
				$t = (exp($lin * $in[$i]/$self->[1][1][1][$i]) - $self->[2][3][$i])/$self->[2][2][$i];
				
				# compute x = ln(t) * x1/r
				$out[$i] = $t > 0 ? log($t) * $self->[1][0][1][$i]/$lin : -1E99;
				
			}
			
		} else {
			
			# for each xyz
			for my $i (0 .. 2) {
				
				# compute t = exp(r * x/x1) * a + b
				$t = exp($lin * $in[$i]/$self->[1][0][1][$i]) * $self->[2][2][$i] + $self->[2][3][$i];
				
				# compute y = ln(t) * y1/r
				$out[$i] = $t > 0 ? log($t) * $self->[1][1][1][$i]/$lin : -1E99;
				
			}
			
		}
		
	# else linear tone compression
	} else {
		
		# if reverse direction
		if ($dir) {
			
			# for each xyz
			for my $i (0 .. 2) {
				
				# compute y = (x - b)/a
				$out[$i] = $self->[2][2][$i] == 0 ? 1E99 : ($in[$i] - $self->[2][3][$i])/$self->[2][2][$i];
				
			}
			
		} else {
			
			# for each xyz
			for my $i (0 .. 2) {
				
				# compute y = ax + b
				$out[$i] = $in[$i] * $self->[2][2][$i] + $self->[2][3][$i];
				
			}
			
		}
		
	}
	
	# return
	return(@out);
	
}

# make PCS connection object from parameters
# structure of the input/output parameter arrays is: (pcs_connection_space, [white_point, [black_point]])
# parameters: (object_reference, ref_to_input_parameter_array, ref_to_output_parameter_array, [tone_compression_linearity])
sub _new_pcs {

	# get object reference
	my ($self) = shift();

	# local variables
	my (@cs, @io);

	# list of supported connection spaces
	@cs = (0 .. 10);

	# message labels
	@io = qw(input output);

	# for input and output parameters
	for my $i (0 .. 1) {
		
		# verify parameter is an array reference
		(ref($_[$i]) eq 'ARRAY') || croak("$io[$i] parameter not an array reference");
		
		# verify number of array parameters
		(@{$_[$i]} >= 1 || @{$_[$i]} <= 3) || croak("$io[$i] array has wrong number parameters");
		
		# verify color space
		(grep {$_[$i][0] == $_} @cs) || croak("$io[$i] color space not supported");
		
		# copy color space
		$self->[1][$i][0] = $_[$i][0];
		
		# if white point is defined
		if (defined($_[$i][1])) {
			
			# verify white point is an array reference
			(ref($_[$i][1]) eq 'ARRAY') || croak("$io[$i] white point not an array reference");
			
			# verify array structure
			(3 == grep {! ref()} @{$_[$i][1]}) || croak("$io[$i] white point array has wrong structure");
			
			# copy white point (converting XYZNumber to xyz)
			$self->[1][$i][1] = [$_[$i][1][0]/ICC::Shared::d50->[0], $_[$i][1][1]/ICC::Shared::d50->[1], $_[$i][1][2]/ICC::Shared::d50->[2]];
			
		} else {
			
			# set white point to perfect white
			$self->[1][$i][1] = [1, 1, 1];
			
		}
		
		# if black point is defined
		if (defined($_[$i][2])) {
			
			# verify black point is an array reference
			(ref($_[$i][2]) eq 'ARRAY') || croak("$io[$i] black point not an array reference");
			
			# verify array structure
			(3 == grep {! ref()} @{$_[$i][2]}) || croak("$io[$i] black point array has wrong structure");
			
			# copy black point (converting XYZNumber to xyz)
			$self->[1][$i][2] = [$_[$i][2][0]/ICC::Shared::d50->[0], $_[$i][2][1]/ICC::Shared::d50->[1], $_[$i][2][2]/ICC::Shared::d50->[2]];
			
		} else {
			
			# set black point to perfect black
			$self->[1][$i][2] = [0, 0, 0];
			
		}
		
	}

	# set tone compression linearity (default = 0)
	$self->[2][1] = defined($_[2]) ? $_[2] : 0;

	# compute tone compression coefficients
	tc_pars($self);

}

1;

