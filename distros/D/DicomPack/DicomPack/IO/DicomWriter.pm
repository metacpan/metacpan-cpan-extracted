##############################################################################
# DicomWriter.pm -- a module to create a Dicom file
#
# Copyright (c) 2010 Baoshe Zhang. All rights reserved.
# This file is part of "DicomPack". DicomReader is free software. You can 
# redistribute it and/or modify it under the same terms as Perl itself.
##############################################################################

package DicomPack::IO::DicomWriter;

use strict;
use warnings;
use DicomPack::DB::DicomTagDict qw/getTag/;
use DicomPack::DB::DicomVRDict qw/getVR/;
use DicomPack::IO::CommonUtil qw/_isLittleEndian _parseDicomFieldPath _pack _showDicomField _getDicomValue/;

our $VERSION = '0.95';

# instantiate DicomWriter
sub new
{
	my $classname = shift;
	my $dicomFields = shift;

	unless(defined $dicomFields)
	{
		$dicomFields = {};
	}

	my $self;

	$self->{DicomField} = $dicomFields;
	$self->{IsLittleEndian} = _isLittleEndian($self->{DicomField});
	$self->{IsImplicitVR} = _isImplicitVR($self->{DicomField});

	bless $self, $classname;

	return $self;
}

# flush the current dicom field to a dicom file.
sub flush
{
	my $self = shift;
	my $outfile = shift;

	my $dicomFields = $self->{DicomField};

	my $isLittleEndian = $self->{IsLittleEndian};
	my $isImplicitVR = $self->{IsImplicitVR};

	_setGroupLength($dicomFields, $isLittleEndian, "0002");
	my $dicomStr = _processDicomField($dicomFields, undef, $isLittleEndian, $isImplicitVR);

	open OUTDICOM, ">$outfile" or die $!;
	_createDICOMheader(\*OUTDICOM);
	print OUTDICOM $dicomStr;
	close OUTDICOM;
}

# create dicom file preamble.
sub _createDICOMheader
{
	my $outdicom = shift;
	print $outdicom pack('.', 128), "DICM";
}

# calculate group length and set (gggg,0000).
sub _setGroupLength
{
	my $dicomField = shift;
	my $isLittleEndian = shift;
	my $group = shift;
	

	if(ref($dicomField) eq "HASH")
	{
		my $groupLen = 0;

		foreach my $field_t (sort keys %$dicomField)
		{
			if($field_t =~ /^$group,/)
			{
				next if($field_t eq "$group,0000");

				if((ref($dicomField->{$field_t}) eq "ARRAY") or   # if sub-structure exists, exit;
				   (ref($dicomField->{$field_t}) eq "HASH")) 
				{
					if(defined $dicomField->{$group.",0000"})
					{
						delete $dicomField->{$group.",0000"};
					}
					return -1;
				}
				else
				{
					my $vr = substr($dicomField->{$field_t}, 0, 2);
					my $value = substr($dicomField->{$field_t}, 3);
					my $len = length($value);
					if($vr =~ /^(OB|OW|OF|SQ|UT|UN)$/)
					{
						$len += 12;
					}
					else
					{
						$len += 8;
					}
					$groupLen += $len;
				}
			}
		}
		if($groupLen > 0)
		{
			if($isLittleEndian or $group eq "0002")
			{
				$dicomField->{$group.",0000"} = "UL:".pack("V", $groupLen);
			}
			else
			{
				$dicomField->{$group.",0000"} = "UL:".pack("N", $groupLen);
			}
		}
	}
	else
	{
		die "Invalid dicom fields!!!";
	}

}

# construct a dicom value
sub _setDicomValue
{
	my $vr = shift;
	my $valueList = shift;
	my $isLittleEndian = shift;

	my $value = "";
	my $vrItem = getVR($vr); # if VR is not valid or not "XX", die
	if(defined $vrItem->{type})
	{
		my $endianness = "<";
		$endianness = ">" unless $isLittleEndian;

		if($vrItem->{type} eq "C" or $vrItem->{type} eq "c")
		{
			$endianness = "";
		}
		#$value = pack($vrItem->{type}.$endianness."*", @$valueList);
		$value = _pack($vrItem->{type}, $endianness, $valueList);

		if(length($value) % 2 != 0)
		{
			$value .= $vrItem->{tailing};
		}
		$value = $vr.":".$value;
	}
	elsif(defined $vrItem->{delimiter})
	{
		$value = join("\\", @$valueList);
		if(length($value) % 2 != 0)
		{
			$value .= $vrItem->{tailing};
		}
		$value = $vr.":".$value;
	}
	else
	{
		if(scalar @$valueList > 1)
		{
			die $vr." is not multi-valued!!!\n";
		}
		if(defined $valueList->[0])
		{
			$value = $valueList->[0];
			if(length($value) % 2 != 0)
			{
				if(defined $vrItem->{tailing})
				{
					$value .= $vrItem->{tailing};
				}
				else
				{
					die "Length of value must be even number!!!\n";
				}
			}
			$value = $vr.":".$value;
		}
		else
		{
			$value = $vr.":";
		}
	}
	return $value;
}

# set a value of a dicom field
sub setValue
{
	my $self = shift;
	my $fieldPath = shift;
	my $valueList = shift;
	my $vr = shift;

	if(!ref($valueList)) # convert scalar to an array
	{
		$valueList = [$valueList];
	}

	$vr = "XX" unless defined $vr;

	my $isLittleEndian = $self->{IsLittleEndian};
	my $isImplicitVR = $self->{IsImplicitVR};

	my @fieldID = _parseDicomFieldPath($fieldPath);

	if($fieldID[0] eq "0002,0010") # change implicit VR or endianness
	{
		($self->{IsLittleEndian}, $self->{IsImplicitVR}) = 
				_checkTransferSyntax($valueList->[0], $self->{DicomField}, $isLittleEndian);
	}

	if($fieldID[0] =~ /^0002,/ or ! $self->{IsImplicitVR})
	{
		if($vr eq "XX")
		{
			$vr = [keys %{getTag($fieldID[-1])->{vr}}]->[0];
			print "VR is not specified explicitly for ".$fieldPath.". $vr is used.\n";
		}
	}

	my $nFields = scalar @fieldID;

	my $value;
	if($fieldID[0] =~ /^0002,/)
	{
		$value = _setDicomValue($vr, $valueList, 1);
	}
	else
	{
		$value = _setDicomValue($vr, $valueList, $isLittleEndian);
	}

	my $tagList;
	for(my $i=0; $i<$nFields; $i++)
	{
		my $tagID = lc($fieldID[$i]);
		if($tagID =~ /^\d+$/)
		{
			$tagList->[$i] = [$tagID, "ARRAY", 0];
		}
		elsif($tagID eq "x")
		{
			$tagList->[$i] = [$tagID, "ARRAY", 1];
		}
		elsif($tagID =~ /([0-9a-fA-F]{4}),([0-9a-fA-F]{4})/)
		{
			$tagList->[$i] = [$tagID, "HASH", 1];
		}
		else
		{
			die "tagID: $tagID, is not supported yet!!!\n";
		}
	}
	for(my $i=0; $i<$nFields; $i++)
	{
		if($i == $nFields-1)
		{
			$tagList->[$i]->[3] = "SCALAR";
		}
		else
		{
			$tagList->[$i]->[3] = $tagList->[$i+1]->[1];
		}
	}

	my $dicomField = $self->{DicomField};

	for(my $i=0; $i<$nFields; $i++)
	{
		my $tagID = $tagList->[$i]->[0];
		my $tagType = $tagList->[$i]->[1];
		my $valueType = $tagList->[$i]->[3];

		if($tagType eq "ARRAY")
		{
			my $addFlag = $tagList->[$i]->[2];

			if($valueType eq "SCALAR") # finish 
			{
				if($addFlag == 1)
				{
					$dicomField = [] unless defined $dicomField;
					push @$dicomField, $value;
				}
				else
				{
					if(defined $dicomField->[$tagID])
					{
						$dicomField->[$tagID] = $value;
					}
					else
					{
						print "The item to be modified is non-existent!!!\n";
						return;
					}
				}
				return;
			}
			else
			{
				if($addFlag == 1)  # add a new array item
				{
					$dicomField = [] unless defined $dicomField;
					if($valueType eq "HASH")
					{
						push @$dicomField, {};
					}
					elsif($valueType eq "ARRAY")
					{
						push @$dicomField, [];
					}
					$dicomField = $dicomField->[scalar @$dicomField - 1];
				}
				else  # modify an existing array item
				{
					if(defined $dicomField->[$tagID])
					{
						$dicomField = $dicomField->[$tagID];
					}
					else
					{
						print "The item to be modified is non-existent!!!\n";
						return;
					}
				}
			}
		}
		elsif($tagType eq "HASH")
		{
			if($valueType eq "SCALAR") # finish 
			{
				$dicomField->{$tagID} = $value;

				return;
			}

			unless(defined $dicomField->{$tagID})
			{
				if($valueType eq "HASH")
				{
					$dicomField->{$tagID} = {};
				}
				elsif($valueType eq "ARRAY")
				{
					$dicomField->{$tagID} = [];
				}
			}

			$dicomField = $dicomField->{$tagID};
		}
	}
	print "dicom field does not exist!!!\n";
	return undef;
}

# construct a binary dicom tag header
sub _constructDicomTag
{
	my ($group, $element, $vr, $len, $isLittleEndian, $isImplicitVR) = @_;

	my $isMetaInfo;

	my $tagHeader = "";

	if($group eq "0002")
	{
		$isMetaInfo = 1;
	}
	else
	{
		$isMetaInfo = 0;
	}

	if($isImplicitVR and $isMetaInfo==0)
	{
		if($isLittleEndian)
		{
			$tagHeader = pack("v v V", hex($group), hex($element), $len);
		}
		else
		{
			$tagHeader = pack("n n N", hex($group), hex($element), $len);
		}
		return $tagHeader;
	}
	
	if($vr =~ m/^(OB|OW|OF|SQ|UT|UN)$/)
	{
		if($isLittleEndian or $isMetaInfo)
		{
			$tagHeader = pack("v v A2 v V", hex($group), hex($element), $vr, 0, $len);
		}
		else
		{
			$tagHeader = pack("n n A2 n N", hex($group), hex($element), $vr, 0, $len);
		}
			
	}
	elsif($vr =~ m/^(AE|AS|AT|CS|DA|DS|DT|FL|FD|IS|LO|LT|PN|SH|SL|SS|ST|TM|UI|UL|US)$/)
	{
		if($isLittleEndian or $isMetaInfo)
		{
			$tagHeader = pack("v v A2 v", hex($group), hex($element), $vr, $len);
		}
		else
		{
			$tagHeader = pack("n n A2 n", hex($group), hex($element), $vr, $len);
		}
	}
	else
	{
		if($isLittleEndian or $isMetaInfo)
		{
			$tagHeader = pack("v v V", hex($group), hex($element), $len);
		}
		else
		{
			$tagHeader = pack("n n N", hex($group), hex($element), $len);
		}
	}
	return $tagHeader;
}

# get a binary string from dicom fields(recursive)
sub _processDicomField
{
	my $dicomField = shift;
	my $dicomTag = shift;
	my $isLittleEndian = shift;
	my $isImplicitVR = shift;

	my $fieldType = ref($dicomField);
	
	my $isMetaInfo = 1;

	my $dicomStr = "";

	if($fieldType eq "HASH")
	{
		foreach my $field_t (sort keys %$dicomField)
		{
			$dicomStr .= _processDicomField($dicomField->{$field_t}, $field_t, $isLittleEndian, $isImplicitVR);
		}
	}
	elsif($fieldType eq "ARRAY") # SQ
	{
		my ($group, $element) = $dicomTag =~ /([0-9a-fA-F]{4}),([0-9a-fA-F]{4})/;
		if(!defined $group or !defined $element)
		{
			die "Dicom Tag: $dicomTag, not valid!!!";
		}

		my $sqStr = "";
		for(my $index=0; $index < scalar @$dicomField; $index++)
		{
			my $sqItemStr = _processDicomField($dicomField->[$index], undef, $isLittleEndian, $isImplicitVR);

			my $sqItemStartTag = _constructDicomTag("fffe", "e000", "XX", length($sqItemStr), $isLittleEndian, $isImplicitVR);
			my $sqItemEndTag = _constructDicomTag("fffe", "e00d", "XX", 0x0, $isLittleEndian, $isImplicitVR);
	

			$sqStr .= $sqItemStartTag;
			$sqStr .= $sqItemStr;
			#$dicomStr .= $sqItemEndTag;
		}

		my $sqVR = "SQ";
		for(my $index=0; $index < scalar @$dicomField; $index++) # for value array's VR
		{
			if(ref($dicomField->[$index])) # no sub-structure
			{
				$sqVR = "SQ";
				last;
			}
			if($index == 0)
			{
				$sqVR = substr($dicomField->[$index], 0, 2);
				if($sqVR ne "OB" and         # no other support value array
					$sqVR ne "OW" and 
					$sqVR ne "OF" and 
					$sqVR ne "UT" and 
					$sqVR ne "UN")
				{
					$sqVR = "SQ";
					last;
				}
			}
			if($sqVR ne substr($dicomField->[$index], 0, 2)) # same VR
			{
				$sqVR = "SQ";
				last;
			}
		}
		my $sqStartTag = _constructDicomTag($group, $element, $sqVR, 0xffffffff, $isLittleEndian, $isImplicitVR);
		my $sqEndTag = _constructDicomTag("fffe", "e0dd", "XX", 0x0, $isLittleEndian, $isImplicitVR);
		$dicomStr .= $sqStartTag;
		$dicomStr .= $sqStr;
		$dicomStr .= $sqEndTag;
	}
	else
	{
		if(defined $dicomTag)
		{
			my ($group, $element) = $dicomTag =~ /([0-9a-fA-F]{4}),([0-9a-fA-F]{4})/;

			if(!defined $group or !defined $element)
			{
				die "Dicom Tag: $dicomTag, not valid!!!";
			}

			if($element eq "0000" and ($group ne "0000" and 
						   $group ne "0002" and 
						   $group ne "0004" and 
						   $group ne "0006")) # ignore group length
			{
				return $dicomStr;
			}

			my $vr = substr($dicomField, 0, 2);
			my $value = substr($dicomField, 3);
			my $len = length($value);
	
			if($len % 2 != 0)
			{
				my $vrItem = getVR($vr);
				if(defined $vrItem->{tailing})
				{
					$value = $value.$vrItem->{tailing};
					$len = length($value);
				}
				else
				{
					die "the length of a dicom field must be even: $dicomTag.\n";
				}
			}
			my $tagHeader = _constructDicomTag($group, $element, $vr, $len, $isLittleEndian, $isImplicitVR);
			$dicomStr .= $tagHeader.$value;
		}
		else
		{
			my $vr = substr($dicomField, 0, 2);
			my $value = substr($dicomField, 3);
			my $len = length($value);

			if($len % 2 != 0)
			{
				my $vrItem = getVR($vr);
				if(defined $vrItem->{tailing})
				{
					$value = $value.$vrItem->{tailing};
				}
				else
				{
					die "the length of a dicom field must be even: $dicomTag.\n";
				}
			}
			$dicomStr .= $value;
		}
	}
	return $dicomStr;
}


#################################

# show the field data and structure of the current dicom file on STDIN
sub showDicomField
{
	my $self = shift;
	my $verbose = shift;
	$verbose = 0 unless defined $verbose;
	my $dicomFields = shift;
	unless(defined $dicomFields)
	{
		$dicomFields = $self->{DicomField};
	}
	_showDicomField($dicomFields, 0, $verbose, $self->{IsLittleEndian});
}

# check if implicit VR is used according to "0002,0010" of meta info
sub _isImplicitVR
{
	my $dicomFields = shift;
	my $isImplicitVR = 0;
	if(defined $dicomFields)
	{
		if(defined $dicomFields->{"0002,0010"})
		{
			my ($tt_t, $vv_t) = _getDicomValue($dicomFields->{"0002,0010"});
			my $transferSyntax = $vv_t->[0];
			if($transferSyntax eq "1.2.840.10008.1.2")
			{
				$isImplicitVR = 1;
			}
		}
	}
	return $isImplicitVR;
}

# check if adjustments to new transfer syntax are needed
sub _checkTransferSyntax
{
	my $transferSyntax = shift;
	my $dicomFields = shift;
	my $oldEndian = shift;

	my $isImplicitVR = $transferSyntax eq "1.2.840.10008.1.2";

	unless($isImplicitVR)
	{
		if(_checkExplicitVR($dicomFields) == -1)
		{
			die "Cannot set VR to be explicit because some existing dicom fields are implicit!!!";
		}
	}

	my $newEndian;
	if($transferSyntax eq "1.2.840.10008.1.2.2")
	{
		$newEndian = 0;
	}
	else
	{
		$newEndian = 1;
	}

	if($newEndian != $oldEndian)
	{
		_changeEndianness($dicomFields, $oldEndian, $newEndian);
	}
	
	return ($newEndian, $isImplicitVR);
}

# change dicom value to a different endianness
sub _changeEndianness
{
	my $dicomFields = shift;
	my $oldEndian = shift;
	my $newEndian = shift;
	my $tagPath = shift;

	$tagPath = "" unless defined $tagPath;

	if(ref($dicomFields) eq "HASH")
	{
		foreach my $field_t (sort keys %$dicomFields)
		{
			if(ref($dicomFields->{$field_t}))
			{
				_changeEndianVR($dicomFields->{$field_t}, $oldEndian, $newEndian, $tagPath."/".$field_t);
			}
			else
			{
				if(substr($field_t, 0, 5) ne "0002,")
				{
					my ($vr, $value) = _getDicomValue($dicomFields->{$field_t}, $oldEndian);
					$dicomFields->{$field_t} = _setDicomValue($vr, $value, $newEndian);
				}
			}
		}
	}
	elsif(ref($dicomFields) eq "ARRAY")
	{
		for(my $index=0; $index < scalar @$dicomFields; $index++)
		{
			if(ref($dicomFields->[$index]))
			{
				_changeEndianVR($dicomFields->[$index], $oldEndian, $newEndian, $tagPath."/".$index);
			}
			else
			{
				my ($vr, $value) = _getDicomValue($dicomFields->[$index], $oldEndian);
				$dicomFields->[$index] = _setDicomValue($vr, $value, $newEndian);
			}
		}
	}
}


# check if implicit or explicit
sub _checkExplicitVR
{
	my $dicomFields = shift;

	if(ref($dicomFields) eq "HASH")
	{
		foreach my $field_t (sort keys %$dicomFields)
		{
			if(substr($field_t, 0, 5) ne "0002,")
			{
				if(_checkExplicitVR($dicomFields->{$field_t}) == -1)
				{
					return -1;
				}
			}
		}
	}
	elsif(ref($dicomFields) eq "ARRAY")
	{
		for(my $index=0; $index < scalar @$dicomFields; $index++)
		{
			if(_checkExplicitVR($dicomFields->[$index]) == -1)
			{
				return -1;
			}
		}
	}
	else
	{
		my $vr = substr($dicomFields, 0, 2);

		if($vr eq "XX")
		{
			return -1;
		}
	}
	return 1;
}

1;

__END__

=head1 NAME

DicomWriter - A module to create a dicom file from dicom fields

=head1 SYNOPSIS

    use DicomPack::IO::DicomWriter;

    my $dicomFields = ...;  # dicomFields is the output of DicomReader->getDicomField().

    my $writer = DicomPack::IO::DicomWeader->new($dicomFields); # dicomFields can be undefined.

    # set PatientName to a new value
    $writer->setValue("PatientName", "DicomTest");

    # assign a value to "300a,0230/x/300b,100". 'x' used to add a new sequence item
    $writer->setValue("300a,0230/x/300b,100", "aValue");

    # use the current Dicom field structure to create a Dicom file.
    $writer->flush($dicomFile);

=head1 DESCRIPTION

This module creates a Dicom file.

=head2 Methods

=over 12

=item C<new>

Returns a new DicomWriter object.

=over 4

=item Input Parameter(s):

=over 4

=item 1.

A template Dicom field structure (optional). If there is a template Dicom file,
use DicomReader to read a template Dicom file and getDicomField() to get
the template Dicom field structure as the input of new().

=back

=back

=item C<setValue>

Set or change the value of a specified Dicom field, or create a dicom
field. If sequence number is 'x', add a new sequence item.

=over 4

=item Input parameter(s):

=over 4

=item 1. 

Dicom tag path. See the doc of getValue of DicomReader for details about format.

=item 2.

An array reference pointing to the values, or a scalar value.

=item 3.

The name of VR (optional). For explicit VR, if missing, default VR will be used.

=back

=back

=item C<flush>

Use the current Dicom field structure to create a new Dicom file.

=over 4

=item Input parameter(s):

=over 4

=item 1.

A path to an output dicom file.

=back

=back

=item C<showDicomField>

Display the structure of a dicom field structure.

=over 4

=item Input parameter(s):

=over 4

=item 1.

Verbose level. Available values: 0, 1, 2. By default, 0.

=item 2.

A dicom field structure (optional). If no dicom field structure is
specified, use the root dicom field structure.

=back

=back

=back

=head1 AUTHOR

Baoshe Zhang, MCV Medical School, Virginia Commonwealth University

=cut

