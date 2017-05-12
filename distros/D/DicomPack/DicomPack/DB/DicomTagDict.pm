##############################################################################
# DicomTagDict -- a module including Dicom Data Dictionary
#
# Copyright (c) 2010 Baoshe Zhang. All rights reserved.
# This file is part of "DicomPack". DicomReader is free software. You can 
# redistribute it and/or modify it under the same terms as Perl itself.
##############################################################################

package DicomPack::DB::DicomTagDict;

use strict;
use warnings;

use vars qw(@ISA @EXPORT_OK);

use Exporter;
@ISA = qw/Exporter/;
@EXPORT_OK = qw/getTag getTagID getTagDesc/;

our $VERSION = '0.95';

my $DicomTagList = {
   "0002,0000" => {
          desc => "File Meta Information Group Length",
            vr => { UL => "1" }
   },
   "0002,0001" => {
          desc => "File Meta Information Version",
            vr => { OB => "1" }
   },
   "0002,0002" => {
          desc => "Media Storage SOP Class UID",
            vr => { UI => "1" }
   },
   "0002,0003" => {
          desc => "Media Storage SOP Instance UID",
            vr => { UI => "1" }
   },
   "0002,0010" => {
          desc => "Transfer Syntax UID",
            vr => { UI => "1" }
   },
   "0002,0012" => {
          desc => "Implementation Class UID",
            vr => { UI => "1" }
   },
   "0002,0013" => {
          desc => "Implementation Version Name",
            vr => { SH => "1" }
   },
   "0002,0016" => {
          desc => "Source Application Entity Title",
            vr => { AE => "1" }
   },
   "0002,0100" => {
          desc => "Private Information Creator UID",
            vr => { UI => "1" }
   },
   "0002,0102" => {
          desc => "Private Information",
            vr => { OB => "1" }
   },
   "0004,1130" => {
          desc => "File-set ID",
            vr => { CS => "1" }
   },
   "0004,1141" => {
          desc => "File-set Descriptor File ID",
            vr => { CS => "1-8" }
   },
   "0004,1142" => {
          desc => "Specific Character Set of File-set Descriptor File",
            vr => { CS => "1" }
   },
   "0004,1200" => {
          desc => "Offset of the First Directory Record of the Root Directory Entity",
            vr => { UL => "1" }
   },
   "0004,1202" => {
          desc => "Offset of the Last Directory Record of the Root Directory Entity",
            vr => { UL => "1" }
   },
   "0004,1212" => {
          desc => "File-set Consistency Flag",
            vr => { US => "1" }
   },
   "0004,1220" => {
          desc => "Directory Record Sequence",
            vr => { SQ => "1" }
   },
   "0004,1400" => {
          desc => "Offset of the Next Directory Record",
            vr => { UL => "1" }
   },
   "0004,1410" => {
          desc => "Record In-use Flag",
            vr => { US => "1" }
   },
   "0004,1420" => {
          desc => "Offset of Referenced Lower-Level Directory Entity",
            vr => { UL => "1" }
   },
   "0004,1430" => {
          desc => "Directory Record Type",
            vr => { CS => "1" }
   },
   "0004,1432" => {
          desc => "Private Record UID",
            vr => { UI => "1" }
   },
   "0004,1500" => {
          desc => "Referenced File ID",
            vr => { CS => "1-8" }
   },
   "0004,1504" => {
          desc => "MRDR Directory Record Offset",
            vr => { UL => "1" },
           ret => 1
    },
   "0004,1510" => {
          desc => "Referenced SOP Class UID in File",
            vr => { UI => "1" }
   },
   "0004,1511" => {
          desc => "Referenced SOP Instance UID in File",
            vr => { UI => "1" }
   },
   "0004,1512" => {
          desc => "Referenced Transfer Syntax UID in File",
            vr => { UI => "1" }
   },
   "0004,151a" => {
          desc => "Referenced Related General SOP Class UID in File",
            vr => { UI => "1-n" }
   },
   "0004,1600" => {
          desc => "Number of References",
            vr => { UL => "1" },
           ret => 1
    },
   "0008,0001" => {
          desc => "Length to End",
            vr => { UL => "1" },
           ret => 1
    },
   "0008,0005" => {
          desc => "Specific Character Set",
            vr => { CS => "1-n" }
   },
   "0008,0006" => {
          desc => "Language Code Sequence",
            vr => { SQ => "1" }
   },
   "0008,0008" => {
          desc => "Image Type",
            vr => { CS => "2-n" }
   },
   "0008,0010" => {
          desc => "Recognition Code",
            vr => { CS => "1" },
           ret => 1
    },
   "0008,0012" => {
          desc => "Instance Creation Date",
            vr => { DA => "1" }
   },
   "0008,0013" => {
          desc => "Instance Creation Time",
            vr => { TM => "1" }
   },
   "0008,0014" => {
          desc => "Instance Creator UID",
            vr => { UI => "1" }
   },
   "0008,0016" => {
          desc => "SOP Class UID",
            vr => { UI => "1" }
   },
   "0008,0018" => {
          desc => "SOP Instance UID",
            vr => { UI => "1" }
   },
   "0008,001a" => {
          desc => "Related General SOP Class UID",
            vr => { UI => "1-n" }
   },
   "0008,001b" => {
          desc => "Original Specialized SOP Class UID",
            vr => { UI => "1" }
   },
   "0008,0020" => {
          desc => "Study Date",
            vr => { DA => "1" }
   },
   "0008,0021" => {
          desc => "Series Date",
            vr => { DA => "1" }
   },
   "0008,0022" => {
          desc => "Acquisition Date",
            vr => { DA => "1" }
   },
   "0008,0023" => {
          desc => "Content Date",
            vr => { DA => "1" }
   },
   "0008,0024" => {
          desc => "Overlay Date",
            vr => { DA => "1" },
           ret => 1
    },
   "0008,0025" => {
          desc => "Curve Date",
            vr => { DA => "1" },
           ret => 1
    },
   "0008,002a" => {
          desc => "Acquisition DateTime",
            vr => { DT => "1" }
   },
   "0008,0030" => {
          desc => "Study Time",
            vr => { TM => "1" }
   },
   "0008,0031" => {
          desc => "Series Time",
            vr => { TM => "1" }
   },
   "0008,0032" => {
          desc => "Acquisition Time",
            vr => { TM => "1" }
   },
   "0008,0033" => {
          desc => "Content Time",
            vr => { TM => "1" }
   },
   "0008,0034" => {
          desc => "Overlay Time",
            vr => { TM => "1" },
           ret => 1
    },
   "0008,0035" => {
          desc => "Curve Time",
            vr => { TM => "1" },
           ret => 1
    },
   "0008,0040" => {
          desc => "Data Set Type",
            vr => { US => "1" },
           ret => 1
    },
   "0008,0041" => {
          desc => "Data Set Subtype",
            vr => { LO => "1" },
           ret => 1
    },
   "0008,0042" => {
          desc => "Nuclear Medicine Series Type",
            vr => { CS => "1" },
           ret => 1
    },
   "0008,0050" => {
          desc => "Accession Number",
            vr => { SH => "1" }
   },
   "0008,0051" => {
          desc => "Issuer of Accession Number Sequence",
            vr => { SQ => "1" }
   },
   "0008,0052" => {
          desc => "Query/Retrieve Level",
            vr => { CS => "1" }
   },
   "0008,0054" => {
          desc => "Retrieve AE Title",
            vr => { AE => "1-n" }
   },
   "0008,0056" => {
          desc => "Instance Availability",
            vr => { CS => "1" }
   },
   "0008,0058" => {
          desc => "Failed SOP Instance UID List",
            vr => { UI => "1-n" }
   },
   "0008,0060" => {
          desc => "Modality",
            vr => { CS => "1" }
   },
   "0008,0061" => {
          desc => "Modalities in Study",
            vr => { CS => "1-n" }
   },
   "0008,0062" => {
          desc => "SOP Classes in Study",
            vr => { UI => "1-n" }
   },
   "0008,0064" => {
          desc => "Conversion Type",
            vr => { CS => "1" }
   },
   "0008,0068" => {
          desc => "Presentation Intent Type",
            vr => { CS => "1" }
   },
   "0008,0070" => {
          desc => "Manufacturer",
            vr => { LO => "1" }
   },
   "0008,0080" => {
          desc => "Institution Name",
            vr => { LO => "1" }
   },
   "0008,0081" => {
          desc => "Institution Address",
            vr => { ST => "1" }
   },
   "0008,0082" => {
          desc => "Institution Code Sequence",
            vr => { SQ => "1" }
   },
   "0008,0090" => {
          desc => "Referring Physician's Name",
            vr => { PN => "1" }
   },
   "0008,0092" => {
          desc => "Referring Physician's Address",
            vr => { ST => "1" }
   },
   "0008,0094" => {
          desc => "Referring Physician's Telephone Numbers",
            vr => { SH => "1-n" }
   },
   "0008,0096" => {
          desc => "Referring Physician Identification Sequence",
            vr => { SQ => "1" }
   },
   "0008,0100" => {
          desc => "Code Value",
            vr => { SH => "1" }
   },
   "0008,0102" => {
          desc => "Coding Scheme Designator",
            vr => { SH => "1" }
   },
   "0008,0103" => {
          desc => "Coding Scheme Version",
            vr => { SH => "1" }
   },
   "0008,0104" => {
          desc => "Code Meaning",
            vr => { LO => "1" }
   },
   "0008,0105" => {
          desc => "Mapping Resource",
            vr => { CS => "1" }
   },
   "0008,0106" => {
          desc => "Context Group Version",
            vr => { DT => "1" }
   },
   "0008,0107" => {
          desc => "Context Group Local Version",
            vr => { DT => "1" }
   },
   "0008,010b" => {
          desc => "Context Group Extension Flag",
            vr => { CS => "1" }
   },
   "0008,010c" => {
          desc => "Coding Scheme UID",
            vr => { UI => "1" }
   },
   "0008,010d" => {
          desc => "Context Group Extension Creator UID",
            vr => { UI => "1" }
   },
   "0008,010f" => {
          desc => "Context Identifier",
            vr => { CS => "1" }
   },
   "0008,0110" => {
          desc => "Coding Scheme Identification Sequence",
            vr => { SQ => "1" }
   },
   "0008,0112" => {
          desc => "Coding Scheme Registry",
            vr => { LO => "1" }
   },
   "0008,0114" => {
          desc => "Coding Scheme External ID",
            vr => { ST => "1" }
   },
   "0008,0115" => {
          desc => "Coding Scheme Name",
            vr => { ST => "1" }
   },
   "0008,0116" => {
          desc => "Coding Scheme Responsible Organization",
            vr => { ST => "1" }
   },
   "0008,0117" => {
          desc => "Context UID",
            vr => { UI => "1" }
   },
   "0008,0201" => {
          desc => "Timezone Offset From UTC",
            vr => { SH => "1" }
   },
   "0008,1000" => {
          desc => "Network ID",
            vr => { AE => "1" },
           ret => 1
    },
   "0008,1010" => {
          desc => "Station Name",
            vr => { SH => "1" }
   },
   "0008,1030" => {
          desc => "Study Description",
            vr => { LO => "1" }
   },
   "0008,1032" => {
          desc => "Procedure Code Sequence",
            vr => { SQ => "1" }
   },
   "0008,103e" => {
          desc => "Series Description",
            vr => { LO => "1" }
   },
   "0008,103f" => {
          desc => "Series Description Code Sequence",
            vr => { SQ => "1" }
   },
   "0008,1040" => {
          desc => "Institutional Department Name",
            vr => { LO => "1" }
   },
   "0008,1048" => {
          desc => "Physician(s) of Record",
            vr => { PN => "1-n" }
   },
   "0008,1049" => {
          desc => "Physician(s) of Record Identification Sequence",
            vr => { SQ => "1" }
   },
   "0008,1050" => {
          desc => "Performing Physician's Name",
            vr => { PN => "1-n" }
   },
   "0008,1052" => {
          desc => "Performing Physician Identification Sequence",
            vr => { SQ => "1" }
   },
   "0008,1060" => {
          desc => "Name of Physician(s) Reading Study",
            vr => { PN => "1-n" }
   },
   "0008,1062" => {
          desc => "Physician(s) Reading Study Identification Sequence",
            vr => { SQ => "1" }
   },
   "0008,1070" => {
          desc => "Operators' Name",
            vr => { PN => "1-n" }
   },
   "0008,1072" => {
          desc => "Operator Identification Sequence",
            vr => { SQ => "1" }
   },
   "0008,1080" => {
          desc => "Admitting Diagnoses Description",
            vr => { LO => "1-n" }
   },
   "0008,1084" => {
          desc => "Admitting Diagnoses Code Sequence",
            vr => { SQ => "1" }
   },
   "0008,1090" => {
          desc => "Manufacturer's Model Name",
            vr => { LO => "1" }
   },
   "0008,1100" => {
          desc => "Referenced Results Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "0008,1110" => {
          desc => "Referenced Study Sequence",
            vr => { SQ => "1" }
   },
   "0008,1111" => {
          desc => "Referenced Performed Procedure Step Sequence",
            vr => { SQ => "1" }
   },
   "0008,1115" => {
          desc => "Referenced Series Sequence",
            vr => { SQ => "1" }
   },
   "0008,1120" => {
          desc => "Referenced Patient Sequence",
            vr => { SQ => "1" }
   },
   "0008,1125" => {
          desc => "Referenced Visit Sequence",
            vr => { SQ => "1" }
   },
   "0008,1130" => {
          desc => "Referenced Overlay Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "0008,1134" => {
          desc => "Referenced Stereometric Instance Sequence",
            vr => { SQ => "1" }
   },
   "0008,113a" => {
          desc => "Referenced Waveform Sequence",
            vr => { SQ => "1" }
   },
   "0008,1140" => {
          desc => "Referenced Image Sequence",
            vr => { SQ => "1" }
   },
   "0008,1145" => {
          desc => "Referenced Curve Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "0008,114a" => {
          desc => "Referenced Instance Sequence",
            vr => { SQ => "1" }
   },
   "0008,114b" => {
          desc => "Referenced Real World Value Mapping Instance Sequence",
            vr => { SQ => "1" }
   },
   "0008,1150" => {
          desc => "Referenced SOP Class UID",
            vr => { UI => "1" }
   },
   "0008,1155" => {
          desc => "Referenced SOP Instance UID",
            vr => { UI => "1" }
   },
   "0008,115a" => {
          desc => "SOP Classes Supported",
            vr => { UI => "1-n" }
   },
   "0008,1160" => {
          desc => "Referenced Frame Number",
            vr => { IS => "1-n" }
   },
   "0008,1161" => {
          desc => "Simple Frame List",
            vr => { UL => "1-n" }
   },
   "0008,1162" => {
          desc => "Calculated Frame List",
            vr => { UL => "3-3n" }
   },
   "0008,1163" => {
          desc => "Time Range",
            vr => { FD => "2" }
   },
   "0008,1164" => {
          desc => "Frame Extraction Sequence",
            vr => { SQ => "1" }
   },
   "0008,1167" => {
          desc => "Multi-Frame Source SOP Instance UID ",
            vr => { UI => "1" }
   },
   "0008,1195" => {
          desc => "Transaction UID",
            vr => { UI => "1" }
   },
   "0008,1197" => {
          desc => "Failure Reason",
            vr => { US => "1" }
   },
   "0008,1198" => {
          desc => "Failed SOP Sequence",
            vr => { SQ => "1" }
   },
   "0008,1199" => {
          desc => "Referenced SOP Sequence",
            vr => { SQ => "1" }
   },
   "0008,1200" => {
          desc => "Studies Containing Other Referenced Instances Sequence",
            vr => { SQ => "1" }
   },
   "0008,1250" => {
          desc => "Related Series Sequence",
            vr => { SQ => "1" }
   },
   "0008,2110" => {
          desc => "Lossy Image Compression (Retired)",
            vr => { CS => "1" },
           ret => 1
    },
   "0008,2111" => {
          desc => "Derivation Description",
            vr => { ST => "1" }
   },
   "0008,2112" => {
          desc => "Source Image Sequence",
            vr => { SQ => "1" }
   },
   "0008,2120" => {
          desc => "Stage Name",
            vr => { SH => "1" }
   },
   "0008,2122" => {
          desc => "Stage Number",
            vr => { IS => "1" }
   },
   "0008,2124" => {
          desc => "Number of Stages",
            vr => { IS => "1" }
   },
   "0008,2127" => {
          desc => "View Name",
            vr => { SH => "1" }
   },
   "0008,2128" => {
          desc => "View Number",
            vr => { IS => "1" }
   },
   "0008,2129" => {
          desc => "Number of Event Timers",
            vr => { IS => "1" }
   },
   "0008,212a" => {
          desc => "Number of Views in Stage",
            vr => { IS => "1" }
   },
   "0008,2130" => {
          desc => "Event Elapsed Time(s)",
            vr => { DS => "1-n" }
   },
   "0008,2132" => {
          desc => "Event Timer Name(s)",
            vr => { LO => "1-n" }
   },
   "0008,2133" => {
          desc => "Event Timer Sequence",
            vr => { SQ => "1" }
   },
   "0008,2134" => {
          desc => "Event Time Offset",
            vr => { FD => "1" }
   },
   "0008,2135" => {
          desc => "Event Code Sequence",
            vr => { SQ => "1" }
   },
   "0008,2142" => {
          desc => "Start Trim",
            vr => { IS => "1" }
   },
   "0008,2143" => {
          desc => "Stop Trim",
            vr => { IS => "1" }
   },
   "0008,2144" => {
          desc => "Recommended Display Frame Rate",
            vr => { IS => "1" }
   },
   "0008,2200" => {
          desc => "Transducer Position",
            vr => { CS => "1" },
           ret => 1
    },
   "0008,2204" => {
          desc => "Transducer Orientation",
            vr => { CS => "1" },
           ret => 1
    },
   "0008,2208" => {
          desc => "Anatomic Structure",
            vr => { CS => "1" },
           ret => 1
    },
   "0008,2218" => {
          desc => "Anatomic Region Sequence",
            vr => { SQ => "1" }
   },
   "0008,2220" => {
          desc => "Anatomic Region Modifier Sequence",
            vr => { SQ => "1" }
   },
   "0008,2228" => {
          desc => "Primary Anatomic Structure Sequence",
            vr => { SQ => "1" }
   },
   "0008,2229" => {
          desc => "Anatomic Structure, Space or Region Sequence",
            vr => { SQ => "1" }
   },
   "0008,2230" => {
          desc => "Primary Anatomic Structure Modifier Sequence",
            vr => { SQ => "1" }
   },
   "0008,2240" => {
          desc => "Transducer Position Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "0008,2242" => {
          desc => "Transducer Position Modifier Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "0008,2244" => {
          desc => "Transducer Orientation Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "0008,2246" => {
          desc => "Transducer Orientation Modifier Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "0008,2251" => {
          desc => "Anatomic Structure Space Or Region Code Sequence (Trial)",
            vr => { SQ => "1" },
           ret => 1
    },
   "0008,2253" => {
          desc => "Anatomic Portal Of Entrance Code Sequence (Trial)",
            vr => { SQ => "1" },
           ret => 1
    },
   "0008,2255" => {
          desc => "Anatomic Approach Direction Code Sequence (Trial)",
            vr => { SQ => "1" },
           ret => 1
    },
   "0008,2256" => {
          desc => "Anatomic Perspective Description (Trial)",
            vr => { ST => "1" },
           ret => 1
    },
   "0008,2257" => {
          desc => "Anatomic Perspective Code Sequence (Trial)",
            vr => { SQ => "1" },
           ret => 1
    },
   "0008,2258" => {
          desc => "Anatomic Location Of Examining Instrument Description (Trial)",
            vr => { ST => "1" },
           ret => 1
    },
   "0008,2259" => {
          desc => "Anatomic Location Of Examining Instrument Code Sequence (Trial)",
            vr => { SQ => "1" },
           ret => 1
    },
   "0008,225a" => {
          desc => "Anatomic Structure Space Or Region Modifier Code Sequence (Trial)",
            vr => { SQ => "1" },
           ret => 1
    },
   "0008,225c" => {
          desc => "OnAxis Background Anatomic Structure Code Sequence (Trial)",
            vr => { SQ => "1" },
           ret => 1
    },
   "0008,3001" => {
          desc => "Alternate Representation Sequence",
            vr => { SQ => "1" }
   },
   "0008,3010" => {
          desc => "Irradiation Event UID",
            vr => { UI => "1" }
   },
   "0008,4000" => {
          desc => "Identifying Comments",
            vr => { LT => "1" },
           ret => 1
    },
   "0008,9007" => {
          desc => "Frame Type",
            vr => { CS => "4" }
   },
   "0008,9092" => {
          desc => "Referenced Image Evidence Sequence",
            vr => { SQ => "1" }
   },
   "0008,9121" => {
          desc => "Referenced Raw Data Sequence",
            vr => { SQ => "1" }
   },
   "0008,9123" => {
          desc => "Creator-Version UID",
            vr => { UI => "1" }
   },
   "0008,9124" => {
          desc => "Derivation Image Sequence",
            vr => { SQ => "1" }
   },
   "0008,9154" => {
          desc => "Source Image Evidence Sequence",
            vr => { SQ => "1" }
   },
   "0008,9205" => {
          desc => "Pixel Presentation",
            vr => { CS => "1" }
   },
   "0008,9206" => {
          desc => "Volumetric Properties",
            vr => { CS => "1" }
   },
   "0008,9207" => {
          desc => "Volume Based Calculation Technique",
            vr => { CS => "1" }
   },
   "0008,9208" => {
          desc => "Complex Image Component",
            vr => { CS => "1" }
   },
   "0008,9209" => {
          desc => "Acquisition Contrast",
            vr => { CS => "1" }
   },
   "0008,9215" => {
          desc => "Derivation Code Sequence",
            vr => { SQ => "1" }
   },
   "0008,9237" => {
          desc => "Referenced Presentation State Sequence",
            vr => { SQ => "1" }
   },
   "0008,9410" => {
          desc => "Referenced Other Plane Sequence",
            vr => { SQ => "1" }
   },
   "0008,9458" => {
          desc => "Frame Display Sequence",
            vr => { SQ => "1" }
   },
   "0008,9459" => {
          desc => "Recommended Display Frame Rate in Float",
            vr => { FL => "1" }
   },
   "0008,9460" => {
          desc => "Skip Frame Range Flag",
            vr => { CS => "1" }
   },
   "0010,0010" => {
          desc => "Patient's Name",
            vr => { PN => "1" }
   },
   "0010,0020" => {
          desc => "Patient ID",
            vr => { LO => "1" }
   },
   "0010,0021" => {
          desc => "Issuer of Patient ID",
            vr => { LO => "1" }
   },
   "0010,0022" => {
          desc => "Type of Patient ID",
            vr => { CS => "1" }
   },
   "0010,0024" => {
          desc => "Issuer of Patient ID Qualifiers Sequence",
            vr => { SQ => "1" }
   },
   "0010,0030" => {
          desc => "Patient's Birth Date",
            vr => { DA => "1" }
   },
   "0010,0032" => {
          desc => "Patient's Birth Time",
            vr => { TM => "1" }
   },
   "0010,0040" => {
          desc => "Patient's Sex",
            vr => { CS => "1" }
   },
   "0010,0050" => {
          desc => "Patient's Insurance Plan Code Sequence",
            vr => { SQ => "1" }
   },
   "0010,0101" => {
          desc => "Patient's Primary Language Code Sequence",
            vr => { SQ => "1" }
   },
   "0010,0102" => {
          desc => "Patient's Primary Language Modifier Code Sequence",
            vr => { SQ => "1" }
   },
   "0010,1000" => {
          desc => "Other Patient IDs",
            vr => { LO => "1-n" }
   },
   "0010,1001" => {
          desc => "Other Patient Names",
            vr => { PN => "1-n" }
   },
   "0010,1002" => {
          desc => "Other Patient IDs Sequence",
            vr => { SQ => "1" }
   },
   "0010,1005" => {
          desc => "Patient's Birth Name",
            vr => { PN => "1" }
   },
   "0010,1010" => {
          desc => "Patient's Age",
            vr => { AS => "1" }
   },
   "0010,1020" => {
          desc => "Patient's Size",
            vr => { DS => "1" }
   },
   "0010,1030" => {
          desc => "Patient's Weight",
            vr => { DS => "1" }
   },
   "0010,1040" => {
          desc => "Patient's Address",
            vr => { LO => "1" }
   },
   "0010,1050" => {
          desc => "Insurance Plan Identification",
            vr => { LO => "1-n" },
           ret => 1
    },
   "0010,1060" => {
          desc => "Patient's Mother's Birth Name",
            vr => { PN => "1" }
   },
   "0010,1080" => {
          desc => "Military Rank",
            vr => { LO => "1" }
   },
   "0010,1081" => {
          desc => "Branch of Service",
            vr => { LO => "1" }
   },
   "0010,1090" => {
          desc => "Medical Record Locator",
            vr => { LO => "1" }
   },
   "0010,2000" => {
          desc => "Medical Alerts",
            vr => { LO => "1-n" }
   },
   "0010,2110" => {
          desc => "Allergies",
            vr => { LO => "1-n" }
   },
   "0010,2150" => {
          desc => "Country of Residence",
            vr => { LO => "1" }
   },
   "0010,2152" => {
          desc => "Region of Residence",
            vr => { LO => "1" }
   },
   "0010,2154" => {
          desc => "Patient's Telephone Numbers",
            vr => { SH => "1-n" }
   },
   "0010,2160" => {
          desc => "Ethnic Group",
            vr => { SH => "1" }
   },
   "0010,2180" => {
          desc => "Occupation",
            vr => { SH => "1" }
   },
   "0010,21a0" => {
          desc => "Smoking Status",
            vr => { CS => "1" }
   },
   "0010,21b0" => {
          desc => "Additional Patient History",
            vr => { LT => "1" }
   },
   "0010,21c0" => {
          desc => "Pregnancy Status",
            vr => { US => "1" }
   },
   "0010,21d0" => {
          desc => "Last Menstrual Date",
            vr => { DA => "1" }
   },
   "0010,21f0" => {
          desc => "Patient's Religious Preference",
            vr => { LO => "1" }
   },
   "0010,2201" => {
          desc => "Patient Species Description",
            vr => { LO => "1" }
   },
   "0010,2202" => {
          desc => "Patient Species Code Sequence",
            vr => { SQ => "1" }
   },
   "0010,2203" => {
          desc => "Patient's Sex Neutered",
            vr => { CS => "1" }
   },
   "0010,2210" => {
          desc => "Anatomical Orientation Type",
            vr => { CS => "1" }
   },
   "0010,2292" => {
          desc => "Patient Breed Description",
            vr => { LO => "1" }
   },
   "0010,2293" => {
          desc => "Patient Breed Code Sequence",
            vr => { SQ => "1" }
   },
   "0010,2294" => {
          desc => "Breed Registration Sequence",
            vr => { SQ => "1" }
   },
   "0010,2295" => {
          desc => "Breed Registration Number",
            vr => { LO => "1" }
   },
   "0010,2296" => {
          desc => "Breed Registry Code Sequence",
            vr => { SQ => "1" }
   },
   "0010,2297" => {
          desc => "Responsible Person",
            vr => { PN => "1" }
   },
   "0010,2298" => {
          desc => "Responsible Person Role",
            vr => { CS => "1" }
   },
   "0010,2299" => {
          desc => "Responsible Organization",
            vr => { LO => "1" }
   },
   "0010,4000" => {
          desc => "Patient Comments",
            vr => { LT => "1" }
   },
   "0010,9431" => {
          desc => "Examined Body Thickness",
            vr => { FL => "1" }
   },
   "0012,0010" => {
          desc => "Clinical Trial Sponsor Name",
            vr => { LO => "1" }
   },
   "0012,0020" => {
          desc => "Clinical Trial Protocol ID",
            vr => { LO => "1" }
   },
   "0012,0021" => {
          desc => "Clinical Trial Protocol Name",
            vr => { LO => "1" }
   },
   "0012,0030" => {
          desc => "Clinical Trial Site ID",
            vr => { LO => "1" }
   },
   "0012,0031" => {
          desc => "Clinical Trial Site Name",
            vr => { LO => "1" }
   },
   "0012,0040" => {
          desc => "Clinical Trial Subject ID",
            vr => { LO => "1" }
   },
   "0012,0042" => {
          desc => "Clinical Trial Subject Reading ID",
            vr => { LO => "1" }
   },
   "0012,0050" => {
          desc => "Clinical Trial Time Point ID",
            vr => { LO => "1" }
   },
   "0012,0051" => {
          desc => "Clinical Trial Time Point Description",
            vr => { ST => "1" }
   },
   "0012,0060" => {
          desc => "Clinical Trial Coordinating Center Name",
            vr => { LO => "1" }
   },
   "0012,0062" => {
          desc => "Patient Identity Removed",
            vr => { CS => "1" }
   },
   "0012,0063" => {
          desc => "De-identification Method",
            vr => { LO => "1-n" }
   },
   "0012,0064" => {
          desc => "De-identification Method Code Sequence",
            vr => { SQ => "1" }
   },
   "0012,0071" => {
          desc => "Clinical Trial Series ID",
            vr => { LO => "1" }
   },
   "0012,0072" => {
          desc => "Clinical Trial Series Description",
            vr => { LO => "1" }
   },
   "0012,0081" => {
          desc => "Clinical Trial Protocol Ethics Committee Name",
            vr => { LO => "1" }
   },
   "0012,0082" => {
          desc => "Clinical Trial Protocol Ethics Committee Approval Number",
            vr => { LO => "1" }
   },
   "0012,0083" => {
          desc => "Consent for Clinical Trial Use Sequence",
            vr => { SQ => "1" }
   },
   "0012,0084" => {
          desc => "Distribution Type",
            vr => { CS => "1" }
   },
   "0012,0085" => {
          desc => "Consent for Distribution Flag",
            vr => { CS => "1" }
   },
   "0018,0010" => {
          desc => "Contrast/Bolus Agent",
            vr => { LO => "1" }
   },
   "0018,0012" => {
          desc => "Contrast/Bolus Agent Sequence",
            vr => { SQ => "1" }
   },
   "0018,0014" => {
          desc => "Contrast/Bolus Administration Route Sequence",
            vr => { SQ => "1" }
   },
   "0018,0015" => {
          desc => "Body Part Examined",
            vr => { CS => "1" }
   },
   "0018,0020" => {
          desc => "Scanning Sequence",
            vr => { CS => "1-n" }
   },
   "0018,0021" => {
          desc => "Sequence Variant",
            vr => { CS => "1-n" }
   },
   "0018,0022" => {
          desc => "Scan Options",
            vr => { CS => "1-n" }
   },
   "0018,0023" => {
          desc => "MR Acquisition Type",
            vr => { CS => "1" }
   },
   "0018,0024" => {
          desc => "Sequence Name",
            vr => { SH => "1" }
   },
   "0018,0025" => {
          desc => "Angio Flag",
            vr => { CS => "1" }
   },
   "0018,0026" => {
          desc => "Intervention Drug Information Sequence",
            vr => { SQ => "1" }
   },
   "0018,0027" => {
          desc => "Intervention Drug Stop Time",
            vr => { TM => "1" }
   },
   "0018,0028" => {
          desc => "Intervention Drug Dose",
            vr => { DS => "1" }
   },
   "0018,0029" => {
          desc => "Intervention Drug Code Sequence",
            vr => { SQ => "1" }
   },
   "0018,002a" => {
          desc => "Additional Drug Sequence",
            vr => { SQ => "1" }
   },
   "0018,0030" => {
          desc => "Radionuclide",
            vr => { LO => "1-n" },
           ret => 1
    },
   "0018,0031" => {
          desc => "Radiopharmaceutical",
            vr => { LO => "1" }
   },
   "0018,0032" => {
          desc => "Energy Window Centerline",
            vr => { DS => "1" },
           ret => 1
    },
   "0018,0033" => {
          desc => "Energy Window Total Width",
            vr => { DS => "1-n" },
           ret => 1
    },
   "0018,0034" => {
          desc => "Intervention Drug Name",
            vr => { LO => "1" }
   },
   "0018,0035" => {
          desc => "Intervention Drug Start Time",
            vr => { TM => "1" }
   },
   "0018,0036" => {
          desc => "Intervention Sequence",
            vr => { SQ => "1" }
   },
   "0018,0037" => {
          desc => "Therapy Type",
            vr => { CS => "1" },
           ret => 1
    },
   "0018,0038" => {
          desc => "Intervention Status",
            vr => { CS => "1" }
   },
   "0018,0039" => {
          desc => "Therapy Description",
            vr => { CS => "1" },
           ret => 1
    },
   "0018,003a" => {
          desc => "Intervention Description",
            vr => { ST => "1" }
   },
   "0018,0040" => {
          desc => "Cine Rate ",
            vr => { IS => "1" }
   },
   "0018,0042" => {
          desc => "Initial Cine Run State",
            vr => { CS => "1" }
   },
   "0018,0050" => {
          desc => "Slice Thickness",
            vr => { DS => "1" }
   },
   "0018,0060" => {
          desc => "KVP",
            vr => { DS => "1" }
   },
   "0018,0070" => {
          desc => "Counts Accumulated",
            vr => { IS => "1" }
   },
   "0018,0071" => {
          desc => "Acquisition Termination Condition",
            vr => { CS => "1" }
   },
   "0018,0072" => {
          desc => "Effective Duration",
            vr => { DS => "1" }
   },
   "0018,0073" => {
          desc => "Acquisition Start Condition",
            vr => { CS => "1" }
   },
   "0018,0074" => {
          desc => "Acquisition Start Condition Data",
            vr => { IS => "1" }
   },
   "0018,0075" => {
          desc => "Acquisition Termination Condition Data",
            vr => { IS => "1" }
   },
   "0018,0080" => {
          desc => "Repetition Time",
            vr => { DS => "1" }
   },
   "0018,0081" => {
          desc => "Echo Time",
            vr => { DS => "1" }
   },
   "0018,0082" => {
          desc => "Inversion Time",
            vr => { DS => "1" }
   },
   "0018,0083" => {
          desc => "Number of Averages",
            vr => { DS => "1" }
   },
   "0018,0084" => {
          desc => "Imaging Frequency",
            vr => { DS => "1" }
   },
   "0018,0085" => {
          desc => "Imaged Nucleus",
            vr => { SH => "1" }
   },
   "0018,0086" => {
          desc => "Echo Number(s)",
            vr => { IS => "1-n" }
   },
   "0018,0087" => {
          desc => "Magnetic Field Strength",
            vr => { DS => "1" }
   },
   "0018,0088" => {
          desc => "Spacing Between Slices",
            vr => { DS => "1" }
   },
   "0018,0089" => {
          desc => "Number of Phase Encoding Steps",
            vr => { IS => "1" }
   },
   "0018,0090" => {
          desc => "Data Collection Diameter",
            vr => { DS => "1" }
   },
   "0018,0091" => {
          desc => "Echo Train Length",
            vr => { IS => "1" }
   },
   "0018,0093" => {
          desc => "Percent Sampling",
            vr => { DS => "1" }
   },
   "0018,0094" => {
          desc => "Percent Phase Field of View",
            vr => { DS => "1" }
   },
   "0018,0095" => {
          desc => "Pixel Bandwidth",
            vr => { DS => "1" }
   },
   "0018,1000" => {
          desc => "Device Serial Number",
            vr => { LO => "1" }
   },
   "0018,1002" => {
          desc => "Device UID",
            vr => { UI => "1" }
   },
   "0018,1003" => {
          desc => "Device ID",
            vr => { LO => "1" }
   },
   "0018,1004" => {
          desc => "Plate ID",
            vr => { LO => "1" }
   },
   "0018,1005" => {
          desc => "Generator ID",
            vr => { LO => "1" }
   },
   "0018,1006" => {
          desc => "Grid ID",
            vr => { LO => "1" }
   },
   "0018,1007" => {
          desc => "Cassette ID",
            vr => { LO => "1" }
   },
   "0018,1008" => {
          desc => "Gantry ID",
            vr => { LO => "1" }
   },
   "0018,1010" => {
          desc => "Secondary Capture Device ID",
            vr => { LO => "1" }
   },
   "0018,1011" => {
          desc => "Hardcopy Creation Device ID",
            vr => { LO => "1" },
           ret => 1
    },
   "0018,1012" => {
          desc => "Date of Secondary Capture",
            vr => { DA => "1" }
   },
   "0018,1014" => {
          desc => "Time of Secondary Capture",
            vr => { TM => "1" }
   },
   "0018,1016" => {
          desc => "Secondary Capture Device Manufacturer",
            vr => { LO => "1" }
   },
   "0018,1017" => {
          desc => "Hardcopy Device Manufacturer",
            vr => { LO => "1" },
           ret => 1
    },
   "0018,1018" => {
          desc => "Secondary Capture Device Manufacturer's Model Name",
            vr => { LO => "1" }
   },
   "0018,1019" => {
          desc => "Secondary Capture Device Software Versions",
            vr => { LO => "1-n" }
   },
   "0018,101a" => {
          desc => "Hardcopy Device Software Version",
            vr => { LO => "1-n" },
           ret => 1
    },
   "0018,101b" => {
          desc => "Hardcopy Device Manufacturer's Model Name",
            vr => { LO => "1" },
           ret => 1
    },
   "0018,1020" => {
          desc => "Software Version(s)",
            vr => { LO => "1-n" }
   },
   "0018,1022" => {
          desc => "Video Image Format Acquired",
            vr => { SH => "1" }
   },
   "0018,1023" => {
          desc => "Digital Image Format Acquired",
            vr => { LO => "1" }
   },
   "0018,1030" => {
          desc => "Protocol Name",
            vr => { LO => "1" }
   },
   "0018,1040" => {
          desc => "Contrast/Bolus Route",
            vr => { LO => "1" }
   },
   "0018,1041" => {
          desc => "Contrast/Bolus Volume",
            vr => { DS => "1" }
   },
   "0018,1042" => {
          desc => "Contrast/Bolus Start Time ",
            vr => { TM => "1" }
   },
   "0018,1043" => {
          desc => "Contrast/Bolus Stop Time ",
            vr => { TM => "1" }
   },
   "0018,1044" => {
          desc => "Contrast/Bolus Total Dose",
            vr => { DS => "1" }
   },
   "0018,1045" => {
          desc => "Syringe Counts",
            vr => { IS => "1" }
   },
   "0018,1046" => {
          desc => "Contrast Flow Rate",
            vr => { DS => "1-n" }
   },
   "0018,1047" => {
          desc => "Contrast Flow Duration",
            vr => { DS => "1-n" }
   },
   "0018,1048" => {
          desc => "Contrast/Bolus Ingredient",
            vr => { CS => "1" }
   },
   "0018,1049" => {
          desc => "Contrast/Bolus Ingredient Concentration",
            vr => { DS => "1" }
   },
   "0018,1050" => {
          desc => "Spatial Resolution",
            vr => { DS => "1" }
   },
   "0018,1060" => {
          desc => "Trigger Time",
            vr => { DS => "1" }
   },
   "0018,1061" => {
          desc => "Trigger Source or Type",
            vr => { LO => "1" }
   },
   "0018,1062" => {
          desc => "Nominal Interval",
            vr => { IS => "1" }
   },
   "0018,1063" => {
          desc => "Frame Time",
            vr => { DS => "1" }
   },
   "0018,1064" => {
          desc => "Cardiac Framing Type",
            vr => { LO => "1" }
   },
   "0018,1065" => {
          desc => "Frame Time Vector",
            vr => { DS => "1-n" }
   },
   "0018,1066" => {
          desc => "Frame Delay",
            vr => { DS => "1" }
   },
   "0018,1067" => {
          desc => "Image Trigger Delay",
            vr => { DS => "1" }
   },
   "0018,1068" => {
          desc => "Multiplex Group Time Offset",
            vr => { DS => "1" }
   },
   "0018,1069" => {
          desc => "Trigger Time Offset",
            vr => { DS => "1" }
   },
   "0018,106a" => {
          desc => "Synchronization Trigger",
            vr => { CS => "1" }
   },
   "0018,106c" => {
          desc => "Synchronization Channel",
            vr => { US => "2" }
   },
   "0018,106e" => {
          desc => "Trigger Sample Position",
            vr => { UL => "1" }
   },
   "0018,1070" => {
          desc => "Radiopharmaceutical Route",
            vr => { LO => "1" }
   },
   "0018,1071" => {
          desc => "Radiopharmaceutical Volume",
            vr => { DS => "1" }
   },
   "0018,1072" => {
          desc => "Radiopharmaceutical Start Time",
            vr => { TM => "1" }
   },
   "0018,1073" => {
          desc => "Radiopharmaceutical Stop Time",
            vr => { TM => "1" }
   },
   "0018,1074" => {
          desc => "Radionuclide Total Dose",
            vr => { DS => "1" }
   },
   "0018,1075" => {
          desc => "Radionuclide Half Life",
            vr => { DS => "1" }
   },
   "0018,1076" => {
          desc => "Radionuclide Positron Fraction",
            vr => { DS => "1" }
   },
   "0018,1077" => {
          desc => "Radiopharmaceutical Specific Activity",
            vr => { DS => "1" }
   },
   "0018,1078" => {
          desc => "Radiopharmaceutical Start DateTime",
            vr => { DT => "1" }
   },
   "0018,1079" => {
          desc => "Radiopharmaceutical Stop DateTime",
            vr => { DT => "1" }
   },
   "0018,1080" => {
          desc => "Beat Rejection Flag",
            vr => { CS => "1" }
   },
   "0018,1081" => {
          desc => "Low R-R Value",
            vr => { IS => "1" }
   },
   "0018,1082" => {
          desc => "High R-R Value",
            vr => { IS => "1" }
   },
   "0018,1083" => {
          desc => "Intervals Acquired",
            vr => { IS => "1" }
   },
   "0018,1084" => {
          desc => "Intervals Rejected",
            vr => { IS => "1" }
   },
   "0018,1085" => {
          desc => "PVC Rejection",
            vr => { LO => "1" }
   },
   "0018,1086" => {
          desc => "Skip Beats",
            vr => { IS => "1" }
   },
   "0018,1088" => {
          desc => "Heart Rate",
            vr => { IS => "1" }
   },
   "0018,1090" => {
          desc => "Cardiac Number of Images",
            vr => { IS => "1" }
   },
   "0018,1094" => {
          desc => "Trigger Window",
            vr => { IS => "1" }
   },
   "0018,1100" => {
          desc => "Reconstruction Diameter",
            vr => { DS => "1" }
   },
   "0018,1110" => {
          desc => "Distance Source to Detector",
            vr => { DS => "1" }
   },
   "0018,1111" => {
          desc => "Distance Source to Patient",
            vr => { DS => "1" }
   },
   "0018,1114" => {
          desc => "Estimated Radiographic Magnification Factor",
            vr => { DS => "1" }
   },
   "0018,1120" => {
          desc => "Gantry/Detector Tilt",
            vr => { DS => "1" }
   },
   "0018,1121" => {
          desc => "Gantry/Detector Slew",
            vr => { DS => "1" }
   },
   "0018,1130" => {
          desc => "Table Height",
            vr => { DS => "1" }
   },
   "0018,1131" => {
          desc => "Table Traverse",
            vr => { DS => "1" }
   },
   "0018,1134" => {
          desc => "Table Motion",
            vr => { CS => "1" }
   },
   "0018,1135" => {
          desc => "Table Vertical Increment",
            vr => { DS => "1-n" }
   },
   "0018,1136" => {
          desc => "Table Lateral Increment",
            vr => { DS => "1-n" }
   },
   "0018,1137" => {
          desc => "Table Longitudinal Increment",
            vr => { DS => "1-n" }
   },
   "0018,1138" => {
          desc => "Table Angle",
            vr => { DS => "1" }
   },
   "0018,113a" => {
          desc => "Table Type",
            vr => { CS => "1" }
   },
   "0018,1140" => {
          desc => "Rotation Direction",
            vr => { CS => "1" }
   },
   "0018,1141" => {
          desc => "Angular Position",
            vr => { DS => "1" },
           ret => 1
    },
   "0018,1142" => {
          desc => "Radial Position",
            vr => { DS => "1-n" }
   },
   "0018,1143" => {
          desc => "Scan Arc",
            vr => { DS => "1" }
   },
   "0018,1144" => {
          desc => "Angular Step",
            vr => { DS => "1" }
   },
   "0018,1145" => {
          desc => "Center of Rotation Offset",
            vr => { DS => "1" }
   },
   "0018,1146" => {
          desc => "Rotation Offset",
            vr => { DS => "1-n" },
           ret => 1
    },
   "0018,1147" => {
          desc => "Field of View Shape",
            vr => { CS => "1" }
   },
   "0018,1149" => {
          desc => "Field of View Dimension(s)",
            vr => { IS => "1-2" }
   },
   "0018,1150" => {
          desc => "Exposure Time",
            vr => { IS => "1" }
   },
   "0018,1151" => {
          desc => "X-Ray Tube Current",
            vr => { IS => "1" }
   },
   "0018,1152" => {
          desc => "Exposure ",
            vr => { IS => "1" }
   },
   "0018,1153" => {
          desc => "Exposure in muAs",
            vr => { IS => "1" }
   },
   "0018,1154" => {
          desc => "Average Pulse Width",
            vr => { DS => "1" }
   },
   "0018,1155" => {
          desc => "Radiation Setting",
            vr => { CS => "1" }
   },
   "0018,1156" => {
          desc => "Rectification Type",
            vr => { CS => "1" }
   },
   "0018,115a" => {
          desc => "Radiation Mode",
            vr => { CS => "1" }
   },
   "0018,115e" => {
          desc => "Image and Fluoroscopy Area Dose Product",
            vr => { DS => "1" }
   },
   "0018,1160" => {
          desc => "Filter Type",
            vr => { SH => "1" }
   },
   "0018,1161" => {
          desc => "Type of Filters",
            vr => { LO => "1-n" }
   },
   "0018,1162" => {
          desc => "Intensifier Size",
            vr => { DS => "1" }
   },
   "0018,1164" => {
          desc => "Imager Pixel Spacing",
            vr => { DS => "2" }
   },
   "0018,1166" => {
          desc => "Grid",
            vr => { CS => "1-n" }
   },
   "0018,1170" => {
          desc => "Generator Power",
            vr => { IS => "1" }
   },
   "0018,1180" => {
          desc => "Collimator/grid Name ",
            vr => { SH => "1" }
   },
   "0018,1181" => {
          desc => "Collimator Type",
            vr => { CS => "1" }
   },
   "0018,1182" => {
          desc => "Focal Distance",
            vr => { IS => "1-2" }
   },
   "0018,1183" => {
          desc => "X Focus Center",
            vr => { DS => "1-2" }
   },
   "0018,1184" => {
          desc => "Y Focus Center",
            vr => { DS => "1-2" }
   },
   "0018,1190" => {
          desc => "Focal Spot(s)",
            vr => { DS => "1-n" }
   },
   "0018,1191" => {
          desc => "Anode Target Material",
            vr => { CS => "1" }
   },
   "0018,11a0" => {
          desc => "Body Part Thickness",
            vr => { DS => "1" }
   },
   "0018,11a2" => {
          desc => "Compression Force",
            vr => { DS => "1" }
   },
   "0018,1200" => {
          desc => "Date of Last Calibration",
            vr => { DA => "1-n" }
   },
   "0018,1201" => {
          desc => "Time of Last Calibration",
            vr => { TM => "1-n" }
   },
   "0018,1210" => {
          desc => "Convolution Kernel",
            vr => { SH => "1-n" }
   },
   "0018,1240" => {
          desc => "Upper/Lower Pixel Values",
            vr => { IS => "1-n" },
           ret => 1
    },
   "0018,1242" => {
          desc => "Actual Frame Duration",
            vr => { IS => "1" }
   },
   "0018,1243" => {
          desc => "Count Rate",
            vr => { IS => "1" }
   },
   "0018,1244" => {
          desc => "Preferred Playback Sequencing",
            vr => { US => "1" }
   },
   "0018,1250" => {
          desc => "Receive Coil Name",
            vr => { SH => "1" }
   },
   "0018,1251" => {
          desc => "Transmit Coil Name",
            vr => { SH => "1" }
   },
   "0018,1260" => {
          desc => "Plate Type",
            vr => { SH => "1" }
   },
   "0018,1261" => {
          desc => "Phosphor Type",
            vr => { LO => "1" }
   },
   "0018,1300" => {
          desc => "Scan Velocity",
            vr => { DS => "1" }
   },
   "0018,1301" => {
          desc => "Whole Body Technique",
            vr => { CS => "1-n" }
   },
   "0018,1302" => {
          desc => "Scan Length",
            vr => { IS => "1" }
   },
   "0018,1310" => {
          desc => "Acquisition Matrix",
            vr => { US => "4" }
   },
   "0018,1312" => {
          desc => "In-plane Phase Encoding Direction",
            vr => { CS => "1" }
   },
   "0018,1314" => {
          desc => "Flip Angle",
            vr => { DS => "1" }
   },
   "0018,1315" => {
          desc => "Variable Flip Angle Flag",
            vr => { CS => "1" }
   },
   "0018,1316" => {
          desc => "SAR",
            vr => { DS => "1" }
   },
   "0018,1318" => {
          desc => "dB/dt",
            vr => { DS => "1" }
   },
   "0018,1400" => {
          desc => "Acquisition Device Processing Description ",
            vr => { LO => "1" }
   },
   "0018,1401" => {
          desc => "Acquisition Device Processing Code",
            vr => { LO => "1" }
   },
   "0018,1402" => {
          desc => "Cassette Orientation",
            vr => { CS => "1" }
   },
   "0018,1403" => {
          desc => "Cassette Size",
            vr => { CS => "1" }
   },
   "0018,1404" => {
          desc => "Exposures on Plate",
            vr => { US => "1" }
   },
   "0018,1405" => {
          desc => "Relative X-Ray Exposure",
            vr => { IS => "1" }
   },
   "0018,1450" => {
          desc => "Column Angulation",
            vr => { DS => "1" }
   },
   "0018,1460" => {
          desc => "Tomo Layer Height",
            vr => { DS => "1" }
   },
   "0018,1470" => {
          desc => "Tomo Angle",
            vr => { DS => "1" }
   },
   "0018,1480" => {
          desc => "Tomo Time",
            vr => { DS => "1" }
   },
   "0018,1490" => {
          desc => "Tomo Type",
            vr => { CS => "1" }
   },
   "0018,1491" => {
          desc => "Tomo Class",
            vr => { CS => "1" }
   },
   "0018,1495" => {
          desc => "Number of Tomosynthesis Source Images",
            vr => { IS => "1" }
   },
   "0018,1500" => {
          desc => "Positioner Motion",
            vr => { CS => "1" }
   },
   "0018,1508" => {
          desc => "Positioner Type",
            vr => { CS => "1" }
   },
   "0018,1510" => {
          desc => "Positioner Primary Angle",
            vr => { DS => "1" }
   },
   "0018,1511" => {
          desc => "Positioner Secondary Angle",
            vr => { DS => "1" }
   },
   "0018,1520" => {
          desc => "Positioner Primary Angle Increment",
            vr => { DS => "1-n" }
   },
   "0018,1521" => {
          desc => "Positioner Secondary Angle Increment",
            vr => { DS => "1-n" }
   },
   "0018,1530" => {
          desc => "Detector Primary Angle",
            vr => { DS => "1" }
   },
   "0018,1531" => {
          desc => "Detector Secondary Angle",
            vr => { DS => "1" }
   },
   "0018,1600" => {
          desc => "Shutter Shape",
            vr => { CS => "1-3" }
   },
   "0018,1602" => {
          desc => "Shutter Left Vertical Edge",
            vr => { IS => "1" }
   },
   "0018,1604" => {
          desc => "Shutter Right Vertical Edge",
            vr => { IS => "1" }
   },
   "0018,1606" => {
          desc => "Shutter Upper Horizontal Edge",
            vr => { IS => "1" }
   },
   "0018,1608" => {
          desc => "Shutter Lower Horizontal Edge",
            vr => { IS => "1" }
   },
   "0018,1610" => {
          desc => "Center of Circular Shutter",
            vr => { IS => "2" }
   },
   "0018,1612" => {
          desc => "Radius of Circular Shutter",
            vr => { IS => "1" }
   },
   "0018,1620" => {
          desc => "Vertices of the Polygonal Shutter",
            vr => { IS => "2-2n" }
   },
   "0018,1622" => {
          desc => "Shutter Presentation Value",
            vr => { US => "1" }
   },
   "0018,1623" => {
          desc => "Shutter Overlay Group",
            vr => { US => "1" }
   },
   "0018,1624" => {
          desc => "Shutter Presentation Color CIELab Value",
            vr => { US => "3" }
   },
   "0018,1700" => {
          desc => "Collimator Shape",
            vr => { CS => "1-3" }
   },
   "0018,1702" => {
          desc => "Collimator Left Vertical Edge",
            vr => { IS => "1" }
   },
   "0018,1704" => {
          desc => "Collimator Right Vertical Edge",
            vr => { IS => "1" }
   },
   "0018,1706" => {
          desc => "Collimator Upper Horizontal Edge",
            vr => { IS => "1" }
   },
   "0018,1708" => {
          desc => "Collimator Lower Horizontal Edge",
            vr => { IS => "1" }
   },
   "0018,1710" => {
          desc => "Center of Circular Collimator",
            vr => { IS => "2" }
   },
   "0018,1712" => {
          desc => "Radius of Circular Collimator",
            vr => { IS => "1" }
   },
   "0018,1720" => {
          desc => "Vertices of the Polygonal Collimator",
            vr => { IS => "2-2n" }
   },
   "0018,1800" => {
          desc => "Acquisition Time Synchronized",
            vr => { CS => "1" }
   },
   "0018,1801" => {
          desc => "Time Source",
            vr => { SH => "1" }
   },
   "0018,1802" => {
          desc => "Time Distribution Protocol",
            vr => { CS => "1" }
   },
   "0018,1803" => {
          desc => "NTP Source Address",
            vr => { LO => "1" }
   },
   "0018,2001" => {
          desc => "Page Number Vector",
            vr => { IS => "1-n" }
   },
   "0018,2002" => {
          desc => "Frame Label Vector",
            vr => { SH => "1-n" }
   },
   "0018,2003" => {
          desc => "Frame Primary Angle Vector",
            vr => { DS => "1-n" }
   },
   "0018,2004" => {
          desc => "Frame Secondary Angle Vector",
            vr => { DS => "1-n" }
   },
   "0018,2005" => {
          desc => "Slice Location Vector",
            vr => { DS => "1-n" }
   },
   "0018,2006" => {
          desc => "Display Window Label Vector",
            vr => { SH => "1-n" }
   },
   "0018,2010" => {
          desc => "Nominal Scanned Pixel Spacing",
            vr => { DS => "2" }
   },
   "0018,2020" => {
          desc => "Digitizing Device Transport Direction",
            vr => { CS => "1" }
   },
   "0018,2030" => {
          desc => "Rotation of Scanned Film",
            vr => { DS => "1" }
   },
   "0018,3100" => {
          desc => "IVUS Acquisition",
            vr => { CS => "1" }
   },
   "0018,3101" => {
          desc => "IVUS Pullback Rate",
            vr => { DS => "1" }
   },
   "0018,3102" => {
          desc => "IVUS Gated Rate",
            vr => { DS => "1" }
   },
   "0018,3103" => {
          desc => "IVUS Pullback Start Frame Number",
            vr => { IS => "1" }
   },
   "0018,3104" => {
          desc => "IVUS Pullback Stop Frame Number",
            vr => { IS => "1" }
   },
   "0018,3105" => {
          desc => "Lesion Number ",
            vr => { IS => "1-n" }
   },
   "0018,4000" => {
          desc => "Acquisition Comments",
            vr => { LT => "1" },
           ret => 1
    },
   "0018,5000" => {
          desc => "Output Power",
            vr => { SH => "1-n" }
   },
   "0018,5010" => {
          desc => "Transducer Data",
            vr => { LO => "1-n" }
   },
   "0018,5012" => {
          desc => "Focus Depth",
            vr => { DS => "1" }
   },
   "0018,5020" => {
          desc => "Processing Function",
            vr => { LO => "1" }
   },
   "0018,5021" => {
          desc => "Postprocessing Function",
            vr => { LO => "1" },
           ret => 1
    },
   "0018,5022" => {
          desc => "Mechanical Index",
            vr => { DS => "1" }
   },
   "0018,5024" => {
          desc => "Bone Thermal Index",
            vr => { DS => "1" }
   },
   "0018,5026" => {
          desc => "Cranial Thermal Index",
            vr => { DS => "1" }
   },
   "0018,5027" => {
          desc => "Soft Tissue Thermal Index",
            vr => { DS => "1" }
   },
   "0018,5028" => {
          desc => "Soft Tissue-focus Thermal Index",
            vr => { DS => "1" }
   },
   "0018,5029" => {
          desc => "Soft Tissue-surface Thermal Index",
            vr => { DS => "1" }
   },
   "0018,5030" => {
          desc => "Dynamic Range",
            vr => { DS => "1" },
           ret => 1
    },
   "0018,5040" => {
          desc => "Total Gain",
            vr => { DS => "1" },
           ret => 1
    },
   "0018,5050" => {
          desc => "Depth of Scan Field",
            vr => { IS => "1" }
   },
   "0018,5100" => {
          desc => "Patient Position",
            vr => { CS => "1" }
   },
   "0018,5101" => {
          desc => "View Position",
            vr => { CS => "1" }
   },
   "0018,5104" => {
          desc => "Projection Eponymous Name Code Sequence",
            vr => { SQ => "1" }
   },
   "0018,5210" => {
          desc => "Image Transformation Matrix",
            vr => { DS => "6" },
           ret => 1
    },
   "0018,5212" => {
          desc => "Image Translation Vector",
            vr => { DS => "3" },
           ret => 1
    },
   "0018,6000" => {
          desc => "Sensitivity",
            vr => { DS => "1" }
   },
   "0018,6011" => {
          desc => "Sequence of Ultrasound Regions",
            vr => { SQ => "1" }
   },
   "0018,6012" => {
          desc => "Region Spatial Format",
            vr => { US => "1" }
   },
   "0018,6014" => {
          desc => "Region Data Type",
            vr => { US => "1" }
   },
   "0018,6016" => {
          desc => "Region Flags",
            vr => { UL => "1" }
   },
   "0018,6018" => {
          desc => "Region Location Min X0",
            vr => { UL => "1" }
   },
   "0018,601a" => {
          desc => "Region Location Min Y0",
            vr => { UL => "1" }
   },
   "0018,601c" => {
          desc => "Region Location Max X1",
            vr => { UL => "1" }
   },
   "0018,601e" => {
          desc => "Region Location Max Y1",
            vr => { UL => "1" }
   },
   "0018,6020" => {
          desc => "Reference Pixel X0",
            vr => { SL => "1" }
   },
   "0018,6022" => {
          desc => "Reference Pixel Y0",
            vr => { SL => "1" }
   },
   "0018,6024" => {
          desc => "Physical Units X Direction",
            vr => { US => "1" }
   },
   "0018,6026" => {
          desc => "Physical Units Y Direction",
            vr => { US => "1" }
   },
   "0018,6028" => {
          desc => "Reference Pixel Physical Value X",
            vr => { FD => "1" }
   },
   "0018,602a" => {
          desc => "Reference Pixel Physical Value Y",
            vr => { FD => "1" }
   },
   "0018,602c" => {
          desc => "Physical Delta X",
            vr => { FD => "1" }
   },
   "0018,602e" => {
          desc => "Physical Delta Y",
            vr => { FD => "1" }
   },
   "0018,6030" => {
          desc => "Transducer Frequency",
            vr => { UL => "1" }
   },
   "0018,6031" => {
          desc => "Transducer Type",
            vr => { CS => "1" }
   },
   "0018,6032" => {
          desc => "Pulse Repetition Frequency",
            vr => { UL => "1" }
   },
   "0018,6034" => {
          desc => "Doppler Correction Angle",
            vr => { FD => "1" }
   },
   "0018,6036" => {
          desc => "Steering Angle",
            vr => { FD => "1" }
   },
   "0018,6038" => {
          desc => "Doppler Sample Volume X Position (Retired)",
            vr => { UL => "1" },
           ret => 1
    },
   "0018,6039" => {
          desc => "Doppler Sample Volume X Position",
            vr => { SL => "1" }
   },
   "0018,603a" => {
          desc => "Doppler Sample Volume Y Position (Retired)",
            vr => { UL => "1" },
           ret => 1
    },
   "0018,603b" => {
          desc => "Doppler Sample Volume Y Position",
            vr => { SL => "1" }
   },
   "0018,603c" => {
          desc => "TMLine Position X0 (Retired)",
            vr => { UL => "1" },
           ret => 1
    },
   "0018,603d" => {
          desc => "TM-Line Position X0",
            vr => { SL => "1" }
   },
   "0018,603e" => {
          desc => "TM-Line Position Y0 (Retired)",
            vr => { UL => "1" },
           ret => 1
    },
   "0018,603f" => {
          desc => "TM-Line Position Y0",
            vr => { SL => "1" }
   },
   "0018,6040" => {
          desc => "TM-Line Position X1 (Retired)",
            vr => { UL => "1" },
           ret => 1
    },
   "0018,6041" => {
          desc => "TM-Line Position X1",
            vr => { SL => "1" }
   },
   "0018,6042" => {
          desc => "TM-Line Position Y1 (Retired)",
            vr => { UL => "1" },
           ret => 1
    },
   "0018,6043" => {
          desc => "TM-Line Position Y1",
            vr => { SL => "1" }
   },
   "0018,6044" => {
          desc => "Pixel Component Organization",
            vr => { US => "1" }
   },
   "0018,6046" => {
          desc => "Pixel Component Mask",
            vr => { UL => "1" }
   },
   "0018,6048" => {
          desc => "Pixel Component Range Start",
            vr => { UL => "1" }
   },
   "0018,604a" => {
          desc => "Pixel Component Range Stop",
            vr => { UL => "1" }
   },
   "0018,604c" => {
          desc => "Pixel Component Physical Units",
            vr => { US => "1" }
   },
   "0018,604e" => {
          desc => "Pixel Component Data Type",
            vr => { US => "1" }
   },
   "0018,6050" => {
          desc => "Number of Table Break Points",
            vr => { UL => "1" }
   },
   "0018,6052" => {
          desc => "Table of X Break Points",
            vr => { UL => "1-n" }
   },
   "0018,6054" => {
          desc => "Table of Y Break Points",
            vr => { FD => "1-n" }
   },
   "0018,6056" => {
          desc => "Number of Table Entries",
            vr => { UL => "1" }
   },
   "0018,6058" => {
          desc => "Table of Pixel Values",
            vr => { UL => "1-n" }
   },
   "0018,605a" => {
          desc => "Table of Parameter Values",
            vr => { FL => "1-n" }
   },
   "0018,6060" => {
          desc => "R Wave Time Vector",
            vr => { FL => "1-n" }
   },
   "0018,7000" => {
          desc => "Detector Conditions Nominal Flag ",
            vr => { CS => "1" }
   },
   "0018,7001" => {
          desc => "Detector Temperature",
            vr => { DS => "1" }
   },
   "0018,7004" => {
          desc => "Detector Type",
            vr => { CS => "1" }
   },
   "0018,7005" => {
          desc => "Detector Configuration",
            vr => { CS => "1" }
   },
   "0018,7006" => {
          desc => "Detector Description",
            vr => { LT => "1" }
   },
   "0018,7008" => {
          desc => "Detector Mode",
            vr => { LT => "1" }
   },
   "0018,700a" => {
          desc => "Detector ID",
            vr => { SH => "1" }
   },
   "0018,700c" => {
          desc => "Date of Last Detector Calibration ",
            vr => { DA => "1" }
   },
   "0018,700e" => {
          desc => "Time of Last Detector Calibration",
            vr => { TM => "1" }
   },
   "0018,7010" => {
          desc => "Exposures on Detector Since Last Calibration ",
            vr => { IS => "1" }
   },
   "0018,7011" => {
          desc => "Exposures on Detector Since Manufactured ",
            vr => { IS => "1" }
   },
   "0018,7012" => {
          desc => "Detector Time Since Last Exposure ",
            vr => { DS => "1" }
   },
   "0018,7014" => {
          desc => "Detector Active Time ",
            vr => { DS => "1" }
   },
   "0018,7016" => {
          desc => "Detector Activation Offset From Exposure",
            vr => { DS => "1" }
   },
   "0018,701a" => {
          desc => "Detector Binning ",
            vr => { DS => "2" }
   },
   "0018,7020" => {
          desc => "Detector Element Physical Size",
            vr => { DS => "2" }
   },
   "0018,7022" => {
          desc => "Detector Element Spacing",
            vr => { DS => "2" }
   },
   "0018,7024" => {
          desc => "Detector Active Shape",
            vr => { CS => "1" }
   },
   "0018,7026" => {
          desc => "Detector Active Dimension(s)",
            vr => { DS => "1-2" }
   },
   "0018,7028" => {
          desc => "Detector Active Origin",
            vr => { DS => "2" }
   },
   "0018,702a" => {
          desc => "Detector Manufacturer Name",
            vr => { LO => "1" }
   },
   "0018,702b" => {
          desc => "Detector Manufacturer's Model Name",
            vr => { LO => "1" }
   },
   "0018,7030" => {
          desc => "Field of View Origin",
            vr => { DS => "2" }
   },
   "0018,7032" => {
          desc => "Field of View Rotation",
            vr => { DS => "1" }
   },
   "0018,7034" => {
          desc => "Field of View Horizontal Flip",
            vr => { CS => "1" }
   },
   "0018,7040" => {
          desc => "Grid Absorbing Material",
            vr => { LT => "1" }
   },
   "0018,7041" => {
          desc => "Grid Spacing Material",
            vr => { LT => "1" }
   },
   "0018,7042" => {
          desc => "Grid Thickness",
            vr => { DS => "1" }
   },
   "0018,7044" => {
          desc => "Grid Pitch",
            vr => { DS => "1" }
   },
   "0018,7046" => {
          desc => "Grid Aspect Ratio",
            vr => { IS => "2" }
   },
   "0018,7048" => {
          desc => "Grid Period",
            vr => { DS => "1" }
   },
   "0018,704c" => {
          desc => "Grid Focal Distance",
            vr => { DS => "1" }
   },
   "0018,7050" => {
          desc => "Filter Material",
            vr => { CS => "1-n" }
   },
   "0018,7052" => {
          desc => "Filter Thickness Minimum",
            vr => { DS => "1-n" }
   },
   "0018,7054" => {
          desc => "Filter Thickness Maximum",
            vr => { DS => "1-n" }
   },
   "0018,7056" => {
          desc => "Filter Beam Path Length Minimum",
            vr => { FL => "1-n" }
   },
   "0018,7058" => {
          desc => "Filter Beam Path Length Maximum",
            vr => { FL => "1-n" }
   },
   "0018,7060" => {
          desc => "Exposure Control Mode",
            vr => { CS => "1" }
   },
   "0018,7062" => {
          desc => "Exposure Control Mode Description",
            vr => { LT => "1" }
   },
   "0018,7064" => {
          desc => "Exposure Status",
            vr => { CS => "1" }
   },
   "0018,7065" => {
          desc => "Phototimer Setting",
            vr => { DS => "1" }
   },
   "0018,8150" => {
          desc => "Exposure Time in ?S",
            vr => { DS => "1" }
   },
   "0018,8151" => {
          desc => "X-Ray Tube Current in ?A",
            vr => { DS => "1" }
   },
   "0018,9004" => {
          desc => "Content Qualification",
            vr => { CS => "1" }
   },
   "0018,9005" => {
          desc => "Pulse Sequence Name",
            vr => { SH => "1" }
   },
   "0018,9006" => {
          desc => "MR Imaging Modifier Sequence",
            vr => { SQ => "1" }
   },
   "0018,9008" => {
          desc => "Echo Pulse Sequence",
            vr => { CS => "1" }
   },
   "0018,9009" => {
          desc => "Inversion Recovery",
            vr => { CS => "1" }
   },
   "0018,9010" => {
          desc => "Flow Compensation",
            vr => { CS => "1" }
   },
   "0018,9011" => {
          desc => "Multiple Spin Echo",
            vr => { CS => "1" }
   },
   "0018,9012" => {
          desc => "Multi-planar Excitation",
            vr => { CS => "1" }
   },
   "0018,9014" => {
          desc => "Phase Contrast",
            vr => { CS => "1" }
   },
   "0018,9015" => {
          desc => "Time of Flight Contrast",
            vr => { CS => "1" }
   },
   "0018,9016" => {
          desc => "Spoiling",
            vr => { CS => "1" }
   },
   "0018,9017" => {
          desc => "Steady State Pulse Sequence",
            vr => { CS => "1" }
   },
   "0018,9018" => {
          desc => "Echo Planar Pulse Sequence",
            vr => { CS => "1" }
   },
   "0018,9019" => {
          desc => "Tag Angle First Axis",
            vr => { FD => "1" }
   },
   "0018,9020" => {
          desc => "Magnetization Transfer",
            vr => { CS => "1" }
   },
   "0018,9021" => {
          desc => "T2 Preparation",
            vr => { CS => "1" }
   },
   "0018,9022" => {
          desc => "Blood Signal Nulling",
            vr => { CS => "1" }
   },
   "0018,9024" => {
          desc => "Saturation Recovery",
            vr => { CS => "1" }
   },
   "0018,9025" => {
          desc => "Spectrally Selected Suppression",
            vr => { CS => "1" }
   },
   "0018,9026" => {
          desc => "Spectrally Selected Excitation",
            vr => { CS => "1" }
   },
   "0018,9027" => {
          desc => "Spatial Pre-saturation",
            vr => { CS => "1" }
   },
   "0018,9028" => {
          desc => "Tagging",
            vr => { CS => "1" }
   },
   "0018,9029" => {
          desc => "Oversampling Phase",
            vr => { CS => "1" }
   },
   "0018,9030" => {
          desc => "Tag Spacing First Dimension",
            vr => { FD => "1" }
   },
   "0018,9032" => {
          desc => "Geometry of k-Space Traversal",
            vr => { CS => "1" }
   },
   "0018,9033" => {
          desc => "Segmented k-Space Traversal",
            vr => { CS => "1" }
   },
   "0018,9034" => {
          desc => "Rectilinear Phase Encode Reordering",
            vr => { CS => "1" }
   },
   "0018,9035" => {
          desc => "Tag Thickness",
            vr => { FD => "1" }
   },
   "0018,9036" => {
          desc => "Partial Fourier Direction",
            vr => { CS => "1" }
   },
   "0018,9037" => {
          desc => "Cardiac Synchronization Technique",
            vr => { CS => "1" }
   },
   "0018,9041" => {
          desc => "Receive Coil Manufacturer Name",
            vr => { LO => "1" }
   },
   "0018,9042" => {
          desc => "MR Receive Coil Sequence",
            vr => { SQ => "1" }
   },
   "0018,9043" => {
          desc => "Receive Coil Type ",
            vr => { CS => "1" }
   },
   "0018,9044" => {
          desc => "Quadrature Receive Coil ",
            vr => { CS => "1" }
   },
   "0018,9045" => {
          desc => "Multi-Coil Definition Sequence",
            vr => { SQ => "1" }
   },
   "0018,9046" => {
          desc => "Multi-Coil Configuration ",
            vr => { LO => "1" }
   },
   "0018,9047" => {
          desc => "Multi-Coil Element Name",
            vr => { SH => "1" }
   },
   "0018,9048" => {
          desc => "Multi-Coil Element Used",
            vr => { CS => "1" }
   },
   "0018,9049" => {
          desc => "MR Transmit Coil Sequence",
            vr => { SQ => "1" }
   },
   "0018,9050" => {
          desc => "Transmit Coil Manufacturer Name",
            vr => { LO => "1" }
   },
   "0018,9051" => {
          desc => "Transmit Coil Type",
            vr => { CS => "1" }
   },
   "0018,9052" => {
          desc => "Spectral Width",
            vr => { FD => "1-2" }
   },
   "0018,9053" => {
          desc => "Chemical Shift Reference",
            vr => { FD => "1-2" }
   },
   "0018,9054" => {
          desc => "Volume Localization Technique",
            vr => { CS => "1" }
   },
   "0018,9058" => {
          desc => "MR Acquisition Frequency Encoding Steps",
            vr => { US => "1" }
   },
   "0018,9059" => {
          desc => "De-coupling",
            vr => { CS => "1" }
   },
   "0018,9060" => {
          desc => "De-coupled Nucleus",
            vr => { CS => "1-2" }
   },
   "0018,9061" => {
          desc => "De-coupling Frequency",
            vr => { FD => "1-2" }
   },
   "0018,9062" => {
          desc => "De-coupling Method",
            vr => { CS => "1" }
   },
   "0018,9063" => {
          desc => "De-coupling Chemical Shift Reference",
            vr => { FD => "1-2" }
   },
   "0018,9064" => {
          desc => "k-space Filtering",
            vr => { CS => "1" }
   },
   "0018,9065" => {
          desc => "Time Domain Filtering",
            vr => { CS => "1-2" }
   },
   "0018,9066" => {
          desc => "Number of Zero fills",
            vr => { US => "1-2" }
   },
   "0018,9067" => {
          desc => "Baseline Correction",
            vr => { CS => "1" }
   },
   "0018,9069" => {
          desc => "Parallel Reduction Factor In-plane",
            vr => { FD => "1" }
   },
   "0018,9070" => {
          desc => "Cardiac R-R Interval Specified",
            vr => { FD => "1" }
   },
   "0018,9073" => {
          desc => "Acquisition Duration",
            vr => { FD => "1" }
   },
   "0018,9074" => {
          desc => "Frame Acquisition DateTime",
            vr => { DT => "1" }
   },
   "0018,9075" => {
          desc => "Diffusion Directionality",
            vr => { CS => "1" }
   },
   "0018,9076" => {
          desc => "Diffusion Gradient Direction Sequence",
            vr => { SQ => "1" }
   },
   "0018,9077" => {
          desc => "Parallel Acquisition",
            vr => { CS => "1" }
   },
   "0018,9078" => {
          desc => "Parallel Acquisition Technique",
            vr => { CS => "1" }
   },
   "0018,9079" => {
          desc => "Inversion Times",
            vr => { FD => "1-n" }
   },
   "0018,9080" => {
          desc => "Metabolite Map Description",
            vr => { ST => "1" }
   },
   "0018,9081" => {
          desc => "Partial Fourier",
            vr => { CS => "1" }
   },
   "0018,9082" => {
          desc => "Effective Echo Time",
            vr => { FD => "1" }
   },
   "0018,9083" => {
          desc => "Metabolite Map Code Sequence",
            vr => { SQ => "1" }
   },
   "0018,9084" => {
          desc => "Chemical Shift Sequence",
            vr => { SQ => "1" }
   },
   "0018,9085" => {
          desc => "Cardiac Signal Source",
            vr => { CS => "1" }
   },
   "0018,9087" => {
          desc => "Diffusion b-value",
            vr => { FD => "1" }
   },
   "0018,9089" => {
          desc => "Diffusion Gradient Orientation",
            vr => { FD => "3" }
   },
   "0018,9090" => {
          desc => "Velocity Encoding Direction",
            vr => { FD => "3" }
   },
   "0018,9091" => {
          desc => "Velocity Encoding Minimum Value",
            vr => { FD => "1" }
   },
   "0018,9093" => {
          desc => "Number of k-Space Trajectories",
            vr => { US => "1" }
   },
   "0018,9094" => {
          desc => "Coverage of k-Space",
            vr => { CS => "1" }
   },
   "0018,9095" => {
          desc => "Spectroscopy Acquisition Phase Rows",
            vr => { UL => "1" }
   },
   "0018,9096" => {
          desc => "Parallel Reduction Factor In-plane (Retired)",
            vr => { FD => "1" },
           ret => 1
    },
   "0018,9098" => {
          desc => "Transmitter Frequency",
            vr => { FD => "1-2" }
   },
   "0018,9100" => {
          desc => "Resonant Nucleus",
            vr => { CS => "1-2" }
   },
   "0018,9101" => {
          desc => "Frequency Correction",
            vr => { CS => "1" }
   },
   "0018,9103" => {
          desc => "MR Spectroscopy FOV/Geometry Sequence",
            vr => { SQ => "1" }
   },
   "0018,9104" => {
          desc => "Slab Thickness",
            vr => { FD => "1" }
   },
   "0018,9105" => {
          desc => "Slab Orientation",
            vr => { FD => "3" }
   },
   "0018,9106" => {
          desc => "Mid Slab Position",
            vr => { FD => "3" }
   },
   "0018,9107" => {
          desc => "MR Spatial Saturation Sequence",
            vr => { SQ => "1" }
   },
   "0018,9112" => {
          desc => "MR Timing and Related Parameters Sequence",
            vr => { SQ => "1" }
   },
   "0018,9114" => {
          desc => "MR Echo Sequence",
            vr => { SQ => "1" }
   },
   "0018,9115" => {
          desc => "MR Modifier Sequence",
            vr => { SQ => "1" }
   },
   "0018,9117" => {
          desc => "MR Diffusion Sequence",
            vr => { SQ => "1" }
   },
   "0018,9118" => {
          desc => "Cardiac Synchronization Sequence",
            vr => { SQ => "1" }
   },
   "0018,9119" => {
          desc => "MR Averages Sequence",
            vr => { SQ => "1" }
   },
   "0018,9125" => {
          desc => "MR FOV/Geometry Sequence",
            vr => { SQ => "1" }
   },
   "0018,9126" => {
          desc => "Volume Localization Sequence",
            vr => { SQ => "1" }
   },
   "0018,9127" => {
          desc => "Spectroscopy Acquisition Data Columns",
            vr => { UL => "1" }
   },
   "0018,9147" => {
          desc => "Diffusion Anisotropy Type",
            vr => { CS => "1" }
   },
   "0018,9151" => {
          desc => "Frame Reference DateTime",
            vr => { DT => "1" }
   },
   "0018,9152" => {
          desc => "MR Metabolite Map Sequence",
            vr => { SQ => "1" }
   },
   "0018,9155" => {
          desc => "Parallel Reduction Factor out-of-plane",
            vr => { FD => "1" }
   },
   "0018,9159" => {
          desc => "Spectroscopy Acquisition Out-of-plane Phase Steps",
            vr => { UL => "1" }
   },
   "0018,9166" => {
          desc => "Bulk Motion Status",
            vr => { CS => "1" },
           ret => 1
    },
   "0018,9168" => {
          desc => "Parallel Reduction Factor Second In-plane",
            vr => { FD => "1" }
   },
   "0018,9169" => {
          desc => "Cardiac Beat Rejection Technique",
            vr => { CS => "1" }
   },
   "0018,9170" => {
          desc => "Respiratory Motion Compensation Technique",
            vr => { CS => "1" }
   },
   "0018,9171" => {
          desc => "Respiratory Signal Source",
            vr => { CS => "1" }
   },
   "0018,9172" => {
          desc => "Bulk Motion Compensation Technique",
            vr => { CS => "1" }
   },
   "0018,9173" => {
          desc => "Bulk Motion Signal Source",
            vr => { CS => "1" }
   },
   "0018,9174" => {
          desc => "Applicable Safety Standard Agency",
            vr => { CS => "1" }
   },
   "0018,9175" => {
          desc => "Applicable Safety Standard Description",
            vr => { LO => "1" }
   },
   "0018,9176" => {
          desc => "Operating Mode Sequence",
            vr => { SQ => "1" }
   },
   "0018,9177" => {
          desc => "Operating Mode Type",
            vr => { CS => "1" }
   },
   "0018,9178" => {
          desc => "Operating Mode",
            vr => { CS => "1" }
   },
   "0018,9179" => {
          desc => "Specific Absorption Rate Definition",
            vr => { CS => "1" }
   },
   "0018,9180" => {
          desc => "Gradient Output Type",
            vr => { CS => "1" }
   },
   "0018,9181" => {
          desc => "Specific Absorption Rate Value",
            vr => { FD => "1" }
   },
   "0018,9182" => {
          desc => "Gradient Output",
            vr => { FD => "1" }
   },
   "0018,9183" => {
          desc => "Flow Compensation Direction",
            vr => { CS => "1" }
   },
   "0018,9184" => {
          desc => "Tagging Delay",
            vr => { FD => "1" }
   },
   "0018,9185" => {
          desc => "Respiratory Motion Compensation Technique Description",
            vr => { ST => "1" }
   },
   "0018,9186" => {
          desc => "Respiratory Signal Source ID",
            vr => { SH => "1" }
   },
   "0018,9195" => {
          desc => "Chemical Shift Minimum Integration Limit in Hz",
            vr => { FD => "1" },
           ret => 1
    },
   "0018,9196" => {
          desc => "Chemical Shift Maximum Integration Limit in Hz",
            vr => { FD => "1" },
           ret => 1
    },
   "0018,9197" => {
          desc => "MR Velocity Encoding Sequence",
            vr => { SQ => "1" }
   },
   "0018,9198" => {
          desc => "First Order Phase Correction",
            vr => { CS => "1" }
   },
   "0018,9199" => {
          desc => "Water Referenced Phase Correction",
            vr => { CS => "1" }
   },
   "0018,9200" => {
          desc => "MR Spectroscopy Acquisition Type",
            vr => { CS => "1" }
   },
   "0018,9214" => {
          desc => "Respiratory Cycle Position",
            vr => { CS => "1" }
   },
   "0018,9217" => {
          desc => "Velocity Encoding Maximum Value",
            vr => { FD => "1" }
   },
   "0018,9218" => {
          desc => "Tag Spacing Second Dimension",
            vr => { FD => "1" }
   },
   "0018,9219" => {
          desc => "Tag Angle Second Axis",
            vr => { SS => "1" }
   },
   "0018,9220" => {
          desc => "Frame Acquisition Duration",
            vr => { FD => "1" }
   },
   "0018,9226" => {
          desc => "MR Image Frame Type Sequence",
            vr => { SQ => "1" }
   },
   "0018,9227" => {
          desc => "MR Spectroscopy Frame Type Sequence",
            vr => { SQ => "1" }
   },
   "0018,9231" => {
          desc => "MR Acquisition Phase Encoding Steps in-plane",
            vr => { US => "1" }
   },
   "0018,9232" => {
          desc => "MR Acquisition Phase Encoding Steps out-of-plane",
            vr => { US => "1" }
   },
   "0018,9234" => {
          desc => "Spectroscopy Acquisition Phase Columns",
            vr => { UL => "1" }
   },
   "0018,9236" => {
          desc => "Cardiac Cycle Position",
            vr => { CS => "1" }
   },
   "0018,9239" => {
          desc => "Specific Absorption Rate Sequence",
            vr => { SQ => "1" }
   },
   "0018,9240" => {
          desc => "RF Echo Train Length",
            vr => { US => "1" }
   },
   "0018,9241" => {
          desc => "Gradient Echo Train Length",
            vr => { US => "1" }
   },
   "0018,9295" => {
          desc => "Chemical Shift Minimum Integration Limit in ppm",
            vr => { FD => "1" }
   },
   "0018,9296" => {
          desc => "Chemical Shift Maximum Integration Limit in ppm",
            vr => { FD => "1" }
   },
   "0018,9301" => {
          desc => "CT Acquisition Type Sequence",
            vr => { SQ => "1" }
   },
   "0018,9302" => {
          desc => "Acquisition Type",
            vr => { CS => "1" }
   },
   "0018,9303" => {
          desc => "Tube Angle",
            vr => { FD => "1" }
   },
   "0018,9304" => {
          desc => "CT Acquisition Details Sequence",
            vr => { SQ => "1" }
   },
   "0018,9305" => {
          desc => "Revolution Time",
            vr => { FD => "1" }
   },
   "0018,9306" => {
          desc => "Single Collimation Width",
            vr => { FD => "1" }
   },
   "0018,9307" => {
          desc => "Total Collimation Width",
            vr => { FD => "1" }
   },
   "0018,9308" => {
          desc => "CT Table Dynamics Sequence",
            vr => { SQ => "1" }
   },
   "0018,9309" => {
          desc => "Table Speed",
            vr => { FD => "1" }
   },
   "0018,9310" => {
          desc => "Table Feed per Rotation",
            vr => { FD => "1" }
   },
   "0018,9311" => {
          desc => "Spiral Pitch Factor",
            vr => { FD => "1" }
   },
   "0018,9312" => {
          desc => "CT Geometry Sequence",
            vr => { SQ => "1" }
   },
   "0018,9313" => {
          desc => "Data Collection Center (Patient)",
            vr => { FD => "3" }
   },
   "0018,9314" => {
          desc => "CT Reconstruction Sequence",
            vr => { SQ => "1" }
   },
   "0018,9315" => {
          desc => "Reconstruction Algorithm",
            vr => { CS => "1" }
   },
   "0018,9316" => {
          desc => "Convolution Kernel Group",
            vr => { CS => "1" }
   },
   "0018,9317" => {
          desc => "Reconstruction Field of View",
            vr => { FD => "2" }
   },
   "0018,9318" => {
          desc => "Reconstruction Target Center (Patient)",
            vr => { FD => "3" }
   },
   "0018,9319" => {
          desc => "Reconstruction Angle",
            vr => { FD => "1" }
   },
   "0018,9320" => {
          desc => "Image Filter",
            vr => { SH => "1" }
   },
   "0018,9321" => {
          desc => "CT Exposure Sequence",
            vr => { SQ => "1" }
   },
   "0018,9322" => {
          desc => "Reconstruction Pixel Spacing ",
            vr => { FD => "2" }
   },
   "0018,9323" => {
          desc => "Exposure Modulation Type",
            vr => { CS => "1" }
   },
   "0018,9324" => {
          desc => "Estimated Dose Saving",
            vr => { FD => "1" }
   },
   "0018,9325" => {
          desc => "CT X-Ray Details Sequence",
            vr => { SQ => "1" }
   },
   "0018,9326" => {
          desc => "CT Position Sequence",
            vr => { SQ => "1" }
   },
   "0018,9327" => {
          desc => "Table Position",
            vr => { FD => "1" }
   },
   "0018,9328" => {
          desc => "Exposure Time in ms",
            vr => { FD => "1" }
   },
   "0018,9329" => {
          desc => "CT Image Frame Type Sequence",
            vr => { SQ => "1" }
   },
   "0018,9330" => {
          desc => "X-Ray Tube Current in mA",
            vr => { FD => "1" }
   },
   "0018,9332" => {
          desc => "Exposure in mAs",
            vr => { FD => "1" }
   },
   "0018,9333" => {
          desc => "Constant Volume Flag ",
            vr => { CS => "1" }
   },
   "0018,9334" => {
          desc => "Fluoroscopy Flag",
            vr => { CS => "1" }
   },
   "0018,9335" => {
          desc => "Distance Source to Data Collection Center",
            vr => { FD => "1" }
   },
   "0018,9337" => {
          desc => "Contrast/Bolus Agent Number",
            vr => { US => "1" }
   },
   "0018,9338" => {
          desc => "Contrast/Bolus Ingredient Code Sequence",
            vr => { SQ => "1" }
   },
   "0018,9340" => {
          desc => "Contrast Administration Profile Sequence",
            vr => { SQ => "1" }
   },
   "0018,9341" => {
          desc => "Contrast/Bolus Usage Sequence",
            vr => { SQ => "1" }
   },
   "0018,9342" => {
          desc => "Contrast/Bolus Agent Administered",
            vr => { CS => "1" }
   },
   "0018,9343" => {
          desc => "Contrast/Bolus Agent Detected",
            vr => { CS => "1" }
   },
   "0018,9344" => {
          desc => "Contrast/Bolus Agent Phase",
            vr => { CS => "1" }
   },
   "0018,9345" => {
          desc => "CTDIvol",
            vr => { FD => "1" }
   },
   "0018,9346" => {
          desc => "CTDI Phantom Type Code Sequence",
            vr => { SQ => "1" }
   },
   "0018,9351" => {
          desc => "Calcium Scoring Mass Factor Patient",
            vr => { FL => "1" }
   },
   "0018,9352" => {
          desc => "Calcium Scoring Mass Factor Device",
            vr => { FL => "3" }
   },
   "0018,9353" => {
          desc => "Energy Weighting Factor",
            vr => { FL => "1" }
   },
   "0018,9360" => {
          desc => "CT Additional X-Ray Source Sequence",
            vr => { SQ => "1" }
   },
   "0018,9401" => {
          desc => "Projection Pixel Calibration Sequence",
            vr => { SQ => "1" }
   },
   "0018,9402" => {
          desc => "Distance Source to Isocenter",
            vr => { FL => "1" }
   },
   "0018,9403" => {
          desc => "Distance Object to Table Top",
            vr => { FL => "1" }
   },
   "0018,9404" => {
          desc => "Object Pixel Spacing in Center of Beam",
            vr => { FL => "2" }
   },
   "0018,9405" => {
          desc => "Positioner Position Sequence",
            vr => { SQ => "1" }
   },
   "0018,9406" => {
          desc => "Table Position Sequence",
            vr => { SQ => "1" }
   },
   "0018,9407" => {
          desc => "Collimator Shape Sequence",
            vr => { SQ => "1" }
   },
   "0018,9412" => {
          desc => "XA/XRF Frame Characteristics Sequence",
            vr => { SQ => "1" }
   },
   "0018,9417" => {
          desc => "Frame Acquisition Sequence",
            vr => { SQ => "1" }
   },
   "0018,9420" => {
          desc => "X-Ray Receptor Type",
            vr => { CS => "1" }
   },
   "0018,9423" => {
          desc => "Acquisition Protocol Name",
            vr => { LO => "1" }
   },
   "0018,9424" => {
          desc => "Acquisition Protocol Description",
            vr => { LT => "1" }
   },
   "0018,9425" => {
          desc => "Contrast/Bolus Ingredient Opaque",
            vr => { CS => "1" }
   },
   "0018,9426" => {
          desc => "Distance Receptor Plane to Detector Housing",
            vr => { FL => "1" }
   },
   "0018,9427" => {
          desc => "Intensifier Active Shape",
            vr => { CS => "1" }
   },
   "0018,9428" => {
          desc => "Intensifier Active Dimension(s)",
            vr => { FL => "1-2" }
   },
   "0018,9429" => {
          desc => "Physical Detector Size",
            vr => { FL => "2" }
   },
   "0018,9430" => {
          desc => "Position of Isocenter Projection",
            vr => { US => "2" }
   },
   "0018,9432" => {
          desc => "Field of View Sequence",
            vr => { SQ => "1" }
   },
   "0018,9433" => {
          desc => "Field of View Description",
            vr => { LO => "1" }
   },
   "0018,9434" => {
          desc => "Exposure Control Sensing Regions Sequence",
            vr => { SQ => "1" }
   },
   "0018,9435" => {
          desc => "Exposure Control Sensing Region Shape",
            vr => { CS => "1" }
   },
   "0018,9436" => {
          desc => "Exposure Control Sensing Region Left Vertical Edge",
            vr => { SS => "1" }
   },
   "0018,9437" => {
          desc => "Exposure Control Sensing Region Right Vertical Edge",
            vr => { SS => "1" }
   },
   "0018,9438" => {
          desc => "Exposure Control Sensing Region Upper Horizontal Edge",
            vr => { SS => "1" }
   },
   "0018,9439" => {
          desc => "Exposure Control Sensing Region Lower Horizontal Edge",
            vr => { SS => "1" }
   },
   "0018,9440" => {
          desc => "Center of Circular Exposure Control Sensing Region",
            vr => { SS => "2" }
   },
   "0018,9441" => {
          desc => "Radius of Circular Exposure Control Sensing Region",
            vr => { US => "1" }
   },
   "0018,9442" => {
          desc => "Vertices of the Polygonal Exposure Control Sensing Region",
            vr => { SS => "2-n" }
   },
   "0018,9445" => {
          desc => "",
            vr => {  },
           ret => 1
    },
   "0018,9447" => {
          desc => "Column Angulation (Patient)",
            vr => { FL => "1" }
   },
   "0018,9449" => {
          desc => "Beam Angle",
            vr => { FL => "1" }
   },
   "0018,9451" => {
          desc => "Frame Detector Parameters Sequence",
            vr => { SQ => "1" }
   },
   "0018,9452" => {
          desc => "Calculated Anatomy Thickness",
            vr => { FL => "1" }
   },
   "0018,9455" => {
          desc => "Calibration Sequence",
            vr => { SQ => "1" }
   },
   "0018,9456" => {
          desc => "Object Thickness Sequence",
            vr => { SQ => "1" }
   },
   "0018,9457" => {
          desc => "Plane Identification",
            vr => { CS => "1" }
   },
   "0018,9461" => {
          desc => "Field of View Dimension(s) in Float",
            vr => { FL => "1-2" }
   },
   "0018,9462" => {
          desc => "Isocenter Reference System Sequence",
            vr => { SQ => "1" }
   },
   "0018,9463" => {
          desc => "Positioner Isocenter Primary Angle",
            vr => { FL => "1" }
   },
   "0018,9464" => {
          desc => "Positioner Isocenter Secondary Angle",
            vr => { FL => "1" }
   },
   "0018,9465" => {
          desc => "Positioner Isocenter Detector Rotation Angle",
            vr => { FL => "1" }
   },
   "0018,9466" => {
          desc => "Table X Position to Isocenter",
            vr => { FL => "1" }
   },
   "0018,9467" => {
          desc => "Table Y Position to Isocenter",
            vr => { FL => "1" }
   },
   "0018,9468" => {
          desc => "Table Z Position to Isocenter",
            vr => { FL => "1" }
   },
   "0018,9469" => {
          desc => "Table Horizontal Rotation Angle",
            vr => { FL => "1" }
   },
   "0018,9470" => {
          desc => "Table Head Tilt Angle",
            vr => { FL => "1" }
   },
   "0018,9471" => {
          desc => "Table Cradle Tilt Angle",
            vr => { FL => "1" }
   },
   "0018,9472" => {
          desc => "Frame Display Shutter Sequence",
            vr => { SQ => "1" }
   },
   "0018,9473" => {
          desc => "Acquired Image Area Dose Product",
            vr => { FL => "1" }
   },
   "0018,9474" => {
          desc => "C-arm Positioner Tabletop Relationship",
            vr => { CS => "1" }
   },
   "0018,9476" => {
          desc => "X-Ray Geometry Sequence",
            vr => { SQ => "1" }
   },
   "0018,9477" => {
          desc => "Irradiation Event Identification Sequence",
            vr => { SQ => "1" }
   },
   "0018,9504" => {
          desc => "X-Ray 3D Frame Type Sequence",
            vr => { SQ => "1" }
   },
   "0018,9506" => {
          desc => "Contributing Sources Sequence",
            vr => { SQ => "1" }
   },
   "0018,9507" => {
          desc => "X-Ray 3D Acquisition Sequence",
            vr => { SQ => "1" }
   },
   "0018,9508" => {
          desc => "Primary Positioner Scan Arc",
            vr => { FL => "1" }
   },
   "0018,9509" => {
          desc => "Secondary Positioner Scan Arc",
            vr => { FL => "1" }
   },
   "0018,9510" => {
          desc => "Primary Positioner Scan Start Angle",
            vr => { FL => "1" }
   },
   "0018,9511" => {
          desc => "Secondary Positioner Scan Start Angle",
            vr => { FL => "1" }
   },
   "0018,9514" => {
          desc => "Primary Positioner Increment",
            vr => { FL => "1" }
   },
   "0018,9515" => {
          desc => "Secondary Positioner Increment",
            vr => { FL => "1" }
   },
   "0018,9516" => {
          desc => "Start Acquisition DateTime",
            vr => { DT => "1" }
   },
   "0018,9517" => {
          desc => "End Acquisition DateTime",
            vr => { DT => "1" }
   },
   "0018,9524" => {
          desc => "Application Name",
            vr => { LO => "1" }
   },
   "0018,9525" => {
          desc => "Application Version",
            vr => { LO => "1" }
   },
   "0018,9526" => {
          desc => "Application Manufacturer",
            vr => { LO => "1" }
   },
   "0018,9527" => {
          desc => "Algorithm Type",
            vr => { CS => "1" }
   },
   "0018,9528" => {
          desc => "Algorithm Description",
            vr => { LO => "1" }
   },
   "0018,9530" => {
          desc => "X-Ray 3D Reconstruction Sequence",
            vr => { SQ => "1" }
   },
   "0018,9531" => {
          desc => "Reconstruction Description",
            vr => { LO => "1" }
   },
   "0018,9538" => {
          desc => "Per Projection Acquisition Sequence",
            vr => { SQ => "1" }
   },
   "0018,9601" => {
          desc => "Diffusion b-matrix Sequence",
            vr => { SQ => "1" }
   },
   "0018,9602" => {
          desc => "Diffusion b-value XX",
            vr => { FD => "1" }
   },
   "0018,9603" => {
          desc => "Diffusion b-value XY",
            vr => { FD => "1" }
   },
   "0018,9604" => {
          desc => "Diffusion b-value XZ",
            vr => { FD => "1" }
   },
   "0018,9605" => {
          desc => "Diffusion b-value YY",
            vr => { FD => "1" }
   },
   "0018,9606" => {
          desc => "Diffusion b-value YZ",
            vr => { FD => "1" }
   },
   "0018,9607" => {
          desc => "Diffusion b-value ZZ",
            vr => { FD => "1" }
   },
   "0018,9701" => {
          desc => "Decay Correction DateTime",
            vr => { DT => "1" }
   },
   "0018,9715" => {
          desc => "Start Density Threshold",
            vr => { FD => "1" }
   },
   "0018,9716" => {
          desc => "Start Relative Density Difference Threshold",
            vr => { FD => "1" }
   },
   "0018,9717" => {
          desc => "Start Cardiac Trigger Count Threshold",
            vr => { FD => "1" }
   },
   "0018,9718" => {
          desc => "Start Respiratory Trigger Count Threshold",
            vr => { FD => "1" }
   },
   "0018,9719" => {
          desc => "Termination Counts Threshold",
            vr => { FD => "1" }
   },
   "0018,9720" => {
          desc => "Termination Density Threshold",
            vr => { FD => "1" }
   },
   "0018,9721" => {
          desc => "Termination Relative Density Threshold",
            vr => { FD => "1" }
   },
   "0018,9722" => {
          desc => "Termination Time Threshold",
            vr => { FD => "1" }
   },
   "0018,9723" => {
          desc => "Termination Cardiac Trigger Count Threshold",
            vr => { FD => "1" }
   },
   "0018,9724" => {
          desc => "Termination Respiratory Trigger Count Threshold",
            vr => { FD => "1" }
   },
   "0018,9725" => {
          desc => "Detector Geometry",
            vr => { CS => "1" }
   },
   "0018,9726" => {
          desc => "Transverse Detector Separation",
            vr => { FD => "1" }
   },
   "0018,9727" => {
          desc => "Axial Detector Dimension",
            vr => { FD => "1" }
   },
   "0018,9729" => {
          desc => "Radiopharmaceutical Agent Number",
            vr => { US => "1" }
   },
   "0018,9732" => {
          desc => "PET Frame Acquisition Sequence",
            vr => { SQ => "1" }
   },
   "0018,9733" => {
          desc => "PET Detector Motion Details Sequence",
            vr => { SQ => "1" }
   },
   "0018,9734" => {
          desc => "PET Table Dynamics Sequence",
            vr => { SQ => "1" }
   },
   "0018,9735" => {
          desc => "PET Position Sequence",
            vr => { SQ => "1" }
   },
   "0018,9736" => {
          desc => "PET Frame Correction Factors Sequence",
            vr => { SQ => "1" }
   },
   "0018,9737" => {
          desc => "Radiopharmaceutical Usage Sequence",
            vr => { SQ => "1" }
   },
   "0018,9738" => {
          desc => "Attenuation Correction Source",
            vr => { CS => "1" }
   },
   "0018,9739" => {
          desc => "Number of Iterations",
            vr => { US => "1" }
   },
   "0018,9740" => {
          desc => "Number of Subsets",
            vr => { US => "1" }
   },
   "0018,9749" => {
          desc => "PET Reconstruction Sequence",
            vr => { SQ => "1" }
   },
   "0018,9751" => {
          desc => "PET Frame Type Sequence",
            vr => { SQ => "1" }
   },
   "0018,9755" => {
          desc => "Time of Flight Information Used",
            vr => { CS => "1" }
   },
   "0018,9756" => {
          desc => "Reconstruction Type",
            vr => { CS => "1" }
   },
   "0018,9758" => {
          desc => "Decay Corrected ",
            vr => { CS => "1" }
   },
   "0018,9759" => {
          desc => "Attenuation Corrected ",
            vr => { CS => "1" }
   },
   "0018,9760" => {
          desc => "Scatter Corrected ",
            vr => { CS => "1" }
   },
   "0018,9761" => {
          desc => "Dead Time Corrected ",
            vr => { CS => "1" }
   },
   "0018,9762" => {
          desc => "Gantry Motion Corrected ",
            vr => { CS => "1" }
   },
   "0018,9763" => {
          desc => "Patient Motion Corrected ",
            vr => { CS => "1" }
   },
   "0018,9764" => {
          desc => "Count Loss Normalization Corrected",
            vr => { CS => "1" }
   },
   "0018,9765" => {
          desc => "Randoms Corrected",
            vr => { CS => "1" }
   },
   "0018,9766" => {
          desc => "Non-uniform Radial Sampling Corrected",
            vr => { CS => "1" }
   },
   "0018,9767" => {
          desc => "Sensitivity Calibrated",
            vr => { CS => "1" }
   },
   "0018,9768" => {
          desc => "Detector Normalization Correction",
            vr => { CS => "1" }
   },
   "0018,9769" => {
          desc => "Iterative Reconstruction Method ",
            vr => { CS => "1" }
   },
   "0018,9770" => {
          desc => "Attenuation Correction Temporal Relationship",
            vr => { CS => "1" }
   },
   "0018,9771" => {
          desc => "Patient Physiological State Sequence",
            vr => { SQ => "1" }
   },
   "0018,9772" => {
          desc => "Patient Physiological State Code Sequence",
            vr => { SQ => "1" }
   },
   "0018,9801" => {
          desc => "Depth(s) of Focus",
            vr => { FD => "1-n" }
   },
   "0018,9803" => {
          desc => "Excluded Intervals Sequence",
            vr => { SQ => "1" }
   },
   "0018,9804" => {
          desc => "Exclusion Start Datetime",
            vr => { DT => "1" }
   },
   "0018,9805" => {
          desc => "Exclusion Duration",
            vr => { FD => "1" }
   },
   "0018,9806" => {
          desc => "US Image Description Sequence",
            vr => { SQ => "1" }
   },
   "0018,9807" => {
          desc => "Image Data Type Sequence",
            vr => { SQ => "1" }
   },
   "0018,9808" => {
          desc => "Data Type",
            vr => { CS => "1" }
   },
   "0018,9809" => {
          desc => "Transducer Scan Pattern Code Sequence",
            vr => { SQ => "1" }
   },
   "0018,980b" => {
          desc => "Aliased Data Type",
            vr => { CS => "1" }
   },
   "0018,980c" => {
          desc => "Position Measuring Device Used",
            vr => { CS => "1" }
   },
   "0018,980d" => {
          desc => "Transducer Geometry Code Sequence",
            vr => { SQ => "1" }
   },
   "0018,980e" => {
          desc => "Transducer Beam Steering Code Sequence",
            vr => { SQ => "1" }
   },
   "0018,980f" => {
          desc => "Transducer Application Code Sequence",
            vr => { SQ => "1" }
   },
   "0018,a001" => {
          desc => "Contributing Equipment Sequence",
            vr => { SQ => "1" }
   },
   "0018,a002" => {
          desc => "Contribution Date Time",
            vr => { DT => "1" }
   },
   "0018,a003" => {
          desc => "Contribution Description",
            vr => { ST => "1" }
   },
   "0020,000d" => {
          desc => "Study Instance UID",
            vr => { UI => "1" }
   },
   "0020,000e" => {
          desc => "Series Instance UID",
            vr => { UI => "1" }
   },
   "0020,0010" => {
          desc => "Study ID",
            vr => { SH => "1" }
   },
   "0020,0011" => {
          desc => "Series Number",
            vr => { IS => "1" }
   },
   "0020,0012" => {
          desc => "Acquisition Number",
            vr => { IS => "1" }
   },
   "0020,0013" => {
          desc => "Instance Number",
            vr => { IS => "1" }
   },
   "0020,0014" => {
          desc => "Isotope Number",
            vr => { IS => "1" },
           ret => 1
    },
   "0020,0015" => {
          desc => "Phase Number",
            vr => { IS => "1" },
           ret => 1
    },
   "0020,0016" => {
          desc => "Interval Number",
            vr => { IS => "1" },
           ret => 1
    },
   "0020,0017" => {
          desc => "Time Slot Number",
            vr => { IS => "1" },
           ret => 1
    },
   "0020,0018" => {
          desc => "Angle Number",
            vr => { IS => "1" },
           ret => 1
    },
   "0020,0019" => {
          desc => "Item Number",
            vr => { IS => "1" }
   },
   "0020,0020" => {
          desc => "Patient Orientation",
            vr => { CS => "2" }
   },
   "0020,0022" => {
          desc => "Overlay Number",
            vr => { IS => "1" },
           ret => 1
    },
   "0020,0024" => {
          desc => "Curve Number",
            vr => { IS => "1" },
           ret => 1
    },
   "0020,0026" => {
          desc => "LUT Number",
            vr => { IS => "1" },
           ret => 1
    },
   "0020,0030" => {
          desc => "Image Position",
            vr => { DS => "3" },
           ret => 1
    },
   "0020,0032" => {
          desc => "Image Position (Patient)",
            vr => { DS => "3" }
   },
   "0020,0035" => {
          desc => "Image Orientation",
            vr => { DS => "6" },
           ret => 1
    },
   "0020,0037" => {
          desc => "Image Orientation (Patient)",
            vr => { DS => "6" }
   },
   "0020,0050" => {
          desc => "Location",
            vr => { DS => "1" },
           ret => 1
    },
   "0020,0052" => {
          desc => "Frame of Reference UID",
            vr => { UI => "1" }
   },
   "0020,0060" => {
          desc => "Laterality",
            vr => { CS => "1" }
   },
   "0020,0062" => {
          desc => "Image Laterality",
            vr => { CS => "1" }
   },
   "0020,0070" => {
          desc => "Image Geometry Type",
            vr => { LO => "1" },
           ret => 1
    },
   "0020,0080" => {
          desc => "Masking Image",
            vr => { CS => "1-n" },
           ret => 1
    },
   "0020,0100" => {
          desc => "Temporal Position Identifier",
            vr => { IS => "1" }
   },
   "0020,0105" => {
          desc => "Number of Temporal Positions",
            vr => { IS => "1" }
   },
   "0020,0110" => {
          desc => "Temporal Resolution",
            vr => { DS => "1" }
   },
   "0020,0200" => {
          desc => "Synchronization Frame of Reference UID",
            vr => { UI => "1" }
   },
   "0020,0242" => {
          desc => "SOP Instance UID of Concatenation Source",
            vr => { UI => "1" }
   },
   "0020,1000" => {
          desc => "Series in Study",
            vr => { IS => "1" },
           ret => 1
    },
   "0020,1001" => {
          desc => "Acquisitions in Series",
            vr => { IS => "1" },
           ret => 1
    },
   "0020,1002" => {
          desc => "Images in Acquisition",
            vr => { IS => "1" }
   },
   "0020,1003" => {
          desc => "Images in Series",
            vr => { IS => "1" },
           ret => 1
    },
   "0020,1004" => {
          desc => "Acquisitions in Study",
            vr => { IS => "1" },
           ret => 1
    },
   "0020,1005" => {
          desc => "Images in Study",
            vr => { IS => "1" },
           ret => 1
    },
   "0020,1020" => {
          desc => "Reference",
            vr => { CS => "1-n" },
           ret => 1
    },
   "0020,1040" => {
          desc => "Position Reference Indicator",
            vr => { LO => "1" }
   },
   "0020,1041" => {
          desc => "Slice Location",
            vr => { DS => "1" }
   },
   "0020,1070" => {
          desc => "Other Study Numbers",
            vr => { IS => "1-n" },
           ret => 1
    },
   "0020,1200" => {
          desc => "Number of Patient Related Studies",
            vr => { IS => "1" }
   },
   "0020,1202" => {
          desc => "Number of Patient Related Series",
            vr => { IS => "1" }
   },
   "0020,1204" => {
          desc => "Number of Patient Related Instances",
            vr => { IS => "1" }
   },
   "0020,1206" => {
          desc => "Number of Study Related Series",
            vr => { IS => "1" }
   },
   "0020,1208" => {
          desc => "Number of Study Related Instances",
            vr => { IS => "1" }
   },
   "0020,1209" => {
          desc => "Number of Series Related Instances",
            vr => { IS => "1" }
   },
   "0020,31xx" => {
          desc => "Source Image IDs",
            vr => { CS => "1-n" },
           ret => 1
    },
   "0020,3401" => {
          desc => "Modifying Device ID",
            vr => { CS => "1" },
           ret => 1
    },
   "0020,3402" => {
          desc => "Modified Image ID",
            vr => { CS => "1" },
           ret => 1
    },
   "0020,3403" => {
          desc => "Modified Image Date",
            vr => { DA => "1" },
           ret => 1
    },
   "0020,3404" => {
          desc => "Modifying Device Manufacturer",
            vr => { LO => "1" },
           ret => 1
    },
   "0020,3405" => {
          desc => "Modified Image Time",
            vr => { TM => "1" },
           ret => 1
    },
   "0020,3406" => {
          desc => "Modified Image Description",
            vr => { LO => "1" },
           ret => 1
    },
   "0020,4000" => {
          desc => "Image Comments",
            vr => { LT => "1" }
   },
   "0020,5000" => {
          desc => "Original Image Identification",
            vr => { AT => "1-n" },
           ret => 1
    },
   "0020,5002" => {
          desc => "Original Image Identification Nomenclature",
            vr => { CS => "1-n" },
           ret => 1
    },
   "0020,9056" => {
          desc => "Stack ID",
            vr => { SH => "1" }
   },
   "0020,9057" => {
          desc => "In-Stack Position Number",
            vr => { UL => "1" }
   },
   "0020,9071" => {
          desc => "Frame Anatomy Sequence",
            vr => { SQ => "1" }
   },
   "0020,9072" => {
          desc => "Frame Laterality",
            vr => { CS => "1" }
   },
   "0020,9111" => {
          desc => "Frame Content Sequence",
            vr => { SQ => "1" }
   },
   "0020,9113" => {
          desc => "Plane Position Sequence",
            vr => { SQ => "1" }
   },
   "0020,9116" => {
          desc => "Plane Orientation Sequence",
            vr => { SQ => "1" }
   },
   "0020,9128" => {
          desc => "Temporal Position Index",
            vr => { UL => "1" }
   },
   "0020,9153" => {
          desc => "Nominal Cardiac Trigger Delay Time",
            vr => { FD => "1" }
   },
   "0020,9156" => {
          desc => "Frame Acquisition Number",
            vr => { US => "1" }
   },
   "0020,9157" => {
          desc => "Dimension Index Values",
            vr => { UL => "1-n" }
   },
   "0020,9158" => {
          desc => "Frame Comments",
            vr => { LT => "1" }
   },
   "0020,9161" => {
          desc => "Concatenation UID",
            vr => { UI => "1" }
   },
   "0020,9162" => {
          desc => "In-concatenation Number",
            vr => { US => "1" }
   },
   "0020,9163" => {
          desc => "In-concatenation Total Number",
            vr => { US => "1" }
   },
   "0020,9164" => {
          desc => "Dimension Organization UID",
            vr => { UI => "1" }
   },
   "0020,9165" => {
          desc => "Dimension Index Pointer",
            vr => { AT => "1" }
   },
   "0020,9167" => {
          desc => "Functional Group Pointer",
            vr => { AT => "1" }
   },
   "0020,9213" => {
          desc => "Dimension Index Private Creator",
            vr => { LO => "1" }
   },
   "0020,9221" => {
          desc => "Dimension Organization Sequence",
            vr => { SQ => "1" }
   },
   "0020,9222" => {
          desc => "Dimension Index Sequence",
            vr => { SQ => "1" }
   },
   "0020,9228" => {
          desc => "Concatenation Frame Offset Number",
            vr => { UL => "1" }
   },
   "0020,9238" => {
          desc => "Functional Group Private Creator",
            vr => { LO => "1" }
   },
   "0020,9241" => {
          desc => "Nominal Percentage of Cardiac Phase",
            vr => { FL => "1" }
   },
   "0020,9245" => {
          desc => "Nominal Percentage of Respiratory Phase",
            vr => { FL => "1" }
   },
   "0020,9246" => {
          desc => "Starting Respiratory Amplitude",
            vr => { FL => "1" }
   },
   "0020,9247" => {
          desc => "Starting Respiratory Phase",
            vr => { CS => "1" }
   },
   "0020,9248" => {
          desc => "Ending Respiratory Amplitude",
            vr => { FL => "1" }
   },
   "0020,9249" => {
          desc => "Ending Respiratory Phase",
            vr => { CS => "1" }
   },
   "0020,9250" => {
          desc => "Respiratory Trigger Type",
            vr => { CS => "1" }
   },
   "0020,9251" => {
          desc => "R - R Interval Time Nominal",
            vr => { FD => "1" }
   },
   "0020,9252" => {
          desc => "Actual Cardiac Trigger Delay Time",
            vr => { FD => "1" }
   },
   "0020,9253" => {
          desc => "Respiratory Synchronization Sequence",
            vr => { SQ => "1" }
   },
   "0020,9254" => {
          desc => "Respiratory Interval Time",
            vr => { FD => "1" }
   },
   "0020,9255" => {
          desc => "Nominal Respiratory Trigger Delay Time",
            vr => { FD => "1" }
   },
   "0020,9256" => {
          desc => "Respiratory Trigger Delay Threshold",
            vr => { FD => "1" }
   },
   "0020,9257" => {
          desc => "Actual Respiratory Trigger Delay Time",
            vr => { FD => "1" }
   },
   "0020,9301" => {
          desc => "Image Position (Volume)",
            vr => { FD => "3" }
   },
   "0020,9302" => {
          desc => "Image Orientation (Volume)",
            vr => { FD => "6" }
   },
   "0020,9307" => {
          desc => "Ultrasound Acquisition Geometry",
            vr => { CS => "1" }
   },
   "0020,9308" => {
          desc => "Apex Position",
            vr => { FD => "3" }
   },
   "0020,9309" => {
          desc => "Volume to Transducer Mapping Matrix",
            vr => { FD => "16" }
   },
   "0020,930a" => {
          desc => "Volume to Table Mapping Matrix",
            vr => { FD => "16" }
   },
   "0020,930c" => {
          desc => "Patient Frame of Reference Source",
            vr => { CS => "1" }
   },
   "0020,930d" => {
          desc => "Temporal Position Time Offset",
            vr => { FD => "1" }
   },
   "0020,930e" => {
          desc => "Plane Position (Volume) Sequence",
            vr => { SQ => "1" }
   },
   "0020,930f" => {
          desc => "Plane Orientation (Volume) Sequence",
            vr => { SQ => "1" }
   },
   "0020,9310" => {
          desc => "Temporal Position Sequence",
            vr => { SQ => "1" }
   },
   "0020,9311" => {
          desc => "Dimension Organization Type",
            vr => { CS => "1" }
   },
   "0020,9312" => {
          desc => "Volume Frame of Reference UID",
            vr => { UI => "1" }
   },
   "0020,9313" => {
          desc => "Table Frame of Reference UID",
            vr => { UI => "1" }
   },
   "0020,9421" => {
          desc => "Dimension Description Label",
            vr => { LO => "1" }
   },
   "0020,9450" => {
          desc => "Patient Orientation in Frame Sequence",
            vr => { SQ => "1" }
   },
   "0020,9453" => {
          desc => "Frame Label",
            vr => { LO => "1" }
   },
   "0020,9518" => {
          desc => "Acquisition Index",
            vr => { US => "1-n" }
   },
   "0020,9529" => {
          desc => "Contributing SOP Instances Reference Sequence",
            vr => { SQ => "1" }
   },
   "0020,9536" => {
          desc => "Reconstruction Index",
            vr => { US => "1" }
   },
   "0022,0001" => {
          desc => "Light Path Filter Pass-Through Wavelength",
            vr => { US => "1" }
   },
   "0022,0002" => {
          desc => "Light Path Filter Pass Band",
            vr => { US => "2" }
   },
   "0022,0003" => {
          desc => "Image Path Filter Pass-Through Wavelength",
            vr => { US => "1" }
   },
   "0022,0004" => {
          desc => "Image Path Filter Pass Band",
            vr => { US => "2" }
   },
   "0022,0005" => {
          desc => "Patient Eye Movement Commanded",
            vr => { CS => "1" }
   },
   "0022,0006" => {
          desc => "Patient Eye Movement Command Code Sequence",
            vr => { SQ => "1" }
   },
   "0022,0007" => {
          desc => "Spherical Lens Power",
            vr => { FL => "1" }
   },
   "0022,0008" => {
          desc => "Cylinder Lens Power",
            vr => { FL => "1" }
   },
   "0022,0009" => {
          desc => "Cylinder Axis",
            vr => { FL => "1" }
   },
   "0022,000a" => {
          desc => "Emmetropic Magnification",
            vr => { FL => "1" }
   },
   "0022,000b" => {
          desc => "Intra Ocular Pressure",
            vr => { FL => "1" }
   },
   "0022,000c" => {
          desc => "Horizontal Field of View",
            vr => { FL => "1" }
   },
   "0022,000d" => {
          desc => "Pupil Dilated",
            vr => { CS => "1" }
   },
   "0022,000e" => {
          desc => "Degree of Dilation",
            vr => { FL => "1" }
   },
   "0022,0010" => {
          desc => "Stereo Baseline Angle",
            vr => { FL => "1" }
   },
   "0022,0011" => {
          desc => "Stereo Baseline Displacement",
            vr => { FL => "1" }
   },
   "0022,0012" => {
          desc => "Stereo Horizontal Pixel Offset",
            vr => { FL => "1" }
   },
   "0022,0013" => {
          desc => "Stereo Vertical Pixel Offset",
            vr => { FL => "1" }
   },
   "0022,0014" => {
          desc => "Stereo Rotation",
            vr => { FL => "1" }
   },
   "0022,0015" => {
          desc => "Acquisition Device Type Code Sequence",
            vr => { SQ => "1" }
   },
   "0022,0016" => {
          desc => "Illumination Type Code Sequence",
            vr => { SQ => "1" }
   },
   "0022,0017" => {
          desc => "Light Path Filter Type Stack Code Sequence",
            vr => { SQ => "1" }
   },
   "0022,0018" => {
          desc => "Image Path Filter Type Stack Code Sequence",
            vr => { SQ => "1" }
   },
   "0022,0019" => {
          desc => "Lenses Code Sequence",
            vr => { SQ => "1" }
   },
   "0022,001a" => {
          desc => "Channel Description Code Sequence",
            vr => { SQ => "1" }
   },
   "0022,001b" => {
          desc => "Refractive State Sequence",
            vr => { SQ => "1" }
   },
   "0022,001c" => {
          desc => "Mydriatic Agent Code Sequence",
            vr => { SQ => "1" }
   },
   "0022,001d" => {
          desc => "Relative Image Position Code Sequence",
            vr => { SQ => "1" }
   },
   "0022,0020" => {
          desc => "Stereo Pairs Sequence",
            vr => { SQ => "1" }
   },
   "0022,0021" => {
          desc => "Left Image Sequence",
            vr => { SQ => "1" }
   },
   "0022,0022" => {
          desc => "Right Image Sequence",
            vr => { SQ => "1" }
   },
   "0022,0030" => {
          desc => "Axial Length of the Eye",
            vr => { FL => "1" }
   },
   "0022,0031" => {
          desc => "Ophthalmic Frame Location Sequence",
            vr => { SQ => "1" }
   },
   "0022,0032" => {
          desc => "Reference Coordinates",
            vr => { FL => "2-2n" }
   },
   "0022,0035" => {
          desc => "Depth Spatial Resolution",
            vr => { FL => "1" }
   },
   "0022,0036" => {
          desc => "Maximum Depth Distortion",
            vr => { FL => "1" }
   },
   "0022,0037" => {
          desc => "Along-scan Spatial Resolution",
            vr => { FL => "1" }
   },
   "0022,0038" => {
          desc => "Maximum Along-scan Distortion",
            vr => { FL => "1" }
   },
   "0022,0039" => {
          desc => "Ophthalmic Image Orientation",
            vr => { CS => "1" }
   },
   "0022,0041" => {
          desc => "Depth of Transverse Image",
            vr => { FL => "1" }
   },
   "0022,0042" => {
          desc => "Mydriatic Agent Concentration Units Sequence",
            vr => { SQ => "1" }
   },
   "0022,0048" => {
          desc => "Across-scan Spatial Resolution",
            vr => { FL => "1" }
   },
   "0022,0049" => {
          desc => "Maximum Across-scan Distortion",
            vr => { FL => "1" }
   },
   "0022,004e" => {
          desc => "Mydriatic Agent Concentration",
            vr => { DS => "1" }
   },
   "0022,0055" => {
          desc => "Illumination Wave Length",
            vr => { FL => "1" }
   },
   "0022,0056" => {
          desc => "Illumination Power",
            vr => { FL => "1" }
   },
   "0022,0057" => {
          desc => "Illumination Bandwidth",
            vr => { FL => "1" }
   },
   "0022,0058" => {
          desc => "Mydriatic Agent Sequence",
            vr => { SQ => "1" }
   },
   "0028,0002" => {
          desc => "Samples per Pixel",
            vr => { US => "1" }
   },
   "0028,0003" => {
          desc => "Samples per Pixel Used",
            vr => { US => "1" }
   },
   "0028,0004" => {
          desc => "Photometric Interpretation",
            vr => { CS => "1" }
   },
   "0028,0005" => {
          desc => "Image Dimensions",
            vr => { US => "1" },
           ret => 1
    },
   "0028,0006" => {
          desc => "Planar Configuration",
            vr => { US => "1" }
   },
   "0028,0008" => {
          desc => "Number of Frames",
            vr => { IS => "1" }
   },
   "0028,0009" => {
          desc => "Frame Increment Pointer",
            vr => { AT => "1-n" }
   },
   "0028,000a" => {
          desc => "Frame Dimension Pointer",
            vr => { AT => "1-n" }
   },
   "0028,0010" => {
          desc => "Rows",
            vr => { US => "1" }
   },
   "0028,0011" => {
          desc => "Columns",
            vr => { US => "1" }
   },
   "0028,0012" => {
          desc => "Planes",
            vr => { US => "1" },
           ret => 1
    },
   "0028,0014" => {
          desc => "Ultrasound Color Data Present",
            vr => { US => "1" }
   },
   "0028,0020" => {
          desc => "",
            vr => {  },
           ret => 1
    },
   "0028,0030" => {
          desc => "Pixel Spacing",
            vr => { DS => "2" }
   },
   "0028,0031" => {
          desc => "Zoom Factor",
            vr => { DS => "2" }
   },
   "0028,0032" => {
          desc => "Zoom Center",
            vr => { DS => "2" }
   },
   "0028,0034" => {
          desc => "Pixel Aspect Ratio",
            vr => { IS => "2" }
   },
   "0028,0040" => {
          desc => "Image Format",
            vr => { CS => "1" },
           ret => 1
    },
   "0028,0050" => {
          desc => "Manipulated Image",
            vr => { LO => "1-n" },
           ret => 1
    },
   "0028,0051" => {
          desc => "Corrected Image",
            vr => { CS => "1-n" }
   },
   "0028,005f" => {
          desc => "Compression Recognition Code",
            vr => { LO => "1" },
           ret => 1
    },
   "0028,0060" => {
          desc => "Compression Code",
            vr => { CS => "1" },
           ret => 1
    },
   "0028,0061" => {
          desc => "Compression Originator",
            vr => { SH => "1" },
           ret => 1
    },
   "0028,0062" => {
          desc => "Compression Label",
            vr => { LO => "1" },
           ret => 1
    },
   "0028,0063" => {
          desc => "Compression Description",
            vr => { SH => "1" },
           ret => 1
    },
   "0028,0065" => {
          desc => "Compression Sequence",
            vr => { CS => "1-n" },
           ret => 1
    },
   "0028,0066" => {
          desc => "Compression Step Pointers",
            vr => { AT => "1-n" },
           ret => 1
    },
   "0028,0068" => {
          desc => "Repeat Interval",
            vr => { US => "1" },
           ret => 1
    },
   "0028,0069" => {
          desc => "Bits Grouped",
            vr => { US => "1" },
           ret => 1
    },
   "0028,0070" => {
          desc => "Perimeter Table",
            vr => { US => "1-n" },
           ret => 1
    },
   "0028,0071" => {
          desc => "Perimeter Value",
            vr => { SS => "1", US => "1" },
           ret => 1
    },
   "0028,0080" => {
          desc => "Predictor Rows",
            vr => { US => "1" },
           ret => 1
    },
   "0028,0081" => {
          desc => "Predictor Columns",
            vr => { US => "1" },
           ret => 1
    },
   "0028,0082" => {
          desc => "Predictor Constants",
            vr => { US => "1-n" },
           ret => 1
    },
   "0028,0090" => {
          desc => "Blocked Pixels",
            vr => { CS => "1" },
           ret => 1
    },
   "0028,0091" => {
          desc => "Block Rows",
            vr => { US => "1" },
           ret => 1
    },
   "0028,0092" => {
          desc => "Block Columns",
            vr => { US => "1" },
           ret => 1
    },
   "0028,0093" => {
          desc => "Row Overlap",
            vr => { US => "1" },
           ret => 1
    },
   "0028,0094" => {
          desc => "Column Overlap",
            vr => { US => "1" },
           ret => 1
    },
   "0028,0100" => {
          desc => "Bits Allocated",
            vr => { US => "1" }
   },
   "0028,0101" => {
          desc => "Bits Stored",
            vr => { US => "1" }
   },
   "0028,0102" => {
          desc => "High Bit",
            vr => { US => "1" }
   },
   "0028,0103" => {
          desc => "Pixel Representation",
            vr => { US => "1" }
   },
   "0028,0104" => {
          desc => "Smallest Valid Pixel Value",
            vr => { SS => "1", US => "1" },
           ret => 1
    },
   "0028,0105" => {
          desc => "Largest Valid Pixel Value",
            vr => { SS => "1", US => "1" },
           ret => 1
    },
   "0028,0106" => {
          desc => "Smallest Image Pixel Value",
            vr => { SS => "1", US => "1" }
   },
   "0028,0107" => {
          desc => "Largest Image Pixel Value",
            vr => { SS => "1", US => "1" }
   },
   "0028,0108" => {
          desc => "Smallest Pixel Value in Series",
            vr => { SS => "1", US => "1" }
   },
   "0028,0109" => {
          desc => "Largest Pixel Value in Series",
            vr => { SS => "1", US => "1" }
   },
   "0028,0110" => {
          desc => "Smallest Image Pixel Value in Plane",
            vr => { SS => "1", US => "1" },
           ret => 1
    },
   "0028,0111" => {
          desc => "Largest Image Pixel Value in Plane",
            vr => { SS => "1", US => "1" },
           ret => 1
    },
   "0028,0120" => {
          desc => "Pixel Padding Value",
            vr => { SS => "1", US => "1" }
   },
   "0028,0121" => {
          desc => "Pixel Padding Range Limit",
            vr => { SS => "1", US => "1" }
   },
   "0028,0200" => {
          desc => "Image Location",
            vr => { US => "1" },
           ret => 1
    },
   "0028,0300" => {
          desc => "Quality Control Image",
            vr => { CS => "1" }
   },
   "0028,0301" => {
          desc => "Burned In Annotation",
            vr => { CS => "1" }
   },
   "0028,0400" => {
          desc => "Transform Label",
            vr => { LO => "1" },
           ret => 1
    },
   "0028,0401" => {
          desc => "Transform Version Number",
            vr => { LO => "1" },
           ret => 1
    },
   "0028,0402" => {
          desc => "Number of Transform Steps",
            vr => { US => "1" },
           ret => 1
    },
   "0028,0403" => {
          desc => "Sequence of Compressed Data",
            vr => { LO => "1-n" },
           ret => 1
    },
   "0028,0404" => {
          desc => "Details of Coefficients",
            vr => { AT => "1-n" },
           ret => 1
    },
   "0028,04x0" => {
          desc => "Rows For Nth Order Coefficients",
            vr => { US => "1" },
           ret => 1
    },
   "0028,04x1" => {
          desc => "Columns For Nth Order Coefficients",
            vr => { US => "1" },
           ret => 1
    },
   "0028,04x2" => {
          desc => "Coefficient Coding",
            vr => { LO => "1-n" },
           ret => 1
    },
   "0028,04x3" => {
          desc => "Coefficient Coding Pointers",
            vr => { AT => "1-n" },
           ret => 1
    },
   "0028,0700" => {
          desc => "DCT Label",
            vr => { LO => "1" },
           ret => 1
    },
   "0028,0701" => {
          desc => "Data Block Description",
            vr => { CS => "1-n" },
           ret => 1
    },
   "0028,0702" => {
          desc => "Data Block",
            vr => { AT => "1-n" },
           ret => 1
    },
   "0028,0710" => {
          desc => "Normalization Factor Format",
            vr => { US => "1" },
           ret => 1
    },
   "0028,0720" => {
          desc => "Zonal Map Number Format",
            vr => { US => "1" },
           ret => 1
    },
   "0028,0721" => {
          desc => "Zonal Map Location",
            vr => { AT => "1-n" },
           ret => 1
    },
   "0028,0722" => {
          desc => "Zonal Map Format",
            vr => { US => "1" },
           ret => 1
    },
   "0028,0730" => {
          desc => "Adaptive Map Format",
            vr => { US => "1" },
           ret => 1
    },
   "0028,0740" => {
          desc => "Code Number Format",
            vr => { US => "1" },
           ret => 1
    },
   "0028,08x0" => {
          desc => "Code Label",
            vr => { CS => "1-n" },
           ret => 1
    },
   "0028,08x2" => {
          desc => "Number of Tables",
            vr => { US => "1" },
           ret => 1
    },
   "0028,08x3" => {
          desc => "Code Table Location",
            vr => { AT => "1-n" },
           ret => 1
    },
   "0028,08x4" => {
          desc => "Bits For Code Word",
            vr => { US => "1" },
           ret => 1
    },
   "0028,08x8" => {
          desc => "Image Data Location",
            vr => { AT => "1-n" },
           ret => 1
    },
   "0028,0a02" => {
          desc => "Pixel Spacing Calibration Type",
            vr => { CS => "1" }
   },
   "0028,0a04" => {
          desc => "Pixel Spacing Calibration Description",
            vr => { LO => "1" }
   },
   "0028,1040" => {
          desc => "Pixel Intensity Relationship",
            vr => { CS => "1" }
   },
   "0028,1041" => {
          desc => "Pixel Intensity Relationship Sign",
            vr => { SS => "1" }
   },
   "0028,1050" => {
          desc => "Window Center",
            vr => { DS => "1-n" }
   },
   "0028,1051" => {
          desc => "Window Width",
            vr => { DS => "1-n" }
   },
   "0028,1052" => {
          desc => "Rescale Intercept",
            vr => { DS => "1" }
   },
   "0028,1053" => {
          desc => "Rescale Slope",
            vr => { DS => "1" }
   },
   "0028,1054" => {
          desc => "Rescale Type",
            vr => { LO => "1" }
   },
   "0028,1055" => {
          desc => "Window Center & Width Explanation",
            vr => { LO => "1-n" }
   },
   "0028,1056" => {
          desc => "VOI LUT Function",
            vr => { CS => "1" }
   },
   "0028,1080" => {
          desc => "Gray Scale",
            vr => { CS => "1" },
           ret => 1
    },
   "0028,1090" => {
          desc => "Recommended Viewing Mode",
            vr => { CS => "1" }
   },
   "0028,1100" => {
          desc => "Gray Lookup Table Descriptor ",
            vr => { SS => "3", US => "3" },
           ret => 1
    },
   "0028,1101" => {
          desc => "Red Palette Color Lookup Table Descriptor ",
            vr => { SS => "3", US => "3" }
   },
   "0028,1102" => {
          desc => "Green Palette Color Lookup Table Descriptor ",
            vr => { SS => "3", US => "3" }
   },
   "0028,1103" => {
          desc => "Blue Palette Color Lookup Table Descriptor ",
            vr => { SS => "3", US => "3" }
   },
   "0028,1104" => {
          desc => "Alpha Palette Color Lookup Table Descriptor",
            vr => { US => "3" }
   },
   "0028,1111" => {
          desc => "Large Red Palette Color Lookup Table Descriptor ",
            vr => { SS => "4", US => "4" },
           ret => 1
    },
   "0028,1112" => {
          desc => "Large Green Palette Color Lookup Table Descriptor ",
            vr => { SS => "4", US => "4" },
           ret => 1
    },
   "0028,1113" => {
          desc => "Large Blue Palette Color Lookup Table Descriptor ",
            vr => { SS => "4", US => "4" },
           ret => 1
    },
   "0028,1199" => {
          desc => "Palette Color Lookup Table UID",
            vr => { UI => "1" }
   },
   "0028,1200" => {
          desc => "Gray Lookup Table Data",
            vr => { OW => "1", SS => "1-n", US => "1-n" },
           ret => 1
    },
   "0028,1201" => {
          desc => "Red Palette Color Lookup Table Data",
            vr => { OW => "1" }
   },
   "0028,1202" => {
          desc => "Green Palette Color Lookup Table Data",
            vr => { OW => "1" }
   },
   "0028,1203" => {
          desc => "Blue Palette Color Lookup Table Data",
            vr => { OW => "1" }
   },
   "0028,1204" => {
          desc => "Alpha Palette Color Lookup Table Data",
            vr => { OW => "1" }
   },
   "0028,1211" => {
          desc => "Large Red Palette Color Lookup Table Data",
            vr => { OW => "1" },
           ret => 1
    },
   "0028,1212" => {
          desc => "Large Green Palette Color Lookup Table Data",
            vr => { OW => "1" },
           ret => 1
    },
   "0028,1213" => {
          desc => "Large Blue Palette Color Lookup Table Data",
            vr => { OW => "1" },
           ret => 1
    },
   "0028,1214" => {
          desc => "Large Palette Color Lookup Table UID",
            vr => { UI => "1" },
           ret => 1
    },
   "0028,1221" => {
          desc => "Segmented Red Palette Color Lookup Table Data",
            vr => { OW => "1" }
   },
   "0028,1222" => {
          desc => "Segmented Green Palette Color Lookup Table Data",
            vr => { OW => "1" }
   },
   "0028,1223" => {
          desc => "Segmented Blue Palette Color Lookup Table Data",
            vr => { OW => "1" }
   },
   "0028,1300" => {
          desc => "Breast Implant Present",
            vr => { CS => "1" }
   },
   "0028,1350" => {
          desc => "Partial View",
            vr => { CS => "1" }
   },
   "0028,1351" => {
          desc => "Partial View Description",
            vr => { ST => "1" }
   },
   "0028,1352" => {
          desc => "Partial View Code Sequence",
            vr => { SQ => "1" }
   },
   "0028,135a" => {
          desc => "Spatial Locations Preserved",
            vr => { CS => "1" }
   },
   "0028,1401" => {
          desc => "Data Frame Assignment Sequence",
            vr => { SQ => "1" }
   },
   "0028,1402" => {
          desc => "Data Path Assignment",
            vr => { CS => "1" }
   },
   "0028,1403" => {
          desc => "Bits Mapped to Color Lookup Table",
            vr => { US => "1" }
   },
   "0028,1404" => {
          desc => "Blending LUT 1 Sequence",
            vr => { SQ => "1" }
   },
   "0028,1405" => {
          desc => "Blending LUT 1 Transfer Function",
            vr => { CS => "1" }
   },
   "0028,1406" => {
          desc => "Blending Weight Constant",
            vr => { FD => "1" }
   },
   "0028,1407" => {
          desc => "Blending Lookup Table Descriptor",
            vr => { US => "3" }
   },
   "0028,1408" => {
          desc => "Blending Lookup Table Data",
            vr => { OW => "1" }
   },
   "0028,140b" => {
          desc => "Enhanced Palette Color Lookup Table Sequence",
            vr => { SQ => "1" }
   },
   "0028,140c" => {
          desc => "Blending LUT 2 Sequence",
            vr => { SQ => "1" }
   },
   "0028,140d" => {
          desc => "Blending LUT 2 Transfer Function",
            vr => { CS => "1" }
   },
   "0028,140e" => {
          desc => "Data Path ID",
            vr => { CS => "1" }
   },
   "0028,140f" => {
          desc => "RGB LUT Transfer Function",
            vr => { CS => "1" }
   },
   "0028,1410" => {
          desc => "Alpha LUT Transfer Function",
            vr => { CS => "1" }
   },
   "0028,2000" => {
          desc => "ICC Profile",
            vr => { OB => "1" }
   },
   "0028,2110" => {
          desc => "Lossy Image Compression",
            vr => { CS => "1" }
   },
   "0028,2112" => {
          desc => "Lossy Image Compression Ratio",
            vr => { DS => "1-n" }
   },
   "0028,2114" => {
          desc => "Lossy Image Compression Method",
            vr => { CS => "1-n" }
   },
   "0028,3000" => {
          desc => "Modality LUT Sequence",
            vr => { SQ => "1" }
   },
   "0028,3002" => {
          desc => "LUT Descriptor",
            vr => { SS => "3", US => "3" }
   },
   "0028,3003" => {
          desc => "LUT Explanation",
            vr => { LO => "1" }
   },
   "0028,3004" => {
          desc => "Modality LUT Type",
            vr => { LO => "1" }
   },
   "0028,3006" => {
          desc => "LUT Data",
            vr => { OW => "1", US => "1-n" }
   },
   "0028,3010" => {
          desc => "VOI LUT Sequence",
            vr => { SQ => "1" }
   },
   "0028,3110" => {
          desc => "Softcopy VOI LUT Sequence",
            vr => { SQ => "1" }
   },
   "0028,4000" => {
          desc => "Image Presentation Comments",
            vr => { LT => "1" },
           ret => 1
    },
   "0028,5000" => {
          desc => "Bi-Plane Acquisition Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "0028,6010" => {
          desc => "Representative Frame Number",
            vr => { US => "1" }
   },
   "0028,6020" => {
          desc => "Frame Numbers of Interest (FOI) ",
            vr => { US => "1-n" }
   },
   "0028,6022" => {
          desc => "Frame of Interest Description",
            vr => { LO => "1-n" }
   },
   "0028,6023" => {
          desc => "Frame of Interest Type",
            vr => { CS => "1-n" }
   },
   "0028,6030" => {
          desc => "Mask Pointer(s)",
            vr => { US => "1-n" },
           ret => 1
    },
   "0028,6040" => {
          desc => "R Wave Pointer",
            vr => { US => "1-n" }
   },
   "0028,6100" => {
          desc => "Mask Subtraction Sequence",
            vr => { SQ => "1" }
   },
   "0028,6101" => {
          desc => "Mask Operation",
            vr => { CS => "1" }
   },
   "0028,6102" => {
          desc => "Applicable Frame Range",
            vr => { US => "2-2n" }
   },
   "0028,6110" => {
          desc => "Mask Frame Numbers",
            vr => { US => "1-n" }
   },
   "0028,6112" => {
          desc => "Contrast Frame Averaging",
            vr => { US => "1" }
   },
   "0028,6114" => {
          desc => "Mask Sub-pixel Shift",
            vr => { FL => "2" }
   },
   "0028,6120" => {
          desc => "TID Offset",
            vr => { SS => "1" }
   },
   "0028,6190" => {
          desc => "Mask Operation Explanation",
            vr => { ST => "1" }
   },
   "0028,7fe0" => {
          desc => "Pixel Data Provider URL",
            vr => { UT => "1" }
   },
   "0028,9001" => {
          desc => "Data Point Rows",
            vr => { UL => "1" }
   },
   "0028,9002" => {
          desc => "Data Point Columns",
            vr => { UL => "1" }
   },
   "0028,9003" => {
          desc => "Signal Domain Columns",
            vr => { CS => "1" }
   },
   "0028,9099" => {
          desc => "Largest Monochrome Pixel Value",
            vr => { US => "1" },
           ret => 1
    },
   "0028,9108" => {
          desc => "Data Representation",
            vr => { CS => "1" }
   },
   "0028,9110" => {
          desc => "Pixel Measures Sequence",
            vr => { SQ => "1" }
   },
   "0028,9132" => {
          desc => "Frame VOI LUT Sequence",
            vr => { SQ => "1" }
   },
   "0028,9145" => {
          desc => "Pixel Value Transformation Sequence",
            vr => { SQ => "1" }
   },
   "0028,9235" => {
          desc => "Signal Domain Rows",
            vr => { CS => "1" }
   },
   "0028,9411" => {
          desc => "Display Filter Percentage",
            vr => { FL => "1" }
   },
   "0028,9415" => {
          desc => "Frame Pixel Shift Sequence",
            vr => { SQ => "1" }
   },
   "0028,9416" => {
          desc => "Subtraction Item ID",
            vr => { US => "1" }
   },
   "0028,9422" => {
          desc => "Pixel Intensity Relationship LUT Sequence",
            vr => { SQ => "1" }
   },
   "0028,9443" => {
          desc => "Frame Pixel Data Properties Sequence",
            vr => { SQ => "1" }
   },
   "0028,9444" => {
          desc => "Geometrical Properties",
            vr => { CS => "1" }
   },
   "0028,9445" => {
          desc => "Geometric Maximum Distortion",
            vr => { FL => "1" }
   },
   "0028,9446" => {
          desc => "Image Processing Applied",
            vr => { CS => "1-n" }
   },
   "0028,9454" => {
          desc => "Mask Selection Mode",
            vr => { CS => "1" }
   },
   "0028,9474" => {
          desc => "LUT Function",
            vr => { CS => "1" }
   },
   "0028,9478" => {
          desc => "Mask Visibility Percentage",
            vr => { FL => "1" }
   },
   "0028,9501" => {
          desc => "Pixel Shift Sequence",
            vr => { SQ => "1" }
   },
   "0028,9502" => {
          desc => "Region Pixel Shift Sequence",
            vr => { SQ => "1" }
   },
   "0028,9503" => {
          desc => "Vertices of the Region",
            vr => { SS => "2-2n" }
   },
   "0028,9505" => {
          desc => "Multi-frame Presentation Sequence",
            vr => { SQ => "1" }
   },
   "0028,9506" => {
          desc => "Pixel Shift Frame Range",
            vr => { US => "2-2n" }
   },
   "0028,9507" => {
          desc => "LUT Frame Range",
            vr => { US => "2-2n" }
   },
   "0028,9520" => {
          desc => "Image to Equipment Mapping Matrix",
            vr => { DS => "16" }
   },
   "0028,9537" => {
          desc => "Equipment Coordinate System Identification",
            vr => { CS => "1" }
   },
   "0032,000a" => {
          desc => "Study Status ID",
            vr => { CS => "1" },
           ret => 1
    },
   "0032,000c" => {
          desc => "Study Priority ID",
            vr => { CS => "1" },
           ret => 1
    },
   "0032,0012" => {
          desc => "Study ID Issuer",
            vr => { LO => "1" },
           ret => 1
    },
   "0032,0032" => {
          desc => "Study Verified Date",
            vr => { DA => "1" },
           ret => 1
    },
   "0032,0033" => {
          desc => "Study Verified Time",
            vr => { TM => "1" },
           ret => 1
    },
   "0032,0034" => {
          desc => "Study Read Date",
            vr => { DA => "1" },
           ret => 1
    },
   "0032,0035" => {
          desc => "Study Read Time",
            vr => { TM => "1" },
           ret => 1
    },
   "0032,1000" => {
          desc => "Scheduled Study Start Date",
            vr => { DA => "1" },
           ret => 1
    },
   "0032,1001" => {
          desc => "Scheduled Study Start Time",
            vr => { TM => "1" },
           ret => 1
    },
   "0032,1010" => {
          desc => "Scheduled Study Stop Date",
            vr => { DA => "1" },
           ret => 1
    },
   "0032,1011" => {
          desc => "Scheduled Study Stop Time",
            vr => { TM => "1" },
           ret => 1
    },
   "0032,1020" => {
          desc => "Scheduled Study Location",
            vr => { LO => "1" },
           ret => 1
    },
   "0032,1021" => {
          desc => "Scheduled Study Location AE Title",
            vr => { AE => "1-n" },
           ret => 1
    },
   "0032,1030" => {
          desc => "Reason for Study",
            vr => { LO => "1" },
           ret => 1
    },
   "0032,1031" => {
          desc => "Requesting Physician Identification Sequence",
            vr => { SQ => "1" }
   },
   "0032,1032" => {
          desc => "Requesting Physician",
            vr => { PN => "1" }
   },
   "0032,1033" => {
          desc => "Requesting Service",
            vr => { LO => "1" }
   },
   "0032,1034" => {
          desc => "Requesting Service Code Sequence",
            vr => { SQ => "1" }
   },
   "0032,1040" => {
          desc => "Study Arrival Date",
            vr => { DA => "1" },
           ret => 1
    },
   "0032,1041" => {
          desc => "Study Arrival Time",
            vr => { TM => "1" },
           ret => 1
    },
   "0032,1050" => {
          desc => "Study Completion Date",
            vr => { DA => "1" },
           ret => 1
    },
   "0032,1051" => {
          desc => "Study Completion Time",
            vr => { TM => "1" },
           ret => 1
    },
   "0032,1055" => {
          desc => "Study Component Status ID",
            vr => { CS => "1" },
           ret => 1
    },
   "0032,1060" => {
          desc => "Requested Procedure Description",
            vr => { LO => "1" }
   },
   "0032,1064" => {
          desc => "Requested Procedure Code Sequence",
            vr => { SQ => "1" }
   },
   "0032,1070" => {
          desc => "Requested Contrast Agent",
            vr => { LO => "1" }
   },
   "0032,4000" => {
          desc => "Study Comments",
            vr => { LT => "1" },
           ret => 1
    },
   "0038,0004" => {
          desc => "Referenced Patient Alias Sequence",
            vr => { SQ => "1" }
   },
   "0038,0008" => {
          desc => "Visit Status ID",
            vr => { CS => "1" }
   },
   "0038,0010" => {
          desc => "Admission ID",
            vr => { LO => "1" }
   },
   "0038,0011" => {
          desc => "Issuer of Admission ID",
            vr => { LO => "1" },
           ret => 1
    },
   "0038,0014" => {
          desc => "Issuer of Admission ID Sequence",
            vr => { SQ => "1" }
   },
   "0038,0016" => {
          desc => "Route of Admissions",
            vr => { LO => "1" }
   },
   "0038,001a" => {
          desc => "Scheduled Admission Date",
            vr => { DA => "1" },
           ret => 1
    },
   "0038,001b" => {
          desc => "Scheduled Admission Time",
            vr => { TM => "1" },
           ret => 1
    },
   "0038,001c" => {
          desc => "Scheduled Discharge Date",
            vr => { DA => "1" },
           ret => 1
    },
   "0038,001d" => {
          desc => "Scheduled Discharge Time",
            vr => { TM => "1" },
           ret => 1
    },
   "0038,001e" => {
          desc => "Scheduled Patient Institution Residence",
            vr => { LO => "1" },
           ret => 1
    },
   "0038,0020" => {
          desc => "Admitting Date",
            vr => { DA => "1" }
   },
   "0038,0021" => {
          desc => "Admitting Time",
            vr => { TM => "1" }
   },
   "0038,0030" => {
          desc => "Discharge Date",
            vr => { DA => "1" },
           ret => 1
    },
   "0038,0032" => {
          desc => "Discharge Time",
            vr => { TM => "1" },
           ret => 1
    },
   "0038,0040" => {
          desc => "Discharge Diagnosis Description",
            vr => { LO => "1" },
           ret => 1
    },
   "0038,0044" => {
          desc => "Discharge Diagnosis Code Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "0038,0050" => {
          desc => "Special Needs",
            vr => { LO => "1" }
   },
   "0038,0060" => {
          desc => "Service Episode ID",
            vr => { LO => "1" }
   },
   "0038,0061" => {
          desc => "Issuer of Service Episode ID",
            vr => { LO => "1" },
           ret => 1
    },
   "0038,0062" => {
          desc => "Service Episode Description",
            vr => { LO => "1" }
   },
   "0038,0064" => {
          desc => "Issuer of Service Episode ID Sequence",
            vr => { SQ => "1" }
   },
   "0038,0100" => {
          desc => "Pertinent Documents Sequence",
            vr => { SQ => "1" }
   },
   "0038,0300" => {
          desc => "Current Patient Location",
            vr => { LO => "1" }
   },
   "0038,0400" => {
          desc => "Patient's Institution Residence",
            vr => { LO => "1" }
   },
   "0038,0500" => {
          desc => "Patient State",
            vr => { LO => "1" }
   },
   "0038,0502" => {
          desc => "Patient Clinical Trial Participation Sequence",
            vr => { SQ => "1" }
   },
   "0038,4000" => {
          desc => "Visit Comments",
            vr => { LT => "1" }
   },
   "003a,0004" => {
          desc => "Waveform Originality",
            vr => { CS => "1" }
   },
   "003a,0005" => {
          desc => "Number of Waveform Channels ",
            vr => { US => "1" }
   },
   "003a,0010" => {
          desc => "Number of Waveform Samples ",
            vr => { UL => "1" }
   },
   "003a,001a" => {
          desc => "Sampling Frequency ",
            vr => { DS => "1" }
   },
   "003a,0020" => {
          desc => "Multiplex Group Label ",
            vr => { SH => "1" }
   },
   "003a,0200" => {
          desc => "Channel Definition Sequence",
            vr => { SQ => "1" }
   },
   "003a,0202" => {
          desc => "Waveform Channel Number ",
            vr => { IS => "1" }
   },
   "003a,0203" => {
          desc => "Channel Label",
            vr => { SH => "1" }
   },
   "003a,0205" => {
          desc => "Channel Status",
            vr => { CS => "1-n" }
   },
   "003a,0208" => {
          desc => "Channel Source Sequence",
            vr => { SQ => "1" }
   },
   "003a,0209" => {
          desc => "Channel Source Modifiers Sequence",
            vr => { SQ => "1" }
   },
   "003a,020a" => {
          desc => "Source Waveform Sequence",
            vr => { SQ => "1" }
   },
   "003a,020c" => {
          desc => "Channel Derivation Description",
            vr => { LO => "1" }
   },
   "003a,0210" => {
          desc => "Channel Sensitivity ",
            vr => { DS => "1" }
   },
   "003a,0211" => {
          desc => "Channel Sensitivity Units Sequence",
            vr => { SQ => "1" }
   },
   "003a,0212" => {
          desc => "Channel Sensitivity Correction Factor",
            vr => { DS => "1" }
   },
   "003a,0213" => {
          desc => "Channel Baseline ",
            vr => { DS => "1" }
   },
   "003a,0214" => {
          desc => "Channel Time Skew",
            vr => { DS => "1" }
   },
   "003a,0215" => {
          desc => "Channel Sample Skew",
            vr => { DS => "1" }
   },
   "003a,0218" => {
          desc => "Channel Offset",
            vr => { DS => "1" }
   },
   "003a,021a" => {
          desc => "Waveform Bits Stored",
            vr => { US => "1" }
   },
   "003a,0220" => {
          desc => "Filter Low Frequency",
            vr => { DS => "1" }
   },
   "003a,0221" => {
          desc => "Filter High Frequency",
            vr => { DS => "1" }
   },
   "003a,0222" => {
          desc => "Notch Filter Frequency",
            vr => { DS => "1" }
   },
   "003a,0223" => {
          desc => "Notch Filter Bandwidth",
            vr => { DS => "1" }
   },
   "003a,0230" => {
          desc => "Waveform Data Display Scale",
            vr => { FL => "1" }
   },
   "003a,0231" => {
          desc => "Waveform Display Background CIELab Value",
            vr => { US => "3" }
   },
   "003a,0240" => {
          desc => "Waveform Presentation Group Sequence",
            vr => { SQ => "1" }
   },
   "003a,0241" => {
          desc => "Presentation Group Number",
            vr => { US => "1" }
   },
   "003a,0242" => {
          desc => "Channel Display Sequence",
            vr => { SQ => "1" }
   },
   "003a,0244" => {
          desc => "Channel Recommended Display CIELab Value",
            vr => { US => "3" }
   },
   "003a,0245" => {
          desc => "Channel Position",
            vr => { FL => "1" }
   },
   "003a,0246" => {
          desc => "Display Shading Flag",
            vr => { CS => "1" }
   },
   "003a,0247" => {
          desc => "Fractional Channel Display Scale",
            vr => { FL => "1" }
   },
   "003a,0248" => {
          desc => "Absolute Channel Display Scale",
            vr => { FL => "1" }
   },
   "003a,0300" => {
          desc => "Multiplexed Audio Channels Description Code Sequence",
            vr => { SQ => "1" }
   },
   "003a,0301" => {
          desc => "Channel Identification Code",
            vr => { IS => "1" }
   },
   "003a,0302" => {
          desc => "Channel Mode",
            vr => { CS => "1" }
   },
   "0040,0001" => {
          desc => "Scheduled Station AE Title",
            vr => { AE => "1-n" }
   },
   "0040,0002" => {
          desc => "Scheduled Procedure Step Start Date",
            vr => { DA => "1" }
   },
   "0040,0003" => {
          desc => "Scheduled Procedure Step Start Time",
            vr => { TM => "1" }
   },
   "0040,0004" => {
          desc => "Scheduled Procedure Step End Date",
            vr => { DA => "1" }
   },
   "0040,0005" => {
          desc => "Scheduled Procedure Step End Time",
            vr => { TM => "1" }
   },
   "0040,0006" => {
          desc => "Scheduled Performing Physician's Name",
            vr => { PN => "1" }
   },
   "0040,0007" => {
          desc => "Scheduled Procedure Step Description",
            vr => { LO => "1" }
   },
   "0040,0008" => {
          desc => "Scheduled Protocol Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,0009" => {
          desc => "Scheduled Procedure Step ID",
            vr => { SH => "1" }
   },
   "0040,000a" => {
          desc => "Stage Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,000b" => {
          desc => "Scheduled Performing Physician Identification Sequence",
            vr => { SQ => "1" }
   },
   "0040,0010" => {
          desc => "Scheduled Station Name",
            vr => { SH => "1-n" }
   },
   "0040,0011" => {
          desc => "Scheduled Procedure Step Location",
            vr => { SH => "1" }
   },
   "0040,0012" => {
          desc => "Pre-Medication",
            vr => { LO => "1" }
   },
   "0040,0020" => {
          desc => "Scheduled Procedure Step Status",
            vr => { CS => "1" }
   },
   "0040,0026" => {
          desc => "Order Placer Identifier Sequence",
            vr => { SQ => "1" }
   },
   "0040,0027" => {
          desc => "Order Filler Identifier Sequence",
            vr => { SQ => "1" }
   },
   "0040,0031" => {
          desc => "Local Namespace Entity ID",
            vr => { UT => "1" }
   },
   "0040,0032" => {
          desc => "Universal Entity ID",
            vr => { UT => "1" }
   },
   "0040,0033" => {
          desc => "Universal Entity ID Type",
            vr => { CS => "1" }
   },
   "0040,0035" => {
          desc => "Identifier Type Code",
            vr => { CS => "1" }
   },
   "0040,0036" => {
          desc => "Assigning Facility Sequence",
            vr => { SQ => "1" }
   },
   "0040,0039" => {
          desc => "Assigning Jurisdiction Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,003a" => {
          desc => "Assigning Agency or Department Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,0100" => {
          desc => "Scheduled Procedure Step Sequence",
            vr => { SQ => "1" }
   },
   "0040,0220" => {
          desc => "Referenced Non-Image Composite SOP Instance Sequence ",
            vr => { SQ => "1" }
   },
   "0040,0241" => {
          desc => "Performed Station AE Title",
            vr => { AE => "1" }
   },
   "0040,0242" => {
          desc => "Performed Station Name",
            vr => { SH => "1" }
   },
   "0040,0243" => {
          desc => "Performed Location",
            vr => { SH => "1" }
   },
   "0040,0244" => {
          desc => "Performed Procedure Step Start Date",
            vr => { DA => "1" }
   },
   "0040,0245" => {
          desc => "Performed Procedure Step Start Time",
            vr => { TM => "1" }
   },
   "0040,0250" => {
          desc => "Performed Procedure Step End Date",
            vr => { DA => "1" }
   },
   "0040,0251" => {
          desc => "Performed Procedure Step End Time",
            vr => { TM => "1" }
   },
   "0040,0252" => {
          desc => "Performed Procedure Step Status",
            vr => { CS => "1" }
   },
   "0040,0253" => {
          desc => "Performed Procedure Step ID",
            vr => { SH => "1" }
   },
   "0040,0254" => {
          desc => "Performed Procedure Step Description",
            vr => { LO => "1" }
   },
   "0040,0255" => {
          desc => "Performed Procedure Type Description",
            vr => { LO => "1" }
   },
   "0040,0260" => {
          desc => "Performed Protocol Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,0261" => {
          desc => "Performed Protocol Type",
            vr => { CS => "1" }
   },
   "0040,0270" => {
          desc => "Scheduled Step Attributes Sequence",
            vr => { SQ => "1" }
   },
   "0040,0275" => {
          desc => "Request Attributes Sequence",
            vr => { SQ => "1" }
   },
   "0040,0280" => {
          desc => "Comments on the Performed Procedure Step",
            vr => { ST => "1" }
   },
   "0040,0281" => {
          desc => "Performed Procedure Step Discontinuation Reason Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,0293" => {
          desc => "Quantity Sequence",
            vr => { SQ => "1" }
   },
   "0040,0294" => {
          desc => "Quantity",
            vr => { DS => "1" }
   },
   "0040,0295" => {
          desc => "Measuring Units Sequence",
            vr => { SQ => "1" }
   },
   "0040,0296" => {
          desc => "Billing Item Sequence",
            vr => { SQ => "1" }
   },
   "0040,0300" => {
          desc => "Total Time of Fluoroscopy",
            vr => { US => "1" }
   },
   "0040,0301" => {
          desc => "Total Number of Exposures",
            vr => { US => "1" }
   },
   "0040,0302" => {
          desc => "Entrance Dose",
            vr => { US => "1" }
   },
   "0040,0303" => {
          desc => "Exposed Area",
            vr => { US => "1-2" }
   },
   "0040,0306" => {
          desc => "Distance Source to Entrance",
            vr => { DS => "1" }
   },
   "0040,0307" => {
          desc => "Distance Source to Support",
            vr => { DS => "1" },
           ret => 1
    },
   "0040,030e" => {
          desc => "Exposure Dose Sequence",
            vr => { SQ => "1" }
   },
   "0040,0310" => {
          desc => "Comments on Radiation Dose",
            vr => { ST => "1" }
   },
   "0040,0312" => {
          desc => "X-Ray Output",
            vr => { DS => "1" }
   },
   "0040,0314" => {
          desc => "Half Value Layer",
            vr => { DS => "1" }
   },
   "0040,0316" => {
          desc => "Organ Dose",
            vr => { DS => "1" }
   },
   "0040,0318" => {
          desc => "Organ Exposed",
            vr => { CS => "1" }
   },
   "0040,0320" => {
          desc => "Billing Procedure Step Sequence",
            vr => { SQ => "1" }
   },
   "0040,0321" => {
          desc => "Film Consumption Sequence",
            vr => { SQ => "1" }
   },
   "0040,0324" => {
          desc => "Billing Supplies and Devices Sequence",
            vr => { SQ => "1" }
   },
   "0040,0330" => {
          desc => "Referenced Procedure Step Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "0040,0340" => {
          desc => "Performed Series Sequence",
            vr => { SQ => "1" }
   },
   "0040,0400" => {
          desc => "Comments on the Scheduled Procedure Step",
            vr => { LT => "1" }
   },
   "0040,0440" => {
          desc => "Protocol Context Sequence",
            vr => { SQ => "1" }
   },
   "0040,0441" => {
          desc => "Content Item Modifier Sequence",
            vr => { SQ => "1" }
   },
   "0040,0500" => {
          desc => "Scheduled Specimen Sequence",
            vr => { SQ => "1" }
   },
   "0040,050a" => {
          desc => "Specimen Accession Number",
            vr => { LO => "1" },
           ret => 1
    },
   "0040,0512" => {
          desc => "Container Identifier",
            vr => { LO => "1" }
   },
   "0040,0513" => {
          desc => "Issuer of the Container Identifier Sequence",
            vr => { SQ => "1" }
   },
   "0040,0515" => {
          desc => "Alternate Container Identifier Sequence",
            vr => { SQ => "1" }
   },
   "0040,0518" => {
          desc => "Container Type Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,051a" => {
          desc => "Container Description",
            vr => { LO => "1" }
   },
   "0040,0520" => {
          desc => "Container Component Sequence",
            vr => { SQ => "1" }
   },
   "0040,0550" => {
          desc => "Specimen Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "0040,0551" => {
          desc => "Specimen Identifier",
            vr => { LO => "1" }
   },
   "0040,0552" => {
          desc => "Specimen Description Sequence - Trial",
            vr => { SQ => "1" },
           ret => 1
    },
   "0040,0553" => {
          desc => "Specimen Description - Trial",
            vr => { ST => "1" },
           ret => 1
    },
   "0040,0554" => {
          desc => "Specimen UID",
            vr => { UI => "1" }
   },
   "0040,0555" => {
          desc => "Acquisition Context Sequence",
            vr => { SQ => "1" }
   },
   "0040,0556" => {
          desc => "Acquisition Context Description",
            vr => { ST => "1" }
   },
   "0040,0560" => {
          desc => "Specimen Description Sequence",
            vr => { SQ => "1" }
   },
   "0040,0562" => {
          desc => "Issuer of the Specimen Identifier Sequence",
            vr => { SQ => "1" }
   },
   "0040,059a" => {
          desc => "Specimen Type Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,0600" => {
          desc => "Specimen Short Description ",
            vr => { LO => "1" }
   },
   "0040,0602" => {
          desc => "Specimen Detailed Description ",
            vr => { UT => "1" }
   },
   "0040,0610" => {
          desc => "Specimen Preparation Sequence",
            vr => { SQ => "1" }
   },
   "0040,0612" => {
          desc => "Specimen Preparation Step Content Item Sequence",
            vr => { SQ => "1" }
   },
   "0040,0620" => {
          desc => "Specimen Localization Content Item Sequence",
            vr => { SQ => "1" }
   },
   "0040,06fa" => {
          desc => "Slide Identifier",
            vr => { LO => "1" },
           ret => 1
    },
   "0040,071a" => {
          desc => "Image Center Point Coordinates Sequence",
            vr => { SQ => "1" }
   },
   "0040,072a" => {
          desc => "X offset in Slide Coordinate System",
            vr => { DS => "1" }
   },
   "0040,073a" => {
          desc => "Y offset in Slide Coordinate System",
            vr => { DS => "1" }
   },
   "0040,074a" => {
          desc => "Z offset in Slide Coordinate System",
            vr => { DS => "1" }
   },
   "0040,08d8" => {
          desc => "Pixel Spacing Sequence",
            vr => { SQ => "1" }
   },
   "0040,08da" => {
          desc => "Coordinate System Axis Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,08ea" => {
          desc => "Measurement Units Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,09f8" => {
          desc => "Vital Stain Code Sequence - Trial",
            vr => { SQ => "1" },
           ret => 1
    },
   "0040,1001" => {
          desc => "Requested Procedure ID",
            vr => { SH => "1" }
   },
   "0040,1002" => {
          desc => "Reason for the Requested Procedure",
            vr => { LO => "1" }
   },
   "0040,1003" => {
          desc => "Requested Procedure Priority ",
            vr => { SH => "1" }
   },
   "0040,1004" => {
          desc => "Patient Transport Arrangements",
            vr => { LO => "1" }
   },
   "0040,1005" => {
          desc => "Requested Procedure Location",
            vr => { LO => "1" }
   },
   "0040,1006" => {
          desc => "Placer Order Number / Procedure",
            vr => { SH => "1" },
           ret => 1
    },
   "0040,1007" => {
          desc => "Filler Order Number / Procedure",
            vr => { SH => "1" },
           ret => 1
    },
   "0040,1008" => {
          desc => "Confidentiality Code",
            vr => { LO => "1" }
   },
   "0040,1009" => {
          desc => "Reporting Priority",
            vr => { SH => "1" }
   },
   "0040,100a" => {
          desc => "Reason for Requested Procedure Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,1010" => {
          desc => "Names of Intended Recipients of Results",
            vr => { PN => "1-n" }
   },
   "0040,1011" => {
          desc => "Intended Recipients of Results Identification Sequence",
            vr => { SQ => "1" }
   },
   "0040,1012" => {
          desc => "Reason For Performed Procedure Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,1101" => {
          desc => "Person Identification Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,1102" => {
          desc => "Person's Address",
            vr => { ST => "1" }
   },
   "0040,1103" => {
          desc => "Person's Telephone Numbers",
            vr => { LO => "1-n" }
   },
   "0040,1400" => {
          desc => "Requested Procedure Comments",
            vr => { LT => "1" }
   },
   "0040,2001" => {
          desc => "Reason for the Imaging Service Request",
            vr => { LO => "1" },
           ret => 1
    },
   "0040,2004" => {
          desc => "Issue Date of Imaging Service Request",
            vr => { DA => "1" }
   },
   "0040,2005" => {
          desc => "Issue Time of Imaging Service Request",
            vr => { TM => "1" }
   },
   "0040,2006" => {
          desc => "Placer Order Number / Imaging Service Request (Retired)",
            vr => { SH => "1" },
           ret => 1
    },
   "0040,2007" => {
          desc => "Filler Order Number / Imaging Service Request (Retired)",
            vr => { SH => "1" },
           ret => 1
    },
   "0040,2008" => {
          desc => "Order Entered By",
            vr => { PN => "1" }
   },
   "0040,2009" => {
          desc => "Order Enterer's Location",
            vr => { SH => "1" }
   },
   "0040,2010" => {
          desc => "Order Callback Phone Number",
            vr => { SH => "1" }
   },
   "0040,2016" => {
          desc => "Placer Order Number / Imaging Service Request",
            vr => { LO => "1" }
   },
   "0040,2017" => {
          desc => "Filler Order Number / Imaging Service Request",
            vr => { LO => "1" }
   },
   "0040,2400" => {
          desc => "Imaging Service Request Comments",
            vr => { LT => "1" }
   },
   "0040,3001" => {
          desc => "Confidentiality Constraint on Patient Data Description",
            vr => { LO => "1" }
   },
   "0040,4001" => {
          desc => "General Purpose Scheduled Procedure Step Status",
            vr => { CS => "1" }
   },
   "0040,4002" => {
          desc => "General Purpose Performed Procedure Step Status",
            vr => { CS => "1" }
   },
   "0040,4003" => {
          desc => "General Purpose Scheduled Procedure Step Priority",
            vr => { CS => "1" }
   },
   "0040,4004" => {
          desc => "Scheduled Processing Applications Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,4005" => {
          desc => "Scheduled Procedure Step Start DateTime",
            vr => { DT => "1" }
   },
   "0040,4006" => {
          desc => "Multiple Copies Flag",
            vr => { CS => "1" }
   },
   "0040,4007" => {
          desc => "Performed Processing Applications Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,4009" => {
          desc => "Human Performer Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,4010" => {
          desc => "Scheduled Procedure Step Modification Date Time",
            vr => { DT => "1" }
   },
   "0040,4011" => {
          desc => "Expected Completion Date Time",
            vr => { DT => "1" }
   },
   "0040,4015" => {
          desc => "Resulting General Purpose Performed Procedure Steps Sequence",
            vr => { SQ => "1" }
   },
   "0040,4016" => {
          desc => "Referenced General Purpose Scheduled Procedure Step Sequence",
            vr => { SQ => "1" }
   },
   "0040,4018" => {
          desc => "Scheduled Workitem Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,4019" => {
          desc => "Performed Workitem Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,4020" => {
          desc => "Input Availability Flag",
            vr => { CS => "1" }
   },
   "0040,4021" => {
          desc => "Input Information Sequence",
            vr => { SQ => "1" }
   },
   "0040,4022" => {
          desc => "Relevant Information Sequence",
            vr => { SQ => "1" }
   },
   "0040,4023" => {
          desc => "Referenced General Purpose Scheduled Procedure Step Transaction UID",
            vr => { UI => "1" }
   },
   "0040,4025" => {
          desc => "Scheduled Station Name Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,4026" => {
          desc => "Scheduled Station Class Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,4027" => {
          desc => "Scheduled Station Geographic Location Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,4028" => {
          desc => "Performed Station Name Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,4029" => {
          desc => "Performed Station Class Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,4030" => {
          desc => "Performed Station Geographic Location Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,4031" => {
          desc => "Requested Subsequent Workitem Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,4032" => {
          desc => "Non-DICOM Output Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,4033" => {
          desc => "Output Information Sequence",
            vr => { SQ => "1" }
   },
   "0040,4034" => {
          desc => "Scheduled Human Performers Sequence",
            vr => { SQ => "1" }
   },
   "0040,4035" => {
          desc => "Actual Human Performers Sequence",
            vr => { SQ => "1" }
   },
   "0040,4036" => {
          desc => "Human Performer's Organization",
            vr => { LO => "1" }
   },
   "0040,4037" => {
          desc => "Human Performer's Name",
            vr => { PN => "1" }
   },
   "0040,4040" => {
          desc => "Raw Data Handling",
            vr => { CS => "1" }
   },
   "0040,8302" => {
          desc => "Entrance Dose in mGy",
            vr => { DS => "1" }
   },
   "0040,9094" => {
          desc => "Referenced Image Real World Value Mapping Sequence",
            vr => { SQ => "1" }
   },
   "0040,9096" => {
          desc => "Real World Value Mapping Sequence ",
            vr => { SQ => "1" }
   },
   "0040,9098" => {
          desc => "Pixel Value Mapping Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,9210" => {
          desc => "LUT Label",
            vr => { SH => "1" }
   },
   "0040,9211" => {
          desc => "Real World Value Last Value Mapped",
            vr => { SS => "1", US => "1" }
   },
   "0040,9212" => {
          desc => "Real World Value LUT Data",
            vr => { FD => "1-n" }
   },
   "0040,9216" => {
          desc => "Real World Value First Value Mapped",
            vr => { SS => "1", US => "1" }
   },
   "0040,9224" => {
          desc => "Real World Value Intercept",
            vr => { FD => "1" }
   },
   "0040,9225" => {
          desc => "Real World Value Slope",
            vr => { FD => "1" }
   },
   "0040,a010" => {
          desc => "Relationship Type",
            vr => { CS => "1" }
   },
   "0040,a027" => {
          desc => "Verifying Organization",
            vr => { LO => "1" }
   },
   "0040,a030" => {
          desc => "Verification Date Time",
            vr => { DT => "1" }
   },
   "0040,a032" => {
          desc => "Observation Date Time",
            vr => { DT => "1" }
   },
   "0040,a040" => {
          desc => "Value Type",
            vr => { CS => "1" }
   },
   "0040,a043" => {
          desc => "Concept Name Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,a050" => {
          desc => "Continuity Of Content",
            vr => { CS => "1" }
   },
   "0040,a073" => {
          desc => "Verifying Observer Sequence",
            vr => { SQ => "1" }
   },
   "0040,a075" => {
          desc => "Verifying Observer Name",
            vr => { PN => "1" }
   },
   "0040,a078" => {
          desc => "Author Observer Sequence",
            vr => { SQ => "1" }
   },
   "0040,a07a" => {
          desc => "Participant Sequence",
            vr => { SQ => "1" }
   },
   "0040,a07c" => {
          desc => "Custodial Organization Sequence",
            vr => { SQ => "1" }
   },
   "0040,a080" => {
          desc => "Participation Type",
            vr => { CS => "1" }
   },
   "0040,a082" => {
          desc => "Participation DateTime",
            vr => { DT => "1" }
   },
   "0040,a084" => {
          desc => "Observer Type",
            vr => { CS => "1" }
   },
   "0040,a088" => {
          desc => "Verifying Observer Identification Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,a090" => {
          desc => "Equivalent CDA Document Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "0040,a0b0" => {
          desc => "Referenced Waveform Channels",
            vr => { US => "2-2n" }
   },
   "0040,a120" => {
          desc => "DateTime",
            vr => { DT => "1" }
   },
   "0040,a121" => {
          desc => "Date",
            vr => { DA => "1" }
   },
   "0040,a122" => {
          desc => "Time",
            vr => { TM => "1" }
   },
   "0040,a123" => {
          desc => "Person Name",
            vr => { PN => "1" }
   },
   "0040,a124" => {
          desc => "UID",
            vr => { UI => "1" }
   },
   "0040,a130" => {
          desc => "Temporal Range Type",
            vr => { CS => "1" }
   },
   "0040,a132" => {
          desc => "Referenced Sample Positions",
            vr => { UL => "1-n" }
   },
   "0040,a136" => {
          desc => "Referenced Frame Numbers",
            vr => { US => "1-n" }
   },
   "0040,a138" => {
          desc => "Referenced Time Offsets",
            vr => { DS => "1-n" }
   },
   "0040,a13a" => {
          desc => "Referenced DateTime ",
            vr => { DT => "1-n" }
   },
   "0040,a160" => {
          desc => "Text Value",
            vr => { UT => "1" }
   },
   "0040,a168" => {
          desc => "Concept Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,a170" => {
          desc => "Purpose of Reference Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,a180" => {
          desc => "Annotation Group Number",
            vr => { US => "1" }
   },
   "0040,a195" => {
          desc => "Modifier Code Sequence ",
            vr => { SQ => "1" }
   },
   "0040,a300" => {
          desc => "Measured Value Sequence",
            vr => { SQ => "1" }
   },
   "0040,a301" => {
          desc => "Numeric Value Qualifier Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,a30a" => {
          desc => "Numeric Value",
            vr => { DS => "1-n" }
   },
   "0040,a353" => {
          desc => "Address - Trial",
            vr => { ST => "1" },
           ret => 1
    },
   "0040,a354" => {
          desc => "Telephone Number - Trial",
            vr => { LO => "1" },
           ret => 1
    },
   "0040,a360" => {
          desc => "Predecessor Documents Sequence",
            vr => { SQ => "1" }
   },
   "0040,a370" => {
          desc => "Referenced Request Sequence",
            vr => { SQ => "1" }
   },
   "0040,a372" => {
          desc => "Performed Procedure Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,a375" => {
          desc => "Current Requested Procedure Evidence Sequence",
            vr => { SQ => "1" }
   },
   "0040,a385" => {
          desc => "Pertinent Other Evidence Sequence",
            vr => { SQ => "1" }
   },
   "0040,a390" => {
          desc => "HL7 Structured Document Reference Sequence",
            vr => { SQ => "1" }
   },
   "0040,a491" => {
          desc => "Completion Flag",
            vr => { CS => "1" }
   },
   "0040,a492" => {
          desc => "Completion Flag Description",
            vr => { LO => "1" }
   },
   "0040,a493" => {
          desc => "Verification Flag",
            vr => { CS => "1" }
   },
   "0040,a494" => {
          desc => "Archive Requested",
            vr => { CS => "1" }
   },
   "0040,a496" => {
          desc => "Preliminary Flag",
            vr => { CS => "1" }
   },
   "0040,a504" => {
          desc => "Content Template Sequence",
            vr => { SQ => "1" }
   },
   "0040,a525" => {
          desc => "Identical Documents Sequence",
            vr => { SQ => "1" }
   },
   "0040,a730" => {
          desc => "Content Sequence",
            vr => { SQ => "1" }
   },
   "0040,b020" => {
          desc => "Waveform Annotation Sequence",
            vr => { SQ => "1" }
   },
   "0040,db00" => {
          desc => "Template Identifier",
            vr => { CS => "1" }
   },
   "0040,db06" => {
          desc => "Template Version",
            vr => { DT => "1" },
           ret => 1
    },
   "0040,db07" => {
          desc => "Template Local Version",
            vr => { DT => "1" },
           ret => 1
    },
   "0040,db0b" => {
          desc => "Template Extension Flag",
            vr => { CS => "1" },
           ret => 1
    },
   "0040,db0c" => {
          desc => "Template Extension Organization UID",
            vr => { UI => "1" },
           ret => 1
    },
   "0040,db0d" => {
          desc => "Template Extension Creator UID",
            vr => { UI => "1" },
           ret => 1
    },
   "0040,db73" => {
          desc => "Referenced Content Item Identifier",
            vr => { UL => "1-n" }
   },
   "0040,e001" => {
          desc => "HL7 Instance Identifier ",
            vr => { ST => "1" }
   },
   "0040,e004" => {
          desc => "HL7 Document Effective Time",
            vr => { DT => "1" }
   },
   "0040,e006" => {
          desc => "HL7 Document Type Code Sequence",
            vr => { SQ => "1" }
   },
   "0040,e010" => {
          desc => "Retrieve URI ",
            vr => { UT => "1" }
   },
   "0040,e011" => {
          desc => "Retrieve Location UID",
            vr => { UI => "1" }
   },
   "0042,0010" => {
          desc => "Document Title",
            vr => { ST => "1" }
   },
   "0042,0011" => {
          desc => "Encapsulated Document",
            vr => { OB => "1" }
   },
   "0042,0012" => {
          desc => "MIME Type of Encapsulated Document",
            vr => { LO => "1" }
   },
   "0042,0013" => {
          desc => "Source Instance Sequence",
            vr => { SQ => "1" }
   },
   "0042,0014" => {
          desc => "List of MIME Types",
            vr => { LO => "1-n" }
   },
   "0044,0001" => {
          desc => "Product Package Identifier",
            vr => { ST => "1" }
   },
   "0044,0002" => {
          desc => "Substance Administration Approval",
            vr => { CS => "1" }
   },
   "0044,0003" => {
          desc => "Approval Status Further Description",
            vr => { LT => "1" }
   },
   "0044,0004" => {
          desc => "Approval Status DateTime ",
            vr => { DT => "1" }
   },
   "0044,0007" => {
          desc => "Product Type Code Sequence",
            vr => { SQ => "1" }
   },
   "0044,0008" => {
          desc => "Product Name",
            vr => { LO => "1-n" }
   },
   "0044,0009" => {
          desc => "Product Description",
            vr => { LT => "1" }
   },
   "0044,000a" => {
          desc => "Product Lot Identifier",
            vr => { LO => "1" }
   },
   "0044,000b" => {
          desc => "Product Expiration DateTime",
            vr => { DT => "1" }
   },
   "0044,0010" => {
          desc => "Substance Administration DateTime",
            vr => { DT => "1" }
   },
   "0044,0011" => {
          desc => "Substance Administration Notes",
            vr => { LO => "1" }
   },
   "0044,0012" => {
          desc => "Substance Administration Device ID",
            vr => { LO => "1" }
   },
   "0044,0013" => {
          desc => "Product Parameter Sequence",
            vr => { SQ => "1" }
   },
   "0044,0019" => {
          desc => "Substance Administration Parameter Sequence",
            vr => { SQ => "1" }
   },
   "0046,0012" => {
          desc => "Lens Description",
            vr => { LO => "1" }
   },
   "0046,0014" => {
          desc => "Right Lens Sequence",
            vr => { SQ => "1" }
   },
   "0046,0015" => {
          desc => "Left Lens Sequence",
            vr => { SQ => "1" }
   },
   "0046,0016" => {
          desc => "Unspecified Laterality Lens Sequence",
            vr => { SQ => "1" }
   },
   "0046,0018" => {
          desc => "Cylinder Sequence",
            vr => { SQ => "1" }
   },
   "0046,0028" => {
          desc => "Prism Sequence",
            vr => { SQ => "1" }
   },
   "0046,0030" => {
          desc => "Horizontal Prism Power",
            vr => { FD => "1" }
   },
   "0046,0032" => {
          desc => "Horizontal Prism Base",
            vr => { CS => "1" }
   },
   "0046,0034" => {
          desc => "Vertical Prism Power",
            vr => { FD => "1" }
   },
   "0046,0036" => {
          desc => "Vertical Prism Base",
            vr => { CS => "1" }
   },
   "0046,0038" => {
          desc => "Lens Segment Type",
            vr => { CS => "1" }
   },
   "0046,0040" => {
          desc => "Optical Transmittance",
            vr => { FD => "1" }
   },
   "0046,0042" => {
          desc => "Channel Width",
            vr => { FD => "1" }
   },
   "0046,0044" => {
          desc => "Pupil Size",
            vr => { FD => "1" }
   },
   "0046,0046" => {
          desc => "Corneal Size",
            vr => { FD => "1" }
   },
   "0046,0050" => {
          desc => "Autorefraction Right Eye Sequence",
            vr => { SQ => "1" }
   },
   "0046,0052" => {
          desc => "Autorefraction Left Eye Sequence",
            vr => { SQ => "1" }
   },
   "0046,0060" => {
          desc => "Distance Pupillary Distance",
            vr => { FD => "1" }
   },
   "0046,0062" => {
          desc => "Near Pupillary Distance",
            vr => { FD => "1" }
   },
   "0046,0063" => {
          desc => "Intermediate Pupillary Distance",
            vr => { FD => "1" }
   },
   "0046,0064" => {
          desc => "Other Pupillary Distance",
            vr => { FD => "1" }
   },
   "0046,0070" => {
          desc => "Keratometry Right Eye Sequence",
            vr => { SQ => "1" }
   },
   "0046,0071" => {
          desc => "Keratometry Left Eye Sequence",
            vr => { SQ => "1" }
   },
   "0046,0074" => {
          desc => "Steep Keratometric Axis Sequence",
            vr => { SQ => "1" }
   },
   "0046,0075" => {
          desc => "Radius of Curvature",
            vr => { FD => "1" }
   },
   "0046,0076" => {
          desc => "Keratometric Power",
            vr => { FD => "1" }
   },
   "0046,0077" => {
          desc => "Keratometric Axis",
            vr => { FD => "1" }
   },
   "0046,0080" => {
          desc => "Flat Keratometric Axis Sequence",
            vr => { SQ => "1" }
   },
   "0046,0092" => {
          desc => "Background Color",
            vr => { CS => "1" }
   },
   "0046,0094" => {
          desc => "Optotype",
            vr => { CS => "1" }
   },
   "0046,0095" => {
          desc => "Optotype Presentation",
            vr => { CS => "1" }
   },
   "0046,0097" => {
          desc => "Subjective Refraction Right Eye Sequence",
            vr => { SQ => "1" }
   },
   "0046,0098" => {
          desc => "Subjective Refraction Left Eye Sequence",
            vr => { SQ => "1" }
   },
   "0046,0100" => {
          desc => "Add Near Sequence",
            vr => { SQ => "1" }
   },
   "0046,0101" => {
          desc => "Add Intermediate Sequence",
            vr => { SQ => "1" }
   },
   "0046,0102" => {
          desc => "Add Other Sequence",
            vr => { SQ => "1" }
   },
   "0046,0104" => {
          desc => "Add Power",
            vr => { FD => "1" }
   },
   "0046,0106" => {
          desc => "Viewing Distance",
            vr => { FD => "1" }
   },
   "0046,0121" => {
          desc => "Visual Acuity Type Code Sequence",
            vr => { SQ => "1" }
   },
   "0046,0122" => {
          desc => "Visual Acuity Right Eye Sequence",
            vr => { SQ => "1" }
   },
   "0046,0123" => {
          desc => "Visual Acuity Left Eye Sequence",
            vr => { SQ => "1" }
   },
   "0046,0124" => {
          desc => "Visual Acuity Both Eyes Open Sequence",
            vr => { SQ => "1" }
   },
   "0046,0125" => {
          desc => "Viewing Distance Type",
            vr => { CS => "1" }
   },
   "0046,0135" => {
          desc => "Visual Acuity Modifiers",
            vr => { SS => "2" }
   },
   "0046,0137" => {
          desc => "Decimal Visual Acuity",
            vr => { FD => "1" }
   },
   "0046,0139" => {
          desc => "Optotype Detailed Definition",
            vr => { LO => "1" }
   },
   "0046,0145" => {
          desc => "Referenced Refractive Measurements Sequence",
            vr => { SQ => "1" }
   },
   "0046,0146" => {
          desc => "Sphere Power",
            vr => { FD => "1" }
   },
   "0046,0147" => {
          desc => "Cylinder Power",
            vr => { FD => "1" }
   },
   "0050,0004" => {
          desc => "Calibration Image",
            vr => { CS => "1" }
   },
   "0050,0010" => {
          desc => "Device Sequence",
            vr => { SQ => "1" }
   },
   "0050,0012" => {
          desc => "Container Component Type Code Sequence",
            vr => { SQ => "1" }
   },
   "0050,0013" => {
          desc => "Container Component Thickness",
            vr => { FD => "1" }
   },
   "0050,0014" => {
          desc => "Device Length",
            vr => { DS => "1" }
   },
   "0050,0015" => {
          desc => "Container Component Width",
            vr => { FD => "1" }
   },
   "0050,0016" => {
          desc => "Device Diameter",
            vr => { DS => "1" }
   },
   "0050,0017" => {
          desc => "Device Diameter Units",
            vr => { CS => "1" }
   },
   "0050,0018" => {
          desc => "Device Volume",
            vr => { DS => "1" }
   },
   "0050,0019" => {
          desc => "Inter-Marker Distance",
            vr => { DS => "1" }
   },
   "0050,001a" => {
          desc => "Container Component Material",
            vr => { CS => "1" }
   },
   "0050,001b" => {
          desc => "Container Component ID",
            vr => { LO => "1" }
   },
   "0050,001c" => {
          desc => "Container Component Length",
            vr => { FD => "1" }
   },
   "0050,001d" => {
          desc => "Container Component Diameter",
            vr => { FD => "1" }
   },
   "0050,001e" => {
          desc => "Container Component Description",
            vr => { LO => "1" }
   },
   "0050,0020" => {
          desc => "Device Description",
            vr => { LO => "1" }
   },
   "0054,0010" => {
          desc => "Energy Window Vector",
            vr => { US => "1-n" }
   },
   "0054,0011" => {
          desc => "Number of Energy Windows",
            vr => { US => "1" }
   },
   "0054,0012" => {
          desc => "Energy Window Information Sequence",
            vr => { SQ => "1" }
   },
   "0054,0013" => {
          desc => "Energy Window Range Sequence",
            vr => { SQ => "1" }
   },
   "0054,0014" => {
          desc => "Energy Window Lower Limit",
            vr => { DS => "1" }
   },
   "0054,0015" => {
          desc => "Energy Window Upper Limit",
            vr => { DS => "1" }
   },
   "0054,0016" => {
          desc => "Radiopharmaceutical Information Sequence",
            vr => { SQ => "1" }
   },
   "0054,0017" => {
          desc => "Residual Syringe Counts",
            vr => { IS => "1" }
   },
   "0054,0018" => {
          desc => "Energy Window Name",
            vr => { SH => "1" }
   },
   "0054,0020" => {
          desc => "Detector Vector",
            vr => { US => "1-n" }
   },
   "0054,0021" => {
          desc => "Number of Detectors",
            vr => { US => "1" }
   },
   "0054,0022" => {
          desc => "Detector Information Sequence",
            vr => { SQ => "1" }
   },
   "0054,0030" => {
          desc => "Phase Vector",
            vr => { US => "1-n" }
   },
   "0054,0031" => {
          desc => "Number of Phases",
            vr => { US => "1" }
   },
   "0054,0032" => {
          desc => "Phase Information Sequence",
            vr => { SQ => "1" }
   },
   "0054,0033" => {
          desc => "Number of Frames in Phase",
            vr => { US => "1" }
   },
   "0054,0036" => {
          desc => "Phase Delay",
            vr => { IS => "1" }
   },
   "0054,0038" => {
          desc => "Pause Between Frames",
            vr => { IS => "1" }
   },
   "0054,0039" => {
          desc => "Phase Description",
            vr => { CS => "1" }
   },
   "0054,0050" => {
          desc => "Rotation Vector",
            vr => { US => "1-n" }
   },
   "0054,0051" => {
          desc => "Number of Rotations",
            vr => { US => "1" }
   },
   "0054,0052" => {
          desc => "Rotation Information Sequence",
            vr => { SQ => "1" }
   },
   "0054,0053" => {
          desc => "Number of Frames in Rotation",
            vr => { US => "1" }
   },
   "0054,0060" => {
          desc => "R-R Interval Vector",
            vr => { US => "1-n" }
   },
   "0054,0061" => {
          desc => "Number of R-R Intervals",
            vr => { US => "1" }
   },
   "0054,0062" => {
          desc => "Gated Information Sequence",
            vr => { SQ => "1" }
   },
   "0054,0063" => {
          desc => "Data Information Sequence",
            vr => { SQ => "1" }
   },
   "0054,0070" => {
          desc => "Time Slot Vector",
            vr => { US => "1-n" }
   },
   "0054,0071" => {
          desc => "Number of Time Slots",
            vr => { US => "1" }
   },
   "0054,0072" => {
          desc => "Time Slot Information Sequence",
            vr => { SQ => "1" }
   },
   "0054,0073" => {
          desc => "Time Slot Time",
            vr => { DS => "1" }
   },
   "0054,0080" => {
          desc => "Slice Vector",
            vr => { US => "1-n" }
   },
   "0054,0081" => {
          desc => "Number of Slices",
            vr => { US => "1" }
   },
   "0054,0090" => {
          desc => "Angular View Vector",
            vr => { US => "1-n" }
   },
   "0054,0100" => {
          desc => "Time Slice Vector",
            vr => { US => "1-n" }
   },
   "0054,0101" => {
          desc => "Number of Time Slices",
            vr => { US => "1" }
   },
   "0054,0200" => {
          desc => "Start Angle",
            vr => { DS => "1" }
   },
   "0054,0202" => {
          desc => "Type of Detector Motion",
            vr => { CS => "1" }
   },
   "0054,0210" => {
          desc => "Trigger Vector",
            vr => { IS => "1-n" }
   },
   "0054,0211" => {
          desc => "Number of Triggers in Phase",
            vr => { US => "1" }
   },
   "0054,0220" => {
          desc => "View Code Sequence",
            vr => { SQ => "1" }
   },
   "0054,0222" => {
          desc => "View Modifier Code Sequence",
            vr => { SQ => "1" }
   },
   "0054,0300" => {
          desc => "Radionuclide Code Sequence",
            vr => { SQ => "1" }
   },
   "0054,0302" => {
          desc => "Administration Route Code Sequence",
            vr => { SQ => "1" }
   },
   "0054,0304" => {
          desc => "Radiopharmaceutical Code Sequence",
            vr => { SQ => "1" }
   },
   "0054,0306" => {
          desc => "Calibration Data Sequence",
            vr => { SQ => "1" }
   },
   "0054,0308" => {
          desc => "Energy Window Number",
            vr => { US => "1" }
   },
   "0054,0400" => {
          desc => "Image ID",
            vr => { SH => "1" }
   },
   "0054,0410" => {
          desc => "Patient Orientation Code Sequence",
            vr => { SQ => "1" }
   },
   "0054,0412" => {
          desc => "Patient Orientation Modifier Code Sequence",
            vr => { SQ => "1" }
   },
   "0054,0414" => {
          desc => "Patient Gantry Relationship Code Sequence",
            vr => { SQ => "1" }
   },
   "0054,0500" => {
          desc => "Slice Progression Direction",
            vr => { CS => "1" }
   },
   "0054,1000" => {
          desc => "Series Type",
            vr => { CS => "2" }
   },
   "0054,1001" => {
          desc => "Units",
            vr => { CS => "1" }
   },
   "0054,1002" => {
          desc => "Counts Source",
            vr => { CS => "1" }
   },
   "0054,1004" => {
          desc => "Reprojection Method",
            vr => { CS => "1" }
   },
   "0054,1100" => {
          desc => "Randoms Correction Method",
            vr => { CS => "1" }
   },
   "0054,1101" => {
          desc => "Attenuation Correction Method",
            vr => { LO => "1" }
   },
   "0054,1102" => {
          desc => "Decay Correction",
            vr => { CS => "1" }
   },
   "0054,1103" => {
          desc => "Reconstruction Method",
            vr => { LO => "1" }
   },
   "0054,1104" => {
          desc => "Detector Lines of Response Used",
            vr => { LO => "1" }
   },
   "0054,1105" => {
          desc => "Scatter Correction Method",
            vr => { LO => "1" }
   },
   "0054,1200" => {
          desc => "Axial Acceptance",
            vr => { DS => "1" }
   },
   "0054,1201" => {
          desc => "Axial Mash",
            vr => { IS => "2" }
   },
   "0054,1202" => {
          desc => "Transverse Mash",
            vr => { IS => "1" }
   },
   "0054,1203" => {
          desc => "Detector Element Size",
            vr => { DS => "2" }
   },
   "0054,1210" => {
          desc => "Coincidence Window Width",
            vr => { DS => "1" }
   },
   "0054,1220" => {
          desc => "Secondary Counts Type",
            vr => { CS => "1-n" }
   },
   "0054,1300" => {
          desc => "Frame Reference Time",
            vr => { DS => "1" }
   },
   "0054,1310" => {
          desc => "Primary (Prompts) Counts Accumulated",
            vr => { IS => "1" }
   },
   "0054,1311" => {
          desc => "Secondary Counts Accumulated",
            vr => { IS => "1-n" }
   },
   "0054,1320" => {
          desc => "Slice Sensitivity Factor",
            vr => { DS => "1" }
   },
   "0054,1321" => {
          desc => "Decay Factor",
            vr => { DS => "1" }
   },
   "0054,1322" => {
          desc => "Dose Calibration Factor",
            vr => { DS => "1" }
   },
   "0054,1323" => {
          desc => "Scatter Fraction Factor",
            vr => { DS => "1" }
   },
   "0054,1324" => {
          desc => "Dead Time Factor",
            vr => { DS => "1" }
   },
   "0054,1330" => {
          desc => "Image Index",
            vr => { US => "1" }
   },
   "0054,1400" => {
          desc => "Counts Included",
            vr => { CS => "1-n" },
           ret => 1
    },
   "0054,1401" => {
          desc => "Dead Time Correction Flag",
            vr => { CS => "1" },
           ret => 1
    },
   "0060,3000" => {
          desc => "Histogram Sequence",
            vr => { SQ => "1" }
   },
   "0060,3002" => {
          desc => "Histogram Number of Bins",
            vr => { US => "1" }
   },
   "0060,3004" => {
          desc => "Histogram First Bin Value",
            vr => { SS => "1", US => "1" }
   },
   "0060,3006" => {
          desc => "Histogram Last Bin Value",
            vr => { SS => "1", US => "1" }
   },
   "0060,3008" => {
          desc => "Histogram Bin Width",
            vr => { US => "1" }
   },
   "0060,3010" => {
          desc => "Histogram Explanation",
            vr => { LO => "1" }
   },
   "0060,3020" => {
          desc => "Histogram Data",
            vr => { UL => "1-n" }
   },
   "0062,0001" => {
          desc => "Segmentation Type",
            vr => { CS => "1" }
   },
   "0062,0002" => {
          desc => "Segment Sequence",
            vr => { SQ => "1" }
   },
   "0062,0003" => {
          desc => "Segmented Property Category Code Sequence",
            vr => { SQ => "1" }
   },
   "0062,0004" => {
          desc => "Segment Number",
            vr => { US => "1" }
   },
   "0062,0005" => {
          desc => "Segment Label",
            vr => { LO => "1" }
   },
   "0062,0006" => {
          desc => "Segment Description",
            vr => { ST => "1" }
   },
   "0062,0008" => {
          desc => "Segment Algorithm Type",
            vr => { CS => "1" }
   },
   "0062,0009" => {
          desc => "Segment Algorithm Name",
            vr => { LO => "1" }
   },
   "0062,000a" => {
          desc => "Segment Identification Sequence",
            vr => { SQ => "1" }
   },
   "0062,000b" => {
          desc => "Referenced Segment Number",
            vr => { US => "1-n" }
   },
   "0062,000c" => {
          desc => "Recommended Display Grayscale Value",
            vr => { US => "1" }
   },
   "0062,000d" => {
          desc => "Recommended Display CIELab Value",
            vr => { US => "3" }
   },
   "0062,000e" => {
          desc => "Maximum Fractional Value",
            vr => { US => "1" }
   },
   "0062,000f" => {
          desc => "Segmented Property Type Code Sequence",
            vr => { SQ => "1" }
   },
   "0062,0010" => {
          desc => "Segmentation Fractional Type",
            vr => { CS => "1" }
   },
   "0064,0002" => {
          desc => "Deformable Registration Sequence",
            vr => { SQ => "1" }
   },
   "0064,0003" => {
          desc => "Source Frame of Reference UID",
            vr => { UI => "1" }
   },
   "0064,0005" => {
          desc => "Deformable Registration Grid Sequence",
            vr => { SQ => "1" }
   },
   "0064,0007" => {
          desc => "Grid Dimensions",
            vr => { UL => "3" }
   },
   "0064,0008" => {
          desc => "Grid Resolution",
            vr => { FD => "3" }
   },
   "0064,0009" => {
          desc => "Vector Grid Data",
            vr => { OF => "1" }
   },
   "0064,000f" => {
          desc => "Pre Deformation Matrix Registration Sequence",
            vr => { SQ => "1" }
   },
   "0064,0010" => {
          desc => "Post Deformation Matrix Registration Sequence",
            vr => { SQ => "1" }
   },
   "0066,0001" => {
          desc => "Number of Surfaces",
            vr => { UL => "1" }
   },
   "0066,0002" => {
          desc => "Surface Sequence",
            vr => { SQ => "1" }
   },
   "0066,0003" => {
          desc => "Surface Number",
            vr => { UL => "1" }
   },
   "0066,0004" => {
          desc => "Surface Comments",
            vr => { LT => "1" }
   },
   "0066,0009" => {
          desc => "Surface Processing",
            vr => { CS => "1" }
   },
   "0066,000a" => {
          desc => "Surface Processing Ratio",
            vr => { FL => "1" }
   },
   "0066,000b" => {
          desc => "Surface Processing Description",
            vr => { LO => "1" }
   },
   "0066,000c" => {
          desc => "Recommended Presentation Opacity",
            vr => { FL => "1" }
   },
   "0066,000d" => {
          desc => "Recommended Presentation Type",
            vr => { CS => "1" }
   },
   "0066,000e" => {
          desc => "Finite Volume",
            vr => { CS => "1" }
   },
   "0066,0010" => {
          desc => "Manifold",
            vr => { CS => "1" }
   },
   "0066,0011" => {
          desc => "Surface Points Sequence",
            vr => { SQ => "1" }
   },
   "0066,0012" => {
          desc => "Surface Points Normals Sequence",
            vr => { SQ => "1" }
   },
   "0066,0013" => {
          desc => "Surface Mesh Primitives Sequence",
            vr => { SQ => "1" }
   },
   "0066,0015" => {
          desc => "Number of Surface Points",
            vr => { UL => "1" }
   },
   "0066,0016" => {
          desc => "Point Coordinates Data",
            vr => { OF => "1" }
   },
   "0066,0017" => {
          desc => "Point Position Accuracy",
            vr => { FL => "3" }
   },
   "0066,0018" => {
          desc => "Mean Point Distance",
            vr => { FL => "1" }
   },
   "0066,0019" => {
          desc => "Maximum Point Distance",
            vr => { FL => "1" }
   },
   "0066,001a" => {
          desc => "Points Bounding Box Coordinates",
            vr => { FL => "6" }
   },
   "0066,001b" => {
          desc => "Axis of Rotation",
            vr => { FL => "3" }
   },
   "0066,001c" => {
          desc => "Center of Rotation",
            vr => { FL => "3" }
   },
   "0066,001e" => {
          desc => "Number of Vectors",
            vr => { UL => "1" }
   },
   "0066,001f" => {
          desc => "Vector Dimensionality",
            vr => { US => "1" }
   },
   "0066,0020" => {
          desc => "Vector Accuracy",
            vr => { FL => "1-n" }
   },
   "0066,0021" => {
          desc => "Vector Coordinate Data",
            vr => { OF => "1" }
   },
   "0066,0023" => {
          desc => "Triangle Point Index List",
            vr => { OW => "1" }
   },
   "0066,0024" => {
          desc => "Edge Point Index List",
            vr => { OW => "1" }
   },
   "0066,0025" => {
          desc => "Vertex Point Index List",
            vr => { OW => "1" }
   },
   "0066,0026" => {
          desc => "Triangle Strip Sequence",
            vr => { SQ => "1" }
   },
   "0066,0027" => {
          desc => "Triangle Fan Sequence",
            vr => { SQ => "1" }
   },
   "0066,0028" => {
          desc => "Line Sequence",
            vr => { SQ => "1" }
   },
   "0066,0029" => {
          desc => "Primitive Point Index List",
            vr => { OW => "1" }
   },
   "0066,002a" => {
          desc => "Surface Count",
            vr => { UL => "1" }
   },
   "0066,002b" => {
          desc => "Referenced Surface Sequence",
            vr => { SQ => "1" }
   },
   "0066,002c" => {
          desc => "Referenced Surface Number",
            vr => { UL => "1" }
   },
   "0066,002d" => {
          desc => "Segment Surface Generation Algorithm Identification Sequence",
            vr => { SQ => "1" }
   },
   "0066,002e" => {
          desc => "Segment Surface Source Instance Sequence",
            vr => { SQ => "1" }
   },
   "0066,002f" => {
          desc => "Algorithm Family Code Sequence",
            vr => { SQ => "1" }
   },
   "0066,0030" => {
          desc => "Algorithm Name Code Sequence",
            vr => { SQ => "1" }
   },
   "0066,0031" => {
          desc => "Algorithm Version",
            vr => { LO => "1" }
   },
   "0066,0032" => {
          desc => "Algorithm Parameters",
            vr => { LT => "1" }
   },
   "0066,0034" => {
          desc => "Facet Sequence",
            vr => { SQ => "1" }
   },
   "0066,0035" => {
          desc => "Surface Processing Algorithm Identification Sequence",
            vr => { SQ => "1" }
   },
   "0066,0036" => {
          desc => "Algorithm Name",
            vr => { LO => "1" }
   },
   "0070,0001" => {
          desc => "Graphic Annotation Sequence",
            vr => { SQ => "1" }
   },
   "0070,0002" => {
          desc => "Graphic Layer",
            vr => { CS => "1" }
   },
   "0070,0003" => {
          desc => "Bounding Box Annotation Units",
            vr => { CS => "1" }
   },
   "0070,0004" => {
          desc => "Anchor Point Annotation Units",
            vr => { CS => "1" }
   },
   "0070,0005" => {
          desc => "Graphic Annotation Units",
            vr => { CS => "1" }
   },
   "0070,0006" => {
          desc => "Unformatted Text Value",
            vr => { ST => "1" }
   },
   "0070,0008" => {
          desc => "Text Object Sequence",
            vr => { SQ => "1" }
   },
   "0070,0009" => {
          desc => "Graphic Object Sequence",
            vr => { SQ => "1" }
   },
   "0070,0010" => {
          desc => "Bounding Box Top Left Hand Corner",
            vr => { FL => "2" }
   },
   "0070,0011" => {
          desc => "Bounding Box Bottom Right Hand Corner",
            vr => { FL => "2" }
   },
   "0070,0012" => {
          desc => "Bounding Box Text Horizontal Justification",
            vr => { CS => "1" }
   },
   "0070,0014" => {
          desc => "Anchor Point",
            vr => { FL => "2" }
   },
   "0070,0015" => {
          desc => "Anchor Point Visibility",
            vr => { CS => "1" }
   },
   "0070,0020" => {
          desc => "Graphic Dimensions ",
            vr => { US => "1" }
   },
   "0070,0021" => {
          desc => "Number of Graphic Points",
            vr => { US => "1" }
   },
   "0070,0022" => {
          desc => "Graphic Data",
            vr => { FL => "2-n" }
   },
   "0070,0023" => {
          desc => "Graphic Type",
            vr => { CS => "1" }
   },
   "0070,0024" => {
          desc => "Graphic Filled",
            vr => { CS => "1" }
   },
   "0070,0040" => {
          desc => "Image Rotation (Retired)",
            vr => { IS => "1" },
           ret => 1
    },
   "0070,0041" => {
          desc => "Image Horizontal Flip",
            vr => { CS => "1" }
   },
   "0070,0042" => {
          desc => "Image Rotation ",
            vr => { US => "1" }
   },
   "0070,0050" => {
          desc => "Displayed Area Top Left Hand Corner (Trial)",
            vr => { US => "2" },
           ret => 1
    },
   "0070,0051" => {
          desc => "Displayed Area Bottom Right Hand Corner (Trial)",
            vr => { US => "2" },
           ret => 1
    },
   "0070,0052" => {
          desc => "Displayed Area Top Left Hand Corner",
            vr => { SL => "2" }
   },
   "0070,0053" => {
          desc => "Displayed Area Bottom Right Hand Corner",
            vr => { SL => "2" }
   },
   "0070,005a" => {
          desc => "Displayed Area Selection Sequence",
            vr => { SQ => "1" }
   },
   "0070,0060" => {
          desc => "Graphic Layer Sequence",
            vr => { SQ => "1" }
   },
   "0070,0062" => {
          desc => "Graphic Layer Order",
            vr => { IS => "1" }
   },
   "0070,0066" => {
          desc => "Graphic Layer Recommended Display Grayscale Value",
            vr => { US => "1" }
   },
   "0070,0067" => {
          desc => "Graphic Layer Recommended Display RGB Value",
            vr => { US => "3" },
           ret => 1
    },
   "0070,0068" => {
          desc => "Graphic Layer Description",
            vr => { LO => "1" }
   },
   "0070,0080" => {
          desc => "Content Label",
            vr => { CS => "1" }
   },
   "0070,0081" => {
          desc => "Content Description",
            vr => { LO => "1" }
   },
   "0070,0082" => {
          desc => "Presentation Creation Date",
            vr => { DA => "1" }
   },
   "0070,0083" => {
          desc => "Presentation Creation Time",
            vr => { TM => "1" }
   },
   "0070,0084" => {
          desc => "Content Creator's Name",
            vr => { PN => "1" }
   },
   "0070,0086" => {
          desc => "Content Creator's Identification Code Sequence",
            vr => { SQ => "1" }
   },
   "0070,0087" => {
          desc => "Alternate Content Description Sequence",
            vr => { SQ => "1" }
   },
   "0070,0100" => {
          desc => "Presentation Size Mode",
            vr => { CS => "1" }
   },
   "0070,0101" => {
          desc => "Presentation Pixel Spacing",
            vr => { DS => "2" }
   },
   "0070,0102" => {
          desc => "Presentation Pixel Aspect Ratio",
            vr => { IS => "2" }
   },
   "0070,0103" => {
          desc => "Presentation Pixel Magnification Ratio",
            vr => { FL => "1" }
   },
   "0070,0306" => {
          desc => "Shape Type",
            vr => { CS => "1" }
   },
   "0070,0308" => {
          desc => "Registration Sequence",
            vr => { SQ => "1" }
   },
   "0070,0309" => {
          desc => "Matrix Registration Sequence",
            vr => { SQ => "1" }
   },
   "0070,030a" => {
          desc => "Matrix Sequence",
            vr => { SQ => "1" }
   },
   "0070,030c" => {
          desc => "Frame of Reference Transformation Matrix Type",
            vr => { CS => "1" }
   },
   "0070,030d" => {
          desc => "Registration Type Code Sequence",
            vr => { SQ => "1" }
   },
   "0070,030f" => {
          desc => "Fiducial Description",
            vr => { ST => "1" }
   },
   "0070,0310" => {
          desc => "Fiducial Identifier",
            vr => { SH => "1" }
   },
   "0070,0311" => {
          desc => "Fiducial Identifier Code Sequence",
            vr => { SQ => "1" }
   },
   "0070,0312" => {
          desc => "Contour Uncertainty Radius",
            vr => { FD => "1" }
   },
   "0070,0314" => {
          desc => "Used Fiducials Sequence",
            vr => { SQ => "1" }
   },
   "0070,0318" => {
          desc => "Graphic Coordinates Data Sequence",
            vr => { SQ => "1" }
   },
   "0070,031a" => {
          desc => "Fiducial UID",
            vr => { UI => "1" }
   },
   "0070,031c" => {
          desc => "Fiducial Set Sequence",
            vr => { SQ => "1" }
   },
   "0070,031e" => {
          desc => "Fiducial Sequence",
            vr => { SQ => "1" }
   },
   "0070,0401" => {
          desc => "Graphic Layer Recommended Display CIELab Value",
            vr => { US => "3" }
   },
   "0070,0402" => {
          desc => "Blending Sequence",
            vr => { SQ => "1" }
   },
   "0070,0403" => {
          desc => "Relative Opacity",
            vr => { FL => "1" }
   },
   "0070,0404" => {
          desc => "Referenced Spatial Registration Sequence",
            vr => { SQ => "1" }
   },
   "0070,0405" => {
          desc => "Blending Position",
            vr => { CS => "1" }
   },
   "0072,0002" => {
          desc => "Hanging Protocol Name",
            vr => { SH => "1" }
   },
   "0072,0004" => {
          desc => "Hanging Protocol Description",
            vr => { LO => "1" }
   },
   "0072,0006" => {
          desc => "Hanging Protocol Level",
            vr => { CS => "1" }
   },
   "0072,0008" => {
          desc => "Hanging Protocol Creator",
            vr => { LO => "1" }
   },
   "0072,000a" => {
          desc => "Hanging Protocol Creation DateTime",
            vr => { DT => "1" }
   },
   "0072,000c" => {
          desc => "Hanging Protocol Definition Sequence",
            vr => { SQ => "1" }
   },
   "0072,000e" => {
          desc => "Hanging Protocol User Identification Code Sequence",
            vr => { SQ => "1" }
   },
   "0072,0010" => {
          desc => "Hanging Protocol User Group Name",
            vr => { LO => "1" }
   },
   "0072,0012" => {
          desc => "Source Hanging Protocol Sequence",
            vr => { SQ => "1" }
   },
   "0072,0014" => {
          desc => "Number of Priors Referenced",
            vr => { US => "1" }
   },
   "0072,0020" => {
          desc => "Image Sets Sequence",
            vr => { SQ => "1" }
   },
   "0072,0022" => {
          desc => "Image Set Selector Sequence",
            vr => { SQ => "1" }
   },
   "0072,0024" => {
          desc => "Image Set Selector Usage Flag",
            vr => { CS => "1" }
   },
   "0072,0026" => {
          desc => "Selector Attribute",
            vr => { AT => "1" }
   },
   "0072,0028" => {
          desc => "Selector Value Number",
            vr => { US => "1" }
   },
   "0072,0030" => {
          desc => "Time Based Image Sets Sequence",
            vr => { SQ => "1" }
   },
   "0072,0032" => {
          desc => "Image Set Number",
            vr => { US => "1" }
   },
   "0072,0034" => {
          desc => "Image Set Selector Category",
            vr => { CS => "1" }
   },
   "0072,0038" => {
          desc => "Relative Time",
            vr => { US => "2" }
   },
   "0072,003a" => {
          desc => "Relative Time Units",
            vr => { CS => "1" }
   },
   "0072,003c" => {
          desc => "Abstract Prior Value",
            vr => { SS => "2" }
   },
   "0072,003e" => {
          desc => "Abstract Prior Code Sequence",
            vr => { SQ => "1" }
   },
   "0072,0040" => {
          desc => "Image Set Label",
            vr => { LO => "1" }
   },
   "0072,0050" => {
          desc => "Selector Attribute VR",
            vr => { CS => "1" }
   },
   "0072,0052" => {
          desc => "Selector Sequence Pointer",
            vr => { AT => "1" }
   },
   "0072,0054" => {
          desc => "Selector Sequence Pointer Private Creator",
            vr => { LO => "1" }
   },
   "0072,0056" => {
          desc => "Selector Attribute Private Creator",
            vr => { LO => "1" }
   },
   "0072,0060" => {
          desc => "Selector AT Value",
            vr => { AT => "1-n" }
   },
   "0072,0062" => {
          desc => "Selector CS Value",
            vr => { CS => "1-n" }
   },
   "0072,0064" => {
          desc => "Selector IS Value",
            vr => { IS => "1-n" }
   },
   "0072,0066" => {
          desc => "Selector LO Value",
            vr => { LO => "1-n" }
   },
   "0072,0068" => {
          desc => "Selector LT Value",
            vr => { LT => "1" }
   },
   "0072,006a" => {
          desc => "Selector PN Value",
            vr => { PN => "1-n" }
   },
   "0072,006c" => {
          desc => "Selector SH Value",
            vr => { SH => "1-n" }
   },
   "0072,006e" => {
          desc => "Selector ST Value",
            vr => { ST => "1" }
   },
   "0072,0070" => {
          desc => "Selector UT Value",
            vr => { UT => "1" }
   },
   "0072,0072" => {
          desc => "Selector DS Value",
            vr => { DS => "1-n" }
   },
   "0072,0074" => {
          desc => "Selector FD Value",
            vr => { FD => "1-n" }
   },
   "0072,0076" => {
          desc => "Selector FL Value",
            vr => { FL => "1-n" }
   },
   "0072,0078" => {
          desc => "Selector UL Value",
            vr => { UL => "1-n" }
   },
   "0072,007a" => {
          desc => "Selector US Value",
            vr => { US => "1-n" }
   },
   "0072,007c" => {
          desc => "Selector SL Value",
            vr => { SL => "1-n" }
   },
   "0072,007e" => {
          desc => "Selector SS Value",
            vr => { SS => "1-n" }
   },
   "0072,0080" => {
          desc => "Selector Code Sequence Value",
            vr => { SQ => "1" }
   },
   "0072,0100" => {
          desc => "Number of Screens",
            vr => { US => "1" }
   },
   "0072,0102" => {
          desc => "Nominal Screen Definition Sequence",
            vr => { SQ => "1" }
   },
   "0072,0104" => {
          desc => "Number of Vertical Pixels",
            vr => { US => "1" }
   },
   "0072,0106" => {
          desc => "Number of Horizontal Pixels",
            vr => { US => "1" }
   },
   "0072,0108" => {
          desc => "Display Environment Spatial Position",
            vr => { FD => "4" }
   },
   "0072,010a" => {
          desc => "Screen Minimum Grayscale Bit Depth",
            vr => { US => "1" }
   },
   "0072,010c" => {
          desc => "Screen Minimum Color Bit Depth",
            vr => { US => "1" }
   },
   "0072,010e" => {
          desc => "Application Maximum Repaint Time",
            vr => { US => "1" }
   },
   "0072,0200" => {
          desc => "Display Sets Sequence",
            vr => { SQ => "1" }
   },
   "0072,0202" => {
          desc => "Display Set Number",
            vr => { US => "1" }
   },
   "0072,0203" => {
          desc => "Display Set Label",
            vr => { LO => "1" }
   },
   "0072,0204" => {
          desc => "Display Set Presentation Group",
            vr => { US => "1" }
   },
   "0072,0206" => {
          desc => "Display Set Presentation Group Description",
            vr => { LO => "1" }
   },
   "0072,0208" => {
          desc => "Partial Data Display Handling",
            vr => { CS => "1" }
   },
   "0072,0210" => {
          desc => "Synchronized Scrolling Sequence",
            vr => { SQ => "1" }
   },
   "0072,0212" => {
          desc => "Display Set Scrolling Group",
            vr => { US => "2-n" }
   },
   "0072,0214" => {
          desc => "Navigation Indicator Sequence",
            vr => { SQ => "1" }
   },
   "0072,0216" => {
          desc => "Navigation Display Set ",
            vr => { US => "1" }
   },
   "0072,0218" => {
          desc => "Reference Display Sets",
            vr => { US => "1-n" }
   },
   "0072,0300" => {
          desc => "Image Boxes Sequence",
            vr => { SQ => "1" }
   },
   "0072,0302" => {
          desc => "Image Box Number",
            vr => { US => "1" }
   },
   "0072,0304" => {
          desc => "Image Box Layout Type",
            vr => { CS => "1" }
   },
   "0072,0306" => {
          desc => "Image Box Tile Horizontal Dimension",
            vr => { US => "1" }
   },
   "0072,0308" => {
          desc => "Image Box Tile Vertical Dimension",
            vr => { US => "1" }
   },
   "0072,0310" => {
          desc => "Image Box Scroll Direction",
            vr => { CS => "1" }
   },
   "0072,0312" => {
          desc => "Image Box Small Scroll Type",
            vr => { CS => "1" }
   },
   "0072,0314" => {
          desc => "Image Box Small Scroll Amount",
            vr => { US => "1" }
   },
   "0072,0316" => {
          desc => "Image Box Large Scroll Type",
            vr => { CS => "1" }
   },
   "0072,0318" => {
          desc => "Image Box Large Scroll Amount",
            vr => { US => "1" }
   },
   "0072,0320" => {
          desc => "Image Box Overlap Priority",
            vr => { US => "1" }
   },
   "0072,0330" => {
          desc => "Cine Relative to Real-Time",
            vr => { FD => "1" }
   },
   "0072,0400" => {
          desc => "Filter Operations Sequence",
            vr => { SQ => "1" }
   },
   "0072,0402" => {
          desc => "Filter-by Category",
            vr => { CS => "1" }
   },
   "0072,0404" => {
          desc => "Filter-by Attribute Presence",
            vr => { CS => "1" }
   },
   "0072,0406" => {
          desc => "Filter-by Operator",
            vr => { CS => "1" }
   },
   "0072,0420" => {
          desc => "Structured Display Background CIELab Value",
            vr => { US => "3" }
   },
   "0072,0421" => {
          desc => "Empty Image Box CIELab Value",
            vr => { US => "3" }
   },
   "0072,0422" => {
          desc => "Structured Display Image Box Sequence",
            vr => { SQ => "1" }
   },
   "0072,0424" => {
          desc => "Structured Display Text Box Sequence",
            vr => { SQ => "1" }
   },
   "0072,0427" => {
          desc => "Referenced First Frame Sequence",
            vr => { SQ => "1" }
   },
   "0072,0430" => {
          desc => "Image Box Synchronization Sequence",
            vr => { SQ => "1" }
   },
   "0072,0432" => {
          desc => "Synchronized Image Box List",
            vr => { US => "2-n" }
   },
   "0072,0434" => {
          desc => "Type of Synchronization",
            vr => { CS => "1" }
   },
   "0072,0500" => {
          desc => "Blending Operation Type",
            vr => { CS => "1" }
   },
   "0072,0510" => {
          desc => "Reformatting Operation Type",
            vr => { CS => "1" }
   },
   "0072,0512" => {
          desc => "Reformatting Thickness",
            vr => { FD => "1" }
   },
   "0072,0514" => {
          desc => "Reformatting Interval",
            vr => { FD => "1" }
   },
   "0072,0516" => {
          desc => "Reformatting Operation Initial View Direction",
            vr => { CS => "1" }
   },
   "0072,0520" => {
          desc => "3D Rendering Type",
            vr => { CS => "1-n" }
   },
   "0072,0600" => {
          desc => "Sorting Operations Sequence",
            vr => { SQ => "1" }
   },
   "0072,0602" => {
          desc => "Sort-by Category",
            vr => { CS => "1" }
   },
   "0072,0604" => {
          desc => "Sorting Direction",
            vr => { CS => "1" }
   },
   "0072,0700" => {
          desc => "Display Set Patient Orientation",
            vr => { CS => "2" }
   },
   "0072,0702" => {
          desc => "VOI Type",
            vr => { CS => "1" }
   },
   "0072,0704" => {
          desc => "Pseudo-Color Type",
            vr => { CS => "1" }
   },
   "0072,0706" => {
          desc => "Show Grayscale Inverted",
            vr => { CS => "1" }
   },
   "0072,0710" => {
          desc => "Show Image True Size Flag",
            vr => { CS => "1" }
   },
   "0072,0712" => {
          desc => "Show Graphic Annotation Flag",
            vr => { CS => "1" }
   },
   "0072,0714" => {
          desc => "Show Patient Demographics Flag",
            vr => { CS => "1" }
   },
   "0072,0716" => {
          desc => "Show Acquisition Techniques Flag",
            vr => { CS => "1" }
   },
   "0072,0717" => {
          desc => "Display Set Horizontal Justification ",
            vr => { CS => "1" }
   },
   "0072,0718" => {
          desc => "Display Set Vertical Justification",
            vr => { CS => "1" }
   },
   "0074,1000" => {
          desc => "Unified Procedure Step State",
            vr => { CS => "1" }
   },
   "0074,1002" => {
          desc => "Unified Procedure Step Progress Information Sequence",
            vr => { SQ => "1" }
   },
   "0074,1004" => {
          desc => "Unified Procedure Step Progress",
            vr => { DS => "1" }
   },
   "0074,1006" => {
          desc => "Unified Procedure Step Progress Description",
            vr => { ST => "1" }
   },
   "0074,1008" => {
          desc => "Unified Procedure Step Communications URI Sequence",
            vr => { SQ => "1" }
   },
   "0074,100a" => {
          desc => "Contact URI",
            vr => { ST => "1" }
   },
   "0074,100c" => {
          desc => "Contact Display Name",
            vr => { LO => "1" }
   },
   "0074,100e" => {
          desc => "Unified Procedure Step Discontinuation Reason Code Sequence",
            vr => { SQ => "1" }
   },
   "0074,1020" => {
          desc => "Beam Task Sequence",
            vr => { SQ => "1" }
   },
   "0074,1022" => {
          desc => "Beam Task Type",
            vr => { CS => "1" }
   },
   "0074,1024" => {
          desc => "Beam Order Index",
            vr => { IS => "1" }
   },
   "0074,1030" => {
          desc => "Delivery Verification Image Sequence",
            vr => { SQ => "1" }
   },
   "0074,1032" => {
          desc => "Verification Image Timing",
            vr => { CS => "1" }
   },
   "0074,1034" => {
          desc => "Double Exposure Flag",
            vr => { CS => "1" }
   },
   "0074,1036" => {
          desc => "Double Exposure Ordering",
            vr => { CS => "1" }
   },
   "0074,1038" => {
          desc => "Double Exposure Meterset",
            vr => { DS => "1" }
   },
   "0074,103a" => {
          desc => "Double Exposure Field Delta",
            vr => { DS => "4" }
   },
   "0074,1040" => {
          desc => "Related Reference RT Image Sequence",
            vr => { SQ => "1" }
   },
   "0074,1042" => {
          desc => "General Machine Verification Sequence",
            vr => { SQ => "1" }
   },
   "0074,1044" => {
          desc => "Conventional Machine Verification Sequence",
            vr => { SQ => "1" }
   },
   "0074,1046" => {
          desc => "Ion Machine Verification Sequence",
            vr => { SQ => "1" }
   },
   "0074,1048" => {
          desc => "Failed Attributes Sequence",
            vr => { SQ => "1" }
   },
   "0074,104a" => {
          desc => "Overridden Attributes Sequence",
            vr => { SQ => "1" }
   },
   "0074,104c" => {
          desc => "Conventional Control Point Verification Sequence",
            vr => { SQ => "1" }
   },
   "0074,104e" => {
          desc => "Ion Control Point Verification Sequence",
            vr => { SQ => "1" }
   },
   "0074,1050" => {
          desc => "Attribute Occurrence Sequence",
            vr => { SQ => "1" }
   },
   "0074,1052" => {
          desc => "Attribute Occurrence Pointer",
            vr => { AT => "1" }
   },
   "0074,1054" => {
          desc => "Attribute Item Selector",
            vr => { UL => "1" }
   },
   "0074,1056" => {
          desc => "Attribute Occurrence Private Creator",
            vr => { LO => "1" }
   },
   "0074,1200" => {
          desc => "Scheduled Procedure Step Priority",
            vr => { CS => "1" }
   },
   "0074,1202" => {
          desc => "Worklist Label",
            vr => { LO => "1" }
   },
   "0074,1204" => {
          desc => "Procedure Step Label",
            vr => { LO => "1" }
   },
   "0074,1210" => {
          desc => "Scheduled Processing Parameters Sequence",
            vr => { SQ => "1" }
   },
   "0074,1212" => {
          desc => "Performed Processing Parameters Sequence",
            vr => { SQ => "1" }
   },
   "0074,1216" => {
          desc => "Unified Procedure Step Performed Procedure Sequence",
            vr => { SQ => "1" }
   },
   "0074,1220" => {
          desc => "Related Procedure Step Sequence",
            vr => { SQ => "1" }
   },
   "0074,1222" => {
          desc => "Procedure Step Relationship Type",
            vr => { LO => "1" }
   },
   "0074,1230" => {
          desc => "Deletion Lock",
            vr => { LO => "1" }
   },
   "0074,1234" => {
          desc => "Receiving AE",
            vr => { AE => "1" }
   },
   "0074,1236" => {
          desc => "Requesting AE",
            vr => { AE => "1" }
   },
   "0074,1238" => {
          desc => "Reason for Cancellation",
            vr => { LT => "1" }
   },
   "0074,1242" => {
          desc => "SCP Status",
            vr => { CS => "1" }
   },
   "0074,1244" => {
          desc => "Subscription List Status",
            vr => { CS => "1" }
   },
   "0074,1246" => {
          desc => "Unified Procedure Step List Status",
            vr => { CS => "1" }
   },
   "0088,0130" => {
          desc => "Storage Media File-set ID",
            vr => { SH => "1" }
   },
   "0088,0140" => {
          desc => "Storage Media File-set UID",
            vr => { UI => "1" }
   },
   "0088,0200" => {
          desc => "Icon Image Sequence",
            vr => { SQ => "1" }
   },
   "0088,0904" => {
          desc => "Topic Title",
            vr => { LO => "1" },
           ret => 1
    },
   "0088,0906" => {
          desc => "Topic Subject",
            vr => { ST => "1" },
           ret => 1
    },
   "0088,0910" => {
          desc => "Topic Author",
            vr => { LO => "1" },
           ret => 1
    },
   "0088,0912" => {
          desc => "Topic Keywords",
            vr => { LO => "1-32" },
           ret => 1
    },
   "0100,0410" => {
          desc => "SOP Instance Status",
            vr => { CS => "1" }
   },
   "0100,0420" => {
          desc => "SOP Authorization DateTime",
            vr => { DT => "1" }
   },
   "0100,0424" => {
          desc => "SOP Authorization Comment",
            vr => { LT => "1" }
   },
   "0100,0426" => {
          desc => "Authorization Equipment Certification Number",
            vr => { LO => "1" }
   },
   "0400,0005" => {
          desc => "MAC ID Number",
            vr => { US => "1" }
   },
   "0400,0010" => {
          desc => "MAC Calculation Transfer Syntax UID",
            vr => { UI => "1" }
   },
   "0400,0015" => {
          desc => "MAC Algorithm",
            vr => { CS => "1" }
   },
   "0400,0020" => {
          desc => "Data Elements Signed",
            vr => { AT => "1-n" }
   },
   "0400,0100" => {
          desc => "Digital Signature UID",
            vr => { UI => "1" }
   },
   "0400,0105" => {
          desc => "Digital Signature DateTime",
            vr => { DT => "1" }
   },
   "0400,0110" => {
          desc => "Certificate Type",
            vr => { CS => "1" }
   },
   "0400,0115" => {
          desc => "Certificate of Signer",
            vr => { OB => "1" }
   },
   "0400,0120" => {
          desc => "Signature",
            vr => { OB => "1" }
   },
   "0400,0305" => {
          desc => "Certified Timestamp Type",
            vr => { CS => "1" }
   },
   "0400,0310" => {
          desc => "Certified Timestamp",
            vr => { OB => "1" }
   },
   "0400,0401" => {
          desc => "Digital Signature Purpose Code Sequence",
            vr => { SQ => "1" }
   },
   "0400,0402" => {
          desc => "Referenced Digital Signature Sequence",
            vr => { SQ => "1" }
   },
   "0400,0403" => {
          desc => "Referenced SOP Instance MAC Sequence",
            vr => { SQ => "1" }
   },
   "0400,0404" => {
          desc => "MAC",
            vr => { OB => "1" }
   },
   "0400,0500" => {
          desc => "Encrypted Attributes Sequence",
            vr => { SQ => "1" }
   },
   "0400,0510" => {
          desc => "Encrypted Content Transfer Syntax UID",
            vr => { UI => "1" }
   },
   "0400,0520" => {
          desc => "Encrypted Content",
            vr => { OB => "1" }
   },
   "0400,0550" => {
          desc => "Modified Attributes Sequence",
            vr => { SQ => "1" }
   },
   "0400,0561" => {
          desc => "Original Attributes Sequence",
            vr => { SQ => "1" }
   },
   "0400,0562" => {
          desc => "Attribute Modification DateTime",
            vr => { DT => "1" }
   },
   "0400,0563" => {
          desc => "Modifying System",
            vr => { LO => "1" }
   },
   "0400,0564" => {
          desc => "Source of Previous Values",
            vr => { LO => "1" }
   },
   "0400,0565" => {
          desc => "Reason for the Attribute Modification",
            vr => { CS => "1" }
   },
   "1000,xxx0" => {
          desc => "Escape Triplet",
            vr => { US => "3" },
           ret => 1
    },
   "1000,xxx1" => {
          desc => "Run Length Triplet",
            vr => { US => "3" },
           ret => 1
    },
   "1000,xxx2" => {
          desc => "Huffman Table Size",
            vr => { US => "1" },
           ret => 1
    },
   "1000,xxx3" => {
          desc => "Huffman Table Triplet",
            vr => { US => "3" },
           ret => 1
    },
   "1000,xxx4" => {
          desc => "Shift Table Size",
            vr => { US => "1" },
           ret => 1
    },
   "1000,xxx5" => {
          desc => "Shift Table Triplet",
            vr => { US => "3" },
           ret => 1
    },
   "1010,xxxx" => {
          desc => "Zonal Map",
            vr => { US => "1-n" },
           ret => 1
    },
   "2000,0010" => {
          desc => "Number of Copies",
            vr => { IS => "1" }
   },
   "2000,001e" => {
          desc => "Printer Configuration Sequence",
            vr => { SQ => "1" }
   },
   "2000,0020" => {
          desc => "Print Priority",
            vr => { CS => "1" }
   },
   "2000,0030" => {
          desc => "Medium Type",
            vr => { CS => "1" }
   },
   "2000,0040" => {
          desc => "Film Destination",
            vr => { CS => "1" }
   },
   "2000,0050" => {
          desc => "Film Session Label",
            vr => { LO => "1" }
   },
   "2000,0060" => {
          desc => "Memory Allocation",
            vr => { IS => "1" }
   },
   "2000,0061" => {
          desc => "Maximum Memory Allocation",
            vr => { IS => "1" }
   },
   "2000,0062" => {
          desc => "Color Image Printing Flag",
            vr => { CS => "1" },
           ret => 1
    },
   "2000,0063" => {
          desc => "Collation Flag",
            vr => { CS => "1" },
           ret => 1
    },
   "2000,0065" => {
          desc => "Annotation Flag",
            vr => { CS => "1" },
           ret => 1
    },
   "2000,0067" => {
          desc => "Image Overlay Flag",
            vr => { CS => "1" },
           ret => 1
    },
   "2000,0069" => {
          desc => "Presentation LUT Flag",
            vr => { CS => "1" },
           ret => 1
    },
   "2000,006a" => {
          desc => "Image Box Presentation LUT Flag",
            vr => { CS => "1" },
           ret => 1
    },
   "2000,00a0" => {
          desc => "Memory Bit Depth",
            vr => { US => "1" }
   },
   "2000,00a1" => {
          desc => "Printing Bit Depth",
            vr => { US => "1" }
   },
   "2000,00a2" => {
          desc => "Media Installed Sequence",
            vr => { SQ => "1" }
   },
   "2000,00a4" => {
          desc => "Other Media Available Sequence",
            vr => { SQ => "1" }
   },
   "2000,00a8" => {
          desc => "Supported Image Display Formats Sequence",
            vr => { SQ => "1" }
   },
   "2000,0500" => {
          desc => "Referenced Film Box Sequence",
            vr => { SQ => "1" }
   },
   "2000,0510" => {
          desc => "Referenced Stored Print  Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "2010,0010" => {
          desc => "Image Display Format",
            vr => { ST => "1" }
   },
   "2010,0030" => {
          desc => "Annotation Display Format ID",
            vr => { CS => "1" }
   },
   "2010,0040" => {
          desc => "Film Orientation",
            vr => { CS => "1" }
   },
   "2010,0050" => {
          desc => "Film Size ID",
            vr => { CS => "1" }
   },
   "2010,0052" => {
          desc => "Printer Resolution ID",
            vr => { CS => "1" }
   },
   "2010,0054" => {
          desc => "Default Printer Resolution ID",
            vr => { CS => "1" }
   },
   "2010,0060" => {
          desc => "Magnification Type",
            vr => { CS => "1" }
   },
   "2010,0080" => {
          desc => "Smoothing Type  ",
            vr => { CS => "1" }
   },
   "2010,00a6" => {
          desc => "Default Magnification Type",
            vr => { CS => "1" }
   },
   "2010,00a7" => {
          desc => "Other Magnification Types Available",
            vr => { CS => "1-n" }
   },
   "2010,00a8" => {
          desc => "Default Smoothing Type",
            vr => { CS => "1" }
   },
   "2010,00a9" => {
          desc => "Other Smoothing Types Available",
            vr => { CS => "1-n" }
   },
   "2010,0100" => {
          desc => "Border Density",
            vr => { CS => "1" }
   },
   "2010,0110" => {
          desc => "Empty Image Density",
            vr => { CS => "1" }
   },
   "2010,0120" => {
          desc => "Min Density",
            vr => { US => "1" }
   },
   "2010,0130" => {
          desc => "Max Density",
            vr => { US => "1" }
   },
   "2010,0140" => {
          desc => "Trim",
            vr => { CS => "1" }
   },
   "2010,0150" => {
          desc => "Configuration Information",
            vr => { ST => "1" }
   },
   "2010,0152" => {
          desc => "Configuration Information Description",
            vr => { LT => "1" }
   },
   "2010,0154" => {
          desc => "Maximum Collated Films",
            vr => { IS => "1" }
   },
   "2010,015e" => {
          desc => "Illumination",
            vr => { US => "1" }
   },
   "2010,0160" => {
          desc => "Reflected Ambient Light",
            vr => { US => "1" }
   },
   "2010,0376" => {
          desc => "Printer Pixel Spacing",
            vr => { DS => "2" }
   },
   "2010,0500" => {
          desc => "Referenced Film Session Sequence",
            vr => { SQ => "1" }
   },
   "2010,0510" => {
          desc => "Referenced Image Box Sequence",
            vr => { SQ => "1" }
   },
   "2010,0520" => {
          desc => "Referenced Basic Annotation Box Sequence",
            vr => { SQ => "1" }
   },
   "2020,0010" => {
          desc => "Image Box Position",
            vr => { US => "1" }
   },
   "2020,0020" => {
          desc => "Polarity",
            vr => { CS => "1" }
   },
   "2020,0030" => {
          desc => "Requested Image Size",
            vr => { DS => "1" }
   },
   "2020,0040" => {
          desc => "Requested Decimate/Crop Behavior",
            vr => { CS => "1" }
   },
   "2020,0050" => {
          desc => "Requested Resolution ID",
            vr => { CS => "1" }
   },
   "2020,00a0" => {
          desc => "Requested Image Size Flag",
            vr => { CS => "1" }
   },
   "2020,00a2" => {
          desc => "Decimate/Crop Result",
            vr => { CS => "1" }
   },
   "2020,0110" => {
          desc => "Basic Grayscale Image Sequence",
            vr => { SQ => "1" }
   },
   "2020,0111" => {
          desc => "Basic Color Image Sequence",
            vr => { SQ => "1" }
   },
   "2020,0130" => {
          desc => "Referenced Image Overlay Box Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "2020,0140" => {
          desc => "Referenced VOI LUT Box Sequence ",
            vr => { SQ => "1" },
           ret => 1
    },
   "2030,0010" => {
          desc => "Annotation Position",
            vr => { US => "1" }
   },
   "2030,0020" => {
          desc => "Text String",
            vr => { LO => "1" }
   },
   "2040,0010" => {
          desc => "Referenced Overlay Plane Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "2040,0011" => {
          desc => "Referenced Overlay Plane Groups",
            vr => { US => "1-99" },
           ret => 1
    },
   "2040,0020" => {
          desc => "Overlay Pixel Data Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "2040,0060" => {
          desc => "Overlay Magnification Type",
            vr => { CS => "1" },
           ret => 1
    },
   "2040,0070" => {
          desc => "Overlay Smoothing Type",
            vr => { CS => "1" },
           ret => 1
    },
   "2040,0072" => {
          desc => "Overlay or Image Magnification",
            vr => { CS => "1" },
           ret => 1
    },
   "2040,0074" => {
          desc => "Magnify to Number of Columns",
            vr => { US => "1" },
           ret => 1
    },
   "2040,0080" => {
          desc => "Overlay Foreground Density",
            vr => { CS => "1" },
           ret => 1
    },
   "2040,0082" => {
          desc => "Overlay Background Density",
            vr => { CS => "1" },
           ret => 1
    },
   "2040,0090" => {
          desc => "Overlay Mode",
            vr => { CS => "1" },
           ret => 1
    },
   "2040,0100" => {
          desc => "Threshold Density",
            vr => { CS => "1" },
           ret => 1
    },
   "2040,0500" => {
          desc => "Referenced Image Box Sequence (Retired)",
            vr => { SQ => "1" },
           ret => 1
    },
   "2050,0010" => {
          desc => "Presentation LUT Sequence",
            vr => { SQ => "1" }
   },
   "2050,0020" => {
          desc => "Presentation LUT Shape",
            vr => { CS => "1" }
   },
   "2050,0500" => {
          desc => "Referenced Presentation  LUT Sequence",
            vr => { SQ => "1" }
   },
   "2100,0010" => {
          desc => "Print Job ID",
            vr => { SH => "1" },
           ret => 1
    },
   "2100,0020" => {
          desc => "Execution Status",
            vr => { CS => "1" }
   },
   "2100,0030" => {
          desc => "Execution Status Info",
            vr => { CS => "1" }
   },
   "2100,0040" => {
          desc => "Creation Date",
            vr => { DA => "1" }
   },
   "2100,0050" => {
          desc => "Creation Time",
            vr => { TM => "1" }
   },
   "2100,0070" => {
          desc => "Originator",
            vr => { AE => "1" }
   },
   "2100,0140" => {
          desc => "Destination AE",
            vr => { AE => "1" },
           ret => 1
    },
   "2100,0160" => {
          desc => "Owner ID",
            vr => { SH => "1" }
   },
   "2100,0170" => {
          desc => "Number of Films",
            vr => { IS => "1" }
   },
   "2100,0500" => {
          desc => "Referenced Print Job Sequence (Pull Stored Print)",
            vr => { SQ => "1" },
           ret => 1
    },
   "2110,0010" => {
          desc => "Printer Status",
            vr => { CS => "1" }
   },
   "2110,0020" => {
          desc => "Printer Status Info",
            vr => { CS => "1" }
   },
   "2110,0030" => {
          desc => "Printer Name",
            vr => { LO => "1" }
   },
   "2110,0099" => {
          desc => "Print Queue ID",
            vr => { SH => "1" },
           ret => 1
    },
   "2120,0010" => {
          desc => "Queue Status",
            vr => { CS => "1" },
           ret => 1
    },
   "2120,0050" => {
          desc => "Print Job Description Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "2120,0070" => {
          desc => "Referenced Print Job Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "2130,0010" => {
          desc => "Print Management Capabilities Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "2130,0015" => {
          desc => "Printer Characteristics Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "2130,0030" => {
          desc => "Film Box Content Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "2130,0040" => {
          desc => "Image Box Content Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "2130,0050" => {
          desc => "Annotation Content Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "2130,0060" => {
          desc => "Image Overlay Box Content Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "2130,0080" => {
          desc => "Presentation LUT Content Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "2130,00a0" => {
          desc => "Proposed Study Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "2130,00c0" => {
          desc => "Original Image Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "2200,0001" => {
          desc => "Label Using Information Extracted From Instances",
            vr => { CS => "1" }
   },
   "2200,0002" => {
          desc => "Label Text",
            vr => { UT => "1" }
   },
   "2200,0003" => {
          desc => "Label Style Selection",
            vr => { CS => "1" }
   },
   "2200,0004" => {
          desc => "Media Disposition",
            vr => { LT => "1" }
   },
   "2200,0005" => {
          desc => "Barcode Value",
            vr => { LT => "1" }
   },
   "2200,0006" => {
          desc => "Barcode Symbology",
            vr => { CS => "1" }
   },
   "2200,0007" => {
          desc => "Allow Media Splitting",
            vr => { CS => "1" }
   },
   "2200,0008" => {
          desc => "Include Non-DICOM Objects",
            vr => { CS => "1" }
   },
   "2200,0009" => {
          desc => "Include Display Application",
            vr => { CS => "1" }
   },
   "2200,000a" => {
          desc => "Preserve Composite Instances After Media Creation",
            vr => { CS => "1" }
   },
   "2200,000b" => {
          desc => "Total Number of Pieces of Media Created",
            vr => { US => "1" }
   },
   "2200,000c" => {
          desc => "Requested Media Application Profile",
            vr => { LO => "1" }
   },
   "2200,000d" => {
          desc => "Referenced Storage Media Sequence",
            vr => { SQ => "1" }
   },
   "2200,000e" => {
          desc => "Failure Attributes",
            vr => { AT => "1-n" }
   },
   "2200,000f" => {
          desc => "Allow Lossy Compression",
            vr => { CS => "1" }
   },
   "2200,0020" => {
          desc => "Request Priority",
            vr => { CS => "1" }
   },
   "3002,0002" => {
          desc => "RT Image Label",
            vr => { SH => "1" }
   },
   "3002,0003" => {
          desc => "RT Image Name",
            vr => { LO => "1" }
   },
   "3002,0004" => {
          desc => "RT Image Description",
            vr => { ST => "1" }
   },
   "3002,000a" => {
          desc => "Reported Values Origin",
            vr => { CS => "1" }
   },
   "3002,000c" => {
          desc => "RT Image Plane",
            vr => { CS => "1" }
   },
   "3002,000d" => {
          desc => "X-Ray Image Receptor Translation",
            vr => { DS => "3" }
   },
   "3002,000e" => {
          desc => "X-Ray Image Receptor Angle",
            vr => { DS => "1" }
   },
   "3002,0010" => {
          desc => "RT Image Orientation",
            vr => { DS => "6" }
   },
   "3002,0011" => {
          desc => "Image Plane Pixel Spacing",
            vr => { DS => "2" }
   },
   "3002,0012" => {
          desc => "RT Image Position",
            vr => { DS => "2" }
   },
   "3002,0020" => {
          desc => "Radiation Machine Name",
            vr => { SH => "1" }
   },
   "3002,0022" => {
          desc => "Radiation Machine SAD",
            vr => { DS => "1" }
   },
   "3002,0024" => {
          desc => "Radiation Machine SSD",
            vr => { DS => "1" }
   },
   "3002,0026" => {
          desc => "RT Image SID",
            vr => { DS => "1" }
   },
   "3002,0028" => {
          desc => "Source to Reference Object Distance",
            vr => { DS => "1" }
   },
   "3002,0029" => {
          desc => "Fraction Number",
            vr => { IS => "1" }
   },
   "3002,0030" => {
          desc => "Exposure Sequence",
            vr => { SQ => "1" }
   },
   "3002,0032" => {
          desc => "Meterset Exposure",
            vr => { DS => "1" }
   },
   "3002,0034" => {
          desc => "Diaphragm Position",
            vr => { DS => "4" }
   },
   "3002,0040" => {
          desc => "Fluence Map Sequence",
            vr => { SQ => "1" }
   },
   "3002,0041" => {
          desc => "Fluence Data Source",
            vr => { CS => "1" }
   },
   "3002,0042" => {
          desc => "Fluence Data Scale",
            vr => { DS => "1" }
   },
   "3002,0050" => {
          desc => "Primary Fluence Mode Sequence",
            vr => { SQ => "1" }
   },
   "3002,0051" => {
          desc => "Fluence Mode",
            vr => { CS => "1" }
   },
   "3002,0052" => {
          desc => "Fluence Mode ID",
            vr => { SH => "1" }
   },
   "3004,0001" => {
          desc => "DVH Type",
            vr => { CS => "1" }
   },
   "3004,0002" => {
          desc => "Dose Units",
            vr => { CS => "1" }
   },
   "3004,0004" => {
          desc => "Dose Type",
            vr => { CS => "1" }
   },
   "3004,0006" => {
          desc => "Dose Comment",
            vr => { LO => "1" }
   },
   "3004,0008" => {
          desc => "Normalization Point",
            vr => { DS => "3" }
   },
   "3004,000a" => {
          desc => "Dose Summation Type",
            vr => { CS => "1" }
   },
   "3004,000c" => {
          desc => "Grid Frame Offset Vector",
            vr => { DS => "2-n" }
   },
   "3004,000e" => {
          desc => "Dose Grid Scaling",
            vr => { DS => "1" }
   },
   "3004,0010" => {
          desc => "RT Dose ROI Sequence",
            vr => { SQ => "1" }
   },
   "3004,0012" => {
          desc => "Dose Value",
            vr => { DS => "1" }
   },
   "3004,0014" => {
          desc => "Tissue Heterogeneity Correction",
            vr => { CS => "1-3" }
   },
   "3004,0040" => {
          desc => "DVH Normalization Point",
            vr => { DS => "3" }
   },
   "3004,0042" => {
          desc => "DVH Normalization Dose Value",
            vr => { DS => "1" }
   },
   "3004,0050" => {
          desc => "DVH Sequence",
            vr => { SQ => "1" }
   },
   "3004,0052" => {
          desc => "DVH Dose Scaling",
            vr => { DS => "1" }
   },
   "3004,0054" => {
          desc => "DVH Volume Units",
            vr => { CS => "1" }
   },
   "3004,0056" => {
          desc => "DVH Number of Bins",
            vr => { IS => "1" }
   },
   "3004,0058" => {
          desc => "DVH Data",
            vr => { DS => "2-2n" }
   },
   "3004,0060" => {
          desc => "DVH Referenced ROI Sequence",
            vr => { SQ => "1" }
   },
   "3004,0062" => {
          desc => "DVH ROI Contribution Type",
            vr => { CS => "1" }
   },
   "3004,0070" => {
          desc => "DVH Minimum Dose",
            vr => { DS => "1" }
   },
   "3004,0072" => {
          desc => "DVH Maximum Dose",
            vr => { DS => "1" }
   },
   "3004,0074" => {
          desc => "DVH Mean Dose",
            vr => { DS => "1" }
   },
   "3006,0002" => {
          desc => "Structure Set Label",
            vr => { SH => "1" }
   },
   "3006,0004" => {
          desc => "Structure Set Name",
            vr => { LO => "1" }
   },
   "3006,0006" => {
          desc => "Structure Set Description",
            vr => { ST => "1" }
   },
   "3006,0008" => {
          desc => "Structure Set Date",
            vr => { DA => "1" }
   },
   "3006,0009" => {
          desc => "Structure Set Time",
            vr => { TM => "1" }
   },
   "3006,0010" => {
          desc => "Referenced Frame of Reference Sequence",
            vr => { SQ => "1" }
   },
   "3006,0012" => {
          desc => "RT Referenced Study Sequence",
            vr => { SQ => "1" }
   },
   "3006,0014" => {
          desc => "RT Referenced Series Sequence",
            vr => { SQ => "1" }
   },
   "3006,0016" => {
          desc => "Contour Image Sequence",
            vr => { SQ => "1" }
   },
   "3006,0020" => {
          desc => "Structure Set ROI Sequence",
            vr => { SQ => "1" }
   },
   "3006,0022" => {
          desc => "ROI Number",
            vr => { IS => "1" }
   },
   "3006,0024" => {
          desc => "Referenced Frame of Reference UID",
            vr => { UI => "1" }
   },
   "3006,0026" => {
          desc => "ROI Name",
            vr => { LO => "1" }
   },
   "3006,0028" => {
          desc => "ROI Description",
            vr => { ST => "1" }
   },
   "3006,002a" => {
          desc => "ROI Display Color",
            vr => { IS => "3" }
   },
   "3006,002c" => {
          desc => "ROI Volume",
            vr => { DS => "1" }
   },
   "3006,0030" => {
          desc => "RT Related ROI Sequence",
            vr => { SQ => "1" }
   },
   "3006,0033" => {
          desc => "RT ROI Relationship",
            vr => { CS => "1" }
   },
   "3006,0036" => {
          desc => "ROI Generation Algorithm",
            vr => { CS => "1" }
   },
   "3006,0038" => {
          desc => "ROI Generation Description",
            vr => { LO => "1" }
   },
   "3006,0039" => {
          desc => "ROI Contour Sequence",
            vr => { SQ => "1" }
   },
   "3006,0040" => {
          desc => "Contour Sequence",
            vr => { SQ => "1" }
   },
   "3006,0042" => {
          desc => "Contour Geometric Type",
            vr => { CS => "1" }
   },
   "3006,0044" => {
          desc => "Contour Slab Thickness",
            vr => { DS => "1" }
   },
   "3006,0045" => {
          desc => "Contour Offset Vector",
            vr => { DS => "3" }
   },
   "3006,0046" => {
          desc => "Number of Contour Points",
            vr => { IS => "1" }
   },
   "3006,0048" => {
          desc => "Contour Number",
            vr => { IS => "1" }
   },
   "3006,0049" => {
          desc => "Attached Contours",
            vr => { IS => "1-n" }
   },
   "3006,0050" => {
          desc => "Contour Data",
            vr => { DS => "3-3n" }
   },
   "3006,0080" => {
          desc => "RT ROI Observations Sequence",
            vr => { SQ => "1" }
   },
   "3006,0082" => {
          desc => "Observation Number",
            vr => { IS => "1" }
   },
   "3006,0084" => {
          desc => "Referenced ROI Number",
            vr => { IS => "1" }
   },
   "3006,0085" => {
          desc => "ROI Observation Label",
            vr => { SH => "1" }
   },
   "3006,0086" => {
          desc => "RT ROI Identification Code Sequence",
            vr => { SQ => "1" }
   },
   "3006,0088" => {
          desc => "ROI Observation Description",
            vr => { ST => "1" }
   },
   "3006,00a0" => {
          desc => "Related RT ROI Observations Sequence",
            vr => { SQ => "1" }
   },
   "3006,00a4" => {
          desc => "RT ROI Interpreted Type",
            vr => { CS => "1" }
   },
   "3006,00a6" => {
          desc => "ROI Interpreter",
            vr => { PN => "1" }
   },
   "3006,00b0" => {
          desc => "ROI Physical Properties Sequence",
            vr => { SQ => "1" }
   },
   "3006,00b2" => {
          desc => "ROI Physical Property",
            vr => { CS => "1" }
   },
   "3006,00b4" => {
          desc => "ROI Physical Property Value",
            vr => { DS => "1" }
   },
   "3006,00b6" => {
          desc => "ROI Elemental Composition Sequence",
            vr => { SQ => "1" }
   },
   "3006,00b7" => {
          desc => "ROI Elemental Composition Atomic Number",
            vr => { US => "1" }
   },
   "3006,00b8" => {
          desc => "ROI Elemental Composition Atomic Mass Fraction",
            vr => { FL => "1" }
   },
   "3006,00c0" => {
          desc => "Frame of Reference Relationship Sequence",
            vr => { SQ => "1" }
   },
   "3006,00c2" => {
          desc => "Related Frame of Reference UID",
            vr => { UI => "1" }
   },
   "3006,00c4" => {
          desc => "Frame of Reference Transformation Type",
            vr => { CS => "1" }
   },
   "3006,00c6" => {
          desc => "Frame of Reference Transformation Matrix",
            vr => { DS => "16" }
   },
   "3006,00c8" => {
          desc => "Frame of Reference Transformation Comment",
            vr => { LO => "1" }
   },
   "3008,0010" => {
          desc => "Measured Dose Reference Sequence",
            vr => { SQ => "1" }
   },
   "3008,0012" => {
          desc => "Measured Dose Description",
            vr => { ST => "1" }
   },
   "3008,0014" => {
          desc => "Measured Dose Type",
            vr => { CS => "1" }
   },
   "3008,0016" => {
          desc => "Measured Dose Value",
            vr => { DS => "1" }
   },
   "3008,0020" => {
          desc => "Treatment Session Beam Sequence",
            vr => { SQ => "1" }
   },
   "3008,0021" => {
          desc => "Treatment Session Ion Beam Sequence",
            vr => { SQ => "1" }
   },
   "3008,0022" => {
          desc => "Current Fraction Number",
            vr => { IS => "1" }
   },
   "3008,0024" => {
          desc => "Treatment Control Point Date",
            vr => { DA => "1" }
   },
   "3008,0025" => {
          desc => "Treatment Control Point Time",
            vr => { TM => "1" }
   },
   "3008,002a" => {
          desc => "Treatment Termination Status",
            vr => { CS => "1" }
   },
   "3008,002b" => {
          desc => "Treatment Termination Code",
            vr => { SH => "1" }
   },
   "3008,002c" => {
          desc => "Treatment Verification Status",
            vr => { CS => "1" }
   },
   "3008,0030" => {
          desc => "Referenced Treatment Record Sequence",
            vr => { SQ => "1" }
   },
   "3008,0032" => {
          desc => "Specified Primary Meterset ",
            vr => { DS => "1" }
   },
   "3008,0033" => {
          desc => "Specified Secondary Meterset ",
            vr => { DS => "1" }
   },
   "3008,0036" => {
          desc => "Delivered Primary Meterset ",
            vr => { DS => "1" }
   },
   "3008,0037" => {
          desc => "Delivered Secondary Meterset ",
            vr => { DS => "1" }
   },
   "3008,003a" => {
          desc => "Specified Treatment Time",
            vr => { DS => "1" }
   },
   "3008,003b" => {
          desc => "Delivered Treatment Time",
            vr => { DS => "1" }
   },
   "3008,0040" => {
          desc => "Control Point Delivery Sequence",
            vr => { SQ => "1" }
   },
   "3008,0041" => {
          desc => "Ion Control Point Delivery Sequence",
            vr => { SQ => "1" }
   },
   "3008,0042" => {
          desc => "Specified Meterset",
            vr => { DS => "1" }
   },
   "3008,0044" => {
          desc => "Delivered Meterset",
            vr => { DS => "1" }
   },
   "3008,0045" => {
          desc => "Meterset Rate Set",
            vr => { FL => "1" }
   },
   "3008,0046" => {
          desc => "Meterset Rate Delivered",
            vr => { FL => "1" }
   },
   "3008,0047" => {
          desc => "Scan Spot Metersets Delivered",
            vr => { FL => "1-n" }
   },
   "3008,0048" => {
          desc => "Dose Rate Delivered",
            vr => { DS => "1" }
   },
   "3008,0050" => {
          desc => "Treatment Summary Calculated Dose Reference Sequence",
            vr => { SQ => "1" }
   },
   "3008,0052" => {
          desc => "Cumulative Dose to Dose Reference",
            vr => { DS => "1" }
   },
   "3008,0054" => {
          desc => "First Treatment Date",
            vr => { DA => "1" }
   },
   "3008,0056" => {
          desc => "Most Recent Treatment Date",
            vr => { DA => "1" }
   },
   "3008,005a" => {
          desc => "Number of Fractions Delivered",
            vr => { IS => "1" }
   },
   "3008,0060" => {
          desc => "Override Sequence",
            vr => { SQ => "1" }
   },
   "3008,0061" => {
          desc => "Parameter Sequence Pointer",
            vr => { AT => "1" }
   },
   "3008,0062" => {
          desc => "Override Parameter Pointer",
            vr => { AT => "1" }
   },
   "3008,0063" => {
          desc => "Parameter Item Index",
            vr => { IS => "1" }
   },
   "3008,0064" => {
          desc => "Measured Dose Reference Number",
            vr => { IS => "1" }
   },
   "3008,0065" => {
          desc => "Parameter Pointer",
            vr => { AT => "1" }
   },
   "3008,0066" => {
          desc => "Override Reason",
            vr => { ST => "1" }
   },
   "3008,0068" => {
          desc => "Corrected Parameter Sequence",
            vr => { SQ => "1" }
   },
   "3008,006a" => {
          desc => "Correction Value",
            vr => { FL => "1" }
   },
   "3008,0070" => {
          desc => "Calculated Dose Reference Sequence",
            vr => { SQ => "1" }
   },
   "3008,0072" => {
          desc => "Calculated Dose Reference Number",
            vr => { IS => "1" }
   },
   "3008,0074" => {
          desc => "Calculated Dose Reference Description",
            vr => { ST => "1" }
   },
   "3008,0076" => {
          desc => "Calculated Dose Reference Dose Value",
            vr => { DS => "1" }
   },
   "3008,0078" => {
          desc => "Start Meterset",
            vr => { DS => "1" }
   },
   "3008,007a" => {
          desc => "End Meterset",
            vr => { DS => "1" }
   },
   "3008,0080" => {
          desc => "Referenced Measured Dose Reference Sequence",
            vr => { SQ => "1" }
   },
   "3008,0082" => {
          desc => "Referenced Measured Dose Reference Number",
            vr => { IS => "1" }
   },
   "3008,0090" => {
          desc => "Referenced Calculated Dose Reference Sequence",
            vr => { SQ => "1" }
   },
   "3008,0092" => {
          desc => "Referenced Calculated Dose Reference Number",
            vr => { IS => "1" }
   },
   "3008,00a0" => {
          desc => "Beam Limiting Device Leaf Pairs Sequence",
            vr => { SQ => "1" }
   },
   "3008,00b0" => {
          desc => "Recorded Wedge Sequence",
            vr => { SQ => "1" }
   },
   "3008,00c0" => {
          desc => "Recorded Compensator Sequence",
            vr => { SQ => "1" }
   },
   "3008,00d0" => {
          desc => "Recorded Block Sequence",
            vr => { SQ => "1" }
   },
   "3008,00e0" => {
          desc => "Treatment Summary Measured Dose Reference Sequence",
            vr => { SQ => "1" }
   },
   "3008,00f0" => {
          desc => "Recorded Snout Sequence",
            vr => { SQ => "1" }
   },
   "3008,00f2" => {
          desc => "Recorded Range Shifter Sequence",
            vr => { SQ => "1" }
   },
   "3008,00f4" => {
          desc => "Recorded Lateral Spreading Device Sequence",
            vr => { SQ => "1" }
   },
   "3008,00f6" => {
          desc => "Recorded Range Modulator Sequence",
            vr => { SQ => "1" }
   },
   "3008,0100" => {
          desc => "Recorded Source Sequence",
            vr => { SQ => "1" }
   },
   "3008,0105" => {
          desc => "Source Serial Number",
            vr => { LO => "1" }
   },
   "3008,0110" => {
          desc => "Treatment Session Application Setup Sequence",
            vr => { SQ => "1" }
   },
   "3008,0116" => {
          desc => "Application Setup Check",
            vr => { CS => "1" }
   },
   "3008,0120" => {
          desc => "Recorded Brachy Accessory Device Sequence",
            vr => { SQ => "1" }
   },
   "3008,0122" => {
          desc => "Referenced Brachy Accessory Device Number",
            vr => { IS => "1" }
   },
   "3008,0130" => {
          desc => "Recorded Channel Sequence",
            vr => { SQ => "1" }
   },
   "3008,0132" => {
          desc => "Specified Channel Total Time",
            vr => { DS => "1" }
   },
   "3008,0134" => {
          desc => "Delivered Channel Total Time",
            vr => { DS => "1" }
   },
   "3008,0136" => {
          desc => "Specified Number of Pulses",
            vr => { IS => "1" }
   },
   "3008,0138" => {
          desc => "Delivered Number of Pulses",
            vr => { IS => "1" }
   },
   "3008,013a" => {
          desc => "Specified Pulse Repetition Interval",
            vr => { DS => "1" }
   },
   "3008,013c" => {
          desc => "Delivered Pulse Repetition Interval",
            vr => { DS => "1" }
   },
   "3008,0140" => {
          desc => "Recorded Source Applicator Sequence",
            vr => { SQ => "1" }
   },
   "3008,0142" => {
          desc => "Referenced Source Applicator Number",
            vr => { IS => "1" }
   },
   "3008,0150" => {
          desc => "Recorded Channel Shield Sequence",
            vr => { SQ => "1" }
   },
   "3008,0152" => {
          desc => "Referenced Channel Shield Number",
            vr => { IS => "1" }
   },
   "3008,0160" => {
          desc => "Brachy Control Point Delivered Sequence",
            vr => { SQ => "1" }
   },
   "3008,0162" => {
          desc => "Safe Position Exit Date",
            vr => { DA => "1" }
   },
   "3008,0164" => {
          desc => "Safe Position Exit Time",
            vr => { TM => "1" }
   },
   "3008,0166" => {
          desc => "Safe Position Return Date",
            vr => { DA => "1" }
   },
   "3008,0168" => {
          desc => "Safe Position Return Time",
            vr => { TM => "1" }
   },
   "3008,0200" => {
          desc => "Current Treatment Status",
            vr => { CS => "1" }
   },
   "3008,0202" => {
          desc => "Treatment Status Comment",
            vr => { ST => "1" }
   },
   "3008,0220" => {
          desc => "Fraction Group Summary Sequence",
            vr => { SQ => "1" }
   },
   "3008,0223" => {
          desc => "Referenced Fraction Number",
            vr => { IS => "1" }
   },
   "3008,0224" => {
          desc => "Fraction Group Type",
            vr => { CS => "1" }
   },
   "3008,0230" => {
          desc => "Beam Stopper Position",
            vr => { CS => "1" }
   },
   "3008,0240" => {
          desc => "Fraction Status Summary Sequence",
            vr => { SQ => "1" }
   },
   "3008,0250" => {
          desc => "Treatment Date",
            vr => { DA => "1" }
   },
   "3008,0251" => {
          desc => "Treatment Time",
            vr => { TM => "1" }
   },
   "300a,0002" => {
          desc => "RT Plan Label",
            vr => { SH => "1" }
   },
   "300a,0003" => {
          desc => "RT Plan Name",
            vr => { LO => "1" }
   },
   "300a,0004" => {
          desc => "RT Plan Description",
            vr => { ST => "1" }
   },
   "300a,0006" => {
          desc => "RT Plan Date",
            vr => { DA => "1" }
   },
   "300a,0007" => {
          desc => "RT Plan Time",
            vr => { TM => "1" }
   },
   "300a,0009" => {
          desc => "Treatment Protocols",
            vr => { LO => "1-n" }
   },
   "300a,000a" => {
          desc => "Plan Intent",
            vr => { CS => "1" }
   },
   "300a,000b" => {
          desc => "Treatment Sites",
            vr => { LO => "1-n" }
   },
   "300a,000c" => {
          desc => "RT Plan Geometry",
            vr => { CS => "1" }
   },
   "300a,000e" => {
          desc => "Prescription Description",
            vr => { ST => "1" }
   },
   "300a,0010" => {
          desc => "Dose Reference Sequence",
            vr => { SQ => "1" }
   },
   "300a,0012" => {
          desc => "Dose Reference Number",
            vr => { IS => "1" }
   },
   "300a,0013" => {
          desc => "Dose Reference UID",
            vr => { UI => "1" }
   },
   "300a,0014" => {
          desc => "Dose Reference Structure Type",
            vr => { CS => "1" }
   },
   "300a,0015" => {
          desc => "Nominal Beam Energy Unit",
            vr => { CS => "1" }
   },
   "300a,0016" => {
          desc => "Dose Reference Description",
            vr => { LO => "1" }
   },
   "300a,0018" => {
          desc => "Dose Reference Point Coordinates",
            vr => { DS => "3" }
   },
   "300a,001a" => {
          desc => "Nominal Prior Dose",
            vr => { DS => "1" }
   },
   "300a,0020" => {
          desc => "Dose Reference Type",
            vr => { CS => "1" }
   },
   "300a,0021" => {
          desc => "Constraint Weight",
            vr => { DS => "1" }
   },
   "300a,0022" => {
          desc => "Delivery Warning Dose",
            vr => { DS => "1" }
   },
   "300a,0023" => {
          desc => "Delivery Maximum Dose",
            vr => { DS => "1" }
   },
   "300a,0025" => {
          desc => "Target Minimum Dose",
            vr => { DS => "1" }
   },
   "300a,0026" => {
          desc => "Target Prescription Dose",
            vr => { DS => "1" }
   },
   "300a,0027" => {
          desc => "Target Maximum Dose",
            vr => { DS => "1" }
   },
   "300a,0028" => {
          desc => "Target Underdose Volume Fraction",
            vr => { DS => "1" }
   },
   "300a,002a" => {
          desc => "Organ at Risk Full-volume Dose",
            vr => { DS => "1" }
   },
   "300a,002b" => {
          desc => "Organ at Risk Limit Dose",
            vr => { DS => "1" }
   },
   "300a,002c" => {
          desc => "Organ at Risk Maximum Dose",
            vr => { DS => "1" }
   },
   "300a,002d" => {
          desc => "Organ at Risk Overdose Volume Fraction",
            vr => { DS => "1" }
   },
   "300a,0040" => {
          desc => "Tolerance Table Sequence",
            vr => { SQ => "1" }
   },
   "300a,0042" => {
          desc => "Tolerance Table Number",
            vr => { IS => "1" }
   },
   "300a,0043" => {
          desc => "Tolerance Table Label",
            vr => { SH => "1" }
   },
   "300a,0044" => {
          desc => "Gantry Angle Tolerance",
            vr => { DS => "1" }
   },
   "300a,0046" => {
          desc => "Beam Limiting Device Angle Tolerance",
            vr => { DS => "1" }
   },
   "300a,0048" => {
          desc => "Beam Limiting Device Tolerance Sequence",
            vr => { SQ => "1" }
   },
   "300a,004a" => {
          desc => "Beam Limiting Device Position Tolerance",
            vr => { DS => "1" }
   },
   "300a,004b" => {
          desc => "Snout Position Tolerance",
            vr => { FL => "1" }
   },
   "300a,004c" => {
          desc => "Patient Support Angle Tolerance",
            vr => { DS => "1" }
   },
   "300a,004e" => {
          desc => "Table Top Eccentric Angle Tolerance",
            vr => { DS => "1" }
   },
   "300a,004f" => {
          desc => "Table Top Pitch Angle Tolerance",
            vr => { FL => "1" }
   },
   "300a,0050" => {
          desc => "Table Top Roll Angle Tolerance",
            vr => { FL => "1" }
   },
   "300a,0051" => {
          desc => "Table Top Vertical Position Tolerance",
            vr => { DS => "1" }
   },
   "300a,0052" => {
          desc => "Table Top Longitudinal Position Tolerance",
            vr => { DS => "1" }
   },
   "300a,0053" => {
          desc => "Table Top Lateral Position Tolerance",
            vr => { DS => "1" }
   },
   "300a,0055" => {
          desc => "RT Plan Relationship",
            vr => { CS => "1" }
   },
   "300a,0070" => {
          desc => "Fraction Group Sequence",
            vr => { SQ => "1" }
   },
   "300a,0071" => {
          desc => "Fraction Group Number",
            vr => { IS => "1" }
   },
   "300a,0072" => {
          desc => "Fraction Group Description",
            vr => { LO => "1" }
   },
   "300a,0078" => {
          desc => "Number of Fractions Planned",
            vr => { IS => "1" }
   },
   "300a,0079" => {
          desc => "Number of Fraction Pattern Digits Per Day",
            vr => { IS => "1" }
   },
   "300a,007a" => {
          desc => "Repeat Fraction Cycle Length",
            vr => { IS => "1" }
   },
   "300a,007b" => {
          desc => "Fraction Pattern",
            vr => { LT => "1" }
   },
   "300a,0080" => {
          desc => "Number of Beams",
            vr => { IS => "1" }
   },
   "300a,0082" => {
          desc => "Beam Dose Specification Point",
            vr => { DS => "3" }
   },
   "300a,0084" => {
          desc => "Beam Dose",
            vr => { DS => "1" }
   },
   "300a,0086" => {
          desc => "Beam Meterset",
            vr => { DS => "1" }
   },
   "300a,0088" => {
          desc => "Beam Dose Point Depth",
            vr => { FL => "1" }
   },
   "300a,0089" => {
          desc => "Beam Dose Point Equivalent Depth",
            vr => { FL => "1" }
   },
   "300a,008a" => {
          desc => "Beam Dose Point SSD",
            vr => { FL => "1" }
   },
   "300a,00a0" => {
          desc => "Number of Brachy Application Setups",
            vr => { IS => "1" }
   },
   "300a,00a2" => {
          desc => "Brachy Application Setup Dose Specification Point",
            vr => { DS => "3" }
   },
   "300a,00a4" => {
          desc => "Brachy Application Setup Dose",
            vr => { DS => "1" }
   },
   "300a,00b0" => {
          desc => "Beam Sequence",
            vr => { SQ => "1" }
   },
   "300a,00b2" => {
          desc => "Treatment Machine Name ",
            vr => { SH => "1" }
   },
   "300a,00b3" => {
          desc => "Primary Dosimeter Unit",
            vr => { CS => "1" }
   },
   "300a,00b4" => {
          desc => "Source-Axis Distance",
            vr => { DS => "1" }
   },
   "300a,00b6" => {
          desc => "Beam Limiting Device Sequence",
            vr => { SQ => "1" }
   },
   "300a,00b8" => {
          desc => "RT Beam Limiting Device Type",
            vr => { CS => "1" }
   },
   "300a,00ba" => {
          desc => "Source to Beam Limiting Device Distance",
            vr => { DS => "1" }
   },
   "300a,00bb" => {
          desc => "Isocenter to Beam Limiting Device Distance",
            vr => { FL => "1" }
   },
   "300a,00bc" => {
          desc => "Number of Leaf/Jaw Pairs",
            vr => { IS => "1" }
   },
   "300a,00be" => {
          desc => "Leaf Position Boundaries",
            vr => { DS => "3-n" }
   },
   "300a,00c0" => {
          desc => "Beam Number",
            vr => { IS => "1" }
   },
   "300a,00c2" => {
          desc => "Beam Name",
            vr => { LO => "1" }
   },
   "300a,00c3" => {
          desc => "Beam Description",
            vr => { ST => "1" }
   },
   "300a,00c4" => {
          desc => "Beam Type",
            vr => { CS => "1" }
   },
   "300a,00c6" => {
          desc => "Radiation Type",
            vr => { CS => "1" }
   },
   "300a,00c7" => {
          desc => "High-Dose Technique Type",
            vr => { CS => "1" }
   },
   "300a,00c8" => {
          desc => "Reference Image Number",
            vr => { IS => "1" }
   },
   "300a,00ca" => {
          desc => "Planned Verification Image Sequence",
            vr => { SQ => "1" }
   },
   "300a,00cc" => {
          desc => "Imaging Device-Specific Acquisition Parameters",
            vr => { LO => "1-n" }
   },
   "300a,00ce" => {
          desc => "Treatment Delivery Type",
            vr => { CS => "1" }
   },
   "300a,00d0" => {
          desc => "Number of Wedges",
            vr => { IS => "1" }
   },
   "300a,00d1" => {
          desc => "Wedge Sequence",
            vr => { SQ => "1" }
   },
   "300a,00d2" => {
          desc => "Wedge Number",
            vr => { IS => "1" }
   },
   "300a,00d3" => {
          desc => "Wedge Type",
            vr => { CS => "1" }
   },
   "300a,00d4" => {
          desc => "Wedge ID",
            vr => { SH => "1" }
   },
   "300a,00d5" => {
          desc => "Wedge Angle",
            vr => { IS => "1" }
   },
   "300a,00d6" => {
          desc => "Wedge Factor",
            vr => { DS => "1" }
   },
   "300a,00d7" => {
          desc => "Total Wedge Tray Water-Equivalent Thickness",
            vr => { FL => "1" }
   },
   "300a,00d8" => {
          desc => "Wedge Orientation",
            vr => { DS => "1" }
   },
   "300a,00d9" => {
          desc => "Isocenter to Wedge Tray Distance",
            vr => { FL => "1" }
   },
   "300a,00da" => {
          desc => "Source to Wedge Tray Distance",
            vr => { DS => "1" }
   },
   "300a,00db" => {
          desc => "Wedge Thin Edge Position",
            vr => { FL => "1" }
   },
   "300a,00dc" => {
          desc => "Bolus ID",
            vr => { SH => "1" }
   },
   "300a,00dd" => {
          desc => "Bolus Description",
            vr => { ST => "1" }
   },
   "300a,00e0" => {
          desc => "Number of Compensators",
            vr => { IS => "1" }
   },
   "300a,00e1" => {
          desc => "Material ID",
            vr => { SH => "1" }
   },
   "300a,00e2" => {
          desc => "Total Compensator Tray Factor",
            vr => { DS => "1" }
   },
   "300a,00e3" => {
          desc => "Compensator Sequence",
            vr => { SQ => "1" }
   },
   "300a,00e4" => {
          desc => "Compensator Number",
            vr => { IS => "1" }
   },
   "300a,00e5" => {
          desc => "Compensator ID",
            vr => { SH => "1" }
   },
   "300a,00e6" => {
          desc => "Source to Compensator Tray Distance",
            vr => { DS => "1" }
   },
   "300a,00e7" => {
          desc => "Compensator Rows",
            vr => { IS => "1" }
   },
   "300a,00e8" => {
          desc => "Compensator Columns",
            vr => { IS => "1" }
   },
   "300a,00e9" => {
          desc => "Compensator Pixel Spacing",
            vr => { DS => "2" }
   },
   "300a,00ea" => {
          desc => "Compensator Position",
            vr => { DS => "2" }
   },
   "300a,00eb" => {
          desc => "Compensator Transmission Data",
            vr => { DS => "1-n" }
   },
   "300a,00ec" => {
          desc => "Compensator Thickness Data",
            vr => { DS => "1-n" }
   },
   "300a,00ed" => {
          desc => "Number of Boli",
            vr => { IS => "1" }
   },
   "300a,00ee" => {
          desc => "Compensator Type",
            vr => { CS => "1" }
   },
   "300a,00f0" => {
          desc => "Number of Blocks",
            vr => { IS => "1" }
   },
   "300a,00f2" => {
          desc => "Total Block Tray Factor",
            vr => { DS => "1" }
   },
   "300a,00f3" => {
          desc => "Total Block Tray Water-Equivalent Thickness",
            vr => { FL => "1" }
   },
   "300a,00f4" => {
          desc => "Block Sequence",
            vr => { SQ => "1" }
   },
   "300a,00f5" => {
          desc => "Block Tray ID",
            vr => { SH => "1" }
   },
   "300a,00f6" => {
          desc => "Source to Block Tray Distance",
            vr => { DS => "1" }
   },
   "300a,00f7" => {
          desc => "Isocenter to Block Tray Distance",
            vr => { FL => "1" }
   },
   "300a,00f8" => {
          desc => "Block Type",
            vr => { CS => "1" }
   },
   "300a,00f9" => {
          desc => "Accessory Code",
            vr => { LO => "1" }
   },
   "300a,00fa" => {
          desc => "Block Divergence",
            vr => { CS => "1" }
   },
   "300a,00fb" => {
          desc => "Block Mounting Position",
            vr => { CS => "1" }
   },
   "300a,00fc" => {
          desc => "Block Number",
            vr => { IS => "1" }
   },
   "300a,00fe" => {
          desc => "Block Name",
            vr => { LO => "1" }
   },
   "300a,0100" => {
          desc => "Block Thickness",
            vr => { DS => "1" }
   },
   "300a,0102" => {
          desc => "Block Transmission",
            vr => { DS => "1" }
   },
   "300a,0104" => {
          desc => "Block Number of Points",
            vr => { IS => "1" }
   },
   "300a,0106" => {
          desc => "Block Data",
            vr => { DS => "2-2n" }
   },
   "300a,0107" => {
          desc => "Applicator Sequence",
            vr => { SQ => "1" }
   },
   "300a,0108" => {
          desc => "Applicator ID",
            vr => { SH => "1" }
   },
   "300a,0109" => {
          desc => "Applicator Type",
            vr => { CS => "1" }
   },
   "300a,010a" => {
          desc => "Applicator Description",
            vr => { LO => "1" }
   },
   "300a,010c" => {
          desc => "Cumulative Dose Reference Coefficient",
            vr => { DS => "1" }
   },
   "300a,010e" => {
          desc => "Final Cumulative Meterset Weight",
            vr => { DS => "1" }
   },
   "300a,0110" => {
          desc => "Number of Control Points",
            vr => { IS => "1" }
   },
   "300a,0111" => {
          desc => "Control Point Sequence",
            vr => { SQ => "1" }
   },
   "300a,0112" => {
          desc => "Control Point Index",
            vr => { IS => "1" }
   },
   "300a,0114" => {
          desc => "Nominal Beam Energy",
            vr => { DS => "1" }
   },
   "300a,0115" => {
          desc => "Dose Rate Set",
            vr => { DS => "1" }
   },
   "300a,0116" => {
          desc => "Wedge Position Sequence",
            vr => { SQ => "1" }
   },
   "300a,0118" => {
          desc => "Wedge Position",
            vr => { CS => "1" }
   },
   "300a,011a" => {
          desc => "Beam Limiting Device Position Sequence",
            vr => { SQ => "1" }
   },
   "300a,011c" => {
          desc => "Leaf/Jaw Positions",
            vr => { DS => "2-2n" }
   },
   "300a,011e" => {
          desc => "Gantry Angle",
            vr => { DS => "1" }
   },
   "300a,011f" => {
          desc => "Gantry Rotation Direction",
            vr => { CS => "1" }
   },
   "300a,0120" => {
          desc => "Beam Limiting Device Angle",
            vr => { DS => "1" }
   },
   "300a,0121" => {
          desc => "Beam Limiting Device Rotation Direction",
            vr => { CS => "1" }
   },
   "300a,0122" => {
          desc => "Patient Support Angle",
            vr => { DS => "1" }
   },
   "300a,0123" => {
          desc => "Patient Support Rotation Direction",
            vr => { CS => "1" }
   },
   "300a,0124" => {
          desc => "Table Top Eccentric Axis Distance",
            vr => { DS => "1" }
   },
   "300a,0125" => {
          desc => "Table Top Eccentric Angle",
            vr => { DS => "1" }
   },
   "300a,0126" => {
          desc => "Table Top Eccentric Rotation Direction",
            vr => { CS => "1" }
   },
   "300a,0128" => {
          desc => "Table Top Vertical Position",
            vr => { DS => "1" }
   },
   "300a,0129" => {
          desc => "Table Top Longitudinal Position",
            vr => { DS => "1" }
   },
   "300a,012a" => {
          desc => "Table Top Lateral Position",
            vr => { DS => "1" }
   },
   "300a,012c" => {
          desc => "Isocenter Position",
            vr => { DS => "3" }
   },
   "300a,012e" => {
          desc => "Surface Entry Point",
            vr => { DS => "3" }
   },
   "300a,0130" => {
          desc => "Source to Surface Distance",
            vr => { DS => "1" }
   },
   "300a,0134" => {
          desc => "Cumulative Meterset Weight",
            vr => { DS => "1" }
   },
   "300a,0140" => {
          desc => "Table Top Pitch Angle",
            vr => { FL => "1" }
   },
   "300a,0142" => {
          desc => "Table Top Pitch Rotation Direction",
            vr => { CS => "1" }
   },
   "300a,0144" => {
          desc => "Table Top Roll Angle",
            vr => { FL => "1" }
   },
   "300a,0146" => {
          desc => "Table Top Roll Rotation Direction",
            vr => { CS => "1" }
   },
   "300a,0148" => {
          desc => "Head Fixation Angle",
            vr => { FL => "1" }
   },
   "300a,014a" => {
          desc => "Gantry Pitch Angle",
            vr => { FL => "1" }
   },
   "300a,014c" => {
          desc => "Gantry Pitch Rotation Direction",
            vr => { CS => "1" }
   },
   "300a,014e" => {
          desc => "Gantry Pitch Angle Tolerance",
            vr => { FL => "1" }
   },
   "300a,0180" => {
          desc => "Patient Setup Sequence",
            vr => { SQ => "1" }
   },
   "300a,0182" => {
          desc => "Patient Setup Number",
            vr => { IS => "1" }
   },
   "300a,0183" => {
          desc => "Patient Setup Label",
            vr => { LO => "1" }
   },
   "300a,0184" => {
          desc => "Patient Additional Position",
            vr => { LO => "1" }
   },
   "300a,0190" => {
          desc => "Fixation Device Sequence",
            vr => { SQ => "1" }
   },
   "300a,0192" => {
          desc => "Fixation Device Type",
            vr => { CS => "1" }
   },
   "300a,0194" => {
          desc => "Fixation Device Label",
            vr => { SH => "1" }
   },
   "300a,0196" => {
          desc => "Fixation Device Description",
            vr => { ST => "1" }
   },
   "300a,0198" => {
          desc => "Fixation Device Position",
            vr => { SH => "1" }
   },
   "300a,0199" => {
          desc => "Fixation Device Pitch Angle",
            vr => { FL => "1" }
   },
   "300a,019a" => {
          desc => "Fixation Device Roll Angle",
            vr => { FL => "1" }
   },
   "300a,01a0" => {
          desc => "Shielding Device Sequence",
            vr => { SQ => "1" }
   },
   "300a,01a2" => {
          desc => "Shielding Device Type",
            vr => { CS => "1" }
   },
   "300a,01a4" => {
          desc => "Shielding Device Label",
            vr => { SH => "1" }
   },
   "300a,01a6" => {
          desc => "Shielding Device Description",
            vr => { ST => "1" }
   },
   "300a,01a8" => {
          desc => "Shielding Device Position",
            vr => { SH => "1" }
   },
   "300a,01b0" => {
          desc => "Setup Technique",
            vr => { CS => "1" }
   },
   "300a,01b2" => {
          desc => "Setup Technique Description",
            vr => { ST => "1" }
   },
   "300a,01b4" => {
          desc => "Setup Device Sequence",
            vr => { SQ => "1" }
   },
   "300a,01b6" => {
          desc => "Setup Device Type",
            vr => { CS => "1" }
   },
   "300a,01b8" => {
          desc => "Setup Device Label",
            vr => { SH => "1" }
   },
   "300a,01ba" => {
          desc => "Setup Device Description",
            vr => { ST => "1" }
   },
   "300a,01bc" => {
          desc => "Setup Device Parameter",
            vr => { DS => "1" }
   },
   "300a,01d0" => {
          desc => "Setup Reference Description",
            vr => { ST => "1" }
   },
   "300a,01d2" => {
          desc => "Table Top Vertical Setup Displacement",
            vr => { DS => "1" }
   },
   "300a,01d4" => {
          desc => "Table Top Longitudinal Setup Displacement",
            vr => { DS => "1" }
   },
   "300a,01d6" => {
          desc => "Table Top Lateral Setup Displacement",
            vr => { DS => "1" }
   },
   "300a,0200" => {
          desc => "Brachy Treatment Technique",
            vr => { CS => "1" }
   },
   "300a,0202" => {
          desc => "Brachy Treatment Type",
            vr => { CS => "1" }
   },
   "300a,0206" => {
          desc => "Treatment Machine Sequence",
            vr => { SQ => "1" }
   },
   "300a,0210" => {
          desc => "Source Sequence",
            vr => { SQ => "1" }
   },
   "300a,0212" => {
          desc => "Source Number",
            vr => { IS => "1" }
   },
   "300a,0214" => {
          desc => "Source Type",
            vr => { CS => "1" }
   },
   "300a,0216" => {
          desc => "Source Manufacturer",
            vr => { LO => "1" }
   },
   "300a,0218" => {
          desc => "Active Source Diameter",
            vr => { DS => "1" }
   },
   "300a,021a" => {
          desc => "Active Source Length",
            vr => { DS => "1" }
   },
   "300a,0222" => {
          desc => "Source Encapsulation Nominal Thickness",
            vr => { DS => "1" }
   },
   "300a,0224" => {
          desc => "Source Encapsulation Nominal Transmission",
            vr => { DS => "1" }
   },
   "300a,0226" => {
          desc => "Source Isotope Name",
            vr => { LO => "1" }
   },
   "300a,0228" => {
          desc => "Source Isotope Half Life",
            vr => { DS => "1" }
   },
   "300a,0229" => {
          desc => "Source Strength Units",
            vr => { CS => "1" }
   },
   "300a,022a" => {
          desc => "Reference Air Kerma Rate",
            vr => { DS => "1" }
   },
   "300a,022b" => {
          desc => "Source Strength",
            vr => { DS => "1" }
   },
   "300a,022c" => {
          desc => "Source Strength Reference Date",
            vr => { DA => "1" }
   },
   "300a,022e" => {
          desc => "Source Strength Reference Time",
            vr => { TM => "1" }
   },
   "300a,0230" => {
          desc => "Application Setup Sequence",
            vr => { SQ => "1" }
   },
   "300a,0232" => {
          desc => "Application Setup Type",
            vr => { CS => "1" }
   },
   "300a,0234" => {
          desc => "Application Setup Number",
            vr => { IS => "1" }
   },
   "300a,0236" => {
          desc => "Application Setup Name",
            vr => { LO => "1" }
   },
   "300a,0238" => {
          desc => "Application Setup Manufacturer",
            vr => { LO => "1" }
   },
   "300a,0240" => {
          desc => "Template Number",
            vr => { IS => "1" }
   },
   "300a,0242" => {
          desc => "Template Type",
            vr => { SH => "1" }
   },
   "300a,0244" => {
          desc => "Template Name",
            vr => { LO => "1" }
   },
   "300a,0250" => {
          desc => "Total Reference Air Kerma",
            vr => { DS => "1" }
   },
   "300a,0260" => {
          desc => "Brachy Accessory Device Sequence",
            vr => { SQ => "1" }
   },
   "300a,0262" => {
          desc => "Brachy Accessory Device Number",
            vr => { IS => "1" }
   },
   "300a,0263" => {
          desc => "Brachy Accessory Device ID",
            vr => { SH => "1" }
   },
   "300a,0264" => {
          desc => "Brachy Accessory Device Type",
            vr => { CS => "1" }
   },
   "300a,0266" => {
          desc => "Brachy Accessory Device Name",
            vr => { LO => "1" }
   },
   "300a,026a" => {
          desc => "Brachy Accessory Device Nominal Thickness",
            vr => { DS => "1" }
   },
   "300a,026c" => {
          desc => "Brachy Accessory Device Nominal Transmission",
            vr => { DS => "1" }
   },
   "300a,0280" => {
          desc => "Channel Sequence",
            vr => { SQ => "1" }
   },
   "300a,0282" => {
          desc => "Channel Number",
            vr => { IS => "1" }
   },
   "300a,0284" => {
          desc => "Channel Length",
            vr => { DS => "1" }
   },
   "300a,0286" => {
          desc => "Channel Total Time",
            vr => { DS => "1" }
   },
   "300a,0288" => {
          desc => "Source Movement Type",
            vr => { CS => "1" }
   },
   "300a,028a" => {
          desc => "Number of Pulses",
            vr => { IS => "1" }
   },
   "300a,028c" => {
          desc => "Pulse Repetition Interval",
            vr => { DS => "1" }
   },
   "300a,0290" => {
          desc => "Source Applicator Number",
            vr => { IS => "1" }
   },
   "300a,0291" => {
          desc => "Source Applicator ID",
            vr => { SH => "1" }
   },
   "300a,0292" => {
          desc => "Source Applicator Type",
            vr => { CS => "1" }
   },
   "300a,0294" => {
          desc => "Source Applicator Name",
            vr => { LO => "1" }
   },
   "300a,0296" => {
          desc => "Source Applicator Length",
            vr => { DS => "1" }
   },
   "300a,0298" => {
          desc => "Source Applicator Manufacturer",
            vr => { LO => "1" }
   },
   "300a,029c" => {
          desc => "Source Applicator Wall Nominal Thickness",
            vr => { DS => "1" }
   },
   "300a,029e" => {
          desc => "Source Applicator Wall Nominal Transmission",
            vr => { DS => "1" }
   },
   "300a,02a0" => {
          desc => "Source Applicator Step Size",
            vr => { DS => "1" }
   },
   "300a,02a2" => {
          desc => "Transfer Tube Number",
            vr => { IS => "1" }
   },
   "300a,02a4" => {
          desc => "Transfer Tube Length",
            vr => { DS => "1" }
   },
   "300a,02b0" => {
          desc => "Channel Shield Sequence",
            vr => { SQ => "1" }
   },
   "300a,02b2" => {
          desc => "Channel Shield Number",
            vr => { IS => "1" }
   },
   "300a,02b3" => {
          desc => "Channel Shield ID",
            vr => { SH => "1" }
   },
   "300a,02b4" => {
          desc => "Channel Shield Name",
            vr => { LO => "1" }
   },
   "300a,02b8" => {
          desc => "Channel Shield Nominal Thickness",
            vr => { DS => "1" }
   },
   "300a,02ba" => {
          desc => "Channel Shield Nominal Transmission",
            vr => { DS => "1" }
   },
   "300a,02c8" => {
          desc => "Final Cumulative Time Weight",
            vr => { DS => "1" }
   },
   "300a,02d0" => {
          desc => "Brachy Control Point Sequence",
            vr => { SQ => "1" }
   },
   "300a,02d2" => {
          desc => "Control Point Relative Position",
            vr => { DS => "1" }
   },
   "300a,02d4" => {
          desc => "Control Point 3D Position",
            vr => { DS => "3" }
   },
   "300a,02d6" => {
          desc => "Cumulative Time Weight",
            vr => { DS => "1" }
   },
   "300a,02e0" => {
          desc => "Compensator Divergence",
            vr => { CS => "1" }
   },
   "300a,02e1" => {
          desc => "Compensator Mounting Position",
            vr => { CS => "1" }
   },
   "300a,02e2" => {
          desc => "Source to Compensator Distance",
            vr => { DS => "1-n" }
   },
   "300a,02e3" => {
          desc => "Total Compensator Tray Water-Equivalent Thickness",
            vr => { FL => "1" }
   },
   "300a,02e4" => {
          desc => "Isocenter to Compensator Tray Distance",
            vr => { FL => "1" }
   },
   "300a,02e5" => {
          desc => "Compensator Column Offset",
            vr => { FL => "1" }
   },
   "300a,02e6" => {
          desc => "Isocenter to Compensator Distances",
            vr => { FL => "1-n" }
   },
   "300a,02e7" => {
          desc => "Compensator Relative Stopping Power Ratio",
            vr => { FL => "1" }
   },
   "300a,02e8" => {
          desc => "Compensator Milling Tool Diameter",
            vr => { FL => "1" }
   },
   "300a,02ea" => {
          desc => "Ion Range Compensator Sequence",
            vr => { SQ => "1" }
   },
   "300a,02eb" => {
          desc => "Compensator Description",
            vr => { LT => "1" }
   },
   "300a,0302" => {
          desc => "Radiation Mass Number",
            vr => { IS => "1" }
   },
   "300a,0304" => {
          desc => "Radiation Atomic Number",
            vr => { IS => "1" }
   },
   "300a,0306" => {
          desc => "Radiation Charge State",
            vr => { SS => "1" }
   },
   "300a,0308" => {
          desc => "Scan Mode",
            vr => { CS => "1" }
   },
   "300a,030a" => {
          desc => "Virtual Source-Axis Distances",
            vr => { FL => "2" }
   },
   "300a,030c" => {
          desc => "Snout Sequence",
            vr => { SQ => "1" }
   },
   "300a,030d" => {
          desc => "Snout Position",
            vr => { FL => "1" }
   },
   "300a,030f" => {
          desc => "Snout ID",
            vr => { SH => "1" }
   },
   "300a,0312" => {
          desc => "Number of Range Shifters",
            vr => { IS => "1" }
   },
   "300a,0314" => {
          desc => "Range Shifter Sequence",
            vr => { SQ => "1" }
   },
   "300a,0316" => {
          desc => "Range Shifter Number",
            vr => { IS => "1" }
   },
   "300a,0318" => {
          desc => "Range Shifter ID",
            vr => { SH => "1" }
   },
   "300a,0320" => {
          desc => "Range Shifter Type",
            vr => { CS => "1" }
   },
   "300a,0322" => {
          desc => "Range Shifter Description",
            vr => { LO => "1" }
   },
   "300a,0330" => {
          desc => "Number of Lateral Spreading Devices",
            vr => { IS => "1" }
   },
   "300a,0332" => {
          desc => "Lateral Spreading Device Sequence",
            vr => { SQ => "1" }
   },
   "300a,0334" => {
          desc => "Lateral Spreading Device Number",
            vr => { IS => "1" }
   },
   "300a,0336" => {
          desc => "Lateral Spreading Device ID",
            vr => { SH => "1" }
   },
   "300a,0338" => {
          desc => "Lateral Spreading Device Type",
            vr => { CS => "1" }
   },
   "300a,033a" => {
          desc => "Lateral Spreading Device Description",
            vr => { LO => "1" }
   },
   "300a,033c" => {
          desc => "Lateral Spreading Device Water Equivalent Thickness",
            vr => { FL => "1" }
   },
   "300a,0340" => {
          desc => "Number of Range Modulators",
            vr => { IS => "1" }
   },
   "300a,0342" => {
          desc => "Range Modulator Sequence",
            vr => { SQ => "1" }
   },
   "300a,0344" => {
          desc => "Range Modulator Number",
            vr => { IS => "1" }
   },
   "300a,0346" => {
          desc => "Range Modulator ID",
            vr => { SH => "1" }
   },
   "300a,0348" => {
          desc => "Range Modulator Type",
            vr => { CS => "1" }
   },
   "300a,034a" => {
          desc => "Range Modulator Description",
            vr => { LO => "1" }
   },
   "300a,034c" => {
          desc => "Beam Current Modulation ID",
            vr => { SH => "1" }
   },
   "300a,0350" => {
          desc => "Patient Support Type",
            vr => { CS => "1" }
   },
   "300a,0352" => {
          desc => "Patient Support ID",
            vr => { SH => "1" }
   },
   "300a,0354" => {
          desc => "Patient Support Accessory Code",
            vr => { LO => "1" }
   },
   "300a,0356" => {
          desc => "Fixation Light Azimuthal Angle",
            vr => { FL => "1" }
   },
   "300a,0358" => {
          desc => "Fixation Light Polar Angle",
            vr => { FL => "1" }
   },
   "300a,035a" => {
          desc => "Meterset Rate",
            vr => { FL => "1" }
   },
   "300a,0360" => {
          desc => "Range Shifter Settings Sequence",
            vr => { SQ => "1" }
   },
   "300a,0362" => {
          desc => "Range Shifter Setting",
            vr => { LO => "1" }
   },
   "300a,0364" => {
          desc => "Isocenter to Range Shifter Distance",
            vr => { FL => "1" }
   },
   "300a,0366" => {
          desc => "Range Shifter Water Equivalent Thickness",
            vr => { FL => "1" }
   },
   "300a,0370" => {
          desc => "Lateral Spreading Device Settings Sequence",
            vr => { SQ => "1" }
   },
   "300a,0372" => {
          desc => "Lateral Spreading Device Setting",
            vr => { LO => "1" }
   },
   "300a,0374" => {
          desc => "Isocenter to Lateral Spreading Device Distance",
            vr => { FL => "1" }
   },
   "300a,0380" => {
          desc => "Range Modulator Settings Sequence",
            vr => { SQ => "1" }
   },
   "300a,0382" => {
          desc => "Range Modulator Gating Start Value",
            vr => { FL => "1" }
   },
   "300a,0384" => {
          desc => "Range Modulator Gating Stop Value",
            vr => { FL => "1" }
   },
   "300a,0386" => {
          desc => "Range Modulator Gating Start Water Equivalent Thickness",
            vr => { FL => "1" }
   },
   "300a,0388" => {
          desc => "Range Modulator Gating Stop Water Equivalent Thickness",
            vr => { FL => "1" }
   },
   "300a,038a" => {
          desc => "Isocenter to Range Modulator Distance",
            vr => { FL => "1" }
   },
   "300a,0390" => {
          desc => "Scan Spot Tune ID",
            vr => { SH => "1" }
   },
   "300a,0392" => {
          desc => "Number of Scan Spot Positions",
            vr => { IS => "1" }
   },
   "300a,0394" => {
          desc => "Scan Spot Position Map",
            vr => { FL => "1-n" }
   },
   "300a,0396" => {
          desc => "Scan Spot Meterset Weights",
            vr => { FL => "1-n" }
   },
   "300a,0398" => {
          desc => "Scanning Spot Size",
            vr => { FL => "2" }
   },
   "300a,039a" => {
          desc => "Number of Paintings",
            vr => { IS => "1" }
   },
   "300a,03a0" => {
          desc => "Ion Tolerance Table Sequence",
            vr => { SQ => "1" }
   },
   "300a,03a2" => {
          desc => "Ion Beam Sequence",
            vr => { SQ => "1" }
   },
   "300a,03a4" => {
          desc => "Ion Beam Limiting Device Sequence",
            vr => { SQ => "1" }
   },
   "300a,03a6" => {
          desc => "Ion Block Sequence",
            vr => { SQ => "1" }
   },
   "300a,03a8" => {
          desc => "Ion Control Point Sequence",
            vr => { SQ => "1" }
   },
   "300a,03aa" => {
          desc => "Ion Wedge Sequence",
            vr => { SQ => "1" }
   },
   "300a,03ac" => {
          desc => "Ion Wedge Position Sequence",
            vr => { SQ => "1" }
   },
   "300a,0401" => {
          desc => "Referenced Setup Image Sequence",
            vr => { SQ => "1" }
   },
   "300a,0402" => {
          desc => "Setup Image Comment",
            vr => { ST => "1" }
   },
   "300a,0410" => {
          desc => "Motion Synchronization Sequence",
            vr => { SQ => "1" }
   },
   "300a,0412" => {
          desc => "Control Point Orientation",
            vr => { FL => "3" }
   },
   "300a,0420" => {
          desc => "General Accessory Sequence",
            vr => { SQ => "1" }
   },
   "300a,0421" => {
          desc => "General Accessory ID",
            vr => { SH => "1" }
   },
   "300a,0422" => {
          desc => "General Accessory Description",
            vr => { ST => "1" }
   },
   "300a,0423" => {
          desc => "General Accessory Type",
            vr => { CS => "1" }
   },
   "300a,0424" => {
          desc => "General Accessory Number",
            vr => { IS => "1" }
   },
   "300c,0002" => {
          desc => "Referenced RT Plan Sequence",
            vr => { SQ => "1" }
   },
   "300c,0004" => {
          desc => "Referenced Beam Sequence",
            vr => { SQ => "1" }
   },
   "300c,0006" => {
          desc => "Referenced Beam Number",
            vr => { IS => "1" }
   },
   "300c,0007" => {
          desc => "Referenced Reference Image Number",
            vr => { IS => "1" }
   },
   "300c,0008" => {
          desc => "Start Cumulative Meterset Weight",
            vr => { DS => "1" }
   },
   "300c,0009" => {
          desc => "End Cumulative Meterset Weight",
            vr => { DS => "1" }
   },
   "300c,000a" => {
          desc => "Referenced Brachy Application Setup Sequence",
            vr => { SQ => "1" }
   },
   "300c,000c" => {
          desc => "Referenced Brachy Application Setup Number",
            vr => { IS => "1" }
   },
   "300c,000e" => {
          desc => "Referenced Source Number",
            vr => { IS => "1" }
   },
   "300c,0020" => {
          desc => "Referenced Fraction Group Sequence",
            vr => { SQ => "1" }
   },
   "300c,0022" => {
          desc => "Referenced Fraction Group Number",
            vr => { IS => "1" }
   },
   "300c,0040" => {
          desc => "Referenced Verification Image Sequence",
            vr => { SQ => "1" }
   },
   "300c,0042" => {
          desc => "Referenced Reference Image Sequence",
            vr => { SQ => "1" }
   },
   "300c,0050" => {
          desc => "Referenced Dose Reference Sequence",
            vr => { SQ => "1" }
   },
   "300c,0051" => {
          desc => "Referenced Dose Reference Number",
            vr => { IS => "1" }
   },
   "300c,0055" => {
          desc => "Brachy Referenced Dose Reference Sequence",
            vr => { SQ => "1" }
   },
   "300c,0060" => {
          desc => "Referenced Structure Set Sequence",
            vr => { SQ => "1" }
   },
   "300c,006a" => {
          desc => "Referenced Patient Setup Number",
            vr => { IS => "1" }
   },
   "300c,0080" => {
          desc => "Referenced Dose Sequence",
            vr => { SQ => "1" }
   },
   "300c,00a0" => {
          desc => "Referenced Tolerance Table Number",
            vr => { IS => "1" }
   },
   "300c,00b0" => {
          desc => "Referenced Bolus Sequence",
            vr => { SQ => "1" }
   },
   "300c,00c0" => {
          desc => "Referenced Wedge Number",
            vr => { IS => "1" }
   },
   "300c,00d0" => {
          desc => "Referenced Compensator Number",
            vr => { IS => "1" }
   },
   "300c,00e0" => {
          desc => "Referenced Block Number",
            vr => { IS => "1" }
   },
   "300c,00f0" => {
          desc => "Referenced Control Point Index",
            vr => { IS => "1" }
   },
   "300c,00f2" => {
          desc => "Referenced Control Point Sequence",
            vr => { SQ => "1" }
   },
   "300c,00f4" => {
          desc => "Referenced Start Control Point Index",
            vr => { IS => "1" }
   },
   "300c,00f6" => {
          desc => "Referenced Stop Control Point Index",
            vr => { IS => "1" }
   },
   "300c,0100" => {
          desc => "Referenced Range Shifter Number",
            vr => { IS => "1" }
   },
   "300c,0102" => {
          desc => "Referenced Lateral Spreading Device Number",
            vr => { IS => "1" }
   },
   "300c,0104" => {
          desc => "Referenced Range Modulator Number",
            vr => { IS => "1" }
   },
   "300e,0002" => {
          desc => "Approval Status",
            vr => { CS => "1" }
   },
   "300e,0004" => {
          desc => "Review Date",
            vr => { DA => "1" }
   },
   "300e,0005" => {
          desc => "Review Time",
            vr => { TM => "1" }
   },
   "300e,0008" => {
          desc => "Reviewer Name",
            vr => { PN => "1" }
   },
   "4000,0010" => {
          desc => "Arbitrary",
            vr => { LT => "1" },
           ret => 1
    },
   "4000,4000" => {
          desc => "Text Comments",
            vr => { LT => "1" },
           ret => 1
    },
   "4008,0040" => {
          desc => "Results ID",
            vr => { SH => "1" },
           ret => 1
    },
   "4008,0042" => {
          desc => "Results ID Issuer",
            vr => { LO => "1" },
           ret => 1
    },
   "4008,0050" => {
          desc => "Referenced Interpretation Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "4008,0100" => {
          desc => "Interpretation Recorded Date",
            vr => { DA => "1" },
           ret => 1
    },
   "4008,0101" => {
          desc => "Interpretation Recorded Time",
            vr => { TM => "1" },
           ret => 1
    },
   "4008,0102" => {
          desc => "Interpretation Recorder",
            vr => { PN => "1" },
           ret => 1
    },
   "4008,0103" => {
          desc => "Reference to Recorded Sound",
            vr => { LO => "1" },
           ret => 1
    },
   "4008,0108" => {
          desc => "Interpretation Transcription Date",
            vr => { DA => "1" },
           ret => 1
    },
   "4008,0109" => {
          desc => "Interpretation Transcription Time",
            vr => { TM => "1" },
           ret => 1
    },
   "4008,010a" => {
          desc => "Interpretation Transcriber",
            vr => { PN => "1" },
           ret => 1
    },
   "4008,010b" => {
          desc => "Interpretation Text",
            vr => { ST => "1" },
           ret => 1
    },
   "4008,010c" => {
          desc => "Interpretation Author",
            vr => { PN => "1" },
           ret => 1
    },
   "4008,0111" => {
          desc => "Interpretation Approver Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "4008,0112" => {
          desc => "Interpretation Approval Date",
            vr => { DA => "1" },
           ret => 1
    },
   "4008,0113" => {
          desc => "Interpretation Approval Time",
            vr => { TM => "1" },
           ret => 1
    },
   "4008,0114" => {
          desc => "Physician Approving Interpretation",
            vr => { PN => "1" },
           ret => 1
    },
   "4008,0115" => {
          desc => "Interpretation Diagnosis Description",
            vr => { LT => "1" },
           ret => 1
    },
   "4008,0117" => {
          desc => "Interpretation Diagnosis Code Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "4008,0118" => {
          desc => "Results Distribution List Sequence",
            vr => { SQ => "1" },
           ret => 1
    },
   "4008,0119" => {
          desc => "Distribution Name",
            vr => { PN => "1" },
           ret => 1
    },
   "4008,011a" => {
          desc => "Distribution Address",
            vr => { LO => "1" },
           ret => 1
    },
   "4008,0200" => {
          desc => "Interpretation ID",
            vr => { SH => "1" },
           ret => 1
    },
   "4008,0202" => {
          desc => "Interpretation ID Issuer",
            vr => { LO => "1" },
           ret => 1
    },
   "4008,0210" => {
          desc => "Interpretation Type ID",
            vr => { CS => "1" },
           ret => 1
    },
   "4008,0212" => {
          desc => "Interpretation Status ID",
            vr => { CS => "1" },
           ret => 1
    },
   "4008,0300" => {
          desc => "Impressions",
            vr => { ST => "1" },
           ret => 1
    },
   "4008,4000" => {
          desc => "Results Comments",
            vr => { ST => "1" },
           ret => 1
    },
   "4ffe,0001" => {
          desc => "MAC Parameters Sequence",
            vr => { SQ => "1" }
   },
   "50xx,0005" => {
          desc => "Curve Dimensions ",
            vr => { US => "1" },
           ret => 1
    },
   "50xx,0010" => {
          desc => "Number of Points ",
            vr => { US => "1" },
           ret => 1
    },
   "50xx,0020" => {
          desc => "Type of Data",
            vr => { CS => "1" },
           ret => 1
    },
   "50xx,0022" => {
          desc => "Curve Description",
            vr => { LO => "1" },
           ret => 1
    },
   "50xx,0030" => {
          desc => "Axis Units ",
            vr => { SH => "1-n" },
           ret => 1
    },
   "50xx,0040" => {
          desc => "Axis Labels ",
            vr => { SH => "1-n" },
           ret => 1
    },
   "50xx,0103" => {
          desc => "Data Value Representation ",
            vr => { US => "1" },
           ret => 1
    },
   "50xx,0104" => {
          desc => "Minimum Coordinate Value ",
            vr => { US => "1-n" },
           ret => 1
    },
   "50xx,0105" => {
          desc => "Maximum Coordinate Value ",
            vr => { US => "1-n" },
           ret => 1
    },
   "50xx,0106" => {
          desc => "Curve Range",
            vr => { SH => "1-n" },
           ret => 1
    },
   "50xx,0110" => {
          desc => "Curve Data Descriptor",
            vr => { US => "1-n" },
           ret => 1
    },
   "50xx,0112" => {
          desc => "Coordinate Start Value",
            vr => { US => "1-n" },
           ret => 1
    },
   "50xx,0114" => {
          desc => "Coordinate Step Value",
            vr => { US => "1-n" },
           ret => 1
    },
   "50xx,1001" => {
          desc => "Curve Activation Layer ",
            vr => { CS => "1" },
           ret => 1
    },
   "50xx,2000" => {
          desc => "Audio Type",
            vr => { US => "1" },
           ret => 1
    },
   "50xx,2002" => {
          desc => "Audio Sample Format",
            vr => { US => "1" },
           ret => 1
    },
   "50xx,2004" => {
          desc => "Number of Channels",
            vr => { US => "1" },
           ret => 1
    },
   "50xx,2006" => {
          desc => "Number of Samples",
            vr => { UL => "1" },
           ret => 1
    },
   "50xx,2008" => {
          desc => "Sample Rate",
            vr => { UL => "1" },
           ret => 1
    },
   "50xx,200a" => {
          desc => "Total Time",
            vr => { UL => "1" },
           ret => 1
    },
   "50xx,200c" => {
          desc => "Audio Sample Data",
            vr => { OB => "1", OW => "1" },
           ret => 1
    },
   "50xx,200e" => {
          desc => "Audio Comments",
            vr => { LT => "1" },
           ret => 1
    },
   "50xx,2500" => {
          desc => "Curve Label",
            vr => { LO => "1" },
           ret => 1
    },
   "50xx,2600" => {
          desc => "Curve Referenced Overlay Sequence ",
            vr => { SQ => "1" },
           ret => 1
    },
   "50xx,2610" => {
          desc => "Curve Referenced Overlay Group",
            vr => { US => "1" },
           ret => 1
    },
   "50xx,3000" => {
          desc => "Curve Data",
            vr => { OB => "1", OW => "1" },
           ret => 1
    },
   "5200,9229" => {
          desc => "Shared Functional Groups Sequence",
            vr => { SQ => "1" }
   },
   "5200,9230" => {
          desc => "Per-frame Functional Groups Sequence",
            vr => { SQ => "1" }
   },
   "5400,0100" => {
          desc => "Waveform Sequence ",
            vr => { SQ => "1" }
   },
   "5400,0110" => {
          desc => "Channel Minimum Value ",
            vr => { OB => "1", OW => "1" }
   },
   "5400,0112" => {
          desc => "Channel Maximum Value ",
            vr => { OB => "1", OW => "1" }
   },
   "5400,1004" => {
          desc => "Waveform Bits Allocated",
            vr => { US => "1" }
   },
   "5400,1006" => {
          desc => "Waveform Sample Interpretation",
            vr => { CS => "1" }
   },
   "5400,100a" => {
          desc => "Waveform Padding Value",
            vr => { OB => "1", OW => "1" }
   },
   "5400,1010" => {
          desc => "Waveform Data ",
            vr => { OB => "1", OW => "1" }
   },
   "5600,0010" => {
          desc => "First Order Phase Correction Angle",
            vr => { OF => "1" }
   },
   "5600,0020" => {
          desc => "Spectroscopy Data",
            vr => { OF => "1" }
   },
   "60xx,0010" => {
          desc => "Overlay Rows",
            vr => { US => "1" }
   },
   "60xx,0011" => {
          desc => "Overlay Columns",
            vr => { US => "1" }
   },
   "60xx,0012" => {
          desc => "Overlay Planes",
            vr => { US => "1" },
           ret => 1
    },
   "60xx,0015" => {
          desc => "Number of Frames in Overlay",
            vr => { IS => "1" }
   },
   "60xx,0022" => {
          desc => "Overlay Description",
            vr => { LO => "1" }
   },
   "60xx,0040" => {
          desc => "Overlay Type",
            vr => { CS => "1" }
   },
   "60xx,0045" => {
          desc => "Overlay Subtype",
            vr => { LO => "1" }
   },
   "60xx,0050" => {
          desc => "Overlay Origin",
            vr => { SS => "2" }
   },
   "60xx,0051" => {
          desc => "Image Frame Origin",
            vr => { US => "1" }
   },
   "60xx,0052" => {
          desc => "Overlay Plane Origin",
            vr => { US => "1" },
           ret => 1
    },
   "60xx,0060" => {
          desc => "Overlay Compression Code",
            vr => { CS => "1" },
           ret => 1
    },
   "60xx,0061" => {
          desc => "Overlay Compression Originator",
            vr => { SH => "1" },
           ret => 1
    },
   "60xx,0062" => {
          desc => "Overlay Compression Label",
            vr => { SH => "1" },
           ret => 1
    },
   "60xx,0063" => {
          desc => "Overlay Compression Description",
            vr => { CS => "1" },
           ret => 1
    },
   "60xx,0066" => {
          desc => "Overlay Compression Step Pointers",
            vr => { AT => "1-n" },
           ret => 1
    },
   "60xx,0068" => {
          desc => "Overlay Repeat Interval",
            vr => { US => "1" },
           ret => 1
    },
   "60xx,0069" => {
          desc => "Overlay Bits Grouped",
            vr => { US => "1" },
           ret => 1
    },
   "60xx,0100" => {
          desc => "Overlay Bits Allocated",
            vr => { US => "1" }
   },
   "60xx,0102" => {
          desc => "Overlay Bit Position",
            vr => { US => "1" }
   },
   "60xx,0110" => {
          desc => "Overlay Format",
            vr => { CS => "1" },
           ret => 1
    },
   "60xx,0200" => {
          desc => "Overlay Location",
            vr => { US => "1" },
           ret => 1
    },
   "60xx,0800" => {
          desc => "Overlay Code Label",
            vr => { CS => "1-n" },
           ret => 1
    },
   "60xx,0802" => {
          desc => "Overlay Number of Tables",
            vr => { US => "1" },
           ret => 1
    },
   "60xx,0803" => {
          desc => "Overlay Code Table Location",
            vr => { AT => "1-n" },
           ret => 1
    },
   "60xx,0804" => {
          desc => "Overlay Bits For Code Word",
            vr => { US => "1" },
           ret => 1
    },
   "60xx,1001" => {
          desc => "Overlay Activation Layer ",
            vr => { CS => "1" }
   },
   "60xx,1100" => {
          desc => "Overlay Descriptor - Gray",
            vr => { US => "1" },
           ret => 1
    },
   "60xx,1101" => {
          desc => "Overlay Descriptor - Red",
            vr => { US => "1" },
           ret => 1
    },
   "60xx,1102" => {
          desc => "Overlay Descriptor - Green",
            vr => { US => "1" },
           ret => 1
    },
   "60xx,1103" => {
          desc => "Overlay Descriptor - Blue",
            vr => { US => "1" },
           ret => 1
    },
   "60xx,1200" => {
          desc => "Overlays - Gray",
            vr => { US => "1-n" },
           ret => 1
    },
   "60xx,1201" => {
          desc => "Overlays - Red",
            vr => { US => "1-n" },
           ret => 1
    },
   "60xx,1202" => {
          desc => "Overlays - Green",
            vr => { US => "1-n" },
           ret => 1
    },
   "60xx,1203" => {
          desc => "Overlays - Blue",
            vr => { US => "1-n" },
           ret => 1
    },
   "60xx,1301" => {
          desc => "ROI Area",
            vr => { IS => "1" }
   },
   "60xx,1302" => {
          desc => "ROI Mean",
            vr => { DS => "1" }
   },
   "60xx,1303" => {
          desc => "ROI Standard Deviation",
            vr => { DS => "1" }
   },
   "60xx,1500" => {
          desc => "Overlay Label",
            vr => { LO => "1" }
   },
   "60xx,3000" => {
          desc => "Overlay Data",
            vr => { OB => "1", OW => "1" }
   },
   "60xx,4000" => {
          desc => "Overlay Comments",
            vr => { LT => "1" },
           ret => 1
    },
   "7fe0,0010" => {
          desc => "Pixel Data",
            vr => { OB => "1", OW => "1" }
   },
   "7fe0,0020" => {
          desc => "Coefficients SDVN",
            vr => { OW => "1" },
           ret => 1
    },
   "7fe0,0030" => {
          desc => "Coefficients SDHN",
            vr => { OW => "1" },
           ret => 1
    },
   "7fe0,0040" => {
          desc => "Coefficients SDDN",
            vr => { OW => "1" },
           ret => 1
    },
   "7fxx,0010" => {
          desc => "Variable Pixel Data",
            vr => { OB => "1", OW => "1" },
           ret => 1
    },
   "7fxx,0011" => {
          desc => "Variable Next Data Group",
            vr => { US => "1" },
           ret => 1
    },
   "7fxx,0020" => {
          desc => "Variable Coefficients SDVN",
            vr => { OW => "1" },
           ret => 1
    },
   "7fxx,0030" => {
          desc => "Variable Coefficients SDHN",
            vr => { OW => "1" },
           ret => 1
    },
   "7fxx,0040" => {
          desc => "Variable Coefficients SDDN",
            vr => { OW => "1" },
           ret => 1
    },
   "fffa,fffa" => {
          desc => "Digital Signatures Sequence",
            vr => { SQ => "1" }
   },
   "fffc,fffc" => {
          desc => "Data Set Trailing Padding",
            vr => { OB => "1" }
   },
};

my $DicomTagNameList = {
   FileMetaInformationGroupLength => "0002,0000",
   FileMetaInformationVersion => "0002,0001",
   MediaStorageSOPClassUID => "0002,0002",
   MediaStorageSOPInstanceUID => "0002,0003",
   TransferSyntaxUID => "0002,0010",
   ImplementationClassUID => "0002,0012",
   ImplementationVersionName => "0002,0013",
   SourceApplicationEntityTitle => "0002,0016",
   PrivateInformationCreatorUID => "0002,0100",
   PrivateInformation => "0002,0102",
   FileSetID => "0004,1130",
   FileSetDescriptorFileID => "0004,1141",
   SpecificCharacterSetOfFileSetDescriptorFile => "0004,1142",
   OffsetOfTheFirstDirectoryRecordOfTheRootDirectoryEntity => "0004,1200",
   OffsetOfTheLastDirectoryRecordOfTheRootDirectoryEntity => "0004,1202",
   FileSetConsistencyFlag => "0004,1212",
   DirectoryRecordSequence => "0004,1220",
   OffsetOfTheNextDirectoryRecord => "0004,1400",
   RecordInUseFlag => "0004,1410",
   OffsetOfReferencedLowerLevelDirectoryEntity => "0004,1420",
   DirectoryRecordType => "0004,1430",
   PrivateRecordUID => "0004,1432",
   ReferencedFileID => "0004,1500",
   MRDRDirectoryRecordOffset => "0004,1504",
   ReferencedSOPClassUIDInFile => "0004,1510",
   ReferencedSOPInstanceUIDInFile => "0004,1511",
   ReferencedTransferSyntaxUIDInFile => "0004,1512",
   ReferencedRelatedGeneralSOPClassUIDInFile => "0004,151a",
   NumberOfReferences => "0004,1600",
   LengthToEnd => "0008,0001",
   SpecificCharacterSet => "0008,0005",
   LanguageCodeSequence => "0008,0006",
   ImageType => "0008,0008",
   RecognitionCode => "0008,0010",
   InstanceCreationDate => "0008,0012",
   InstanceCreationTime => "0008,0013",
   InstanceCreatorUID => "0008,0014",
   SOPClassUID => "0008,0016",
   SOPInstanceUID => "0008,0018",
   RelatedGeneralSOPClassUID => "0008,001a",
   OriginalSpecializedSOPClassUID => "0008,001b",
   StudyDate => "0008,0020",
   SeriesDate => "0008,0021",
   AcquisitionDate => "0008,0022",
   ContentDate => "0008,0023",
   OverlayDate => "0008,0024",
   CurveDate => "0008,0025",
   AcquisitionDateTime => "0008,002a",
   StudyTime => "0008,0030",
   SeriesTime => "0008,0031",
   AcquisitionTime => "0008,0032",
   ContentTime => "0008,0033",
   OverlayTime => "0008,0034",
   CurveTime => "0008,0035",
   DataSetType => "0008,0040",
   DataSetSubtype => "0008,0041",
   NuclearMedicineSeriesType => "0008,0042",
   AccessionNumber => "0008,0050",
   IssuerOfAccessionNumberSequence => "0008,0051",
   QueryRetrieveLevel => "0008,0052",
   RetrieveAETitle => "0008,0054",
   InstanceAvailability => "0008,0056",
   FailedSOPInstanceUIDList => "0008,0058",
   Modality => "0008,0060",
   ModalitiesInStudy => "0008,0061",
   SOPClassesInStudy => "0008,0062",
   ConversionType => "0008,0064",
   PresentationIntentType => "0008,0068",
   Manufacturer => "0008,0070",
   InstitutionName => "0008,0080",
   InstitutionAddress => "0008,0081",
   InstitutionCodeSequence => "0008,0082",
   ReferringPhysicianName => "0008,0090",
   ReferringPhysicianAddress => "0008,0092",
   ReferringPhysicianTelephoneNumbers => "0008,0094",
   ReferringPhysicianIdentificationSequence => "0008,0096",
   CodeValue => "0008,0100",
   CodingSchemeDesignator => "0008,0102",
   CodingSchemeVersion => "0008,0103",
   CodeMeaning => "0008,0104",
   MappingResource => "0008,0105",
   ContextGroupVersion => "0008,0106",
   ContextGroupLocalVersion => "0008,0107",
   ContextGroupExtensionFlag => "0008,010b",
   CodingSchemeUID => "0008,010c",
   ContextGroupExtensionCreatorUID => "0008,010d",
   ContextIdentifier => "0008,010f",
   CodingSchemeIdentificationSequence => "0008,0110",
   CodingSchemeRegistry => "0008,0112",
   CodingSchemeExternalID => "0008,0114",
   CodingSchemeName => "0008,0115",
   CodingSchemeResponsibleOrganization => "0008,0116",
   ContextUID => "0008,0117",
   TimezoneOffsetFromUTC => "0008,0201",
   NetworkID => "0008,1000",
   StationName => "0008,1010",
   StudyDescription => "0008,1030",
   ProcedureCodeSequence => "0008,1032",
   SeriesDescription => "0008,103e",
   SeriesDescriptionCodeSequence => "0008,103f",
   InstitutionalDepartmentName => "0008,1040",
   PhysiciansOfRecord => "0008,1048",
   PhysiciansOfRecordIdentificationSequence => "0008,1049",
   PerformingPhysicianName => "0008,1050",
   PerformingPhysicianIdentificationSequence => "0008,1052",
   NameOfPhysiciansReadingStudy => "0008,1060",
   PhysiciansReadingStudyIdentificationSequence => "0008,1062",
   OperatorsName => "0008,1070",
   OperatorIdentificationSequence => "0008,1072",
   AdmittingDiagnosesDescription => "0008,1080",
   AdmittingDiagnosesCodeSequence => "0008,1084",
   ManufacturerModelName => "0008,1090",
   ReferencedResultsSequence => "0008,1100",
   ReferencedStudySequence => "0008,1110",
   ReferencedPerformedProcedureStepSequence => "0008,1111",
   ReferencedSeriesSequence => "0008,1115",
   ReferencedPatientSequence => "0008,1120",
   ReferencedVisitSequence => "0008,1125",
   ReferencedOverlaySequence => "0008,1130",
   ReferencedStereometricInstanceSequence => "0008,1134",
   ReferencedWaveformSequence => "0008,113a",
   ReferencedImageSequence => "0008,1140",
   ReferencedCurveSequence => "0008,1145",
   ReferencedInstanceSequence => "0008,114a",
   ReferencedRealWorldValueMappingInstanceSequence => "0008,114b",
   ReferencedSOPClassUID => "0008,1150",
   ReferencedSOPInstanceUID => "0008,1155",
   SOPClassesSupported => "0008,115a",
   ReferencedFrameNumber => "0008,1160",
   SimpleFrameList => "0008,1161",
   CalculatedFrameList => "0008,1162",
   TimeRange => "0008,1163",
   FrameExtractionSequence => "0008,1164",
   MultiFrameSourceSOPInstanceUID => "0008,1167",
   TransactionUID => "0008,1195",
   FailureReason => "0008,1197",
   FailedSOPSequence => "0008,1198",
   ReferencedSOPSequence => "0008,1199",
   StudiesContainingOtherReferencedInstancesSequence => "0008,1200",
   RelatedSeriesSequence => "0008,1250",
   LossyImageCompressionRetired => "0008,2110",
   DerivationDescription => "0008,2111",
   SourceImageSequence => "0008,2112",
   StageName => "0008,2120",
   StageNumber => "0008,2122",
   NumberOfStages => "0008,2124",
   ViewName => "0008,2127",
   ViewNumber => "0008,2128",
   NumberOfEventTimers => "0008,2129",
   NumberOfViewsInStage => "0008,212a",
   EventElapsedTimes => "0008,2130",
   EventTimerNames => "0008,2132",
   EventTimerSequence => "0008,2133",
   EventTimeOffset => "0008,2134",
   EventCodeSequence => "0008,2135",
   StartTrim => "0008,2142",
   StopTrim => "0008,2143",
   RecommendedDisplayFrameRate => "0008,2144",
   TransducerPosition => "0008,2200",
   TransducerOrientation => "0008,2204",
   AnatomicStructure => "0008,2208",
   AnatomicRegionSequence => "0008,2218",
   AnatomicRegionModifierSequence => "0008,2220",
   PrimaryAnatomicStructureSequence => "0008,2228",
   AnatomicStructureSpaceOrRegionSequence => "0008,2229",
   PrimaryAnatomicStructureModifierSequence => "0008,2230",
   TransducerPositionSequence => "0008,2240",
   TransducerPositionModifierSequence => "0008,2242",
   TransducerOrientationSequence => "0008,2244",
   TransducerOrientationModifierSequence => "0008,2246",
   AnatomicStructureSpaceOrRegionCodeSequenceTrial => "0008,2251",
   AnatomicPortalOfEntranceCodeSequenceTrial => "0008,2253",
   AnatomicApproachDirectionCodeSequenceTrial => "0008,2255",
   AnatomicPerspectiveDescriptionTrial => "0008,2256",
   AnatomicPerspectiveCodeSequenceTrial => "0008,2257",
   AnatomicLocationOfExaminingInstrumentDescriptionTrial => "0008,2258",
   AnatomicLocationOfExaminingInstrumentCodeSequenceTrial => "0008,2259",
   AnatomicStructureSpaceOrRegionModifierCodeSequenceTrial => "0008,225a",
   OnAxisBackgroundAnatomicStructureCodeSequenceTrial => "0008,225c",
   AlternateRepresentationSequence => "0008,3001",
   IrradiationEventUID => "0008,3010",
   IdentifyingComments => "0008,4000",
   FrameType => "0008,9007",
   ReferencedImageEvidenceSequence => "0008,9092",
   ReferencedRawDataSequence => "0008,9121",
   CreatorVersionUID => "0008,9123",
   DerivationImageSequence => "0008,9124",
   SourceImageEvidenceSequence => "0008,9154",
   PixelPresentation => "0008,9205",
   VolumetricProperties => "0008,9206",
   VolumeBasedCalculationTechnique => "0008,9207",
   ComplexImageComponent => "0008,9208",
   AcquisitionContrast => "0008,9209",
   DerivationCodeSequence => "0008,9215",
   ReferencedPresentationStateSequence => "0008,9237",
   ReferencedOtherPlaneSequence => "0008,9410",
   FrameDisplaySequence => "0008,9458",
   RecommendedDisplayFrameRateInFloat => "0008,9459",
   SkipFrameRangeFlag => "0008,9460",
   PatientName => "0010,0010",
   PatientID => "0010,0020",
   IssuerOfPatientID => "0010,0021",
   TypeOfPatientID => "0010,0022",
   IssuerOfPatientIDQualifiersSequence => "0010,0024",
   PatientBirthDate => "0010,0030",
   PatientBirthTime => "0010,0032",
   PatientSex => "0010,0040",
   PatientInsurancePlanCodeSequence => "0010,0050",
   PatientPrimaryLanguageCodeSequence => "0010,0101",
   PatientPrimaryLanguageModifierCodeSequence => "0010,0102",
   OtherPatientIDs => "0010,1000",
   OtherPatientNames => "0010,1001",
   OtherPatientIDsSequence => "0010,1002",
   PatientBirthName => "0010,1005",
   PatientAge => "0010,1010",
   PatientSize => "0010,1020",
   PatientWeight => "0010,1030",
   PatientAddress => "0010,1040",
   InsurancePlanIdentification => "0010,1050",
   PatientMotherBirthName => "0010,1060",
   MilitaryRank => "0010,1080",
   BranchOfService => "0010,1081",
   MedicalRecordLocator => "0010,1090",
   MedicalAlerts => "0010,2000",
   Allergies => "0010,2110",
   CountryOfResidence => "0010,2150",
   RegionOfResidence => "0010,2152",
   PatientTelephoneNumbers => "0010,2154",
   EthnicGroup => "0010,2160",
   Occupation => "0010,2180",
   SmokingStatus => "0010,21a0",
   AdditionalPatientHistory => "0010,21b0",
   PregnancyStatus => "0010,21c0",
   LastMenstrualDate => "0010,21d0",
   PatientReligiousPreference => "0010,21f0",
   PatientSpeciesDescription => "0010,2201",
   PatientSpeciesCodeSequence => "0010,2202",
   PatientSexNeutered => "0010,2203",
   AnatomicalOrientationType => "0010,2210",
   PatientBreedDescription => "0010,2292",
   PatientBreedCodeSequence => "0010,2293",
   BreedRegistrationSequence => "0010,2294",
   BreedRegistrationNumber => "0010,2295",
   BreedRegistryCodeSequence => "0010,2296",
   ResponsiblePerson => "0010,2297",
   ResponsiblePersonRole => "0010,2298",
   ResponsibleOrganization => "0010,2299",
   PatientComments => "0010,4000",
   ExaminedBodyThickness => "0010,9431",
   ClinicalTrialSponsorName => "0012,0010",
   ClinicalTrialProtocolID => "0012,0020",
   ClinicalTrialProtocolName => "0012,0021",
   ClinicalTrialSiteID => "0012,0030",
   ClinicalTrialSiteName => "0012,0031",
   ClinicalTrialSubjectID => "0012,0040",
   ClinicalTrialSubjectReadingID => "0012,0042",
   ClinicalTrialTimePointID => "0012,0050",
   ClinicalTrialTimePointDescription => "0012,0051",
   ClinicalTrialCoordinatingCenterName => "0012,0060",
   PatientIdentityRemoved => "0012,0062",
   DeidentificationMethod => "0012,0063",
   DeidentificationMethodCodeSequence => "0012,0064",
   ClinicalTrialSeriesID => "0012,0071",
   ClinicalTrialSeriesDescription => "0012,0072",
   ClinicalTrialProtocolEthicsCommitteeName => "0012,0081",
   ClinicalTrialProtocolEthicsCommitteeApprovalNumber => "0012,0082",
   ConsentForClinicalTrialUseSequence => "0012,0083",
   DistributionType => "0012,0084",
   ConsentForDistributionFlag => "0012,0085",
   ContrastBolusAgent => "0018,0010",
   ContrastBolusAgentSequence => "0018,0012",
   ContrastBolusAdministrationRouteSequence => "0018,0014",
   BodyPartExamined => "0018,0015",
   ScanningSequence => "0018,0020",
   SequenceVariant => "0018,0021",
   ScanOptions => "0018,0022",
   MRAcquisitionType => "0018,0023",
   SequenceName => "0018,0024",
   AngioFlag => "0018,0025",
   InterventionDrugInformationSequence => "0018,0026",
   InterventionDrugStopTime => "0018,0027",
   InterventionDrugDose => "0018,0028",
   InterventionDrugCodeSequence => "0018,0029",
   AdditionalDrugSequence => "0018,002a",
   Radionuclide => "0018,0030",
   Radiopharmaceutical => "0018,0031",
   EnergyWindowCenterline => "0018,0032",
   EnergyWindowTotalWidth => "0018,0033",
   InterventionDrugName => "0018,0034",
   InterventionDrugStartTime => "0018,0035",
   InterventionSequence => "0018,0036",
   TherapyType => "0018,0037",
   InterventionStatus => "0018,0038",
   TherapyDescription => "0018,0039",
   InterventionDescription => "0018,003a",
   CineRate => "0018,0040",
   InitialCineRunState => "0018,0042",
   SliceThickness => "0018,0050",
   KVP => "0018,0060",
   CountsAccumulated => "0018,0070",
   AcquisitionTerminationCondition => "0018,0071",
   EffectiveDuration => "0018,0072",
   AcquisitionStartCondition => "0018,0073",
   AcquisitionStartConditionData => "0018,0074",
   AcquisitionTerminationConditionData => "0018,0075",
   RepetitionTime => "0018,0080",
   EchoTime => "0018,0081",
   InversionTime => "0018,0082",
   NumberOfAverages => "0018,0083",
   ImagingFrequency => "0018,0084",
   ImagedNucleus => "0018,0085",
   EchoNumbers => "0018,0086",
   MagneticFieldStrength => "0018,0087",
   SpacingBetweenSlices => "0018,0088",
   NumberOfPhaseEncodingSteps => "0018,0089",
   DataCollectionDiameter => "0018,0090",
   EchoTrainLength => "0018,0091",
   PercentSampling => "0018,0093",
   PercentPhaseFieldOfView => "0018,0094",
   PixelBandwidth => "0018,0095",
   DeviceSerialNumber => "0018,1000",
   DeviceUID => "0018,1002",
   DeviceID => "0018,1003",
   PlateID => "0018,1004",
   GeneratorID => "0018,1005",
   GridID => "0018,1006",
   CassetteID => "0018,1007",
   GantryID => "0018,1008",
   SecondaryCaptureDeviceID => "0018,1010",
   HardcopyCreationDeviceID => "0018,1011",
   DateOfSecondaryCapture => "0018,1012",
   TimeOfSecondaryCapture => "0018,1014",
   SecondaryCaptureDeviceManufacturer => "0018,1016",
   HardcopyDeviceManufacturer => "0018,1017",
   SecondaryCaptureDeviceManufacturerModelName => "0018,1018",
   SecondaryCaptureDeviceSoftwareVersions => "0018,1019",
   HardcopyDeviceSoftwareVersion => "0018,101a",
   HardcopyDeviceManufacturerModelName => "0018,101b",
   SoftwareVersions => "0018,1020",
   VideoImageFormatAcquired => "0018,1022",
   DigitalImageFormatAcquired => "0018,1023",
   ProtocolName => "0018,1030",
   ContrastBolusRoute => "0018,1040",
   ContrastBolusVolume => "0018,1041",
   ContrastBolusStartTime => "0018,1042",
   ContrastBolusStopTime => "0018,1043",
   ContrastBolusTotalDose => "0018,1044",
   SyringeCounts => "0018,1045",
   ContrastFlowRate => "0018,1046",
   ContrastFlowDuration => "0018,1047",
   ContrastBolusIngredient => "0018,1048",
   ContrastBolusIngredientConcentration => "0018,1049",
   SpatialResolution => "0018,1050",
   TriggerTime => "0018,1060",
   TriggerSourceOrType => "0018,1061",
   NominalInterval => "0018,1062",
   FrameTime => "0018,1063",
   CardiacFramingType => "0018,1064",
   FrameTimeVector => "0018,1065",
   FrameDelay => "0018,1066",
   ImageTriggerDelay => "0018,1067",
   MultiplexGroupTimeOffset => "0018,1068",
   TriggerTimeOffset => "0018,1069",
   SynchronizationTrigger => "0018,106a",
   SynchronizationChannel => "0018,106c",
   TriggerSamplePosition => "0018,106e",
   RadiopharmaceuticalRoute => "0018,1070",
   RadiopharmaceuticalVolume => "0018,1071",
   RadiopharmaceuticalStartTime => "0018,1072",
   RadiopharmaceuticalStopTime => "0018,1073",
   RadionuclideTotalDose => "0018,1074",
   RadionuclideHalfLife => "0018,1075",
   RadionuclidePositronFraction => "0018,1076",
   RadiopharmaceuticalSpecificActivity => "0018,1077",
   RadiopharmaceuticalStartDateTime => "0018,1078",
   RadiopharmaceuticalStopDateTime => "0018,1079",
   BeatRejectionFlag => "0018,1080",
   LowRRValue => "0018,1081",
   HighRRValue => "0018,1082",
   IntervalsAcquired => "0018,1083",
   IntervalsRejected => "0018,1084",
   PVCRejection => "0018,1085",
   SkipBeats => "0018,1086",
   HeartRate => "0018,1088",
   CardiacNumberOfImages => "0018,1090",
   TriggerWindow => "0018,1094",
   ReconstructionDiameter => "0018,1100",
   DistanceSourceToDetector => "0018,1110",
   DistanceSourceToPatient => "0018,1111",
   EstimatedRadiographicMagnificationFactor => "0018,1114",
   GantryDetectorTilt => "0018,1120",
   GantryDetectorSlew => "0018,1121",
   TableHeight => "0018,1130",
   TableTraverse => "0018,1131",
   TableMotion => "0018,1134",
   TableVerticalIncrement => "0018,1135",
   TableLateralIncrement => "0018,1136",
   TableLongitudinalIncrement => "0018,1137",
   TableAngle => "0018,1138",
   TableType => "0018,113a",
   RotationDirection => "0018,1140",
   AngularPosition => "0018,1141",
   RadialPosition => "0018,1142",
   ScanArc => "0018,1143",
   AngularStep => "0018,1144",
   CenterOfRotationOffset => "0018,1145",
   RotationOffset => "0018,1146",
   FieldOfViewShape => "0018,1147",
   FieldOfViewDimensions => "0018,1149",
   ExposureTime => "0018,1150",
   XRayTubeCurrent => "0018,1151",
   Exposure => "0018,1152",
   ExposureInuAs => "0018,1153",
   AveragePulseWidth => "0018,1154",
   RadiationSetting => "0018,1155",
   RectificationType => "0018,1156",
   RadiationMode => "0018,115a",
   ImageAndFluoroscopyAreaDoseProduct => "0018,115e",
   FilterType => "0018,1160",
   TypeOfFilters => "0018,1161",
   IntensifierSize => "0018,1162",
   ImagerPixelSpacing => "0018,1164",
   Grid => "0018,1166",
   GeneratorPower => "0018,1170",
   CollimatorGridName => "0018,1180",
   CollimatorType => "0018,1181",
   FocalDistance => "0018,1182",
   XFocusCenter => "0018,1183",
   YFocusCenter => "0018,1184",
   FocalSpots => "0018,1190",
   AnodeTargetMaterial => "0018,1191",
   BodyPartThickness => "0018,11a0",
   CompressionForce => "0018,11a2",
   DateOfLastCalibration => "0018,1200",
   TimeOfLastCalibration => "0018,1201",
   ConvolutionKernel => "0018,1210",
   UpperLowerPixelValues => "0018,1240",
   ActualFrameDuration => "0018,1242",
   CountRate => "0018,1243",
   PreferredPlaybackSequencing => "0018,1244",
   ReceiveCoilName => "0018,1250",
   TransmitCoilName => "0018,1251",
   PlateType => "0018,1260",
   PhosphorType => "0018,1261",
   ScanVelocity => "0018,1300",
   WholeBodyTechnique => "0018,1301",
   ScanLength => "0018,1302",
   AcquisitionMatrix => "0018,1310",
   InPlanePhaseEncodingDirection => "0018,1312",
   FlipAngle => "0018,1314",
   VariableFlipAngleFlag => "0018,1315",
   SAR => "0018,1316",
   dBdt => "0018,1318",
   AcquisitionDeviceProcessingDescription => "0018,1400",
   AcquisitionDeviceProcessingCode => "0018,1401",
   CassetteOrientation => "0018,1402",
   CassetteSize => "0018,1403",
   ExposuresOnPlate => "0018,1404",
   RelativeXRayExposure => "0018,1405",
   ColumnAngulation => "0018,1450",
   TomoLayerHeight => "0018,1460",
   TomoAngle => "0018,1470",
   TomoTime => "0018,1480",
   TomoType => "0018,1490",
   TomoClass => "0018,1491",
   NumberOfTomosynthesisSourceImages => "0018,1495",
   PositionerMotion => "0018,1500",
   PositionerType => "0018,1508",
   PositionerPrimaryAngle => "0018,1510",
   PositionerSecondaryAngle => "0018,1511",
   PositionerPrimaryAngleIncrement => "0018,1520",
   PositionerSecondaryAngleIncrement => "0018,1521",
   DetectorPrimaryAngle => "0018,1530",
   DetectorSecondaryAngle => "0018,1531",
   ShutterShape => "0018,1600",
   ShutterLeftVerticalEdge => "0018,1602",
   ShutterRightVerticalEdge => "0018,1604",
   ShutterUpperHorizontalEdge => "0018,1606",
   ShutterLowerHorizontalEdge => "0018,1608",
   CenterOfCircularShutter => "0018,1610",
   RadiusOfCircularShutter => "0018,1612",
   VerticesOfThePolygonalShutter => "0018,1620",
   ShutterPresentationValue => "0018,1622",
   ShutterOverlayGroup => "0018,1623",
   ShutterPresentationColorCIELabValue => "0018,1624",
   CollimatorShape => "0018,1700",
   CollimatorLeftVerticalEdge => "0018,1702",
   CollimatorRightVerticalEdge => "0018,1704",
   CollimatorUpperHorizontalEdge => "0018,1706",
   CollimatorLowerHorizontalEdge => "0018,1708",
   CenterOfCircularCollimator => "0018,1710",
   RadiusOfCircularCollimator => "0018,1712",
   VerticesOfThePolygonalCollimator => "0018,1720",
   AcquisitionTimeSynchronized => "0018,1800",
   TimeSource => "0018,1801",
   TimeDistributionProtocol => "0018,1802",
   NTPSourceAddress => "0018,1803",
   PageNumberVector => "0018,2001",
   FrameLabelVector => "0018,2002",
   FramePrimaryAngleVector => "0018,2003",
   FrameSecondaryAngleVector => "0018,2004",
   SliceLocationVector => "0018,2005",
   DisplayWindowLabelVector => "0018,2006",
   NominalScannedPixelSpacing => "0018,2010",
   DigitizingDeviceTransportDirection => "0018,2020",
   RotationOfScannedFilm => "0018,2030",
   IVUSAcquisition => "0018,3100",
   IVUSPullbackRate => "0018,3101",
   IVUSGatedRate => "0018,3102",
   IVUSPullbackStartFrameNumber => "0018,3103",
   IVUSPullbackStopFrameNumber => "0018,3104",
   LesionNumber => "0018,3105",
   AcquisitionComments => "0018,4000",
   OutputPower => "0018,5000",
   TransducerData => "0018,5010",
   FocusDepth => "0018,5012",
   ProcessingFunction => "0018,5020",
   PostprocessingFunction => "0018,5021",
   MechanicalIndex => "0018,5022",
   BoneThermalIndex => "0018,5024",
   CranialThermalIndex => "0018,5026",
   SoftTissueThermalIndex => "0018,5027",
   SoftTissueFocusThermalIndex => "0018,5028",
   SoftTissueSurfaceThermalIndex => "0018,5029",
   DynamicRange => "0018,5030",
   TotalGain => "0018,5040",
   DepthOfScanField => "0018,5050",
   PatientPosition => "0018,5100",
   ViewPosition => "0018,5101",
   ProjectionEponymousNameCodeSequence => "0018,5104",
   ImageTransformationMatrix => "0018,5210",
   ImageTranslationVector => "0018,5212",
   Sensitivity => "0018,6000",
   SequenceOfUltrasoundRegions => "0018,6011",
   RegionSpatialFormat => "0018,6012",
   RegionDataType => "0018,6014",
   RegionFlags => "0018,6016",
   RegionLocationMinX0 => "0018,6018",
   RegionLocationMinY0 => "0018,601a",
   RegionLocationMaxX1 => "0018,601c",
   RegionLocationMaxY1 => "0018,601e",
   ReferencePixelX0 => "0018,6020",
   ReferencePixelY0 => "0018,6022",
   PhysicalUnitsXDirection => "0018,6024",
   PhysicalUnitsYDirection => "0018,6026",
   ReferencePixelPhysicalValueX => "0018,6028",
   ReferencePixelPhysicalValueY => "0018,602a",
   PhysicalDeltaX => "0018,602c",
   PhysicalDeltaY => "0018,602e",
   TransducerFrequency => "0018,6030",
   TransducerType => "0018,6031",
   PulseRepetitionFrequency => "0018,6032",
   DopplerCorrectionAngle => "0018,6034",
   SteeringAngle => "0018,6036",
   DopplerSampleVolumeXPositionRetired => "0018,6038",
   DopplerSampleVolumeXPosition => "0018,6039",
   DopplerSampleVolumeYPositionRetired => "0018,603a",
   DopplerSampleVolumeYPosition => "0018,603b",
   TMLinePositionX0Retired => "0018,603c",
   TMLinePositionX0 => "0018,603d",
   TMLinePositionY0Retired => "0018,603e",
   TMLinePositionY0 => "0018,603f",
   TMLinePositionX1Retired => "0018,6040",
   TMLinePositionX1 => "0018,6041",
   TMLinePositionY1Retired => "0018,6042",
   TMLinePositionY1 => "0018,6043",
   PixelComponentOrganization => "0018,6044",
   PixelComponentMask => "0018,6046",
   PixelComponentRangeStart => "0018,6048",
   PixelComponentRangeStop => "0018,604a",
   PixelComponentPhysicalUnits => "0018,604c",
   PixelComponentDataType => "0018,604e",
   NumberOfTableBreakPoints => "0018,6050",
   TableOfXBreakPoints => "0018,6052",
   TableOfYBreakPoints => "0018,6054",
   NumberOfTableEntries => "0018,6056",
   TableOfPixelValues => "0018,6058",
   TableOfParameterValues => "0018,605a",
   RWaveTimeVector => "0018,6060",
   DetectorConditionsNominalFlag => "0018,7000",
   DetectorTemperature => "0018,7001",
   DetectorType => "0018,7004",
   DetectorConfiguration => "0018,7005",
   DetectorDescription => "0018,7006",
   DetectorMode => "0018,7008",
   DetectorID => "0018,700a",
   DateOfLastDetectorCalibration => "0018,700c",
   TimeOfLastDetectorCalibration => "0018,700e",
   ExposuresOnDetectorSinceLastCalibration => "0018,7010",
   ExposuresOnDetectorSinceManufactured => "0018,7011",
   DetectorTimeSinceLastExposure => "0018,7012",
   DetectorActiveTime => "0018,7014",
   DetectorActivationOffsetFromExposure => "0018,7016",
   DetectorBinning => "0018,701a",
   DetectorElementPhysicalSize => "0018,7020",
   DetectorElementSpacing => "0018,7022",
   DetectorActiveShape => "0018,7024",
   DetectorActiveDimensions => "0018,7026",
   DetectorActiveOrigin => "0018,7028",
   DetectorManufacturerName => "0018,702a",
   DetectorManufacturerModelName => "0018,702b",
   FieldOfViewOrigin => "0018,7030",
   FieldOfViewRotation => "0018,7032",
   FieldOfViewHorizontalFlip => "0018,7034",
   GridAbsorbingMaterial => "0018,7040",
   GridSpacingMaterial => "0018,7041",
   GridThickness => "0018,7042",
   GridPitch => "0018,7044",
   GridAspectRatio => "0018,7046",
   GridPeriod => "0018,7048",
   GridFocalDistance => "0018,704c",
   FilterMaterial => "0018,7050",
   FilterThicknessMinimum => "0018,7052",
   FilterThicknessMaximum => "0018,7054",
   FilterBeamPathLengthMinimum => "0018,7056",
   FilterBeamPathLengthMaximum => "0018,7058",
   ExposureControlMode => "0018,7060",
   ExposureControlModeDescription => "0018,7062",
   ExposureStatus => "0018,7064",
   PhototimerSetting => "0018,7065",
   ExposureTimeInuS => "0018,8150",
   XRayTubeCurrentInuA => "0018,8151",
   ContentQualification => "0018,9004",
   PulseSequenceName => "0018,9005",
   MRImagingModifierSequence => "0018,9006",
   EchoPulseSequence => "0018,9008",
   InversionRecovery => "0018,9009",
   FlowCompensation => "0018,9010",
   MultipleSpinEcho => "0018,9011",
   MultiPlanarExcitation => "0018,9012",
   PhaseContrast => "0018,9014",
   TimeOfFlightContrast => "0018,9015",
   Spoiling => "0018,9016",
   SteadyStatePulseSequence => "0018,9017",
   EchoPlanarPulseSequence => "0018,9018",
   TagAngleFirstAxis => "0018,9019",
   MagnetizationTransfer => "0018,9020",
   T2Preparation => "0018,9021",
   BloodSignalNulling => "0018,9022",
   SaturationRecovery => "0018,9024",
   SpectrallySelectedSuppression => "0018,9025",
   SpectrallySelectedExcitation => "0018,9026",
   SpatialPresaturation => "0018,9027",
   Tagging => "0018,9028",
   OversamplingPhase => "0018,9029",
   TagSpacingFirstDimension => "0018,9030",
   GeometryOfKSpaceTraversal => "0018,9032",
   SegmentedKSpaceTraversal => "0018,9033",
   RectilinearPhaseEncodeReordering => "0018,9034",
   TagThickness => "0018,9035",
   PartialFourierDirection => "0018,9036",
   CardiacSynchronizationTechnique => "0018,9037",
   ReceiveCoilManufacturerName => "0018,9041",
   MRReceiveCoilSequence => "0018,9042",
   ReceiveCoilType => "0018,9043",
   QuadratureReceiveCoil => "0018,9044",
   MultiCoilDefinitionSequence => "0018,9045",
   MultiCoilConfiguration => "0018,9046",
   MultiCoilElementName => "0018,9047",
   MultiCoilElementUsed => "0018,9048",
   MRTransmitCoilSequence => "0018,9049",
   TransmitCoilManufacturerName => "0018,9050",
   TransmitCoilType => "0018,9051",
   SpectralWidth => "0018,9052",
   ChemicalShiftReference => "0018,9053",
   VolumeLocalizationTechnique => "0018,9054",
   MRAcquisitionFrequencyEncodingSteps => "0018,9058",
   Decoupling => "0018,9059",
   DecoupledNucleus => "0018,9060",
   DecouplingFrequency => "0018,9061",
   DecouplingMethod => "0018,9062",
   DecouplingChemicalShiftReference => "0018,9063",
   KSpaceFiltering => "0018,9064",
   TimeDomainFiltering => "0018,9065",
   NumberOfZeroFills => "0018,9066",
   BaselineCorrection => "0018,9067",
   ParallelReductionFactorInPlane => "0018,9069",
   CardiacRRIntervalSpecified => "0018,9070",
   AcquisitionDuration => "0018,9073",
   FrameAcquisitionDateTime => "0018,9074",
   DiffusionDirectionality => "0018,9075",
   DiffusionGradientDirectionSequence => "0018,9076",
   ParallelAcquisition => "0018,9077",
   ParallelAcquisitionTechnique => "0018,9078",
   InversionTimes => "0018,9079",
   MetaboliteMapDescription => "0018,9080",
   PartialFourier => "0018,9081",
   EffectiveEchoTime => "0018,9082",
   MetaboliteMapCodeSequence => "0018,9083",
   ChemicalShiftSequence => "0018,9084",
   CardiacSignalSource => "0018,9085",
   DiffusionBValue => "0018,9087",
   DiffusionGradientOrientation => "0018,9089",
   VelocityEncodingDirection => "0018,9090",
   VelocityEncodingMinimumValue => "0018,9091",
   NumberOfKSpaceTrajectories => "0018,9093",
   CoverageOfKSpace => "0018,9094",
   SpectroscopyAcquisitionPhaseRows => "0018,9095",
   ParallelReductionFactorInPlaneRetired => "0018,9096",
   TransmitterFrequency => "0018,9098",
   ResonantNucleus => "0018,9100",
   FrequencyCorrection => "0018,9101",
   MRSpectroscopyFOVGeometrySequence => "0018,9103",
   SlabThickness => "0018,9104",
   SlabOrientation => "0018,9105",
   MidSlabPosition => "0018,9106",
   MRSpatialSaturationSequence => "0018,9107",
   MRTimingAndRelatedParametersSequence => "0018,9112",
   MREchoSequence => "0018,9114",
   MRModifierSequence => "0018,9115",
   MRDiffusionSequence => "0018,9117",
   CardiacSynchronizationSequence => "0018,9118",
   MRAveragesSequence => "0018,9119",
   MRFOVGeometrySequence => "0018,9125",
   VolumeLocalizationSequence => "0018,9126",
   SpectroscopyAcquisitionDataColumns => "0018,9127",
   DiffusionAnisotropyType => "0018,9147",
   FrameReferenceDateTime => "0018,9151",
   MRMetaboliteMapSequence => "0018,9152",
   ParallelReductionFactorOutOfPlane => "0018,9155",
   SpectroscopyAcquisitionOutOfPlanePhaseSteps => "0018,9159",
   BulkMotionStatus => "0018,9166",
   ParallelReductionFactorSecondInPlane => "0018,9168",
   CardiacBeatRejectionTechnique => "0018,9169",
   RespiratoryMotionCompensationTechnique => "0018,9170",
   RespiratorySignalSource => "0018,9171",
   BulkMotionCompensationTechnique => "0018,9172",
   BulkMotionSignalSource => "0018,9173",
   ApplicableSafetyStandardAgency => "0018,9174",
   ApplicableSafetyStandardDescription => "0018,9175",
   OperatingModeSequence => "0018,9176",
   OperatingModeType => "0018,9177",
   OperatingMode => "0018,9178",
   SpecificAbsorptionRateDefinition => "0018,9179",
   GradientOutputType => "0018,9180",
   SpecificAbsorptionRateValue => "0018,9181",
   GradientOutput => "0018,9182",
   FlowCompensationDirection => "0018,9183",
   TaggingDelay => "0018,9184",
   RespiratoryMotionCompensationTechniqueDescription => "0018,9185",
   RespiratorySignalSourceID => "0018,9186",
   ChemicalShiftMinimumIntegrationLimitInHz => "0018,9195",
   ChemicalShiftMaximumIntegrationLimitInHz => "0018,9196",
   MRVelocityEncodingSequence => "0018,9197",
   FirstOrderPhaseCorrection => "0018,9198",
   WaterReferencedPhaseCorrection => "0018,9199",
   MRSpectroscopyAcquisitionType => "0018,9200",
   RespiratoryCyclePosition => "0018,9214",
   VelocityEncodingMaximumValue => "0018,9217",
   TagSpacingSecondDimension => "0018,9218",
   TagAngleSecondAxis => "0018,9219",
   FrameAcquisitionDuration => "0018,9220",
   MRImageFrameTypeSequence => "0018,9226",
   MRSpectroscopyFrameTypeSequence => "0018,9227",
   MRAcquisitionPhaseEncodingStepsInPlane => "0018,9231",
   MRAcquisitionPhaseEncodingStepsOutOfPlane => "0018,9232",
   SpectroscopyAcquisitionPhaseColumns => "0018,9234",
   CardiacCyclePosition => "0018,9236",
   SpecificAbsorptionRateSequence => "0018,9239",
   RFEchoTrainLength => "0018,9240",
   GradientEchoTrainLength => "0018,9241",
   ChemicalShiftMinimumIntegrationLimitInppm => "0018,9295",
   ChemicalShiftMaximumIntegrationLimitInppm => "0018,9296",
   CTAcquisitionTypeSequence => "0018,9301",
   AcquisitionType => "0018,9302",
   TubeAngle => "0018,9303",
   CTAcquisitionDetailsSequence => "0018,9304",
   RevolutionTime => "0018,9305",
   SingleCollimationWidth => "0018,9306",
   TotalCollimationWidth => "0018,9307",
   CTTableDynamicsSequence => "0018,9308",
   TableSpeed => "0018,9309",
   TableFeedPerRotation => "0018,9310",
   SpiralPitchFactor => "0018,9311",
   CTGeometrySequence => "0018,9312",
   DataCollectionCenterPatient => "0018,9313",
   CTReconstructionSequence => "0018,9314",
   ReconstructionAlgorithm => "0018,9315",
   ConvolutionKernelGroup => "0018,9316",
   ReconstructionFieldOfView => "0018,9317",
   ReconstructionTargetCenterPatient => "0018,9318",
   ReconstructionAngle => "0018,9319",
   ImageFilter => "0018,9320",
   CTExposureSequence => "0018,9321",
   ReconstructionPixelSpacing => "0018,9322",
   ExposureModulationType => "0018,9323",
   EstimatedDoseSaving => "0018,9324",
   CTXRayDetailsSequence => "0018,9325",
   CTPositionSequence => "0018,9326",
   TablePosition => "0018,9327",
   ExposureTimeInms => "0018,9328",
   CTImageFrameTypeSequence => "0018,9329",
   XRayTubeCurrentInmA => "0018,9330",
   ExposureInmAs => "0018,9332",
   ConstantVolumeFlag => "0018,9333",
   FluoroscopyFlag => "0018,9334",
   DistanceSourceToDataCollectionCenter => "0018,9335",
   ContrastBolusAgentNumber => "0018,9337",
   ContrastBolusIngredientCodeSequence => "0018,9338",
   ContrastAdministrationProfileSequence => "0018,9340",
   ContrastBolusUsageSequence => "0018,9341",
   ContrastBolusAgentAdministered => "0018,9342",
   ContrastBolusAgentDetected => "0018,9343",
   ContrastBolusAgentPhase => "0018,9344",
   CTDIvol => "0018,9345",
   CTDIPhantomTypeCodeSequence => "0018,9346",
   CalciumScoringMassFactorPatient => "0018,9351",
   CalciumScoringMassFactorDevice => "0018,9352",
   EnergyWeightingFactor => "0018,9353",
   CTAdditionalXRaySourceSequence => "0018,9360",
   ProjectionPixelCalibrationSequence => "0018,9401",
   DistanceSourceToIsocenter => "0018,9402",
   DistanceObjectToTableTop => "0018,9403",
   ObjectPixelSpacingInCenterOfBeam => "0018,9404",
   PositionerPositionSequence => "0018,9405",
   TablePositionSequence => "0018,9406",
   CollimatorShapeSequence => "0018,9407",
   XAXRFFrameCharacteristicsSequence => "0018,9412",
   FrameAcquisitionSequence => "0018,9417",
   XRayReceptorType => "0018,9420",
   AcquisitionProtocolName => "0018,9423",
   AcquisitionProtocolDescription => "0018,9424",
   ContrastBolusIngredientOpaque => "0018,9425",
   DistanceReceptorPlaneToDetectorHousing => "0018,9426",
   IntensifierActiveShape => "0018,9427",
   IntensifierActiveDimensions => "0018,9428",
   PhysicalDetectorSize => "0018,9429",
   PositionOfIsocenterProjection => "0018,9430",
   FieldOfViewSequence => "0018,9432",
   FieldOfViewDescription => "0018,9433",
   ExposureControlSensingRegionsSequence => "0018,9434",
   ExposureControlSensingRegionShape => "0018,9435",
   ExposureControlSensingRegionLeftVerticalEdge => "0018,9436",
   ExposureControlSensingRegionRightVerticalEdge => "0018,9437",
   ExposureControlSensingRegionUpperHorizontalEdge => "0018,9438",
   ExposureControlSensingRegionLowerHorizontalEdge => "0018,9439",
   CenterOfCircularExposureControlSensingRegion => "0018,9440",
   RadiusOfCircularExposureControlSensingRegion => "0018,9441",
   VerticesOfThePolygonalExposureControlSensingRegion => "0018,9442",
   ColumnAngulationPatient => "0018,9447",
   BeamAngle => "0018,9449",
   FrameDetectorParametersSequence => "0018,9451",
   CalculatedAnatomyThickness => "0018,9452",
   CalibrationSequence => "0018,9455",
   ObjectThicknessSequence => "0018,9456",
   PlaneIdentification => "0018,9457",
   FieldOfViewDimensionsInFloat => "0018,9461",
   IsocenterReferenceSystemSequence => "0018,9462",
   PositionerIsocenterPrimaryAngle => "0018,9463",
   PositionerIsocenterSecondaryAngle => "0018,9464",
   PositionerIsocenterDetectorRotationAngle => "0018,9465",
   TableXPositionToIsocenter => "0018,9466",
   TableYPositionToIsocenter => "0018,9467",
   TableZPositionToIsocenter => "0018,9468",
   TableHorizontalRotationAngle => "0018,9469",
   TableHeadTiltAngle => "0018,9470",
   TableCradleTiltAngle => "0018,9471",
   FrameDisplayShutterSequence => "0018,9472",
   AcquiredImageAreaDoseProduct => "0018,9473",
   CArmPositionerTabletopRelationship => "0018,9474",
   XRayGeometrySequence => "0018,9476",
   IrradiationEventIdentificationSequence => "0018,9477",
   XRay3DFrameTypeSequence => "0018,9504",
   ContributingSourcesSequence => "0018,9506",
   XRay3DAcquisitionSequence => "0018,9507",
   PrimaryPositionerScanArc => "0018,9508",
   SecondaryPositionerScanArc => "0018,9509",
   PrimaryPositionerScanStartAngle => "0018,9510",
   SecondaryPositionerScanStartAngle => "0018,9511",
   PrimaryPositionerIncrement => "0018,9514",
   SecondaryPositionerIncrement => "0018,9515",
   StartAcquisitionDateTime => "0018,9516",
   EndAcquisitionDateTime => "0018,9517",
   ApplicationName => "0018,9524",
   ApplicationVersion => "0018,9525",
   ApplicationManufacturer => "0018,9526",
   AlgorithmType => "0018,9527",
   AlgorithmDescription => "0018,9528",
   XRay3DReconstructionSequence => "0018,9530",
   ReconstructionDescription => "0018,9531",
   PerProjectionAcquisitionSequence => "0018,9538",
   DiffusionBMatrixSequence => "0018,9601",
   DiffusionBValueXX => "0018,9602",
   DiffusionBValueXY => "0018,9603",
   DiffusionBValueXZ => "0018,9604",
   DiffusionBValueYY => "0018,9605",
   DiffusionBValueYZ => "0018,9606",
   DiffusionBValueZZ => "0018,9607",
   DecayCorrectionDateTime => "0018,9701",
   StartDensityThreshold => "0018,9715",
   StartRelativeDensityDifferenceThreshold => "0018,9716",
   StartCardiacTriggerCountThreshold => "0018,9717",
   StartRespiratoryTriggerCountThreshold => "0018,9718",
   TerminationCountsThreshold => "0018,9719",
   TerminationDensityThreshold => "0018,9720",
   TerminationRelativeDensityThreshold => "0018,9721",
   TerminationTimeThreshold => "0018,9722",
   TerminationCardiacTriggerCountThreshold => "0018,9723",
   TerminationRespiratoryTriggerCountThreshold => "0018,9724",
   DetectorGeometry => "0018,9725",
   TransverseDetectorSeparation => "0018,9726",
   AxialDetectorDimension => "0018,9727",
   RadiopharmaceuticalAgentNumber => "0018,9729",
   PETFrameAcquisitionSequence => "0018,9732",
   PETDetectorMotionDetailsSequence => "0018,9733",
   PETTableDynamicsSequence => "0018,9734",
   PETPositionSequence => "0018,9735",
   PETFrameCorrectionFactorsSequence => "0018,9736",
   RadiopharmaceuticalUsageSequence => "0018,9737",
   AttenuationCorrectionSource => "0018,9738",
   NumberOfIterations => "0018,9739",
   NumberOfSubsets => "0018,9740",
   PETReconstructionSequence => "0018,9749",
   PETFrameTypeSequence => "0018,9751",
   TimeOfFlightInformationUsed => "0018,9755",
   ReconstructionType => "0018,9756",
   DecayCorrected => "0018,9758",
   AttenuationCorrected => "0018,9759",
   ScatterCorrected => "0018,9760",
   DeadTimeCorrected => "0018,9761",
   GantryMotionCorrected => "0018,9762",
   PatientMotionCorrected => "0018,9763",
   CountLossNormalizationCorrected => "0018,9764",
   RandomsCorrected => "0018,9765",
   NonUniformRadialSamplingCorrected => "0018,9766",
   SensitivityCalibrated => "0018,9767",
   DetectorNormalizationCorrection => "0018,9768",
   IterativeReconstructionMethod => "0018,9769",
   AttenuationCorrectionTemporalRelationship => "0018,9770",
   PatientPhysiologicalStateSequence => "0018,9771",
   PatientPhysiologicalStateCodeSequence => "0018,9772",
   DepthsOfFocus => "0018,9801",
   ExcludedIntervalsSequence => "0018,9803",
   ExclusionStartDatetime => "0018,9804",
   ExclusionDuration => "0018,9805",
   USImageDescriptionSequence => "0018,9806",
   ImageDataTypeSequence => "0018,9807",
   DataType => "0018,9808",
   TransducerScanPatternCodeSequence => "0018,9809",
   AliasedDataType => "0018,980b",
   PositionMeasuringDeviceUsed => "0018,980c",
   TransducerGeometryCodeSequence => "0018,980d",
   TransducerBeamSteeringCodeSequence => "0018,980e",
   TransducerApplicationCodeSequence => "0018,980f",
   ContributingEquipmentSequence => "0018,a001",
   ContributionDateTime => "0018,a002",
   ContributionDescription => "0018,a003",
   StudyInstanceUID => "0020,000d",
   SeriesInstanceUID => "0020,000e",
   StudyID => "0020,0010",
   SeriesNumber => "0020,0011",
   AcquisitionNumber => "0020,0012",
   InstanceNumber => "0020,0013",
   IsotopeNumber => "0020,0014",
   PhaseNumber => "0020,0015",
   IntervalNumber => "0020,0016",
   TimeSlotNumber => "0020,0017",
   AngleNumber => "0020,0018",
   ItemNumber => "0020,0019",
   PatientOrientation => "0020,0020",
   OverlayNumber => "0020,0022",
   CurveNumber => "0020,0024",
   LUTNumber => "0020,0026",
   ImagePosition => "0020,0030",
   ImagePositionPatient => "0020,0032",
   ImageOrientation => "0020,0035",
   ImageOrientationPatient => "0020,0037",
   Location => "0020,0050",
   FrameOfReferenceUID => "0020,0052",
   Laterality => "0020,0060",
   ImageLaterality => "0020,0062",
   ImageGeometryType => "0020,0070",
   MaskingImage => "0020,0080",
   TemporalPositionIdentifier => "0020,0100",
   NumberOfTemporalPositions => "0020,0105",
   TemporalResolution => "0020,0110",
   SynchronizationFrameOfReferenceUID => "0020,0200",
   SOPInstanceUIDOfConcatenationSource => "0020,0242",
   SeriesInStudy => "0020,1000",
   AcquisitionsInSeries => "0020,1001",
   ImagesInAcquisition => "0020,1002",
   ImagesInSeries => "0020,1003",
   AcquisitionsInStudy => "0020,1004",
   ImagesInStudy => "0020,1005",
   Reference => "0020,1020",
   PositionReferenceIndicator => "0020,1040",
   SliceLocation => "0020,1041",
   OtherStudyNumbers => "0020,1070",
   NumberOfPatientRelatedStudies => "0020,1200",
   NumberOfPatientRelatedSeries => "0020,1202",
   NumberOfPatientRelatedInstances => "0020,1204",
   NumberOfStudyRelatedSeries => "0020,1206",
   NumberOfStudyRelatedInstances => "0020,1208",
   NumberOfSeriesRelatedInstances => "0020,1209",
   SourceImageIDs => "0020,31xx",
   ModifyingDeviceID => "0020,3401",
   ModifiedImageID => "0020,3402",
   ModifiedImageDate => "0020,3403",
   ModifyingDeviceManufacturer => "0020,3404",
   ModifiedImageTime => "0020,3405",
   ModifiedImageDescription => "0020,3406",
   ImageComments => "0020,4000",
   OriginalImageIdentification => "0020,5000",
   OriginalImageIdentificationNomenclature => "0020,5002",
   StackID => "0020,9056",
   InStackPositionNumber => "0020,9057",
   FrameAnatomySequence => "0020,9071",
   FrameLaterality => "0020,9072",
   FrameContentSequence => "0020,9111",
   PlanePositionSequence => "0020,9113",
   PlaneOrientationSequence => "0020,9116",
   TemporalPositionIndex => "0020,9128",
   NominalCardiacTriggerDelayTime => "0020,9153",
   FrameAcquisitionNumber => "0020,9156",
   DimensionIndexValues => "0020,9157",
   FrameComments => "0020,9158",
   ConcatenationUID => "0020,9161",
   InConcatenationNumber => "0020,9162",
   InConcatenationTotalNumber => "0020,9163",
   DimensionOrganizationUID => "0020,9164",
   DimensionIndexPointer => "0020,9165",
   FunctionalGroupPointer => "0020,9167",
   DimensionIndexPrivateCreator => "0020,9213",
   DimensionOrganizationSequence => "0020,9221",
   DimensionIndexSequence => "0020,9222",
   ConcatenationFrameOffsetNumber => "0020,9228",
   FunctionalGroupPrivateCreator => "0020,9238",
   NominalPercentageOfCardiacPhase => "0020,9241",
   NominalPercentageOfRespiratoryPhase => "0020,9245",
   StartingRespiratoryAmplitude => "0020,9246",
   StartingRespiratoryPhase => "0020,9247",
   EndingRespiratoryAmplitude => "0020,9248",
   EndingRespiratoryPhase => "0020,9249",
   RespiratoryTriggerType => "0020,9250",
   RRIntervalTimeNominal => "0020,9251",
   ActualCardiacTriggerDelayTime => "0020,9252",
   RespiratorySynchronizationSequence => "0020,9253",
   RespiratoryIntervalTime => "0020,9254",
   NominalRespiratoryTriggerDelayTime => "0020,9255",
   RespiratoryTriggerDelayThreshold => "0020,9256",
   ActualRespiratoryTriggerDelayTime => "0020,9257",
   ImagePositionVolume => "0020,9301",
   ImageOrientationVolume => "0020,9302",
   UltrasoundAcquisitionGeometry => "0020,9307",
   ApexPosition => "0020,9308",
   VolumeToTransducerMappingMatrix => "0020,9309",
   VolumeToTableMappingMatrix => "0020,930a",
   PatientFrameOfReferenceSource => "0020,930c",
   TemporalPositionTimeOffset => "0020,930d",
   PlanePositionVolumeSequence => "0020,930e",
   PlaneOrientationVolumeSequence => "0020,930f",
   TemporalPositionSequence => "0020,9310",
   DimensionOrganizationType => "0020,9311",
   VolumeFrameOfReferenceUID => "0020,9312",
   TableFrameOfReferenceUID => "0020,9313",
   DimensionDescriptionLabel => "0020,9421",
   PatientOrientationInFrameSequence => "0020,9450",
   FrameLabel => "0020,9453",
   AcquisitionIndex => "0020,9518",
   ContributingSOPInstancesReferenceSequence => "0020,9529",
   ReconstructionIndex => "0020,9536",
   LightPathFilterPassThroughWavelength => "0022,0001",
   LightPathFilterPassBand => "0022,0002",
   ImagePathFilterPassThroughWavelength => "0022,0003",
   ImagePathFilterPassBand => "0022,0004",
   PatientEyeMovementCommanded => "0022,0005",
   PatientEyeMovementCommandCodeSequence => "0022,0006",
   SphericalLensPower => "0022,0007",
   CylinderLensPower => "0022,0008",
   CylinderAxis => "0022,0009",
   EmmetropicMagnification => "0022,000a",
   IntraOcularPressure => "0022,000b",
   HorizontalFieldOfView => "0022,000c",
   PupilDilated => "0022,000d",
   DegreeOfDilation => "0022,000e",
   StereoBaselineAngle => "0022,0010",
   StereoBaselineDisplacement => "0022,0011",
   StereoHorizontalPixelOffset => "0022,0012",
   StereoVerticalPixelOffset => "0022,0013",
   StereoRotation => "0022,0014",
   AcquisitionDeviceTypeCodeSequence => "0022,0015",
   IlluminationTypeCodeSequence => "0022,0016",
   LightPathFilterTypeStackCodeSequence => "0022,0017",
   ImagePathFilterTypeStackCodeSequence => "0022,0018",
   LensesCodeSequence => "0022,0019",
   ChannelDescriptionCodeSequence => "0022,001a",
   RefractiveStateSequence => "0022,001b",
   MydriaticAgentCodeSequence => "0022,001c",
   RelativeImagePositionCodeSequence => "0022,001d",
   StereoPairsSequence => "0022,0020",
   LeftImageSequence => "0022,0021",
   RightImageSequence => "0022,0022",
   AxialLengthOfTheEye => "0022,0030",
   OphthalmicFrameLocationSequence => "0022,0031",
   ReferenceCoordinates => "0022,0032",
   DepthSpatialResolution => "0022,0035",
   MaximumDepthDistortion => "0022,0036",
   AlongScanSpatialResolution => "0022,0037",
   MaximumAlongScanDistortion => "0022,0038",
   OphthalmicImageOrientation => "0022,0039",
   DepthOfTransverseImage => "0022,0041",
   MydriaticAgentConcentrationUnitsSequence => "0022,0042",
   AcrossScanSpatialResolution => "0022,0048",
   MaximumAcrossScanDistortion => "0022,0049",
   MydriaticAgentConcentration => "0022,004e",
   IlluminationWaveLength => "0022,0055",
   IlluminationPower => "0022,0056",
   IlluminationBandwidth => "0022,0057",
   MydriaticAgentSequence => "0022,0058",
   SamplesPerPixel => "0028,0002",
   SamplesPerPixelUsed => "0028,0003",
   PhotometricInterpretation => "0028,0004",
   ImageDimensions => "0028,0005",
   PlanarConfiguration => "0028,0006",
   NumberOfFrames => "0028,0008",
   FrameIncrementPointer => "0028,0009",
   FrameDimensionPointer => "0028,000a",
   Rows => "0028,0010",
   Columns => "0028,0011",
   Planes => "0028,0012",
   UltrasoundColorDataPresent => "0028,0014",
   PixelSpacing => "0028,0030",
   ZoomFactor => "0028,0031",
   ZoomCenter => "0028,0032",
   PixelAspectRatio => "0028,0034",
   ImageFormat => "0028,0040",
   ManipulatedImage => "0028,0050",
   CorrectedImage => "0028,0051",
   CompressionRecognitionCode => "0028,005f",
   CompressionCode => "0028,0060",
   CompressionOriginator => "0028,0061",
   CompressionLabel => "0028,0062",
   CompressionDescription => "0028,0063",
   CompressionSequence => "0028,0065",
   CompressionStepPointers => "0028,0066",
   RepeatInterval => "0028,0068",
   BitsGrouped => "0028,0069",
   PerimeterTable => "0028,0070",
   PerimeterValue => "0028,0071",
   PredictorRows => "0028,0080",
   PredictorColumns => "0028,0081",
   PredictorConstants => "0028,0082",
   BlockedPixels => "0028,0090",
   BlockRows => "0028,0091",
   BlockColumns => "0028,0092",
   RowOverlap => "0028,0093",
   ColumnOverlap => "0028,0094",
   BitsAllocated => "0028,0100",
   BitsStored => "0028,0101",
   HighBit => "0028,0102",
   PixelRepresentation => "0028,0103",
   SmallestValidPixelValue => "0028,0104",
   LargestValidPixelValue => "0028,0105",
   SmallestImagePixelValue => "0028,0106",
   LargestImagePixelValue => "0028,0107",
   SmallestPixelValueInSeries => "0028,0108",
   LargestPixelValueInSeries => "0028,0109",
   SmallestImagePixelValueInPlane => "0028,0110",
   LargestImagePixelValueInPlane => "0028,0111",
   PixelPaddingValue => "0028,0120",
   PixelPaddingRangeLimit => "0028,0121",
   ImageLocation => "0028,0200",
   QualityControlImage => "0028,0300",
   BurnedInAnnotation => "0028,0301",
   TransformLabel => "0028,0400",
   TransformVersionNumber => "0028,0401",
   NumberOfTransformSteps => "0028,0402",
   SequenceOfCompressedData => "0028,0403",
   DetailsOfCoefficients => "0028,0404",
   RowsForNthOrderCoefficients => "0028,04x0",
   ColumnsForNthOrderCoefficients => "0028,04x1",
   CoefficientCoding => "0028,04x2",
   CoefficientCodingPointers => "0028,04x3",
   DCTLabel => "0028,0700",
   DataBlockDescription => "0028,0701",
   DataBlock => "0028,0702",
   NormalizationFactorFormat => "0028,0710",
   ZonalMapNumberFormat => "0028,0720",
   ZonalMapLocation => "0028,0721",
   ZonalMapFormat => "0028,0722",
   AdaptiveMapFormat => "0028,0730",
   CodeNumberFormat => "0028,0740",
   CodeLabel => "0028,08x0",
   NumberOfTables => "0028,08x2",
   CodeTableLocation => "0028,08x3",
   BitsForCodeWord => "0028,08x4",
   ImageDataLocation => "0028,08x8",
   PixelSpacingCalibrationType => "0028,0a02",
   PixelSpacingCalibrationDescription => "0028,0a04",
   PixelIntensityRelationship => "0028,1040",
   PixelIntensityRelationshipSign => "0028,1041",
   WindowCenter => "0028,1050",
   WindowWidth => "0028,1051",
   RescaleIntercept => "0028,1052",
   RescaleSlope => "0028,1053",
   RescaleType => "0028,1054",
   WindowCenterWidthExplanation => "0028,1055",
   VOILUTFunction => "0028,1056",
   GrayScale => "0028,1080",
   RecommendedViewingMode => "0028,1090",
   GrayLookupTableDescriptor => "0028,1100",
   RedPaletteColorLookupTableDescriptor => "0028,1101",
   GreenPaletteColorLookupTableDescriptor => "0028,1102",
   BluePaletteColorLookupTableDescriptor => "0028,1103",
   AlphaPaletteColorLookupTableDescriptor => "0028,1104",
   LargeRedPaletteColorLookupTableDescriptor => "0028,1111",
   LargeGreenPaletteColorLookupTableDescriptor => "0028,1112",
   LargeBluePaletteColorLookupTableDescriptor => "0028,1113",
   PaletteColorLookupTableUID => "0028,1199",
   GrayLookupTableData => "0028,1200",
   RedPaletteColorLookupTableData => "0028,1201",
   GreenPaletteColorLookupTableData => "0028,1202",
   BluePaletteColorLookupTableData => "0028,1203",
   AlphaPaletteColorLookupTableData => "0028,1204",
   LargeRedPaletteColorLookupTableData => "0028,1211",
   LargeGreenPaletteColorLookupTableData => "0028,1212",
   LargeBluePaletteColorLookupTableData => "0028,1213",
   LargePaletteColorLookupTableUID => "0028,1214",
   SegmentedRedPaletteColorLookupTableData => "0028,1221",
   SegmentedGreenPaletteColorLookupTableData => "0028,1222",
   SegmentedBluePaletteColorLookupTableData => "0028,1223",
   BreastImplantPresent => "0028,1300",
   PartialView => "0028,1350",
   PartialViewDescription => "0028,1351",
   PartialViewCodeSequence => "0028,1352",
   SpatialLocationsPreserved => "0028,135a",
   DataFrameAssignmentSequence => "0028,1401",
   DataPathAssignment => "0028,1402",
   BitsMappedToColorLookupTable => "0028,1403",
   BlendingLUT1Sequence => "0028,1404",
   BlendingLUT1TransferFunction => "0028,1405",
   BlendingWeightConstant => "0028,1406",
   BlendingLookupTableDescriptor => "0028,1407",
   BlendingLookupTableData => "0028,1408",
   EnhancedPaletteColorLookupTableSequence => "0028,140b",
   BlendingLUT2Sequence => "0028,140c",
   BlendingLUT2TransferFunction => "0028,140d",
   DataPathID => "0028,140e",
   RGBLUTTransferFunction => "0028,140f",
   AlphaLUTTransferFunction => "0028,1410",
   ICCProfile => "0028,2000",
   LossyImageCompression => "0028,2110",
   LossyImageCompressionRatio => "0028,2112",
   LossyImageCompressionMethod => "0028,2114",
   ModalityLUTSequence => "0028,3000",
   LUTDescriptor => "0028,3002",
   LUTExplanation => "0028,3003",
   ModalityLUTType => "0028,3004",
   LUTData => "0028,3006",
   VOILUTSequence => "0028,3010",
   SoftcopyVOILUTSequence => "0028,3110",
   ImagePresentationComments => "0028,4000",
   BiPlaneAcquisitionSequence => "0028,5000",
   RepresentativeFrameNumber => "0028,6010",
   FrameNumbersOfInterest => "0028,6020",
   FrameOfInterestDescription => "0028,6022",
   FrameOfInterestType => "0028,6023",
   MaskPointers => "0028,6030",
   RWavePointer => "0028,6040",
   MaskSubtractionSequence => "0028,6100",
   MaskOperation => "0028,6101",
   ApplicableFrameRange => "0028,6102",
   MaskFrameNumbers => "0028,6110",
   ContrastFrameAveraging => "0028,6112",
   MaskSubPixelShift => "0028,6114",
   TIDOffset => "0028,6120",
   MaskOperationExplanation => "0028,6190",
   PixelDataProviderURL => "0028,7fe0",
   DataPointRows => "0028,9001",
   DataPointColumns => "0028,9002",
   SignalDomainColumns => "0028,9003",
   LargestMonochromePixelValue => "0028,9099",
   DataRepresentation => "0028,9108",
   PixelMeasuresSequence => "0028,9110",
   FrameVOILUTSequence => "0028,9132",
   PixelValueTransformationSequence => "0028,9145",
   SignalDomainRows => "0028,9235",
   DisplayFilterPercentage => "0028,9411",
   FramePixelShiftSequence => "0028,9415",
   SubtractionItemID => "0028,9416",
   PixelIntensityRelationshipLUTSequence => "0028,9422",
   FramePixelDataPropertiesSequence => "0028,9443",
   GeometricalProperties => "0028,9444",
   GeometricMaximumDistortion => "0028,9445",
   ImageProcessingApplied => "0028,9446",
   MaskSelectionMode => "0028,9454",
   LUTFunction => "0028,9474",
   MaskVisibilityPercentage => "0028,9478",
   PixelShiftSequence => "0028,9501",
   RegionPixelShiftSequence => "0028,9502",
   VerticesOfTheRegion => "0028,9503",
   MultiFramePresentationSequence => "0028,9505",
   PixelShiftFrameRange => "0028,9506",
   LUTFrameRange => "0028,9507",
   ImageToEquipmentMappingMatrix => "0028,9520",
   EquipmentCoordinateSystemIdentification => "0028,9537",
   StudyStatusID => "0032,000a",
   StudyPriorityID => "0032,000c",
   StudyIDIssuer => "0032,0012",
   StudyVerifiedDate => "0032,0032",
   StudyVerifiedTime => "0032,0033",
   StudyReadDate => "0032,0034",
   StudyReadTime => "0032,0035",
   ScheduledStudyStartDate => "0032,1000",
   ScheduledStudyStartTime => "0032,1001",
   ScheduledStudyStopDate => "0032,1010",
   ScheduledStudyStopTime => "0032,1011",
   ScheduledStudyLocation => "0032,1020",
   ScheduledStudyLocationAETitle => "0032,1021",
   ReasonForStudy => "0032,1030",
   RequestingPhysicianIdentificationSequence => "0032,1031",
   RequestingPhysician => "0032,1032",
   RequestingService => "0032,1033",
   RequestingServiceCodeSequence => "0032,1034",
   StudyArrivalDate => "0032,1040",
   StudyArrivalTime => "0032,1041",
   StudyCompletionDate => "0032,1050",
   StudyCompletionTime => "0032,1051",
   StudyComponentStatusID => "0032,1055",
   RequestedProcedureDescription => "0032,1060",
   RequestedProcedureCodeSequence => "0032,1064",
   RequestedContrastAgent => "0032,1070",
   StudyComments => "0032,4000",
   ReferencedPatientAliasSequence => "0038,0004",
   VisitStatusID => "0038,0008",
   AdmissionID => "0038,0010",
   IssuerOfAdmissionID => "0038,0011",
   IssuerOfAdmissionIDSequence => "0038,0014",
   RouteOfAdmissions => "0038,0016",
   ScheduledAdmissionDate => "0038,001a",
   ScheduledAdmissionTime => "0038,001b",
   ScheduledDischargeDate => "0038,001c",
   ScheduledDischargeTime => "0038,001d",
   ScheduledPatientInstitutionResidence => "0038,001e",
   AdmittingDate => "0038,0020",
   AdmittingTime => "0038,0021",
   DischargeDate => "0038,0030",
   DischargeTime => "0038,0032",
   DischargeDiagnosisDescription => "0038,0040",
   DischargeDiagnosisCodeSequence => "0038,0044",
   SpecialNeeds => "0038,0050",
   ServiceEpisodeID => "0038,0060",
   IssuerOfServiceEpisodeID => "0038,0061",
   ServiceEpisodeDescription => "0038,0062",
   IssuerOfServiceEpisodeIDSequence => "0038,0064",
   PertinentDocumentsSequence => "0038,0100",
   CurrentPatientLocation => "0038,0300",
   PatientInstitutionResidence => "0038,0400",
   PatientState => "0038,0500",
   PatientClinicalTrialParticipationSequence => "0038,0502",
   VisitComments => "0038,4000",
   WaveformOriginality => "003a,0004",
   NumberOfWaveformChannels => "003a,0005",
   NumberOfWaveformSamples => "003a,0010",
   SamplingFrequency => "003a,001a",
   MultiplexGroupLabel => "003a,0020",
   ChannelDefinitionSequence => "003a,0200",
   WaveformChannelNumber => "003a,0202",
   ChannelLabel => "003a,0203",
   ChannelStatus => "003a,0205",
   ChannelSourceSequence => "003a,0208",
   ChannelSourceModifiersSequence => "003a,0209",
   SourceWaveformSequence => "003a,020a",
   ChannelDerivationDescription => "003a,020c",
   ChannelSensitivity => "003a,0210",
   ChannelSensitivityUnitsSequence => "003a,0211",
   ChannelSensitivityCorrectionFactor => "003a,0212",
   ChannelBaseline => "003a,0213",
   ChannelTimeSkew => "003a,0214",
   ChannelSampleSkew => "003a,0215",
   ChannelOffset => "003a,0218",
   WaveformBitsStored => "003a,021a",
   FilterLowFrequency => "003a,0220",
   FilterHighFrequency => "003a,0221",
   NotchFilterFrequency => "003a,0222",
   NotchFilterBandwidth => "003a,0223",
   WaveformDataDisplayScale => "003a,0230",
   WaveformDisplayBackgroundCIELabValue => "003a,0231",
   WaveformPresentationGroupSequence => "003a,0240",
   PresentationGroupNumber => "003a,0241",
   ChannelDisplaySequence => "003a,0242",
   ChannelRecommendedDisplayCIELabValue => "003a,0244",
   ChannelPosition => "003a,0245",
   DisplayShadingFlag => "003a,0246",
   FractionalChannelDisplayScale => "003a,0247",
   AbsoluteChannelDisplayScale => "003a,0248",
   MultiplexedAudioChannelsDescriptionCodeSequence => "003a,0300",
   ChannelIdentificationCode => "003a,0301",
   ChannelMode => "003a,0302",
   ScheduledStationAETitle => "0040,0001",
   ScheduledProcedureStepStartDate => "0040,0002",
   ScheduledProcedureStepStartTime => "0040,0003",
   ScheduledProcedureStepEndDate => "0040,0004",
   ScheduledProcedureStepEndTime => "0040,0005",
   ScheduledPerformingPhysicianName => "0040,0006",
   ScheduledProcedureStepDescription => "0040,0007",
   ScheduledProtocolCodeSequence => "0040,0008",
   ScheduledProcedureStepID => "0040,0009",
   StageCodeSequence => "0040,000a",
   ScheduledPerformingPhysicianIdentificationSequence => "0040,000b",
   ScheduledStationName => "0040,0010",
   ScheduledProcedureStepLocation => "0040,0011",
   PreMedication => "0040,0012",
   ScheduledProcedureStepStatus => "0040,0020",
   OrderPlacerIdentifierSequence => "0040,0026",
   OrderFillerIdentifierSequence => "0040,0027",
   LocalNamespaceEntityID => "0040,0031",
   UniversalEntityID => "0040,0032",
   UniversalEntityIDType => "0040,0033",
   IdentifierTypeCode => "0040,0035",
   AssigningFacilitySequence => "0040,0036",
   AssigningJurisdictionCodeSequence => "0040,0039",
   AssigningAgencyOrDepartmentCodeSequence => "0040,003a",
   ScheduledProcedureStepSequence => "0040,0100",
   ReferencedNonImageCompositeSOPInstanceSequence => "0040,0220",
   PerformedStationAETitle => "0040,0241",
   PerformedStationName => "0040,0242",
   PerformedLocation => "0040,0243",
   PerformedProcedureStepStartDate => "0040,0244",
   PerformedProcedureStepStartTime => "0040,0245",
   PerformedProcedureStepEndDate => "0040,0250",
   PerformedProcedureStepEndTime => "0040,0251",
   PerformedProcedureStepStatus => "0040,0252",
   PerformedProcedureStepID => "0040,0253",
   PerformedProcedureStepDescription => "0040,0254",
   PerformedProcedureTypeDescription => "0040,0255",
   PerformedProtocolCodeSequence => "0040,0260",
   PerformedProtocolType => "0040,0261",
   ScheduledStepAttributesSequence => "0040,0270",
   RequestAttributesSequence => "0040,0275",
   CommentsOnThePerformedProcedureStep => "0040,0280",
   PerformedProcedureStepDiscontinuationReasonCodeSequence => "0040,0281",
   QuantitySequence => "0040,0293",
   Quantity => "0040,0294",
   MeasuringUnitsSequence => "0040,0295",
   BillingItemSequence => "0040,0296",
   TotalTimeOfFluoroscopy => "0040,0300",
   TotalNumberOfExposures => "0040,0301",
   EntranceDose => "0040,0302",
   ExposedArea => "0040,0303",
   DistanceSourceToEntrance => "0040,0306",
   DistanceSourceToSupport => "0040,0307",
   ExposureDoseSequence => "0040,030e",
   CommentsOnRadiationDose => "0040,0310",
   XRayOutput => "0040,0312",
   HalfValueLayer => "0040,0314",
   OrganDose => "0040,0316",
   OrganExposed => "0040,0318",
   BillingProcedureStepSequence => "0040,0320",
   FilmConsumptionSequence => "0040,0321",
   BillingSuppliesAndDevicesSequence => "0040,0324",
   ReferencedProcedureStepSequence => "0040,0330",
   PerformedSeriesSequence => "0040,0340",
   CommentsOnTheScheduledProcedureStep => "0040,0400",
   ProtocolContextSequence => "0040,0440",
   ContentItemModifierSequence => "0040,0441",
   ScheduledSpecimenSequence => "0040,0500",
   SpecimenAccessionNumber => "0040,050a",
   ContainerIdentifier => "0040,0512",
   IssuerOfTheContainerIdentifierSequence => "0040,0513",
   AlternateContainerIdentifierSequence => "0040,0515",
   ContainerTypeCodeSequence => "0040,0518",
   ContainerDescription => "0040,051a",
   ContainerComponentSequence => "0040,0520",
   SpecimenSequence => "0040,0550",
   SpecimenIdentifier => "0040,0551",
   SpecimenDescriptionSequenceTrial => "0040,0552",
   SpecimenDescriptionTrial => "0040,0553",
   SpecimenUID => "0040,0554",
   AcquisitionContextSequence => "0040,0555",
   AcquisitionContextDescription => "0040,0556",
   SpecimenDescriptionSequence => "0040,0560",
   IssuerOfTheSpecimenIdentifierSequence => "0040,0562",
   SpecimenTypeCodeSequence => "0040,059a",
   SpecimenShortDescription => "0040,0600",
   SpecimenDetailedDescription => "0040,0602",
   SpecimenPreparationSequence => "0040,0610",
   SpecimenPreparationStepContentItemSequence => "0040,0612",
   SpecimenLocalizationContentItemSequence => "0040,0620",
   SlideIdentifier => "0040,06fa",
   ImageCenterPointCoordinatesSequence => "0040,071a",
   XOffsetInSlideCoordinateSystem => "0040,072a",
   YOffsetInSlideCoordinateSystem => "0040,073a",
   ZOffsetInSlideCoordinateSystem => "0040,074a",
   PixelSpacingSequence => "0040,08d8",
   CoordinateSystemAxisCodeSequence => "0040,08da",
   MeasurementUnitsCodeSequence => "0040,08ea",
   VitalStainCodeSequenceTrial => "0040,09f8",
   RequestedProcedureID => "0040,1001",
   ReasonForTheRequestedProcedure => "0040,1002",
   RequestedProcedurePriority => "0040,1003",
   PatientTransportArrangements => "0040,1004",
   RequestedProcedureLocation => "0040,1005",
   PlacerOrderNumberProcedure => "0040,1006",
   FillerOrderNumberProcedure => "0040,1007",
   ConfidentialityCode => "0040,1008",
   ReportingPriority => "0040,1009",
   ReasonForRequestedProcedureCodeSequence => "0040,100a",
   NamesOfIntendedRecipientsOfResults => "0040,1010",
   IntendedRecipientsOfResultsIdentificationSequence => "0040,1011",
   ReasonForPerformedProcedureCodeSequence => "0040,1012",
   PersonIdentificationCodeSequence => "0040,1101",
   PersonAddress => "0040,1102",
   PersonTelephoneNumbers => "0040,1103",
   RequestedProcedureComments => "0040,1400",
   ReasonForTheImagingServiceRequest => "0040,2001",
   IssueDateOfImagingServiceRequest => "0040,2004",
   IssueTimeOfImagingServiceRequest => "0040,2005",
   PlacerOrderNumberImagingServiceRequestRetired => "0040,2006",
   FillerOrderNumberImagingServiceRequestRetired => "0040,2007",
   OrderEnteredBy => "0040,2008",
   OrderEntererLocation => "0040,2009",
   OrderCallbackPhoneNumber => "0040,2010",
   PlacerOrderNumberImagingServiceRequest => "0040,2016",
   FillerOrderNumberImagingServiceRequest => "0040,2017",
   ImagingServiceRequestComments => "0040,2400",
   ConfidentialityConstraintOnPatientDataDescription => "0040,3001",
   GeneralPurposeScheduledProcedureStepStatus => "0040,4001",
   GeneralPurposePerformedProcedureStepStatus => "0040,4002",
   GeneralPurposeScheduledProcedureStepPriority => "0040,4003",
   ScheduledProcessingApplicationsCodeSequence => "0040,4004",
   ScheduledProcedureStepStartDateTime => "0040,4005",
   MultipleCopiesFlag => "0040,4006",
   PerformedProcessingApplicationsCodeSequence => "0040,4007",
   HumanPerformerCodeSequence => "0040,4009",
   ScheduledProcedureStepModificationDateTime => "0040,4010",
   ExpectedCompletionDateTime => "0040,4011",
   ResultingGeneralPurposePerformedProcedureStepsSequence => "0040,4015",
   ReferencedGeneralPurposeScheduledProcedureStepSequence => "0040,4016",
   ScheduledWorkitemCodeSequence => "0040,4018",
   PerformedWorkitemCodeSequence => "0040,4019",
   InputAvailabilityFlag => "0040,4020",
   InputInformationSequence => "0040,4021",
   RelevantInformationSequence => "0040,4022",
   ReferencedGeneralPurposeScheduledProcedureStepTransactionUID => "0040,4023",
   ScheduledStationNameCodeSequence => "0040,4025",
   ScheduledStationClassCodeSequence => "0040,4026",
   ScheduledStationGeographicLocationCodeSequence => "0040,4027",
   PerformedStationNameCodeSequence => "0040,4028",
   PerformedStationClassCodeSequence => "0040,4029",
   PerformedStationGeographicLocationCodeSequence => "0040,4030",
   RequestedSubsequentWorkitemCodeSequence => "0040,4031",
   NonDICOMOutputCodeSequence => "0040,4032",
   OutputInformationSequence => "0040,4033",
   ScheduledHumanPerformersSequence => "0040,4034",
   ActualHumanPerformersSequence => "0040,4035",
   HumanPerformerOrganization => "0040,4036",
   HumanPerformerName => "0040,4037",
   RawDataHandling => "0040,4040",
   EntranceDoseInmGy => "0040,8302",
   ReferencedImageRealWorldValueMappingSequence => "0040,9094",
   RealWorldValueMappingSequence => "0040,9096",
   PixelValueMappingCodeSequence => "0040,9098",
   LUTLabel => "0040,9210",
   RealWorldValueLastValueMapped => "0040,9211",
   RealWorldValueLUTData => "0040,9212",
   RealWorldValueFirstValueMapped => "0040,9216",
   RealWorldValueIntercept => "0040,9224",
   RealWorldValueSlope => "0040,9225",
   RelationshipType => "0040,a010",
   VerifyingOrganization => "0040,a027",
   VerificationDateTime => "0040,a030",
   ObservationDateTime => "0040,a032",
   ValueType => "0040,a040",
   ConceptNameCodeSequence => "0040,a043",
   ContinuityOfContent => "0040,a050",
   VerifyingObserverSequence => "0040,a073",
   VerifyingObserverName => "0040,a075",
   AuthorObserverSequence => "0040,a078",
   ParticipantSequence => "0040,a07a",
   CustodialOrganizationSequence => "0040,a07c",
   ParticipationType => "0040,a080",
   ParticipationDateTime => "0040,a082",
   ObserverType => "0040,a084",
   VerifyingObserverIdentificationCodeSequence => "0040,a088",
   EquivalentCDADocumentSequence => "0040,a090",
   ReferencedWaveformChannels => "0040,a0b0",
   DateTime => "0040,a120",
   Date => "0040,a121",
   Time => "0040,a122",
   PersonName => "0040,a123",
   UID => "0040,a124",
   TemporalRangeType => "0040,a130",
   ReferencedSamplePositions => "0040,a132",
   ReferencedFrameNumbers => "0040,a136",
   ReferencedTimeOffsets => "0040,a138",
   ReferencedDateTime => "0040,a13a",
   TextValue => "0040,a160",
   ConceptCodeSequence => "0040,a168",
   PurposeOfReferenceCodeSequence => "0040,a170",
   AnnotationGroupNumber => "0040,a180",
   ModifierCodeSequence => "0040,a195",
   MeasuredValueSequence => "0040,a300",
   NumericValueQualifierCodeSequence => "0040,a301",
   NumericValue => "0040,a30a",
   AddressTrial => "0040,a353",
   TelephoneNumberTrial => "0040,a354",
   PredecessorDocumentsSequence => "0040,a360",
   ReferencedRequestSequence => "0040,a370",
   PerformedProcedureCodeSequence => "0040,a372",
   CurrentRequestedProcedureEvidenceSequence => "0040,a375",
   PertinentOtherEvidenceSequence => "0040,a385",
   HL7StructuredDocumentReferenceSequence => "0040,a390",
   CompletionFlag => "0040,a491",
   CompletionFlagDescription => "0040,a492",
   VerificationFlag => "0040,a493",
   ArchiveRequested => "0040,a494",
   PreliminaryFlag => "0040,a496",
   ContentTemplateSequence => "0040,a504",
   IdenticalDocumentsSequence => "0040,a525",
   ContentSequence => "0040,a730",
   WaveformAnnotationSequence => "0040,b020",
   TemplateIdentifier => "0040,db00",
   TemplateVersion => "0040,db06",
   TemplateLocalVersion => "0040,db07",
   TemplateExtensionFlag => "0040,db0b",
   TemplateExtensionOrganizationUID => "0040,db0c",
   TemplateExtensionCreatorUID => "0040,db0d",
   ReferencedContentItemIdentifier => "0040,db73",
   HL7InstanceIdentifier => "0040,e001",
   HL7DocumentEffectiveTime => "0040,e004",
   HL7DocumentTypeCodeSequence => "0040,e006",
   RetrieveURI => "0040,e010",
   RetrieveLocationUID => "0040,e011",
   DocumentTitle => "0042,0010",
   EncapsulatedDocument => "0042,0011",
   MIMETypeOfEncapsulatedDocument => "0042,0012",
   SourceInstanceSequence => "0042,0013",
   ListOfMIMETypes => "0042,0014",
   ProductPackageIdentifier => "0044,0001",
   SubstanceAdministrationApproval => "0044,0002",
   ApprovalStatusFurtherDescription => "0044,0003",
   ApprovalStatusDateTime => "0044,0004",
   ProductTypeCodeSequence => "0044,0007",
   ProductName => "0044,0008",
   ProductDescription => "0044,0009",
   ProductLotIdentifier => "0044,000a",
   ProductExpirationDateTime => "0044,000b",
   SubstanceAdministrationDateTime => "0044,0010",
   SubstanceAdministrationNotes => "0044,0011",
   SubstanceAdministrationDeviceID => "0044,0012",
   ProductParameterSequence => "0044,0013",
   SubstanceAdministrationParameterSequence => "0044,0019",
   LensDescription => "0046,0012",
   RightLensSequence => "0046,0014",
   LeftLensSequence => "0046,0015",
   UnspecifiedLateralityLensSequence => "0046,0016",
   CylinderSequence => "0046,0018",
   PrismSequence => "0046,0028",
   HorizontalPrismPower => "0046,0030",
   HorizontalPrismBase => "0046,0032",
   VerticalPrismPower => "0046,0034",
   VerticalPrismBase => "0046,0036",
   LensSegmentType => "0046,0038",
   OpticalTransmittance => "0046,0040",
   ChannelWidth => "0046,0042",
   PupilSize => "0046,0044",
   CornealSize => "0046,0046",
   AutorefractionRightEyeSequence => "0046,0050",
   AutorefractionLeftEyeSequence => "0046,0052",
   DistancePupillaryDistance => "0046,0060",
   NearPupillaryDistance => "0046,0062",
   IntermediatePupillaryDistance => "0046,0063",
   OtherPupillaryDistance => "0046,0064",
   KeratometryRightEyeSequence => "0046,0070",
   KeratometryLeftEyeSequence => "0046,0071",
   SteepKeratometricAxisSequence => "0046,0074",
   RadiusOfCurvature => "0046,0075",
   KeratometricPower => "0046,0076",
   KeratometricAxis => "0046,0077",
   FlatKeratometricAxisSequence => "0046,0080",
   BackgroundColor => "0046,0092",
   Optotype => "0046,0094",
   OptotypePresentation => "0046,0095",
   SubjectiveRefractionRightEyeSequence => "0046,0097",
   SubjectiveRefractionLeftEyeSequence => "0046,0098",
   AddNearSequence => "0046,0100",
   AddIntermediateSequence => "0046,0101",
   AddOtherSequence => "0046,0102",
   AddPower => "0046,0104",
   ViewingDistance => "0046,0106",
   VisualAcuityTypeCodeSequence => "0046,0121",
   VisualAcuityRightEyeSequence => "0046,0122",
   VisualAcuityLeftEyeSequence => "0046,0123",
   VisualAcuityBothEyesOpenSequence => "0046,0124",
   ViewingDistanceType => "0046,0125",
   VisualAcuityModifiers => "0046,0135",
   DecimalVisualAcuity => "0046,0137",
   OptotypeDetailedDefinition => "0046,0139",
   ReferencedRefractiveMeasurementsSequence => "0046,0145",
   SpherePower => "0046,0146",
   CylinderPower => "0046,0147",
   CalibrationImage => "0050,0004",
   DeviceSequence => "0050,0010",
   ContainerComponentTypeCodeSequence => "0050,0012",
   ContainerComponentThickness => "0050,0013",
   DeviceLength => "0050,0014",
   ContainerComponentWidth => "0050,0015",
   DeviceDiameter => "0050,0016",
   DeviceDiameterUnits => "0050,0017",
   DeviceVolume => "0050,0018",
   InterMarkerDistance => "0050,0019",
   ContainerComponentMaterial => "0050,001a",
   ContainerComponentID => "0050,001b",
   ContainerComponentLength => "0050,001c",
   ContainerComponentDiameter => "0050,001d",
   ContainerComponentDescription => "0050,001e",
   DeviceDescription => "0050,0020",
   EnergyWindowVector => "0054,0010",
   NumberOfEnergyWindows => "0054,0011",
   EnergyWindowInformationSequence => "0054,0012",
   EnergyWindowRangeSequence => "0054,0013",
   EnergyWindowLowerLimit => "0054,0014",
   EnergyWindowUpperLimit => "0054,0015",
   RadiopharmaceuticalInformationSequence => "0054,0016",
   ResidualSyringeCounts => "0054,0017",
   EnergyWindowName => "0054,0018",
   DetectorVector => "0054,0020",
   NumberOfDetectors => "0054,0021",
   DetectorInformationSequence => "0054,0022",
   PhaseVector => "0054,0030",
   NumberOfPhases => "0054,0031",
   PhaseInformationSequence => "0054,0032",
   NumberOfFramesInPhase => "0054,0033",
   PhaseDelay => "0054,0036",
   PauseBetweenFrames => "0054,0038",
   PhaseDescription => "0054,0039",
   RotationVector => "0054,0050",
   NumberOfRotations => "0054,0051",
   RotationInformationSequence => "0054,0052",
   NumberOfFramesInRotation => "0054,0053",
   RRIntervalVector => "0054,0060",
   NumberOfRRIntervals => "0054,0061",
   GatedInformationSequence => "0054,0062",
   DataInformationSequence => "0054,0063",
   TimeSlotVector => "0054,0070",
   NumberOfTimeSlots => "0054,0071",
   TimeSlotInformationSequence => "0054,0072",
   TimeSlotTime => "0054,0073",
   SliceVector => "0054,0080",
   NumberOfSlices => "0054,0081",
   AngularViewVector => "0054,0090",
   TimeSliceVector => "0054,0100",
   NumberOfTimeSlices => "0054,0101",
   StartAngle => "0054,0200",
   TypeOfDetectorMotion => "0054,0202",
   TriggerVector => "0054,0210",
   NumberOfTriggersInPhase => "0054,0211",
   ViewCodeSequence => "0054,0220",
   ViewModifierCodeSequence => "0054,0222",
   RadionuclideCodeSequence => "0054,0300",
   AdministrationRouteCodeSequence => "0054,0302",
   RadiopharmaceuticalCodeSequence => "0054,0304",
   CalibrationDataSequence => "0054,0306",
   EnergyWindowNumber => "0054,0308",
   ImageID => "0054,0400",
   PatientOrientationCodeSequence => "0054,0410",
   PatientOrientationModifierCodeSequence => "0054,0412",
   PatientGantryRelationshipCodeSequence => "0054,0414",
   SliceProgressionDirection => "0054,0500",
   SeriesType => "0054,1000",
   Units => "0054,1001",
   CountsSource => "0054,1002",
   ReprojectionMethod => "0054,1004",
   RandomsCorrectionMethod => "0054,1100",
   AttenuationCorrectionMethod => "0054,1101",
   DecayCorrection => "0054,1102",
   ReconstructionMethod => "0054,1103",
   DetectorLinesOfResponseUsed => "0054,1104",
   ScatterCorrectionMethod => "0054,1105",
   AxialAcceptance => "0054,1200",
   AxialMash => "0054,1201",
   TransverseMash => "0054,1202",
   DetectorElementSize => "0054,1203",
   CoincidenceWindowWidth => "0054,1210",
   SecondaryCountsType => "0054,1220",
   FrameReferenceTime => "0054,1300",
   PrimaryPromptsCountsAccumulated => "0054,1310",
   SecondaryCountsAccumulated => "0054,1311",
   SliceSensitivityFactor => "0054,1320",
   DecayFactor => "0054,1321",
   DoseCalibrationFactor => "0054,1322",
   ScatterFractionFactor => "0054,1323",
   DeadTimeFactor => "0054,1324",
   ImageIndex => "0054,1330",
   CountsIncluded => "0054,1400",
   DeadTimeCorrectionFlag => "0054,1401",
   HistogramSequence => "0060,3000",
   HistogramNumberOfBins => "0060,3002",
   HistogramFirstBinValue => "0060,3004",
   HistogramLastBinValue => "0060,3006",
   HistogramBinWidth => "0060,3008",
   HistogramExplanation => "0060,3010",
   HistogramData => "0060,3020",
   SegmentationType => "0062,0001",
   SegmentSequence => "0062,0002",
   SegmentedPropertyCategoryCodeSequence => "0062,0003",
   SegmentNumber => "0062,0004",
   SegmentLabel => "0062,0005",
   SegmentDescription => "0062,0006",
   SegmentAlgorithmType => "0062,0008",
   SegmentAlgorithmName => "0062,0009",
   SegmentIdentificationSequence => "0062,000a",
   ReferencedSegmentNumber => "0062,000b",
   RecommendedDisplayGrayscaleValue => "0062,000c",
   RecommendedDisplayCIELabValue => "0062,000d",
   MaximumFractionalValue => "0062,000e",
   SegmentedPropertyTypeCodeSequence => "0062,000f",
   SegmentationFractionalType => "0062,0010",
   DeformableRegistrationSequence => "0064,0002",
   SourceFrameOfReferenceUID => "0064,0003",
   DeformableRegistrationGridSequence => "0064,0005",
   GridDimensions => "0064,0007",
   GridResolution => "0064,0008",
   VectorGridData => "0064,0009",
   PreDeformationMatrixRegistrationSequence => "0064,000f",
   PostDeformationMatrixRegistrationSequence => "0064,0010",
   NumberOfSurfaces => "0066,0001",
   SurfaceSequence => "0066,0002",
   SurfaceNumber => "0066,0003",
   SurfaceComments => "0066,0004",
   SurfaceProcessing => "0066,0009",
   SurfaceProcessingRatio => "0066,000a",
   SurfaceProcessingDescription => "0066,000b",
   RecommendedPresentationOpacity => "0066,000c",
   RecommendedPresentationType => "0066,000d",
   FiniteVolume => "0066,000e",
   Manifold => "0066,0010",
   SurfacePointsSequence => "0066,0011",
   SurfacePointsNormalsSequence => "0066,0012",
   SurfaceMeshPrimitivesSequence => "0066,0013",
   NumberOfSurfacePoints => "0066,0015",
   PointCoordinatesData => "0066,0016",
   PointPositionAccuracy => "0066,0017",
   MeanPointDistance => "0066,0018",
   MaximumPointDistance => "0066,0019",
   PointsBoundingBoxCoordinates => "0066,001a",
   AxisOfRotation => "0066,001b",
   CenterOfRotation => "0066,001c",
   NumberOfVectors => "0066,001e",
   VectorDimensionality => "0066,001f",
   VectorAccuracy => "0066,0020",
   VectorCoordinateData => "0066,0021",
   TrianglePointIndexList => "0066,0023",
   EdgePointIndexList => "0066,0024",
   VertexPointIndexList => "0066,0025",
   TriangleStripSequence => "0066,0026",
   TriangleFanSequence => "0066,0027",
   LineSequence => "0066,0028",
   PrimitivePointIndexList => "0066,0029",
   SurfaceCount => "0066,002a",
   ReferencedSurfaceSequence => "0066,002b",
   ReferencedSurfaceNumber => "0066,002c",
   SegmentSurfaceGenerationAlgorithmIdentificationSequence => "0066,002d",
   SegmentSurfaceSourceInstanceSequence => "0066,002e",
   AlgorithmFamilyCodeSequence => "0066,002f",
   AlgorithmNameCodeSequence => "0066,0030",
   AlgorithmVersion => "0066,0031",
   AlgorithmParameters => "0066,0032",
   FacetSequence => "0066,0034",
   SurfaceProcessingAlgorithmIdentificationSequence => "0066,0035",
   AlgorithmName => "0066,0036",
   GraphicAnnotationSequence => "0070,0001",
   GraphicLayer => "0070,0002",
   BoundingBoxAnnotationUnits => "0070,0003",
   AnchorPointAnnotationUnits => "0070,0004",
   GraphicAnnotationUnits => "0070,0005",
   UnformattedTextValue => "0070,0006",
   TextObjectSequence => "0070,0008",
   GraphicObjectSequence => "0070,0009",
   BoundingBoxTopLeftHandCorner => "0070,0010",
   BoundingBoxBottomRightHandCorner => "0070,0011",
   BoundingBoxTextHorizontalJustification => "0070,0012",
   AnchorPoint => "0070,0014",
   AnchorPointVisibility => "0070,0015",
   GraphicDimensions => "0070,0020",
   NumberOfGraphicPoints => "0070,0021",
   GraphicData => "0070,0022",
   GraphicType => "0070,0023",
   GraphicFilled => "0070,0024",
   ImageRotationRetired => "0070,0040",
   ImageHorizontalFlip => "0070,0041",
   ImageRotation => "0070,0042",
   DisplayedAreaTopLeftHandCornerTrial => "0070,0050",
   DisplayedAreaBottomRightHandCornerTrial => "0070,0051",
   DisplayedAreaTopLeftHandCorner => "0070,0052",
   DisplayedAreaBottomRightHandCorner => "0070,0053",
   DisplayedAreaSelectionSequence => "0070,005a",
   GraphicLayerSequence => "0070,0060",
   GraphicLayerOrder => "0070,0062",
   GraphicLayerRecommendedDisplayGrayscaleValue => "0070,0066",
   GraphicLayerRecommendedDisplayRGBValue => "0070,0067",
   GraphicLayerDescription => "0070,0068",
   ContentLabel => "0070,0080",
   ContentDescription => "0070,0081",
   PresentationCreationDate => "0070,0082",
   PresentationCreationTime => "0070,0083",
   ContentCreatorName => "0070,0084",
   ContentCreatorIdentificationCodeSequence => "0070,0086",
   AlternateContentDescriptionSequence => "0070,0087",
   PresentationSizeMode => "0070,0100",
   PresentationPixelSpacing => "0070,0101",
   PresentationPixelAspectRatio => "0070,0102",
   PresentationPixelMagnificationRatio => "0070,0103",
   ShapeType => "0070,0306",
   RegistrationSequence => "0070,0308",
   MatrixRegistrationSequence => "0070,0309",
   MatrixSequence => "0070,030a",
   FrameOfReferenceTransformationMatrixType => "0070,030c",
   RegistrationTypeCodeSequence => "0070,030d",
   FiducialDescription => "0070,030f",
   FiducialIdentifier => "0070,0310",
   FiducialIdentifierCodeSequence => "0070,0311",
   ContourUncertaintyRadius => "0070,0312",
   UsedFiducialsSequence => "0070,0314",
   GraphicCoordinatesDataSequence => "0070,0318",
   FiducialUID => "0070,031a",
   FiducialSetSequence => "0070,031c",
   FiducialSequence => "0070,031e",
   GraphicLayerRecommendedDisplayCIELabValue => "0070,0401",
   BlendingSequence => "0070,0402",
   RelativeOpacity => "0070,0403",
   ReferencedSpatialRegistrationSequence => "0070,0404",
   BlendingPosition => "0070,0405",
   HangingProtocolName => "0072,0002",
   HangingProtocolDescription => "0072,0004",
   HangingProtocolLevel => "0072,0006",
   HangingProtocolCreator => "0072,0008",
   HangingProtocolCreationDateTime => "0072,000a",
   HangingProtocolDefinitionSequence => "0072,000c",
   HangingProtocolUserIdentificationCodeSequence => "0072,000e",
   HangingProtocolUserGroupName => "0072,0010",
   SourceHangingProtocolSequence => "0072,0012",
   NumberOfPriorsReferenced => "0072,0014",
   ImageSetsSequence => "0072,0020",
   ImageSetSelectorSequence => "0072,0022",
   ImageSetSelectorUsageFlag => "0072,0024",
   SelectorAttribute => "0072,0026",
   SelectorValueNumber => "0072,0028",
   TimeBasedImageSetsSequence => "0072,0030",
   ImageSetNumber => "0072,0032",
   ImageSetSelectorCategory => "0072,0034",
   RelativeTime => "0072,0038",
   RelativeTimeUnits => "0072,003a",
   AbstractPriorValue => "0072,003c",
   AbstractPriorCodeSequence => "0072,003e",
   ImageSetLabel => "0072,0040",
   SelectorAttributeVR => "0072,0050",
   SelectorSequencePointer => "0072,0052",
   SelectorSequencePointerPrivateCreator => "0072,0054",
   SelectorAttributePrivateCreator => "0072,0056",
   SelectorATValue => "0072,0060",
   SelectorCSValue => "0072,0062",
   SelectorISValue => "0072,0064",
   SelectorLOValue => "0072,0066",
   SelectorLTValue => "0072,0068",
   SelectorPNValue => "0072,006a",
   SelectorSHValue => "0072,006c",
   SelectorSTValue => "0072,006e",
   SelectorUTValue => "0072,0070",
   SelectorDSValue => "0072,0072",
   SelectorFDValue => "0072,0074",
   SelectorFLValue => "0072,0076",
   SelectorULValue => "0072,0078",
   SelectorUSValue => "0072,007a",
   SelectorSLValue => "0072,007c",
   SelectorSSValue => "0072,007e",
   SelectorCodeSequenceValue => "0072,0080",
   NumberOfScreens => "0072,0100",
   NominalScreenDefinitionSequence => "0072,0102",
   NumberOfVerticalPixels => "0072,0104",
   NumberOfHorizontalPixels => "0072,0106",
   DisplayEnvironmentSpatialPosition => "0072,0108",
   ScreenMinimumGrayscaleBitDepth => "0072,010a",
   ScreenMinimumColorBitDepth => "0072,010c",
   ApplicationMaximumRepaintTime => "0072,010e",
   DisplaySetsSequence => "0072,0200",
   DisplaySetNumber => "0072,0202",
   DisplaySetLabel => "0072,0203",
   DisplaySetPresentationGroup => "0072,0204",
   DisplaySetPresentationGroupDescription => "0072,0206",
   PartialDataDisplayHandling => "0072,0208",
   SynchronizedScrollingSequence => "0072,0210",
   DisplaySetScrollingGroup => "0072,0212",
   NavigationIndicatorSequence => "0072,0214",
   NavigationDisplaySet => "0072,0216",
   ReferenceDisplaySets => "0072,0218",
   ImageBoxesSequence => "0072,0300",
   ImageBoxNumber => "0072,0302",
   ImageBoxLayoutType => "0072,0304",
   ImageBoxTileHorizontalDimension => "0072,0306",
   ImageBoxTileVerticalDimension => "0072,0308",
   ImageBoxScrollDirection => "0072,0310",
   ImageBoxSmallScrollType => "0072,0312",
   ImageBoxSmallScrollAmount => "0072,0314",
   ImageBoxLargeScrollType => "0072,0316",
   ImageBoxLargeScrollAmount => "0072,0318",
   ImageBoxOverlapPriority => "0072,0320",
   CineRelativeToRealTime => "0072,0330",
   FilterOperationsSequence => "0072,0400",
   FilterByCategory => "0072,0402",
   FilterByAttributePresence => "0072,0404",
   FilterByOperator => "0072,0406",
   StructuredDisplayBackgroundCIELabValue => "0072,0420",
   EmptyImageBoxCIELabValue => "0072,0421",
   StructuredDisplayImageBoxSequence => "0072,0422",
   StructuredDisplayTextBoxSequence => "0072,0424",
   ReferencedFirstFrameSequence => "0072,0427",
   ImageBoxSynchronizationSequence => "0072,0430",
   SynchronizedImageBoxList => "0072,0432",
   TypeOfSynchronization => "0072,0434",
   BlendingOperationType => "0072,0500",
   ReformattingOperationType => "0072,0510",
   ReformattingThickness => "0072,0512",
   ReformattingInterval => "0072,0514",
   ReformattingOperationInitialViewDirection => "0072,0516",
   ThreeDRenderingType => "0072,0520",
   SortingOperationsSequence => "0072,0600",
   SortByCategory => "0072,0602",
   SortingDirection => "0072,0604",
   DisplaySetPatientOrientation => "0072,0700",
   VOIType => "0072,0702",
   PseudoColorType => "0072,0704",
   ShowGrayscaleInverted => "0072,0706",
   ShowImageTrueSizeFlag => "0072,0710",
   ShowGraphicAnnotationFlag => "0072,0712",
   ShowPatientDemographicsFlag => "0072,0714",
   ShowAcquisitionTechniquesFlag => "0072,0716",
   DisplaySetHorizontalJustification => "0072,0717",
   DisplaySetVerticalJustification => "0072,0718",
   UnifiedProcedureStepState => "0074,1000",
   UnifiedProcedureStepProgressInformationSequence => "0074,1002",
   UnifiedProcedureStepProgress => "0074,1004",
   UnifiedProcedureStepProgressDescription => "0074,1006",
   UnifiedProcedureStepCommunicationsURISequence => "0074,1008",
   ContactURI => "0074,100a",
   ContactDisplayName => "0074,100c",
   UnifiedProcedureStepDiscontinuationReasonCodeSequence => "0074,100e",
   BeamTaskSequence => "0074,1020",
   BeamTaskType => "0074,1022",
   BeamOrderIndex => "0074,1024",
   DeliveryVerificationImageSequence => "0074,1030",
   VerificationImageTiming => "0074,1032",
   DoubleExposureFlag => "0074,1034",
   DoubleExposureOrdering => "0074,1036",
   DoubleExposureMeterset => "0074,1038",
   DoubleExposureFieldDelta => "0074,103a",
   RelatedReferenceRTImageSequence => "0074,1040",
   GeneralMachineVerificationSequence => "0074,1042",
   ConventionalMachineVerificationSequence => "0074,1044",
   IonMachineVerificationSequence => "0074,1046",
   FailedAttributesSequence => "0074,1048",
   OverriddenAttributesSequence => "0074,104a",
   ConventionalControlPointVerificationSequence => "0074,104c",
   IonControlPointVerificationSequence => "0074,104e",
   AttributeOccurrenceSequence => "0074,1050",
   AttributeOccurrencePointer => "0074,1052",
   AttributeItemSelector => "0074,1054",
   AttributeOccurrencePrivateCreator => "0074,1056",
   ScheduledProcedureStepPriority => "0074,1200",
   WorklistLabel => "0074,1202",
   ProcedureStepLabel => "0074,1204",
   ScheduledProcessingParametersSequence => "0074,1210",
   PerformedProcessingParametersSequence => "0074,1212",
   UnifiedProcedureStepPerformedProcedureSequence => "0074,1216",
   RelatedProcedureStepSequence => "0074,1220",
   ProcedureStepRelationshipType => "0074,1222",
   DeletionLock => "0074,1230",
   ReceivingAE => "0074,1234",
   RequestingAE => "0074,1236",
   ReasonForCancellation => "0074,1238",
   SCPStatus => "0074,1242",
   SubscriptionListStatus => "0074,1244",
   UnifiedProcedureStepListStatus => "0074,1246",
   StorageMediaFileSetID => "0088,0130",
   StorageMediaFileSetUID => "0088,0140",
   IconImageSequence => "0088,0200",
   TopicTitle => "0088,0904",
   TopicSubject => "0088,0906",
   TopicAuthor => "0088,0910",
   TopicKeywords => "0088,0912",
   SOPInstanceStatus => "0100,0410",
   SOPAuthorizationDateTime => "0100,0420",
   SOPAuthorizationComment => "0100,0424",
   AuthorizationEquipmentCertificationNumber => "0100,0426",
   MACIDNumber => "0400,0005",
   MACCalculationTransferSyntaxUID => "0400,0010",
   MACAlgorithm => "0400,0015",
   DataElementsSigned => "0400,0020",
   DigitalSignatureUID => "0400,0100",
   DigitalSignatureDateTime => "0400,0105",
   CertificateType => "0400,0110",
   CertificateOfSigner => "0400,0115",
   Signature => "0400,0120",
   CertifiedTimestampType => "0400,0305",
   CertifiedTimestamp => "0400,0310",
   DigitalSignaturePurposeCodeSequence => "0400,0401",
   ReferencedDigitalSignatureSequence => "0400,0402",
   ReferencedSOPInstanceMACSequence => "0400,0403",
   MAC => "0400,0404",
   EncryptedAttributesSequence => "0400,0500",
   EncryptedContentTransferSyntaxUID => "0400,0510",
   EncryptedContent => "0400,0520",
   ModifiedAttributesSequence => "0400,0550",
   OriginalAttributesSequence => "0400,0561",
   AttributeModificationDateTime => "0400,0562",
   ModifyingSystem => "0400,0563",
   SourceOfPreviousValues => "0400,0564",
   ReasonForTheAttributeModification => "0400,0565",
   EscapeTriplet => "1000,xxx0",
   RunLengthTriplet => "1000,xxx1",
   HuffmanTableSize => "1000,xxx2",
   HuffmanTableTriplet => "1000,xxx3",
   ShiftTableSize => "1000,xxx4",
   ShiftTableTriplet => "1000,xxx5",
   ZonalMap => "1010,xxxx",
   NumberOfCopies => "2000,0010",
   PrinterConfigurationSequence => "2000,001e",
   PrintPriority => "2000,0020",
   MediumType => "2000,0030",
   FilmDestination => "2000,0040",
   FilmSessionLabel => "2000,0050",
   MemoryAllocation => "2000,0060",
   MaximumMemoryAllocation => "2000,0061",
   ColorImagePrintingFlag => "2000,0062",
   CollationFlag => "2000,0063",
   AnnotationFlag => "2000,0065",
   ImageOverlayFlag => "2000,0067",
   PresentationLUTFlag => "2000,0069",
   ImageBoxPresentationLUTFlag => "2000,006a",
   MemoryBitDepth => "2000,00a0",
   PrintingBitDepth => "2000,00a1",
   MediaInstalledSequence => "2000,00a2",
   OtherMediaAvailableSequence => "2000,00a4",
   SupportedImageDisplayFormatsSequence => "2000,00a8",
   ReferencedFilmBoxSequence => "2000,0500",
   ReferencedStoredPrintSequence => "2000,0510",
   ImageDisplayFormat => "2010,0010",
   AnnotationDisplayFormatID => "2010,0030",
   FilmOrientation => "2010,0040",
   FilmSizeID => "2010,0050",
   PrinterResolutionID => "2010,0052",
   DefaultPrinterResolutionID => "2010,0054",
   MagnificationType => "2010,0060",
   SmoothingType => "2010,0080",
   DefaultMagnificationType => "2010,00a6",
   OtherMagnificationTypesAvailable => "2010,00a7",
   DefaultSmoothingType => "2010,00a8",
   OtherSmoothingTypesAvailable => "2010,00a9",
   BorderDensity => "2010,0100",
   EmptyImageDensity => "2010,0110",
   MinDensity => "2010,0120",
   MaxDensity => "2010,0130",
   Trim => "2010,0140",
   ConfigurationInformation => "2010,0150",
   ConfigurationInformationDescription => "2010,0152",
   MaximumCollatedFilms => "2010,0154",
   Illumination => "2010,015e",
   ReflectedAmbientLight => "2010,0160",
   PrinterPixelSpacing => "2010,0376",
   ReferencedFilmSessionSequence => "2010,0500",
   ReferencedImageBoxSequence => "2010,0510",
   ReferencedBasicAnnotationBoxSequence => "2010,0520",
   ImageBoxPosition => "2020,0010",
   Polarity => "2020,0020",
   RequestedImageSize => "2020,0030",
   RequestedDecimateCropBehavior => "2020,0040",
   RequestedResolutionID => "2020,0050",
   RequestedImageSizeFlag => "2020,00a0",
   DecimateCropResult => "2020,00a2",
   BasicGrayscaleImageSequence => "2020,0110",
   BasicColorImageSequence => "2020,0111",
   ReferencedImageOverlayBoxSequence => "2020,0130",
   ReferencedVOILUTBoxSequence => "2020,0140",
   AnnotationPosition => "2030,0010",
   TextString => "2030,0020",
   ReferencedOverlayPlaneSequence => "2040,0010",
   ReferencedOverlayPlaneGroups => "2040,0011",
   OverlayPixelDataSequence => "2040,0020",
   OverlayMagnificationType => "2040,0060",
   OverlaySmoothingType => "2040,0070",
   OverlayOrImageMagnification => "2040,0072",
   MagnifyToNumberOfColumns => "2040,0074",
   OverlayForegroundDensity => "2040,0080",
   OverlayBackgroundDensity => "2040,0082",
   OverlayMode => "2040,0090",
   ThresholdDensity => "2040,0100",
   ReferencedImageBoxSequenceRetired => "2040,0500",
   PresentationLUTSequence => "2050,0010",
   PresentationLUTShape => "2050,0020",
   ReferencedPresentationLUTSequence => "2050,0500",
   PrintJobID => "2100,0010",
   ExecutionStatus => "2100,0020",
   ExecutionStatusInfo => "2100,0030",
   CreationDate => "2100,0040",
   CreationTime => "2100,0050",
   Originator => "2100,0070",
   DestinationAE => "2100,0140",
   OwnerID => "2100,0160",
   NumberOfFilms => "2100,0170",
   ReferencedPrintJobSequencePullStoredPrint => "2100,0500",
   PrinterStatus => "2110,0010",
   PrinterStatusInfo => "2110,0020",
   PrinterName => "2110,0030",
   PrintQueueID => "2110,0099",
   QueueStatus => "2120,0010",
   PrintJobDescriptionSequence => "2120,0050",
   ReferencedPrintJobSequence => "2120,0070",
   PrintManagementCapabilitiesSequence => "2130,0010",
   PrinterCharacteristicsSequence => "2130,0015",
   FilmBoxContentSequence => "2130,0030",
   ImageBoxContentSequence => "2130,0040",
   AnnotationContentSequence => "2130,0050",
   ImageOverlayBoxContentSequence => "2130,0060",
   PresentationLUTContentSequence => "2130,0080",
   ProposedStudySequence => "2130,00a0",
   OriginalImageSequence => "2130,00c0",
   LabelUsingInformationExtractedFromInstances => "2200,0001",
   LabelText => "2200,0002",
   LabelStyleSelection => "2200,0003",
   MediaDisposition => "2200,0004",
   BarcodeValue => "2200,0005",
   BarcodeSymbology => "2200,0006",
   AllowMediaSplitting => "2200,0007",
   IncludeNonDICOMObjects => "2200,0008",
   IncludeDisplayApplication => "2200,0009",
   PreserveCompositeInstancesAfterMediaCreation => "2200,000a",
   TotalNumberOfPiecesOfMediaCreated => "2200,000b",
   RequestedMediaApplicationProfile => "2200,000c",
   ReferencedStorageMediaSequence => "2200,000d",
   FailureAttributes => "2200,000e",
   AllowLossyCompression => "2200,000f",
   RequestPriority => "2200,0020",
   RTImageLabel => "3002,0002",
   RTImageName => "3002,0003",
   RTImageDescription => "3002,0004",
   ReportedValuesOrigin => "3002,000a",
   RTImagePlane => "3002,000c",
   XRayImageReceptorTranslation => "3002,000d",
   XRayImageReceptorAngle => "3002,000e",
   RTImageOrientation => "3002,0010",
   ImagePlanePixelSpacing => "3002,0011",
   RTImagePosition => "3002,0012",
   RadiationMachineName => "3002,0020",
   RadiationMachineSAD => "3002,0022",
   RadiationMachineSSD => "3002,0024",
   RTImageSID => "3002,0026",
   SourceToReferenceObjectDistance => "3002,0028",
   FractionNumber => "3002,0029",
   ExposureSequence => "3002,0030",
   MetersetExposure => "3002,0032",
   DiaphragmPosition => "3002,0034",
   FluenceMapSequence => "3002,0040",
   FluenceDataSource => "3002,0041",
   FluenceDataScale => "3002,0042",
   PrimaryFluenceModeSequence => "3002,0050",
   FluenceMode => "3002,0051",
   FluenceModeID => "3002,0052",
   DVHType => "3004,0001",
   DoseUnits => "3004,0002",
   DoseType => "3004,0004",
   DoseComment => "3004,0006",
   NormalizationPoint => "3004,0008",
   DoseSummationType => "3004,000a",
   GridFrameOffsetVector => "3004,000c",
   DoseGridScaling => "3004,000e",
   RTDoseROISequence => "3004,0010",
   DoseValue => "3004,0012",
   TissueHeterogeneityCorrection => "3004,0014",
   DVHNormalizationPoint => "3004,0040",
   DVHNormalizationDoseValue => "3004,0042",
   DVHSequence => "3004,0050",
   DVHDoseScaling => "3004,0052",
   DVHVolumeUnits => "3004,0054",
   DVHNumberOfBins => "3004,0056",
   DVHData => "3004,0058",
   DVHReferencedROISequence => "3004,0060",
   DVHROIContributionType => "3004,0062",
   DVHMinimumDose => "3004,0070",
   DVHMaximumDose => "3004,0072",
   DVHMeanDose => "3004,0074",
   StructureSetLabel => "3006,0002",
   StructureSetName => "3006,0004",
   StructureSetDescription => "3006,0006",
   StructureSetDate => "3006,0008",
   StructureSetTime => "3006,0009",
   ReferencedFrameOfReferenceSequence => "3006,0010",
   RTReferencedStudySequence => "3006,0012",
   RTReferencedSeriesSequence => "3006,0014",
   ContourImageSequence => "3006,0016",
   StructureSetROISequence => "3006,0020",
   ROINumber => "3006,0022",
   ReferencedFrameOfReferenceUID => "3006,0024",
   ROIName => "3006,0026",
   ROIDescription => "3006,0028",
   ROIDisplayColor => "3006,002a",
   ROIVolume => "3006,002c",
   RTRelatedROISequence => "3006,0030",
   RTROIRelationship => "3006,0033",
   ROIGenerationAlgorithm => "3006,0036",
   ROIGenerationDescription => "3006,0038",
   ROIContourSequence => "3006,0039",
   ContourSequence => "3006,0040",
   ContourGeometricType => "3006,0042",
   ContourSlabThickness => "3006,0044",
   ContourOffsetVector => "3006,0045",
   NumberOfContourPoints => "3006,0046",
   ContourNumber => "3006,0048",
   AttachedContours => "3006,0049",
   ContourData => "3006,0050",
   RTROIObservationsSequence => "3006,0080",
   ObservationNumber => "3006,0082",
   ReferencedROINumber => "3006,0084",
   ROIObservationLabel => "3006,0085",
   RTROIIdentificationCodeSequence => "3006,0086",
   ROIObservationDescription => "3006,0088",
   RelatedRTROIObservationsSequence => "3006,00a0",
   RTROIInterpretedType => "3006,00a4",
   ROIInterpreter => "3006,00a6",
   ROIPhysicalPropertiesSequence => "3006,00b0",
   ROIPhysicalProperty => "3006,00b2",
   ROIPhysicalPropertyValue => "3006,00b4",
   ROIElementalCompositionSequence => "3006,00b6",
   ROIElementalCompositionAtomicNumber => "3006,00b7",
   ROIElementalCompositionAtomicMassFraction => "3006,00b8",
   FrameOfReferenceRelationshipSequence => "3006,00c0",
   RelatedFrameOfReferenceUID => "3006,00c2",
   FrameOfReferenceTransformationType => "3006,00c4",
   FrameOfReferenceTransformationMatrix => "3006,00c6",
   FrameOfReferenceTransformationComment => "3006,00c8",
   MeasuredDoseReferenceSequence => "3008,0010",
   MeasuredDoseDescription => "3008,0012",
   MeasuredDoseType => "3008,0014",
   MeasuredDoseValue => "3008,0016",
   TreatmentSessionBeamSequence => "3008,0020",
   TreatmentSessionIonBeamSequence => "3008,0021",
   CurrentFractionNumber => "3008,0022",
   TreatmentControlPointDate => "3008,0024",
   TreatmentControlPointTime => "3008,0025",
   TreatmentTerminationStatus => "3008,002a",
   TreatmentTerminationCode => "3008,002b",
   TreatmentVerificationStatus => "3008,002c",
   ReferencedTreatmentRecordSequence => "3008,0030",
   SpecifiedPrimaryMeterset => "3008,0032",
   SpecifiedSecondaryMeterset => "3008,0033",
   DeliveredPrimaryMeterset => "3008,0036",
   DeliveredSecondaryMeterset => "3008,0037",
   SpecifiedTreatmentTime => "3008,003a",
   DeliveredTreatmentTime => "3008,003b",
   ControlPointDeliverySequence => "3008,0040",
   IonControlPointDeliverySequence => "3008,0041",
   SpecifiedMeterset => "3008,0042",
   DeliveredMeterset => "3008,0044",
   MetersetRateSet => "3008,0045",
   MetersetRateDelivered => "3008,0046",
   ScanSpotMetersetsDelivered => "3008,0047",
   DoseRateDelivered => "3008,0048",
   TreatmentSummaryCalculatedDoseReferenceSequence => "3008,0050",
   CumulativeDoseToDoseReference => "3008,0052",
   FirstTreatmentDate => "3008,0054",
   MostRecentTreatmentDate => "3008,0056",
   NumberOfFractionsDelivered => "3008,005a",
   OverrideSequence => "3008,0060",
   ParameterSequencePointer => "3008,0061",
   OverrideParameterPointer => "3008,0062",
   ParameterItemIndex => "3008,0063",
   MeasuredDoseReferenceNumber => "3008,0064",
   ParameterPointer => "3008,0065",
   OverrideReason => "3008,0066",
   CorrectedParameterSequence => "3008,0068",
   CorrectionValue => "3008,006a",
   CalculatedDoseReferenceSequence => "3008,0070",
   CalculatedDoseReferenceNumber => "3008,0072",
   CalculatedDoseReferenceDescription => "3008,0074",
   CalculatedDoseReferenceDoseValue => "3008,0076",
   StartMeterset => "3008,0078",
   EndMeterset => "3008,007a",
   ReferencedMeasuredDoseReferenceSequence => "3008,0080",
   ReferencedMeasuredDoseReferenceNumber => "3008,0082",
   ReferencedCalculatedDoseReferenceSequence => "3008,0090",
   ReferencedCalculatedDoseReferenceNumber => "3008,0092",
   BeamLimitingDeviceLeafPairsSequence => "3008,00a0",
   RecordedWedgeSequence => "3008,00b0",
   RecordedCompensatorSequence => "3008,00c0",
   RecordedBlockSequence => "3008,00d0",
   TreatmentSummaryMeasuredDoseReferenceSequence => "3008,00e0",
   RecordedSnoutSequence => "3008,00f0",
   RecordedRangeShifterSequence => "3008,00f2",
   RecordedLateralSpreadingDeviceSequence => "3008,00f4",
   RecordedRangeModulatorSequence => "3008,00f6",
   RecordedSourceSequence => "3008,0100",
   SourceSerialNumber => "3008,0105",
   TreatmentSessionApplicationSetupSequence => "3008,0110",
   ApplicationSetupCheck => "3008,0116",
   RecordedBrachyAccessoryDeviceSequence => "3008,0120",
   ReferencedBrachyAccessoryDeviceNumber => "3008,0122",
   RecordedChannelSequence => "3008,0130",
   SpecifiedChannelTotalTime => "3008,0132",
   DeliveredChannelTotalTime => "3008,0134",
   SpecifiedNumberOfPulses => "3008,0136",
   DeliveredNumberOfPulses => "3008,0138",
   SpecifiedPulseRepetitionInterval => "3008,013a",
   DeliveredPulseRepetitionInterval => "3008,013c",
   RecordedSourceApplicatorSequence => "3008,0140",
   ReferencedSourceApplicatorNumber => "3008,0142",
   RecordedChannelShieldSequence => "3008,0150",
   ReferencedChannelShieldNumber => "3008,0152",
   BrachyControlPointDeliveredSequence => "3008,0160",
   SafePositionExitDate => "3008,0162",
   SafePositionExitTime => "3008,0164",
   SafePositionReturnDate => "3008,0166",
   SafePositionReturnTime => "3008,0168",
   CurrentTreatmentStatus => "3008,0200",
   TreatmentStatusComment => "3008,0202",
   FractionGroupSummarySequence => "3008,0220",
   ReferencedFractionNumber => "3008,0223",
   FractionGroupType => "3008,0224",
   BeamStopperPosition => "3008,0230",
   FractionStatusSummarySequence => "3008,0240",
   TreatmentDate => "3008,0250",
   TreatmentTime => "3008,0251",
   RTPlanLabel => "300a,0002",
   RTPlanName => "300a,0003",
   RTPlanDescription => "300a,0004",
   RTPlanDate => "300a,0006",
   RTPlanTime => "300a,0007",
   TreatmentProtocols => "300a,0009",
   PlanIntent => "300a,000a",
   TreatmentSites => "300a,000b",
   RTPlanGeometry => "300a,000c",
   PrescriptionDescription => "300a,000e",
   DoseReferenceSequence => "300a,0010",
   DoseReferenceNumber => "300a,0012",
   DoseReferenceUID => "300a,0013",
   DoseReferenceStructureType => "300a,0014",
   NominalBeamEnergyUnit => "300a,0015",
   DoseReferenceDescription => "300a,0016",
   DoseReferencePointCoordinates => "300a,0018",
   NominalPriorDose => "300a,001a",
   DoseReferenceType => "300a,0020",
   ConstraintWeight => "300a,0021",
   DeliveryWarningDose => "300a,0022",
   DeliveryMaximumDose => "300a,0023",
   TargetMinimumDose => "300a,0025",
   TargetPrescriptionDose => "300a,0026",
   TargetMaximumDose => "300a,0027",
   TargetUnderdoseVolumeFraction => "300a,0028",
   OrganAtRiskFullVolumeDose => "300a,002a",
   OrganAtRiskLimitDose => "300a,002b",
   OrganAtRiskMaximumDose => "300a,002c",
   OrganAtRiskOverdoseVolumeFraction => "300a,002d",
   ToleranceTableSequence => "300a,0040",
   ToleranceTableNumber => "300a,0042",
   ToleranceTableLabel => "300a,0043",
   GantryAngleTolerance => "300a,0044",
   BeamLimitingDeviceAngleTolerance => "300a,0046",
   BeamLimitingDeviceToleranceSequence => "300a,0048",
   BeamLimitingDevicePositionTolerance => "300a,004a",
   SnoutPositionTolerance => "300a,004b",
   PatientSupportAngleTolerance => "300a,004c",
   TableTopEccentricAngleTolerance => "300a,004e",
   TableTopPitchAngleTolerance => "300a,004f",
   TableTopRollAngleTolerance => "300a,0050",
   TableTopVerticalPositionTolerance => "300a,0051",
   TableTopLongitudinalPositionTolerance => "300a,0052",
   TableTopLateralPositionTolerance => "300a,0053",
   RTPlanRelationship => "300a,0055",
   FractionGroupSequence => "300a,0070",
   FractionGroupNumber => "300a,0071",
   FractionGroupDescription => "300a,0072",
   NumberOfFractionsPlanned => "300a,0078",
   NumberOfFractionPatternDigitsPerDay => "300a,0079",
   RepeatFractionCycleLength => "300a,007a",
   FractionPattern => "300a,007b",
   NumberOfBeams => "300a,0080",
   BeamDoseSpecificationPoint => "300a,0082",
   BeamDose => "300a,0084",
   BeamMeterset => "300a,0086",
   BeamDosePointDepth => "300a,0088",
   BeamDosePointEquivalentDepth => "300a,0089",
   BeamDosePointSSD => "300a,008a",
   NumberOfBrachyApplicationSetups => "300a,00a0",
   BrachyApplicationSetupDoseSpecificationPoint => "300a,00a2",
   BrachyApplicationSetupDose => "300a,00a4",
   BeamSequence => "300a,00b0",
   TreatmentMachineName => "300a,00b2",
   PrimaryDosimeterUnit => "300a,00b3",
   SourceAxisDistance => "300a,00b4",
   BeamLimitingDeviceSequence => "300a,00b6",
   RTBeamLimitingDeviceType => "300a,00b8",
   SourceToBeamLimitingDeviceDistance => "300a,00ba",
   IsocenterToBeamLimitingDeviceDistance => "300a,00bb",
   NumberOfLeafJawPairs => "300a,00bc",
   LeafPositionBoundaries => "300a,00be",
   BeamNumber => "300a,00c0",
   BeamName => "300a,00c2",
   BeamDescription => "300a,00c3",
   BeamType => "300a,00c4",
   RadiationType => "300a,00c6",
   HighDoseTechniqueType => "300a,00c7",
   ReferenceImageNumber => "300a,00c8",
   PlannedVerificationImageSequence => "300a,00ca",
   ImagingDeviceSpecificAcquisitionParameters => "300a,00cc",
   TreatmentDeliveryType => "300a,00ce",
   NumberOfWedges => "300a,00d0",
   WedgeSequence => "300a,00d1",
   WedgeNumber => "300a,00d2",
   WedgeType => "300a,00d3",
   WedgeID => "300a,00d4",
   WedgeAngle => "300a,00d5",
   WedgeFactor => "300a,00d6",
   TotalWedgeTrayWaterEquivalentThickness => "300a,00d7",
   WedgeOrientation => "300a,00d8",
   IsocenterToWedgeTrayDistance => "300a,00d9",
   SourceToWedgeTrayDistance => "300a,00da",
   WedgeThinEdgePosition => "300a,00db",
   BolusID => "300a,00dc",
   BolusDescription => "300a,00dd",
   NumberOfCompensators => "300a,00e0",
   MaterialID => "300a,00e1",
   TotalCompensatorTrayFactor => "300a,00e2",
   CompensatorSequence => "300a,00e3",
   CompensatorNumber => "300a,00e4",
   CompensatorID => "300a,00e5",
   SourceToCompensatorTrayDistance => "300a,00e6",
   CompensatorRows => "300a,00e7",
   CompensatorColumns => "300a,00e8",
   CompensatorPixelSpacing => "300a,00e9",
   CompensatorPosition => "300a,00ea",
   CompensatorTransmissionData => "300a,00eb",
   CompensatorThicknessData => "300a,00ec",
   NumberOfBoli => "300a,00ed",
   CompensatorType => "300a,00ee",
   NumberOfBlocks => "300a,00f0",
   TotalBlockTrayFactor => "300a,00f2",
   TotalBlockTrayWaterEquivalentThickness => "300a,00f3",
   BlockSequence => "300a,00f4",
   BlockTrayID => "300a,00f5",
   SourceToBlockTrayDistance => "300a,00f6",
   IsocenterToBlockTrayDistance => "300a,00f7",
   BlockType => "300a,00f8",
   AccessoryCode => "300a,00f9",
   BlockDivergence => "300a,00fa",
   BlockMountingPosition => "300a,00fb",
   BlockNumber => "300a,00fc",
   BlockName => "300a,00fe",
   BlockThickness => "300a,0100",
   BlockTransmission => "300a,0102",
   BlockNumberOfPoints => "300a,0104",
   BlockData => "300a,0106",
   ApplicatorSequence => "300a,0107",
   ApplicatorID => "300a,0108",
   ApplicatorType => "300a,0109",
   ApplicatorDescription => "300a,010a",
   CumulativeDoseReferenceCoefficient => "300a,010c",
   FinalCumulativeMetersetWeight => "300a,010e",
   NumberOfControlPoints => "300a,0110",
   ControlPointSequence => "300a,0111",
   ControlPointIndex => "300a,0112",
   NominalBeamEnergy => "300a,0114",
   DoseRateSet => "300a,0115",
   WedgePositionSequence => "300a,0116",
   WedgePosition => "300a,0118",
   BeamLimitingDevicePositionSequence => "300a,011a",
   LeafJawPositions => "300a,011c",
   GantryAngle => "300a,011e",
   GantryRotationDirection => "300a,011f",
   BeamLimitingDeviceAngle => "300a,0120",
   BeamLimitingDeviceRotationDirection => "300a,0121",
   PatientSupportAngle => "300a,0122",
   PatientSupportRotationDirection => "300a,0123",
   TableTopEccentricAxisDistance => "300a,0124",
   TableTopEccentricAngle => "300a,0125",
   TableTopEccentricRotationDirection => "300a,0126",
   TableTopVerticalPosition => "300a,0128",
   TableTopLongitudinalPosition => "300a,0129",
   TableTopLateralPosition => "300a,012a",
   IsocenterPosition => "300a,012c",
   SurfaceEntryPoint => "300a,012e",
   SourceToSurfaceDistance => "300a,0130",
   CumulativeMetersetWeight => "300a,0134",
   TableTopPitchAngle => "300a,0140",
   TableTopPitchRotationDirection => "300a,0142",
   TableTopRollAngle => "300a,0144",
   TableTopRollRotationDirection => "300a,0146",
   HeadFixationAngle => "300a,0148",
   GantryPitchAngle => "300a,014a",
   GantryPitchRotationDirection => "300a,014c",
   GantryPitchAngleTolerance => "300a,014e",
   PatientSetupSequence => "300a,0180",
   PatientSetupNumber => "300a,0182",
   PatientSetupLabel => "300a,0183",
   PatientAdditionalPosition => "300a,0184",
   FixationDeviceSequence => "300a,0190",
   FixationDeviceType => "300a,0192",
   FixationDeviceLabel => "300a,0194",
   FixationDeviceDescription => "300a,0196",
   FixationDevicePosition => "300a,0198",
   FixationDevicePitchAngle => "300a,0199",
   FixationDeviceRollAngle => "300a,019a",
   ShieldingDeviceSequence => "300a,01a0",
   ShieldingDeviceType => "300a,01a2",
   ShieldingDeviceLabel => "300a,01a4",
   ShieldingDeviceDescription => "300a,01a6",
   ShieldingDevicePosition => "300a,01a8",
   SetupTechnique => "300a,01b0",
   SetupTechniqueDescription => "300a,01b2",
   SetupDeviceSequence => "300a,01b4",
   SetupDeviceType => "300a,01b6",
   SetupDeviceLabel => "300a,01b8",
   SetupDeviceDescription => "300a,01ba",
   SetupDeviceParameter => "300a,01bc",
   SetupReferenceDescription => "300a,01d0",
   TableTopVerticalSetupDisplacement => "300a,01d2",
   TableTopLongitudinalSetupDisplacement => "300a,01d4",
   TableTopLateralSetupDisplacement => "300a,01d6",
   BrachyTreatmentTechnique => "300a,0200",
   BrachyTreatmentType => "300a,0202",
   TreatmentMachineSequence => "300a,0206",
   SourceSequence => "300a,0210",
   SourceNumber => "300a,0212",
   SourceType => "300a,0214",
   SourceManufacturer => "300a,0216",
   ActiveSourceDiameter => "300a,0218",
   ActiveSourceLength => "300a,021a",
   SourceEncapsulationNominalThickness => "300a,0222",
   SourceEncapsulationNominalTransmission => "300a,0224",
   SourceIsotopeName => "300a,0226",
   SourceIsotopeHalfLife => "300a,0228",
   SourceStrengthUnits => "300a,0229",
   ReferenceAirKermaRate => "300a,022a",
   SourceStrength => "300a,022b",
   SourceStrengthReferenceDate => "300a,022c",
   SourceStrengthReferenceTime => "300a,022e",
   ApplicationSetupSequence => "300a,0230",
   ApplicationSetupType => "300a,0232",
   ApplicationSetupNumber => "300a,0234",
   ApplicationSetupName => "300a,0236",
   ApplicationSetupManufacturer => "300a,0238",
   TemplateNumber => "300a,0240",
   TemplateType => "300a,0242",
   TemplateName => "300a,0244",
   TotalReferenceAirKerma => "300a,0250",
   BrachyAccessoryDeviceSequence => "300a,0260",
   BrachyAccessoryDeviceNumber => "300a,0262",
   BrachyAccessoryDeviceID => "300a,0263",
   BrachyAccessoryDeviceType => "300a,0264",
   BrachyAccessoryDeviceName => "300a,0266",
   BrachyAccessoryDeviceNominalThickness => "300a,026a",
   BrachyAccessoryDeviceNominalTransmission => "300a,026c",
   ChannelSequence => "300a,0280",
   ChannelNumber => "300a,0282",
   ChannelLength => "300a,0284",
   ChannelTotalTime => "300a,0286",
   SourceMovementType => "300a,0288",
   NumberOfPulses => "300a,028a",
   PulseRepetitionInterval => "300a,028c",
   SourceApplicatorNumber => "300a,0290",
   SourceApplicatorID => "300a,0291",
   SourceApplicatorType => "300a,0292",
   SourceApplicatorName => "300a,0294",
   SourceApplicatorLength => "300a,0296",
   SourceApplicatorManufacturer => "300a,0298",
   SourceApplicatorWallNominalThickness => "300a,029c",
   SourceApplicatorWallNominalTransmission => "300a,029e",
   SourceApplicatorStepSize => "300a,02a0",
   TransferTubeNumber => "300a,02a2",
   TransferTubeLength => "300a,02a4",
   ChannelShieldSequence => "300a,02b0",
   ChannelShieldNumber => "300a,02b2",
   ChannelShieldID => "300a,02b3",
   ChannelShieldName => "300a,02b4",
   ChannelShieldNominalThickness => "300a,02b8",
   ChannelShieldNominalTransmission => "300a,02ba",
   FinalCumulativeTimeWeight => "300a,02c8",
   BrachyControlPointSequence => "300a,02d0",
   ControlPointRelativePosition => "300a,02d2",
   ControlPoint3DPosition => "300a,02d4",
   CumulativeTimeWeight => "300a,02d6",
   CompensatorDivergence => "300a,02e0",
   CompensatorMountingPosition => "300a,02e1",
   SourceToCompensatorDistance => "300a,02e2",
   TotalCompensatorTrayWaterEquivalentThickness => "300a,02e3",
   IsocenterToCompensatorTrayDistance => "300a,02e4",
   CompensatorColumnOffset => "300a,02e5",
   IsocenterToCompensatorDistances => "300a,02e6",
   CompensatorRelativeStoppingPowerRatio => "300a,02e7",
   CompensatorMillingToolDiameter => "300a,02e8",
   IonRangeCompensatorSequence => "300a,02ea",
   CompensatorDescription => "300a,02eb",
   RadiationMassNumber => "300a,0302",
   RadiationAtomicNumber => "300a,0304",
   RadiationChargeState => "300a,0306",
   ScanMode => "300a,0308",
   VirtualSourceAxisDistances => "300a,030a",
   SnoutSequence => "300a,030c",
   SnoutPosition => "300a,030d",
   SnoutID => "300a,030f",
   NumberOfRangeShifters => "300a,0312",
   RangeShifterSequence => "300a,0314",
   RangeShifterNumber => "300a,0316",
   RangeShifterID => "300a,0318",
   RangeShifterType => "300a,0320",
   RangeShifterDescription => "300a,0322",
   NumberOfLateralSpreadingDevices => "300a,0330",
   LateralSpreadingDeviceSequence => "300a,0332",
   LateralSpreadingDeviceNumber => "300a,0334",
   LateralSpreadingDeviceID => "300a,0336",
   LateralSpreadingDeviceType => "300a,0338",
   LateralSpreadingDeviceDescription => "300a,033a",
   LateralSpreadingDeviceWaterEquivalentThickness => "300a,033c",
   NumberOfRangeModulators => "300a,0340",
   RangeModulatorSequence => "300a,0342",
   RangeModulatorNumber => "300a,0344",
   RangeModulatorID => "300a,0346",
   RangeModulatorType => "300a,0348",
   RangeModulatorDescription => "300a,034a",
   BeamCurrentModulationID => "300a,034c",
   PatientSupportType => "300a,0350",
   PatientSupportID => "300a,0352",
   PatientSupportAccessoryCode => "300a,0354",
   FixationLightAzimuthalAngle => "300a,0356",
   FixationLightPolarAngle => "300a,0358",
   MetersetRate => "300a,035a",
   RangeShifterSettingsSequence => "300a,0360",
   RangeShifterSetting => "300a,0362",
   IsocenterToRangeShifterDistance => "300a,0364",
   RangeShifterWaterEquivalentThickness => "300a,0366",
   LateralSpreadingDeviceSettingsSequence => "300a,0370",
   LateralSpreadingDeviceSetting => "300a,0372",
   IsocenterToLateralSpreadingDeviceDistance => "300a,0374",
   RangeModulatorSettingsSequence => "300a,0380",
   RangeModulatorGatingStartValue => "300a,0382",
   RangeModulatorGatingStopValue => "300a,0384",
   RangeModulatorGatingStartWaterEquivalentThickness => "300a,0386",
   RangeModulatorGatingStopWaterEquivalentThickness => "300a,0388",
   IsocenterToRangeModulatorDistance => "300a,038a",
   ScanSpotTuneID => "300a,0390",
   NumberOfScanSpotPositions => "300a,0392",
   ScanSpotPositionMap => "300a,0394",
   ScanSpotMetersetWeights => "300a,0396",
   ScanningSpotSize => "300a,0398",
   NumberOfPaintings => "300a,039a",
   IonToleranceTableSequence => "300a,03a0",
   IonBeamSequence => "300a,03a2",
   IonBeamLimitingDeviceSequence => "300a,03a4",
   IonBlockSequence => "300a,03a6",
   IonControlPointSequence => "300a,03a8",
   IonWedgeSequence => "300a,03aa",
   IonWedgePositionSequence => "300a,03ac",
   ReferencedSetupImageSequence => "300a,0401",
   SetupImageComment => "300a,0402",
   MotionSynchronizationSequence => "300a,0410",
   ControlPointOrientation => "300a,0412",
   GeneralAccessorySequence => "300a,0420",
   GeneralAccessoryID => "300a,0421",
   GeneralAccessoryDescription => "300a,0422",
   GeneralAccessoryType => "300a,0423",
   GeneralAccessoryNumber => "300a,0424",
   ReferencedRTPlanSequence => "300c,0002",
   ReferencedBeamSequence => "300c,0004",
   ReferencedBeamNumber => "300c,0006",
   ReferencedReferenceImageNumber => "300c,0007",
   StartCumulativeMetersetWeight => "300c,0008",
   EndCumulativeMetersetWeight => "300c,0009",
   ReferencedBrachyApplicationSetupSequence => "300c,000a",
   ReferencedBrachyApplicationSetupNumber => "300c,000c",
   ReferencedSourceNumber => "300c,000e",
   ReferencedFractionGroupSequence => "300c,0020",
   ReferencedFractionGroupNumber => "300c,0022",
   ReferencedVerificationImageSequence => "300c,0040",
   ReferencedReferenceImageSequence => "300c,0042",
   ReferencedDoseReferenceSequence => "300c,0050",
   ReferencedDoseReferenceNumber => "300c,0051",
   BrachyReferencedDoseReferenceSequence => "300c,0055",
   ReferencedStructureSetSequence => "300c,0060",
   ReferencedPatientSetupNumber => "300c,006a",
   ReferencedDoseSequence => "300c,0080",
   ReferencedToleranceTableNumber => "300c,00a0",
   ReferencedBolusSequence => "300c,00b0",
   ReferencedWedgeNumber => "300c,00c0",
   ReferencedCompensatorNumber => "300c,00d0",
   ReferencedBlockNumber => "300c,00e0",
   ReferencedControlPointIndex => "300c,00f0",
   ReferencedControlPointSequence => "300c,00f2",
   ReferencedStartControlPointIndex => "300c,00f4",
   ReferencedStopControlPointIndex => "300c,00f6",
   ReferencedRangeShifterNumber => "300c,0100",
   ReferencedLateralSpreadingDeviceNumber => "300c,0102",
   ReferencedRangeModulatorNumber => "300c,0104",
   ApprovalStatus => "300e,0002",
   ReviewDate => "300e,0004",
   ReviewTime => "300e,0005",
   ReviewerName => "300e,0008",
   Arbitrary => "4000,0010",
   TextComments => "4000,4000",
   ResultsID => "4008,0040",
   ResultsIDIssuer => "4008,0042",
   ReferencedInterpretationSequence => "4008,0050",
   InterpretationRecordedDate => "4008,0100",
   InterpretationRecordedTime => "4008,0101",
   InterpretationRecorder => "4008,0102",
   ReferenceToRecordedSound => "4008,0103",
   InterpretationTranscriptionDate => "4008,0108",
   InterpretationTranscriptionTime => "4008,0109",
   InterpretationTranscriber => "4008,010a",
   InterpretationText => "4008,010b",
   InterpretationAuthor => "4008,010c",
   InterpretationApproverSequence => "4008,0111",
   InterpretationApprovalDate => "4008,0112",
   InterpretationApprovalTime => "4008,0113",
   PhysicianApprovingInterpretation => "4008,0114",
   InterpretationDiagnosisDescription => "4008,0115",
   InterpretationDiagnosisCodeSequence => "4008,0117",
   ResultsDistributionListSequence => "4008,0118",
   DistributionName => "4008,0119",
   DistributionAddress => "4008,011a",
   InterpretationID => "4008,0200",
   InterpretationIDIssuer => "4008,0202",
   InterpretationTypeID => "4008,0210",
   InterpretationStatusID => "4008,0212",
   Impressions => "4008,0300",
   ResultsComments => "4008,4000",
   MACParametersSequence => "4ffe,0001",
   CurveDimensions => "50xx,0005",
   NumberOfPoints => "50xx,0010",
   TypeOfData => "50xx,0020",
   CurveDescription => "50xx,0022",
   AxisUnits => "50xx,0030",
   AxisLabels => "50xx,0040",
   DataValueRepresentation => "50xx,0103",
   MinimumCoordinateValue => "50xx,0104",
   MaximumCoordinateValue => "50xx,0105",
   CurveRange => "50xx,0106",
   CurveDataDescriptor => "50xx,0110",
   CoordinateStartValue => "50xx,0112",
   CoordinateStepValue => "50xx,0114",
   CurveActivationLayer => "50xx,1001",
   AudioType => "50xx,2000",
   AudioSampleFormat => "50xx,2002",
   NumberOfChannels => "50xx,2004",
   NumberOfSamples => "50xx,2006",
   SampleRate => "50xx,2008",
   TotalTime => "50xx,200a",
   AudioSampleData => "50xx,200c",
   AudioComments => "50xx,200e",
   CurveLabel => "50xx,2500",
   CurveReferencedOverlaySequence => "50xx,2600",
   CurveReferencedOverlayGroup => "50xx,2610",
   CurveData => "50xx,3000",
   SharedFunctionalGroupsSequence => "5200,9229",
   PerFrameFunctionalGroupsSequence => "5200,9230",
   WaveformSequence => "5400,0100",
   ChannelMinimumValue => "5400,0110",
   ChannelMaximumValue => "5400,0112",
   WaveformBitsAllocated => "5400,1004",
   WaveformSampleInterpretation => "5400,1006",
   WaveformPaddingValue => "5400,100a",
   WaveformData => "5400,1010",
   FirstOrderPhaseCorrectionAngle => "5600,0010",
   SpectroscopyData => "5600,0020",
   OverlayRows => "60xx,0010",
   OverlayColumns => "60xx,0011",
   OverlayPlanes => "60xx,0012",
   NumberOfFramesInOverlay => "60xx,0015",
   OverlayDescription => "60xx,0022",
   OverlayType => "60xx,0040",
   OverlaySubtype => "60xx,0045",
   OverlayOrigin => "60xx,0050",
   ImageFrameOrigin => "60xx,0051",
   OverlayPlaneOrigin => "60xx,0052",
   OverlayCompressionCode => "60xx,0060",
   OverlayCompressionOriginator => "60xx,0061",
   OverlayCompressionLabel => "60xx,0062",
   OverlayCompressionDescription => "60xx,0063",
   OverlayCompressionStepPointers => "60xx,0066",
   OverlayRepeatInterval => "60xx,0068",
   OverlayBitsGrouped => "60xx,0069",
   OverlayBitsAllocated => "60xx,0100",
   OverlayBitPosition => "60xx,0102",
   OverlayFormat => "60xx,0110",
   OverlayLocation => "60xx,0200",
   OverlayCodeLabel => "60xx,0800",
   OverlayNumberOfTables => "60xx,0802",
   OverlayCodeTableLocation => "60xx,0803",
   OverlayBitsForCodeWord => "60xx,0804",
   OverlayActivationLayer => "60xx,1001",
   OverlayDescriptorGray => "60xx,1100",
   OverlayDescriptorRed => "60xx,1101",
   OverlayDescriptorGreen => "60xx,1102",
   OverlayDescriptorBlue => "60xx,1103",
   OverlaysGray => "60xx,1200",
   OverlaysRed => "60xx,1201",
   OverlaysGreen => "60xx,1202",
   OverlaysBlue => "60xx,1203",
   ROIArea => "60xx,1301",
   ROIMean => "60xx,1302",
   ROIStandardDeviation => "60xx,1303",
   OverlayLabel => "60xx,1500",
   OverlayData => "60xx,3000",
   OverlayComments => "60xx,4000",
   PixelData => "7fe0,0010",
   CoefficientsSDVN => "7fe0,0020",
   CoefficientsSDHN => "7fe0,0030",
   CoefficientsSDDN => "7fe0,0040",
   VariablePixelData => "7fxx,0010",
   VariableNextDataGroup => "7fxx,0011",
   VariableCoefficientsSDVN => "7fxx,0020",
   VariableCoefficientsSDHN => "7fxx,0030",
   VariableCoefficientsSDDN => "7fxx,0040",
   DigitalSignaturesSequence => "fffa,fffa",
   DataSetTrailingPadding => "fffc,fffc",
};

# get a tag description. Input parameter: Dicom tag ID or name.
sub getTagDesc
{
    my $tagID = shift;
    my $tag = getTag($tagID);
    if(defined $tag)
    {
       return $tag->{desc};
    }
    return "Private";
}

# get a tag ID. Input parameter: Dicom tag ID or name
sub getTagID
{
    my $tagName = shift;
    if(defined $DicomTagNameList->{$tagName})
    {
        return $DicomTagNameList->{$tagName};
    }
    else
    {
	return lc($tagName) if($tagName =~ /^[0-9A-Fa-f]{4},[0-9A-Fa-f]{4}$/);
    }
    return undef; 
}

# get a tag structure. Input parameter: Dicom tag ID or name
sub getTag
{
    my $tagID = shift;

    if($tagID !~ /^[0-9A-Fa-f]{4},[0-9A-Fa-f]{4}$/ and defined $DicomTagNameList->{$tagID})
    {
        $tagID = $DicomTagNameList->{$tagID};
    }

    $tagID = lc($tagID);
    if(defined $DicomTagList->{$tagID})
    {
        return $DicomTagList->{$tagID};
    }
    else
    {
        if($tagID =~ /^0020,31/) # (0020,31xx)
        {
            $tagID = "0020,31xx";
            if(defined $DicomTagList->{$tagID})
            {
               return $DicomTagList->{$tagID};
            }
        }
	elsif($tagID =~ /^(0028,04)(.)([0-3])$/) # (0028,04x0), (0028,04x1), (0028,04x2), (0028,04x3)
	{
	    $tagID = $1."x".$3;
	    if(defined $DicomTagList->{$tagID})
	    {
		return $DicomTagList->{$tagID};
	    }
	}
	elsif($tagID =~ /^(0028,08)(.)([02-48])$/) # (0028,08x0), (0028,08x2), (0028,08x3), (0028,08x4), (0028,08x8)
	{
            $tagID = $1."x".$3;
            if(defined $DicomTagList->{$tagID})
            {
                return $DicomTagList->{$tagID};
            }
	}
        elsif($tagID =~ /^(50)(.{2})(,.{4})$/ or 
	      $tagID =~ /^(60)(.{2})(,.{4})$/)  # (50xx,yyyy) or (60xx,yyyy)
        {
            $tagID = $1."xx".$3;
            if(defined $DicomTagList->{$tagID})
            {
                return $DicomTagList->{$tagID};
            }
        }
        elsif($tagID =~ /^(1000,)(.{3})([0-5])$/)  # (1000,xxx[0-5])
        {
            $tagID = $1."xxx".$3;
            if(defined $DicomTagList->{$tagID})
            {
                return $DicomTagList->{$tagID};
            }
        }
        elsif($tagID =~ /^1010,/)  # (1010,xxxx)
        {
            $tagID = "1010,xxxx";
            if(defined $DicomTagList->{$tagID})
            {
                return $DicomTagList->{$tagID};
            }
        }
        elsif($tagID =~ /^(7f)(.{2})(,.{4})$/)  # (7fxx,0010), (7fxx,0011), (7fxx,0020), (7fxx,0030), (7fxx,0040)
        {
            $tagID = $1."xx".$3;
            if(defined $DicomTagList->{$tagID})
            {
                return $DicomTagList->{$tagID};
            }
        }

        return undef;
    }
}

1;

__END__

=head1 NAME

DicomTagDict - Dicom Data Dictionary

=head1 SYNOPSIS

References: DICOM PS 3.6-2009 (Part 6: Data Dictionary)

=head1 DESCRIPTION

This module contains information about Dicom Data Dictionary.

=head2 Methods

=over 12

=item C<getTagDesc>

Get a tag description.

=over 4

=item Input Parameter(s):

=over 4

=item 1.

A Dicom tag ID (e.g., "0010,0010") or tag name (e.g., "PatientName").
Tag ID is case-insensitive and Tag Name is case-sensitive.

=back

=item Return Value:

The description of a specified Dicom tag.

=back

=item C<getTagID>

Get a tag ID.

=over 4

=item Input Parameter(s):

=over 4

=item 1.

A Dicom tag ID (e.g., "0010,0010") or tag name (e.g., "PatientName").
Tag ID is case-insensitive and Tag Name is case-sensitive.

=back

=item Return Value:

The Tag ID of a specified Dicom tag.

=back

=item C<getTag>

Get information about a Dicom tag ID.

=over 4

=item Input Parameter(s):

=over 4

=item 1.

A Dicom tag ID (e.g., "0010,0010") or tag name (e.g., "PatientName").
Tag ID is case-insensitive and Tag Name is case-sensitive.

=back

=item Return Value:

A hash reference pointing to the information about a specified Dicom tag.

=back

=back

=head1 AUTHORS

Baoshe Zhang, MCV Medical School, Virginia Commonwealth University

=cut

