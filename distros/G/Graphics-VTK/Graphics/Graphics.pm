
package Graphics::VTK::Graphics;
use 5.004;
use strict;
use Carp;

use vars qw/ $VERSION @ISA/;

require DynaLoader;

$VERSION = '4.0.001';

@ISA = qw/ DynaLoader /;

bootstrap Graphics::VTK::Graphics $VERSION;


=head1 NAME

VTKGraphics  - A Perl interface to VTKGraphics library

=head1 SYNOPSIS

C<use Graphics::VTK;>
C<use Graphics::VTK::Graphics;>

=head1 DESCRIPTION

Graphics::VTK::Graphics is an interface to the Graphics libaray of the C++ visualization toolkit VTK..

=head1 AUTHOR

Original PerlVTK Package: Roberto De Leo <rdl@math.umd.edu>

Additional Refinements: John Cerney <j-cerney1@raytheon.com>

=cut

package Graphics::VTK::AppendFilter;


@Graphics::VTK::AppendFilter::ISA = qw( Graphics::VTK::DataSetToUnstructuredGridFilter );

=head1 Graphics::VTK::AppendFilter

=over 1

=item *

Inherits from DataSetToUnstructuredGridFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddInput (vtkDataSet *in);
   const char *GetClassName ();
   vtkDataSet *GetInput (int idx);
   vtkDataSet *GetInput ();
   vtkDataSetCollection *GetInputList ();
   vtkAppendFilter *New ();
   void RemoveInput (vtkDataSet *in);


B<vtkAppendFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::AppendPolyData;


@Graphics::VTK::AppendPolyData::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::AppendPolyData

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddInput (vtkPolyData *);
   const char *GetClassName ();
   vtkPolyData *GetInput (int idx);
   vtkPolyData *GetInput ();
   int GetParallelStreaming ();
   int GetUserManagedInputs ();
   vtkAppendPolyData *New ();
   void ParallelStreamingOff ();
   void ParallelStreamingOn ();
   void RemoveInput (vtkPolyData *);
   void SetInputByNumber (int num, vtkPolyData *input);
   void SetNumberOfInputs (int num);
   void SetParallelStreaming (int );
   void SetUserManagedInputs (int );
   void UserManagedInputsOff ();
   void UserManagedInputsOn ();


B<vtkAppendPolyData Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   long *AppendCells (long *pDest, vtkCellArray *src, long offset);
      Can't Handle 'long *' return type without a hint

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ApproximatingSubdivisionFilter;


@Graphics::VTK::ApproximatingSubdivisionFilter::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::ApproximatingSubdivisionFilter

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetNumberOfSubdivisions ();
   void SetNumberOfSubdivisions (int );


B<vtkApproximatingSubdivisionFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   long InterpolatePosition (vtkPoints *inputPts, vtkPoints *outputPts, vtkIdList *stencil, float *weights);
      Don't know the size of pointer arg number 4

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ArrayCalculator;


@Graphics::VTK::ArrayCalculator::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::ArrayCalculator

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddScalarArrayName (const char *arrayName, int component);
   void AddScalarVariable (const char *variableName, const char *arrayName, int component);
   void AddVectorArrayName (const char *arrayName, int component0, int component1, int component2);
   void AddVectorVariable (const char *variableName, const char *arrayName, int component0, int component1, int component2);
   int GetAttributeMode ();
   const char *GetAttributeModeAsString ();
   const char *GetClassName ();
   char *GetFunction ();
   int GetNumberOfScalarArrays ();
   int GetNumberOfVectorArrays ();
   char *GetResultArrayName ();
   char *GetScalarArrayName (int i);
   char *GetScalarVariableName (int i);
   int GetSelectedScalarComponent (int i);
   char *GetVectorArrayName (int i);
   char *GetVectorVariableName (int i);
   vtkArrayCalculator *New ();
   void RemoveAllVariables ();
   void SetAttributeMode (int );
   void SetAttributeModeToDefault ();
   void SetAttributeModeToUseCellData ();
   void SetAttributeModeToUsePointData ();
   void SetFunction (const char *function);
   void SetResultArrayName (const char *name);


B<vtkArrayCalculator Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   char *GetScalarArrayNames ();
      Can't Handle 'char **' return type yet

   char *GetScalarVariableNames ();
      Can't Handle 'char **' return type yet

   int *GetSelectedScalarComponents ();
      Can't Handle 'int *' return type without a hint

   int *GetSelectedVectorComponents ();
      Can't Handle 'int *' return type without a hint

   int *GetSelectedVectorComponents (int i);
      Can't Handle 'int *' return type without a hint

   char *GetVectorArrayNames ();
      Can't Handle 'char **' return type yet

   char *GetVectorVariableNames ();
      Can't Handle 'char **' return type yet

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ArrowSource;


@Graphics::VTK::ArrowSource::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::ArrowSource

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetShaftRadius ();
   float GetShaftRadiusMaxValue ();
   float GetShaftRadiusMinValue ();
   int GetShaftResolution ();
   int GetShaftResolutionMaxValue ();
   int GetShaftResolutionMinValue ();
   float GetTipLength ();
   float GetTipLengthMaxValue ();
   float GetTipLengthMinValue ();
   float GetTipRadius ();
   float GetTipRadiusMaxValue ();
   float GetTipRadiusMinValue ();
   int GetTipResolution ();
   int GetTipResolutionMaxValue ();
   int GetTipResolutionMinValue ();
   vtkArrowSource *New ();
   void SetShaftRadius (float );
   void SetShaftResolution (int );
   void SetTipLength (float );
   void SetTipRadius (float );
   void SetTipResolution (int );


B<vtkArrowSource Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::AssignAttribute;


@Graphics::VTK::AssignAttribute::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::AssignAttribute

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Assign (const char *name, const char *attributeType, const char *attributeLoc);
   void Assign (int inputAttributeType, int attributeType, int attributeLoc);
   const char *GetClassName ();
   vtkAssignAttribute *New ();


B<vtkAssignAttribute Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void Assign (const char *fieldName, int attributeType, int attributeLoc);
      Can't Get Unique Function Signature for this overloaded method

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::AttributeDataToFieldDataFilter;


@Graphics::VTK::AttributeDataToFieldDataFilter::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::AttributeDataToFieldDataFilter

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetPassAttributeData ();
   vtkAttributeDataToFieldDataFilter *New ();
   void PassAttributeDataOff ();
   void PassAttributeDataOn ();
   void SetPassAttributeData (int );


B<vtkAttributeDataToFieldDataFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::Axes;


@Graphics::VTK::Axes::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::Axes

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void ComputeNormalsOff ();
   void ComputeNormalsOn ();
   const char *GetClassName ();
   int GetComputeNormals ();
   float  *GetOrigin ();
      (Returns a 3-element Perl list)
   float GetScaleFactor ();
   int GetSymmetric ();
   vtkAxes *New ();
   void SetComputeNormals (int );
   void SetOrigin (float , float , float );
   void SetScaleFactor (float );
   void SetSymmetric (int );
   void SymmetricOff ();
   void SymmetricOn ();


B<vtkAxes Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetOrigin (float  a[3]);
      Method is redundant. Same as SetOrigin( float, float, float)


=cut

package Graphics::VTK::BlankStructuredGrid;


@Graphics::VTK::BlankStructuredGrid::ISA = qw( Graphics::VTK::StructuredGridToStructuredGridFilter );

=head1 Graphics::VTK::BlankStructuredGrid

=over 1

=item *

Inherits from StructuredGridToStructuredGridFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int GetArrayId ();
   char *GetArrayName ();
   const char *GetClassName ();
   int GetComponent ();
   int GetComponentMaxValue ();
   int GetComponentMinValue ();
   float GetMaxBlankingValue ();
   float GetMinBlankingValue ();
   vtkBlankStructuredGrid *New ();
   void SetArrayId (int );
   void SetArrayName (char *);
   void SetComponent (int );
   void SetMaxBlankingValue (float );
   void SetMinBlankingValue (float );


B<vtkBlankStructuredGrid Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::BlankStructuredGridWithImage;


@Graphics::VTK::BlankStructuredGridWithImage::ISA = qw( Graphics::VTK::StructuredGridToStructuredGridFilter );

=head1 Graphics::VTK::BlankStructuredGridWithImage

=over 1

=item *

Inherits from StructuredGridToStructuredGridFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   vtkImageData *GetBlankingInput ();
   const char *GetClassName ();
   vtkBlankStructuredGridWithImage *New ();
   void SetBlankingInput (vtkImageData *input);


B<vtkBlankStructuredGridWithImage Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::BrownianPoints;


@Graphics::VTK::BrownianPoints::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::BrownianPoints

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetMaximumSpeed ();
   float GetMaximumSpeedMaxValue ();
   float GetMaximumSpeedMinValue ();
   float GetMinimumSpeed ();
   float GetMinimumSpeedMaxValue ();
   float GetMinimumSpeedMinValue ();
   vtkBrownianPoints *New ();
   void SetMaximumSpeed (float );
   void SetMinimumSpeed (float );


B<vtkBrownianPoints Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ButterflySubdivisionFilter;


@Graphics::VTK::ButterflySubdivisionFilter::ISA = qw( Graphics::VTK::InterpolatingSubdivisionFilter );

=head1 Graphics::VTK::ButterflySubdivisionFilter

=over 1

=item *

Inherits from InterpolatingSubdivisionFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkButterflySubdivisionFilter *New ();


B<vtkButterflySubdivisionFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void GenerateBoundaryStencil (long p1, long p2, vtkPolyData *polys, vtkIdList *stencilIds, float *weights);
      Don't know the size of pointer arg number 5

   void GenerateButterflyStencil (long p1, long p2, vtkPolyData *polys, vtkIdList *stencilIds, float *weights);
      Don't know the size of pointer arg number 5

   void GenerateLoopStencil (long p1, long p2, vtkPolyData *polys, vtkIdList *stencilIds, float *weights);
      Don't know the size of pointer arg number 5


=cut

package Graphics::VTK::CellCenters;


@Graphics::VTK::CellCenters::ISA = qw( Graphics::VTK::DataSetToPolyDataFilter );

=head1 Graphics::VTK::CellCenters

=over 1

=item *

Inherits from DataSetToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetVertexCells ();
   vtkCellCenters *New ();
   void SetVertexCells (int );
   void VertexCellsOff ();
   void VertexCellsOn ();


B<vtkCellCenters Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::CellDataToPointData;


@Graphics::VTK::CellDataToPointData::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::CellDataToPointData

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetPassCellData ();
   vtkCellDataToPointData *New ();
   void PassCellDataOff ();
   void PassCellDataOn ();
   void SetPassCellData (int );


B<vtkCellDataToPointData Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::CellDerivatives;


@Graphics::VTK::CellDerivatives::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::CellDerivatives

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetTensorMode ();
   const char *GetTensorModeAsString ();
   int GetVectorMode ();
   const char *GetVectorModeAsString ();
   vtkCellDerivatives *New ();
   void SetTensorMode (int );
   void SetTensorModeToComputeGradient ();
   void SetTensorModeToComputeStrain ();
   void SetTensorModeToPassTensors ();
   void SetVectorMode (int );
   void SetVectorModeToComputeGradient ();
   void SetVectorModeToComputeVorticity ();
   void SetVectorModeToPassVectors ();


B<vtkCellDerivatives Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::CleanPolyData;


@Graphics::VTK::CleanPolyData::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::CleanPolyData

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void ConvertLinesToPointsOff ();
   void ConvertLinesToPointsOn ();
   void ConvertPolysToLinesOff ();
   void ConvertPolysToLinesOn ();
   void ConvertStripsToPolysOff ();
   void ConvertStripsToPolysOn ();
   void CreateDefaultLocator (void );
   float GetAbsoluteTolerance ();
   float GetAbsoluteToleranceMaxValue ();
   float GetAbsoluteToleranceMinValue ();
   const char *GetClassName ();
   int GetConvertLinesToPoints ();
   int GetConvertPolysToLines ();
   int GetConvertStripsToPolys ();
   vtkPointLocator *GetLocator ();
   unsigned long GetMTime ();
   int GetPieceInvariant ();
   int GetPointMerging ();
   float GetTolerance ();
   int GetToleranceIsAbsolute ();
   float GetToleranceMaxValue ();
   float GetToleranceMinValue ();
   vtkCleanPolyData *New ();
   void PieceInvariantOff ();
   void PieceInvariantOn ();
   void PointMergingOff ();
   void PointMergingOn ();
   void ReleaseLocator (void );
   void SetAbsoluteTolerance (float );
   void SetConvertLinesToPoints (int );
   void SetConvertPolysToLines (int );
   void SetConvertStripsToPolys (int );
   void SetLocator (vtkPointLocator *locator);
   void SetPieceInvariant (int );
   void SetPointMerging (int );
   void SetTolerance (float );
   void SetToleranceIsAbsolute (int );
   void ToleranceIsAbsoluteOff ();
   void ToleranceIsAbsoluteOn ();


B<vtkCleanPolyData Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void OperateOnBounds (float in[6], float out[6]);
      Don't know the size of pointer arg number 1

   virtual void OperateOnPoint (float in[3], float out[3]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ClipDataSet;


@Graphics::VTK::ClipDataSet::ISA = qw( Graphics::VTK::DataSetToUnstructuredGridFilter );

=head1 Graphics::VTK::ClipDataSet

=over 1

=item *

Inherits from DataSetToUnstructuredGridFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CreateDefaultLocator ();
   void GenerateClipScalarsOff ();
   void GenerateClipScalarsOn ();
   void GenerateClippedOutputOff ();
   void GenerateClippedOutputOn ();
   const char *GetClassName ();
   vtkImplicitFunction *GetClipFunction ();
   vtkUnstructuredGrid *GetClippedOutput ();
   int GetGenerateClipScalars ();
   int GetGenerateClippedOutput ();
   int GetInsideOut ();
   vtkPointLocator *GetLocator ();
   unsigned long GetMTime ();
   float GetValue ();
   void InsideOutOff ();
   void InsideOutOn ();
   vtkClipDataSet *New ();
   void SetClipFunction (vtkImplicitFunction *);
   void SetGenerateClipScalars (int );
   void SetGenerateClippedOutput (int );
   void SetInsideOut (int );
   void SetLocator (vtkPointLocator *locator);
   void SetValue (float );


B<vtkClipDataSet Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ClipPolyData;


@Graphics::VTK::ClipPolyData::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::ClipPolyData

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CreateDefaultLocator ();
   void GenerateClipScalarsOff ();
   void GenerateClipScalarsOn ();
   void GenerateClippedOutputOff ();
   void GenerateClippedOutputOn ();
   const char *GetClassName ();
   vtkImplicitFunction *GetClipFunction ();
   vtkPolyData *GetClippedOutput ();
   int GetGenerateClipScalars ();
   int GetGenerateClippedOutput ();
   int GetInsideOut ();
   vtkPointLocator *GetLocator ();
   unsigned long GetMTime ();
   float GetValue ();
   void InsideOutOff ();
   void InsideOutOn ();
   vtkClipPolyData *New ();
   void SetClipFunction (vtkImplicitFunction *);
   void SetGenerateClipScalars (int );
   void SetGenerateClippedOutput (int );
   void SetInsideOut (int );
   void SetLocator (vtkPointLocator *locator);
   void SetValue (float );


B<vtkClipPolyData Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ClipVolume;


@Graphics::VTK::ClipVolume::ISA = qw( Graphics::VTK::StructuredPointsToUnstructuredGridFilter );

=head1 Graphics::VTK::ClipVolume

=over 1

=item *

Inherits from StructuredPointsToUnstructuredGridFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CreateDefaultLocator ();
   void GenerateClipScalarsOff ();
   void GenerateClipScalarsOn ();
   void GenerateClippedOutputOff ();
   void GenerateClippedOutputOn ();
   const char *GetClassName ();
   vtkImplicitFunction *GetClipFunction ();
   vtkUnstructuredGrid *GetClippedOutput ();
   int GetGenerateClipScalars ();
   int GetGenerateClippedOutput ();
   int GetInsideOut ();
   vtkPointLocator *GetLocator ();
   unsigned long GetMTime ();
   float GetMergeTolerance ();
   float GetMergeToleranceMaxValue ();
   float GetMergeToleranceMinValue ();
   float GetValue ();
   void InsideOutOff ();
   void InsideOutOn ();
   vtkClipVolume *New ();
   void SetClipFunction (vtkImplicitFunction *);
   void SetGenerateClipScalars (int );
   void SetGenerateClippedOutput (int );
   void SetInsideOut (int );
   void SetLocator (vtkPointLocator *locator);
   void SetMergeTolerance (float );
   void SetValue (float );


B<vtkClipVolume Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ClipVoxel (float value, vtkDataArray *cellScalars, int flip, float origin[3], float spacing[3], vtkIdList *cellIds, vtkPoints *cellPts, vtkPointData *inPD, vtkPointData *outPD, vtkCellData *inCD, long cellId, vtkCellData *outCD, vtkCellData *clippedCD);
      Don't know the size of pointer arg number 4

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ConeSource;


@Graphics::VTK::ConeSource::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::ConeSource

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CappingOff ();
   void CappingOn ();
   float GetAngle ();
   int GetCapping ();
   const char *GetClassName ();
   float GetHeight ();
   float GetHeightMaxValue ();
   float GetHeightMinValue ();
   float GetRadius ();
   float GetRadiusMaxValue ();
   float GetRadiusMinValue ();
   int GetResolution ();
   int GetResolutionMaxValue ();
   int GetResolutionMinValue ();
   vtkConeSource *New ();
   void SetAngle (float angle);
   void SetCapping (int );
   void SetHeight (float );
   void SetRadius (float );
   void SetResolution (int );


B<vtkConeSource Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ConnectivityFilter;


@Graphics::VTK::ConnectivityFilter::ISA = qw( Graphics::VTK::DataSetToUnstructuredGridFilter );

=head1 Graphics::VTK::ConnectivityFilter

=over 1

=item *

Inherits from DataSetToUnstructuredGridFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddSeed (long id);
   void AddSpecifiedRegion (int id);
   void ColorRegionsOff ();
   void ColorRegionsOn ();
   void DeleteSeed (long id);
   void DeleteSpecifiedRegion (int id);
   const char *GetClassName ();
   float  *GetClosestPoint ();
      (Returns a 3-element Perl list)
   int GetColorRegions ();
   int GetExtractionMode ();
   const char *GetExtractionModeAsString ();
   int GetExtractionModeMaxValue ();
   int GetExtractionModeMinValue ();
   int GetNumberOfExtractedRegions ();
   int GetScalarConnectivity ();
   float  *GetScalarRange ();
      (Returns a 2-element Perl list)
   void InitializeSeedList ();
   void InitializeSpecifiedRegionList ();
   vtkConnectivityFilter *New ();
   void ScalarConnectivityOff ();
   void ScalarConnectivityOn ();
   void SetClosestPoint (float , float , float );
   void SetColorRegions (int );
   void SetExtractionMode (int );
   void SetExtractionModeToAllRegions ();
   void SetExtractionModeToCellSeededRegions ();
   void SetExtractionModeToClosestPointRegion ();
   void SetExtractionModeToLargestRegion ();
   void SetExtractionModeToPointSeededRegions ();
   void SetExtractionModeToSpecifiedRegions ();
   void SetScalarConnectivity (int );
   void SetScalarRange (float , float );


B<vtkConnectivityFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetClosestPoint (float  a[3]);
      Method is redundant. Same as SetClosestPoint( float, float, float)

   void SetScalarRange (float  a[2]);
      Method is redundant. Same as SetScalarRange( float, float)


=cut

package Graphics::VTK::ContourFilter;


@Graphics::VTK::ContourFilter::ISA = qw( Graphics::VTK::DataSetToPolyDataFilter );

=head1 Graphics::VTK::ContourFilter

=over 1

=item *

Inherits from DataSetToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void ComputeGradientsOff ();
   void ComputeGradientsOn ();
   void ComputeNormalsOff ();
   void ComputeNormalsOn ();
   void ComputeScalarsOff ();
   void ComputeScalarsOn ();
   void CreateDefaultLocator ();
   void GenerateValues (int numContours, float rangeStart, float rangeEnd);
   const char *GetClassName ();
   int GetComputeGradients ();
   int GetComputeNormals ();
   int GetComputeScalars ();
   vtkPointLocator *GetLocator ();
   unsigned long GetMTime ();
   int GetNumberOfContours ();
   int GetUseScalarTree ();
   float GetValue (int i);
   vtkContourFilter *New ();
   void SetComputeGradients (int );
   void SetComputeNormals (int );
   void SetComputeScalars (int );
   void SetLocator (vtkPointLocator *locator);
   void SetNumberOfContours (int number);
   void SetUseScalarTree (int );
   void SetValue (int i, float value);
   void UseScalarTreeOff ();
   void UseScalarTreeOn ();


B<vtkContourFilter Unsupported Funcs:>

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

package Graphics::VTK::ContourGrid;


@Graphics::VTK::ContourGrid::ISA = qw( Graphics::VTK::UnstructuredGridToPolyDataFilter );

=head1 Graphics::VTK::ContourGrid

=over 1

=item *

Inherits from UnstructuredGridToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void ComputeGradientsOff ();
   void ComputeGradientsOn ();
   void ComputeNormalsOff ();
   void ComputeNormalsOn ();
   void ComputeScalarsOff ();
   void ComputeScalarsOn ();
   void CreateDefaultLocator ();
   void GenerateValues (int numContours, float rangeStart, float rangeEnd);
   const char *GetClassName ();
   int GetComputeGradients ();
   int GetComputeNormals ();
   int GetComputeScalars ();
   vtkPointLocator *GetLocator ();
   unsigned long GetMTime ();
   int GetNumberOfContours ();
   int GetUseScalarTree ();
   float GetValue (int i);
   vtkContourGrid *New ();
   void SetComputeGradients (int );
   void SetComputeNormals (int );
   void SetComputeScalars (int );
   void SetLocator (vtkPointLocator *locator);
   void SetNumberOfContours (int number);
   void SetUseScalarTree (int );
   void SetValue (int i, float value);
   void UseScalarTreeOff ();
   void UseScalarTreeOn ();


B<vtkContourGrid Unsupported Funcs:>

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

package Graphics::VTK::CubeSource;


@Graphics::VTK::CubeSource::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::CubeSource

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   float  *GetCenter ();
      (Returns a 3-element Perl list)
   const char *GetClassName ();
   float GetXLength ();
   float GetXLengthMaxValue ();
   float GetXLengthMinValue ();
   float GetYLength ();
   float GetYLengthMaxValue ();
   float GetYLengthMinValue ();
   float GetZLength ();
   float GetZLengthMaxValue ();
   float GetZLengthMinValue ();
   vtkCubeSource *New ();
   void SetBounds (float xMin, float xMax, float yMin, float yMax, float zMin, float zMax);
   void SetCenter (float , float , float );
   void SetXLength (float );
   void SetYLength (float );
   void SetZLength (float );


B<vtkCubeSource Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetBounds (float bounds[6]);
      Method is redundant. Same as SetBounds( float, float, float, float, float, float)

   void SetCenter (float  a[3]);
      Method is redundant. Same as SetCenter( float, float, float)


=cut

package Graphics::VTK::Cursor3D;


@Graphics::VTK::Cursor3D::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::Cursor3D

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AllOff ();
   void AllOn ();
   void AxesOff ();
   void AxesOn ();
   int GetAxes ();
   const char *GetClassName ();
   float  *GetFocalPoint ();
      (Returns a 3-element Perl list)
   vtkPolyData *GetFocus ();
   float  *GetModelBounds ();
      (Returns a 6-element Perl list)
   int GetOutline ();
   int GetWrap ();
   int GetXShadows ();
   int GetYShadows ();
   int GetZShadows ();
   vtkCursor3D *New ();
   void OutlineOff ();
   void OutlineOn ();
   void SetAxes (int );
   void SetFocalPoint (float , float , float );
   void SetModelBounds (float xmin, float xmax, float ymin, float ymax, float zmin, float zmax);
   void SetOutline (int );
   void SetWrap (int );
   void SetXShadows (int );
   void SetYShadows (int );
   void SetZShadows (int );
   void WrapOff ();
   void WrapOn ();
   void XShadowsOff ();
   void XShadowsOn ();
   void YShadowsOff ();
   void YShadowsOn ();
   void ZShadowsOff ();
   void ZShadowsOn ();


B<vtkCursor3D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetFocalPoint (float  a[3]);
      Method is redundant. Same as SetFocalPoint( float, float, float)

   void SetModelBounds (float bounds[6]);
      Method is redundant. Same as SetModelBounds( float, float, float, float, float, float)


=cut

package Graphics::VTK::Cutter;


@Graphics::VTK::Cutter::ISA = qw( Graphics::VTK::DataSetToPolyDataFilter );

=head1 Graphics::VTK::Cutter

=over 1

=item *

Inherits from DataSetToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CreateDefaultLocator ();
   void GenerateCutScalarsOff ();
   void GenerateCutScalarsOn ();
   void GenerateValues (int numContours, float rangeStart, float rangeEnd);
   const char *GetClassName ();
   vtkImplicitFunction *GetCutFunction ();
   int GetGenerateCutScalars ();
   vtkPointLocator *GetLocator ();
   unsigned long GetMTime ();
   int GetNumberOfContours ();
   int GetSortBy ();
   const char *GetSortByAsString ();
   int GetSortByMaxValue ();
   int GetSortByMinValue ();
   float GetValue (int i);
   vtkCutter *New ();
   void SetCutFunction (vtkImplicitFunction *);
   void SetGenerateCutScalars (int );
   void SetLocator (vtkPointLocator *locator);
   void SetNumberOfContours (int number);
   void SetSortBy (int );
   void SetSortByToSortByCell ();
   void SetSortByToSortByValue ();
   void SetValue (int i, float value);


B<vtkCutter Unsupported Funcs:>

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

package Graphics::VTK::CylinderSource;


@Graphics::VTK::CylinderSource::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::CylinderSource

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CappingOff ();
   void CappingOn ();
   int GetCapping ();
   float  *GetCenter ();
      (Returns a 3-element Perl list)
   const char *GetClassName ();
   float GetHeight ();
   float GetHeightMaxValue ();
   float GetHeightMinValue ();
   float GetRadius ();
   float GetRadiusMaxValue ();
   float GetRadiusMinValue ();
   int GetResolution ();
   int GetResolutionMaxValue ();
   int GetResolutionMinValue ();
   vtkCylinderSource *New ();
   void SetCapping (int );
   void SetCenter (float , float , float );
   void SetHeight (float );
   void SetRadius (float );
   void SetResolution (int );


B<vtkCylinderSource Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetCenter (float  a[3]);
      Method is redundant. Same as SetCenter( float, float, float)


=cut

package Graphics::VTK::DashedStreamLine;


@Graphics::VTK::DashedStreamLine::ISA = qw( Graphics::VTK::StreamLine );

=head1 Graphics::VTK::DashedStreamLine

=over 1

=item *

Inherits from StreamLine

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetDashFactor ();
   float GetDashFactorMaxValue ();
   float GetDashFactorMinValue ();
   vtkDashedStreamLine *New ();
   void SetDashFactor (float );


B<vtkDashedStreamLine Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::DataObjectToDataSetFilter;


@Graphics::VTK::DataObjectToDataSetFilter::ISA = qw( Graphics::VTK::Source );

=head1 Graphics::VTK::DataObjectToDataSetFilter

=over 1

=item *

Inherits from Source

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void DefaultNormalizeOff ();
   void DefaultNormalizeOn ();
   int GetCellConnectivityComponentArrayComponent ();
   const char *GetCellConnectivityComponentArrayName ();
   int GetCellConnectivityComponentMaxRange ();
   int GetCellConnectivityComponentMinRange ();
   int GetCellTypeComponentArrayComponent ();
   const char *GetCellTypeComponentArrayName ();
   int GetCellTypeComponentMaxRange ();
   int GetCellTypeComponentMinRange ();
   const char *GetClassName ();
   int GetDataSetType ();
   int GetDefaultNormalize ();
   int  *GetDimensions ();
      (Returns a 3-element Perl list)
   vtkDataObject *GetInput ();
   int GetLinesComponentArrayComponent ();
   const char *GetLinesComponentArrayName ();
   int GetLinesComponentMaxRange ();
   int GetLinesComponentMinRange ();
   float  *GetOrigin ();
      (Returns a 3-element Perl list)
   vtkDataSet *GetOutput (int idx);
   vtkDataSet *GetOutput ();
   int GetPointComponentArrayComponent (int comp);
   const char *GetPointComponentArrayName (int comp);
   int GetPointComponentMaxRange (int comp);
   int GetPointComponentMinRange (int comp);
   int GetPointComponentNormailzeFlag (int comp);
   vtkPolyData *GetPolyDataOutput ();
   int GetPolysComponentArrayComponent ();
   const char *GetPolysComponentArrayName ();
   int GetPolysComponentMaxRange ();
   int GetPolysComponentMinRange ();
   vtkRectilinearGrid *GetRectilinearGridOutput ();
   float  *GetSpacing ();
      (Returns a 3-element Perl list)
   int GetStripsComponentArrayComponent ();
   const char *GetStripsComponentArrayName ();
   int GetStripsComponentMaxRange ();
   int GetStripsComponentMinRange ();
   vtkStructuredGrid *GetStructuredGridOutput ();
   vtkStructuredPoints *GetStructuredPointsOutput ();
   vtkUnstructuredGrid *GetUnstructuredGridOutput ();
   int GetVertsComponentArrayComponent ();
   const char *GetVertsComponentArrayName ();
   int GetVertsComponentMaxRange ();
   int GetVertsComponentMinRange ();
   vtkDataObjectToDataSetFilter *New ();
   void SetCellConnectivityComponent (char *arrayName, int arrayComp, int min, int max);
   void SetCellConnectivityComponent (char *arrayName, int arrayComp);
   void SetCellTypeComponent (char *arrayName, int arrayComp, int min, int max);
   void SetCellTypeComponent (char *arrayName, int arrayComp);
   void SetDataSetType (int );
   void SetDataSetTypeToPolyData ();
   void SetDataSetTypeToRectilinearGrid ();
   void SetDataSetTypeToStructuredGrid ();
   void SetDataSetTypeToStructuredPoints ();
   void SetDataSetTypeToUnstructuredGrid ();
   void SetDefaultNormalize (int );
   void SetDimensions (int , int , int );
   void SetDimensionsComponent (char *arrayName, int arrayComp, int min, int max);
   void SetDimensionsComponent (char *arrayName, int arrayComp);
   void SetInput (vtkDataObject *input);
   void SetLinesComponent (char *arrayName, int arrayComp, int min, int max);
   void SetLinesComponent (char *arrayName, int arrayComp);
   void SetOrigin (float , float , float );
   void SetOriginComponent (char *arrayName, int arrayComp, int min, int max);
   void SetOriginComponent (char *arrayName, int arrayComp);
   void SetPointComponent (int comp, char *arrayName, int arrayComp, int min, int max, int normalize);
   void SetPointComponent (int comp, char *arrayName, int arrayComp);
   void SetPolysComponent (char *arrayName, int arrayComp, int min, int max);
   void SetPolysComponent (char *arrayName, int arrayComp);
   void SetSpacing (float , float , float );
   void SetSpacingComponent (char *arrayName, int arrayComp, int min, int max);
   void SetSpacingComponent (char *arrayName, int arrayComp);
   void SetStripsComponent (char *arrayName, int arrayComp, int min, int max);
   void SetStripsComponent (char *arrayName, int arrayComp);
   void SetVertsComponent (char *arrayName, int arrayComp, int min, int max);
   void SetVertsComponent (char *arrayName, int arrayComp);


B<vtkDataObjectToDataSetFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   vtkCellArray *ConstructCellArray (vtkDataArray *da, int comp, long compRange[2]);
      Don't know the size of pointer arg number 3

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetDimensions (int  a[3]);
      Method is redundant. Same as SetDimensions( int, int, int)

   void SetOrigin (float  a[3]);
      Method is redundant. Same as SetOrigin( float, float, float)

   void SetSpacing (float  a[3]);
      Method is redundant. Same as SetSpacing( float, float, float)


=cut

package Graphics::VTK::DataSetSurfaceFilter;


@Graphics::VTK::DataSetSurfaceFilter::ISA = qw( Graphics::VTK::DataSetToPolyDataFilter );

=head1 Graphics::VTK::DataSetSurfaceFilter

=over 1

=item *

Inherits from DataSetToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetUseStrips ();
   vtkDataSetSurfaceFilter *New ();
   void SetUseStrips (int );
   void UseStripsOff ();
   void UseStripsOn ();


B<vtkDataSetSurfaceFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ExecuteFaceQuads (vtkDataSet *input, int maxFlag, int *ext, int aAxis, int bAxis, int cAxis);
      Don't know the size of pointer arg number 3

   void ExecuteFaceStrips (vtkDataSet *input, int maxFlag, int *ext, int aAxis, int bAxis, int cAxis);
      Don't know the size of pointer arg number 3

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void StructuredExecute (vtkDataSet *input, int *ext);
      Don't know the size of pointer arg number 2


=cut

package Graphics::VTK::DataSetToDataObjectFilter;


@Graphics::VTK::DataSetToDataObjectFilter::ISA = qw( Graphics::VTK::DataObjectSource );

=head1 Graphics::VTK::DataSetToDataObjectFilter

=over 1

=item *

Inherits from DataObjectSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CellDataOff ();
   void CellDataOn ();
   void FieldDataOff ();
   void FieldDataOn ();
   void GeometryOff ();
   void GeometryOn ();
   int GetCellData ();
   const char *GetClassName ();
   int GetFieldData ();
   int GetGeometry ();
   vtkDataSet *GetInput ();
   int GetPointData ();
   int GetTopology ();
   vtkDataSetToDataObjectFilter *New ();
   void PointDataOff ();
   void PointDataOn ();
   void SetCellData (int );
   void SetFieldData (int );
   void SetGeometry (int );
   virtual void SetInput (vtkDataSet *input);
   void SetPointData (int );
   void SetTopology (int );
   void TopologyOff ();
   void TopologyOn ();


B<vtkDataSetToDataObjectFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::DataSetTriangleFilter;


@Graphics::VTK::DataSetTriangleFilter::ISA = qw( Graphics::VTK::DataSetToUnstructuredGridFilter );

=head1 Graphics::VTK::DataSetTriangleFilter

=over 1

=item *

Inherits from DataSetToUnstructuredGridFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkDataSetTriangleFilter *New ();


B<vtkDataSetTriangleFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::DecimatePro;


@Graphics::VTK::DecimatePro::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::DecimatePro

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AccumulateErrorOff ();
   void AccumulateErrorOn ();
   void BoundaryVertexDeletionOff ();
   void BoundaryVertexDeletionOn ();
   float GetAbsoluteError ();
   float GetAbsoluteErrorMaxValue ();
   float GetAbsoluteErrorMinValue ();
   int GetAccumulateError ();
   int GetBoundaryVertexDeletion ();
   const char *GetClassName ();
   int GetDegree ();
   int GetDegreeMaxValue ();
   int GetDegreeMinValue ();
   int GetErrorIsAbsolute ();
   float GetFeatureAngle ();
   float GetFeatureAngleMaxValue ();
   float GetFeatureAngleMinValue ();
   float GetInflectionPointRatio ();
   float GetInflectionPointRatioMaxValue ();
   float GetInflectionPointRatioMinValue ();
   float GetMaximumError ();
   float GetMaximumErrorMaxValue ();
   float GetMaximumErrorMinValue ();
   long GetNumberOfInflectionPoints ();
   int GetPreSplitMesh ();
   int GetPreserveTopology ();
   float GetSplitAngle ();
   float GetSplitAngleMaxValue ();
   float GetSplitAngleMinValue ();
   int GetSplitting ();
   float GetTargetReduction ();
   float GetTargetReductionMaxValue ();
   float GetTargetReductionMinValue ();
   vtkDecimatePro *New ();
   void PreSplitMeshOff ();
   void PreSplitMeshOn ();
   void PreserveTopologyOff ();
   void PreserveTopologyOn ();
   void SetAbsoluteError (float );
   void SetAccumulateError (int );
   void SetBoundaryVertexDeletion (int );
   void SetDegree (int );
   void SetErrorIsAbsolute (int );
   void SetFeatureAngle (float );
   void SetInflectionPointRatio (float );
   void SetMaximumError (float );
   void SetPreSplitMesh (int );
   void SetPreserveTopology (int );
   void SetSplitAngle (float );
   void SetSplitting (int );
   void SetTargetReduction (float );
   void SplittingOff ();
   void SplittingOn ();


B<vtkDecimatePro Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int EvaluateVertex (long ptId, unsigned short numTris, long *tris, long fedges[2]);
      Don't know the size of pointer arg number 3

   long FindSplit (int type, long fedges[2], long &pt1, long &pt2, vtkIdList *CollapseTris);
      Don't know the size of pointer arg number 2

   void GetInflectionPoints (float *inflectionPoints);
      Don't know the size of pointer arg number 1

   float *GetInflectionPoints ();
      Can't Handle 'float *' return type without a hint

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SplitLoop (long fedges[2], long &n1, long *l1, long &n2, long *l2);
      Don't know the size of pointer arg number 1

   void SplitVertex (long ptId, int type, unsigned short numTris, long *tris, int insert);
      Don't know the size of pointer arg number 4


=cut

package Graphics::VTK::Delaunay2D;


@Graphics::VTK::Delaunay2D::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::Delaunay2D

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void BoundingTriangulationOff ();
   void BoundingTriangulationOn ();
   double GetAlpha ();
   double GetAlphaMaxValue ();
   double GetAlphaMinValue ();
   int GetBoundingTriangulation ();
   const char *GetClassName ();
   vtkPointSet *GetInput ();
   double GetOffset ();
   double GetOffsetMaxValue ();
   double GetOffsetMinValue ();
   vtkPolyData *GetSource ();
   double GetTolerance ();
   double GetToleranceMaxValue ();
   double GetToleranceMinValue ();
   vtkAbstractTransform *GetTransform ();
   vtkDelaunay2D *New ();
   void SetAlpha (double );
   void SetBoundingTriangulation (int );
   virtual void SetInput (vtkPointSet *input);
   void SetOffset (double );
   void SetSource (vtkPolyData *);
   void SetTolerance (double );
   void SetTransform (vtkAbstractTransform *);


B<vtkDelaunay2D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void CheckEdge (long ptId, double x[3], long p1, long p2, long tri);
      Don't know the size of pointer arg number 2

   void FillPolygons (vtkCellArray *polys, int *triUse);
      Don't know the size of pointer arg number 2

   long FindTriangle (double x[3], long ptIds[3], long tri, double tol, long nei[3], vtkIdList *neighbors);
      Don't know the size of pointer arg number 1

   void GetPoint (long id, double x[3]);
      Don't know the size of pointer arg number 2

   int InCircle (double x[3], double x1[3], double x2[3], double x3[3]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   int *RecoverBoundary ();
      Can't Handle 'int *' return type without a hint

   void SetPoint (long id, double *x);
      Don't know the size of pointer arg number 2


=cut

package Graphics::VTK::Delaunay3D;


@Graphics::VTK::Delaunay3D::ISA = qw( Graphics::VTK::UnstructuredGridSource );

=head1 Graphics::VTK::Delaunay3D

=over 1

=item *

Inherits from UnstructuredGridSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void BoundingTriangulationOff ();
   void BoundingTriangulationOn ();
   void CreateDefaultLocator ();
   void EndPointInsertion ();
   float GetAlpha ();
   float GetAlphaMaxValue ();
   float GetAlphaMinValue ();
   int GetBoundingTriangulation ();
   const char *GetClassName ();
   vtkPointSet *GetInput ();
   vtkPointLocator *GetLocator ();
   unsigned long GetMTime ();
   float GetOffset ();
   float GetOffsetMaxValue ();
   float GetOffsetMinValue ();
   float GetTolerance ();
   float GetToleranceMaxValue ();
   float GetToleranceMinValue ();
   vtkDelaunay3D *New ();
   void SetAlpha (float );
   void SetBoundingTriangulation (int );
   virtual void SetInput (vtkPointSet *input);
   void SetLocator (vtkPointLocator *locator);
   void SetOffset (float );
   void SetTolerance (float );


B<vtkDelaunay3D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   long FindEnclosingFaces (float x[3], vtkUnstructuredGrid *Mesh, vtkIdList *tetras, vtkIdList *faces, vtkPointLocator *Locator);
      Don't know the size of pointer arg number 1

   int FindTetra (vtkUnstructuredGrid *Mesh, double x[3], long tetId, int depth);
      Don't know the size of pointer arg number 2

   int InSphere (double x[3], long tetraId);
      Don't know the size of pointer arg number 1

   vtkUnstructuredGrid *InitPointInsertion (float center[3], float length, long numPts, vtkPoints &pts);
      Don't know the size of pointer arg number 1

   void InsertPoint (vtkUnstructuredGrid *Mesh, vtkPoints *points, long id, float x[3], vtkIdList *holeTetras);
      Don't know the size of pointer arg number 4

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::Dicer;


@Graphics::VTK::Dicer::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::Dicer

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void FieldDataOff ();
   void FieldDataOn ();
   const char *GetClassName ();
   int GetDiceMode ();
   int GetDiceModeMaxValue ();
   int GetDiceModeMinValue ();
   int GetFieldData ();
   long unsigned GetMemoryLimit ();
   unsigned GetMemoryLimitMaxValue ();
   unsigned GetMemoryLimitMinValue ();
   int GetNumberOfActualPieces ();
   int GetNumberOfPieces ();
   int GetNumberOfPiecesMaxValue ();
   int GetNumberOfPiecesMinValue ();
   int GetNumberOfPointsPerPiece ();
   int GetNumberOfPointsPerPieceMaxValue ();
   int GetNumberOfPointsPerPieceMinValue ();
   void SetDiceMode (int );
   void SetDiceModeToMemoryLimitPerPiece ();
   void SetDiceModeToNumberOfPointsPerPiece ();
   void SetDiceModeToSpecifiedNumberOfPieces ();
   void SetFieldData (int );
   void SetMemoryLimit (unsigned long );
   void SetNumberOfPieces (int );
   void SetNumberOfPointsPerPiece (int );


B<vtkDicer Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::DiskSource;


@Graphics::VTK::DiskSource::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::DiskSource

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int GetCircumferentialResolution ();
   int GetCircumferentialResolutionMaxValue ();
   int GetCircumferentialResolutionMinValue ();
   const char *GetClassName ();
   float GetInnerRadius ();
   float GetInnerRadiusMaxValue ();
   float GetInnerRadiusMinValue ();
   float GetOuterRadius ();
   float GetOuterRadiusMaxValue ();
   float GetOuterRadiusMinValue ();
   int GetRadialResolution ();
   int GetRadialResolutionMaxValue ();
   int GetRadialResolutionMinValue ();
   vtkDiskSource *New ();
   void SetCircumferentialResolution (int );
   void SetInnerRadius (float );
   void SetOuterRadius (float );
   void SetRadialResolution (int );


B<vtkDiskSource Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::EdgePoints;


@Graphics::VTK::EdgePoints::ISA = qw( Graphics::VTK::DataSetToPolyDataFilter );

=head1 Graphics::VTK::EdgePoints

=over 1

=item *

Inherits from DataSetToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetValue ();
   vtkEdgePoints *New ();
   void SetValue (float );


B<vtkEdgePoints Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ElevationFilter;


@Graphics::VTK::ElevationFilter::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::ElevationFilter

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float  *GetHighPoint ();
      (Returns a 3-element Perl list)
   float  *GetLowPoint ();
      (Returns a 3-element Perl list)
   float  *GetScalarRange ();
      (Returns a 2-element Perl list)
   vtkElevationFilter *New ();
   void SetHighPoint (float , float , float );
   void SetLowPoint (float , float , float );
   void SetScalarRange (float , float );


B<vtkElevationFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetHighPoint (float  a[3]);
      Method is redundant. Same as SetHighPoint( float, float, float)

   void SetLowPoint (float  a[3]);
      Method is redundant. Same as SetLowPoint( float, float, float)

   void SetScalarRange (float  a[2]);
      Method is redundant. Same as SetScalarRange( float, float)


=cut

package Graphics::VTK::ExtractEdges;


@Graphics::VTK::ExtractEdges::ISA = qw( Graphics::VTK::DataSetToPolyDataFilter );

=head1 Graphics::VTK::ExtractEdges

=over 1

=item *

Inherits from DataSetToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CreateDefaultLocator ();
   const char *GetClassName ();
   vtkPointLocator *GetLocator ();
   unsigned long GetMTime ();
   vtkExtractEdges *New ();
   void SetLocator (vtkPointLocator *locator);


B<vtkExtractEdges Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ExtractGeometry;


@Graphics::VTK::ExtractGeometry::ISA = qw( Graphics::VTK::DataSetToUnstructuredGridFilter );

=head1 Graphics::VTK::ExtractGeometry

=over 1

=item *

Inherits from DataSetToUnstructuredGridFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void ExtractBoundaryCellsOff ();
   void ExtractBoundaryCellsOn ();
   void ExtractInsideOff ();
   void ExtractInsideOn ();
   const char *GetClassName ();
   int GetExtractBoundaryCells ();
   int GetExtractInside ();
   vtkImplicitFunction *GetImplicitFunction ();
   unsigned long GetMTime ();
   vtkExtractGeometry *New ();
   void SetExtractBoundaryCells (int );
   void SetExtractInside (int );
   void SetImplicitFunction (vtkImplicitFunction *);


B<vtkExtractGeometry Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ExtractGrid;


@Graphics::VTK::ExtractGrid::ISA = qw( Graphics::VTK::StructuredGridToStructuredGridFilter );

=head1 Graphics::VTK::ExtractGrid

=over 1

=item *

Inherits from StructuredGridToStructuredGridFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetIncludeBoundary ();
   int  *GetSampleRate ();
      (Returns a 3-element Perl list)
   int  *GetVOI ();
      (Returns a 6-element Perl list)
   void IncludeBoundaryOff ();
   void IncludeBoundaryOn ();
   vtkExtractGrid *New ();
   void SetIncludeBoundary (int );
   void SetSampleRate (int , int , int );
   void SetVOI (int , int , int , int , int , int );


B<vtkExtractGrid Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetSampleRate (int  a[3]);
      Method is redundant. Same as SetSampleRate( int, int, int)

   void SetVOI (int  a[6]);
      Method is redundant. Same as SetVOI( int, int, int, int, int, int)


=cut

package Graphics::VTK::ExtractPolyDataGeometry;


@Graphics::VTK::ExtractPolyDataGeometry::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::ExtractPolyDataGeometry

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void ExtractBoundaryCellsOff ();
   void ExtractBoundaryCellsOn ();
   void ExtractInsideOff ();
   void ExtractInsideOn ();
   const char *GetClassName ();
   int GetExtractBoundaryCells ();
   int GetExtractInside ();
   vtkImplicitFunction *GetImplicitFunction ();
   unsigned long GetMTime ();
   vtkExtractPolyDataGeometry *New ();
   void SetExtractBoundaryCells (int );
   void SetExtractInside (int );
   void SetImplicitFunction (vtkImplicitFunction *);


B<vtkExtractPolyDataGeometry Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ExtractTensorComponents;


@Graphics::VTK::ExtractTensorComponents::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::ExtractTensorComponents

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void ExtractNormalsOff ();
   void ExtractNormalsOn ();
   void ExtractScalarsOff ();
   void ExtractScalarsOn ();
   void ExtractTCoordsOff ();
   void ExtractTCoordsOn ();
   void ExtractVectorsOff ();
   void ExtractVectorsOn ();
   const char *GetClassName ();
   int GetExtractNormals ();
   int GetExtractScalars ();
   int GetExtractTCoords ();
   int GetExtractVectors ();
   int  *GetNormalComponents ();
      (Returns a 6-element Perl list)
   int GetNormalizeNormals ();
   int GetNumberOfTCoords ();
   int GetNumberOfTCoordsMaxValue ();
   int GetNumberOfTCoordsMinValue ();
   int GetPassTensorsToOutput ();
   int  *GetScalarComponents ();
      (Returns a 2-element Perl list)
   int GetScalarMode ();
   int  *GetTCoordComponents ();
      (Returns a 6-element Perl list)
   int  *GetVectorComponents ();
      (Returns a 6-element Perl list)
   vtkExtractTensorComponents *New ();
   void NormalizeNormalsOff ();
   void NormalizeNormalsOn ();
   void PassTensorsToOutputOff ();
   void PassTensorsToOutputOn ();
   void ScalarIsComponent ();
   void ScalarIsDeterminant ();
   void ScalarIsEffectiveStress ();
   void SetExtractNormals (int );
   void SetExtractScalars (int );
   void SetExtractTCoords (int );
   void SetExtractVectors (int );
   void SetNormalComponents (int , int , int , int , int , int );
   void SetNormalizeNormals (int );
   void SetNumberOfTCoords (int );
   void SetPassTensorsToOutput (int );
   void SetScalarComponents (int , int );
   void SetScalarMode (int );
   void SetTCoordComponents (int , int , int , int , int , int );
   void SetVectorComponents (int , int , int , int , int , int );


B<vtkExtractTensorComponents Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetNormalComponents (int  a[6]);
      Method is redundant. Same as SetNormalComponents( int, int, int, int, int, int)

   void SetScalarComponents (int  a[2]);
      Method is redundant. Same as SetScalarComponents( int, int)

   void SetTCoordComponents (int  a[6]);
      Method is redundant. Same as SetTCoordComponents( int, int, int, int, int, int)

   void SetVectorComponents (int  a[6]);
      Method is redundant. Same as SetVectorComponents( int, int, int, int, int, int)


=cut

package Graphics::VTK::ExtractUnstructuredGrid;


@Graphics::VTK::ExtractUnstructuredGrid::ISA = qw( Graphics::VTK::UnstructuredGridToUnstructuredGridFilter );

=head1 Graphics::VTK::ExtractUnstructuredGrid

=over 1

=item *

Inherits from UnstructuredGridToUnstructuredGridFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CellClippingOff ();
   void CellClippingOn ();
   void CreateDefaultLocator ();
   void ExtentClippingOff ();
   void ExtentClippingOn ();
   int GetCellClipping ();
   long GetCellMaximum ();
   long GetCellMaximumMaxValue ();
   long GetCellMaximumMinValue ();
   long GetCellMinimum ();
   long GetCellMinimumMaxValue ();
   long GetCellMinimumMinValue ();
   const char *GetClassName ();
   float *GetExtent ();
      (Returns a 6-element Perl list)
   int GetExtentClipping ();
   vtkPointLocator *GetLocator ();
   unsigned long GetMTime ();
   int GetMerging ();
   int GetPointClipping ();
   long GetPointMaximum ();
   long GetPointMaximumMaxValue ();
   long GetPointMaximumMinValue ();
   long GetPointMinimum ();
   long GetPointMinimumMaxValue ();
   long GetPointMinimumMinValue ();
   void MergingOff ();
   void MergingOn ();
   vtkExtractUnstructuredGrid *New ();
   void PointClippingOff ();
   void PointClippingOn ();
   void SetCellClipping (int );
   void SetCellMaximum (long );
   void SetCellMinimum (long );
   void SetExtent (float xMin, float xMax, float yMin, float yMax, float zMin, float zMax);
   void SetExtentClipping (int );
   void SetLocator (vtkPointLocator *locator);
   void SetMerging (int );
   void SetPointClipping (int );
   void SetPointMaximum (long );
   void SetPointMinimum (long );


B<vtkExtractUnstructuredGrid Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetExtent (float extent[6]);
      Method is redundant. Same as SetExtent( float, float, float, float, float, float)


=cut

package Graphics::VTK::ExtractVectorComponents;


@Graphics::VTK::ExtractVectorComponents::ISA = qw( Graphics::VTK::Source );

=head1 Graphics::VTK::ExtractVectorComponents

=over 1

=item *

Inherits from Source

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void ExtractToFieldDataOff ();
   void ExtractToFieldDataOn ();
   const char *GetClassName ();
   int GetExtractToFieldData ();
   vtkDataSet *GetInput ();
   vtkDataSet *GetOutput (int i);
   vtkDataSet *GetVxComponent ();
   vtkDataSet *GetVyComponent ();
   vtkDataSet *GetVzComponent ();
   vtkExtractVectorComponents *New ();
   void SetExtractToFieldData (int );
   virtual void SetInput (vtkDataSet *input);


B<vtkExtractVectorComponents Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::FeatureEdges;


@Graphics::VTK::FeatureEdges::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::FeatureEdges

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void BoundaryEdgesOff ();
   void BoundaryEdgesOn ();
   void ColoringOff ();
   void ColoringOn ();
   void CreateDefaultLocator ();
   void FeatureEdgesOff ();
   void FeatureEdgesOn ();
   int GetBoundaryEdges ();
   const char *GetClassName ();
   int GetColoring ();
   float GetFeatureAngle ();
   float GetFeatureAngleMaxValue ();
   float GetFeatureAngleMinValue ();
   int GetFeatureEdges ();
   vtkPointLocator *GetLocator ();
   unsigned long GetMTime ();
   int GetManifoldEdges ();
   int GetNonManifoldEdges ();
   void ManifoldEdgesOff ();
   void ManifoldEdgesOn ();
   vtkFeatureEdges *New ();
   void NonManifoldEdgesOff ();
   void NonManifoldEdgesOn ();
   void SetBoundaryEdges (int );
   void SetColoring (int );
   void SetFeatureAngle (float );
   void SetFeatureEdges (int );
   void SetLocator (vtkPointLocator *locator);
   void SetManifoldEdges (int );
   void SetNonManifoldEdges (int );


B<vtkFeatureEdges Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::FieldDataToAttributeDataFilter;


@Graphics::VTK::FieldDataToAttributeDataFilter::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::FieldDataToAttributeDataFilter

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   virtual void ComputeInputUpdateExtents (vtkDataObject *output);
   static int ConstructArray (vtkDataArray *da, int comp, vtkDataArray *frray, int fieldComp, long min, long max, int normalize);
   void DefaultNormalizeOff ();
   void DefaultNormalizeOn ();
   const char *GetClassName ();
   int GetDefaultNormalize ();
   static vtkDataArray *GetFieldArray (vtkFieldData *fd, char *name, int comp);
   int GetInputField ();
   int GetNormalComponentArrayComponent (int comp);
   const char *GetNormalComponentArrayName (int comp);
   int GetNormalComponentMaxRange (int comp);
   int GetNormalComponentMinRange (int comp);
   int GetNormalComponentNormalizeFlag (int comp);
   int GetOutputAttributeData ();
   int GetScalarComponentArrayComponent (int comp);
   const char *GetScalarComponentArrayName (int comp);
   int GetScalarComponentMaxRange (int comp);
   int GetScalarComponentMinRange (int comp);
   int GetScalarComponentNormalizeFlag (int comp);
   int GetTCoordComponentArrayComponent (int comp);
   const char *GetTCoordComponentArrayName (int comp);
   int GetTCoordComponentMaxRange (int comp);
   int GetTCoordComponentMinRange (int comp);
   int GetTCoordComponentNormalizeFlag (int comp);
   int GetTensorComponentArrayComponent (int comp);
   const char *GetTensorComponentArrayName (int comp);
   int GetTensorComponentMaxRange (int comp);
   int GetTensorComponentMinRange (int comp);
   int GetTensorComponentNormalizeFlag (int comp);
   int GetVectorComponentArrayComponent (int comp);
   const char *GetVectorComponentArrayName (int comp);
   int GetVectorComponentMaxRange (int comp);
   int GetVectorComponentMinRange (int comp);
   int GetVectorComponentNormalizeFlag (int comp);
   vtkFieldDataToAttributeDataFilter *New ();
   void SetDefaultNormalize (int );
   void SetInputField (int );
   void SetInputFieldToCellDataField ();
   void SetInputFieldToDataObjectField ();
   void SetInputFieldToPointDataField ();
   void SetNormalComponent (int comp, const char *arrayName, int arrayComp, int min, int max, int normalize);
   void SetNormalComponent (int comp, const char *arrayName, int arrayComp);
   void SetOutputAttributeData (int );
   void SetOutputAttributeDataToCellData ();
   void SetOutputAttributeDataToPointData ();
   void SetScalarComponent (int comp, const char *arrayName, int arrayComp, int min, int max, int normalize);
   void SetScalarComponent (int comp, const char *arrayName, int arrayComp);
   void SetTCoordComponent (int comp, const char *arrayName, int arrayComp, int min, int max, int normalize);
   void SetTCoordComponent (int comp, const char *arrayName, int arrayComp);
   void SetTensorComponent (int comp, const char *arrayName, int arrayComp, int min, int max, int normalize);
   void SetTensorComponent (int comp, const char *arrayName, int arrayComp);
   void SetVectorComponent (int comp, const char *arrayName, int arrayComp, int min, int max, int normalize);
   void SetVectorComponent (int comp, const char *arrayName, int arrayComp);


B<vtkFieldDataToAttributeDataFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ConstructGhostLevels (int num, vtkFieldData *fd, vtkDataSetAttributes *attr, long componentRange[2], char *array, int arrayComponent, int normalize);
      Don't know the size of pointer arg number 4

   void ConstructNormals (int num, vtkFieldData *fd, vtkDataSetAttributes *attr, long componentRange[3][2], char *arrays[3], int arrayComponents[3], int normalize[3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void ConstructScalars (int num, vtkFieldData *fd, vtkDataSetAttributes *attr, long componentRange[4][2], char *arrays[4], int arrayComponents[4], int normalize[4], int numComp);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void ConstructTCoords (int num, vtkFieldData *fd, vtkDataSetAttributes *attr, long componentRange[3][2], char *arrays[3], int arrayComponents[3], int normalize[3], int numComp);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void ConstructTensors (int num, vtkFieldData *fd, vtkDataSetAttributes *attr, long componentRange[9][2], char *arrays[9], int arrayComponents[9], int normalize[9]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void ConstructVectors (int num, vtkFieldData *fd, vtkDataSetAttributes *attr, long componentRange[3][2], char *arrays[3], int arrayComponents[3], int normalize[3]);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   static int GetComponentsType (int numComp, vtkDataArray *arrays);
      Can't Parse Arg ' vtkDataArray ** arrays'
   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   static void SetArrayName (vtkObject *self, char &name, const char *newName);
      Can't Parse Arg ' char * &name'

=cut

package Graphics::VTK::GeometryFilter;


@Graphics::VTK::GeometryFilter::ISA = qw( Graphics::VTK::DataSetToPolyDataFilter );

=head1 Graphics::VTK::GeometryFilter

=over 1

=item *

Inherits from DataSetToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CellClippingOff ();
   void CellClippingOn ();
   void CreateDefaultLocator ();
   void ExtentClippingOff ();
   void ExtentClippingOn ();
   int GetCellClipping ();
   long GetCellMaximum ();
   long GetCellMaximumMaxValue ();
   long GetCellMaximumMinValue ();
   long GetCellMinimum ();
   long GetCellMinimumMaxValue ();
   long GetCellMinimumMinValue ();
   const char *GetClassName ();
   float *GetExtent ();
      (Returns a 6-element Perl list)
   int GetExtentClipping ();
   vtkPointLocator *GetLocator ();
   unsigned long GetMTime ();
   int GetMerging ();
   int GetPointClipping ();
   long GetPointMaximum ();
   long GetPointMaximumMaxValue ();
   long GetPointMaximumMinValue ();
   long GetPointMinimum ();
   long GetPointMinimumMaxValue ();
   long GetPointMinimumMinValue ();
   void MergingOff ();
   void MergingOn ();
   vtkGeometryFilter *New ();
   void PointClippingOff ();
   void PointClippingOn ();
   void SetCellClipping (int );
   void SetCellMaximum (long );
   void SetCellMinimum (long );
   void SetExtent (float xMin, float xMax, float yMin, float yMax, float zMin, float zMax);
   void SetExtentClipping (int );
   void SetLocator (vtkPointLocator *locator);
   void SetMerging (int );
   void SetPointClipping (int );
   void SetPointMaximum (long );
   void SetPointMinimum (long );


B<vtkGeometryFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetExtent (float extent[6]);
      Method is redundant. Same as SetExtent( float, float, float, float, float, float)


=cut

package Graphics::VTK::Glyph2D;


@Graphics::VTK::Glyph2D::ISA = qw( Graphics::VTK::Glyph3D );

=head1 Graphics::VTK::Glyph2D

=over 1

=item *

Inherits from Glyph3D

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkGlyph2D *New ();


B<vtkGlyph2D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::Glyph3D;


@Graphics::VTK::Glyph3D::ISA = qw( Graphics::VTK::DataSetToPolyDataFilter );

=head1 Graphics::VTK::Glyph3D

=over 1

=item *

Inherits from DataSetToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void ClampingOff ();
   void ClampingOn ();
   void GeneratePointIdsOff ();
   void GeneratePointIdsOn ();
   int GetClamping ();
   const char *GetClassName ();
   int GetColorMode ();
   const char *GetColorModeAsString ();
   int GetGeneratePointIds ();
   int GetIndexMode ();
   const char *GetIndexModeAsString ();
   int GetNumberOfSources ();
   int GetOrient ();
   char *GetPointIdsName ();
   float  *GetRange ();
      (Returns a 2-element Perl list)
   float GetScaleFactor ();
   int GetScaleMode ();
   const char *GetScaleModeAsString ();
   int GetScaling ();
   vtkPolyData *GetSource (int id);
   int GetVectorMode ();
   const char *GetVectorModeAsString ();
   vtkGlyph3D *New ();
   void OrientOff ();
   void OrientOn ();
   void ScalingOff ();
   void ScalingOn ();
   void SetClamping (int );
   void SetColorMode (int );
   void SetColorModeToColorByScalar ();
   void SetColorModeToColorByScale ();
   void SetColorModeToColorByVector ();
   void SetGeneratePointIds (int );
   void SetIndexMode (int );
   void SetIndexModeToOff ();
   void SetIndexModeToScalar ();
   void SetIndexModeToVector ();
   void SetNumberOfSources (int num);
   void SetOrient (int );
   void SetPointIdsName (char *);
   void SetRange (float , float );
   void SetScaleFactor (float );
   void SetScaleMode (int );
   void SetScaleModeToDataScalingOff ();
   void SetScaleModeToScaleByScalar ();
   void SetScaleModeToScaleByVector ();
   void SetScaleModeToScaleByVectorComponents ();
   void SetScaling (int );
   void SetSource (int id, vtkPolyData *pd);
   void SetSource (vtkPolyData *pd);
   void SetVectorMode (int );
   void SetVectorModeToUseNormal ();
   void SetVectorModeToUseVector ();
   void SetVectorModeToVectorRotationOff ();


B<vtkGlyph3D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetRange (float  a[2]);
      Method is redundant. Same as SetRange( float, float)


=cut

package Graphics::VTK::GlyphSource2D;


@Graphics::VTK::GlyphSource2D::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::GlyphSource2D

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CrossOff ();
   void CrossOn ();
   void DashOff ();
   void DashOn ();
   void FilledOff ();
   void FilledOn ();
   float  *GetCenter ();
      (Returns a 3-element Perl list)
   const char *GetClassName ();
   float  *GetColor ();
      (Returns a 3-element Perl list)
   int GetCross ();
   int GetDash ();
   int GetFilled ();
   int GetGlyphType ();
   int GetGlyphTypeMaxValue ();
   int GetGlyphTypeMinValue ();
   float GetRotationAngle ();
   float GetScale ();
   float GetScale2 ();
   float GetScale2MaxValue ();
   float GetScale2MinValue ();
   float GetScaleMaxValue ();
   float GetScaleMinValue ();
   vtkGlyphSource2D *New ();
   void SetCenter (float , float , float );
   void SetColor (float , float , float );
   void SetCross (int );
   void SetDash (int );
   void SetFilled (int );
   void SetGlyphType (int );
   void SetGlyphTypeToArrow ();
   void SetGlyphTypeToCircle ();
   void SetGlyphTypeToCross ();
   void SetGlyphTypeToDash ();
   void SetGlyphTypeToDiamond ();
   void SetGlyphTypeToHookedArrow ();
   void SetGlyphTypeToNone ();
   void SetGlyphTypeToSquare ();
   void SetGlyphTypeToThickArrow ();
   void SetGlyphTypeToThickCross ();
   void SetGlyphTypeToTriangle ();
   void SetGlyphTypeToVertex ();
   void SetRotationAngle (float );
   void SetScale (float );
   void SetScale2 (float );


B<vtkGlyphSource2D Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetCenter (float  a[3]);
      Method is redundant. Same as SetCenter( float, float, float)

   void SetColor (float  a[3]);
      Method is redundant. Same as SetColor( float, float, float)


=cut

package Graphics::VTK::GraphLayoutFilter;


@Graphics::VTK::GraphLayoutFilter::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::GraphLayoutFilter

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AutomaticBoundsComputationOff ();
   void AutomaticBoundsComputationOn ();
   int GetAutomaticBoundsComputation ();
   const char *GetClassName ();
   float GetCoolDownRate ();
   float GetCoolDownRateMaxValue ();
   float GetCoolDownRateMinValue ();
   float  *GetGraphBounds ();
      (Returns a 6-element Perl list)
   int GetMaxNumberOfIterations ();
   int GetMaxNumberOfIterationsMaxValue ();
   int GetMaxNumberOfIterationsMinValue ();
   int GetThreeDimensionalLayout ();
   vtkGraphLayoutFilter *New ();
   void SetAutomaticBoundsComputation (int );
   void SetCoolDownRate (float );
   void SetGraphBounds (float , float , float , float , float , float );
   void SetMaxNumberOfIterations (int );
   void SetThreeDimensionalLayout (int );
   void ThreeDimensionalLayoutOff ();
   void ThreeDimensionalLayoutOn ();


B<vtkGraphLayoutFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetGraphBounds (float  a[6]);
      Method is redundant. Same as SetGraphBounds( float, float, float, float, float, float)


=cut

package Graphics::VTK::HedgeHog;


@Graphics::VTK::HedgeHog::ISA = qw( Graphics::VTK::DataSetToPolyDataFilter );

=head1 Graphics::VTK::HedgeHog

=over 1

=item *

Inherits from DataSetToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetScaleFactor ();
   int GetVectorMode ();
   const char *GetVectorModeAsString ();
   vtkHedgeHog *New ();
   void SetScaleFactor (float );
   void SetVectorMode (int );
   void SetVectorModeToUseNormal ();
   void SetVectorModeToUseVector ();


B<vtkHedgeHog Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::Hull;


@Graphics::VTK::Hull::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::Hull

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddCubeEdgePlanes ();
   void AddCubeFacePlanes ();
   void AddCubeVertexPlanes ();
   int AddPlane (float A, float B, float C, float D);
   int AddPlane (float A, float B, float C);
   void AddRecursiveSpherePlanes (int level);
   void GenerateHull (vtkPolyData *pd, float xmin, float xmax, float ymin, float ymax, float zmin, float zmax);
   const char *GetClassName ();
   int GetNumberOfPlanes ();
   vtkHull *New ();
   void RemoveAllPlanes (void );
   void SetPlane (int i, float A, float B, float C, float D);
   void SetPlane (int i, float A, float B, float C);
   void SetPlanes (vtkPlanes *planes);


B<vtkHull Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int AddPlane (float plane[3]);
      Method is redundant. Same as AddPlane( float, float, float)

   int AddPlane (float plane[3], float D);
      Don't know the size of pointer arg number 1

   void ClipPolygonsFromPlanes (vtkPoints *points, vtkCellArray *polys, float *bounds);
      Don't know the size of pointer arg number 3

   void CreateInitialPolygon (double *, int , float *);
      Don't know the size of pointer arg number 1

   void GenerateHull (vtkPolyData *pd, float *bounds);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetPlane (int i, float plane[3]);
      Don't know the size of pointer arg number 2

   void SetPlane (int i, float plane[3], float D);
      Don't know the size of pointer arg number 2


=cut

package Graphics::VTK::HyperStreamline;


@Graphics::VTK::HyperStreamline::ISA = qw( Graphics::VTK::DataSetToPolyDataFilter );

=head1 Graphics::VTK::HyperStreamline

=over 1

=item *

Inherits from DataSetToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetIntegrationDirection ();
   int GetIntegrationDirectionMaxValue ();
   int GetIntegrationDirectionMinValue ();
   float GetIntegrationStepLength ();
   float GetIntegrationStepLengthMaxValue ();
   float GetIntegrationStepLengthMinValue ();
   int GetLogScaling ();
   float GetMaximumPropagationDistance ();
   float GetMaximumPropagationDistanceMaxValue ();
   float GetMaximumPropagationDistanceMinValue ();
   int GetNumberOfSides ();
   int GetNumberOfSidesMaxValue ();
   int GetNumberOfSidesMinValue ();
   float GetRadius ();
   float GetRadiusMaxValue ();
   float GetRadiusMinValue ();
   float *GetStartPosition ();
      (Returns a 3-element Perl list)
   float GetStepLength ();
   float GetStepLengthMaxValue ();
   float GetStepLengthMinValue ();
   float GetTerminalEigenvalue ();
   float GetTerminalEigenvalueMaxValue ();
   float GetTerminalEigenvalueMinValue ();
   void IntegrateMajorEigenvector ();
   void IntegrateMediumEigenvector ();
   void IntegrateMinorEigenvector ();
   void LogScalingOff ();
   void LogScalingOn ();
   vtkHyperStreamline *New ();
   void SetIntegrationDirection (int );
   void SetIntegrationDirectionToBackward ();
   void SetIntegrationDirectionToForward ();
   void SetIntegrationDirectionToIntegrateBothDirections ();
   void SetIntegrationStepLength (float );
   void SetLogScaling (int );
   void SetMaximumPropagationDistance (float );
   void SetNumberOfSides (int );
   void SetRadius (float );
   void SetStartLocation (long cellId, int subId, float r, float s, float t);
   void SetStartPosition (float x, float y, float z);
   void SetStepLength (float );
   void SetTerminalEigenvalue (float );


B<vtkHyperStreamline Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   long GetStartLocation (int &subId, float pcoords[3]);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetStartLocation (long cellId, int subId, float pcoords[3]);
      Don't know the size of pointer arg number 3

   void SetStartPosition (float x[3]);
      Method is redundant. Same as SetStartPosition( float, float, float)


=cut

package Graphics::VTK::IdFilter;


@Graphics::VTK::IdFilter::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::IdFilter

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CellIdsOff ();
   void CellIdsOn ();
   void FieldDataOff ();
   void FieldDataOn ();
   int GetCellIds ();
   const char *GetClassName ();
   int GetFieldData ();
   char *GetIdsArrayName ();
   int GetPointIds ();
   vtkIdFilter *New ();
   void PointIdsOff ();
   void PointIdsOn ();
   void SetCellIds (int );
   void SetFieldData (int );
   void SetIdsArrayName (char *);
   void SetPointIds (int );


B<vtkIdFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ImageDataGeometryFilter;


@Graphics::VTK::ImageDataGeometryFilter::ISA = qw( Graphics::VTK::StructuredPointsToPolyDataFilter );

=head1 Graphics::VTK::ImageDataGeometryFilter

=over 1

=item *

Inherits from StructuredPointsToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageDataGeometryFilter *New ();
   void SetExtent (int iMin, int iMax, int jMin, int jMax, int kMin, int kMax);


B<vtkImageDataGeometryFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int *GetExtent ();
      Can't Handle 'int *' return type without a hint

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetExtent (int extent[6]);
      Method is redundant. Same as SetExtent( int, int, int, int, int, int)


=cut

package Graphics::VTK::ImplicitTextureCoords;


@Graphics::VTK::ImplicitTextureCoords::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::ImplicitTextureCoords

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void FlipTextureOff ();
   void FlipTextureOn ();
   const char *GetClassName ();
   int GetFlipTexture ();
   vtkImplicitFunction *GetRFunction ();
   vtkImplicitFunction *GetSFunction ();
   vtkImplicitFunction *GetTFunction ();
   vtkImplicitTextureCoords *New ();
   void SetFlipTexture (int );
   void SetRFunction (vtkImplicitFunction *);
   void SetSFunction (vtkImplicitFunction *);
   void SetTFunction (vtkImplicitFunction *);


B<vtkImplicitTextureCoords Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::InterpolateDataSetAttributes;


@Graphics::VTK::InterpolateDataSetAttributes::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::InterpolateDataSetAttributes

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddInput (vtkDataSet *in);
   const char *GetClassName ();
   vtkDataSetCollection *GetInputList ();
   float GetT ();
   float GetTMaxValue ();
   float GetTMinValue ();
   vtkInterpolateDataSetAttributes *New ();
   void SetT (float );


B<vtkInterpolateDataSetAttributes Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::InterpolatingSubdivisionFilter;


@Graphics::VTK::InterpolatingSubdivisionFilter::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::InterpolatingSubdivisionFilter

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetNumberOfSubdivisions ();
   void SetNumberOfSubdivisions (int );


B<vtkInterpolatingSubdivisionFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   long InterpolatePosition (vtkPoints *inputPts, vtkPoints *outputPts, vtkIdList *stencil, float *weights);
      Don't know the size of pointer arg number 4

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::LineSource;


@Graphics::VTK::LineSource::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::LineSource

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float  *GetPoint1 ();
      (Returns a 3-element Perl list)
   float  *GetPoint2 ();
      (Returns a 3-element Perl list)
   int GetResolution ();
   int GetResolutionMaxValue ();
   int GetResolutionMinValue ();
   vtkLineSource *New ();
   void SetPoint1 (float , float , float );
   void SetPoint2 (float , float , float );
   void SetResolution (int );


B<vtkLineSource Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetPoint1 (float  a[3]);
      Method is redundant. Same as SetPoint1( float, float, float)

   void SetPoint2 (float  a[3]);
      Method is redundant. Same as SetPoint2( float, float, float)


=cut

package Graphics::VTK::LinearExtrusionFilter;


@Graphics::VTK::LinearExtrusionFilter::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::LinearExtrusionFilter

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CappingOff ();
   void CappingOn ();
   int GetCapping ();
   const char *GetClassName ();
   float  *GetExtrusionPoint ();
      (Returns a 3-element Perl list)
   int GetExtrusionType ();
   int GetExtrusionTypeMaxValue ();
   int GetExtrusionTypeMinValue ();
   float GetScaleFactor ();
   float  *GetVector ();
      (Returns a 3-element Perl list)
   vtkLinearExtrusionFilter *New ();
   void SetCapping (int );
   void SetExtrusionPoint (float , float , float );
   void SetExtrusionType (int );
   void SetExtrusionTypeToNormalExtrusion ();
   void SetExtrusionTypeToPointExtrusion ();
   void SetExtrusionTypeToVectorExtrusion ();
   void SetScaleFactor (float );
   void SetVector (float , float , float );


B<vtkLinearExtrusionFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetExtrusionPoint (float  a[3]);
      Method is redundant. Same as SetExtrusionPoint( float, float, float)

   void SetVector (float  a[3]);
      Method is redundant. Same as SetVector( float, float, float)


=cut

package Graphics::VTK::LinearSubdivisionFilter;


@Graphics::VTK::LinearSubdivisionFilter::ISA = qw( Graphics::VTK::InterpolatingSubdivisionFilter );

=head1 Graphics::VTK::LinearSubdivisionFilter

=over 1

=item *

Inherits from InterpolatingSubdivisionFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkLinearSubdivisionFilter *New ();

=cut

package Graphics::VTK::LinkEdgels;


@Graphics::VTK::LinkEdgels::ISA = qw( Graphics::VTK::StructuredPointsToPolyDataFilter );

=head1 Graphics::VTK::LinkEdgels

=over 1

=item *

Inherits from StructuredPointsToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetGradientThreshold ();
   float GetLinkThreshold ();
   float GetPhiThreshold ();
   vtkLinkEdgels *New ();
   void SetGradientThreshold (float );
   void SetLinkThreshold (float );
   void SetPhiThreshold (float );


B<vtkLinkEdgels Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void LinkEdgels (int xdim, int ydim, float *image, vtkDataArray *inVectors, vtkCellArray *newLines, vtkPoints *newPts, vtkFloatArray *outScalars, vtkFloatArray *outVectors, int z);
      Don't know the size of pointer arg number 3

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::LoopSubdivisionFilter;


@Graphics::VTK::LoopSubdivisionFilter::ISA = qw( Graphics::VTK::ApproximatingSubdivisionFilter );

=head1 Graphics::VTK::LoopSubdivisionFilter

=over 1

=item *

Inherits from ApproximatingSubdivisionFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkLoopSubdivisionFilter *New ();


B<vtkLoopSubdivisionFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void GenerateEvenStencil (long p1, vtkPolyData *polys, vtkIdList *stencilIds, float *weights);
      Don't know the size of pointer arg number 4

   void GenerateOddStencil (long p1, long p2, vtkPolyData *polys, vtkIdList *stencilIds, float *weights);
      Don't know the size of pointer arg number 5


=cut

package Graphics::VTK::MaskPoints;


@Graphics::VTK::MaskPoints::ISA = qw( Graphics::VTK::DataSetToPolyDataFilter );

=head1 Graphics::VTK::MaskPoints

=over 1

=item *

Inherits from DataSetToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void GenerateVerticesOff ();
   void GenerateVerticesOn ();
   const char *GetClassName ();
   int GetGenerateVertices ();
   long GetMaximumNumberOfPoints ();
   long GetMaximumNumberOfPointsMaxValue ();
   long GetMaximumNumberOfPointsMinValue ();
   long GetOffset ();
   long GetOffsetMaxValue ();
   long GetOffsetMinValue ();
   int GetOnRatio ();
   int GetOnRatioMaxValue ();
   int GetOnRatioMinValue ();
   int GetRandomMode ();
   vtkMaskPoints *New ();
   void RandomModeOff ();
   void RandomModeOn ();
   void SetGenerateVertices (int );
   void SetMaximumNumberOfPoints (long );
   void SetOffset (long );
   void SetOnRatio (int );
   void SetRandomMode (int );


B<vtkMaskPoints Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::MaskPolyData;


@Graphics::VTK::MaskPolyData::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::MaskPolyData

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   long GetOffset ();
   long GetOffsetMaxValue ();
   long GetOffsetMinValue ();
   int GetOnRatio ();
   int GetOnRatioMaxValue ();
   int GetOnRatioMinValue ();
   vtkMaskPolyData *New ();
   void SetOffset (long );
   void SetOnRatio (int );


B<vtkMaskPolyData Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::MassProperties;


@Graphics::VTK::MassProperties::ISA = qw( Graphics::VTK::ProcessObject );

=head1 Graphics::VTK::MassProperties

=over 1

=item *

Inherits from ProcessObject

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkPolyData *GetInput ();
   double GetKx ();
   double GetKy ();
   double GetKz ();
   double GetNormalizedShapeIndex ();
   double GetSurfaceArea ();
   double GetVolume ();
   double GetVolumeX ();
   double GetVolumeY ();
   double GetVolumeZ ();
   vtkMassProperties *New ();
   void SetInput (vtkPolyData *input);
   void Update ();


B<vtkMassProperties Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::MergeDataObjectFilter;


@Graphics::VTK::MergeDataObjectFilter::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::MergeDataObjectFilter

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkDataObject *GetDataObject ();
   int GetOutputField ();
   vtkMergeDataObjectFilter *New ();
   void SetDataObject (vtkDataObject *object);
   void SetOutputField (int );
   void SetOutputFieldToCellDataField ();
   void SetOutputFieldToDataObjectField ();
   void SetOutputFieldToPointDataField ();


B<vtkMergeDataObjectFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::MergeFields;


@Graphics::VTK::MergeFields::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::MergeFields

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   void Merge (int component, const char *arrayName, int sourceComp);
   vtkMergeFields *New ();
   void SetNumberOfComponents (int );
   void SetOutputField (const char *name, const char *fieldLoc);
   void SetOutputField (const char *name, int fieldLoc);


B<vtkMergeFields Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void AddComponent (Component *op);
      Don't know the size of pointer arg number 1

   Component *GetNextComponent (Component *op);
      Don't know the size of pointer arg number 1

   void PrintComponent (Component *op, ostream &os, vtkIndent indent);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::MergeFilter;


@Graphics::VTK::MergeFilter::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::MergeFilter

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddField (const char *name, vtkDataSet *input);
   const char *GetClassName ();
   vtkDataSet *GetGeometry ();
   vtkDataSet *GetNormals ();
   vtkDataSet *GetScalars ();
   vtkDataSet *GetTCoords ();
   vtkDataSet *GetTensors ();
   vtkDataSet *GetVectors ();
   vtkMergeFilter *New ();
   void SetGeometry (vtkDataSet *input);
   void SetNormals (vtkDataSet *);
   void SetScalars (vtkDataSet *);
   void SetTCoords (vtkDataSet *);
   void SetTensors (vtkDataSet *);
   void SetVectors (vtkDataSet *);


B<vtkMergeFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::OBBDicer;


@Graphics::VTK::OBBDicer::ISA = qw( Graphics::VTK::Dicer );

=head1 Graphics::VTK::OBBDicer

=over 1

=item *

Inherits from Dicer

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkOBBDicer *New ();


B<vtkOBBDicer Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::OBBTree;


@Graphics::VTK::OBBTree::ISA = qw( Graphics::VTK::CellLocator );

=head1 Graphics::VTK::OBBTree

=over 1

=item *

Inherits from CellLocator

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void BuildLocator ();
   void FreeSearchStructure ();
   void GenerateRepresentation (int level, vtkPolyData *pd);
   const char *GetClassName ();
   vtkOBBTree *New ();


B<vtkOBBTree Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeOBB (vtkPoints *pts, float corner[3], float max[3], float mid[3], float min[3], float size[3]);
      Don't know the size of pointer arg number 2

   void ComputeOBB (vtkDataSet *input, float corner[3], float max[3], float mid[3], float min[3], float size[3]);
      Don't know the size of pointer arg number 2

   int InsideOrOutside (const float point[3]);
      Can't handle methods with single array args (like a[3]) yet.

   int IntersectWithLine (const float a0[3], const float a1[3], vtkPoints *points, vtkIdList *cellIds);
      Don't know the size of pointer arg number 1

   int IntersectWithLine (float a0[3], float a1[3], float tol, float &t, float x[3], float pcoords[3], int &subId);
      Don't know the size of pointer arg number 1

   int IntersectWithLine (float a0[3], float a1[3], float tol, float &t, float x[3], float pcoords[3], int &subId, long &cellId);
      Don't know the size of pointer arg number 1

   int IntersectWithLine (float a0[3], float a1[3], float tol, float &t, float x[3], float pcoords[3], int &subId, long &cellId, vtkGenericCell *cell);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::OutlineCornerFilter;


@Graphics::VTK::OutlineCornerFilter::ISA = qw( Graphics::VTK::DataSetToPolyDataFilter );

=head1 Graphics::VTK::OutlineCornerFilter

=over 1

=item *

Inherits from DataSetToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetCornerFactor ();
   float GetCornerFactorMaxValue ();
   float GetCornerFactorMinValue ();
   vtkOutlineCornerFilter *New ();
   void SetCornerFactor (float );


B<vtkOutlineCornerFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::OutlineCornerSource;


@Graphics::VTK::OutlineCornerSource::ISA = qw( Graphics::VTK::OutlineSource );

=head1 Graphics::VTK::OutlineCornerSource

=over 1

=item *

Inherits from OutlineSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetCornerFactor ();
   float GetCornerFactorMaxValue ();
   float GetCornerFactorMinValue ();
   vtkOutlineCornerSource *New ();
   void SetCornerFactor (float );


B<vtkOutlineCornerSource Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::OutlineFilter;


@Graphics::VTK::OutlineFilter::ISA = qw( Graphics::VTK::DataSetToPolyDataFilter );

=head1 Graphics::VTK::OutlineFilter

=over 1

=item *

Inherits from DataSetToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkOutlineFilter *New ();

=cut

package Graphics::VTK::OutlineSource;


@Graphics::VTK::OutlineSource::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::OutlineSource

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   float  *GetBounds ();
      (Returns a 6-element Perl list)
   const char *GetClassName ();
   vtkOutlineSource *New ();
   void SetBounds (float , float , float , float , float , float );


B<vtkOutlineSource Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetBounds (float  a[6]);
      Method is redundant. Same as SetBounds( float, float, float, float, float, float)


=cut

package Graphics::VTK::PlaneSource;


@Graphics::VTK::PlaneSource::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::PlaneSource

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   float  *GetCenter ();
      (Returns a 3-element Perl list)
   const char *GetClassName ();
   float  *GetNormal ();
      (Returns a 3-element Perl list)
   float  *GetOrigin ();
      (Returns a 3-element Perl list)
   float  *GetPoint1 ();
      (Returns a 3-element Perl list)
   float  *GetPoint2 ();
      (Returns a 3-element Perl list)
   void GetResolution (int &xR, int &yR);
   int GetXResolution ();
   int GetYResolution ();
   vtkPlaneSource *New ();
   void Push (float distance);
   void SetCenter (float x, float y, float z);
   void SetNormal (float nx, float ny, float nz);
   void SetOrigin (float , float , float );
   void SetPoint1 (float x, float y, float z);
   void SetPoint2 (float x, float y, float z);
   void SetResolution (const int xR, const int yR);
   void SetXResolution (int );
   void SetYResolution (int );


B<vtkPlaneSource Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetCenter (float center[3]);
      Method is redundant. Same as SetCenter( float, float, float)

   void SetNormal (float n[3]);
      Method is redundant. Same as SetNormal( float, float, float)

   void SetOrigin (float  a[3]);
      Method is redundant. Same as SetOrigin( float, float, float)

   void SetPoint1 (float pnt[3]);
      Method is redundant. Same as SetPoint1( float, float, float)

   void SetPoint2 (float pnt[3]);
      Method is redundant. Same as SetPoint2( float, float, float)

   int UpdatePlane (float v1[3], float v2[3]);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::PointDataToCellData;


@Graphics::VTK::PointDataToCellData::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::PointDataToCellData

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetPassPointData ();
   vtkPointDataToCellData *New ();
   void PassPointDataOff ();
   void PassPointDataOn ();
   void SetPassPointData (int );


B<vtkPointDataToCellData Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::PointSource;


@Graphics::VTK::PointSource::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::PointSource

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   float  *GetCenter ();
      (Returns a 3-element Perl list)
   const char *GetClassName ();
   int GetDistribution ();
   long GetNumberOfPoints ();
   long GetNumberOfPointsMaxValue ();
   long GetNumberOfPointsMinValue ();
   float GetRadius ();
   float GetRadiusMaxValue ();
   float GetRadiusMinValue ();
   vtkPointSource *New ();
   void SetCenter (float , float , float );
   void SetDistribution (int );
   void SetDistributionToShell ();
   void SetDistributionToUniform ();
   void SetNumberOfPoints (long );
   void SetRadius (float );


B<vtkPointSource Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetCenter (float  a[3]);
      Method is redundant. Same as SetCenter( float, float, float)


=cut

package Graphics::VTK::PolyDataConnectivityFilter;


@Graphics::VTK::PolyDataConnectivityFilter::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::PolyDataConnectivityFilter

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddSeed (int id);
   void AddSpecifiedRegion (int id);
   void ColorRegionsOff ();
   void ColorRegionsOn ();
   void DeleteSeed (int id);
   void DeleteSpecifiedRegion (int id);
   const char *GetClassName ();
   float  *GetClosestPoint ();
      (Returns a 3-element Perl list)
   int GetColorRegions ();
   int GetExtractionMode ();
   const char *GetExtractionModeAsString ();
   int GetExtractionModeMaxValue ();
   int GetExtractionModeMinValue ();
   int GetNumberOfExtractedRegions ();
   int GetScalarConnectivity ();
   float  *GetScalarRange ();
      (Returns a 2-element Perl list)
   void InitializeSeedList ();
   void InitializeSpecifiedRegionList ();
   vtkPolyDataConnectivityFilter *New ();
   void ScalarConnectivityOff ();
   void ScalarConnectivityOn ();
   void SetClosestPoint (float , float , float );
   void SetColorRegions (int );
   void SetExtractionMode (int );
   void SetExtractionModeToAllRegions ();
   void SetExtractionModeToCellSeededRegions ();
   void SetExtractionModeToClosestPointRegion ();
   void SetExtractionModeToLargestRegion ();
   void SetExtractionModeToPointSeededRegions ();
   void SetExtractionModeToSpecifiedRegions ();
   void SetScalarConnectivity (int );


B<vtkPolyDataConnectivityFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetClosestPoint (float  a[3]);
      Method is redundant. Same as SetClosestPoint( float, float, float)

   void SetScalarRange (float  [2]);
      Can't handle methods with single array args (like a[3]) yet.


=cut

package Graphics::VTK::PolyDataNormals;


@Graphics::VTK::PolyDataNormals::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::PolyDataNormals

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void ComputeCellNormalsOff ();
   void ComputeCellNormalsOn ();
   void ComputePointNormalsOff ();
   void ComputePointNormalsOn ();
   void ConsistencyOff ();
   void ConsistencyOn ();
   void FlipNormalsOff ();
   void FlipNormalsOn ();
   const char *GetClassName ();
   int GetComputeCellNormals ();
   int GetComputePointNormals ();
   int GetConsistency ();
   float GetFeatureAngle ();
   float GetFeatureAngleMaxValue ();
   float GetFeatureAngleMinValue ();
   int GetFlipNormals ();
   int GetMaxRecursionDepth ();
   int GetNonManifoldTraversal ();
   int GetSplitting ();
   vtkPolyDataNormals *New ();
   void NonManifoldTraversalOff ();
   void NonManifoldTraversalOn ();
   void SetComputeCellNormals (int );
   void SetComputePointNormals (int );
   void SetConsistency (int );
   void SetFeatureAngle (float );
   void SetFlipNormals (int );
   void SetNonManifoldTraversal (int );
   void SetSplitting (int );
   void SplittingOff ();
   void SplittingOn ();


B<vtkPolyDataNormals Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetMaxRecursionDepth (int );
      Method is marked 'Do Not Use' in its descriptions


=cut

package Graphics::VTK::PolyDataStreamer;


@Graphics::VTK::PolyDataStreamer::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::PolyDataStreamer

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void ColorByPieceOff ();
   void ColorByPieceOn ();
   const char *GetClassName ();
   int GetColorByPiece ();
   int GetNumberOfStreamDivisions ();
   vtkPolyDataStreamer *New ();
   void SetColorByPiece (int );
   void SetNumberOfStreamDivisions (int num);


B<vtkPolyDataStreamer Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ProbeFilter;


@Graphics::VTK::ProbeFilter::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::ProbeFilter

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkDataSet *GetSource ();
   int GetSpatialMatch ();
   vtkIdTypeArray *GetValidPoints ();
   vtkProbeFilter *New ();
   void SetSource (vtkDataSet *source);
   void SetSpatialMatch (int );
   void SpatialMatchOff ();
   void SpatialMatchOn ();


B<vtkProbeFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ProgrammableAttributeDataFilter;


@Graphics::VTK::ProgrammableAttributeDataFilter::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::ProgrammableAttributeDataFilter

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddInput (vtkDataSet *in);
   const char *GetClassName ();
   vtkDataSetCollection *GetInputList ();
   vtkProgrammableAttributeDataFilter *New ();
   void RemoveInput (vtkDataSet *in);
   void SetExecuteMethod (void (*func)(void *) , void *arg);


B<vtkProgrammableAttributeDataFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetExecuteMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.


=cut

package Graphics::VTK::ProgrammableDataObjectSource;


@Graphics::VTK::ProgrammableDataObjectSource::ISA = qw( Graphics::VTK::Source );

=head1 Graphics::VTK::ProgrammableDataObjectSource

=over 1

=item *

Inherits from Source

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkDataObject *GetOutput (int idx);
   vtkDataObject *GetOutput ();
   vtkProgrammableDataObjectSource *New ();
   void SetExecuteMethod (void (*func)(void *) , void *arg);


B<vtkProgrammableDataObjectSource Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetExecuteMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.


=cut

package Graphics::VTK::ProgrammableFilter;


@Graphics::VTK::ProgrammableFilter::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::ProgrammableFilter

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkPolyData *GetPolyDataInput ();
   vtkRectilinearGrid *GetRectilinearGridInput ();
   vtkStructuredGrid *GetStructuredGridInput ();
   vtkStructuredPoints *GetStructuredPointsInput ();
   vtkUnstructuredGrid *GetUnstructuredGridInput ();
   vtkProgrammableFilter *New ();
   void SetExecuteMethod (void (*func)(void *) , void *arg);


B<vtkProgrammableFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void SetExecuteMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.


=cut

package Graphics::VTK::ProgrammableGlyphFilter;


@Graphics::VTK::ProgrammableGlyphFilter::ISA = qw( Graphics::VTK::DataSetToPolyDataFilter );

=head1 Graphics::VTK::ProgrammableGlyphFilter

=over 1

=item *

Inherits from DataSetToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetColorMode ();
   const char *GetColorModeAsString ();
   float  *GetPoint ();
      (Returns a 3-element Perl list)
   vtkPointData *GetPointData ();
   long GetPointId ();
   vtkPolyData *GetSource ();
   vtkProgrammableGlyphFilter *New ();
   void SetColorMode (int );
   void SetColorModeToColorByInput ();
   void SetColorModeToColorBySource ();
   void SetGlyphMethod (void (*func)(void *) , void *arg);
   void SetSource (vtkPolyData *source);


B<vtkProgrammableGlyphFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetGlyphMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.


=cut

package Graphics::VTK::ProgrammableSource;


@Graphics::VTK::ProgrammableSource::ISA = qw( Graphics::VTK::Source );

=head1 Graphics::VTK::ProgrammableSource

=over 1

=item *

Inherits from Source

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkPolyData *GetPolyDataOutput ();
   vtkRectilinearGrid *GetRectilinearGridOutput ();
   vtkStructuredGrid *GetStructuredGridOutput ();
   vtkStructuredPoints *GetStructuredPointsOutput ();
   vtkUnstructuredGrid *GetUnstructuredGridOutput ();
   vtkProgrammableSource *New ();
   void SetExecuteMethod (void (*func)(void *) , void *arg);
   void UpdateData (vtkDataObject *output);
   void UpdateInformation ();


B<vtkProgrammableSource Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void SetExecuteMethodArgDelete (void (*func)(void *) );
      No TCL interface is provided by VTK, so we aren't going to provide one either.


=cut

package Graphics::VTK::ProjectedTexture;


@Graphics::VTK::ProjectedTexture::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::ProjectedTexture

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   float  *GetAspectRatio ();
      (Returns a 3-element Perl list)
   const char *GetClassName ();
   float  *GetFocalPoint ();
      (Returns a 3-element Perl list)
   float  *GetOrientation ();
      (Returns a 3-element Perl list)
   float  *GetPosition ();
      (Returns a 3-element Perl list)
   float  *GetSRange ();
      (Returns a 2-element Perl list)
   float  *GetTRange ();
      (Returns a 2-element Perl list)
   float  *GetUp ();
      (Returns a 3-element Perl list)
   vtkProjectedTexture *New ();
   void SetAspectRatio (float , float , float );
   void SetFocalPoint (float x, float y, float z);
   void SetPosition (float , float , float );
   void SetSRange (float , float );
   void SetTRange (float , float );
   void SetUp (float , float , float );


B<vtkProjectedTexture Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetAspectRatio (float  a[3]);
      Method is redundant. Same as SetAspectRatio( float, float, float)

   void SetFocalPoint (float focalPoint[3]);
      Method is redundant. Same as SetFocalPoint( float, float, float)

   void SetPosition (float  a[3]);
      Method is redundant. Same as SetPosition( float, float, float)

   void SetSRange (float  a[2]);
      Method is redundant. Same as SetSRange( float, float)

   void SetTRange (float  a[2]);
      Method is redundant. Same as SetTRange( float, float)

   void SetUp (float  a[3]);
      Method is redundant. Same as SetUp( float, float, float)


=cut

package Graphics::VTK::QuadricClustering;


@Graphics::VTK::QuadricClustering::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::QuadricClustering

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void Append (vtkPolyData *piece);
   void CopyCellDataOff ();
   void CopyCellDataOn ();
   void EndAppend ();
   const char *GetClassName ();
   int GetCopyCellData ();
   float  *GetDivisionOrigin ();
      (Returns a 3-element Perl list)
   float  *GetDivisionSpacing ();
      (Returns a 3-element Perl list)
   vtkFeatureEdges *GetFeatureEdges ();
   float GetFeaturePointsAngle ();
   float GetFeaturePointsAngleMaxValue ();
   float GetFeaturePointsAngleMinValue ();
   int *GetNumberOfDivisions ();
      (Returns a 3-element Perl list)
   int GetNumberOfXDivisions ();
   int GetNumberOfYDivisions ();
   int GetNumberOfZDivisions ();
   int GetUseFeatureEdges ();
   int GetUseFeaturePoints ();
   int GetUseInputPoints ();
   int GetUseInternalTriangles ();
   vtkQuadricClustering *New ();
   void SetCopyCellData (int );
   void SetDivisionOrigin (float x, float y, float z);
   void SetDivisionSpacing (float x, float y, float z);
   void SetFeaturePointsAngle (float );
   void SetNumberOfXDivisions (int num);
   void SetNumberOfYDivisions (int num);
   void SetNumberOfZDivisions (int num);
   void SetUseFeatureEdges (int );
   void SetUseFeaturePoints (int );
   void SetUseInputPoints (int );
   void SetUseInternalTriangles (int );
   void StartAppend (float x0, float x1, float y0, float y1, float z0, float z1);
   void UseFeatureEdgesOff ();
   void UseFeatureEdgesOn ();
   void UseFeaturePointsOff ();
   void UseFeaturePointsOn ();
   void UseInputPointsOff ();
   void UseInputPointsOn ();
   void UseInternalTrianglesOff ();
   void UseInternalTrianglesOn ();


B<vtkQuadricClustering Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void AddEdge (long *binIds, float *pt0, float *pt1, int geometeryFlag);
      Don't know the size of pointer arg number 1

   void AddQuadric (long binId, float quadric[9]);
      Don't know the size of pointer arg number 2

   void AddTriangle (long *binIds, float *pt0, float *pt1, float *pt2, int geometeryFlag);
      Don't know the size of pointer arg number 1

   void AddVertex (long binId, float *pt, int geometryFlag);
      Don't know the size of pointer arg number 2

   void ComputeRepresentativePoint (float quadric[9], long binId, float point[3]);
      Don't know the size of pointer arg number 1

   void GetNumberOfDivisions (int div[3]);
      Can't handle methods with single array args (like a[3]) in overloaded methods yet.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetDivisionOrigin (float o[3]);
      Method is redundant. Same as SetDivisionOrigin( float, float, float)

   void SetDivisionSpacing (float s[3]);
      Method is redundant. Same as SetDivisionSpacing( float, float, float)

   void SetNumberOfDivisions (int div[3]);
      Can't handle methods with single array args (like a[3]) yet.

   void StartAppend (float *bounds);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::QuadricDecimation;


@Graphics::VTK::QuadricDecimation::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::QuadricDecimation

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetMaximumCollapsedEdges ();
   float GetMaximumCost ();
   vtkPolyData *GetTestOutput ();
   vtkQuadricDecimation *New ();
   void SetMaximumCollapsedEdges (int );
   void SetMaximumCost (float );


B<vtkQuadricDecimation Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   float ComputeCost (long edgeId, float x[3], vtkPointData *pd);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::QuantizePolyDataPoints;


@Graphics::VTK::QuantizePolyDataPoints::ISA = qw( Graphics::VTK::CleanPolyData );

=head1 Graphics::VTK::QuantizePolyDataPoints

=over 1

=item *

Inherits from CleanPolyData

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetQFactor ();
   float GetQFactorMaxValue ();
   float GetQFactorMinValue ();
   vtkQuantizePolyDataPoints *New ();
   void SetQFactor (float );


B<vtkQuantizePolyDataPoints Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void OperateOnBounds (float in[6], float out[6]);
      Don't know the size of pointer arg number 1

   virtual void OperateOnPoint (float in[3], float out[3]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::RearrangeFields;


@Graphics::VTK::RearrangeFields::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::RearrangeFields

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int AddOperation (const char *operationType, const char *attributeType, const char *fromFieldLoc, const char *toFieldLoc);
   int AddOperation (int operationType, int attributeType, int fromFieldLoc, int toFieldLoc);
   const char *GetClassName ();
   vtkRearrangeFields *New ();
   void RemoveAllOperations ();
   int RemoveOperation (const char *operationType, const char *attributeType, const char *fromFieldLoc, const char *toFieldLoc);
   int RemoveOperation (int operationType, int attributeType, int fromFieldLoc, int toFieldLoc);
   int RemoveOperation (int operationId);


B<vtkRearrangeFields Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int AddOperation (int operationType, const char *name, int fromFieldLoc, int toFieldLoc);
      Can't Get Unique Function Signature for this overloaded method

   void AddOperation (Operation *op);
      Don't know the size of pointer arg number 1

   void ApplyOperation (Operation *op, vtkDataSet *input, vtkDataSet *output);
      Don't know the size of pointer arg number 1

   int CompareOperationsByName (const Operation *op1, const Operation *op2);
      Don't know the size of pointer arg number 1

   int CompareOperationsByType (const Operation *op1, const Operation *op2);
      Don't know the size of pointer arg number 1

   void DeleteOperation (Operation *op, Operation *before);
      Don't know the size of pointer arg number 1

   Operation *GetNextOperation (Operation *op);
      Don't know the size of pointer arg number 1

   void PrintOperation (Operation *op, ostream &os, vtkIndent indent);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   int RemoveOperation (int operationType, const char *name, int fromFieldLoc, int toFieldLoc);
      Can't Get Unique Function Signature for this overloaded method


=cut

package Graphics::VTK::RectilinearGridGeometryFilter;


@Graphics::VTK::RectilinearGridGeometryFilter::ISA = qw( Graphics::VTK::RectilinearGridToPolyDataFilter );

=head1 Graphics::VTK::RectilinearGridGeometryFilter

=over 1

=item *

Inherits from RectilinearGridToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int  *GetExtent ();
      (Returns a 6-element Perl list)
   vtkRectilinearGridGeometryFilter *New ();
   void SetExtent (int iMin, int iMax, int jMin, int jMax, int kMin, int kMax);


B<vtkRectilinearGridGeometryFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetExtent (int extent[6]);
      Method is redundant. Same as SetExtent( int, int, int, int, int, int)


=cut

package Graphics::VTK::RecursiveDividingCubes;


@Graphics::VTK::RecursiveDividingCubes::ISA = qw( Graphics::VTK::StructuredPointsToPolyDataFilter );

=head1 Graphics::VTK::RecursiveDividingCubes

=over 1

=item *

Inherits from StructuredPointsToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetDistance ();
   float GetDistanceMaxValue ();
   float GetDistanceMinValue ();
   int GetIncrement ();
   int GetIncrementMaxValue ();
   int GetIncrementMinValue ();
   float GetValue ();
   vtkRecursiveDividingCubes *New ();
   void SetDistance (float );
   void SetIncrement (int );
   void SetValue (float );


B<vtkRecursiveDividingCubes Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SubDivide (float origin[3], float h[3], float values[8]);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::ReverseSense;


@Graphics::VTK::ReverseSense::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::ReverseSense

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetReverseCells ();
   int GetReverseNormals ();
   vtkReverseSense *New ();
   void ReverseCellsOff ();
   void ReverseCellsOn ();
   void ReverseNormalsOff ();
   void ReverseNormalsOn ();
   void SetReverseCells (int );
   void SetReverseNormals (int );


B<vtkReverseSense Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::RibbonFilter;


@Graphics::VTK::RibbonFilter::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::RibbonFilter

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   float GetAngle ();
   float GetAngleMaxValue ();
   float GetAngleMinValue ();
   const char *GetClassName ();
   float  *GetDefaultNormal ();
      (Returns a 3-element Perl list)
   int GetUseDefaultNormal ();
   int GetVaryWidth ();
   float GetWidth ();
   float GetWidthFactor ();
   float GetWidthMaxValue ();
   float GetWidthMinValue ();
   vtkRibbonFilter *New ();
   void SetAngle (float );
   void SetDefaultNormal (float , float , float );
   void SetUseDefaultNormal (int );
   void SetVaryWidth (int );
   void SetWidth (float );
   void SetWidthFactor (float );
   void UseDefaultNormalOff ();
   void UseDefaultNormalOn ();
   void VaryWidthOff ();
   void VaryWidthOn ();


B<vtkRibbonFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetDefaultNormal (float  a[3]);
      Method is redundant. Same as SetDefaultNormal( float, float, float)


=cut

package Graphics::VTK::RotationalExtrusionFilter;


@Graphics::VTK::RotationalExtrusionFilter::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::RotationalExtrusionFilter

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CappingOff ();
   void CappingOn ();
   float GetAngle ();
   int GetCapping ();
   const char *GetClassName ();
   float GetDeltaRadius ();
   int GetResolution ();
   int GetResolutionMaxValue ();
   int GetResolutionMinValue ();
   float GetTranslation ();
   vtkRotationalExtrusionFilter *New ();
   void SetAngle (float );
   void SetCapping (int );
   void SetDeltaRadius (float );
   void SetResolution (int );
   void SetTranslation (float );


B<vtkRotationalExtrusionFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::RuledSurfaceFilter;


@Graphics::VTK::RuledSurfaceFilter::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::RuledSurfaceFilter

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CloseSurfaceOff ();
   void CloseSurfaceOn ();
   const char *GetClassName ();
   int GetCloseSurface ();
   float GetDistanceFactor ();
   float GetDistanceFactorMaxValue ();
   float GetDistanceFactorMinValue ();
   int GetOffset ();
   int GetOffsetMaxValue ();
   int GetOffsetMinValue ();
   int GetOnRatio ();
   int GetOnRatioMaxValue ();
   int GetOnRatioMinValue ();
   int GetPassLines ();
   int  *GetResolution ();
      (Returns a 2-element Perl list)
   int GetRuledMode ();
   const char *GetRuledModeAsString ();
   int GetRuledModeMaxValue ();
   int GetRuledModeMinValue ();
   vtkRuledSurfaceFilter *New ();
   void PassLinesOff ();
   void PassLinesOn ();
   void SetCloseSurface (int );
   void SetDistanceFactor (float );
   void SetOffset (int );
   void SetOnRatio (int );
   void SetPassLines (int );
   void SetResolution (int , int );
   void SetRuledMode (int );
   void SetRuledModeToPointWalk ();
   void SetRuledModeToResample ();


B<vtkRuledSurfaceFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PointWalk (vtkPolyData *output, vtkPoints *inPts, int npts, long *pts, int npts2, long *pts2);
      Don't know the size of pointer arg number 4

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void Resample (vtkPolyData *output, vtkPoints *inPts, vtkPoints *newPts, int npts, long *pts, int npts2, long *pts2);
      Don't know the size of pointer arg number 5

   void SetResolution (int  a[2]);
      Method is redundant. Same as SetResolution( int, int)


=cut

package Graphics::VTK::SelectPolyData;


@Graphics::VTK::SelectPolyData::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::SelectPolyData

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void GenerateSelectionScalarsOff ();
   void GenerateSelectionScalarsOn ();
   void GenerateUnselectedOutputOff ();
   void GenerateUnselectedOutputOn ();
   const char *GetClassName ();
   int GetGenerateSelectionScalars ();
   int GetGenerateUnselectedOutput ();
   int GetInsideOut ();
   vtkPoints *GetLoop ();
   unsigned long GetMTime ();
   vtkPolyData *GetSelectionEdges ();
   int GetSelectionMode ();
   const char *GetSelectionModeAsString ();
   int GetSelectionModeMaxValue ();
   int GetSelectionModeMinValue ();
   vtkPolyData *GetUnselectedOutput ();
   virtual int InRegisterLoop (vtkObject *);
   void InsideOutOff ();
   void InsideOutOn ();
   vtkSelectPolyData *New ();
   void SetGenerateSelectionScalars (int );
   void SetGenerateUnselectedOutput (int );
   void SetInsideOut (int );
   void SetLoop (vtkPoints *);
   void SetSelectionMode (int );
   void SetSelectionModeToClosestPointRegion ();
   void SetSelectionModeToLargestRegion ();
   void SetSelectionModeToSmallestRegion ();
   void UnRegister (vtkObject *o);


B<vtkSelectPolyData Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ShrinkFilter;


@Graphics::VTK::ShrinkFilter::ISA = qw( Graphics::VTK::DataSetToUnstructuredGridFilter );

=head1 Graphics::VTK::ShrinkFilter

=over 1

=item *

Inherits from DataSetToUnstructuredGridFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetShrinkFactor ();
   float GetShrinkFactorMaxValue ();
   float GetShrinkFactorMinValue ();
   vtkShrinkFilter *New ();
   void SetShrinkFactor (float );


B<vtkShrinkFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ShrinkPolyData;


@Graphics::VTK::ShrinkPolyData::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::ShrinkPolyData

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetShrinkFactor ();
   float GetShrinkFactorMaxValue ();
   float GetShrinkFactorMinValue ();
   vtkShrinkPolyData *New ();
   void SetShrinkFactor (float );


B<vtkShrinkPolyData Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::SimpleElevationFilter;


@Graphics::VTK::SimpleElevationFilter::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::SimpleElevationFilter

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float  *GetVector ();
      (Returns a 3-element Perl list)
   vtkSimpleElevationFilter *New ();
   void SetVector (float , float , float );


B<vtkSimpleElevationFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetVector (float  a[3]);
      Method is redundant. Same as SetVector( float, float, float)


=cut

package Graphics::VTK::SmoothPolyDataFilter;


@Graphics::VTK::SmoothPolyDataFilter::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::SmoothPolyDataFilter

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void BoundarySmoothingOff ();
   void BoundarySmoothingOn ();
   void FeatureEdgeSmoothingOff ();
   void FeatureEdgeSmoothingOn ();
   void GenerateErrorScalarsOff ();
   void GenerateErrorScalarsOn ();
   void GenerateErrorVectorsOff ();
   void GenerateErrorVectorsOn ();
   int GetBoundarySmoothing ();
   const char *GetClassName ();
   float GetConvergence ();
   float GetConvergenceMaxValue ();
   float GetConvergenceMinValue ();
   float GetEdgeAngle ();
   float GetEdgeAngleMaxValue ();
   float GetEdgeAngleMinValue ();
   float GetFeatureAngle ();
   float GetFeatureAngleMaxValue ();
   float GetFeatureAngleMinValue ();
   int GetFeatureEdgeSmoothing ();
   int GetGenerateErrorScalars ();
   int GetGenerateErrorVectors ();
   int GetNumberOfIterations ();
   int GetNumberOfIterationsMaxValue ();
   int GetNumberOfIterationsMinValue ();
   float GetRelaxationFactor ();
   vtkPolyData *GetSource ();
   vtkSmoothPolyDataFilter *New ();
   void SetBoundarySmoothing (int );
   void SetConvergence (float );
   void SetEdgeAngle (float );
   void SetFeatureAngle (float );
   void SetFeatureEdgeSmoothing (int );
   void SetGenerateErrorScalars (int );
   void SetGenerateErrorVectors (int );
   void SetNumberOfIterations (int );
   void SetRelaxationFactor (float );
   void SetSource (vtkPolyData *source);


B<vtkSmoothPolyDataFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::SpatialRepresentationFilter;


@Graphics::VTK::SpatialRepresentationFilter::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::SpatialRepresentationFilter

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkDataSet *GetInput ();
   int GetLevel ();
   vtkPolyData *GetOutput (int level);
   vtkPolyData *GetOutput ();
   vtkLocator *GetSpatialRepresentation ();
   vtkSpatialRepresentationFilter *New ();
   void ResetOutput ();
   virtual void SetInput (vtkDataSet *input);
   void SetSpatialRepresentation (vtkLocator *);


B<vtkSpatialRepresentationFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::SphereSource;


@Graphics::VTK::SphereSource::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::SphereSource

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   float  *GetCenter ();
      (Returns a 3-element Perl list)
   const char *GetClassName ();
   float GetEndPhi ();
   float GetEndPhiMaxValue ();
   float GetEndPhiMinValue ();
   float GetEndTheta ();
   float GetEndThetaMaxValue ();
   float GetEndThetaMinValue ();
   int GetLatLongTessellation ();
   int GetPhiResolution ();
   int GetPhiResolutionMaxValue ();
   int GetPhiResolutionMinValue ();
   float GetRadius ();
   float GetRadiusMaxValue ();
   float GetRadiusMinValue ();
   float GetStartPhi ();
   float GetStartPhiMaxValue ();
   float GetStartPhiMinValue ();
   float GetStartTheta ();
   float GetStartThetaMaxValue ();
   float GetStartThetaMinValue ();
   int GetThetaResolution ();
   int GetThetaResolutionMaxValue ();
   int GetThetaResolutionMinValue ();
   void LatLongTessellationOff ();
   void LatLongTessellationOn ();
   vtkSphereSource *New ();
   void SetCenter (float , float , float );
   void SetEndPhi (float );
   void SetEndTheta (float );
   void SetLatLongTessellation (int );
   void SetPhiResolution (int );
   void SetRadius (float );
   void SetStartPhi (float );
   void SetStartTheta (float );
   void SetThetaResolution (int );


B<vtkSphereSource Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetCenter (float  a[3]);
      Method is redundant. Same as SetCenter( float, float, float)


=cut

package Graphics::VTK::SplitField;


@Graphics::VTK::SplitField::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::SplitField

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkSplitField *New ();
   void SetInputField (const char *name, const char *fieldLoc);
   void SetInputField (int attributeType, int fieldLoc);
   void Split (int component, const char *arrayName);


B<vtkSplitField Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void AddComponent (Component *op);
      Don't know the size of pointer arg number 1

   Component *GetNextComponent (Component *op);
      Don't know the size of pointer arg number 1

   void PrintComponent (Component *op, ostream &os, vtkIndent indent);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetInputField (const char *name, int fieldLoc);
      Can't Get Unique Function Signature for this overloaded method


=cut

package Graphics::VTK::StreamLine;


@Graphics::VTK::StreamLine::ISA = qw( Graphics::VTK::Streamer );

=head1 Graphics::VTK::StreamLine

=over 1

=item *

Inherits from Streamer

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetStepLength ();
   float GetStepLengthMaxValue ();
   float GetStepLengthMinValue ();
   vtkStreamLine *New ();
   void SetStepLength (float );


B<vtkStreamLine Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::StreamPoints;


@Graphics::VTK::StreamPoints::ISA = qw( Graphics::VTK::Streamer );

=head1 Graphics::VTK::StreamPoints

=over 1

=item *

Inherits from Streamer

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetTimeIncrement ();
   float GetTimeIncrementMaxValue ();
   float GetTimeIncrementMinValue ();
   vtkStreamPoints *New ();
   void SetTimeIncrement (float );


B<vtkStreamPoints Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::Streamer;


@Graphics::VTK::Streamer::ISA = qw( Graphics::VTK::DataSetToPolyDataFilter );

=head1 Graphics::VTK::Streamer

=over 1

=item *

Inherits from DataSetToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetIntegrationDirection ();
   const char *GetIntegrationDirectionAsString ();
   int GetIntegrationDirectionMaxValue ();
   int GetIntegrationDirectionMinValue ();
   float GetIntegrationStepLength ();
   float GetIntegrationStepLengthMaxValue ();
   float GetIntegrationStepLengthMinValue ();
   vtkInitialValueProblemSolver *GetIntegrator ();
   float GetMaximumPropagationTime ();
   float GetMaximumPropagationTimeMaxValue ();
   float GetMaximumPropagationTimeMinValue ();
   int GetNumberOfThreads ();
   int GetOrientationScalars ();
   float GetSavePointInterval ();
   vtkDataSet *GetSource ();
   int GetSpeedScalars ();
   float *GetStartPosition ();
      (Returns a 3-element Perl list)
   float GetTerminalSpeed ();
   float GetTerminalSpeedMaxValue ();
   float GetTerminalSpeedMinValue ();
   int GetVorticity ();
   vtkStreamer *New ();
   void OrientationScalarsOff ();
   void OrientationScalarsOn ();
   void SetIntegrationDirection (int );
   void SetIntegrationDirectionToBackward ();
   void SetIntegrationDirectionToForward ();
   void SetIntegrationDirectionToIntegrateBothDirections ();
   void SetIntegrationStepLength (float );
   void SetIntegrator (vtkInitialValueProblemSolver *);
   void SetMaximumPropagationTime (float );
   void SetNumberOfThreads (int );
   void SetOrientationScalars (int );
   void SetSavePointInterval (float );
   void SetSource (vtkDataSet *source);
   void SetSpeedScalars (int );
   void SetStartLocation (long cellId, int subId, float r, float s, float t);
   void SetStartPosition (float x, float y, float z);
   void SetTerminalSpeed (float );
   void SetVorticity (int );
   void SpeedScalarsOff ();
   void SpeedScalarsOn ();
   void VorticityOff ();
   void VorticityOn ();


B<vtkStreamer Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   long GetStartLocation (int &subId, float pcoords[3]);
      Don't know the size of pointer arg number 2

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetStartLocation (long cellId, int subId, float pcoords[3]);
      Don't know the size of pointer arg number 3

   void SetStartPosition (float x[3]);
      Method is redundant. Same as SetStartPosition( float, float, float)

   static VTK_THREAD_RETURN_TYPE ThreadedIntegrate (void *arg);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::Stripper;


@Graphics::VTK::Stripper::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::Stripper

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetMaximumLength ();
   int GetMaximumLengthMaxValue ();
   int GetMaximumLengthMinValue ();
   vtkStripper *New ();
   void SetMaximumLength (int );


B<vtkStripper Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::StructuredGridGeometryFilter;


@Graphics::VTK::StructuredGridGeometryFilter::ISA = qw( Graphics::VTK::StructuredGridToPolyDataFilter );

=head1 Graphics::VTK::StructuredGridGeometryFilter

=over 1

=item *

Inherits from StructuredGridToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int  *GetExtent ();
      (Returns a 6-element Perl list)
   vtkStructuredGridGeometryFilter *New ();
   void SetExtent (int iMin, int iMax, int jMin, int jMax, int kMin, int kMax);


B<vtkStructuredGridGeometryFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetExtent (int extent[6]);
      Method is redundant. Same as SetExtent( int, int, int, int, int, int)


=cut

package Graphics::VTK::StructuredGridOutlineFilter;


@Graphics::VTK::StructuredGridOutlineFilter::ISA = qw( Graphics::VTK::StructuredGridToPolyDataFilter );

=head1 Graphics::VTK::StructuredGridOutlineFilter

=over 1

=item *

Inherits from StructuredGridToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkStructuredGridOutlineFilter *New ();

=cut

package Graphics::VTK::StructuredPointsGeometryFilter;


@Graphics::VTK::StructuredPointsGeometryFilter::ISA = qw( Graphics::VTK::ImageDataGeometryFilter );

=head1 Graphics::VTK::StructuredPointsGeometryFilter

=over 1

=item *

Inherits from ImageDataGeometryFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkStructuredPointsGeometryFilter *New ();

=cut

package Graphics::VTK::SubPixelPositionEdgels;


@Graphics::VTK::SubPixelPositionEdgels::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::SubPixelPositionEdgels

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkStructuredPoints *GetGradMaps ();
   int GetTargetFlag ();
   float GetTargetValue ();
   vtkSubPixelPositionEdgels *New ();
   void SetGradMaps (vtkStructuredPoints *gm);
   void SetTargetFlag (int );
   void SetTargetValue (float );
   void TargetFlagOff ();
   void TargetFlagOn ();


B<vtkSubPixelPositionEdgels Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void Move (int xdim, int ydim, int zdim, int x, int y, float *img, vtkDataArray *inVecs, float *result, int z, float *aspect, float *resultNormal);
      Don't know the size of pointer arg number 6

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::SubdivideTetra;


@Graphics::VTK::SubdivideTetra::ISA = qw( Graphics::VTK::UnstructuredGridToUnstructuredGridFilter );

=head1 Graphics::VTK::SubdivideTetra

=over 1

=item *

Inherits from UnstructuredGridToUnstructuredGridFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkSubdivideTetra *New ();


B<vtkSubdivideTetra Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::SuperquadricSource;


@Graphics::VTK::SuperquadricSource::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::SuperquadricSource

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   float  *GetCenter ();
      (Returns a 3-element Perl list)
   const char *GetClassName ();
   int GetPhiResolution ();
   float GetPhiRoundness ();
   float  *GetScale ();
      (Returns a 3-element Perl list)
   float GetSize ();
   int GetThetaResolution ();
   float GetThetaRoundness ();
   float GetThickness ();
   float GetThicknessMaxValue ();
   float GetThicknessMinValue ();
   int GetToroidal ();
   vtkSuperquadricSource *New ();
   void SetCenter (float , float , float );
   void SetPhiResolution (int i);
   void SetPhiRoundness (float e);
   void SetScale (float , float , float );
   void SetSize (float );
   void SetThetaResolution (int i);
   void SetThetaRoundness (float e);
   void SetThickness (float );
   void SetToroidal (int );
   void ToroidalOff ();
   void ToroidalOn ();


B<vtkSuperquadricSource Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetCenter (float  a[3]);
      Method is redundant. Same as SetCenter( float, float, float)

   void SetScale (float  a[3]);
      Method is redundant. Same as SetScale( float, float, float)


=cut

package Graphics::VTK::TensorGlyph;


@Graphics::VTK::TensorGlyph::ISA = qw( Graphics::VTK::DataSetToPolyDataFilter );

=head1 Graphics::VTK::TensorGlyph

=over 1

=item *

Inherits from DataSetToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void ClampScalingOff ();
   void ClampScalingOn ();
   void ColorGlyphsOff ();
   void ColorGlyphsOn ();
   void ExtractEigenvaluesOff ();
   void ExtractEigenvaluesOn ();
   int GetClampScaling ();
   const char *GetClassName ();
   int GetColorGlyphs ();
   int GetExtractEigenvalues ();
   float GetMaxScaleFactor ();
   float GetScaleFactor ();
   int GetScaling ();
   vtkPolyData *GetSource ();
   vtkTensorGlyph *New ();
   void ScalingOff ();
   void ScalingOn ();
   void SetClampScaling (int );
   void SetColorGlyphs (int );
   void SetExtractEigenvalues (int );
   void SetMaxScaleFactor (float );
   void SetScaleFactor (float );
   void SetScaling (int );
   void SetSource (vtkPolyData *source);


B<vtkTensorGlyph Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::TextSource;


@Graphics::VTK::TextSource::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::TextSource

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void BackingOff ();
   void BackingOn ();
   float  *GetBackgroundColor ();
      (Returns a 3-element Perl list)
   int GetBacking ();
   const char *GetClassName ();
   float  *GetForegroundColor ();
      (Returns a 3-element Perl list)
   char *GetText ();
   vtkTextSource *New ();
   void SetBackgroundColor (float , float , float );
   void SetBacking (int );
   void SetForegroundColor (float , float , float );
   void SetText (char *);


B<vtkTextSource Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetBackgroundColor (float  a[3]);
      Method is redundant. Same as SetBackgroundColor( float, float, float)

   void SetForegroundColor (float  a[3]);
      Method is redundant. Same as SetForegroundColor( float, float, float)


=cut

package Graphics::VTK::TextureMapToCylinder;


@Graphics::VTK::TextureMapToCylinder::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::TextureMapToCylinder

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AutomaticCylinderGenerationOff ();
   void AutomaticCylinderGenerationOn ();
   int GetAutomaticCylinderGeneration ();
   const char *GetClassName ();
   float  *GetPoint1 ();
      (Returns a 3-element Perl list)
   float  *GetPoint2 ();
      (Returns a 3-element Perl list)
   int GetPreventSeam ();
   vtkTextureMapToCylinder *New ();
   void PreventSeamOff ();
   void PreventSeamOn ();
   void SetAutomaticCylinderGeneration (int );
   void SetPoint1 (float , float , float );
   void SetPoint2 (float , float , float );
   void SetPreventSeam (int );


B<vtkTextureMapToCylinder Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetPoint1 (float  a[3]);
      Method is redundant. Same as SetPoint1( float, float, float)

   void SetPoint2 (float  a[3]);
      Method is redundant. Same as SetPoint2( float, float, float)


=cut

package Graphics::VTK::TextureMapToPlane;


@Graphics::VTK::TextureMapToPlane::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::TextureMapToPlane

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AutomaticPlaneGenerationOff ();
   void AutomaticPlaneGenerationOn ();
   int GetAutomaticPlaneGeneration ();
   const char *GetClassName ();
   float  *GetNormal ();
      (Returns a 3-element Perl list)
   float  *GetOrigin ();
      (Returns a 3-element Perl list)
   float  *GetPoint1 ();
      (Returns a 3-element Perl list)
   float  *GetPoint2 ();
      (Returns a 3-element Perl list)
   float  *GetSRange ();
      (Returns a 2-element Perl list)
   float  *GetTRange ();
      (Returns a 2-element Perl list)
   vtkTextureMapToPlane *New ();
   void SetAutomaticPlaneGeneration (int );
   void SetNormal (float , float , float );
   void SetOrigin (float , float , float );
   void SetPoint1 (float , float , float );
   void SetPoint2 (float , float , float );
   void SetSRange (float , float );
   void SetTRange (float , float );


B<vtkTextureMapToPlane Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetNormal (float  a[3]);
      Method is redundant. Same as SetNormal( float, float, float)

   void SetOrigin (float  a[3]);
      Method is redundant. Same as SetOrigin( float, float, float)

   void SetPoint1 (float  a[3]);
      Method is redundant. Same as SetPoint1( float, float, float)

   void SetPoint2 (float  a[3]);
      Method is redundant. Same as SetPoint2( float, float, float)

   void SetSRange (float  a[2]);
      Method is redundant. Same as SetSRange( float, float)

   void SetTRange (float  a[2]);
      Method is redundant. Same as SetTRange( float, float)


=cut

package Graphics::VTK::TextureMapToSphere;


@Graphics::VTK::TextureMapToSphere::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::TextureMapToSphere

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AutomaticSphereGenerationOff ();
   void AutomaticSphereGenerationOn ();
   int GetAutomaticSphereGeneration ();
   float  *GetCenter ();
      (Returns a 3-element Perl list)
   const char *GetClassName ();
   int GetPreventSeam ();
   vtkTextureMapToSphere *New ();
   void PreventSeamOff ();
   void PreventSeamOn ();
   void SetAutomaticSphereGeneration (int );
   void SetCenter (float , float , float );
   void SetPreventSeam (int );


B<vtkTextureMapToSphere Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetCenter (float  a[3]);
      Method is redundant. Same as SetCenter( float, float, float)


=cut

package Graphics::VTK::TexturedSphereSource;


@Graphics::VTK::TexturedSphereSource::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::TexturedSphereSource

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetPhi ();
   float GetPhiMaxValue ();
   float GetPhiMinValue ();
   int GetPhiResolution ();
   int GetPhiResolutionMaxValue ();
   int GetPhiResolutionMinValue ();
   float GetRadius ();
   float GetRadiusMaxValue ();
   float GetRadiusMinValue ();
   float GetTheta ();
   float GetThetaMaxValue ();
   float GetThetaMinValue ();
   int GetThetaResolution ();
   int GetThetaResolutionMaxValue ();
   int GetThetaResolutionMinValue ();
   vtkTexturedSphereSource *New ();
   void SetPhi (float );
   void SetPhiResolution (int );
   void SetRadius (float );
   void SetTheta (float );
   void SetThetaResolution (int );


B<vtkTexturedSphereSource Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::Threshold;


@Graphics::VTK::Threshold::ISA = qw( Graphics::VTK::DataSetToUnstructuredGridFilter );

=head1 Graphics::VTK::Threshold

=over 1

=item *

Inherits from DataSetToUnstructuredGridFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AllScalarsOff ();
   void AllScalarsOn ();
   int GetAllScalars ();
   char *GetArrayName ();
   int GetAttributeMode ();
   const char *GetAttributeModeAsString ();
   const char *GetClassName ();
   float GetLowerThreshold ();
   float GetUpperThreshold ();
   vtkThreshold *New ();
   void SetAllScalars (int );
   void SetArrayName (char *);
   void SetAttributeMode (int );
   void SetAttributeModeToDefault ();
   void SetAttributeModeToUseCellData ();
   void SetAttributeModeToUsePointData ();
   void ThresholdBetween (float lower, float upper);
   void ThresholdByLower (float lower);
   void ThresholdByUpper (float upper);


B<vtkThreshold Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ThresholdPoints;


@Graphics::VTK::ThresholdPoints::ISA = qw( Graphics::VTK::DataSetToPolyDataFilter );

=head1 Graphics::VTK::ThresholdPoints

=over 1

=item *

Inherits from DataSetToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetLowerThreshold ();
   float GetUpperThreshold ();
   vtkThresholdPoints *New ();
   void ThresholdBetween (float lower, float upper);
   void ThresholdByLower (float lower);
   void ThresholdByUpper (float upper);


B<vtkThresholdPoints Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::ThresholdTextureCoords;


@Graphics::VTK::ThresholdTextureCoords::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::ThresholdTextureCoords

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float  *GetInTextureCoord ();
      (Returns a 3-element Perl list)
   float GetLowerThreshold ();
   float  *GetOutTextureCoord ();
      (Returns a 3-element Perl list)
   int GetTextureDimension ();
   int GetTextureDimensionMaxValue ();
   int GetTextureDimensionMinValue ();
   float GetUpperThreshold ();
   vtkThresholdTextureCoords *New ();
   void SetInTextureCoord (float , float , float );
   void SetOutTextureCoord (float , float , float );
   void SetTextureDimension (int );
   void ThresholdBetween (float lower, float upper);
   void ThresholdByLower (float lower);
   void ThresholdByUpper (float upper);


B<vtkThresholdTextureCoords Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetInTextureCoord (float  a[3]);
      Method is redundant. Same as SetInTextureCoord( float, float, float)

   void SetOutTextureCoord (float  a[3]);
      Method is redundant. Same as SetOutTextureCoord( float, float, float)


=cut

package Graphics::VTK::TransformFilter;


@Graphics::VTK::TransformFilter::ISA = qw( Graphics::VTK::PointSetToPointSetFilter );

=head1 Graphics::VTK::TransformFilter

=over 1

=item *

Inherits from PointSetToPointSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   unsigned long GetMTime ();
   vtkAbstractTransform *GetTransform ();
   vtkTransformFilter *New ();
   void SetTransform (vtkAbstractTransform *);


B<vtkTransformFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::TransformPolyDataFilter;


@Graphics::VTK::TransformPolyDataFilter::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::TransformPolyDataFilter

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   unsigned long GetMTime ();
   vtkAbstractTransform *GetTransform ();
   vtkTransformPolyDataFilter *New ();
   void SetTransform (vtkAbstractTransform *);


B<vtkTransformPolyDataFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::TransformTextureCoords;


@Graphics::VTK::TransformTextureCoords::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::TransformTextureCoords

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddPosition (float deltaR, float deltaS, float deltaT);
   void FlipROff ();
   void FlipROn ();
   void FlipSOff ();
   void FlipSOn ();
   void FlipTOff ();
   void FlipTOn ();
   const char *GetClassName ();
   int GetFlipR ();
   int GetFlipS ();
   int GetFlipT ();
   float  *GetOrigin ();
      (Returns a 3-element Perl list)
   float  *GetPosition ();
      (Returns a 3-element Perl list)
   float  *GetScale ();
      (Returns a 3-element Perl list)
   vtkTransformTextureCoords *New ();
   void SetFlipR (int );
   void SetFlipS (int );
   void SetFlipT (int );
   void SetOrigin (float , float , float );
   void SetPosition (float , float , float );
   void SetScale (float , float , float );


B<vtkTransformTextureCoords Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void AddPosition (float deltaPosition[3]);
      Method is redundant. Same as AddPosition( float, float, float)

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetOrigin (float  a[3]);
      Method is redundant. Same as SetOrigin( float, float, float)

   void SetPosition (float  a[3]);
      Method is redundant. Same as SetPosition( float, float, float)

   void SetScale (float  a[3]);
      Method is redundant. Same as SetScale( float, float, float)


=cut

package Graphics::VTK::TriangleFilter;


@Graphics::VTK::TriangleFilter::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::TriangleFilter

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetPassLines ();
   int GetPassVerts ();
   vtkTriangleFilter *New ();
   void PassLinesOff ();
   void PassLinesOn ();
   void PassVertsOff ();
   void PassVertsOn ();
   void SetPassLines (int );
   void SetPassVerts (int );


B<vtkTriangleFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::TriangularTCoords;


@Graphics::VTK::TriangularTCoords::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::TriangularTCoords

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkTriangularTCoords *New ();


B<vtkTriangularTCoords Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::TubeFilter;


@Graphics::VTK::TubeFilter::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::TubeFilter

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CappingOff ();
   void CappingOn ();
   int GetCapping ();
   const char *GetClassName ();
   float  *GetDefaultNormal ();
      (Returns a 3-element Perl list)
   int GetNumberOfSides ();
   int GetNumberOfSidesMaxValue ();
   int GetNumberOfSidesMinValue ();
   int GetOffset ();
   int GetOffsetMaxValue ();
   int GetOffsetMinValue ();
   int GetOnRatio ();
   int GetOnRatioMaxValue ();
   int GetOnRatioMinValue ();
   float GetRadius ();
   float GetRadiusFactor ();
   float GetRadiusMaxValue ();
   float GetRadiusMinValue ();
   int GetUseDefaultNormal ();
   int GetVaryRadius ();
   const char *GetVaryRadiusAsString ();
   int GetVaryRadiusMaxValue ();
   int GetVaryRadiusMinValue ();
   vtkTubeFilter *New ();
   void SetCapping (int );
   void SetDefaultNormal (float , float , float );
   void SetNumberOfSides (int );
   void SetOffset (int );
   void SetOnRatio (int );
   void SetRadius (float );
   void SetRadiusFactor (float );
   void SetUseDefaultNormal (int );
   void SetVaryRadius (int );
   void SetVaryRadiusToVaryRadiusByScalar ();
   void SetVaryRadiusToVaryRadiusByVector ();
   void SetVaryRadiusToVaryRadiusOff ();
   void UseDefaultNormalOff ();
   void UseDefaultNormalOn ();


B<vtkTubeFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetDefaultNormal (float  a[3]);
      Method is redundant. Same as SetDefaultNormal( float, float, float)


=cut

package Graphics::VTK::VectorDot;


@Graphics::VTK::VectorDot::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::VectorDot

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float  *GetScalarRange ();
      (Returns a 2-element Perl list)
   vtkVectorDot *New ();
   void SetScalarRange (float , float );


B<vtkVectorDot Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetScalarRange (float  a[2]);
      Method is redundant. Same as SetScalarRange( float, float)


=cut

package Graphics::VTK::VectorNorm;


@Graphics::VTK::VectorNorm::ISA = qw( Graphics::VTK::DataSetToDataSetFilter );

=head1 Graphics::VTK::VectorNorm

=over 1

=item *

Inherits from DataSetToDataSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   int GetAttributeMode ();
   const char *GetAttributeModeAsString ();
   const char *GetClassName ();
   int GetNormalize ();
   vtkVectorNorm *New ();
   void NormalizeOff ();
   void NormalizeOn ();
   void SetAttributeMode (int );
   void SetAttributeModeToDefault ();
   void SetAttributeModeToUseCellData ();
   void SetAttributeModeToUsePointData ();
   void SetNormalize (int );


B<vtkVectorNorm Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::VoxelContoursToSurfaceFilter;


@Graphics::VTK::VoxelContoursToSurfaceFilter::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::VoxelContoursToSurfaceFilter

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetMemoryLimitInBytes ();
   float  *GetSpacing ();
      (Returns a 3-element Perl list)
   vtkVoxelContoursToSurfaceFilter *New ();
   void SetMemoryLimitInBytes (int );
   void SetSpacing (float , float , float );


B<vtkVoxelContoursToSurfaceFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void CastLines (float *slice, float gridOrigin[3], int gridSize[3], int type);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void PushDistances (float *ptr, int gridSize[3], int chunkSize);
      Don't know the size of pointer arg number 1

   void SetSpacing (float  a[3]);
      Method is redundant. Same as SetSpacing( float, float, float)


=cut

package Graphics::VTK::WarpLens;


@Graphics::VTK::WarpLens::ISA = qw( Graphics::VTK::PointSetToPointSetFilter );

=head1 Graphics::VTK::WarpLens

=over 1

=item *

Inherits from PointSetToPointSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   float *GetCenter ();
      (Returns a 2-element Perl list)
   const char *GetClassName ();
   float GetFormatHeight ();
   float GetFormatWidth ();
   int GetImageHeight ();
   int GetImageWidth ();
   float GetK1 ();
   float GetK2 ();
   float GetKappa ();
   float GetP1 ();
   float GetP2 ();
   float  *GetPrincipalPoint ();
      (Returns a 2-element Perl list)
   vtkWarpLens *New ();
   void SetCenter (float centerX, float centerY);
   void SetFormatHeight (float );
   void SetFormatWidth (float );
   void SetImageHeight (int );
   void SetImageWidth (int );
   void SetK1 (float );
   void SetK2 (float );
   void SetKappa (float kappa);
   void SetP1 (float );
   void SetP2 (float );
   void SetPrincipalPoint (float , float );


B<vtkWarpLens Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetPrincipalPoint (float  a[2]);
      Method is redundant. Same as SetPrincipalPoint( float, float)


=cut

package Graphics::VTK::WarpScalar;


@Graphics::VTK::WarpScalar::ISA = qw( Graphics::VTK::PointSetToPointSetFilter );

=head1 Graphics::VTK::WarpScalar

=over 1

=item *

Inherits from PointSetToPointSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float  *GetNormal ();
      (Returns a 3-element Perl list)
   float GetScaleFactor ();
   int GetUseNormal ();
   int GetXYPlane ();
   vtkWarpScalar *New ();
   void SetNormal (float , float , float );
   void SetScaleFactor (float );
   void SetUseNormal (int );
   void SetXYPlane (int );
   void UseNormalOff ();
   void UseNormalOn ();
   void XYPlaneOff ();
   void XYPlaneOn ();


B<vtkWarpScalar Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetNormal (float  a[3]);
      Method is redundant. Same as SetNormal( float, float, float)


=cut

package Graphics::VTK::WarpTo;


@Graphics::VTK::WarpTo::ISA = qw( Graphics::VTK::PointSetToPointSetFilter );

=head1 Graphics::VTK::WarpTo

=over 1

=item *

Inherits from PointSetToPointSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AbsoluteOff ();
   void AbsoluteOn ();
   int GetAbsolute ();
   const char *GetClassName ();
   float  *GetPosition ();
      (Returns a 3-element Perl list)
   float GetScaleFactor ();
   vtkWarpTo *New ();
   void SetAbsolute (int );
   void SetPosition (float , float , float );
   void SetScaleFactor (float );


B<vtkWarpTo Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetPosition (float  a[3]);
      Method is redundant. Same as SetPosition( float, float, float)


=cut

package Graphics::VTK::WarpVector;


@Graphics::VTK::WarpVector::ISA = qw( Graphics::VTK::PointSetToPointSetFilter );

=head1 Graphics::VTK::WarpVector

=over 1

=item *

Inherits from PointSetToPointSetFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float GetScaleFactor ();
   vtkWarpVector *New ();
   void SetScaleFactor (float );


B<vtkWarpVector Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::WindowedSincPolyDataFilter;


@Graphics::VTK::WindowedSincPolyDataFilter::ISA = qw( Graphics::VTK::PolyDataToPolyDataFilter );

=head1 Graphics::VTK::WindowedSincPolyDataFilter

=over 1

=item *

Inherits from PolyDataToPolyDataFilter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void BoundarySmoothingOff ();
   void BoundarySmoothingOn ();
   void FeatureEdgeSmoothingOff ();
   void FeatureEdgeSmoothingOn ();
   void GenerateErrorScalarsOff ();
   void GenerateErrorScalarsOn ();
   void GenerateErrorVectorsOff ();
   void GenerateErrorVectorsOn ();
   int GetBoundarySmoothing ();
   const char *GetClassName ();
   float GetEdgeAngle ();
   float GetEdgeAngleMaxValue ();
   float GetEdgeAngleMinValue ();
   float GetFeatureAngle ();
   float GetFeatureAngleMaxValue ();
   float GetFeatureAngleMinValue ();
   int GetFeatureEdgeSmoothing ();
   int GetGenerateErrorScalars ();
   int GetGenerateErrorVectors ();
   int GetNumberOfIterations ();
   int GetNumberOfIterationsMaxValue ();
   int GetNumberOfIterationsMinValue ();
   float GetPassBand ();
   float GetPassBandMaxValue ();
   float GetPassBandMinValue ();
   vtkWindowedSincPolyDataFilter *New ();
   void SetBoundarySmoothing (int );
   void SetEdgeAngle (float );
   void SetFeatureAngle (float );
   void SetFeatureEdgeSmoothing (int );
   void SetGenerateErrorScalars (int );
   void SetGenerateErrorVectors (int );
   void SetNumberOfIterations (int );
   void SetPassBand (float );


B<vtkWindowedSincPolyDataFilter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

1;
