
package Graphics::VTK::Filtering;
use 5.004;
use strict;
use Carp;

use vars qw/ $VERSION @ISA/;

require DynaLoader;

$VERSION = '4.0.001';

@ISA = qw/ DynaLoader /;

bootstrap Graphics::VTK::Filtering $VERSION;


=head1 NAME

VTKFiltering  - A Perl interface to VTKFiltering library

=head1 SYNOPSIS

C<use Graphics::VTK;>
C<use Graphics::VTK::Filtering;>

=head1 DESCRIPTION

Graphics::VTK::Filtering is an interface to the Filtering libaray of the C++ visualization toolkit VTK..

=head1 AUTHOR

Original PerlVTK Package: Roberto De Leo <rdl@math.umd.edu>

Additional Refinements: John Cerney <j-cerney1@raytheon.com>

=cut

package Graphics::VTK::CardinalSpline;


@Graphics::VTK::CardinalSpline::ISA = qw( Graphics::VTK::Spline );

=head1 Graphics::VTK::CardinalSpline

=over 1

=item *

Inherits from Spline

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Compute ();
   float Evaluate (float t);
   const char *GetClassName ();
   vtkCardinalSpline *New ();


B<vtkCardinalSpline Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void Fit1D (int n, float *x, float *y, float *w, float coefficients[4][], int leftConstraint, float leftValue, int rightConstraint, float rightValue);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void FitClosed1D (int n, float *x, float *y, float *w, float coefficients[4][]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::CastToConcrete;


@Graphics::VTK::CastToConcrete::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::CastToConcrete

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkCastToConcrete *New ();

=cut

package Graphics::VTK::CellLocator;


@Graphics::VTK::CellLocator::ISA = qw( Graphics::VTK::Locator );

=head1 Graphics::VTK::CellLocator

=over 1

=item *

Inherits from Locator

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void BuildLocator ();
   void CacheCellBoundsOff ();
   void CacheCellBoundsOn ();
   void FreeSearchStructure ();
   void GenerateRepresentation (int level, vtkPolyData *pd);
   int GetCacheCellBounds ();
   virtual vtkIdList *GetCells (int bucket);
   const char *GetClassName ();
   virtual int GetNumberOfBuckets (void );
   int GetNumberOfCellsPerBucket ();
   int GetNumberOfCellsPerBucketMaxValue ();
   int GetNumberOfCellsPerBucketMinValue ();
   vtkCellLocator *New ();
   void SetCacheCellBounds (int );
   void SetNumberOfCellsPerBucket (int );


B<vtkCellLocator Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   float Distance2ToBounds (float x[3], float bounds[6]);
      Don't know the size of pointer arg number 1

   float Distance2ToBucket (float x[3], int nei[3]);
      Don't know the size of pointer arg number 1

   void FindClosestPoint (float x[3], float closestPoint[3], long &cellId, int &subId, float &dist2);
      Don't know the size of pointer arg number 1

   int FindClosestPointWithinRadius (float x[3], float radius, float closestPoint[3], long &cellId, int &subId, float &dist2);
      Don't know the size of pointer arg number 1

   int FindClosestPointWithinRadius (float x[3], float radius, float closestPoint[3], vtkGenericCell *cell, long &cellId, int &subId, float &dist2);
      Don't know the size of pointer arg number 1

   int FindClosestPointWithinRadius (float x[3], float radius, float closestPoint[3], vtkGenericCell *cell, long &cellId, int &subId, float &dist2, int &inside);
      Don't know the size of pointer arg number 1

   void FindClosestPoint (float x[3], float closestPoint[3], vtkGenericCell *cell, long &cellId, int &subId, float &dist2);
      Don't know the size of pointer arg number 1

   int GenerateIndex (int offset, int numDivs, int i, int j, int k, long &idx);
      Don't know the size of pointer arg number 6

   void GetBucketNeighbors (int ijk[3], int ndivs, int level);
      Don't know the size of pointer arg number 1

   void GetChildren (int idx, int level, int children[8]);
      Don't know the size of pointer arg number 3

   void GetOverlappingBuckets (float x[3], int ijk[3], float dist, int prevMinLevel[3], int prevMaxLevel[3]);
      Don't know the size of pointer arg number 1

   virtual int IntersectWithLine (float a0[3], float a1[3], float tol, float &t, float x[3], float pcoords[3], int &subId);
      Don't know the size of pointer arg number 1

   virtual int IntersectWithLine (float a0[3], float a1[3], float tol, float &t, float x[3], float pcoords[3], int &subId, long &cellId);
      Don't know the size of pointer arg number 1

   virtual int IntersectWithLine (float a0[3], float a1[3], float tol, float &t, float x[3], float pcoords[3], int &subId, long &cellId, vtkGenericCell *cell);
      Don't know the size of pointer arg number 1

   void MarkParents (void *, int , int , int , int , int );
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ColorTransferFunction;


@Graphics::VTK::ColorTransferFunction::ISA = qw( Graphics::VTK::ScalarsToColors );

=head1 Graphics::VTK::ColorTransferFunction

=over 1

=item *

Inherits from ScalarsToColors

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddHSVPoint (float x, float h, float s, float v);
   void AddHSVSegment (float x1, float h1, float s1, float v1, float x2, float h2, float s2, float v2);
   void AddRGBPoint (float x, float r, float g, float b);
   void AddRGBSegment (float x1, float r1, float g1, float b1, float x2, float r2, float g2, float b2);
   void ClampingOff ();
   void ClampingOn ();
   void DeepCopy (vtkColorTransferFunction *f);
   float GetBlueValue (float x);
   int GetClamping ();
   int GetClampingMaxValue ();
   int GetClampingMinValue ();
   const char *GetClassName ();
   float *GetColor (float x);
      (Returns a 3-element Perl list)
   int GetColorSpace ();
   int GetColorSpaceMaxValue ();
   int GetColorSpaceMinValue ();
   float GetGreenValue (float x);
   float  *GetRange ();
      (Returns a 2-element Perl list)
   float GetRedValue (float x);
   int GetSize ();
   vtkColorTransferFunction *New ();
   void RemoveAllPoints ();
   void RemovePoint (float x);
   void SetClamping (int );
   void SetColorSpace (int );
   void SetColorSpaceToHSV ();
   void SetColorSpaceToRGB ();


B<vtkColorTransferFunction Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void BuildFunctionFromTable (float x1, float x2, int size, float *table);
      Don't know the size of pointer arg number 4

   void GetColor (float x, float rgb[3]);
      Don't know the size of pointer arg number 2

   float *GetDataPointer ();
      Can't Handle 'float *' return type without a hint

   void GetTable (float x1, float x2, int n, float *table);
      Don't know the size of pointer arg number 4

   const unsigned char *GetTable (float x1, float x2, int n);
      Can't Handle 'const unsigned char *' return type without a hint

   virtual void MapScalarsThroughTable2 (void *input, unsigned char *output, int inputDataType, int numberOfValues, int inputIncrement, int outputIncrement);
      Don't know the size of pointer arg number 1

   virtual unsigned char *MapValue (float v);
      Can't Handle 'unsigned char *' return type without a hint

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::Cone;


@Graphics::VTK::Cone::ISA = qw( Graphics::VTK::ImplicitFunction );

=head1 Graphics::VTK::Cone

=over 1

=item *

Inherits from ImplicitFunction

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   float EvaluateFunction (float x, float y, float z);
   float GetAngle ();
   float GetAngleMaxValue ();
   float GetAngleMinValue ();
   const char *GetClassName ();
   vtkCone *New ();
   void SetAngle (float );


B<vtkCone Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   float EvaluateFunction (float x[3]);
      Method is redundant. Same as EvaluateFunction( float, float, float)

   void EvaluateGradient (float x[3], float g[3]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::Cylinder;


@Graphics::VTK::Cylinder::ISA = qw( Graphics::VTK::ImplicitFunction );

=head1 Graphics::VTK::Cylinder

=over 1

=item *

Inherits from ImplicitFunction

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   float EvaluateFunction (float x, float y, float z);
   float  *GetCenter ();
      (Returns a 3-element Perl list)
   const char *GetClassName ();
   float GetRadius ();
   vtkCylinder *New ();
   void SetCenter (float , float , float );
   void SetRadius (float );


B<vtkCylinder Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   float EvaluateFunction (float x[3]);
      Method is redundant. Same as EvaluateFunction( float, float, float)

   void EvaluateGradient (float x[3], float g[3]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetCenter (float  a[3]);
      Method is redundant. Same as SetCenter( float, float, float)


=cut

package Graphics::VTK::DataObjectSource;


@Graphics::VTK::DataObjectSource::ISA = qw( Graphics::VTK::Source );

=head1 Graphics::VTK::DataObjectSource

=over 1

=item *

Inherits from Source

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkDataObject *GetOutput (int idx);
   vtkDataObject *GetOutput ();
   vtkDataObjectSource *New ();
   void SetOutput (vtkDataObject *);

=cut

package Graphics::VTK::DataSetSource;


@Graphics::VTK::DataSetSource::ISA = qw( Graphics::VTK::Source );

=head1 Graphics::VTK::DataSetSource

=over 1

=item *

Inherits from Source

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkDataSet *GetOutput (int idx);
   vtkDataSet *GetOutput ();
   vtkDataSetSource *New ();
   void SetOutput (vtkDataSet *);

=cut

package Graphics::VTK::DataSetToDataSetFilter;


@Graphics::VTK::DataSetToDataSetFilter::ISA = qw( Graphics::VTK::DataSetSource );

=head1 Graphics::VTK::DataSetToDataSetFilter

=over 1

=item *

Inherits from DataSetSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual void ComputeInputUpdateExtents (vtkDataObject *output);
   const char *GetClassName ();
   vtkDataSet *GetInput ();
   vtkDataSet *GetOutput (int idx);
   vtkDataSet *GetOutput ();
   vtkPolyData *GetPolyDataOutput ();
   vtkRectilinearGrid *GetRectilinearGridOutput ();
   vtkStructuredGrid *GetStructuredGridOutput ();
   vtkStructuredPoints *GetStructuredPointsOutput ();
   vtkUnstructuredGrid *GetUnstructuredGridOutput ();
   void SetInput (vtkDataSet *input);

=cut

package Graphics::VTK::DataSetToPolyDataFilter;


@Graphics::VTK::DataSetToPolyDataFilter::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::DataSetToPolyDataFilter

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual void ComputeInputUpdateExtents (vtkDataObject *output);
   const char *GetClassName ();
   vtkDataSet *GetInput ();
   virtual void SetInput (vtkDataSet *input);

=cut

package Graphics::VTK::DataSetToStructuredGridFilter;


@Graphics::VTK::DataSetToStructuredGridFilter::ISA = qw( Graphics::VTK::StructuredGridSource );

=head1 Graphics::VTK::DataSetToStructuredGridFilter

=over 1

=item *

Inherits from StructuredGridSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkDataSet *GetInput ();
   virtual void SetInput (vtkDataSet *input);

=cut

package Graphics::VTK::DataSetToStructuredPointsFilter;


@Graphics::VTK::DataSetToStructuredPointsFilter::ISA = qw( Graphics::VTK::StructuredPointsSource );

=head1 Graphics::VTK::DataSetToStructuredPointsFilter

=over 1

=item *

Inherits from StructuredPointsSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkDataSet *GetInput ();
   virtual void SetInput (vtkDataSet *input);

=cut

package Graphics::VTK::DataSetToUnstructuredGridFilter;


@Graphics::VTK::DataSetToUnstructuredGridFilter::ISA = qw( Graphics::VTK::UnstructuredGridSource );

=head1 Graphics::VTK::DataSetToUnstructuredGridFilter

=over 1

=item *

Inherits from UnstructuredGridSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkDataSet *GetInput ();
   virtual void SetInput (vtkDataSet *input);

=cut

package Graphics::VTK::ImageInPlaceFilter;


@Graphics::VTK::ImageInPlaceFilter::ISA = qw( Graphics::VTK::ImageToImageFilter );

=head1 Graphics::VTK::ImageInPlaceFilter

=over 1

=item *

Inherits from ImageToImageFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageInPlaceFilter *New ();

=cut

package Graphics::VTK::ImageMultipleInputFilter;


@Graphics::VTK::ImageMultipleInputFilter::ISA = qw( Graphics::VTK::ImageSource );

=head1 Graphics::VTK::ImageMultipleInputFilter

=over 1

=item *

Inherits from ImageSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual void AddInput (vtkImageData *input);
   void BypassOff ();
   void BypassOn ();
   int GetBypass ();
   const char *GetClassName ();
   vtkImageData *GetInput (int num);
   vtkImageData *GetInput ();
   int GetNumberOfThreads ();
   int GetNumberOfThreadsMaxValue ();
   int GetNumberOfThreadsMinValue ();
   vtkImageMultipleInputFilter *New ();
   virtual void RemoveInput (vtkImageData *input);
   void SetBypass (int );
   virtual void SetInput (int num, vtkImageData *input);
   void SetNumberOfThreads (int );


B<vtkImageMultipleInputFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void ComputeInputUpdateExtent (int inExt[6], int outExt[6], int whichInput);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   virtual int SplitExtent (int splitExt[6], int startExt[6], int num, int total);
      Don't know the size of pointer arg number 1

   virtual void ThreadedExecute (vtkImageData *inDatas, vtkImageData *outData, int extent[6], int threadId);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageMultipleInputOutputFilter;


@Graphics::VTK::ImageMultipleInputOutputFilter::ISA = qw( Graphics::VTK::ImageMultipleInputFilter );

=head1 Graphics::VTK::ImageMultipleInputOutputFilter

=over 1

=item *

Inherits from ImageMultipleInputFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageData *GetOutput (int num);
   vtkImageData *GetOutput ();
   vtkImageMultipleInputOutputFilter *New ();


B<vtkImageMultipleInputOutputFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void ComputeInputUpdateExtent (int inExt[6], int outExt[6], int whichInput);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   virtual void ThreadedExecute (vtkImageData *inDatas, vtkImageData *outDatas, int extent[6], int threadId);
      Don't know the size of pointer arg number 3

   virtual void ThreadedExecute (vtkImageData *inDatas, vtkImageData *outData, int extent[6], int threadId);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageSource;


@Graphics::VTK::ImageSource::ISA = qw( Graphics::VTK::Source );

=head1 Graphics::VTK::ImageSource

=over 1

=item *

Inherits from Source

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageData *GetOutput (int idx);
   vtkImageData *GetOutput ();
   vtkImageSource *New ();
   void SetOutput (vtkImageData *output);


B<vtkImageSource Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeRequiredInputUpdateExtent (int *, int *);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::ImageToImageFilter;


@Graphics::VTK::ImageToImageFilter::ISA = qw( Graphics::VTK::ImageSource );

=head1 Graphics::VTK::ImageToImageFilter

=over 1

=item *

Inherits from ImageSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageData *GetInput ();
   long GetInputMemoryLimit ();
   int GetNumberOfThreads ();
   int GetNumberOfThreadsMaxValue ();
   int GetNumberOfThreadsMinValue ();
   vtkImageToImageFilter *New ();
   virtual void SetInput (vtkImageData *input);
   void SetInputMemoryLimit (int );
   void SetNumberOfThreads (int );


B<vtkImageToImageFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void BypassOff ();
      Method is marked 'Do Not Use' in its descriptions

   void BypassOn ();
      Method is marked 'Do Not Use' in its descriptions

   virtual void ComputeInputUpdateExtent (int inExt[6], int outExt[6]);
      Don't know the size of pointer arg number 1

   int GetBypass ();
      Method is marked 'Do Not Use' in its descriptions

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetBypass (int );
      Method is marked 'Do Not Use' in its descriptions

   virtual int SplitExtent (int splitExt[6], int startExt[6], int num, int total);
      Don't know the size of pointer arg number 1

   virtual void ThreadedExecute (vtkImageData *inData, vtkImageData *outData, int extent[6], int threadId);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::ImageToStructuredPoints;


@Graphics::VTK::ImageToStructuredPoints::ISA = qw( Graphics::VTK::Source );

=head1 Graphics::VTK::ImageToStructuredPoints

=over 1

=item *

Inherits from Source

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageData *GetInput ();
   vtkStructuredPoints *GetOutput (int idx);
   vtkStructuredPoints *GetOutput ();
   vtkImageData *GetVectorInput ();
   vtkImageToStructuredPoints *New ();
   void SetInput (vtkImageData *input);
   void SetVectorInput (vtkImageData *input);


B<vtkImageToStructuredPoints Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ImageTwoInputFilter;


@Graphics::VTK::ImageTwoInputFilter::ISA = qw( Graphics::VTK::ImageMultipleInputFilter );

=head1 Graphics::VTK::ImageTwoInputFilter

=over 1

=item *

Inherits from ImageMultipleInputFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageData *GetInput1 ();
   vtkImageData *GetInput2 ();
   vtkImageTwoInputFilter *New ();
   virtual void SetInput1 (vtkImageData *input);
   virtual void SetInput2 (vtkImageData *input);

=cut

package Graphics::VTK::ImplicitBoolean;


@Graphics::VTK::ImplicitBoolean::ISA = qw( Graphics::VTK::ImplicitFunction );

=head1 Graphics::VTK::ImplicitBoolean

=over 1

=item *

Inherits from ImplicitFunction

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddFunction (vtkImplicitFunction *in);
   float EvaluateFunction (float x, float y, float z);
   const char *GetClassName ();
   vtkImplicitFunctionCollection *GetFunction ();
   unsigned long GetMTime ();
   int GetOperationType ();
   const char *GetOperationTypeAsString ();
   int GetOperationTypeMaxValue ();
   int GetOperationTypeMinValue ();
   vtkImplicitBoolean *New ();
   void RemoveFunction (vtkImplicitFunction *in);
   void SetOperationType (int );
   void SetOperationTypeToDifference ();
   void SetOperationTypeToIntersection ();
   void SetOperationTypeToUnion ();
   void SetOperationTypeToUnionOfMagnitudes ();


B<vtkImplicitBoolean Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   float EvaluateFunction (float x[3]);
      Method is redundant. Same as EvaluateFunction( float, float, float)

   void EvaluateGradient (float x[3], float g[3]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ImplicitDataSet;


@Graphics::VTK::ImplicitDataSet::ISA = qw( Graphics::VTK::ImplicitFunction );

=head1 Graphics::VTK::ImplicitDataSet

=over 1

=item *

Inherits from ImplicitFunction

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   float EvaluateFunction (float x, float y, float z);
   const char *GetClassName ();
   vtkDataSet *GetDataSet ();
   unsigned long GetMTime ();
   float  *GetOutGradient ();
      (Returns a 3-element Perl list)
   float GetOutValue ();
   vtkImplicitDataSet *New ();
   void SetDataSet (vtkDataSet *);
   void SetOutGradient (float , float , float );
   void SetOutValue (float );


B<vtkImplicitDataSet Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   float EvaluateFunction (float x[3]);
      Method is redundant. Same as EvaluateFunction( float, float, float)

   void EvaluateGradient (float x[3], float n[3]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetOutGradient (float  a[3]);
      Method is redundant. Same as SetOutGradient( float, float, float)


=cut

package Graphics::VTK::ImplicitSelectionLoop;


@Graphics::VTK::ImplicitSelectionLoop::ISA = qw( Graphics::VTK::ImplicitFunction );

=head1 Graphics::VTK::ImplicitSelectionLoop

=over 1

=item *

Inherits from ImplicitFunction

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AutomaticNormalGenerationOff ();
   void AutomaticNormalGenerationOn ();
   float EvaluateFunction (float x, float y, float z);
   int GetAutomaticNormalGeneration ();
   const char *GetClassName ();
   vtkPoints *GetLoop ();
   unsigned long GetMTime ();
   float  *GetNormal ();
      (Returns a 3-element Perl list)
   vtkImplicitSelectionLoop *New ();
   void SetAutomaticNormalGeneration (int );
   void SetLoop (vtkPoints *);
   void SetNormal (float , float , float );


B<vtkImplicitSelectionLoop Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   float EvaluateFunction (float x[3]);
      Method is redundant. Same as EvaluateFunction( float, float, float)

   void EvaluateGradient (float x[3], float n[3]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetNormal (float  a[3]);
      Method is redundant. Same as SetNormal( float, float, float)


=cut

package Graphics::VTK::ImplicitVolume;


@Graphics::VTK::ImplicitVolume::ISA = qw( Graphics::VTK::ImplicitFunction );

=head1 Graphics::VTK::ImplicitVolume

=over 1

=item *

Inherits from ImplicitFunction

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   float EvaluateFunction (float x, float y, float z);
   const char *GetClassName ();
   unsigned long GetMTime ();
   float  *GetOutGradient ();
      (Returns a 3-element Perl list)
   float GetOutValue ();
   vtkImageData *GetVolume ();
   vtkImplicitVolume *New ();
   void SetOutGradient (float , float , float );
   void SetOutValue (float );
   void SetVolume (vtkImageData *);


B<vtkImplicitVolume Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   float EvaluateFunction (float x[3]);
      Method is redundant. Same as EvaluateFunction( float, float, float)

   void EvaluateGradient (float x[3], float n[3]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetOutGradient (float  a[3]);
      Method is redundant. Same as SetOutGradient( float, float, float)


=cut

package Graphics::VTK::ImplicitWindowFunction;


@Graphics::VTK::ImplicitWindowFunction::ISA = qw( Graphics::VTK::ImplicitFunction );

=head1 Graphics::VTK::ImplicitWindowFunction

=over 1

=item *

Inherits from ImplicitFunction

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   float EvaluateFunction (float x, float y, float z);
   const char *GetClassName ();
   vtkImplicitFunction *GetImplicitFunction ();
   unsigned long GetMTime ();
   float  *GetWindowRange ();
      (Returns a 2-element Perl list)
   float  *GetWindowValues ();
      (Returns a 2-element Perl list)
   vtkImplicitWindowFunction *New ();
   void SetImplicitFunction (vtkImplicitFunction *);
   void SetWindowRange (float , float );
   void SetWindowValues (float , float );


B<vtkImplicitWindowFunction Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   float EvaluateFunction (float x[3]);
      Method is redundant. Same as EvaluateFunction( float, float, float)

   void EvaluateGradient (float x[3], float n[3]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetWindowRange (float  a[2]);
      Method is redundant. Same as SetWindowRange( float, float)

   void SetWindowValues (float  a[2]);
      Method is redundant. Same as SetWindowValues( float, float)


=cut

package Graphics::VTK::KochanekSpline;


@Graphics::VTK::KochanekSpline::ISA = qw( Graphics::VTK::Spline );

=head1 Graphics::VTK::KochanekSpline

=over 1

=item *

Inherits from Spline

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Compute ();
   float Evaluate (float t);
   const char *GetClassName ();
   float GetDefaultBias ();
   float GetDefaultContinuity ();
   float GetDefaultTension ();
   vtkKochanekSpline *New ();
   void SetDefaultBias (float );
   void SetDefaultContinuity (float );
   void SetDefaultTension (float );


B<vtkKochanekSpline Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void Fit1D (int n, float *x, float *y, float tension, float bias, float continuity, float coefficients[4][], int leftConstraint, float leftValue, int rightConstraint, float rightValue);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::MergePoints;


@Graphics::VTK::MergePoints::ISA = qw( Graphics::VTK::PointLocator );

=head1 Graphics::VTK::MergePoints

=over 1

=item *

Inherits from PointLocator

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   long IsInsertedPoint (float x, float y, float z);
   vtkMergePoints *New ();


B<vtkMergePoints Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int InsertUniquePoint (const float x[3], long &ptId);
      Don't know the size of pointer arg number 1

   long IsInsertedPoint (const float x[3]);
      Method is redundant. Same as IsInsertedPoint( float, float, float)


=cut

package Graphics::VTK::MergePoints2D;


@Graphics::VTK::MergePoints2D::ISA = qw( Graphics::VTK::PointLocator2D );

=head1 Graphics::VTK::MergePoints2D

=over 1

=item *

Inherits from PointLocator2D

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkMergePoints2D *New ();


B<vtkMergePoints2D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int IsInsertedPoint (float x[2]);
      Can't handle methods with single array args (like a[3]) yet.


=cut

package Graphics::VTK::PiecewiseFunction;


@Graphics::VTK::PiecewiseFunction::ISA = qw( Graphics::VTK::DataObject );

=head1 Graphics::VTK::PiecewiseFunction

=over 1

=item *

Inherits from DataObject

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddPoint (float x, float val);
   void AddSegment (float x1, float val1, float x2, float val2);
   void ClampingOff ();
   void ClampingOn ();
   void DeepCopy (vtkDataObject *f);
   int GetClamping ();
   const char *GetClassName ();
   int GetDataObjectType ();
   float GetFirstNonZeroValue ();
   unsigned long GetMTime ();
   float *GetRange ();
      (Returns a 2-element Perl list)
   int GetSize ();
   const char *GetType ();
   float GetValue (float x);
   void Initialize ();
   vtkPiecewiseFunction *New ();
   void RemoveAllPoints ();
   void RemovePoint (float x);
   void SetClamping (int );
   void ShallowCopy (vtkDataObject *f);


B<vtkPiecewiseFunction Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void BuildFunctionFromTable (float x1, float x2, int size, float *table, int stride);
      Don't know the size of pointer arg number 4

   float *GetDataPointer ();
      Can't Handle 'float *' return type without a hint

   void GetTable (float x1, float x2, int size, float *table, int stride);
      Don't know the size of pointer arg number 4

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::PointSetSource;


@Graphics::VTK::PointSetSource::ISA = qw( Graphics::VTK::Source );

=head1 Graphics::VTK::PointSetSource

=over 1

=item *

Inherits from Source

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkPointSet *GetOutput (int idx);
   vtkPointSet *GetOutput ();
   vtkPointSetSource *New ();
   void SetOutput (vtkPointSet *output);

=cut

package Graphics::VTK::PointSetToPointSetFilter;


@Graphics::VTK::PointSetToPointSetFilter::ISA = qw( Graphics::VTK::PointSetSource );

=head1 Graphics::VTK::PointSetToPointSetFilter

=over 1

=item *

Inherits from PointSetSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual void ComputeInputUpdateExtents (vtkDataObject *output);
   const char *GetClassName ();
   vtkPointSet *GetInput ();
   vtkPointSet *GetOutput (int idx);
   vtkPointSet *GetOutput ();
   vtkPolyData *GetPolyDataOutput ();
   vtkStructuredGrid *GetStructuredGridOutput ();
   vtkUnstructuredGrid *GetUnstructuredGridOutput ();
   void SetInput (vtkPointSet *input);

=cut

package Graphics::VTK::PolyDataCollection;


@Graphics::VTK::PolyDataCollection::ISA = qw( Graphics::VTK::Collection );

=head1 Graphics::VTK::PolyDataCollection

=over 1

=item *

Inherits from Collection

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddItem (vtkPolyData *pd);
   const char *GetClassName ();
   vtkPolyData *GetNextItem ();
   vtkPolyDataCollection *New ();

=cut

package Graphics::VTK::PolyDataSource;


@Graphics::VTK::PolyDataSource::ISA = qw( Graphics::VTK::Source );

=head1 Graphics::VTK::PolyDataSource

=over 1

=item *

Inherits from Source

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkPolyData *GetOutput (int idx);
   vtkPolyData *GetOutput ();
   vtkPolyDataSource *New ();
   void SetOutput (vtkPolyData *output);

=cut

package Graphics::VTK::PolyDataToPolyDataFilter;


@Graphics::VTK::PolyDataToPolyDataFilter::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::PolyDataToPolyDataFilter

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkPolyData *GetInput ();
   virtual void SetInput (vtkPolyData *input);

=cut

package Graphics::VTK::RectilinearGridSource;


@Graphics::VTK::RectilinearGridSource::ISA = qw( Graphics::VTK::Source );

=head1 Graphics::VTK::RectilinearGridSource

=over 1

=item *

Inherits from Source

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkRectilinearGrid *GetOutput (int idx);
   vtkRectilinearGrid *GetOutput ();
   vtkRectilinearGridSource *New ();
   void SetOutput (vtkRectilinearGrid *output);

=cut

package Graphics::VTK::RectilinearGridToPolyDataFilter;


@Graphics::VTK::RectilinearGridToPolyDataFilter::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::RectilinearGridToPolyDataFilter

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkRectilinearGrid *GetInput ();
   void SetInput (vtkRectilinearGrid *input);

=cut

package Graphics::VTK::ScalarTree;


@Graphics::VTK::ScalarTree::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::ScalarTree

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void BuildTree ();
   int GetBranchingFactor ();
   int GetBranchingFactorMaxValue ();
   int GetBranchingFactorMinValue ();
   const char *GetClassName ();
   vtkDataSet *GetDataSet ();
   int GetLevel ();
   int GetMaxLevel ();
   int GetMaxLevelMaxValue ();
   int GetMaxLevelMinValue ();
   void InitTraversal (float scalarValue);
   void Initialize ();
   vtkScalarTree *New ();
   void SetBranchingFactor (int );
   void SetDataSet (vtkDataSet *);
   void SetMaxLevel (int );


B<vtkScalarTree Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   vtkCell *GetNextCell (long &cellId, vtkIdList &ptIds, vtkDataArray *cellScalars);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::SimpleImageToImageFilter;


@Graphics::VTK::SimpleImageToImageFilter::ISA = qw( Graphics::VTK::ImageSource );

=head1 Graphics::VTK::SimpleImageToImageFilter

=over 1

=item *

Inherits from ImageSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageData *GetInput ();
   virtual void SetInput (vtkImageData *input);


B<vtkSimpleImageToImageFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void ComputeInputUpdateExtent (int inExt[6], int outExt[6]);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::Sphere;


@Graphics::VTK::Sphere::ISA = qw( Graphics::VTK::ImplicitFunction );

=head1 Graphics::VTK::Sphere

=over 1

=item *

Inherits from ImplicitFunction

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   float EvaluateFunction (float x, float y, float z);
   float  *GetCenter ();
      (Returns a 3-element Perl list)
   const char *GetClassName ();
   float GetRadius ();
   vtkSphere *New ();
   void SetCenter (float , float , float );
   void SetRadius (float );


B<vtkSphere Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   float EvaluateFunction (float x[3]);
      Method is redundant. Same as EvaluateFunction( float, float, float)

   void EvaluateGradient (float x[3], float n[3]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetCenter (float  a[3]);
      Method is redundant. Same as SetCenter( float, float, float)


=cut

package Graphics::VTK::Spline;


@Graphics::VTK::Spline::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::Spline

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddPoint (float t, float x);
   void ClampValueOff ();
   void ClampValueOn ();
   void ClosedOff ();
   void ClosedOn ();
   virtual void Compute () = 0;
   int GetClampValue ();
   const char *GetClassName ();
   int GetClosed ();
   int GetLeftConstraint ();
   int GetLeftConstraintMaxValue ();
   int GetLeftConstraintMinValue ();
   float GetLeftValue ();
   unsigned long GetMTime ();
   int GetRightConstraint ();
   int GetRightConstraintMaxValue ();
   int GetRightConstraintMinValue ();
   float GetRightValue ();
   void RemoveAllPoints ();
   void RemovePoint (float t);
   void SetClampValue (int );
   void SetClosed (int );
   void SetLeftConstraint (int );
   void SetLeftValue (float );
   void SetRightConstraint (int );
   void SetRightValue (float );


B<vtkSpline Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::StructuredGridSource;


@Graphics::VTK::StructuredGridSource::ISA = qw( Graphics::VTK::Source );

=head1 Graphics::VTK::StructuredGridSource

=over 1

=item *

Inherits from Source

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkStructuredGrid *GetOutput (int idx);
   vtkStructuredGrid *GetOutput ();
   vtkStructuredGridSource *New ();
   void SetOutput (vtkStructuredGrid *output);

=cut

package Graphics::VTK::StructuredGridToPolyDataFilter;


@Graphics::VTK::StructuredGridToPolyDataFilter::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::StructuredGridToPolyDataFilter

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkStructuredGrid *GetInput ();
   void SetInput (vtkStructuredGrid *input);

=cut

package Graphics::VTK::StructuredGridToStructuredGridFilter;


@Graphics::VTK::StructuredGridToStructuredGridFilter::ISA = qw( Graphics::VTK::StructuredGridSource );

=head1 Graphics::VTK::StructuredGridToStructuredGridFilter

=over 1

=item *

Inherits from StructuredGridSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkStructuredGrid *GetInput ();
   void SetInput (vtkStructuredGrid *input);

=cut

package Graphics::VTK::StructuredPointsCollection;


@Graphics::VTK::StructuredPointsCollection::ISA = qw( Graphics::VTK::Collection );

=head1 Graphics::VTK::StructuredPointsCollection

=over 1

=item *

Inherits from Collection

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddItem (vtkStructuredPoints *ds);
   const char *GetClassName ();
   vtkStructuredPoints *GetNextItem ();
   vtkStructuredPointsCollection *New ();

=cut

package Graphics::VTK::StructuredPointsSource;


@Graphics::VTK::StructuredPointsSource::ISA = qw( Graphics::VTK::Source );

=head1 Graphics::VTK::StructuredPointsSource

=over 1

=item *

Inherits from Source

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkStructuredPoints *GetOutput (int idx);
   vtkStructuredPoints *GetOutput ();
   vtkStructuredPointsSource *New ();
   void SetOutput (vtkStructuredPoints *output);

=cut

package Graphics::VTK::StructuredPointsToPolyDataFilter;


@Graphics::VTK::StructuredPointsToPolyDataFilter::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::StructuredPointsToPolyDataFilter

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageData *GetInput ();
   void SetInput (vtkImageData *input);

=cut

package Graphics::VTK::StructuredPointsToStructuredPointsFilter;


@Graphics::VTK::StructuredPointsToStructuredPointsFilter::ISA = qw( Graphics::VTK::StructuredPointsSource );

=head1 Graphics::VTK::StructuredPointsToStructuredPointsFilter

=over 1

=item *

Inherits from StructuredPointsSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageData *GetInput ();
   void SetInput (vtkImageData *input);

=cut

package Graphics::VTK::StructuredPointsToUnstructuredGridFilter;


@Graphics::VTK::StructuredPointsToUnstructuredGridFilter::ISA = qw( Graphics::VTK::UnstructuredGridSource );

=head1 Graphics::VTK::StructuredPointsToUnstructuredGridFilter

=over 1

=item *

Inherits from UnstructuredGridSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageData *GetInput ();
   void SetInput (vtkImageData *input);

=cut

package Graphics::VTK::Superquadric;


@Graphics::VTK::Superquadric::ISA = qw( Graphics::VTK::ImplicitFunction );

=head1 Graphics::VTK::Superquadric

=over 1

=item *

Inherits from ImplicitFunction

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   float EvaluateFunction (float x, float y, float z);
   float  *GetCenter ();
      (Returns a 3-element Perl list)
   const char *GetClassName ();
   float GetPhiRoundness ();
   float  *GetScale ();
      (Returns a 3-element Perl list)
   float GetSize ();
   float GetThetaRoundness ();
   float GetThickness ();
   float GetThicknessMaxValue ();
   float GetThicknessMinValue ();
   int GetToroidal ();
   vtkSuperquadric *New ();
   void SetCenter (float , float , float );
   void SetPhiRoundness (float e);
   void SetScale (float , float , float );
   void SetSize (float );
   void SetThetaRoundness (float e);
   void SetThickness (float );
   void SetToroidal (int );
   void ToroidalOff ();
   void ToroidalOn ();


B<vtkSuperquadric Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   float EvaluateFunction (float x[3]);
      Method is redundant. Same as EvaluateFunction( float, float, float)

   void EvaluateGradient (float x[3], float g[3]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetCenter (float  a[3]);
      Method is redundant. Same as SetCenter( float, float, float)

   void SetScale (float  a[3]);
      Method is redundant. Same as SetScale( float, float, float)


=cut

package Graphics::VTK::UnstructuredGridSource;


@Graphics::VTK::UnstructuredGridSource::ISA = qw( Graphics::VTK::Source );

=head1 Graphics::VTK::UnstructuredGridSource

=over 1

=item *

Inherits from Source

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkUnstructuredGrid *GetOutput (int idx);
   vtkUnstructuredGrid *GetOutput ();
   vtkUnstructuredGridSource *New ();
   void SetOutput (vtkUnstructuredGrid *output);

=cut

package Graphics::VTK::UnstructuredGridToPolyDataFilter;


@Graphics::VTK::UnstructuredGridToPolyDataFilter::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::UnstructuredGridToPolyDataFilter

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual void ComputeInputUpdateExtents (vtkDataObject *output);
   const char *GetClassName ();
   vtkUnstructuredGrid *GetInput ();
   virtual void SetInput (vtkUnstructuredGrid *input);

=cut

package Graphics::VTK::UnstructuredGridToUnstructuredGridFilter;


@Graphics::VTK::UnstructuredGridToUnstructuredGridFilter::ISA = qw( Graphics::VTK::UnstructuredGridSource );

=head1 Graphics::VTK::UnstructuredGridToUnstructuredGridFilter

=over 1

=item *

Inherits from UnstructuredGridSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkUnstructuredGrid *GetInput ();
   void SetInput (vtkUnstructuredGrid *input);

=cut

1;
