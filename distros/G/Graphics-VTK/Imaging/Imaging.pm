
package Graphics::VTK::Imaging;
use 5.004;
use strict;
use Carp;

use vars qw/ $VERSION @ISA/;

require DynaLoader;

$VERSION = '4.0.001';

@ISA = qw/ DynaLoader /;

bootstrap Graphics::VTK::Imaging $VERSION;


=head1 NAME

VTKImaging  - A Perl interface to VTKImaging library

=head1 SYNOPSIS

C<use Graphics::VTK;>
C<use Graphics::VTK::Imaging;>

=head1 DESCRIPTION

Graphics::VTK::Imaging is an interface to the Imaging libaray of the C++ visualization toolkit VTK..

=head1 AUTHOR

Original PerlVTK Package: Roberto De Leo <rdl@math.umd.edu>

Additional Refinements: John Cerney <j-cerney1@raytheon.com>

=cut

package Graphics::VTK::BooleanTexture;


@Graphics::VTK::BooleanTexture::ISA = qw( Graphics::VTK::StructuredPointsSource );

=head1 Graphics::VTK::BooleanTexture

=over 1

=item *

Inherits from StructuredPointsSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   unsigned char  *GetInIn ();
      (Returns a 2-element Perl list)
   unsigned char  *GetInOn ();
      (Returns a 2-element Perl list)
   unsigned char  *GetInOut ();
      (Returns a 2-element Perl list)
   unsigned char  *GetOnIn ();
      (Returns a 2-element Perl list)
   unsigned char  *GetOnOn ();
      (Returns a 2-element Perl list)
   unsigned char  *GetOnOut ();
      (Returns a 2-element Perl list)
   unsigned char  *GetOutIn ();
      (Returns a 2-element Perl list)
   unsigned char  *GetOutOn ();
      (Returns a 2-element Perl list)
   unsigned char  *GetOutOut ();
      (Returns a 2-element Perl list)
   int GetThickness ();
   int GetXSize ();
   int GetYSize ();
   vtkBooleanTexture *New ();
   void SetInIn (unsigned char , unsigned char );
   void SetInOn (unsigned char , unsigned char );
   void SetInOut (unsigned char , unsigned char );
   void SetOnIn (unsigned char , unsigned char );
   void SetOnOn (unsigned char , unsigned char );
   void SetOnOut (unsigned char , unsigned char );
   void SetOutIn (unsigned char , unsigned char );
   void SetOutOn (unsigned char , unsigned char );
   void SetOutOut (unsigned char , unsigned char );
   void SetThickness (int );
   void SetXSize (int );
   void SetYSize (int );


B<vtkBooleanTexture Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetInIn (unsigned char  a[2]);
      Arg types of 'unsigned char  *' not supported yet
   void SetInOn (unsigned char  a[2]);
      Arg types of 'unsigned char  *' not supported yet
   void SetInOut (unsigned char  a[2]);
      Arg types of 'unsigned char  *' not supported yet
   void SetOnIn (unsigned char  a[2]);
      Arg types of 'unsigned char  *' not supported yet
   void SetOnOn (unsigned char  a[2]);
      Arg types of 'unsigned char  *' not supported yet
   void SetOnOut (unsigned char  a[2]);
      Arg types of 'unsigned char  *' not supported yet
   void SetOutIn (unsigned char  a[2]);
      Arg types of 'unsigned char  *' not supported yet
   void SetOutOn (unsigned char  a[2]);
      Arg types of 'unsigned char  *' not supported yet
   void SetOutOut (unsigned char  a[2]);
      Arg types of 'unsigned char  *' not supported yet

=cut

package Graphics::VTK::ExtractVOI;


@Graphics::VTK::ExtractVOI::ISA = qw( Graphics::VTK::StructuredPointsToStructuredPointsFilter );

=head1 Graphics::VTK::ExtractVOI

=over 1

=item *

Inherits from StructuredPointsToStructuredPointsFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int  *GetSampleRate ();
      (Returns a 3-element Perl list)
   int  *GetVOI ();
      (Returns a 6-element Perl list)
   vtkExtractVOI *New ();
   void SetSampleRate (int , int , int );
   void SetVOI (int , int , int , int , int , int );


B<vtkExtractVOI Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetSampleRate (int  a[3]);
      Method is redundant. Same as SetSampleRate( int, int, int)

   void SetVOI (int  a[6]);
      Method is redundant. Same as SetVOI( int, int, int, int, int, int)


=cut

package Graphics::VTK::GaussianSplatter;


@Graphics::VTK::GaussianSplatter::ISA = qw( Graphics::VTK::DataSetToStructuredPointsFilter );

=head1 Graphics::VTK::GaussianSplatter

=over 1

=item *

Inherits from DataSetToStructuredPointsFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CappingOff ();
   void CappingOn ();
   void ComputeModelBounds ();
   int GetAccumulationMode ();
   const char *GetAccumulationModeAsString ();
   int GetAccumulationModeMaxValue ();
   int GetAccumulationModeMinValue ();
   float GetCapValue ();
   int GetCapping ();
   const char *GetClassName ();
   float GetEccentricity ();
   float GetEccentricityMaxValue ();
   float GetEccentricityMinValue ();
   float GetExponentFactor ();
   float  *GetModelBounds ();
      (Returns a 6-element Perl list)
   int GetNormalWarping ();
   float GetNullValue ();
   float GetRadius ();
   float GetRadiusMaxValue ();
   float GetRadiusMinValue ();
   int  *GetSampleDimensions ();
      (Returns a 3-element Perl list)
   int GetScalarWarping ();
   float GetScaleFactor ();
   float GetScaleFactorMaxValue ();
   float GetScaleFactorMinValue ();
   vtkGaussianSplatter *New ();
   void NormalWarpingOff ();
   void NormalWarpingOn ();
   void ScalarWarpingOff ();
   void ScalarWarpingOn ();
   void SetAccumulationMode (int );
   void SetAccumulationModeToMax ();
   void SetAccumulationModeToMin ();
   void SetAccumulationModeToSum ();
   void SetCapValue (float );
   void SetCapping (int );
   void SetEccentricity (float );
   void SetExponentFactor (float );
   void SetModelBounds (float , float , float , float , float , float );
   void SetNormalWarping (int );
   void SetNullValue (float );
   void SetRadius (float );
   void SetSampleDimensions (int i, int j, int k);
   void SetScalarWarping (int );
   void SetScaleFactor (float );


B<vtkGaussianSplatter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetModelBounds (float  a[6]);
      Method is redundant. Same as SetModelBounds( float, float, float, float, float, float)

   void SetSampleDimensions (int dim[3]);
      Method is redundant. Same as SetSampleDimensions( int, int, int)


=cut

package Graphics::VTK::ImageAccumulate;


@Graphics::VTK::ImageAccumulate::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageAccumulate

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int *GetComponentExtent ();
      (Returns a 6-element Perl list)
   float  *GetComponentOrigin ();
      (Returns a 3-element Perl list)
   float  *GetComponentSpacing ();
      (Returns a 3-element Perl list)
   double  *GetMax ();
      (Returns a 3-element Perl list)
   double  *GetMean ();
      (Returns a 3-element Perl list)
   double  *GetMin ();
      (Returns a 3-element Perl list)
   int GetReverseStencil ();
   double  *GetStandardDeviation ();
      (Returns a 3-element Perl list)
   vtkImageStencilData *GetStencil ();
   long GetVoxelCount ();
   vtkImageAccumulate *New ();
   void ReverseStencilOff ();
   void ReverseStencilOn ();
   void SetComponentExtent (int minX, int maxX, int minY, int maxY, int minZ, int maxZ);
   void SetComponentOrigin (float , float , float );
   void SetComponentSpacing (float , float , float );
   void SetReverseStencil (int );
   void SetStencil (vtkImageStencilData *stencil);


B<vtkImageAccumulate Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeInputUpdateExtent (int inExt[6], int outExt[6]);
      Don't know the size of pointer arg number 1

   void GetComponentExtent (int extent[6]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetComponentExtent (int extent[6]);
      Method is redundant. Same as SetComponentExtent( int, int, int, int, int, int)

   void SetComponentOrigin (float  a[3]);
      Method is redundant. Same as SetComponentOrigin( float, float, float)

   void SetComponentSpacing (float  a[3]);
      Method is redundant. Same as SetComponentSpacing( float, float, float)


=cut

package Graphics::VTK::ImageAnisotropicDiffusion2D;


@Graphics::VTK::ImageAnisotropicDiffusion2D::ISA = qw( Graphics::VTK::ImageSpatialFilter );

=head1 Graphics::VTK::ImageAnisotropicDiffusion2D

=over 1

=item *

Inherits from ImageSpatialFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CornersOff ();
   void CornersOn ();
   void EdgesOff ();
   void EdgesOn ();
   void FacesOff ();
   void FacesOn ();
   const char *GetClassName ();
   int GetCorners ();
   float GetDiffusionFactor ();
   float GetDiffusionThreshold ();
   int GetEdges ();
   int GetFaces ();
   int GetGradientMagnitudeThreshold ();
   int GetNumberOfIterations ();
   void GradientMagnitudeThresholdOff ();
   void GradientMagnitudeThresholdOn ();
   vtkImageAnisotropicDiffusion2D *New ();
   void SetCorners (int );
   void SetDiffusionFactor (float );
   void SetDiffusionThreshold (float );
   void SetEdges (int );
   void SetFaces (int );
   void SetGradientMagnitudeThreshold (int );
   void SetNumberOfIterations (int num);


B<vtkImageAnisotropicDiffusion2D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void Iterate (vtkImageData *in, vtkImageData *out, float ar0, float ar1, int *coreExtent, int count);
      Don't know the size of pointer arg number 5

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageAnisotropicDiffusion3D;


@Graphics::VTK::ImageAnisotropicDiffusion3D::ISA = qw( Graphics::VTK::ImageSpatialFilter );

=head1 Graphics::VTK::ImageAnisotropicDiffusion3D

=over 1

=item *

Inherits from ImageSpatialFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CornersOff ();
   void CornersOn ();
   void EdgesOff ();
   void EdgesOn ();
   void FacesOff ();
   void FacesOn ();
   const char *GetClassName ();
   int GetCorners ();
   float GetDiffusionFactor ();
   float GetDiffusionThreshold ();
   int GetEdges ();
   int GetFaces ();
   int GetGradientMagnitudeThreshold ();
   int GetNumberOfIterations ();
   void GradientMagnitudeThresholdOff ();
   void GradientMagnitudeThresholdOn ();
   vtkImageAnisotropicDiffusion3D *New ();
   void SetCorners (int );
   void SetDiffusionFactor (float );
   void SetDiffusionThreshold (float );
   void SetEdges (int );
   void SetFaces (int );
   void SetGradientMagnitudeThreshold (int );
   void SetNumberOfIterations (int num);


B<vtkImageAnisotropicDiffusion3D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void Iterate (vtkImageData *in, vtkImageData *out, float ar0, float ar1, float ar3, int *coreExtent, int count);
      Don't know the size of pointer arg number 6

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageAppend;


@Graphics::VTK::ImageAppend::ISA = qw( Graphics::VTK::ImageMultipleInputFilter );

=head1 Graphics::VTK::ImageAppend

=over 1

=item *

Inherits from ImageMultipleInputFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int GetAppendAxis ();
   const char *GetClassName ();
   int GetPreserveExtents ();
   vtkImageAppend *New ();
   void PreserveExtentsOff ();
   void PreserveExtentsOn ();
   void SetAppendAxis (int );
   void SetPreserveExtents (int );


B<vtkImageAppend Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeInputUpdateExtent (int inExt[6], int outExt[6], int whichInput);
      Don't know the size of pointer arg number 1

   void InitOutput (int outExt[6], vtkImageData *outData);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inDatas, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageAppendComponents;


@Graphics::VTK::ImageAppendComponents::ISA = qw( Graphics::VTK::ImageMultipleInputFilter );

=head1 Graphics::VTK::ImageAppendComponents

=over 1

=item *

Inherits from ImageMultipleInputFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageAppendComponents *New ();
   virtual void SetInput2 (vtkImageData *input);


B<vtkImageAppendComponents Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void SetInput1 (vtkImageData *input);
      Method is marked 'Do Not Use' in its descriptions

   void ThreadedExecute (vtkImageData *inDatas, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageBlend;


@Graphics::VTK::ImageBlend::ISA = qw( Graphics::VTK::ImageMultipleInputFilter );

=head1 Graphics::VTK::ImageBlend

=over 1

=item *

Inherits from ImageMultipleInputFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int GetBlendMode ();
   const char *GetBlendModeAsString (void );
   int GetBlendModeMaxValue ();
   int GetBlendModeMinValue ();
   const char *GetClassName ();
   float GetCompoundThreshold ();
   double GetOpacity (int idx);
   vtkImageStencilData *GetStencil ();
   vtkImageBlend *New ();
   void SetBlendMode (int );
   void SetBlendModeToCompound ();
   void SetBlendModeToNormal ();
   void SetCompoundThreshold (float );
   void SetOpacity (int idx, double opacity);
   void SetStencil (vtkImageStencilData *);


B<vtkImageBlend Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeInputUpdateExtent (int inExt[6], int outExt[6], int whichInput);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inDatas, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageButterworthHighPass;


@Graphics::VTK::ImageButterworthHighPass::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageButterworthHighPass

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float  *GetCutOff ();
      (Returns a 3-element Perl list)
   int GetOrder ();
   float GetXCutOff ();
   float GetYCutOff ();
   float GetZCutOff ();
   vtkImageButterworthHighPass *New ();
   void SetCutOff (float , float , float );
   void SetCutOff (float v);
   void SetOrder (int );
   void SetXCutOff (float v);
   void SetYCutOff (float v);
   void SetZCutOff (float v);


B<vtkImageButterworthHighPass Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetCutOff (float  a[3]);
      Method is redundant. Same as SetCutOff( float, float, float)

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int outExt[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageButterworthLowPass;


@Graphics::VTK::ImageButterworthLowPass::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageButterworthLowPass

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float  *GetCutOff ();
      (Returns a 3-element Perl list)
   int GetOrder ();
   float GetXCutOff ();
   float GetYCutOff ();
   float GetZCutOff ();
   vtkImageButterworthLowPass *New ();
   void SetCutOff (float , float , float );
   void SetCutOff (float v);
   void SetOrder (int );
   void SetXCutOff (float v);
   void SetYCutOff (float v);
   void SetZCutOff (float v);


B<vtkImageButterworthLowPass Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetCutOff (float  a[3]);
      Method is redundant. Same as SetCutOff( float, float, float)

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int outExt[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageCacheFilter;


@Graphics::VTK::ImageCacheFilter::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageCacheFilter

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int GetCacheSize ();
   const char *GetClassName ();
   vtkImageCacheFilter *New ();
   void SetCacheSize (int size);
   void UpdateData (vtkDataObject *outData);


B<vtkImageCacheFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ImageCanvasSource2D;


@Graphics::VTK::ImageCanvasSource2D::ISA = qw( Graphics::VTK::StructuredPoints );

=head1 Graphics::VTK::ImageCanvasSource2D

=over 1

=item *

Inherits from StructuredPoints

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void DrawCircle (int c0, int c1, float radius);
   void DrawPoint (int p0, int p1);
   void DrawSegment (int x0, int y0, int x1, int y1);
   void DrawSegment3D (float x1, float y1, float z1, float x2, float y2, float z2);
   void FillBox (int min0, int max0, int min1, int max1);
   void FillPixel (int x, int y);
   void FillTriangle (int x0, int y0, int x1, int y1, int x2, int y2);
   void FillTube (int x0, int y0, int x1, int y1, float radius);
   const char *GetClassName ();
   int GetDefaultZ ();
   float  *GetDrawColor ();
      (Returns a 4-element Perl list)
   vtkImageData *GetImageData ();
   vtkImageData *GetOutput ();
   vtkImageCanvasSource2D *New ();
   void SetDefaultZ (int );
   void SetDrawColor (float , float , float , float );
   void SetDrawColor (float a, float b, float c);
   void SetDrawColor (float a, float b);
   void SetDrawColor (float a);
   void SetExtent (int x1, int x2, int y1, int y2, int z1, int z2);
   void SetImageData (vtkImageData *image);


B<vtkImageCanvasSource2D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void DrawSegment3D (float *p0, float *p1);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetDrawColor (float  a[4]);
      Method is redundant. Same as SetDrawColor( float, float, float, float)

   void SetExtent (int *extent);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::ImageCast;


@Graphics::VTK::ImageCast::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageCast

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void ClampOverflowOff ();
   void ClampOverflowOn ();
   int GetClampOverflow ();
   const char *GetClassName ();
   int GetOutputScalarType ();
   vtkImageCast *New ();
   void SetClampOverflow (int );
   void SetOutputScalarType (int );
   void SetOutputScalarTypeToChar ();
   void SetOutputScalarTypeToDouble ();
   void SetOutputScalarTypeToFloat ();
   void SetOutputScalarTypeToInt ();
   void SetOutputScalarTypeToLong ();
   void SetOutputScalarTypeToShort ();
   void SetOutputScalarTypeToUnsignedChar ();
   void SetOutputScalarTypeToUnsignedInt ();
   void SetOutputScalarTypeToUnsignedLong ();
   void SetOutputScalarTypeToUnsignedShort ();


B<vtkImageCast Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int ext[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageChangeInformation;


@Graphics::VTK::ImageChangeInformation::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageChangeInformation

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CenterImageOff ();
   void CenterImageOn ();
   int GetCenterImage ();
   const char *GetClassName ();
   int  *GetExtentTranslation ();
      (Returns a 3-element Perl list)
   vtkImageData *GetInformationInput ();
   float  *GetOriginScale ();
      (Returns a 3-element Perl list)
   float  *GetOriginTranslation ();
      (Returns a 3-element Perl list)
   int  *GetOutputExtentStart ();
      (Returns a 3-element Perl list)
   float  *GetOutputOrigin ();
      (Returns a 3-element Perl list)
   float  *GetOutputSpacing ();
      (Returns a 3-element Perl list)
   float  *GetSpacingScale ();
      (Returns a 3-element Perl list)
   vtkImageChangeInformation *New ();
   void SetCenterImage (int );
   void SetExtentTranslation (int , int , int );
   void SetInformationInput (vtkImageData *);
   void SetOriginScale (float , float , float );
   void SetOriginTranslation (float , float , float );
   void SetOutputExtentStart (int , int , int );
   void SetOutputOrigin (float , float , float );
   void SetOutputSpacing (float , float , float );
   void SetSpacingScale (float , float , float );


B<vtkImageChangeInformation Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeInputUpdateExtent (int extent[6], int wholeExtent[6]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetExtentTranslation (int  a[3]);
      Method is redundant. Same as SetExtentTranslation( int, int, int)

   void SetOriginScale (float  a[3]);
      Method is redundant. Same as SetOriginScale( float, float, float)

   void SetOriginTranslation (float  a[3]);
      Method is redundant. Same as SetOriginTranslation( float, float, float)

   void SetOutputExtentStart (int  a[3]);
      Method is redundant. Same as SetOutputExtentStart( int, int, int)

   void SetOutputOrigin (float  a[3]);
      Method is redundant. Same as SetOutputOrigin( float, float, float)

   void SetOutputSpacing (float  a[3]);
      Method is redundant. Same as SetOutputSpacing( float, float, float)

   void SetSpacingScale (float  a[3]);
      Method is redundant. Same as SetSpacingScale( float, float, float)


=cut

package Graphics::VTK::ImageCheckerboard;


@Graphics::VTK::ImageCheckerboard::ISA = qw( Graphics::VTK::ImageTwoInputFilter );

=head1 Graphics::VTK::ImageCheckerboard

=over 1

=item *

Inherits from ImageTwoInputFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int  *GetNumberOfDivisions ();
      (Returns a 3-element Perl list)
   vtkImageCheckerboard *New ();
   void SetNumberOfDivisions (int , int , int );


B<vtkImageCheckerboard Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetNumberOfDivisions (int  a[3]);
      Method is redundant. Same as SetNumberOfDivisions( int, int, int)

   void ThreadedExecute (vtkImageData *inDatas, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageCityBlockDistance;


@Graphics::VTK::ImageCityBlockDistance::ISA = qw( Graphics::VTK::ImageDecomposeFilter );

=head1 Graphics::VTK::ImageCityBlockDistance

=over 1

=item *

Inherits from ImageDecomposeFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageCityBlockDistance *New ();


B<vtkImageCityBlockDistance Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeInputUpdateExtent (int inExt[6], int outExt[6]);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::ImageClip;


@Graphics::VTK::ImageClip::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageClip

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void ClipDataOff ();
   void ClipDataOn ();
   const char *GetClassName ();
   int GetClipData ();
   int *GetOutputWholeExtent ();
      (Returns a 6-element Perl list)
   vtkImageClip *New ();
   void ResetOutputWholeExtent ();
   void SetClipData (int );
   void SetOutputWholeExtent (int minX, int maxX, int minY, int maxY, int minZ, int maxZ);
   void SetOutputWholeExtent (int piece, int numPieces);


B<vtkImageClip Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void CopyData (vtkImageData *inData, vtkImageData *outData, int *ext);
      Don't know the size of pointer arg number 3

   void GetOutputWholeExtent (int extent[6]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetOutputWholeExtent (int extent[6]);
      Method is redundant. Same as SetOutputWholeExtent( int, int, int, int, int, int)

   int SplitExtentTmp (int piece, int numPieces, int *ext);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageConnector;


@Graphics::VTK::ImageConnector::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::ImageConnector

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   char unsigned GetConnectedValue ();
   char unsigned GetUnconnectedValue ();
   vtkImageConnector *New ();
   void RemoveAllSeeds ();
   void SetConnectedValue (unsigned char );
   void SetUnconnectedValue (unsigned char );


B<vtkImageConnector Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void MarkData (vtkImageData *data, int dimensionality, int ext[6]);
      Don't know the size of pointer arg number 3

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ImageConstantPad;


@Graphics::VTK::ImageConstantPad::ISA = qw( Graphics::VTK::ImagePadFilter );

=head1 Graphics::VTK::ImageConstantPad

=over 1

=item *

Inherits from ImagePadFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetConstant ();
   vtkImageConstantPad *New ();
   void SetConstant (float );


B<vtkImageConstantPad Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int outExt[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageContinuousDilate3D;


@Graphics::VTK::ImageContinuousDilate3D::ISA = qw( Graphics::VTK::ImageSpatialFilter );

=head1 Graphics::VTK::ImageContinuousDilate3D

=over 1

=item *

Inherits from ImageSpatialFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageContinuousDilate3D *New ();
   void SetKernelSize (int size0, int size1, int size2);


B<vtkImageContinuousDilate3D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageContinuousErode3D;


@Graphics::VTK::ImageContinuousErode3D::ISA = qw( Graphics::VTK::ImageSpatialFilter );

=head1 Graphics::VTK::ImageContinuousErode3D

=over 1

=item *

Inherits from ImageSpatialFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageContinuousErode3D *New ();
   void SetKernelSize (int size0, int size1, int size2);


B<vtkImageContinuousErode3D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageConvolve;


@Graphics::VTK::ImageConvolve::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageConvolve

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float *GetKernel3x3 ();
      (Returns a 9-element Perl list)
   float *GetKernel3x3x3 ();
      (Returns a 27-element Perl list)
   float *GetKernel5x5 ();
      (Returns a 25-element Perl list)
   int  *GetKernelSize ();
      (Returns a 3-element Perl list)
   vtkImageConvolve *New ();


B<vtkImageConvolve Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void GetKernel (float *kernel);
      Don't know the size of pointer arg number 1

   void GetKernel3x3 (float kernel[9]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void GetKernel3x3x3 (float kernel[27]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void GetKernel5x5 (float kernel[25]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   float *GetKernel ();
      Can't Handle 'float *' return type without a hint

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetKernel (const float *kernel, int sizeX, int sizeY, int sizeZ);
      Don't know the size of pointer arg number 1

   void SetKernel3x3 (const float kernel[9]);
      Can't handle methods with single array args (like a[3]) yet.

   void SetKernel3x3x3 (const float kernel[27]);
      Can't handle methods with single array args (like a[3]) yet.

   void SetKernel5x5 (const float kernel[25]);
      Can't handle methods with single array args (like a[3]) yet.

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int outExt[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageCorrelation;


@Graphics::VTK::ImageCorrelation::ISA = qw( Graphics::VTK::ImageTwoInputFilter );

=head1 Graphics::VTK::ImageCorrelation

=over 1

=item *

Inherits from ImageTwoInputFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetDimensionality ();
   int GetDimensionalityMaxValue ();
   int GetDimensionalityMinValue ();
   vtkImageCorrelation *New ();
   void SetDimensionality (int );


B<vtkImageCorrelation Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void ComputeInputUpdateExtent (int inExt[6], int outExt[6], int whichInput);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inDatas, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageCursor3D;


@Graphics::VTK::ImageCursor3D::ISA = qw( Graphics::VTK::ImageInPlaceFilter );

=head1 Graphics::VTK::ImageCursor3D

=over 1

=item *

Inherits from ImageInPlaceFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float  *GetCursorPosition ();
      (Returns a 3-element Perl list)
   int GetCursorRadius ();
   float GetCursorValue ();
   vtkImageCursor3D *New ();
   void SetCursorPosition (float , float , float );
   void SetCursorRadius (int );
   void SetCursorValue (float );


B<vtkImageCursor3D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetCursorPosition (float  a[3]);
      Method is redundant. Same as SetCursorPosition( float, float, float)


=cut

package Graphics::VTK::ImageDataStreamer;


@Graphics::VTK::ImageDataStreamer::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageDataStreamer

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkExtentTranslator *GetExtentTranslator ();
   int GetNumberOfStreamDivisions ();
   vtkImageDataStreamer *New ();
   void SetExtentTranslator (vtkExtentTranslator *);
   void SetNumberOfStreamDivisions (int );
   void UpdateData (vtkDataObject *out);


B<vtkImageDataStreamer Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ImageDecomposeFilter;


@Graphics::VTK::ImageDecomposeFilter::ISA = qw( Graphics::VTK::ImageIterateFilter );

=head1 Graphics::VTK::ImageDecomposeFilter

=over 1

=item *

Inherits from ImageIterateFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetDimensionality ();
   void SetDimensionality (int dim);
   void SetFilteredAxes (int axis0, int axis2, int axis3);
   void SetFilteredAxes (int axis0, int axis2);
   void SetFilteredAxes (int axis0);


B<vtkImageDecomposeFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PermuteExtent (int *extent, int &min0, int &max0, int &min1, int &max1, int &min2, int &max2);
      Don't know the size of pointer arg number 1

   void PermuteIncrements (int *increments, int &inc0, int &inc1, int &inc2);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ImageDifference;


@Graphics::VTK::ImageDifference::ISA = qw( Graphics::VTK::ImageTwoInputFilter );

=head1 Graphics::VTK::ImageDifference

=over 1

=item *

Inherits from ImageTwoInputFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AllowShiftOff ();
   void AllowShiftOn ();
   void AveragingOff ();
   void AveragingOn ();
   int GetAllowShift ();
   int GetAveraging ();
   const char *GetClassName ();
   float GetError (void );
   vtkImageData *GetImage ();
   int GetThreshold ();
   float GetThresholdedError (void );
   vtkImageDifference *New ();
   void SetAllowShift (int );
   void SetAveraging (int );
   void SetImage (vtkImageData *image);
   void SetInput (int num, vtkImageData *input);
   void SetInput (vtkImageData *input);
   void SetThreshold (int );


B<vtkImageDifference Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeInputUpdateExtent (int inExt[6], int outExt[6], int whichInput);
      Don't know the size of pointer arg number 1

   void GetError (float *e);
      Don't know the size of pointer arg number 1

   void GetThresholdedError (float *e);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inDatas, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageDilateErode3D;


@Graphics::VTK::ImageDilateErode3D::ISA = qw( Graphics::VTK::ImageSpatialFilter );

=head1 Graphics::VTK::ImageDilateErode3D

=over 1

=item *

Inherits from ImageSpatialFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetDilateValue ();
   float GetErodeValue ();
   vtkImageDilateErode3D *New ();
   void SetDilateValue (float );
   void SetErodeValue (float );
   void SetKernelSize (int size0, int size1, int size2);


B<vtkImageDilateErode3D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageDivergence;


@Graphics::VTK::ImageDivergence::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageDivergence

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageDivergence *New ();


B<vtkImageDivergence Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeInputUpdateExtent (int inExt[6], int outExt[6]);
      Don't know the size of pointer arg number 1

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int ext[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageDotProduct;


@Graphics::VTK::ImageDotProduct::ISA = qw( Graphics::VTK::ImageTwoInputFilter );

=head1 Graphics::VTK::ImageDotProduct

=over 1

=item *

Inherits from ImageTwoInputFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageDotProduct *New ();


B<vtkImageDotProduct Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ThreadedExecute (vtkImageData *inDatas, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageEllipsoidSource;


@Graphics::VTK::ImageEllipsoidSource::ISA = qw( Graphics::VTK::ImageSource );

=head1 Graphics::VTK::ImageEllipsoidSource

=over 1

=item *

Inherits from ImageSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   float  *GetCenter ();
      (Returns a 3-element Perl list)
   const char *GetClassName ();
   float GetInValue ();
   float GetOutValue ();
   int GetOutputScalarType ();
   float  *GetRadius ();
      (Returns a 3-element Perl list)
   int *GetWholeExtent ();
      (Returns a 6-element Perl list)
   vtkImageEllipsoidSource *New ();
   void SetCenter (float , float , float );
   void SetInValue (float );
   void SetOutValue (float );
   void SetOutputScalarType (int );
   void SetOutputScalarTypeToChar ();
   void SetOutputScalarTypeToDouble ();
   void SetOutputScalarTypeToFloat ();
   void SetOutputScalarTypeToInt ();
   void SetOutputScalarTypeToLong ();
   void SetOutputScalarTypeToShort ();
   void SetOutputScalarTypeToUnsignedChar ();
   void SetOutputScalarTypeToUnsignedInt ();
   void SetOutputScalarTypeToUnsignedLong ();
   void SetOutputScalarTypeToUnsignedShort ();
   void SetRadius (float , float , float );
   void SetWholeExtent (int minX, int maxX, int minY, int maxY, int minZ, int maxZ);


B<vtkImageEllipsoidSource Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void GetWholeExtent (int extent[6]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetCenter (float  a[3]);
      Method is redundant. Same as SetCenter( float, float, float)

   void SetRadius (float  a[3]);
      Method is redundant. Same as SetRadius( float, float, float)

   void SetWholeExtent (int extent[6]);
      Method is redundant. Same as SetWholeExtent( int, int, int, int, int, int)


=cut

package Graphics::VTK::ImageEuclideanDistance;


@Graphics::VTK::ImageEuclideanDistance::ISA = qw( Graphics::VTK::ImageDecomposeFilter );

=head1 Graphics::VTK::ImageEuclideanDistance

=over 1

=item *

Inherits from ImageDecomposeFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void ConsiderAnisotropyOff ();
   void ConsiderAnisotropyOn ();
   int GetAlgorithm ();
   const char *GetClassName ();
   int GetConsiderAnisotropy ();
   int GetInitialize ();
   float GetMaximumDistance ();
   void InitializeOff ();
   void InitializeOn ();
   void IterativeExecuteData (vtkImageData *in, vtkImageData *out);
   vtkImageEuclideanDistance *New ();
   void SetAlgorithm (int );
   void SetAlgorithmToSaito ();
   void SetAlgorithmToSaitoCached ();
   void SetConsiderAnisotropy (int );
   void SetInitialize (int );
   void SetMaximumDistance (float );


B<vtkImageEuclideanDistance Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeInputUpdateExtent (int inExt[6], int outExt[6]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   int SplitExtent (int splitExt[6], int startExt[6], int num, int total);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::ImageEuclideanToPolar;


@Graphics::VTK::ImageEuclideanToPolar::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageEuclideanToPolar

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetThetaMaximum ();
   vtkImageEuclideanToPolar *New ();
   void SetThetaMaximum (float );


B<vtkImageEuclideanToPolar Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int ext[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageExport;


@Graphics::VTK::ImageExport::ISA = qw( Graphics::VTK::ProcessObject );

=head1 Graphics::VTK::ImageExport

=over 1

=item *

Inherits from ProcessObject

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Export ();
   const char *GetClassName ();
   int *GetDataDimensions ();
      (Returns a 3-element Perl list)
   int *GetDataExtent ();
      (Returns a 6-element Perl list)
   int GetDataMemorySize ();
   int GetDataNumberOfScalarComponents ();
   float *GetDataOrigin ();
      (Returns a 3-element Perl list)
   int GetDataScalarType ();
   const char *GetDataScalarTypeAsString ();
   float *GetDataSpacing ();
      (Returns a 3-element Perl list)
   int GetImageLowerLeft ();
   vtkImageData *GetInput ();
   void ImageLowerLeftOff ();
   void ImageLowerLeftOn ();
   vtkImageExport *New ();
   void SetImageLowerLeft (int );
   void SetInput (vtkImageData *input);


B<vtkImageExport Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void *BufferPointerCallback ();
      Can't Handle 'void *' return type without a hint

   static void *BufferPointerCallbackFunction (void *);
      Can't Handle 'static void *' return type without a hint

   virtual int *DataExtentCallback ();
      Can't Handle 'int *' return type without a hint

   static int *DataExtentCallbackFunction (void *);
      Can't Handle 'static int *' return type without a hint

   virtual void Export (void *);
      Don't know the size of pointer arg number 1

   void *GetCallbackUserData ();
      Can't Handle 'void *' return type without a hint

   void GetDataDimensions (int *ptr);
      Don't know the size of pointer arg number 1

   void GetDataExtent (int *ptr);
      Don't know the size of pointer arg number 1

   void GetDataOrigin (float *ptr);
      Don't know the size of pointer arg number 1

   void GetDataSpacing (float *ptr);
      Don't know the size of pointer arg number 1

   void *GetExportVoidPointer ();
      Can't Handle 'void *' return type without a hint

   void *GetPointerToData ();
      Can't Handle 'void *' return type without a hint

   static int NumberOfComponentsCallbackFunction (void *);
      Don't know the size of pointer arg number 1

   virtual float *OriginCallback ();
      Can't Handle 'float *' return type without a hint

   static float *OriginCallbackFunction (void *);
      Can't Handle 'static float *' return type without a hint

   static int PipelineModifiedCallbackFunction (void *);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   virtual void PropagateUpdateExtentCallback (int *);
      Don't know the size of pointer arg number 1

   static void PropagateUpdateExtentCallbackFunction (void *, int *);
      Don't know the size of pointer arg number 1

   static const char *ScalarTypeCallbackFunction (void *);
      Don't know the size of pointer arg number 1

   void SetExportVoidPointer (void *);
      Don't know the size of pointer arg number 1

   virtual float *SpacingCallback ();
      Can't Handle 'float *' return type without a hint

   static float *SpacingCallbackFunction (void *);
      Can't Handle 'static float *' return type without a hint

   static void UpdateDataCallbackFunction (void *);
      Don't know the size of pointer arg number 1

   static void UpdateInformationCallbackFunction (void *);
      Don't know the size of pointer arg number 1

   virtual int *WholeExtentCallback ();
      Can't Handle 'int *' return type without a hint

   static int *WholeExtentCallbackFunction (void *);
      Can't Handle 'static int *' return type without a hint


=cut

package Graphics::VTK::ImageExtractComponents;


@Graphics::VTK::ImageExtractComponents::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageExtractComponents

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int  *GetComponents ();
      (Returns a 3-element Perl list)
   int GetNumberOfComponents ();
   vtkImageExtractComponents *New ();
   void SetComponents (int c1, int c2, int c3);
   void SetComponents (int c1, int c2);
   void SetComponents (int c1);


B<vtkImageExtractComponents Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int ext[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageFFT;


@Graphics::VTK::ImageFFT::ISA = qw( Graphics::VTK::ImageFourierFilter );

=head1 Graphics::VTK::ImageFFT

=over 1

=item *

Inherits from ImageFourierFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   virtual void IterativeExecuteData (vtkImageData *in, vtkImageData *out);
   vtkImageFFT *New ();


B<vtkImageFFT Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeInputUpdateExtent (int inExt[6], int outExt[6]);
      Don't know the size of pointer arg number 1

   int SplitExtent (int splitExt[6], int startExt[6], int num, int total);
      Don't know the size of pointer arg number 1

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int outExt[6], int threadId);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageFlip;


@Graphics::VTK::ImageFlip::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageFlip

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetFilteredAxis ();
   int GetPreserveImageExtent ();
   vtkImageFlip *New ();
   void PreserveImageExtentOff ();
   void PreserveImageExtentOn ();
   void SetFilteredAxes (int axis);
   void SetFilteredAxis (int );
   void SetPreserveImageExtent (int );


B<vtkImageFlip Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeInputUpdateExtent (int inExt[6], int outExt[6]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int outExt[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageFourierCenter;


@Graphics::VTK::ImageFourierCenter::ISA = qw( Graphics::VTK::ImageDecomposeFilter );

=head1 Graphics::VTK::ImageFourierCenter

=over 1

=item *

Inherits from ImageDecomposeFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   virtual void IterativeExecuteData (vtkImageData *in, vtkImageData *out);
   vtkImageFourierCenter *New ();


B<vtkImageFourierCenter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeInputUpdateExtent (int inExt[6], int outExt[6]);
      Don't know the size of pointer arg number 1

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int outExt[6], int threadId);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageFourierFilter;


@Graphics::VTK::ImageFourierFilter::ISA = qw( Graphics::VTK::ImageDecomposeFilter );

=head1 Graphics::VTK::ImageFourierFilter

=over 1

=item *

Inherits from ImageDecomposeFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();

=cut

package Graphics::VTK::ImageGaussianSmooth;


@Graphics::VTK::ImageGaussianSmooth::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageGaussianSmooth

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetDimensionality ();
   float  *GetRadiusFactors ();
      (Returns a 3-element Perl list)
   float  *GetStandardDeviations ();
      (Returns a 3-element Perl list)
   vtkImageGaussianSmooth *New ();
   void SetDimensionality (int );
   void SetRadiusFactor (float f);
   void SetRadiusFactors (float , float , float );
   void SetRadiusFactors (float f, float f2);
   void SetStandardDeviation (float a, float b, float c);
   void SetStandardDeviation (float a, float b);
   void SetStandardDeviation (float std);
   void SetStandardDeviations (float , float , float );
   void SetStandardDeviations (float a, float b);


B<vtkImageGaussianSmooth Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeInputUpdateExtent (int inExt[6], int outExt[6]);
      Don't know the size of pointer arg number 1

   void ComputeKernel (double *kernel, int min, int max, double std);
      Don't know the size of pointer arg number 1

   void ExecuteAxis (int axis, vtkImageData *inData, int inExt[6], vtkImageData *outData, int outExt[6], int *pcycle, int target, int *pcount, int total);
      Don't know the size of pointer arg number 3

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetRadiusFactors (float  a[3]);
      Method is redundant. Same as SetRadiusFactors( float, float, float)

   void SetStandardDeviations (float  a[3]);
      Method is redundant. Same as SetStandardDeviations( float, float, float)

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int outExt[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageGaussianSource;


@Graphics::VTK::ImageGaussianSource::ISA = qw( Graphics::VTK::ImageSource );

=head1 Graphics::VTK::ImageGaussianSource

=over 1

=item *

Inherits from ImageSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   float  *GetCenter ();
      (Returns a 3-element Perl list)
   const char *GetClassName ();
   float GetMaximum ();
   float GetStandardDeviation ();
   vtkImageGaussianSource *New ();
   void SetCenter (float , float , float );
   void SetMaximum (float );
   void SetStandardDeviation (float );
   void SetWholeExtent (int xMinx, int xMax, int yMin, int yMax, int zMin, int zMax);


B<vtkImageGaussianSource Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetCenter (float  a[3]);
      Method is redundant. Same as SetCenter( float, float, float)


=cut

package Graphics::VTK::ImageGradient;


@Graphics::VTK::ImageGradient::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageGradient

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetDimensionality ();
   int GetDimensionalityMaxValue ();
   int GetDimensionalityMinValue ();
   int GetHandleBoundaries ();
   void HandleBoundariesOff ();
   void HandleBoundariesOn ();
   vtkImageGradient *New ();
   void SetDimensionality (int );
   void SetHandleBoundaries (int );


B<vtkImageGradient Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeInputUpdateExtent (int inExt[6], int outExt[6]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageGradientMagnitude;


@Graphics::VTK::ImageGradientMagnitude::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageGradientMagnitude

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetDimensionality ();
   int GetDimensionalityMaxValue ();
   int GetDimensionalityMinValue ();
   int GetHandleBoundaries ();
   void HandleBoundariesOff ();
   void HandleBoundariesOn ();
   vtkImageGradientMagnitude *New ();
   void SetDimensionality (int );
   void SetHandleBoundaries (int );


B<vtkImageGradientMagnitude Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeInputUpdateExtent (int inExt[6], int outExt[6]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageGridSource;


@Graphics::VTK::ImageGridSource::ISA = qw( Graphics::VTK::ImageSource );

=head1 Graphics::VTK::ImageGridSource

=over 1

=item *

Inherits from ImageSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int  *GetDataExtent ();
      (Returns a 6-element Perl list)
   float  *GetDataOrigin ();
      (Returns a 3-element Perl list)
   int GetDataScalarType ();
   const char *GetDataScalarTypeAsString ();
   float  *GetDataSpacing ();
      (Returns a 3-element Perl list)
   float GetFillValue ();
   int  *GetGridOrigin ();
      (Returns a 3-element Perl list)
   int  *GetGridSpacing ();
      (Returns a 3-element Perl list)
   float GetLineValue ();
   vtkImageGridSource *New ();
   void SetDataExtent (int , int , int , int , int , int );
   void SetDataOrigin (float , float , float );
   void SetDataScalarType (int );
   void SetDataScalarTypeToFloat ();
   void SetDataScalarTypeToInt ();
   void SetDataScalarTypeToShort ();
   void SetDataScalarTypeToUnsignedChar ();
   void SetDataScalarTypeToUnsignedShort ();
   void SetDataSpacing (float , float , float );
   void SetFillValue (float );
   void SetGridOrigin (int , int , int );
   void SetGridSpacing (int , int , int );
   void SetLineValue (float );


B<vtkImageGridSource Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetDataExtent (int  a[6]);
      Method is redundant. Same as SetDataExtent( int, int, int, int, int, int)

   void SetDataOrigin (float  a[3]);
      Method is redundant. Same as SetDataOrigin( float, float, float)

   void SetDataSpacing (float  a[3]);
      Method is redundant. Same as SetDataSpacing( float, float, float)

   void SetGridOrigin (int  a[3]);
      Method is redundant. Same as SetGridOrigin( int, int, int)

   void SetGridSpacing (int  a[3]);
      Method is redundant. Same as SetGridSpacing( int, int, int)


=cut

package Graphics::VTK::ImageHSVToRGB;


@Graphics::VTK::ImageHSVToRGB::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageHSVToRGB

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetMaximum ();
   vtkImageHSVToRGB *New ();
   void SetMaximum (float );


B<vtkImageHSVToRGB Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int ext[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageHybridMedian2D;


@Graphics::VTK::ImageHybridMedian2D::ISA = qw( Graphics::VTK::ImageSpatialFilter );

=head1 Graphics::VTK::ImageHybridMedian2D

=over 1

=item *

Inherits from ImageSpatialFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageHybridMedian2D *New ();


B<vtkImageHybridMedian2D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   float ComputeMedian (float *array, int size);
      Don't know the size of pointer arg number 1

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int outExt[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageIdealHighPass;


@Graphics::VTK::ImageIdealHighPass::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageIdealHighPass

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float  *GetCutOff ();
      (Returns a 3-element Perl list)
   float GetXCutOff ();
   float GetYCutOff ();
   float GetZCutOff ();
   vtkImageIdealHighPass *New ();
   void SetCutOff (float , float , float );
   void SetCutOff (float v);
   void SetXCutOff (float v);
   void SetYCutOff (float v);
   void SetZCutOff (float v);


B<vtkImageIdealHighPass Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetCutOff (float  a[3]);
      Method is redundant. Same as SetCutOff( float, float, float)

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int outExt[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageIdealLowPass;


@Graphics::VTK::ImageIdealLowPass::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageIdealLowPass

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float  *GetCutOff ();
      (Returns a 3-element Perl list)
   float GetXCutOff ();
   float GetYCutOff ();
   float GetZCutOff ();
   vtkImageIdealLowPass *New ();
   void SetCutOff (float , float , float );
   void SetCutOff (float v);
   void SetXCutOff (float v);
   void SetYCutOff (float v);
   void SetZCutOff (float v);


B<vtkImageIdealLowPass Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetCutOff (float  a[3]);
      Method is redundant. Same as SetCutOff( float, float, float)

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int outExt[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageImport;


@Graphics::VTK::ImageImport::ISA = qw( Graphics::VTK::ImageSource );

=head1 Graphics::VTK::ImageImport

=over 1

=item *

Inherits from ImageSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int  *GetDataExtent ();
      (Returns a 6-element Perl list)
   float  *GetDataOrigin ();
      (Returns a 3-element Perl list)
   int GetDataScalarType ();
   const char *GetDataScalarTypeAsString ();
   float  *GetDataSpacing ();
      (Returns a 3-element Perl list)
   int GetNumberOfScalarComponents ();
   int  *GetWholeExtent ();
      (Returns a 6-element Perl list)
   vtkImageImport *New ();
   virtual void PropagateUpdateExtent (vtkDataObject *output);
   void SetDataExtent (int , int , int , int , int , int );
   void SetDataExtentToWholeExtent ();
   void SetDataOrigin (float , float , float );
   void SetDataScalarType (int );
   void SetDataScalarTypeToDouble ();
   void SetDataScalarTypeToFloat ();
   void SetDataScalarTypeToInt ();
   void SetDataScalarTypeToShort ();
   void SetDataScalarTypeToUnsignedChar ();
   void SetDataScalarTypeToUnsignedShort ();
   void SetDataSpacing (float , float , float );
   void SetNumberOfScalarComponents (int );
   void SetWholeExtent (int , int , int , int , int , int );


B<vtkImageImport Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void CopyImportVoidPointer (void *ptr, int size);
      Method is marked 'Do Not Use' in its descriptions

   void *GetImportVoidPointer ();
      Can't Handle 'void *' return type without a hint

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetDataExtent (int  a[6]);
      Method is redundant. Same as SetDataExtent( int, int, int, int, int, int)

   void SetDataOrigin (float  a[3]);
      Method is redundant. Same as SetDataOrigin( float, float, float)

   void SetDataSpacing (float  a[3]);
      Method is redundant. Same as SetDataSpacing( float, float, float)

   void SetImportVoidPointer (void *ptr);
      Don't know the size of pointer arg number 1

   void SetImportVoidPointer (void *ptr, int save);
      Don't know the size of pointer arg number 1

   void SetWholeExtent (int  a[6]);
      Method is redundant. Same as SetWholeExtent( int, int, int, int, int, int)


=cut

package Graphics::VTK::ImageIslandRemoval2D;


@Graphics::VTK::ImageIslandRemoval2D::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageIslandRemoval2D

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int GetAreaThreshold ();
   const char *GetClassName ();
   float GetIslandValue ();
   float GetReplaceValue ();
   int GetSquareNeighborhood ();
   vtkImageIslandRemoval2D *New ();
   void SetAreaThreshold (int );
   void SetIslandValue (float );
   void SetReplaceValue (float );
   void SetSquareNeighborhood (int );
   void SquareNeighborhoodOff ();
   void SquareNeighborhoodOn ();


B<vtkImageIslandRemoval2D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ImageIterateFilter;


@Graphics::VTK::ImageIterateFilter::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageIterateFilter

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void ComputeInputUpdateExtents (vtkDataObject *output);
   const char *GetClassName ();
   int GetIteration ();
   int GetNumberOfIterations ();


B<vtkImageIterateFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ImageLaplacian;


@Graphics::VTK::ImageLaplacian::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageLaplacian

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetDimensionality ();
   int GetDimensionalityMaxValue ();
   int GetDimensionalityMinValue ();
   vtkImageLaplacian *New ();
   void SetDimensionality (int );


B<vtkImageLaplacian Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeInputUpdateExtent (int inExt[6], int outExt[6]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int ext[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageLogarithmicScale;


@Graphics::VTK::ImageLogarithmicScale::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageLogarithmicScale

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetConstant ();
   vtkImageLogarithmicScale *New ();
   void SetConstant (float );


B<vtkImageLogarithmicScale Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int outExt[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageLogic;


@Graphics::VTK::ImageLogic::ISA = qw( Graphics::VTK::ImageTwoInputFilter );

=head1 Graphics::VTK::ImageLogic

=over 1

=item *

Inherits from ImageTwoInputFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetOperation ();
   float GetOutputTrueValue ();
   vtkImageLogic *New ();
   void SetOperation (int );
   void SetOperationToAnd ();
   void SetOperationToNand ();
   void SetOperationToNor ();
   void SetOperationToNot ();
   void SetOperationToOr ();
   void SetOperationToXor ();
   void SetOutputTrueValue (float );


B<vtkImageLogic Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inDatas, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageLuminance;


@Graphics::VTK::ImageLuminance::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageLuminance

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageLuminance *New ();


B<vtkImageLuminance Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int ext[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageMagnify;


@Graphics::VTK::ImageMagnify::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageMagnify

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetInterpolate ();
   int  *GetMagnificationFactors ();
      (Returns a 3-element Perl list)
   void InterpolateOff ();
   void InterpolateOn ();
   vtkImageMagnify *New ();
   void SetInterpolate (int );
   void SetMagnificationFactors (int , int , int );


B<vtkImageMagnify Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeInputUpdateExtent (int inExt[6], int outExt[6]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetMagnificationFactors (int  a[3]);
      Method is redundant. Same as SetMagnificationFactors( int, int, int)

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageMagnitude;


@Graphics::VTK::ImageMagnitude::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageMagnitude

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageMagnitude *New ();


B<vtkImageMagnitude Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageMandelbrotSource;


@Graphics::VTK::ImageMandelbrotSource::ISA = qw( Graphics::VTK::ImageSource );

=head1 Graphics::VTK::ImageMandelbrotSource

=over 1

=item *

Inherits from ImageSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CopyOriginAndSample (vtkImageMandelbrotSource *source);
   const char *GetClassName ();
   short unsigned GetMaximumNumberOfIterations ();
   unsigned GetMaximumNumberOfIterationsMaxValue ();
   unsigned GetMaximumNumberOfIterationsMinValue ();
   double  *GetOriginCX ();
      (Returns a 4-element Perl list)
   int  *GetProjectionAxes ();
      (Returns a 3-element Perl list)
   double  *GetSampleCX ();
      (Returns a 4-element Perl list)
   int  *GetWholeExtent ();
      (Returns a 6-element Perl list)
   vtkImageMandelbrotSource *New ();
   void Pan (double x, double y, double z);
   void SetMaximumNumberOfIterations (unsigned short );
   void SetOriginCX (double , double , double , double );
   void SetProjectionAxes (int , int , int );
   void SetSample (double v);
   void SetSampleCX (double , double , double , double );
   void SetWholeExtent (int minX, int maxX, int minY, int maxY, int minZ, int maxZ);
   void Zoom (double factor);


B<vtkImageMandelbrotSource Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetOriginCX (double  a[4]);
      Method is redundant. Same as SetOriginCX( double, double, double, double)

   void SetProjectionAxes (int  a[3]);
      Method is redundant. Same as SetProjectionAxes( int, int, int)

   void SetSampleCX (double  a[4]);
      Method is redundant. Same as SetSampleCX( double, double, double, double)

   void SetWholeExtent (int extent[6]);
      Method is redundant. Same as SetWholeExtent( int, int, int, int, int, int)


=cut

package Graphics::VTK::ImageMapToColors;


@Graphics::VTK::ImageMapToColors::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageMapToColors

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int GetActiveComponent ();
   const char *GetClassName ();
   vtkScalarsToColors *GetLookupTable ();
   unsigned long GetMTime ();
   int GetOutputFormat ();
   int GetPassAlphaToOutput ();
   vtkImageMapToColors *New ();
   void PassAlphaToOutputOff ();
   void PassAlphaToOutputOn ();
   void SetActiveComponent (int );
   void SetLookupTable (vtkScalarsToColors *);
   void SetOutputFormat (int );
   void SetOutputFormatToLuminance ();
   void SetOutputFormatToLuminanceAlpha ();
   void SetOutputFormatToRGB ();
   void SetOutputFormatToRGBA ();
   void SetPassAlphaToOutput (int );


B<vtkImageMapToColors Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageMapToRGBA;


@Graphics::VTK::ImageMapToRGBA::ISA = qw( Graphics::VTK::ImageMapToColors );

=head1 Graphics::VTK::ImageMapToRGBA

=over 1

=item *

Inherits from ImageMapToColors

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageMapToRGBA *New ();

=cut

package Graphics::VTK::ImageMapToWindowLevelColors;


@Graphics::VTK::ImageMapToWindowLevelColors::ISA = qw( Graphics::VTK::ImageMapToColors );

=head1 Graphics::VTK::ImageMapToWindowLevelColors

=over 1

=item *

Inherits from ImageMapToColors

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetLevel ();
   float GetWindow ();
   vtkImageMapToWindowLevelColors *New ();
   void SetLevel (float );
   void SetWindow (float );


B<vtkImageMapToWindowLevelColors Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageMask;


@Graphics::VTK::ImageMask::ISA = qw( Graphics::VTK::ImageTwoInputFilter );

=head1 Graphics::VTK::ImageMask

=over 1

=item *

Inherits from ImageTwoInputFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetMaskedOutputValueLength ();
   int GetNotMask ();
   vtkImageMask *New ();
   void NotMaskOff ();
   void NotMaskOn ();
   void SetImageInput (vtkImageData *in);
   void SetMaskInput (vtkImageData *in);
   void SetMaskedOutputValue (float v1, float v2, float v3);
   void SetMaskedOutputValue (float v1, float v2);
   void SetMaskedOutputValue (float v);
   void SetNotMask (int );


B<vtkImageMask Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   float *GetMaskedOutputValue ();
      Can't Handle 'float *' return type without a hint

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetMaskedOutputValue (int num, float *v);
      Don't know the size of pointer arg number 2

   void ThreadedExecute (vtkImageData *inDatas, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageMaskBits;


@Graphics::VTK::ImageMaskBits::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageMaskBits

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   unsigned int  *GetMasks ();
      (Returns a 4-element Perl list)
   int GetOperation ();
   vtkImageMaskBits *New ();
   void SetMask (unsigned int mask);
   void SetMasks (unsigned int , unsigned int , unsigned int , unsigned int );
   void SetMasks (unsigned int mask1, unsigned int mask2, unsigned int mask3);
   void SetMasks (unsigned int mask1, unsigned int mask2);
   void SetOperation (int );
   void SetOperationToAnd ();
   void SetOperationToNand ();
   void SetOperationToNor ();
   void SetOperationToOr ();
   void SetOperationToXor ();


B<vtkImageMaskBits Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &, vtkIndent );
      I/O Streams not Supported yet

   void SetMasks (unsigned int  a[4]);
      Arg types of 'unsigned int  *' not supported yet
   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int ext[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageMathematics;


@Graphics::VTK::ImageMathematics::ISA = qw( Graphics::VTK::ImageTwoInputFilter );

=head1 Graphics::VTK::ImageMathematics

=over 1

=item *

Inherits from ImageTwoInputFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   double GetConstantC ();
   double GetConstantK ();
   int GetOperation ();
   vtkImageMathematics *New ();
   void SetConstantC (double );
   void SetConstantK (double );
   void SetOperation (int );
   void SetOperationToATAN ();
   void SetOperationToATAN2 ();
   void SetOperationToAbsoluteValue ();
   void SetOperationToAdd ();
   void SetOperationToAddConstant ();
   void SetOperationToComplexMultiply ();
   void SetOperationToConjugate ();
   void SetOperationToCos ();
   void SetOperationToDivide ();
   void SetOperationToExp ();
   void SetOperationToInvert ();
   void SetOperationToLog ();
   void SetOperationToMax ();
   void SetOperationToMin ();
   void SetOperationToMultiply ();
   void SetOperationToMultiplyByK ();
   void SetOperationToReplaceCByK ();
   void SetOperationToSin ();
   void SetOperationToSquare ();
   void SetOperationToSquareRoot ();
   void SetOperationToSubtract ();


B<vtkImageMathematics Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inDatas, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageMedian3D;


@Graphics::VTK::ImageMedian3D::ISA = qw( Graphics::VTK::ImageSpatialFilter );

=head1 Graphics::VTK::ImageMedian3D

=over 1

=item *

Inherits from ImageSpatialFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetNumberOfElements ();
   vtkImageMedian3D *New ();
   void SetKernelSize (int size0, int size1, int size2);


B<vtkImageMedian3D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageMirrorPad;


@Graphics::VTK::ImageMirrorPad::ISA = qw( Graphics::VTK::ImagePadFilter );

=head1 Graphics::VTK::ImageMirrorPad

=over 1

=item *

Inherits from ImagePadFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageMirrorPad *New ();


B<vtkImageMirrorPad Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeInputUpdateExtent (int inExt[6], int outExt[6]);
      Don't know the size of pointer arg number 1

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outRegion, int ext[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageNoiseSource;


@Graphics::VTK::ImageNoiseSource::ISA = qw( Graphics::VTK::ImageSource );

=head1 Graphics::VTK::ImageNoiseSource

=over 1

=item *

Inherits from ImageSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetMaximum ();
   float GetMinimum ();
   vtkImageNoiseSource *New ();
   void SetMaximum (float );
   void SetMinimum (float );
   void SetWholeExtent (int xMinx, int xMax, int yMin, int yMax, int zMin, int zMax);


B<vtkImageNoiseSource Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ImageNonMaximumSuppression;


@Graphics::VTK::ImageNonMaximumSuppression::ISA = qw( Graphics::VTK::ImageTwoInputFilter );

=head1 Graphics::VTK::ImageNonMaximumSuppression

=over 1

=item *

Inherits from ImageTwoInputFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetDimensionality ();
   int GetDimensionalityMaxValue ();
   int GetDimensionalityMinValue ();
   int GetHandleBoundaries ();
   void HandleBoundariesOff ();
   void HandleBoundariesOn ();
   vtkImageNonMaximumSuppression *New ();
   void SetDimensionality (int );
   void SetHandleBoundaries (int );
   void SetMagnitudeInput (vtkImageData *input);
   void SetVectorInput (vtkImageData *input);


B<vtkImageNonMaximumSuppression Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void ComputeInputUpdateExtent (int inExt[6], int outExt[6], int whichInput);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inDatas, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageNormalize;


@Graphics::VTK::ImageNormalize::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageNormalize

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageNormalize *New ();


B<vtkImageNormalize Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageOpenClose3D;


@Graphics::VTK::ImageOpenClose3D::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageOpenClose3D

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void DebugOff ();
   void DebugOn ();
   const char *GetClassName ();
   float GetCloseValue ();
   vtkImageDilateErode3D *GetFilter0 ();
   vtkImageDilateErode3D *GetFilter1 ();
   unsigned long GetMTime ();
   float GetOpenValue ();
   vtkImageData *GetOutput (int idx);
   vtkImageData *GetOutput ();
   void Modified ();
   vtkImageOpenClose3D *New ();
   void SetCloseValue (float value);
   void SetInput (vtkImageData *Input);
   void SetKernelSize (int size0, int size1, int size2);
   void SetOpenValue (float value);


B<vtkImageOpenClose3D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ImagePadFilter;


@Graphics::VTK::ImagePadFilter::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImagePadFilter

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetOutputNumberOfScalarComponents ();
   int *GetOutputWholeExtent ();
      (Returns a 6-element Perl list)
   vtkImagePadFilter *New ();
   void SetOutputNumberOfScalarComponents (int );
   void SetOutputWholeExtent (int minX, int maxX, int minY, int maxY, int minZ, int maxZ);


B<vtkImagePadFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeInputUpdateExtent (int inExt[6], int outExt[6]);
      Don't know the size of pointer arg number 1

   void GetOutputWholeExtent (int extent[6]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetOutputWholeExtent (int extent[6]);
      Method is redundant. Same as SetOutputWholeExtent( int, int, int, int, int, int)


=cut

package Graphics::VTK::ImagePermute;


@Graphics::VTK::ImagePermute::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImagePermute

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int  *GetFilteredAxes ();
      (Returns a 3-element Perl list)
   vtkImagePermute *New ();
   void SetFilteredAxes (int , int , int );


B<vtkImagePermute Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeInputUpdateExtent (int inExt[6], int outExt[6]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetFilteredAxes (int  a[3]);
      Method is redundant. Same as SetFilteredAxes( int, int, int)

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int ext[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageQuantizeRGBToIndex;


@Graphics::VTK::ImageQuantizeRGBToIndex::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageQuantizeRGBToIndex

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   float GetBuildTreeExecuteTime ();
   const char *GetClassName ();
   float GetInitializeExecuteTime ();
   float GetLookupIndexExecuteTime ();
   vtkLookupTable *GetLookupTable ();
   int GetNumberOfColors ();
   int GetNumberOfColorsMaxValue ();
   int GetNumberOfColorsMinValue ();
   vtkImageQuantizeRGBToIndex *New ();
   void SetNumberOfColors (int );


B<vtkImageQuantizeRGBToIndex Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeInputUpdateExtent (int inExt[6], int outExt[6]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ImageRFFT;


@Graphics::VTK::ImageRFFT::ISA = qw( Graphics::VTK::ImageFourierFilter );

=head1 Graphics::VTK::ImageRFFT

=over 1

=item *

Inherits from ImageFourierFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   virtual void IterativeExecuteData (vtkImageData *in, vtkImageData *out);
   vtkImageRFFT *New ();


B<vtkImageRFFT Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeInputUpdateExtent (int inExt[6], int outExt[6]);
      Don't know the size of pointer arg number 1

   int SplitExtent (int splitExt[6], int startExt[6], int num, int total);
      Don't know the size of pointer arg number 1

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int outExt[6], int threadId);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageRGBToHSV;


@Graphics::VTK::ImageRGBToHSV::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageRGBToHSV

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetMaximum ();
   vtkImageRGBToHSV *New ();
   void SetMaximum (float );


B<vtkImageRGBToHSV Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int ext[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageRange3D;


@Graphics::VTK::ImageRange3D::ISA = qw( Graphics::VTK::ImageSpatialFilter );

=head1 Graphics::VTK::ImageRange3D

=over 1

=item *

Inherits from ImageSpatialFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageRange3D *New ();
   void SetKernelSize (int size0, int size1, int size2);


B<vtkImageRange3D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageResample;


@Graphics::VTK::ImageResample::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageResample

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   float GetAxisMagnificationFactor (int axis);
   const char *GetClassName ();
   int GetDimensionality ();
   int GetInterpolate ();
   void InterpolateOff ();
   void InterpolateOn ();
   vtkImageResample *New ();
   void SetAxisMagnificationFactor (int axis, float factor);
   void SetAxisOutputSpacing (int axis, float spacing);
   void SetDimensionality (int );
   void SetInterpolate (int );


B<vtkImageResample Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeInputUpdateExtent (int inExt[6], int outExt[6]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageReslice;


@Graphics::VTK::ImageReslice::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageReslice

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AutoCropOutputOff ();
   void AutoCropOutputOn ();
   int GetAutoCropOutput ();
   float  *GetBackgroundColor ();
      (Returns a 4-element Perl list)
   float GetBackgroundLevel ();
   const char *GetClassName ();
   vtkImageData *GetInformationInput ();
   int GetInterpolate ();
   int GetInterpolationMode ();
   const char *GetInterpolationModeAsString ();
   unsigned long GetMTime ();
   int GetMirror ();
   int GetOptimization ();
   int GetOutputDimensionality ();
   int  *GetOutputExtent ();
      (Returns a 6-element Perl list)
   float  *GetOutputOrigin ();
      (Returns a 3-element Perl list)
   float  *GetOutputSpacing ();
      (Returns a 3-element Perl list)
   vtkMatrix4x4 *GetResliceAxes ();
   double *GetResliceAxesDirectionCosines ();
      (Returns a 9-element Perl list)
   double *GetResliceAxesOrigin ();
      (Returns a 3-element Perl list)
   vtkAbstractTransform *GetResliceTransform ();
   vtkImageStencilData *GetStencil ();
   int GetTransformInputSampling ();
   int GetWrap ();
   void InterpolateOff ();
   void InterpolateOn ();
   void MirrorOff ();
   void MirrorOn ();
   vtkImageReslice *New ();
   void OptimizationOff ();
   void OptimizationOn ();
   void SetAutoCropOutput (int );
   void SetBackgroundColor (float , float , float , float );
   void SetBackgroundLevel (float v);
   void SetInformationInput (vtkImageData *);
   void SetInterpolate (int t);
   void SetInterpolationMode (int );
   void SetInterpolationModeToCubic ();
   void SetInterpolationModeToLinear ();
   void SetInterpolationModeToNearestNeighbor ();
   void SetMirror (int );
   void SetOptimization (int );
   void SetOutputDimensionality (int );
   void SetOutputExtent (int , int , int , int , int , int );
   void SetOutputExtentToDefault ();
   void SetOutputOrigin (float , float , float );
   void SetOutputOriginToDefault ();
   void SetOutputSpacing (float , float , float );
   void SetOutputSpacingToDefault ();
   void SetResliceAxes (vtkMatrix4x4 *);
   void SetResliceAxesDirectionCosines (double x0, double x1, double x2, double y0, double y1, double y2, double z0, double z1, double z2);
   void SetResliceAxesOrigin (double x, double y, double z);
   void SetResliceTransform (vtkAbstractTransform *);
   void SetStencil (vtkImageStencilData *stencil);
   void SetTransformInputSampling (int );
   void SetWrap (int );
   void TransformInputSamplingOff ();
   void TransformInputSamplingOn ();
   void WrapOff ();
   void WrapOn ();


B<vtkImageReslice Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeInputUpdateExtent (int inExt[6], int outExt[6]);
      Don't know the size of pointer arg number 1

   void GetAutoCroppedOutputBounds (vtkImageData *input, float bounds[6]);
      Don't know the size of pointer arg number 2

   void GetResliceAxesDirectionCosines (double x[3], double y[3], double z[3]);
      Don't know the size of pointer arg number 1

   void GetResliceAxesDirectionCosines (double xyz[9]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void GetResliceAxesOrigin (double xyz[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void OptimizedComputeInputUpdateExtent (int inExt[6], int outExt[6]);
      Don't know the size of pointer arg number 1

   void OptimizedThreadedExecute (vtkImageData *inData, vtkImageData *outData, int ext[6], int id);
      Don't know the size of pointer arg number 3

   virtual void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetBackgroundColor (float  a[4]);
      Method is redundant. Same as SetBackgroundColor( float, float, float, float)

   void SetOutputExtent (int  a[6]);
      Method is redundant. Same as SetOutputExtent( int, int, int, int, int, int)

   void SetOutputOrigin (float  a[3]);
      Method is redundant. Same as SetOutputOrigin( float, float, float)

   void SetOutputSpacing (float  a[3]);
      Method is redundant. Same as SetOutputSpacing( float, float, float)

   void SetResliceAxesDirectionCosines (const double x[3], const double y[3], const double z[3]);
      Don't know the size of pointer arg number 1

   void SetResliceAxesDirectionCosines (const double xyz[9]);
      Method is redundant. Same as SetResliceAxesDirectionCosines( double, double, double, double, double, double, double, double, double)

   void SetResliceAxesOrigin (const double xyz[3]);
      Method is redundant. Same as SetResliceAxesOrigin( double, double, double)

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int ext[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageSeedConnectivity;


@Graphics::VTK::ImageSeedConnectivity::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageSeedConnectivity

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddSeed (int i0, int i1, int i2);
   void AddSeed (int i0, int i1);
   const char *GetClassName ();
   vtkImageConnector *GetConnector ();
   int GetDimensionality ();
   int GetInputConnectValue ();
   int GetOutputConnectedValue ();
   int GetOutputUnconnectedValue ();
   vtkImageSeedConnectivity *New ();
   void RemoveAllSeeds ();
   void SetDimensionality (int );
   void SetInputConnectValue (int );
   void SetOutputConnectedValue (int );
   void SetOutputUnconnectedValue (int );


B<vtkImageSeedConnectivity Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void AddSeed (int num, int *index);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ImageShiftScale;


@Graphics::VTK::ImageShiftScale::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageShiftScale

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void ClampOverflowOff ();
   void ClampOverflowOn ();
   int GetClampOverflow ();
   const char *GetClassName ();
   int GetOutputScalarType ();
   float GetScale ();
   float GetShift ();
   vtkImageShiftScale *New ();
   void SetClampOverflow (int );
   void SetOutputScalarType (int );
   void SetOutputScalarTypeToChar ();
   void SetOutputScalarTypeToDouble ();
   void SetOutputScalarTypeToFloat ();
   void SetOutputScalarTypeToInt ();
   void SetOutputScalarTypeToLong ();
   void SetOutputScalarTypeToShort ();
   void SetOutputScalarTypeToUnsignedChar ();
   void SetOutputScalarTypeToUnsignedInt ();
   void SetOutputScalarTypeToUnsignedLong ();
   void SetOutputScalarTypeToUnsignedShort ();
   void SetScale (float );
   void SetShift (float );


B<vtkImageShiftScale Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageShrink3D;


@Graphics::VTK::ImageShrink3D::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageShrink3D

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AveragingOff ();
   void AveragingOn ();
   int GetAveraging ();
   const char *GetClassName ();
   int GetMaximum ();
   int GetMean ();
   int GetMedian ();
   int GetMinimum ();
   int  *GetShift ();
      (Returns a 3-element Perl list)
   int  *GetShrinkFactors ();
      (Returns a 3-element Perl list)
   void MaximumOff ();
   void MaximumOn ();
   void MeanOff ();
   void MeanOn ();
   void MedianOff ();
   void MedianOn ();
   void MinimumOff ();
   void MinimumOn ();
   vtkImageShrink3D *New ();
   void SetAveraging (int );
   void SetMaximum (int );
   void SetMean (int );
   void SetMedian (int );
   void SetMinimum (int );
   void SetShift (int , int , int );
   void SetShrinkFactors (int , int , int );


B<vtkImageShrink3D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeInputUpdateExtent (int inExt[6], int outExt[6]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetShift (int  a[3]);
      Method is redundant. Same as SetShift( int, int, int)

   void SetShrinkFactors (int  a[3]);
      Method is redundant. Same as SetShrinkFactors( int, int, int)

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int ext[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageSinusoidSource;


@Graphics::VTK::ImageSinusoidSource::ISA = qw( Graphics::VTK::ImageSource );

=head1 Graphics::VTK::ImageSinusoidSource

=over 1

=item *

Inherits from ImageSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   float GetAmplitude ();
   const char *GetClassName ();
   float  *GetDirection ();
      (Returns a 3-element Perl list)
   float GetPeriod ();
   float GetPhase ();
   vtkImageSinusoidSource *New ();
   void SetAmplitude (float );
   void SetDirection (float , float , float );
   void SetPeriod (float );
   void SetPhase (float );
   void SetWholeExtent (int xMinx, int xMax, int yMin, int yMax, int zMin, int zMax);


B<vtkImageSinusoidSource Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetDirection (float dir[3]);
      Method is redundant. Same as SetDirection( float, float, float)


=cut

package Graphics::VTK::ImageSkeleton2D;


@Graphics::VTK::ImageSkeleton2D::ISA = qw( Graphics::VTK::ImageIterateFilter );

=head1 Graphics::VTK::ImageSkeleton2D

=over 1

=item *

Inherits from ImageIterateFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetPrune ();
   virtual void IterativeExecuteData (vtkImageData *in, vtkImageData *out);
   vtkImageSkeleton2D *New ();
   void PruneOff ();
   void PruneOn ();
   void SetNumberOfIterations (int num);
   void SetPrune (int );


B<vtkImageSkeleton2D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeInputUpdateExtent (int inExt[6], int outExt[6]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int outExt[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageSobel2D;


@Graphics::VTK::ImageSobel2D::ISA = qw( Graphics::VTK::ImageSpatialFilter );

=head1 Graphics::VTK::ImageSobel2D

=over 1

=item *

Inherits from ImageSpatialFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageSobel2D *New ();


B<vtkImageSobel2D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int outExt[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageSobel3D;


@Graphics::VTK::ImageSobel3D::ISA = qw( Graphics::VTK::ImageSpatialFilter );

=head1 Graphics::VTK::ImageSobel3D

=over 1

=item *

Inherits from ImageSpatialFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageSobel3D *New ();


B<vtkImageSobel3D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int outExt[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageSpatialFilter;


@Graphics::VTK::ImageSpatialFilter::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageSpatialFilter

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int *GetKernelMiddle ();
      (Returns a 3-element Perl list)
   int *GetKernelSize ();
      (Returns a 3-element Perl list)
   vtkImageSpatialFilter *New ();


B<vtkImageSpatialFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeInputUpdateExtent (int extent[6], int wholeExtent[6]);
      Don't know the size of pointer arg number 1

   void ComputeOutputWholeExtent (int extent[6], int handleBoundaries);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ImageStencil;


@Graphics::VTK::ImageStencil::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageStencil

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   float  *GetBackgroundColor ();
      (Returns a 4-element Perl list)
   vtkImageData *GetBackgroundInput ();
   float GetBackgroundValue ();
   const char *GetClassName ();
   int GetReverseStencil ();
   vtkImageStencilData *GetStencil ();
   vtkImageStencil *New ();
   void ReverseStencilOff ();
   void ReverseStencilOn ();
   void SetBackgroundColor (float , float , float , float );
   virtual void SetBackgroundInput (vtkImageData *input);
   void SetBackgroundValue (float val);
   void SetReverseStencil (int );
   virtual void SetStencil (vtkImageStencilData *stencil);


B<vtkImageStencil Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetBackgroundColor (float  a[4]);
      Method is redundant. Same as SetBackgroundColor( float, float, float, float)

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageStencilData;


@Graphics::VTK::ImageStencilData::ISA = qw( Graphics::VTK::DataObject );

=head1 Graphics::VTK::ImageStencilData

=over 1

=item *

Inherits from DataObject

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AllocateExtents ();
   void DeepCopy (vtkDataObject *o);
   const char *GetClassName ();
   int GetDataObjectType ();
   int  *GetExtent ();
      (Returns a 6-element Perl list)
   int GetExtentType ();
   int GetNextExtent (int &r1, int &r2, int xMin, int xMax, int yIdx, int zIdx, int &iter);
   float  *GetOldOrigin ();
      (Returns a 3-element Perl list)
   float  *GetOldSpacing ();
      (Returns a 3-element Perl list)
   float  *GetOrigin ();
      (Returns a 3-element Perl list)
   float  *GetSpacing ();
      (Returns a 3-element Perl list)
   void Initialize ();
   void InsertNextExtent (int r1, int r2, int yIdx, int zIdx);
   void InternalImageStencilDataCopy (vtkImageStencilData *s);
   vtkImageStencilData *New ();
   void PropagateUpdateExtent ();
   void SetExtent (int , int , int , int , int , int );
   void SetOldOrigin (float , float , float );
   void SetOldSpacing (float , float , float );
   void SetOrigin (float , float , float );
   void SetSpacing (float , float , float );
   void ShallowCopy (vtkDataObject *f);
   void TriggerAsynchronousUpdate ();
   void UpdateData ();


B<vtkImageStencilData Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetExtent (int  a[6]);
      Method is redundant. Same as SetExtent( int, int, int, int, int, int)

   void SetOldOrigin (float  a[3]);
      Method is redundant. Same as SetOldOrigin( float, float, float)

   void SetOldSpacing (float  a[3]);
      Method is redundant. Same as SetOldSpacing( float, float, float)

   void SetOrigin (float  a[3]);
      Method is redundant. Same as SetOrigin( float, float, float)

   void SetSpacing (float  a[3]);
      Method is redundant. Same as SetSpacing( float, float, float)


=cut

package Graphics::VTK::ImageStencilSource;


@Graphics::VTK::ImageStencilSource::ISA = qw( Graphics::VTK::Source );

=head1 Graphics::VTK::ImageStencilSource

=over 1

=item *

Inherits from Source

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageStencilData *GetOutput ();
   vtkImageStencilSource *New ();
   void SetOutput (vtkImageStencilData *output);


B<vtkImageStencilSource Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   virtual void ThreadedExecute (vtkImageStencilData *output, int extent[6], int threadId);
      Don't know the size of pointer arg number 2


=cut

package Graphics::VTK::ImageThreshold;


@Graphics::VTK::ImageThreshold::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageThreshold

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetInValue ();
   float GetLowerThreshold ();
   float GetOutValue ();
   int GetOutputScalarType ();
   int GetReplaceIn ();
   int GetReplaceOut ();
   float GetUpperThreshold ();
   vtkImageThreshold *New ();
   void ReplaceInOff ();
   void ReplaceInOn ();
   void ReplaceOutOff ();
   void ReplaceOutOn ();
   void SetInValue (float val);
   void SetOutValue (float val);
   void SetOutputScalarType (int );
   void SetOutputScalarTypeToChar ();
   void SetOutputScalarTypeToDouble ();
   void SetOutputScalarTypeToFloat ();
   void SetOutputScalarTypeToInt ();
   void SetOutputScalarTypeToLong ();
   void SetOutputScalarTypeToShort ();
   void SetOutputScalarTypeToUnsignedChar ();
   void SetOutputScalarTypeToUnsignedInt ();
   void SetOutputScalarTypeToUnsignedLong ();
   void SetOutputScalarTypeToUnsignedShort ();
   void SetReplaceIn (int );
   void SetReplaceOut (int );
   void ThresholdBetween (float lower, float upper);
   void ThresholdByLower (float thresh);
   void ThresholdByUpper (float thresh);


B<vtkImageThreshold Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageToImageStencil;


@Graphics::VTK::ImageToImageStencil::ISA = qw( Graphics::VTK::ImageStencilSource );

=head1 Graphics::VTK::ImageToImageStencil

=over 1

=item *

Inherits from ImageStencilSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageData *GetInput ();
   float GetLowerThreshold ();
   float GetUpperThreshold ();
   vtkImageToImageStencil *New ();
   void SetInput (vtkImageData *input);
   void SetLowerThreshold (float );
   void SetUpperThreshold (float );
   void ThresholdBetween (float lower, float upper);
   void ThresholdByLower (float thresh);
   void ThresholdByUpper (float thresh);


B<vtkImageToImageStencil Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageStencilData *output, int extent[6], int threadId);
      Don't know the size of pointer arg number 2


=cut

package Graphics::VTK::ImageTranslateExtent;


@Graphics::VTK::ImageTranslateExtent::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageTranslateExtent

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int  *GetTranslation ();
      (Returns a 3-element Perl list)
   vtkImageTranslateExtent *New ();
   void SetTranslation (int , int , int );


B<vtkImageTranslateExtent Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeInputUpdateExtent (int extent[6], int wholeExtent[6]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetTranslation (int  a[3]);
      Method is redundant. Same as SetTranslation( int, int, int)


=cut

package Graphics::VTK::ImageVariance3D;


@Graphics::VTK::ImageVariance3D::ISA = qw( Graphics::VTK::ImageSpatialFilter );

=head1 Graphics::VTK::ImageVariance3D

=over 1

=item *

Inherits from ImageSpatialFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageVariance3D *New ();
   void SetKernelSize (int size0, int size1, int size2);


B<vtkImageVariance3D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int extent[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageWrapPad;


@Graphics::VTK::ImageWrapPad::ISA = qw( Graphics::VTK::ImagePadFilter );

=head1 Graphics::VTK::ImageWrapPad

=over 1

=item *

Inherits from ImagePadFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageWrapPad *New ();


B<vtkImageWrapPad Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeInputUpdateExtent (int inExt[6], int outExt[6]);
      Don't know the size of pointer arg number 1

   void ThreadedExecute (vtkImageData *inData, vtkImageData *outRegion, int ext[6], int id);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImplicitFunctionToImageStencil;


@Graphics::VTK::ImplicitFunctionToImageStencil::ISA = qw( Graphics::VTK::ImageStencilSource );

=head1 Graphics::VTK::ImplicitFunctionToImageStencil

=over 1

=item *

Inherits from ImageStencilSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImplicitFunction *GetInput ();
   float GetThreshold ();
   vtkImplicitFunctionToImageStencil *New ();
   void SetInput (vtkImplicitFunction *);
   void SetThreshold (float );


B<vtkImplicitFunctionToImageStencil Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageStencilData *output, int extent[6], int threadId);
      Don't know the size of pointer arg number 2


=cut

package Graphics::VTK::PointLoad;


@Graphics::VTK::PointLoad::ISA = qw( Graphics::VTK::StructuredPointsSource );

=head1 Graphics::VTK::PointLoad

=over 1

=item *

Inherits from StructuredPointsSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void ComputeEffectiveStressOff ();
   void ComputeEffectiveStressOn ();
   const char *GetClassName ();
   int GetComputeEffectiveStress ();
   float GetLoadValue ();
   float  *GetModelBounds ();
      (Returns a 6-element Perl list)
   float GetPoissonsRatio ();
   int  *GetSampleDimensions ();
      (Returns a 3-element Perl list)
   vtkPointLoad *New ();
   void SetComputeEffectiveStress (int );
   void SetLoadValue (float );
   void SetModelBounds (float , float , float , float , float , float );
   void SetPoissonsRatio (float );
   void SetSampleDimensions (int i, int j, int k);


B<vtkPointLoad Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetModelBounds (float  a[6]);
      Method is redundant. Same as SetModelBounds( float, float, float, float, float, float)

   void SetSampleDimensions (int dim[3]);
      Method is redundant. Same as SetSampleDimensions( int, int, int)


=cut

package Graphics::VTK::SampleFunction;


@Graphics::VTK::SampleFunction::ISA = qw( Graphics::VTK::StructuredPointsSource );

=head1 Graphics::VTK::SampleFunction

=over 1

=item *

Inherits from StructuredPointsSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CappingOff ();
   void CappingOn ();
   void ComputeNormalsOff ();
   void ComputeNormalsOn ();
   float GetCapValue ();
   int GetCapping ();
   const char *GetClassName ();
   int GetComputeNormals ();
   vtkImplicitFunction *GetImplicitFunction ();
   unsigned long GetMTime ();
   float  *GetModelBounds ();
      (Returns a 6-element Perl list)
   int  *GetSampleDimensions ();
      (Returns a 3-element Perl list)
   vtkSampleFunction *New ();
   void SetCapValue (float );
   void SetCapping (int );
   void SetComputeNormals (int );
   void SetImplicitFunction (vtkImplicitFunction *);
   void SetModelBounds (float , float , float , float , float , float );
   void SetSampleDimensions (int i, int j, int k);
   void SetScalars (vtkDataArray *);


B<vtkSampleFunction Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetModelBounds (float  a[6]);
      Method is redundant. Same as SetModelBounds( float, float, float, float, float, float)

   void SetSampleDimensions (int dim[3]);
      Method is redundant. Same as SetSampleDimensions( int, int, int)


=cut

package Graphics::VTK::ShepardMethod;


@Graphics::VTK::ShepardMethod::ISA = qw( Graphics::VTK::DataSetToStructuredPointsFilter );

=head1 Graphics::VTK::ShepardMethod

=over 1

=item *

Inherits from DataSetToStructuredPointsFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetMaximumDistance ();
   float GetMaximumDistanceMaxValue ();
   float GetMaximumDistanceMinValue ();
   float  *GetModelBounds ();
      (Returns a 6-element Perl list)
   float GetNullValue ();
   int  *GetSampleDimensions ();
      (Returns a 3-element Perl list)
   vtkShepardMethod *New ();
   void SetMaximumDistance (float );
   void SetModelBounds (float , float , float , float , float , float );
   void SetNullValue (float );
   void SetSampleDimensions (int i, int j, int k);


B<vtkShepardMethod Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   float ComputeModelBounds (float origin[3], float ar[3]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetModelBounds (float  a[6]);
      Method is redundant. Same as SetModelBounds( float, float, float, float, float, float)

   void SetSampleDimensions (int dim[3]);
      Method is redundant. Same as SetSampleDimensions( int, int, int)


=cut

package Graphics::VTK::SimpleImageFilterExample;


@Graphics::VTK::SimpleImageFilterExample::ISA = qw( Graphics::VTK::SimpleImageToImageFilter );

=head1 Graphics::VTK::SimpleImageFilterExample

=over 1

=item *

Inherits from SimpleImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkSimpleImageFilterExample *New ();

=cut

package Graphics::VTK::SurfaceReconstructionFilter;


@Graphics::VTK::SurfaceReconstructionFilter::ISA = qw( Graphics::VTK::DataSetToStructuredPointsFilter );

=head1 Graphics::VTK::SurfaceReconstructionFilter

=over 1

=item *

Inherits from DataSetToStructuredPointsFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetNeighborhoodSize ();
   float GetSampleSpacing ();
   vtkSurfaceReconstructionFilter *New ();
   void SetNeighborhoodSize (int );
   void SetSampleSpacing (float );


B<vtkSurfaceReconstructionFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::TriangularTexture;


@Graphics::VTK::TriangularTexture::ISA = qw( Graphics::VTK::StructuredPointsSource );

=head1 Graphics::VTK::TriangularTexture

=over 1

=item *

Inherits from StructuredPointsSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetScaleFactor ();
   int GetTexturePattern ();
   int GetTexturePatternMaxValue ();
   int GetTexturePatternMinValue ();
   int GetXSize ();
   int GetYSize ();
   vtkTriangularTexture *New ();
   void SetScaleFactor (float );
   void SetTexturePattern (int );
   void SetXSize (int );
   void SetYSize (int );


B<vtkTriangularTexture Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::VoxelModeller;


@Graphics::VTK::VoxelModeller::ISA = qw( Graphics::VTK::DataSetToStructuredPointsFilter );

=head1 Graphics::VTK::VoxelModeller

=over 1

=item *

Inherits from DataSetToStructuredPointsFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetMaximumDistance ();
   float GetMaximumDistanceMaxValue ();
   float GetMaximumDistanceMinValue ();
   float  *GetModelBounds ();
      (Returns a 6-element Perl list)
   int  *GetSampleDimensions ();
      (Returns a 3-element Perl list)
   vtkVoxelModeller *New ();
   void SetMaximumDistance (float );
   void SetModelBounds (float xmin, float xmax, float ymin, float ymax, float zmin, float zmax);
   void SetSampleDimensions (int i, int j, int k);
   void Write (char *);


B<vtkVoxelModeller Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   float ComputeModelBounds (float origin[3], float ar[3]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetModelBounds (float bounds[6]);
      Method is redundant. Same as SetModelBounds( float, float, float, float, float, float)

   void SetSampleDimensions (int dim[3]);
      Method is redundant. Same as SetSampleDimensions( int, int, int)


=cut

package Graphics::VTK::WindowToImageFilter;


@Graphics::VTK::WindowToImageFilter::ISA = qw( Graphics::VTK::ImageSource );

=head1 Graphics::VTK::WindowToImageFilter

=over 1

=item *

Inherits from ImageSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkWindow *GetInput ();
   vtkWindowToImageFilter *New ();
   void SetInput (vtkWindow *input);


B<vtkWindowToImageFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

1;
