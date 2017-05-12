
package Graphics::VTK::IO;
use 5.004;
use strict;
use Carp;

use vars qw/ $VERSION @ISA/;

require DynaLoader;

$VERSION = '4.0.001';

@ISA = qw/ DynaLoader /;

bootstrap Graphics::VTK::IO $VERSION;


=head1 NAME

VTKIO  - A Perl interface to VTKIO library

=head1 SYNOPSIS

C<use Graphics::VTK;>
C<use Graphics::VTK::IO;>

=head1 DESCRIPTION

Graphics::VTK::IO is an interface to the IO libaray of the C++ visualization toolkit VTK..

=head1 AUTHOR

Original PerlVTK Package: Roberto De Leo <rdl@math.umd.edu>

Additional Refinements: John Cerney <j-cerney1@raytheon.com>

=cut

package Graphics::VTK::BMPReader;


@Graphics::VTK::BMPReader::ISA = qw( Graphics::VTK::ImageReader );

=head1 Graphics::VTK::BMPReader

=over 1

=item *

Inherits from ImageReader

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetDepth ();
   vtkBMPReader *New ();


B<vtkBMPReader Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::BMPWriter;


@Graphics::VTK::BMPWriter::ISA = qw( Graphics::VTK::ImageWriter );

=head1 Graphics::VTK::BMPWriter

=over 1

=item *

Inherits from ImageWriter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkBMPWriter *New ();


B<vtkBMPWriter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void WriteFile (ofstream *file, vtkImageData *data, int ext[6]);
      Don't know the size of pointer arg number 1

   virtual void WriteFileHeader (ofstream *, vtkImageData *);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::BYUReader;


@Graphics::VTK::BYUReader::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::BYUReader

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   char *GetDisplacementFileName ();
   char *GetGeometryFileName ();
   int GetPartNumber ();
   int GetPartNumberMaxValue ();
   int GetPartNumberMinValue ();
   int GetReadDisplacement ();
   int GetReadScalar ();
   int GetReadTexture ();
   char *GetScalarFileName ();
   char *GetTextureFileName ();
   vtkBYUReader *New ();
   void ReadDisplacementOff ();
   void ReadDisplacementOn ();
   void ReadScalarOff ();
   void ReadScalarOn ();
   void ReadTextureOff ();
   void ReadTextureOn ();
   void SetDisplacementFileName (char *);
   void SetGeometryFileName (char *);
   void SetPartNumber (int );
   void SetReadDisplacement (int );
   void SetReadScalar (int );
   void SetReadTexture (int );
   void SetScalarFileName (char *);
   void SetTextureFileName (char *);


B<vtkBYUReader Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void ReadGeometryFile (FILE *fp, int &numPts);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::BYUWriter;


@Graphics::VTK::BYUWriter::ISA = qw( Graphics::VTK::PolyDataWriter );

=head1 Graphics::VTK::BYUWriter

=over 1

=item *

Inherits from PolyDataWriter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   char *GetDisplacementFileName ();
   char *GetGeometryFileName ();
   char *GetScalarFileName ();
   char *GetTextureFileName ();
   int GetWriteDisplacement ();
   int GetWriteScalar ();
   int GetWriteTexture ();
   vtkBYUWriter *New ();
   void SetDisplacementFileName (char *);
   void SetGeometryFileName (char *);
   void SetScalarFileName (char *);
   void SetTextureFileName (char *);
   void SetWriteDisplacement (int );
   void SetWriteScalar (int );
   void SetWriteTexture (int );
   void WriteDisplacementOff ();
   void WriteDisplacementOn ();
   void WriteScalarOff ();
   void WriteScalarOn ();
   void WriteTextureOff ();
   void WriteTextureOn ();


B<vtkBYUWriter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void WriteGeometryFile (FILE *fp, int numPts);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::DEMReader;


@Graphics::VTK::DEMReader::ISA = qw( Graphics::VTK::ImageSource );

=head1 Graphics::VTK::DEMReader

=over 1

=item *

Inherits from ImageSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void ExecuteInformation ();
   int GetAccuracyCode ();
   const char *GetClassName ();
   int GetDEMLevel ();
   float  *GetElevationBounds ();
      (Returns a 2-element Perl list)
   int GetElevationPattern ();
   int GetElevationUnitOfMeasure ();
   char *GetFileName ();
   int GetGroundSystem ();
   int GetGroundZone ();
   float GetLocalRotation ();
   char *GetMapLabel ();
   int GetPlaneUnitOfMeasure ();
   int GetPolygonSize ();
   int  *GetProfileDimension ();
      (Returns a 2-element Perl list)
   float  *GetProjectionParameters ();
      (Returns a 15-element Perl list)
   float  *GetSpatialResolution ();
      (Returns a 3-element Perl list)
   vtkDEMReader *New ();
   void SetFileName (char *);


B<vtkDEMReader Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeExtentOriginAndSpacing (int extent[6], float origin[6], float spacing[6]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::DataObjectReader;


@Graphics::VTK::DataObjectReader::ISA = qw( Graphics::VTK::DataReader );

=head1 Graphics::VTK::DataObjectReader

=over 1

=item *

Inherits from DataReader

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkDataObject *GetOutput (int idx);
   vtkDataObject *GetOutput ();
   vtkDataObjectReader *New ();
   void SetOutput (vtkDataObject *);


B<vtkDataObjectReader Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::DataObjectWriter;


@Graphics::VTK::DataObjectWriter::ISA = qw( Graphics::VTK::Writer );

=head1 Graphics::VTK::DataObjectWriter

=over 1

=item *

Inherits from Writer

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   char *GetFieldDataName ();
   char *GetFileName ();
   int GetFileType ();
   char *GetHeader ();
   vtkDataObject *GetInput ();
   vtkDataObjectWriter *New ();
   void SetFieldDataName (char *fieldname);
   void SetFileName (const char *filename);
   void SetFileType (int type);
   void SetFileTypeToASCII ();
   void SetFileTypeToBinary ();
   void SetHeader (char *header);
   void SetInput (vtkDataObject &input);
   void SetInput (vtkDataObject *input);


B<vtkDataObjectWriter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::DataReader;


@Graphics::VTK::DataReader::ISA = qw( Graphics::VTK::Source );

=head1 Graphics::VTK::DataReader

=over 1

=item *

Inherits from Source

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CloseVTKFile ();
   const char *GetClassName ();
   char *GetFieldDataName ();
   const char *GetFieldDataNameInFile (int i);
   char *GetFileName ();
   int GetFileType ();
   char *GetHeader ();
   char *GetInputString ();
   int GetInputStringLength ();
   char *GetLookupTableName ();
   char *GetNormalsName ();
   const char *GetNormalsNameInFile (int i);
   int GetNumberOfFieldDataInFile ();
   int GetNumberOfNormalsInFile ();
   int GetNumberOfScalarsInFile ();
   int GetNumberOfTCoordsInFile ();
   int GetNumberOfTensorsInFile ();
   int GetNumberOfVectorsInFile ();
   int GetReadFromInputString ();
   char *GetScalarsName ();
   const char *GetScalarsNameInFile (int i);
   char *GetTCoordsName ();
   const char *GetTCoordsNameInFile (int i);
   char *GetTensorsName ();
   const char *GetTensorsNameInFile (int i);
   char *GetVectorsName ();
   const char *GetVectorsNameInFile (int i);
   int IsFilePolyData ();
   int IsFileRectilinearGrid ();
   int IsFileStructuredGrid ();
   int IsFileStructuredPoints ();
   int IsFileUnstructuredGrid ();
   int IsFileValid (const char *dstype);
   vtkDataReader *New ();
   int OpenVTKFile ();
   int Read (char *);
   vtkDataArray *ReadArray (const char *dataType, int numTuples, int numComp);
   int ReadCellData (vtkDataSet *ds, int numCells);
   int ReadCoordinates (vtkRectilinearGrid *rg, int axes, int numCoords);
   vtkFieldData *ReadFieldData ();
   void ReadFromInputStringOff ();
   void ReadFromInputStringOn ();
   int ReadHeader ();
   int ReadPointData (vtkDataSet *ds, int numPts);
   int ReadPoints (vtkPointSet *ps, int numPts);
   void SetBinaryInputString (const char *, int len);
   void SetFieldDataName (char *);
   void SetFileName (char *);
   void SetInputString (const char *in, int len);
   void SetInputString (const char *in);
   void SetLookupTableName (char *);
   void SetNormalsName (char *);
   void SetReadFromInputString (int );
   void SetScalarsName (char *);
   void SetTCoordsName (char *);
   void SetTensorsName (char *);
   void SetVectorsName (char *);


B<vtkDataReader Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void CheckFor (const char *name, char *line, int &num, char &array, int &allocSize);
      No TCL interface is provided by VTK, so we aren't going to provide one either.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   int ReadCells (int size, int *data);
      Don't know the size of pointer arg number 2

   int ReadCells (int size, int *data, int skip1, int read2, int skip3);
      Don't know the size of pointer arg number 2

   int Read (unsigned char *);
      Don't know the size of pointer arg number 1

   int Read (short *);
      Don't know the size of pointer arg number 1

   int Read (unsigned short *);
      Don't know the size of pointer arg number 1

   int Read (int *);
      Don't know the size of pointer arg number 1

   int Read (unsigned int *);
      Don't know the size of pointer arg number 1

   int Read (long *);
      Don't know the size of pointer arg number 1

   int Read (unsigned long *);
      Don't know the size of pointer arg number 1

   int Read (float *);
      Don't know the size of pointer arg number 1

   int Read (double *);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::DataSetReader;


@Graphics::VTK::DataSetReader::ISA = qw( Graphics::VTK::DataReader );

=head1 Graphics::VTK::DataSetReader

=over 1

=item *

Inherits from DataReader

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkDataSet *GetOutput (int idx);
   vtkDataSet *GetOutput ();
   vtkPolyData *GetPolyDataOutput ();
   vtkRectilinearGrid *GetRectilinearGridOutput ();
   vtkStructuredGrid *GetStructuredGridOutput ();
   vtkStructuredPoints *GetStructuredPointsOutput ();
   vtkUnstructuredGrid *GetUnstructuredGridOutput ();
   vtkDataSetReader *New ();
   void Update ();


B<vtkDataSetReader Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::DataSetWriter;


@Graphics::VTK::DataSetWriter::ISA = qw( Graphics::VTK::DataWriter );

=head1 Graphics::VTK::DataSetWriter

=over 1

=item *

Inherits from DataWriter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkDataSet *GetInput ();
   vtkDataSetWriter *New ();
   void SetInput (vtkDataSet *input);


B<vtkDataSetWriter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::DataWriter;


@Graphics::VTK::DataWriter::ISA = qw( Graphics::VTK::Writer );

=head1 Graphics::VTK::DataWriter

=over 1

=item *

Inherits from Writer

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   char *GetFieldDataName ();
   char *GetFileName ();
   int GetFileType ();
   int GetFileTypeMaxValue ();
   int GetFileTypeMinValue ();
   char *GetHeader ();
   char *GetLookupTableName ();
   char *GetNormalsName ();
   char *GetOutputString ();
   int GetOutputStringLength ();
   char *GetScalarsName ();
   char *GetTCoordsName ();
   char *GetTensorsName ();
   char *GetVectorsName ();
   int GetWriteToOutputString ();
   vtkDataWriter *New ();
   char *RegisterAndGetOutputString ();
   void SetFieldDataName (char *);
   void SetFileName (char *);
   void SetFileType (int );
   void SetFileTypeToASCII ();
   void SetFileTypeToBinary ();
   void SetHeader (char *);
   void SetLookupTableName (char *);
   void SetNormalsName (char *);
   void SetScalarsName (char *);
   void SetTCoordsName (char *);
   void SetTensorsName (char *);
   void SetVectorsName (char *);
   void SetWriteToOutputString (int );
   void WriteToOutputStringOff ();
   void WriteToOutputStringOn ();


B<vtkDataWriter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void CloseVTKFile (ostream *fp);
      I/O Streams not Supported yet

   unsigned char *GetBinaryOutputString ();
      Can't Handle 'unsigned char *' return type without a hint

   virtual ostream *OpenVTKFile ();
      I/O Streams not Supported yet

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   int WriteArray (ostream *fp, int dataType, vtkDataArray *data, const char *format, int num, int numComp);
      Don't know the size of pointer arg number 1

   int WriteCellData (ostream *fp, vtkDataSet *ds);
      I/O Streams not Supported yet

   int WriteCells (ostream *fp, vtkCellArray *cells, const char *label);
      I/O Streams not Supported yet

   int WriteCoordinates (ostream *fp, vtkDataArray *coords, int axes);
      I/O Streams not Supported yet

   int WriteDataSetData (ostream *fp, vtkDataSet *ds);
      I/O Streams not Supported yet

   int WriteFieldData (ostream *fp, vtkFieldData *f);
      I/O Streams not Supported yet

   int WriteHeader (ostream *fp);
      I/O Streams not Supported yet

   int WriteNormalData (ostream *fp, vtkDataArray *n, int num);
      Don't know the size of pointer arg number 1

   int WritePointData (ostream *fp, vtkDataSet *ds);
      I/O Streams not Supported yet

   int WritePoints (ostream *fp, vtkPoints *p);
      I/O Streams not Supported yet

   int WriteScalarData (ostream *fp, vtkDataArray *s, int num);
      Don't know the size of pointer arg number 1

   int WriteTCoordData (ostream *fp, vtkDataArray *tc, int num);
      Don't know the size of pointer arg number 1

   int WriteTensorData (ostream *fp, vtkDataArray *t, int num);
      Don't know the size of pointer arg number 1

   int WriteVectorData (ostream *fp, vtkDataArray *v, int num);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::EnSight6BinaryReader;


@Graphics::VTK::EnSight6BinaryReader::ISA = qw( Graphics::VTK::EnSightReader );

=head1 Graphics::VTK::EnSight6BinaryReader

=over 1

=item *

Inherits from EnSightReader

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkEnSight6BinaryReader *New ();


B<vtkEnSight6BinaryReader Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int ReadFloatArray (float *result, int numFloats);
      Don't know the size of pointer arg number 1

   int ReadInt (int *result);
      Don't know the size of pointer arg number 1

   int ReadIntArray (int *result, int numInts);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::EnSight6Reader;


@Graphics::VTK::EnSight6Reader::ISA = qw( Graphics::VTK::EnSightReader );

=head1 Graphics::VTK::EnSight6Reader

=over 1

=item *

Inherits from EnSightReader

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkEnSight6Reader *New ();

=cut

package Graphics::VTK::EnSightGoldBinaryReader;


@Graphics::VTK::EnSightGoldBinaryReader::ISA = qw( Graphics::VTK::EnSightReader );

=head1 Graphics::VTK::EnSightGoldBinaryReader

=over 1

=item *

Inherits from EnSightReader

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkEnSightGoldBinaryReader *New ();


B<vtkEnSightGoldBinaryReader Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int ReadFloatArray (float *result, int numFloats);
      Don't know the size of pointer arg number 1

   int ReadInt (int *result);
      Don't know the size of pointer arg number 1

   int ReadIntArray (int *result, int numInts);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::EnSightGoldReader;


@Graphics::VTK::EnSightGoldReader::ISA = qw( Graphics::VTK::EnSightReader );

=head1 Graphics::VTK::EnSightGoldReader

=over 1

=item *

Inherits from EnSightReader

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkEnSightGoldReader *New ();

=cut

package Graphics::VTK::EnSightReader;


@Graphics::VTK::EnSightReader::ISA = qw( Graphics::VTK::DataSetSource );

=head1 Graphics::VTK::EnSightReader

=over 1

=item *

Inherits from DataSetSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   char *GetCaseFileName ();
   const char *GetClassName ();
   char *GetComplexDescription (int n);
   int GetComplexVariableType (int n);
   char *GetDescription (int n, int type);
   char *GetDescription (int n);
   char *GetFilePath ();
   float GetMaximumTimeValue ();
   float GetMinimumTimeValue ();
   int GetNumberOfComplexScalarsPerElement ();
   int GetNumberOfComplexScalarsPerNode ();
   int GetNumberOfComplexVariables ();
   int GetNumberOfComplexVectorsPerElement ();
   int GetNumberOfComplexVectorsPerNode ();
   int GetNumberOfScalarsPerElement ();
   int GetNumberOfScalarsPerMeasuredNode ();
   int GetNumberOfScalarsPerNode ();
   int GetNumberOfTensorsSymmPerElement ();
   int GetNumberOfTensorsSymmPerNode ();
   int GetNumberOfVariables (int type);
   int GetNumberOfVariables ();
   int GetNumberOfVectorsPerElement ();
   int GetNumberOfVectorsPerMeasuredNode ();
   int GetNumberOfVectorsPerNode ();
   float GetTimeValue ();
   int GetVariableType (int n);
   void SetCaseFileName (char *fileName);
   void SetFilePath (char *);
   void SetTimeValue (float );
   void Update ();


B<vtkEnSightReader Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::GESignaReader;


@Graphics::VTK::GESignaReader::ISA = qw( Graphics::VTK::ImageReader2 );

=head1 Graphics::VTK::GESignaReader

=over 1

=item *

Inherits from ImageReader2

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkGESignaReader *New ();

=cut

package Graphics::VTK::GenericEnSightReader;


@Graphics::VTK::GenericEnSightReader::ISA = qw( Graphics::VTK::DataSetSource );

=head1 Graphics::VTK::GenericEnSightReader

=over 1

=item *

Inherits from DataSetSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   char *GetCaseFileName ();
   const char *GetClassName ();
   char *GetComplexDescription (int n);
   int GetComplexVariableType (int n);
   char *GetDescription (int n, int type);
   char *GetDescription (int n);
   char *GetFilePath ();
   float GetMaximumTimeValue ();
   float GetMinimumTimeValue ();
   int GetNumberOfComplexScalarsPerElement ();
   int GetNumberOfComplexScalarsPerNode ();
   int GetNumberOfComplexVectorsPerElement ();
   int GetNumberOfComplexVectorsPerNode ();
   int GetNumberOfScalarsPerElement ();
   int GetNumberOfScalarsPerMeasuredNode ();
   int GetNumberOfScalarsPerNode ();
   int GetNumberOfTensorsSymmPerElement ();
   int GetNumberOfTensorsSymmPerNode ();
   int GetNumberOfVariables (int type);
   int GetNumberOfVectorsPerElement ();
   int GetNumberOfVectorsPerMeasuredNode ();
   int GetNumberOfVectorsPerNode ();
   float GetTimeValue ();
   int GetVariableType (int n);
   vtkGenericEnSightReader *New ();
   void SetCaseFileName (char *fileName);
   void SetFilePath (char *);
   void SetTimeValue (float );
   void Update ();


B<vtkGenericEnSightReader Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::IVWriter;


@Graphics::VTK::IVWriter::ISA = qw( Graphics::VTK::PolyDataWriter );

=head1 Graphics::VTK::IVWriter

=over 1

=item *

Inherits from PolyDataWriter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkIVWriter *New ();


B<vtkIVWriter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void WritePolyData (vtkPolyData *polyData, FILE *fp);
      Don't know the size of pointer arg number 2


=cut

package Graphics::VTK::ImageReader;


@Graphics::VTK::ImageReader::ISA = qw( Graphics::VTK::ImageSource );

=head1 Graphics::VTK::ImageReader

=over 1

=item *

Inherits from ImageSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void ComputeInternalFileName (int slice);
   void FileLowerLeftOff ();
   void FileLowerLeftOn ();
   const char *GetClassName ();
   int GetDataByteOrder ();
   const char *GetDataByteOrderAsString ();
   int  *GetDataExtent ();
      (Returns a 6-element Perl list)
   short unsigned GetDataMask ();
   float  *GetDataOrigin ();
      (Returns a 3-element Perl list)
   int GetDataScalarType ();
   float  *GetDataSpacing ();
      (Returns a 3-element Perl list)
   int  *GetDataVOI ();
      (Returns a 6-element Perl list)
   int GetFileDimensionality ();
   int GetFileLowerLeft ();
   char *GetFileName ();
   int GetFileNameSliceOffset ();
   int GetFileNameSliceSpacing ();
   char *GetFilePattern ();
   char *GetFilePrefix ();
   unsigned long GetHeaderSize (int slice);
   unsigned long GetHeaderSize ();
   char *GetInternalFileName ();
   int GetNumberOfScalarComponents ();
   int GetSwapBytes ();
   vtkTransform *GetTransform ();
   vtkImageReader *New ();
   void OpenFile ();
   void SetDataByteOrder (int );
   void SetDataByteOrderToBigEndian ();
   void SetDataByteOrderToLittleEndian ();
   void SetDataExtent (int , int , int , int , int , int );
   void SetDataMask (int val);
   void SetDataOrigin (float , float , float );
   void SetDataScalarType (int type);
   void SetDataScalarTypeToDouble ();
   void SetDataScalarTypeToFloat ();
   void SetDataScalarTypeToInt ();
   void SetDataScalarTypeToShort ();
   void SetDataScalarTypeToUnsignedChar ();
   void SetDataScalarTypeToUnsignedShort ();
   void SetDataSpacing (float , float , float );
   void SetDataVOI (int , int , int , int , int , int );
   void SetFileDimensionality (int );
   void SetFileLowerLeft (int );
   void SetFileName (const char *);
   void SetFileNameSliceOffset (int );
   void SetFileNameSliceSpacing (int );
   void SetFilePattern (const char *);
   void SetFilePrefix (const char *);
   void SetHeaderSize (unsigned long size);
   void SetNumberOfScalarComponents (int );
   void SetSwapBytes (int );
   void SetTransform (vtkTransform *);
   void SwapBytesOff ();
   void SwapBytesOn ();


B<vtkImageReader Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void ComputeInverseTransformedExtent (int inExtent[6], int outExtent[6]);
      Don't know the size of pointer arg number 1

   void ComputeInverseTransformedIncrements (int inIncr[3], int outIncr[3]);
      Don't know the size of pointer arg number 1

   void ComputeTransformedExtent (int inExtent[6], int outExtent[6]);
      Don't know the size of pointer arg number 1

   void ComputeTransformedIncrements (int inIncr[3], int outIncr[3]);
      Don't know the size of pointer arg number 1

   void OpenAndSeekFile (int extent[6], int slice);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetDataExtent (int  a[6]);
      Method is redundant. Same as SetDataExtent( int, int, int, int, int, int)

   void SetDataOrigin (float  a[3]);
      Method is redundant. Same as SetDataOrigin( float, float, float)

   void SetDataSpacing (float  a[3]);
      Method is redundant. Same as SetDataSpacing( float, float, float)

   void SetDataVOI (int  a[6]);
      Method is redundant. Same as SetDataVOI( int, int, int, int, int, int)


=cut

package Graphics::VTK::ImageReader2;


@Graphics::VTK::ImageReader2::ISA = qw( Graphics::VTK::ImageSource );

=head1 Graphics::VTK::ImageReader2

=over 1

=item *

Inherits from ImageSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void ComputeInternalFileName (int slice);
   void FileLowerLeftOff ();
   void FileLowerLeftOn ();
   const char *GetClassName ();
   int GetDataByteOrder ();
   const char *GetDataByteOrderAsString ();
   int  *GetDataExtent ();
      (Returns a 6-element Perl list)
   float  *GetDataOrigin ();
      (Returns a 3-element Perl list)
   int GetDataScalarType ();
   float  *GetDataSpacing ();
      (Returns a 3-element Perl list)
   int GetFileDimensionality ();
   int GetFileLowerLeft ();
   char *GetFileName ();
   char *GetFilePattern ();
   char *GetFilePrefix ();
   int GetHeaderSize (int slice);
   int GetHeaderSize ();
   char *GetInternalFileName ();
   int GetNumberOfScalarComponents ();
   int GetSwapBytes ();
   vtkImageReader2 *New ();
   void OpenFile ();
   void SeekFile (int i, int j, int k);
   void SetDataByteOrder (int );
   void SetDataByteOrderToBigEndian ();
   void SetDataByteOrderToLittleEndian ();
   void SetDataExtent (int , int , int , int , int , int );
   void SetDataOrigin (float , float , float );
   void SetDataScalarType (int type);
   void SetDataScalarTypeToDouble ();
   void SetDataScalarTypeToFloat ();
   void SetDataScalarTypeToInt ();
   void SetDataScalarTypeToShort ();
   void SetDataScalarTypeToUnsignedChar ();
   void SetDataScalarTypeToUnsignedShort ();
   void SetDataSpacing (float , float , float );
   void SetFileDimensionality (int );
   void SetFileLowerLeft (int );
   void SetFileName (const char *);
   void SetFilePattern (const char *);
   void SetFilePrefix (const char *);
   void SetHeaderSize (int size);
   void SetNumberOfScalarComponents (int );
   void SetSwapBytes (int );
   void SwapBytesOff ();
   void SwapBytesOn ();


B<vtkImageReader2 Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetDataExtent (int  a[6]);
      Method is redundant. Same as SetDataExtent( int, int, int, int, int, int)

   void SetDataOrigin (float  a[3]);
      Method is redundant. Same as SetDataOrigin( float, float, float)

   void SetDataSpacing (float  a[3]);
      Method is redundant. Same as SetDataSpacing( float, float, float)


=cut

package Graphics::VTK::ImageWriter;


@Graphics::VTK::ImageWriter::ISA = qw( Graphics::VTK::ProcessObject );

=head1 Graphics::VTK::ImageWriter

=over 1

=item *

Inherits from ProcessObject

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetFileDimensionality ();
   char *GetFileName ();
   char *GetFilePattern ();
   char *GetFilePrefix ();
   vtkImageData *GetInput ();
   vtkImageWriter *New ();
   void SetFileDimensionality (int );
   void SetFileName (const char *);
   void SetFilePattern (const char *filePattern);
   void SetFilePrefix (char *filePrefix);
   virtual void SetInput (vtkImageData *input);
   virtual void Write ();


B<vtkImageWriter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   virtual void RecursiveWrite (int dim, vtkImageData *region, ofstream *file);
      Don't know the size of pointer arg number 3

   virtual void RecursiveWrite (int dim, vtkImageData *cache, vtkImageData *data, ofstream *file);
      Don't know the size of pointer arg number 4

   virtual void WriteFile (ofstream *file, vtkImageData *data, int extent[6]);
      Don't know the size of pointer arg number 1

   virtual void WriteFileHeader (ofstream *, vtkImageData *);
      Don't know the size of pointer arg number 1

   virtual void WriteFileTrailer (ofstream *, vtkImageData *);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::JPEGReader;


@Graphics::VTK::JPEGReader::ISA = qw( Graphics::VTK::ImageReader2 );

=head1 Graphics::VTK::JPEGReader

=over 1

=item *

Inherits from ImageReader2

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkJPEGReader *New ();

=cut

package Graphics::VTK::JPEGWriter;


@Graphics::VTK::JPEGWriter::ISA = qw( Graphics::VTK::ImageWriter );

=head1 Graphics::VTK::JPEGWriter

=over 1

=item *

Inherits from ImageWriter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int unsigned GetProgressive ();
   int unsigned GetQuality ();
   unsigned GetQualityMaxValue ();
   unsigned GetQualityMinValue ();
   vtkJPEGWriter *New ();
   void ProgressiveOff ();
   void ProgressiveOn ();
   void SetProgressive (unsigned int );
   void SetQuality (unsigned int );
   virtual void Write ();


B<vtkJPEGWriter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::MCubesReader;


@Graphics::VTK::MCubesReader::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::MCubesReader

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CreateDefaultLocator ();
   void FlipNormalsOff ();
   void FlipNormalsOn ();
   const char *GetClassName ();
   int GetDataByteOrder ();
   const char *GetDataByteOrderAsString ();
   char *GetFileName ();
   int GetFlipNormals ();
   int GetHeaderSize ();
   int GetHeaderSizeMaxValue ();
   int GetHeaderSizeMinValue ();
   char *GetLimitsFileName ();
   vtkPointLocator *GetLocator ();
   unsigned long GetMTime ();
   int GetNormals ();
   int GetSwapBytes ();
   vtkMCubesReader *New ();
   void NormalsOff ();
   void NormalsOn ();
   void SetDataByteOrder (int );
   void SetDataByteOrderToBigEndian ();
   void SetDataByteOrderToLittleEndian ();
   void SetFileName (char *);
   void SetFlipNormals (int );
   void SetHeaderSize (int );
   void SetLimitsFileName (char *);
   void SetLocator (vtkPointLocator *locator);
   void SetNormals (int );
   void SetSwapBytes (int );
   void SwapBytesOff ();
   void SwapBytesOn ();


B<vtkMCubesReader Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::MCubesWriter;


@Graphics::VTK::MCubesWriter::ISA = qw( Graphics::VTK::PolyDataWriter );

=head1 Graphics::VTK::MCubesWriter

=over 1

=item *

Inherits from PolyDataWriter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   char *GetLimitsFileName ();
   vtkMCubesWriter *New ();
   void SetLimitsFileName (char *);


B<vtkMCubesWriter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::OBJReader;


@Graphics::VTK::OBJReader::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::OBJReader

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   char *GetFileName ();
   vtkOBJReader *New ();
   void SetFileName (char *);


B<vtkOBJReader Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::PLOT3DReader;


@Graphics::VTK::PLOT3DReader::ISA = qw( Graphics::VTK::StructuredGridSource );

=head1 Graphics::VTK::PLOT3DReader

=over 1

=item *

Inherits from StructuredGridSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void AddFunction (int functionNumber);
   float GetAlpha ();
   const char *GetClassName ();
   int GetFileFormat ();
   int GetFileFormatMaxValue ();
   int GetFileFormatMinValue ();
   float GetFsmach ();
   char *GetFunctionFileName ();
   float GetGamma ();
   int GetGridNumber ();
   int GetNumberOfGrids ();
   char *GetQFileName ();
   float GetR ();
   float GetRe ();
   int GetScalarFunctionNumber ();
   float GetTime ();
   float GetUvinf ();
   char *GetVectorFunctionFileName ();
   int GetVectorFunctionNumber ();
   float GetVvinf ();
   float GetWvinf ();
   char *GetXYZFileName ();
   vtkPLOT3DReader *New ();
   void RemoveAllFunctions ();
   void RemoveFunction (int );
   void SetFileFormat (int );
   void SetFunctionFileName (char *);
   void SetGamma (float );
   void SetGridNumber (int );
   void SetQFileName (char *);
   void SetR (float );
   void SetScalarFunctionNumber (int );
   void SetUvinf (float );
   void SetVectorFunctionFileName (char *);
   void SetVectorFunctionNumber (int );
   void SetVvinf (float );
   void SetWvinf (float );
   void SetXYZFileName (char *);


B<vtkPLOT3DReader Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int GetFileType (FILE *fp);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   int ReadBinaryFunctionFile (FILE *fp, vtkStructuredGrid *output);
      Don't know the size of pointer arg number 1

   int ReadBinaryGrid (FILE *fp, vtkStructuredGrid *output);
      Don't know the size of pointer arg number 1

   int ReadBinaryGridDimensions (FILE *fp, vtkStructuredGrid *output);
      Don't know the size of pointer arg number 1

   int ReadBinarySolution (FILE *fp, vtkStructuredGrid *output);
      Don't know the size of pointer arg number 1

   int ReadBinaryVectorFunctionFile (FILE *fp, vtkStructuredGrid *output);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::PLYReader;


@Graphics::VTK::PLYReader::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::PLYReader

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   char *GetFileName ();
   vtkPLYReader *New ();
   void SetFileName (char *);


B<vtkPLYReader Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::PLYWriter;


@Graphics::VTK::PLYWriter::ISA = qw( Graphics::VTK::PolyDataWriter );

=head1 Graphics::VTK::PLYWriter

=over 1

=item *

Inherits from PolyDataWriter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   char *GetArrayName ();
   const char *GetClassName ();
   unsigned char  *GetColor ();
      (Returns a 3-element Perl list)
   int GetColorMode ();
   int GetComponent ();
   int GetComponentMaxValue ();
   int GetComponentMinValue ();
   int GetDataByteOrder ();
   int GetDataByteOrderMaxValue ();
   int GetDataByteOrderMinValue ();
   vtkScalarsToColors *GetLookupTable ();
   vtkPLYWriter *New ();
   void SetArrayName (char *);
   void SetColor (unsigned char , unsigned char , unsigned char );
   void SetColorMode (int );
   void SetColorModeToDefault ();
   void SetColorModeToOff ();
   void SetColorModeToUniformCellColor ();
   void SetColorModeToUniformColor ();
   void SetColorModeToUniformPointColor ();
   void SetComponent (int );
   void SetDataByteOrder (int );
   void SetDataByteOrderToBigEndian ();
   void SetDataByteOrderToLittleEndian ();
   void SetLookupTable (vtkScalarsToColors *);


B<vtkPLYWriter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   unsigned char *GetColors (long num, vtkDataSetAttributes *dsa);
      Can't Handle 'unsigned char *' return type without a hint

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetColor (unsigned char  a[3]);
      Arg types of 'unsigned char  *' not supported yet

=cut

package Graphics::VTK::PNGReader;


@Graphics::VTK::PNGReader::ISA = qw( Graphics::VTK::ImageReader2 );

=head1 Graphics::VTK::PNGReader

=over 1

=item *

Inherits from ImageReader2

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkPNGReader *New ();

=cut

package Graphics::VTK::PNGWriter;


@Graphics::VTK::PNGWriter::ISA = qw( Graphics::VTK::ImageWriter );

=head1 Graphics::VTK::PNGWriter

=over 1

=item *

Inherits from ImageWriter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkPNGWriter *New ();
   virtual void Write ();

=cut

package Graphics::VTK::PNMReader;


@Graphics::VTK::PNMReader::ISA = qw( Graphics::VTK::ImageReader );

=head1 Graphics::VTK::PNMReader

=over 1

=item *

Inherits from ImageReader

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkPNMReader *New ();

=cut

package Graphics::VTK::PNMWriter;


@Graphics::VTK::PNMWriter::ISA = qw( Graphics::VTK::ImageWriter );

=head1 Graphics::VTK::PNMWriter

=over 1

=item *

Inherits from ImageWriter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkPNMWriter *New ();


B<vtkPNMWriter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void WriteFile (ofstream *file, vtkImageData *data, int extent[6]);
      Don't know the size of pointer arg number 1

   virtual void WriteFileHeader (ofstream *, vtkImageData *);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::ParticleReader;


@Graphics::VTK::ParticleReader::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::ParticleReader

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetDataByteOrder ();
   const char *GetDataByteOrderAsString ();
   char *GetFileName ();
   int GetSwapBytes ();
   vtkParticleReader *New ();
   void SetDataByteOrder (int );
   void SetDataByteOrderToBigEndian ();
   void SetDataByteOrderToLittleEndian ();
   void SetFileName (char *);
   void SetSwapBytes (int );
   void SwapBytesOff ();
   void SwapBytesOn ();


B<vtkParticleReader Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::PolyDataReader;


@Graphics::VTK::PolyDataReader::ISA = qw( Graphics::VTK::DataReader );

=head1 Graphics::VTK::PolyDataReader

=over 1

=item *

Inherits from DataReader

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkPolyData *GetOutput (int idx);
   vtkPolyData *GetOutput ();
   vtkPolyDataReader *New ();
   void SetOutput (vtkPolyData *output);


B<vtkPolyDataReader Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::PolyDataWriter;


@Graphics::VTK::PolyDataWriter::ISA = qw( Graphics::VTK::DataWriter );

=head1 Graphics::VTK::PolyDataWriter

=over 1

=item *

Inherits from DataWriter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkPolyData *GetInput ();
   vtkPolyDataWriter *New ();
   void SetInput (vtkPolyData *input);


B<vtkPolyDataWriter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::PostScriptWriter;


@Graphics::VTK::PostScriptWriter::ISA = qw( Graphics::VTK::ImageWriter );

=head1 Graphics::VTK::PostScriptWriter

=over 1

=item *

Inherits from ImageWriter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkPostScriptWriter *New ();


B<vtkPostScriptWriter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void WriteFile (ofstream *file, vtkImageData *data, int extent[6]);
      Don't know the size of pointer arg number 1

   virtual void WriteFileHeader (ofstream *, vtkImageData *);
      Don't know the size of pointer arg number 1

   virtual void WriteFileTrailer (ofstream *, vtkImageData *);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::RectilinearGridReader;


@Graphics::VTK::RectilinearGridReader::ISA = qw( Graphics::VTK::DataReader );

=head1 Graphics::VTK::RectilinearGridReader

=over 1

=item *

Inherits from DataReader

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkRectilinearGrid *GetOutput (int idx);
   vtkRectilinearGrid *GetOutput ();
   vtkRectilinearGridReader *New ();
   void SetOutput (vtkRectilinearGrid *output);


B<vtkRectilinearGridReader Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::RectilinearGridWriter;


@Graphics::VTK::RectilinearGridWriter::ISA = qw( Graphics::VTK::DataWriter );

=head1 Graphics::VTK::RectilinearGridWriter

=over 1

=item *

Inherits from DataWriter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkRectilinearGrid *GetInput ();
   vtkRectilinearGridWriter *New ();
   void SetInput (vtkRectilinearGrid *input);


B<vtkRectilinearGridWriter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::SLCReader;


@Graphics::VTK::SLCReader::ISA = qw( Graphics::VTK::StructuredPointsSource );

=head1 Graphics::VTK::SLCReader

=over 1

=item *

Inherits from StructuredPointsSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetError ();
   char *GetFileName ();
   vtkSLCReader *New ();
   void SetFileName (char *);


B<vtkSLCReader Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   unsigned char *Decode8BitData (unsigned char *in_ptr, int size);
      Can't Handle 'unsigned char *' return type without a hint

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::STLReader;


@Graphics::VTK::STLReader::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::STLReader

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CreateDefaultLocator ();
   const char *GetClassName ();
   char *GetFileName ();
   vtkPointLocator *GetLocator ();
   unsigned long GetMTime ();
   int GetMerging ();
   int GetScalarTags ();
   void MergingOff ();
   void MergingOn ();
   vtkSTLReader *New ();
   void ScalarTagsOff ();
   void ScalarTagsOn ();
   void SetFileName (char *);
   void SetLocator (vtkPointLocator *locator);
   void SetMerging (int );
   void SetScalarTags (int );


B<vtkSTLReader Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   int GetSTLFileType (FILE *fp);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   int ReadASCIISTL (FILE *fp, vtkPoints *, vtkCellArray *, vtkFloatArray *scalars);
      Don't know the size of pointer arg number 1

   int ReadBinarySTL (FILE *fp, vtkPoints *, vtkCellArray *);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::STLWriter;


@Graphics::VTK::STLWriter::ISA = qw( Graphics::VTK::PolyDataWriter );

=head1 Graphics::VTK::STLWriter

=over 1

=item *

Inherits from PolyDataWriter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkSTLWriter *New ();

=cut

package Graphics::VTK::StructuredGridReader;


@Graphics::VTK::StructuredGridReader::ISA = qw( Graphics::VTK::DataReader );

=head1 Graphics::VTK::StructuredGridReader

=over 1

=item *

Inherits from DataReader

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkStructuredGrid *GetOutput (int idx);
   vtkStructuredGrid *GetOutput ();
   vtkStructuredGridReader *New ();
   void SetOutput (vtkStructuredGrid *output);


B<vtkStructuredGridReader Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::StructuredGridWriter;


@Graphics::VTK::StructuredGridWriter::ISA = qw( Graphics::VTK::DataWriter );

=head1 Graphics::VTK::StructuredGridWriter

=over 1

=item *

Inherits from DataWriter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkStructuredGrid *GetInput ();
   vtkStructuredGridWriter *New ();
   void SetInput (vtkStructuredGrid *input);


B<vtkStructuredGridWriter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void WriteBlanking (ostream *fp, vtkStructuredGrid *ds);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::StructuredPointsReader;


@Graphics::VTK::StructuredPointsReader::ISA = qw( Graphics::VTK::DataReader );

=head1 Graphics::VTK::StructuredPointsReader

=over 1

=item *

Inherits from DataReader

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkStructuredPoints *GetOutput (int idx);
   vtkStructuredPoints *GetOutput ();
   vtkStructuredPointsReader *New ();
   void SetOutput (vtkStructuredPoints *output);


B<vtkStructuredPointsReader Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::StructuredPointsWriter;


@Graphics::VTK::StructuredPointsWriter::ISA = qw( Graphics::VTK::DataWriter );

=head1 Graphics::VTK::StructuredPointsWriter

=over 1

=item *

Inherits from DataWriter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkImageData *GetInput ();
   vtkStructuredPointsWriter *New ();
   void SetInput (vtkImageData *input);


B<vtkStructuredPointsWriter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::TIFFReader;


@Graphics::VTK::TIFFReader::ISA = qw( Graphics::VTK::ImageReader );

=head1 Graphics::VTK::TIFFReader

=over 1

=item *

Inherits from ImageReader

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkTIFFReader *New ();

=cut

package Graphics::VTK::TIFFWriter;


@Graphics::VTK::TIFFWriter::ISA = qw( Graphics::VTK::ImageWriter );

=head1 Graphics::VTK::TIFFWriter

=over 1

=item *

Inherits from ImageWriter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkTIFFWriter *New ();


B<vtkTIFFWriter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   virtual void WriteFile (ofstream *file, vtkImageData *data, int ext[6]);
      Don't know the size of pointer arg number 1

   virtual void WriteFileHeader (ofstream *, vtkImageData *);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::UGFacetReader;


@Graphics::VTK::UGFacetReader::ISA = qw( Graphics::VTK::PolyDataSource );

=head1 Graphics::VTK::UGFacetReader

=over 1

=item *

Inherits from PolyDataSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   void CreateDefaultLocator ();
   const char *GetClassName ();
   char *GetFileName ();
   vtkPointLocator *GetLocator ();
   unsigned long GetMTime ();
   int GetMerging ();
   int GetNumberOfParts ();
   short GetPartColorIndex (int partId);
   int GetPartNumber ();
   void MergingOff ();
   void MergingOn ();
   vtkUGFacetReader *New ();
   void SetFileName (char *);
   void SetLocator (vtkPointLocator *locator);
   void SetMerging (int );
   void SetPartNumber (int );


B<vtkUGFacetReader Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::UnstructuredGridReader;


@Graphics::VTK::UnstructuredGridReader::ISA = qw( Graphics::VTK::DataReader );

=head1 Graphics::VTK::UnstructuredGridReader

=over 1

=item *

Inherits from DataReader

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkUnstructuredGrid *GetOutput (int idx);
   vtkUnstructuredGrid *GetOutput ();
   vtkUnstructuredGridReader *New ();
   void SetOutput (vtkUnstructuredGrid *output);


B<vtkUnstructuredGridReader Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::UnstructuredGridWriter;


@Graphics::VTK::UnstructuredGridWriter::ISA = qw( Graphics::VTK::DataWriter );

=head1 Graphics::VTK::UnstructuredGridWriter

=over 1

=item *

Inherits from DataWriter

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   vtkUnstructuredGrid *GetInput ();
   vtkUnstructuredGridWriter *New ();
   void SetInput (vtkUnstructuredGrid *input);


B<vtkUnstructuredGridWriter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

package Graphics::VTK::Volume16Reader;


@Graphics::VTK::Volume16Reader::ISA = qw( Graphics::VTK::VolumeReader );

=head1 Graphics::VTK::Volume16Reader

=over 1

=item *

Inherits from VolumeReader

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   int GetDataByteOrder ();
   const char *GetDataByteOrderAsString ();
   int  *GetDataDimensions ();
      (Returns a 2-element Perl list)
   short unsigned GetDataMask ();
   int GetHeaderSize ();
   vtkStructuredPoints *GetImage (int ImageNumber);
   int GetSwapBytes ();
   vtkTransform *GetTransform ();
   vtkVolume16Reader *New ();
   void SetDataByteOrder (int );
   void SetDataByteOrderToBigEndian ();
   void SetDataByteOrderToLittleEndian ();
   void SetDataDimensions (int , int );
   void SetDataMask (unsigned short );
   void SetHeaderSize (int );
   void SetSwapBytes (int );
   void SetTransform (vtkTransform *);
   void SwapBytesOff ();
   void SwapBytesOn ();


B<vtkVolume16Reader Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void AdjustSpacingAndOrigin (int dimensions[3], float Spacing[3], float origin[3]);
      Don't know the size of pointer arg number 1

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   int Read16BitImage (FILE *fp, unsigned short *pixels, int xsize, int ysize, int skip, int swapBytes);
      Don't know the size of pointer arg number 1

   void SetDataDimensions (int  a[2]);
      Method is redundant. Same as SetDataDimensions( int, int)

   void TransformSlice (unsigned short *slice, unsigned short *pixels, int k, int dimensions[3], int bounds[3]);
      Don't know the size of pointer arg number 1


=cut

package Graphics::VTK::VolumeReader;


@Graphics::VTK::VolumeReader::ISA = qw( Graphics::VTK::StructuredPointsSource );

=head1 Graphics::VTK::VolumeReader

=over 1

=item *

Inherits from StructuredPointsSource

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   float  *GetDataOrigin ();
      (Returns a 3-element Perl list)
   float  *GetDataSpacing ();
      (Returns a 3-element Perl list)
   char *GetFilePattern ();
   char *GetFilePrefix ();
   virtual vtkStructuredPoints *GetImage (int ImageNumber) = 0;
   int  *GetImageRange ();
      (Returns a 2-element Perl list)
   void SetDataOrigin (float , float , float );
   void SetDataSpacing (float , float , float );
   void SetFilePattern (char *);
   void SetFilePrefix (char *);
   void SetImageRange (int , int );


B<vtkVolumeReader Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet

   void SetDataOrigin (float  a[3]);
      Method is redundant. Same as SetDataOrigin( float, float, float)

   void SetDataSpacing (float  a[3]);
      Method is redundant. Same as SetDataSpacing( float, float, float)

   void SetImageRange (int  a[2]);
      Method is redundant. Same as SetImageRange( int, int)


=cut

package Graphics::VTK::Writer;


@Graphics::VTK::Writer::ISA = qw( Graphics::VTK::ProcessObject );

=head1 Graphics::VTK::Writer

=over 1

=item *

Inherits from ProcessObject

=back

B<Functions Supported for this class by the PerlVTK module:>
(To find more about their use check the VTK documentation at http://www.kitware.com.)

   const char *GetClassName ();
   void Update ();
   virtual void Write ();


B<vtkWriter Unsupported Funcs:>

Functions which are not supported supported for this class by the PerlVTK module.

   void PrintSelf (ostream &os, vtkIndent indent);
      I/O Streams not Supported yet


=cut

1;
