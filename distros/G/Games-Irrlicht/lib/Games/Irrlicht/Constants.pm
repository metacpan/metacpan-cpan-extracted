
# Constants - make Irrlicht constants and enums available

package Games::Irrlicht::Constants;

# (C) by Tels <http://bloodgate.com/>

use strict;
require Exporter;
use vars qw/$VERSION @ISA @EXPORT/;
BEGIN
  {
  @ISA = qw/Exporter/;
  }
$VERSION = '0.01';

use constant EDT_NULL => 0;
use constant EDT_SOFTWARE => 1;
use constant EDT_DIRECTX8 => 2;
use constant EDT_DIRECTX9 => 3;
use constant EDT_OPENGL => 4;

# enum ECOLOR_FORMAT
use constant  ECF_A1R5G5B5 => 0;
use constant  ECF_R5G6B5 => 1;
use constant  ECF_R8G8B8 => 2;
use constant  ECF_A8R8G8B8 => 3;

# enum E_TEXTURE_CREATION_FLAG 
use constant  ETCF_ALWAYS_16_BIT => 0x00000001;
use constant  ETCF_ALWAYS_32_BIT => 0x00000002;
use constant  ETCF_OPTIMIZED_FOR_QUALITY => 0x00000004;
use constant  ETCF_OPTIMIZED_FOR_SPEED => 0x00000008;
use constant  ETCF_CREATE_MIP_MAPS => 0x00000010;
use constant  ETCF_FORCE_32_BIT_DO_NOT_USE => 0x7fffffff;

# enum 	E_VIDEO_DRIVER_FEATURE
use constant  EVDF_RENDER_TO_TARGET => 0;
use constant  EVDF_BILINEAR_FILER => 1;
use constant  EVDF_HARDWARE_TL => 2;
use constant  EVDF_MIP_MAP => 3;
use constant  EVDF_STENCIL_BUFFER => 4;

# enum E_TRANSFORMATION_STATE  
use constant  ETS_VIEW => 0;
use constant  ETS_WORLD => 1;
use constant  ETS_PROJECTION => 2;
use constant  ETS_COUNT => 3;

# enum E_VERTEX_TYPE 
use constant  EVT_STANDARD => 0;
use constant  EVT_2TCOORDS => 1;

# enum 	E_MATERIAL_TYPE 
use constant  EMT_SOLID => 0;
use constant  EMT_SOLID_2_LAYER => 1;
use constant  EMT_LIGHTMAP => 2;
use constant  EMT_LIGHTMAP_ADD => 3;
use constant  EMT_LIGHTMAP_M2 => 4;
use constant  EMT_LIGHTMAP_M4 => 5;
use constant  EMT_LIGHTMAP_LIGHTING => 6;
use constant  EMT_LIGHTMAP_LIGHTING_M2 => 7;
use constant  EMT_LIGHTMAP_LIGHTING_M4 => 8;
use constant  EMT_SPHERE_MAP => 9;
use constant  EMT_REFLECTION_2_LAYER => 10;
use constant  EMT_TRANSPARENT_ADD_COLOR => 11;
use constant  EMT_TRANSPARENT_ALPHA_CHANNEL => 12;
use constant  EMT_TRANSPARENT_VERTEX_ALPHA => 13;
use constant  EMT_TRANSPARENT_REFLECTION_2_LAYER => 14; 
use constant  EMT_FORCE_32BIT => 0x7fffffff;

# enum 	E_MATERIAL_FLAG 
use constant  EMF_WIREFRAME => 0;
use constant  EMF_GOURAUD_SHADING => 1;
use constant  EMF_LIGHTING => 2;
use constant  EMF_ZBUFFER => 3;
use constant  EMF_ZWRITE_ENABLE => 4;
use constant  EMF_BACK_FACE_CULLING => 5;
use constant  EMF_BILINEAR_FILTER => 6;
use constant  EMF_TRILINEAR_FILTER => 7;
use constant  EMF_FOG_ENABLE => 8;
use constant  EMF_MATERIAL_FLAG_COUNT => 9;

sub import
  {
  # export all our constants
  for (keys %{Games::Irrlicht::Constants::})
    {
    next if $_ !~ /^E[MCDTV][A-Z][A-Z]?_/;
    #print "Really Exporting $_\n";
    push @EXPORT, $_;
    }
  __PACKAGE__->export_to_level(1,'',@EXPORT);
  }

# enum EDriverType 

1;	# eof

__END__

=pod

=head1 NAME

Games::Irrlicht::Constants - make Irrlicht constants and enums available

=head1 SYNOPSIS

	package Games::Irrlicht::Constants;

	print EDT_OPENGL;

=head1 EXPORTS

Exports all the known Irrlicht constants per default.

=head1 DESCRIPTION

This package provides you with all the constants from the Irrlicht engine.

=head1 AUTHORS

(c) 2004, Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<Games::Irrlicht>.

=cut

