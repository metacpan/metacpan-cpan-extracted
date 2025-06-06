#!/usr/bin/env perl

use strict;
use warnings;

use Dicom::DCMTK::DCMDump::Get;
use File::Temp qw(tempfile);
use IO::Barf qw(barf);
use MIME::Base64::Perl qw(decode_base64);

# Object.
my $obj = Dicom::DCMTK::DCMDump::Get->new;

# Fake DICOM file.
my $dicom_data = <<'END';
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAABESUNNAgAAAFVMBADIAAAAAgABAE9CAAACAAAAAAECAAIAVUkaADEuMi4y
NzYuMC43MjMwMDEwLjMuMS4wLjEAAgADAFVJOAAxLjIuMjc2LjAuNzIzMDAxMC4zLjEuNC44MzIz
MzI5LjE5MTQ1LjE0MDkwNDI2NzUuODkyOTU4AAIAEABVSRQAMS4yLjg0MC4xMDAwOC4xLjIuMQAC
ABIAVUkcADEuMi4yNzYuMC43MjMwMDEwLjMuMC4zLjYuMAACABMAU0gQAE9GRklTX0RDTVRLXzM2
MCAIAAUAQ1MKAElTT19JUiAxMDAIAFAAU0gGADAwMDAwMAgAgABMTwgAU2tpbS5jeiAIAJAAUE4O
AFNpbmNsYWlyXlR5bGVyCAAQEVNRAAAAAAAACAAgEVNRAAAAAAAAEAAQAFBOEABUZXJyZWxsXlN0
ZXBoZW4gEAAgAExPCgBQNjIzNTU2NTk5EAAwAERBCAAxOTQzMDIxMRAAQABDUwIATSAQAAAgTE8K
AE1FVEFTVEFTSVMQABAhTE8GAFRBTlRBTBAAAEBMVBAAUGF0aWVudCBjb21tZW50ICAADQBVSSgA
MS4yLjI3Ni4wLjcyMzAwMTAuMS4yLjEuMS4xLjIuMTQwOTA0MjY3NTIAMhBQTgwASXZlcnNeU3Rl
dmVuMgBgEExPBgBFWEFNNiBAAAABU1EAALQAAAD+/wDgrAAAAAgAYABDUwIARVMyAHAQTE8MAEJB
UklVTVNVTEZBVEAAAQBBRQwARm9vIHN0YXRpb24gQAACAERBCAAyMDE0MDgyNkAAAwBUTQYAMDg1
NjA3QAAGAFBOCgBDcm9zc15KYWNrQAAHAExPBgBFeGFtNDdAAAkAU0gIAFNQRDM0NDUgQAAQAFNI
BgBTVE40NTZAABEAU0gGAEIzNEY1NkAAEgBMTwAAQAAABExUAABAAFQCTE8kAFBlcmZvcm1lZCBQ
cm9jZWR1cmUgU3RlcCBEZXNjcmlwdGlvbkAAARBTSAwAUlA0NTRHMjM0IG9rQAADEFNIBABMT1cg
END
my (undef, $dicom_file) = tempfile();
barf($dicom_file, decode_base64($dicom_data));

# Get dcmdump output.
my $dcmdump = $obj->get($dicom_file);

# Clean.
unlink $dicom_file;

# Print out.
print $dcmdump."\n";

# Output:
# 
# # Dicom-File-Format
# 
# # Dicom-Meta-Information-Header
# # Used TransferSyntax: Little Endian Explicit
# (0002,0000) UL 200                                      #   4, 1 FileMetaInformationGroupLength
# (0002,0001) OB 00\01                                    #   2, 1 FileMetaInformationVersion
# (0002,0002) UI [1.2.276.0.7230010.3.1.0.1]              #  26, 1 MediaStorageSOPClassUID
# (0002,0003) UI [1.2.276.0.7230010.3.1.4.8323329.19145.1409042675.892958] #  56, 1 MediaStorageSOPInstanceUID
# (0002,0010) UI =LittleEndianExplicit                    #  20, 1 TransferSyntaxUID
# (0002,0012) UI [1.2.276.0.7230010.3.0.3.6.0]            #  28, 1 ImplementationClassUID
# (0002,0013) SH [OFFIS_DCMTK_360]                        #  16, 1 ImplementationVersionName
# 
# # Dicom-Data-Set
# # Used TransferSyntax: Little Endian Explicit
# (0008,0005) CS [ISO_IR 100]                             #  10, 1 SpecificCharacterSet
# (0008,0050) SH [000000]                                 #   6, 1 AccessionNumber
# (0008,0080) LO [Skim.cz]                                #   8, 1 InstitutionName
# (0008,0090) PN [Sinclair^Tyler]                         #  14, 1 ReferringPhysicianName
# (0008,1110) SQ (Sequence with explicit length #=0)      #   0, 1 ReferencedStudySequence
# (fffe,e0dd) na (SequenceDelimitationItem for re-encod.) #   0, 0 SequenceDelimitationItem
# (0008,1120) SQ (Sequence with explicit length #=0)      #   0, 1 ReferencedPatientSequence
# (fffe,e0dd) na (SequenceDelimitationItem for re-encod.) #   0, 0 SequenceDelimitationItem
# (0010,0010) PN [Terrell^Stephen]                        #  16, 1 PatientName
# (0010,0020) LO [P623556599]                             #  10, 1 PatientID
# (0010,0030) DA [19430211]                               #   8, 1 PatientBirthDate
# (0010,0040) CS [M]                                      #   2, 1 PatientSex
# (0010,2000) LO [METASTASIS]                             #  10, 1 MedicalAlerts
# (0010,2110) LO [TANTAL]                                 #   6, 1 Allergies
# (0010,4000) LT [Patient comment]                        #  16, 1 PatientComments
# (0020,000d) UI [1.2.276.0.7230010.1.2.1.1.1.2.1409042675] #  40, 1 StudyInstanceUID
# (0032,1032) PN [Ivers^Steven]                           #  12, 1 RequestingPhysician
# (0032,1060) LO [EXAM6]                                  #   6, 1 RequestedProcedureDescription
# (0040,0100) SQ (Sequence with explicit length #=1)      # 180, 1 ScheduledProcedureStepSequence
#   (fffe,e000) na (Item with explicit length #=12)         # 172, 1 Item
#     (0008,0060) CS [ES]                                     #   2, 1 Modality
#     (0032,1070) LO [BARIUMSULFAT]                           #  12, 1 RequestedContrastAgent
#     (0040,0001) AE [Foo station]                            #  12, 1 ScheduledStationAETitle
#     (0040,0002) DA [20140826]                               #   8, 1 ScheduledProcedureStepStartDate
#     (0040,0003) TM [085607]                                 #   6, 1 ScheduledProcedureStepStartTime
#     (0040,0006) PN [Cross^Jack]                             #  10, 1 ScheduledPerformingPhysicianName
#     (0040,0007) LO [Exam47]                                 #   6, 1 ScheduledProcedureStepDescription
#     (0040,0009) SH [SPD3445]                                #   8, 1 ScheduledProcedureStepID
#     (0040,0010) SH [STN456]                                 #   6, 1 ScheduledStationName
#     (0040,0011) SH [B34F56]                                 #   6, 1 ScheduledProcedureStepLocation
#     (0040,0012) LO (no value available)                     #   0, 0 PreMedication
#     (0040,0400) LT (no value available)                     #   0, 0 CommentsOnTheScheduledProcedureStep
#   (fffe,e00d) na (ItemDelimitationItem for re-encoding)   #   0, 0 ItemDelimitationItem
# (fffe,e0dd) na (SequenceDelimitationItem for re-encod.) #   0, 0 SequenceDelimitationItem
# (0040,0254) LO [Performed Procedure Step Description]   #  36, 1 PerformedProcedureStepDescription
# (0040,1001) SH [RP454G234 ok]                           #  12, 1 RequestedProcedureID
# (0040,1003) SH [LOW]                                    #   4, 1 RequestedProcedurePriority