#!/usr/bin/env perl

use strict;
use warnings;

use Dicom::UID::Generator;

# Object.
my $obj = Dicom::UID::Generator->new(
      'library_number' => 999,
      'model_number' => '001',
      'serial_number' => 123,
);

# Get Series Instance UID.
my $series_instance_uid = $obj->create_series_instance_uid;

# Get Study Instance UID.
my $study_instance_uid = $obj->create_study_instance_uid;

# Get SOP Instance UID.
my $sop_instance_uid = $obj->create_sop_instance_uid;

# Print out.
print "Study Instance UID: $study_instance_uid\n";
print "Series Instance UID: $series_instance_uid\n";
print "SOP Instance UID: $sop_instance_uid\n";

# Output like:
# Study Instance UID: 999.001.123.1.2.976.20160825112022726.2
# Series Instance UID: 999.001.123.1.3.976.20160825112022647.1
# SOP Instance UID: 999.001.123.1.4.976.20160825112022727.3

# Comments:
# 999 is DICOM library number.
# 001 is device model number.
# 123 is device serial number.
# 1.2, 1.3, 1.4 are hardcoded resolutions of DICOM UID type.
# 976 is PID of process.
# 20160825112022726 is timestamp.
# last number is number of 'uid_counter' parameter.