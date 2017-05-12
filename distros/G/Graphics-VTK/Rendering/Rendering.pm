
package Graphics::VTK::Rendering;
use 5.004;
use strict;
use Carp;

use vars qw/ $VERSION @ISA/;

require DynaLoader;

$VERSION = '4.0.001';

@ISA = qw/ DynaLoader /;

bootstrap Graphics::VTK::Rendering $VERSION;


=head1 NAME

VTKRendering  - A Perl interface to VTKRendering library

=head1 SYNOPSIS

C<use Graphics::VTK;>
C<use Graphics::VTK::Rendering;>

=head1 DESCRIPTION

Graphics::VTK::Rendering is an interface to the Rendering libaray of the C++ visualization toolkit VTK..

=head1 AUTHOR

Original PerlVTK Package: Roberto De Leo <rdl@math.umd.edu>

Additional Refinements: John Cerney <j-cerney1@raytheon.com>

=cut

package Graphics::VTK::OpenGLRenderWindow;


@Graphics::VTK::OpenGLRenderWindow::ISA = qw( Graphics::VTK::RenderWindow );

=head1 Graphics::VTK::OpenGLRenderWindow

=over 1

=item *

Inherits from RenderWindow

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetDepthBufferSize ();
   static int GetGlobalMaximumNumberOfMultiSamples ();
   int GetMultiSamples ();
   void MakeCurrent () = 0;
   virtual void OpenGLInit ();
   void RegisterTextureResource (GLuint id);
   static void SetGlobalMaximumNumberOfMultiSamples (int val);
   void SetMultiSamples (int );
   virtual void StereoUpdate ();


B<vtkOpenGLRenderWindow Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual unsigned char *GetPixelData (int x, int y, int x2, int y2, int front);
      Can't Handle 'unsigned char *' return type without a hint

   virtual unsigned char *GetRGBACharPixelData (int x, int y, int x2, int y2, int front);
      Can't Handle 'unsigned char *' return type without a hint

   virtual float *GetRGBAPixelData (int x, int y, int x2, int y2, int front);
      Can't Handle 'float *' return type without a hint

   virtual float *GetZbufferData (int x1, int y1, int x2, int y2);
      Can't Handle 'float *' return type without a hint

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   virtual void ReleaseRGBAPixelData (float *data);
      Don't know the size of pointer arg number 1

   virtual void SetPixelData (int x, int y, int x2, int y2, unsigned char *, int front);
      Don't know the size of pointer arg number 5

   virtual void SetRGBACharPixelData (int x, int y, int x2, int y2, unsigned char *, int front, int blend);
      Don't know the size of pointer arg number 5

   virtual void SetRGBAPixelData (int x, int y, int x2, int y2, float *, int front, int blend);
      Don't know the size of pointer arg number 5

   virtual void SetZbufferData (int x1, int y1, int x2, int y2, float *buffer);
      Don't know the size of pointer arg number 5


=cut

package Graphics::VTK::AbstractMapper3D;


@Graphics::VTK::AbstractMapper3D::ISA = qw( Graphics::VTK::AbstractMapper );

=head1 Graphics::VTK::AbstractMapper3D

=over 1

=item *

Inherits from AbstractMapper

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual float *GetBounds () = 0;
      (Returns a 6-element Perl list)
   float *GetCenter ();
      (Returns a 3-element Perl list)
   const char *GetClassName ();
   float GetLength ();
   virtual int IsARayCastMapper ();
   virtual int IsARenderIntoImageMapper ();
   virtual void Update () = 0;


B<vtkAbstractMapper3D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void GetBounds (float bounds[6]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::AbstractPicker;


@Graphics::VTK::AbstractPicker::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::AbstractPicker

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddPickList (vtkProp *);
   void DeletePickList (vtkProp *);
   const char *GetClassName ();
   int GetPickFromList ();
   vtkPropCollection *GetPickList ();
   float  *GetPickPosition ();
      (Returns a 3-element Perl list)
   vtkRenderer *GetRenderer ();
   float  *GetSelectionPoint ();
      (Returns a 3-element Perl list)
   void InitializePickList ();
   virtual int Pick (float selectionX, float selectionY, float selectionZ, vtkRenderer *renderer) = 0;
   void PickFromListOff ();
   void PickFromListOn ();
   void SetEndPickMethod (void (*func)(void *) , void *arg);
   void SetPickFromList (int );
   void SetPickMethod (void (*func)(void *) , void *arg);
   void SetStartPickMethod (void (*func)(void *) , void *arg);


B<vtkAbstractPicker Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int Pick (float selectionPt[3], vtkRenderer *ren);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetEndPickMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void SetPickMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void SetStartPickMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.


=cut

package Graphics::VTK::AbstractPropPicker;


@Graphics::VTK::AbstractPropPicker::ISA = qw( Graphics::VTK::AbstractPicker );

=head1 Graphics::VTK::AbstractPropPicker

=over 1

=item *

Inherits from AbstractPicker

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual vtkActor *GetActor ();
   virtual vtkActor2D *GetActor2D ();
   virtual vtkAssembly *GetAssembly ();
   const char *GetClassName ();
   vtkAssemblyPath *GetPath ();
   virtual vtkProp *GetProp ();
   virtual vtkProp3D *GetProp3D ();
   virtual vtkPropAssembly *GetPropAssembly ();
   virtual vtkVolume *GetVolume ();
   void SetPath (vtkAssemblyPath *);


B<vtkAbstractPropPicker Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::Actor;


@Graphics::VTK::Actor::ISA = qw( Graphics::VTK::Prop3D );

=head1 Graphics::VTK::Actor

=over 1

=item *

Inherits from Prop3D

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual void ApplyProperties ();
   virtual void GetActors (vtkPropCollection *);
   vtkProperty *GetBackfaceProperty ();
   float *GetBounds ();
      (Returns a 6-element Perl list)
   const char *GetClassName ();
   unsigned long GetMTime ();
   vtkMapper *GetMapper ();
   virtual vtkActor *GetNextPart ();
   virtual int GetNumberOfParts ();
   vtkProperty *GetProperty ();
   virtual unsigned long GetRedrawMTime ();
   vtkTexture *GetTexture ();
   virtual void InitPartTraversal ();
   virtual vtkProperty *MakeProperty ();
   vtkActor *New ();
   void ReleaseGraphicsResources (vtkWindow *);
   virtual void Render (vtkRenderer *, vtkMapper *);
   virtual int RenderOpaqueGeometry (vtkViewport *viewport);
   virtual int RenderTranslucentGeometry (vtkViewport *viewport);
   void SetBackfaceProperty (vtkProperty *lut);
   void SetMapper (vtkMapper *);
   void SetProperty (vtkProperty *lut);
   void SetTexture (vtkTexture *);
   void ShallowCopy (vtkProp *prop);


B<vtkActor Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void GetBounds (float bounds[6]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ActorCollection;


@Graphics::VTK::ActorCollection::ISA = qw( Graphics::VTK::PropCollection );

=head1 Graphics::VTK::ActorCollection

=over 1

=item *

Inherits from PropCollection

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddItem (vtkActor *a);
   void ApplyProperties (vtkProperty *p);
   const char *GetClassName ();
   vtkActor *GetLastActor ();
   vtkActor *GetLastItem ();
   vtkActor *GetNextActor ();
   vtkActor *GetNextItem ();
   vtkActorCollection *New ();

=cut

package Graphics::VTK::Assembly;


@Graphics::VTK::Assembly::ISA = qw( Graphics::VTK::Prop3D );

=head1 Graphics::VTK::Assembly

=over 1

=item *

Inherits from Prop3D

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddPart (vtkProp3D *);
   void GetActors (vtkPropCollection *);
   float *GetBounds ();
      (Returns a 6-element Perl list)
   const char *GetClassName ();
   unsigned long GetMTime ();
   vtkAssemblyPath *GetNextPath ();
   int GetNumberOfPaths ();
   vtkProp3DCollection *GetParts ();
   void GetVolumes (vtkPropCollection *);
   void InitPathTraversal ();
   vtkAssembly *New ();
   void ReleaseGraphicsResources (vtkWindow *);
   void RemovePart (vtkProp3D *);
   int RenderOpaqueGeometry (vtkViewport *ren);
   int RenderTranslucentGeometry (vtkViewport *ren);
   void ShallowCopy (vtkProp *prop);


B<vtkAssembly Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void GetBounds (float bounds[6]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::AxisActor2D;


@Graphics::VTK::AxisActor2D::ISA = qw( Graphics::VTK::Actor2D );

=head1 Graphics::VTK::AxisActor2D

=over 1

=item *

Inherits from Actor2D

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AdjustLabelsOff ();
   void AdjustLabelsOn ();
   void AxisVisibilityOff ();
   void AxisVisibilityOn ();
   void BoldOff ();
   void BoldOn ();
   int GetAdjustLabels ();
   int GetAxisVisibility ();
   int GetBold ();
   const char *GetClassName ();
   float GetFontFactor ();
   float GetFontFactorMaxValue ();
   float GetFontFactorMinValue ();
   int GetFontFamily ();
   int GetItalic ();
   float GetLabelFactor ();
   float GetLabelFactorMaxValue ();
   float GetLabelFactorMinValue ();
   char *GetLabelFormat ();
   int GetLabelVisibility ();
   int GetNumberOfLabels ();
   int GetNumberOfLabelsMaxValue ();
   int GetNumberOfLabelsMinValue ();
   float *GetPoint1 ();
      (Returns a 2-element Perl list)
   vtkCoordinate *GetPoint1Coordinate ();
   float *GetPoint2 ();
      (Returns a 2-element Perl list)
   vtkCoordinate *GetPoint2Coordinate ();
   float  *GetRange ();
      (Returns a 2-element Perl list)
   int GetShadow ();
   int GetTickLength ();
   int GetTickLengthMaxValue ();
   int GetTickLengthMinValue ();
   int GetTickOffset ();
   int GetTickOffsetMaxValue ();
   int GetTickOffsetMinValue ();
   int GetTickVisibility ();
   char *GetTitle ();
   int GetTitleVisibility ();
   void ItalicOff ();
   void ItalicOn ();
   void LabelVisibilityOff ();
   void LabelVisibilityOn ();
   vtkAxisActor2D *New ();
   void ReleaseGraphicsResources (vtkWindow *);
   int RenderOpaqueGeometry (vtkViewport *viewport);
   int RenderOverlay (vtkViewport *viewport);
   int RenderTranslucentGeometry (vtkViewport *);
   void SetAdjustLabels (int );
   void SetAxisVisibility (int );
   void SetBold (int );
   void SetFontFactor (float );
   void SetFontFamily (int );
   void SetFontFamilyToArial ();
   void SetFontFamilyToCourier ();
   void SetFontFamilyToTimes ();
   void SetItalic (int );
   void SetLabelFactor (float );
   void SetLabelFormat (char *);
   void SetLabelVisibility (int );
   void SetNumberOfLabels (int );
   void SetPoint1 (float, float);
   void SetPoint2 (float, float);
   void SetRange (float , float );
   void SetShadow (int );
   void SetTickLength (int );
   void SetTickOffset (int );
   void SetTickVisibility (int );
   void SetTitle (char *);
   void SetTitleVisibility (int );
   void ShadowOff ();
   void ShadowOn ();
   void ShallowCopy (vtkProp *prop);
   void TickVisibilityOff ();
   void TickVisibilityOn ();
   void TitleVisibilityOff ();
   void TitleVisibilityOn ();


B<vtkAxisActor2D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   static void ComputeRange (float inRange[2], float outRange[2], int inNumTicks, int &outNumTicks, float &interval);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   static int SetFontSize (vtkViewport *viewport, vtkTextMapper *textMapper, int *size, float factor, int &stringWidth, int &stringHeight);
      Don't know the size of pointer arg number 3

   static void SetOffsetPosition (float xTick[3], float theta, int stringHeight, int stringWidth, int offset, vtkActor2D *actor);
      Don't know the size of pointer arg number 1

   void SetPoint1 (float a[2]);
      Method is redundant. Same as SetPoint1( float, float)

   void SetPoint2 (float a[2]);
      Method is redundant. Same as SetPoint2( float, float)

   void SetRange (float  a[2]);
      Method is redundant. Same as SetRange( float, float)


=cut

package Graphics::VTK::Camera;


@Graphics::VTK::Camera::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::Camera

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Azimuth (double angle);
   void ComputeViewPlaneNormal ();
   void Dolly (double distance);
   void Elevation (double angle);
   vtkMatrix4x4 *GetCameraLightTransformMatrix ();
   const char *GetClassName ();
   double  *GetClippingRange ();
      (Returns a 2-element Perl list)
   vtkMatrix4x4 &GetCompositePerspectiveTransform (double aspect, double nearz, double farz);
   vtkMatrix4x4 *GetCompositePerspectiveTransformMatrix (double aspect, double nearz, double farz);
   double  *GetDirectionOfProjection ();
      (Returns a 3-element Perl list)
   double GetDistance ();
   double GetEyeAngle ();
   double GetFocalDisk ();
   double  *GetFocalPoint ();
      (Returns a 3-element Perl list)
   float *GetOrientation ();
      (Returns a 3-element Perl list)
   float *GetOrientationWXYZ ();
      (Returns a 4-element Perl list)
   int GetParallelProjection ();
   double GetParallelScale ();
   vtkMatrix4x4 *GetPerspectiveTransformMatrix (double aspect, double nearz, double farz);
   double  *GetPosition ();
      (Returns a 3-element Perl list)
   double GetRoll ();
   double GetThickness ();
   double GetViewAngle ();
   double  *GetViewPlaneNormal ();
      (Returns a 3-element Perl list)
   double  *GetViewShear ();
      (Returns a 3-element Perl list)
   vtkMatrix4x4 *GetViewTransformMatrix ();
   vtkTransform *GetViewTransformObject ();
   double  *GetViewUp ();
      (Returns a 3-element Perl list)
   unsigned long GetViewingRaysMTime ();
   double  *GetWindowCenter ();
      (Returns a 2-element Perl list)
   vtkCamera *New ();
   void OrthogonalizeViewUp ();
   void ParallelProjectionOff ();
   void ParallelProjectionOn ();
   void Pitch (double angle);
   virtual void Render (vtkRenderer *);
   void Roll (double angle);
   void SetClippingRange (double near, double far);
   void SetDistance (double );
   void SetEyeAngle (double );
   void SetFocalDisk (double );
   void SetFocalPoint (double x, double y, double z);
   void SetObliqueAngles (double alpha, double beta);
   void SetParallelProjection (int flag);
   void SetParallelScale (double scale);
   void SetPosition (double x, double y, double z);
   void SetRoll (double angle);
   void SetThickness (double );
   void SetViewAngle (double angle);
   void SetViewPlaneNormal (double x, double y, double z);
   void SetViewShear (double dxdz, double dydz, double center);
   void SetViewUp (double vx, double vy, double vz);
   void SetWindowCenter (double x, double y);
   void ViewingRaysModified ();
   void Yaw (double angle);
   void Zoom (double factor);


B<vtkCamera Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void GetClippingRange (float a[2]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void GetDirectionOfProjection (float a[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void GetFocalPoint (float a[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void GetFrustumPlanes (float aspect, float planes[24]);
      Don't know the size of pointer arg number 2

   vtkMatrix4x4 &GetPerspectiveTransform (double aspect, double nearz, double farz);
      Method is marked 'Do Not Use' in its descriptions

   void GetPosition (float a[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void GetViewPlaneNormal (float a[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   vtkMatrix4x4 &GetViewTransform ();
      Method is marked 'Do Not Use' in its descriptions

   void GetViewUp (float a[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetClippingRange (const double a[2]);
      Method is redundant. Same as SetClippingRange( double, double)

   void SetClippingRange (const float a[2]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void SetFocalPoint (const double a[3]);
      Method is redundant. Same as SetFocalPoint( double, double, double)

   void SetFocalPoint (const float a[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void SetPosition (const double a[3]);
      Method is redundant. Same as SetPosition( double, double, double)

   void SetPosition (const float a[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void SetViewPlaneNormal (const double a[3]);
      Method is redundant. Same as SetViewPlaneNormal( double, double, double)

   void SetViewPlaneNormal (const float a[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void SetViewShear (double d[3]);
      Method is redundant. Same as SetViewShear( double, double, double)

   void SetViewUp (const double a[3]);
      Method is redundant. Same as SetViewUp( double, double, double)

   void SetViewUp (const float a[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   virtual void UpdateViewport (vtkRenderer *);
      Method is marked 'Do Not Use' in its descriptions


=cut

package Graphics::VTK::CellPicker;


@Graphics::VTK::CellPicker::ISA = qw( Graphics::VTK::Picker );

=head1 Graphics::VTK::CellPicker

=over 1

=item *

Inherits from Picker

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   long GetCellId ();
   const char *GetClassName ();
   float  *GetPCoords ();
      (Returns a 3-element Perl list)
   int GetSubId ();
   vtkCellPicker *New ();


B<vtkCellPicker Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual float IntersectWithLine (float p1[3], float p2[3], float tol, vtkAssemblyPath *path, vtkProp3D *p, vtkAbstractMapper3D *m);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::Culler;


@Graphics::VTK::Culler::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::Culler

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();


B<vtkCuller Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual float Cull (vtkRenderer *ren, vtkProp *propList, int &listLength, int &initialized) = 0;
      Don't know the size of pointer arg number 2


=cut

package Graphics::VTK::CullerCollection;


@Graphics::VTK::CullerCollection::ISA = qw( Graphics::VTK::Collection );

=head1 Graphics::VTK::CullerCollection

=over 1

=item *

Inherits from Collection

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddItem (vtkCuller *a);
   const char *GetClassName ();
   vtkCuller *GetLastItem ();
   vtkCuller *GetNextItem ();
   vtkCullerCollection *New ();

=cut

package Graphics::VTK::DataSetMapper;


@Graphics::VTK::DataSetMapper::ISA = qw( Graphics::VTK::Mapper );

=head1 Graphics::VTK::DataSetMapper

=over 1

=item *

Inherits from Mapper

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkDataSet *GetInput ();
   unsigned long GetMTime ();
   vtkPolyDataMapper *GetPolyDataMapper ();
   vtkDataSetMapper *New ();
   void ReleaseGraphicsResources (vtkWindow *);
   void Render (vtkRenderer *ren, vtkActor *act);
   void SetInput (vtkDataSet *input);


B<vtkDataSetMapper Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::DirectionEncoder;


@Graphics::VTK::DirectionEncoder::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::DirectionEncoder

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   virtual int GetNumberOfEncodedDirections (void ) = 0;


B<vtkDirectionEncoder Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual float *GetDecodedGradient (int value) = 0;
      Can't Handle 'float *' return type without a hint

   virtual float *GetDecodedGradientTable (void ) = 0;
      Can't Handle 'float *' return type without a hint

   virtual int GetEncodedDirection (float n[3]) = 0;
      Can't handle methods with single array args (like a[3]) yet.


=cut

package Graphics::VTK::EncodedGradientEstimator;


@Graphics::VTK::EncodedGradientEstimator::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::EncodedGradientEstimator

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void BoundsClipOff ();
   void BoundsClipOn ();
   void ComputeGradientMagnitudesOff ();
   void ComputeGradientMagnitudesOn ();
   void CylinderClipOff ();
   void CylinderClipOn ();
   int  *GetBounds ();
      (Returns a 6-element Perl list)
   int GetBoundsClip ();
   int GetBoundsClipMaxValue ();
   int GetBoundsClipMinValue ();
   const char *GetClassName ();
   int GetComputeGradientMagnitudes ();
   int GetCylinderClip ();
   vtkDirectionEncoder *GetDirectionEncoder ();
   int GetEncodedNormalIndex (int x_index, int y_index, int z_index);
   int GetEncodedNormalIndex (int xyz_index);
   float GetGradientMagnitudeBias ();
   float GetGradientMagnitudeScale ();
   vtkImageData *GetInput ();
   float GetLastUpdateTimeInCPUSeconds ();
   float GetLastUpdateTimeInSeconds ();
   int GetNumberOfThreads ();
   int GetNumberOfThreadsMaxValue ();
   int GetNumberOfThreadsMinValue ();
   int GetUseCylinderClip ();
   float GetZeroNormalThreshold ();
   int GetZeroPad ();
   int GetZeroPadMaxValue ();
   int GetZeroPadMinValue ();
   void SetBounds (int , int , int , int , int , int );
   void SetBoundsClip (int );
   void SetComputeGradientMagnitudes (int );
   void SetCylinderClip (int );
   void SetDirectionEncoder (vtkDirectionEncoder *direnc);
   void SetGradientMagnitudeBias (float );
   void SetGradientMagnitudeScale (float );
   void SetInput (vtkImageData *);
   void SetNumberOfThreads (int );
   void SetZeroNormalThreshold (float v);
   void SetZeroPad (int );
   void Update (void );
   void ZeroPadOff ();
   void ZeroPadOn ();


B<vtkEncodedGradientEstimator Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int *GetCircleLimits ();
      Can't Handle 'int *' return type without a hint

   unsigned short *GetEncodedNormals (void );
      Can't Handle 'unsigned short *' return type without a hint

   unsigned char *GetGradientMagnitudes (void );
      Can't Handle 'unsigned char *' return type without a hint

   void PrintSelf (ostream &os, vtkIndent index);
      I/O Streams not Supported yet

   void SetBounds (int  a[6]);
      Method is redundant. Same as SetBounds( int, int, int, int, int, int)


=cut

package Graphics::VTK::EncodedGradientShader;


@Graphics::VTK::EncodedGradientShader::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::EncodedGradientShader

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetZeroNormalDiffuseIntensity ();
   float GetZeroNormalDiffuseIntensityMaxValue ();
   float GetZeroNormalDiffuseIntensityMinValue ();
   float GetZeroNormalSpecularIntensity ();
   float GetZeroNormalSpecularIntensityMaxValue ();
   float GetZeroNormalSpecularIntensityMinValue ();
   vtkEncodedGradientShader *New ();
   void SetZeroNormalDiffuseIntensity (float );
   void SetZeroNormalSpecularIntensity (float );
   void UpdateShadingTable (vtkRenderer *ren, vtkVolume *vol, vtkEncodedGradientEstimator *gradest);


B<vtkEncodedGradientShader Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void BuildShadingTable (int index, float lightDirection[3], float lightColor[3], float lightIntensity, float viewDirection[3], float material[4], int twoSided, vtkEncodedGradientEstimator *gradest, int updateFlag);
      Don't know the size of pointer arg number 2

   float *GetBlueDiffuseShadingTable (vtkVolume *vol);
      Can't Handle 'float *' return type without a hint

   float *GetBlueSpecularShadingTable (vtkVolume *vol);
      Can't Handle 'float *' return type without a hint

   float *GetGreenDiffuseShadingTable (vtkVolume *vol);
      Can't Handle 'float *' return type without a hint

   float *GetGreenSpecularShadingTable (vtkVolume *vol);
      Can't Handle 'float *' return type without a hint

   float *GetRedDiffuseShadingTable (vtkVolume *vol);
      Can't Handle 'float *' return type without a hint

   float *GetRedSpecularShadingTable (vtkVolume *vol);
      Can't Handle 'float *' return type without a hint

   void PrintSelf (ostream &os, vtkIndent index);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::Exporter;


@Graphics::VTK::Exporter::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::Exporter

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkRenderWindow *GetInput ();
   unsigned long GetMTime ();
   vtkRenderWindow *GetRenderWindow ();
   void SetEndWrite (void (*func)(void *) , void *arg);
   void SetInput (vtkRenderWindow *renWin);
   void SetRenderWindow (vtkRenderWindow *);
   void SetStartWrite (void (*func)(void *) , void *arg);
   void Update ();
   virtual void Write ();


B<vtkExporter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetEndWriteArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void SetStartWriteArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.


=cut

package Graphics::VTK::FiniteDifferenceGradientEstimator;


@Graphics::VTK::FiniteDifferenceGradientEstimator::ISA = qw( Graphics::VTK::EncodedGradientEstimator );

=head1 Graphics::VTK::FiniteDifferenceGradientEstimator

=over 1

=item *

Inherits from EncodedGradientEstimator

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetSampleSpacingInVoxels ();
   vtkFiniteDifferenceGradientEstimator *New ();
   void SetSampleSpacingInVoxels (int );


B<vtkFiniteDifferenceGradientEstimator Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent index);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::Follower;


@Graphics::VTK::Follower::ISA = qw( Graphics::VTK::Actor );

=head1 Graphics::VTK::Follower

=over 1

=item *

Inherits from Actor

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   vtkCamera *GetCamera ();
   const char *GetClassName ();
   virtual void GetMatrix (vtkMatrix4x4 *m);
   virtual vtkMatrix4x4 *GetMatrix ();
   vtkFollower *New ();
   virtual void Render (vtkRenderer *ren);
   virtual int RenderOpaqueGeometry (vtkViewport *viewport);
   virtual int RenderTranslucentGeometry (vtkViewport *viewport);
   void SetCamera (vtkCamera *);
   void ShallowCopy (vtkProp *prop);


B<vtkFollower Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void GetMatrix (double m[16]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::FrustumCoverageCuller;


@Graphics::VTK::FrustumCoverageCuller::ISA = qw( Graphics::VTK::Culler );

=head1 Graphics::VTK::FrustumCoverageCuller

=over 1

=item *

Inherits from Culler

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetMaximumCoverage ();
   float GetMinimumCoverage ();
   int GetSortingStyle ();
   const char *GetSortingStyleAsString (void );
   int GetSortingStyleMaxValue ();
   int GetSortingStyleMinValue ();
   vtkFrustumCoverageCuller *New ();
   void SetMaximumCoverage (float );
   void SetMinimumCoverage (float );
   void SetSortingStyle (int );
   void SetSortingStyleToBackToFront ();
   void SetSortingStyleToFrontToBack ();
   void SetSortingStyleToNone ();


B<vtkFrustumCoverageCuller Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::GraphicsFactory;


@Graphics::VTK::GraphicsFactory::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::GraphicsFactory

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   static vtkObject *CreateInstance (const char *vtkclassname);
   const char *GetClassName ();
   static const char *GetRenderLibrary ();
   vtkGraphicsFactory *New ();

=cut

package Graphics::VTK::IVExporter;


@Graphics::VTK::IVExporter::ISA = qw( Graphics::VTK::Exporter );

=head1 Graphics::VTK::IVExporter

=over 1

=item *

Inherits from Exporter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   char *GetFileName ();
   vtkIVExporter *New ();
   void SetFileName (char *);


B<vtkIVExporter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void WriteALight (vtkLight *aLight, FILE *fp);
      Don't know the size of pointer arg number 2

   void WriteAnActor (vtkActor *anActor, FILE *fp);
      Don't know the size of pointer arg number 2

   void WritePointData (vtkPoints *points, vtkDataArray *normals, vtkDataArray *tcoords, vtkUnsignedCharArray *colors, FILE *fp);
      Don't know the size of pointer arg number 5


=cut

package Graphics::VTK::ImageActor;


@Graphics::VTK::ImageActor::ISA = qw( Graphics::VTK::Prop );

=head1 Graphics::VTK::ImageActor

=over 1

=item *

Inherits from Prop

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   float *GetBounds ();
      (Returns a 6-element Perl list)
   const char *GetClassName ();
   int *GetDisplayExtent ();
      (Returns a 6-element Perl list)
   vtkImageData *GetInput ();
   int GetInterpolate ();
   int GetSliceNumber ();
   int GetWholeZMax ();
   int GetWholeZMin ();
   int GetZSlice ();
   void InterpolateOff ();
   void InterpolateOn ();
   vtkImageActor *New ();
   void SetDisplayExtent (int minX, int maxX, int minY, int maxY, int minZ, int maxZ);
   void SetInput (vtkImageData *);
   void SetInterpolate (int );
   void SetZSlice (int z);


B<vtkImageActor Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void GetBounds (float bounds[6]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void GetDisplayExtent (int extent[6]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetDisplayExtent (int extent[6]);
      Method is redundant. Same as SetDisplayExtent( int, int, int, int, int, int)


=cut

package Graphics::VTK::ImageMapper;


@Graphics::VTK::ImageMapper::ISA = qw( Graphics::VTK::Mapper2D );

=head1 Graphics::VTK::ImageMapper

=over 1

=item *

Inherits from Mapper2D

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetColorLevel ();
   float GetColorScale ();
   float GetColorShift ();
   float GetColorWindow ();
   int  *GetCustomDisplayExtents ();
      (Returns a 4-element Perl list)
   vtkImageData *GetInput ();
   unsigned long GetMTime ();
   int GetRenderToRectangle ();
   int GetUseCustomExtents ();
   int GetWholeZMax ();
   int GetWholeZMin ();
   int GetZSlice ();
   vtkImageMapper *New ();
   virtual void RenderData (vtkViewport *, vtkImageData *, vtkActor2D *) = 0;
   void RenderStart (vtkViewport *viewport, vtkActor2D *actor);
   void RenderToRectangleOff ();
   void RenderToRectangleOn ();
   void SetColorLevel (float );
   void SetColorWindow (float );
   virtual void SetInput (vtkImageData *input);
   void SetRenderToRectangle (int );
   void SetUseCustomExtents (int );
   void SetZSlice (int );
   void UseCustomExtentsOff ();
   void UseCustomExtentsOn ();


B<vtkImageMapper Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetCustomDisplayExtents (int  [4]);
      Can't handle methods with single array args (like a[3]) yet.


=cut

package Graphics::VTK::ImageViewer;


@Graphics::VTK::ImageViewer::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::ImageViewer

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   vtkActor2D *GetActor2D ();
   const char *GetClassName ();
   float GetColorLevel ();
   float GetColorWindow ();
   int GetGrayScaleHint ();
   vtkImageMapper *GetImageMapper ();
   vtkImageWindow *GetImageWindow ();
   vtkImager *GetImager ();
   vtkImageData *GetInput ();
   int *GetPosition ();
      (Returns a 2-element Perl list)
   vtkRenderWindow *GetRenderWindow ();
   vtkRenderer *GetRenderer ();
   int *GetSize ();
      (Returns a 2-element Perl list)
   int GetWholeZMax ();
   int GetWholeZMin ();
   char *GetWindowName ();
   int GetZSlice ();
   void GrayScaleHintOff ();
   void GrayScaleHintOn ();
   vtkImageViewer *New ();
   virtual void Render (void );
   void SetColorLevel (float s);
   void SetColorWindow (float s);
   void SetGrayScaleHint (int a);
   void SetInput (vtkImageData *in);
   void SetPosition (int a, int b);
   void SetSize (int a, int b);
   void SetZSlice (int s);


B<vtkImageViewer Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetDisplayId (void *a);
      Don't know the size of pointer arg number 1

   void SetParentId (void *a);
      Don't know the size of pointer arg number 1

   virtual void SetPosition (int a[2]);
      Method is redundant. Same as SetPosition( int, int)

   virtual void SetSize (int a[2]);
      Method is redundant. Same as SetSize( int, int)

   void SetWindowId (void *a);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::ImageViewer2;


@Graphics::VTK::ImageViewer2::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::ImageViewer2

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetColorLevel ();
   float GetColorWindow ();
   vtkImageActor *GetImageActor ();
   vtkImageData *GetInput ();
   vtkRenderWindow *GetRenderWindow ();
   vtkRenderer *GetRenderer ();
   int GetWholeZMax ();
   int GetWholeZMin ();
   vtkImageMapToWindowLevelColors *GetWindowLevel ();
   char *GetWindowName ();
   int GetZSlice ();
   vtkImageViewer2 *New ();
   virtual void Render (void );
   void SetColorLevel (float s);
   void SetColorWindow (float s);
   void SetInput (vtkImageData *in);
   void SetPosition (int a, int b);
   void SetSize (int a, int b);
   void SetZSlice (int s);
   void SetupInteractor (vtkRenderWindowInteractor *);


B<vtkImageViewer2 Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int *GetPosition ();
      Can't Handle 'int *' return type without a hint

   int *GetSize ();
      Can't Handle 'int *' return type without a hint

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetDisplayId (void *a);
      Don't know the size of pointer arg number 1

   void SetParentId (void *a);
      Don't know the size of pointer arg number 1

   virtual void SetPosition (int a[2]);
      Method is redundant. Same as SetPosition( int, int)

   virtual void SetSize (int a[2]);
      Method is redundant. Same as SetSize( int, int)

   void SetWindowId (void *a);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::ImageWindow;


@Graphics::VTK::ImageWindow::ISA = qw( Graphics::VTK::Window );

=head1 Graphics::VTK::ImageWindow

=over 1

=item *

Inherits from Window

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddImager (vtkImager *im);
   virtual void ClosePPMImageFile ();
   virtual void EraseWindow ();
   virtual void Frame () = 0;
   const char *GetClassName ();
   char *GetFileName ();
   int GetGrayScaleHint ();
   vtkImagerCollection *GetImagers ();
   void GrayScaleHintOff ();
   void GrayScaleHintOn ();
   virtual void MakeCurrent ();
   vtkImageWindow *New ();
   virtual int OpenPPMImageFile ();
   void RemoveImager (vtkImager *im);
   virtual void Render ();
   virtual void SaveImageAsPPM ();
   void SetFileName (char *);
   void SetGrayScaleHint (int );
   virtual void SetParentInfo (char *);
   virtual void SetPosition (int x, int y) = 0;
   virtual void SetSize (int , int ) = 0;
   virtual void SetWindowInfo (char *);
   virtual void SwapBuffers () = 0;
   virtual void WritePPMImageFile ();


B<vtkImageWindow Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void *GetGenericContext () = 0;
      Can't Handle 'void *' return type without a hint

   virtual void *GetGenericDisplayId () = 0;
      Can't Handle 'void *' return type without a hint

   virtual void *GetGenericDrawable ();
      Can't Handle 'void *' return type without a hint

   virtual void *GetGenericParentId () = 0;
      Can't Handle 'void *' return type without a hint

   virtual void *GetGenericWindowId () = 0;
      Can't Handle 'void *' return type without a hint

   virtual int *GetPosition () = 0;
      Can't Handle 'int *' return type without a hint

   virtual void GetPosition (int *x, int *y);
      Don't know the size of pointer arg number 1

   virtual int *GetSize () = 0;
      Can't Handle 'int *' return type without a hint

   virtual void GetSize (int *x, int *y);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   virtual void SetDisplayId (void *) = 0;
      Don't know the size of pointer arg number 1

   virtual void SetParentId (void *) = 0;
      Don't know the size of pointer arg number 1

   virtual void SetPosition (int a[2]);
      Method is redundant. Same as SetPosition( int, int)

   virtual void SetSize (int a[2]);
      Method is redundant. Same as SetSize( int, int)

   virtual void SetWindowId (void *) = 0;
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::Imager;


@Graphics::VTK::Imager::ISA = qw( Graphics::VTK::Viewport );

=head1 Graphics::VTK::Imager

=over 1

=item *

Inherits from Viewport

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual void Erase ();
   const char *GetClassName ();
   vtkImageWindow *GetImageWindow ();
   virtual float GetPickedZ ();
   vtkWindow *GetVTKWindow ();
   vtkImager *New ();
   virtual vtkAssemblyPath *PickProp (float selectionX, float selectionY);
   virtual int RenderOpaqueGeometry ();
   virtual int RenderOverlay ();
   virtual int RenderTranslucentGeometry ();

=cut

package Graphics::VTK::ImagerCollection;


@Graphics::VTK::ImagerCollection::ISA = qw( Graphics::VTK::Collection );

=head1 Graphics::VTK::ImagerCollection

=over 1

=item *

Inherits from Collection

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddItem (vtkImager *a);
   const char *GetClassName ();
   vtkImager *GetLastItem ();
   vtkImager *GetNextItem ();
   vtkImagerCollection *New ();

=cut

package Graphics::VTK::ImagingFactory;


@Graphics::VTK::ImagingFactory::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::ImagingFactory

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   static vtkObject *CreateInstance (const char *vtkclassname);
   const char *GetClassName ();
   vtkImagingFactory *New ();

=cut

package Graphics::VTK::Importer;


@Graphics::VTK::Importer::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::Importer

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkRenderWindow *GetRenderWindow ();
   vtkRenderer *GetRenderer ();
   void Read ();
   void SetRenderWindow (vtkRenderWindow *);
   void Update ();


B<vtkImporter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::InteractorStyle;


@Graphics::VTK::InteractorStyle::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::InteractorStyle

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AutoAdjustCameraClippingRangeOff ();
   void AutoAdjustCameraClippingRangeOn ();
   void FindPokedCamera (int , int );
   void FindPokedRenderer (int , int );
   int GetAutoAdjustCameraClippingRange ();
   int GetAutoAdjustCameraClippingRangeMaxValue ();
   int GetAutoAdjustCameraClippingRangeMinValue ();
   const char *GetClassName ();
   vtkRenderWindowInteractor *GetInteractor ();
   float  *GetPickColor ();
      (Returns a 3-element Perl list)
   virtual void HighlightActor2D (vtkActor2D *actor2D);
   virtual void HighlightProp (vtkProp *prop);
   virtual void HighlightProp3D (vtkProp3D *prop3D);
   vtkInteractorStyle *New ();
   virtual void OnChar (int ctrl, int shift, char keycode, int repeatcount);
   virtual void OnConfigure (int width, int height);
   virtual void OnEnter (int ctrl, int shift, int x, int y);
   virtual void OnKeyDown (int ctrl, int shift, char keycode, int repeatcount);
   virtual void OnKeyPress (int ctrl, int shift, char keycode, char *keysym, int repeatcount);
   virtual void OnKeyRelease (int ctrl, int shift, char keycode, char *keysym, int repeatcount);
   virtual void OnKeyUp (int ctrl, int shift, char keycode, int repeatcount);
   virtual void OnLeave (int ctrl, int shift, int x, int y);
   virtual void OnLeftButtonDown (int ctrl, int shift, int X, int Y);
   virtual void OnLeftButtonUp (int ctrl, int shift, int X, int Y);
   virtual void OnMiddleButtonDown (int ctrl, int shift, int X, int Y);
   virtual void OnMiddleButtonUp (int ctrl, int shift, int X, int Y);
   virtual void OnMouseMove (int ctrl, int shift, int X, int Y);
   virtual void OnRightButtonDown (int ctrl, int shift, int X, int Y);
   virtual void OnRightButtonUp (int ctrl, int shift, int X, int Y);
   virtual void OnTimer ();
   void SetAutoAdjustCameraClippingRange (int );
   virtual void SetInteractor (vtkRenderWindowInteractor *interactor);
   void SetLeftButtonPressMethod (void (*func)(void *) , void *arg);
   void SetLeftButtonReleaseMethod (void (*func)(void *) , void *arg);
   void SetMiddleButtonPressMethod (void (*func)(void *) , void *arg);
   void SetMiddleButtonReleaseMethod (void (*func)(void *) , void *arg);
   void SetPickColor (float , float , float );
   void SetRightButtonPressMethod (void (*func)(void *) , void *arg);
   void SetRightButtonReleaseMethod (void (*func)(void *) , void *arg);


B<vtkInteractorStyle Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void ComputeDisplayToWorld (double x, double y, double z, double *worldPt);
      Don't know the size of pointer arg number 4

   virtual void ComputeDisplayToWorld (double x, double y, double z, float *worldPt);
      Don't know the size of pointer arg number 4

   virtual void ComputeWorldToDisplay (double x, double y, double z, double *displayPt);
      Don't know the size of pointer arg number 4

   virtual void ComputeWorldToDisplay (double x, double y, double z, float *displayPt);
      Don't know the size of pointer arg number 4

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetLeftButtonPressMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void SetLeftButtonReleaseMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void SetMiddleButtonPressMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void SetMiddleButtonReleaseMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void SetPickColor (float  a[3]);
      Method is redundant. Same as SetPickColor( float, float, float)

   void SetRightButtonPressMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void SetRightButtonReleaseMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.


=cut

package Graphics::VTK::InteractorStyleFlight;


@Graphics::VTK::InteractorStyleFlight::ISA = qw( Graphics::VTK::InteractorStyle );

=head1 Graphics::VTK::InteractorStyleFlight

=over 1

=item *

Inherits from InteractorStyle

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void DisableMotionOff ();
   void DisableMotionOn ();
   void FixUpVectorOff ();
   void FixUpVectorOn ();
   double GetAngleAccelerationFactor ();
   double GetAngleStepSize ();
   const char *GetClassName ();
   int GetDisableMotion ();
   int GetFixUpVector ();
   double  *GetFixedUpVector ();
      (Returns a 3-element Perl list)
   double GetMotionAccelerationFactor ();
   double GetMotionStepSize ();
   vtkInteractorStyleFlight *New ();
   virtual void OnChar (int ctrl, int shift, char keycode, int repeatcount);
   virtual void OnKeyDown (int ctrl, int shift, char keycode, int repeatcount);
   virtual void OnKeyUp (int ctrl, int shift, char keycode, int repeatcount);
   virtual void OnLeftButtonDown (int ctrl, int shift, int X, int Y);
   virtual void OnLeftButtonUp (int ctrl, int shift, int X, int Y);
   virtual void OnMiddleButtonDown (int ctrl, int shift, int X, int Y);
   virtual void OnMiddleButtonUp (int ctrl, int shift, int X, int Y);
   virtual void OnMouseMove (int ctrl, int shift, int X, int Y);
   virtual void OnRightButtonDown (int ctrl, int shift, int X, int Y);
   virtual void OnRightButtonUp (int ctrl, int shift, int X, int Y);
   virtual void OnTimer (void );
   void PerformAzimuthalScan (int numsteps);
   void SetAngleAccelerationFactor (double );
   void SetAngleStepSize (double );
   void SetDisableMotion (int );
   void SetFixUpVector (int );
   void SetMotionAccelerationFactor (double );
   void SetMotionStepSize (double );


B<vtkInteractorStyleFlight Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void JumpTo (double campos[3], double focpos[3]);
      Don't know the size of pointer arg number 1

   void MotionAlongVector (double vector[3], double amount);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetFixedUpVector (double  [3]);
      Can't handle methods with single array args (like a[3]) yet.


=cut

package Graphics::VTK::InteractorStyleImage;


@Graphics::VTK::InteractorStyleImage::ISA = qw( Graphics::VTK::InteractorStyle );

=head1 Graphics::VTK::InteractorStyleImage

=over 1

=item *

Inherits from InteractorStyle

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int  *GetWindowLevelCurrentPosition ();
      (Returns a 2-element Perl list)
   int  *GetWindowLevelStartPosition ();
      (Returns a 2-element Perl list)
   vtkInteractorStyleImage *New ();
   void OnLeftButtonDown (int ctrl, int shift, int x, int y);
   void OnLeftButtonUp (int ctrl, int shift, int x, int y);
   void OnMiddleButtonDown (int ctrl, int shift, int x, int y);
   void OnMiddleButtonUp (int ctrl, int shift, int x, int y);
   void OnMouseMove (int ctrl, int shift, int x, int y);
   void OnRightButtonDown (int ctrl, int shift, int x, int y);
   void OnRightButtonUp (int ctrl, int shift, int x, int y);


B<vtkInteractorStyleImage Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::InteractorStyleJoystickActor;


@Graphics::VTK::InteractorStyleJoystickActor::ISA = qw( Graphics::VTK::InteractorStyle );

=head1 Graphics::VTK::InteractorStyleJoystickActor

=over 1

=item *

Inherits from InteractorStyle

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkInteractorStyleJoystickActor *New ();
   void OnLeftButtonDown (int ctrl, int shift, int x, int y);
   void OnLeftButtonUp (int ctrl, int shift, int x, int y);
   void OnMiddleButtonDown (int ctrl, int shift, int x, int y);
   void OnMiddleButtonUp (int ctrl, int shift, int x, int y);
   void OnMouseMove (int ctrl, int shift, int x, int y);
   void OnRightButtonDown (int ctrl, int shift, int x, int y);
   void OnRightButtonUp (int ctrl, int shift, int x, int y);
   void OnTimer (void );


B<vtkInteractorStyleJoystickActor Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void Prop3DTransform (vtkProp3D *prop3D, double *boxCenter, int numRotation, double *rotate, double *scale);
      Don't know the size of pointer arg number 2

   void Prop3DTransform (vtkProp3D *prop3D, float *boxCenter, int NumRotation, double *rotate, double *scale);
      Don't know the size of pointer arg number 2


=cut

package Graphics::VTK::InteractorStyleJoystickCamera;


@Graphics::VTK::InteractorStyleJoystickCamera::ISA = qw( Graphics::VTK::InteractorStyle );

=head1 Graphics::VTK::InteractorStyleJoystickCamera

=over 1

=item *

Inherits from InteractorStyle

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkInteractorStyleJoystickCamera *New ();
   void OnLeftButtonDown (int ctrl, int shift, int x, int y);
   void OnLeftButtonUp (int ctrl, int shift, int x, int y);
   void OnMiddleButtonDown (int ctrl, int shift, int x, int y);
   void OnMiddleButtonUp (int ctrl, int shift, int x, int y);
   void OnMouseMove (int ctrl, int shift, int x, int y);
   void OnRightButtonDown (int ctrl, int shift, int x, int y);
   void OnRightButtonUp (int ctrl, int shift, int x, int y);
   void OnTimer (void );


B<vtkInteractorStyleJoystickCamera Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::InteractorStyleSwitch;


@Graphics::VTK::InteractorStyleSwitch::ISA = qw( Graphics::VTK::InteractorStyle );

=head1 Graphics::VTK::InteractorStyleSwitch

=over 1

=item *

Inherits from InteractorStyle

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkInteractorStyleSwitch *New ();
   void OnChar (int ctrl, int shift, char keycode, int repeatcount);
   void OnLeftButtonDown (int ctrl, int shift, int x, int y);
   void OnLeftButtonUp (int ctrl, int shift, int x, int y);
   void OnMiddleButtonDown (int ctrl, int shift, int x, int y);
   void OnMiddleButtonUp (int ctrl, int shift, int x, int y);
   void OnMouseMove (int ctrl, int shift, int x, int y);
   void OnRightButtonDown (int ctrl, int shift, int x, int y);
   void OnRightButtonUp (int ctrl, int shift, int x, int y);
   void OnTimer ();
   void SetAutoAdjustCameraClippingRange (int value);
   void SetInteractor (vtkRenderWindowInteractor *iren);

=cut

package Graphics::VTK::InteractorStyleTrackball;


@Graphics::VTK::InteractorStyleTrackball::ISA = qw( Graphics::VTK::InteractorStyle );

=head1 Graphics::VTK::InteractorStyleTrackball

=over 1

=item *

Inherits from InteractorStyle

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int GetActorMode ();
   const char *GetClassName ();
   int GetTrackballMode ();
   vtkInteractorStyleTrackball *New ();
   virtual void OnChar (int ctrl, int shift, char keycode, int repeatcount);
   virtual void OnLeftButtonDown (int ctrl, int shift, int X, int Y);
   virtual void OnLeftButtonUp (int ctrl, int shift, int X, int Y);
   virtual void OnMiddleButtonDown (int ctrl, int shift, int X, int Y);
   virtual void OnMiddleButtonUp (int ctrl, int shift, int X, int Y);
   virtual void OnRightButtonDown (int ctrl, int shift, int X, int Y);
   virtual void OnRightButtonUp (int ctrl, int shift, int X, int Y);
   virtual void OnTimer (void );
   virtual void SetActorModeToActor ();
   virtual void SetActorModeToCamera ();
   virtual void SetTrackballModeToJoystick ();
   virtual void SetTrackballModeToTrackball ();


B<vtkInteractorStyleTrackball Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void Prop3DTransform (vtkProp3D *prop3D, double *boxCenter, int numRotation, double *rotate, double *scale);
      Don't know the size of pointer arg number 2

   void Prop3DTransform (vtkProp3D *prop3D, float *boxCenter, int NumRotation, double *rotate, double *scale);
      Don't know the size of pointer arg number 2


=cut

package Graphics::VTK::InteractorStyleTrackballActor;


@Graphics::VTK::InteractorStyleTrackballActor::ISA = qw( Graphics::VTK::InteractorStyle );

=head1 Graphics::VTK::InteractorStyleTrackballActor

=over 1

=item *

Inherits from InteractorStyle

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkInteractorStyleTrackballActor *New ();
   void OnLeftButtonDown (int ctrl, int shift, int x, int y);
   void OnLeftButtonUp (int ctrl, int shift, int x, int y);
   void OnMiddleButtonDown (int ctrl, int shift, int x, int y);
   void OnMiddleButtonUp (int ctrl, int shift, int x, int y);
   void OnMouseMove (int ctrl, int shift, int x, int y);
   void OnRightButtonDown (int ctrl, int shift, int x, int y);
   void OnRightButtonUp (int ctrl, int shift, int x, int y);


B<vtkInteractorStyleTrackballActor Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void Prop3DTransform (vtkProp3D *prop3D, double *boxCenter, int numRotation, double *rotate, double *scale);
      Don't know the size of pointer arg number 2

   void Prop3DTransform (vtkProp3D *prop3D, float *boxCenter, int NumRotation, double *rotate, double *scale);
      Don't know the size of pointer arg number 2


=cut

package Graphics::VTK::InteractorStyleTrackballCamera;


@Graphics::VTK::InteractorStyleTrackballCamera::ISA = qw( Graphics::VTK::InteractorStyle );

=head1 Graphics::VTK::InteractorStyleTrackballCamera

=over 1

=item *

Inherits from InteractorStyle

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkInteractorStyleTrackballCamera *New ();
   void OnLeftButtonDown (int ctrl, int shift, int x, int y);
   void OnLeftButtonUp (int ctrl, int shift, int x, int y);
   void OnMiddleButtonDown (int ctrl, int shift, int x, int y);
   void OnMiddleButtonUp (int ctrl, int shift, int x, int y);
   void OnMouseMove (int ctrl, int shift, int x, int y);
   void OnRightButtonDown (int ctrl, int shift, int x, int y);
   void OnRightButtonUp (int ctrl, int shift, int x, int y);


B<vtkInteractorStyleTrackballCamera Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::InteractorStyleUnicam;


@Graphics::VTK::InteractorStyleUnicam::ISA = qw( Graphics::VTK::InteractorStyle );

=head1 Graphics::VTK::InteractorStyleUnicam

=over 1

=item *

Inherits from InteractorStyle

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float  *GetWorldUpVector ();
      (Returns a 3-element Perl list)
   vtkInteractorStyleUnicam *New ();
   virtual void OnLeftButtonDown (int ctrl, int shift, int X, int Y);
   virtual void OnLeftButtonMove (int ctrl, int shift, int X, int Y);
   virtual void OnLeftButtonUp (int ctrl, int shift, int X, int Y);
   virtual void OnMiddleButtonMove (int , int , int , int );
   virtual void OnMouseMove (int ctrl, int shift, int X, int Y);
   virtual void OnRightButtonMove (int , int , int , int );
   virtual void OnTimer (void );
   void SetWorldUpVector (float x, float y, float z);


B<vtkInteractorStyleUnicam Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void GetRightVandUpV (float *p, vtkCamera *cam, float *rightV, float *upV);
      Don't know the size of pointer arg number 1

   void NormalizeMouseXY (int X, int Y, float *NX, float *NY);
      Don't know the size of pointer arg number 3

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetWorldUpVector (double a[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void SetWorldUpVector (float a[3]);
      Method is redundant. Same as SetWorldUpVector( float, float, float)


=cut

package Graphics::VTK::InteractorStyleUser;


@Graphics::VTK::InteractorStyleUser::ISA = qw( Graphics::VTK::InteractorStyleSwitch );

=head1 Graphics::VTK::InteractorStyleUser

=over 1

=item *

Inherits from InteractorStyleSwitch

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int GetButton ();
   int GetChar ();
   const char *GetClassName ();
   int GetCtrlKey ();
   char *GetKeySym ();
   int  *GetOldPos ();
      (Returns a 2-element Perl list)
   int GetShiftKey ();
   vtkInteractorStyleUser *New ();
   void SetButtonPressMethod (void (*func)(void *) , void *arg);
   void SetButtonReleaseMethod (void (*func)(void *) , void *arg);
   void SetCharMethod (void (*func)(void *) , void *arg);
   void SetConfigureMethod (void (*func)(void *) , void *arg);
   void SetEnterMethod (void (*func)(void *) , void *arg);
   void SetKeyPressMethod (void (*func)(void *) , void *arg);
   void SetKeyReleaseMethod (void (*func)(void *) , void *arg);
   void SetLeaveMethod (void (*func)(void *) , void *arg);
   void SetMouseMoveMethod (void (*func)(void *) , void *arg);
   void SetTimerMethod (void (*func)(void *) , void *arg);


B<vtkInteractorStyleUser Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void EndUserInteraction ();
      Method is marked 'Do Not Use' in its descriptions

   int  *GetLastPos ();
      Method is marked 'Do Not Use' in its descriptions

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetButtonPressMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void SetButtonReleaseMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void SetCharMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void SetConfigureMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void SetEnterMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void SetKeyPressMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void SetKeyReleaseMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void SetLeaveMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void SetMouseMoveMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void SetTimerMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void SetUserInteractionMethod (void (*func)(void *) , void *arg);
      Method is marked 'Do Not Use' in its descriptions

   void SetUserInteractionMethodArgDelete (void (*func)(void *) );
      Method is marked 'Do Not Use' in its descriptions

   void StartUserInteraction ();
      Method is marked 'Do Not Use' in its descriptions

   void vtkSetOldCallback (unsigned long &tag, unsigned long event, void (*func)(void *) , void *arg);
      Arg types of 'unsigned long &' not supported yet

=cut

package Graphics::VTK::LODActor;


@Graphics::VTK::LODActor::ISA = qw( Graphics::VTK::Actor );

=head1 Graphics::VTK::LODActor

=over 1

=item *

Inherits from Actor

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddLODMapper (vtkMapper *mapper);
   const char *GetClassName ();
   vtkMapperCollection *GetLODMappers ();
   int GetNumberOfCloudPoints ();
   void Modified ();
   vtkLODActor *New ();
   void ReleaseGraphicsResources (vtkWindow *);
   virtual void Render (vtkRenderer *, vtkMapper *);
   int RenderOpaqueGeometry (vtkViewport *viewport);
   void SetNumberOfCloudPoints (int );
   void ShallowCopy (vtkProp *prop);


B<vtkLODActor Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::LODProp3D;


@Graphics::VTK::LODProp3D::ISA = qw( Graphics::VTK::Prop3D );

=head1 Graphics::VTK::LODProp3D

=over 1

=item *

Inherits from Prop3D

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int AddLOD (vtkMapper *m, vtkProperty *p, vtkProperty *back, vtkTexture *t, float time);
   int AddLOD (vtkMapper *m, vtkProperty *p, vtkTexture *t, float time);
   int AddLOD (vtkMapper *m, vtkProperty *p, vtkProperty *back, float time);
   int AddLOD (vtkVolumeMapper *m, vtkVolumeProperty *p, float time);
   int AddLOD (vtkMapper *m, vtkTexture *t, float time);
   int AddLOD (vtkMapper *m, vtkProperty *p, float time);
   int AddLOD (vtkVolumeMapper *m, float time);
   int AddLOD (vtkMapper *m, float time);
   void AutomaticLODSelectionOff ();
   void AutomaticLODSelectionOn ();
   void AutomaticPickLODSelectionOff ();
   void AutomaticPickLODSelectionOn ();
   void DisableLOD (int id);
   void EnableLOD (int id);
   virtual void GetActors (vtkPropCollection *);
   int GetAutomaticLODSelection ();
   int GetAutomaticLODSelectionMaxValue ();
   int GetAutomaticLODSelectionMinValue ();
   int GetAutomaticPickLODSelection ();
   int GetAutomaticPickLODSelectionMaxValue ();
   int GetAutomaticPickLODSelectionMinValue ();
   float *GetBounds ();
      (Returns a 6-element Perl list)
   const char *GetClassName ();
   float GetLODEstimatedRenderTime (int id);
   float GetLODIndexEstimatedRenderTime (int index);
   float GetLODIndexLevel (int index);
   float GetLODLevel (int id);
   vtkAbstractMapper3D *GetLODMapper (int id);
   int GetLastRenderedLODID ();
   int GetPickLODID (void );
   int GetSelectedLODID ();
   int GetSelectedPickLODID ();
   vtkLODProp3DEntry static vtkLODProp3D *New ();
   void RemoveLOD (int id);
   void SetAutomaticLODSelection (int );
   void SetAutomaticPickLODSelection (int );
   void SetLODBackfaceProperty (int id, vtkProperty *t);
   void SetLODLevel (int id, float level);
   void SetLODMapper (int id, vtkVolumeMapper *m);
   void SetLODMapper (int id, vtkMapper *m);
   void SetLODProperty (int id, vtkVolumeProperty *p);
   void SetLODProperty (int id, vtkProperty *p);
   void SetLODTexture (int id, vtkTexture *t);
   void SetPickMethod (void (*func)(void *) , void *arg);
   void SetSelectedLODID (int );
   void SetSelectedPickLODID (int id);
   void ShallowCopy (vtkProp *prop);


B<vtkLODProp3D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void GetBounds (float bounds[6]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void GetLODBackfaceProperty (int id, vtkProperty *t);
      Don't know the size of pointer arg number 2

   void GetLODMapper (int id, vtkMapper *m);
      Don't know the size of pointer arg number 2

   void GetLODMapper (int id, vtkVolumeMapper *m);
      Don't know the size of pointer arg number 2

   void GetLODProperty (int id, vtkProperty *p);
      Don't know the size of pointer arg number 2

   void GetLODProperty (int id, vtkVolumeProperty *p);
      Don't know the size of pointer arg number 2

   void GetLODTexture (int id, vtkTexture *t);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetPickMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.


=cut

package Graphics::VTK::LabeledDataMapper;


@Graphics::VTK::LabeledDataMapper::ISA = qw( Graphics::VTK::Mapper2D );

=head1 Graphics::VTK::LabeledDataMapper

=over 1

=item *

Inherits from Mapper2D

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void BoldOff ();
   void BoldOn ();
   int GetBold ();
   const char *GetClassName ();
   int GetFieldDataArray ();
   int GetFieldDataArrayMaxValue ();
   int GetFieldDataArrayMinValue ();
   int GetFontFamily ();
   int GetFontSize ();
   int GetFontSizeMaxValue ();
   int GetFontSizeMinValue ();
   vtkDataSet *GetInput ();
   int GetItalic ();
   char *GetLabelFormat ();
   int GetLabelMode ();
   int GetLabeledComponent ();
   int GetShadow ();
   void ItalicOff ();
   void ItalicOn ();
   vtkLabeledDataMapper *New ();
   virtual void ReleaseGraphicsResources (vtkWindow *);
   void RenderOpaqueGeometry (vtkViewport *viewport, vtkActor2D *actor);
   void RenderOverlay (vtkViewport *viewport, vtkActor2D *actor);
   void SetBold (int );
   void SetFieldDataArray (int );
   void SetFontFamily (int );
   void SetFontFamilyToArial ();
   void SetFontFamilyToCourier ();
   void SetFontFamilyToTimes ();
   void SetFontSize (int );
   void SetInput (vtkDataSet *);
   void SetItalic (int );
   void SetLabelFormat (char *);
   void SetLabelMode (int );
   void SetLabelModeToLabelFieldData ();
   void SetLabelModeToLabelIds ();
   void SetLabelModeToLabelNormals ();
   void SetLabelModeToLabelScalars ();
   void SetLabelModeToLabelTCoords ();
   void SetLabelModeToLabelTensors ();
   void SetLabelModeToLabelVectors ();
   void SetLabeledComponent (int );
   void SetShadow (int );
   void ShadowOff ();
   void ShadowOn ();


B<vtkLabeledDataMapper Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::Light;


@Graphics::VTK::Light::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::Light

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void DeepCopy (vtkLight *light);
   float  *GetAttenuationValues ();
      (Returns a 3-element Perl list)
   const char *GetClassName ();
   float  *GetColor ();
      (Returns a 3-element Perl list)
   float GetConeAngle ();
   float GetExponent ();
   float  *GetFocalPoint ();
      (Returns a 3-element Perl list)
   float GetIntensity ();
   int GetLightType ();
   float  *GetPosition ();
      (Returns a 3-element Perl list)
   int GetPositional ();
   int GetSwitch ();
   vtkMatrix4x4 *GetTransformMatrix ();
   void GetTransformedFocalPoint (float &a0, float &a1, float &a2);
   float *GetTransformedFocalPoint ();
      (Returns a 3-element Perl list)
   void GetTransformedPosition (float &a0, float &a1, float &a2);
   float *GetTransformedPosition ();
      (Returns a 3-element Perl list)
   int LightTypeIsCameraLight ();
   int LightTypeIsHeadlight ();
   int LightTypeIsSceneLight ();
   vtkLight *New ();
   void PositionalOff ();
   void PositionalOn ();
   virtual void Render (vtkRenderer *, int );
   void SetAttenuationValues (float , float , float );
   void SetColor (float , float , float );
   void SetConeAngle (float );
   void SetDirectionAngle (float elevation, float azimuth);
   void SetExponent (float );
   void SetFocalPoint (float , float , float );
   void SetIntensity (float );
   void SetLightType (int );
   void SetLightTypeToCameraLight ();
   void SetLightTypeToHeadlight ();
   void SetLightTypeToSceneLight ();
   void SetPosition (float , float , float );
   void SetPositional (int );
   void SetSwitch (int );
   void SetTransformMatrix (vtkMatrix4x4 *);
   void SwitchOff ();
   void SwitchOn ();


B<vtkLight Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void GetTransformedFocalPoint (float a[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void GetTransformedPosition (float a[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ReadSelf (istream &is);
      Arg types of 'istream' not supported yet
   void SetAttenuationValues (float  a[3]);
      Method is redundant. Same as SetAttenuationValues( float, float, float)

   void SetColor (float  a[3]);
      Method is redundant. Same as SetColor( float, float, float)

   void SetDirectionAngle (float ang[2]);
      Method is redundant. Same as SetDirectionAngle( float, float)

   void SetFocalPoint (float  a[3]);
      Method is redundant. Same as SetFocalPoint( float, float, float)

   void SetFocalPoint (double *a);
      Don't know the size of pointer arg number 1

   void SetPosition (float  a[3]);
      Method is redundant. Same as SetPosition( float, float, float)

   void SetPosition (double *a);
      Don't know the size of pointer arg number 1

   void WriteSelf (ostream &os);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::LightCollection;


@Graphics::VTK::LightCollection::ISA = qw( Graphics::VTK::Collection );

=head1 Graphics::VTK::LightCollection

=over 1

=item *

Inherits from Collection

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddItem (vtkLight *a);
   const char *GetClassName ();
   vtkLight *GetNextItem ();
   vtkLightCollection *New ();

=cut

package Graphics::VTK::LightKit;


@Graphics::VTK::LightKit::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::LightKit

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddLightsToRenderer (vtkRenderer *renderer);
   void DeepCopy (vtkLightKit *kit);
   const char *GetClassName ();
   float  *GetFillLightAngle ();
      (Returns a 2-element Perl list)
   float GetFillLightAzimuth ();
   float  *GetFillLightColor ();
      (Returns a 3-element Perl list)
   float GetFillLightElevation ();
   float GetFillLightWarmth ();
   float  *GetHeadlightColor ();
      (Returns a 3-element Perl list)
   float GetHeadlightWarmth ();
   float  *GetKeyLightAngle ();
      (Returns a 2-element Perl list)
   float GetKeyLightAzimuth ();
   float  *GetKeyLightColor ();
      (Returns a 3-element Perl list)
   float GetKeyLightElevation ();
   float GetKeyLightIntensity ();
   float GetKeyLightWarmth ();
   float GetKeyToFillRatio ();
   float GetKeyToFillRatioMaxValue ();
   float GetKeyToFillRatioMinValue ();
   float GetKeyToHeadRatio ();
   float GetKeyToHeadRatioMaxValue ();
   float GetKeyToHeadRatioMinValue ();
   int GetMaintainLuminance ();
   void MaintainLuminanceOff ();
   void MaintainLuminanceOn ();
   void Modified ();
   vtkLightKit *New ();
   void RemoveLightsFromRenderer (vtkRenderer *renderer);
   void SetFillLightAngle (float elevation, float azimuth);
   void SetFillLightAzimuth (float x);
   void SetFillLightElevation (float x);
   void SetFillLightWarmth (float );
   void SetHeadlightWarmth (float );
   void SetKeyLightAngle (float elevation, float azimuth);
   void SetKeyLightAzimuth (float x);
   void SetKeyLightElevation (float x);
   void SetKeyLightIntensity (float );
   void SetKeyLightWarmth (float );
   void SetKeyToFillRatio (float );
   void SetKeyToHeadRatio (float );
   void SetMaintainLuminance (int );
   void Update ();


B<vtkLightKit Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetFillLightAngle (float angle[2]);
      Method is redundant. Same as SetFillLightAngle( float, float)

   void SetKeyLightAngle (float angle[2]);
      Method is redundant. Same as SetKeyLightAngle( float, float)

   void WarmthToRGB (float w, float rgb[3]);
      Don't know the size of pointer arg number 2

   void WarmthToRGBI (float w, float rgb[3], float &i);
      Don't know the size of pointer arg number 2


=cut

package Graphics::VTK::Mapper;


@Graphics::VTK::Mapper::ISA = qw( Graphics::VTK::AbstractMapper3D );

=head1 Graphics::VTK::Mapper

=over 1

=item *

Inherits from AbstractMapper3D

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void ColorByArrayComponent (char *arrayName, int component);
   void ColorByArrayComponent (int arrayNum, int component);
   virtual void CreateDefaultLookupTable ();
   int GetArrayAccessMode ();
   int GetArrayComponent ();
   int GetArrayId ();
   char *GetArrayName ();
   virtual float *GetBounds ();
      (Returns a 6-element Perl list)
   const char *GetClassName ();
   int GetColorMode ();
   const char *GetColorModeAsString ();
   static int GetGlobalImmediateModeRendering ();
   int GetImmediateModeRendering ();
   vtkDataSet *GetInputAsDataSet ();
   vtkScalarsToColors *GetLookupTable ();
   unsigned long GetMTime ();
   float GetRenderTime ();
   static int GetResolveCoincidentTopology ();
   static void GetResolveCoincidentTopologyPolygonOffsetParameters (float &factor, float &units);
   static double GetResolveCoincidentTopologyZShift ();
   int GetScalarMode ();
   const char *GetScalarModeAsString ();
   float  *GetScalarRange ();
      (Returns a 2-element Perl list)
   int GetScalarVisibility ();
   int GetUseLookupTableScalarRange ();
   static void GlobalImmediateModeRenderingOff ();
   static void GlobalImmediateModeRenderingOn ();
   void ImmediateModeRenderingOff ();
   void ImmediateModeRenderingOn ();
   vtkUnsignedCharArray *MapScalars (float alpha);
   virtual void ReleaseGraphicsResources (vtkWindow *);
   virtual void Render (vtkRenderer *ren, vtkActor *a) = 0;
   void ScalarVisibilityOff ();
   void ScalarVisibilityOn ();
   void SetColorMode (int );
   void SetColorModeToDefault ();
   void SetColorModeToMapScalars ();
   static void SetGlobalImmediateModeRendering (int val);
   void SetImmediateModeRendering (int );
   void SetLookupTable (vtkScalarsToColors *lut);
   void SetRenderTime (float time);
   static void SetResolveCoincidentTopology (int val);
   static void SetResolveCoincidentTopologyPolygonOffsetParameters (float factor, float units);
   static void SetResolveCoincidentTopologyToDefault ();
   static void SetResolveCoincidentTopologyToOff ();
   static void SetResolveCoincidentTopologyToPolygonOffset ();
   static void SetResolveCoincidentTopologyToShiftZBuffer ();
   static void SetResolveCoincidentTopologyZShift (double val);
   void SetScalarMode (int );
   void SetScalarModeToDefault ();
   void SetScalarModeToUseCellData ();
   void SetScalarModeToUseCellFieldData ();
   void SetScalarModeToUsePointData ();
   void SetScalarModeToUsePointFieldData ();
   void SetScalarRange (float , float );
   void SetScalarVisibility (int );
   void SetUseLookupTableScalarRange (int );
   void ShallowCopy (vtkAbstractMapper *m);
   virtual void Update ();
   void UseLookupTableScalarRangeOff ();
   void UseLookupTableScalarRangeOn ();


B<vtkMapper Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void GetBounds (float bounds[6]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetScalarRange (float  a[2]);
      Method is redundant. Same as SetScalarRange( float, float)


=cut

package Graphics::VTK::MapperCollection;


@Graphics::VTK::MapperCollection::ISA = qw( Graphics::VTK::Collection );

=head1 Graphics::VTK::MapperCollection

=over 1

=item *

Inherits from Collection

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddItem (vtkMapper *a);
   const char *GetClassName ();
   vtkMapper *GetLastItem ();
   vtkMapper *GetNextItem ();
   vtkMapperCollection *New ();

=cut

package Graphics::VTK::OBJExporter;


@Graphics::VTK::OBJExporter::ISA = qw( Graphics::VTK::Exporter );

=head1 Graphics::VTK::OBJExporter

=over 1

=item *

Inherits from Exporter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   char *GetFilePrefix ();
   vtkOBJExporter *New ();
   void SetFilePrefix (char *);


B<vtkOBJExporter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void WriteAnActor (vtkActor *anActor, FILE *fpObj, FILE *fpMat, int &id);
      Don't know the size of pointer arg number 2


=cut

package Graphics::VTK::OOGLExporter;


@Graphics::VTK::OOGLExporter::ISA = qw( Graphics::VTK::Exporter );

=head1 Graphics::VTK::OOGLExporter

=over 1

=item *

Inherits from Exporter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   char *GetFileName ();
   vtkOOGLExporter *New ();
   void SetFileName (char *);


B<vtkOOGLExporter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void WriteALight (vtkLight *aLight, FILE *fp);
      Don't know the size of pointer arg number 2

   void WriteAnActor (vtkActor *anActor, FILE *fp, int count);
      Don't know the size of pointer arg number 2


=cut

package Graphics::VTK::ParallelCoordinatesActor;


@Graphics::VTK::ParallelCoordinatesActor::ISA = qw( Graphics::VTK::Actor2D );

=head1 Graphics::VTK::ParallelCoordinatesActor

=over 1

=item *

Inherits from Actor2D

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void BoldOff ();
   void BoldOn ();
   int GetBold ();
   const char *GetClassName ();
   int GetFontFamily ();
   int GetIndependentVariables ();
   int GetIndependentVariablesMaxValue ();
   int GetIndependentVariablesMinValue ();
   vtkDataObject *GetInput ();
   int GetItalic ();
   char *GetLabelFormat ();
   int GetNumberOfLabels ();
   int GetNumberOfLabelsMaxValue ();
   int GetNumberOfLabelsMinValue ();
   int GetShadow ();
   char *GetTitle ();
   void ItalicOff ();
   void ItalicOn ();
   vtkParallelCoordinatesActor *New ();
   void ReleaseGraphicsResources (vtkWindow *);
   int RenderOpaqueGeometry (vtkViewport *);
   int RenderOverlay (vtkViewport *);
   int RenderTranslucentGeometry (vtkViewport *);
   void SetBold (int );
   void SetFontFamily (int );
   void SetFontFamilyToArial ();
   void SetFontFamilyToCourier ();
   void SetFontFamilyToTimes ();
   void SetIndependentVariables (int );
   void SetIndependentVariablesToColumns ();
   void SetIndependentVariablesToRows ();
   void SetInput (vtkDataObject *);
   void SetItalic (int );
   void SetLabelFormat (char *);
   void SetNumberOfLabels (int );
   void SetShadow (int );
   void SetTitle (char *);
   void ShadowOff ();
   void ShadowOn ();


B<vtkParallelCoordinatesActor Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int PlaceAxes (vtkViewport *viewport, int *size);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::Picker;


@Graphics::VTK::Picker::ISA = qw( Graphics::VTK::AbstractPropPicker );

=head1 Graphics::VTK::Picker

=over 1

=item *

Inherits from AbstractPropPicker

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   vtkActorCollection *GetActors ();
   const char *GetClassName ();
   vtkDataSet *GetDataSet ();
   vtkAbstractMapper3D *GetMapper ();
   float  *GetMapperPosition ();
      (Returns a 3-element Perl list)
   vtkPoints *GetPickedPositions ();
   vtkProp3DCollection *GetProp3Ds ();
   float GetTolerance ();
   vtkPicker *New ();
   virtual int Pick (float selectionX, float selectionY, float selectionZ, vtkRenderer *renderer);
   void SetTolerance (float );


B<vtkPicker Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual float IntersectWithLine (float p1[3], float p2[3], float tol, vtkAssemblyPath *path, vtkProp3D *p, vtkAbstractMapper3D *m);
      Don't know the size of pointer arg number 1

   void MarkPicked (vtkAssemblyPath *path, vtkProp3D *p, vtkAbstractMapper3D *m, float tMin, float mapperPos[3]);
      Don't know the size of pointer arg number 5

   int Pick (float selectionPt[3], vtkRenderer *ren);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::PointPicker;


@Graphics::VTK::PointPicker::ISA = qw( Graphics::VTK::Picker );

=head1 Graphics::VTK::PointPicker

=over 1

=item *

Inherits from Picker

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   long GetPointId ();
   vtkPointPicker *New ();


B<vtkPointPicker Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   float IntersectWithLine (float p1[3], float p2[3], float tol, vtkAssemblyPath *path, vtkProp3D *p, vtkAbstractMapper3D *m);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::PolyDataMapper;


@Graphics::VTK::PolyDataMapper::ISA = qw( Graphics::VTK::Mapper );

=head1 Graphics::VTK::PolyDataMapper

=over 1

=item *

Inherits from Mapper

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual float *GetBounds ();
      (Returns a 6-element Perl list)
   const char *GetClassName ();
   int GetGhostLevel ();
   vtkPolyData *GetInput ();
   int GetNumberOfPieces ();
   int GetNumberOfSubPieces ();
   int GetPiece ();
   vtkPolyDataMapper *New ();
   virtual void Render (vtkRenderer *ren, vtkActor *act);
   virtual void RenderPiece (vtkRenderer *ren, vtkActor *act) = 0;
   void SetGhostLevel (int );
   void SetInput (vtkPolyData *in);
   void SetNumberOfPieces (int );
   void SetNumberOfSubPieces (int );
   void SetPiece (int );
   void ShallowCopy (vtkAbstractMapper *m);
   void Update ();


B<vtkPolyDataMapper Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void GetBounds (float bounds[6]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::PolyDataMapper2D;


@Graphics::VTK::PolyDataMapper2D::ISA = qw( Graphics::VTK::Mapper2D );

=head1 Graphics::VTK::PolyDataMapper2D

=over 1

=item *

Inherits from Mapper2D

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void ColorByArrayComponent (char *arrayName, int component);
   void ColorByArrayComponent (int arrayNum, int component);
   virtual void CreateDefaultLookupTable ();
   int GetArrayAccessMode ();
   int GetArrayComponent ();
   int GetArrayId ();
   char *GetArrayName ();
   const char *GetClassName ();
   int GetColorMode ();
   const char *GetColorModeAsString ();
   vtkPolyData *GetInput ();
   vtkScalarsToColors *GetLookupTable ();
   virtual unsigned long GetMTime ();
   int GetScalarMode ();
   float  *GetScalarRange ();
      (Returns a 2-element Perl list)
   int GetScalarVisibility ();
   vtkCoordinate *GetTransformCoordinate ();
   int GetUseLookupTableScalarRange ();
   vtkUnsignedCharArray *MapScalars (float alpha);
   vtkPolyDataMapper2D *New ();
   void ScalarVisibilityOff ();
   void ScalarVisibilityOn ();
   void SetColorMode (int );
   void SetColorModeToDefault ();
   void SetColorModeToMapScalars ();
   void SetInput (vtkPolyData *);
   void SetLookupTable (vtkScalarsToColors *lut);
   void SetScalarMode (int );
   void SetScalarModeToDefault ();
   void SetScalarModeToUseCellData ();
   void SetScalarModeToUseCellFieldData ();
   void SetScalarModeToUsePointData ();
   void SetScalarModeToUsePointFieldData ();
   void SetScalarRange (float , float );
   void SetScalarVisibility (int );
   void SetTransformCoordinate (vtkCoordinate *);
   void SetUseLookupTableScalarRange (int );
   void ShallowCopy (vtkAbstractMapper *m);
   void UseLookupTableScalarRangeOff ();
   void UseLookupTableScalarRangeOn ();


B<vtkPolyDataMapper2D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetScalarRange (float  a[2]);
      Method is redundant. Same as SetScalarRange( float, float)


=cut

package Graphics::VTK::Prop3D;


@Graphics::VTK::Prop3D::ISA = qw( Graphics::VTK::Prop );

=head1 Graphics::VTK::Prop3D

=over 1

=item *

Inherits from Prop

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddOrientation (float , float , float );
   void AddPosition (float deltaX, float deltaY, float deltaZ);
   virtual void ComputeMatrix ();
   virtual float *GetBounds () = 0;
      (Returns a 6-element Perl list)
   float *GetCenter ();
      (Returns a 3-element Perl list)
   const char *GetClassName ();
   int GetIsIdentity ();
   float GetLength ();
   virtual void GetMatrix (vtkMatrix4x4 *m);
   vtkMatrix4x4 *GetMatrix ();
   float *GetOrientation ();
      (Returns a 3-element Perl list)
   float *GetOrientationWXYZ ();
      (Returns a 4-element Perl list)
   float  *GetOrigin ();
      (Returns a 3-element Perl list)
   float  *GetPosition ();
      (Returns a 3-element Perl list)
   float  *GetScale ();
      (Returns a 3-element Perl list)
   vtkMatrix4x4 *GetUserMatrix ();
   vtkLinearTransform *GetUserTransform ();
   float *GetXRange ();
      (Returns a 2-element Perl list)
   float *GetYRange ();
      (Returns a 2-element Perl list)
   float *GetZRange ();
      (Returns a 2-element Perl list)
   void InitPathTraversal ();
   void PokeMatrix (vtkMatrix4x4 *matrix);
   void RotateWXYZ (float , float , float , float );
   void RotateX (float );
   void RotateY (float );
   void RotateZ (float );
   void SetOrientation (float , float , float );
   virtual void SetOrigin (float _arg1, float _arg2, float _arg3);
   virtual void SetPosition (float _arg1, float _arg2, float _arg3);
   virtual void SetScale (float _arg1, float _arg2, float _arg3);
   void SetScale (float s);
   void SetUserMatrix (vtkMatrix4x4 *matrix);
   void SetUserTransform (vtkLinearTransform *transform);
   void ShallowCopy (vtkProp *prop);


B<vtkProp3D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void AddOrientation (float a[3]);
      Method is redundant. Same as AddOrientation( float, float, float)

   void AddPosition (float deltaPosition[3]);
      Method is redundant. Same as AddPosition( float, float, float)

   void GetBounds (float bounds[6]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   virtual void GetMatrix (double m[16]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void GetOrientation (float o[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetOrientation (float a[3]);
      Method is redundant. Same as SetOrientation( float, float, float)

   virtual void SetOrigin (float _arg[3]);
      Method is redundant. Same as SetOrigin( float, float, float)

   virtual void SetPosition (float _arg[3]);
      Method is redundant. Same as SetPosition( float, float, float)

   virtual void SetScale (float _arg[3]);
      Method is redundant. Same as SetScale( float, float, float)


=cut

package Graphics::VTK::Prop3DCollection;


@Graphics::VTK::Prop3DCollection::ISA = qw( Graphics::VTK::PropCollection );

=head1 Graphics::VTK::Prop3DCollection

=over 1

=item *

Inherits from PropCollection

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddItem (vtkProp3D *p);
   const char *GetClassName ();
   vtkProp3D *GetLastProp3D ();
   vtkProp3D *GetNextProp3D ();
   vtkProp3DCollection *New ();

=cut

package Graphics::VTK::PropPicker;


@Graphics::VTK::PropPicker::ISA = qw( Graphics::VTK::AbstractPropPicker );

=head1 Graphics::VTK::PropPicker

=over 1

=item *

Inherits from AbstractPropPicker

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkPropPicker *New ();
   int Pick (float selectionX, float selectionY, float selectionZ, vtkRenderer *renderer);
   int PickProp (float selectionX, float selectionY, vtkRenderer *renderer, vtkPropCollection *pickfrom);
   int PickProp (float selectionX, float selectionY, vtkRenderer *renderer);


B<vtkPropPicker Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int Pick (float selectionPt[3], vtkRenderer *renderer);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::Property;


@Graphics::VTK::Property::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::Property

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void BackfaceCullingOff ();
   void BackfaceCullingOn ();
   virtual void BackfaceRender (vtkActor *, vtkRenderer *);
   void DeepCopy (vtkProperty *p);
   void EdgeVisibilityOff ();
   void EdgeVisibilityOn ();
   void FrontfaceCullingOff ();
   void FrontfaceCullingOn ();
   float GetAmbient ();
   float  *GetAmbientColor ();
      (Returns a 3-element Perl list)
   float GetAmbientMaxValue ();
   float GetAmbientMinValue ();
   int GetBackfaceCulling ();
   const char *GetClassName ();
   float *GetColor ();
      (Returns a 3-element Perl list)
   float GetDiffuse ();
   float  *GetDiffuseColor ();
      (Returns a 3-element Perl list)
   float GetDiffuseMaxValue ();
   float GetDiffuseMinValue ();
   float  *GetEdgeColor ();
      (Returns a 3-element Perl list)
   int GetEdgeVisibility ();
   int GetFrontfaceCulling ();
   int GetInterpolation ();
   char *GetInterpolationAsString ();
   int GetInterpolationMaxValue ();
   int GetInterpolationMinValue ();
   int GetLineStipplePattern ();
   int GetLineStippleRepeatFactor ();
   int GetLineStippleRepeatFactorMaxValue ();
   int GetLineStippleRepeatFactorMinValue ();
   float GetLineWidth ();
   float GetLineWidthMaxValue ();
   float GetLineWidthMinValue ();
   float GetOpacity ();
   float GetOpacityMaxValue ();
   float GetOpacityMinValue ();
   float GetPointSize ();
   float GetPointSizeMaxValue ();
   float GetPointSizeMinValue ();
   int GetRepresentation ();
   char *GetRepresentationAsString ();
   int GetRepresentationMaxValue ();
   int GetRepresentationMinValue ();
   float GetSpecular ();
   float  *GetSpecularColor ();
      (Returns a 3-element Perl list)
   float GetSpecularMaxValue ();
   float GetSpecularMinValue ();
   float GetSpecularPower ();
   float GetSpecularPowerMaxValue ();
   float GetSpecularPowerMinValue ();
   vtkProperty *New ();
   virtual void Render (vtkActor *, vtkRenderer *);
   void SetAmbient (float );
   void SetAmbientColor (float , float , float );
   void SetBackfaceCulling (int );
   void SetColor (float r, float g, float b);
   void SetDiffuse (float );
   void SetDiffuseColor (float , float , float );
   void SetEdgeColor (float , float , float );
   void SetEdgeVisibility (int );
   void SetFrontfaceCulling (int );
   void SetInterpolation (int );
   void SetInterpolationToFlat ();
   void SetInterpolationToGouraud ();
   void SetInterpolationToPhong ();
   void SetLineStipplePattern (int );
   void SetLineStippleRepeatFactor (int );
   void SetLineWidth (float );
   void SetOpacity (float );
   void SetPointSize (float );
   void SetRepresentation (int );
   void SetRepresentationToPoints ();
   void SetRepresentationToSurface ();
   void SetRepresentationToWireframe ();
   void SetSpecular (float );
   void SetSpecularColor (float , float , float );
   void SetSpecularPower (float );


B<vtkProperty Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void GetColor (float rgb[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetAmbientColor (float  a[3]);
      Method is redundant. Same as SetAmbientColor( float, float, float)

   void SetColor (float a[3]);
      Method is redundant. Same as SetColor( float, float, float)

   void SetDiffuseColor (float  a[3]);
      Method is redundant. Same as SetDiffuseColor( float, float, float)

   void SetEdgeColor (float  a[3]);
      Method is redundant. Same as SetEdgeColor( float, float, float)

   void SetSpecularColor (float  a[3]);
      Method is redundant. Same as SetSpecularColor( float, float, float)


=cut

package Graphics::VTK::RayCaster;


@Graphics::VTK::RayCaster::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::RayCaster

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AutomaticScaleAdjustmentOff (void );
   void AutomaticScaleAdjustmentOn (void );
   void BilinearImageZoomOff ();
   void BilinearImageZoomOn ();
   int GetAutomaticScaleAdjustment ();
   float GetAutomaticScaleLowerLimit ();
   int GetBilinearImageZoom ();
   const char *GetClassName ();
   float GetImageScale (int level);
   int GetImageScaleCount (void );
   int GetNumberOfSamplesTaken ();
   int GetNumberOfThreads ();
   float *GetParallelIncrements (void );
      (Returns a 2-element Perl list)
   float *GetParallelStartPosition (void );
      (Returns a 3-element Perl list)
   float GetSelectedImageScaleIndex (int level);
   float GetTotalRenderTime ();
   float GetViewRaysStepSize (int level);
   vtkRayCaster *New ();
   void SetAutomaticScaleLowerLimit (float scale);
   void SetBilinearImageZoom (int val);
   void SetImageScale (int level, float scale);
   void SetNumberOfThreads (int val);
   void SetSelectedImageScaleIndex (int level, float scale);
   void SetViewRaysStepSize (int level, float scale);


B<vtkRayCaster Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   float *GetPerspectiveViewRays ();
      Can't Handle 'float *' return type without a hint

   void GetViewRaysSize (int size[2]);
      Can't handle methods with single array args (like a[3]) yet.


=cut

package Graphics::VTK::RecursiveSphereDirectionEncoder;


@Graphics::VTK::RecursiveSphereDirectionEncoder::ISA = qw( Graphics::VTK::DirectionEncoder );

=head1 Graphics::VTK::RecursiveSphereDirectionEncoder

=over 1

=item *

Inherits from DirectionEncoder

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float *GetDecodedGradient (int value);
      (Returns a 3-element Perl list)
   int GetNumberOfEncodedDirections (void );
   int GetRecursionDepth ();
   int GetRecursionDepthMaxValue ();
   int GetRecursionDepthMinValue ();
   vtkRecursiveSphereDirectionEncoder *New ();
   void SetRecursionDepth (int );


B<vtkRecursiveSphereDirectionEncoder Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   float *GetDecodedGradientTable (void );
      Can't Handle 'float *' return type without a hint

   int GetEncodedDirection (float n[3]);
      Can't handle methods with single array args (like a[3]) yet.

   void PrintSelf (ostream &os, vtkIndent index);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::RenderWindow;


@Graphics::VTK::RenderWindow::ISA = qw( Graphics::VTK::Window );

=head1 Graphics::VTK::RenderWindow

=over 1

=item *

Inherits from Window

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddRenderer (vtkRenderer *);
   void BordersOff ();
   void BordersOn ();
   virtual int CheckAbortStatus ();
   virtual void CopyResultFrame ();
   virtual void Frame ();
   void FullScreenOff ();
   void FullScreenOn ();
   int GetAAFrames ();
   int GetAbortRender ();
   int GetBorders ();
   const char *GetClassName ();
   virtual int GetDepthBufferSize ();
   float GetDesiredUpdateRate ();
   virtual int GetEventPending ();
   int GetFDFrames ();
   int GetFullScreen ();
   int GetInAbortCheck ();
   vtkRenderWindowInteractor *GetInteractor ();
   int GetLineSmoothing ();
   int GetNeverRendered ();
   int GetNumberOfLayers ();
   int GetNumberOfLayersMaxValue ();
   int GetNumberOfLayersMinValue ();
   int GetPointSmoothing ();
   int GetPolygonSmoothing ();
   static const char *GetRenderLibrary ();
   vtkRendererCollection *GetRenderers ();
   int GetStereoCapableWindow ();
   int GetStereoRender ();
   int GetStereoType ();
   char *GetStereoTypeAsString ();
   int GetSubFrames ();
   int GetSwapBuffers ();
   virtual void HideCursor ();
   void LineSmoothingOff ();
   void LineSmoothingOn ();
   virtual void MakeCurrent ();
   virtual vtkRenderWindowInteractor *MakeRenderWindowInteractor ();
   vtkRenderWindow *New ();
   void PointSmoothingOff ();
   void PointSmoothingOn ();
   void PolygonSmoothingOff ();
   void PolygonSmoothingOn ();
   void RemoveRenderer (vtkRenderer *);
   virtual void Render ();
   void SetAAFrames (int );
   void SetAbortCheckMethod (void (*func)(void *) , void *arg);
   void SetAbortRender (int );
   void SetBorders (int );
   void SetDesiredUpdateRate (float );
   void SetFDFrames (int );
   virtual void SetFullScreen (int );
   void SetInAbortCheck (int );
   void SetInteractor (vtkRenderWindowInteractor *);
   void SetLineSmoothing (int );
   void SetNumberOfLayers (int );
   virtual void SetParentInfo (char *);
   void SetPointSmoothing (int );
   void SetPolygonSmoothing (int );
   virtual void SetStereoCapableWindow (int capable);
   void SetStereoRender (int stereo);
   void SetStereoType (int );
   void SetStereoTypeToCrystalEyes ();
   void SetStereoTypeToDresden ();
   void SetStereoTypeToInterlaced ();
   void SetStereoTypeToLeft ();
   void SetStereoTypeToRedBlue ();
   void SetStereoTypeToRight ();
   void SetSubFrames (int );
   void SetSwapBuffers (int );
   virtual void SetWindowInfo (char *);
   virtual void ShowCursor ();
   virtual void Start ();
   void StereoCapableWindowOff ();
   void StereoCapableWindowOn ();
   virtual void StereoMidpoint ();
   virtual void StereoRenderComplete ();
   void StereoRenderOff ();
   void StereoRenderOn ();
   virtual void StereoUpdate ();
   void SwapBuffersOff ();
   void SwapBuffersOn ();
   void UnRegister (vtkObject *o);
   virtual void WindowRemap ();


B<vtkRenderWindow Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void *GetGenericContext ();
      Can't Handle 'void *' return type without a hint

   virtual void *GetGenericDisplayId ();
      Can't Handle 'void *' return type without a hint

   virtual void *GetGenericDrawable ();
      Can't Handle 'void *' return type without a hint

   virtual void *GetGenericParentId ();
      Can't Handle 'void *' return type without a hint

   virtual void *GetGenericWindowId ();
      Can't Handle 'void *' return type without a hint

   virtual unsigned char *GetRGBACharPixelData (int , int , int , int , int );
      Can't Handle 'unsigned char *' return type without a hint

   virtual float *GetRGBAPixelData (int , int , int , int , int );
      Can't Handle 'float *' return type without a hint

   virtual float *GetZbufferData (int , int , int , int );
      Can't Handle 'float *' return type without a hint

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetAbortCheckMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   virtual void SetDisplayId (void *);
      Don't know the size of pointer arg number 1

   virtual void SetParentId (void *);
      Don't know the size of pointer arg number 1

   virtual void SetPixelData (int , int , int , int , unsigned char *, int );
      Don't know the size of pointer arg number 5

   virtual void SetRGBACharPixelData (int , int , int , int , unsigned char *, int , int blend);
      Don't know the size of pointer arg number 5

   virtual void SetRGBAPixelData (int , int , int , int , float *, int , int blend);
      Don't know the size of pointer arg number 5

   virtual void SetWindowId (void *);
      Don't know the size of pointer arg number 1

   virtual void SetZbufferData (int , int , int , int , float *);
      Don't know the size of pointer arg number 5


=cut

package Graphics::VTK::RenderWindowCollection;


@Graphics::VTK::RenderWindowCollection::ISA = qw( Graphics::VTK::Collection );

=head1 Graphics::VTK::RenderWindowCollection

=over 1

=item *

Inherits from Collection

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddItem (vtkRenderWindow *a);
   const char *GetClassName ();
   vtkRenderWindow *GetNextItem ();
   vtkRenderWindowCollection *New ();

=cut

package Graphics::VTK::RenderWindowInteractor;


@Graphics::VTK::RenderWindowInteractor::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::RenderWindowInteractor

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual vtkAbstractPropPicker *CreateDefaultPicker ();
   virtual int CreateTimer (int );
   virtual int DestroyTimer ();
   virtual void Disable ();
   virtual void Enable ();
   virtual void EndPickCallback ();
   virtual void ExitCallback ();
   void FlyTo (vtkRenderer *ren, float x, float y, float z);
   const char *GetClassName ();
   float GetDesiredUpdateRate ();
   float GetDesiredUpdateRateMaxValue ();
   float GetDesiredUpdateRateMinValue ();
   float GetDolly ();
   int GetEnabled ();
   int  *GetEventPosition ();
      (Returns a 2-element Perl list)
   int GetInitialized ();
   vtkInteractorStyle *GetInteractorStyle ();
   int GetLightFollowCamera ();
   int GetNumberOfFlyFrames ();
   int GetNumberOfFlyFramesMaxValue ();
   int GetNumberOfFlyFramesMinValue ();
   vtkAbstractPicker *GetPicker ();
   vtkRenderWindow *GetRenderWindow ();
   int  *GetSize ();
      (Returns a 2-element Perl list)
   float GetStillUpdateRate ();
   float GetStillUpdateRateMaxValue ();
   float GetStillUpdateRateMinValue ();
   void HideCursor ();
   virtual void Initialize ();
   void LightFollowCameraOff ();
   void LightFollowCameraOn ();
   vtkRenderWindowInteractor *New ();
   void ReInitialize ();
   void Render ();
   void SetDesiredUpdateRate (float );
   void SetDolly (float );
   void SetEndPickMethod (void (*func)(void *) , void *arg);
   void SetEventPosition (int , int );
   void SetExitMethod (void (*func)(void *) , void *arg);
   virtual void SetInteractorStyle (vtkInteractorStyle *);
   void SetLightFollowCamera (int );
   void SetNumberOfFlyFrames (int );
   void SetPicker (vtkAbstractPicker *);
   void SetRenderWindow (vtkRenderWindow *aren);
   void SetSize (int , int );
   void SetStartPickMethod (void (*func)(void *) , void *arg);
   void SetStillUpdateRate (float );
   void SetUserMethod (void (*func)(void *) , void *arg);
   void ShowCursor ();
   virtual void Start ();
   virtual void StartPickCallback ();
   virtual void TerminateApp (void );
   void UnRegister (vtkObject *o);
   virtual void UpdateSize (int x, int y);
   virtual void UserCallback ();


B<vtkRenderWindowInteractor Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void FlyTo (vtkRenderer *ren, float *x);
      Don't know the size of pointer arg number 2

   virtual void GetMousePosition (int *x, int *y);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetEndPickMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void SetEventPosition (int  a[2]);
      Method is redundant. Same as SetEventPosition( int, int)

   void SetExitMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void SetSize (int  a[2]);
      Method is redundant. Same as SetSize( int, int)

   void SetStartPickMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void SetUserMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.


=cut

package Graphics::VTK::Renderer;


@Graphics::VTK::Renderer::ISA = qw( Graphics::VTK::Viewport );

=head1 Graphics::VTK::Renderer

=over 1

=item *

Inherits from Viewport

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddActor (vtkProp *p);
   void AddCuller (vtkCuller *);
   void AddLight (vtkLight *);
   void AddVolume (vtkProp *p);
   void BackingStoreOff ();
   void BackingStoreOn ();
   virtual void Clear ();
   void CreateLight (void );
   virtual void DeviceRender () = 0;
   vtkCamera *GetActiveCamera ();
   vtkActorCollection *GetActors ();
   virtual float GetAllocatedRenderTime ();
   float  *GetAmbient ();
      (Returns a 3-element Perl list)
   int GetBackingStore ();
   const char *GetClassName ();
   vtkCullerCollection *GetCullers ();
   int GetInteractive ();
   float GetLastRenderTimeInSeconds ();
   int GetLayer ();
   int GetLightFollowCamera ();
   vtkLightCollection *GetLights ();
   unsigned long GetMTime ();
   int GetNumberOfPropsRenderedAsGeometry ();
   vtkRayCaster *GetRayCaster ();
   vtkRenderWindow *GetRenderWindow ();
   virtual float GetTimeFactor ();
   int GetTwoSidedLighting ();
   virtual vtkWindow *GetVTKWindow ();
   vtkVolumeCollection *GetVolumes ();
   float GetZ (int x, int y);
   void InteractiveOff ();
   void InteractiveOn ();
   void LightFollowCameraOff ();
   void LightFollowCameraOn ();
   virtual vtkCamera *MakeCamera ();
   virtual vtkLight *MakeLight ();
   vtkRenderer *New ();
   vtkAssemblyPath *PickProp (float selectionX, float selectionY);
   void RemoveActor (vtkProp *p);
   void RemoveCuller (vtkCuller *);
   void RemoveLight (vtkLight *);
   void RemoveVolume (vtkProp *p);
   virtual void Render ();
   void RenderOverlay ();
   void ResetCamera (float xmin, float xmax, float ymin, float ymax, float zmin, float zmax);
   void ResetCamera ();
   void ResetCameraClippingRange (float xmin, float xmax, float ymin, float ymax, float zmin, float zmax);
   void ResetCameraClippingRange ();
   void SetActiveCamera (vtkCamera *);
   void SetAllocatedRenderTime (float );
   void SetAmbient (float , float , float );
   void SetBackingStore (int );
   void SetInteractive (int );
   void SetLayer (int );
   void SetLightFollowCamera (int );
   void SetRenderWindow (vtkRenderWindow *);
   void SetTwoSidedLighting (int );
   int Transparent ();
   void TwoSidedLightingOff ();
   void TwoSidedLightingOn ();
   virtual void ViewToWorld (float &wx, float &wy, float &wz);
   void ViewToWorld ();
   int VisibleActorCount ();
   int VisibleVolumeCount ();
   virtual void WorldToView (float &wx, float &wy, float &wz);
   void WorldToView ();


B<vtkRenderer Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeVisiblePropBounds (float bounds[6]);
      Can't handle methods with single array args (like a[3]) yet.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ResetCameraClippingRange (float bounds[6]);
      Method is redundant. Same as ResetCameraClippingRange( float, float, float, float, float, float)

   void ResetCamera (float bounds[6]);
      Method is redundant. Same as ResetCamera( float, float, float, float, float, float)

   void SetAmbient (float  a[3]);
      Method is redundant. Same as SetAmbient( float, float, float)


=cut

package Graphics::VTK::RendererCollection;


@Graphics::VTK::RendererCollection::ISA = qw( Graphics::VTK::Collection );

=head1 Graphics::VTK::RendererCollection

=over 1

=item *

Inherits from Collection

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddItem (vtkRenderer *a);
   const char *GetClassName ();
   vtkRenderer *GetNextItem ();
   vtkRendererCollection *New ();
   void Render ();
   void RenderOverlay ();

=cut

package Graphics::VTK::RendererSource;


@Graphics::VTK::RendererSource::ISA = qw( Graphics::VTK::StructuredPointsSource );

=head1 Graphics::VTK::RendererSource

=over 1

=item *

Inherits from StructuredPointsSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void DepthValuesOff ();
   void DepthValuesOn ();
   const char *GetClassName ();
   int GetDepthValues ();
   vtkRenderer *GetInput ();
   unsigned long GetMTime ();
   int GetRenderFlag ();
   int GetWholeWindow ();
   vtkRendererSource *New ();
   void RenderFlagOff ();
   void RenderFlagOn ();
   void SetDepthValues (int );
   void SetInput (vtkRenderer *);
   void SetRenderFlag (int );
   void SetWholeWindow (int );
   void WholeWindowOff ();
   void WholeWindowOn ();


B<vtkRendererSource Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ScalarBarActor;


@Graphics::VTK::ScalarBarActor::ISA = qw( Graphics::VTK::Actor2D );

=head1 Graphics::VTK::ScalarBarActor

=over 1

=item *

Inherits from Actor2D

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void BoldOff ();
   void BoldOn ();
   int GetBold ();
   const char *GetClassName ();
   int GetFontFamily ();
   int GetItalic ();
   char *GetLabelFormat ();
   vtkScalarsToColors *GetLookupTable ();
   int GetMaximumNumberOfColors ();
   int GetMaximumNumberOfColorsMaxValue ();
   int GetMaximumNumberOfColorsMinValue ();
   int GetNumberOfLabels ();
   int GetNumberOfLabelsMaxValue ();
   int GetNumberOfLabelsMinValue ();
   int GetOrientation ();
   int GetOrientationMaxValue ();
   int GetOrientationMinValue ();
   int GetShadow ();
   char *GetTitle ();
   void ItalicOff ();
   void ItalicOn ();
   vtkScalarBarActor *New ();
   virtual void ReleaseGraphicsResources (vtkWindow *);
   int RenderOpaqueGeometry (vtkViewport *viewport);
   int RenderOverlay (vtkViewport *viewport);
   int RenderTranslucentGeometry (vtkViewport *);
   void SetBold (int );
   void SetFontFamily (int );
   void SetFontFamilyToArial ();
   void SetFontFamilyToCourier ();
   void SetFontFamilyToTimes ();
   void SetItalic (int );
   void SetLabelFormat (char *);
   void SetLookupTable (vtkScalarsToColors *);
   void SetMaximumNumberOfColors (int );
   void SetNumberOfLabels (int );
   void SetOrientation (int );
   void SetOrientationToHorizontal ();
   void SetOrientationToVertical ();
   void SetShadow (int );
   void SetTitle (char *);
   void ShadowOff ();
   void ShadowOn ();
   void ShallowCopy (vtkProp *prop);


B<vtkScalarBarActor Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void AllocateAndSizeLabels (int *labelSize, int *size, vtkViewport *viewport, float *range);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SizeTitle (int *titleSize, int *size, vtkViewport *viewport);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::ScaledTextActor;


@Graphics::VTK::ScaledTextActor::ISA = qw( Graphics::VTK::Actor2D );

=head1 Graphics::VTK::ScaledTextActor

=over 1

=item *

Inherits from Actor2D

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetMaximumLineHeight ();
   int  *GetMinimumSize ();
      (Returns a 2-element Perl list)
   vtkScaledTextActor *New ();
   void SetMapper (vtkTextMapper *mapper);
   void SetMaximumLineHeight (float );
   void SetMinimumSize (int , int );
   void ShallowCopy (vtkProp *prop);


B<vtkScaledTextActor Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetMinimumSize (int  a[2]);
      Method is redundant. Same as SetMinimumSize( int, int)


=cut

package Graphics::VTK::SelectVisiblePoints;


@Graphics::VTK::SelectVisiblePoints::ISA = qw( Graphics::VTK::DataSetToPolyDataFilter );

=head1 Graphics::VTK::SelectVisiblePoints

=over 1

=item *

Inherits from DataSetToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   unsigned long GetMTime ();
   vtkRenderer *GetRenderer ();
   int GetSelectInvisible ();
   int  *GetSelection ();
      (Returns a 4-element Perl list)
   int GetSelectionWindow ();
   float GetTolerance ();
   float GetToleranceMaxValue ();
   float GetToleranceMinValue ();
   vtkSelectVisiblePoints *New ();
   void SelectInvisibleOff ();
   void SelectInvisibleOn ();
   void SelectionWindowOff ();
   void SelectionWindowOn ();
   void SetRenderer (vtkRenderer *ren);
   void SetSelectInvisible (int );
   void SetSelection (int , int , int , int );
   void SetSelectionWindow (int );
   void SetTolerance (float );


B<vtkSelectVisiblePoints Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetSelection (int  a[4]);
      Method is redundant. Same as SetSelection( int, int, int, int)


=cut

package Graphics::VTK::TextMapper;


@Graphics::VTK::TextMapper::ISA = qw( Graphics::VTK::Mapper2D );

=head1 Graphics::VTK::TextMapper

=over 1

=item *

Inherits from Mapper2D

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void BoldOff ();
   void BoldOn ();
   int GetBold ();
   const char *GetClassName ();
   int GetFontFamily ();
   int GetFontSize ();
   int GetHeight (vtkViewport *);
   char *GetInput ();
   int GetItalic ();
   int GetJustification ();
   int GetJustificationMaxValue ();
   int GetJustificationMinValue ();
   float GetLineOffset ();
   float GetLineSpacing ();
   int GetNumberOfLines (const char *input);
   int GetNumberOfLines ();
   int GetShadow ();
   int GetVerticalJustification ();
   int GetVerticalJustificationMaxValue ();
   int GetVerticalJustificationMinValue ();
   int GetWidth (vtkViewport *);
   void ItalicOff ();
   void ItalicOn ();
   vtkTextMapper *New ();
   void SetBold (int val);
   void SetFontFamily (int val);
   void SetFontFamilyToArial ();
   void SetFontFamilyToCourier ();
   void SetFontFamilyToTimes ();
   virtual void SetFontSize (int size);
   void SetInput (const char *inputString);
   void SetItalic (int val);
   void SetJustification (int );
   void SetJustificationToCentered ();
   void SetJustificationToLeft ();
   void SetJustificationToRight ();
   void SetLineOffset (float );
   void SetLineSpacing (float );
   void SetShadow (int val);
   void SetVerticalJustification (int );
   void SetVerticalJustificationToBottom ();
   void SetVerticalJustificationToCentered ();
   void SetVerticalJustificationToTop ();
   void ShadowOff ();
   void ShadowOn ();
   void ShallowCopy (vtkTextMapper *tm);


B<vtkTextMapper Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void GetMultiLineSize (vtkViewport *viewport, int size[2]);
      Don't know the size of pointer arg number 2

   virtual void GetSize (vtkViewport *, int size[2]);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::Texture;


@Graphics::VTK::Texture::ISA = qw( Graphics::VTK::ProcessObject );

=head1 Graphics::VTK::Texture

=over 1

=item *

Inherits from ProcessObject

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageData *GetInput ();
   int GetInterpolate ();
   vtkLookupTable *GetLookupTable ();
   int GetMapColorScalarsThroughLookupTable ();
   vtkUnsignedCharArray *GetMappedScalars ();
   int GetQuality ();
   int GetRepeat ();
   void InterpolateOff ();
   void InterpolateOn ();
   virtual void Load (vtkRenderer *);
   void MapColorScalarsThroughLookupTableOff ();
   void MapColorScalarsThroughLookupTableOn ();
   vtkTexture *New ();
   virtual void ReleaseGraphicsResources (vtkWindow *);
   virtual void Render (vtkRenderer *ren);
   void RepeatOff ();
   void RepeatOn ();
   void SetInput (vtkImageData *input);
   void SetInterpolate (int );
   void SetLookupTable (vtkLookupTable *);
   void SetMapColorScalarsThroughLookupTable (int );
   void SetQuality (int );
   void SetQualityTo16Bit ();
   void SetQualityTo32Bit ();
   void SetQualityToDefault ();
   void SetRepeat (int );


B<vtkTexture Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   unsigned char *MapScalarsToColors (vtkDataArray *scalars);
      Can't Handle 'unsigned char *' return type without a hint

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::VRMLExporter;


@Graphics::VTK::VRMLExporter::ISA = qw( Graphics::VTK::Exporter );

=head1 Graphics::VTK::VRMLExporter

=over 1

=item *

Inherits from Exporter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   char *GetFileName ();
   float GetSpeed ();
   vtkVRMLExporter *New ();
   void SetFileName (char *);
   void SetSpeed (float );


B<vtkVRMLExporter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetFilePointer (FILE *);
      Don't know the size of pointer arg number 1

   void WriteALight (vtkLight *aLight, FILE *fp);
      Don't know the size of pointer arg number 2

   void WriteAnActor (vtkActor *anActor, FILE *fp);
      Don't know the size of pointer arg number 2

   void WritePointData (vtkPoints *points, vtkDataArray *normals, vtkDataArray *tcoords, vtkUnsignedCharArray *colors, FILE *fp);
      Don't know the size of pointer arg number 5


=cut

package Graphics::VTK::Volume;


@Graphics::VTK::Volume::ISA = qw( Graphics::VTK::Prop3D );

=head1 Graphics::VTK::Volume

=over 1

=item *

Inherits from Prop3D

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   float *GetBounds ();
      (Returns a 6-element Perl list)
   const char *GetClassName ();
   unsigned long GetMTime ();
   vtkVolumeMapper *GetMapper ();
   float GetMaxXBound ();
   float GetMaxYBound ();
   float GetMaxZBound ();
   float GetMinXBound ();
   float GetMinYBound ();
   float GetMinZBound ();
   vtkVolumeProperty *GetProperty ();
   unsigned long GetRedrawMTime ();
   void GetVolumes (vtkPropCollection *vc);
   vtkVolume *New ();
   void SetMapper (vtkVolumeMapper *mapper);
   void SetProperty (vtkVolumeProperty *property);
   void ShallowCopy (vtkProp *prop);
   void Update ();


B<vtkVolume Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void GetBounds (float bounds[6]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::VolumeCollection;


@Graphics::VTK::VolumeCollection::ISA = qw( Graphics::VTK::PropCollection );

=head1 Graphics::VTK::VolumeCollection

=over 1

=item *

Inherits from PropCollection

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddItem (vtkVolume *a);
   const char *GetClassName ();
   vtkVolume *GetNextItem ();
   vtkVolume *GetNextVolume ();
   vtkVolumeCollection *New ();

=cut

package Graphics::VTK::VolumeMapper;


@Graphics::VTK::VolumeMapper::ISA = qw( Graphics::VTK::AbstractMapper3D );

=head1 Graphics::VTK::VolumeMapper

=over 1

=item *

Inherits from AbstractMapper3D

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CroppingOff ();
   void CroppingOn ();
   virtual float *GetBounds ();
      (Returns a 6-element Perl list)
   const char *GetClassName ();
   int GetCropping ();
   int GetCroppingRegionFlags ();
   int GetCroppingRegionFlagsMaxValue ();
   int GetCroppingRegionFlagsMinValue ();
   float  *GetCroppingRegionPlanes ();
      (Returns a 6-element Perl list)
   vtkImageData *GetInput ();
   virtual vtkImageData *GetRGBTextureInput ();
   float  *GetVoxelCroppingRegionPlanes ();
      (Returns a 6-element Perl list)
   void SetCropping (int );
   void SetCroppingRegionFlags (int );
   void SetCroppingRegionFlagsToCross ();
   void SetCroppingRegionFlagsToFence ();
   void SetCroppingRegionFlagsToInvertedCross ();
   void SetCroppingRegionFlagsToInvertedFence ();
   void SetCroppingRegionFlagsToSubVolume ();
   void SetCroppingRegionPlanes (float , float , float , float , float , float );
   void SetInput (vtkImageData *);
   void SetRGBTextureInput (vtkImageData *rgbTexture);
   virtual void Update ();


B<vtkVolumeMapper Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void GetBounds (float bounds[6]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void PrintSelf (ostream &os, vtkIndent index);
      I/O Streams not Supported yet

   void SetCroppingRegionPlanes (float  a[6]);
      Method is redundant. Same as SetCroppingRegionPlanes( float, float, float, float, float, float)


=cut

package Graphics::VTK::VolumeProMapper;


@Graphics::VTK::VolumeProMapper::ISA = qw( Graphics::VTK::VolumeMapper );

=head1 Graphics::VTK::VolumeProMapper

=over 1

=item *

Inherits from VolumeMapper

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CursorOff ();
   void CursorOn ();
   void CutPlaneOff ();
   void CutPlaneOn ();
   virtual int GetAvailableBoardMemory ();
   int GetBlendMode ();
   const char *GetBlendModeAsString (void );
   int GetBlendModeMaxValue ();
   int GetBlendModeMinValue ();
   const char *GetClassName ();
   int GetCursor ();
   int GetCursorMaxValue ();
   int GetCursorMinValue ();
   double  *GetCursorPosition ();
      (Returns a 3-element Perl list)
   int GetCursorType ();
   const char *GetCursorTypeAsString (void );
   int GetCursorTypeMaxValue ();
   int GetCursorTypeMinValue ();
   double  *GetCursorXAxisColor ();
      (Returns a 3-element Perl list)
   double  *GetCursorYAxisColor ();
      (Returns a 3-element Perl list)
   double  *GetCursorZAxisColor ();
      (Returns a 3-element Perl list)
   int GetCutPlane ();
   double  *GetCutPlaneEquation ();
      (Returns a 4-element Perl list)
   int GetCutPlaneFallOffDistance ();
   int GetCutPlaneFallOffDistanceMaxValue ();
   int GetCutPlaneFallOffDistanceMinValue ();
   int GetCutPlaneMaxValue ();
   int GetCutPlaneMinValue ();
   double GetCutPlaneThickness ();
   double GetCutPlaneThicknessMaxValue ();
   double GetCutPlaneThicknessMinValue ();
   int GetGradientDiffuseModulation ();
   int GetGradientDiffuseModulationMaxValue ();
   int GetGradientDiffuseModulationMinValue ();
   int GetGradientOpacityModulation ();
   int GetGradientOpacityModulationMaxValue ();
   int GetGradientOpacityModulationMinValue ();
   int GetGradientSpecularModulation ();
   int GetGradientSpecularModulationMaxValue ();
   int GetGradientSpecularModulationMinValue ();
   int GetIntermixIntersectingGeometry ();
   int GetIntermixIntersectingGeometryMaxValue ();
   int GetIntermixIntersectingGeometryMinValue ();
   int GetMajorBoardVersion ();
   int GetMinorBoardVersion ();
   int GetNoHardware ();
   int GetNumberOfBoards ();
   int  *GetSubVolume ();
      (Returns a 6-element Perl list)
   int GetSuperSampling ();
   double  *GetSuperSamplingFactor ();
      (Returns a 3-element Perl list)
   int GetSuperSamplingMaxValue ();
   int GetSuperSamplingMinValue ();
   int GetWrongVLIVersion ();
   void GradientDiffuseModulationOff ();
   void GradientDiffuseModulationOn ();
   void GradientOpacityModulationOff ();
   void GradientOpacityModulationOn ();
   void GradientSpecularModulationOff ();
   void GradientSpecularModulationOn ();
   void IntermixIntersectingGeometryOff ();
   void IntermixIntersectingGeometryOn ();
   vtkVolumeProMapper *New ();
   virtual void Render (vtkRenderer *, vtkVolume *);
   void SetBlendMode (int );
   void SetBlendModeToComposite ();
   void SetBlendModeToMaximumIntensity ();
   void SetBlendModeToMinimumIntensity ();
   void SetCursor (int );
   void SetCursorPosition (double , double , double );
   void SetCursorType (int );
   void SetCursorTypeToCrossHair ();
   void SetCursorTypeToPlane ();
   void SetCursorXAxisColor (double , double , double );
   void SetCursorYAxisColor (double , double , double );
   void SetCursorZAxisColor (double , double , double );
   void SetCutPlane (int );
   void SetCutPlaneEquation (double , double , double , double );
   void SetCutPlaneFallOffDistance (int );
   void SetCutPlaneThickness (double );
   void SetGradientDiffuseModulation (int );
   void SetGradientOpacityModulation (int );
   void SetGradientSpecularModulation (int );
   void SetIntermixIntersectingGeometry (int );
   void SetSubVolume (int , int , int , int , int , int );
   void SetSuperSampling (int );
   void SetSuperSamplingFactor (double x, double y, double z);
   void SuperSamplingOff ();
   void SuperSamplingOn ();


B<vtkVolumeProMapper Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void GetLockSizesForBoardMemory (unsigned int , unsigned int *, unsigned int *, unsigned int *);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent index);
      I/O Streams not Supported yet

   void SetCursorPosition (double  a[3]);
      Method is redundant. Same as SetCursorPosition( double, double, double)

   void SetCursorXAxisColor (double  a[3]);
      Method is redundant. Same as SetCursorXAxisColor( double, double, double)

   void SetCursorYAxisColor (double  a[3]);
      Method is redundant. Same as SetCursorYAxisColor( double, double, double)

   void SetCursorZAxisColor (double  a[3]);
      Method is redundant. Same as SetCursorZAxisColor( double, double, double)

   void SetCutPlaneEquation (double  a[4]);
      Method is redundant. Same as SetCutPlaneEquation( double, double, double, double)

   void SetSubVolume (int  a[6]);
      Method is redundant. Same as SetSubVolume( int, int, int, int, int, int)

   void SetSuperSamplingFactor (double f[3]);
      Method is redundant. Same as SetSuperSamplingFactor( double, double, double)


=cut

package Graphics::VTK::VolumeProperty;


@Graphics::VTK::VolumeProperty::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::VolumeProperty

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   float GetAmbient ();
   float GetAmbientMaxValue ();
   float GetAmbientMinValue ();
   const char *GetClassName ();
   int GetColorChannels ();
   float GetDiffuse ();
   float GetDiffuseMaxValue ();
   float GetDiffuseMinValue ();
   vtkPiecewiseFunction *GetGradientOpacity ();
   vtkPiecewiseFunction *GetGrayTransferFunction ();
   int GetInterpolationType ();
   const char *GetInterpolationTypeAsString (void );
   int GetInterpolationTypeMaxValue ();
   int GetInterpolationTypeMinValue ();
   unsigned long GetMTime ();
   float GetRGBTextureCoefficient ();
   float GetRGBTextureCoefficientMaxValue ();
   float GetRGBTextureCoefficientMinValue ();
   vtkColorTransferFunction *GetRGBTransferFunction ();
   vtkPiecewiseFunction *GetScalarOpacity ();
   int GetShade ();
   float GetSpecular ();
   float GetSpecularMaxValue ();
   float GetSpecularMinValue ();
   float GetSpecularPower ();
   float GetSpecularPowerMaxValue ();
   float GetSpecularPowerMinValue ();
   vtkVolumeProperty *New ();
   void SetAmbient (float );
   void SetColor (vtkPiecewiseFunction *function);
   void SetColor (vtkColorTransferFunction *function);
   void SetDiffuse (float );
   void SetGradientOpacity (vtkPiecewiseFunction *function);
   void SetInterpolationType (int );
   void SetInterpolationTypeToLinear ();
   void SetInterpolationTypeToNearest ();
   void SetRGBTextureCoefficient (float );
   void SetScalarOpacity (vtkPiecewiseFunction *function);
   void SetShade (int );
   void SetSpecular (float );
   void SetSpecularPower (float );
   void ShadeOff ();
   void ShadeOn ();


B<vtkVolumeProperty Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::VolumeRayCastCompositeFunction;


@Graphics::VTK::VolumeRayCastCompositeFunction::ISA = qw( Graphics::VTK::VolumeRayCastFunction );

=head1 Graphics::VTK::VolumeRayCastCompositeFunction

=over 1

=item *

Inherits from VolumeRayCastFunction

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetCompositeMethod ();
   const char *GetCompositeMethodAsString (void );
   int GetCompositeMethodMaxValue ();
   int GetCompositeMethodMinValue ();
   vtkVolumeRayCastCompositeFunction *New ();
   void SetCompositeMethod (int );
   void SetCompositeMethodToClassifyFirst ();
   void SetCompositeMethodToInterpolateFirst ();


B<vtkVolumeRayCastCompositeFunction Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent index);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::VolumeRayCastFunction;


@Graphics::VTK::VolumeRayCastFunction::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::VolumeRayCastFunction

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   virtual float GetZeroOpacityThreshold (vtkVolume *vol) = 0;

=cut

package Graphics::VTK::VolumeRayCastIsosurfaceFunction;


@Graphics::VTK::VolumeRayCastIsosurfaceFunction::ISA = qw( Graphics::VTK::VolumeRayCastFunction );

=head1 Graphics::VTK::VolumeRayCastIsosurfaceFunction

=over 1

=item *

Inherits from VolumeRayCastFunction

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetIsoValue ();
   float GetZeroOpacityThreshold (vtkVolume *vol);
   vtkVolumeRayCastIsosurfaceFunction *New ();
   void SetIsoValue (float );


B<vtkVolumeRayCastIsosurfaceFunction Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent index);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::VolumeRayCastMIPFunction;


@Graphics::VTK::VolumeRayCastMIPFunction::ISA = qw( Graphics::VTK::VolumeRayCastFunction );

=head1 Graphics::VTK::VolumeRayCastMIPFunction

=over 1

=item *

Inherits from VolumeRayCastFunction

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetMaximizeMethod ();
   const char *GetMaximizeMethodAsString (void );
   int GetMaximizeMethodMaxValue ();
   int GetMaximizeMethodMinValue ();
   float GetZeroOpacityThreshold (vtkVolume *vol);
   vtkVolumeRayCastMIPFunction *New ();
   void SetMaximizeMethod (int );
   void SetMaximizeMethodToOpacity ();
   void SetMaximizeMethodToScalarValue ();


B<vtkVolumeRayCastMIPFunction Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent index);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::VolumeRayCastMapper;


@Graphics::VTK::VolumeRayCastMapper::ISA = qw( Graphics::VTK::VolumeMapper );

=head1 Graphics::VTK::VolumeRayCastMapper

=over 1

=item *

Inherits from VolumeMapper

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AutoAdjustSampleDistancesOff ();
   void AutoAdjustSampleDistancesOn ();
   int GetAutoAdjustSampleDistances ();
   int GetAutoAdjustSampleDistancesMaxValue ();
   int GetAutoAdjustSampleDistancesMinValue ();
   const char *GetClassName ();
   vtkEncodedGradientEstimator *GetGradientEstimator ();
   vtkEncodedGradientShader *GetGradientShader ();
   float GetImageSampleDistance ();
   float GetImageSampleDistanceMaxValue ();
   float GetImageSampleDistanceMinValue ();
   int GetIntermixIntersectingGeometry ();
   int GetIntermixIntersectingGeometryMaxValue ();
   int GetIntermixIntersectingGeometryMinValue ();
   float GetMaximumImageSampleDistance ();
   float GetMaximumImageSampleDistanceMaxValue ();
   float GetMaximumImageSampleDistanceMinValue ();
   float GetMinimumImageSampleDistance ();
   float GetMinimumImageSampleDistanceMaxValue ();
   float GetMinimumImageSampleDistanceMinValue ();
   int GetNumberOfThreads ();
   float GetSampleDistance ();
   vtkVolumeRayCastFunction *GetVolumeRayCastFunction ();
   void IntermixIntersectingGeometryOff ();
   void IntermixIntersectingGeometryOn ();
   vtkVolumeRayCastMapper *New ();
   void SetAutoAdjustSampleDistances (int );
   void SetGradientEstimator (vtkEncodedGradientEstimator *gradest);
   void SetImageSampleDistance (float );
   void SetIntermixIntersectingGeometry (int );
   void SetMaximumImageSampleDistance (float );
   void SetMinimumImageSampleDistance (float );
   void SetNumberOfThreads (int num);
   void SetSampleDistance (float );
   void SetVolumeRayCastFunction (vtkVolumeRayCastFunction *);


B<vtkVolumeRayCastMapper Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int ClipRayAgainstClippingPlanes (VTKVRCDynamicInfo *dynamicInfo, VTKVRCStaticInfo *staticInfo);
      Don't know the size of pointer arg number 1

   int ClipRayAgainstVolume (VTKVRCDynamicInfo *dynamicInfo, float bounds[6]);
      Don't know the size of pointer arg number 1

   void InitializeClippingPlanes (VTKVRCStaticInfo *staticInfo, vtkPlaneCollection *planes);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent index);
      I/O Streams not Supported yet

   VTK_THREAD_RETURN_TYPE VolumeRayCastMapper_CastRays (void *arg);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::VolumeTextureMapper;


@Graphics::VTK::VolumeTextureMapper::ISA = qw( Graphics::VTK::VolumeMapper );

=head1 Graphics::VTK::VolumeTextureMapper

=over 1

=item *

Inherits from VolumeMapper

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkEncodedGradientEstimator *GetGradientEstimator ();
   vtkEncodedGradientShader *GetGradientShader ();
   void SetGradientEstimator (vtkEncodedGradientEstimator *gradest);
   virtual void Update ();


B<vtkVolumeTextureMapper Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent index);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::VolumeTextureMapper2D;


@Graphics::VTK::VolumeTextureMapper2D::ISA = qw( Graphics::VTK::VolumeTextureMapper );

=head1 Graphics::VTK::VolumeTextureMapper2D

=over 1

=item *

Inherits from VolumeTextureMapper

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetMaximumNumberOfPlanes ();
   int GetMaximumStorageSize ();
   int  *GetTargetTextureSize ();
      (Returns a 2-element Perl list)
   vtkVolumeTextureMapper2D *New ();
   void SetMaximumNumberOfPlanes (int );
   void SetMaximumStorageSize (int );
   void SetTargetTextureSize (int , int );


B<vtkVolumeTextureMapper2D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeAxisTextureSize (int axis, int *size);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent index);
      I/O Streams not Supported yet

   void SetTargetTextureSize (int  a[2]);
      Method is redundant. Same as SetTargetTextureSize( int, int)


=cut

package Graphics::VTK::WorldPointPicker;


@Graphics::VTK::WorldPointPicker::ISA = qw( Graphics::VTK::AbstractPicker );

=head1 Graphics::VTK::WorldPointPicker

=over 1

=item *

Inherits from AbstractPicker

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkWorldPointPicker *New ();
   int Pick (float selectionX, float selectionY, float selectionZ, vtkRenderer *renderer);


B<vtkWorldPointPicker Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int Pick (float selectionPt[3], vtkRenderer *renderer);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::MesaActor;


@Graphics::VTK::MesaActor::ISA = qw( Graphics::VTK::Actor );

=head1 Graphics::VTK::MesaActor

=over 1

=item *

Inherits from Actor

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkProperty *MakeProperty ();
   vtkMesaActor *New ();
   void Render (vtkRenderer *ren, vtkMapper *mapper);

=cut

package Graphics::VTK::MesaCamera;


@Graphics::VTK::MesaCamera::ISA = qw( Graphics::VTK::Camera );

=head1 Graphics::VTK::MesaCamera

=over 1

=item *

Inherits from Camera

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkMesaCamera *New ();
   void Render (vtkRenderer *ren);
   void UpdateViewport (vtkRenderer *ren);

=cut

package Graphics::VTK::MesaImageActor;


@Graphics::VTK::MesaImageActor::ISA = qw( Graphics::VTK::ImageActor );

=head1 Graphics::VTK::MesaImageActor

=over 1

=item *

Inherits from ImageActor

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   void Load (vtkRenderer *ren);
   vtkMesaImageActor *New ();
   void ReleaseGraphicsResources (vtkWindow *);


B<vtkMesaImageActor Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   unsigned char *MakeDataSuitable (int &xsize, int &ysize, int &release);
      Can't Handle 'unsigned char *' return type without a hint


=cut

package Graphics::VTK::MesaImageMapper;


@Graphics::VTK::MesaImageMapper::ISA = qw( Graphics::VTK::ImageMapper );

=head1 Graphics::VTK::MesaImageMapper

=over 1

=item *

Inherits from ImageMapper

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkMesaImageMapper *New ();
   void RenderData (vtkViewport *viewport, vtkImageData *data, vtkActor2D *actor);
   void RenderOpaqueGeometry (vtkViewport *viewport, vtkActor2D *actor);

=cut

package Graphics::VTK::MesaImageWindow;


@Graphics::VTK::MesaImageWindow::ISA = qw( Graphics::VTK::XImageWindow );

=head1 Graphics::VTK::MesaImageWindow

=over 1

=item *

Inherits from XImageWindow

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual void EraseWindow ();
   void Frame ();
   const char *GetClassName ();
   virtual int GetDesiredDepth ();
   void MakeCurrent ();
   virtual void MakeDefaultWindow ();
   vtkMesaImageWindow *New ();
   void Render ();
   virtual void SetOffScreenRendering (int i);
   void SwapBuffers ();


B<vtkMesaImageWindow Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual Colormap GetDesiredColormap ();
      Can't Handle ColorMap return type yet

   virtual Visual *GetDesiredVisual ();
      Can't Handle Visual return type yet

   XVisualInfo *GetDesiredVisualInfo ();
      Can't Handle 'XVisualInfo *' return type yet

   virtual void *GetGenericContext ();
      Can't Handle 'void *' return type without a hint

   virtual void *GetGenericDisplayId ();
      Can't Handle 'void *' return type without a hint

   virtual void *GetGenericDrawable ();
      Can't Handle 'void *' return type without a hint

   virtual void *GetGenericParentId ();
      Can't Handle 'void *' return type without a hint

   virtual void *GetGenericWindowId ();
      Can't Handle 'void *' return type without a hint

   virtual unsigned char *GetPixelData (int x, int y, int x2, int y2, int front);
      Can't Handle 'unsigned char *' return type without a hint

   virtual float *GetRGBAPixelData (int x, int y, int x2, int y2, int front);
      Can't Handle 'float *' return type without a hint

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   virtual void SetPixelData (int x, int y, int x2, int y2, unsigned char *, int front);
      Don't know the size of pointer arg number 5

   virtual void SetRGBAPixelData (int x, int y, int x2, int y2, float *, int front, int blend);
      Don't know the size of pointer arg number 5


=cut

package Graphics::VTK::MesaImager;


@Graphics::VTK::MesaImager::ISA = qw( Graphics::VTK::Imager );

=head1 Graphics::VTK::MesaImager

=over 1

=item *

Inherits from Imager

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Erase ();
   const char *GetClassName ();
   vtkMesaImager *New ();
   int RenderOpaqueGeometry ();

=cut

package Graphics::VTK::MesaLight;


@Graphics::VTK::MesaLight::ISA = qw( Graphics::VTK::Light );

=head1 Graphics::VTK::MesaLight

=over 1

=item *

Inherits from Light

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkMesaLight *New ();
   void Render (vtkRenderer *ren, int light_index);

=cut

package Graphics::VTK::MesaPolyDataMapper;


@Graphics::VTK::MesaPolyDataMapper::ISA = qw( Graphics::VTK::PolyDataMapper );

=head1 Graphics::VTK::MesaPolyDataMapper

=over 1

=item *

Inherits from PolyDataMapper

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual void Draw (vtkRenderer *ren, vtkActor *a);
   const char *GetClassName ();
   vtkMesaPolyDataMapper *New ();
   void ReleaseGraphicsResources (vtkWindow *);
   virtual void RenderPiece (vtkRenderer *ren, vtkActor *a);

=cut

package Graphics::VTK::MesaPolyDataMapper2D;


@Graphics::VTK::MesaPolyDataMapper2D::ISA = qw( Graphics::VTK::PolyDataMapper2D );

=head1 Graphics::VTK::MesaPolyDataMapper2D

=over 1

=item *

Inherits from PolyDataMapper2D

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkMesaPolyDataMapper2D *New ();
   void RenderOpaqueGeometry (vtkViewport *viewport, vtkActor2D *actor);

=cut

package Graphics::VTK::MesaProperty;


@Graphics::VTK::MesaProperty::ISA = qw( Graphics::VTK::Property );

=head1 Graphics::VTK::MesaProperty

=over 1

=item *

Inherits from Property

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void BackfaceRender (vtkActor *a, vtkRenderer *ren);
   const char *GetClassName ();
   vtkMesaProperty *New ();
   void Render (vtkActor *a, vtkRenderer *ren);

=cut

package Graphics::VTK::MesaRenderWindow;


@Graphics::VTK::MesaRenderWindow::ISA = qw( Graphics::VTK::RenderWindow );

=head1 Graphics::VTK::MesaRenderWindow

=over 1

=item *

Inherits from RenderWindow

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetDepthBufferSize ();
   static int GetGlobalMaximumNumberOfMultiSamples ();
   int GetMultiSamples ();
   void MakeCurrent () = 0;
   vtkMesaRenderWindow *New ();
   virtual void OpenGLInit ();
   void RegisterTextureResource (GLuint id);
   static void SetGlobalMaximumNumberOfMultiSamples (int val);
   void SetMultiSamples (int );
   virtual void StereoUpdate ();


B<vtkMesaRenderWindow Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual unsigned char *GetPixelData (int x, int y, int x2, int y2, int front);
      Can't Handle 'unsigned char *' return type without a hint

   virtual unsigned char *GetRGBACharPixelData (int x, int y, int x2, int y2, int front);
      Can't Handle 'unsigned char *' return type without a hint

   virtual float *GetRGBAPixelData (int x, int y, int x2, int y2, int front);
      Can't Handle 'float *' return type without a hint

   virtual float *GetZbufferData (int x1, int y1, int x2, int y2);
      Can't Handle 'float *' return type without a hint

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   virtual void ReleaseRGBAPixelData (float *data);
      Don't know the size of pointer arg number 1

   virtual void SetPixelData (int x, int y, int x2, int y2, unsigned char *, int front);
      Don't know the size of pointer arg number 5

   virtual void SetRGBACharPixelData (int x, int y, int x2, int y2, unsigned char *, int front, int blend);
      Don't know the size of pointer arg number 5

   virtual void SetRGBAPixelData (int x, int y, int x2, int y2, float *, int front, int blend);
      Don't know the size of pointer arg number 5

   virtual void SetZbufferData (int x1, int y1, int x2, int y2, float *buffer);
      Don't know the size of pointer arg number 5


=cut

package Graphics::VTK::MesaRenderer;


@Graphics::VTK::MesaRenderer::ISA = qw( Graphics::VTK::Renderer );

=head1 Graphics::VTK::MesaRenderer

=over 1

=item *

Inherits from Renderer

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Clear (void );
   void ClearLights (void );
   void DeviceRender (void );
   const char *GetClassName ();
   virtual vtkCamera *MakeCamera ();
   virtual vtkLight *MakeLight ();
   vtkMesaRenderer *New ();
   int UpdateLights (void );


B<vtkMesaRenderer Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::MesaTexture;


@Graphics::VTK::MesaTexture::ISA = qw( Graphics::VTK::Texture );

=head1 Graphics::VTK::MesaTexture

=over 1

=item *

Inherits from Texture

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   void Load (vtkRenderer *ren);
   vtkMesaTexture *New ();
   void ReleaseGraphicsResources (vtkWindow *);


B<vtkMesaTexture Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   unsigned char *ResampleToPowerOfTwo (int &xsize, int &ysize, unsigned char *dptr, int bpp);
      Can't Handle 'unsigned char *' return type without a hint


=cut

package Graphics::VTK::MesaVolumeRayCastMapper;


@Graphics::VTK::MesaVolumeRayCastMapper::ISA = qw( Graphics::VTK::VolumeRayCastMapper );

=head1 Graphics::VTK::MesaVolumeRayCastMapper

=over 1

=item *

Inherits from VolumeRayCastMapper

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkMesaVolumeRayCastMapper *New ();

=cut

package Graphics::VTK::MesaVolumeTextureMapper2D;


@Graphics::VTK::MesaVolumeTextureMapper2D::ISA = qw( Graphics::VTK::VolumeTextureMapper2D );

=head1 Graphics::VTK::MesaVolumeTextureMapper2D

=over 1

=item *

Inherits from VolumeTextureMapper2D

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkMesaVolumeTextureMapper2D *New ();


B<vtkMesaVolumeTextureMapper2D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent index);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::XMesaRenderWindow;


@Graphics::VTK::XMesaRenderWindow::ISA = qw( Graphics::VTK::MesaRenderWindow );

=head1 Graphics::VTK::XMesaRenderWindow

=over 1

=item *

Inherits from MesaRenderWindow

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual void Frame (void );
   const char *GetClassName ();
   virtual int GetDesiredDepth ();
   virtual int GetEventPending ();
   void HideCursor ();
   virtual void Initialize (void );
   void MakeCurrent ();
   vtkXMesaRenderWindow *New ();
   virtual void PrefFullScreen (void );
   void Render ();
   virtual void SetFullScreen (int );
   void SetNextWindowId (Window );
   void SetOffScreenRendering (int i);
   void SetParentId (Window );
   void SetParentInfo (char *info);
   void SetPosition (int , int );
   virtual void SetSize (int , int );
   virtual void SetStereoCapableWindow (int capable);
   void SetWindowId (Window );
   void SetWindowInfo (char *info);
   void SetWindowName (char *);
   void ShowCursor ();
   virtual void Start (void );
   virtual void WindowInitialize (void );
   virtual void WindowRemap (void );


B<vtkXMesaRenderWindow Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual Colormap GetDesiredColormap ();
      Can't Handle ColorMap return type yet

   virtual Visual *GetDesiredVisual ();
      Can't Handle Visual return type yet

   virtual XVisualInfo *GetDesiredVisualInfo ();
      Can't Handle 'XVisualInfo *' return type yet

   Display *GetDisplayId ();
      Can't Handle Display return type yet

   virtual void *GetGenericContext ();
      Can't Handle 'void *' return type without a hint

   virtual void *GetGenericDisplayId ();
      Can't Handle 'void *' return type without a hint

   virtual void *GetGenericDrawable ();
      Can't Handle 'void *' return type without a hint

   virtual void *GetGenericParentId ();
      Can't Handle 'void *' return type without a hint

   virtual void *GetGenericWindowId ();
      Can't Handle 'void *' return type without a hint

   Window GetParentId ();
      Can't Handle Window return type yet

   virtual int *GetPosition ();
      Can't Handle 'int *' return type without a hint

   virtual int *GetScreenSize ();
      Can't Handle 'int *' return type without a hint

   virtual int *GetSize ();
      Can't Handle 'int *' return type without a hint

   Window GetWindowId ();
      Can't Handle Window return type yet

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetDisplayId (Display *);
      Don't know the size of pointer arg number 1

   void SetDisplayId (void *);
      Don't know the size of pointer arg number 1

   void SetParentId (void *);
      Don't know the size of pointer arg number 1

   void SetPosition (int a[2]);
      Method is redundant. Same as SetPosition( int, int)

   virtual void SetSize (int a[2]);
      Method is redundant. Same as SetSize( int, int)

   void SetWindowId (void *);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::XMesaTextMapper;


@Graphics::VTK::XMesaTextMapper::ISA = qw( Graphics::VTK::XTextMapper );

=head1 Graphics::VTK::XMesaTextMapper

=over 1

=item *

Inherits from XTextMapper

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkXMesaTextMapper *New ();
   virtual void ReleaseGraphicsResources (vtkWindow *);
   void RenderOpaqueGeometry (vtkViewport *viewport, vtkActor2D *actor);
   void RenderOverlay (vtkViewport *viewport, vtkActor2D *actor);


B<vtkXMesaTextMapper Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   static int GetListBaseForFont (vtkTextMapper *tm, vtkViewport *vp, Font );
      Arg types of 'Font' not supported

=cut

package Graphics::VTK::OpenGLActor;


@Graphics::VTK::OpenGLActor::ISA = qw( Graphics::VTK::Actor );

=head1 Graphics::VTK::OpenGLActor

=over 1

=item *

Inherits from Actor

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkOpenGLActor *New ();
   void Render (vtkRenderer *ren, vtkMapper *mapper);

=cut

package Graphics::VTK::OpenGLCamera;


@Graphics::VTK::OpenGLCamera::ISA = qw( Graphics::VTK::Camera );

=head1 Graphics::VTK::OpenGLCamera

=over 1

=item *

Inherits from Camera

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkOpenGLCamera *New ();
   void Render (vtkRenderer *ren);
   void UpdateViewport (vtkRenderer *ren);

=cut

package Graphics::VTK::OpenGLImageActor;


@Graphics::VTK::OpenGLImageActor::ISA = qw( Graphics::VTK::ImageActor );

=head1 Graphics::VTK::OpenGLImageActor

=over 1

=item *

Inherits from ImageActor

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   void Load (vtkRenderer *ren);
   vtkOpenGLImageActor *New ();
   void ReleaseGraphicsResources (vtkWindow *);


B<vtkOpenGLImageActor Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   unsigned char *MakeDataSuitable (int &xsize, int &ysize, int &release);
      Can't Handle 'unsigned char *' return type without a hint


=cut

package Graphics::VTK::OpenGLImageMapper;


@Graphics::VTK::OpenGLImageMapper::ISA = qw( Graphics::VTK::ImageMapper );

=head1 Graphics::VTK::OpenGLImageMapper

=over 1

=item *

Inherits from ImageMapper

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkOpenGLImageMapper *New ();
   void RenderData (vtkViewport *viewport, vtkImageData *data, vtkActor2D *actor);
   void RenderOpaqueGeometry (vtkViewport *viewport, vtkActor2D *actor);

=cut

package Graphics::VTK::OpenGLImager;


@Graphics::VTK::OpenGLImager::ISA = qw( Graphics::VTK::Imager );

=head1 Graphics::VTK::OpenGLImager

=over 1

=item *

Inherits from Imager

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Erase ();
   const char *GetClassName ();
   vtkOpenGLImager *New ();
   int RenderOpaqueGeometry ();

=cut

package Graphics::VTK::OpenGLLight;


@Graphics::VTK::OpenGLLight::ISA = qw( Graphics::VTK::Light );

=head1 Graphics::VTK::OpenGLLight

=over 1

=item *

Inherits from Light

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkOpenGLLight *New ();
   void Render (vtkRenderer *ren, int light_index);

=cut

package Graphics::VTK::OpenGLPolyDataMapper;


@Graphics::VTK::OpenGLPolyDataMapper::ISA = qw( Graphics::VTK::PolyDataMapper );

=head1 Graphics::VTK::OpenGLPolyDataMapper

=over 1

=item *

Inherits from PolyDataMapper

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual void Draw (vtkRenderer *ren, vtkActor *a);
   const char *GetClassName ();
   vtkOpenGLPolyDataMapper *New ();
   void ReleaseGraphicsResources (vtkWindow *);
   virtual void RenderPiece (vtkRenderer *ren, vtkActor *a);

=cut

package Graphics::VTK::OpenGLPolyDataMapper2D;


@Graphics::VTK::OpenGLPolyDataMapper2D::ISA = qw( Graphics::VTK::PolyDataMapper2D );

=head1 Graphics::VTK::OpenGLPolyDataMapper2D

=over 1

=item *

Inherits from PolyDataMapper2D

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkOpenGLPolyDataMapper2D *New ();
   void RenderOpaqueGeometry (vtkViewport *viewport, vtkActor2D *actor);

=cut

package Graphics::VTK::OpenGLProperty;


@Graphics::VTK::OpenGLProperty::ISA = qw( Graphics::VTK::Property );

=head1 Graphics::VTK::OpenGLProperty

=over 1

=item *

Inherits from Property

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void BackfaceRender (vtkActor *a, vtkRenderer *ren);
   const char *GetClassName ();
   vtkOpenGLProperty *New ();
   void Render (vtkActor *a, vtkRenderer *ren);

=cut

package Graphics::VTK::OpenGLRenderer;


@Graphics::VTK::OpenGLRenderer::ISA = qw( Graphics::VTK::Renderer );

=head1 Graphics::VTK::OpenGLRenderer

=over 1

=item *

Inherits from Renderer

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Clear (void );
   void ClearLights (void );
   void DeviceRender (void );
   const char *GetClassName ();
   vtkOpenGLRenderer *New ();
   int UpdateLights (void );


B<vtkOpenGLRenderer Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::OpenGLTexture;


@Graphics::VTK::OpenGLTexture::ISA = qw( Graphics::VTK::Texture );

=head1 Graphics::VTK::OpenGLTexture

=over 1

=item *

Inherits from Texture

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   void Load (vtkRenderer *ren);
   vtkOpenGLTexture *New ();
   void ReleaseGraphicsResources (vtkWindow *);


B<vtkOpenGLTexture Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   unsigned char *ResampleToPowerOfTwo (int &xsize, int &ysize, unsigned char *dptr, int bpp);
      Can't Handle 'unsigned char *' return type without a hint


=cut

package Graphics::VTK::OpenGLVolumeRayCastMapper;


@Graphics::VTK::OpenGLVolumeRayCastMapper::ISA = qw( Graphics::VTK::VolumeRayCastMapper );

=head1 Graphics::VTK::OpenGLVolumeRayCastMapper

=over 1

=item *

Inherits from VolumeRayCastMapper

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkOpenGLVolumeRayCastMapper *New ();

=cut

package Graphics::VTK::OpenGLVolumeTextureMapper2D;


@Graphics::VTK::OpenGLVolumeTextureMapper2D::ISA = qw( Graphics::VTK::VolumeTextureMapper2D );

=head1 Graphics::VTK::OpenGLVolumeTextureMapper2D

=over 1

=item *

Inherits from VolumeTextureMapper2D

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkOpenGLVolumeTextureMapper2D *New ();


B<vtkOpenGLVolumeTextureMapper2D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent index);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::OpenGLImageWindow;


@Graphics::VTK::OpenGLImageWindow::ISA = qw( Graphics::VTK::XImageWindow );

=head1 Graphics::VTK::OpenGLImageWindow

=over 1

=item *

Inherits from XImageWindow

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual void EraseWindow ();
   void Frame ();
   const char *GetClassName ();
   virtual int GetDesiredDepth ();
   void MakeCurrent ();
   virtual void MakeDefaultWindow ();
   vtkOpenGLImageWindow *New ();
   void Render ();
   void SwapBuffers ();


B<vtkOpenGLImageWindow Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual Colormap GetDesiredColormap ();
      Can't Handle ColorMap return type yet

   virtual Visual *GetDesiredVisual ();
      Can't Handle Visual return type yet

   XVisualInfo *GetDesiredVisualInfo ();
      Can't Handle 'XVisualInfo *' return type yet

   virtual void *GetGenericContext ();
      Can't Handle 'void *' return type without a hint

   virtual void *GetGenericDisplayId ();
      Can't Handle 'void *' return type without a hint

   virtual void *GetGenericDrawable ();
      Can't Handle 'void *' return type without a hint

   virtual void *GetGenericParentId ();
      Can't Handle 'void *' return type without a hint

   virtual void *GetGenericWindowId ();
      Can't Handle 'void *' return type without a hint

   virtual unsigned char *GetPixelData (int x, int y, int x2, int y2, int front);
      Can't Handle 'unsigned char *' return type without a hint

   virtual float *GetRGBAPixelData (int x, int y, int x2, int y2, int front);
      Can't Handle 'float *' return type without a hint

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   virtual void SetPixelData (int x, int y, int x2, int y2, unsigned char *, int front);
      Don't know the size of pointer arg number 5

   virtual void SetRGBAPixelData (int x, int y, int x2, int y2, float *, int front, int blend);
      Don't know the size of pointer arg number 5


=cut

package Graphics::VTK::XImageWindow;


@Graphics::VTK::XImageWindow::ISA = qw( Graphics::VTK::ImageWindow );

=head1 Graphics::VTK::XImageWindow

=over 1

=item *

Inherits from ImageWindow

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void EraseWindow ();
   void Frame ();
   const char *GetClassName ();
   virtual int GetDesiredDepth ();
   int GetNumberOfColors ();
   int *GetPosition ();
      (Returns a 2-element Perl list)
   int *GetSize ();
      (Returns a 2-element Perl list)
   int GetVisualClass ();
   int GetVisualDepth ();
   vtkXImageWindow *New ();
   void SetBackgroundColor (float r, float g, float b);
   void SetParentId (Window );
   void SetParentInfo (char *info);
   void SetPosition (int , int );
   void SetSize (int x, int y);
   void SetWindowId (Window );
   void SetWindowInfo (char *info);
   void SetWindowName (char *name);
   void SwapBuffers ();


B<vtkXImageWindow Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void GetDefaultVisualInfo (XVisualInfo *info);
      Don't know the size of pointer arg number 1

   virtual Colormap GetDesiredColormap ();
      Can't Handle ColorMap return type yet

   virtual Visual *GetDesiredVisual ();
      Can't Handle Visual return type yet

   Display *GetDisplayId ();
      Can't Handle Display return type yet

   GC GetGC ();
      Can't Handle GC return type yet

   void *GetGenericContext ();
      Can't Handle 'void *' return type without a hint

   void *GetGenericDisplayId ();
      Can't Handle 'void *' return type without a hint

   void *GetGenericDrawable ();
      Can't Handle 'void *' return type without a hint

   void *GetGenericParentId ();
      Can't Handle 'void *' return type without a hint

   void *GetGenericWindowId ();
      Can't Handle 'void *' return type without a hint

   Window GetParentId ();
      Can't Handle Window return type yet

   unsigned char *GetPixelData (int x1, int y1, int x2, int y2, int );
      Can't Handle 'unsigned char *' return type without a hint

   void GetPosition (int *x, int *y);
      Don't know the size of pointer arg number 1

   void GetShiftsScalesAndMasks (int &rshift, int &gshift, int &bshift, int &rscale, int &gscale, int &bscale, unsigned long &rmask, unsigned long &gmask, unsigned long &bmask);
      Arg types of 'unsigned long &' not supported yet
   void GetSize (int *x, int *y);
      Don't know the size of pointer arg number 1

   Visual *GetVisualId ();
      Can't Handle Visual return type yet

   Window GetWindowId ();
      Can't Handle Window return type yet

   Colormap MakeColorMap (Visual *visual);
      Can't Handle ColorMap return type yet

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetDisplayId (Display *);
      Don't know the size of pointer arg number 1

   void SetDisplayId (void *);
      Don't know the size of pointer arg number 1

   void SetParentId (void *);
      Don't know the size of pointer arg number 1

   void SetPosition (int a[2]);
      Method is redundant. Same as SetPosition( int, int)

   void SetSize (int a[2]);
      Method is redundant. Same as SetSize( int, int)

   void SetWindowId (void *);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::XOpenGLRenderWindow;


@Graphics::VTK::XOpenGLRenderWindow::ISA = qw( Graphics::VTK::OpenGLRenderWindow );

=head1 Graphics::VTK::XOpenGLRenderWindow

=over 1

=item *

Inherits from OpenGLRenderWindow

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual void Frame (void );
   const char *GetClassName ();
   virtual int GetDesiredDepth ();
   virtual int GetEventPending ();
   void HideCursor ();
   virtual void Initialize (void );
   void MakeCurrent ();
   vtkXOpenGLRenderWindow *New ();
   virtual void PrefFullScreen (void );
   void Render ();
   virtual void SetFullScreen (int );
   void SetNextWindowId (Window );
   void SetOffScreenRendering (int i);
   void SetParentId (Window );
   void SetParentInfo (char *info);
   void SetPosition (int , int );
   virtual void SetSize (int , int );
   virtual void SetStereoCapableWindow (int capable);
   void SetWindowId (Window );
   void SetWindowInfo (char *info);
   void SetWindowName (char *);
   void ShowCursor ();
   virtual void Start (void );
   virtual void WindowInitialize (void );
   virtual void WindowRemap (void );


B<vtkXOpenGLRenderWindow Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual Colormap GetDesiredColormap ();
      Can't Handle ColorMap return type yet

   virtual Visual *GetDesiredVisual ();
      Can't Handle Visual return type yet

   virtual XVisualInfo *GetDesiredVisualInfo ();
      Can't Handle 'XVisualInfo *' return type yet

   Display *GetDisplayId ();
      Can't Handle Display return type yet

   virtual void *GetGenericContext ();
      Can't Handle 'void *' return type without a hint

   virtual void *GetGenericDisplayId ();
      Can't Handle 'void *' return type without a hint

   virtual void *GetGenericDrawable ();
      Can't Handle 'void *' return type without a hint

   virtual void *GetGenericParentId ();
      Can't Handle 'void *' return type without a hint

   virtual void *GetGenericWindowId ();
      Can't Handle 'void *' return type without a hint

   Window GetParentId ();
      Can't Handle Window return type yet

   virtual int *GetPosition ();
      Can't Handle 'int *' return type without a hint

   virtual int *GetScreenSize ();
      Can't Handle 'int *' return type without a hint

   virtual int *GetSize ();
      Can't Handle 'int *' return type without a hint

   Window GetWindowId ();
      Can't Handle Window return type yet

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetDisplayId (Display *);
      Don't know the size of pointer arg number 1

   void SetDisplayId (void *);
      Don't know the size of pointer arg number 1

   void SetParentId (void *);
      Don't know the size of pointer arg number 1

   void SetPosition (int a[2]);
      Method is redundant. Same as SetPosition( int, int)

   virtual void SetSize (int a[2]);
      Method is redundant. Same as SetSize( int, int)

   void SetWindowId (void *);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::XOpenGLTextMapper;


@Graphics::VTK::XOpenGLTextMapper::ISA = qw( Graphics::VTK::XTextMapper );

=head1 Graphics::VTK::XOpenGLTextMapper

=over 1

=item *

Inherits from XTextMapper

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkXOpenGLTextMapper *New ();
   virtual void ReleaseGraphicsResources (vtkWindow *);
   void RenderGeometry (vtkViewport *viewport, vtkActor2D *actor);
   void RenderOpaqueGeometry (vtkViewport *viewport, vtkActor2D *actor);
   void RenderOverlay (vtkViewport *, vtkActor2D *);
   void RenderTranslucentGeometry (vtkViewport *viewport, vtkActor2D *actor);


B<vtkXOpenGLTextMapper Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   static int GetListBaseForFont (vtkTextMapper *tm, vtkViewport *vp, Font );
      Arg types of 'Font' not supported

=cut

package Graphics::VTK::XRenderWindowInteractor;


@Graphics::VTK::XRenderWindowInteractor::ISA = qw( Graphics::VTK::RenderWindowInteractor );

=head1 Graphics::VTK::XRenderWindowInteractor

=over 1

=item *

Inherits from RenderWindowInteractor

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void BreakLoopFlagOff ();
   void BreakLoopFlagOn ();
   int CreateTimer (int timertype);
   int DestroyTimer (void );
   virtual void Disable ();
   virtual void Enable ();
   int GetBreakLoopFlag ();
   const char *GetClassName ();
   virtual void Initialize ();
   vtkXRenderWindowInteractor *New ();
   void SetBreakLoopFlag (int );
   virtual void Start ();
   void TerminateApp (void );


B<vtkXRenderWindowInteractor Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   XtIntervalId AddTimeOut (XtAppContext app_context, unsigned long erval, XtTimerCallbackProc proc, XtPointer client_data);
      Arg types of 'XtAppContext' not supported yet
   void Callback (Widget w, XtPointer client_data, XEvent *event, Boolean *ctd);
      Arg types of 'Widget' not supported yet
   XtAppContext GetApp ();
      Can't Handle XtAppContext return type yet

   virtual void GetMousePosition (int *x, int *y);
      Don't know the size of pointer arg number 1

   Widget GetTopLevelShell ();
      Can't Handle Widget return type yet

   Widget GetWidget ();
      Can't Handle Widget return type yet

   virtual void Initialize (XtAppContext app);
      Arg types of 'XtAppContext' not supported yet
   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   virtual void SetTopLevelShell (Widget );
      Arg types of 'Widget' not supported yet
   virtual void SetWidget (Widget );
      Arg types of 'Widget' not supported yet
   void Timer (XtPointer client_data, XtIntervalId *id);
      Don't know the size of pointer arg number 2

   void vtkXRenderWindowInteractorCallback (Widget , XtPointer , XEvent *, Boolean *);
      Arg types of 'Widget' not supported yet
   void vtkXRenderWindowInteractorTimer (XtPointer , XtIntervalId *);
      Don't know the size of pointer arg number 2


=cut

package Graphics::VTK::XTextMapper;


@Graphics::VTK::XTextMapper::ISA = qw( Graphics::VTK::TextMapper );

=head1 Graphics::VTK::XTextMapper

=over 1

=item *

Inherits from TextMapper

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkXTextMapper *New ();
   void SetFontSize (int size);


B<vtkXTextMapper Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void DetermineSize (vtkViewport *viewport, int size[2]);
      Don't know the size of pointer arg number 2

   void GetSize (vtkViewport *viewport, int size[2]);
      Don't know the size of pointer arg number 2


=cut

package Graphics::VTK::Win32OpenGLImageWindow;


@Graphics::VTK::Win32OpenGLImageWindow::ISA = qw( Graphics::VTK::ImageWindow );

=head1 Graphics::VTK::Win32OpenGLImageWindow

=over 1

=item *

Inherits from ImageWindow

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Clean ();
   void Frame ();
   const char *GetClassName ();
   vtkWin32OpenGLImageWindow *GetOutput ();
   void MakeCurrent ();
   virtual void MakeDefaultWindow ();
   vtkWin32OpenGLImageWindow *New ();
   virtual void OpenGLInit ();
   void Render ();
   void ResumeScreenRendering ();
   void SetParentInfo (char *);
   virtual void SetPosition (int , int );
   virtual void SetSize (int , int );
   void SetWindowInfo (char *);
   virtual void SetWindowName (char *);
   void SetupMemoryRendering (int x, int y, HDC prn);
   virtual void SetupPalette (HDC hDC);
   virtual void SetupPixelFormat (HDC hDC, DWORD dwFlags, int debug, int bpp, int zbpp);
   void SwapBuffers ();


B<vtkWin32OpenGLImageWindow Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   HDC GetMemoryDC ();
      Can't Handle HDC return type yet

   unsigned char *GetMemoryData ();
      Can't Handle 'unsigned char *' return type without a hint

   virtual unsigned char *GetPixelData (int x, int y, int x2, int y2, int front);
      Can't Handle 'unsigned char *' return type without a hint

   virtual int *GetPosition ();
      Can't Handle 'int *' return type without a hint

   virtual void GetPosition (int *x, int *y);
      Don't know the size of pointer arg number 1

   virtual float *GetRGBAPixelData (int x, int y, int x2, int y2, int front);
      Can't Handle 'float *' return type without a hint

   virtual int *GetSize ();
      Can't Handle 'int *' return type without a hint

   virtual void GetSize (int *x, int *y);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   virtual void ReleaseRGBAPixelData (float *data);
      Don't know the size of pointer arg number 1

   virtual void SetPixelData (int x, int y, int x2, int y2, unsigned char *, int front);
      Don't know the size of pointer arg number 5

   virtual void SetPosition (int a[2]);
      Method is redundant. Same as SetPosition( int, int)

   virtual void SetRGBAPixelData (int x, int y, int x2, int y2, float *, int front, int blend);
      Don't know the size of pointer arg number 5

   virtual void SetSize (int a[2]);
      Method is redundant. Same as SetSize( int, int)


=cut

package Graphics::VTK::Win32OpenGLRenderWindow;


@Graphics::VTK::Win32OpenGLRenderWindow::ISA = qw( Graphics::VTK::OpenGLRenderWindow );

=head1 Graphics::VTK::Win32OpenGLRenderWindow

=over 1

=item *

Inherits from OpenGLRenderWindow

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Clean ();
   void Frame (void );
   const char *GetClassName ();
   virtual int GetEventPending ();
   void HideCursor ();
   virtual void Initialize (void );
   void MakeCurrent ();
   vtkWin32OpenGLRenderWindow *New ();
   virtual void PrefFullScreen (void );
   void ResumeScreenRendering (void );
   virtual void SetFullScreen (int );
   virtual void SetOffScreenRendering (int offscreen);
   void SetParentInfo (char *);
   virtual void SetPosition (int , int );
   virtual void SetSize (int , int );
   virtual void SetStereoCapableWindow (int capable);
   void SetWindowInfo (char *);
   virtual void SetWindowName (char *);
   void SetupMemoryRendering (int x, int y, HDC prn);
   void SetupMemoryRendering (HBITMAP hbmp);
   virtual void SetupPalette (HDC hDC);
   virtual void SetupPixelFormat (HDC hDC, DWORD dwFlags, int debug, int bpp, int zbpp);
   void ShowCursor ();
   virtual void Start (void );
   virtual void WindowInitialize (void );
   virtual void WindowRemap (void );


B<vtkWin32OpenGLRenderWindow Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   HDC GetMemoryDC ();
      Can't Handle HDC return type yet

   unsigned char *GetMemoryData ();
      Can't Handle 'unsigned char *' return type without a hint

   virtual int *GetPosition ();
      Can't Handle 'int *' return type without a hint

   virtual int *GetScreenSize ();
      Can't Handle 'int *' return type without a hint

   virtual int *GetSize ();
      Can't Handle 'int *' return type without a hint

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   virtual void SetPosition (int a[2]);
      Method is redundant. Same as SetPosition( int, int)

   virtual void SetSize (int a[2]);
      Method is redundant. Same as SetSize( int, int)


=cut

package Graphics::VTK::Win32OpenGLTextMapper;


@Graphics::VTK::Win32OpenGLTextMapper::ISA = qw( Graphics::VTK::Win32TextMapper );

=head1 Graphics::VTK::Win32OpenGLTextMapper

=over 1

=item *

Inherits from Win32TextMapper

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   static int GetListBaseForFont (vtkTextMapper *tm, vtkViewport *vp);
   vtkWin32OpenGLTextMapper *New ();
   virtual void ReleaseGraphicsResources (vtkWindow *);
   void RenderGeometry (vtkViewport *viewport, vtkActor2D *actor);
   void RenderOpaqueGeometry (vtkViewport *viewport, vtkActor2D *actor);
   void RenderOverlay (vtkViewport *viewport, vtkActor2D *actor);
   void RenderTranslucentGeometry (vtkViewport *viewport, vtkActor2D *actor);

=cut

package Graphics::VTK::Win32RenderWindowInteractor;


@Graphics::VTK::Win32RenderWindowInteractor::ISA = qw( Graphics::VTK::RenderWindowInteractor );

=head1 Graphics::VTK::Win32RenderWindowInteractor

=over 1

=item *

Inherits from RenderWindowInteractor

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int CreateTimer (int timertype);
   int DestroyTimer (void );
   virtual void Disable ();
   virtual void Enable ();
   virtual void ExitCallback ();
   const char *GetClassName ();
   int GetInstallMessageProc ();
   virtual void Initialize ();
   void InstallMessageProcOff ();
   void InstallMessageProcOn ();
   vtkWin32RenderWindowInteractor *New ();
   static void SetClassExitMethod (void (*func)(void *) , void *arg);
   void SetInstallMessageProc (int );
   virtual void Start ();
   void TerminateApp (void );


B<vtkWin32RenderWindowInteractor Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   static void SetClassExitMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.


=cut

package Graphics::VTK::Win32TextMapper;


@Graphics::VTK::Win32TextMapper::ISA = qw( Graphics::VTK::TextMapper );

=head1 Graphics::VTK::Win32TextMapper

=over 1

=item *

Inherits from TextMapper

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkWin32TextMapper *New ();


B<vtkWin32TextMapper Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void GetSize (vtkViewport *viewport, int size[2]);
      Don't know the size of pointer arg number 2


=cut

1;
