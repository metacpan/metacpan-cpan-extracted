#!/usr/local/bin/perl -w
#
use Graphics::VTK;

# Test marching cubes speed
$v16 = Graphics::VTK::Volume16Reader->new;
$v16->SetDataDimensions(64,64);
$v16->GetOutput->SetOrigin(0.0,0.0,0.0);
$v16->SetDataByteOrderToLittleEndian;
$v16->SetFilePrefix("../../../vtkdata/headsq/quarter");
$v16->SetImageRange(1,93);
$v16->SetDataSpacing(3.2,3.2,1.5);
$v16->Update;
$iso = Graphics::VTK::ContourFilter->new;
$iso->SetInput($v16->GetOutput);
$iso->SetValue(0,1150);
$t = sprintf("%6.2f",($time->iso_Update(1))[0] / 1000000.0);
print("$t seconds");
exit();
