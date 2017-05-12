
package Graphics::VTK::Common;
use 5.004;
use strict;
use Carp;

use vars qw/ $VERSION @ISA/;

require DynaLoader;

$VERSION = '4.0.001';

@ISA = qw/ DynaLoader /;

bootstrap Graphics::VTK::Common $VERSION;


=head1 NAME

VTKCommon  - A Perl interface to VTKCommon library

=head1 SYNOPSIS

C<use Graphics::VTK;>
C<use Graphics::VTK::Common;>

=head1 DESCRIPTION

Graphics::VTK::Common is an interface to the Common libaray of the C++ visualization toolkit VTK..

=head1 AUTHOR

Original PerlVTK Package: Roberto De Leo <rdl@math.umd.edu>

Additional Refinements: John Cerney <j-cerney1@raytheon.com>

=cut

package Graphics::VTK::AbstractMapper;


@Graphics::VTK::AbstractMapper::ISA = qw( Graphics::VTK::ProcessObject );

=head1 Graphics::VTK::AbstractMapper

=over 1

=item *

Inherits from ProcessObject

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddClippingPlane (vtkPlane *plane);
   const char *GetClassName ();
   vtkPlaneCollection *GetClippingPlanes ();
   virtual unsigned long GetMTime ();
   static vtkDataArray *GetScalars (vtkDataSet *input, int scalarMode, int arrayAccessMode, int arrayId, const char *arrayName, int &component);
   float GetTimeToDraw ();
   virtual void ReleaseGraphicsResources (vtkWindow *);
   void RemoveAllClippingPlanes ();
   void RemoveClippingPlane (vtkPlane *plane);
   void SetClippingPlanes (vtkPlanes *planes);
   void SetClippingPlanes (vtkPlaneCollection *);
   void ShallowCopy (vtkAbstractMapper *m);


B<vtkAbstractMapper Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::AbstractTransform;


@Graphics::VTK::AbstractTransform::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::AbstractTransform

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual int CircuitCheck (vtkAbstractTransform *transform);
   void DeepCopy (vtkAbstractTransform *);
   const char *GetClassName ();
   vtkAbstractTransform *GetInverse ();
   unsigned long GetMTime ();
   void Identity ();
   virtual void Inverse () = 0;
   virtual vtkAbstractTransform *MakeTransform () = 0;
   void SetInverse (vtkAbstractTransform *transform);
   double *TransformDoublePoint (double x, double y, double z);
      (Returns a 3-element Perl list)
   float *TransformFloatPoint (float x, float y, float z);
      (Returns a 3-element Perl list)
   double *TransformPoint (double x, double y, double z);
      (Returns a 3-element Perl list)
   virtual void TransformPoints (vtkPoints *inPts, vtkPoints *outPts);
   virtual void TransformPointsNormalsVectors (vtkPoints *inPts, vtkPoints *outPts, vtkDataArray *inNms, vtkDataArray *outNms, vtkDataArray *inVrs, vtkDataArray *outVrs);
   void UnRegister (vtkObject *O);
   void Update ();


B<vtkAbstractTransform Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void InternalTransformDerivative (const float in[3], float out[3], float derivative[3][3]) = 0;
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   virtual void InternalTransformDerivative (const double in[3], double out[3], double derivative[3][3]) = 0;
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   virtual void InternalTransformPoint (const float in[3], float out[3]) = 0;
      Don't know the size of pointer arg number 1

   virtual void InternalTransformPoint (const double in[3], double out[3]) = 0;
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   double *TransformDoubleNormalAtPoint (const double point[3], const double normal[3]);
      Don't know the size of pointer arg number 1

   double *TransformDoublePoint (const double point[3]);
      Method is redundant. Same as TransformDoublePoint( double, double, double)

   double *TransformDoubleVectorAtPoint (const double point[3], const double vector[3]);
      Don't know the size of pointer arg number 1

   float *TransformFloatNormalAtPoint (const float point[3], const float normal[3]);
      Don't know the size of pointer arg number 1

   float *TransformFloatPoint (const float point[3]);
      Method is redundant. Same as TransformFloatPoint( float, float, float)

   float *TransformFloatVectorAtPoint (const float point[3], const float vector[3]);
      Don't know the size of pointer arg number 1

   void TransformNormalAtPoint (const float point[3], const float in[3], float out[3]);
      Don't know the size of pointer arg number 1

   void TransformNormalAtPoint (const double point[3], const double in[3], double out[3]);
      Don't know the size of pointer arg number 1

   double *TransformNormalAtPoint (const double point[3], const double normal[3]);
      Don't know the size of pointer arg number 1

   void TransformPoint (const float in[3], float out[3]);
      Don't know the size of pointer arg number 1

   void TransformPoint (const double in[3], double out[3]);
      Don't know the size of pointer arg number 1

   double *TransformPoint (const double point[3]);
      Method is redundant. Same as TransformPoint__( double, double, double)

   void TransformVectorAtPoint (const float point[3], const float in[3], float out[3]);
      Don't know the size of pointer arg number 1

   void TransformVectorAtPoint (const double point[3], const double in[3], double out[3]);
      Don't know the size of pointer arg number 1

   double *TransformVectorAtPoint (const double point[3], const double vector[3]);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::Actor2D;


@Graphics::VTK::Actor2D::ISA = qw( Graphics::VTK::Prop );

=head1 Graphics::VTK::Actor2D

=over 1

=item *

Inherits from Prop

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual void GetActors2D (vtkPropCollection *pc);
   const char *GetClassName ();
   float GetHeight ();
   int GetLayerNumber ();
   unsigned long GetMTime ();
   vtkMapper2D *GetMapper ();
   float *GetPosition ();
      (Returns a 2-element Perl list)
   float *GetPosition2 ();
      (Returns a 2-element Perl list)
   vtkCoordinate *GetPosition2Coordinate ();
   vtkCoordinate *GetPositionCoordinate ();
   vtkProperty2D *GetProperty ();
   float GetWidth ();
   vtkActor2D *New ();
   virtual void ReleaseGraphicsResources (vtkWindow *);
   int RenderOpaqueGeometry (vtkViewport *viewport);
   int RenderOverlay (vtkViewport *viewport);
   int RenderTranslucentGeometry (vtkViewport *viewport);
   void SetDisplayPosition (int , int );
   void SetHeight (float h);
   void SetLayerNumber (int );
   void SetMapper (vtkMapper2D *mapper);
   void SetPosition (float, float);
   void SetPosition2 (float, float);
   void SetProperty (vtkProperty2D *);
   void SetWidth (float w);
   void ShallowCopy (vtkProp *prop);


B<vtkActor2D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetPosition2 (float a[2]);
      Method is redundant. Same as SetPosition2( float, float)

   void SetPosition (float a[2]);
      Method is redundant. Same as SetPosition( float, float)


=cut

package Graphics::VTK::Actor2DCollection;


@Graphics::VTK::Actor2DCollection::ISA = qw( Graphics::VTK::PropCollection );

=head1 Graphics::VTK::Actor2DCollection

=over 1

=item *

Inherits from PropCollection

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddItem (vtkActor2D *a);
   const char *GetClassName ();
   vtkActor2D *GetLastActor2D ();
   vtkActor2D *GetLastItem ();
   vtkActor2D *GetNextActor2D ();
   vtkActor2D *GetNextItem ();
   int IsItemPresent (vtkActor2D *a);
   vtkActor2DCollection *New ();
   void RenderOverlay (vtkViewport *viewport);
   void Sort ();

=cut

package Graphics::VTK::AssemblyNode;


@Graphics::VTK::AssemblyNode::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::AssemblyNode

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   virtual unsigned long GetMTime ();
   vtkMatrix4x4 *GetMatrix ();
   vtkProp *GetProp ();
   vtkAssemblyNode *New ();
   void SetMatrix (vtkMatrix4x4 *matrix);
   void SetProp (vtkProp *prop);


B<vtkAssemblyNode Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::AssemblyPath;


@Graphics::VTK::AssemblyPath::ISA = qw( Graphics::VTK::Collection );

=head1 Graphics::VTK::AssemblyPath

=over 1

=item *

Inherits from Collection

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddNode (vtkProp *p, vtkMatrix4x4 *m);
   void DeleteLastNode ();
   const char *GetClassName ();
   vtkAssemblyNode *GetFirstNode ();
   vtkAssemblyNode *GetLastNode ();
   virtual unsigned long GetMTime ();
   vtkAssemblyNode *GetNextNode ();
   vtkAssemblyPath *New ();
   void ShallowCopy (vtkAssemblyPath *path);


B<vtkAssemblyPath Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::AssemblyPaths;


@Graphics::VTK::AssemblyPaths::ISA = qw( Graphics::VTK::Collection );

=head1 Graphics::VTK::AssemblyPaths

=over 1

=item *

Inherits from Collection

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddItem (vtkAssemblyPath *p);
   const char *GetClassName ();
   virtual unsigned long GetMTime ();
   vtkAssemblyPath *GetNextItem ();
   int IsItemPresent (vtkAssemblyPath *p);
   vtkAssemblyPaths *New ();
   void RemoveItem (vtkAssemblyPath *p);

=cut

package Graphics::VTK::BitArray;


@Graphics::VTK::BitArray::ISA = qw( Graphics::VTK::DataArray );

=head1 Graphics::VTK::BitArray

=over 1

=item *

Inherits from DataArray

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int Allocate (const long sz, const long ext);
   void DeepCopy (vtkDataArray *da);
   const char *GetClassName ();
   int GetDataType ();
   int GetValue (const long id);
   void Initialize ();
   virtual void InsertComponent (const long i, const int j, const float c);
   long InsertNextValue (const int i);
   void InsertValue (const long id, const int i);
   vtkBitArray *New ();
   virtual void Resize (long numTuples);
   void SetComponent (const long i, const int j, const float c);
   void SetNumberOfTuples (const long number);
   void SetNumberOfValues (const long number);
   void SetValue (const long id, const int value);
   void Squeeze ();


B<vtkBitArray Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   unsigned char *GetPointer (const long id);
      Can't Handle 'unsigned char *' return type without a hint

   float *GetTuple (const long i);
      Can't Handle 'float *' return type without a hint

   void GetTuple (const long i, float *tuple);
      Don't know the size of pointer arg number 2

   void GetTuple (const long i, double *tuple);
      Don't know the size of pointer arg number 2

   void *GetVoidPointer (const long id);
      Can't Handle 'void *' return type without a hint

   long InsertNextTuple (const float *tuple);
      Don't know the size of pointer arg number 1

   long InsertNextTuple (const double *tuple);
      Don't know the size of pointer arg number 1

   void InsertTuple (const long i, const float *tuple);
      Don't know the size of pointer arg number 2

   void InsertTuple (const long i, const double *tuple);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   unsigned char *ResizeAndExtend (const long sz);
      Can't Handle 'unsigned char *' return type without a hint

   void SetArray (unsigned char *array, long size, int save);
      Don't know the size of pointer arg number 1

   void SetTuple (const long i, const float *tuple);
      Don't know the size of pointer arg number 2

   void SetTuple (const long i, const double *tuple);
      Don't know the size of pointer arg number 2

   void SetVoidArray (void *array, long size, int save);
      Don't know the size of pointer arg number 1

   unsigned char *WritePointer (const long id, const long number);
      Can't Handle 'unsigned char *' return type without a hint


=cut

package Graphics::VTK::ByteSwap;


@Graphics::VTK::ByteSwap::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::ByteSwap

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkByteSwap *New ();
   static void Swap2BERange (char *c, int num);
   static void Swap2LERange (char *c, int num);
   static void Swap4BE (char *c);
   static void Swap4BERange (char *c, int num);
   static void Swap4LE (char *c);
   static void Swap4LERange (char *c, int num);
   static void Swap8BE (char *c);
   static void Swap8BERange (char *c, int num);
   static void Swap8LE (char *c);
   static void Swap8LERange (char *c, int num);


B<vtkByteSwap Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   static void Swap2BE (short *s);
      Don't know the size of pointer arg number 1

   static void Swap2BERange (short *i, int num);
      Don't know the size of pointer arg number 1

   static void Swap2BE (unsigned short *s);
      Don't know the size of pointer arg number 1

   static void Swap2LE (short *s);
      Don't know the size of pointer arg number 1

   static void Swap2LERange (short *i, int num);
      Don't know the size of pointer arg number 1

   static void Swap2LE (unsigned short *s);
      Don't know the size of pointer arg number 1

   static void Swap4BERange (float *p, int num);
      Don't know the size of pointer arg number 1

   static void Swap4BERange (int *i, int num);
      Don't know the size of pointer arg number 1

   static void Swap4BERange (unsigned long *i, int num);
      Don't know the size of pointer arg number 1

   static void Swap4BERange (long *i, int num);
      Don't know the size of pointer arg number 1

   static void Swap4BE (float *p);
      Don't know the size of pointer arg number 1

   static void Swap4BE (int *i);
      Don't know the size of pointer arg number 1

   static void Swap4BE (unsigned long *i);
      Don't know the size of pointer arg number 1

   static void Swap4LERange (unsigned char *c, int num);
      Don't know the size of pointer arg number 1

   static void Swap4LERange (float *p, int num);
      Don't know the size of pointer arg number 1

   static void Swap4LERange (int *i, int num);
      Don't know the size of pointer arg number 1

   static void Swap4LERange (unsigned long *i, int num);
      Don't know the size of pointer arg number 1

   static void Swap4LE (float *p);
      Don't know the size of pointer arg number 1

   static void Swap4LE (int *i);
      Don't know the size of pointer arg number 1

   static void Swap4LE (unsigned long *i);
      Don't know the size of pointer arg number 1

   static void Swap4LE (long *i);
      Don't know the size of pointer arg number 1

   static void Swap8BERange (double *d, int num);
      Don't know the size of pointer arg number 1

   static void Swap8BE (double *d);
      Don't know the size of pointer arg number 1

   static void Swap8LERange (double *d, int num);
      Don't know the size of pointer arg number 1

   static void Swap8LE (double *d);
      Don't know the size of pointer arg number 1

   static void SwapVoidRange (void *buffer, int numWords, int wordSize);
      Don't know the size of pointer arg number 1

   static void SwapWrite2BERange (char *c, int num, FILE *fp);
      Don't know the size of pointer arg number 3

   static void SwapWrite2BERange (short *i, int num, FILE *fp);
      Don't know the size of pointer arg number 1

   static void SwapWrite2BERange (char *c, int num, ostream *fp);
      I/O Streams not Supported yet

   static void SwapWrite2BERange (short *i, int num, ostream *fp);
      I/O Streams not Supported yet

   static void SwapWrite4BERange (char *c, int num, FILE *fp);
      Don't know the size of pointer arg number 3

   static void SwapWrite4BERange (float *p, int num, FILE *fp);
      Don't know the size of pointer arg number 1

   static void SwapWrite4BERange (int *i, int num, FILE *fp);
      Don't know the size of pointer arg number 1

   static void SwapWrite4BERange (unsigned long *i, int num, FILE *fp);
      Don't know the size of pointer arg number 1

   static void SwapWrite4BERange (long *i, int num, FILE *fp);
      Don't know the size of pointer arg number 1

   static void SwapWrite4BERange (char *c, int num, ostream *fp);
      I/O Streams not Supported yet

   static void SwapWrite4BERange (float *p, int num, ostream *fp);
      I/O Streams not Supported yet

   static void SwapWrite4BERange (int *i, int num, ostream *fp);
      I/O Streams not Supported yet

   static void SwapWrite4BERange (unsigned long *i, int num, ostream *fp);
      I/O Streams not Supported yet

   static void SwapWrite4BERange (long *i, int num, ostream *fp);
      I/O Streams not Supported yet

   static void SwapWrite8BERange (char *c, int num, FILE *fp);
      Don't know the size of pointer arg number 3

   static void SwapWrite8BERange (double *d, int num, FILE *fp);
      Don't know the size of pointer arg number 1

   static void SwapWrite8BERange (char *c, int num, ostream *fp);
      I/O Streams not Supported yet

   static void SwapWrite8BERange (double *d, int num, ostream *fp);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::Cell;


@Graphics::VTK::Cell::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::Cell

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual void Clip (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *connectivity, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd, int insideOut) = 0;
   virtual void Contour (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *verts, vtkCellArray *lines, vtkCellArray *polys, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd) = 0;
   virtual void DeepCopy (vtkCell *c);
   float *GetBounds ();
      (Returns a 6-element Perl list)
   virtual int GetCellDimension () = 0;
   virtual int GetCellType () = 0;
   const char *GetClassName ();
   virtual vtkCell *GetEdge (int edgeId) = 0;
   virtual vtkCell *GetFace (int faceId) = 0;
   virtual int GetInterpolationOrder ();
   float GetLength2 ();
   virtual int GetNumberOfEdges () = 0;
   virtual int GetNumberOfFaces () = 0;
   int GetNumberOfPoints ();
   long GetPointId (int ptId);
   vtkIdList *GetPointIds ();
   vtkPoints *GetPoints ();
   virtual void ShallowCopy (vtkCell *c);
   virtual int Triangulate (int index, vtkIdList *ptIds, vtkPoints *pts) = 0;


B<vtkCell Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual int CellBoundary (int subId, float pcoords[3], vtkIdList *pts) = 0;
      Don't know the size of pointer arg number 2

   virtual void Derivatives (int subId, float pcoords[3], float *values, int dim, float *derivs) = 0;
      Don't know the size of pointer arg number 2

   virtual void EvaluateLocation (int &subId, float pcoords[3], float x[3], float *weights) = 0;
      Don't know the size of pointer arg number 2

   virtual int EvaluatePosition (float x[3], float *closestPoint, int &subId, float pcoords[3], float &dist2, float *weights) = 0;
      Don't know the size of pointer arg number 1

   void GetBounds (float bounds[6]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   virtual int GetParametricCenter (float pcoords[3]);
      Can't handle methods with single array args (like a[3]) yet.

   static char HitBBox (float bounds[6], float origin[3], float dir[3], float coord[3], float &t);
      Don't know the size of pointer arg number 1

   void Initialize (int npts, long *pts, vtkPoints *p);
      Don't know the size of pointer arg number 2

   virtual int IntersectWithLine (float p1[3], float p2[3], float tol, float &t, float x[3], float pcoords[3], int &subId) = 0;
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::Cell3D;


@Graphics::VTK::Cell3D::ISA = qw( Graphics::VTK::Cell );

=head1 Graphics::VTK::Cell3D

=over 1

=item *

Inherits from Cell

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual void Clip (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *connectivity, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd, int insideOut);
   virtual int GetCellDimension ();
   const char *GetClassName ();


B<vtkCell3D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void GetEdgePoints (int edgeId, int &pts) = 0;
      Don't know the size of pointer arg number 2

   virtual void GetFacePoints (int faceId, int &pts) = 0;
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::CellArray;


@Graphics::VTK::CellArray::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::CellArray

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int Allocate (const long sz, const int ext);
   void DeepCopy (vtkCellArray *ca);
   long EstimateSize (long numCells, int maxPtsPerCell);
   unsigned long GetActualMemorySize ();
   const char *GetClassName ();
   vtkDataArray *GetData ();
   long GetInsertLocation (int npts);
   int GetMaxCellSize ();
   long GetNumberOfCells ();
   long GetNumberOfConnectivityEntries ();
   long GetSize ();
   long GetTraversalLocation (long npts);
   long GetTraversalLocation ();
   void InitTraversal ();
   void Initialize ();
   void InsertCellPoint (long id);
   long InsertNextCell (vtkIdList *pts);
   long InsertNextCell (vtkCell *cell);
   long InsertNextCell (int npts);
   vtkCellArray *New ();
   void Reset ();
   void ReverseCell (long loc);
   void SetCells (long ncells, vtkIdTypeArray *cells);
   void SetTraversalLocation (long loc);
   void Squeeze ();
   void UpdateCellCount (int npts);


B<vtkCellArray Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void GetCell (long loc, long &npts, long &pts);
      Don't know the size of pointer arg number 2

   int GetNextCell (long &npts, long &pts);
      Don't know the size of pointer arg number 1

   long *GetPointer ();
      Can't Handle 'long *' return type without a hint

   long InsertNextCell (long npts, long *pts);
      Don't know the size of pointer arg number 2

   void ReplaceCell (long loc, int npts, long *pts);
      Don't know the size of pointer arg number 3

   long *WritePointer (const long ncells, const long size);
      Can't Handle 'long *' return type without a hint


=cut

package Graphics::VTK::CellData;


@Graphics::VTK::CellData::ISA = qw( Graphics::VTK::DataSetAttributes );

=head1 Graphics::VTK::CellData

=over 1

=item *

Inherits from DataSetAttributes

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkCellData *New ();


B<vtkCellData Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::CellLinks;


@Graphics::VTK::CellLinks::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::CellLinks

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddCellReference (long cellId, long ptId);
   void Allocate (long numLinks, long ext);
   void BuildLinks (vtkDataSet *data, vtkCellArray *Connectivity);
   void BuildLinks (vtkDataSet *data);
   void DeepCopy (vtkCellLinks *src);
   void DeletePoint (long ptId);
   unsigned long GetActualMemorySize ();
   const char *GetClassName ();
   unsigned short GetNcells (long ptId);
   void InsertNextCellReference (long ptId, long cellId);
   long InsertNextPoint (int numLinks);
   vtkLink_s unsigned short ncells long cells static vtkCellLinks *New ();
   void RemoveCellReference (long cellId, long ptId);
   void Reset ();
   void ResizeCellList (long ptId, int size);
   void Squeeze ();


B<vtkCellLinks Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   long *GetCells (long ptId);
      Can't Handle 'long *' return type without a hint

   _vtkLink_s &GetLink (long ptId);
      Can't Handle _vtkLink_s return type yet

   _vtkLink_s *Resize (long sz);
      Can't Handle _vtkLink_s return type yet


=cut

package Graphics::VTK::CellTypes;


@Graphics::VTK::CellTypes::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::CellTypes

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int Allocate (int sz, int ext);
   void DeepCopy (vtkCellTypes *src);
   void DeleteCell (int cellId);
   unsigned long GetActualMemorySize ();
   int GetCellLocation (int cellId);
   unsigned char GetCellType (int cellId);
   const char *GetClassName ();
   int GetNumberOfTypes ();
   void InsertCell (int id, unsigned char type, int loc);
   int InsertNextCell (unsigned char type, int loc);
   int InsertNextType (unsigned char type);
   int IsType (unsigned char type);
   vtkCellTypes *New ();
   void Reset ();
   void SetCellTypes (int ncells, vtkUnsignedCharArray *cellTypes, vtkIntArray *cellLocations);
   void Squeeze ();

=cut

package Graphics::VTK::CharArray;


@Graphics::VTK::CharArray::ISA = qw( Graphics::VTK::DataArray );

=head1 Graphics::VTK::CharArray

=over 1

=item *

Inherits from DataArray

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int Allocate (const long sz, const long ext);
   void DeepCopy (vtkDataArray *ia);
   const char *GetClassName ();
   float GetComponent (const long i, const int j);
   int GetDataType ();
   char *GetPointer (const long id);
   char GetValue (const long id);
   void Initialize ();
   void InsertComponent (const long i, const int j, const float c);
   long InsertNextValue (const char c);
   void InsertValue (const long id, const char c);
   vtkCharArray *New ();
   virtual void Resize (long numTuples);
   void SetArray (char *array, long size, int save);
   void SetComponent (const long i, const int j, const float c);
   void SetNumberOfTuples (const long number);
   void SetNumberOfValues (const long number);
   void SetValue (const long id, const char value);
   void Squeeze ();
   char *WritePointer (const long id, const long number);


B<vtkCharArray Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   float *GetTuple (const long i);
      Can't Handle 'float *' return type without a hint

   void GetTuple (const long i, float *tuple);
      Don't know the size of pointer arg number 2

   void GetTuple (const long i, double *tuple);
      Don't know the size of pointer arg number 2

   void *GetVoidPointer (const long id);
      Can't Handle 'void *' return type without a hint

   long InsertNextTuple (const float *tuple);
      Don't know the size of pointer arg number 1

   long InsertNextTuple (const double *tuple);
      Don't know the size of pointer arg number 1

   void InsertTuple (const long i, const float *tuple);
      Don't know the size of pointer arg number 2

   void InsertTuple (const long i, const double *tuple);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetTuple (const long i, const float *tuple);
      Don't know the size of pointer arg number 2

   void SetTuple (const long i, const double *tuple);
      Don't know the size of pointer arg number 2

   void SetVoidArray (void *array, long size, int save);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::Collection;


@Graphics::VTK::Collection::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::Collection

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddItem (vtkObject *);
   const char *GetClassName ();
   vtkObject *GetItemAsObject (int i);
   vtkObject *GetNextItemAsObject ();
   int GetNumberOfItems ();
   void InitTraversal ();
   int IsItemPresent (vtkObject *);
   vtkCollection *New ();
   void RemoveAllItems ();
   void RemoveItem (vtkObject *);
   void RemoveItem (int i);
   void ReplaceItem (int i, vtkObject *);


B<vtkCollection Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ContourValues;


@Graphics::VTK::ContourValues::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::ContourValues

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void GenerateValues (int numContours, float rangeStart, float rangeEnd);
   const char *GetClassName ();
   int GetNumberOfContours ();
   float GetValue (int i);
   vtkContourValues *New ();
   void SetNumberOfContours (const int number);
   void SetValue (int i, float value);


B<vtkContourValues Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void GenerateValues (int numContours, float range[2]);
      Don't know the size of pointer arg number 2

   float *GetValues ();
      Can't Handle 'float *' return type without a hint

   void GetValues (float *contourValues);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::Coordinate;


@Graphics::VTK::Coordinate::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::Coordinate

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int *GetComputedDisplayValue (vtkViewport *);
      (Returns a 2-element Perl list)
   float *GetComputedFloatDisplayValue (vtkViewport *);
      (Returns a 2-element Perl list)
   float *GetComputedFloatViewportValue (vtkViewport *);
      (Returns a 2-element Perl list)
   int *GetComputedLocalDisplayValue (vtkViewport *);
      (Returns a 2-element Perl list)
   int *GetComputedViewportValue (vtkViewport *);
      (Returns a 2-element Perl list)
   float *GetComputedWorldValue (vtkViewport *);
      (Returns a 3-element Perl list)
   int GetCoordinateSystem ();
   const char *GetCoordinateSystemAsString ();
   vtkCoordinate *GetReferenceCoordinate ();
   float  *GetValue ();
      (Returns a 3-element Perl list)
   vtkViewport *GetViewport ();
   vtkCoordinate *New ();
   void SetCoordinateSystem (int );
   void SetCoordinateSystemToDisplay ();
   void SetCoordinateSystemToNormalizedDisplay ();
   void SetCoordinateSystemToNormalizedViewport ();
   void SetCoordinateSystemToView ();
   void SetCoordinateSystemToViewport ();
   void SetCoordinateSystemToWorld ();
   void SetReferenceCoordinate (vtkCoordinate *);
   void SetValue (float , float , float );
   void SetValue (float a, float b);
   void SetViewport (vtkViewport *viewport);


B<vtkCoordinate Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual float *GetComputedUserDefinedValue (vtkViewport *);
      Can't Handle 'float *' return type without a hint

   float *GetComputedValue (vtkViewport *);
      Can't Handle 'float *' return type without a hint

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetValue (float  a[3]);
      Method is redundant. Same as SetValue( float, float, float)


=cut

package Graphics::VTK::CriticalSection;


@Graphics::VTK::CriticalSection::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::CriticalSection

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   void Lock (void );
   vtkCriticalSection *New ();
   void Unlock (void );


B<vtkCriticalSection Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::DataArray;


@Graphics::VTK::DataArray::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::DataArray

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual int Allocate (const long sz, const long ext) = 0;
   virtual void ComputeRange (int comp);
   virtual void CopyComponent (const int j, vtkDataArray *from, const int fromComponent);
   static vtkDataArray *CreateDataArray (int dataType);
   void CreateDefaultLookupTable ();
   virtual void DeepCopy (vtkDataArray *da);
   virtual void FillComponent (const int j, const float c);
   unsigned long GetActualMemorySize ();
   const char *GetClassName ();
   virtual float GetComponent (const long i, const int j);
   virtual void GetData (long tupleMin, long tupleMax, int compMin, int compMax, vtkFloatArray *data);
   virtual int GetDataType () = 0;
   double GetDataTypeMax ();
   double GetDataTypeMin ();
   vtkLookupTable *GetLookupTable ();
   long GetMaxId ();
   virtual float GetMaxNorm ();
   const char *GetName ();
   int GetNumberOfComponents ();
   int GetNumberOfComponentsMaxValue ();
   int GetNumberOfComponentsMinValue ();
   long GetNumberOfTuples ();
   float *GetRange (int comp);
      (Returns a 2-element Perl list)
   float *GetRange ();
      (Returns a 2-element Perl list)
   long GetSize ();
   float GetTuple1 (const long i);
   float *GetTuple2 (const long i);
      (Returns a 2-element Perl list)
   float *GetTuple3 (const long i);
      (Returns a 3-element Perl list)
   float *GetTuple4 (const long i);
      (Returns a 4-element Perl list)
   float *GetTuple9 (const long i);
      (Returns a 9-element Perl list)
   void GetTuples (long p1, long p2, vtkDataArray *output);
   void GetTuples (vtkIdList *ptIds, vtkDataArray *output);
   virtual void Initialize () = 0;
   virtual void InsertComponent (const long i, const int j, const float c);
   void InsertNextTuple1 (float value);
   void InsertNextTuple2 (float val0, float val1);
   void InsertNextTuple3 (float val0, float val1, float val2);
   void InsertNextTuple4 (float val0, float val1, float val2, float val3);
   void InsertNextTuple9 (float val0, float val1, float val2, float val3, float val4, float val5, float val6, float val7, float val8);
   void InsertTuple1 (const long i, float value);
   void InsertTuple2 (const long i, float val0, float val1);
   void InsertTuple3 (const long i, float val0, float val1, float val2);
   void InsertTuple4 (const long i, float val0, float val1, float val2, float val3);
   void InsertTuple9 (const long i, float val0, float val1, float val2, float val3, float val4, float val5, float val6, float val7, float val8);
   void Reset ();
   virtual void Resize (long numTuples) = 0;
   virtual void SetComponent (const long i, const int j, const float c);
   void SetLookupTable (vtkLookupTable *lut);
   void SetName (const char *name);
   void SetNumberOfComponents (int );
   virtual void SetNumberOfTuples (const long number) = 0;
   void SetTuple1 (const long i, float value);
   void SetTuple2 (const long i, float val0, float val1);
   void SetTuple3 (const long i, float val0, float val1, float val2);
   void SetTuple4 (const long i, float val0, float val1, float val2, float val3);
   void SetTuple9 (const long i, float val0, float val1, float val2, float val3, float val4, float val5, float val6, float val7, float val8);
   virtual void Squeeze () = 0;


B<vtkDataArray Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void GetDataTypeRange (double range[2]);
      Can't handle methods with single array args (like a[3]) yet.

   void GetRange (float range[2], int comp);
      Don't know the size of pointer arg number 1

   void GetRange (float range[2]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   virtual float *GetTuple (const long i) = 0;
      Can't Handle 'float *' return type without a hint

   float *GetTupleN (const long i, int n);
      Can't Handle 'float *' return type without a hint

   virtual void GetTuple (const long i, float *tuple) = 0;
      Don't know the size of pointer arg number 2

   virtual void GetTuple (const long i, double *tuple);
      Don't know the size of pointer arg number 2

   virtual void *GetVoidPointer (const long id) = 0;
      Can't Handle 'void *' return type without a hint

   virtual long InsertNextTuple (const float *tuple) = 0;
      Don't know the size of pointer arg number 1

   virtual long InsertNextTuple (const double *tuple);
      Don't know the size of pointer arg number 1

   virtual void InsertTuple (const long i, const float *tuple) = 0;
      Don't know the size of pointer arg number 2

   virtual void InsertTuple (const long i, const double *tuple);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   virtual void SetTuple (const long i, const float *tuple) = 0;
      Don't know the size of pointer arg number 2

   virtual void SetTuple (const long i, const double *tuple);
      Don't know the size of pointer arg number 2

   virtual void SetVoidArray (void *, long , int );
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::DataObject;


@Graphics::VTK::DataObject::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::DataObject

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddConsumer (vtkProcessObject *c);
   void CopyInformation (vtkDataObject *data);
   virtual void CopyTypeSpecificInformation (vtkDataObject *data);
   void DataHasBeenGenerated ();
   virtual void DeepCopy (vtkDataObject *src);
   virtual unsigned long GetActualMemorySize ();
   const char *GetClassName ();
   vtkProcessObject *GetConsumer (int i);
   virtual int GetDataObjectType ();
   int GetDataReleased ();
   virtual unsigned long GetEstimatedMemorySize ();
   vtkExtentTranslator *GetExtentTranslator ();
   vtkFieldData *GetFieldData ();
   static int GetGlobalReleaseDataFlag ();
   float GetLocality ();
   unsigned long GetMTime ();
   int GetMaximumNumberOfPieces ();
   virtual int GetNetReferenceCount ();
   int GetNumberOfConsumers ();
   long unsigned GetPipelineMTime ();
   int GetReleaseDataFlag ();
   int GetRequestExactExtent ();
   vtkSource *GetSource ();
   int  *GetUpdateExtent ();
      (Returns a 6-element Perl list)
   int GetUpdateGhostLevel ();
   int GetUpdateNumberOfPieces ();
   int GetUpdatePiece ();
   unsigned long GetUpdateTime ();
   int  *GetWholeExtent ();
      (Returns a 6-element Perl list)
   void GlobalReleaseDataFlagOff ();
   void GlobalReleaseDataFlagOn ();
   virtual void Initialize ();
   int IsConsumer (vtkProcessObject *c);
   vtkDataObject *New ();
   virtual void PrepareForNewData ();
   virtual void PropagateUpdateExtent ();
   void ReleaseData ();
   void ReleaseDataFlagOff ();
   void ReleaseDataFlagOn ();
   void RemoveConsumer (vtkProcessObject *c);
   void RequestExactExtentOff ();
   void RequestExactExtentOn ();
   void SetExtentTranslator (vtkExtentTranslator *translator);
   void SetFieldData (vtkFieldData *);
   static void SetGlobalReleaseDataFlag (int val);
   void SetLocality (float );
   void SetMaximumNumberOfPieces (int );
   void SetPipelineMTime (unsigned long time);
   void SetReleaseDataFlag (int );
   void SetRequestExactExtent (int v);
   void SetSource (vtkSource *s);
   virtual void SetUpdateExtent (int x1, int x2, int y1, int y2, int z1, int z2);
   virtual void SetUpdateExtent (int , int , int );
   void SetUpdateExtent (int piece, int numPieces);
   void SetUpdateExtentToWholeExtent ();
   void SetUpdateGhostLevel (int level);
   void SetUpdateNumberOfPieces (int num);
   void SetUpdatePiece (int piece);
   void SetWholeExtent (int , int , int , int , int , int );
   virtual void ShallowCopy (vtkDataObject *src);
   int ShouldIReleaseData ();
   virtual void TriggerAsynchronousUpdate ();
   void UnRegister (vtkObject *o);
   virtual void Update ();
   virtual void UpdateData ();
   virtual void UpdateInformation ();


B<vtkDataObject Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   virtual void SetUpdateExtent (int ext[6]);
      Method is redundant. Same as SetUpdateExtent( int, int, int, int, int, int)

   void SetWholeExtent (int  a[6]);
      Method is redundant. Same as SetWholeExtent( int, int, int, int, int, int)


=cut

package Graphics::VTK::DataObjectCollection;


@Graphics::VTK::DataObjectCollection::ISA = qw( Graphics::VTK::Collection );

=head1 Graphics::VTK::DataObjectCollection

=over 1

=item *

Inherits from Collection

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddItem (vtkDataObject *ds);
   const char *GetClassName ();
   vtkDataObject *GetItem (int i);
   vtkDataObject *GetNextItem ();
   vtkDataObjectCollection *New ();

=cut

package Graphics::VTK::DataSet;


@Graphics::VTK::DataSet::ISA = qw( Graphics::VTK::DataObject );

=head1 Graphics::VTK::DataSet

=over 1

=item *

Inherits from DataObject

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual void ComputeBounds ();
   virtual void CopyStructure (vtkDataSet *ds) = 0;
   void DeepCopy (vtkDataObject *src);
   long FindPoint (float x, float y, float z);
   unsigned long GetActualMemorySize ();
   float *GetBounds ();
      (Returns a 6-element Perl list)
   virtual void GetCell (long cellId, vtkGenericCell *cell) = 0;
   virtual vtkCell *GetCell (long cellId) = 0;
   vtkCellData *GetCellData ();
   virtual void GetCellNeighbors (long cellId, vtkIdList *ptIds, vtkIdList *cellIds);
   virtual void GetCellPoints (long cellId, vtkIdList *ptIds) = 0;
   virtual int GetCellType (long cellId) = 0;
   virtual void GetCellTypes (vtkCellTypes *types);
   float *GetCenter ();
      (Returns a 3-element Perl list)
   const char *GetClassName ();
   int GetDataObjectType ();
   float GetLength ();
   unsigned long GetMTime ();
   virtual int GetMaxCellSize () = 0;
   virtual long GetNumberOfCells () = 0;
   virtual long GetNumberOfPoints () = 0;
   virtual float *GetPoint (long ptId) = 0;
      (Returns a 3-element Perl list)
   virtual void GetPointCells (long ptId, vtkIdList *cellIds) = 0;
   vtkPointData *GetPointData ();
   float *GetScalarRange ();
      (Returns a 2-element Perl list)
   void Initialize ();
   void ShallowCopy (vtkDataObject *src);
   virtual void Squeeze ();


B<vtkDataSet Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual vtkCell *FindAndGetCell (float x[3], vtkCell *cell, long cellId, float tol2, int &subId, float pcoords[3], float *weights);
      Don't know the size of pointer arg number 1

   virtual long FindCell (float x[3], vtkCell *cell, long cellId, float tol2, int &subId, float pcoords[3], float *weights) = 0;
      Don't know the size of pointer arg number 1

   virtual long FindCell (float x[3], vtkCell *cell, vtkGenericCell *gencell, long cellId, float tol2, int &subId, float pcoords[3], float *weights) = 0;
      Don't know the size of pointer arg number 1

   virtual long FindPoint (float x[3]) = 0;
      Method is redundant. Same as FindPoint( float, float, float)

   void GetBounds (float bounds[6]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   virtual void GetCellBounds (long cellId, float bounds[6]);
      Don't know the size of pointer arg number 2

   void GetCenter (float center[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   virtual void GetPoint (long id, float x[3]);
      Don't know the size of pointer arg number 2

   virtual void GetScalarRange (float range[2]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::DataSetAttributes;


@Graphics::VTK::DataSetAttributes::ISA = qw( Graphics::VTK::FieldData );

=head1 Graphics::VTK::DataSetAttributes

=over 1

=item *

Inherits from FieldData

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual void CopyAllOff ();
   virtual void CopyAllOn ();
   void CopyAllocate (vtkDataSetAttributes *pd, long sze, long ext);
   void CopyData (vtkDataSetAttributes *fromPd, long fromId, long toId);
   void CopyNormalsOff ();
   void CopyNormalsOn ();
   void CopyScalarsOff ();
   void CopyScalarsOn ();
   void CopyTCoordsOff ();
   void CopyTCoordsOn ();
   void CopyTensorsOff ();
   void CopyTensorsOn ();
   void CopyTuple (vtkDataArray *fromData, vtkDataArray *toData, long fromId, long toId);
   void CopyVectorsOff ();
   void CopyVectorsOn ();
   virtual void DeepCopy (vtkFieldData *pd);
   vtkDataArray *GetAttribute (int attributeType);
   const char *GetClassName ();
   int GetCopyNormals ();
   int GetCopyScalars ();
   int GetCopyTCoords ();
   int GetCopyTensors ();
   int GetCopyVectors ();
   vtkDataArray *GetNormals ();
   vtkDataArray *GetScalars ();
   vtkDataArray *GetTCoords ();
   vtkDataArray *GetTensors ();
   vtkDataArray *GetVectors ();
   virtual void Initialize ();
   void InterpolateAllocate (vtkDataSetAttributes *pd, long sze, long ext);
   void InterpolateEdge (vtkDataSetAttributes *fromPd, long toId, long p1, long p2, float t);
   void InterpolateTime (vtkDataSetAttributes *from1, vtkDataSetAttributes *from2, long id, float t);
   int IsArrayAnAttribute (int idx);
   vtkDataSetAttributes *New ();
   virtual void PassData (vtkFieldData *fd);
   virtual void RemoveArray (const char *name);
   int SetActiveAttribute (const char *name, int attributeType);
   int SetActiveAttribute (int index, int attributeType);
   int SetActiveNormals (const char *name);
   int SetActiveScalars (const char *name);
   int SetActiveTCoords (const char *name);
   int SetActiveTensors (const char *name);
   int SetActiveVectors (const char *name);
   void SetCopyAttribute (int index, int value);
   void SetCopyNormals (int i);
   void SetCopyScalars (int i);
   void SetCopyTCoords (int i);
   void SetCopyTensors (int i);
   void SetCopyVectors (int i);
   int SetNormals (vtkDataArray *da);
   int SetScalars (vtkDataArray *da);
   int SetTCoords (vtkDataArray *da);
   int SetTensors (vtkDataArray *da);
   int SetVectors (vtkDataArray *da);
   virtual void ShallowCopy (vtkFieldData *pd);
   virtual void Update ();


B<vtkDataSetAttributes Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void GetAttributeIndices (int *indexArray);
      Don't know the size of pointer arg number 1

   void InterpolatePoint (vtkDataSetAttributes *fromPd, long toId, vtkIdList *ids, float *weights);
      Don't know the size of pointer arg number 4

   void InterpolateTuple (vtkDataArray *fromData, vtkDataArray *toData, long toId, vtkIdList *ptIds, float *weights);
      Don't know the size of pointer arg number 5

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::DataSetCollection;


@Graphics::VTK::DataSetCollection::ISA = qw( Graphics::VTK::Collection );

=head1 Graphics::VTK::DataSetCollection

=over 1

=item *

Inherits from Collection

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddItem (vtkDataSet *ds);
   const char *GetClassName ();
   vtkDataSet *GetItem (int i);
   vtkDataSet *GetNextItem ();
   vtkDataSetCollection *New ();

=cut

package Graphics::VTK::DebugLeaks;


@Graphics::VTK::DebugLeaks::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::DebugLeaks

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   static void ConstructClass (const char *classname);
   static void DeleteTable ();
   static void DestructClass (const char *classname);
   const char *GetClassName ();
   vtkDebugLeaks *New ();
   static void PrintCurrentLeaks ();
   static void PromptUserOff ();
   static void PromptUserOn ();

=cut

package Graphics::VTK::Directory;


@Graphics::VTK::Directory::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::Directory

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   const char *GetFile (int index);
   int GetNumberOfFiles ();
   vtkDirectory *New ();
   int Open (const char *dir);


B<vtkDirectory Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::DoubleArray;


@Graphics::VTK::DoubleArray::ISA = qw( Graphics::VTK::DataArray );

=head1 Graphics::VTK::DoubleArray

=over 1

=item *

Inherits from DataArray

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int Allocate (const long sz, const long ext);
   void DeepCopy (vtkDataArray *da);
   const char *GetClassName ();
   int GetDataType ();
   double GetValue (const long id);
   void Initialize ();
   virtual void InsertComponent (const long i, const int j, const float c);
   long InsertNextValue (const double f);
   void InsertValue (const long id, const double f);
   vtkDoubleArray *New ();
   virtual void Resize (long numTuples);
   void SetNumberOfTuples (const long number);
   void SetNumberOfValues (const long number);
   void SetValue (const long id, const double value);
   void Squeeze ();


B<vtkDoubleArray Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   double *GetPointer (const long id);
      Can't Handle 'double *' return type without a hint

   float *GetTuple (const long i);
      Can't Handle 'float *' return type without a hint

   void GetTuple (const long i, float *tuple);
      Don't know the size of pointer arg number 2

   void GetTuple (const long i, double *tuple);
      Don't know the size of pointer arg number 2

   void *GetVoidPointer (const long id);
      Can't Handle 'void *' return type without a hint

   long InsertNextTuple (const float *tuple);
      Don't know the size of pointer arg number 1

   long InsertNextTuple (const double *tuple);
      Don't know the size of pointer arg number 1

   void InsertTuple (const long i, const float *tuple);
      Don't know the size of pointer arg number 2

   void InsertTuple (const long i, const double *tuple);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   double *ResizeAndExtend (const long sz);
      Can't Handle 'double *' return type without a hint

   void SetArray (double *array, long size, int save);
      Don't know the size of pointer arg number 1

   void SetTuple (const long i, const float *tuple);
      Don't know the size of pointer arg number 2

   void SetTuple (const long i, const double *tuple);
      Don't know the size of pointer arg number 2

   void SetVoidArray (void *array, long size, int save);
      Don't know the size of pointer arg number 1

   double *WritePointer (const long id, const long number);
      Can't Handle 'double *' return type without a hint


=cut

package Graphics::VTK::DynamicLoader;


@Graphics::VTK::DynamicLoader::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::DynamicLoader

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   static const char *LastError ();
   static const char *LibExtension ();
   static const char *LibPrefix ();
   vtkDynamicLoader *New ();


B<vtkDynamicLoader Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   static void *GetSymbolAddress (vtkLibHandle , const char *);
      Can't Handle 'static void *' return type without a hint


=cut

package Graphics::VTK::EdgeTable;


@Graphics::VTK::EdgeTable::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::EdgeTable

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   long GetNumberOfEdges ();
   int InitEdgeInsertion (long numPoints, int storeAttributes);
   int InitPointInsertion (vtkPoints *newPts, long estSize);
   void InitTraversal ();
   void Initialize ();
   void InsertEdge (long p1, long p2, int attributeId);
   long InsertEdge (long p1, long p2);
   int IsEdge (long p1, long p2);
   vtkEdgeTable *New ();
   void Reset ();


B<vtkEdgeTable Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int GetNextEdge (long &p1, long &p2);
      Don't know the size of pointer arg number 1

   int InsertUniquePoint (long p1, long p2, float x[3], long &ptId);
      Don't know the size of pointer arg number 3

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   vtkIdList *Resize (long size);
      Can't Handle 'vtkIdList **' return type yet


=cut

package Graphics::VTK::EmptyCell;


@Graphics::VTK::EmptyCell::ISA = qw( Graphics::VTK::Cell );

=head1 Graphics::VTK::EmptyCell

=over 1

=item *

Inherits from Cell

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Clip (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *pts, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd, int insideOut);
   void Contour (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *verts1, vtkCellArray *lines, vtkCellArray *verts2, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd);
   int GetCellDimension ();
   int GetCellType ();
   const char *GetClassName ();
   vtkCell *GetEdge (int );
   vtkCell *GetFace (int );
   int GetNumberOfEdges ();
   int GetNumberOfFaces ();
   vtkEmptyCell *New ();
   int Triangulate (int index, vtkIdList *ptIds, vtkPoints *pts);


B<vtkEmptyCell Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int CellBoundary (int subId, float pcoords[3], vtkIdList *pts);
      Don't know the size of pointer arg number 2

   void Derivatives (int subId, float pcoords[3], float *values, int dim, float *derivs);
      Don't know the size of pointer arg number 2

   void EvaluateLocation (int &subId, float pcoords[3], float x[3], float *weights);
      Don't know the size of pointer arg number 2

   int EvaluatePosition (float x[3], float *closestPoint, int &subId, float pcoords[3], float &dist2, float *weights);
      Don't know the size of pointer arg number 1

   int IntersectWithLine (float p1[3], float p2[3], float tol, float &t, float x[3], float pcoords[3], int &subId);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::ExtentTranslator;


@Graphics::VTK::ExtentTranslator::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::ExtentTranslator

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int  *GetExtent ();
      (Returns a 6-element Perl list)
   int GetGhostLevel ();
   int GetNumberOfPieces ();
   int GetPiece ();
   int GetSplitMode ();
   int  *GetWholeExtent ();
      (Returns a 6-element Perl list)
   vtkExtentTranslator *New ();
   virtual int PieceToExtent ();
   virtual int PieceToExtentByPoints ();
   void SetExtent (int , int , int , int , int , int );
   void SetGhostLevel (int );
   void SetNumberOfPieces (int );
   void SetPiece (int );
   void SetSplitModeToBlock ();
   void SetSplitModeToXSlab ();
   void SetSplitModeToYSlab ();
   void SetSplitModeToZSlab ();
   void SetWholeExtent (int , int , int , int , int , int );


B<vtkExtentTranslator Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual int PieceToExtentThreadSafe (int piece, int numPieces, int ghostLevel, int *wholeExtent, int *resultExtent, int splitMode, int byPoints);
      Don't know the size of pointer arg number 4

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetExtent (int  a[6]);
      Method is redundant. Same as SetExtent( int, int, int, int, int, int)

   void SetWholeExtent (int  a[6]);
      Method is redundant. Same as SetWholeExtent( int, int, int, int, int, int)

   int SplitExtent (int piece, int numPieces, int *extent, int splitMode);
      Don't know the size of pointer arg number 3

   int SplitExtentByPoints (int piece, int numPieces, int *extent, int splitMode);
      Don't know the size of pointer arg number 3


=cut

package Graphics::VTK::FieldData;


@Graphics::VTK::FieldData::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::FieldData

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int AddArray (vtkDataArray *array);
   int Allocate (const long sz, const long ext);
   void AllocateArrays (int num);
   virtual void CopyAllOff ();
   virtual void CopyAllOn ();
   void CopyFieldOff (const char *name);
   void CopyFieldOn (const char *name);
   virtual void DeepCopy (vtkFieldData *da);
   virtual unsigned long GetActualMemorySize ();
   vtkDataArray *GetArray (const char *arrayName, int &index);
   vtkDataArray *GetArray (const char *arrayName);
   vtkDataArray *GetArray (int i);
   int GetArrayContainingComponent (int i, int &arrayComp);
   const char *GetArrayName (int i);
   const char *GetClassName ();
   float GetComponent (const long i, const int j);
   void GetField (vtkIdList *ptId, vtkFieldData *f);
   unsigned long GetMTime ();
   int GetNumberOfArrays ();
   int GetNumberOfComponents ();
   long GetNumberOfTuples ();
   virtual void Initialize ();
   void InsertComponent (const long i, const int j, const float c);
   vtkFieldData *New ();
   virtual void PassData (vtkFieldData *fd);
   virtual void RemoveArray (const char *name);
   void Reset ();
   void SetComponent (const long i, const int j, const float c);
   void SetNumberOfArrays (int num);
   void SetNumberOfTuples (const long number);
   virtual void ShallowCopy (vtkFieldData *da);
   void Squeeze ();


B<vtkFieldData Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   float *GetTuple (const long i);
      Can't Handle 'float *' return type without a hint

   void GetTuple (const long i, float *tuple);
      Don't know the size of pointer arg number 2

   long InsertNextTuple (const float *tuple);
      Don't know the size of pointer arg number 1

   void InsertTuple (const long i, const float *tuple);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetTuple (const long i, const float *tuple);
      Don't know the size of pointer arg number 2


=cut

package Graphics::VTK::FileOutputWindow;


@Graphics::VTK::FileOutputWindow::ISA = qw( Graphics::VTK::OutputWindow );

=head1 Graphics::VTK::FileOutputWindow

=over 1

=item *

Inherits from OutputWindow

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AppendOff ();
   void AppendOn ();
   virtual void DisplayText (const char *);
   void FlushOff ();
   void FlushOn ();
   int GetAppend ();
   const char *GetClassName ();
   char *GetFileName ();
   int GetFlush ();
   vtkFileOutputWindow *New ();
   void SetAppend (int );
   void SetFileName (char *);
   void SetFlush (int );


B<vtkFileOutputWindow Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::FloatArray;


@Graphics::VTK::FloatArray::ISA = qw( Graphics::VTK::DataArray );

=head1 Graphics::VTK::FloatArray

=over 1

=item *

Inherits from DataArray

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int Allocate (const long sz, const long ext);
   void DeepCopy (vtkDataArray *fa);
   const char *GetClassName ();
   float GetComponent (const long i, const int j);
   int GetDataType ();
   float GetValue (const long id);
   void Initialize ();
   void InsertComponent (const long i, const int j, const float c);
   long InsertNextValue (const float f);
   void InsertValue (const long id, const float f);
   vtkFloatArray *New ();
   virtual void Resize (long numTuples);
   void SetComponent (const long i, const int j, const float c);
   void SetNumberOfTuples (const long number);
   void SetNumberOfValues (const long number);
   void SetValue (const long id, const float value);
   void Squeeze ();


B<vtkFloatArray Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   float *GetPointer (const long id);
      Can't Handle 'float *' return type without a hint

   float *GetTuple (const long i);
      Can't Handle 'float *' return type without a hint

   void GetTuple (const long i, float *tuple);
      Don't know the size of pointer arg number 2

   void GetTuple (const long i, double *tuple);
      Don't know the size of pointer arg number 2

   void *GetVoidPointer (const long id);
      Can't Handle 'void *' return type without a hint

   long InsertNextTuple (const float *tuple);
      Don't know the size of pointer arg number 1

   long InsertNextTuple (const double *tuple);
      Don't know the size of pointer arg number 1

   void InsertTuple (const long i, const float *tuple);
      Don't know the size of pointer arg number 2

   void InsertTuple (const long i, const double *tuple);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   float *ResizeAndExtend (const long sz);
      Can't Handle 'float *' return type without a hint

   void SetArray (float *array, long size, int save);
      Don't know the size of pointer arg number 1

   void SetTuple (const long i, const float *tuple);
      Don't know the size of pointer arg number 2

   void SetTuple (const long i, const double *tuple);
      Don't know the size of pointer arg number 2

   void SetVoidArray (void *array, long size, int save);
      Don't know the size of pointer arg number 1

   float *WritePointer (const long id, const long number);
      Can't Handle 'float *' return type without a hint


=cut

package Graphics::VTK::FunctionParser;


@Graphics::VTK::FunctionParser::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::FunctionParser

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   char *GetFunction ();
   int GetNumberOfScalarVariables ();
   int GetNumberOfVectorVariables ();
   double GetScalarResult ();
   char *GetScalarVariableName (int i);
   double GetScalarVariableValue (const char *variableName);
   double GetScalarVariableValue (int i);
   double *GetVectorResult ();
      (Returns a 3-element Perl list)
   char *GetVectorVariableName (int i);
   double *GetVectorVariableValue (const char *variableName);
      (Returns a 3-element Perl list)
   double *GetVectorVariableValue (int i);
      (Returns a 3-element Perl list)
   int IsScalarResult ();
   int IsVectorResult ();
   vtkFunctionParser *New ();
   void SetFunction (const char *function);
   void SetScalarVariableValue (const char *variableName, double value);
   void SetScalarVariableValue (int i, double value);
   void SetVectorVariableValue (const char *variableName, double xValue, double yValue, double zValue);
   void SetVectorVariableValue (int i, double xValue, double yValue, double zValue);


B<vtkFunctionParser Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void GetVectorResult (double result[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void GetVectorVariableValue (const char *variableName, double value[3]);
      Don't know the size of pointer arg number 2

   void GetVectorVariableValue (int i, double value[3]);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetVectorVariableValue (const char *variableName, const double values[3]);
      Don't know the size of pointer arg number 2

   void SetVectorVariableValue (int i, const double values[3]);
      Don't know the size of pointer arg number 2


=cut

package Graphics::VTK::FunctionSet;


@Graphics::VTK::FunctionSet::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::FunctionSet

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   virtual int GetNumberOfFunctions ();
   virtual int GetNumberOfIndependentVariables ();


B<vtkFunctionSet Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual int FunctionValues (float *x, float *f) = 0;
      Don't know the size of pointer arg number 1

   virtual void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::GeneralTransform;


@Graphics::VTK::GeneralTransform::ISA = qw( Graphics::VTK::AbstractTransform );

=head1 Graphics::VTK::GeneralTransform

=over 1

=item *

Inherits from AbstractTransform

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int CircuitCheck (vtkAbstractTransform *transform);
   void Concatenate (vtkMatrix4x4 *matrix);
   void Concatenate (vtkAbstractTransform *transform);
   const char *GetClassName ();
   vtkAbstractTransform *GetConcatenatedTransform (int i);
   vtkAbstractTransform *GetInput ();
   int GetInverseFlag ();
   unsigned long GetMTime ();
   int GetNumberOfConcatenatedTransforms ();
   void Identity ();
   void Inverse ();
   vtkAbstractTransform *MakeTransform ();
   vtkGeneralTransform *New ();
   void Pop ();
   void PostMultiply ();
   void PreMultiply ();
   void Push ();
   void RotateWXYZ (double angle, double x, double y, double z);
   void RotateX (double angle);
   void RotateY (double angle);
   void RotateZ (double angle);
   void Scale (double x, double y, double z);
   void SetInput (vtkAbstractTransform *input);
   void Translate (double x, double y, double z);


B<vtkGeneralTransform Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void Concatenate (const double elements[16]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void InternalTransformDerivative (const float in[3], float out[3], float derivative[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void InternalTransformDerivative (const double in[3], double out[3], double derivative[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void InternalTransformPoint (const float in[3], float out[3]);
      Don't know the size of pointer arg number 1

   void InternalTransformPoint (const double in[3], double out[3]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void RotateWXYZ (double angle, const double axis[3]);
      Don't know the size of pointer arg number 2

   void RotateWXYZ (double angle, const float axis[3]);
      Don't know the size of pointer arg number 2

   void Scale (const double s[3]);
      Method is redundant. Same as Scale( double, double, double)

   void Scale (const float s[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void Translate (const double x[3]);
      Method is redundant. Same as Translate( double, double, double)

   void Translate (const float x[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.


=cut

package Graphics::VTK::GenericCell;


@Graphics::VTK::GenericCell::ISA = qw( Graphics::VTK::Cell );

=head1 Graphics::VTK::GenericCell

=over 1

=item *

Inherits from Cell

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Clip (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *connectivity, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd, int insideOut);
   void Contour (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *verts, vtkCellArray *lines, vtkCellArray *polys, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd);
   void DeepCopy (vtkCell *c);
   int GetCellDimension ();
   int GetCellType ();
   const char *GetClassName ();
   vtkCell *GetEdge (int edgeId);
   vtkCell *GetFace (int faceId);
   int GetInterpolationOrder ();
   int GetNumberOfEdges ();
   int GetNumberOfFaces ();
   vtkGenericCell *New ();
   void SetCellType (int cellType);
   void SetCellTypeToEmptyCell ();
   void SetCellTypeToHexahedron ();
   void SetCellTypeToLine ();
   void SetCellTypeToPixel ();
   void SetCellTypeToPolyLine ();
   void SetCellTypeToPolyVertex ();
   void SetCellTypeToPolygon ();
   void SetCellTypeToPyramid ();
   void SetCellTypeToQuad ();
   void SetCellTypeToTetra ();
   void SetCellTypeToTriangle ();
   void SetCellTypeToTriangleStrip ();
   void SetCellTypeToVertex ();
   void SetCellTypeToVoxel ();
   void SetCellTypeToWedge ();
   void ShallowCopy (vtkCell *c);
   int Triangulate (int index, vtkIdList *ptIds, vtkPoints *pts);


B<vtkGenericCell Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int CellBoundary (int subId, float pcoords[3], vtkIdList *pts);
      Don't know the size of pointer arg number 2

   void Derivatives (int subId, float pcoords[3], float *values, int dim, float *derivs);
      Don't know the size of pointer arg number 2

   void EvaluateLocation (int &subId, float pcoords[3], float x[3], float *weights);
      Don't know the size of pointer arg number 2

   int EvaluatePosition (float x[3], float *closestPoint, int &subId, float pcoords[3], float &dist2, float *weights);
      Don't know the size of pointer arg number 1

   int GetParametricCenter (float pcoords[3]);
      Can't handle methods with single array args (like a[3]) yet.

   int IntersectWithLine (float p1[3], float p2[3], float tol, float &t, float x[3], float pcoords[3], int &subId);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::Heap;


@Graphics::VTK::Heap::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::Heap

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetNumberOfAllocations ();
   vtkHeap *New ();
   char *vtkStrDup (const char *str);


B<vtkHeap Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void *AllocateMemory (size_t n);
      Can't Handle 'void *' return type without a hint

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::Hexahedron;


@Graphics::VTK::Hexahedron::ISA = qw( Graphics::VTK::Cell3D );

=head1 Graphics::VTK::Hexahedron

=over 1

=item *

Inherits from Cell3D

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Contour (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *verts, vtkCellArray *lines, vtkCellArray *polys, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd);
   int GetCellType ();
   const char *GetClassName ();
   vtkCell *GetEdge (int edgeId);
   vtkCell *GetFace (int faceId);
   int GetNumberOfEdges ();
   int GetNumberOfFaces ();
   vtkHexahedron *New ();
   int Triangulate (int index, vtkIdList *ptIds, vtkPoints *pts);


B<vtkHexahedron Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int CellBoundary (int subId, float pcoords[3], vtkIdList *pts);
      Don't know the size of pointer arg number 2

   void Derivatives (int subId, float pcoords[3], float *values, int dim, float *derivs);
      Don't know the size of pointer arg number 2

   void EvaluateLocation (int &subId, float pcoords[3], float x[3], float *weights);
      Don't know the size of pointer arg number 2

   int EvaluatePosition (float x[3], float *closestPoint, int &subId, float pcoords[3], float &dist2, float *weights);
      Don't know the size of pointer arg number 1

   static int *GetEdgeArray (int edgeId);
      Can't Handle 'static int *' return type without a hint

   virtual void GetEdgePoints (int edgeId, int &pts);
      Don't know the size of pointer arg number 2

   static int *GetFaceArray (int faceId);
      Can't Handle 'static int *' return type without a hint

   virtual void GetFacePoints (int faceId, int &pts);
      Don't know the size of pointer arg number 2

   static void InterpolationDerivs (float pcoords[3], float derivs[24]);
      Don't know the size of pointer arg number 1

   static void InterpolationFunctions (float pcoords[3], float weights[8]);
      Don't know the size of pointer arg number 1

   int IntersectWithLine (float p1[3], float p2[3], float tol, float &t, float x[3], float pcoords[3], int &subId);
      Don't know the size of pointer arg number 1

   void JacobianInverse (float pcoords[3], double *inverse, float derivs[24]);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::HomogeneousTransform;


@Graphics::VTK::HomogeneousTransform::ISA = qw( Graphics::VTK::AbstractTransform );

=head1 Graphics::VTK::HomogeneousTransform

=over 1

=item *

Inherits from AbstractTransform

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkHomogeneousTransform *GetHomogeneousInverse ();
   void GetMatrix (vtkMatrix4x4 *m);
   vtkMatrix4x4 *GetMatrix ();
   void TransformPoints (vtkPoints *inPts, vtkPoints *outPts);
   virtual void TransformPointsNormalsVectors (vtkPoints *inPts, vtkPoints *outPts, vtkDataArray *inNms, vtkDataArray *outNms, vtkDataArray *inVrs, vtkDataArray *outVrs);


B<vtkHomogeneousTransform Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void InternalTransformDerivative (const float in[3], float out[3], float derivative[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void InternalTransformDerivative (const double in[3], double out[3], double derivative[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void InternalTransformPoint (const float in[3], float out[3]);
      Don't know the size of pointer arg number 1

   void InternalTransformPoint (const double in[3], double out[3]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::IdList;


@Graphics::VTK::IdList::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::IdList

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int Allocate (const int sz, const int strategy);
   void DeepCopy (vtkIdList *ids);
   void DeleteId (long id);
   const char *GetClassName ();
   long GetId (const int i);
   long GetNumberOfIds ();
   void Initialize ();
   void InsertId (const long i, const long id);
   long InsertNextId (const long id);
   long InsertUniqueId (const long id);
   void IntersectWith (vtkIdList &otherIds);
   long IsId (long id);
   vtkIdList *New ();
   void Reset ();
   void SetId (const long i, const long id);
   void SetNumberOfIds (const long number);
   void Squeeze ();


B<vtkIdList Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   long *GetPointer (const long i);
      Can't Handle 'long *' return type without a hint

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   long *Resize (const long sz);
      Can't Handle 'long *' return type without a hint

   long *WritePointer (const long i, const long number);
      Can't Handle 'long *' return type without a hint


=cut

package Graphics::VTK::IdTypeArray;


@Graphics::VTK::IdTypeArray::ISA = qw( Graphics::VTK::DataArray );

=head1 Graphics::VTK::IdTypeArray

=over 1

=item *

Inherits from DataArray

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int Allocate (const long sz, const long ext);
   void DeepCopy (vtkDataArray *ia);
   const char *GetClassName ();
   int GetDataType ();
   long GetValue (const long id);
   void Initialize ();
   long InsertNextValue (const long i);
   void InsertValue (const long id, const long i);
   vtkIdTypeArray *New ();
   virtual void Resize (long numTuples);
   void SetNumberOfTuples (const long number);
   void SetNumberOfValues (const long number);
   void SetValue (const long id, const long value);
   void Squeeze ();


B<vtkIdTypeArray Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   long *GetPointer (const long id);
      Can't Handle 'long *' return type without a hint

   float *GetTuple (const long i);
      Can't Handle 'float *' return type without a hint

   void GetTuple (const long i, float *tuple);
      Don't know the size of pointer arg number 2

   void GetTuple (const long i, double *tuple);
      Don't know the size of pointer arg number 2

   void *GetVoidPointer (const long id);
      Can't Handle 'void *' return type without a hint

   long InsertNextTuple (const float *tuple);
      Don't know the size of pointer arg number 1

   long InsertNextTuple (const double *tuple);
      Don't know the size of pointer arg number 1

   void InsertTuple (const long i, const float *tuple);
      Don't know the size of pointer arg number 2

   void InsertTuple (const long i, const double *tuple);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   long *ResizeAndExtend (const long sz);
      Can't Handle 'long *' return type without a hint

   void SetArray (long *array, long size, int save);
      Don't know the size of pointer arg number 1

   void SetTuple (const long i, const float *tuple);
      Don't know the size of pointer arg number 2

   void SetTuple (const long i, const double *tuple);
      Don't know the size of pointer arg number 2

   void SetVoidArray (void *array, long size, int save);
      Don't know the size of pointer arg number 1

   long *WritePointer (const long id, const long number);
      Can't Handle 'long *' return type without a hint


=cut

package Graphics::VTK::IdentityTransform;


@Graphics::VTK::IdentityTransform::ISA = qw( Graphics::VTK::LinearTransform );

=head1 Graphics::VTK::IdentityTransform

=over 1

=item *

Inherits from LinearTransform

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   void Inverse ();
   vtkAbstractTransform *MakeTransform ();
   vtkIdentityTransform *New ();
   void TransformNormals (vtkDataArray *inNms, vtkDataArray *outNms);
   void TransformPoints (vtkPoints *inPts, vtkPoints *outPts);
   void TransformPointsNormalsVectors (vtkPoints *inPts, vtkPoints *outPts, vtkDataArray *inNms, vtkDataArray *outNms, vtkDataArray *inVrs, vtkDataArray *outVrs);
   void TransformVectors (vtkDataArray *inVrs, vtkDataArray *outVrs);


B<vtkIdentityTransform Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void InternalTransformDerivative (const float in[3], float out[3], float derivative[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void InternalTransformDerivative (const double in[3], double out[3], double derivative[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void InternalTransformNormal (const float in[3], float out[3]);
      Don't know the size of pointer arg number 1

   void InternalTransformNormal (const double in[3], double out[3]);
      Don't know the size of pointer arg number 1

   void InternalTransformPoint (const float in[3], float out[3]);
      Don't know the size of pointer arg number 1

   void InternalTransformPoint (const double in[3], double out[3]);
      Don't know the size of pointer arg number 1

   void InternalTransformVector (const float in[3], float out[3]);
      Don't know the size of pointer arg number 1

   void InternalTransformVector (const double in[3], double out[3]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ImageData;


@Graphics::VTK::ImageData::ISA = qw( Graphics::VTK::DataSet );

=head1 Graphics::VTK::ImageData

=over 1

=item *

Inherits from DataSet

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AllocateScalars ();
   void ComputeBounds ();
   void CopyAndCastFrom (vtkImageData *inData, int x0, int x1, int y0, int y1, int z0, int z1);
   void CopyStructure (vtkDataSet *ds);
   void CopyTypeSpecificInformation (vtkDataObject *image);
   virtual void Crop ();
   void DeepCopy (vtkDataObject *src);
   long FindPoint (float x, float y, float z);
   unsigned long GetActualMemorySize ();
   void GetAxisUpdateExtent (int axis, int &min, int &max);
   void GetCell (long cellId, vtkGenericCell *cell);
   vtkCell *GetCell (long cellId);
   void GetCellPoints (long cellId, vtkIdList *ptIds);
   int GetCellType (long cellId);
   const char *GetClassName ();
   int GetDataDimension ();
   int GetDataObjectType ();
   int *GetDimensions ();
      (Returns a 3-element Perl list)
   virtual unsigned long GetEstimatedMemorySize ();
   int  *GetExtent ();
      (Returns a 6-element Perl list)
   void GetIncrements (int &incX, int &incY, int &incZ);
   int *GetIncrements ();
      (Returns a 3-element Perl list)
   int GetMaxCellSize ();
   long GetNumberOfCells ();
   long GetNumberOfPoints ();
   int GetNumberOfScalarComponents ();
   float  *GetOrigin ();
      (Returns a 3-element Perl list)
   float *GetPoint (long ptId);
      (Returns a 3-element Perl list)
   void GetPointCells (long ptId, vtkIdList *cellIds);
   float GetScalarComponentAsFloat (int x, int y, int z, int component);
   int GetScalarSize ();
   int GetScalarType ();
   double GetScalarTypeMax ();
   double GetScalarTypeMin ();
   float  *GetSpacing ();
      (Returns a 3-element Perl list)
   void GetVoxelGradient (int i, int j, int k, vtkDataArray *s, vtkDataArray *g);
   vtkImageData *New ();
   virtual void PrepareForNewData ();
   void SetAxisUpdateExtent (int axis, int min, int max);
   void SetDimensions (int i, int j, int k);
   void SetExtent (int x1, int x2, int y1, int y2, int z1, int z2);
   void SetNumberOfScalarComponents (int n);
   void SetOrigin (float , float , float );
   void SetScalarType (int );
   void SetScalarTypeToChar ();
   void SetScalarTypeToDouble ();
   void SetScalarTypeToFloat ();
   void SetScalarTypeToInt ();
   void SetScalarTypeToLong ();
   void SetScalarTypeToShort ();
   void SetScalarTypeToUnsignedChar ();
   void SetScalarTypeToUnsignedInt ();
   void SetScalarTypeToUnsignedLong ();
   void SetScalarTypeToUnsignedShort ();
   void SetSpacing (float , float , float );
   void SetUpdateExtent (int x1, int x2, int y1, int y2, int z1, int z2);
   void SetUpdateExtent (int piece, int numPieces, int ghostLevel);
   void SetUpdateExtent (int piece, int numPieces);
   void ShallowCopy (vtkDataObject *src);
   void UpdateData ();


B<vtkImageData Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   long ComputeCellId (int ijk[3]);
      Can't handle methods with single array args (like a[3]) yet.

   long ComputePointId (int ijk[3]);
      Can't handle methods with single array args (like a[3]) yet.

   int ComputeStructuredCoordinates (float x[3], int ijk[3], float pcoords[3]);
      Don't know the size of pointer arg number 1

   void CopyAndCastFrom (vtkImageData *inData, int extent[6]);
      Don't know the size of pointer arg number 2

   vtkCell *FindAndGetCell (float x[3], vtkCell *cell, long cellId, float tol2, int &subId, float pcoords[3], float *weights);
      Don't know the size of pointer arg number 1

   long FindCell (float x[3], vtkCell *cell, long cellId, float tol2, int &subId, float pcoords[3], float *weights);
      Don't know the size of pointer arg number 1

   long FindCell (float x[3], vtkCell *cell, vtkGenericCell *gencell, long cellId, float tol2, int &subId, float pcoords[3], float *weights);
      Don't know the size of pointer arg number 1

   long FindPoint (float x[3]);
      Method is redundant. Same as FindPoint( float, float, float)

   void GetCellBounds (long cellId, float bounds[6]);
      Don't know the size of pointer arg number 2

   void GetContinuousIncrements (int extent[6], int &incX, int &incY, int &incZ);
      Don't know the size of pointer arg number 1

   void GetDimensions (int dims[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void GetIncrements (int inc[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void GetPointGradient (int i, int j, int k, vtkDataArray *s, float g[3]);
      Don't know the size of pointer arg number 5

   void GetPoint (long id, float x[3]);
      Don't know the size of pointer arg number 2

   void *GetScalarPointer (int coordinates[3]);
      Can't Handle 'void *' return type without a hint

   void *GetScalarPointerForExtent (int coordinates[6]);
      Can't Handle 'void *' return type without a hint

   void *GetScalarPointer (int x, int y, int z);
      Can't Handle 'void *' return type without a hint

   void *GetScalarPointer ();
      Can't Handle 'void *' return type without a hint

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetDimensions (int dims[3]);
      Method is redundant. Same as SetDimensions( int, int, int)

   void SetExtent (int extent[6]);
      Method is redundant. Same as SetExtent( int, int, int, int, int, int)

   void SetOrigin (float  a[3]);
      Method is redundant. Same as SetOrigin( float, float, float)

   void SetSpacing (float  a[3]);
      Method is redundant. Same as SetSpacing( float, float, float)

   void SetUpdateExtent (int ext[6]);
      Method is redundant. Same as SetUpdateExtent( int, int, int, int, int, int)


=cut

package Graphics::VTK::ImplicitFunction;


@Graphics::VTK::ImplicitFunction::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::ImplicitFunction

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   float EvaluateFunction (float x, float y, float z);
   float *FunctionGradient (float x, float y, float z);
      (Returns a 3-element Perl list)
   float FunctionValue (float x, float y, float z);
   const char *GetClassName ();
   unsigned long GetMTime ();
   vtkAbstractTransform *GetTransform ();
   void SetTransform (vtkAbstractTransform *);


B<vtkImplicitFunction Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual float EvaluateFunction (float x[3]) = 0;
      Method is redundant. Same as EvaluateFunction( float, float, float)

   virtual void EvaluateGradient (float x[3], float g[3]) = 0;
      Don't know the size of pointer arg number 1

   void FunctionGradient (const float x[3], float g[3]);
      Don't know the size of pointer arg number 1

   float *FunctionGradient (const float x[3]);
      Method is redundant. Same as FunctionGradient_( float, float, float)

   float FunctionValue (const float x[3]);
      Method is redundant. Same as FunctionValue( float, float, float)

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ImplicitFunctionCollection;


@Graphics::VTK::ImplicitFunctionCollection::ISA = qw( Graphics::VTK::Collection );

=head1 Graphics::VTK::ImplicitFunctionCollection

=over 1

=item *

Inherits from Collection

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddItem (vtkImplicitFunction *);
   const char *GetClassName ();
   vtkImplicitFunction *GetNextItem ();
   vtkImplicitFunctionCollection *New ();

=cut

package Graphics::VTK::Indent;


=head1 Graphics::VTK::Indent

=over 1

=item *

Inherits from 

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Delete ();
   virtual const char *GetClassName ();
   vtkIndent *New ();


B<vtkIndent Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   vtkIndent GetNextIndent ();
      Can't return vtk Object Types that aren't a pointer


=cut

package Graphics::VTK::InitialValueProblemSolver;


@Graphics::VTK::InitialValueProblemSolver::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::InitialValueProblemSolver

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkFunctionSet *GetFunctionSet ();
   virtual void SetFunctionSet (vtkFunctionSet *functionset);


B<vtkInitialValueProblemSolver Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual float ComputeNextStep (float *xprev, float *xnext, float t, float delT);
      Don't know the size of pointer arg number 1

   virtual float ComputeNextStep (float *xprev, float *dxprev, float *xnext, float t, float delT) = 0;
      Don't know the size of pointer arg number 1

   virtual void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::IntArray;


@Graphics::VTK::IntArray::ISA = qw( Graphics::VTK::DataArray );

=head1 Graphics::VTK::IntArray

=over 1

=item *

Inherits from DataArray

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int Allocate (const long sz, const long ext);
   void DeepCopy (vtkDataArray *ia);
   const char *GetClassName ();
   int GetDataType ();
   int GetValue (const long id);
   void Initialize ();
   virtual void InsertComponent (const long i, const int j, const float c);
   long InsertNextValue (const int i);
   void InsertValue (const long id, const int i);
   vtkIntArray *New ();
   virtual void Resize (long numTuples);
   void SetNumberOfTuples (const long number);
   void SetNumberOfValues (const long number);
   void SetValue (const long id, const int value);
   void Squeeze ();


B<vtkIntArray Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int *GetPointer (const long id);
      Can't Handle 'int *' return type without a hint

   float *GetTuple (const long i);
      Can't Handle 'float *' return type without a hint

   void GetTuple (const long i, float *tuple);
      Don't know the size of pointer arg number 2

   void GetTuple (const long i, double *tuple);
      Don't know the size of pointer arg number 2

   void *GetVoidPointer (const long id);
      Can't Handle 'void *' return type without a hint

   long InsertNextTuple (const float *tuple);
      Don't know the size of pointer arg number 1

   long InsertNextTuple (const double *tuple);
      Don't know the size of pointer arg number 1

   void InsertTuple (const long i, const float *tuple);
      Don't know the size of pointer arg number 2

   void InsertTuple (const long i, const double *tuple);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   int *ResizeAndExtend (const long sz);
      Can't Handle 'int *' return type without a hint

   void SetArray (int *array, long size, int save);
      Don't know the size of pointer arg number 1

   void SetTuple (const long i, const float *tuple);
      Don't know the size of pointer arg number 2

   void SetTuple (const long i, const double *tuple);
      Don't know the size of pointer arg number 2

   void SetVoidArray (void *array, long size, int save);
      Don't know the size of pointer arg number 1

   int *WritePointer (const long id, const long number);
      Can't Handle 'int *' return type without a hint


=cut

package Graphics::VTK::InterpolatedVelocityField;


@Graphics::VTK::InterpolatedVelocityField::ISA = qw( Graphics::VTK::FunctionSet );

=head1 Graphics::VTK::InterpolatedVelocityField

=over 1

=item *

Inherits from FunctionSet

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CachingOff ();
   void CachingOn ();
   void ClearLastCellId ();
   int GetCacheHit ();
   int GetCacheMiss ();
   int GetCaching ();
   const char *GetClassName ();
   vtkDataSet *GetDataSet ();
   long GetLastCellId ();
   vtkInterpolatedVelocityField *New ();
   void SetCaching (int );
   virtual void SetDataSet (vtkDataSet *dataset);
   void SetLastCellId (long );


B<vtkInterpolatedVelocityField Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual int FunctionValues (float *x, float *f);
      Don't know the size of pointer arg number 1

   int GetLastLocalCoordinates (float pcoords[3]);
      Can't handle methods with single array args (like a[3]) yet.

   int GetLastWeights (float *w);
      Don't know the size of pointer arg number 1

   virtual void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::Line;


@Graphics::VTK::Line::ISA = qw( Graphics::VTK::Cell );

=head1 Graphics::VTK::Line

=over 1

=item *

Inherits from Cell

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Clip (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *lines, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd, int insideOut);
   void Contour (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *verts, vtkCellArray *lines, vtkCellArray *polys, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd);
   int GetCellDimension ();
   int GetCellType ();
   const char *GetClassName ();
   vtkCell *GetEdge (int );
   vtkCell *GetFace (int );
   int GetNumberOfEdges ();
   int GetNumberOfFaces ();
   vtkLine *New ();
   int Triangulate (int index, vtkIdList *ptIds, vtkPoints *pts);


B<vtkLine Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int CellBoundary (int subId, float pcoords[3], vtkIdList *pts);
      Don't know the size of pointer arg number 2

   void Derivatives (int subId, float pcoords[3], float *values, int dim, float *derivs);
      Don't know the size of pointer arg number 2

   static float DistanceToLine (float x[3], float p1[3], float p2[3], float &t, float closestPoint[3]);
      Don't know the size of pointer arg number 1

   static float DistanceToLine (float x[3], float p1[3], float p2[3]);
      Don't know the size of pointer arg number 1

   void EvaluateLocation (int &subId, float pcoords[3], float x[3], float *weights);
      Don't know the size of pointer arg number 2

   int EvaluatePosition (float x[3], float *closestPoint, int &subId, float pcoords[3], float &dist2, float *weights);
      Don't know the size of pointer arg number 1

   static void InterpolationFunctions (float pcoords[3], float weights[2]);
      Don't know the size of pointer arg number 1

   int IntersectWithLine (float p1[3], float p2[3], float tol, float &t, float x[3], float pcoords[3], int &subId);
      Don't know the size of pointer arg number 1

   static int Intersection (float p1[3], float p2[3], float x1[3], float x2[3], float &u, float &v);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::LinearTransform;


@Graphics::VTK::LinearTransform::ISA = qw( Graphics::VTK::HomogeneousTransform );

=head1 Graphics::VTK::LinearTransform

=over 1

=item *

Inherits from HomogeneousTransform

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkLinearTransform *GetLinearInverse ();
   double *TransformDoubleNormal (double x, double y, double z);
      (Returns a 3-element Perl list)
   double *TransformDoubleVector (double x, double y, double z);
      (Returns a 3-element Perl list)
   float *TransformFloatNormal (float x, float y, float z);
      (Returns a 3-element Perl list)
   float *TransformFloatVector (float x, float y, float z);
      (Returns a 3-element Perl list)
   double *TransformNormal (double x, double y, double z);
      (Returns a 3-element Perl list)
   virtual void TransformNormals (vtkDataArray *inNms, vtkDataArray *outNms);
   void TransformPoints (vtkPoints *inPts, vtkPoints *outPts);
   void TransformPointsNormalsVectors (vtkPoints *inPts, vtkPoints *outPts, vtkDataArray *inNms, vtkDataArray *outNms, vtkDataArray *inVrs, vtkDataArray *outVrs);
   double *TransformVector (double x, double y, double z);
      (Returns a 3-element Perl list)
   virtual void TransformVectors (vtkDataArray *inVrs, vtkDataArray *outVrs);


B<vtkLinearTransform Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void InternalTransformDerivative (const float in[3], float out[3], float derivative[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void InternalTransformDerivative (const double in[3], double out[3], double derivative[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   virtual void InternalTransformNormal (const float in[3], float out[3]);
      Don't know the size of pointer arg number 1

   virtual void InternalTransformNormal (const double in[3], double out[3]);
      Don't know the size of pointer arg number 1

   void InternalTransformPoint (const float in[3], float out[3]);
      Don't know the size of pointer arg number 1

   void InternalTransformPoint (const double in[3], double out[3]);
      Don't know the size of pointer arg number 1

   virtual void InternalTransformVector (const float in[3], float out[3]);
      Don't know the size of pointer arg number 1

   virtual void InternalTransformVector (const double in[3], double out[3]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   double *TransformDoubleNormal (const double normal[3]);
      Method is redundant. Same as TransformDoubleNormal( double, double, double)

   double *TransformDoubleVector (const double vec[3]);
      Method is redundant. Same as TransformDoubleVector( double, double, double)

   float *TransformFloatNormal (const float normal[3]);
      Method is redundant. Same as TransformFloatNormal( float, float, float)

   float *TransformFloatVector (const float vec[3]);
      Method is redundant. Same as TransformFloatVector( float, float, float)

   void TransformNormal (const float in[3], float out[3]);
      Don't know the size of pointer arg number 1

   void TransformNormal (const double in[3], double out[3]);
      Don't know the size of pointer arg number 1

   double *TransformNormal (const double normal[3]);
      Method is redundant. Same as TransformNormal__( double, double, double)

   double *TransformVector (const double normal[3]);
      Method is redundant. Same as TransformVector( double, double, double)

   void TransformVector (const float in[3], float out[3]);
      Don't know the size of pointer arg number 1

   void TransformVector (const double in[3], double out[3]);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::Locator;


@Graphics::VTK::Locator::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::Locator

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AutomaticOff ();
   void AutomaticOn ();
   virtual void BuildLocator () = 0;
   virtual void FreeSearchStructure () = 0;
   virtual void GenerateRepresentation (int level, vtkPolyData *pd) = 0;
   int GetAutomatic ();
   long unsigned GetBuildTime ();
   const char *GetClassName ();
   vtkDataSet *GetDataSet ();
   int GetLevel ();
   int GetMaxLevel ();
   int GetMaxLevelMaxValue ();
   int GetMaxLevelMinValue ();
   int GetRetainCellLists ();
   float GetTolerance ();
   float GetToleranceMaxValue ();
   float GetToleranceMinValue ();
   virtual void Initialize ();
   void RetainCellListsOff ();
   void RetainCellListsOn ();
   void SetAutomatic (int );
   void SetDataSet (vtkDataSet *);
   void SetMaxLevel (int );
   void SetRetainCellLists (int );
   void SetTolerance (float );
   virtual void Update ();


B<vtkLocator Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::LogLookupTable;


@Graphics::VTK::LogLookupTable::ISA = qw( Graphics::VTK::LookupTable );

=head1 Graphics::VTK::LogLookupTable

=over 1

=item *

Inherits from LookupTable

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkLogLookupTable *New ();


B<vtkLogLookupTable Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::LongArray;


@Graphics::VTK::LongArray::ISA = qw( Graphics::VTK::DataArray );

=head1 Graphics::VTK::LongArray

=over 1

=item *

Inherits from DataArray

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int Allocate (const long sz, const long ext);
   void DeepCopy (vtkDataArray *da);
   const char *GetClassName ();
   int GetDataType ();
   long GetValue (const long id);
   void Initialize ();
   virtual void InsertComponent (const long i, const int j, const float c);
   long InsertNextValue (const long );
   void InsertValue (const long id, const long i);
   vtkLongArray *New ();
   virtual void Resize (long numTuples);
   void SetNumberOfTuples (const long number);
   void SetNumberOfValues (const long number);
   void SetValue (const long id, const long value);
   void Squeeze ();


B<vtkLongArray Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   long *GetPointer (const long id);
      Can't Handle 'long *' return type without a hint

   float *GetTuple (const long i);
      Can't Handle 'float *' return type without a hint

   void GetTuple (const long i, float *tuple);
      Don't know the size of pointer arg number 2

   void GetTuple (const long i, double *tuple);
      Don't know the size of pointer arg number 2

   void *GetVoidPointer (const long id);
      Can't Handle 'void *' return type without a hint

   long InsertNextTuple (const float *tuple);
      Don't know the size of pointer arg number 1

   long InsertNextTuple (const double *tuple);
      Don't know the size of pointer arg number 1

   void InsertTuple (const long i, const float *tuple);
      Don't know the size of pointer arg number 2

   void InsertTuple (const long i, const double *tuple);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   long *ResizeAndExtend (const long sz);
      Can't Handle 'long *' return type without a hint

   void SetArray (long *array, long size, int save);
      Don't know the size of pointer arg number 1

   void SetTuple (const long i, const float *tuple);
      Don't know the size of pointer arg number 2

   void SetTuple (const long i, const double *tuple);
      Don't know the size of pointer arg number 2

   void SetVoidArray (void *array, long size, int save);
      Don't know the size of pointer arg number 1

   long *WritePointer (const long id, const long number);
      Can't Handle 'long *' return type without a hint


=cut

package Graphics::VTK::LookupTable;


@Graphics::VTK::LookupTable::ISA = qw( Graphics::VTK::ScalarsToColors );

=head1 Graphics::VTK::LookupTable

=over 1

=item *

Inherits from ScalarsToColors

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int Allocate (int sz, int ext);
   virtual void Build ();
   float  *GetAlphaRange ();
      (Returns a 2-element Perl list)
   const char *GetClassName ();
   float *GetColor (float x);
      (Returns a 3-element Perl list)
   float  *GetHueRange ();
      (Returns a 2-element Perl list)
   int GetNumberOfColors ();
   int GetNumberOfColorsMaxValue ();
   int GetNumberOfColorsMinValue ();
   int GetNumberOfTableValues ();
   float GetOpacity (float v);
   int GetRamp ();
   float  *GetSaturationRange ();
      (Returns a 2-element Perl list)
   int GetScale ();
   float  *GetTableRange ();
      (Returns a 2-element Perl list)
   float *GetTableValue (int id);
      (Returns a 4-element Perl list)
   float  *GetValueRange ();
      (Returns a 2-element Perl list)
   vtkLookupTable *New ();
   void SetAlphaRange (float , float );
   void SetHueRange (float , float );
   void SetNumberOfColors (int );
   void SetNumberOfTableValues (int number);
   void SetRamp (int );
   void SetRampToLinear ();
   void SetRampToSCurve ();
   void SetRange (float min, float max);
   void SetSaturationRange (float , float );
   void SetScale (int scale);
   void SetScaleToLinear ();
   void SetScaleToLog10 ();
   virtual void SetTableRange (float min, float max);
   void SetTableValue (int indx, float r, float g, float b, float a);
   void SetValueRange (float , float );


B<vtkLookupTable Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void GetColor (float x, float rgb[3]);
      Don't know the size of pointer arg number 2

   unsigned char *GetPointer (const int id);
      Can't Handle 'unsigned char *' return type without a hint

   float *GetRange ();
      Can't Handle 'float *' return type without a hint

   void GetTableValue (int id, float rgba[4]);
      Don't know the size of pointer arg number 2

   void MapScalarsThroughTable2 (void *input, unsigned char *output, int inputDataType, int numberOfValues, int inputIncrement, int outputIncrement);
      Don't know the size of pointer arg number 1

   unsigned char *MapValue (float v);
      Can't Handle 'unsigned char *' return type without a hint

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetAlphaRange (float  a[2]);
      Method is redundant. Same as SetAlphaRange( float, float)

   void SetHueRange (float  a[2]);
      Method is redundant. Same as SetHueRange( float, float)

   void SetRange (float rng[2]);
      Method is redundant. Same as SetRange( float, float)

   void SetSaturationRange (float  a[2]);
      Method is redundant. Same as SetSaturationRange( float, float)

   void SetTableRange (float r[2]);
      Method is redundant. Same as SetTableRange( float, float)

   void SetTableValue (int indx, float rgba[4]);
      Don't know the size of pointer arg number 2

   void SetValueRange (float  a[2]);
      Method is redundant. Same as SetValueRange( float, float)

   unsigned char *WritePointer (const int id, const int number);
      Can't Handle 'unsigned char *' return type without a hint


=cut

package Graphics::VTK::Mapper2D;


@Graphics::VTK::Mapper2D::ISA = qw( Graphics::VTK::AbstractMapper );

=head1 Graphics::VTK::Mapper2D

=over 1

=item *

Inherits from AbstractMapper

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkMapper2D *New ();
   virtual void RenderOpaqueGeometry (vtkViewport *, vtkActor2D *);
   virtual void RenderOverlay (vtkViewport *, vtkActor2D *);
   virtual void RenderTranslucentGeometry (vtkViewport *, vtkActor2D *);


B<vtkMapper2D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::Math;


@Graphics::VTK::Math::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::Math

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   static float DegreesToRadians ();
   static double Determinant2x2 (double a, double b, double c, double d);
   static double Determinant3x3 (double a1, double a2, double a3, double b1, double b2, double b3, double c1, double c2, double c3);
   static double DoubleDegreesToRadians ();
   const char *GetClassName ();
   vtkMath *New ();
   static float Pi ();
   static float Random (float min, float max);
   static float Random ();
   static void RandomSeed (long s);


B<vtkMath Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   static void Cross (const float x[3], const float y[3], float z[3]);
      Don't know the size of pointer arg number 1

   static void Cross (const double x[3], const double y[3], double z[3]);
      Don't know the size of pointer arg number 1

   static float Determinant2x2 (const float c1[2], const float c2[2]);
      Don't know the size of pointer arg number 1

   static double Determinant3x3 (float A[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   static double Determinant3x3 (double A[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   static float Determinant3x3 (const float c1[3], const float c2[3], const float c3[3]);
      Don't know the size of pointer arg number 1

   static void Diagonalize3x3 (const float A[3][3], float w[3], float V[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   static void Diagonalize3x3 (const double A[3][3], double w[3], double V[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   static float Distance2BetweenPoints (const float x[3], const float y[3]);
      Don't know the size of pointer arg number 1

   static double Distance2BetweenPoints (const double x[3], const double y[3]);
      Don't know the size of pointer arg number 1

   static float Dot (const float x[3], const float y[3]);
      Don't know the size of pointer arg number 1

   static float Dot2D (const float x[3], const float y[3]);
      Don't know the size of pointer arg number 1

   static double Dot2D (const double x[3], const double y[3]);
      Don't know the size of pointer arg number 1

   static double Dot (const double x[3], const double y[3]);
      Don't know the size of pointer arg number 1

   static double EstimateMatrixCondition (double *A, int size);
      Don't know the size of pointer arg number 1

   static void Identity3x3 (float A[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   static void Identity3x3 (double A[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   static void Invert3x3 (const float A[3][3], float AI[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   static void Invert3x3 (const double A[3][3], double AI[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   static int InvertMatrix (double *A, double *AI, int size);
      Don't know the size of pointer arg number 1

   static int InvertMatrix (double *A, double *AI, int size, int *tmp1Size, double *tmp2Size);
      Don't know the size of pointer arg number 1

   static int Jacobi (float *a, float *w, float *v);
      Don't know the size of pointer arg number 1

   static int JacobiN (float *a, int n, float *w, float *v);
      Don't know the size of pointer arg number 1

   static int JacobiN (double *a, int n, double *w, double *v);
      Don't know the size of pointer arg number 1

   static int Jacobi (double *a, double *w, double *v);
      Don't know the size of pointer arg number 1

   static void LUFactor3x3 (float A[3][3], int index[3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   static void LUFactor3x3 (double A[3][3], int index[3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   static int LUFactorLinearSystem (double *A, int *index, int size);
      Don't know the size of pointer arg number 1

   static int LUFactorLinearSystem (double *A, int *index, int size, double *tmpSize);
      Don't know the size of pointer arg number 1

   static void LUSolve3x3 (const float A[3][3], const int index[3], float x[3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   static void LUSolve3x3 (const double A[3][3], const int index[3], double x[3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   static void LUSolveLinearSystem (double *A, int *index, double *x, int size);
      Don't know the size of pointer arg number 1

   static void LinearSolve3x3 (const float A[3][3], const float x[3], float y[3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   static void LinearSolve3x3 (const double A[3][3], const double x[3], double y[3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   static void Matrix3x3ToQuaternion (const float A[3][3], float quat[4]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   static void Matrix3x3ToQuaternion (const double A[3][3], double quat[4]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   static void Multiply3x3 (const float A[3][3], const float in[3], float out[3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   static void Multiply3x3 (const double A[3][3], const double in[3], double out[3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   static void Multiply3x3 (const float A[3][3], const float B[3][3], float C[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   static void Multiply3x3 (const double A[3][3], const double B[3][3], double C[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   static float Norm (const float *x, int n);
      Don't know the size of pointer arg number 1

   static float Norm2D (const float x[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   static double Norm2D (const double x[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   static float Norm (const float x[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   static double Norm (const double x[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   static float Normalize (float x[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   static float Normalize2D (float x[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   static double Normalize2D (double x[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   static double Normalize (double x[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   static void Orthogonalize3x3 (const float A[3][3], float B[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   static void Orthogonalize3x3 (const double A[3][3], double B[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   static void Perpendiculars (const double x[3], double y[3], double z[3], double theta);
      Don't know the size of pointer arg number 1

   static void Perpendiculars (const float x[3], float y[3], float z[3], double theta);
      Don't know the size of pointer arg number 1

   static void QuaternionToMatrix3x3 (const float quat[4], float A[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   static void QuaternionToMatrix3x3 (const double quat[4], double A[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   static void SingularValueDecomposition3x3 (const float A[3][3], float U[3][3], float w[3], float VT[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   static void SingularValueDecomposition3x3 (const double A[3][3], double U[3][3], double w[3], double VT[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   static double *SolveCubic (double c0, double c1, double c2, double c3);
      Can't Handle 'static double *' return type without a hint

   static int SolveCubic (double c0, double c1, double c2, double c3, double *r1, double *r2, double *r3, int *num_roots);
      Don't know the size of pointer arg number 5

   static int SolveLeastSquares (int numberOfSamples, double *xt, int xOrder, double *yt, int yOrder, double *mt);
      Don't know the size of pointer arg number 2

   static double *SolveLinear (double c0, double c1);
      Can't Handle 'static double *' return type without a hint

   static int SolveLinearSystem (double *A, double *x, int size);
      Don't know the size of pointer arg number 1

   static int SolveLinear (double c0, double c1, double *r1, int *num_roots);
      Don't know the size of pointer arg number 3

   static double *SolveQuadratic (double c0, double c1, double c2);
      Can't Handle 'static double *' return type without a hint

   static int SolveQuadratic (double c0, double c1, double c2, double *r1, double *r2, int *num_roots);
      Don't know the size of pointer arg number 4

   static void Transpose3x3 (const float A[3][3], float AT[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   static void Transpose3x3 (const double A[3][3], double AT[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.


=cut

package Graphics::VTK::Matrix4x4;


@Graphics::VTK::Matrix4x4::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::Matrix4x4

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Adjoint (vtkMatrix4x4 *in, vtkMatrix4x4 *out);
   void DeepCopy (vtkMatrix4x4 *source);
   double Determinant ();
   const char *GetClassName ();
   double GetElement (int i, int j) const;
   void Identity ();
   static void Invert (vtkMatrix4x4 *in, vtkMatrix4x4 *out);
   void Invert ();
   static void Multiply4x4 (vtkMatrix4x4 *a, vtkMatrix4x4 *b, vtkMatrix4x4 *c);
   vtkMatrix4x4 *New ();
   void SetElement (int i, int j, double value);
   static void Transpose (vtkMatrix4x4 *in, vtkMatrix4x4 *out);
   void Transpose ();
   void Zero ();


B<vtkMatrix4x4 Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void DeepCopy (const double Elements[16]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   double *MultiplyDoublePoint (const double in[4]);
      Can't handle methods with single array args (like a[3]) yet.

   float *MultiplyFloatPoint (const float in[4]);
      Can't handle methods with single array args (like a[3]) yet.

   void MultiplyPoint (const float in[4], float out[4]);
      Don't know the size of pointer arg number 1

   void MultiplyPoint (const double in[4], double out[4]);
      Don't know the size of pointer arg number 1

   float *MultiplyPoint (const float in[4]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::MatrixToHomogeneousTransform;


@Graphics::VTK::MatrixToHomogeneousTransform::ISA = qw( Graphics::VTK::HomogeneousTransform );

=head1 Graphics::VTK::MatrixToHomogeneousTransform

=over 1

=item *

Inherits from HomogeneousTransform

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkMatrix4x4 *GetInput ();
   unsigned long GetMTime ();
   void Inverse ();
   vtkAbstractTransform *MakeTransform ();
   vtkMatrixToHomogeneousTransform *New ();
   void SetInput (vtkMatrix4x4 *);
   void SetMatrix (vtkMatrix4x4 *matrix);


B<vtkMatrixToHomogeneousTransform Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::MatrixToLinearTransform;


@Graphics::VTK::MatrixToLinearTransform::ISA = qw( Graphics::VTK::LinearTransform );

=head1 Graphics::VTK::MatrixToLinearTransform

=over 1

=item *

Inherits from LinearTransform

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkMatrix4x4 *GetInput ();
   unsigned long GetMTime ();
   void Inverse ();
   vtkAbstractTransform *MakeTransform ();
   vtkMatrixToLinearTransform *New ();
   void SetInput (vtkMatrix4x4 *);
   void SetMatrix (vtkMatrix4x4 *matrix);


B<vtkMatrixToLinearTransform Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::MultiThreader;


@Graphics::VTK::MultiThreader::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::MultiThreader

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   static int GetGlobalDefaultNumberOfThreads ();
   static int GetGlobalMaximumNumberOfThreads ();
   int GetNumberOfThreads ();
   int GetNumberOfThreadsMaxValue ();
   int GetNumberOfThreadsMinValue ();
   vtkMultiThreader *New ();
   static void SetGlobalDefaultNumberOfThreads (int val);
   static void SetGlobalMaximumNumberOfThreads (int val);
   void SetNumberOfThreads (int );


B<vtkMultiThreader Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::MutexLock;


@Graphics::VTK::MutexLock::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::MutexLock

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   void Lock (void );
   vtkMutexLock *New ();
   void Unlock (void );


B<vtkMutexLock Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::Object;


=head1 Graphics::VTK::Object

=over 1

=item *

Inherits from 

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   static void BreakOnError ();
   virtual void DebugOff ();
   virtual void DebugOn ();
   virtual void Delete ();
   virtual const char *GetClassName ();
   unsigned char GetDebug ();
   static int GetGlobalWarningDisplay ();
   virtual unsigned long GetMTime ();
   int GetReferenceCount ();
   static void GlobalWarningDisplayOff ();
   static void GlobalWarningDisplayOn ();
   int HasObserver (const char *event);
   static int IsTypeOf (const char *name);
   virtual void Modified ();
   vtkObject *New ();
   void Register (vtkObject *o);
   void RemoveObserver (unsigned long tag);
   static vtkObject *SafeDownCast (vtkObject *o);
   void SetDebug (unsigned char debugFlag);
   static void SetGlobalWarningDisplay (int val);
   void SetReferenceCount (int );
   virtual void UnRegister (vtkObject *o);


B<vtkObject Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int HasObserver (unsigned long event);
      Can't Handle Function Signature for this overloaded method

   void *new size_t tSize
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void delete void p
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void vtkObject
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void Print (ostream &os);
      I/O Streams not Supported yet

   virtual void PrintHeader (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   virtual void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   virtual void PrintTrailer (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ObjectFactory;


@Graphics::VTK::ObjectFactory::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::ObjectFactory

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   static vtkObject *CreateInstance (const char *vtkclassname);
   virtual void Disable (const char *className);
   const char *GetClassName ();
   virtual const char *GetClassOverrideName (int index);
   virtual const char *GetClassOverrideWithName (int index);
   virtual const char *GetDescription () = 0;
   virtual int GetEnableFlag (const char *className, const char *subclassName);
   virtual int GetEnableFlag (int index);
   char *GetLibraryPath ();
   virtual int GetNumberOfOverrides ();
   virtual const char *GetOverrideDescription (int index);
   static void GetOverrideInformation (const char *name, vtkOverrideInformationCollection *);
   static vtkObjectFactoryCollection *GetRegisteredFactories ();
   virtual const char *GetVTKSourceVersion () = 0;
   virtual int HasOverride (const char *className, const char *subclassName);
   virtual int HasOverride (const char *className);
   static int HasOverrideAny (const char *className);
   static void ReHash ();
   static void RegisterFactory (vtkObjectFactory *);
   static void SetAllEnableFlags (int flag, const char *className, const char *subclassName);
   static void SetAllEnableFlags (int flag, const char *className);
   virtual void SetEnableFlag (int flag, const char *className, const char *subclassName);
   static void UnRegisterAllFactories ();
   static void UnRegisterFactory (vtkObjectFactory *);


B<vtkObjectFactory Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ObjectFactoryCollection;


@Graphics::VTK::ObjectFactoryCollection::ISA = qw( Graphics::VTK::Collection );

=head1 Graphics::VTK::ObjectFactoryCollection

=over 1

=item *

Inherits from Collection

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddItem (vtkObjectFactory *t);
   const char *GetClassName ();
   vtkObjectFactory *GetNextItem ();
   vtkObjectFactoryCollection *New ();

=cut

package Graphics::VTK::OrderedTriangulator;


@Graphics::VTK::OrderedTriangulator::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::OrderedTriangulator

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   long AddTetras (int classification, vtkUnstructuredGrid *ugrid);
   long AddTetras (int classification, vtkCellArray *connectivity);
   const char *GetClassName ();
   int GetPreSorted ();
   long GetTetras (int classification, vtkUnstructuredGrid *ugrid);
   vtkOrderedTriangulator *New ();
   void PreSortedOff ();
   void PreSortedOn ();
   void SetPreSorted (int );
   void Triangulate ();
   void UpdatePointType (long internalId, int type);


B<vtkOrderedTriangulator Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void InitTriangulation (float bounds[6], int numPts);
      Don't know the size of pointer arg number 1

   long InsertPoint (long id, float x[3], int type);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::OutputWindow;


@Graphics::VTK::OutputWindow::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::OutputWindow

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual void DisplayDebugText (const char *);
   virtual void DisplayErrorText (const char *);
   virtual void DisplayGenericWarningText (const char *);
   virtual void DisplayText (const char *);
   virtual void DisplayWarningText (const char *);
   const char *GetClassName ();
   static vtkOutputWindow *GetInstance ();
   vtkOutputWindow *New ();
   void PromptUserOff ();
   void PromptUserOn ();
   static void SetInstance (vtkOutputWindow *instance);
   void SetPromptUser (int );


B<vtkOutputWindow Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::OverrideInformation;


@Graphics::VTK::OverrideInformation::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::OverrideInformation

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   const char *GetClassOverrideName ();
   const char *GetClassOverrideWithName ();
   const char *GetDescription ();
   vtkObjectFactory *GetObjectFactory ();
   vtkOverrideInformation *New ();
   void SetClassOverrideName (char *);
   void SetClassOverrideWithName (char *);
   void SetDescription (char *);


B<vtkOverrideInformation Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::OverrideInformationCollection;


@Graphics::VTK::OverrideInformationCollection::ISA = qw( Graphics::VTK::Collection );

=head1 Graphics::VTK::OverrideInformationCollection

=over 1

=item *

Inherits from Collection

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddItem (vtkOverrideInformation *);
   const char *GetClassName ();
   vtkOverrideInformation *GetNextItem ();
   vtkOverrideInformationCollection *New ();

=cut

package Graphics::VTK::PerspectiveTransform;


@Graphics::VTK::PerspectiveTransform::ISA = qw( Graphics::VTK::HomogeneousTransform );

=head1 Graphics::VTK::PerspectiveTransform

=over 1

=item *

Inherits from HomogeneousTransform

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AdjustViewport (double oldXMin, double oldXMax, double oldYMin, double oldYMax, double newXMin, double newXMax, double newYMin, double newYMax);
   void AdjustZBuffer (double oldNearZ, double oldFarZ, double newNearZ, double newFarZ);
   int CircuitCheck (vtkAbstractTransform *transform);
   void Concatenate (vtkMatrix4x4 *matrix);
   void Concatenate (vtkHomogeneousTransform *transform);
   void Frustum (double xmin, double xmax, double ymin, double ymax, double znear, double zfar);
   const char *GetClassName ();
   vtkHomogeneousTransform *GetConcatenatedTransform (int i);
   vtkHomogeneousTransform *GetInput ();
   int GetInverseFlag ();
   unsigned long GetMTime ();
   int GetNumberOfConcatenatedTransforms ();
   void Identity ();
   void Inverse ();
   vtkAbstractTransform *MakeTransform ();
   vtkPerspectiveTransform *New ();
   void Ortho (double xmin, double xmax, double ymin, double ymax, double znear, double zfar);
   void Perspective (double angle, double aspect, double znear, double zfar);
   void Pop ();
   void PostMultiply ();
   void PreMultiply ();
   void Push ();
   void RotateWXYZ (double angle, double x, double y, double z);
   void RotateX (double angle);
   void RotateY (double angle);
   void RotateZ (double angle);
   void Scale (double x, double y, double z);
   void SetInput (vtkHomogeneousTransform *input);
   void SetMatrix (vtkMatrix4x4 *matrix);
   void Shear (double dxdz, double dydz, double zplane);
   void Stereo (double angle, double focaldistance);
   void Translate (double x, double y, double z);


B<vtkPerspectiveTransform Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void Concatenate (const double elements[16]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void RotateWXYZ (double angle, const double axis[3]);
      Don't know the size of pointer arg number 2

   void RotateWXYZ (double angle, const float axis[3]);
      Don't know the size of pointer arg number 2

   void Scale (const double s[3]);
      Method is redundant. Same as Scale( double, double, double)

   void Scale (const float s[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void SetMatrix (const double elements[16]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void SetupCamera (const double position[3], const double focalpoint[3], const double viewup[3]);
      Don't know the size of pointer arg number 1

   void Translate (const double x[3]);
      Method is redundant. Same as Translate( double, double, double)

   void Translate (const float x[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.


=cut

package Graphics::VTK::Pixel;


@Graphics::VTK::Pixel::ISA = qw( Graphics::VTK::Cell );

=head1 Graphics::VTK::Pixel

=over 1

=item *

Inherits from Cell

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Clip (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *polys, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd, int insideOut);
   void Contour (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *verts, vtkCellArray *lines, vtkCellArray *polys, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd);
   int GetCellDimension ();
   int GetCellType ();
   const char *GetClassName ();
   vtkCell *GetEdge (int edgeId);
   vtkCell *GetFace (int );
   int GetNumberOfEdges ();
   int GetNumberOfFaces ();
   vtkPixel *New ();
   int Triangulate (int index, vtkIdList *ptIds, vtkPoints *pts);


B<vtkPixel Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int CellBoundary (int subId, float pcoords[3], vtkIdList *pts);
      Don't know the size of pointer arg number 2

   void Derivatives (int subId, float pcoords[3], float *values, int dim, float *derivs);
      Don't know the size of pointer arg number 2

   void EvaluateLocation (int &subId, float pcoords[3], float x[3], float *weights);
      Don't know the size of pointer arg number 2

   int EvaluatePosition (float x[3], float *closestPoint, int &subId, float pcoords[3], float &dist2, float *weights);
      Don't know the size of pointer arg number 1

   static void InterpolationDerivs (float pcoords[3], float derivs[8]);
      Don't know the size of pointer arg number 1

   static void InterpolationFunctions (float pcoords[3], float weights[4]);
      Don't know the size of pointer arg number 1

   int IntersectWithLine (float p1[3], float p2[3], float tol, float &t, float x[3], float pcoords[3], int &subId);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::Plane;


@Graphics::VTK::Plane::ISA = qw( Graphics::VTK::ImplicitFunction );

=head1 Graphics::VTK::Plane

=over 1

=item *

Inherits from ImplicitFunction

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   float EvaluateFunction (float x, float y, float z);
   const char *GetClassName ();
   float  *GetNormal ();
      (Returns a 3-element Perl list)
   float  *GetOrigin ();
      (Returns a 3-element Perl list)
   vtkPlane *New ();
   void SetNormal (float , float , float );
   void SetOrigin (float , float , float );


B<vtkPlane Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   static float DistanceToPlane (float x[3], float n[3], float p0[3]);
      Don't know the size of pointer arg number 1

   static float Evaluate (float normal[3], float origin[3], float x[3]);
      Don't know the size of pointer arg number 1

   float EvaluateFunction (float x[3]);
      Method is redundant. Same as EvaluateFunction( float, float, float)

   void EvaluateGradient (float x[3], float g[3]);
      Don't know the size of pointer arg number 1

   static float Evaluate (double normal[3], double origin[3], double x[3]);
      Don't know the size of pointer arg number 1

   static void GeneralizedProjectPoint (float x[3], float origin[3], float normal[3], float xproj[3]);
      Don't know the size of pointer arg number 1

   static int IntersectWithLine (float p1[3], float p2[3], float n[3], float p0[3], float &t, float x[3]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   static void ProjectPoint (float x[3], float origin[3], float normal[3], float xproj[3]);
      Don't know the size of pointer arg number 1

   static void ProjectPoint (double x[3], double origin[3], double normal[3], double xproj[3]);
      Don't know the size of pointer arg number 1

   void SetNormal (float  a[3]);
      Method is redundant. Same as SetNormal( float, float, float)

   void SetOrigin (float  a[3]);
      Method is redundant. Same as SetOrigin( float, float, float)


=cut

package Graphics::VTK::PlaneCollection;


@Graphics::VTK::PlaneCollection::ISA = qw( Graphics::VTK::Collection );

=head1 Graphics::VTK::PlaneCollection

=over 1

=item *

Inherits from Collection

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddItem (vtkPlane *);
   const char *GetClassName ();
   vtkPlane *GetNextItem ();
   vtkPlaneCollection *New ();

=cut

package Graphics::VTK::Planes;


@Graphics::VTK::Planes::ISA = qw( Graphics::VTK::ImplicitFunction );

=head1 Graphics::VTK::Planes

=over 1

=item *

Inherits from ImplicitFunction

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   float EvaluateFunction (float x, float y, float z);
   const char *GetClassName ();
   vtkDataArray *GetNormals ();
   int GetNumberOfPlanes ();
   vtkPlane *GetPlane (int i);
   vtkPoints *GetPoints ();
   vtkPlanes *New ();
   void SetBounds (float xmin, float xmax, float ymin, float ymax, float zmin, float zmax);
   void SetNormals (vtkDataArray *normals);
   void SetPoints (vtkPoints *);


B<vtkPlanes Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   float EvaluateFunction (float x[3]);
      Method is redundant. Same as EvaluateFunction( float, float, float)

   void EvaluateGradient (float x[3], float n[3]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetBounds (float bounds[6]);
      Method is redundant. Same as SetBounds( float, float, float, float, float, float)

   void SetFrustumPlanes (float planes[24]);
      Can't handle methods with single array args (like a[3]) yet.


=cut

package Graphics::VTK::PointData;


@Graphics::VTK::PointData::ISA = qw( Graphics::VTK::DataSetAttributes );

=head1 Graphics::VTK::PointData

=over 1

=item *

Inherits from DataSetAttributes

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkPointData *New ();
   void NullPoint (long ptId);


B<vtkPointData Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::PointLocator;


@Graphics::VTK::PointLocator::ISA = qw( Graphics::VTK::Locator );

=head1 Graphics::VTK::PointLocator

=over 1

=item *

Inherits from Locator

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void BuildLocator ();
   virtual void FindClosestNPoints (int N, float x, float y, float z, vtkIdList *result);
   long FindClosestPoint (float x, float y, float z);
   virtual void FindDistributedPoints (int N, float x, float y, float z, vtkIdList *result, int M);
   virtual void FindPointsWithinRadius (float R, float x, float y, float z, vtkIdList *result);
   void FreeSearchStructure ();
   void GenerateRepresentation (int level, vtkPolyData *pd);
   const char *GetClassName ();
   int  *GetDivisions ();
      (Returns a 3-element Perl list)
   int GetNumberOfPointsPerBucket ();
   int GetNumberOfPointsPerBucketMaxValue ();
   int GetNumberOfPointsPerBucketMinValue ();
   void Initialize ();
   long IsInsertedPoint (float x, float y, float z);
   vtkPointLocator *New ();
   void SetDivisions (int , int , int );
   void SetNumberOfPointsPerBucket (int );


B<vtkPointLocator Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   float Distance2ToBounds (const float x[3], const float bounds[6]);
      Don't know the size of pointer arg number 1

   float Distance2ToBucket (const float x[3], const int nei[3]);
      Don't know the size of pointer arg number 1

   virtual long FindClosestInsertedPoint (const float x[3]);
      Can't handle methods with single array args (like a[3]) yet.

   virtual void FindClosestNPoints (int N, const float x[3], vtkIdList *result);
      Don't know the size of pointer arg number 2

   virtual long FindClosestPoint (const float x[3]);
      Method is redundant. Same as FindClosestPoint( float, float, float)

   long FindClosestPointWithinRadius (float radius, const float x[3], float &dist2);
      Don't know the size of pointer arg number 2

   long FindClosestPointWithinRadius (float radius, const float x[3], float inputDataLength, float &dist2);
      Don't know the size of pointer arg number 2

   virtual void FindDistributedPoints (int N, const float x[3], vtkIdList *result, int M);
      Don't know the size of pointer arg number 2

   virtual void FindPointsWithinRadius (float R, const float x[3], vtkIdList *result);
      Don't know the size of pointer arg number 2

   void GetBucketNeighbors (vtkNeighborPoints *buckets, const int ijk[3], const int ndivs[3], int level);
      Don't know the size of pointer arg number 2

   void GetOverlappingBuckets (vtkNeighborPoints *buckets, const float x[3], const int ijk[3], float dist, int level);
      Don't know the size of pointer arg number 2

   void GetOverlappingBuckets (vtkNeighborPoints *buckets, const float x[3], float dist, int prevMinLevel[3], int prevMaxLevel[3]);
      Don't know the size of pointer arg number 2

   virtual vtkIdList *GetPointsInBucket (const float x[3], int ijk[3]);
      Don't know the size of pointer arg number 1

   virtual int InitPointInsertion (vtkPoints *newPts, const float bounds[6]);
      Don't know the size of pointer arg number 2

   virtual int InitPointInsertion (vtkPoints *newPts, const float bounds[6], long estSize);
      Don't know the size of pointer arg number 2

   virtual long InsertNextPoint (const float x[3]);
      Can't handle methods with single array args (like a[3]) yet.

   virtual void InsertPoint (long ptId, const float x[3]);
      Don't know the size of pointer arg number 2

   virtual int InsertUniquePoint (const float x[3], long &ptId);
      Don't know the size of pointer arg number 1

   virtual long IsInsertedPoint (const float x[3]);
      Method is redundant. Same as IsInsertedPoint( float, float, float)

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetDivisions (int  a[3]);
      Method is redundant. Same as SetDivisions( int, int, int)


=cut

package Graphics::VTK::PointLocator2D;


@Graphics::VTK::PointLocator2D::ISA = qw( Graphics::VTK::Locator );

=head1 Graphics::VTK::PointLocator2D

=over 1

=item *

Inherits from Locator

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void BuildLocator ();
   virtual void FindClosestNPoints (int N, float x, float y, vtkIdList *result);
   virtual void FindDistributedPoints (int N, float x, float y, vtkIdList *result, int M);
   virtual void FindPointsWithinRadius (float R, float x, float y, vtkIdList *result);
   void FreeSearchStructure ();
   void GenerateRepresentation (int level, vtkPolyData *pd);
   const char *GetClassName ();
   int  *GetDivisions ();
      (Returns a 2-element Perl list)
   int GetNumberOfPointsPerBucket ();
   int GetNumberOfPointsPerBucketMaxValue ();
   int GetNumberOfPointsPerBucketMinValue ();
   vtkPoints *GetPoints ();
   void Initialize ();
   vtkPointLocator2D *New ();
   void SetDivisions (int , int );
   void SetNumberOfPointsPerBucket (int );
   void SetPoints (vtkPoints *);


B<vtkPointLocator2D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void FindClosestNPoints (int N, float x[2], vtkIdList *result);
      Don't know the size of pointer arg number 2

   virtual int FindClosestPoint (float x[2]);
      Can't handle methods with single array args (like a[3]) yet.

   virtual void FindDistributedPoints (int N, float x[2], vtkIdList *result, int M);
      Don't know the size of pointer arg number 2

   virtual void FindPointsWithinRadius (float R, float x[2], vtkIdList *result);
      Don't know the size of pointer arg number 2

   void GetBucketNeighbors (int ijk[2], int ndivs[2], int level);
      Don't know the size of pointer arg number 1

   void GetOverlappingBuckets (float x[2], int ijk[2], float dist, int level);
      Don't know the size of pointer arg number 1

   virtual int IsInsertedPoint (float x[2]);
      Can't handle methods with single array args (like a[3]) yet.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetDivisions (int  a[2]);
      Method is redundant. Same as SetDivisions( int, int)


=cut

package Graphics::VTK::PointSet;


@Graphics::VTK::PointSet::ISA = qw( Graphics::VTK::DataSet );

=head1 Graphics::VTK::PointSet

=over 1

=item *

Inherits from DataSet

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void ComputeBounds ();
   void CopyStructure (vtkDataSet *pd);
   void DeepCopy (vtkDataObject *src);
   long FindPoint (float x, float y, float z);
   unsigned long GetActualMemorySize ();
   const char *GetClassName ();
   unsigned long GetMTime ();
   virtual int GetNetReferenceCount ();
   long GetNumberOfPoints ();
   float *GetPoint (long ptId);
      (Returns a 3-element Perl list)
   vtkPoints *GetPoints ();
   void Initialize ();
   void SetPoints (vtkPoints *);
   void ShallowCopy (vtkDataObject *src);
   void Squeeze ();
   void UnRegister (vtkObject *o);


B<vtkPointSet Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   long FindCell (float x[3], vtkCell *cell, long cellId, float tol2, int &subId, float pcoords[3], float *weights);
      Don't know the size of pointer arg number 1

   long FindCell (float x[3], vtkCell *cell, vtkGenericCell *gencell, long cellId, float tol2, int &subId, float pcoords[3], float *weights);
      Don't know the size of pointer arg number 1

   long FindPoint (float x[3]);
      Method is redundant. Same as FindPoint( float, float, float)

   void GetPoint (long ptId, float x[3]);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::Points;


@Graphics::VTK::Points::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::Points

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual int Allocate (const long sz, const long ext);
   virtual void ComputeBounds ();
   virtual void DeepCopy (vtkPoints *ad);
   unsigned long GetActualMemorySize ();
   float *GetBounds ();
      (Returns a 6-element Perl list)
   const char *GetClassName ();
   vtkDataArray *GetData ();
   virtual int GetDataType ();
   long GetNumberOfPoints ();
   float *GetPoint (long id);
      (Returns a 3-element Perl list)
   void GetPoints (vtkIdList *ptId, vtkPoints *fp);
   virtual void Initialize ();
   long InsertNextPoint (double x, double y, double z);
   void InsertPoint (long id, double x, double y, double z);
   vtkPoints *New ();
   virtual void Reset ();
   virtual void SetData (vtkDataArray *);
   virtual void SetDataType (int dataType);
   void SetDataTypeToBit ();
   void SetDataTypeToChar ();
   void SetDataTypeToDouble ();
   void SetDataTypeToFloat ();
   void SetDataTypeToInt ();
   void SetDataTypeToLong ();
   void SetDataTypeToShort ();
   void SetDataTypeToUnsignedChar ();
   void SetDataTypeToUnsignedInt ();
   void SetDataTypeToUnsignedLong ();
   void SetDataTypeToUnsignedShort ();
   void SetNumberOfPoints (long number);
   void SetPoint (long id, double x, double y, double z);
   virtual void ShallowCopy (vtkPoints *ad);
   virtual void Squeeze ();


B<vtkPoints Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void GetBounds (float bounds[6]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void GetPoint (long id, float x[3]);
      Don't know the size of pointer arg number 2

   void GetPoint (long id, double x[3]);
      Don't know the size of pointer arg number 2

   void *GetVoidPointer (const int id);
      Can't Handle 'void *' return type without a hint

   long InsertNextPoint (const float x[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   long InsertNextPoint (const double x[3]);
      Method is redundant. Same as InsertNextPoint( double, double, double)

   void InsertPoint (long id, const float x[3]);
      Don't know the size of pointer arg number 2

   void InsertPoint (long id, const double x[3]);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetPoint (long id, const float x[3]);
      Don't know the size of pointer arg number 2

   void SetPoint (long id, const double x[3]);
      Don't know the size of pointer arg number 2


=cut

package Graphics::VTK::PolyData;


@Graphics::VTK::PolyData::ISA = qw( Graphics::VTK::PointSet );

=head1 Graphics::VTK::PolyData

=over 1

=item *

Inherits from PointSet

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddCellReference (long cellId);
   void AddReferenceToCell (long ptId, long cellId);
   void Allocate (vtkPolyData *inPolyData, long numCells, int extSize);
   void Allocate (long numCells, int extSize);
   void BuildCells ();
   void BuildLinks ();
   void ComputeBounds ();
   void CopyCells (vtkPolyData *pd, vtkIdList *idList, vtkPointLocator *locatorNULL);
   void CopyStructure (vtkDataSet *ds);
   void DeepCopy (vtkDataObject *src);
   void DeleteCell (long cellId);
   void DeleteCells ();
   void DeleteLinks ();
   void DeletePoint (long ptId);
   unsigned long GetActualMemorySize ();
   void GetCell (long cellId, vtkGenericCell *cell);
   vtkCell *GetCell (long cellId);
   void GetCellEdgeNeighbors (long cellId, long p1, long p2, vtkIdList *cellIds);
   void GetCellNeighbors (long cellId, vtkIdList *ptIds, vtkIdList *cellIds);
   void GetCellPoints (long cellId, vtkIdList *ptIds);
   int GetCellType (long cellId);
   const char *GetClassName ();
   int GetDataObjectType ();
   int GetGhostLevel ();
   vtkCellArray *GetLines ();
   int GetMaxCellSize ();
   long GetNumberOfCells ();
   long GetNumberOfLines ();
   int GetNumberOfPieces ();
   long GetNumberOfPolys ();
   long GetNumberOfStrips ();
   long GetNumberOfVerts ();
   int GetPiece ();
   void GetPointCells (long ptId, vtkIdList *cellIds);
   vtkCellArray *GetPolys ();
   vtkCellArray *GetStrips ();
   void GetUpdateExtent (int &piece, int &numPieces, int &ghostLevel);
   int  *GetUpdateExtent ();
      (Returns a 6-element Perl list)
   vtkCellArray *GetVerts ();
   virtual void Initialize ();
   int InsertNextCell (int type, vtkIdList *pts);
   int IsEdge (int v1, int v2);
   int IsPointUsedByCell (long ptId, long cellId);
   int IsTriangle (int v1, int v2, int v3);
   vtkPolyData *New ();
   void RemoveCellReference (long cellId);
   void RemoveGhostCells (int level);
   void RemoveReferenceToCell (long ptId, long cellId);
   void ReplaceCellPoint (long cellId, long oldPtId, long newPtId);
   void Reset ();
   void ResizeCellList (long ptId, int size);
   void ReverseCell (long cellId);
   void SetLines (vtkCellArray *l);
   void SetPolys (vtkCellArray *p);
   void SetStrips (vtkCellArray *s);
   void SetUpdateExtent (int x1, int x2, int y1, int y2, int z1, int z2);
   void SetUpdateExtent (int piece, int numPieces, int ghostLevel);
   void SetUpdateExtent (int piece, int numPieces);
   void SetVerts (vtkCellArray *v);
   void ShallowCopy (vtkDataObject *src);
   void Squeeze ();


B<vtkPolyData Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void GetCellBounds (long cellId, float bounds[6]);
      Don't know the size of pointer arg number 2

   void GetCellPoints (long cellId, long &npts, long &pts);
      Don't know the size of pointer arg number 2

   void GetPointCells (long ptId, unsigned short &ncells, long &cells);
      Arg types of 'unsigned short &' not supported yet
   int InsertNextCell (int type, int npts, long *pts);
      Don't know the size of pointer arg number 3

   int InsertNextLinkedCell (int type, int npts, long *pts);
      Don't know the size of pointer arg number 3

   int InsertNextLinkedPoint (float x[3], int numLinks);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ReplaceCell (long cellId, int npts, long *pts);
      Don't know the size of pointer arg number 3

   void ReplaceLinkedCell (long cellId, int npts, long *pts);
      Don't know the size of pointer arg number 3

   void SetUpdateExtent (int ext[6]);
      Method is redundant. Same as SetUpdateExtent( int, int, int, int, int, int)


=cut

package Graphics::VTK::PolyLine;


@Graphics::VTK::PolyLine::ISA = qw( Graphics::VTK::Cell );

=head1 Graphics::VTK::PolyLine

=over 1

=item *

Inherits from Cell

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Clip (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *lines, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd, int insideOut);
   void Contour (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *verts, vtkCellArray *lines, vtkCellArray *polys, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd);
   int GenerateSlidingNormals (vtkPoints *, vtkCellArray *, vtkDataArray *);
   int GetCellDimension ();
   int GetCellType ();
   const char *GetClassName ();
   vtkCell *GetEdge (int );
   vtkCell *GetFace (int );
   int GetNumberOfEdges ();
   int GetNumberOfFaces ();
   vtkPolyLine *New ();
   int Triangulate (int index, vtkIdList *ptIds, vtkPoints *pts);


B<vtkPolyLine Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int CellBoundary (int subId, float pcoords[3], vtkIdList *pts);
      Don't know the size of pointer arg number 2

   void Derivatives (int subId, float pcoords[3], float *values, int dim, float *derivs);
      Don't know the size of pointer arg number 2

   void EvaluateLocation (int &subId, float pcoords[3], float x[3], float *weights);
      Don't know the size of pointer arg number 2

   int EvaluatePosition (float x[3], float *closestPoint, int &subId, float pcoords[3], float &dist2, float *weights);
      Don't know the size of pointer arg number 1

   int GetParametricCenter (float pcoords[3]);
      Can't handle methods with single array args (like a[3]) yet.

   int IntersectWithLine (float p1[3], float p2[3], float tol, float &t, float x[3], float pcoords[3], int &subId);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::PolyVertex;


@Graphics::VTK::PolyVertex::ISA = qw( Graphics::VTK::Cell );

=head1 Graphics::VTK::PolyVertex

=over 1

=item *

Inherits from Cell

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Clip (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *verts, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd, int insideOut);
   void Contour (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *verts, vtkCellArray *lines, vtkCellArray *polys, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd);
   int GetCellDimension ();
   int GetCellType ();
   const char *GetClassName ();
   vtkCell *GetEdge (int );
   vtkCell *GetFace (int );
   int GetNumberOfEdges ();
   int GetNumberOfFaces ();
   vtkPolyVertex *New ();
   int Triangulate (int index, vtkIdList *ptIds, vtkPoints *pts);


B<vtkPolyVertex Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int CellBoundary (int subId, float pcoords[3], vtkIdList *pts);
      Don't know the size of pointer arg number 2

   void Derivatives (int subId, float pcoords[3], float *values, int dim, float *derivs);
      Don't know the size of pointer arg number 2

   void EvaluateLocation (int &subId, float pcoords[3], float x[3], float *weights);
      Don't know the size of pointer arg number 2

   int EvaluatePosition (float x[3], float *closestPoint, int &subId, float pcoords[3], float &dist2, float *weights);
      Don't know the size of pointer arg number 1

   int GetParametricCenter (float pcoords[3]);
      Can't handle methods with single array args (like a[3]) yet.

   int IntersectWithLine (float p1[3], float p2[3], float tol, float &t, float x[3], float pcoords[3], int &subId);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::Polygon;


@Graphics::VTK::Polygon::ISA = qw( Graphics::VTK::Cell );

=head1 Graphics::VTK::Polygon

=over 1

=item *

Inherits from Cell

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Clip (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *tris, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd, int insideOut);
   void Contour (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *verts, vtkCellArray *lines, vtkCellArray *polys, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd);
   int GetCellDimension ();
   int GetCellType ();
   const char *GetClassName ();
   vtkCell *GetEdge (int edgeId);
   vtkCell *GetFace (int );
   int GetNumberOfEdges ();
   int GetNumberOfFaces ();
   vtkPolygon *New ();
   int Triangulate (int index, vtkIdList *ptIds, vtkPoints *pts);
   int Triangulate (vtkIdList *outTris);


B<vtkPolygon Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int CellBoundary (int subId, float pcoords[3], vtkIdList *pts);
      Don't know the size of pointer arg number 2

   static void ComputeNormal (vtkPoints *p, int numPts, long *pts, float n[3]);
      Don't know the size of pointer arg number 3

   static void ComputeNormal (vtkPoints *p, float n[3]);
      Don't know the size of pointer arg number 2

   static void ComputeNormal (int numPts, float *pts, float n[3]);
      Don't know the size of pointer arg number 2

   void ComputeWeights (float x[3], float *weights);
      Don't know the size of pointer arg number 1

   void Derivatives (int subId, float pcoords[3], float *values, int dim, float *derivs);
      Don't know the size of pointer arg number 2

   void EvaluateLocation (int &subId, float pcoords[3], float x[3], float *weights);
      Don't know the size of pointer arg number 2

   int EvaluatePosition (float x[3], float *closestPoint, int &subId, float pcoords[3], float &dist2, float *weights);
      Don't know the size of pointer arg number 1

   static int IntersectPolygonWithPolygon (int npts, float *pts, float bounds[6], int npts2, float *pts2, float bounds2[3], float tol, float x[3]);
      Don't know the size of pointer arg number 2

   int IntersectWithLine (float p1[3], float p2[3], float tol, float &t, float x[3], float pcoords[3], int &subId);
      Don't know the size of pointer arg number 1

   int ParameterizePolygon (float p0[3], float p10[3], float &l10, float p20[3], float &l20, float n[3]);
      Don't know the size of pointer arg number 1

   static int PointInPolygon (float x[3], int numPts, float *pts, float bounds[6], float n[3]);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::PriorityQueue;


@Graphics::VTK::PriorityQueue::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::PriorityQueue

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Allocate (const long sz, const long ext);
   float DeleteId (long id);
   const char *GetClassName ();
   long GetNumberOfItems ();
   float GetPriority (long id);
   void Insert (float priority, long id);
   vtkPriorityQueue *New ();
   void Reset ();


B<vtkPriorityQueue Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ProcessObject;


@Graphics::VTK::ProcessObject::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::ProcessObject

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AbortExecuteOff ();
   void AbortExecuteOn ();
   int GetAbortExecute ();
   const char *GetClassName ();
   int GetNumberOfInputs ();
   float GetProgress ();
   float GetProgressMaxValue ();
   float GetProgressMinValue ();
   char *GetProgressText ();
   vtkProcessObject *New ();
   void RemoveAllInputs ();
   void SetAbortExecute (int );
   void SetEndMethod (void (*func)(void *) , void *arg);
   void SetProgress (float );
   void SetProgressMethod (void (*func)(void *) , void *arg);
   void SetProgressText (char *);
   void SetStartMethod (void (*func)(void *) , void *arg);
   void SqueezeInputArray ();
   void UpdateProgress (float amount);


B<vtkProcessObject Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   vtkDataObject *GetInputs ();
      Can't Handle 'vtkDataObject **' return type yet

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetEndMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void SetProgressMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void SetStartMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.


=cut

package Graphics::VTK::Prop;


@Graphics::VTK::Prop::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::Prop

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void DragableOff ();
   void DragableOn ();
   virtual void GetActors (vtkPropCollection *);
   virtual void GetActors2D (vtkPropCollection *);
   const char *GetClassName ();
   int GetDragable ();
   virtual vtkMatrix4x4 *GetMatrix ();
   virtual vtkAssemblyPath *GetNextPath ();
   virtual int GetNumberOfPaths ();
   int GetPickable ();
   virtual unsigned long GetRedrawMTime ();
   int GetVisibility ();
   virtual void GetVolumes (vtkPropCollection *);
   virtual void InitPathTraversal ();
   vtkProp *New ();
   virtual void Pick ();
   void PickableOff ();
   void PickableOn ();
   virtual void PokeMatrix (vtkMatrix4x4 *);
   void SetDragable (int );
   void SetPickMethod (void (*func)(void *) , void *arg);
   void SetPickable (int );
   void SetVisibility (int );
   virtual void ShallowCopy (vtkProp *prop);
   void VisibilityOff ();
   void VisibilityOn ();


B<vtkProp Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual float *GetBounds ();
      Can't Handle 'float *' return type without a hint

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetPickMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.


=cut

package Graphics::VTK::PropAssembly;


@Graphics::VTK::PropAssembly::ISA = qw( Graphics::VTK::Prop );

=head1 Graphics::VTK::PropAssembly

=over 1

=item *

Inherits from Prop

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddPart (vtkProp *);
   float *GetBounds ();
      (Returns a 6-element Perl list)
   const char *GetClassName ();
   unsigned long GetMTime ();
   vtkAssemblyPath *GetNextPath ();
   int GetNumberOfPaths ();
   vtkPropCollection *GetParts ();
   void InitPathTraversal ();
   vtkPropAssembly *New ();
   void ReleaseGraphicsResources (vtkWindow *);
   void RemovePart (vtkProp *);
   int RenderOpaqueGeometry (vtkViewport *ren);
   int RenderOverlay (vtkViewport *);
   int RenderTranslucentGeometry (vtkViewport *ren);
   void ShallowCopy (vtkProp *Prop);


B<vtkPropAssembly Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::PropCollection;


@Graphics::VTK::PropCollection::ISA = qw( Graphics::VTK::Collection );

=head1 Graphics::VTK::PropCollection

=over 1

=item *

Inherits from Collection

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddItem (vtkProp *a);
   const char *GetClassName ();
   vtkProp *GetLastProp ();
   vtkProp *GetNextProp ();
   int GetNumberOfPaths ();
   vtkPropCollection *New ();

=cut

package Graphics::VTK::Property2D;


@Graphics::VTK::Property2D::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::Property2D

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void DeepCopy (vtkProperty2D *p);
   const char *GetClassName ();
   float  *GetColor ();
      (Returns a 3-element Perl list)
   int GetDisplayLocation ();
   int GetDisplayLocationMaxValue ();
   int GetDisplayLocationMinValue ();
   int GetLineStipplePattern ();
   int GetLineStippleRepeatFactor ();
   int GetLineStippleRepeatFactorMaxValue ();
   int GetLineStippleRepeatFactorMinValue ();
   float GetLineWidth ();
   float GetLineWidthMaxValue ();
   float GetLineWidthMinValue ();
   float GetOpacity ();
   float GetPointSize ();
   float GetPointSizeMaxValue ();
   float GetPointSizeMinValue ();
   vtkProperty2D *New ();
   virtual void Render (vtkViewport *);
   void SetColor (float , float , float );
   void SetDisplayLocation (int );
   void SetDisplayLocationToBackground ();
   void SetDisplayLocationToForeground ();
   void SetLineStipplePattern (int );
   void SetLineStippleRepeatFactor (int );
   void SetLineWidth (float );
   void SetOpacity (float );
   void SetPointSize (float );


B<vtkProperty2D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetColor (float  a[3]);
      Method is redundant. Same as SetColor( float, float, float)


=cut

package Graphics::VTK::Pyramid;


@Graphics::VTK::Pyramid::ISA = qw( Graphics::VTK::Cell3D );

=head1 Graphics::VTK::Pyramid

=over 1

=item *

Inherits from Cell3D

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Contour (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *verts, vtkCellArray *lines, vtkCellArray *polys, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd);
   int GetCellDimension ();
   int GetCellType ();
   const char *GetClassName ();
   vtkCell *GetEdge (int edgeId);
   vtkCell *GetFace (int faceId);
   int GetNumberOfEdges ();
   int GetNumberOfFaces ();
   vtkPyramid *New ();
   int Triangulate (int index, vtkIdList *ptIds, vtkPoints *pts);


B<vtkPyramid Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int CellBoundary (int subId, float pcoords[3], vtkIdList *pts);
      Don't know the size of pointer arg number 2

   void Derivatives (int subId, float pcoords[3], float *values, int dim, float *derivs);
      Don't know the size of pointer arg number 2

   void EvaluateLocation (int &subId, float pcoords[3], float x[3], float *weights);
      Don't know the size of pointer arg number 2

   int EvaluatePosition (float x[3], float *closestPoint, int &subId, float pcoords[3], float &dist2, float *weights);
      Don't know the size of pointer arg number 1

   static int *GetEdgeArray (int edgeId);
      Can't Handle 'static int *' return type without a hint

   virtual void GetEdgePoints (int edgeId, int &pts);
      Don't know the size of pointer arg number 2

   static int *GetFaceArray (int faceId);
      Can't Handle 'static int *' return type without a hint

   virtual void GetFacePoints (int faceId, int &pts);
      Don't know the size of pointer arg number 2

   int GetParametricCenter (float pcoords[3]);
      Can't handle methods with single array args (like a[3]) yet.

   static void InterpolationDerivs (float pcoords[3], float derivs[15]);
      Don't know the size of pointer arg number 1

   static void InterpolationFunctions (float pcoords[3], float weights[5]);
      Don't know the size of pointer arg number 1

   int IntersectWithLine (float p1[3], float p2[3], float tol, float &t, float x[3], float pcoords[3], int &subId);
      Don't know the size of pointer arg number 1

   int JacobianInverse (float pcoords[3], double *inverse, float derivs[15]);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::Quad;


@Graphics::VTK::Quad::ISA = qw( Graphics::VTK::Cell );

=head1 Graphics::VTK::Quad

=over 1

=item *

Inherits from Cell

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Clip (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *polys, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd, int insideOut);
   void Contour (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *verts, vtkCellArray *lines, vtkCellArray *polys, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd);
   int GetCellDimension ();
   int GetCellType ();
   const char *GetClassName ();
   vtkCell *GetEdge (int edgeId);
   vtkCell *GetFace (int );
   int GetNumberOfEdges ();
   int GetNumberOfFaces ();
   vtkQuad *New ();
   int Triangulate (int index, vtkIdList *ptIds, vtkPoints *pts);


B<vtkQuad Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int CellBoundary (int subId, float pcoords[3], vtkIdList *pts);
      Don't know the size of pointer arg number 2

   void Derivatives (int subId, float pcoords[3], float *values, int dim, float *derivs);
      Don't know the size of pointer arg number 2

   void EvaluateLocation (int &subId, float pcoords[3], float x[3], float *weights);
      Don't know the size of pointer arg number 2

   int EvaluatePosition (float x[3], float *closestPoint, int &subId, float pcoords[3], float &dist2, float *weights);
      Don't know the size of pointer arg number 1

   static void InterpolationDerivs (float pcoords[3], float derivs[8]);
      Don't know the size of pointer arg number 1

   static void InterpolationFunctions (float pcoords[3], float sf[4]);
      Don't know the size of pointer arg number 1

   int IntersectWithLine (float p1[3], float p2[3], float tol, float &t, float x[3], float pcoords[3], int &subId);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::Quadric;


@Graphics::VTK::Quadric::ISA = qw( Graphics::VTK::ImplicitFunction );

=head1 Graphics::VTK::Quadric

=over 1

=item *

Inherits from ImplicitFunction

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   float EvaluateFunction (float x, float y, float z);
   const char *GetClassName ();
   float  *GetCoefficients ();
      (Returns a 10-element Perl list)
   vtkQuadric *New ();
   void SetCoefficients (float a0, float a1, float a2, float a3, float a4, float a5, float a6, float a7, float a8, float a9);


B<vtkQuadric Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   float EvaluateFunction (float x[3]);
      Method is redundant. Same as EvaluateFunction( float, float, float)

   void EvaluateGradient (float x[3], float g[3]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetCoefficients (float a[10]);
      Method is redundant. Same as SetCoefficients( float, float, float, float, float, float, float, float, float, float)


=cut

package Graphics::VTK::RectilinearGrid;


@Graphics::VTK::RectilinearGrid::ISA = qw( Graphics::VTK::DataSet );

=head1 Graphics::VTK::RectilinearGrid

=over 1

=item *

Inherits from DataSet

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void ComputeBounds ();
   void CopyStructure (vtkDataSet *ds);
   void DeepCopy (vtkDataObject *src);
   int FindPoint (float x, float y, float z);
   unsigned long GetActualMemorySize ();
   void GetCell (long cellId, vtkGenericCell *cell);
   vtkCell *GetCell (long cellId);
   void GetCellNeighbors (long cellId, vtkIdList *ptIds, vtkIdList *cellIds);
   void GetCellPoints (long cellId, vtkIdList *ptIds);
   int GetCellType (long cellId);
   const char *GetClassName ();
   int GetDataDimension ();
   int GetDataObjectType ();
   int  *GetDimensions ();
      (Returns a 3-element Perl list)
   int  *GetExtent ();
      (Returns a 6-element Perl list)
   int GetMaxCellSize ();
   long GetNumberOfCells ();
   long GetNumberOfPoints ();
   float *GetPoint (long ptId);
      (Returns a 3-element Perl list)
   void GetPointCells (long ptId, vtkIdList *cellIds);
   vtkDataArray *GetXCoordinates ();
   vtkDataArray *GetYCoordinates ();
   vtkDataArray *GetZCoordinates ();
   void Initialize ();
   vtkRectilinearGrid *New ();
   void SetDimensions (int i, int j, int k);
   void SetExtent (int x1, int x2, int y1, int y2, int z1, int z2);
   void SetUpdateExtent (int x1, int x2, int y1, int y2, int z1, int z2);
   void SetUpdateExtent (int piece, int numPieces, int ghostLevel);
   void SetUpdateExtent (int piece, int numPieces);
   void SetXCoordinates (vtkDataArray *);
   void SetYCoordinates (vtkDataArray *);
   void SetZCoordinates (vtkDataArray *);
   void ShallowCopy (vtkDataObject *src);


B<vtkRectilinearGrid Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   long ComputeCellId (int ijk[3]);
      Can't handle methods with single array args (like a[3]) yet.

   long ComputePointId (int ijk[3]);
      Can't handle methods with single array args (like a[3]) yet.

   int ComputeStructuredCoordinates (float x[3], int ijk[3], float pcoords[3]);
      Don't know the size of pointer arg number 1

   vtkCell *FindAndGetCell (float x[3], vtkCell *cell, long cellId, float tol2, int &subId, float pcoords[3], float *weights);
      Don't know the size of pointer arg number 1

   long FindCell (float x[3], vtkCell *cell, long cellId, float tol2, int &subId, float pcoords[3], float *weights);
      Don't know the size of pointer arg number 1

   long FindCell (float x[3], vtkCell *cell, vtkGenericCell *gencell, long cellId, float tol2, int &subId, float pcoords[3], float *weights);
      Don't know the size of pointer arg number 1

   long FindPoint (float x[3]);
      Method is redundant. Same as FindPoint( float, float, float)

   void GetCellBounds (long cellId, float bounds[6]);
      Don't know the size of pointer arg number 2

   void GetCellNeighbors (long cellId, vtkIdList &ptIds, vtkIdList &cellIds);
      Method is marked 'Do Not Use' in its descriptions

   void GetPoint (long id, float x[3]);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetDimensions (int dim[3]);
      Method is redundant. Same as SetDimensions( int, int, int)

   void SetExtent (int extent[6]);
      Method is redundant. Same as SetExtent( int, int, int, int, int, int)

   void SetUpdateExtent (int ext[6]);
      Method is redundant. Same as SetUpdateExtent( int, int, int, int, int, int)


=cut

package Graphics::VTK::ReferenceCount;


@Graphics::VTK::ReferenceCount::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::ReferenceCount

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkReferenceCount *New ();


B<vtkReferenceCount Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::RungeKutta2;


@Graphics::VTK::RungeKutta2::ISA = qw( Graphics::VTK::InitialValueProblemSolver );

=head1 Graphics::VTK::RungeKutta2

=over 1

=item *

Inherits from InitialValueProblemSolver

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkRungeKutta2 *New ();


B<vtkRungeKutta2 Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual float ComputeNextStep (float *xprev, float *xnext, float t, float delT);
      Don't know the size of pointer arg number 1

   virtual float ComputeNextStep (float *xprev, float *dxprev, float *xnext, float t, float delT);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::RungeKutta4;


@Graphics::VTK::RungeKutta4::ISA = qw( Graphics::VTK::InitialValueProblemSolver );

=head1 Graphics::VTK::RungeKutta4

=over 1

=item *

Inherits from InitialValueProblemSolver

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkRungeKutta4 *New ();


B<vtkRungeKutta4 Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual float ComputeNextStep (float *xprev, float *xnext, float t, float delT);
      Don't know the size of pointer arg number 1

   virtual float ComputeNextStep (float *xprev, float *dxprev, float *xnext, float t, float delT);
      Don't know the size of pointer arg number 1

   virtual void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ScalarsToColors;


@Graphics::VTK::ScalarsToColors::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::ScalarsToColors

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual void Build ();
   virtual vtkUnsignedCharArray *ConvertUnsignedCharToRGBA (vtkUnsignedCharArray *colors, int numComp, int numTuples);
   float GetAlpha ();
   const char *GetClassName ();
   float *GetColor (float v);
      (Returns a 3-element Perl list)
   float GetLuminance (float x);
   virtual float GetOpacity (float );
   vtkUnsignedCharArray *MapScalars (vtkDataArray *scalars, int colorMode, int component);
   void SetAlpha (float alpha);
   virtual void SetRange (float min, float max) = 0;


B<vtkScalarsToColors Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void GetColor (float v, float rgb[3]) = 0;
      Don't know the size of pointer arg number 2

   virtual float *GetRange () = 0;
      Can't Handle 'float *' return type without a hint

   void MapScalarsThroughTable (vtkDataArray *scalars, unsigned char *output, int outputFormat);
      Don't know the size of pointer arg number 2

   virtual void MapScalarsThroughTable2 (void *input, unsigned char *output, int inputDataType, int numberOfValues, int inputIncrement, int outputFormat) = 0;
      Don't know the size of pointer arg number 1

   void MapScalarsThroughTable (vtkDataArray *scalars, unsigned char *output);
      Don't know the size of pointer arg number 2

   virtual unsigned char *MapValue (float v) = 0;
      Can't Handle 'unsigned char *' return type without a hint

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetRange (float rng[2]);
      Method is redundant. Same as SetRange( float, float)


=cut

package Graphics::VTK::ShortArray;


@Graphics::VTK::ShortArray::ISA = qw( Graphics::VTK::DataArray );

=head1 Graphics::VTK::ShortArray

=over 1

=item *

Inherits from DataArray

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int Allocate (const long sz, const long ext);
   void DeepCopy (vtkDataArray *da);
   const char *GetClassName ();
   float GetComponent (const long i, const int j);
   int GetDataType ();
   short GetValue (const long id);
   void Initialize ();
   void InsertComponent (const long i, const int j, const float c);
   long InsertNextValue (const short );
   void InsertValue (const long id, const short i);
   vtkShortArray *New ();
   virtual void Resize (long numTuples);
   void SetComponent (const long i, const int j, const float c);
   void SetNumberOfTuples (const long number);
   void SetNumberOfValues (const long number);
   void SetValue (const long id, const short value);
   void Squeeze ();


B<vtkShortArray Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   short *GetPointer (const long id);
      Can't Handle 'short *' return type without a hint

   float *GetTuple (const long i);
      Can't Handle 'float *' return type without a hint

   void GetTuple (const long i, float *tuple);
      Don't know the size of pointer arg number 2

   void GetTuple (const long i, double *tuple);
      Don't know the size of pointer arg number 2

   void *GetVoidPointer (const long id);
      Can't Handle 'void *' return type without a hint

   long InsertNextTuple (const float *tuple);
      Don't know the size of pointer arg number 1

   long InsertNextTuple (const double *tuple);
      Don't know the size of pointer arg number 1

   void InsertTuple (const long i, const float *tuple);
      Don't know the size of pointer arg number 2

   void InsertTuple (const long i, const double *tuple);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   short *ResizeAndExtend (const long sz);
      Can't Handle 'short *' return type without a hint

   void SetArray (short *array, long size, int save);
      Don't know the size of pointer arg number 1

   void SetTuple (const long i, const float *tuple);
      Don't know the size of pointer arg number 2

   void SetTuple (const long i, const double *tuple);
      Don't know the size of pointer arg number 2

   void SetVoidArray (void *array, long size, int save);
      Don't know the size of pointer arg number 1

   short *WritePointer (const long id, const long number);
      Can't Handle 'short *' return type without a hint


=cut

package Graphics::VTK::Source;


@Graphics::VTK::Source::ISA = qw( Graphics::VTK::ProcessObject );

=head1 Graphics::VTK::Source

=over 1

=item *

Inherits from ProcessObject

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual void ComputeInputUpdateExtents (vtkDataObject *output);
   virtual void EnlargeOutputUpdateExtents (vtkDataObject *output);
   const char *GetClassName ();
   int GetNumberOfOutputs ();
   int GetOutputIndex (vtkDataObject *out);
   virtual int GetReleaseDataFlag ();
   virtual int InRegisterLoop (vtkObject *);
   vtkSource *New ();
   virtual void PropagateUpdateExtent (vtkDataObject *output);
   void ReleaseDataFlagOff ();
   void ReleaseDataFlagOn ();
   virtual void SetReleaseDataFlag (int );
   virtual void TriggerAsynchronousUpdate ();
   void UnRegister (vtkObject *o);
   void UnRegisterAllOutputs (void );
   virtual void Update ();
   virtual void UpdateData (vtkDataObject *output);
   virtual void UpdateInformation ();
   virtual void UpdateWholeExtent ();


B<vtkSource Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   vtkDataObject *GetOutputs ();
      Can't Handle 'vtkDataObject **' return type yet

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::StructuredData;


@Graphics::VTK::StructuredData::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::StructuredData

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   static int GetDataDimension (int dataDescription);
   vtkStructuredData *New ();


B<vtkStructuredData Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   static long ComputeCellId (int dim[3], int ijk[3]);
      Don't know the size of pointer arg number 1

   static long ComputePointId (int dim[3], int ijk[3]);
      Don't know the size of pointer arg number 1

   static void GetCellNeigbors (long cellId, vtkIdList *ptIds, vtkIdList *cellIds, int dim[3]);
      Don't know the size of pointer arg number 4

   static void GetCellPoints (long cellId, vtkIdList *ptIds, int dataDescription, int dim[3]);
      Don't know the size of pointer arg number 4

   static void GetPointCells (long ptId, vtkIdList *cellIds, int dim[3]);
      Don't know the size of pointer arg number 3

   static int SetDimensions (int inDim[3], int dim[3]);
      Don't know the size of pointer arg number 1

   static int SetExtent (int inExt[6], int ext[6]);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::StructuredGrid;


@Graphics::VTK::StructuredGrid::ISA = qw( Graphics::VTK::PointSet );

=head1 Graphics::VTK::StructuredGrid

=over 1

=item *

Inherits from PointSet

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void BlankPoint (long ptId);
   void BlankingOff ();
   void BlankingOn ();
   void CopyStructure (vtkDataSet *ds);
   void DeepCopy (vtkDataObject *src);
   unsigned long GetActualMemorySize ();
   int GetBlanking ();
   void GetCell (long cellId, vtkGenericCell *cell);
   vtkCell *GetCell (long cellId);
   void GetCellNeighbors (long cellId, vtkIdList *ptIds, vtkIdList *cellIds);
   void GetCellPoints (long cellId, vtkIdList *ptIds);
   int GetCellType (long cellId);
   const char *GetClassName ();
   int GetDataDimension ();
   int GetDataObjectType ();
   virtual int *GetDimensions ();
      (Returns a 3-element Perl list)
   int  *GetExtent ();
      (Returns a 6-element Perl list)
   int GetMaxCellSize ();
   long GetNumberOfCells ();
   long GetNumberOfPoints ();
   float *GetPoint (long ptId);
      (Returns a 3-element Perl list)
   void GetPointCells (long ptId, vtkIdList *cellIds);
   vtkUnsignedCharArray *GetPointVisibility ();
   float *GetScalarRange ();
      (Returns a 2-element Perl list)
   void Initialize ();
   unsigned char IsCellVisible (long cellId);
   unsigned char IsPointVisible (long ptId);
   vtkStructuredGrid *New ();
   void SetBlanking (int blanking);
   void SetDimensions (int i, int j, int k);
   void SetExtent (int x1, int x2, int y1, int y2, int z1, int z2);
   void SetPointVisibility (vtkUnsignedCharArray *pointVisibility);
   void SetUpdateExtent (int x1, int x2, int y1, int y2, int z1, int z2);
   void SetUpdateExtent (int piece, int numPieces, int ghostLevel);
   void SetUpdateExtent (int piece, int numPieces);
   void ShallowCopy (vtkDataObject *src);
   void UnBlankPoint (long ptId);


B<vtkStructuredGrid Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void GetCellBounds (long cellId, float bounds[6]);
      Don't know the size of pointer arg number 2

   virtual void GetDimensions (int dim[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void GetPoint (long ptId, float p[3]);
      Don't know the size of pointer arg number 2

   virtual void GetScalarRange (float range[2]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetDimensions (int dim[3]);
      Method is redundant. Same as SetDimensions( int, int, int)

   void SetExtent (int extent[6]);
      Method is redundant. Same as SetExtent( int, int, int, int, int, int)

   void SetUpdateExtent (int ext[6]);
      Method is redundant. Same as SetUpdateExtent( int, int, int, int, int, int)


=cut

package Graphics::VTK::StructuredPoints;


@Graphics::VTK::StructuredPoints::ISA = qw( Graphics::VTK::ImageData );

=head1 Graphics::VTK::StructuredPoints

=over 1

=item *

Inherits from ImageData

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetDataObjectType ();
   vtkStructuredPoints *New ();

=cut

package Graphics::VTK::Tensor;


@Graphics::VTK::Tensor::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::Tensor

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddComponent (int i, int j, float v);
   void DeepCopy (vtkTensor *t);
   const char *GetClassName ();
   float *GetColumn (int j);
      (Returns a 3-element Perl list)
   float GetComponent (int i, int j);
   void Initialize ();
   vtkTensor *New ();
   void SetComponent (int i, int j, float v);


B<vtkTensor Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void vtkTensor
      No TCL interface is provided by VTK, so we aren't going to provide one either.


=cut

package Graphics::VTK::Tetra;


@Graphics::VTK::Tetra::ISA = qw( Graphics::VTK::Cell3D );

=head1 Graphics::VTK::Tetra

=over 1

=item *

Inherits from Cell3D

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Clip (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *connectivity, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd, int insideOut);
   void Contour (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *verts, vtkCellArray *lines, vtkCellArray *polys, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd);
   int GetCellType ();
   const char *GetClassName ();
   vtkCell *GetEdge (int edgeId);
   vtkCell *GetFace (int faceId);
   int GetNumberOfEdges ();
   int GetNumberOfFaces ();
   vtkTetra *New ();
   int Triangulate (int index, vtkIdList *ptIds, vtkPoints *pts);


B<vtkTetra Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   static int BarycentricCoords (double x[3], double x1[3], double x2[3], double x3[3], double x4[3], double bcoords[4]);
      Don't know the size of pointer arg number 1

   int CellBoundary (int subId, float pcoords[3], vtkIdList *pts);
      Don't know the size of pointer arg number 2

   static double Circumsphere (double p1[3], double p2[3], double p3[3], double p4[3], double center[3]);
      Don't know the size of pointer arg number 1

   static double ComputeVolume (double p1[3], double p2[3], double p3[3], double p4[3]);
      Don't know the size of pointer arg number 1

   void Derivatives (int subId, float pcoords[3], float *values, int dim, float *derivs);
      Don't know the size of pointer arg number 2

   void EvaluateLocation (int &subId, float pcoords[3], float x[3], float *weights);
      Don't know the size of pointer arg number 2

   int EvaluatePosition (float x[3], float *closestPoint, int &subId, float pcoords[3], float &dist2, float *weights);
      Don't know the size of pointer arg number 1

   static int *GetEdgeArray (int edgeId);
      Can't Handle 'static int *' return type without a hint

   virtual void GetEdgePoints (int edgeId, int &pts);
      Don't know the size of pointer arg number 2

   static int *GetFaceArray (int faceId);
      Can't Handle 'static int *' return type without a hint

   virtual void GetFacePoints (int faceId, int &pts);
      Don't know the size of pointer arg number 2

   int GetParametricCenter (float pcoords[3]);
      Can't handle methods with single array args (like a[3]) yet.

   static void InterpolationDerivs (float derivs[12]);
      Can't handle methods with single array args (like a[3]) yet.

   static void InterpolationFunctions (float pcoords[3], float weights[4]);
      Don't know the size of pointer arg number 1

   int IntersectWithLine (float p1[3], float p2[3], float tol, float &t, float x[3], float pcoords[3], int &subId);
      Don't know the size of pointer arg number 1

   int JacobianInverse (double *inverse, float derivs[12]);
      Don't know the size of pointer arg number 1

   static void TetraCenter (float p1[3], float p2[3], float p3[3], float p4[3], float center[3]);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::TimeStamp;


=head1 Graphics::VTK::TimeStamp

=over 1

=item *

Inherits from 

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Delete ();
   virtual const char *GetClassName ();
   unsigned long GetMTime ();
   void Modified ();
   vtkTimeStamp *New ();


B<vtkTimeStamp Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int vtkTimeStamp ts return this ModifiedTime ts ModifiedTime
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   unsigned long return this ModifiedTime
      No TCL interface is provided by VTK, so we aren't going to provide one either.


=cut

package Graphics::VTK::TimerLog;


@Graphics::VTK::TimerLog::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::TimerLog

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   static void AllocateLog ();
   static void DumpLog (char *filename);
   static double GetCPUTime ();
   const char *GetClassName ();
   static double GetCurrentTime ();
   double GetElapsedTime ();
   static int GetMaxEntries ();
   static void MarkEvent (char *EventString);
   vtkTimerLog *New ();
   static void ResetLog ();
   static void SetMaxEntries (int a);
   void StartTimer ();
   void StopTimer ();


B<vtkTimerLog Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::Transform;


@Graphics::VTK::Transform::ISA = qw( Graphics::VTK::LinearTransform );

=head1 Graphics::VTK::Transform

=over 1

=item *

Inherits from LinearTransform

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int CircuitCheck (vtkAbstractTransform *transform);
   void Concatenate (vtkMatrix4x4 *matrix);
   void Concatenate (vtkLinearTransform *transform);
   const char *GetClassName ();
   vtkLinearTransform *GetConcatenatedTransform (int i);
   vtkLinearTransform *GetInput ();
   void GetInverse (vtkMatrix4x4 *inverse);
   vtkAbstractTransform *GetInverse ();
   int GetInverseFlag ();
   unsigned long GetMTime ();
   int GetNumberOfConcatenatedTransforms ();
   float *GetOrientation ();
      (Returns a 3-element Perl list)
   float *GetOrientationWXYZ ();
      (Returns a 4-element Perl list)
   float *GetPosition ();
      (Returns a 3-element Perl list)
   float *GetScale ();
      (Returns a 3-element Perl list)
   void GetTranspose (vtkMatrix4x4 *transpose);
   void Identity ();
   void Inverse ();
   vtkAbstractTransform *MakeTransform ();
   vtkTransform *New ();
   void Pop ();
   void PostMultiply ();
   void PreMultiply ();
   void Push ();
   void RotateWXYZ (double angle, double x, double y, double z);
   void RotateX (double angle);
   void RotateY (double angle);
   void RotateZ (double angle);
   void Scale (double x, double y, double z);
   void SetInput (vtkLinearTransform *input);
   void SetMatrix (vtkMatrix4x4 *matrix);
   void Translate (double x, double y, double z);


B<vtkTransform Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void Concatenate (const double elements[16]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void GetOrientation (double orient[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void GetOrientationWXYZ (double wxyz[4]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void GetOrientationWXYZ (float wxyz[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void GetOrientation (float orient[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void GetPosition (double pos[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void GetPosition (float pos[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void GetScale (double scale[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void GetScale (float scale[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void MultiplyPoint (const float in[4], float out[4]);
      Don't know the size of pointer arg number 1

   void MultiplyPoint (const double in[4], double out[4]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void RotateWXYZ (double angle, const double axis[3]);
      Don't know the size of pointer arg number 2

   void RotateWXYZ (double angle, const float axis[3]);
      Don't know the size of pointer arg number 2

   void Scale (const double s[3]);
      Method is redundant. Same as Scale( double, double, double)

   void Scale (const float s[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void SetMatrix (const double elements[16]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void Translate (const double x[3]);
      Method is redundant. Same as Translate( double, double, double)

   void Translate (const float x[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.


=cut

package Graphics::VTK::TransformCollection;


@Graphics::VTK::TransformCollection::ISA = qw( Graphics::VTK::Collection );

=head1 Graphics::VTK::TransformCollection

=over 1

=item *

Inherits from Collection

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddItem (vtkTransform *);
   const char *GetClassName ();
   vtkTransform *GetNextItem ();
   vtkTransformCollection *New ();

=cut

package Graphics::VTK::Triangle;


@Graphics::VTK::Triangle::ISA = qw( Graphics::VTK::Cell );

=head1 Graphics::VTK::Triangle

=over 1

=item *

Inherits from Cell

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Clip (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *polys, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd, int insideOut);
   void Contour (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *verts, vtkCellArray *lines, vtkCellArray *polys, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd);
   int GetCellDimension ();
   int GetCellType ();
   const char *GetClassName ();
   vtkCell *GetEdge (int edgeId);
   vtkCell *GetFace (int );
   int GetNumberOfEdges ();
   int GetNumberOfFaces ();
   vtkTriangle *New ();
   int Triangulate (int index, vtkIdList *ptIds, vtkPoints *pts);


B<vtkTriangle Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   static int BarycentricCoords (double x[2], double x1[2], double x2[2], double x3[2], double bcoords[3]);
      Don't know the size of pointer arg number 1

   int CellBoundary (int subId, float pcoords[3], vtkIdList *pts);
      Don't know the size of pointer arg number 2

   static double Circumcircle (double p1[2], double p2[2], double p3[2], double center[2]);
      Don't know the size of pointer arg number 1

   static void ComputeNormal (vtkPoints *p, int numPts, long *pts, float n[3]);
      Don't know the size of pointer arg number 3

   static void ComputeNormalDirection (float v1[3], float v2[3], float v3[3], float n[3]);
      Don't know the size of pointer arg number 1

   static void ComputeNormalDirection (double v1[3], double v2[3], double v3[3], double n[3]);
      Don't know the size of pointer arg number 1

   static void ComputeNormal (float v1[3], float v2[3], float v3[3], float n[3]);
      Don't know the size of pointer arg number 1

   static void ComputeNormal (double v1[3], double v2[3], double v3[3], double n[3]);
      Don't know the size of pointer arg number 1

   static void ComputeQuadric (float x1[3], float x2[3], float x3[3], float quadric[4][4]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   static void ComputeQuadric (float x1[3], float x2[3], float x3[3], vtkQuadric *quadric);
      Don't know the size of pointer arg number 1

   void Derivatives (int subId, float pcoords[3], float *values, int dim, float *derivs);
      Don't know the size of pointer arg number 2

   void EvaluateLocation (int &subId, float pcoords[3], float x[3], float *weights);
      Don't know the size of pointer arg number 2

   int EvaluatePosition (float x[3], float *closestPoint, int &subId, float pcoords[3], float &dist2, float *weights);
      Don't know the size of pointer arg number 1

   int GetParametricCenter (float pcoords[3]);
      Can't handle methods with single array args (like a[3]) yet.

   int IntersectWithLine (float p1[3], float p2[3], float tol, float &t, float x[3], float pcoords[3], int &subId);
      Don't know the size of pointer arg number 1

   static int PointInTriangle (float x[3], float x1[3], float x2[3], float x3[3], float tol2);
      Don't know the size of pointer arg number 1

   static int ProjectTo2D (double x1[3], double x2[3], double x3[3], double v1[2], double v2[2], double v3[2]);
      Don't know the size of pointer arg number 1

   static float TriangleArea (float p1[3], float p2[3], float p3[3]);
      Don't know the size of pointer arg number 1

   static void TriangleCenter (float p1[3], float p2[3], float p3[3], float center[3]);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::TriangleStrip;


@Graphics::VTK::TriangleStrip::ISA = qw( Graphics::VTK::Cell );

=head1 Graphics::VTK::TriangleStrip

=over 1

=item *

Inherits from Cell

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Clip (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *polys, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd, int insideOut);
   void Contour (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *verts, vtkCellArray *lines, vtkCellArray *polys, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd);
   int GetCellDimension ();
   int GetCellType ();
   const char *GetClassName ();
   vtkCell *GetEdge (int edgeId);
   vtkCell *GetFace (int );
   int GetNumberOfEdges ();
   int GetNumberOfFaces ();
   vtkTriangleStrip *New ();
   int Triangulate (int index, vtkIdList *ptIds, vtkPoints *pts);


B<vtkTriangleStrip Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int CellBoundary (int subId, float pcoords[3], vtkIdList *pts);
      Don't know the size of pointer arg number 2

   static void DecomposeStrip (int npts, long *pts, vtkCellArray *tris);
      Don't know the size of pointer arg number 2

   void Derivatives (int subId, float pcoords[3], float *values, int dim, float *derivs);
      Don't know the size of pointer arg number 2

   void EvaluateLocation (int &subId, float pcoords[3], float x[3], float *weights);
      Don't know the size of pointer arg number 2

   int EvaluatePosition (float x[3], float *closestPoint, int &subId, float pcoords[3], float &dist2, float *weights);
      Don't know the size of pointer arg number 1

   int GetParametricCenter (float pcoords[3]);
      Can't handle methods with single array args (like a[3]) yet.

   int IntersectWithLine (float p1[3], float p2[3], float tol, float &t, float x[3], float pcoords[3], int &subId);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::UnsignedCharArray;


@Graphics::VTK::UnsignedCharArray::ISA = qw( Graphics::VTK::DataArray );

=head1 Graphics::VTK::UnsignedCharArray

=over 1

=item *

Inherits from DataArray

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int Allocate (const long sz, const long ext);
   void DeepCopy (vtkDataArray *da);
   const char *GetClassName ();
   float GetComponent (const long i, const int j);
   int GetDataType ();
   unsigned char GetValue (const long id);
   void Initialize ();
   void InsertComponent (const long i, const int j, const float c);
   long InsertNextValue (const unsigned char c);
   void InsertValue (const long id, const unsigned char c);
   vtkUnsignedCharArray *New ();
   virtual void Resize (long numTuples);
   void SetComponent (const long i, const int j, const float c);
   void SetNumberOfTuples (const long number);
   void SetNumberOfValues (const long number);
   void SetValue (const long id, const unsigned char value);
   void Squeeze ();


B<vtkUnsignedCharArray Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   unsigned char *GetPointer (const long id);
      Can't Handle 'unsigned char *' return type without a hint

   float *GetTuple (const long i);
      Can't Handle 'float *' return type without a hint

   void GetTuple (const long i, float *tuple);
      Don't know the size of pointer arg number 2

   void GetTuple (const long i, double *tuple);
      Don't know the size of pointer arg number 2

   void *GetVoidPointer (const long id);
      Can't Handle 'void *' return type without a hint

   long InsertNextTuple (const float *tuple);
      Don't know the size of pointer arg number 1

   long InsertNextTuple (const double *tuple);
      Don't know the size of pointer arg number 1

   void InsertTuple (const long i, const float *tuple);
      Don't know the size of pointer arg number 2

   void InsertTuple (const long i, const double *tuple);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   unsigned char *ResizeAndExtend (const long sz);
      Can't Handle 'unsigned char *' return type without a hint

   void SetArray (unsigned char *array, long size, int save);
      Don't know the size of pointer arg number 1

   void SetTuple (const long i, const float *tuple);
      Don't know the size of pointer arg number 2

   void SetTuple (const long i, const double *tuple);
      Don't know the size of pointer arg number 2

   void SetVoidArray (void *array, long size, int save);
      Don't know the size of pointer arg number 1

   unsigned char *WritePointer (const long id, const long number);
      Can't Handle 'unsigned char *' return type without a hint


=cut

package Graphics::VTK::UnsignedIntArray;


@Graphics::VTK::UnsignedIntArray::ISA = qw( Graphics::VTK::DataArray );

=head1 Graphics::VTK::UnsignedIntArray

=over 1

=item *

Inherits from DataArray

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int Allocate (const long sz, const long ext);
   void DeepCopy (vtkDataArray *da);
   void DeepCopy (vtkDataArray &da);
   const char *GetClassName ();
   int GetDataType ();
   unsigned int GetValue (const long id);
   void Initialize ();
   virtual void InsertComponent (const long i, const int j, const float c);
   long InsertNextValue (const unsigned int );
   void InsertValue (const long id, const unsigned int i);
   vtkUnsignedIntArray *New ();
   virtual void Resize (long numTuples);
   void SetNumberOfTuples (const long number);
   void SetNumberOfValues (const long number);
   void SetValue (const long id, const unsigned int value);
   void Squeeze ();


B<vtkUnsignedIntArray Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   unsigned int *GetPointer (const long id);
      Can't Handle 'unsigned int *' return type without a hint

   float *GetTuple (const long i);
      Can't Handle 'float *' return type without a hint

   void GetTuple (const long i, float *tuple);
      Don't know the size of pointer arg number 2

   void GetTuple (const long i, double *tuple);
      Don't know the size of pointer arg number 2

   void *GetVoidPointer (const long id);
      Can't Handle 'void *' return type without a hint

   long InsertNextTuple (const float *tuple);
      Don't know the size of pointer arg number 1

   long InsertNextTuple (const double *tuple);
      Don't know the size of pointer arg number 1

   void InsertTuple (const long i, const float *tuple);
      Don't know the size of pointer arg number 2

   void InsertTuple (const long i, const double *tuple);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   unsigned int *ResizeAndExtend (const long sz);
      Can't Handle 'unsigned int *' return type without a hint

   void SetArray (unsigned int *array, long size, int save);
      Don't know the size of pointer arg number 1

   void SetTuple (const long i, const float *tuple);
      Don't know the size of pointer arg number 2

   void SetTuple (const long i, const double *tuple);
      Don't know the size of pointer arg number 2

   void SetVoidArray (void *array, long size, int save);
      Don't know the size of pointer arg number 1

   unsigned int *WritePointer (const long id, const long number);
      Can't Handle 'unsigned int *' return type without a hint


=cut

package Graphics::VTK::UnsignedLongArray;


@Graphics::VTK::UnsignedLongArray::ISA = qw( Graphics::VTK::DataArray );

=head1 Graphics::VTK::UnsignedLongArray

=over 1

=item *

Inherits from DataArray

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int Allocate (const long sz, const long ext);
   void DeepCopy (vtkDataArray *da);
   void DeepCopy (vtkDataArray &da);
   const char *GetClassName ();
   int GetDataType ();
   unsigned long GetValue (const long id);
   void Initialize ();
   virtual void InsertComponent (const long i, const int j, const float c);
   long InsertNextValue (const unsigned long );
   void InsertValue (const long id, const unsigned long i);
   vtkUnsignedLongArray *New ();
   virtual void Resize (long numTuples);
   void SetNumberOfTuples (const long number);
   void SetNumberOfValues (const long number);
   void SetValue (const long id, const unsigned long value);
   void Squeeze ();


B<vtkUnsignedLongArray Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   unsigned long *GetPointer (const long id);
      Can't Handle 'unsigned long *' return type without a hint

   float *GetTuple (const long i);
      Can't Handle 'float *' return type without a hint

   void GetTuple (const long i, float *tuple);
      Don't know the size of pointer arg number 2

   void GetTuple (const long i, double *tuple);
      Don't know the size of pointer arg number 2

   void *GetVoidPointer (const long id);
      Can't Handle 'void *' return type without a hint

   long InsertNextTuple (const float *tuple);
      Don't know the size of pointer arg number 1

   long InsertNextTuple (const double *tuple);
      Don't know the size of pointer arg number 1

   void InsertTuple (const long i, const float *tuple);
      Don't know the size of pointer arg number 2

   void InsertTuple (const long i, const double *tuple);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   unsigned long *ResizeAndExtend (const long sz);
      Can't Handle 'unsigned long *' return type without a hint

   void SetArray (unsigned long *array, long size, int save);
      Don't know the size of pointer arg number 1

   void SetTuple (const long i, const float *tuple);
      Don't know the size of pointer arg number 2

   void SetTuple (const long i, const double *tuple);
      Don't know the size of pointer arg number 2

   void SetVoidArray (void *array, long size, int save);
      Don't know the size of pointer arg number 1

   unsigned long *WritePointer (const long id, const long number);
      Can't Handle 'unsigned long *' return type without a hint


=cut

package Graphics::VTK::UnsignedShortArray;


@Graphics::VTK::UnsignedShortArray::ISA = qw( Graphics::VTK::DataArray );

=head1 Graphics::VTK::UnsignedShortArray

=over 1

=item *

Inherits from DataArray

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int Allocate (const long sz, const long ext);
   void DeepCopy (vtkDataArray *ia);
   void DeepCopy (vtkDataArray &ia);
   const char *GetClassName ();
   float GetComponent (const long i, const int j);
   int GetDataType ();
   unsigned short GetValue (const long id);
   void Initialize ();
   void InsertComponent (const long i, const int j, const float c);
   long InsertNextValue (const unsigned short );
   void InsertValue (const long id, const unsigned short i);
   vtkUnsignedShortArray *New ();
   virtual void Resize (long numTuples);
   void SetComponent (const long i, const int j, const float c);
   void SetNumberOfTuples (const long number);
   void SetNumberOfValues (const long number);
   void SetValue (const long id, const unsigned short value);
   void Squeeze ();


B<vtkUnsignedShortArray Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   unsigned short *GetPointer (const long id);
      Can't Handle 'unsigned short *' return type without a hint

   float *GetTuple (const long i);
      Can't Handle 'float *' return type without a hint

   void GetTuple (const long i, float *tuple);
      Don't know the size of pointer arg number 2

   void GetTuple (const long i, double *tuple);
      Don't know the size of pointer arg number 2

   void *GetVoidPointer (const long id);
      Can't Handle 'void *' return type without a hint

   long InsertNextTuple (const float *tuple);
      Don't know the size of pointer arg number 1

   long InsertNextTuple (const double *tuple);
      Don't know the size of pointer arg number 1

   void InsertTuple (const long i, const float *tuple);
      Don't know the size of pointer arg number 2

   void InsertTuple (const long i, const double *tuple);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   unsigned short *ResizeAndExtend (const long sz);
      Can't Handle 'unsigned short *' return type without a hint

   void SetArray (unsigned short *array, long size, int save);
      Don't know the size of pointer arg number 1

   void SetTuple (const long i, const float *tuple);
      Don't know the size of pointer arg number 2

   void SetTuple (const long i, const double *tuple);
      Don't know the size of pointer arg number 2

   void SetVoidArray (void *array, long size, int save);
      Don't know the size of pointer arg number 1

   unsigned short *WritePointer (const long id, const long number);
      Can't Handle 'unsigned short *' return type without a hint


=cut

package Graphics::VTK::UnstructuredGrid;


@Graphics::VTK::UnstructuredGrid::ISA = qw( Graphics::VTK::PointSet );

=head1 Graphics::VTK::UnstructuredGrid

=over 1

=item *

Inherits from PointSet

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddReferenceToCell (long ptId, long cellId);
   virtual void Allocate (long numCells, int extSize);
   void BuildLinks ();
   virtual void CopyStructure (vtkDataSet *ds);
   virtual void DeepCopy (vtkDataObject *src);
   unsigned long GetActualMemorySize ();
   virtual void GetCell (long cellId, vtkGenericCell *cell);
   virtual vtkCell *GetCell (long cellId);
   vtkCellLinks *GetCellLinks ();
   virtual void GetCellNeighbors (long cellId, vtkIdList *ptIds, vtkIdList *cellIds);
   virtual void GetCellPoints (long cellId, vtkIdList *ptIds);
   int GetCellType (long cellId);
   vtkCellArray *GetCells ();
   const char *GetClassName ();
   int GetDataObjectType ();
   int GetGhostLevel ();
   void GetIdsOfCellsOfType (int type, vtkIntArray *array);
   void GetListOfUniqueCellTypes (vtkUnsignedCharArray *uniqueTypes);
   int GetMaxCellSize ();
   long GetNumberOfCells ();
   int GetNumberOfPieces ();
   int GetPiece ();
   void GetPointCells (long ptId, vtkIdList *cellIds);
   void GetUpdateExtent (int &piece, int &numPieces, int &ghostLevel);
   int  *GetUpdateExtent ();
      (Returns a 6-element Perl list)
   void Initialize ();
   int InsertNextCell (int type, vtkIdList *ptIds);
   int IsHomogeneous ();
   vtkUnstructuredGrid *New ();
   void RemoveReferenceToCell (long ptId, long cellId);
   void Reset ();
   void ResizeCellList (long ptId, int size);
   void SetCells (vtkUnsignedCharArray *cellTypes, vtkIntArray *cellLocations, vtkCellArray *cells);
   void SetUpdateExtent (int x1, int x2, int y1, int y2, int z1, int z2);
   void SetUpdateExtent (int piece, int numPieces, int ghostLevel);
   void SetUpdateExtent (int piece, int numPieces);
   virtual void ShallowCopy (vtkDataObject *src);
   void Squeeze ();


B<vtkUnstructuredGrid Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void GetCellBounds (long cellId, float bounds[6]);
      Don't know the size of pointer arg number 2

   void GetCellNeighbors (long cellId, vtkIdList &ptIds, vtkIdList &cellIds);
      Method is marked 'Do Not Use' in its descriptions

   virtual void GetCellPoints (long cellId, long &npts, long &pts);
      Don't know the size of pointer arg number 2

   int InsertNextCell (int type, int npts, long *pts);
      Don't know the size of pointer arg number 3

   int InsertNextLinkedCell (int type, int npts, long *pts);
      Don't know the size of pointer arg number 3

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ReplaceCell (long cellId, int npts, long *pts);
      Don't know the size of pointer arg number 3

   void SetCells (int *types, vtkCellArray *cells);
      Don't know the size of pointer arg number 1

   void SetUpdateExtent (int ext[6]);
      Method is redundant. Same as SetUpdateExtent( int, int, int, int, int, int)


=cut

package Graphics::VTK::Version;


@Graphics::VTK::Version::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::Version

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   static int GetVTKBuildVersion ();
   static int GetVTKMajorVersion ();
   static int GetVTKMinorVersion ();
   static const char *GetVTKSourceVersion ();
   static const char *GetVTKVersion ();
   vtkVersion *New ();

=cut

package Graphics::VTK::Vertex;


@Graphics::VTK::Vertex::ISA = qw( Graphics::VTK::Cell );

=head1 Graphics::VTK::Vertex

=over 1

=item *

Inherits from Cell

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Clip (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *pts, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd, int insideOut);
   void Contour (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *verts1, vtkCellArray *lines, vtkCellArray *verts2, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd);
   int GetCellDimension ();
   int GetCellType ();
   const char *GetClassName ();
   vtkCell *GetEdge (int );
   vtkCell *GetFace (int );
   int GetNumberOfEdges ();
   int GetNumberOfFaces ();
   vtkVertex *New ();
   int Triangulate (int index, vtkIdList *ptIds, vtkPoints *pts);


B<vtkVertex Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int CellBoundary (int subId, float pcoords[3], vtkIdList *pts);
      Don't know the size of pointer arg number 2

   void Derivatives (int subId, float pcoords[3], float *values, int dim, float *derivs);
      Don't know the size of pointer arg number 2

   void EvaluateLocation (int &subId, float pcoords[3], float x[3], float *weights);
      Don't know the size of pointer arg number 2

   int EvaluatePosition (float x[3], float *closestPoint, int &subId, float pcoords[3], float &dist2, float *weights);
      Don't know the size of pointer arg number 1

   static void InterpolationFunctions (float pcoords[3], float weights[1]);
      Don't know the size of pointer arg number 1

   int IntersectWithLine (float p1[3], float p2[3], float tol, float &t, float x[3], float pcoords[3], int &subId);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::Viewport;


@Graphics::VTK::Viewport::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::Viewport

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddActor2D (vtkProp *p);
   void AddProp (vtkProp *);
   void ComputeAspect ();
   virtual void DisplayToLocalDisplay (float &x, float &y);
   virtual void DisplayToNormalizedDisplay (float &u, float &v);
   virtual void DisplayToView ();
   void DisplayToWorld ();
   vtkActor2DCollection *GetActors2D ();
   float  *GetAspect ();
      (Returns a 2-element Perl list)
   float  *GetBackground ();
      (Returns a 3-element Perl list)
   virtual float *GetCenter ();
      (Returns a 2-element Perl list)
   const char *GetClassName ();
   float  *GetDisplayPoint ();
      (Returns a 3-element Perl list)
   int GetIsPicking ();
   int *GetOrigin ();
      (Returns a 2-element Perl list)
   float GetPickX ();
   float GetPickY ();
   virtual float GetPickedZ () = 0;
   float  *GetPixelAspect ();
      (Returns a 2-element Perl list)
   vtkPropCollection *GetProps ();
   int *GetSize ();
      (Returns a 2-element Perl list)
   virtual vtkWindow *GetVTKWindow () = 0;
   float  *GetViewPoint ();
      (Returns a 3-element Perl list)
   float  *GetViewport ();
      (Returns a 4-element Perl list)
   float  *GetWorldPoint ();
      (Returns a 4-element Perl list)
   virtual int IsInViewport (int x, int y);
   virtual void LocalDisplayToDisplay (float &x, float &y);
   virtual void NormalizedDisplayToDisplay (float &u, float &v);
   virtual void NormalizedDisplayToViewport (float &x, float &y);
   virtual void NormalizedViewportToView (float &x, float &y, float &z);
   virtual void NormalizedViewportToViewport (float &u, float &v);
   virtual vtkAssemblyPath *PickProp (float selectionX, float selectionY) = 0;
   vtkAssemblyPath *PickPropFrom (float selectionX, float selectionY, vtkPropCollection *);
   void RemoveActor2D (vtkProp *p);
   void RemoveProp (vtkProp *);
   void SetAspect (float , float );
   void SetBackground (float , float , float );
   void SetDisplayPoint (float , float , float );
   void SetEndRenderMethod (void (*func)(void *) , void *arg);
   void SetPixelAspect (float , float );
   void SetStartRenderMethod (void (*func)(void *) , void *arg);
   void SetViewPoint (float , float , float );
   void SetViewport (float , float , float , float );
   void SetWorldPoint (float , float , float , float );
   virtual void ViewToDisplay ();
   virtual void ViewToNormalizedViewport (float &x, float &y, float &z);
   virtual void ViewToWorld (float &, float &, float &);
   virtual void ViewToWorld ();
   virtual void ViewportToNormalizedDisplay (float &x, float &y);
   virtual void ViewportToNormalizedViewport (float &u, float &v);
   void WorldToDisplay ();
   virtual void WorldToView (float &, float &, float &);
   virtual void WorldToView ();


B<vtkViewport Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void GetDisplayPoint (double *a);
      Don't know the size of pointer arg number 1

   void GetWorldPoint (double *a);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetAspect (float  a[2]);
      Method is redundant. Same as SetAspect( float, float)

   void SetBackground (float  a[3]);
      Method is redundant. Same as SetBackground( float, float, float)

   void SetDisplayPoint (float  a[3]);
      Method is redundant. Same as SetDisplayPoint( float, float, float)

   void SetEndRenderMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void SetPixelAspect (float  a[2]);
      Method is redundant. Same as SetPixelAspect( float, float)

   void SetStartRenderMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void SetViewPoint (float  a[3]);
      Method is redundant. Same as SetViewPoint( float, float, float)

   void SetViewport (float  a[4]);
      Method is redundant. Same as SetViewport( float, float, float, float)

   void SetWorldPoint (float  a[4]);
      Method is redundant. Same as SetWorldPoint( float, float, float, float)


=cut

package Graphics::VTK::VoidArray;


@Graphics::VTK::VoidArray::ISA = qw( Graphics::VTK::DataArray );

=head1 Graphics::VTK::VoidArray

=over 1

=item *

Inherits from DataArray

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int Allocate (const long sz, const long ext);
   void DeepCopy (vtkDataArray *da);
   const char *GetClassName ();
   int GetDataType ();
   void Initialize ();
   vtkVoidArray *New ();
   virtual void Resize (long numTuples);
   void SetNumberOfTuples (const long number);
   void SetNumberOfValues (const long number);
   void Squeeze ();


B<vtkVoidArray Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void *GetPointer (const long id);
      Can't Handle 'void *' return type without a hint

   float *GetTuple (const long i);
      Can't Handle 'float *' return type without a hint

   void GetTuple (const long i, float *tuple);
      Don't know the size of pointer arg number 2

   void GetTuple (const long i, double *tuple);
      Don't know the size of pointer arg number 2

   void *GetValue (const long id);
      Can't Handle 'void *' return type without a hint

   void *GetVoidPointer (const long id);
      Can't Handle 'void *' return type without a hint

   long InsertNextTuple (const float *tuple);
      Don't know the size of pointer arg number 1

   long InsertNextTuple (const double *tuple);
      Don't know the size of pointer arg number 1

   long InsertNextValue (void *v);
      Don't know the size of pointer arg number 1

   void InsertTuple (const long i, const float *tuple);
      Don't know the size of pointer arg number 2

   void InsertTuple (const long i, const double *tuple);
      Don't know the size of pointer arg number 2

   void InsertValue (const long id, void *p);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void *ResizeAndExtend (const long sz);
      Can't Handle 'void *' return type without a hint

   void SetTuple (const long i, const float *tuple);
      Don't know the size of pointer arg number 2

   void SetTuple (const long i, const double *tuple);
      Don't know the size of pointer arg number 2

   void SetValue (const long id, void *value);
      Don't know the size of pointer arg number 2

   void *WritePointer (const long id, const long number);
      Can't Handle 'void *' return type without a hint


=cut

package Graphics::VTK::Voxel;


@Graphics::VTK::Voxel::ISA = qw( Graphics::VTK::Cell3D );

=head1 Graphics::VTK::Voxel

=over 1

=item *

Inherits from Cell3D

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Contour (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *verts, vtkCellArray *lines, vtkCellArray *polys, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd);
   int GetCellDimension ();
   int GetCellType ();
   const char *GetClassName ();
   vtkCell *GetEdge (int edgeId);
   vtkCell *GetFace (int faceId);
   int GetNumberOfEdges ();
   int GetNumberOfFaces ();
   vtkVoxel *New ();
   int Triangulate (int index, vtkIdList *ptIds, vtkPoints *pts);


B<vtkVoxel Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int CellBoundary (int subId, float pcoords[3], vtkIdList *pts);
      Don't know the size of pointer arg number 2

   void Derivatives (int subId, float pcoords[3], float *values, int dim, float *derivs);
      Don't know the size of pointer arg number 2

   void EvaluateLocation (int &subId, float pcoords[3], float x[3], float *weights);
      Don't know the size of pointer arg number 2

   int EvaluatePosition (float x[3], float *closestPoint, int &subId, float pcoords[3], float &dist2, float *weights);
      Don't know the size of pointer arg number 1

   static int *GetEdgeArray (int edgeId);
      Can't Handle 'static int *' return type without a hint

   virtual void GetEdgePoints (int edgeId, int &pts);
      Don't know the size of pointer arg number 2

   static int *GetFaceArray (int faceId);
      Can't Handle 'static int *' return type without a hint

   virtual void GetFacePoints (int faceId, int &pts);
      Don't know the size of pointer arg number 2

   static void InterpolationDerivs (float pcoords[3], float derivs[24]);
      Don't know the size of pointer arg number 1

   static void InterpolationFunctions (float pcoords[3], float weights[8]);
      Don't know the size of pointer arg number 1

   int IntersectWithLine (float p1[3], float p2[3], float tol, float &t, float x[3], float pcoords[3], int &subId);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::WarpTransform;


@Graphics::VTK::WarpTransform::ISA = qw( Graphics::VTK::AbstractTransform );

=head1 Graphics::VTK::WarpTransform

=over 1

=item *

Inherits from AbstractTransform

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetInverseFlag ();
   int GetInverseIterations ();
   double GetInverseTolerance ();
   void Inverse ();
   void SetInverseIterations (int );
   void SetInverseTolerance (double );


B<vtkWarpTransform Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void ForwardTransformDerivative (const float in[3], float out[3], float derivative[3][3]) = 0;
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   virtual void ForwardTransformDerivative (const double in[3], double out[3], double derivative[3][3]) = 0;
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   virtual void ForwardTransformPoint (const float in[3], float out[3]) = 0;
      Don't know the size of pointer arg number 1

   virtual void ForwardTransformPoint (const double in[3], double out[3]) = 0;
      Don't know the size of pointer arg number 1

   void InternalTransformDerivative (const float in[3], float out[3], float derivative[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void InternalTransformDerivative (const double in[3], double out[3], double derivative[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void InternalTransformPoint (const float in[3], float out[3]);
      Don't know the size of pointer arg number 1

   void InternalTransformPoint (const double in[3], double out[3]);
      Don't know the size of pointer arg number 1

   virtual void InverseTransformDerivative (const float in[3], float out[3], float derivative[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   virtual void InverseTransformDerivative (const double in[3], double out[3], double derivative[3][3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   virtual void InverseTransformPoint (const float in[3], float out[3]);
      Don't know the size of pointer arg number 1

   virtual void InverseTransformPoint (const double in[3], double out[3]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void TemplateTransformInverse (const float in[3], float out[3]);
      Method is marked 'Do Not Use' in its descriptions

   void TemplateTransformInverse (const double in[3], double out[3]);
      Method is marked 'Do Not Use' in its descriptions

   void TemplateTransformInverse (const float in[3], float out[3], float derivative[3][3]);
      Method is marked 'Do Not Use' in its descriptions

   void TemplateTransformInverse (const double in[3], double out[3], double derivative[3][3]);
      Method is marked 'Do Not Use' in its descriptions

   void TemplateTransformPoint (const float in[3], float out[3]);
      Method is marked 'Do Not Use' in its descriptions

   void TemplateTransformPoint (const double in[3], double out[3]);
      Method is marked 'Do Not Use' in its descriptions

   void TemplateTransformPoint (const float in[3], float out[3], float derivative[3][3]);
      Method is marked 'Do Not Use' in its descriptions

   void TemplateTransformPoint (const double in[3], double out[3], double derivative[3][3]);
      Method is marked 'Do Not Use' in its descriptions


=cut

package Graphics::VTK::Wedge;


@Graphics::VTK::Wedge::ISA = qw( Graphics::VTK::Cell3D );

=head1 Graphics::VTK::Wedge

=over 1

=item *

Inherits from Cell3D

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Contour (float value, vtkDataArray *cellScalars, vtkPointLocator *locator, vtkCellArray *verts, vtkCellArray *lines, vtkCellArray *polys, vtkPointData *inPd, vtkPointData *outPd, vtkCellData *inCd, long cellId, vtkCellData *outCd);
   int GetCellDimension ();
   int GetCellType ();
   const char *GetClassName ();
   vtkCell *GetEdge (int edgeId);
   vtkCell *GetFace (int faceId);
   int GetNumberOfEdges ();
   int GetNumberOfFaces ();
   vtkWedge *New ();
   int Triangulate (int index, vtkIdList *ptIds, vtkPoints *pts);


B<vtkWedge Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int CellBoundary (int subId, float pcoords[3], vtkIdList *pts);
      Don't know the size of pointer arg number 2

   void Derivatives (int subId, float pcoords[3], float *values, int dim, float *derivs);
      Don't know the size of pointer arg number 2

   void EvaluateLocation (int &subId, float pcoords[3], float x[3], float *weights);
      Don't know the size of pointer arg number 2

   int EvaluatePosition (float x[3], float *closestPoint, int &subId, float pcoords[3], float &dist2, float *weights);
      Don't know the size of pointer arg number 1

   static int *GetEdgeArray (int edgeId);
      Can't Handle 'static int *' return type without a hint

   virtual void GetEdgePoints (int edgeId, int &pts);
      Don't know the size of pointer arg number 2

   static int *GetFaceArray (int faceId);
      Can't Handle 'static int *' return type without a hint

   virtual void GetFacePoints (int faceId, int &pts);
      Don't know the size of pointer arg number 2

   int GetParametricCenter (float pcoords[3]);
      Can't handle methods with single array args (like a[3]) yet.

   static void InterpolationDerivs (float pcoords[3], float derivs[18]);
      Don't know the size of pointer arg number 1

   static void InterpolationFunctions (float pcoords[3], float weights[6]);
      Don't know the size of pointer arg number 1

   int IntersectWithLine (float p1[3], float p2[3], float tol, float &t, float x[3], float pcoords[3], int &subId);
      Don't know the size of pointer arg number 1

   int JacobianInverse (float pcoords[3], double *inverse, float derivs[18]);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::Window;


@Graphics::VTK::Window::ISA = qw( Graphics::VTK::Object );

=head1 Graphics::VTK::Window

=over 1

=item *

Inherits from Object

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void DoubleBufferOff ();
   void DoubleBufferOn ();
   void EraseOff ();
   void EraseOn ();
   const char *GetClassName ();
   int GetDPI ();
   int GetDPIMaxValue ();
   int GetDPIMinValue ();
   int GetDoubleBuffer ();
   int GetErase ();
   int GetMapped ();
   int GetOffScreenRendering ();
   virtual int *GetPosition ();
      (Returns a 2-element Perl list)
   virtual int *GetSize ();
      (Returns a 2-element Perl list)
   char *GetWindowName ();
   virtual void MakeCurrent ();
   void MappedOff ();
   void MappedOn ();
   void OffScreenRenderingOff ();
   void OffScreenRenderingOn ();
   virtual void Render () = 0;
   void SetDPI (int );
   void SetDoubleBuffer (int );
   void SetErase (int );
   void SetMapped (int );
   void SetOffScreenRendering (int );
   virtual void SetParentInfo (char *) = 0;
   virtual void SetPosition (int , int );
   virtual void SetSize (int , int );
   virtual void SetWindowInfo (char *) = 0;
   virtual void SetWindowName (char *);


B<vtkWindow Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void *GetGenericContext () = 0;
      Can't Handle 'void *' return type without a hint

   virtual void *GetGenericDisplayId () = 0;
      Can't Handle 'void *' return type without a hint

   virtual void *GetGenericDrawable () = 0;
      Can't Handle 'void *' return type without a hint

   virtual void *GetGenericParentId () = 0;
      Can't Handle 'void *' return type without a hint

   virtual void *GetGenericWindowId () = 0;
      Can't Handle 'void *' return type without a hint

   virtual unsigned char *GetPixelData (int , int , int , int , int );
      Can't Handle 'unsigned char *' return type without a hint

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

package Graphics::VTK::WindowLevelLookupTable;


@Graphics::VTK::WindowLevelLookupTable::ISA = qw( Graphics::VTK::LookupTable );

=head1 Graphics::VTK::WindowLevelLookupTable

=over 1

=item *

Inherits from LookupTable

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Build ();
   const char *GetClassName ();
   int GetInverseVideo ();
   float GetLevel ();
   float  *GetMaximumTableValue ();
      (Returns a 4-element Perl list)
   float  *GetMinimumTableValue ();
      (Returns a 4-element Perl list)
   float GetWindow ();
   void InverseVideoOff ();
   void InverseVideoOn ();
   vtkWindowLevelLookupTable *New ();
   void SetInverseVideo (int iv);
   void SetLevel (float level);
   void SetMaximumColor (int r, int g, int b, int a);
   void SetMaximumTableValue (float , float , float , float );
   void SetMinimumColor (int r, int g, int b, int a);
   void SetMinimumTableValue (float , float , float , float );
   void SetWindow (float window);


B<vtkWindowLevelLookupTable Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void GetMaximumColor (unsigned char rgba[4]);
      Arg types of 'unsigned char *' not supported yet
   unsigned char *GetMaximumColor ();
      Can't Handle 'unsigned char *' return type without a hint

   void GetMinimumColor (unsigned char rgba[4]);
      Arg types of 'unsigned char *' not supported yet
   unsigned char *GetMinimumColor ();
      Can't Handle 'unsigned char *' return type without a hint

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetMaximumColor (const unsigned char rgba[4]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void SetMaximumTableValue (float  a[4]);
      Method is redundant. Same as SetMaximumTableValue( float, float, float, float)

   void SetMinimumColor (const unsigned char rgba[4]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void SetMinimumTableValue (float  a[4]);
      Method is redundant. Same as SetMinimumTableValue( float, float, float, float)


=cut

package Graphics::VTK::XMLFileOutputWindow;


@Graphics::VTK::XMLFileOutputWindow::ISA = qw( Graphics::VTK::FileOutputWindow );

=head1 Graphics::VTK::XMLFileOutputWindow

=over 1

=item *

Inherits from FileOutputWindow

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual void DisplayDebugText (const char *);
   virtual void DisplayErrorText (const char *);
   virtual void DisplayGenericWarningText (const char *);
   virtual void DisplayTag (const char *);
   virtual void DisplayText (const char *);
   virtual void DisplayWarningText (const char *);
   const char *GetClassName ();
   vtkXMLFileOutputWindow *New ();

=cut

package Graphics::VTK::Win32OutputWindow;


@Graphics::VTK::Win32OutputWindow::ISA = qw( Graphics::VTK::OutputWindow );

=head1 Graphics::VTK::Win32OutputWindow

=over 1

=item *

Inherits from OutputWindow

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual void DisplayText (const char *);
   const char *GetClassName ();
   vtkWin32OutputWindow *New ();

=cut

1;
