package ICC::Profile::ZXML;

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
use Compress::Raw::Zlib; # interface to zlib

# create new ZXML tag object
# parameters: ([text_string])
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();

	# create empty ZXML object
	my $self = [
				{},		# object header
				''		# zip compressed string
	];

	# if parameter supplied
	if (@_) {
		
		# save it
		$self->[1] = shift();
		
	}

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# create ZXML tag object from ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
# returns: (ref_to_object)
sub new_fh {

	# get object class
	my $class = shift();

	# create empty ZXML object
	my $self = [
				{},		# object header
				''		# zip compressed string
	];

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# read ZXML data from profile
	_readICCZXML($self, @_);

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# writes ZXML tag object to ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub write_fh {

	# get tag reference
	my $self = shift();

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# write ZXML data to profile
	_writeICCZXML($self, @_);

}

# get tag size (for writing to profile)
# note: deflates the CxF file and saves result
# returns: (tag_size)
sub size {

	# get parameters
	my ($self) = @_;

	# return size
	return(12 + length($self->[1]));

}

# get/set zipped data string
# parameters: ([data])
# returns: (data)
sub data {

	# get object reference
	my $self = shift();

	# if parameter supplied
	if (@_) {
		
		# save it
		$self->[1] = shift();
		
	}

	# return text string
	return($self->[1]);

}

# get/set CxF text string
# inflates/deflates zipped data string
# parameters: ([text_string])
# returns: (text_string)
sub text {

	# get object reference
	my $self = shift();

	# local variables
	my ($cxf, $d, $i, $status);

	# if parameter supplied
	if (@_) {
		
		# get parameter
		$cxf = shift();
		
		# make deflation object
		($d, $status) = Compress::Raw::Zlib::Deflate->new('-AppendOutput' => 1);
		
		# check status
		($status == Z_OK) || croak("zlib error $status creating deflation object");
		
		# deflate the text string (adding 4 nulls)
		$status = $d->deflate(pack('a* x4', $cxf), $self->[1]);
		
		# check status
		($status == Z_OK) || croak("zlib error $status deflating text string");
		
		# finish decompression
		$status = $d->flush($self->[1]);
		
	} else {
		
		# make inflation object
		($i, $status) = Compress::Raw::Zlib::Inflate->new();
		
		# check status
		($status == Z_OK) || croak("zlib error $status creating inflation object");
		
		# inflate entire zip string
		$status = $i->inflate($self->[1], $cxf);
		
		# check status
		($status == Z_STREAM_END) || croak("zlib error $status inflating text string");
		
		# trim nulls from end of string
		$cxf = unpack('Z*', $cxf);
		
	}

	# return text string
	return($cxf);

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

# read ZXML tag from ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _readICCZXML {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my ($buf, $a, $b);

	# save tag signature
	$self->[0]{'signature'} = $tag->[0];

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# read tag
	read($fh, $buf, $tag->[2]);
	
	# unpack zip string
	($a, $b, $self->[1]) = unpack('x4 N2 a*', $buf);

	# save prefix values
	$self->[0]{'prefix'} = [$a, $b];

}

# write ZXML tag to ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _writeICCZXML {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# write tag
	print $fh pack('a4 N2 a*', 'ZXML', @{$self->[0]{'prefix'}}, $self->[1]);

}

1;