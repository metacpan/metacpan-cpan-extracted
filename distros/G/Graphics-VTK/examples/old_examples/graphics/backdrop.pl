#!/usr/local/bin/perl -w
#
use Graphics::VTK;

#
sub BuildBackdrop
{
 my $minX = shift;
 my $maxX = shift;
 my $minY = shift;
 my $maxY = shift;
 my $minZ = shift;
 my $maxZ = shift;
 my $thickness = shift;
 my $back;
 my $backMapper;
 my $backPlane;
 my $base;
 my $baseMapper;
 my $basePlane;
 my $left;
 my $leftMapper;
 my $leftPlane;
 $basePlane = Graphics::VTK::CubeSource->new if (!defined($basePlane));
 $basePlane->SetCenter(($maxX + $minX) / 2.0,$minY,($maxZ + $minZ) / 2.0);
 $basePlane->SetXLength(($maxX - $minX));
 $basePlane->SetYLength($thickness);
 $basePlane->SetZLength(($maxZ - $minZ));
 $baseMapper = Graphics::VTK::PolyDataMapper->new if (!defined($baseMapper));
 $baseMapper->SetInput($basePlane->GetOutput);
 $base = Graphics::VTK::Actor->new if (!defined($base));
 $base->SetMapper($baseMapper);
 $backPlane = Graphics::VTK::CubeSource->new if (!defined($backPlane));
 $backPlane->SetCenter(($maxX + $minX) / 2.0,($maxY + $minY) / 2.0,$minZ);
 $backPlane->SetXLength(($maxX - $minX));
 $backPlane->SetYLength(($maxY - $minY));
 $backPlane->SetZLength($thickness);
 $backMapper = Graphics::VTK::PolyDataMapper->new if (!defined($backMapper));
 $backMapper->SetInput($backPlane->GetOutput);
 $back = Graphics::VTK::Actor->new if (!defined($back));
 $back->SetMapper($backMapper);
 $leftPlane = Graphics::VTK::CubeSource->new if (!defined($leftPlane));
 $leftPlane->SetCenter($minX,($maxY + $minY) / 2.0,($maxZ + $minZ) / 2.0);
 $leftPlane->SetXLength($thickness);
 $leftPlane->SetYLength(($maxY - $minY));
 $leftPlane->SetZLength(($maxZ - $minZ));
 $leftMapper = Graphics::VTK::PolyDataMapper->new if (!defined($leftMapper));
 $leftMapper->SetInput($leftPlane->GetOutput);
 $left = Graphics::VTK::Actor->new if (!defined($left));
 $left->SetMapper($leftMapper);
}
