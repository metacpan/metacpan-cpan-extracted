package ICC::Profile::gbd_;

use strict;
use Carp;

our $VERSION = 0.12;

# revised 2016-05-17
#
# Copyright © 2004-2018 by William B. Birkett

# add development directory
use lib 'lib';

# inherit from Shared
use parent qw(ICC::Shared);

# create new gbd_ object
# hash keys are: ('vertex', 'pcs', 'device')
# 'vertex', 'pcs' and 'device' values are 2D array references -or- Math::Matrix objects
# each 'vertex' row contains an array of 3 indices defining a gamut face
# these indices address the 'pcs' and optional 'device' coordinate arrays
# parameters: ([ref_to_attribute_hash])
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();

	# create empty gbd_ object
	# index 4 reserved for cache
	# index 5 reserved for index
	my $self = [
		{},    # header
		[],    # face vertex IDs
		[],    # pcs coordinates
		[]     # device coordinates
	];
	
	# local parameter
	my ($info);

	# if there are parameters
	if (@_) {
		
		# if one parameter, a hash reference
		if (@_ == 1 && ref($_[0]) eq 'HASH') {
			
			# make new gbd_ object from attribute hash
			_new_from_hash($self, shift());
			
		} else {
			
			# error
			croak('\'gbd_\' invalid parameter(s)');
			
		}
		
	}

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

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
			$self->[0] = {%{shift()}};
			
		} else {
			
			# error
			croak('\'gbd_\' header attribute must be a hash reference');
			
		}
		
	}
	
	# return header reference
	return($self->[0]);
	
}

# get/set reference to vertex array
# parameters: ([ref_to_new_array])
# returns: (ref_to_array)
sub vertex {

	# get object reference
	my $self = shift();

	# if there are parameters
	if (@_) {
		
		# if one parameter, a 2-D array reference
		if (@_ == 1 && ref($_[0]) eq 'ARRAY' && @{$_[0]} == grep {ref() eq 'ARRAY'} @{$_[0]}) {
			
			# set vertex to clone of array
			$self->[1] = bless(Storable::dclone($_[0]), 'Math::Matrix');
			
		# if one parameter, a Math::Matrix object
		} elsif (@_ == 1 && UNIVERSAL::isa($_[0], 'Math::Matrix')) {
			
			# set vertex to object
			$self->[1] = $_[0];
			
		} else {
			
			# error
			croak('gbd_ vertex must be a 2-D array reference or Math::Matrix object');
			
		}
		
	}

	# return object reference
	return($self->[1]);

}

# get/set reference to pcs array
# parameters: ([ref_to_new_array])
# returns: (ref_to_array)
sub pcs {

	# get object reference
	my $self = shift();

	# if there are parameters
	if (@_) {
		
		# if one parameter, a 2-D array reference
		if (@_ == 1 && ref($_[0]) eq 'ARRAY' && @{$_[0]} == grep {ref() eq 'ARRAY'} @{$_[0]}) {
			
			# set pcs to clone of array
			$self->[2] = bless(Storable::dclone($_[0]), 'Math::Matrix');
			
		# if one parameter, a Math::Matrix object
		} elsif (@_ == 1 && UNIVERSAL::isa($_[0], 'Math::Matrix')) {
			
			# set pcs to object
			$self->[2] = $_[0];
			
		} else {
			
			# error
			croak('gbd_ pcs must be a 2-D array reference or Math::Matrix object');
			
		}
		
	}

	# return object reference
	return($self->[2]);

}

# get/set reference to device array
# parameters: ([ref_to_new_array])
# returns: (ref_to_array)
sub device {

	# get object reference
	my $self = shift();

	# if there are parameters
	if (@_) {
		
		# if one parameter, a 2-D array reference
		if (@_ == 1 && ref($_[0]) eq 'ARRAY' && @{$_[0]} == grep {ref() eq 'ARRAY'} @{$_[0]}) {
			
			# set device to clone of array
			$self->[3] = bless(Storable::dclone($_[0]), 'Math::Matrix');
			
		# if one parameter, a Math::Matrix object
		} elsif (@_ == 1 && UNIVERSAL::isa($_[0], 'Math::Matrix')) {
			
			# set device to object
			$self->[3] = $_[0];
			
		} else {
			
			# error
			croak('gbd_ device must be a 2-D array reference or Math::Matrix object');
			
		}
		
	}

	# return object reference
	return($self->[3]);

}

# test an array of samples against gamut
# the point inside the gamut my be supplied,
# otherwise it is computed from the gamut data
# result is an array, [[radius, intersect_point, face_ID], [...]]
# if radius == 1, sample is on the gamut surface
# if radius > 1, sample is inside the gamut
# if radius < 1, sample is out-of-gamut
# parameters: (sample_array, [point_inside_gamut])
# returns: (result_array)
sub test {

	# get parameters
	my ($self, $samples, $p0) = @_;

	# local variables
	my ($m, $n, $ps, $i, $j, $faces, $info, $r, $px, $result);

	# if parameter is undefined
	if (! defined($p0)) {
		
		# if defined in header
		if (defined($self->[0]{'p0'}) && defined($self->[5])) {
			
			# use header value
			$p0 = $self->[0]{'p0'};
			
		} else {
			
			# use mean value of vertices
			$p0 = ICC::Support::Lapack::mean($self->[2]);
			
		}
		
	# if parameter is defined, but different from header value
	} elsif (defined($self->[0]{'p0'}) && ($self->[0]{'p0'}[0] != $p0->[0] || $self->[0]{'p0'}[1] != $p0->[1] || $self->[0]{'p0'}[2] != $p0->[2])) {
		
		# undefine spherical index to force re-calculation
		undef($self->[5]);
		
	}

	# if spherical index defined
	if (defined($self->[5])) {
		
		# get index array size
		$m = @{$self->[5]};
		$n = @{$self->[5][0]};
		
	} else {
		
		# compute index grid size
		$m = $n = int(@{$self->[1]}**(1/3));
		
		# make spherical index
		_make_index($self, $p0, $m, $n) ;
		
	}

	# for each sample
	for my $s (0 .. $#{$samples}) {
		
		# get sample
		$ps = $samples->[$s];
		
		# compute spherical indices
		$i = int($m * atan2(sqrt(($ps->[1] - $p0->[1])**2 + ($ps->[2] - $p0->[2])**2), $ps->[0] - $p0->[0])/ICC::Shared::PI);
		$j = int($n * (atan2($ps->[2] - $p0->[2], $ps->[1] - $p0->[1])/ICC::Shared::PI + 1)/2);
		
		# limit indices
		$i = $i < $m ? $i : $m - 1;
		$j = $j < $n ? $j : 0;
		
		# get face ID list from spherical index
		$faces = $self->[5][$i][$j];
		
		# for each gamut face
		for my $f (@{$faces}) {
			
			# find intersection, if a new face
			($info, $r, $px) = intersect($self, $f, $p0, $ps);
			
			# if intersect found
			if ($info == 0) {
				
				# save result
				$result->[$s] = [$r, $px, $f];
				
				# quit loop
				last;
				
			}
			
		}
		
	}

	# return
	return($result);

}

# compute intersection of line segment with face triangle
# the radius is 0 at point_0, and 1 at point_1
# parameters: (face_ID, point_0, point_1)
# returns: (info, radius, point_intersect)
sub intersect {

	# get parameters
	my ($self, $fid, $p0, $p1) = @_;

	# local variables
	my ($v0, $v1, $v2, $u, $v, $n, $dir, $w, $w0, $r, $a, $b);
	my ($px, $uu, $uv, $vv, $wu, $wv, $d, $s, $t);

	# if face values are cached
	if (defined($self->[4][$fid])) {
		
		# get face vertex
		$v0 = $self->[2][$self->[1][$fid][0]];
		
		# get face values
		($u, $v, $n, $uu, $uv, $vv) = @{$self->[4][$fid]};
		
	} else {
		
		# get face vertices
		$v0 = $self->[2][$self->[1][$fid][0]];
		$v1 = $self->[2][$self->[1][$fid][1]];
		$v2 = $self->[2][$self->[1][$fid][2]];
		
		# compute triangle edge vectors
		$u = [$v1->[0] - $v0->[0], $v1->[1] - $v0->[1], $v1->[2] - $v0->[2]];
		$v = [$v2->[0] - $v0->[0], $v2->[1] - $v0->[1], $v2->[2] - $v0->[2]];
		
		# compute normal vector
		$n = ICC::Shared::crossProduct($u, $v);
		
		# compute barycentric dot products
		$uu = ICC::Shared::dotProduct($u, $u);
		$uv = ICC::Shared::dotProduct($u, $v);
		$vv = ICC::Shared::dotProduct($v, $v);
		
		# cache face values
		$self->[4][$fid] = [$u, $v, $n, $uu, $uv, $vv];
		
	}

	# check for degenerate triangle
	return(-1) if ($n->[0] == 0 && $n->[1] == 0 && $n->[2] == 0);

	# compute direction vector
	$dir = [$p1->[0] - $p0->[0], $p1->[1] - $p0->[1], $p1->[2] - $p0->[2]];

	# compute segment to triangle vector
	$w0 = [$p0->[0] - $v0->[0], $p0->[1] - $v0->[1], $p0->[2] - $v0->[2]];

	# compute dot products
	$a = -ICC::Shared::dotProduct($n, $w0);
	$b = ICC::Shared::dotProduct($n, $dir);

	# if b is a very small number
	if (abs($b) < ICC::Shared::DBL_MIN) {
		
		# return (3 - segment lies in plane, 4 - segment disjoint from plane)
		return($a ? 3 : 4);
		
	}

	# compute radius
	$r = $a/$b;

	# check if reverse intersection
	return(2, $r) if ($r < 0);

	# compute the intersection point
	$px = [$p0->[0] + $r * $dir->[0], $p0->[1] + $r * $dir->[1], $p0->[2] + $r * $dir->[2]];

	# compute barycentric dot products
	$w = [$px->[0] - $v0->[0], $px->[1] - $v0->[1], $px->[2] - $v0->[2]];
	$wu = ICC::Shared::dotProduct($w, $u);
	$wv = ICC::Shared::dotProduct($w, $v);

	# compute common denominator
	$d = $uv * $uv - $uu * $vv;

	# compute barycentric coordinate
	$s = ($uv * $wv - $vv * $wu) / $d;

	# return if intersect outside triangle
	return(1, $r, $px) if ($s < 0 || $s > 1);

	# compute barycentric coordinate
	$t = ($uv * $wu - $uu * $wv) / $d;

	# return if intersect outside triangle
	return(1, $r, $px) if ($t < 0 || ($s + $t) > 1);

	# return intersect within triangle
	return(0, $r, $px);

}

# create gbd_ object from ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
# returns: (ref_to_object)
sub new_fh {

	# get object class
	my $class = shift();

	# create empty gbd_ object
	my $self = [
		{},    # header
		[],    # matrix
		[]     # offset
	];

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# read gbd_ data from profile
	_readICCgbd_($self, @_);

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# writes gbd_ object to ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub write_fh {

	# get object reference
	my $self = shift();

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# write gbd_ data to profile
	_writeICCgbd_($self, @_);

}

# get tag size (for writing to profile)
# returns: (clut_size)
sub size {

	# get parameter
	my $self = shift();

	# local variables
	my ($p, $q, $size);

	# get number of pcs channels
	$p = @{$self->[2][0]};

	# get number of device channels
	$q = defined($self->[3][0]) ? @{$self->[3][0]} : 0;

	# set header size
	$size = 20;

	# add face vertex IDs
	$size += 12 * @{$self->[1]};

	# add vertex pcs values
	$size += 4 * $p * @{$self->[2]};

	# add vertex device values (may be 0)
	$size += 4 * $q * @{$self->[3]};

	# return size
	return($size);

}

# print object contents to string
# format is an array structure
# parameter: ([format])
# returns: (string)
sub sdump {

	# get parameters
	my ($self, $p) = @_;

	# local variables
	my ($s, $fmt, $f, $v, $e);

	# resolve parameter to an array reference
	$p = defined($p) ? ref($p) eq 'ARRAY' ? $p : [$p] : [];

	# get format string
	$fmt = defined($p->[0]) && ! ref($p->[0]) ? $p->[0] : 'undef';

	# set string to object ID
	$s = sprintf("'%s' object, (0x%x)\n", ref($self), $self);

	# get stats
	($f, $v, $e) = _check_faces($self);

	# append stats
	$s .= "faces: $f   vertices: $v   edges: $e\n";

	# return
	return($s);

}

# check gamut faces
# parameters: (ref_to_object)
# returns: (faces, vertices, edges)
sub _check_faces {

	# get object reference
	my $self = shift();

	# local variables
	my (%v, %e, $p0, $p1, $p2);

	# for each face
	for my $i (0 .. $#{$self->[1]}) {
		
		# get indices
		$p0 = $self->[1][$i][0];
		$p1 = $self->[1][$i][1];
		$p2 = $self->[1][$i][2];
		
		# add vertices
		$v{$p0}++;
		$v{$p1}++;
		$v{$p2}++;
		
		# add edges
		$e{$p0 > $p1 ? "$p0:$p1" : "$p1:$p0"}++;
		$e{$p1 > $p2 ? "$p1:$p2" : "$p2:$p1"}++;
		$e{$p0 > $p2 ? "$p0:$p2" : "$p2:$p0"}++;
		
	}

	# return faces, vertices, edges
	return(scalar(@{$self->[1]}), scalar(keys(%v)), scalar(keys(%e)));

}

# make spherical index
# parameters: (object_ref, point_inside_gamut, latitude_steps, longitude_steps)
sub _make_index {

	# get parameters
	my ($self, $p0, $m, $n) = @_;

	# local variables
	my ($f, $s, $length, $dc, $dot, $dxy);

	# for each face
	for my $i (0 .. $#{$self->[1]}) {
		
		# for each coordinate
		for my $j (0 .. 2) {
			
			# for each vertex
			for my $k (0 .. 2) {
				
				# add value to face centroid
				$f->[$j][$i] += $self->[2][$self->[1][$i][$k]][$j]/3;
				
			}
			
			# subtract internal point value
			$f->[$j][$i] -= $p0->[$j];
			
		}
		
		# compute vector length
		$length = sqrt($f->[0][$i]**2 + $f->[1][$i]**2 + $f->[2][$i]**2);
		
		# for each coordinate
		for my $j (0 .. 2) {
			
			# normalize
			$f->[$j][$i] /= $length;
			
		}
		
	}

	# for each x
	for my $i (0 .. $m - 1) {
		
		# for each y
		for my $j (0 .. $n - 1) {
			
			# compute spherical unit vector for cell[x][y]
			$dc = sin(ICC::Shared::PI * ($i + 0.5)/$m);
			$s->[$n * $i + $j][0] = cos(ICC::Shared::PI * ($i + 0.5)/$m);
			$s->[$n * $i + $j][1] = -$dc * cos(2 * ICC::Shared::PI * (($j + 0.5)/$n));
			$s->[$n * $i + $j][2] = -$dc * sin(2 * ICC::Shared::PI * (($j + 0.5)/$n));
			
		}
		
	}

	# compute dot products [s x 3] * [3 x f] = [s x f]
	$dot = ICC::Support::Lapack::mat_xplus($s, $f);

	# initialize index
	undef($self->[5]);

	# for each x
	for my $i (0 .. $m - 1) {
		
		# for each y
		for my $j (0 .. $n - 1) {
			
			# get dot product list for cell[x][y]
			$dxy = $dot->[$n * $i + $j];
			
			# compute face ID list, sorted by dot product
			$self->[5][$i][$j] = [map {$_->[0]} sort {$b->[1] <=> $a->[1]} map {[$_, $dxy->[$_]]} (0 .. $#{$self->[1]})];
			
		}
		
	}

	# save internal point in header hash
	$self->[0]{'p0'} = $p0;

}

# make new gbd_ object from attribute hash
# hash keys are: ('vertex', 'pcs', 'device')
# object elements not specified in the hash are unchanged
# parameters: (ref_to_object, ref_to_attribute_hash)
sub _new_from_hash {

	# get parameters
	my ($self, $hash) = @_;

	# local variables
	my ($value, $f, $v, $e);

	# if 'vertex' key defined
	if (defined($hash->{'vertex'})) {
		
		# get value
		$value = $hash->{'vertex'};
		
		# if reference to a 2-D array
		if (ref($value) eq 'ARRAY' && @{$value} == grep {ref() eq 'ARRAY'} @{$value}) {
			
			# set vertex to clone of array
			$self->[1] = bless(Storable::dclone($value), 'Math::Matrix');
			
		# if a reference to a Math::Matrix object
		} elsif (UNIVERSAL::isa($value, 'Math::Matrix')) {
			
			# set vertex to object
			$self->[1] = $value;
			
		} else {
			
			# wrong data type
			croak('wrong \'vertex\' data type');
			
		}
		
		# verify number of faces
		(@{$self->[1]} >= 4) || croak('number of faces < 4');
		
		# verify number of vertices per face
		(@{$self->[1]} == 3) || croak('number of vertices per face <> 3');
		
		# check gamut faces
		($f, $v, $e) = _check_faces($self);
		
		# verify closed shape using Euler's formula
		($f + $v - $e == 2) || carp('not a closed shape');
		
	}

	# if 'pcs' key defined
	if (defined($hash->{'pcs'})) {
		
		# get value
		$value = $hash->{'pcs'};
		
		# if reference to a 2-D array
		if (ref($value) eq 'ARRAY' && @{$value} == grep {ref() eq 'ARRAY'} @{$value}) {
			
			# set pcs to clone of array
			$self->[1] = bless(Storable::dclone($value), 'Math::Matrix');
			
		# if a reference to a Math::Matrix object
		} elsif (UNIVERSAL::isa($value, 'Math::Matrix')) {
			
			# set pcs to object
			$self->[2] = $value;
			
		} else {
			
			# wrong data type
			croak('wrong \'pcs\' data type');
			
		}
		
		# verify number of vertices
		(@{$self->[2]} >= 4) || croak('number of vertices < 4');
		
		# verify number of pcs channels
		(@{$self->[2][0]} >= 3) || croak('number of pcs channels < 3');
		
	}

	# if 'device' key defined
	if (defined($hash->{'device'})) {
		
		# get value
		$value = $hash->{'device'};
		
		# if reference to a 2-D array
		if (ref($value) eq 'ARRAY' && @{$value} == grep {ref() eq 'ARRAY'} @{$value}) {
			
			# set device to clone of array
			$self->[1] = bless(Storable::dclone($value), 'Math::Matrix');
			
		# if a reference to a Math::Matrix object
		} elsif (UNIVERSAL::isa($value, 'Math::Matrix')) {
			
			# set device to object
			$self->[3] = $value;
			
		} else {
			
			# wrong data type
			croak('wrong \'device\' data type');
			
		}
		
		# verify number of vertices
		(@{$self->[3]} >= 4) || croak('number of vertices < 4');
		
		# verify number of pcs channels
		(@{$self->[3][0]} >= 1 && @{$self->[3][0]} <= 16) || croak('number of device channels < 1 or > 16');
		
	}
	
	# verify pcs array size
	(@{$self->[2]} == 0 || @{$self->[2]} == $v) || croak('pcs and face arrays have different number of vertices');
	
	# if both pcs and device arrays were supplied
	if (defined($hash->{'pcs'}) && defined($hash->{'device'})) {
		
		# verify pcs and device arrays have same number of vertices
		(@{$self->[2]} == @{$self->[3]}) || croak('pcs and device arrays are different sizes');
		
	}
	
}

# read gbd_ tag from ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _readICCgbd_ {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my ($buf, $p, $q, $v, $f, $bytes);

	# save tag signature
	$self->[0]{'signature'} = $tag->[0];

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# read tag header
	read($fh, $buf, 20);

	# unpack header
	($p, $q, $v, $f) = unpack('x8 n2 N2', $buf);

	# for each face
	for my $i (0 .. $f - 1) {
		
		# read vertex IDs
		read($fh, $buf, 12);
		
		# unpack the values
		$self->[1][$i] = [unpack('N3', $buf)];
		
	}

	# bless to Math::Matrix object
	bless($self->[1], 'Math::Matrix');

	# compute the buffer size
	$bytes = 4 * $p;

	# for each vertex
	for my $i (0 .. $v - 1) {
		
		# read vertex PCS values
		read($fh, $buf, $bytes);
		
		# unpack the values
		$self->[2][$i] = [unpack('f>*', $buf)];
		
	}

	# bless to Math::Matrix object
	bless($self->[2], 'Math::Matrix');

	# if there are device values
	if ($bytes = 4 * $q) {
		
		# for each vertex
		for my $i (0 .. $v - 1) {
			
			# read vertex device values
			read($fh, $buf, $bytes);
			
			# unpack the values
			$self->[3][$i] = [unpack('f>*', $buf)];
			
		}
		
		# bless to Math::Matrix object
		bless($self->[3], 'Math::Matrix');
		
	}
	
}

# write gbd_ tag to ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _writeICCgbd_ {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my ($p, $q, $v, $f);

	# get number of PCS channels
	$p = @{$self->[2][0]};

	# get number of device channels
	$q = defined($self->[3][0]) ? @{$self->[3][0]} : 0;

	# get number of vertices
	$v = @{$self->[2]};

	# get number of faces
	$f = @{$self->[1]};

	# validate number PCS channels (3 and up)
	($p >= 3) || croak('unsupported number of input channels');

	# validate number device channels (1 to 15)
	($q > 0 && $q < 16) || croak('unsupported number of output channels');

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# write tag header
	print $fh pack('a4 x4 n2 N2', 'gbd ', $p, $q, $v, $f);

	# for each face
	for my $i (0 .. $f - 1) {
		
		# write face vertex IDs
		print $fh pack('N3', @{$self->[1][$i]});
		
	}

	# for each vertex
	for my $i (0 .. $v - 1) {
		
		# write vertex PCS values
		print $fh pack('f>*', @{$self->[2][$i]});
		
	}

	# if there are vertex device values
	if ($q) {
		
		# for each vertex
		for my $i (0 .. $v - 1) {
			
			# write vertex device values
			print $fh pack('f>*', @{$self->[3][$i]});
			
		}
		
	}
	
}

1;