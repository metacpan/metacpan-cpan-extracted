##############################################################################
# DicomVRDict.pm -- a module including Dicom Data Structure and Endcoding
#
# Copyright (c) 2010 Baoshe Zhang. All rights reserved.
# This file is part of "DicomPack". DicomReader is free software. You can 
# redistribute it and/or modify it under the same terms as Perl itself.
##############################################################################

package DicomPack::DB::DicomVRDict;

use strict;
use warnings;

use vars qw(@ISA @EXPORT_OK);

use Exporter;
@ISA = qw/Exporter/;
@EXPORT_OK = qw/getVR/;

our $VERSION = '0.95';

my $DicomVRList = {
   "AE" => {
          desc    => "Application Entity",
          tailing => ' ',
          leading => ' ',
          maxlen  => 16,
          delimiter => "\\", 
        },
   "AS" => {
          desc    => "Age String",
          len     => 4,
          pattern => q/^\d{3}[D|W|M|Y]$/,
        },
   "AT" => {
          desc    => "Attribute Tag",
          type    => "S",
          len     => 4
        },
   "CS" => {
          desc    => "Code String",
          tailing => ' ',
          leading => ' ',
          maxlen  => 16,
          pattern => q/^[A-Z0-9\s\_]+$/,
          delimiter => "\\",
        },
   "DA" => {
          desc    => "Date",
          len     => 8,
          pattern => q/^\d{8}$/,  # '-' is allowed in query and trailing SPACE for padding
          delimiter => "\\",
        },
   "DS" => {
          desc    => "Decimal String",
          tailing => ' ',
          leading => ' ',
          maxlen  => 16,
          pattern => q/^[+-0-9Ee\.]+$/,
          delimiter => "\\",
        },
   "DT" => {
          desc    => "Date Time",
          tailing => ' ',
          maxlen  => 26,
          pattern => q/^[0-9+-\s\.]+$/,
          delimiter => "\\",
        },
   "FL" => {
          desc    => "Floating Point Single",
          len     => 4,
          type    => "f",
        },
   "FD" => {
          desc    => "Floating Point Double",
          len     => 8,
          type    => "d",
        },
   "IS" => {
          desc    => "Integer String",
          tailing => ' ',
          leading => ' ',
          maxlen  => 12,
          pattern => q/^[+-]?[0-9]+$/,
          delimiter => "\\",
        },
   "LO" => {
          desc    => "Long String",
          tailing => ' ',
          leading => ' ',
          maxlen  => 64,
          delimiter => "\\",
        },
   "LT" => {
          desc    => "Long Text",
          tailing => ' ',
          maxlen  => 10240
        },
   "OB" => {
          desc    => "Other Byte String",
          tailing => chr(0),
          type    => "C",
        },
   "OF" => {
          desc    => "Other Float String",
          type    => "f",
        },

   "OW" => {
          desc    => "Other Word String",
          type    => "S",
        },
   "PN" => {
          desc    => "Person Name",
          tailing => ' ',
          leading => ' ',
          delimiter => "\\",
        },
   "SH" => {
          desc    => "Short String",
          tailing => ' ',
          leading => ' ',
          maxlen  => 16,
          delimiter => "\\",
        },
   "SL" => {
          desc    => "Signed Long",
          len     => 4,
          type    => "l",
        },
   "SQ" => {
          desc    => "Sequences of Items",
        },
   "SS" => {
          desc    => "Signed Short",
          len     => 2,
          type    => "s",
        },
   "ST" => {
          desc    => "Short Text",
          tailing => ' ',
          maxlen  => 1024
        },
   "TM" => {
          desc    => "Time",
          tailing => ' ',
          maxlen  => 16,  # for Query, 28 bytes maximum
          pattern => q/^[0-9\.\s]$/,
          delimiter => "\\",
        },
   "UI" => {
          desc    => "Unique Identifier",
          tailing => chr(0),
          maxlen  => 64,
          pattern => q/^[0-9\.]+$/,
          delimiter => "\\",
        },
   "UL" => {
          desc    => "Unsigned Long",
          len     => 4,
          type    => "L",
        },
   "UN" => {
          desc    => "Unknown",
        },
   "US" => {
          desc    => "Unsigned Short",
          len     => 2,
          type    => "S",
        },
   "UT" => {
          desc    => "Unlimited Text",
          tailing => ' '
        },
   "XX" => {
          desc    => "Implicit VR",
        },
};

# get a VR structure. Input parameters: VR Name.
sub getVR
{
    my $vrName = shift;
    if(defined $DicomVRList->{$vrName})
    {
        return $DicomVRList->{$vrName};
    }
    else
    {
        die "Unsupported VR: $vrName\n";
    }
}

1;

__END__

=head1 NAME

DicomVRDict - Dicom Data Structure and Encoding

=head1 SYNOPSIS

References: DICOM PS 3.5-2009 (Part 5: Data Structures and Encoding)

=head1 DESCRIPTION

This module contains information about Dicom Data Dictionary.

=head2 Methods

=over 12

=item C<getVR>

Get information about a VR.

=over 4

=item Input Parameter(s):

=over 4

=item 1.

A VR name. VR name is case-sensitive.

=back

=item Return Value:

A hash reference to the information of a VR.

=back

=back

=head1 AUTHORS

Baoshe Zhang, MCV Medical School, Virginia Commonwealth University

=cut

