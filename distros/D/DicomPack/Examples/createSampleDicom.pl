# a sample demo program to create a CT image.

use strict;

use lib "../";
use DicomPack::IO::DicomWriter;

my $writer = DicomPack::IO::DicomWriter->new();

$writer->setValue("TransferSyntaxUID", "1.2.840.10008.1.2.1", "UI");

$writer->setValue("StudyDate", "20100520", "DA");
$writer->setValue("StudyTime", "072709", "TM");

$writer->setValue("PatientName", "Demo", "PN");
$writer->setValue("PatientID", "123Test");

$writer->setValue("0021,0012/x/PerformingPhysicianName", "Monkey");
$writer->setValue("0021,0012/0/NameOfPhysiciansReadingStudy", "Donkey");

$writer->setValue("Modality", "CT", "CS");

$writer->setValue("ImagePositionPatient", [-10.10, 10.3, 20.555], "DS");
$writer->setValue("ImageOrientationPatient", [1, 0.0, 0.0, 0.0, 0.0, -1.00], "DS");

$writer->setValue("Rows", 100, "US");
$writer->setValue("Columns", 100, "US");

$writer->setValue("SliceThickness", 1.0, "DS");
$writer->setValue("PixelSpacing", [1, 1], "DS");
$writer->setValue("BitsAllocated", 16, "US");
$writer->setValue("BitsStored", 16, "US");
$writer->setValue("HighBit", 15, "US");

my $value;

for(my $i=0; $i<100; $i++)
{
  for(my $j=0; $j<100; $j++)
  {
      my $index = $i*100 + $j;
      $value->[$index] = $i + $j;
  }
}

$writer->setValue("7fe0,0010", $value, "OB");

$writer->flush("sample.dcm");
