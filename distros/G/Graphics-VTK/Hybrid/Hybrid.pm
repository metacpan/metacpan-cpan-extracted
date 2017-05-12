
package Graphics::VTK::Hybrid;
use 5.004;
use strict;
use Carp;

use vars qw/ $VERSION @ISA/;

require DynaLoader;

$VERSION = '4.0.001';

@ISA = qw/ DynaLoader /;

bootstrap Graphics::VTK::Hybrid $VERSION;


=head1 NAME

VTKHybrid  - A Perl interface to VTKHybrid library

=head1 SYNOPSIS

C<use Graphics::VTK;>
C<use Graphics::VTK::Hybrid;>

=head1 DESCRIPTION

Graphics::VTK::Hybrid is an interface to the Hybrid libaray of the C++ visualization toolkit VTK..

=head1 AUTHOR

Original PerlVTK Package: Roberto De Leo <rdl@math.umd.edu>

Additional Refinements: John Cerney <j-cerney1@raytheon.com>

=cut

package Graphics::VTK::3DSImporter;


@Graphics::VTK::3DSImporter::ISA = qw( Graphics::VTK::Importer );

=head1 Graphics::VTK::3DSImporter

=over 1

=item *

Inherits from Importer

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void ComputeNormalsOff ();
   void ComputeNormalsOn ();
   const char *GetClassName ();
   int GetComputeNormals ();
   FILE *GetFileFD ();
   char *GetFileName ();
   vtk3DSImporter *New ();
   void SetComputeNormals (int );
   void SetFileName (char *);


B<vtk3DSImporter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   vtkPolyData *GeneratePolyData (Mesh *meshPtr);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ArcPlotter;


@Graphics::VTK::ArcPlotter::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::ArcPlotter

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   vtkCamera *GetCamera ();
   const char *GetClassName ();
   float  *GetDefaultNormal ();
      (Returns a 3-element Perl list)
   int GetFieldDataArray ();
   int GetFieldDataArrayMaxValue ();
   int GetFieldDataArrayMinValue ();
   float GetHeight ();
   float GetHeightMaxValue ();
   float GetHeightMinValue ();
   unsigned long GetMTime ();
   float GetOffset ();
   float GetOffsetMaxValue ();
   float GetOffsetMinValue ();
   int GetPlotComponent ();
   int GetPlotMode ();
   float GetRadius ();
   float GetRadiusMaxValue ();
   float GetRadiusMinValue ();
   int GetUseDefaultNormal ();
   vtkArcPlotter *New ();
   void SetCamera (vtkCamera *);
   void SetDefaultNormal (float , float , float );
   void SetFieldDataArray (int );
   void SetHeight (float );
   void SetOffset (float );
   void SetPlotComponent (int );
   void SetPlotMode (int );
   void SetPlotModeToPlotFieldData ();
   void SetPlotModeToPlotNormals ();
   void SetPlotModeToPlotScalars ();
   void SetPlotModeToPlotTCoords ();
   void SetPlotModeToPlotTensors ();
   void SetPlotModeToPlotVectors ();
   void SetRadius (float );
   void SetUseDefaultNormal (int );
   void UseDefaultNormalOff ();
   void UseDefaultNormalOn ();


B<vtkArcPlotter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int OffsetPoint (long ptId, vtkPoints *inPts, float n[3], vtkPoints *newPts, float offset, float *range, float val);
      Don't know the size of pointer arg number 3

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetDefaultNormal (float  a[3]);
      Method is redundant. Same as SetDefaultNormal( float, float, float)


=cut

package Graphics::VTK::CaptionActor2D;


@Graphics::VTK::CaptionActor2D::ISA = qw( Graphics::VTK::Actor2D );

=head1 Graphics::VTK::CaptionActor2D

=over 1

=item *

Inherits from Actor2D

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void BoldOff ();
   void BoldOn ();
   void BorderOff ();
   void BorderOn ();
   float *GetAttachmentPoint ();
      (Returns a 3-element Perl list)
   vtkCoordinate *GetAttachmentPointCoordinate ();
   int GetBold ();
   int GetBorder ();
   char *GetCaption ();
   const char *GetClassName ();
   int GetFontFamily ();
   int GetItalic ();
   int GetJustification ();
   int GetJustificationMaxValue ();
   int GetJustificationMinValue ();
   int GetLeader ();
   vtkPolyData *GetLeaderGlyph ();
   float GetLeaderGlyphSize ();
   float GetLeaderGlyphSizeMaxValue ();
   float GetLeaderGlyphSizeMinValue ();
   int GetMaximumLeaderGlyphSize ();
   int GetMaximumLeaderGlyphSizeMaxValue ();
   int GetMaximumLeaderGlyphSizeMinValue ();
   int GetPadding ();
   int GetPaddingMaxValue ();
   int GetPaddingMinValue ();
   int GetShadow ();
   int GetThreeDimensionalLeader ();
   int GetVerticalJustification ();
   int GetVerticalJustificationMaxValue ();
   int GetVerticalJustificationMinValue ();
   void ItalicOff ();
   void ItalicOn ();
   void LeaderOff ();
   void LeaderOn ();
   vtkCaptionActor2D *New ();
   void SetAttachmentPoint (float, float, float);
   void SetBold (int );
   void SetBorder (int );
   void SetCaption (char *);
   void SetFontFamily (int );
   void SetFontFamilyToArial ();
   void SetFontFamilyToCourier ();
   void SetFontFamilyToTimes ();
   void SetItalic (int );
   void SetJustification (int );
   void SetJustificationToCentered ();
   void SetJustificationToLeft ();
   void SetJustificationToRight ();
   void SetLeader (int );
   void SetLeaderGlyph (vtkPolyData *);
   void SetLeaderGlyphSize (float );
   void SetMaximumLeaderGlyphSize (int );
   void SetPadding (int );
   void SetShadow (int );
   void SetThreeDimensionalLeader (int );
   void SetVerticalJustification (int );
   void SetVerticalJustificationToBottom ();
   void SetVerticalJustificationToCentered ();
   void SetVerticalJustificationToTop ();
   void ShadowOff ();
   void ShadowOn ();
   void ShallowCopy (vtkProp *prop);
   void ThreeDimensionalLeaderOff ();
   void ThreeDimensionalLeaderOn ();


B<vtkCaptionActor2D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetAttachmentPoint (float a[3]);
      Method is redundant. Same as SetAttachmentPoint( float, float, float)


=cut

package Graphics::VTK::CubeAxesActor2D;


@Graphics::VTK::CubeAxesActor2D::ISA = qw( Graphics::VTK::Actor2D );

=head1 Graphics::VTK::CubeAxesActor2D

=over 1

=item *

Inherits from Actor2D

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void BoldOff ();
   void BoldOn ();
   int GetBold ();
   void GetBounds (float &xmin, float &xmax, float &ymin, float &ymax, float &zmin, float &zmax);
   float *GetBounds ();
      (Returns a 6-element Perl list)
   vtkCamera *GetCamera ();
   const char *GetClassName ();
   float GetCornerOffset ();
   int GetFlyMode ();
   int GetFlyModeMaxValue ();
   int GetFlyModeMinValue ();
   float GetFontFactor ();
   float GetFontFactorMaxValue ();
   float GetFontFactorMinValue ();
   int GetFontFamily ();
   float GetInertia ();
   int GetInertiaMaxValue ();
   int GetInertiaMinValue ();
   vtkDataSet *GetInput ();
   int GetItalic ();
   char *GetLabelFormat ();
   int GetNumberOfLabels ();
   int GetNumberOfLabelsMaxValue ();
   int GetNumberOfLabelsMinValue ();
   vtkProp *GetProp ();
   void GetRanges (float &xmin, float &xmax, float &ymin, float &ymax, float &zmin, float &zmax);
   int GetScaling ();
   int GetShadow ();
   int GetUseRanges ();
   int GetXAxisVisibility ();
   char *GetXLabel ();
   int GetYAxisVisibility ();
   char *GetYLabel ();
   int GetZAxisVisibility ();
   char *GetZLabel ();
   void ItalicOff ();
   void ItalicOn ();
   vtkCubeAxesActor2D *New ();
   void ReleaseGraphicsResources (vtkWindow *);
   int RenderOpaqueGeometry (vtkViewport *);
   int RenderOverlay (vtkViewport *);
   int RenderTranslucentGeometry (vtkViewport *);
   void ScalingOff ();
   void ScalingOn ();
   void SetBold (int );
   void SetBounds (float , float , float , float , float , float );
   void SetCamera (vtkCamera *);
   void SetCornerOffset (float );
   void SetFlyMode (int );
   void SetFlyModeToClosestTriad ();
   void SetFlyModeToOuterEdges ();
   void SetFontFactor (float );
   void SetFontFamily (int );
   void SetFontFamilyToArial ();
   void SetFontFamilyToCourier ();
   void SetFontFamilyToTimes ();
   void SetInertia (int );
   void SetInput (vtkDataSet *);
   void SetItalic (int );
   void SetLabelFormat (char *);
   void SetNumberOfLabels (int );
   void SetProp (vtkProp *);
   void SetRanges (float , float , float , float , float , float );
   void SetScaling (int );
   void SetShadow (int );
   void SetUseRanges (int );
   void SetXAxisVisibility (int );
   void SetXLabel (char *);
   void SetYAxisVisibility (int );
   void SetYLabel (char *);
   void SetZAxisVisibility (int );
   void SetZLabel (char *);
   void ShadowOff ();
   void ShadowOn ();
   void ShallowCopy (vtkCubeAxesActor2D *actor);
   void UseRangesOff ();
   void UseRangesOn ();
   void XAxisVisibilityOff ();
   void XAxisVisibilityOn ();
   void YAxisVisibilityOff ();
   void YAxisVisibilityOn ();
   void ZAxisVisibilityOff ();
   void ZAxisVisibilityOn ();


B<vtkCubeAxesActor2D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void AdjustAxes (float pts[8][3], float bounds[6], int idx, int xIdx, int yIdx, int zIdx, int zIdx2, int xAxes, int yAxes, int zAxes, float xCoords[4], float yCoords[4], float zCoords[4], float xRange[2], float yRange[2], float zRange[2]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   int ClipBounds (vtkViewport *viewport, float pts[8][3], float bounds[6]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   float EvaluateBounds (float planes[24], float bounds[6]);
      Don't know the size of pointer arg number 1

   float EvaluatePoint (float planes[24], float x[3]);
      Don't know the size of pointer arg number 1

   void GetBounds (float bounds[6]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   float *GetRanges ();
      Can't Handle 'float *' return type without a hint

   void GetRanges (float ranges[6]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetBounds (float  a[6]);
      Method is redundant. Same as SetBounds( float, float, float, float, float, float)

   void SetRanges (float  a[6]);
      Method is redundant. Same as SetRanges( float, float, float, float, float, float)

   void TransformBounds (vtkViewport *viewport, float bounds[6], float pts[8][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.


=cut

package Graphics::VTK::DepthSortPolyData;


@Graphics::VTK::DepthSortPolyData::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::DepthSortPolyData

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   vtkCamera *GetCamera ();
   const char *GetClassName ();
   int GetDepthSortMode ();
   int GetDirection ();
   unsigned long GetMTime ();
   double  *GetOrigin ();
      (Returns a 3-element Perl list)
   vtkProp3D *GetProp3D ();
   int GetSortScalars ();
   double  *GetVector ();
      (Returns a 3-element Perl list)
   vtkDepthSortPolyData *New ();
   void SetCamera (vtkCamera *);
   void SetDepthSortMode (int );
   void SetDepthSortModeToBoundsCenter ();
   void SetDepthSortModeToFirstPoint ();
   void SetDepthSortModeToParametricCenter ();
   void SetDirection (int );
   void SetDirectionToBackToFront ();
   void SetDirectionToFrontToBack ();
   void SetDirectionToSpecifiedVector ();
   void SetOrigin (double , double , double );
   void SetProp3D (vtkProp3D *);
   void SetSortScalars (int );
   void SetVector (double , double , double );
   void SortScalarsOff ();
   void SortScalarsOn ();


B<vtkDepthSortPolyData Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeProjectionVector (double vector[3], double origin[3]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetOrigin (double  a[3]);
      Method is redundant. Same as SetOrigin( double, double, double)

   void SetVector (double  a[3]);
      Method is redundant. Same as SetVector( double, double, double)


=cut

package Graphics::VTK::EarthSource;


@Graphics::VTK::EarthSource::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::EarthSource

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetOnRatio ();
   int GetOnRatioMaxValue ();
   int GetOnRatioMinValue ();
   int GetOutline ();
   float GetRadius ();
   float GetRadiusMaxValue ();
   float GetRadiusMinValue ();
   vtkEarthSource *New ();
   void OutlineOff ();
   void OutlineOn ();
   void SetOnRatio (int );
   void SetOutline (int );
   void SetRadius (float );


B<vtkEarthSource Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::GridTransform;


@Graphics::VTK::GridTransform::ISA = qw( Graphics::VTK::WarpTransform );

=head1 Graphics::VTK::GridTransform

=over 1

=item *

Inherits from WarpTransform

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageData *GetDisplacementGrid ();
   float GetDisplacementScale ();
   float GetDisplacementShift ();
   int GetInterpolationMode ();
   const char *GetInterpolationModeAsString ();
   unsigned long GetMTime ();
   vtkAbstractTransform *MakeTransform ();
   vtkGridTransform *New ();
   void SetDisplacementGrid (vtkImageData *);
   void SetDisplacementScale (float );
   void SetDisplacementShift (float );
   void SetInterpolationMode (int mode);
   void SetInterpolationModeToCubic ();
   void SetInterpolationModeToLinear ();
   void SetInterpolationModeToNearestNeighbor ();


B<vtkGridTransform Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ForwardTransformDerivative (const float in[3], float out[3], float derivative[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void ForwardTransformDerivative (const double in[3], double out[3], double derivative[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void ForwardTransformPoint (const float in[3], float out[3]);
      Don't know the size of pointer arg number 1

   void ForwardTransformPoint (const double in[3], double out[3]);
      Don't know the size of pointer arg number 1

   void InverseTransformDerivative (const float in[3], float out[3], float derivative[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void InverseTransformDerivative (const double in[3], double out[3], double derivative[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void InverseTransformPoint (const float in[3], float out[3]);
      Don't know the size of pointer arg number 1

   void InverseTransformPoint (const double in[3], double out[3]);
      Don't know the size of pointer arg number 1

   virtual void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ImageToPolyDataFilter;


@Graphics::VTK::ImageToPolyDataFilter::ISA = qw( Graphics::VTK::StructuredPointsToPolyDataFilter );

=head1 Graphics::VTK::ImageToPolyDataFilter

=over 1

=item *

Inherits from StructuredPointsToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void DecimationOff ();
   void DecimationOn ();
   const char *GetClassName ();
   int GetColorMode ();
   int GetColorModeMaxValue ();
   int GetColorModeMinValue ();
   int GetDecimation ();
   float GetDecimationError ();
   float GetDecimationErrorMaxValue ();
   float GetDecimationErrorMinValue ();
   int GetError ();
   int GetErrorMaxValue ();
   int GetErrorMinValue ();
   vtkScalarsToColors *GetLookupTable ();
   int GetNumberOfSmoothingIterations ();
   int GetNumberOfSmoothingIterationsMaxValue ();
   int GetNumberOfSmoothingIterationsMinValue ();
   int GetOutputStyle ();
   int GetOutputStyleMaxValue ();
   int GetOutputStyleMinValue ();
   int GetSmoothing ();
   int GetSubImageSize ();
   int GetSubImageSizeMaxValue ();
   int GetSubImageSizeMinValue ();
   vtkImageToPolyDataFilter *New ();
   void SetColorMode (int );
   void SetColorModeToLUT ();
   void SetColorModeToLinear256 ();
   void SetDecimation (int );
   void SetDecimationError (float );
   void SetError (int );
   void SetLookupTable (vtkScalarsToColors *);
   void SetNumberOfSmoothingIterations (int );
   void SetOutputStyle (int );
   void SetOutputStyleToPixelize ();
   void SetOutputStyleToPolygonalize ();
   void SetOutputStyleToRunLength ();
   void SetSmoothing (int );
   void SetSubImageSize (int );
   void SmoothingOff ();
   void SmoothingOn ();


B<vtkImageToPolyDataFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int BuildEdges (vtkUnsignedCharArray *pixels, int dims[3], float origin[3], float spacing[3], vtkUnsignedCharArray *pointDescr, vtkPolyData *edges);
      Don't know the size of pointer arg number 2

   void BuildTable (unsigned char *inPixels);
      Don't know the size of pointer arg number 1

   unsigned char *GetColor (unsigned char *rgb);
      Can't Handle 'unsigned char *' return type without a hint

   void GetIJ (int id, int &i, int &j, int dims[3]);
      Don't know the size of pointer arg number 4

   int GetNeighbors (unsigned char *ptr, int &i, int &j, int dims[3], unsigned char *neighbors[4], int mode);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   int IsSameColor (unsigned char *p1, unsigned char *p2);
      Don't know the size of pointer arg number 1

   virtual void PixelizeImage (vtkUnsignedCharArray *pixels, int dims[3], float origin[3], float spacing[3], vtkPolyData *output);
      Don't know the size of pointer arg number 2

   virtual void PolygonalizeImage (vtkUnsignedCharArray *pixels, int dims[3], float origin[3], float spacing[3], vtkPolyData *output);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   int ProcessImage (vtkUnsignedCharArray *pixels, int dims[2]);
      Don't know the size of pointer arg number 2

   vtkUnsignedCharArray *QuantizeImage (vtkDataArray *inScalars, int numComp, int type, int dims[3], int ext[4]);
      Don't know the size of pointer arg number 4

   virtual void RunLengthImage (vtkUnsignedCharArray *pixels, int dims[3], float origin[3], float spacing[3], vtkPolyData *output);
      Don't know the size of pointer arg number 2


=cut

package Graphics::VTK::ImplicitModeller;


@Graphics::VTK::ImplicitModeller::ISA = qw( Graphics::VTK::DataSetToStructuredPointsFilter );

=head1 Graphics::VTK::ImplicitModeller

=over 1

=item *

Inherits from DataSetToStructuredPointsFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AdjustBoundsOff ();
   void AdjustBoundsOn ();
   void Append (vtkDataSet *input);
   void CappingOff ();
   void CappingOn ();
   float ComputeModelBounds (vtkDataSet *inputNULL);
   void EndAppend ();
   int GetAdjustBounds ();
   float GetAdjustDistance ();
   float GetAdjustDistanceMaxValue ();
   float GetAdjustDistanceMinValue ();
   float GetCapValue ();
   int GetCapping ();
   const char *GetClassName ();
   int GetLocatorMaxLevel ();
   float GetMaximumDistance ();
   float GetMaximumDistanceMaxValue ();
   float GetMaximumDistanceMinValue ();
   float  *GetModelBounds ();
      (Returns a 6-element Perl list)
   int GetNumberOfThreads ();
   int GetProcessMode ();
   const char *GetProcessModeAsString (void );
   int GetProcessModeMaxValue ();
   int GetProcessModeMinValue ();
   int  *GetSampleDimensions ();
      (Returns a 3-element Perl list)
   vtkImplicitModeller *New ();
   void SetAdjustBounds (int );
   void SetAdjustDistance (float );
   void SetCapValue (float );
   void SetCapping (int );
   void SetLocatorMaxLevel (int );
   void SetMaximumDistance (float );
   void SetModelBounds (float , float , float , float , float , float );
   void SetNumberOfThreads (int );
   void SetProcessMode (int );
   void SetProcessModeToPerCell ();
   void SetProcessModeToPerVoxel ();
   void SetSampleDimensions (int i, int j, int k);
   void StartAppend ();
   virtual void UpdateData (vtkDataObject *output);


B<vtkImplicitModeller Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetModelBounds (float  a[6]);
      Method is redundant. Same as SetModelBounds( float, float, float, float, float, float)

   void SetSampleDimensions (int dim[3]);
      Method is redundant. Same as SetSampleDimensions( int, int, int)


=cut

package Graphics::VTK::IterativeClosestPointTransform;


@Graphics::VTK::IterativeClosestPointTransform::ISA = qw( Graphics::VTK::LinearTransform );

=head1 Graphics::VTK::IterativeClosestPointTransform

=over 1

=item *

Inherits from LinearTransform

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CheckMeanDistanceOff ();
   void CheckMeanDistanceOn ();
   int GetCheckMeanDistance ();
   const char *GetClassName ();
   vtkLandmarkTransform *GetLandmarkTransform ();
   vtkCellLocator *GetLocator ();
   float GetMaximumMeanDistance ();
   int GetMaximumNumberOfIterations ();
   int GetMaximumNumberOfLandmarks ();
   float GetMeanDistance ();
   int GetMeanDistanceMode ();
   const char *GetMeanDistanceModeAsString ();
   int GetMeanDistanceModeMaxValue ();
   int GetMeanDistanceModeMinValue ();
   int GetNumberOfIterations ();
   vtkDataSet *GetSource ();
   int GetStartByMatchingCentroids ();
   vtkDataSet *GetTarget ();
   void Inverse ();
   vtkAbstractTransform *MakeTransform ();
   vtkIterativeClosestPointTransform *New ();
   void SetCheckMeanDistance (int );
   void SetLocator (vtkCellLocator *locator);
   void SetMaximumMeanDistance (float );
   void SetMaximumNumberOfIterations (int );
   void SetMaximumNumberOfLandmarks (int );
   void SetMeanDistanceMode (int );
   void SetMeanDistanceModeToAbsoluteValue ();
   void SetMeanDistanceModeToRMS ();
   void SetSource (vtkDataSet *source);
   void SetStartByMatchingCentroids (int );
   void SetTarget (vtkDataSet *target);
   void StartByMatchingCentroidsOff ();
   void StartByMatchingCentroidsOn ();


B<vtkIterativeClosestPointTransform Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::LandmarkTransform;


@Graphics::VTK::LandmarkTransform::ISA = qw( Graphics::VTK::LinearTransform );

=head1 Graphics::VTK::LandmarkTransform

=over 1

=item *

Inherits from LinearTransform

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   unsigned long GetMTime ();
   int GetMode ();
   const char *GetModeAsString ();
   vtkPoints *GetSourceLandmarks ();
   vtkPoints *GetTargetLandmarks ();
   void Inverse ();
   vtkAbstractTransform *MakeTransform ();
   vtkLandmarkTransform *New ();
   void SetMode (int );
   void SetModeToAffine ();
   void SetModeToRigidBody ();
   void SetModeToSimilarity ();
   void SetSourceLandmarks (vtkPoints *points);
   void SetTargetLandmarks (vtkPoints *points);


B<vtkLandmarkTransform Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::LegendBoxActor;


@Graphics::VTK::LegendBoxActor::ISA = qw( Graphics::VTK::Actor2D );

=head1 Graphics::VTK::LegendBoxActor

=over 1

=item *

Inherits from Actor2D

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void BoldOff ();
   void BoldOn ();
   void BorderOff ();
   void BorderOn ();
   int GetBold ();
   int GetBorder ();
   const char *GetClassName ();
   float *GetEntryColor (int i);
      (Returns a 3-element Perl list)
   const char *GetEntryString (int i);
   vtkPolyData *GetEntrySymbol (int i);
   int GetFontFamily ();
   int GetItalic ();
   int GetLockBorder ();
   int GetNumberOfEntries ();
   int GetPadding ();
   int GetPaddingMaxValue ();
   int GetPaddingMinValue ();
   int GetScalarVisibility ();
   int GetShadow ();
   void ItalicOff ();
   void ItalicOn ();
   void LockBorderOff ();
   void LockBorderOn ();
   vtkLegendBoxActor *New ();
   void ScalarVisibilityOff ();
   void ScalarVisibilityOn ();
   void SetBold (int );
   void SetBorder (int );
   void SetEntryColor (int i, float r, float g, float b);
   void SetEntryString (int i, const char *string);
   void SetEntrySymbol (int i, vtkPolyData *symbol);
   void SetFontFamily (int );
   void SetFontFamilyToArial ();
   void SetFontFamilyToCourier ();
   void SetFontFamilyToTimes ();
   void SetItalic (int );
   void SetLockBorder (int );
   void SetNumberOfEntries (int num);
   void SetPadding (int );
   void SetScalarVisibility (int );
   void SetShadow (int );
   void ShadowOff ();
   void ShadowOn ();
   void ShallowCopy (vtkProp *prop);


B<vtkLegendBoxActor Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetEntry (int i, vtkPolyData *symbol, const char *string, float color[3]);
      Don't know the size of pointer arg number 4

   void SetEntryColor (int i, float color[3]);
      Don't know the size of pointer arg number 2


=cut

package Graphics::VTK::PolyDataToImageStencil;


@Graphics::VTK::PolyDataToImageStencil::ISA = qw( Graphics::VTK::ImageStencilSource );

=head1 Graphics::VTK::PolyDataToImageStencil

=over 1

=item *

Inherits from ImageStencilSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkPolyData *GetInput ();
   float GetTolerance ();
   vtkPolyDataToImageStencil *New ();
   void SetInput (vtkPolyData *input);
   void SetTolerance (float );


B<vtkPolyDataToImageStencil Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ThreadedExecute (vtkImageStencilData *output, int extent[6], int threadId);
      Don't know the size of pointer arg number 2


=cut

package Graphics::VTK::RIBExporter;


@Graphics::VTK::RIBExporter::ISA = qw( Graphics::VTK::Exporter );

=head1 Graphics::VTK::RIBExporter

=over 1

=item *

Inherits from Exporter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void BackgroundOff ();
   void BackgroundOn ();
   int GetBackground ();
   const char *GetClassName ();
   char *GetFilePrefix ();
   int  *GetPixelSamples ();
      (Returns a 2-element Perl list)
   int  *GetSize ();
      (Returns a 2-element Perl list)
   char *GetTexturePrefix ();
   vtkRIBExporter *New ();
   void SetBackground (int );
   void SetFilePrefix (char *);
   void SetPixelSamples (int , int );
   void SetSize (int , int );
   void SetTexturePrefix (char *);


B<vtkRIBExporter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetPixelSamples (int  a[2]);
      Method is redundant. Same as SetPixelSamples( int, int)

   void SetSize (int  a[2]);
      Method is redundant. Same as SetSize( int, int)

   void WriteViewport (vtkRenderer *aRenderer, int size[2]);
      Don't know the size of pointer arg number 2


=cut

package Graphics::VTK::RIBLight;


@Graphics::VTK::RIBLight::ISA = qw( Graphics::VTK::Light );

=head1 Graphics::VTK::RIBLight

=over 1

=item *

Inherits from Light

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetShadows ();
   vtkRIBLight *New ();
   void Render (vtkRenderer *ren, int index);
   void SetShadows (int );
   void ShadowsOff ();
   void ShadowsOn ();


B<vtkRIBLight Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::RIBProperty;


@Graphics::VTK::RIBProperty::ISA = qw( Graphics::VTK::Property );

=head1 Graphics::VTK::RIBProperty

=over 1

=item *

Inherits from Property

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddParameter (char *parameter, char *value);
   void AddVariable (char *variable, char *declaration);
   const char *GetClassName ();
   char *GetDeclarations ();
   char *GetDisplacementShader ();
   char *GetParameters ();
   char *GetSurfaceShader ();
   vtkRIBProperty *New ();
   void SetDisplacementShader (char *);
   void SetParameter (char *parameter, char *value);
   void SetSurfaceShader (char *);
   void SetVariable (char *variable, char *declaration);


B<vtkRIBProperty Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::RenderLargeImage;


@Graphics::VTK::RenderLargeImage::ISA = qw( Graphics::VTK::ImageSource );

=head1 Graphics::VTK::RenderLargeImage

=over 1

=item *

Inherits from ImageSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkRenderer *GetInput ();
   int GetMagnification ();
   vtkRenderLargeImage *New ();
   void SetInput (vtkRenderer *);
   void SetMagnification (int );


B<vtkRenderLargeImage Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ThinPlateSplineTransform;


@Graphics::VTK::ThinPlateSplineTransform::ISA = qw( Graphics::VTK::WarpTransform );

=head1 Graphics::VTK::ThinPlateSplineTransform

=over 1

=item *

Inherits from WarpTransform

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int GetBasis ();
   const char *GetBasisAsString ();
   const char *GetClassName ();
   unsigned long GetMTime ();
   double GetSigma ();
   vtkPoints *GetSourceLandmarks ();
   vtkPoints *GetTargetLandmarks ();
   vtkAbstractTransform *MakeTransform ();
   vtkThinPlateSplineTransform *New ();
   void SetBasis (int basis);
   void SetBasisToR ();
   void SetBasisToR2LogR ();
   void SetSigma (double );
   void SetSourceLandmarks (vtkPoints *source);
   void SetTargetLandmarks (vtkPoints *target);


B<vtkThinPlateSplineTransform Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ForwardTransformDerivative (const float in[3], float out[3], float derivative[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void ForwardTransformDerivative (const double in[3], double out[3], double derivative[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void ForwardTransformPoint (const float in[3], float out[3]);
      Don't know the size of pointer arg number 1

   void ForwardTransformPoint (const double in[3], double out[3]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::TransformToGrid;


@Graphics::VTK::TransformToGrid::ISA = qw( Graphics::VTK::ImageSource );

=head1 Graphics::VTK::TransformToGrid

=over 1

=item *

Inherits from ImageSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetDisplacementScale ();
   float GetDisplacementShift ();
   int  *GetGridExtent ();
      (Returns a 6-element Perl list)
   float  *GetGridOrigin ();
      (Returns a 3-element Perl list)
   int GetGridScalarType ();
   float  *GetGridSpacing ();
      (Returns a 3-element Perl list)
   vtkAbstractTransform *GetInput ();
   vtkTransformToGrid *New ();
   void SetGridExtent (int , int , int , int , int , int );
   void SetGridOrigin (float , float , float );
   void SetGridScalarType (int );
   void SetGridScalarTypeToChar ();
   void SetGridScalarTypeToFloat ();
   void SetGridScalarTypeToShort ();
   void SetGridScalarTypeToUnsignedChar ();
   void SetGridScalarTypeToUnsignedShort ();
   void SetGridSpacing (float , float , float );
   void SetInput (vtkAbstractTransform *);


B<vtkTransformToGrid Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetGridExtent (int  a[6]);
      Method is redundant. Same as SetGridExtent( int, int, int, int, int, int)

   void SetGridOrigin (float  a[3]);
      Method is redundant. Same as SetGridOrigin( float, float, float)

   void SetGridSpacing (float  a[3]);
      Method is redundant. Same as SetGridSpacing( float, float, float)


=cut

package Graphics::VTK::VRMLImporter;


@Graphics::VTK::VRMLImporter::ISA = qw( Graphics::VTK::Importer );

=head1 Graphics::VTK::VRMLImporter

=over 1

=item *

Inherits from Importer

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   FILE *GetFileFD ();
   char *GetFileName ();
   vtkObject *GetVRMLDEFObject (const char *name);
   vtkVRMLImporter *New ();
   void SetFileName (char *);
   void enterField (const char *);
   void enterNode (const char *);
   void exitField ();
   void exitNode ();
   void useNode (const char *);


B<vtkVRMLImporter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::VectorText;


@Graphics::VTK::VectorText::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::VectorText

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   char *GetText ();
   vtkVectorText *New ();
   void SetText (char *);


B<vtkVectorText Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::VideoSource;


@Graphics::VTK::VideoSource::ISA = qw( Graphics::VTK::ImageSource );

=head1 Graphics::VTK::VideoSource

=over 1

=item *

Inherits from ImageSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AutoAdvanceOff ();
   void AutoAdvanceOn ();
   virtual void FastForward ();
   int GetAutoAdvance ();
   const char *GetClassName ();
   int  *GetClipRegion ();
      (Returns a 6-element Perl list)
   float  *GetDataOrigin ();
      (Returns a 3-element Perl list)
   float  *GetDataSpacing ();
      (Returns a 3-element Perl list)
   int GetFrameBufferSize ();
   int GetFrameCount ();
   int GetFrameIndex ();
   float GetFrameRate ();
   int  *GetFrameSize ();
      (Returns a 3-element Perl list)
   virtual double GetFrameTimeStamp (int frame);
   virtual double GetFrameTimeStamp ();
   virtual int GetInitialized ();
   int GetNumberOfOutputFrames ();
   float GetOpacity ();
   int GetOutputFormat ();
   int  *GetOutputWholeExtent ();
      (Returns a 6-element Perl list)
   int GetPlaying ();
   int GetRecording ();
   virtual void Grab ();
   virtual void Initialize ();
   virtual void InternalGrab ();
   vtkVideoSource *New ();
   virtual void Play ();
   virtual void Record ();
   virtual void ReleaseSystemResources ();
   virtual void Rewind ();
   virtual void Seek (int n);
   void SetAutoAdvance (int );
   virtual void SetClipRegion (int x0, int x1, int y0, int y1, int z0, int z1);
   void SetDataOrigin (float , float , float );
   void SetDataSpacing (float , float , float );
   virtual void SetFrameBufferSize (int FrameBufferSize);
   void SetFrameCount (int );
   virtual void SetFrameRate (float rate);
   virtual void SetFrameSize (int x, int y, int z);
   void SetNumberOfOutputFrames (int );
   void SetOpacity (float );
   virtual void SetOutputFormat (int format);
   void SetOutputFormatToLuminance ();
   void SetOutputFormatToRGB ();
   void SetOutputFormatToRGBA ();
   void SetOutputWholeExtent (int , int , int , int , int , int );
   virtual void Stop ();


B<vtkVideoSource Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   double GetStartTimeStamp ();
      Method is for internal use only

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   virtual void SetClipRegion (int r[6]);
      Method is redundant. Same as SetClipRegion( int, int, int, int, int, int)

   void SetDataOrigin (float  a[3]);
      Method is redundant. Same as SetDataOrigin( float, float, float)

   void SetDataSpacing (float  a[3]);
      Method is redundant. Same as SetDataSpacing( float, float, float)

   virtual void SetFrameSize (int dim[3]);
      Method is redundant. Same as SetFrameSize( int, int, int)

   void SetOutputWholeExtent (int  a[6]);
      Method is redundant. Same as SetOutputWholeExtent( int, int, int, int, int, int)

   void SetStartTimeStamp (double t);
      Method is for internal use only


=cut

package Graphics::VTK::WeightedTransformFilter;


@Graphics::VTK::WeightedTransformFilter::ISA = qw( Graphics::VTK::PointSetToPointSetFilter );

=head1 Graphics::VTK::WeightedTransformFilter

=over 1

=item *

Inherits from PointSetToPointSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddInputValuesOff ();
   void AddInputValuesOn ();
   int GetAddInputValues ();
   char *GetCellDataWeightArray ();
   const char *GetClassName ();
   unsigned long GetMTime ();
   int GetNumberOfTransforms ();
   virtual vtkAbstractTransform *GetTransform (int num);
   char *GetWeightArray ();
   vtkWeightedTransformFilter *New ();
   void SetAddInputValues (int );
   void SetCellDataWeightArray (char *);
   virtual void SetNumberOfTransforms (int num);
   virtual void SetTransform (vtkAbstractTransform *transform, int num);
   void SetWeightArray (char *);


B<vtkWeightedTransformFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::XYPlotActor;


@Graphics::VTK::XYPlotActor::ISA = qw( Graphics::VTK::Actor2D );

=head1 Graphics::VTK::XYPlotActor

=over 1

=item *

Inherits from Actor2D

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddDataObjectInput (vtkDataObject *in);
   void AddInput (vtkDataSet *in);
   void BoldOff ();
   void BoldOn ();
   void ExchangeAxesOff ();
   void ExchangeAxesOn ();
   int GetBold ();
   int GetBorder ();
   int GetBorderMaxValue ();
   int GetBorderMinValue ();
   const char *GetClassName ();
   vtkDataObjectCollection *GetDataObjectInputList ();
   int GetDataObjectPlotMode ();
   const char *GetDataObjectPlotModeAsString ();
   int GetDataObjectPlotModeMaxValue ();
   int GetDataObjectPlotModeMinValue ();
   int GetDataObjectXComponent (int i);
   int GetDataObjectYComponent (int i);
   int GetExchangeAxes ();
   int GetFontFamily ();
   float GetGlyphSize ();
   float GetGlyphSizeMaxValue ();
   float GetGlyphSizeMinValue ();
   vtkGlyphSource2D *GetGlyphSource ();
   vtkDataSetCollection *GetInputList ();
   int GetItalic ();
   char *GetLabelFormat ();
   int GetLegend ();
   vtkLegendBoxActor *GetLegendBoxActor ();
   float  *GetLegendPosition ();
      (Returns a 2-element Perl list)
   float  *GetLegendPosition2 ();
      (Returns a 2-element Perl list)
   int GetLogx ();
   unsigned long GetMTime ();
   int GetNumberOfXLabels ();
   int GetNumberOfXLabelsMaxValue ();
   int GetNumberOfXLabelsMinValue ();
   int GetNumberOfYLabels ();
   int GetNumberOfYLabelsMaxValue ();
   int GetNumberOfYLabelsMinValue ();
   float *GetPlotColor (int i);
      (Returns a 3-element Perl list)
   float  *GetPlotCoordinate ();
      (Returns a 2-element Perl list)
   int GetPlotCurveLines ();
   int GetPlotCurvePoints ();
   const char *GetPlotLabel (int i);
   int GetPlotLines (int i);
   int GetPlotLines ();
   int GetPlotPoints (int i);
   int GetPlotPoints ();
   vtkPolyData *GetPlotSymbol (int i);
   int GetPointComponent (int i);
   int GetReverseXAxis ();
   int GetReverseYAxis ();
   int GetShadow ();
   char *GetTitle ();
   float  *GetViewportCoordinate ();
      (Returns a 2-element Perl list)
   float  *GetXRange ();
      (Returns a 2-element Perl list)
   char *GetXTitle ();
   int GetXValues ();
   const char *GetXValuesAsString ();
   int GetXValuesMaxValue ();
   int GetXValuesMinValue ();
   float  *GetYRange ();
      (Returns a 2-element Perl list)
   char *GetYTitle ();
   int IsInPlot (vtkViewport *viewport, float u, float v);
   void ItalicOff ();
   void ItalicOn ();
   void LegendOff ();
   void LegendOn ();
   void LogxOff ();
   void LogxOn ();
   vtkXYPlotActor *New ();
   void PlotCurveLinesOff ();
   void PlotCurveLinesOn ();
   void PlotCurvePointsOff ();
   void PlotCurvePointsOn ();
   void PlotLinesOff ();
   void PlotLinesOn ();
   void PlotPointsOff ();
   void PlotPointsOn ();
   void PlotToViewportCoordinate (vtkViewport *viewport, float &u, float &v);
   void PlotToViewportCoordinate (vtkViewport *viewport);
   void RemoveDataObjectInput (vtkDataObject *in);
   void RemoveInput (vtkDataSet *in);
   void ReverseXAxisOff ();
   void ReverseXAxisOn ();
   void ReverseYAxisOff ();
   void ReverseYAxisOn ();
   void SetBold (int );
   void SetBorder (int );
   void SetDataObjectPlotMode (int );
   void SetDataObjectPlotModeToColumns ();
   void SetDataObjectPlotModeToRows ();
   void SetDataObjectXComponent (int i, int comp);
   void SetDataObjectYComponent (int i, int comp);
   void SetExchangeAxes (int );
   void SetFontFamily (int );
   void SetFontFamilyToArial ();
   void SetFontFamilyToCourier ();
   void SetFontFamilyToTimes ();
   void SetGlyphSize (float );
   void SetItalic (int );
   void SetLabelFormat (char *);
   void SetLegend (int );
   void SetLegendPosition (float , float );
   void SetLegendPosition2 (float , float );
   void SetLogx (int );
   void SetNumberOfLabels (int num);
   void SetNumberOfXLabels (int );
   void SetNumberOfYLabels (int );
   void SetPlotColor (int i, float r, float g, float b);
   void SetPlotCoordinate (float , float );
   void SetPlotCurveLines (int );
   void SetPlotCurvePoints (int );
   void SetPlotLabel (int i, const char *label);
   void SetPlotLines (int i, int );
   void SetPlotLines (int );
   void SetPlotPoints (int i, int );
   void SetPlotPoints (int );
   void SetPlotRange (float xmin, float ymin, float xmax, float ymax);
   void SetPlotSymbol (int i, vtkPolyData *input);
   void SetPointComponent (int i, int comp);
   void SetReverseXAxis (int );
   void SetReverseYAxis (int );
   void SetShadow (int );
   void SetTitle (char *);
   void SetViewportCoordinate (float , float );
   void SetXRange (float , float );
   void SetXTitle (char *);
   void SetXValues (int );
   void SetXValuesToArcLength ();
   void SetXValuesToIndex ();
   void SetXValuesToNormalizedArcLength ();
   void SetXValuesToValue ();
   void SetYRange (float , float );
   void SetYTitle (char *);
   void ShadowOff ();
   void ShadowOn ();
   void ViewportToPlotCoordinate (vtkViewport *viewport, float &u, float &v);
   void ViewportToPlotCoordinate (vtkViewport *viewport);


B<vtkXYPlotActor Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ClipPlotData (int *pos, int *pos2, vtkPolyData *pd);
      Don't know the size of pointer arg number 1

   void ComputeDORange (float xrange[2], float yrange[2], float *lengths);
      Don't know the size of pointer arg number 1

   float ComputeGlyphScale (int i, int *pos, int *pos2);
      Don't know the size of pointer arg number 2

   void ComputeXRange (float range[2], float *lengths);
      Don't know the size of pointer arg number 1

   virtual void CreatePlotData (int *pos, int *pos2, float xRange[2], float yRange[2], float *norms, int numDS, int numDO);
      Don't know the size of pointer arg number 1

   void GenerateClipPlanes (int *pos, int *pos2);
      Don't know the size of pointer arg number 1

   void PlaceAxes (vtkViewport *viewport, int *size, int pos[2], int pos2[2]);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetLegendPosition2 (float  a[2]);
      Method is redundant. Same as SetLegendPosition2( float, float)

   void SetLegendPosition (float  a[2]);
      Method is redundant. Same as SetLegendPosition( float, float)

   void SetPlotColor (int i, const float color[3]);
      Don't know the size of pointer arg number 2

   void SetPlotCoordinate (float  a[2]);
      Method is redundant. Same as SetPlotCoordinate( float, float)

   void SetViewportCoordinate (float  a[2]);
      Method is redundant. Same as SetViewportCoordinate( float, float)

   void SetXRange (float  a[2]);
      Method is redundant. Same as SetXRange( float, float)

   void SetYRange (float  a[2]);
      Method is redundant. Same as SetYRange( float, float)

   float *TransformPoint (int pos[2], int pos2[2], float x[3], float xNew[3]);
      Can't Handle 'float *' return type without a hint


=cut

1;
