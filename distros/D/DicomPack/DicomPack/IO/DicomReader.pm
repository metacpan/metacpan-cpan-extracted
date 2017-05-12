##############################################################################
# DicomReader.pm -- a module to read Dicom files
#
# Copyright (c) 2010 Baoshe Zhang. All rights reserved.
# This file is part of "DicomPack". DicomReader is free software. You can 
# redistribute it and/or modify it under the same terms as Perl itself.
##############################################################################

package DicomPack::IO::DicomReader;

use strict;
use warnings;

use DicomPack::DB::DicomVRDict qw/getVR/;
use DicomPack::IO::CommonUtil qw/_getDicomValue _isLittleEndian _showDicomField _parseDicomFieldPath/;

our $VERSION = '0.95';

#instantiate DicomReader
sub new
{
	my $classname = shift;
	my $infile = shift;
	my $options = shift;

	my $self = {Options=>$options};

	if(_parseDicomFile($self, $infile))
	{
		bless $self, $classname;
		return $self;
	}
	return undef;
}

# parse a dicom file and load all dicom data into a structure
sub _parseDicomFile
{
	my $self = shift;
	my $infile = shift;

	open INDICOM, "<$infile" or die $!;
	binmode INDICOM, q{:raw};

	my $filesize = -s $infile;

	my $dicomFileContent;

	my $nret = read(INDICOM, $dicomFileContent, $filesize);
	if($nret != $filesize)
	{
		print "Error: read file: $infile\n";
		exit;		
	}
	close INDICOM;

	my $startPos = 0;
	if(substr($dicomFileContent, 128, 4) eq 'DICM')
	{
		$startPos = 128 + 4;
	}

	my $isImplicitVR = $self->{Options}->{ImplicitVR};

	my $byteCount;
	($byteCount, $self->{DicomField}) = _processDicomStr(\$dicomFileContent, $startPos, $filesize-$startPos, 1, $isImplicitVR, 0);

	unless(defined $self->{DicomField}) # invalid dicom file
	{
		print "$infile may not be a valid dicom file!!!\n";
		return undef;
	}
}

# parse a dicom string and return a structure containing all dicom data
sub parseDicomString
{
	my $self = shift;
	my $dicomStr = shift;

	my $isLittleEndian = $self->isLittleEndian();
	my $isImplicitVR = $self->isImplicitVR();

	my ($byteCount, $fields) = _processDicomStr(\$dicomStr, 0, 
					length($dicomStr), $isLittleEndian, $isImplicitVR, 0);

	return $fields;
}

# check the endianness of a dicom file according to "0002,0010" of meta info
sub isLittleEndian
{
	my $self = shift;
	my $dicomFields = $self->{DicomField};

	return _isLittleEndian($dicomFields);
}

# check implicit/explicit VR of a dicom file according to "0002,0010" of meta info
sub isImplicitVR
{
	my $self = shift;
	my $dicomFields = $self->{DicomField};
	my $isImplicitVR = undef;
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
			else
			{
				$isImplicitVR = 0;
			}
		}
	}
	return $isImplicitVR;
}

# parse a dicom tag header
sub _processDicomTag
{
	my $dicomTagStr = shift;
	my $isLittleEndian = shift;
	my $isImplicitVR = shift;
	my ($group, $element, $len, $vr, $tagLen);

	my $isMetaInfo;

	my $t_data;

	$t_data = substr($dicomTagStr, 0, 2);
	($group) = unpack("v", $t_data);

	if($group == 0x0002)
	{
		$isMetaInfo = 1;
	}
	else
	{
		$isMetaInfo = 0;
	}

	$t_data = substr($dicomTagStr, 0, 8);
	if($isLittleEndian or $isMetaInfo)
	{
		($group, $element, $vr, $len) = unpack("v v A2 v", $t_data);
	}
	else
	{
		($group, $element, $vr, $len) = unpack("n n A2 n", $t_data);	
	}

	my $tagID = sprintf "%04x,%04x", $group, $element;

	unless(defined $isImplicitVR)
	{
		if($vr =~ m/^(AE|AS|AT|CS|DA|DS|DT|FL|FD|IS|LO|LT|PN|SH|SL|SS|ST|TM|UI|UL|US|OB|OW|OF|SQ|UT|UN)$/)
		{
			$isImplicitVR = 0;
		}
		else
		{
			$isImplicitVR = 1;
		}
	}

	if($isImplicitVR and !$isMetaInfo)  # implicit VR
	{
		$tagLen = 8;
		$vr = "XX";
		$t_data = substr($dicomTagStr, 4, 4);
		if($isLittleEndian or $isMetaInfo)
		{
			$len = unpack("V", $t_data);
		}
		else
		{
			$len = unpack("N", $t_data);
		}
		return ($tagID, $tagLen, $vr, $len);
	}

	# explicit VR
	if($vr =~ m/^(AE|AS|AT|CS|DA|DS|DT|FL|FD|IS|LO|LT|PN|SH|SL|SS|ST|TM|UI|UL|US)$/) 
	{ 
		$tagLen = 8;
	}
	else
	{
		if($vr =~ m/^(OB|OW|OF|SQ|UT|UN)$/)
		{
			$tagLen = 12;
			$t_data = substr($dicomTagStr, 8, 4);
			if($isLittleEndian or $isMetaInfo)
			{
				$len = unpack("V", $t_data);
			}
			else
			{
				$len = unpack("N", $t_data);
			}
		}
		else
		{
			$tagLen = 8;
			$vr = "XX";

			if($tagID ne "fffe,e000" and $tagID ne "fffe,e00d" and $tagID ne "fffe,e0dd") # no-substructure
			{
				return ($tagID, $tagLen, $vr, -1);
			}

			$t_data = substr($dicomTagStr, 4, 4);
			if($isLittleEndian or $isMetaInfo)
			{
				$len = unpack("V", $t_data);
			}
			else
			{
				$len = unpack("N", $t_data);
			}
		}
	}

	return ($tagID, $tagLen, $vr, $len);
}

# process dicom fields from DICOM data string (recursive)
sub _processDicomStr
{
	my $pDicomStr = shift;
	my $startPos = shift;
	my $strLen = shift;
	my $isLittleEndian = shift;
	my $isImplicitVR = shift;
	my $depth = shift;
	my $vrParent = shift;
	my $byteCount = 0;
	my $dicomFields;

	while(1)
	{
		if($byteCount < 0 or $startPos+$byteCount+8 > length($$pDicomStr))
		{
			return (-1, undef);
		}

		my ($tagID, $tagLen, $vr, $len) = _processDicomTag(substr($$pDicomStr, $startPos+$byteCount, 12), 
									$isLittleEndian, $isImplicitVR);
		if($len == -1) # for explicit VR, tagID not SQ item 
		{
			return (-1, undef);
		}

		$byteCount += $tagLen;

		if($tagID eq "fffe,e00d" or $tagID eq "fffe,e0dd")
		{
			last;
		}

		# process SQ structure
		if($len == 0xffffffff or ($vr eq "SQ" and $len != 0))
		{
			if($len == 0xffffffff) # set the length of value to 0
			{
				$len = -1;
			}

			if($tagID eq "fffe,e000") # SQ item
			{
				my ($nRet, $fRet) = _processDicomStr($pDicomStr, 
							$startPos+$byteCount, $len, $isLittleEndian, $isImplicitVR, $depth+1, $vr);
				push @$dicomFields, $fRet;

				$byteCount += $nRet;
			}
			else
			{
				my ($nRet, $fRet) = _processDicomStr($pDicomStr, 
							$startPos+$byteCount, $len, $isLittleEndian, $isImplicitVR, $depth+1, $vr);
				$dicomFields->{$tagID} = $fRet;
				$byteCount += $nRet;
			}
		}
		else
		{
			if($startPos+$byteCount+$len > length($$pDicomStr)) # if no-structure, return;
			{
				return (-1, undef);
			}

			my $value = substr($$pDicomStr, $startPos+$byteCount, $len);
			$byteCount += $len;

			my $isStruct = 0;

			if(length($value) > 8 and $vr eq "XX") # when implicit-type value is long enough, assume that sub-structure may exist.
			{
				my ($nRet, $fRet) = _processDicomStr(\$value,
							0, length($value), $isLittleEndian, $isImplicitVR, $depth+1, $vr);
				if(defined $fRet) # return not (-1, undef)
				{
					if($tagID eq "fffe,e000") # SQ item
					{
						push @$dicomFields, $fRet;
					}
					else
					{
						if($tagID ne "fffc,fffc") # ignore dataset trailing padding
						{
							$dicomFields->{$tagID} = $fRet;
						}
					}
					$isStruct = 1;
				}
			}
			if($isStruct == 0) # no sub-structure
			{
				if($tagID eq "fffe,e000") # SQ item
				{
					if(defined $vrParent and $vrParent ne "SQ") # SQ item using 
					{
						push @$dicomFields, $vrParent.":".$value;
					}
					else
					{
						push @$dicomFields, $vr.":".$value;
					}
				}
				else  # return (-1, undef)
				{
					if($tagID ne "fffc,fffc") # ignore dataset trailing padding
					{
						$dicomFields->{$tagID} = $vr.":".$value;
					}
				}
			}

			if($tagID eq "0002,0010") # dicom endianness
			{
				my ($tt_t, $vv_t) = _getDicomValue($dicomFields->{"0002,0010"});
				my $transferSyntax = $vv_t->[0];
				if($transferSyntax eq "1.2.840.10008.1.2.2")
				{
					$isLittleEndian = 0;
				}
				if($transferSyntax eq "1.2.840.10008.1.2")
				{
					$isImplicitVR = 1;
				}
				else
				{
					$isImplicitVR = 0;
				}
			}
		}

		if($strLen >= 0 and $byteCount >= $strLen) # if byteCount>=strLen(not -1), exit loop
		{
			if($byteCount != $strLen) # if byteCount != strLen, no sub-structure
			{
				$byteCount = -1;
				$dicomFields = undef;
			}
			last;
		}
	}

	return ($byteCount, $dicomFields);
}

# get a value of a dicom field
sub getValue
{
	my $self = shift;
	my $fieldPath = shift;
	my $mode = shift;
	
	$mode = "" unless defined $mode;

	my @fieldID = _parseDicomFieldPath($fieldPath);

	my $dicomFields = $self->{DicomField};

	my $nFields = scalar @fieldID;
	for(my $i=0; $i<$nFields; $i++)
	{
		my $tagID = $fieldID[$i];

		if($tagID =~ /^\d+$/)
		{
			$dicomFields = $dicomFields->[$tagID];
		}
		else
		{
			if(ref($dicomFields) eq "HASH")
			{
				if(defined $dicomFields->{$tagID})
				{
					$dicomFields = $dicomFields->{$tagID};
				}
				else
				{
					print "Dicom field: $fieldPath, does not exist!!!\n";
					return undef;
				}
			}
		}

		unless(ref($dicomFields))
		{
			if($i == $nFields-1)
			{
				if($mode eq "native")
				{
					return $dicomFields;
				}
				else
				{
					my $isLittleEndian = $self->isLittleEndian();
					my ($vr, $value) = _getDicomValue($dicomFields, $isLittleEndian);

					if(scalar @$value == 1)
					{
						return $value->[0];
					}
					else
					{
						return ($value, $vr);
					}
				}
			}
			else
			{
				print "Dicom field: $fieldPath, does not exist!!!\n";
				return undef;
			} 
		}
	}
	return $dicomFields;
}

# get a pointer to the structure containing all dicom data
sub getDicomField
{
	my $self = shift;
	return $self->{DicomField};
}

# show the field data and structure of the current dicom file on STDIN
sub showDicomField
{
	my $self = shift;
	my $verbose = shift;
	my $dicomFields = shift;

	$verbose = 0 unless defined $verbose;

	unless(defined $dicomFields)
	{
		$dicomFields = $self->{DicomField};
	}
	_showDicomField($dicomFields, 0, $verbose, $self->isLittleEndian());
}

1;

__END__

=head1 NAME

DicomReader - A module to read Dicom Files

=head1 SYNOPSIS

    use DicomPack::IO::DicomReader;
    my $dicomFile = "your dicom file";

    # get a DicomReader object
    my $reader = DicomPack::IO::DicomReader->new($dicomFile);

    # show the content of the Dicom file to std.
    $reader->showDicomField(2);

    # get patient name
    my $patientName = $reader->getValue("PatientName");

    # get the value of a complex structure. Return value is a sub Dicom field.
    my $aDicomField = $reader->getValue("300a,0230/0/300a,0280/2/1001,01ff");

    # show the above dicom structure to std.
    $reader->showDicomField(2, $aDicomField);

    # get the root Dicom field structure.
    my $rootDicomField = $reader->getDicomField();


=head1 DESCRIPTION

This module reads a Dicom file.

=head2 Methods

=over 12

=item C<new>

Returns a new DicomReader object.

=over 4

=item Input Parameter:

=over 4

=item 1.

A path to a dicom file.

=back

=back

=item C<getValue>

Get the value of a specified dicom field.

=over 4

=item Input Parameters:

=over 4

=item 1.

Dicom tag path. Format: "TagID or TagName/SequenceNumber/TagID or TagName/SequenceNumber",
e.g.,"300a,0230/0/300a,0280/2/1001,01ff/0/MaterialID".

=item 2.

mode (optional). When mode is 'native', the return value is in the native binary format 
prefixed 'vr:' (where vr is the VR value, e.g., 'UI').

=back

=item Return Value:

The value of the specified dicom field or a hash ref or an array ref.

=back

=item C<getDicomField>

Get a hash ref pointing to the root structure of the dicom fields.

=over 4

=item Return Value:

A hash ref pointing to the root structure of the dicom fields.

=back

=item C<showDicomField>

Display the structure of a dicom field structure.

=over 4

=item Input Parameter(s):

=over 4

=item 1.

Verbose level. Available values: 0, 1, 2. Default value: 0.

=item 2.

A dicom field structure (optional). If no dicom field structure is
specified, use the root dicom field structure.

=back

=back

=item C<parseDicomString>

Parse a string containing a Dicom binary field. The whole content of a Dicom file can be used as 
an input string. 

=over 4

=item Input Parameter(s):

=over 4

=item 1.

A string containing a dicom field.

=back

=item Return Value:

A Dicom field structure.

=back

=item C<isLittleEndian>

Check the endianness of the current Dicom field structure.

=over 4

=item Return Value:

When true, little endianness; otherwise, big endianness.

=back

=item C<isImplicitVR>

Check if the current Dicom field structure is implicitly VRed.

=over 4

=item Return Value:

When true, implicit VR; otherwise, explicit VR.

=back

=back


=head1 AUTHOR

Baoshe Zhang, MCV Medical School, Virginia Commonwealth University

=cut

