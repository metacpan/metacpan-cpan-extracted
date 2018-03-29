package ICC::Profile::cvst;

use strict;
use Carp;

our $VERSION = 0.31;

# revised 2018-03-27
#
# Copyright © 2004-2018 by William B. Birkett

# add development directory
use lib 'lib';

# inherit from Shared
use parent qw(ICC::Shared);

# support modules
use File::Glob;
use POSIX ();
use Template;
use XML::LibXML;

# create new cvst object
# array contains curve objects for each channel
# objects must have 'transform' and 'derivative' methods
# parameters: ([ref_to_array])
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift;

	# create empty cvst object
	my $self = [
		{},    # object header
		[],    # curve object array
	];

	# if there are parameters
	if (@_) {
		
		# if one parameter, a hash reference
		if (@_ == 1 && ref($_[0]) eq 'ARRAY') {
			
			# make new cvst object from array
			_new_from_array($self, shift());
			
		} else {
			
			# error
			croak('\'cvst\' parameter must be an array reference');
			
		}
		
	}

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# create inverse 'cvst' object
# returns: (ref_to_object)
sub inv {

	# get object
	my $self = shift();

	# local variables
	my ($array);

	# for each curve object
	for my $i (0 .. $#{$self->[1]}) {
		
		# verify curve object has 'inv' method
		($self->[1][$i]->can('inv')) || croak('curve element lacks \'inv\' method');
		
		# make inverse curve object
		$array->[$i] = $self->[1][$i]->inv();
		
	}

	# return
	return(ICC::Profile::cvst->new($array));

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
			croak('parameter must be a hash reference');
			
		}
		
	}
	
	# return reference
	return($self->[0]);
	
}

# get/set array reference
# parameters: ([ref_to_new_array])
# returns: (ref_to_array)
sub array {

	# get object reference
	my $self = shift();

	# if one parameter supplied
	if (@_ == 1) {
		
		# verify array reference
		(ref($_[0]) eq 'ARRAY') || croak('not an array reference');

		# get array reference
		my $array = shift();
		
		# for each curve element
		for my $i (0 .. $#{$array}) {
			
			# verify object has processing methods
			($array->[$i]->can('transform') && $array->[$i]->can('derivative')) || croak('curve element lacks \'transform\' or \'derivative\' method');
			
			# add curve element
			$self->[1][$i] = $array->[$i];
			
		}
		
	} elsif (@_) {
		
		# error
		croak("too many parameters\n");
		
	}
	
	# return array reference
	return($self->[1]);
	
}

# create cvst object from ICC profile
# assumes file handle is positoned at start of cvst data
# header information must be read separately by the calling function
# parameters: (ref_to_parent_object, file_handle, input_channels, output_channels)
# returns: (ref_to_object)
sub new_fh {

	# get object class
	my $class = shift();

	# create empty cvst object
	my $self = [
		{},    # object header
		[],    # curve object array
	];

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# read cvst data from profile
	_readICCcvst($self, @_);

	# bless object
	bless($self, $class);
	
	# return object reference
	return($self);

}

# writes cvst tag object to ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub write_fh {

	# get object reference
	my $self = shift();

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# write cvst data to profile
	_writeICCcvst($self, @_);

}

# get cvst size (for writing to profile)
# returns: (cvst_size)
sub size {

	# get parameter
	my $self = shift();

	# get size of header and table
	my $size = 12 + 8 * @{$self->[1]};

	# for each curve object
	for my $crv (@{$self->[1]}) {
		
		# add size
		$size += $crv->size();
		
		# adjust to 4-byte boundary
		$size += -$size % 4;
		
	}

	# return size
	return($size);

}

# get number of input channels
# returns: (number)
sub cin {

	# get object reference
	my $self = shift();

	# return
	return(scalar(@{$self->[1]}));

}

# get number of output channels
# returns: (number)
sub cout {

	# get object reference
	my $self = shift();

	# return
	return(scalar(@{$self->[1]}));

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
# hash key 'diag' for diagonal vector
# parameters: (input_vector, [hash])
# returns: (Jacobian_matrix, [output_vector])
sub jacobian {

	# get parameters
	my ($self, $in, $hash) = @_;

	# local variables
	my (@drv, $out, $jac);

	# for each channel
	for my $i (0 .. $#{$self->[1]}) {
		
		# compute derivative
		$drv[$i] = $self->[1][$i]->derivative($in->[$i]);
		
		# compute transform
		$out->[$i] = $self->[1][$i]->transform($in->[$i]) if wantarray;
		
	}

	# if 'diag' enabled
	if ($hash->{'diag'}) {
		
		# make diagonal vector
		$jac = [@drv];
		
	} else {
		
		# make diagonal matrix
		$jac = Math::Matrix->diagonal(@drv);
		
	}

	# if output values wanted
	if (wantarray) {
		
		# return Jacobian matrix and output vector
		return($jac, $out);
		
	} else {
		
		# return Jacobian matrix only
		return($jac);
		
	}
	
}

# compute parametric Jacobian matrix
# note: parameters are selected by the 'slice' array
# parameters: (input_vector)
# returns: (parametric_jacobian_matrix)
sub parajac {

	# get parameters
	my ($self, $in) = @_;

	# local variables
	my ($jac, $s, @pj);

	# verify curve object has '_parametric' method
	($self->[1][0]->can('_parametric')) || croak('parajac method not supported');

	# get slice array ref (if any)
	$s = $self->[0]{'slice'};

	# for each channel
	for my $i (0 .. $#{$self->[1]}) {
		
		# get parametric partial derivatives
		@pj = $self->[1][$i]->_parametric(0, $in->[$i]);
		
		# for each channel
		for my $j (0 .. $#{$self->[1]}) {
			
			# if current channel
			if ($j == $i) {
				
				# if slice defined
				if ($s) {
					
					# push slice parameters on matrix row
					push(@{$jac->[$j]}, @pj[@{$s}]);
					
				} else {
					
					# push all parameters on matrix row
					push(@{$jac->[$j]}, @pj);
					
				}
				
			} else {
				
				# if slice defined
				if ($s) {
					
					# push zeros on matrix row
					push(@{$jac->[$j]}, (0) x @{$s});
					
				} else {
					
					# push zeros on matrix row
					push(@{$jac->[$j]}, (0) x @pj);
					
				}
				
			}
			
		}
		
	}

	# return Jacobian matrix
	return(bless($jac, 'Math::Matrix'));

}

# find min/max values
# calls the 'roots' method of any 'bern' objects
# should be called after modifying Bernstein parameters
sub roots {

	# get parameter
	my $self = shift();

	# for each channel
	for my $i (0 .. $#{$self->[1]}) {
		
		# call 'roots' method if a 'bern' object
		$self->[1][$i]->roots if (UNIVERSAL::isa($_[1], 'ICC::Support::bern'));
		
	}
	
}

# get 'para' or 'parf' curve parameters
# returns: (ref_to_array)
sub pars {

	# get object reference
	my $self = shift();

	# local variables
	my ($pars);

	# for each curve
	for my $i (0 .. $#{$self->[1]}) {
		
		# verify curve is a 'para' or 'parf' object
		(UNIVERSAL::isa($self->[1][$i], 'ICC::Profile::para') || UNIVERSAL::isa($self->[1][$i], 'ICC::Profile::parf')) || croak('curve is not a \'para\' or \'parf\' object');
		
		# copy parameters
		$pars->[$i] = [@{$self->[1][$i]->array}];
		
	}

	# return parameter array
	return($pars);

}

# make new 'cvst' object containing 'curv' objects
# assumes curve domain/range is (0 - 1)
# direction: 0 - normal, 1 - inverse
# parameters: (number_of_table_entries, [direction])
# returns: (cvst_object)
sub curv {

	# get parameters
	my ($self, $n, $dir) = @_;

	# local variables
	my ($curv);

	# for each channel
	for my $i (0 .. $#{$self->[1]}) {
		
		# create table array
		$curv->[$i] = $self->[1][$i]->curv($n, $dir);
		
	}

	# return 'cvst' object
	return(ICC::Profile::cvst->new($curv));

}

# write Agfa Apogee tone curve file
# assumes curve domain/range is (0 - 1)
# options parameter may be a scalar or hash reference
# hash keys: 'dir', 'steps'
# direction: 0 - normal, 1 - inverse
# parameters: (file_path, [options])
sub apogee {

	# get parameters
	my ($self, $path, $opts) = @_;

	# local variables
	my ($dir, @STdot, %ink, @files);
	my ($dom, $root, @obj);
	my ($i, @out);

	# process options
	$dir = _options($opts);

	# if steps are defined
	if (defined($opts->{'steps'})) {
		
		# set input %-dot values
		@STdot = @{$opts->{'steps'}};
		
	} else {
		
		# set standard 'Stimuli' %-dot values used by Apogee RIP (31-step)
		@STdot = (0 .. 6, (map {5 * $_} (2 .. 18)), 94 .. 100);
		
	}

	# set ink hash
	%ink = ('Cyan', 0, 'Magenta', 1, 'Yellow', 2, 'Black', 3);

	# resolve file list from path
	(@files = File::Glob::bsd_glob($path)) || croak('invalid file path');

	# verify file path is unique
	(@files == 1) || carp('file path not unique');

	# open curve set template
	eval {$dom = XML::LibXML->load_xml('location' => ICC::Shared::getICCPath('Templates/Apogee_template.xml'))} || croak('can\'t load Apogee curve template');

	# get the root element
	$root = $dom->documentElement();

	# get the 'Curve' nodes
	@obj = $root->findnodes('Curve');

	# for each 'Curve' node
	for my $n (@obj) {
		
		# look-up the color index (0 - 3)
		$i = $ink{$n->getAttribute('Name')};
		
		# set the 'Stimuli' values
		$n->setAttribute('Stimuli', join(' ', @STdot));
		
		# set the 'Measured' values
		$n->setAttribute('Measured', join(' ', @STdot));
		
		# compute and set the 'Wanted' values
		$n->setAttribute('Wanted', join(' ', map {sprintf("%f", 100 * ($self->[1][$i]->_transform($dir, $_/100)))} @STdot));
		
		# compute and set the 'TransferCurve' values
		$n->setAttribute('TransferCurve', join(' ', map {sprintf("%f", 100 * ($self->[1][$i]->_transform($dir, $_/255)))} (0 .. 255)));
		
	}

	# add namespace attribute
	$root->setAttribute('xmlns', 'file:///procres');

	# write XML file
	$dom->toFile($files[0], 1);

}

# write tone curves as a device link profile
# assumes curve domain/range is (0 - 1)
# options parameter may be a scalar or hash reference
# hash key: 'dir'
# direction: 0 - normal, 1 - inverse
# parameters: (file_path, [options])
sub device_link {

	# get parameters
	my ($self, $path, $opts) = @_;

	# local variables
	my ($dir, $n, @files, $sig, $clrt, $profile, $b);

	# process options
	$dir = _options($opts);

	# get number of channels
	$n = @{$self->[1]};

	# resolve file list from path
	(@files = File::Glob::bsd_glob($path)) || croak('invalid file path');

	# verify file path is unique
	(@files == 1) || carp('file path not unique');

	# if grayscale
	if ($n == 1) {
		
		# make signature
		$sig = 'GRAY';
		
	} elsif ($n == 3) {
		
		# make signature
		$sig = 'RGB ';
		
	} elsif ($n == 4) {
		
		# make signature
		$sig = 'CMYK';
		
	} else {
		
		# make signature
		$sig = sprintf("%XCLR", $n);
		
		# make colorant tag (could be developed further)
		$clrt = ICC::Profile::clrt->new();
		
	}

	# make device link profile object
	$profile = ICC::Profile->new({'class' => 'link', 'data' => $sig, 'PCS' => $sig, 'version' => '04200000'});

	# add copyright tag
	$profile->tag({'cprt' => ICC::Profile::mluc->new('en', 'US', 'Copyright (c) 2004-2018 by William B. Birkett')});

	# add description tag
	$profile->tag({'desc' => ICC::Profile::mluc->new('en', 'US', 'tone curves')});

	# add profile sequence tag
	$profile->tag({'pseq' => ICC::Profile::pseq->new()});

	# for each curve
	for my $i (0 .. $#{$self->[1]}) {
		
		# if direction is forward and curve is an ICC::Profile object
		if ($dir == 0 && (UNIVERSAL::isa($self->[1][$i], 'ICC::Profile::curv') || UNIVERSAL::isa($self->[1][$i], 'ICC::Profile::para'))) {
			
			# use curve object as-is
			$b->[$i] = $self->[1][$i];
			
		} else {
			
			# use ICC::Profile::curv equivalent
			$b->[$i] = $self->[1][$i]->curv(1285, $dir);
			
		}
		
	}

	# add A2B0 tag (B-curves only)
	$profile->tag({'A2B0' => ICC::Profile::mAB_->new({'b_curves' => ICC::Profile::cvst->new($b)})});

	# add colorant tags, if nCLR
	$profile->tag({'clrt' => $clrt, 'clot' => $clrt}) if (defined($clrt));

	# write profile
	$profile->write($files[0]);

}

# write Fuji XMF tone curve file
# assumes curve domain/range is (0 - 1)
# options parameter may be a scalar or hash reference
# hash key: 'dir'
# direction: 0 - normal, 1 - inverse
# parameters: (file_path, [options])
sub fuji_xmf {

	# get parameters
	my ($self, $path, $opts) = @_;

	# local variables
	my ($dir, @XTRdot, @files, $fh, $rs, @colors, @Tdot);

	# process options
	$dir = _options($opts);

	# set tone curve %-dot values used by XMF RIP
	@XTRdot = (0, 1, 2, 3, 4, 5, 10, 20, 25, 30, 40, 50, 60, 70, 75, 80, 90, 95, 96, 97, 98, 99, 100);

	# resolve file list from path
	(@files = File::Glob::bsd_glob($path)) || croak('invalid file path');

	# verify file path is unique
	(@files == 1) || carp('file path not unique');

	# open the file
	open($fh, '>', $files[0]) or croak("can't open $files[0]: $!");

	# set output record separator (Windows CR-LF)
	$rs = "\015\012";

	# set color list
	@colors = qw(Cyan Magenta Yellow Black);

	# print colors
	print $fh join(';', @colors), $rs;

	# for each step
	for my $j (0 .. 100) {
		
		# if a valid dot value
		if (grep {$j == $_} @XTRdot) {
			
			# for each channel
			for my $i (0 .. 3) {
				
				# compute transformed dot value
				$Tdot[$i] = sprintf("%.2f", 100 * ($self->[1][$i]->_transform($dir, $j/100)));
				
			}
			
			# print transformed values
			print $fh join(';', @Tdot), $rs;
			
		} else {
			
			# print empty line
			print $fh '‐;‐;‐;‐', $rs;
			
		}
		
	}

	# close the file
	close($fh);

}

# write Harlequin tone curve file
# assumes curve domain/range is (0 - 1)
# options parameter may be a scalar or hash reference
# hash key: 'dir'
# direction: 0 - normal, 1 - inverse
# note: values must be entered manually in Harlequin RIP
# parameters: (file_path, [options])
sub harlequin {

	# get parameters
	my ($self, $path, $opts) = @_;

	# local variables
	my ($dir, @HQNdot, @files, $fh, $rs, @colors);

	# process options
	$dir = _options($opts);

	# set tone curve %-dot values used by Harlequin RIP (they are reversed for input with Calibration Manager)
	@HQNdot = (100, 95, 90, 85, 80, 70, 60, 50, 40, 30, 20, 15, 10, 8, 6, 4, 2, 0);

	# resolve file list from path
	(@files = File::Glob::bsd_glob($path)) || croak('invalid file path');

	# verify file path is unique
	(@files == 1) || carp('file path not unique');

	# open the file
	open($fh, '>', $files[0]) or croak("can't open $files[0]: $!");

	# set output record separator (Windows CR-LF)
	$rs = "\015\012";
	
	# set color list
	@colors = qw(Cyan Magenta Yellow Black);

	# for each channel
	for my $i (0 .. 3) {
		
		# print color
		print $fh "$colors[$i]$rs";
		
		# for each step
		for my $j (0 .. $#HQNdot) {
			
			# print input and transformed values
			printf $fh "%7.2f   %7.2f$rs", $HQNdot[$j], 100 * ($self->[1][$i]->_transform($dir, $HQNdot[$j]/100));
			
		}
		
		# print space
		print $fh "$rs$rs";
		
	}

	# close the file
	close($fh);

}

# write HP Indigo tone curve file set
# assumes curve domain/range is (0 - 1)
# options parameter may be a scalar or hash reference
# hash key: 'dir'
# direction: 0 - normal, 1 - inverse
# parameters: (folder_path, [options])
sub indigo {

	# get parameters
	my ($self, $path, $opts) = @_;

	# local variables
	my ($dir, $rs, @files, $fh, @segs, $file);
	my (@CMYK, @HPdot, $steps);
	my ($dotr, $dotp);

	# process options
	$dir = _options($opts);

	# set record separator (CR-LF)
	$rs = "\015\012";

	# resolve file list from path
	(@files = File::Glob::bsd_glob($path)) || croak('invalid file path');

	# verify file path is unique
	(@files == 1) || carp('file path not unique');

	# split the path
	@segs = split(/\//, $files[0]);

	# make the folder
	mkdir($files[0]);

	# ink color array (for building file names)
	@CMYK = qw(Cyan Magenta Yellow Black);

	# set tone curve device values
	@HPdot = map {$_/10} (0 .. 10);

	# get upper index
	$steps = $#HPdot;

	# for each color
	for my $i (0 .. 3) {
		
		# build the file path
		$file = "$files[0]/tone_curve-$CMYK[$i].lut";
		
		# create the file
		open($fh, '>', $file) or croak("can't open $file: $!");
		
		# for each step
		for my $j (0 .. $steps) {
			
			# get reference device value
			$dotr = $HPdot[$j];
			
			# get press device value
			$dotp = $self->[1][$i]->_transform($dir, $dotr);
			
			# limit %-dot (0 - 100)
			$dotr = ($dotr < 0) ? 0 : $dotr;
			$dotp = ($dotp < 0) ? 0 : $dotp;
			$dotr = ($dotr > 1) ? 1 : $dotr;
			$dotp = ($dotp > 1) ? 1 : $dotp;
			
			# print step info
			printf $fh "%3.1f\t%6.4f$rs", $dotr, $dotp;
			
		}
		
		# close file
		close($fh);
		
	}
	
}

# write ISO 18620 tone curve file
# assumes curve domain/range is (0 - 1)
# options parameter may be a scalar or hash reference
# hash keys: 'dir', 'steps'
# direction: 0 - normal, 1 - inverse
# parameters: (file_path, [options])
sub iso_18620 {

	# get parameters
	my ($self, $path, $opts) = @_;

	# local variables
	my ($dir, @STdot, %ink, @files);
	my ($dom, $root, @obj);
	my ($i, @out);

	# process options
	$dir = _options($opts);

	# if steps are defined
	if (defined($opts->{'steps'})) {
		
		# set input %-dot values
		@STdot = @{$opts->{'steps'}};
		
	} else {
		
		# set default input %dot values
		@STdot = (0, 1, 2, 5, (map {10 * $_} (1 .. 9)), 95, 100);
		
	}

	# set ink hash
	%ink = ('Cyan', 0, 'Magenta', 1, 'Yellow', 2, 'Black', 3);

	# resolve file list from path
	(@files = File::Glob::bsd_glob($path)) || croak('invalid file path');

	# verify file path is unique
	(@files == 1) || carp('file path not unique');

	# open curve set template
	eval {$dom = XML::LibXML->load_xml('location' => ICC::Shared::getICCPath('Templates/ISO_18620_template.xml'))} || croak('can\'t load ISO 18620 curve template');

	# get the root element
	$root = $dom->documentElement();

	# get the 'TransferCurve' nodes
	@obj = $root->findnodes('TransferCurve');

	# for each 'TransferCurve' node
	for my $n (@obj) {
		
		# look-up the color index (0 - 3)
		$i = $ink{$n->getAttribute('Separation')};
		
		# compute and set the 'Curve' values
		$n->setAttribute('Curve', join(' ', map {sprintf("%f %f", $_/100, $self->[1][$i]->_transform($dir, $_/100))} @STdot));
		
	}

	# add namespace attribute
	$root->setAttribute('xmlns', 'http://www.npes.org/schema/ISO18620/');

	# write XML file
	$dom->toFile($files[0], 1);

}

# write Photoshop tone curve file
# assumes curve domain/range is (0 - 1)
# options parameter may be a scalar or hash reference
# hash keys: 'dir', 'steps'
# direction: 0 - normal, 1 - inverse
# note: Photoshop curves must have between 2 and 16 points
# parameters: (file_path, [options])
sub photoshop {

	# get parameters
	my ($self, $path, $opts) = @_;

	# local variables
	my ($dir, $xval, $n, @files, $fh, $x, $y, $xmin, $xmax, $xp, @yx);

	# process options
	$dir = _options($opts);

	# if 'steps' array supplied
	if (defined($opts->{'steps'})) {
		
		# copy step values
		$xval = [map {$_/100} @{$opts->{'steps'}}];
		
		# verify maximum number of curve points
		($#{$xval} < 16) || croak('photoshop curve steps array has more than 16 points');
		
		# verify minimum number of curve points
		($#{$xval} > 0) || croak('photoshop curve steps array has less than 2 points');
		
	# if 'bern' curve objects
	} elsif (UNIVERSAL::isa($self->[1][0], 'ICC::Support::bern')) {
		
		# compute array upper index
		$n = ($#{$self->[1][0][1][0]} > $#{$self->[1][0][1][1]}) ? $#{$self->[1][0][1][0]} : $#{$self->[1][0][1][1]};
		
		# make x-value array
		$xval = [map {$_/$n} (0 .. $n)];
		
	# if 'akima' curve objects
	} elsif (UNIVERSAL::isa($self->[1][0], 'ICC::Support::akima')) {
		
		# compute upper index
		$n = $#{$self->[1][0][1]} < 16 ? $#{$self->[1][0][1]} : 15;
		
		# make x-value array
		$xval = [map {$_/$n} (0 .. $n)];
		
	} else {
		
		# use default array (5 points)
		$xval = [map {$_/4} (0 .. 4)];
		
	}

	# sort the x-values from low to high
	@{$xval} = sort {$a <=> $b} @{$xval};

	# resolve file list from path
	(@files = File::Glob::bsd_glob($path)) || croak('invalid file path');

	# verify file path is unique
	(@files == 1) || carp('file path not unique');

	# open the file
	open($fh, '>', $files[0]) or croak("can't open $files[0]: $!");

	# set binary mode
	binmode($fh);

	# print the version and number of curves (including master curve)
	print $fh pack('n2', 4, scalar(@{$self->[1]}) + 1);

	# print null master curve
	print $fh pack('n5', 2, 0, 0, 255, 255);

	# for each channel
	for my $i (0 .. $#{$self->[1]}) {
	
		# compute min and max x-values (correspond to y-values of 0 and 1)
		$xmin = $self->[1][$i]->_transform((1 - $dir), 0);
		$xmax = $self->[1][$i]->_transform((1 - $dir), 1);
		
		# swap min and max if negative curve
		($xmax, $xmin) = ($xmin, $xmax) if ($xmin > $xmax);
		
		# initialize point array
		@yx = ();
		
		# initialize previous x-value
		$xp = -1;
		
		# for each point
		for my $j (0 .. $#{$xval}) {
			
			# get x-value
			$x = $xval->[$j];
			
			# limit x-value (previously limited domain 0 - 1)
			$x = $x > $xmax ? $xmax : ($x < $xmin ? $xmin : $x);
			
			# skip if x-value same as previous
			next if ($x == $xp);
			
			# set previous x-value
			$xp = $x;
			
			# get y-value
			$y = $self->[1][$i]->_transform($dir, $x);
			
			# limit y-value
			$y = $y > 1 ? 1 : ($y < 0 ? 0 : $y);
			
			# push y-x pair on array (Photoshop curve points are [output, input])
			push(@yx, [$y, $x]);
			
		}
		
		# print number of points
		print $fh pack('n', scalar(@yx));
		
		# if 3 channels (RGB)
		if (@{$self->[1]} == 3) {
			
			# for each point
			for (@yx) {
				
				# print point value (y, x), normal for RGB
				print $fh pack('n2', map {255 * $_ + 0.5} @{$_});
				
			}
			
		} else {
			
			# for each point (in reverse order)
			for (reverse(@yx)) {
				
				# print point value (y, x), complemented for Grayscale, CMYK, Multichannel
				print $fh pack('n2', map {255 * (1 - $_) + 0.5} @{$_});
				
			}
			
		}
		
	}

	# close the file
	close($fh);

	# set file creator and type (OS X only)
	ICC::Shared::setFile($files[0], '8BIM', '8BSC');

}

# write Prinergy (Harmony) tone curve file
# assumes curve domain/range is (0 - 1)
# options parameter may be a scalar or hash reference
# hash keys: 'dir', 'Comments', 'CurveSet', 'DefaultFrequency', 'DefaultMedium',
#	'DefaultResolution', 'DefaultSpotFunction', 'Enabled', 'FirstName', 'FreqFrom',
#	'FreqTo', 'FrequencyUsed', 'ID', 'Medium', 'MediumUsed', 'Resolution',
#	'ResolutionUsed', 'ScreeningType', 'ScreeningTypeUsed', 'SpotFunction',
#	'SpotFunctionMode', 'SpotFunctionUsed'
# direction: 0 - normal, 1 - inverse
# parameters: (file_path, [options])
sub prinergy {

	# get parameters
	my ($self, $path, $opts) = @_;

	# local variables
	my ($dir, $prinergy, $key);
	my (@files, $fh, @time, $time, @month, $datetime);
	my ($rs, @colors, @map, $up);

	# process options
	$dir = _options($opts);

	# read prinergy hash template
	$prinergy = YAML::Tiny->read(ICC::Shared::getICCPath('Preferences/Prinergy.yml'))->[0];

	# for each hash key
	for my $key (keys(%{$prinergy})) {
		
		# set to options value, if defined
		$prinergy->{$key} = $opts->{$key} if (defined($opts->{$key}));
		
		# set undefined values to null string
		$prinergy->{$key} = '' if (! defined($prinergy->{$key}));
		
	}

	# resolve file list from path
	(@files = File::Glob::bsd_glob($path)) || croak('invalid file path');

	# verify file path is unique
	(@files == 1) || carp('file path not unique');

	# open the file
	open($fh, '>', $files[0]) or croak("can't open $files[0]: $!");

	# set file creator and type (Windows NT SFM values)
	ICC::Shared::setFile($files[0], 'LMAN', 'TEXT');

	# get the time
	@time = localtime(time);

	# print time as string
	$time = sprintf "%d/%d/%d %2.2d:%2.2d:%2.2d", $time[4]+1, $time[3], $time[5]+1900, $time[2], $time[1], $time[0];

	# make array of months
	@month = qw(January February March April May June July August September October November December);

	# print datetime as string
	$datetime = sprintf "%2.2d %s %d %2.2d:%2.2d:%2.2d", $time[3], $month[$time[4]], $time[5]+1900, $time[2], $time[1], $time[0];

	# Windows record separator (CR-LF)
	$rs = "\015\012";

	# print Prinergy header
	print $fh ";Creo Harmony Database File$rs";
	print $fh ";1.07$rs";
	print $fh ";$time$rs";
	print $fh ";Next Calibration ID = 0001$rs$rs";

	# print 'transfer' table info
	printf $fh "[ E %s, %s %s %s %s %s ]$rs", $prinergy->{'FirstName'}, $prinergy->{'DefaultMedium'}, 'CMYK',
	$prinergy->{'DefaultSpotFunction'}, $prinergy->{'DefaultFrequency'}, $prinergy->{'DefaultResolution'};
	print $fh "FirstName = $prinergy->{'FirstName'}$rs";
	print $fh "ID = $prinergy->{'ID'}$rs";
	print $fh "Enabled = $prinergy->{'Enabled'}$rs";
	print $fh "CurveSet = $prinergy->{'CurveSet'}$rs";
	print $fh "DateTime = $datetime$rs";
	printf $fh "Time = %d$rs", time;
	print $fh "MediumUsed = $prinergy->{'MediumUsed'}$rs";
	print $fh "Medium = $prinergy->{'Medium'}$rs";
	print $fh "ScreeningTypeUsed = $prinergy->{'ScreeningTypeUsed'}$rs";
	print $fh "ScreeningType = $prinergy->{'ScreeningType'}$rs";
	print $fh "ResolutionUsed = $prinergy->{'ResolutionUsed'}$rs";
	print $fh "Resolution = $prinergy->{'Resolution'}$rs";
	print $fh "FrequencyUsed = $prinergy->{'FrequencyUsed'}$rs";
	print $fh "FreqFrom = $prinergy->{'FreqFrom'}$rs";
	print $fh "FreqTo = $prinergy->{'FreqTo'}$rs";
	print $fh "SpotFunctionUsed = $prinergy->{'SpotFunctionUsed'}$rs";
	print $fh "SpotFunction = $prinergy->{'SpotFunction'}$rs";
	print $fh "SpotFunctionMode = $prinergy->{'SpotFunctionMode'}$rs";
	print $fh "DefaultMedium = $prinergy->{'DefaultMedium'}$rs";
	print $fh "DefaultResolution = $prinergy->{'DefaultResolution'}$rs";
	print $fh "DefaultFrequency = $prinergy->{'DefaultFrequency'}$rs";
	print $fh "DefaultSpotFunction = $prinergy->{'DefaultSpotFunction'}$rs";

	# set color names
	@colors = qw(Cyan Magenta Yellow Black);

	# set color map (KCMY)
	@map = (3, 0, 1, 2);

	# set upper index (number of curve points - 1)
	$up = 100;

	# for each curve
	for my $i (0 .. 3) {

		# print curve dropoff
		printf $fh "Curve%d DropOff = %d$rs", $i + 1, 0;

		# print curve color
		printf $fh "Curve%d Color = %s$rs", $i + 1, $colors[$map[$i]];

		# print curve start
		printf $fh "Curve%d = ", $i + 1;

		# print curve points
		for my $j (0 .. $up) {
		
			# print curve values
			printf $fh "%d %d ", 1E7 * $j/$up + 0.5, 1E7 * $self->[1][$map[$i]]->_transform($dir, $j/$up) + 0.5;
		
		}

		# print curve end
		print $fh "$rs";

	}

	# print trailing comments
	print $fh "Comments = $prinergy->{'Comments'}$rs";
	print $fh "$rs";

	# close the file
	close($fh);

}

# write Rampage tone curve file set
# assumes curve domain/range is (0 - 1)
# options parameter may be a scalar or hash reference
# hash key: 'dir'
# direction: 0 - normal, 1 - inverse
# parameters: (folder_path, [options])
sub rampage {

	# get parameters
	my ($self, $path, $opts) = @_;

	# local variables
	my ($dir, $rs, @files, $fh0, $fh1, @segs, $folder, $file);
	my (@CMYK, @RAMdot, $steps);
	my ($dotr, $dotp);

	# process options
	$dir = _options($opts);

	# set record separator (CR-LF)
	$rs = "\015\012";

	# resolve file list from path
	(@files = File::Glob::bsd_glob($path)) || croak('invalid file path');

	# verify file path is unique
	(@files == 1) || carp('file path not unique');

	# split the path
	@segs = split(/\//, $files[0]);

	# get the folder name
	$folder = $segs[-1];

	# make the folder
	mkdir($files[0]);

	# ink color array (for building file names)
	@CMYK = qw(C M Y K);

	# set tone curve %-dot values
	@RAMdot = (0, 1, 3, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 97, 99, 100);

	# get upper index
	$steps = $#RAMdot;

	# for each color
	for my $i (0 .. 3) {
	
		# build the DESIRED file path
		$file = $files[0] . '/' . $folder . '_DESIRED_' . $CMYK[$i];
		
		# create the DESIRED file
		open($fh0, '>', $file) or croak("can't open $file: $!");
		
		# set file creator and type
		ICC::Shared::setFile($file, 'RamC', 'Clst');
		
		# build the ACT file path
		$file = $files[0] . '/' . $folder . '_ACT_' . $CMYK[$i];
		
		# create the ACT file
		open($fh1, '>', $file) or croak("can't open $file: $!");
		
		# set file creator and type
		ICC::Shared::setFile($file, 'RamC', 'Clst');
		
		# print DESIRED header
		print $fh0 "2$rs";
		print $fh0 "0.0000000000$rs";
		print $fh0 "0.0000000000$rs";
		printf $fh0 "%2d$rs", $steps + 1;
		
		# print ACT header
		print $fh1 "2$rs";
		print $fh1 "0.0000000000$rs";
		print $fh1 "0.0000000000$rs";
		printf $fh1 "%2d$rs", $steps + 1;
		
		# for each step
		for my $j (0 .. $steps) {
			
			# get reference %-dot
			$dotr = $RAMdot[$j];
			
			# get press %-dot
			$dotp = 100 * $self->[1][$i]->_transform($dir, $dotr/100);
			
			# limit %-dot (0 - 100)
			$dotr = ($dotr < 0) ? 0 : $dotr;
			$dotp = ($dotp < 0) ? 0 : $dotp;
			$dotr = ($dotr > 100) ? 100 : $dotr;
			$dotp = ($dotp > 100) ? 100 : $dotp;
			
			# print DESIRED step info
			printf $fh0 "%3.1f    %3.1f$rs", $dotr, $dotp;
			
			# print ACT step info
			printf $fh1 "%3.1f    %3.1f$rs", $dotr, $dotr;
			
		}
	
		# print DESIRED footer
		print $fh0 "Version: 2.0$rs";
		
		# print ACT footer
		print $fh1 "Version: 2.0$rs";
		
		# close the DESIRED file
		close($fh0);
		
		# close the ACT file
		close($fh1);
	
	}
	
}

# write Trueflow tone curve file
# assumes curve domain/range is (0 - 1)
# options parameter may be a scalar or hash reference
# hash key: 'dir'
# direction: 0 - normal, 1 - inverse
# parameters: (file_path, [options])
sub trueflow {

	# get parameters
	my ($self, $path, $opts) = @_;

	# local variables
	my ($dir, @names, @colors, @map, @TFdot);
	my (@files, $fh, $in, $out, $dg, @lut, $float);

	# process options
	$dir = _options($opts);

	# set curve names
	@names = qw(Y M C K);

	# set curve display colors (YMCK)
	@colors = (0x00ffff, 0xff00ff, 0xffff00, 0x000000);

	# set color map (YMCK)
	@map = (2, 1, 0, 3);

	# set tone curve %-dot values
	@TFdot = (0, 2, 5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 95, 98, 100);

	# resolve file list from path
	(@files = File::Glob::bsd_glob($path)) || croak('invalid file path');

	# verify file path is unique
	(@files == 1) || carp('file path not unique');

	# open the file
	open($fh, '>', $files[0]) or croak("can't open $files[0]: $!");

	# set binary mode
	binmode($fh);

	# print the header
	print $fh pack('C4a4', 4, 3, 2, 1, 'DGT'); 	# file signature
	print $fh pack('V', 256);					# offset to first curve
	print $fh pack('V', 100);					#
	print $fh pack('V', 4);						# number of curves
	print $fh pack('V4', 640, 640, 640, 640);	# curve block sizes

	# seek start of first curve
	seek($fh, 256, 0);

	# loop thru colors (0-3) (YMCK)
	for my $i (0 .. 3) {
		
		# print curve name
		print $fh pack('a128', $names[$i]);
		
		# print display color
		print $fh pack('V', $colors[$i]);
		
		# print curve parameters (LUT_size, dot_gain_steps, dot_gain_table_size)
		print $fh pack('V3', 256, 15, 240);
		
		# print binary LUT
		#
		# for each step
		for my $j (0 .. 255) {
			
			# compute output value
			$out = $self->[1][$map[$i]]->_transform($dir, $j/255);
			
			# print LUT value (limited and rounded)
			print $fh pack('C', 255 * ($out < 0 ? 0 : ($out > 1 ? 1 : $out)) + 0.5);
			
		}
		
		# print dot gain table
		#
		# for each tone curve step
		for my $j (0 .. $#TFdot) {
			
			# compute input value
			$in = $TFdot[$j]/100;
			
			# compute output value
			$out = $self->[1][$map[$i]]->_transform($dir, $in);
			
			# compute dot gain (rounded to 0.1%)
			$dg = POSIX::floor(1000 * ($out - $in) + 0.5)/10;
			
			# print dot gain value (little-endian double)
			print $fh pack('C2 x6 d<', $TFdot[$j], 1, $dg);
			
		}
		
	}

	# close the file
	close($fh);

}

# write Xitron Sierra tone curve file
# assumes curve domain/range is (0 - 1)
# options parameter may be a scalar or hash reference
# hash key: 'dir'
# direction: 0 - normal, 1 - inverse
# parameters: (file_path, [options])
sub xitron {

	# get parameters
	my ($self, $path, $opts) = @_;

	# local variables
	my ($dir, @XTRdot, @files, $fh, $rs, @colors, @Tdot);

	# process options
	$dir = _options($opts);

	# set tone curve %-dot values used by Xitron RIP
	@XTRdot = (0, 1, 2, 3, 4, 5, 10, 20, 25, 30, 40, 50, 60, 70, 75, 80, 90, 95, 96, 97, 98, 99, 100);

	# resolve file list from path
	(@files = File::Glob::bsd_glob($path)) || croak('invalid file path');

	# verify file path is unique
	(@files == 1) || carp('file path not unique');

	# open the file
	open($fh, '>', $files[0]) or croak("can't open $files[0]: $!");

	# set output record separator (Windows CR-LF)
	$rs = "\015\012";

	# set color list
	@colors = qw(Cyan Magenta Yellow Black);

	# print colors
	print $fh join(';', @colors), $rs;

	# for each step
	for my $j (0 .. $#XTRdot) {
		
		# for each channel
		for my $i (0 .. 3) {
			
			# compute transformed dot value
			$Tdot[$i] = sprintf("%.4f", 100 * ($self->[1][$i]->_transform($dir, $XTRdot[$j]/100)));
			
		}
		
		# print transformed values
		print $fh join(';', @Tdot), $rs;
		
	}

	# close the file
	close($fh);

}

# write tab delimited text tone curve file
# assumes curve domain/range is (0 - 1)
# options parameter may be a scalar or hash reference
# hash keys: 'dir', 'steps'
# direction: 0 - normal, 1 - inverse
# parameters: (file_path, [options])
sub text {

	# get parameters
	my ($self, $path, $opts) = @_;

	# local variables
	my ($dir, @XTRdot, $fp, @files, $fh, $rs, @Tdot);

	# process options
	$dir = _options($opts);

	# if 'steps' are defined
	if (defined($opts->{'steps'})) {
		
		# copy step values
		@XTRdot = @{$opts->{'steps'}};
		
		# check for non-integer values
		$fp = grep {int($_) != $_} @XTRdot;
		
	} else {
		
		# set default input %-dot values
		@XTRdot = map {$_ * 5} (0 .. 20);
		
	}

	# resolve file list from path
	(@files = File::Glob::bsd_glob($path)) || croak('invalid file path');

	# verify file path is unique
	(@files == 1) || carp('file path not unique');

	# open the file
	open($fh, '>', $files[0]) or croak("can't open $files[0]: $!");

	# set output record separator (Windows CR-LF)
	$rs = "\015\012";

	# for each step
	for my $j (@XTRdot) {
		
		# format input value
		$Tdot[0] = $fp ? sprintf("%.2f", $j) : $j;
		
		# for each channel
		for my $i (0 .. $#{$self->[1]}) {
			
			# compute transformed dot value
			$Tdot[$i + 1] = sprintf("%.2f", 100 * ($self->[1][$i]->_transform($dir, $j/100)));
			
		}
		
		# print step values
		print $fh join("\t", @Tdot), $rs;
		
	}

	# close the file
	close($fh);

}

# graph tone curves
# assumes curve domain/range is (0 - 1)
# options parameter may be a scalar or hash reference
# hash keys: 'dir', 'composite'
# direction: 0 - normal, 1 - inverse
# parameters: (folder_path, [options])
sub graph {

	# get parameters
	my ($self, $path, $opts) = @_;

	# local variables
	my ($dir, $include, $folder, $tt, $vars, @colors, @inks, $s, $lib);

	# process options
	$dir = _options($opts);

	# if ICC::Templates folder is found in @INC (may be relative)
	if (($include) = grep {-d} map {File::Spec->catdir($_, 'ICC', 'Templates')} @INC) {
		
		# purify folder path
		$folder = File::Glob::bsd_glob($path);
		
		# make a template processing object
		$tt = Template->new({
			'INCLUDE_PATH' => $include,
			'OUTPUT_PATH' => $folder,
		});
		
		# if gray scale curve
		if ($#{$self->[1]} == 0) {
			
			# set colors
			@colors = qw(black);
			@inks = qw(grayscale);
			
		# if RGB curves
		} elsif ($#{$self->[1]} == 2) {
			
			# set colors
			@colors = @inks = qw(red green blue);
			
		# if CMYK+ curves
		} elsif ($#{$self->[1]} > 2) {
			
			# set colors
			@colors = qw(cyan magenta yellow black orange green blue);
			$colors[2] = '#cc0'; # dark yellow
			$colors[4] = '#f80'; # orange
			@inks = qw(cyan magenta yellow black ink5 ink6 ink7);
			
		}
		
		# if 'composite' curve
		if ($opts->{'composite'}) {
			
			# for each curve
			for my $i (0 .. $#{$self->[1]}) {
				
				# compute curve data
				$s->[$i] = '[' . join(', ', map {sprintf("%.3f", $self->[1][$i]->_transform($dir, $_/100))} (0 .. 100)) . ']';
			
			}
			
			# make composite javascript string of curve data
			$vars->{'data'} = '[' . join(', ', @{$s}) . ']';
			
			# set graph title
			$vars->{'title'} = "composite tone curves";
			
			# set graph colors
			$vars->{'colors'} = '[' . join(', ', map {"'$_'"} @colors) . ']';
			
			# process the template
			$tt->process('rgraph_cvst_svg.tt2', $vars, "composite.html") || CORE::die $tt->error();
			
		} else {
			
			# for each curve
			for my $i (0 .. $#{$self->[1]}) {
				
				# make javascript string of curve data
				$vars->{'data'} = '[[' . join(', ', map {sprintf("%.3f", $self->[1][$i]->_transform($dir, $_/100))} (0 .. 100)) . ']]';
				
				# set graph title
				$vars->{'title'} = "$inks[$i] tone curve";
				
				# set graph color
				$vars->{'colors'} = "['$colors[$i]']";
				
				# process the template
				$tt->process('rgraph_cvst_svg.tt2', $vars, "$inks[$i].html") || CORE::die $tt->error();
			
			}
			
		}
		
		# make path to 'lib' folder
		$lib = "$folder/lib";
		
		# make 'lib' folder, if none
		mkdir($lib) if ! -d $lib;
		
		# match 'ICC' folder path
		$include =~ m/^(.*)Templates$/;
		
		# copy Rgraph Javascripts to 'lib' folder
		qx(cp -n "$1/Javascripts/rgraph/RGraph.svg.common.core.js" $lib);
		qx(cp -n "$1/Javascripts/rgraph/RGraph.svg.line.js" $lib);
		
		# if 'composite' curve
		if ($opts->{'composite'}) {
			
			# open graph file in browser
			qx(open "$folder/composite.html");
			
		} else {
			
			# for each curve
			for my $i (0 .. $#{$self->[1]}) {
				
				# open graph file in browser
				qx(open "$folder/$inks[$i].html");
				
				# pause for first file (Firefox)
				sleep(1) if ($i == 0);
				
			}
			
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
	my ($element, $fmt, $s, $pt, $st);

	# resolve parameter to an array reference
	$p = defined($p) ? ref($p) eq 'ARRAY' ? $p : [$p] : [];

	# get format string
	$fmt = defined($p->[0]) && ! ref($p->[0]) ? $p->[0] : 's';

	# set string to object ID
	$s = sprintf("'%s' object, (0x%x)\n", ref($self), $self);

	# if format contains 'o'
	if ($fmt =~ m/s/) {
		
		# get default parameter
		$pt = $p->[-1];
		
		# for each processing element
		for my $i (0 .. $#{$self->[1]}) {
			
			# get element reference
			$element = $self->[1][$i];
			
			# if processing element is undefined
			if (! defined($element)) {
				
				# append message
				$s .= "\tprocessing element is undefined\n";
				
			# if processing element is not a blessed object
			} elsif (! Scalar::Util::blessed($element)) {
				
				# append message
				$s .= "\tprocessing element is not a blessed object\n";
				
			# if processing element has an 'sdump' method
			} elsif ($element->can('sdump')) {
				
				# get 'sdump' string
				$st = $element->sdump(defined($p->[$i + 1]) ? $p->[$i + 1] : $pt);
				
				# prepend tabs to each line
				$st =~ s/^/\t/mg;
				
				# append 'sdump' string
				$s .= $st;
				
			# processing element is object without an 'sdump' method
			} else {
				
				# append object info
				$s .= sprintf("\t'%s' object, (0x%x)\n", ref($element), $element);
				
			}
			
		}
		
	}

	# return
	return($s);

}

# transform list
# parameters: (object_reference, list, [hash])
# returns: (list)
sub _trans0 {

	# local variables
	my ($self, @out, $hash);

	# get object reference
	$self = shift();

	# get optional hash
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# for each channel
	for my $i (0 .. $#{$self->[1]}) {
		
		# compute transform
		$out[$i] = $self->[1][$i]->transform($_[$i]);
		
	}

	# return output array
	return(@out);

}

# transform vector
# parameters: (object_reference, vector, [hash])
# returns: (vector)
sub _trans1 {

	# get parameters
	my ($self, $in, $hash) = @_;

	# local variable
	my ($out);

	# for each channel
	for my $i (0 .. $#{$self->[1]}) {
		
		# compute transform
		$out->[$i] = $self->[1][$i]->transform($in->[$i]);
		
	}

	# return
	return($out);

}

# transform matrix (2-D array -or- Math::Matrix object)
# parameters: (object_reference, matrix, [hash])
# returns: (matrix)
sub _trans2 {

	# get parameters
	my ($self, $in, $hash) = @_;

	# local variable
	my ($out);

	# for each input vector
	for my $i (0 .. $#{$in}) {
		
		# for each channel
		for my $j (0 .. $#{$self->[1]}) {
			
			# compute transform
			$out->[$i][$j] = $self->[1][$j]->transform($in->[$i][$j]);
			
		}
		
	}

	# return
	return($out);

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
# parameters: (ref_to_object, input_array_reference, output_array_reference, hash)
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
	my ($self, $hash, @out);

	# get object reference
	$self = shift();

	# get optional hash
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# for each channel
	for my $i (0 .. $#{$self->[1]}) {
		
		# compute invert
		$out[$i] = $self->[1][$i]->inverse($_[$i]);
		
	}

	# return output array
	return(@out);

}

# invert vector
# parameters: (object_reference, vector, [hash])
# returns: (vector)
sub _inv1 {

	# get parameters
	my ($self, $in, $hash) = @_;

	# local variable
	my ($out);

	# for each channel
	for my $i (0 .. $#{$self->[1]}) {
		
		# compute invert
		$out->[$i] = $self->[1][$i]->inverse($in->[$i]);
		
	}

	# return
	return($out);

}

# invert matrix (2-D array -or- Math::Matrix object)
# parameters: (object_reference, matrix, [hash])
# returns: (matrix)
sub _inv2 {

	# get parameters
	my ($self, $in, $hash) = @_;

	# local variable
	my ($out);

	# for each input vector
	for my $i (0 .. $#{$in}) {
		
		# for each channel
		for my $j (0 .. $#{$self->[1]}) {
			
			# compute invert
			$out->[$i][$j] = $self->[1][$j]->inverse($in->[$i][$j]);
			
		}
		
	}

	# return
	return($out);

}

# invert structure
# parameters: (object_reference, structure, [hash])
# returns: (structure)
sub _inv3 {

	# get parameters
	my ($self, $in, $hash) = @_;

	# recursive inverse
	_crawl2($self, $in, my $out = []);

	# return
	return($out);

}

# recursive inverse
# array structure is traversed until scalar arrays are found and inverted
# parameters: (object_reference, input_array_reference, output_array_reference, hash)
sub _crawl2 {
	
	# get parameters
	my ($self, $in, $out, $hash) = @_;
	
	# if input is a vector (reference to a scalar array)
	if (@{$in} == grep {! ref()} @{$in}) {
		
		# invert input vector and copy to output
		@{$out} = @{_inv1($self, $in, $hash)};
		
	} else {
		
		# for each input element
		for my $i (0 .. $#{$in}) {
			
			# if an array reference
			if (ref($in->[$i]) eq 'ARRAY') {
				
				# invert next level
				_crawl2($self, $in->[$i], $out->[$i] = []);
				
			} else {
				
				# error
				croak('invalid inverse input');
				
			}
			
		}
		
	}
	
}

# process the options parameter
# the parameter may be a scalar or hash reference
# parameter: (options_parameter)
# returns: (direction_flag)
sub _options {

	# local variable
	my ($dir, $steps, $n);

	# if parameter is defined
	if (defined($_[0])) {
		
		# if parameter is a hash reference
		if (ref($_[0]) eq 'HASH') {
			
			# use 'dir' hash value
			$dir = $_[0]->{'dir'};
			
			# if the 'steps' key is defined
			if (defined($steps = $_[0]->{'steps'})) {
				
				# if steps value is an array reference
				if (ref($steps) eq 'ARRAY') {
					
					# if step values are valid
					if (@{$steps} == grep {Scalar::Util::looks_like_number($_) && $_ >= 0 && $_ <= 100} @{$steps}) {
						
						# sort step values
						@{$steps} = sort {$a <=> $b} @{$steps};
						
					} else {
						
						# print warning
						carp("invalid 'step' value(s)\n");
						
						# delete hash entry
						delete($_[0]->{'steps'});
						
					}
					
				# if steps value is a scalar
				} elsif (! ref($steps)) {
					
					# if steps value is a positive integer > 1
					if (Scalar::Util::looks_like_number($steps) && int($steps) == $steps && $steps > 1) {
						
						# set upper index
						$n = $steps - 1;
						
						# make steps an array
						$_[0]->{'steps'} = [map {100 * $_/$n} (0 .. $n)];
						
					} else {
						
						# print warning
						carp("'steps' value must be an integer > 1\n");
					
						# delete hash entry
						delete($_[0]->{'steps'});
						
					}
					
				} else {
					
					# print warning
					carp("'steps' value must be a scalar or array reference\n");
					
					# delete hash entry
					delete($_[0]->{'steps'});
					
				}
				
			}
			
		# if parameter is a scalar
		} elsif (! ref($_[0])) {
			
			# use scalar value
			$dir = $_[0];
			
			# undefine parameter
			undef($_[0]);
			
		# any other type
		} else {
			
			# print warning
			carp("options parameter must be a scalar or hash reference\n");
			
			# undefine parameter
			undef($_[0]);
			
		}
		
	}

	# return purified flag
	return($dir ? 1 : 0);

}

# make new cvst object from array
# parameters: (ref_to_object, ref_to_array)
sub _new_from_array {

	# get parameters
	my ($self, $array) = @_;

	# for each curve element
	for my $i (0 .. $#{$array}) {
		
		# verify object has processing methods
		($array->[$i]->can('transform') && $array->[$i]->can('derivative')) || croak('curve element lacks \'transform\' or \'derivative\' method');
		
		# add curve element
		$self->[1][$i] = $array->[$i];
		
	}

}

# read cvst tag from ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _readICCcvst {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my ($buf, @mft, $table, $tag2, $type, $class, %hash);

	# set tag signature
	$self->[0]{'signature'} = $tag->[0];

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# read tag header
	read($fh, $buf, 12);

	# unpack header
	@mft = unpack('a4 x4 n2', $buf);

	# verify tag signature
	($mft[0] eq 'cvst') or croak('wrong tag type');

	# for each curve set element
	for my $i (0 .. $mft[1] - 1) {
		
		# read positionNumber
		read($fh, $buf, 8);
		
		# unpack to processing element tag table
		$table->[$i] = ['cvst', unpack('N2', $buf)];
		
	}

	# for each curve set element
	for my $i (0 .. $mft[1] - 1) {
		
		# get tag table entry
		$tag2 = $table->[$i];
		
		# make offset absolute
		$tag2->[1] += $tag->[1];
		
		# if a duplicate tag
		if (exists($hash{$tag2->[1]})) {
			
			# use original tag object
			$self->[1][$i] = $hash{$tag2->[1]};
			
		} else {
			
			# seek to start of tag
			seek($fh, $tag2->[1], 0);
			
			# read tag type signature
			read($fh, $type, 4);
			
			# convert non-word characters to underscores
			$type =~ s|\W|_|g;
			
			# form class specifier
			$class = "ICC::Profile::$type";
			
			# if 'class->new_fh' method exists
			if ($class->can('new_fh')) {
				
				# create specific tag object
				$self->[1][$i] = $class->new_fh($self, $fh, $tag2);
				
			} else {
				
				# create generic tag object
				$self->[1][$i] = ICC::Profile::Generic->new_fh($self, $fh, $tag2);
				
				# print warning
				print "curve set element $type opened as generic\n";
				
			}
			
			# save tag object in hash
			$hash{$tag2->[1]} = $self->[1][$i];
			
		}
		
	}
	
}

# write cvst tag to ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _writeICCcvst {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my ($n, $offset, $size, @cept, %hash);

	# get number of curve elements
	$n = @{$self->[1]};

	# verify number of channels (1 to 15)
	($n > 0 && $n < 16) || croak('unsupported number of channels');

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# write tag type signature and number channels
	print $fh pack('a4 x4 n2', 'cvst', $n, $n);

	# initialize tag offset
	$offset = 12 + 8 * $n;

	# for each curve element
	for my $i (0 .. $#{$self->[1]}) {
		
		# verify curve element is 'curf' object
		(UNIVERSAL::isa($self->[1][$i], 'ICC::Profile::curf')) || croak('curve element must a \'curf\' object');
		
		# if tag not in hash
		if (! exists($hash{$self->[1][$i]})) {
			
			# get size
			$size = $self->[1][$i]->size();
			
			# set table entry and add to hash
			$cept[$i] = $hash{$self->[1][$i]} = [$offset, $size];
			
			# update offset
			$offset += $size;
			
			# adjust to 4-byte boundary
			$offset += -$offset % 4;
			
		} else {
			
			# set table entry
			$cept[$i] = $hash{$self->[1][$i]};
			
		}
		
		# write curve element position entry
		print $fh pack('N2', @{$cept[$i]});
		
	}

	# initialize hash
	%hash = ();

	# for each curve element
	for my $i (0 .. $#{$self->[1]}) {
		
		# if tag not in hash
		if (! exists($hash{$self->[1][$i]})) {
			
			# make offset absolute
			$cept[$i][0] += $tag->[1];
			
			# write tag
			$self->[1][$i]->write_fh($self, $fh, ['cvst', $cept[$i][0], $cept[$i][1]]);
			
			# add key to hash
			$hash{$self->[1][$i]}++;
			
		}
		
	}
	
}

1;
