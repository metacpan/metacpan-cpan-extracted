##############################################################################
# CommonUtil.pm -- a module including common functions for internal use
#
# Copyright (c) 2010 Baoshe Zhang. All rights reserved.
# This file is part of "DicomPack". DicomPack is free software;
# you can redistribute it and/or modify it under the same
# terms as Perl itself.
##############################################################################

package DicomPack::IO::CommonUtil;

use strict;
use warnings;

use DicomPack::DB::DicomTagDict qw/getTagDesc getTagID/;
use DicomPack::DB::DicomVRDict qw/getVR/;

use vars qw(@ISA @EXPORT_OK);
use Exporter;
@ISA = qw/Exporter/;
@EXPORT_OK = qw/_getEndian _pack _unpack _isLittleEndian _toString _getDicomValue _showDicomField _parseDicomFieldPath/;

# get the endianness of current system. ">" for big endiannes, "<" for little endianness.
sub _getEndian
{
	return ">" if pack("L", 1) eq pack("N", 1);
	return "<";
}

# a repalcement for pack function. The versions of perl prior to 5.10.0 do not support ">" and "<".
sub _pack  
{
	my ($dataType, $endianness, $data) = @_;

	if(eval("require 5.0100") or $endianness eq "")
	{
		return pack($dataType.$endianness."*", @$data);
	}

	if($dataType !~ /^[sSiIlLqQjJfFdDpP]$/)
	{
		die "DataType: $dataType, not supporte!!!\n";
	}

	if(ref($data) ne "ARRAY")
	{
		die "Data should be an ARRAY Ref!!!\n";	
	}

	if(_getEndian() eq $endianness) 
	{
		return pack($dataType."*", @$data);
	}
	else
	{
		my $data_t = "";
		foreach my $iData (@$data)
		{
			my $iData_t = pack "C*", reverse unpack("C*", pack($dataType, $iData));
			$data_t .= $iData_t;
		}
		return $data_t;
	}
}

# A replacement for unpack. The versions of perl prior to 5.10.0 do not support ">" and "<".
sub _unpack
{
        my ($dataType, $endianness, $data) = @_;

        if(eval("require 5.0100") or $endianness eq "")
        {
                return unpack($dataType.$endianness."*", $data);
        }

        if($dataType !~ /^[sSiIlLqQjJfFdDpP]$/)
        {
                die "DataType: $dataType, not supporte!!!\n";
        }

        if(_getEndian() eq $endianness)
        {
                return unpack($dataType."*", $data);
        }
        else # little endianness
        {
                my @data_t;
                foreach my $iData (unpack($dataType."*", $data))
                {
                        my $iData_t = unpack($dataType, pack("C*", reverse unpack("C*", pack($dataType, $iData))));
			push @data_t, $iData_t;
                }
                return @data_t;
        }
}

# check the endianness of a dicom file according to "0002,0010" of meta info
sub _isLittleEndian
{
        my $dicomFields = shift;
        my $isLittleEndian = 1;
        if(defined $dicomFields)
        {
                if(defined $dicomFields->{"0002,0010"})
                {
                        my ($tt_t, $vv_t) = _getDicomValue($dicomFields->{"0002,0010"});
                        my $transferSyntax = $vv_t->[0];
                        if($transferSyntax eq "1.2.840.10008.1.2.2")
                        {
                                $isLittleEndian = 0;
                        }
                }
        }
        return $isLittleEndian;
}

# convert a composite dicom value to a string
sub _toString
{
	my $dicomValue = shift;
	my $isLittleEndian = shift;
	my $verbose = shift;
	my $indent = shift;

	my ($vr, $value) = _getDicomValue($dicomValue, $isLittleEndian);

	my $valueStr = "";

	if($verbose <= 1)
	{
		my $nPrint = scalar @$value;
		if($nPrint > 15)
		{
			$nPrint = 15;
		}
		for(my $i=0; $i<$nPrint; $i++)
		{
			my $t = $value->[$i];
			$valueStr .= $t.' ';
		}
		if($nPrint < scalar @$value)
		{
			$valueStr .= "...\n";
		}

		if(length($valueStr) > 255)
		{
			$valueStr = substr($valueStr, 0, 255);
			$valueStr .= "...\n";
		}
	}
	else
	{
		for(my $i=0; $i<scalar @$value; $i++)
		{
			my $t = $value->[$i];
			$valueStr .= $t.' ';
			if(($i+1)%16 == 0)
			{
				$valueStr .= "\n"."  ".$indent;
			}
		}
	}

	return $vr.":".$valueStr;
}

# process a composite dicom value
sub _getDicomValue
{
	my $dicomValue = shift;
	my $isLittleEndian = shift;

	my $vr = substr($dicomValue, 0, 2);
	my $value = substr($dicomValue, 3);

	my @t_data;

        my $vrItem = getVR($vr);
        if(defined $vrItem->{tailing})
        {
             $value =~ s/($vrItem->{tailing})+$//; 
        }
        if(defined $vrItem->{leading})
        {
             $value =~ s/^($vrItem->{leading})+//;
        }

	if(defined $vrItem->{type})
	{
		my $endianness = "<";
		$endianness = ">" unless $isLittleEndian;
		if($vrItem->{type} eq "C" or $vrItem->{type} eq "c")
		{
			$endianness = "";
		}
		#@t_data = unpack($vrItem->{type}.$endianness."*", $value);
		@t_data = _unpack($vrItem->{type}, $endianness, $value);
	}
	elsif (defined $vrItem->{delimiter})
	{
		@t_data = split quotemeta($vrItem->{delimiter}), $value;
	}
	else
	{
		@t_data = $value;
	}

	return ($vr, \@t_data);
}

# show dicom file's structure and field data (recursive)
sub _showDicomField
{
	my $dicomFields = shift;
	my $depth = shift;
	my $verbose = shift;

	my $isLittleEndian = shift;

	my $tagID = shift;

	my $indent = " " x (4*$depth);

	if(ref($dicomFields) eq "HASH")
	{
		foreach my $field_t (sort keys %$dicomFields)
		{
			my $desc = getTagDesc($field_t);
			print $indent."$field_t"." [".$desc."]"."->\n";
			_showDicomField($dicomFields->{$field_t}, $depth+1, $verbose, $isLittleEndian, $field_t);
		}
	}
	elsif(ref($dicomFields) eq "ARRAY")
	{
		for(my $index=0; $index < scalar @$dicomFields; $index++)
		{
			print $indent."$index->\n";
			_showDicomField($dicomFields->[$index], $depth+1, $verbose, $isLittleEndian);
		}
	}
	else
	{
		if($verbose >= 1)
		{
			if(defined $tagID and $tagID =~ /^0002,/)
			{
				print $indent._toString($dicomFields, 1, $verbose, $indent), "\n";
			}
			else
			{
				print $indent._toString($dicomFields, $isLittleEndian, $verbose, $indent), "\n";
			}
		}
	}
}

sub _parseDicomFieldPath
{
	my $fieldPath = shift;

        $fieldPath =~ s/^\s*\/*//;
        $fieldPath =~ s/\/*\s*$//;
        my @fieldID = split /\//, $fieldPath;

	my @tagIDList;

        my $nFields = scalar @fieldID;
        for(my $i=0; $i<$nFields; $i++)
        {
                my $tagID = $fieldID[$i];

                $tagID = getTagID($tagID) if ($tagID !~ /^\d+$/ and $tagID ne "x");

                die "Tag: $fieldID[$i], not exists!!!" unless defined $tagID;

		push @tagIDList, $tagID;
	}
	return @tagIDList;
}

1;

