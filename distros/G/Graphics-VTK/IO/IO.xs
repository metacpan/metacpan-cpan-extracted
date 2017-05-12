#include "EXTERN.h"

/* avoid some nasty defines on win32 that cause c++ compilation to fail */
#ifdef WIN32
#define WIN32IOP_H
#endif

#include "perl.h"
#include "XSUB.h"

/* 'THIS' gets redefined to 'void' in 
the standard mingw include 'basetyps.h', which causes problems with
the 'THIS' that appears in XS code. */
#ifdef __MINGW32__
#undef THIS
#endif

#include "vtkPerl.h"
#include "vtkBMPReader.h"
#include "vtkBMPWriter.h"
#include "vtkBYUReader.h"
#include "vtkBYUWriter.h"
#include "vtkDEMReader.h"
#include "vtkDataObjectReader.h"
#include "vtkDataObjectWriter.h"
#include "vtkDataReader.h"
#include "vtkDataSetReader.h"
#include "vtkDataSetWriter.h"
#include "vtkDataWriter.h"
#include "vtkEnSight6BinaryReader.h"
#include "vtkEnSight6Reader.h"
#include "vtkEnSightGoldBinaryReader.h"
#include "vtkEnSightGoldReader.h"
#include "vtkEnSightReader.h"
#include "vtkGESignaReader.h"
#include "vtkGenericEnSightReader.h"
#include "vtkIVWriter.h"
#include "vtkImageReader.h"
#include "vtkImageReader2.h"
#include "vtkImageWriter.h"
#include "vtkJPEGReader.h"
#include "vtkJPEGWriter.h"
#include "vtkMCubesReader.h"
#include "vtkMCubesWriter.h"
#include "vtkOBJReader.h"
#include "vtkPLOT3DReader.h"
#include "vtkPLYReader.h"
#include "vtkPLYWriter.h"
#include "vtkPNGReader.h"
#include "vtkPNGWriter.h"
#include "vtkPNMReader.h"
#include "vtkPNMWriter.h"
#include "vtkParticleReader.h"
#include "vtkPolyDataReader.h"
#include "vtkPolyDataWriter.h"
#include "vtkPostScriptWriter.h"
#include "vtkRectilinearGridReader.h"
#include "vtkRectilinearGridWriter.h"
#include "vtkSLCReader.h"
#include "vtkSTLReader.h"
#include "vtkSTLWriter.h"
#include "vtkStructuredGridReader.h"
#include "vtkStructuredGridWriter.h"
#include "vtkStructuredPointsReader.h"
#include "vtkStructuredPointsWriter.h"
#include "vtkTIFFReader.h"
#include "vtkTIFFWriter.h"
#include "vtkUGFacetReader.h"
#include "vtkUnstructuredGridReader.h"
#include "vtkUnstructuredGridWriter.h"
#include "vtkVolume16Reader.h"
#include "vtkVolumeReader.h"
#include "vtkWriter.h"
/* Routine to call a perl code ref, used by all the Set...Method methods
   like SetExecuteMethod.
*/

void
callperlsub(void * codeRef){
	SV* code = (SV*) codeRef;
	int count;
	dSP;
	PUSHMARK(SP) ;
	/*printf("callperlsub called'%s'\n",SvPV_nolen(code)); */
	count = perl_call_sv(code, G_DISCARD|G_NOARGS ) ;

}

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::BMPReader PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkBMPReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkBMPReader::GetDepth()
		CODE:
		RETVAL = THIS->GetDepth();
		OUTPUT:
		RETVAL


static vtkBMPReader*
vtkBMPReader::New()
		CODE:
		RETVAL = vtkBMPReader::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::BMPWriter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkBMPWriter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkBMPWriter*
vtkBMPWriter::New()
		CODE:
		RETVAL = vtkBMPWriter::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::BYUReader PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkBYUReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


char *
vtkBYUReader::GetDisplacementFileName()
		CODE:
		RETVAL = THIS->GetDisplacementFileName();
		OUTPUT:
		RETVAL


char *
vtkBYUReader::GetGeometryFileName()
		CODE:
		RETVAL = THIS->GetGeometryFileName();
		OUTPUT:
		RETVAL


int
vtkBYUReader::GetPartNumber()
		CODE:
		RETVAL = THIS->GetPartNumber();
		OUTPUT:
		RETVAL


int
vtkBYUReader::GetPartNumberMaxValue()
		CODE:
		RETVAL = THIS->GetPartNumberMaxValue();
		OUTPUT:
		RETVAL


int
vtkBYUReader::GetPartNumberMinValue()
		CODE:
		RETVAL = THIS->GetPartNumberMinValue();
		OUTPUT:
		RETVAL


int
vtkBYUReader::GetReadDisplacement()
		CODE:
		RETVAL = THIS->GetReadDisplacement();
		OUTPUT:
		RETVAL


int
vtkBYUReader::GetReadScalar()
		CODE:
		RETVAL = THIS->GetReadScalar();
		OUTPUT:
		RETVAL


int
vtkBYUReader::GetReadTexture()
		CODE:
		RETVAL = THIS->GetReadTexture();
		OUTPUT:
		RETVAL


char *
vtkBYUReader::GetScalarFileName()
		CODE:
		RETVAL = THIS->GetScalarFileName();
		OUTPUT:
		RETVAL


char *
vtkBYUReader::GetTextureFileName()
		CODE:
		RETVAL = THIS->GetTextureFileName();
		OUTPUT:
		RETVAL


static vtkBYUReader*
vtkBYUReader::New()
		CODE:
		RETVAL = vtkBYUReader::New();
		OUTPUT:
		RETVAL


void
vtkBYUReader::ReadDisplacementOff()
		CODE:
		THIS->ReadDisplacementOff();
		XSRETURN_EMPTY;


void
vtkBYUReader::ReadDisplacementOn()
		CODE:
		THIS->ReadDisplacementOn();
		XSRETURN_EMPTY;


void
vtkBYUReader::ReadScalarOff()
		CODE:
		THIS->ReadScalarOff();
		XSRETURN_EMPTY;


void
vtkBYUReader::ReadScalarOn()
		CODE:
		THIS->ReadScalarOn();
		XSRETURN_EMPTY;


void
vtkBYUReader::ReadTextureOff()
		CODE:
		THIS->ReadTextureOff();
		XSRETURN_EMPTY;


void
vtkBYUReader::ReadTextureOn()
		CODE:
		THIS->ReadTextureOn();
		XSRETURN_EMPTY;


void
vtkBYUReader::SetDisplacementFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetDisplacementFileName(arg1);
		XSRETURN_EMPTY;


void
vtkBYUReader::SetGeometryFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetGeometryFileName(arg1);
		XSRETURN_EMPTY;


void
vtkBYUReader::SetPartNumber(arg1)
		int 	arg1
		CODE:
		THIS->SetPartNumber(arg1);
		XSRETURN_EMPTY;


void
vtkBYUReader::SetReadDisplacement(arg1)
		int 	arg1
		CODE:
		THIS->SetReadDisplacement(arg1);
		XSRETURN_EMPTY;


void
vtkBYUReader::SetReadScalar(arg1)
		int 	arg1
		CODE:
		THIS->SetReadScalar(arg1);
		XSRETURN_EMPTY;


void
vtkBYUReader::SetReadTexture(arg1)
		int 	arg1
		CODE:
		THIS->SetReadTexture(arg1);
		XSRETURN_EMPTY;


void
vtkBYUReader::SetScalarFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetScalarFileName(arg1);
		XSRETURN_EMPTY;


void
vtkBYUReader::SetTextureFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetTextureFileName(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::BYUWriter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkBYUWriter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


char *
vtkBYUWriter::GetDisplacementFileName()
		CODE:
		RETVAL = THIS->GetDisplacementFileName();
		OUTPUT:
		RETVAL


char *
vtkBYUWriter::GetGeometryFileName()
		CODE:
		RETVAL = THIS->GetGeometryFileName();
		OUTPUT:
		RETVAL


char *
vtkBYUWriter::GetScalarFileName()
		CODE:
		RETVAL = THIS->GetScalarFileName();
		OUTPUT:
		RETVAL


char *
vtkBYUWriter::GetTextureFileName()
		CODE:
		RETVAL = THIS->GetTextureFileName();
		OUTPUT:
		RETVAL


int
vtkBYUWriter::GetWriteDisplacement()
		CODE:
		RETVAL = THIS->GetWriteDisplacement();
		OUTPUT:
		RETVAL


int
vtkBYUWriter::GetWriteScalar()
		CODE:
		RETVAL = THIS->GetWriteScalar();
		OUTPUT:
		RETVAL


int
vtkBYUWriter::GetWriteTexture()
		CODE:
		RETVAL = THIS->GetWriteTexture();
		OUTPUT:
		RETVAL


static vtkBYUWriter*
vtkBYUWriter::New()
		CODE:
		RETVAL = vtkBYUWriter::New();
		OUTPUT:
		RETVAL


void
vtkBYUWriter::SetDisplacementFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetDisplacementFileName(arg1);
		XSRETURN_EMPTY;


void
vtkBYUWriter::SetGeometryFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetGeometryFileName(arg1);
		XSRETURN_EMPTY;


void
vtkBYUWriter::SetScalarFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetScalarFileName(arg1);
		XSRETURN_EMPTY;


void
vtkBYUWriter::SetTextureFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetTextureFileName(arg1);
		XSRETURN_EMPTY;


void
vtkBYUWriter::SetWriteDisplacement(arg1)
		int 	arg1
		CODE:
		THIS->SetWriteDisplacement(arg1);
		XSRETURN_EMPTY;


void
vtkBYUWriter::SetWriteScalar(arg1)
		int 	arg1
		CODE:
		THIS->SetWriteScalar(arg1);
		XSRETURN_EMPTY;


void
vtkBYUWriter::SetWriteTexture(arg1)
		int 	arg1
		CODE:
		THIS->SetWriteTexture(arg1);
		XSRETURN_EMPTY;


void
vtkBYUWriter::WriteDisplacementOff()
		CODE:
		THIS->WriteDisplacementOff();
		XSRETURN_EMPTY;


void
vtkBYUWriter::WriteDisplacementOn()
		CODE:
		THIS->WriteDisplacementOn();
		XSRETURN_EMPTY;


void
vtkBYUWriter::WriteScalarOff()
		CODE:
		THIS->WriteScalarOff();
		XSRETURN_EMPTY;


void
vtkBYUWriter::WriteScalarOn()
		CODE:
		THIS->WriteScalarOn();
		XSRETURN_EMPTY;


void
vtkBYUWriter::WriteTextureOff()
		CODE:
		THIS->WriteTextureOff();
		XSRETURN_EMPTY;


void
vtkBYUWriter::WriteTextureOn()
		CODE:
		THIS->WriteTextureOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::DEMReader PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkDEMReader::ExecuteInformation()
		CODE:
		THIS->ExecuteInformation();
		XSRETURN_EMPTY;


int
vtkDEMReader::GetAccuracyCode()
		CODE:
		RETVAL = THIS->GetAccuracyCode();
		OUTPUT:
		RETVAL


const char *
vtkDEMReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkDEMReader::GetDEMLevel()
		CODE:
		RETVAL = THIS->GetDEMLevel();
		OUTPUT:
		RETVAL


float  *
vtkDEMReader::GetElevationBounds()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetElevationBounds();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


int
vtkDEMReader::GetElevationPattern()
		CODE:
		RETVAL = THIS->GetElevationPattern();
		OUTPUT:
		RETVAL


int
vtkDEMReader::GetElevationUnitOfMeasure()
		CODE:
		RETVAL = THIS->GetElevationUnitOfMeasure();
		OUTPUT:
		RETVAL


char *
vtkDEMReader::GetFileName()
		CODE:
		RETVAL = THIS->GetFileName();
		OUTPUT:
		RETVAL


int
vtkDEMReader::GetGroundSystem()
		CODE:
		RETVAL = THIS->GetGroundSystem();
		OUTPUT:
		RETVAL


int
vtkDEMReader::GetGroundZone()
		CODE:
		RETVAL = THIS->GetGroundZone();
		OUTPUT:
		RETVAL


float
vtkDEMReader::GetLocalRotation()
		CODE:
		RETVAL = THIS->GetLocalRotation();
		OUTPUT:
		RETVAL


char *
vtkDEMReader::GetMapLabel()
		CODE:
		RETVAL = THIS->GetMapLabel();
		OUTPUT:
		RETVAL


int
vtkDEMReader::GetPlaneUnitOfMeasure()
		CODE:
		RETVAL = THIS->GetPlaneUnitOfMeasure();
		OUTPUT:
		RETVAL


int
vtkDEMReader::GetPolygonSize()
		CODE:
		RETVAL = THIS->GetPolygonSize();
		OUTPUT:
		RETVAL


int  *
vtkDEMReader::GetProfileDimension()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetProfileDimension();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


float  *
vtkDEMReader::GetProjectionParameters()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetProjectionParameters();
		EXTEND(SP, 15);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUSHs(sv_2mortal(newSVnv(retval[6])));
		PUSHs(sv_2mortal(newSVnv(retval[7])));
		PUSHs(sv_2mortal(newSVnv(retval[8])));
		PUSHs(sv_2mortal(newSVnv(retval[9])));
		PUSHs(sv_2mortal(newSVnv(retval[10])));
		PUSHs(sv_2mortal(newSVnv(retval[11])));
		PUSHs(sv_2mortal(newSVnv(retval[12])));
		PUSHs(sv_2mortal(newSVnv(retval[13])));
		PUSHs(sv_2mortal(newSVnv(retval[14])));
		PUTBACK;
		return;


float  *
vtkDEMReader::GetSpatialResolution()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetSpatialResolution();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


static vtkDEMReader*
vtkDEMReader::New()
		CODE:
		RETVAL = vtkDEMReader::New();
		OUTPUT:
		RETVAL


void
vtkDEMReader::SetFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetFileName(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::DataObjectReader PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkDataObjectReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataObject *
vtkDataObjectReader::GetOutput(arg1 = 0)
	CASE: items == 2
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataObject";
		CODE:
		RETVAL = THIS->GetOutput(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE: items == 1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataObject";
		CODE:
		RETVAL = THIS->GetOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataObjectReader::GetOutput\n");



static vtkDataObjectReader*
vtkDataObjectReader::New()
		CODE:
		RETVAL = vtkDataObjectReader::New();
		OUTPUT:
		RETVAL


void
vtkDataObjectReader::SetOutput(arg1)
		vtkDataObject *	arg1
		CODE:
		THIS->SetOutput(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::DataObjectWriter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkDataObjectWriter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


char *
vtkDataObjectWriter::GetFieldDataName()
		CODE:
		RETVAL = THIS->GetFieldDataName();
		OUTPUT:
		RETVAL


char *
vtkDataObjectWriter::GetFileName()
		CODE:
		RETVAL = THIS->GetFileName();
		OUTPUT:
		RETVAL


int
vtkDataObjectWriter::GetFileType()
		CODE:
		RETVAL = THIS->GetFileType();
		OUTPUT:
		RETVAL


char *
vtkDataObjectWriter::GetHeader()
		CODE:
		RETVAL = THIS->GetHeader();
		OUTPUT:
		RETVAL


vtkDataObject *
vtkDataObjectWriter::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataObject";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkDataObjectWriter*
vtkDataObjectWriter::New()
		CODE:
		RETVAL = vtkDataObjectWriter::New();
		OUTPUT:
		RETVAL


void
vtkDataObjectWriter::SetFieldDataName(fieldname)
		char *	fieldname
		CODE:
		THIS->SetFieldDataName(fieldname);
		XSRETURN_EMPTY;


void
vtkDataObjectWriter::SetFileName(filename)
		const char *	filename
		CODE:
		THIS->SetFileName(filename);
		XSRETURN_EMPTY;


void
vtkDataObjectWriter::SetFileType(type)
		int 	type
		CODE:
		THIS->SetFileType(type);
		XSRETURN_EMPTY;


void
vtkDataObjectWriter::SetFileTypeToASCII()
		CODE:
		THIS->SetFileTypeToASCII();
		XSRETURN_EMPTY;


void
vtkDataObjectWriter::SetFileTypeToBinary()
		CODE:
		THIS->SetFileTypeToBinary();
		XSRETURN_EMPTY;


void
vtkDataObjectWriter::SetHeader(header)
		char *	header
		CODE:
		THIS->SetHeader(header);
		XSRETURN_EMPTY;


void
vtkDataObjectWriter::SetInput(arg1 = 0)
	CASE: items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1),"Graphics::VTK::DataObject")
		vtkDataObject *	arg1
		CODE:
		THIS->SetInput(* arg1);
		XSRETURN_EMPTY;
	CASE: items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1),"Graphics::VTK::DataObject")
		vtkDataObject *	arg1
		CODE:
		THIS->SetInput(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataObjectWriter::SetInput\n");


MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::DataReader PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkDataReader::CloseVTKFile()
		CODE:
		THIS->CloseVTKFile();
		XSRETURN_EMPTY;


const char *
vtkDataReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


char *
vtkDataReader::GetFieldDataName()
		CODE:
		RETVAL = THIS->GetFieldDataName();
		OUTPUT:
		RETVAL


const char *
vtkDataReader::GetFieldDataNameInFile(i)
		int 	i
		CODE:
		RETVAL = THIS->GetFieldDataNameInFile(i);
		OUTPUT:
		RETVAL


char *
vtkDataReader::GetFileName()
		CODE:
		RETVAL = THIS->GetFileName();
		OUTPUT:
		RETVAL


int
vtkDataReader::GetFileType()
		CODE:
		RETVAL = THIS->GetFileType();
		OUTPUT:
		RETVAL


char *
vtkDataReader::GetHeader()
		CODE:
		RETVAL = THIS->GetHeader();
		OUTPUT:
		RETVAL


char *
vtkDataReader::GetInputString()
		CODE:
		RETVAL = THIS->GetInputString();
		OUTPUT:
		RETVAL


int
vtkDataReader::GetInputStringLength()
		CODE:
		RETVAL = THIS->GetInputStringLength();
		OUTPUT:
		RETVAL


char *
vtkDataReader::GetLookupTableName()
		CODE:
		RETVAL = THIS->GetLookupTableName();
		OUTPUT:
		RETVAL


char *
vtkDataReader::GetNormalsName()
		CODE:
		RETVAL = THIS->GetNormalsName();
		OUTPUT:
		RETVAL


const char *
vtkDataReader::GetNormalsNameInFile(i)
		int 	i
		CODE:
		RETVAL = THIS->GetNormalsNameInFile(i);
		OUTPUT:
		RETVAL


int
vtkDataReader::GetNumberOfFieldDataInFile()
		CODE:
		RETVAL = THIS->GetNumberOfFieldDataInFile();
		OUTPUT:
		RETVAL


int
vtkDataReader::GetNumberOfNormalsInFile()
		CODE:
		RETVAL = THIS->GetNumberOfNormalsInFile();
		OUTPUT:
		RETVAL


int
vtkDataReader::GetNumberOfScalarsInFile()
		CODE:
		RETVAL = THIS->GetNumberOfScalarsInFile();
		OUTPUT:
		RETVAL


int
vtkDataReader::GetNumberOfTCoordsInFile()
		CODE:
		RETVAL = THIS->GetNumberOfTCoordsInFile();
		OUTPUT:
		RETVAL


int
vtkDataReader::GetNumberOfTensorsInFile()
		CODE:
		RETVAL = THIS->GetNumberOfTensorsInFile();
		OUTPUT:
		RETVAL


int
vtkDataReader::GetNumberOfVectorsInFile()
		CODE:
		RETVAL = THIS->GetNumberOfVectorsInFile();
		OUTPUT:
		RETVAL


int
vtkDataReader::GetReadFromInputString()
		CODE:
		RETVAL = THIS->GetReadFromInputString();
		OUTPUT:
		RETVAL


char *
vtkDataReader::GetScalarsName()
		CODE:
		RETVAL = THIS->GetScalarsName();
		OUTPUT:
		RETVAL


const char *
vtkDataReader::GetScalarsNameInFile(i)
		int 	i
		CODE:
		RETVAL = THIS->GetScalarsNameInFile(i);
		OUTPUT:
		RETVAL


char *
vtkDataReader::GetTCoordsName()
		CODE:
		RETVAL = THIS->GetTCoordsName();
		OUTPUT:
		RETVAL


const char *
vtkDataReader::GetTCoordsNameInFile(i)
		int 	i
		CODE:
		RETVAL = THIS->GetTCoordsNameInFile(i);
		OUTPUT:
		RETVAL


char *
vtkDataReader::GetTensorsName()
		CODE:
		RETVAL = THIS->GetTensorsName();
		OUTPUT:
		RETVAL


const char *
vtkDataReader::GetTensorsNameInFile(i)
		int 	i
		CODE:
		RETVAL = THIS->GetTensorsNameInFile(i);
		OUTPUT:
		RETVAL


char *
vtkDataReader::GetVectorsName()
		CODE:
		RETVAL = THIS->GetVectorsName();
		OUTPUT:
		RETVAL


const char *
vtkDataReader::GetVectorsNameInFile(i)
		int 	i
		CODE:
		RETVAL = THIS->GetVectorsNameInFile(i);
		OUTPUT:
		RETVAL


int
vtkDataReader::IsFilePolyData()
		CODE:
		RETVAL = THIS->IsFilePolyData();
		OUTPUT:
		RETVAL


int
vtkDataReader::IsFileRectilinearGrid()
		CODE:
		RETVAL = THIS->IsFileRectilinearGrid();
		OUTPUT:
		RETVAL


int
vtkDataReader::IsFileStructuredGrid()
		CODE:
		RETVAL = THIS->IsFileStructuredGrid();
		OUTPUT:
		RETVAL


int
vtkDataReader::IsFileStructuredPoints()
		CODE:
		RETVAL = THIS->IsFileStructuredPoints();
		OUTPUT:
		RETVAL


int
vtkDataReader::IsFileUnstructuredGrid()
		CODE:
		RETVAL = THIS->IsFileUnstructuredGrid();
		OUTPUT:
		RETVAL


int
vtkDataReader::IsFileValid(dstype)
		const char *	dstype
		CODE:
		RETVAL = THIS->IsFileValid(dstype);
		OUTPUT:
		RETVAL


static vtkDataReader*
vtkDataReader::New()
		CODE:
		RETVAL = vtkDataReader::New();
		OUTPUT:
		RETVAL


int
vtkDataReader::OpenVTKFile()
		CODE:
		RETVAL = THIS->OpenVTKFile();
		OUTPUT:
		RETVAL


int
vtkDataReader::Read(arg1 = 0)
	CASE: items == 2
		char *	arg1
		CODE:
		RETVAL = THIS->Read(arg1);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataReader::Read\n");



vtkDataArray *
vtkDataReader::ReadArray(dataType, numTuples, numComp)
		const char *	dataType
		int 	numTuples
		int 	numComp
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataArray";
		CODE:
		RETVAL = THIS->ReadArray(dataType, numTuples, numComp);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkDataReader::ReadCellData(ds, numCells)
		vtkDataSet *	ds
		int 	numCells
		CODE:
		RETVAL = THIS->ReadCellData(ds, numCells);
		OUTPUT:
		RETVAL


int
vtkDataReader::ReadCoordinates(rg, axes, numCoords)
		vtkRectilinearGrid *	rg
		int 	axes
		int 	numCoords
		CODE:
		RETVAL = THIS->ReadCoordinates(rg, axes, numCoords);
		OUTPUT:
		RETVAL


vtkFieldData *
vtkDataReader::ReadFieldData()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkFieldData";
		CODE:
		RETVAL = THIS->ReadFieldData();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkDataReader::ReadFromInputStringOff()
		CODE:
		THIS->ReadFromInputStringOff();
		XSRETURN_EMPTY;


void
vtkDataReader::ReadFromInputStringOn()
		CODE:
		THIS->ReadFromInputStringOn();
		XSRETURN_EMPTY;


int
vtkDataReader::ReadHeader()
		CODE:
		RETVAL = THIS->ReadHeader();
		OUTPUT:
		RETVAL


int
vtkDataReader::ReadPointData(ds, numPts)
		vtkDataSet *	ds
		int 	numPts
		CODE:
		RETVAL = THIS->ReadPointData(ds, numPts);
		OUTPUT:
		RETVAL


int
vtkDataReader::ReadPoints(ps, numPts)
		vtkPointSet *	ps
		int 	numPts
		CODE:
		RETVAL = THIS->ReadPoints(ps, numPts);
		OUTPUT:
		RETVAL


void
vtkDataReader::SetBinaryInputString(arg1, len)
		const char *	arg1
		int 	len
		CODE:
		THIS->SetBinaryInputString(arg1, len);
		XSRETURN_EMPTY;


void
vtkDataReader::SetFieldDataName(arg1)
		char *	arg1
		CODE:
		THIS->SetFieldDataName(arg1);
		XSRETURN_EMPTY;


void
vtkDataReader::SetFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetFileName(arg1);
		XSRETURN_EMPTY;


void
vtkDataReader::SetInputString(arg1 = 0, arg2 = 0)
	CASE: items == 3
		const char *	arg1
		int 	arg2
		CODE:
		THIS->SetInputString(arg1, arg2);
		XSRETURN_EMPTY;
	CASE: items == 2
		const char *	arg1
		CODE:
		THIS->SetInputString(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataReader::SetInputString\n");



void
vtkDataReader::SetLookupTableName(arg1)
		char *	arg1
		CODE:
		THIS->SetLookupTableName(arg1);
		XSRETURN_EMPTY;


void
vtkDataReader::SetNormalsName(arg1)
		char *	arg1
		CODE:
		THIS->SetNormalsName(arg1);
		XSRETURN_EMPTY;


void
vtkDataReader::SetReadFromInputString(arg1)
		int 	arg1
		CODE:
		THIS->SetReadFromInputString(arg1);
		XSRETURN_EMPTY;


void
vtkDataReader::SetScalarsName(arg1)
		char *	arg1
		CODE:
		THIS->SetScalarsName(arg1);
		XSRETURN_EMPTY;


void
vtkDataReader::SetTCoordsName(arg1)
		char *	arg1
		CODE:
		THIS->SetTCoordsName(arg1);
		XSRETURN_EMPTY;


void
vtkDataReader::SetTensorsName(arg1)
		char *	arg1
		CODE:
		THIS->SetTensorsName(arg1);
		XSRETURN_EMPTY;


void
vtkDataReader::SetVectorsName(arg1)
		char *	arg1
		CODE:
		THIS->SetVectorsName(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::DataSetReader PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkDataSetReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataSet *
vtkDataSetReader::GetOutput(arg1 = 0)
	CASE: items == 2
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetOutput(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE: items == 1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataSetReader::GetOutput\n");



vtkPolyData *
vtkDataSetReader::GetPolyDataOutput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPolyData";
		CODE:
		RETVAL = THIS->GetPolyDataOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkRectilinearGrid *
vtkDataSetReader::GetRectilinearGridOutput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkRectilinearGrid";
		CODE:
		RETVAL = THIS->GetRectilinearGridOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkStructuredGrid *
vtkDataSetReader::GetStructuredGridOutput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkStructuredGrid";
		CODE:
		RETVAL = THIS->GetStructuredGridOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkStructuredPoints *
vtkDataSetReader::GetStructuredPointsOutput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkStructuredPoints";
		CODE:
		RETVAL = THIS->GetStructuredPointsOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkUnstructuredGrid *
vtkDataSetReader::GetUnstructuredGridOutput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkUnstructuredGrid";
		CODE:
		RETVAL = THIS->GetUnstructuredGridOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkDataSetReader*
vtkDataSetReader::New()
		CODE:
		RETVAL = vtkDataSetReader::New();
		OUTPUT:
		RETVAL


void
vtkDataSetReader::Update()
		CODE:
		THIS->Update();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::DataSetWriter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkDataSetWriter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataSet *
vtkDataSetWriter::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkDataSetWriter*
vtkDataSetWriter::New()
		CODE:
		RETVAL = vtkDataSetWriter::New();
		OUTPUT:
		RETVAL


void
vtkDataSetWriter::SetInput(input)
		vtkDataSet *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::DataWriter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkDataWriter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


char *
vtkDataWriter::GetFieldDataName()
		CODE:
		RETVAL = THIS->GetFieldDataName();
		OUTPUT:
		RETVAL


char *
vtkDataWriter::GetFileName()
		CODE:
		RETVAL = THIS->GetFileName();
		OUTPUT:
		RETVAL


int
vtkDataWriter::GetFileType()
		CODE:
		RETVAL = THIS->GetFileType();
		OUTPUT:
		RETVAL


int
vtkDataWriter::GetFileTypeMaxValue()
		CODE:
		RETVAL = THIS->GetFileTypeMaxValue();
		OUTPUT:
		RETVAL


int
vtkDataWriter::GetFileTypeMinValue()
		CODE:
		RETVAL = THIS->GetFileTypeMinValue();
		OUTPUT:
		RETVAL


char *
vtkDataWriter::GetHeader()
		CODE:
		RETVAL = THIS->GetHeader();
		OUTPUT:
		RETVAL


char *
vtkDataWriter::GetLookupTableName()
		CODE:
		RETVAL = THIS->GetLookupTableName();
		OUTPUT:
		RETVAL


char *
vtkDataWriter::GetNormalsName()
		CODE:
		RETVAL = THIS->GetNormalsName();
		OUTPUT:
		RETVAL


char *
vtkDataWriter::GetOutputString()
		CODE:
		RETVAL = THIS->GetOutputString();
		OUTPUT:
		RETVAL


int
vtkDataWriter::GetOutputStringLength()
		CODE:
		RETVAL = THIS->GetOutputStringLength();
		OUTPUT:
		RETVAL


char *
vtkDataWriter::GetScalarsName()
		CODE:
		RETVAL = THIS->GetScalarsName();
		OUTPUT:
		RETVAL


char *
vtkDataWriter::GetTCoordsName()
		CODE:
		RETVAL = THIS->GetTCoordsName();
		OUTPUT:
		RETVAL


char *
vtkDataWriter::GetTensorsName()
		CODE:
		RETVAL = THIS->GetTensorsName();
		OUTPUT:
		RETVAL


char *
vtkDataWriter::GetVectorsName()
		CODE:
		RETVAL = THIS->GetVectorsName();
		OUTPUT:
		RETVAL


int
vtkDataWriter::GetWriteToOutputString()
		CODE:
		RETVAL = THIS->GetWriteToOutputString();
		OUTPUT:
		RETVAL


static vtkDataWriter*
vtkDataWriter::New()
		CODE:
		RETVAL = vtkDataWriter::New();
		OUTPUT:
		RETVAL


char *
vtkDataWriter::RegisterAndGetOutputString()
		CODE:
		RETVAL = THIS->RegisterAndGetOutputString();
		OUTPUT:
		RETVAL


void
vtkDataWriter::SetFieldDataName(arg1)
		char *	arg1
		CODE:
		THIS->SetFieldDataName(arg1);
		XSRETURN_EMPTY;


void
vtkDataWriter::SetFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetFileName(arg1);
		XSRETURN_EMPTY;


void
vtkDataWriter::SetFileType(arg1)
		int 	arg1
		CODE:
		THIS->SetFileType(arg1);
		XSRETURN_EMPTY;


void
vtkDataWriter::SetFileTypeToASCII()
		CODE:
		THIS->SetFileTypeToASCII();
		XSRETURN_EMPTY;


void
vtkDataWriter::SetFileTypeToBinary()
		CODE:
		THIS->SetFileTypeToBinary();
		XSRETURN_EMPTY;


void
vtkDataWriter::SetHeader(arg1)
		char *	arg1
		CODE:
		THIS->SetHeader(arg1);
		XSRETURN_EMPTY;


void
vtkDataWriter::SetLookupTableName(arg1)
		char *	arg1
		CODE:
		THIS->SetLookupTableName(arg1);
		XSRETURN_EMPTY;


void
vtkDataWriter::SetNormalsName(arg1)
		char *	arg1
		CODE:
		THIS->SetNormalsName(arg1);
		XSRETURN_EMPTY;


void
vtkDataWriter::SetScalarsName(arg1)
		char *	arg1
		CODE:
		THIS->SetScalarsName(arg1);
		XSRETURN_EMPTY;


void
vtkDataWriter::SetTCoordsName(arg1)
		char *	arg1
		CODE:
		THIS->SetTCoordsName(arg1);
		XSRETURN_EMPTY;


void
vtkDataWriter::SetTensorsName(arg1)
		char *	arg1
		CODE:
		THIS->SetTensorsName(arg1);
		XSRETURN_EMPTY;


void
vtkDataWriter::SetVectorsName(arg1)
		char *	arg1
		CODE:
		THIS->SetVectorsName(arg1);
		XSRETURN_EMPTY;


void
vtkDataWriter::SetWriteToOutputString(arg1)
		int 	arg1
		CODE:
		THIS->SetWriteToOutputString(arg1);
		XSRETURN_EMPTY;


void
vtkDataWriter::WriteToOutputStringOff()
		CODE:
		THIS->WriteToOutputStringOff();
		XSRETURN_EMPTY;


void
vtkDataWriter::WriteToOutputStringOn()
		CODE:
		THIS->WriteToOutputStringOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::EnSight6BinaryReader PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkEnSight6BinaryReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkEnSight6BinaryReader*
vtkEnSight6BinaryReader::New()
		CODE:
		RETVAL = vtkEnSight6BinaryReader::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::EnSight6Reader PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkEnSight6Reader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkEnSight6Reader*
vtkEnSight6Reader::New()
		CODE:
		RETVAL = vtkEnSight6Reader::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::EnSightGoldBinaryReader PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkEnSightGoldBinaryReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkEnSightGoldBinaryReader*
vtkEnSightGoldBinaryReader::New()
		CODE:
		RETVAL = vtkEnSightGoldBinaryReader::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::EnSightGoldReader PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkEnSightGoldReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkEnSightGoldReader*
vtkEnSightGoldReader::New()
		CODE:
		RETVAL = vtkEnSightGoldReader::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::EnSightReader PREFIX = vtk

PROTOTYPES: DISABLE



char *
vtkEnSightReader::GetCaseFileName()
		CODE:
		RETVAL = THIS->GetCaseFileName();
		OUTPUT:
		RETVAL


const char *
vtkEnSightReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


char *
vtkEnSightReader::GetComplexDescription(n)
		int 	n
		CODE:
		RETVAL = THIS->GetComplexDescription(n);
		OUTPUT:
		RETVAL


int
vtkEnSightReader::GetComplexVariableType(n)
		int 	n
		CODE:
		RETVAL = THIS->GetComplexVariableType(n);
		OUTPUT:
		RETVAL


char *
vtkEnSightReader::GetDescription(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		RETVAL = THIS->GetDescription(arg1, arg2);
		OUTPUT:
		RETVAL
	CASE: items == 2
		int 	arg1
		CODE:
		RETVAL = THIS->GetDescription(arg1);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkEnSightReader::GetDescription\n");



char *
vtkEnSightReader::GetFilePath()
		CODE:
		RETVAL = THIS->GetFilePath();
		OUTPUT:
		RETVAL


float
vtkEnSightReader::GetMaximumTimeValue()
		CODE:
		RETVAL = THIS->GetMaximumTimeValue();
		OUTPUT:
		RETVAL


float
vtkEnSightReader::GetMinimumTimeValue()
		CODE:
		RETVAL = THIS->GetMinimumTimeValue();
		OUTPUT:
		RETVAL


int
vtkEnSightReader::GetNumberOfComplexScalarsPerElement()
		CODE:
		RETVAL = THIS->GetNumberOfComplexScalarsPerElement();
		OUTPUT:
		RETVAL


int
vtkEnSightReader::GetNumberOfComplexScalarsPerNode()
		CODE:
		RETVAL = THIS->GetNumberOfComplexScalarsPerNode();
		OUTPUT:
		RETVAL


int
vtkEnSightReader::GetNumberOfComplexVariables()
		CODE:
		RETVAL = THIS->GetNumberOfComplexVariables();
		OUTPUT:
		RETVAL


int
vtkEnSightReader::GetNumberOfComplexVectorsPerElement()
		CODE:
		RETVAL = THIS->GetNumberOfComplexVectorsPerElement();
		OUTPUT:
		RETVAL


int
vtkEnSightReader::GetNumberOfComplexVectorsPerNode()
		CODE:
		RETVAL = THIS->GetNumberOfComplexVectorsPerNode();
		OUTPUT:
		RETVAL


int
vtkEnSightReader::GetNumberOfScalarsPerElement()
		CODE:
		RETVAL = THIS->GetNumberOfScalarsPerElement();
		OUTPUT:
		RETVAL


int
vtkEnSightReader::GetNumberOfScalarsPerMeasuredNode()
		CODE:
		RETVAL = THIS->GetNumberOfScalarsPerMeasuredNode();
		OUTPUT:
		RETVAL


int
vtkEnSightReader::GetNumberOfScalarsPerNode()
		CODE:
		RETVAL = THIS->GetNumberOfScalarsPerNode();
		OUTPUT:
		RETVAL


int
vtkEnSightReader::GetNumberOfTensorsSymmPerElement()
		CODE:
		RETVAL = THIS->GetNumberOfTensorsSymmPerElement();
		OUTPUT:
		RETVAL


int
vtkEnSightReader::GetNumberOfTensorsSymmPerNode()
		CODE:
		RETVAL = THIS->GetNumberOfTensorsSymmPerNode();
		OUTPUT:
		RETVAL


int
vtkEnSightReader::GetNumberOfVariables(arg1 = 0)
	CASE: items == 2
		int 	arg1
		CODE:
		RETVAL = THIS->GetNumberOfVariables(arg1);
		OUTPUT:
		RETVAL
	CASE: items == 1
		CODE:
		RETVAL = THIS->GetNumberOfVariables();
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkEnSightReader::GetNumberOfVariables\n");



int
vtkEnSightReader::GetNumberOfVectorsPerElement()
		CODE:
		RETVAL = THIS->GetNumberOfVectorsPerElement();
		OUTPUT:
		RETVAL


int
vtkEnSightReader::GetNumberOfVectorsPerMeasuredNode()
		CODE:
		RETVAL = THIS->GetNumberOfVectorsPerMeasuredNode();
		OUTPUT:
		RETVAL


int
vtkEnSightReader::GetNumberOfVectorsPerNode()
		CODE:
		RETVAL = THIS->GetNumberOfVectorsPerNode();
		OUTPUT:
		RETVAL


float
vtkEnSightReader::GetTimeValue()
		CODE:
		RETVAL = THIS->GetTimeValue();
		OUTPUT:
		RETVAL


int
vtkEnSightReader::GetVariableType(n)
		int 	n
		CODE:
		RETVAL = THIS->GetVariableType(n);
		OUTPUT:
		RETVAL


void
vtkEnSightReader::SetCaseFileName(fileName)
		char *	fileName
		CODE:
		THIS->SetCaseFileName(fileName);
		XSRETURN_EMPTY;


void
vtkEnSightReader::SetFilePath(arg1)
		char *	arg1
		CODE:
		THIS->SetFilePath(arg1);
		XSRETURN_EMPTY;


void
vtkEnSightReader::SetTimeValue(arg1)
		float 	arg1
		CODE:
		THIS->SetTimeValue(arg1);
		XSRETURN_EMPTY;


void
vtkEnSightReader::Update()
		CODE:
		THIS->Update();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::GESignaReader PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkGESignaReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkGESignaReader*
vtkGESignaReader::New()
		CODE:
		RETVAL = vtkGESignaReader::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::GenericEnSightReader PREFIX = vtk

PROTOTYPES: DISABLE



char *
vtkGenericEnSightReader::GetCaseFileName()
		CODE:
		RETVAL = THIS->GetCaseFileName();
		OUTPUT:
		RETVAL


const char *
vtkGenericEnSightReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


char *
vtkGenericEnSightReader::GetComplexDescription(n)
		int 	n
		CODE:
		RETVAL = THIS->GetComplexDescription(n);
		OUTPUT:
		RETVAL


int
vtkGenericEnSightReader::GetComplexVariableType(n)
		int 	n
		CODE:
		RETVAL = THIS->GetComplexVariableType(n);
		OUTPUT:
		RETVAL


char *
vtkGenericEnSightReader::GetDescription(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		RETVAL = THIS->GetDescription(arg1, arg2);
		OUTPUT:
		RETVAL
	CASE: items == 2
		int 	arg1
		CODE:
		RETVAL = THIS->GetDescription(arg1);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkGenericEnSightReader::GetDescription\n");



char *
vtkGenericEnSightReader::GetFilePath()
		CODE:
		RETVAL = THIS->GetFilePath();
		OUTPUT:
		RETVAL


float
vtkGenericEnSightReader::GetMaximumTimeValue()
		CODE:
		RETVAL = THIS->GetMaximumTimeValue();
		OUTPUT:
		RETVAL


float
vtkGenericEnSightReader::GetMinimumTimeValue()
		CODE:
		RETVAL = THIS->GetMinimumTimeValue();
		OUTPUT:
		RETVAL


int
vtkGenericEnSightReader::GetNumberOfComplexScalarsPerElement()
		CODE:
		RETVAL = THIS->GetNumberOfComplexScalarsPerElement();
		OUTPUT:
		RETVAL


int
vtkGenericEnSightReader::GetNumberOfComplexScalarsPerNode()
		CODE:
		RETVAL = THIS->GetNumberOfComplexScalarsPerNode();
		OUTPUT:
		RETVAL


int
vtkGenericEnSightReader::GetNumberOfComplexVectorsPerElement()
		CODE:
		RETVAL = THIS->GetNumberOfComplexVectorsPerElement();
		OUTPUT:
		RETVAL


int
vtkGenericEnSightReader::GetNumberOfComplexVectorsPerNode()
		CODE:
		RETVAL = THIS->GetNumberOfComplexVectorsPerNode();
		OUTPUT:
		RETVAL


int
vtkGenericEnSightReader::GetNumberOfScalarsPerElement()
		CODE:
		RETVAL = THIS->GetNumberOfScalarsPerElement();
		OUTPUT:
		RETVAL


int
vtkGenericEnSightReader::GetNumberOfScalarsPerMeasuredNode()
		CODE:
		RETVAL = THIS->GetNumberOfScalarsPerMeasuredNode();
		OUTPUT:
		RETVAL


int
vtkGenericEnSightReader::GetNumberOfScalarsPerNode()
		CODE:
		RETVAL = THIS->GetNumberOfScalarsPerNode();
		OUTPUT:
		RETVAL


int
vtkGenericEnSightReader::GetNumberOfTensorsSymmPerElement()
		CODE:
		RETVAL = THIS->GetNumberOfTensorsSymmPerElement();
		OUTPUT:
		RETVAL


int
vtkGenericEnSightReader::GetNumberOfTensorsSymmPerNode()
		CODE:
		RETVAL = THIS->GetNumberOfTensorsSymmPerNode();
		OUTPUT:
		RETVAL


int
vtkGenericEnSightReader::GetNumberOfVariables(type)
		int 	type
		CODE:
		RETVAL = THIS->GetNumberOfVariables(type);
		OUTPUT:
		RETVAL


int
vtkGenericEnSightReader::GetNumberOfVectorsPerElement()
		CODE:
		RETVAL = THIS->GetNumberOfVectorsPerElement();
		OUTPUT:
		RETVAL


int
vtkGenericEnSightReader::GetNumberOfVectorsPerMeasuredNode()
		CODE:
		RETVAL = THIS->GetNumberOfVectorsPerMeasuredNode();
		OUTPUT:
		RETVAL


int
vtkGenericEnSightReader::GetNumberOfVectorsPerNode()
		CODE:
		RETVAL = THIS->GetNumberOfVectorsPerNode();
		OUTPUT:
		RETVAL


float
vtkGenericEnSightReader::GetTimeValue()
		CODE:
		RETVAL = THIS->GetTimeValue();
		OUTPUT:
		RETVAL


int
vtkGenericEnSightReader::GetVariableType(n)
		int 	n
		CODE:
		RETVAL = THIS->GetVariableType(n);
		OUTPUT:
		RETVAL


static vtkGenericEnSightReader*
vtkGenericEnSightReader::New()
		CODE:
		RETVAL = vtkGenericEnSightReader::New();
		OUTPUT:
		RETVAL


void
vtkGenericEnSightReader::SetCaseFileName(fileName)
		char *	fileName
		CODE:
		THIS->SetCaseFileName(fileName);
		XSRETURN_EMPTY;


void
vtkGenericEnSightReader::SetFilePath(arg1)
		char *	arg1
		CODE:
		THIS->SetFilePath(arg1);
		XSRETURN_EMPTY;


void
vtkGenericEnSightReader::SetTimeValue(arg1)
		float 	arg1
		CODE:
		THIS->SetTimeValue(arg1);
		XSRETURN_EMPTY;


void
vtkGenericEnSightReader::Update()
		CODE:
		THIS->Update();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::IVWriter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkIVWriter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkIVWriter*
vtkIVWriter::New()
		CODE:
		RETVAL = vtkIVWriter::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::ImageReader PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImageReader::ComputeInternalFileName(slice)
		int 	slice
		CODE:
		THIS->ComputeInternalFileName(slice);
		XSRETURN_EMPTY;


void
vtkImageReader::FileLowerLeftOff()
		CODE:
		THIS->FileLowerLeftOff();
		XSRETURN_EMPTY;


void
vtkImageReader::FileLowerLeftOn()
		CODE:
		THIS->FileLowerLeftOn();
		XSRETURN_EMPTY;


const char *
vtkImageReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageReader::GetDataByteOrder()
		CODE:
		RETVAL = THIS->GetDataByteOrder();
		OUTPUT:
		RETVAL


const char *
vtkImageReader::GetDataByteOrderAsString()
		CODE:
		RETVAL = THIS->GetDataByteOrderAsString();
		OUTPUT:
		RETVAL


int  *
vtkImageReader::GetDataExtent()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDataExtent();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;


unsigned short
vtkImageReader::GetDataMask()
		CODE:
		RETVAL = THIS->GetDataMask();
		OUTPUT:
		RETVAL


float  *
vtkImageReader::GetDataOrigin()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDataOrigin();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int
vtkImageReader::GetDataScalarType()
		CODE:
		RETVAL = THIS->GetDataScalarType();
		OUTPUT:
		RETVAL


float  *
vtkImageReader::GetDataSpacing()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDataSpacing();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int  *
vtkImageReader::GetDataVOI()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDataVOI();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;


int
vtkImageReader::GetFileDimensionality()
		CODE:
		RETVAL = THIS->GetFileDimensionality();
		OUTPUT:
		RETVAL


int
vtkImageReader::GetFileLowerLeft()
		CODE:
		RETVAL = THIS->GetFileLowerLeft();
		OUTPUT:
		RETVAL


char *
vtkImageReader::GetFileName()
		CODE:
		RETVAL = THIS->GetFileName();
		OUTPUT:
		RETVAL


int
vtkImageReader::GetFileNameSliceOffset()
		CODE:
		RETVAL = THIS->GetFileNameSliceOffset();
		OUTPUT:
		RETVAL


int
vtkImageReader::GetFileNameSliceSpacing()
		CODE:
		RETVAL = THIS->GetFileNameSliceSpacing();
		OUTPUT:
		RETVAL


char *
vtkImageReader::GetFilePattern()
		CODE:
		RETVAL = THIS->GetFilePattern();
		OUTPUT:
		RETVAL


char *
vtkImageReader::GetFilePrefix()
		CODE:
		RETVAL = THIS->GetFilePrefix();
		OUTPUT:
		RETVAL


unsigned long
vtkImageReader::GetHeaderSize(arg1 = 0)
	CASE: items == 2
		int 	arg1
		CODE:
		RETVAL = THIS->GetHeaderSize(arg1);
		OUTPUT:
		RETVAL
	CASE: items == 1
		CODE:
		RETVAL = THIS->GetHeaderSize();
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageReader::GetHeaderSize\n");



char *
vtkImageReader::GetInternalFileName()
		CODE:
		RETVAL = THIS->GetInternalFileName();
		OUTPUT:
		RETVAL


int
vtkImageReader::GetNumberOfScalarComponents()
		CODE:
		RETVAL = THIS->GetNumberOfScalarComponents();
		OUTPUT:
		RETVAL


int
vtkImageReader::GetSwapBytes()
		CODE:
		RETVAL = THIS->GetSwapBytes();
		OUTPUT:
		RETVAL


vtkTransform *
vtkImageReader::GetTransform()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkTransform";
		CODE:
		RETVAL = THIS->GetTransform();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkImageReader*
vtkImageReader::New()
		CODE:
		RETVAL = vtkImageReader::New();
		OUTPUT:
		RETVAL


void
vtkImageReader::OpenFile()
		CODE:
		THIS->OpenFile();
		XSRETURN_EMPTY;


void
vtkImageReader::SetDataByteOrder(arg1)
		int 	arg1
		CODE:
		THIS->SetDataByteOrder(arg1);
		XSRETURN_EMPTY;


void
vtkImageReader::SetDataByteOrderToBigEndian()
		CODE:
		THIS->SetDataByteOrderToBigEndian();
		XSRETURN_EMPTY;


void
vtkImageReader::SetDataByteOrderToLittleEndian()
		CODE:
		THIS->SetDataByteOrderToLittleEndian();
		XSRETURN_EMPTY;


void
vtkImageReader::SetDataExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetDataExtent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageReader::SetDataExtent\n");



void
vtkImageReader::SetDataMask(val)
		int 	val
		CODE:
		THIS->SetDataMask(val);
		XSRETURN_EMPTY;


void
vtkImageReader::SetDataOrigin(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetDataOrigin(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageReader::SetDataOrigin\n");



void
vtkImageReader::SetDataScalarType(type)
		int 	type
		CODE:
		THIS->SetDataScalarType(type);
		XSRETURN_EMPTY;


void
vtkImageReader::SetDataScalarTypeToDouble()
		CODE:
		THIS->SetDataScalarTypeToDouble();
		XSRETURN_EMPTY;


void
vtkImageReader::SetDataScalarTypeToFloat()
		CODE:
		THIS->SetDataScalarTypeToFloat();
		XSRETURN_EMPTY;


void
vtkImageReader::SetDataScalarTypeToInt()
		CODE:
		THIS->SetDataScalarTypeToInt();
		XSRETURN_EMPTY;


void
vtkImageReader::SetDataScalarTypeToShort()
		CODE:
		THIS->SetDataScalarTypeToShort();
		XSRETURN_EMPTY;


void
vtkImageReader::SetDataScalarTypeToUnsignedChar()
		CODE:
		THIS->SetDataScalarTypeToUnsignedChar();
		XSRETURN_EMPTY;


void
vtkImageReader::SetDataScalarTypeToUnsignedShort()
		CODE:
		THIS->SetDataScalarTypeToUnsignedShort();
		XSRETURN_EMPTY;


void
vtkImageReader::SetDataSpacing(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetDataSpacing(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageReader::SetDataSpacing\n");



void
vtkImageReader::SetDataVOI(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetDataVOI(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageReader::SetDataVOI\n");



void
vtkImageReader::SetFileDimensionality(arg1)
		int 	arg1
		CODE:
		THIS->SetFileDimensionality(arg1);
		XSRETURN_EMPTY;


void
vtkImageReader::SetFileLowerLeft(arg1)
		int 	arg1
		CODE:
		THIS->SetFileLowerLeft(arg1);
		XSRETURN_EMPTY;


void
vtkImageReader::SetFileName(arg1)
		const char *	arg1
		CODE:
		THIS->SetFileName(arg1);
		XSRETURN_EMPTY;


void
vtkImageReader::SetFileNameSliceOffset(arg1)
		int 	arg1
		CODE:
		THIS->SetFileNameSliceOffset(arg1);
		XSRETURN_EMPTY;


void
vtkImageReader::SetFileNameSliceSpacing(arg1)
		int 	arg1
		CODE:
		THIS->SetFileNameSliceSpacing(arg1);
		XSRETURN_EMPTY;


void
vtkImageReader::SetFilePattern(arg1)
		const char *	arg1
		CODE:
		THIS->SetFilePattern(arg1);
		XSRETURN_EMPTY;


void
vtkImageReader::SetFilePrefix(arg1)
		const char *	arg1
		CODE:
		THIS->SetFilePrefix(arg1);
		XSRETURN_EMPTY;


void
vtkImageReader::SetHeaderSize(size)
		unsigned long 	size
		CODE:
		THIS->SetHeaderSize(size);
		XSRETURN_EMPTY;


void
vtkImageReader::SetNumberOfScalarComponents(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfScalarComponents(arg1);
		XSRETURN_EMPTY;


void
vtkImageReader::SetSwapBytes(arg1)
		int 	arg1
		CODE:
		THIS->SetSwapBytes(arg1);
		XSRETURN_EMPTY;


void
vtkImageReader::SetTransform(arg1)
		vtkTransform *	arg1
		CODE:
		THIS->SetTransform(arg1);
		XSRETURN_EMPTY;


void
vtkImageReader::SwapBytesOff()
		CODE:
		THIS->SwapBytesOff();
		XSRETURN_EMPTY;


void
vtkImageReader::SwapBytesOn()
		CODE:
		THIS->SwapBytesOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::ImageReader2 PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImageReader2::ComputeInternalFileName(slice)
		int 	slice
		CODE:
		THIS->ComputeInternalFileName(slice);
		XSRETURN_EMPTY;


void
vtkImageReader2::FileLowerLeftOff()
		CODE:
		THIS->FileLowerLeftOff();
		XSRETURN_EMPTY;


void
vtkImageReader2::FileLowerLeftOn()
		CODE:
		THIS->FileLowerLeftOn();
		XSRETURN_EMPTY;


const char *
vtkImageReader2::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageReader2::GetDataByteOrder()
		CODE:
		RETVAL = THIS->GetDataByteOrder();
		OUTPUT:
		RETVAL


const char *
vtkImageReader2::GetDataByteOrderAsString()
		CODE:
		RETVAL = THIS->GetDataByteOrderAsString();
		OUTPUT:
		RETVAL


int  *
vtkImageReader2::GetDataExtent()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDataExtent();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;


float  *
vtkImageReader2::GetDataOrigin()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDataOrigin();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int
vtkImageReader2::GetDataScalarType()
		CODE:
		RETVAL = THIS->GetDataScalarType();
		OUTPUT:
		RETVAL


float  *
vtkImageReader2::GetDataSpacing()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDataSpacing();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int
vtkImageReader2::GetFileDimensionality()
		CODE:
		RETVAL = THIS->GetFileDimensionality();
		OUTPUT:
		RETVAL


int
vtkImageReader2::GetFileLowerLeft()
		CODE:
		RETVAL = THIS->GetFileLowerLeft();
		OUTPUT:
		RETVAL


char *
vtkImageReader2::GetFileName()
		CODE:
		RETVAL = THIS->GetFileName();
		OUTPUT:
		RETVAL


char *
vtkImageReader2::GetFilePattern()
		CODE:
		RETVAL = THIS->GetFilePattern();
		OUTPUT:
		RETVAL


char *
vtkImageReader2::GetFilePrefix()
		CODE:
		RETVAL = THIS->GetFilePrefix();
		OUTPUT:
		RETVAL


int
vtkImageReader2::GetHeaderSize(arg1 = 0)
	CASE: items == 2
		int 	arg1
		CODE:
		RETVAL = THIS->GetHeaderSize(arg1);
		OUTPUT:
		RETVAL
	CASE: items == 1
		CODE:
		RETVAL = THIS->GetHeaderSize();
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageReader2::GetHeaderSize\n");



char *
vtkImageReader2::GetInternalFileName()
		CODE:
		RETVAL = THIS->GetInternalFileName();
		OUTPUT:
		RETVAL


int
vtkImageReader2::GetNumberOfScalarComponents()
		CODE:
		RETVAL = THIS->GetNumberOfScalarComponents();
		OUTPUT:
		RETVAL


int
vtkImageReader2::GetSwapBytes()
		CODE:
		RETVAL = THIS->GetSwapBytes();
		OUTPUT:
		RETVAL


static vtkImageReader2*
vtkImageReader2::New()
		CODE:
		RETVAL = vtkImageReader2::New();
		OUTPUT:
		RETVAL


void
vtkImageReader2::OpenFile()
		CODE:
		THIS->OpenFile();
		XSRETURN_EMPTY;


void
vtkImageReader2::SeekFile(i, j, k)
		int 	i
		int 	j
		int 	k
		CODE:
		THIS->SeekFile(i, j, k);
		XSRETURN_EMPTY;


void
vtkImageReader2::SetDataByteOrder(arg1)
		int 	arg1
		CODE:
		THIS->SetDataByteOrder(arg1);
		XSRETURN_EMPTY;


void
vtkImageReader2::SetDataByteOrderToBigEndian()
		CODE:
		THIS->SetDataByteOrderToBigEndian();
		XSRETURN_EMPTY;


void
vtkImageReader2::SetDataByteOrderToLittleEndian()
		CODE:
		THIS->SetDataByteOrderToLittleEndian();
		XSRETURN_EMPTY;


void
vtkImageReader2::SetDataExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetDataExtent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageReader2::SetDataExtent\n");



void
vtkImageReader2::SetDataOrigin(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetDataOrigin(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageReader2::SetDataOrigin\n");



void
vtkImageReader2::SetDataScalarType(type)
		int 	type
		CODE:
		THIS->SetDataScalarType(type);
		XSRETURN_EMPTY;


void
vtkImageReader2::SetDataScalarTypeToDouble()
		CODE:
		THIS->SetDataScalarTypeToDouble();
		XSRETURN_EMPTY;


void
vtkImageReader2::SetDataScalarTypeToFloat()
		CODE:
		THIS->SetDataScalarTypeToFloat();
		XSRETURN_EMPTY;


void
vtkImageReader2::SetDataScalarTypeToInt()
		CODE:
		THIS->SetDataScalarTypeToInt();
		XSRETURN_EMPTY;


void
vtkImageReader2::SetDataScalarTypeToShort()
		CODE:
		THIS->SetDataScalarTypeToShort();
		XSRETURN_EMPTY;


void
vtkImageReader2::SetDataScalarTypeToUnsignedChar()
		CODE:
		THIS->SetDataScalarTypeToUnsignedChar();
		XSRETURN_EMPTY;


void
vtkImageReader2::SetDataScalarTypeToUnsignedShort()
		CODE:
		THIS->SetDataScalarTypeToUnsignedShort();
		XSRETURN_EMPTY;


void
vtkImageReader2::SetDataSpacing(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetDataSpacing(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageReader2::SetDataSpacing\n");



void
vtkImageReader2::SetFileDimensionality(arg1)
		int 	arg1
		CODE:
		THIS->SetFileDimensionality(arg1);
		XSRETURN_EMPTY;


void
vtkImageReader2::SetFileLowerLeft(arg1)
		int 	arg1
		CODE:
		THIS->SetFileLowerLeft(arg1);
		XSRETURN_EMPTY;


void
vtkImageReader2::SetFileName(arg1)
		const char *	arg1
		CODE:
		THIS->SetFileName(arg1);
		XSRETURN_EMPTY;


void
vtkImageReader2::SetFilePattern(arg1)
		const char *	arg1
		CODE:
		THIS->SetFilePattern(arg1);
		XSRETURN_EMPTY;


void
vtkImageReader2::SetFilePrefix(arg1)
		const char *	arg1
		CODE:
		THIS->SetFilePrefix(arg1);
		XSRETURN_EMPTY;


void
vtkImageReader2::SetHeaderSize(size)
		int 	size
		CODE:
		THIS->SetHeaderSize(size);
		XSRETURN_EMPTY;


void
vtkImageReader2::SetNumberOfScalarComponents(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfScalarComponents(arg1);
		XSRETURN_EMPTY;


void
vtkImageReader2::SetSwapBytes(arg1)
		int 	arg1
		CODE:
		THIS->SetSwapBytes(arg1);
		XSRETURN_EMPTY;


void
vtkImageReader2::SwapBytesOff()
		CODE:
		THIS->SwapBytesOff();
		XSRETURN_EMPTY;


void
vtkImageReader2::SwapBytesOn()
		CODE:
		THIS->SwapBytesOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::ImageWriter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkImageWriter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageWriter::GetFileDimensionality()
		CODE:
		RETVAL = THIS->GetFileDimensionality();
		OUTPUT:
		RETVAL


char *
vtkImageWriter::GetFileName()
		CODE:
		RETVAL = THIS->GetFileName();
		OUTPUT:
		RETVAL


char *
vtkImageWriter::GetFilePattern()
		CODE:
		RETVAL = THIS->GetFilePattern();
		OUTPUT:
		RETVAL


char *
vtkImageWriter::GetFilePrefix()
		CODE:
		RETVAL = THIS->GetFilePrefix();
		OUTPUT:
		RETVAL


vtkImageData *
vtkImageWriter::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageData";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkImageWriter*
vtkImageWriter::New()
		CODE:
		RETVAL = vtkImageWriter::New();
		OUTPUT:
		RETVAL


void
vtkImageWriter::SetFileDimensionality(arg1)
		int 	arg1
		CODE:
		THIS->SetFileDimensionality(arg1);
		XSRETURN_EMPTY;


void
vtkImageWriter::SetFileName(arg1)
		const char *	arg1
		CODE:
		THIS->SetFileName(arg1);
		XSRETURN_EMPTY;


void
vtkImageWriter::SetFilePattern(filePattern)
		const char *	filePattern
		CODE:
		THIS->SetFilePattern(filePattern);
		XSRETURN_EMPTY;


void
vtkImageWriter::SetFilePrefix(filePrefix)
		char *	filePrefix
		CODE:
		THIS->SetFilePrefix(filePrefix);
		XSRETURN_EMPTY;


void
vtkImageWriter::SetInput(input)
		vtkImageData *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;


void
vtkImageWriter::Write()
		CODE:
		THIS->Write();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::JPEGReader PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkJPEGReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkJPEGReader*
vtkJPEGReader::New()
		CODE:
		RETVAL = vtkJPEGReader::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::JPEGWriter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkJPEGWriter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


unsigned int
vtkJPEGWriter::GetProgressive()
		CODE:
		RETVAL = THIS->GetProgressive();
		OUTPUT:
		RETVAL


unsigned int
vtkJPEGWriter::GetQuality()
		CODE:
		RETVAL = THIS->GetQuality();
		OUTPUT:
		RETVAL


unsigned
vtkJPEGWriter::GetQualityMaxValue()
		CODE:
		RETVAL = THIS->GetQualityMaxValue();
		OUTPUT:
		RETVAL


unsigned
vtkJPEGWriter::GetQualityMinValue()
		CODE:
		RETVAL = THIS->GetQualityMinValue();
		OUTPUT:
		RETVAL


static vtkJPEGWriter*
vtkJPEGWriter::New()
		CODE:
		RETVAL = vtkJPEGWriter::New();
		OUTPUT:
		RETVAL


void
vtkJPEGWriter::ProgressiveOff()
		CODE:
		THIS->ProgressiveOff();
		XSRETURN_EMPTY;


void
vtkJPEGWriter::ProgressiveOn()
		CODE:
		THIS->ProgressiveOn();
		XSRETURN_EMPTY;


void
vtkJPEGWriter::SetProgressive(arg1)
		unsigned int 	arg1
		CODE:
		THIS->SetProgressive(arg1);
		XSRETURN_EMPTY;


void
vtkJPEGWriter::SetQuality(arg1)
		unsigned int 	arg1
		CODE:
		THIS->SetQuality(arg1);
		XSRETURN_EMPTY;


void
vtkJPEGWriter::Write()
		CODE:
		THIS->Write();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::MCubesReader PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkMCubesReader::CreateDefaultLocator()
		CODE:
		THIS->CreateDefaultLocator();
		XSRETURN_EMPTY;


void
vtkMCubesReader::FlipNormalsOff()
		CODE:
		THIS->FlipNormalsOff();
		XSRETURN_EMPTY;


void
vtkMCubesReader::FlipNormalsOn()
		CODE:
		THIS->FlipNormalsOn();
		XSRETURN_EMPTY;


const char *
vtkMCubesReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkMCubesReader::GetDataByteOrder()
		CODE:
		RETVAL = THIS->GetDataByteOrder();
		OUTPUT:
		RETVAL


const char *
vtkMCubesReader::GetDataByteOrderAsString()
		CODE:
		RETVAL = THIS->GetDataByteOrderAsString();
		OUTPUT:
		RETVAL


char *
vtkMCubesReader::GetFileName()
		CODE:
		RETVAL = THIS->GetFileName();
		OUTPUT:
		RETVAL


int
vtkMCubesReader::GetFlipNormals()
		CODE:
		RETVAL = THIS->GetFlipNormals();
		OUTPUT:
		RETVAL


int
vtkMCubesReader::GetHeaderSize()
		CODE:
		RETVAL = THIS->GetHeaderSize();
		OUTPUT:
		RETVAL


int
vtkMCubesReader::GetHeaderSizeMaxValue()
		CODE:
		RETVAL = THIS->GetHeaderSizeMaxValue();
		OUTPUT:
		RETVAL


int
vtkMCubesReader::GetHeaderSizeMinValue()
		CODE:
		RETVAL = THIS->GetHeaderSizeMinValue();
		OUTPUT:
		RETVAL


char *
vtkMCubesReader::GetLimitsFileName()
		CODE:
		RETVAL = THIS->GetLimitsFileName();
		OUTPUT:
		RETVAL


vtkPointLocator *
vtkMCubesReader::GetLocator()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPointLocator";
		CODE:
		RETVAL = THIS->GetLocator();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkMCubesReader::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkMCubesReader::GetNormals()
		CODE:
		RETVAL = THIS->GetNormals();
		OUTPUT:
		RETVAL


int
vtkMCubesReader::GetSwapBytes()
		CODE:
		RETVAL = THIS->GetSwapBytes();
		OUTPUT:
		RETVAL


static vtkMCubesReader*
vtkMCubesReader::New()
		CODE:
		RETVAL = vtkMCubesReader::New();
		OUTPUT:
		RETVAL


void
vtkMCubesReader::NormalsOff()
		CODE:
		THIS->NormalsOff();
		XSRETURN_EMPTY;


void
vtkMCubesReader::NormalsOn()
		CODE:
		THIS->NormalsOn();
		XSRETURN_EMPTY;


void
vtkMCubesReader::SetDataByteOrder(arg1)
		int 	arg1
		CODE:
		THIS->SetDataByteOrder(arg1);
		XSRETURN_EMPTY;


void
vtkMCubesReader::SetDataByteOrderToBigEndian()
		CODE:
		THIS->SetDataByteOrderToBigEndian();
		XSRETURN_EMPTY;


void
vtkMCubesReader::SetDataByteOrderToLittleEndian()
		CODE:
		THIS->SetDataByteOrderToLittleEndian();
		XSRETURN_EMPTY;


void
vtkMCubesReader::SetFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetFileName(arg1);
		XSRETURN_EMPTY;


void
vtkMCubesReader::SetFlipNormals(arg1)
		int 	arg1
		CODE:
		THIS->SetFlipNormals(arg1);
		XSRETURN_EMPTY;


void
vtkMCubesReader::SetHeaderSize(arg1)
		int 	arg1
		CODE:
		THIS->SetHeaderSize(arg1);
		XSRETURN_EMPTY;


void
vtkMCubesReader::SetLimitsFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetLimitsFileName(arg1);
		XSRETURN_EMPTY;


void
vtkMCubesReader::SetLocator(locator)
		vtkPointLocator *	locator
		CODE:
		THIS->SetLocator(locator);
		XSRETURN_EMPTY;


void
vtkMCubesReader::SetNormals(arg1)
		int 	arg1
		CODE:
		THIS->SetNormals(arg1);
		XSRETURN_EMPTY;


void
vtkMCubesReader::SetSwapBytes(arg1)
		int 	arg1
		CODE:
		THIS->SetSwapBytes(arg1);
		XSRETURN_EMPTY;


void
vtkMCubesReader::SwapBytesOff()
		CODE:
		THIS->SwapBytesOff();
		XSRETURN_EMPTY;


void
vtkMCubesReader::SwapBytesOn()
		CODE:
		THIS->SwapBytesOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::MCubesWriter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkMCubesWriter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


char *
vtkMCubesWriter::GetLimitsFileName()
		CODE:
		RETVAL = THIS->GetLimitsFileName();
		OUTPUT:
		RETVAL


static vtkMCubesWriter*
vtkMCubesWriter::New()
		CODE:
		RETVAL = vtkMCubesWriter::New();
		OUTPUT:
		RETVAL


void
vtkMCubesWriter::SetLimitsFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetLimitsFileName(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::OBJReader PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkOBJReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


char *
vtkOBJReader::GetFileName()
		CODE:
		RETVAL = THIS->GetFileName();
		OUTPUT:
		RETVAL


static vtkOBJReader*
vtkOBJReader::New()
		CODE:
		RETVAL = vtkOBJReader::New();
		OUTPUT:
		RETVAL


void
vtkOBJReader::SetFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetFileName(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::PLOT3DReader PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkPLOT3DReader::AddFunction(functionNumber)
		int 	functionNumber
		CODE:
		THIS->AddFunction(functionNumber);
		XSRETURN_EMPTY;


float
vtkPLOT3DReader::GetAlpha()
		CODE:
		RETVAL = THIS->GetAlpha();
		OUTPUT:
		RETVAL


const char *
vtkPLOT3DReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkPLOT3DReader::GetFileFormat()
		CODE:
		RETVAL = THIS->GetFileFormat();
		OUTPUT:
		RETVAL


int
vtkPLOT3DReader::GetFileFormatMaxValue()
		CODE:
		RETVAL = THIS->GetFileFormatMaxValue();
		OUTPUT:
		RETVAL


int
vtkPLOT3DReader::GetFileFormatMinValue()
		CODE:
		RETVAL = THIS->GetFileFormatMinValue();
		OUTPUT:
		RETVAL


float
vtkPLOT3DReader::GetFsmach()
		CODE:
		RETVAL = THIS->GetFsmach();
		OUTPUT:
		RETVAL


char *
vtkPLOT3DReader::GetFunctionFileName()
		CODE:
		RETVAL = THIS->GetFunctionFileName();
		OUTPUT:
		RETVAL


float
vtkPLOT3DReader::GetGamma()
		CODE:
		RETVAL = THIS->GetGamma();
		OUTPUT:
		RETVAL


int
vtkPLOT3DReader::GetGridNumber()
		CODE:
		RETVAL = THIS->GetGridNumber();
		OUTPUT:
		RETVAL


int
vtkPLOT3DReader::GetNumberOfGrids()
		CODE:
		RETVAL = THIS->GetNumberOfGrids();
		OUTPUT:
		RETVAL


char *
vtkPLOT3DReader::GetQFileName()
		CODE:
		RETVAL = THIS->GetQFileName();
		OUTPUT:
		RETVAL


float
vtkPLOT3DReader::GetR()
		CODE:
		RETVAL = THIS->GetR();
		OUTPUT:
		RETVAL


float
vtkPLOT3DReader::GetRe()
		CODE:
		RETVAL = THIS->GetRe();
		OUTPUT:
		RETVAL


int
vtkPLOT3DReader::GetScalarFunctionNumber()
		CODE:
		RETVAL = THIS->GetScalarFunctionNumber();
		OUTPUT:
		RETVAL


float
vtkPLOT3DReader::GetTime()
		CODE:
		RETVAL = THIS->GetTime();
		OUTPUT:
		RETVAL


float
vtkPLOT3DReader::GetUvinf()
		CODE:
		RETVAL = THIS->GetUvinf();
		OUTPUT:
		RETVAL


char *
vtkPLOT3DReader::GetVectorFunctionFileName()
		CODE:
		RETVAL = THIS->GetVectorFunctionFileName();
		OUTPUT:
		RETVAL


int
vtkPLOT3DReader::GetVectorFunctionNumber()
		CODE:
		RETVAL = THIS->GetVectorFunctionNumber();
		OUTPUT:
		RETVAL


float
vtkPLOT3DReader::GetVvinf()
		CODE:
		RETVAL = THIS->GetVvinf();
		OUTPUT:
		RETVAL


float
vtkPLOT3DReader::GetWvinf()
		CODE:
		RETVAL = THIS->GetWvinf();
		OUTPUT:
		RETVAL


char *
vtkPLOT3DReader::GetXYZFileName()
		CODE:
		RETVAL = THIS->GetXYZFileName();
		OUTPUT:
		RETVAL


static vtkPLOT3DReader*
vtkPLOT3DReader::New()
		CODE:
		RETVAL = vtkPLOT3DReader::New();
		OUTPUT:
		RETVAL


void
vtkPLOT3DReader::RemoveAllFunctions()
		CODE:
		THIS->RemoveAllFunctions();
		XSRETURN_EMPTY;


void
vtkPLOT3DReader::RemoveFunction(arg1)
		int 	arg1
		CODE:
		THIS->RemoveFunction(arg1);
		XSRETURN_EMPTY;


void
vtkPLOT3DReader::SetFileFormat(arg1)
		int 	arg1
		CODE:
		THIS->SetFileFormat(arg1);
		XSRETURN_EMPTY;


void
vtkPLOT3DReader::SetFunctionFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetFunctionFileName(arg1);
		XSRETURN_EMPTY;


void
vtkPLOT3DReader::SetGamma(arg1)
		float 	arg1
		CODE:
		THIS->SetGamma(arg1);
		XSRETURN_EMPTY;


void
vtkPLOT3DReader::SetGridNumber(arg1)
		int 	arg1
		CODE:
		THIS->SetGridNumber(arg1);
		XSRETURN_EMPTY;


void
vtkPLOT3DReader::SetQFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetQFileName(arg1);
		XSRETURN_EMPTY;


void
vtkPLOT3DReader::SetR(arg1)
		float 	arg1
		CODE:
		THIS->SetR(arg1);
		XSRETURN_EMPTY;


void
vtkPLOT3DReader::SetScalarFunctionNumber(arg1)
		int 	arg1
		CODE:
		THIS->SetScalarFunctionNumber(arg1);
		XSRETURN_EMPTY;


void
vtkPLOT3DReader::SetUvinf(arg1)
		float 	arg1
		CODE:
		THIS->SetUvinf(arg1);
		XSRETURN_EMPTY;


void
vtkPLOT3DReader::SetVectorFunctionFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetVectorFunctionFileName(arg1);
		XSRETURN_EMPTY;


void
vtkPLOT3DReader::SetVectorFunctionNumber(arg1)
		int 	arg1
		CODE:
		THIS->SetVectorFunctionNumber(arg1);
		XSRETURN_EMPTY;


void
vtkPLOT3DReader::SetVvinf(arg1)
		float 	arg1
		CODE:
		THIS->SetVvinf(arg1);
		XSRETURN_EMPTY;


void
vtkPLOT3DReader::SetWvinf(arg1)
		float 	arg1
		CODE:
		THIS->SetWvinf(arg1);
		XSRETURN_EMPTY;


void
vtkPLOT3DReader::SetXYZFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetXYZFileName(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::PLYReader PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkPLYReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


char *
vtkPLYReader::GetFileName()
		CODE:
		RETVAL = THIS->GetFileName();
		OUTPUT:
		RETVAL


static vtkPLYReader*
vtkPLYReader::New()
		CODE:
		RETVAL = vtkPLYReader::New();
		OUTPUT:
		RETVAL


void
vtkPLYReader::SetFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetFileName(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::PLYWriter PREFIX = vtk

PROTOTYPES: DISABLE



char *
vtkPLYWriter::GetArrayName()
		CODE:
		RETVAL = THIS->GetArrayName();
		OUTPUT:
		RETVAL


const char *
vtkPLYWriter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


unsigned char  *
vtkPLYWriter::GetColor()
		PREINIT:
		unsigned char  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetColor();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int
vtkPLYWriter::GetColorMode()
		CODE:
		RETVAL = THIS->GetColorMode();
		OUTPUT:
		RETVAL


int
vtkPLYWriter::GetComponent()
		CODE:
		RETVAL = THIS->GetComponent();
		OUTPUT:
		RETVAL


int
vtkPLYWriter::GetComponentMaxValue()
		CODE:
		RETVAL = THIS->GetComponentMaxValue();
		OUTPUT:
		RETVAL


int
vtkPLYWriter::GetComponentMinValue()
		CODE:
		RETVAL = THIS->GetComponentMinValue();
		OUTPUT:
		RETVAL


int
vtkPLYWriter::GetDataByteOrder()
		CODE:
		RETVAL = THIS->GetDataByteOrder();
		OUTPUT:
		RETVAL


int
vtkPLYWriter::GetDataByteOrderMaxValue()
		CODE:
		RETVAL = THIS->GetDataByteOrderMaxValue();
		OUTPUT:
		RETVAL


int
vtkPLYWriter::GetDataByteOrderMinValue()
		CODE:
		RETVAL = THIS->GetDataByteOrderMinValue();
		OUTPUT:
		RETVAL


vtkScalarsToColors *
vtkPLYWriter::GetLookupTable()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkScalarsToColors";
		CODE:
		RETVAL = THIS->GetLookupTable();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkPLYWriter*
vtkPLYWriter::New()
		CODE:
		RETVAL = vtkPLYWriter::New();
		OUTPUT:
		RETVAL


void
vtkPLYWriter::SetArrayName(arg1)
		char *	arg1
		CODE:
		THIS->SetArrayName(arg1);
		XSRETURN_EMPTY;


void
vtkPLYWriter::SetColor(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		unsigned char 	arg1
		unsigned char 	arg2
		unsigned char 	arg3
		CODE:
		THIS->SetColor(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPLYWriter::SetColor\n");



void
vtkPLYWriter::SetColorMode(arg1)
		int 	arg1
		CODE:
		THIS->SetColorMode(arg1);
		XSRETURN_EMPTY;


void
vtkPLYWriter::SetColorModeToDefault()
		CODE:
		THIS->SetColorModeToDefault();
		XSRETURN_EMPTY;


void
vtkPLYWriter::SetColorModeToOff()
		CODE:
		THIS->SetColorModeToOff();
		XSRETURN_EMPTY;


void
vtkPLYWriter::SetColorModeToUniformCellColor()
		CODE:
		THIS->SetColorModeToUniformCellColor();
		XSRETURN_EMPTY;


void
vtkPLYWriter::SetColorModeToUniformColor()
		CODE:
		THIS->SetColorModeToUniformColor();
		XSRETURN_EMPTY;


void
vtkPLYWriter::SetColorModeToUniformPointColor()
		CODE:
		THIS->SetColorModeToUniformPointColor();
		XSRETURN_EMPTY;


void
vtkPLYWriter::SetComponent(arg1)
		int 	arg1
		CODE:
		THIS->SetComponent(arg1);
		XSRETURN_EMPTY;


void
vtkPLYWriter::SetDataByteOrder(arg1)
		int 	arg1
		CODE:
		THIS->SetDataByteOrder(arg1);
		XSRETURN_EMPTY;


void
vtkPLYWriter::SetDataByteOrderToBigEndian()
		CODE:
		THIS->SetDataByteOrderToBigEndian();
		XSRETURN_EMPTY;


void
vtkPLYWriter::SetDataByteOrderToLittleEndian()
		CODE:
		THIS->SetDataByteOrderToLittleEndian();
		XSRETURN_EMPTY;


void
vtkPLYWriter::SetLookupTable(arg1)
		vtkScalarsToColors *	arg1
		CODE:
		THIS->SetLookupTable(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::PNGReader PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkPNGReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkPNGReader*
vtkPNGReader::New()
		CODE:
		RETVAL = vtkPNGReader::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::PNGWriter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkPNGWriter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkPNGWriter*
vtkPNGWriter::New()
		CODE:
		RETVAL = vtkPNGWriter::New();
		OUTPUT:
		RETVAL


void
vtkPNGWriter::Write()
		CODE:
		THIS->Write();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::PNMReader PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkPNMReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkPNMReader*
vtkPNMReader::New()
		CODE:
		RETVAL = vtkPNMReader::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::PNMWriter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkPNMWriter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkPNMWriter*
vtkPNMWriter::New()
		CODE:
		RETVAL = vtkPNMWriter::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::ParticleReader PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkParticleReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkParticleReader::GetDataByteOrder()
		CODE:
		RETVAL = THIS->GetDataByteOrder();
		OUTPUT:
		RETVAL


const char *
vtkParticleReader::GetDataByteOrderAsString()
		CODE:
		RETVAL = THIS->GetDataByteOrderAsString();
		OUTPUT:
		RETVAL


char *
vtkParticleReader::GetFileName()
		CODE:
		RETVAL = THIS->GetFileName();
		OUTPUT:
		RETVAL


int
vtkParticleReader::GetSwapBytes()
		CODE:
		RETVAL = THIS->GetSwapBytes();
		OUTPUT:
		RETVAL


static vtkParticleReader*
vtkParticleReader::New()
		CODE:
		RETVAL = vtkParticleReader::New();
		OUTPUT:
		RETVAL


void
vtkParticleReader::SetDataByteOrder(arg1)
		int 	arg1
		CODE:
		THIS->SetDataByteOrder(arg1);
		XSRETURN_EMPTY;


void
vtkParticleReader::SetDataByteOrderToBigEndian()
		CODE:
		THIS->SetDataByteOrderToBigEndian();
		XSRETURN_EMPTY;


void
vtkParticleReader::SetDataByteOrderToLittleEndian()
		CODE:
		THIS->SetDataByteOrderToLittleEndian();
		XSRETURN_EMPTY;


void
vtkParticleReader::SetFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetFileName(arg1);
		XSRETURN_EMPTY;


void
vtkParticleReader::SetSwapBytes(arg1)
		int 	arg1
		CODE:
		THIS->SetSwapBytes(arg1);
		XSRETURN_EMPTY;


void
vtkParticleReader::SwapBytesOff()
		CODE:
		THIS->SwapBytesOff();
		XSRETURN_EMPTY;


void
vtkParticleReader::SwapBytesOn()
		CODE:
		THIS->SwapBytesOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::PolyDataReader PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkPolyDataReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkPolyData *
vtkPolyDataReader::GetOutput(arg1 = 0)
	CASE: items == 2
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPolyData";
		CODE:
		RETVAL = THIS->GetOutput(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE: items == 1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPolyData";
		CODE:
		RETVAL = THIS->GetOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPolyDataReader::GetOutput\n");



static vtkPolyDataReader*
vtkPolyDataReader::New()
		CODE:
		RETVAL = vtkPolyDataReader::New();
		OUTPUT:
		RETVAL


void
vtkPolyDataReader::SetOutput(output)
		vtkPolyData *	output
		CODE:
		THIS->SetOutput(output);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::PolyDataWriter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkPolyDataWriter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkPolyData *
vtkPolyDataWriter::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPolyData";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkPolyDataWriter*
vtkPolyDataWriter::New()
		CODE:
		RETVAL = vtkPolyDataWriter::New();
		OUTPUT:
		RETVAL


void
vtkPolyDataWriter::SetInput(input)
		vtkPolyData *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::PostScriptWriter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkPostScriptWriter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkPostScriptWriter*
vtkPostScriptWriter::New()
		CODE:
		RETVAL = vtkPostScriptWriter::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::RectilinearGridReader PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkRectilinearGridReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkRectilinearGrid *
vtkRectilinearGridReader::GetOutput(arg1 = 0)
	CASE: items == 2
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkRectilinearGrid";
		CODE:
		RETVAL = THIS->GetOutput(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE: items == 1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkRectilinearGrid";
		CODE:
		RETVAL = THIS->GetOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkRectilinearGridReader::GetOutput\n");



static vtkRectilinearGridReader*
vtkRectilinearGridReader::New()
		CODE:
		RETVAL = vtkRectilinearGridReader::New();
		OUTPUT:
		RETVAL


void
vtkRectilinearGridReader::SetOutput(output)
		vtkRectilinearGrid *	output
		CODE:
		THIS->SetOutput(output);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::RectilinearGridWriter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkRectilinearGridWriter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkRectilinearGrid *
vtkRectilinearGridWriter::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkRectilinearGrid";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkRectilinearGridWriter*
vtkRectilinearGridWriter::New()
		CODE:
		RETVAL = vtkRectilinearGridWriter::New();
		OUTPUT:
		RETVAL


void
vtkRectilinearGridWriter::SetInput(input)
		vtkRectilinearGrid *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::SLCReader PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkSLCReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkSLCReader::GetError()
		CODE:
		RETVAL = THIS->GetError();
		OUTPUT:
		RETVAL


char *
vtkSLCReader::GetFileName()
		CODE:
		RETVAL = THIS->GetFileName();
		OUTPUT:
		RETVAL


static vtkSLCReader*
vtkSLCReader::New()
		CODE:
		RETVAL = vtkSLCReader::New();
		OUTPUT:
		RETVAL


void
vtkSLCReader::SetFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetFileName(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::STLReader PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkSTLReader::CreateDefaultLocator()
		CODE:
		THIS->CreateDefaultLocator();
		XSRETURN_EMPTY;


const char *
vtkSTLReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


char *
vtkSTLReader::GetFileName()
		CODE:
		RETVAL = THIS->GetFileName();
		OUTPUT:
		RETVAL


vtkPointLocator *
vtkSTLReader::GetLocator()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPointLocator";
		CODE:
		RETVAL = THIS->GetLocator();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkSTLReader::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkSTLReader::GetMerging()
		CODE:
		RETVAL = THIS->GetMerging();
		OUTPUT:
		RETVAL


int
vtkSTLReader::GetScalarTags()
		CODE:
		RETVAL = THIS->GetScalarTags();
		OUTPUT:
		RETVAL


void
vtkSTLReader::MergingOff()
		CODE:
		THIS->MergingOff();
		XSRETURN_EMPTY;


void
vtkSTLReader::MergingOn()
		CODE:
		THIS->MergingOn();
		XSRETURN_EMPTY;


static vtkSTLReader*
vtkSTLReader::New()
		CODE:
		RETVAL = vtkSTLReader::New();
		OUTPUT:
		RETVAL


void
vtkSTLReader::ScalarTagsOff()
		CODE:
		THIS->ScalarTagsOff();
		XSRETURN_EMPTY;


void
vtkSTLReader::ScalarTagsOn()
		CODE:
		THIS->ScalarTagsOn();
		XSRETURN_EMPTY;


void
vtkSTLReader::SetFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetFileName(arg1);
		XSRETURN_EMPTY;


void
vtkSTLReader::SetLocator(locator)
		vtkPointLocator *	locator
		CODE:
		THIS->SetLocator(locator);
		XSRETURN_EMPTY;


void
vtkSTLReader::SetMerging(arg1)
		int 	arg1
		CODE:
		THIS->SetMerging(arg1);
		XSRETURN_EMPTY;


void
vtkSTLReader::SetScalarTags(arg1)
		int 	arg1
		CODE:
		THIS->SetScalarTags(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::STLWriter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkSTLWriter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkSTLWriter*
vtkSTLWriter::New()
		CODE:
		RETVAL = vtkSTLWriter::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::StructuredGridReader PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkStructuredGridReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkStructuredGrid *
vtkStructuredGridReader::GetOutput(arg1 = 0)
	CASE: items == 2
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkStructuredGrid";
		CODE:
		RETVAL = THIS->GetOutput(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE: items == 1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkStructuredGrid";
		CODE:
		RETVAL = THIS->GetOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkStructuredGridReader::GetOutput\n");



static vtkStructuredGridReader*
vtkStructuredGridReader::New()
		CODE:
		RETVAL = vtkStructuredGridReader::New();
		OUTPUT:
		RETVAL


void
vtkStructuredGridReader::SetOutput(output)
		vtkStructuredGrid *	output
		CODE:
		THIS->SetOutput(output);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::StructuredGridWriter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkStructuredGridWriter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkStructuredGrid *
vtkStructuredGridWriter::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkStructuredGrid";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkStructuredGridWriter*
vtkStructuredGridWriter::New()
		CODE:
		RETVAL = vtkStructuredGridWriter::New();
		OUTPUT:
		RETVAL


void
vtkStructuredGridWriter::SetInput(input)
		vtkStructuredGrid *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::StructuredPointsReader PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkStructuredPointsReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkStructuredPoints *
vtkStructuredPointsReader::GetOutput(arg1 = 0)
	CASE: items == 2
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkStructuredPoints";
		CODE:
		RETVAL = THIS->GetOutput(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE: items == 1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkStructuredPoints";
		CODE:
		RETVAL = THIS->GetOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkStructuredPointsReader::GetOutput\n");



static vtkStructuredPointsReader*
vtkStructuredPointsReader::New()
		CODE:
		RETVAL = vtkStructuredPointsReader::New();
		OUTPUT:
		RETVAL


void
vtkStructuredPointsReader::SetOutput(output)
		vtkStructuredPoints *	output
		CODE:
		THIS->SetOutput(output);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::StructuredPointsWriter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkStructuredPointsWriter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkImageData *
vtkStructuredPointsWriter::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImageData";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkStructuredPointsWriter*
vtkStructuredPointsWriter::New()
		CODE:
		RETVAL = vtkStructuredPointsWriter::New();
		OUTPUT:
		RETVAL


void
vtkStructuredPointsWriter::SetInput(input)
		vtkImageData *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::TIFFReader PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkTIFFReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkTIFFReader*
vtkTIFFReader::New()
		CODE:
		RETVAL = vtkTIFFReader::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::TIFFWriter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkTIFFWriter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkTIFFWriter*
vtkTIFFWriter::New()
		CODE:
		RETVAL = vtkTIFFWriter::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::UGFacetReader PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkUGFacetReader::CreateDefaultLocator()
		CODE:
		THIS->CreateDefaultLocator();
		XSRETURN_EMPTY;


const char *
vtkUGFacetReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


char *
vtkUGFacetReader::GetFileName()
		CODE:
		RETVAL = THIS->GetFileName();
		OUTPUT:
		RETVAL


vtkPointLocator *
vtkUGFacetReader::GetLocator()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPointLocator";
		CODE:
		RETVAL = THIS->GetLocator();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkUGFacetReader::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkUGFacetReader::GetMerging()
		CODE:
		RETVAL = THIS->GetMerging();
		OUTPUT:
		RETVAL


int
vtkUGFacetReader::GetNumberOfParts()
		CODE:
		RETVAL = THIS->GetNumberOfParts();
		OUTPUT:
		RETVAL


short
vtkUGFacetReader::GetPartColorIndex(partId)
		int 	partId
		CODE:
		RETVAL = THIS->GetPartColorIndex(partId);
		OUTPUT:
		RETVAL


int
vtkUGFacetReader::GetPartNumber()
		CODE:
		RETVAL = THIS->GetPartNumber();
		OUTPUT:
		RETVAL


void
vtkUGFacetReader::MergingOff()
		CODE:
		THIS->MergingOff();
		XSRETURN_EMPTY;


void
vtkUGFacetReader::MergingOn()
		CODE:
		THIS->MergingOn();
		XSRETURN_EMPTY;


static vtkUGFacetReader*
vtkUGFacetReader::New()
		CODE:
		RETVAL = vtkUGFacetReader::New();
		OUTPUT:
		RETVAL


void
vtkUGFacetReader::SetFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetFileName(arg1);
		XSRETURN_EMPTY;


void
vtkUGFacetReader::SetLocator(locator)
		vtkPointLocator *	locator
		CODE:
		THIS->SetLocator(locator);
		XSRETURN_EMPTY;


void
vtkUGFacetReader::SetMerging(arg1)
		int 	arg1
		CODE:
		THIS->SetMerging(arg1);
		XSRETURN_EMPTY;


void
vtkUGFacetReader::SetPartNumber(arg1)
		int 	arg1
		CODE:
		THIS->SetPartNumber(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::UnstructuredGridReader PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkUnstructuredGridReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkUnstructuredGrid *
vtkUnstructuredGridReader::GetOutput(arg1 = 0)
	CASE: items == 2
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkUnstructuredGrid";
		CODE:
		RETVAL = THIS->GetOutput(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE: items == 1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkUnstructuredGrid";
		CODE:
		RETVAL = THIS->GetOutput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkUnstructuredGridReader::GetOutput\n");



static vtkUnstructuredGridReader*
vtkUnstructuredGridReader::New()
		CODE:
		RETVAL = vtkUnstructuredGridReader::New();
		OUTPUT:
		RETVAL


void
vtkUnstructuredGridReader::SetOutput(output)
		vtkUnstructuredGrid *	output
		CODE:
		THIS->SetOutput(output);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::UnstructuredGridWriter PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkUnstructuredGridWriter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkUnstructuredGrid *
vtkUnstructuredGridWriter::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkUnstructuredGrid";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkUnstructuredGridWriter*
vtkUnstructuredGridWriter::New()
		CODE:
		RETVAL = vtkUnstructuredGridWriter::New();
		OUTPUT:
		RETVAL


void
vtkUnstructuredGridWriter::SetInput(input)
		vtkUnstructuredGrid *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::Volume16Reader PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkVolume16Reader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkVolume16Reader::GetDataByteOrder()
		CODE:
		RETVAL = THIS->GetDataByteOrder();
		OUTPUT:
		RETVAL


const char *
vtkVolume16Reader::GetDataByteOrderAsString()
		CODE:
		RETVAL = THIS->GetDataByteOrderAsString();
		OUTPUT:
		RETVAL


int  *
vtkVolume16Reader::GetDataDimensions()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDataDimensions();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


unsigned short
vtkVolume16Reader::GetDataMask()
		CODE:
		RETVAL = THIS->GetDataMask();
		OUTPUT:
		RETVAL


int
vtkVolume16Reader::GetHeaderSize()
		CODE:
		RETVAL = THIS->GetHeaderSize();
		OUTPUT:
		RETVAL


vtkStructuredPoints *
vtkVolume16Reader::GetImage(ImageNumber)
		int 	ImageNumber
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkStructuredPoints";
		CODE:
		RETVAL = THIS->GetImage(ImageNumber);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkVolume16Reader::GetSwapBytes()
		CODE:
		RETVAL = THIS->GetSwapBytes();
		OUTPUT:
		RETVAL


vtkTransform *
vtkVolume16Reader::GetTransform()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkTransform";
		CODE:
		RETVAL = THIS->GetTransform();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkVolume16Reader*
vtkVolume16Reader::New()
		CODE:
		RETVAL = vtkVolume16Reader::New();
		OUTPUT:
		RETVAL


void
vtkVolume16Reader::SetDataByteOrder(arg1)
		int 	arg1
		CODE:
		THIS->SetDataByteOrder(arg1);
		XSRETURN_EMPTY;


void
vtkVolume16Reader::SetDataByteOrderToBigEndian()
		CODE:
		THIS->SetDataByteOrderToBigEndian();
		XSRETURN_EMPTY;


void
vtkVolume16Reader::SetDataByteOrderToLittleEndian()
		CODE:
		THIS->SetDataByteOrderToLittleEndian();
		XSRETURN_EMPTY;


void
vtkVolume16Reader::SetDataDimensions(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetDataDimensions(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkVolume16Reader::SetDataDimensions\n");



void
vtkVolume16Reader::SetDataMask(arg1)
		unsigned short 	arg1
		CODE:
		THIS->SetDataMask(arg1);
		XSRETURN_EMPTY;


void
vtkVolume16Reader::SetHeaderSize(arg1)
		int 	arg1
		CODE:
		THIS->SetHeaderSize(arg1);
		XSRETURN_EMPTY;


void
vtkVolume16Reader::SetSwapBytes(arg1)
		int 	arg1
		CODE:
		THIS->SetSwapBytes(arg1);
		XSRETURN_EMPTY;


void
vtkVolume16Reader::SetTransform(arg1)
		vtkTransform *	arg1
		CODE:
		THIS->SetTransform(arg1);
		XSRETURN_EMPTY;


void
vtkVolume16Reader::SwapBytesOff()
		CODE:
		THIS->SwapBytesOff();
		XSRETURN_EMPTY;


void
vtkVolume16Reader::SwapBytesOn()
		CODE:
		THIS->SwapBytesOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::VolumeReader PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkVolumeReader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkVolumeReader::GetDataOrigin()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDataOrigin();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkVolumeReader::GetDataSpacing()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDataSpacing();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


char *
vtkVolumeReader::GetFilePattern()
		CODE:
		RETVAL = THIS->GetFilePattern();
		OUTPUT:
		RETVAL


char *
vtkVolumeReader::GetFilePrefix()
		CODE:
		RETVAL = THIS->GetFilePrefix();
		OUTPUT:
		RETVAL


vtkStructuredPoints *
vtkVolumeReader::GetImage(ImageNumber)
		int 	ImageNumber
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkStructuredPoints";
		CODE:
		RETVAL = THIS->GetImage(ImageNumber);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int  *
vtkVolumeReader::GetImageRange()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetImageRange();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


void
vtkVolumeReader::SetDataOrigin(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetDataOrigin(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkVolumeReader::SetDataOrigin\n");



void
vtkVolumeReader::SetDataSpacing(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetDataSpacing(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkVolumeReader::SetDataSpacing\n");



void
vtkVolumeReader::SetFilePattern(arg1)
		char *	arg1
		CODE:
		THIS->SetFilePattern(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeReader::SetFilePrefix(arg1)
		char *	arg1
		CODE:
		THIS->SetFilePrefix(arg1);
		XSRETURN_EMPTY;


void
vtkVolumeReader::SetImageRange(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetImageRange(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkVolumeReader::SetImageRange\n");


MODULE = Graphics::VTK::IO	PACKAGE = Graphics::VTK::Writer PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkWriter::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


void
vtkWriter::Update()
		CODE:
		THIS->Update();
		XSRETURN_EMPTY;


void
vtkWriter::Write()
		CODE:
		THIS->Write();
		XSRETURN_EMPTY;


