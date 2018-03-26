package ICC::Profile::desc;

use strict;
use Carp;

our $VERSION = 0.22;

# revised 2016-05-17
#
# Copyright © 2004-2018 by William B. Birkett

# add development directory
use lib 'lib';

# inherit from Shared
use parent qw(ICC::Shared);

# support modules
use Encode; # Unicode module

# create new desc tag object
# parameters: ()
# parameters: (ref_to_attribute_hash)
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();
	
	# create empty desc object
	my $self = [
				{},		# object header
				'',		# ASCII string
				0,		# Unicode language
				'',		# Unicode string
				0,		# ScriptCode code
				''		# ScriptCode string
			];

	# if single parameter is a hash reference
	if (@_ == 1 && ref($_[0]) eq 'HASH') {

		# set object attributes
		_newICCdesc($self, @_);

	}

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# create desc tag object from ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
# returns: (ref_to_object)
sub new_fh {

	# get object class
	my $class = shift();

	# create empty desc object
	my $self = [
				{},		# object header
				'',		# ASCII string
				0,		# Unicode language
				'',		# Unicode string
				0,		# ScriptCode language
				''		# ScriptCode string
			];

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# read desc data from profile
	_readICCdesc($self, @_);

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# writes desc tag object to ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub write_fh {

	# get tag reference
	my $self = shift();

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# write desc data to profile
	_writeICCdesc($self, @_);

}

# get tag size (for writing to profile)
# returns: (tag_size)
sub size {
	
	# get parameters
	my ($self) = @_;
	
	# return size
	return(91 + length($self->[1]) + 2 * length($self->[3]) + (length($self->[3]) > 0 ? 2 : 0));
	
}

# get ASCII desc string
# parameters: ([desc_string])
# returns: (desc_string)
sub ASCII {

	# get object reference
	my $self = shift();
	
	# if parameter supplied
	if (@_) {
		
		# save desc string
		$self->[1] = shift();
		
	}
	
	# return desc string
	return($self->[1]);

}

# get Unicode desc string
# parameters: ([desc_string, [lang_code]])
# returns: (desc_string, [lang_code])
sub Unicode {

	# get object reference
	my $self = shift();
	
	# if parameter supplied
	if (@_) {
		
		# save desc string
		$self->[3] = shift();
		
		# if parameter supplied
		if (@_) {
			
			# save language code
			$self->[2] = shift();
			
		}
		
	}
	
	# if language code wanted
	if (wantarray) {
		
		# return desc string and language code
		return($self->[3], $self->[2]);
		
	} else {
		
		# return desc string
		return($self->[3]);
		
	}

}

# get ScriptCode desc string
# parameters: ([desc_string, [ScriptCode_code]])
# returns: (desc_string, [ScriptCode_code])
sub ScriptCode {

	# get object reference
	my $self = shift();
	
	# if parameter supplied
	if (@_) {
		
		# save desc string
		$self->[5] = shift();
		
		# if parameter supplied
		if (@_) {
			
			# save ScriptCode code
			$self->[4] = shift();
			
		}
		
	}
	
	# if ScriptCode code wanted
	if (wantarray) {
		
		# return desc string and ScriptCode code
		return($self->[5], $self->[4]);
		
	} else {
		
		# return desc string
		return($self->[5]);
		
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

# set object attributes from parameter hash
# supported attributes: 'ascii', 'unicode_lang', 'unicode', 'scriptcode_lang', 'scriptcode'
# parameters: (ref_to_object, parameter_hash)
sub _newICCdesc {
	
	# get parameters
	my ($self, $pars) = @_;
	
	# local variables
	my (%desc);
	
	# hash of description strings
	%desc = ('ascii' => 1, 'unicode_lang' => 2, 'unicode' => 3, 'scriptcode_lang' => 4, 'scriptcode' => 5);
	
	# for each parameter key
	for my $key (keys(%{$pars})) {
		
		# if supported key
		if (exists($desc{$key})) {
			
			# save value
			$self->[$desc{$key}] = $pars->{$key};
			
		}
		
	}
	
}

# read desc tag from ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _readICCdesc {
	
	# get parameters
	my ($self, $parent, $fh, $tag) = @_;
	
	# local variables
	my ($buf, $cnt);
	
	# save tag signature
	$self->[0]{'signature'} = $tag->[0];
	
	# seek start of tag
	seek($fh, $tag->[1], 0);
		
	# read first 12 bytes
	read($fh, $buf, 12);
	
	# unpack ASCII string count
	$cnt = unpack('x8 N', $buf);
	
	# read ASCII string and Unicode language/count
	read($fh, $buf, $cnt + 8);
	
	# unpack ASCII string and Unicode language/count
	($self->[1], $self->[2], $cnt) = unpack("Z$cnt N2", $buf);
	
	# doulbe Unicode count
	$cnt *= 2;
	
	# read Unicode string and ScriptCode language/count
	read($fh, $buf, $cnt + 3);
	
	# unpack Unicode string and ScriptCode language/count
	($self->[3], $self->[4], $cnt) = unpack("a$cnt nC", $buf);
	
	# decode Unicode string
	$self->[3] = decode('UTF-16BE', $self->[3]);
	
	# chop null terminator
	chop($self->[3]);
	
	# read ScriptCode string
	read($fh, $buf, 67);
	
	# unpack ScriptCode string
	$self->[5] = unpack("Z$cnt", $buf);
	
}

# write desc tag to ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _writeICCdesc {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my ($cnt, $ufmt);

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# get ASCII count
	$cnt = length($self->[1]) + 1;

	# write ASCII
	print $fh pack("a4 x4 N Z$cnt", 'desc', $cnt, $self->[1]);

	# get Unicode count
	$cnt = length($self->[3]) + 1;

	# if count > 1
	if ($cnt > 1) {
		
		# make Unicode format string
		$ufmt = 'a' . (2 * $cnt);
		
		# write Unicode
		print $fh pack("N N $ufmt", $self->[2], $cnt, encode('UTF-16BE', ($self->[3] . chr(0))));
		
	} else {
		
		# write nulls
		print $fh pack('x8');
		
	}
	
	# get ScriptCode count
	$cnt = length($self->[5]) + 1;
	
	# if count > 1
	if ($cnt > 1) {
		
		# write ScriptCode
		print $fh pack('n C Z67', $self->[4], $cnt, $self->[5]);
		
	} else {
		
		# write nulls
		print $fh pack('x70');
		
	}
	
}

1;