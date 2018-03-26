package ICC::Profile;

use strict;
use Carp;

our $VERSION = 0.60;

# revised 2017-08-05
#
# Copyright © 2004-2018 by William B. Birkett

# add development directories
BEGIN {

	# local variable
	my ($home);

	# if Windows
	if ($^O eq 'MSWin32') {
		
		# use Parallels home volume
		$home = 'Y:';
		
	} else {
		
		# use UNIX home path
		$home = $ENV{'HOME'};
		
	}

	# add development directories to @INC
	unshift(@INC, "$home/Projects/Software/ICC_Modules/ICC-Profile/lib");
	unshift(@INC, "$home/Projects/Software/ICC_Modules/ICC-Support-Image/lib");
	unshift(@INC, "$home/Projects/Software/ICC_Modules/ICC-Support-Image/blib/arch");
	unshift(@INC, "$home/Projects/Software/ICC_Modules/ICC-Support-Lapack/blib/lib");
	unshift(@INC, "$home/Projects/Software/ICC_Modules/ICC-Support-Lapack/blib/arch");
	unshift(@INC, "$home/Projects/Software/ICC_Modules/ICC-Support-Levmar/blib/lib");
	unshift(@INC, "$home/Projects/Software/ICC_Modules/ICC-Support-Levmar/blib/arch");

}

# global variables
our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS);

# inherit from Exporter and ICC::Shared
use parent qw(Exporter ICC::Shared);

# load library modules
BEGIN {

	# local variables
	my (@modules, @opt, @export);

	# module list
	@modules = qw(
		Data::Dumper
		Digest::MD5
		File::Glob
		ICC::Profile::clro
		ICC::Profile::clrt
		ICC::Profile::clut
		ICC::Profile::curf
		ICC::Profile::curv
		ICC::Profile::cvst
		ICC::Profile::data
		ICC::Profile::desc
		ICC::Profile::gbd_
		ICC::Profile::Generic
		ICC::Profile::mAB_
		ICC::Profile::mBA_
		ICC::Profile::matf
		ICC::Profile::mft1
		ICC::Profile::mft2
		ICC::Profile::mluc
		ICC::Profile::mpet
		ICC::Profile::ncl2
		ICC::Profile::para
		ICC::Profile::parf
		ICC::Profile::pseq
		ICC::Profile::samf
		ICC::Profile::sf32
		ICC::Profile::sig_
		ICC::Profile::text
		ICC::Profile::vcgt
		ICC::Profile::view
		ICC::Profile::XYZ_
		ICC::Profile::ZXML
		ICC::Shared
		ICC::Support::akima
		ICC::Support::bern
		ICC::Support::Chart
		ICC::Support::Color
		ICC::Support::geo1
		ICC::Support::geo2
		ICC::Support::nMIX
		ICC::Support::nNET
		ICC::Support::nNET2
		ICC::Support::nPINT
		ICC::Support::PCS
		ICC::Support::ratfunc
		ICC::Support::rbf
		ICC::Support::spline
		ICC::Support::spline2
	);

	# optional modules
	@opt = qw (
		ICC::Support::Image
		ICC::Support::Lapack
		ICC::Support::Levmar
	);

	# disable strict refs (to access exported lists)
	no strict 'refs';

	# for each module
	for my $mod (@modules, @opt) {
		
		# load module
		eval "use $mod";
		
		# if error
		if ($@) {
			
			# if an optional module
			if (grep {$mod eq $_} @opt) {
				
				# warn
				print("failed to load optional module $mod\n");
				
			} else {
				
				# error
				die("error loading module $mod");
				
			}
			
		}
		
		# get exported list
		@export = @{$mod . '::EXPORT'};
		
		# add to export list
		push(@EXPORT, @export);
		
		# match module key
		$mod =~ m/:?(\w+)$/;
		
		# add to group hash
		$EXPORT_TAGS{lc($1)} = [@export];
		
	}

	# restore strict refs
	use strict;

	# copy EXPORT list to EXPORT_OK
	@EXPORT_OK = @EXPORT;

	# add 'all' to group hash
	$EXPORT_TAGS{'all'} = \@EXPORT;

}

# create new profile object
# parameters: ()
# parameters: (ref_to_parameter_hash)
# parameters: (path_to_profile, [default_profile_path])
# parameters: (path_to_TIFF, [default_profile_path])
# parameters: (path_to_PSD, [default_profile_path])
# supported hash keys: 'version', 'class', 'subclass', 'data', 'PCS', 'render'
# returns: (ref_to_profile_object)
sub new {

	# get object class
	my $class = shift();

	# create empty profile object
	my $self = [
		{},    # object header
		[],    # profile header
		[]     # tag table
	];

	# if one parameter, a hash reference
	if (@_ == 1 && ref($_[0]) eq 'HASH') {
		
		# create new profile from parameter hash
		_newICCprofile($self, @_);
		
	# if any parameters
	} elsif (@_) {
		
		# read data from existing profile
		_readICCprofile($self, @_) || carp("couldn't read profile: $_[0]\n");
		
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
			croak('parameter must be a hash reference');
			
		}
		
	}

	# return reference
	return($self->[0]);

}

# get/set profile header
# parameters: ([ref_to_new_array])
# returns: (ref_to_array)
sub profile_header {

	# get object reference
	my $self = shift();

	# if there are parameters
	if (@_) {
		
		# if one parameter, an array reference
		if (@_ == 1 && ref($_[0]) eq 'ARRAY' && @{$_[0]} == grep {! ref()} @{$_[0]}) {
			
			# set header to copy of array
			$self->[1] = [@{shift()}];
			
		} else {
			
			# error
			croak('profile header must be an array reference');
			
		}
		
	}

	# return reference
	return($self->[1]);

}

# get/set profile tag table
# parameters: ([ref_to_new_array])
# returns: (ref_to_array)
sub tag_table {

	# get object reference
	my $self = shift();

	# if there are parameters
	if (@_) {
		
		# if one parameter, a 2-D array reference
		if (@_ == 1 && ref($_[0]) eq 'ARRAY' && @{$_[0]} == grep {ref() eq 'ARRAY'} @{$_[0]}) {
			
			# set tag table to copy of array
			$self->[2] = Storable::dclone(shift());
			
		} else {
			
			# error
			croak('profile tag table must be a 2-D array reference');
			
		}
		
	}

	# return reference
	return($self->[2]);

}

# get/set tag objects
# get tag object(s) returns 'undef' if tag signature not found
# parameters: (list_of_tag_signatures)
# returns: (list_of_tag_objects)
# set tag object(s) replaces, adds or deletes tags
# hash keys are tag signatures, hash values are object refs
# a hash value of 'delete' will delete the tag
# parameters: (ref_to_parameter_hash)
# returns: (list_of_tag_objects)
sub tag {

	# get object reference
	my $self = shift();

	# local variables
	my ($hash, $value, @match, @tags, $rem);

	# if parameter hash supplied
	if (@_ == 1 && ref($_[0]) eq 'HASH') {
		
		# get hash
		$hash = shift();
		
		# for each key
		for my $key (keys(%{$hash})) {
			
			# get value
			$value = $hash->{$key};
			
			# verify tag signature
			(length($key) == 4) || croak('tag signature wrong length');
			
			# match tag signature
			@match = grep {$key eq $self->[2][$_][0]} (0 .. $#{$self->[2]});
			
			# if tag value undefined or an ICC::Profile or ICC::Support object
			if (! defined($value) || ref($value) =~ m/^ICC::(Profile|Support)::/) {
				
				# if no matches
				if (@match == 0) {
					
					# add new tag
					push(@{$self->[2]}, [$key, 0, 0, $value]);
					
				# if one match
				} elsif (@match == 1) {
					
					# modify matched tag
					$self->[2][$match[0]] = [$key, 0, 0, $value];
					
				# more than one match
				} else {
					
					# modify first matched tag
					$self->[2][$match[0]] = [$key, 0, 0, $value];
					
					# print warning
					carp "tag table contains multiple tags with '$key' signature\n";
					
				}
				
				# add tag to list
				push(@tags, $value);
				
			# if tag value is 'delete'
			} elsif ($value eq 'delete') {
				
				# if no matches
				if (@match == 0) {
					
					# print warning
					carp "tag table contains no '$key' tag(s) to delete\n";
					
				# one or more matches
				} else {
					
					# for each tag
					for my $i (@match) {
						
						# delete tag
						$rem = splice(@{$self->[2]}, $i, 1);
						
						# add tag to list
						push(@tags, defined($rem) ? $rem->[3] : undef);
						
					}
					
				}
				
			} else {
				
				# error
				croak("invalid '$key' tag value");
				
			}
			
		}
		
	# if list of tag signatures
	} elsif (@_) {
		
		# for each signature
		for my $key (@_) {
			
			# match tag signature
			@match = grep {$key eq $_->[0]} @{$self->[2]};
			
			# if no matches
			if (@match == 0) {
				
				# add 'undef' to tag list
				push(@tags, undef);
				
			# if one match
			} elsif (@match == 1) {
				
				# add matched tag to tag list
				push(@tags, $match[0][3]);
				
			# more than one match
			} else {
				
				# add first matched tag to tag list
				push(@tags, $match[0][3]);
				
				# print warning
				carp "tag table contains multiple tags with '$key' signature\n";
				
			}
			
		}
		
	}
	
	# if list is expected
	if (wantarray) {
		
		# return tag list
		return(@tags);
		
	} else {
		
		# return first tag
		return($tags[0]);
		
	}
	
}

# write ICC profile
# parameters: (path_to_profile)
# parameters: (scalar_reference)
sub write {

	# get object reference
	my $self = shift();

	# verify parameter count
	(@_ == 1) || croak('wrong number of parameters');

	# write profile
	_writeICCprofile($self, @_);

	# return
	return();

}

# write ICC profile to scalar
# returns: (scalar_reference)
sub serialize {

	# get object reference
	my $self = shift();

	# local variable
	my $buf;

	# write profile
	_writeICCprofile($self, \$buf);

	# return
	return(\$buf);

}

# print object contents to string
# optional format may contain the characters 'p', 't' and 's'
# when the format contains 'p' the profile header will be dumped
# when the format contains 't' the profile tag table will be dumped
# when the format contains 's' the profile structure will be dumped
# when the format is omitted, a default value of 'pts' is used
# parameter: ([format])
# returns: (string)
sub sdump {

	# get parameters
	my ($self, $p) = @_;

	# local variables
	my ($header, $entry, $tag, $fmt, $s, $pt, $st);

	# resolve parameter to an array reference
	$p = defined($p) ? ref($p) eq 'ARRAY' ? $p : [$p] : [];

	# get format string
	$fmt = defined($p->[0]) && ! ref($p->[0]) ? $p->[0] : 'pts';

	# set string to object ID
	$s = sprintf("'%s' object, (0x%x)\n", ref($self), $self);

	# if format contains 'p'
	if ($fmt =~ m/p/) {
		
		# if profile header contains data
		if (@{$self->[1]}) {
			
			# get profile header array
			$header = $self->[1];
			
			# add header info
			$s .= sprintf("%24s: %d bytes\n", 'Size', $header->[0]);
			$s .= sprintf("%24s: %4s\n", 'Preferred CMM', $header->[1]);
			$s .= sprintf("%24s: %d.%d.%d\n", 'Specification Version', substr($header->[2], 0, 2), substr($header->[2], 2, 1), substr($header->[2], 3, 1));
			$s .= sprintf("%24s: %4s\n", 'Class', $header->[3]);
			$s .= sprintf("%24s: %4s\n", 'Data', $header->[4]);
			$s .= sprintf("%24s: %4s\n", 'PCS', $header->[5]);
			$s .= sprintf("%24s: %04d-%02d-%02d %02d:%02d:%02d\n", 'Created', @{$header}[6 .. 11]);
			$s .= sprintf("%24s: %4s\n", 'Platform', $header->[13]);
			$s .= sprintf("%24s: <0x%08x>\n", 'Flags', $header->[14]);
			$s .= sprintf("%24s: %4s\n", 'Device Manufacturer', $header->[15]);
			$s .= sprintf("%24s: %4s\n", 'Device Model', $header->[16]);
			$s .= sprintf("%24s: <0x%08x> <0x%08x>\n", 'Device Attributes', @{$header}[17 .. 18]);
			$s .= sprintf("%24s: %d\n", 'Rendering Intent', $header->[19]);
			$s .= sprintf("%24s: %7.5f, %7.5f, %7.5f\n", 'PCS Illuminant', map {$_/65536} @{$header}[20 .. 22]);
			$s .= sprintf("%24s: %4s\n", 'Creator', $header->[23]);
			
			# if no MD5 signature
			if ($header->[24] eq '00' x 16) {
				
				# print no MD5 signature
				$s .= sprintf("%24s:\n\n", 'MD5 Signature');
				
			} else {
				
				# print MD5 signature in 8 byte segments
				$s .= sprintf("%24s: %8s %8s %8s %8s\n\n", 'MD5 Signature', substr($header->[24], 0, 8), substr($header->[24], 8, 8), substr($header->[24], 16, 8), substr($header->[24], 24, 8));
				
			}
			
		} else {
			
			# add message
			$s .= "<header empty>\n";
			
		}
		
	}

	# if format contains 't'
	if ($fmt =~ m/t/) {
		
		# if tag table contains data
		if (@{$self->[2]}) {
			
			# print tag table header
			$s .= "   #   Tag           Object Type         Offset     Size\n";
			
			# for each tag table entry
			for my $i (0 .. $#{$self->[2]}) {
				
				# get tag table entry
				$entry = $self->[2][$i];
				
				# print tag table entry
				$s .= sprintf("%4d  '%4s'  %-24s %8d %8d\n", $i + 1, $entry->[0], ref($entry->[3]) || '        undefined', $entry->[1] || 0, $entry->[2] || 0);
				
			}
			
			# add line ending
			$s .= "\n";
			
		} else {
			
			# add message
			$s .= "<tag table empty>\n";
			
		}
		
	}

	# if format contains 's'
	if ($fmt =~ m/s/) {
		
		# get default parameter
		$pt = $p->[-1];
		
		# for each tag
		for my $i (0 .. $#{$self->[2]}) {
			
			# get tag reference
			$tag = $self->[2][$i][3];
			
			# if tag is undefined
			if (! defined($tag)) {
				
				# append message
				$s .= "\ttag is undefined\n";
				
			# if tag is not a blessed object
			} elsif (! Scalar::Util::blessed($tag)) {
				
				# append message
				$s .= "\ttag is not a blessed object\n";
				
			# if tag has an 'sdump' method
			} elsif ($tag->can('sdump')) {
				
				# get 'sdump' string
				$st = $tag->sdump(defined($p->[$i + 1]) ? $p->[$i + 1] : $pt);
				
				# prepend tabs to each line
				$st =~ s/^/\t/mg;
				
				# append 'sdump' string
				$s .= $st;
				
			# tag is object without an 'sdump' method
			} else {
				
				# append object info
				$s .= sprintf("\t'%s' object, (0x%x)\n", ref($tag), $tag);
				
			}
			
		}
		
	}

	# return
	return($s);

}

# create new profile object
# parameters: (ref_to_object, parameter_hash)
sub _newICCprofile {

	# get parameters
	my ($self, $hash) = @_;

	# local variables
	my ($version, $class, $subclass, $dcs, $pcs, $dri) = @{$hash}{qw(version class subclass data PCS render)};
	my ($redcs, $repcs, $vmaj, $vmin);

	# regular expression to match data color space (table 19, ICC1v43_2010-12)
	$redcs = qr/^(XYZ |Lab |Luv |YCbr|Yxy |RGB |GRAY|HSV |HLS |CMYK|CMY |[2-9A-F]CLR)$/;

	# regular expression to match profile connection space (section 7.2.7, ICC1v43_2010-12)
	$repcs = qr/^(XYZ |Lab )$/;

	# resolve version number (optional, default version 2.4)
	$version = defined($version) ? $version : '02400000';

	# verify version number (section 7.2.4, ICC1v43_2010-12)
	($version =~ m/^[0-9]{4}0000$/) || croak('invalid version number');

	# get major revision
	$vmaj = substr($version, 0, 2);

	# get minor revision
	$vmin = substr($version, 2, 1);

	# verify profile class (required) (table 18, ICC1v43_2010-12)
	(defined($class)) || croak('missing profile class parameter');
	($class =~ m/^(scnr|mntr|prtr|link|spac|abst|nmcl)$/) || croak('invalid profile class');

	# resolve subclass (optional, default 0)
	$subclass = defined($subclass) ? $subclass : 0;

	# verify data color space (required)
	(defined($dcs)) || croak('missing data color space parameter');
	(($dcs =~ $repcs) || ($class ne 'abst' && $dcs =~ $redcs)) || croak('invalid data color space');

	# verify profile connection space (required)
	$pcs = $hash->{'PCS'} || croak('missing profile connection space parameter');
	(($pcs =~ $repcs) || ($class eq 'link' && $pcs =~ $redcs)) || croak('invalid profile connection space');

	# resolve default rendering intent (optional, default 0)
	$dri = defined($dri) ? $dri : 0;

	# verify default rendering intent (table 23, ICC1v43_2010-12)
	($dri =~ m/^[0-3]$/) || croak('invalid default rendering intent');

	# set header (note: size, time and ID are computed when writing profile)
	$self->[1] = [
		0,				# profile size
		"\x00" x 4, 	# preferred CMM type signature
		$version,		# profile version number
		$class,			# profile/device class signature
		$dcs,			# data color space
		$pcs,			# profile connection space
		0,				# year
		0,				# month
		0,				# day
		0,				# hour
		0,				# minute
		0,				# second
		'acsp',			# profile file signature
		'APPL',			# primary platform signature
		0,				# flags
		"\x00" x 4,		# device manufacturer
		"\x00" x 4,		# device model
		0,				# attributes
		0,				# attributes (reserved for ICC)
		$dri,			# default rendering intent
		0x00F6D6,		# illuminant X (D50)
		0x010000,		# illuminant Y (D50)
		0x00D32D,		# illuminant Z (D50)
		'DPLG',			# profile creator signature (Doppelganger)
		'00' x 16		# profile ID (MD5)
	];

	# if an input device profile
	if ($class eq 'scnr') {
		
		# set tag table
		$self->[2] = [
			['desc'],
			['cprt'],
			['wtpt']
		];
		
		# if subclass 0 (N-component LUT-based input profile)
		if ($subclass == 0) {
			
			# add AToB0Tag
			push(@{$self->[2]},
				['A2B0']
			);
			
		# if subclass 1 (Three-component matrix-based input profile)
		} elsif ($subclass == 1) {
			
			# add additional required tags
			push(@{$self->[2]},
				['rXYZ'],
				['gXYZ'],
				['bXYZ'],
				['rTRC'],
				['gTRC'],
				['bTRC']
			);
			
		# if subclass 2 (Monochrome input profile)
		} elsif ($subclass == 2) {
			
			# add grayTRCTag
			push(@{$self->[2]},
				['kTRC']
			);
			
		}
		
	# if a display device profile
	} elsif ($class eq 'mntr') {
		
		# set tag table
		$self->[2] = [
			['desc'],
			['cprt'],
			['wtpt']
		];
		
		# if subclass 0 (N-Component LUT-based display profile)
		if ($subclass == 0) {
			
			# add additional required tags
			push(@{$self->[2]},
				['A2B0'],
				['B2A0']
			);
			
		# if subclass 1 (Three-component matrix-based display profile)
		} elsif ($subclass == 1) {
			
			# add additional required tags
			push(@{$self->[2]},
				['rXYZ'],
				['gXYZ'],
				['bXYZ'],
				['rTRC'],
				['gTRC'],
				['bTRC']
			);
			
		# if subclass 2 (Monochrome display profile)
		} elsif ($subclass == 2) {
			
			# add grayTRCTag
			push(@{$self->[2]},
				['kTRC']
			);
			
		}
		
	# if a output device profile
	} elsif ($class eq 'prtr') {
		
		# set tag table
		$self->[2] = [
			['desc'],
			['cprt'],
			['wtpt']
		];
		
		# if subclass 0 (N-component LUT-based output profile)
		if ($subclass == 0) {
			
			# add additional required tags
			push(@{$self->[2]},
				['A2B0'],
				['A2B1'],
				['A2B2'],
				['B2A0'],
				['B2A1'],
				['B2A2'],
				['gamt']
			);
			
			# if data color space is xCLR and version 4
			if ($dcs =~ m|CLR$| && $vmaj == 4) {
				
				# add colorantTableTag
				push(@{$self->[2]},
					['clrt']
				);
				
			}
			
		# if subclass 2 (Monochrome output profile)
		} elsif ($subclass == 2) {
			
			# add grayTRCTag
			push(@{$self->[2]},
				['kTRC']
			);
			
		}
		
	# if a device link profile
	} elsif ($class eq 'link') {
		
		# set tag table
		$self->[2] = [
			['desc'],
			['cprt'],
			['pseq'],
			['A2B0']
		];
		
		# if data color space is xCLR and version 4
		if ($dcs =~ m|CLR$| && $vmaj == 4) {
			
			# add colorantTableTag
			push(@{$self->[2]},
				['clrt']
			);
			
		}
		
		# if data color space is xCLR and version 4
		if ($pcs =~ m|CLR$| && $vmaj == 4) {
			
			# add colorantTableOutTag
			push(@{$self->[2]},
				['clot']
			);
			
		}
		
	# if a color space conversion profile
	} elsif ($class eq 'spac') {
		
		# set tag table
		$self->[2] = [
			['desc'],
			['cprt'],
			['wtpt'],
			['A2B0'],
			['B2A0']
		];
		
	# if an abstract profile
	} elsif ($class eq 'abst') {
		
		# set tag table
		$self->[2] = [
			['desc'],
			['cprt'],
			['wtpt'],
			['A2B0']
		];
		
	# if a named color profile
	} else {
		
		# set tag table
		$self->[2] = [
			['desc'],
			['cprt'],
			['wtpt'],
			['ncl2']
		];
		
	}
	
}

# read embedded profile from PSD file
# parameters: (file_handle)
# returns: (reference_to_buffer)
sub _readICCprofilePSD {

	# get file handle
	my $fh = shift();

	# local variables
	my ($buf, @header, @res, $end);

	# seek start of file
	seek($fh, 0, 0);

	# read the header
	(read($fh, $buf, 30) == 30) || return(0);

	# unpack the header
	@header = unpack('a4 n x6 n N N n n N', $buf);

	# verify PSD signature
	if (($header[0] eq '8BPS') && ($header[1] == 1)) {
		
		# skip to resource size
		seek($fh, $header[7], 1);
		
		# read resource size
		read($fh, $buf, 4);
		
		# compute resource block end
		$end = tell($fh) + unpack('N', $buf);
		
		# while file position < resource block end
		while (tell($fh) < $end) {
			
			# read resource type, ID and name count
			read($fh, $buf, 7);
			
			# unpack resource type, ID and name count
			@res = unpack('a4 n C', $buf);
			
			# read the resource name (Pascal string)
			read($fh, $buf, $res[2] + (1 - $res[2] % 2));
			
			# save the resource name
			$res[2] = substr($buf, 0, $res[2]);
			
			# read the resource size
			read($fh, $buf, 4);
			
			# unpack resource size
			$res[3] = unpack('N', $buf);
			
			# if ICC profile resource
			if ($res[1] == 1039) {
				
				# read profile
				read($fh, $buf, $res[3]);
				
				# return buffer reference
				return(\$buf);
				
			}
			
			# skip to next resource
			seek($fh, $res[3] + (- $res[3] % 2), 1);
			
		}
		
	}

	# return (no profile found)
	return(0);

}

# read embedded profile from TIFF file
# parameters: (file_handle)
# returns: (reference_to_buffer)
sub _readICCprofileTIFF {

	# get file handle
	my $fh = shift();

	# local variables
	my (@ts, $buf, $short, $long, @header);
	my ($count, @tag, $size);

	# type size (in bytes)
	@ts = (0, 1, 1, 2, 4, 8, 1, 1, 2, 4, 8, 4, 8);

	# seek start of file
	seek($fh, 0, 0);

	# read the header
	(read($fh, $buf, 8) == 8) || return(0);

	# if big-endian (Motorola)
	if ($buf =~ m|^MM|) {
		
		# set unpack formats
		$short = 'n';
		$long = 'N';
	
	# little-endian (Intel)
	} else {
		
		# set unpack formats
		$short = 'v';
		$long = 'V';
		
	}

	# unpack the header
	@header = unpack("A2 $short $long", $buf);

	# verify TIFF file signature
	if ($header[1] == 42) {
		
		# seek first IFD (image file directory)
		seek($fh, $header[2], 0);
		
		# read number entries
		read($fh, $buf, 2);
		
		# unpack the directory count
		$count = unpack("$short", $buf);
		
		# read the directory
		for (1 .. $count) {
			
			# read first part of IFD entry
			read($fh, $buf, 8);
			
			# unpack tag, type and count
			@tag = unpack("$short $short $long", $buf);
			
			# read last part of IFD entry
			read($fh, $buf, 4);
			
			# determine value/offset size
			$size = $ts[$tag[1]] * $tag[2] + (($tag[1] == 2) ? 1 : 0);
			
			# if value/offset size > 4 or a single long value
			if ($size > 4 || $ts[$tag[1]] == 4) {
				
				# unpack value/offset
				$tag[3] = unpack($long, $buf);
				
			} elsif ($ts[$tag[1]] == 2 && $tag[2] == 1) {
				
				# unpack value
				$tag[3] = unpack($short, $buf);
				
			} elsif ($ts[$tag[1]] == 2 && $tag[2] == 2) {
				
				# unpack values
				$tag[3 .. 4] = unpack("$short $short", $buf);
				
			}
			
			# if ICC profile tag
			if ($tag[0] == 34675) {
				
				# seek start of profile
				seek($fh, $tag[3], 0);

				# read profile
				read($fh, $buf, $tag[2]);

				# close file
				close($fh);

				# return reference to buffer
				return(\$buf);
				
			}
			
		}
		
	}

	# return
	return(0);

}

# read profile data from profile file
# parameters: (ref_to_object, path_to_profile, [path_to_default_profile])
# parameters: (ref_to_object, scalar_reference, [path_to_default_profile])
# returns: (success_flag)
sub _readICCprofile {

	# get parameters
	my ($self, $path, $default) = @_;

	# local variables
	my ($fh, $buf, $ref);
	my (%hash, $type, $class);
	my ($wtpt, $bkpt, $A2B0, $A2B1);

	# if path a scalar reference
	if (ref($path) eq 'SCALAR') {
		
		# open the profile file
		open($fh, '<', $path) or croak("unable to read profile from scalar");
		
		# save file type in object header
		$self->[0]{'file_type'} = 'scalar';
		
	# if path a scalar
	} elsif (! ref($path)) {
		
		# filter file path
		ICC::Shared::filterPath($path);
		
		# open the profile file
		open($fh, '<', $path) or croak("unable to read profile from $path");
		
		# save path in object header
		$self->[0]{'file_path'} = $path;

		# save file type in object header
		$self->[0]{'file_type'} = 'prof';

	} else {
		
		# error
		croak("invalid path parameter");
		
	}

	# set binary mode
	binmode($fh);

	# seek to profile file signature
	seek($fh, 36, 0);

	# read profile file signature
	read($fh, $buf, 4);

	# if not an ICC profile
	if ($buf ne 'acsp') {
		
		# if TIFF with embedded profile
		if ($ref = _readICCprofileTIFF($fh)) {
			
			# open the profile
			open($fh, '<', $ref);
			
			# set binary mode
			binmode($fh);
			
			# save file type in object header
			$self->[0]{'file_type'} = 'TIFF';

		# if PSD with embedded profile
		} elsif ($ref = _readICCprofilePSD($fh)) {
			
			# open the profile
			open($fh, '<', $ref);
			
			# set binary mode
			binmode($fh);
			
			# save file type in object header
			$self->[0]{'file_type'} = '8BPS';

		# if default profile path supplied
		} elsif (defined($default)) {
			
			# close current file
			close($fh);
			
			# filter file path
			ICC::Shared::filterPath($default);
		
			# open the profile file
			open($fh, '<', $default) || return(0);
			
			# set binary mode
			binmode($fh);
			
			# save path in object header
			$self->[0]{'file_path'} = $default;
			
			# seek to profile file signature
			seek($fh, 36, 0);
			
			# read profile file signature
			read($fh, $buf, 4);
			
			# if not an ICC profile
			if ($buf ne 'acsp') {
				
				# close file
				close($fh);
				
				# return
				return(0);
				
			}
			
		} else {
			
			# close file
			close($fh);
			
			# return
			return(0);
			
		}
		
	}

	# read the header
	_readICCheader($fh, $self->[1]) || return(0);

	# read the tag table
	_readICCtagtable($fh, $self->[2]) || return(0);

	# for each tag
	for my $tag (@{$self->[2]}) {
		
		# if a duplicate tag
		if (exists($hash{$tag->[1]})) {
			
			# use original tag
			$tag->[3] = $hash{$tag->[1]};
			
		} else {
			
			# seek to start of tag
			seek($fh, $tag->[1], 0);
			
			# read tag type signature
			read($fh, $type, 4);
			
			# convert non-word characters to underscores
			$type =~ s|\W|_|g;
			
			# form class specifier
			$class = "ICC::Profile::$type";
			
			# if 'class->new_fh' method exists
			if ($class->can('new_fh')) {
				
				# create specific tag object
				$tag->[3] = $class->new_fh($self, $fh, $tag);
				
			} else {
				
				# create generic tag object
				$tag->[3] = ICC::Profile::Generic->new_fh($self, $fh, $tag);
				
				# print message
				print "tag type $type opened as generic\n";
				
			}
			
			# save tag in hash
			$hash{$tag->[1]} = $tag->[3];
			
		}
		
		# save white point tag
		$wtpt = $tag->[3] if ($tag->[0] eq 'wtpt');
		
		# save black point tag
		$bkpt = $tag->[3] if ($tag->[0] eq 'bkpt');
		
		# save 'A2B0' tag
		$A2B0 = $tag->[3] if ($tag->[0] eq 'A2B0');
		
		# save 'A2B1' tag
		$A2B1 = $tag->[3] if ($tag->[0] eq 'A2B1');
		
	}

	# close the profile file
	close($fh);

	# for each tag
	for my $tag (@{$self->[2]}) {
		
		# if an 'A2Bx', 'B2Ax', or 'gamt' tag
		if (($tag->[0] =~ m/^(A2B[0-9A-F]|B2A[0-9A-F]|gamt)$/) && defined($tag->[3])) {
			
			# add white point XYZ values to tag header (if available)
			$tag->[3][0]{'wtpt'} = [@{$wtpt->XYZ}] if defined($wtpt);
			
			# add black point XYZ values to tag header (if available)
			$tag->[3][0]{'bkpt'} = [@{$bkpt->XYZ}] if defined($bkpt);
			
			# add pcs encoding to tag header
			$tag->[3][0]{'pcs_encoding'} = _pcs($self, defined($A2B1) ? $A2B1 : $A2B0);
			
		# if a 'D2Bx', 'B2Dx' or 'gbdx' tag
		} elsif (($tag->[0] =~ m/^(D2B[0-9A-F]|B2D[0-9A-F]|gbd[0-3])$/) && defined($tag->[3])) {
			
			# add white point XYZ values to tag header (if available)
			$tag->[3][0]{'wtpt'} = [@{$wtpt->XYZ}] if defined($wtpt);
			
			# add black point XYZ values to tag header (if available)
			$tag->[3][0]{'bkpt'} = [@{$bkpt->XYZ}] if defined($bkpt);
			
			# add pcs encoding to tag header (32-bit)
			$tag->[3][0]{'pcs_encoding'} = $self->[1][5] eq 'Lab ' ? 3 : 8;
			
		}
		
	}

	# return
	return(1);

}

# read ICC header
# parameters: (file_handle, ref_to_header_array)
# returns: (success_flag)
sub _readICCheader {

	# get parameters
	my ($fh, $header) = @_;

	# seek to start of header
	seek($fh, 0, 0);

	# read the header (128 bytes)
	(read($fh, my $buf, 128) == 128) || return(0);

	# unpack the header
	@{$header} = unpack('N a4 H8 a4 a4 a4 n6 a4 a4 N a4 a4 N2 N N3 a4 H32 x28', $buf);

	# return success if profile file signature verified
	return($header->[12] eq 'acsp' ? 1 : 0);

}

# read ICC tag table
# parameters: (file_handle, ref_to_tag_table_array)
# returns: (success_flag)
sub _readICCtagtable {

	# get parameters
	my ($fh, $tagtab) = @_;

	# local variables
	my ($buf, $n);

	# seek to start of tag table
	seek($fh, 128, 0);

	# read tag count (4 bytes)
	(read($fh, $buf, 4) == 4) || return(0);

	# unpack tag count
	$n = unpack('N', $buf);

	# read tag entries
	for my $i (0 .. $n - 1) {
	
		# read tag entry (12 bytes)
		(read($fh, $buf, 12) == 12) || return(0);
		
		# unpack tag entry
		$tagtab->[$i] = [unpack('a4 N N', $buf)];
		
	}

	# return
	return(1);

}

# write ICC profile
# parameters: (ref_to_object, path_to_profile)
sub _writeICCprofile {

	# get parameters
	my ($self, $path) = @_;

	# local variables
	my (@localtime);
	my ($fh, $fp, $sig, %hash, %dup, $pad);
	my ($vmaj, $ri, $flags);

	# get profile major version
	$vmaj = substr($self->[1][2], 0, 2);

	# get localtime
	@localtime = localtime();

	# set time in profile header
	@{$self->[1]}[6 .. 11] = (
		$localtime[5] + 1900,	# year
		$localtime[4] + 1,		# month
		$localtime[3],			# day
		$localtime[2],			# hour
		$localtime[1],			# minute
		$localtime[0],			# second
	);
				
	# if profile version 4
	if ($vmaj == 4) {
		
		# convert tags to version 4
		_to_v4($self);
		
		# save flags
		$flags = $self->[1][14];
		
		# save rendering intent (clearing upper 16-bits)
		$ri = $self->[1][19] & 0x0000ffff;
		
		# clear for MD5 calculation
		$self->[1][14] = 0;
		$self->[1][19] = 0;
		
	}

	# clear MD5 string
	$self->[1][24] = "\x00" x 16;

	# for each tag
	for my $i (0 .. $#{$self->[2]}) {
		
		# get tag signature
		$sig = $self->[2][$i][0];
		
		# error if duplicate tag
		(! exists($dup{$sig})) || croak("duplicate '$sig' tag");
		
		# add tag to duplicate hash
		$dup{$sig} = '';
		
		# if tag object is defined
		if (defined($self->[2][$i][3])) {
			
			# if tag->size method exists
			if ($self->[2][$i][3]->can('size')) {
				
				# set tag size (without padding)
				$self->[2][$i][2] = $self->[2][$i][3]->size();
				
				# save size with padding to 4-byte boundary
				$hash{$self->[2][$i][3]} = $self->[2][$i][2] + (-$self->[2][$i][2] % 4);
				
			} else {
				
				# error
				croak("'$sig' object has no 'size' method");
				
			}
			
		} else {
			
			# error
			croak("'$sig' object undefined");
			
		}
	
	}

	# compute profile header and tag table size
	$self->[1][0] = 132 + @{$self->[2]} * 12;

	# for each unique tag
	for (values(%hash)) {
		
		# add tag size (with padding to 4-byte boundary)
		$self->[1][0] += $_;
		
	}

	# initialize hash
	%hash = ();

	# initialize file pointer
	$fp = 132 + @{$self->[2]} * 12;

	# for each tag
	for my $tag (@{$self->[2]}) {
		
		# if tag already processed
		if (exists($hash{$tag->[3]})) {
			
			# copy offset
			$tag->[1] = $hash{$tag->[3]};
			
		} else {
			
			# set offset
			$tag->[1] = $fp;
			
			# add tag to hash
			$hash{$tag->[3]} = $fp;
			
			# increment offset with padding to 4-byte boundary
			$fp += $tag->[2] + (-$tag->[2] % 4);
			
		}
		
	}

	# if path a scalar reference
	if (ref($path) eq 'SCALAR') {
		
		# open the profile file
		open($fh, '>', $path) or croak("unable to write profile to scalar");
		
	# if path a scalar
	} elsif (! ref($path)) {
		
		# filter file path
		ICC::Shared::filterPath($path);
		
		# open the profile file
		open($fh, '>', $path) or croak("unable to write profile to $path");
		
	} else {
		
		# error
		croak("invalid path parameter");
		
	}

	# set binary mode
	binmode($fh);

	# write header
	_writeICCheader($fh, $self->[1]);

	# write tag table
	_writeICCtagtable($fh, $self->[2]);

	# initialize hash
	%hash = ();

	# for each tag
	for my $tag (@{$self->[2]}) {
		
		# if tag not written
		if (! exists($hash{$tag->[3]})) {
			
			# if tag is writable
			if ($tag->[3]->can('write_fh')) {
				
				# write tag
				$tag->[3]->write_fh($self, $fh, $tag);
				
				# add to hash
				$hash{$tag->[3]}++;
				
			} else {
				
				# get tag signature
				$sig = $tag->[0];
				
				# error
				croak("'$sig' object has no 'write_fh' method");
				
			}
			
		}
		
	}

	# seek EOF (file pointer may be beyond actual EOF)
	seek($fh, 0, 2);

	# compute padding
	$pad = $self->[1][0] - tell($fh);

	# check for file overrun
	croak('file overrun') if ($pad < 0);

	# write final padding (if any)
	print $fh "\x00" x $pad if ($pad > 0);

	# close the profile file
	close($fh);

	# if profile version 4
	if ($vmaj == 4) {
		
		# re-open the profile file for read-write access
		open($fh, '+<', $path);
		
		# set binary mode
		binmode($fh);
		
		# calculate MD5 string
		$self->[1][24] = Digest::MD5->new->addfile($fh)->hexdigest;
		
		# restore flags
		$self->[1][14] = $flags;
		
		# restore rendering intent
		$self->[1][19] = $ri;
		
		# re-write header
		_writeICCheader($fh, $self->[1]);
		
		# close the profile file
		close($fh);
		
	}

	# set file creator and type (Mac OSX) if path not a reference
	ICC::Shared::setFile($path, 'sync', 'prof') if (! ref($path));

}

# write ICC header
# parameters: (file_handle, ref_to_header_array)
sub _writeICCheader {

	# get parameters
	my ($fh, $header) = @_;

	# seek to start of header
	seek($fh, 0, 0);

	# write the header (128 bytes)
	print $fh pack('N a4 H8 a4 a4 a4 n6 a4 a4 N a4 a4 N2 N N3 a4 H32 x28', @{$header});

}

# write ICC tag table
# parameters: (file_handle, ref_to_tag_table)
sub _writeICCtagtable {

	# get parameters
	my ($fh, $tagtab) = @_;

	# seek to start of tag table
	seek($fh, 128, 0);

	# write tag count (4 bytes)
	print $fh pack('N', $#{$tagtab} + 1);

	# write tag entries
	for my $tag (@{$tagtab}) {
		
		# write tag entry (12 bytes)
		print $fh pack('a4 N N', @{$tag}[0 .. 2]);
		
	}
	
}

# determine tag PCS encoding from A2B tag
# parameters: (ref_to_profile_object, ref_to_tag_object)
# returns: (pcs_type)
sub _pcs {

	# get parameters
	my ($self, $tag) = @_;

	# local variables
	my (@Labmw);

	# if profile PCS is 'XYZ '
	if ($self->[1][5] eq 'XYZ ') {
		
		# return PCS encoding (16-bit XYZ)
		return(7);
		
	# if profile PCS is 'Lab '
	} elsif ($self->[1][5] eq 'Lab ') {
		
		# if tag is 'mft2'
		if (UNIVERSAL::isa($tag, 'ICC::Profile::mft2')) {
			
			# get media white L*a*b* value
			@Labmw = $tag->transform(($self->[1][4] eq 'RGB ' ? 1 : 0) x $tag->input->cin());
			
			# return PCS encoding (16-bit ICC legacy)
			return(1) if (_dE(@Labmw, 65280/65535, 32768/65535, 32768/65535) < 0.00195);
			
			# return PCS encoding (Monaco)
			return(2) if (_dE(@Labmw, 1, 32768/65535, 32768/65535) < 0.00195);
			
			# print warning
			print "profile PCS encoding is ambiguous\n";
			
			# return PCS encoding (16-bit legacy)
			return(1);
			
		} else {
			
			# return PCS encoding (16-bit ICC CIELab)
			return(0);
			
		}
		
	} else {
		
		# return undefined (might be a device link profile)
		return();
		
	}
	
}

# compute deltaE
# parameters: (array_1, array_2)
sub _dE {

	# return
	return(sqrt(($_[0] - $_[3])**2 + (2.55 * ($_[1] - $_[4]))**2 + (2.55 * ($_[2] - $_[5]))**2));

}

# convert 'desc' tags to version 4
# see ICC1v43_2010-12.pdf, section 10.18.3
# parameters: (ref_to_object)
sub _to_v4 {

	# get parameters
	my ($self) = shift();

	# for each tag
	for my $tag (@{$self->[2]}) {
		
		# if 'desc' tag type
		if (UNIVERSAL::isa($tag->[3], 'ICC::Profile::desc')) {
			
			# replace with equivalent 'mluc' tag
			$tag->[3] = ICC::Profile::mluc->new('en', 'US', $tag->[3]->ASCII);
			
		# if 'pseq' tag type
		} elsif (UNIVERSAL::isa($tag->[3], 'ICC::Profile::pseq')) {
			
			# convert any 'desc' tags embedded in the 'pseq' tag
			#
			# for each pds
			for my $pds (@{$tag->[3][1]}) {
				
				# if profile device manufacturer tag is 'desc' tag type
				if (UNIVERSAL::isa($pds->[5], 'ICC::Profile::desc')) {
					
					# replace with equivalent 'mluc' tag
					$pds->[5] = ICC::Profile::mluc->new('en', 'US', $pds->[5]->ASCII);
					
				}
				
				# if profile device model tag is 'desc' tag type
				if (UNIVERSAL::isa($pds->[6], 'ICC::Profile::desc')) {
					
					# replace with equivalent 'mluc' tag
					$pds->[6] = ICC::Profile::mluc->new('en', 'US', $pds->[6]->ASCII);
					
				}
				
			}
			
		# if 'cprt' tag is 'text' tag type
		} elsif ($tag->[0] eq 'cprt' && UNIVERSAL::isa($tag->[3], 'ICC::Profile::text')) {
			
			# replace with equivalent 'mluc' tag
			$tag->[3] = ICC::Profile::mluc->new('en', 'US', $tag->[3]->text);
			
		}
		
	}
	
}

1;