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
#include "vtkAbstractMapper.h"
#include "vtkAbstractTransform.h"
#include "vtkActor2D.h"
#include "vtkActor2DCollection.h"
#include "vtkAssemblyNode.h"
#include "vtkAssemblyPath.h"
#include "vtkAssemblyPaths.h"
#include "vtkBitArray.h"
#include "vtkByteSwap.h"
#include "vtkCell.h"
#include "vtkCell3D.h"
#include "vtkCellArray.h"
#include "vtkCellData.h"
#include "vtkCellLinks.h"
#include "vtkCellTypes.h"
#include "vtkCharArray.h"
#include "vtkCollection.h"
#include "vtkContourValues.h"
#include "vtkCoordinate.h"
#include "vtkCriticalSection.h"
#include "vtkDataArray.h"
#include "vtkDataObject.h"
#include "vtkDataObjectCollection.h"
#include "vtkDataSet.h"
#include "vtkDataSetAttributes.h"
#include "vtkDataSetCollection.h"
#include "vtkDebugLeaks.h"
#include "vtkDirectory.h"
#include "vtkDoubleArray.h"
#include "vtkDynamicLoader.h"
#include "vtkEdgeTable.h"
#include "vtkEmptyCell.h"
#include "vtkExtentTranslator.h"
#include "vtkFieldData.h"
#include "vtkFileOutputWindow.h"
#include "vtkFloatArray.h"
#include "vtkFunctionParser.h"
#include "vtkFunctionSet.h"
#include "vtkGeneralTransform.h"
#include "vtkGenericCell.h"
#include "vtkHeap.h"
#include "vtkHexahedron.h"
#include "vtkHomogeneousTransform.h"
#include "vtkIdList.h"
#include "vtkIdTypeArray.h"
#include "vtkIdentityTransform.h"
#include "vtkImageData.h"
#include "vtkImplicitFunction.h"
#include "vtkImplicitFunctionCollection.h"
#include "vtkIndent.h"
#include "vtkInitialValueProblemSolver.h"
#include "vtkIntArray.h"
#include "vtkInterpolatedVelocityField.h"
#include "vtkLine.h"
#include "vtkLinearTransform.h"
#include "vtkLocator.h"
#include "vtkLogLookupTable.h"
#include "vtkLongArray.h"
#include "vtkLookupTable.h"
#include "vtkMapper2D.h"
#include "vtkMath.h"
#include "vtkMatrix4x4.h"
#include "vtkMatrixToHomogeneousTransform.h"
#include "vtkMatrixToLinearTransform.h"
#include "vtkMultiThreader.h"
#include "vtkMutexLock.h"
#include "vtkObject.h"
#include "vtkObjectFactory.h"
#include "vtkObjectFactoryCollection.h"
#include "vtkOrderedTriangulator.h"
#include "vtkOutputWindow.h"
#include "vtkOverrideInformation.h"
#include "vtkOverrideInformationCollection.h"
#include "vtkPerspectiveTransform.h"
#include "vtkPixel.h"
#include "vtkPlane.h"
#include "vtkPlaneCollection.h"
#include "vtkPlanes.h"
#include "vtkPointData.h"
#include "vtkPointLocator.h"
#include "vtkPointLocator2D.h"
#include "vtkPointSet.h"
#include "vtkPoints.h"
#include "vtkPolyData.h"
#include "vtkPolyLine.h"
#include "vtkPolyVertex.h"
#include "vtkPolygon.h"
#include "vtkPriorityQueue.h"
#include "vtkProcessObject.h"
#include "vtkProp.h"
#include "vtkPropAssembly.h"
#include "vtkPropCollection.h"
#include "vtkProperty2D.h"
#include "vtkPyramid.h"
#include "vtkQuad.h"
#include "vtkQuadric.h"
#include "vtkRectilinearGrid.h"
#include "vtkReferenceCount.h"
#include "vtkRungeKutta2.h"
#include "vtkRungeKutta4.h"
#include "vtkScalarsToColors.h"
#include "vtkShortArray.h"
#include "vtkSource.h"
#include "vtkStructuredData.h"
#include "vtkStructuredGrid.h"
#include "vtkStructuredPoints.h"
#include "vtkTensor.h"
#include "vtkTetra.h"
#include "vtkTimeStamp.h"
#include "vtkTimerLog.h"
#include "vtkTransform.h"
#include "vtkTransformCollection.h"
#include "vtkTriangle.h"
#include "vtkTriangleStrip.h"
#include "vtkUnsignedCharArray.h"
#include "vtkUnsignedIntArray.h"
#include "vtkUnsignedLongArray.h"
#include "vtkUnsignedShortArray.h"
#include "vtkUnstructuredGrid.h"
#include "vtkVersion.h"
#include "vtkVertex.h"
#include "vtkViewport.h"
#include "vtkVoidArray.h"
#include "vtkVoxel.h"
#include "vtkWarpTransform.h"
#include "vtkWedge.h"
#include "vtkWindow.h"
#include "vtkWindowLevelLookupTable.h"
#include "vtkXMLFileOutputWindow.h"
#ifdef WIN32
#include "vtkWin32OutputWindow.h"
#endif
#include "vtkCommand.h"

/*=========================================================================

   Subclass of vtkCommand for the perl interface
   
 =========================================================================*/

 class vtkPerlCommand : public vtkCommand
{
public:
  static vtkPerlCommand *New() { return new vtkPerlCommand; };

  void SetCallback(SV* codeRef);
  
  void Execute(vtkObject *, unsigned long, void *);

  SV* code;
  
protected:
  vtkPerlCommand();
  ~vtkPerlCommand(); 
};

vtkPerlCommand::vtkPerlCommand()
{ 
  this->code = NULL; 
}

vtkPerlCommand::~vtkPerlCommand() 
{ 
  if(this->code) { SvREFCNT_dec(this->code); } // We are done with this SV
}

void vtkPerlCommand::SetCallback(SV* codeRef)
{
	this->code = codeRef;
	SvREFCNT_inc(this->code); // Increment its reference count while we are using it
	

}
  
  
// Execute the perl callback
void vtkPerlCommand::Execute(vtkObject *, unsigned long, void *)
{

  int count;
  dSP;
  PUSHMARK(SP) ;
  /*printf("callperlsub called'%s'\n",SvPV_nolen(code)); */
  count = perl_call_sv(this->code, G_DISCARD|G_NOARGS ) ;
}	
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

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::AbstractMapper PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkAbstractMapper::AddClippingPlane(plane)
		vtkPlane *	plane
		CODE:
		THIS->AddClippingPlane(plane);
		XSRETURN_EMPTY;


const char *
vtkAbstractMapper::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkPlaneCollection *
vtkAbstractMapper::GetClippingPlanes()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPlaneCollection";
		CODE:
		RETVAL = THIS->GetClippingPlanes();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkAbstractMapper::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


static vtkDataArray *
vtkAbstractMapper::GetScalars(input, scalarMode, arrayAccessMode, arrayId, arrayName, component)
		vtkDataSet *	input
		int 	scalarMode
		int 	arrayAccessMode
		int 	arrayId
		const char *	arrayName
		int 	component
		CODE:
		RETVAL = vtkAbstractMapper::GetScalars(input, scalarMode, arrayAccessMode, arrayId, arrayName, component);
		OUTPUT:
		component
		RETVAL


float
vtkAbstractMapper::GetTimeToDraw()
		CODE:
		RETVAL = THIS->GetTimeToDraw();
		OUTPUT:
		RETVAL


void
vtkAbstractMapper::ReleaseGraphicsResources(arg1)
		vtkWindow *	arg1
		CODE:
		THIS->ReleaseGraphicsResources(arg1);
		XSRETURN_EMPTY;


void
vtkAbstractMapper::RemoveAllClippingPlanes()
		CODE:
		THIS->RemoveAllClippingPlanes();
		XSRETURN_EMPTY;


void
vtkAbstractMapper::RemoveClippingPlane(plane)
		vtkPlane *	plane
		CODE:
		THIS->RemoveClippingPlane(plane);
		XSRETURN_EMPTY;


void
vtkAbstractMapper::SetClippingPlanes(arg1 = 0)
	CASE: items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1),"Graphics::VTK::Planes")
		vtkPlanes *	arg1
		CODE:
		THIS->SetClippingPlanes(arg1);
		XSRETURN_EMPTY;
	CASE: items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1),"Graphics::VTK::PlaneCollection")
		vtkPlaneCollection *	arg1
		CODE:
		THIS->SetClippingPlanes(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkAbstractMapper::SetClippingPlanes\n");



void
vtkAbstractMapper::ShallowCopy(m)
		vtkAbstractMapper *	m
		CODE:
		THIS->ShallowCopy(m);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::AbstractTransform PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkAbstractTransform::CircuitCheck(transform)
		vtkAbstractTransform *	transform
		CODE:
		RETVAL = THIS->CircuitCheck(transform);
		OUTPUT:
		RETVAL


void
vtkAbstractTransform::DeepCopy(arg1)
		vtkAbstractTransform *	arg1
		CODE:
		THIS->DeepCopy(arg1);
		XSRETURN_EMPTY;


const char *
vtkAbstractTransform::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkAbstractTransform *
vtkAbstractTransform::GetInverse()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAbstractTransform";
		CODE:
		RETVAL = THIS->GetInverse();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkAbstractTransform::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


void
vtkAbstractTransform::Identity()
		CODE:
		THIS->Identity();
		XSRETURN_EMPTY;


void
vtkAbstractTransform::Inverse()
		CODE:
		THIS->Inverse();
		XSRETURN_EMPTY;


vtkAbstractTransform *
vtkAbstractTransform::MakeTransform()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAbstractTransform";
		CODE:
		RETVAL = THIS->MakeTransform();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkAbstractTransform::SetInverse(transform)
		vtkAbstractTransform *	transform
		CODE:
		THIS->SetInverse(transform);
		XSRETURN_EMPTY;


double *
vtkAbstractTransform::TransformDoublePoint(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		double 	arg1
		double 	arg2
		double 	arg3
		PREINIT:
		double * retval;
		CODE:
		SP -= items;
		retval = THIS->TransformDoublePoint(arg1, arg2, arg3);
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkAbstractTransform::TransformDoublePoint\n");



float *
vtkAbstractTransform::TransformFloatPoint(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->TransformFloatPoint(arg1, arg2, arg3);
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkAbstractTransform::TransformFloatPoint\n");



double *
vtkAbstractTransform::TransformPoint(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		double 	arg1
		double 	arg2
		double 	arg3
		PREINIT:
		double * retval;
		CODE:
		SP -= items;
		retval = THIS->TransformPoint(arg1, arg2, arg3);
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkAbstractTransform::TransformPoint\n");



void
vtkAbstractTransform::TransformPoints(inPts, outPts)
		vtkPoints *	inPts
		vtkPoints *	outPts
		CODE:
		THIS->TransformPoints(inPts, outPts);
		XSRETURN_EMPTY;


void
vtkAbstractTransform::TransformPointsNormalsVectors(inPts, outPts, inNms, outNms, inVrs, outVrs)
		vtkPoints *	inPts
		vtkPoints *	outPts
		vtkDataArray *	inNms
		vtkDataArray *	outNms
		vtkDataArray *	inVrs
		vtkDataArray *	outVrs
		CODE:
		THIS->TransformPointsNormalsVectors(inPts, outPts, inNms, outNms, inVrs, outVrs);
		XSRETURN_EMPTY;


void
vtkAbstractTransform::UnRegister(O)
		vtkObject *	O
		CODE:
		THIS->UnRegister(O);
		XSRETURN_EMPTY;


void
vtkAbstractTransform::Update()
		CODE:
		THIS->Update();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Actor2D PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkActor2D::GetActors2D(pc)
		vtkPropCollection *	pc
		CODE:
		THIS->GetActors2D(pc);
		XSRETURN_EMPTY;


const char *
vtkActor2D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkActor2D::GetHeight()
		CODE:
		RETVAL = THIS->GetHeight();
		OUTPUT:
		RETVAL


int
vtkActor2D::GetLayerNumber()
		CODE:
		RETVAL = THIS->GetLayerNumber();
		OUTPUT:
		RETVAL


unsigned long
vtkActor2D::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


vtkMapper2D *
vtkActor2D::GetMapper()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkMapper2D";
		CODE:
		RETVAL = THIS->GetMapper();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float *
vtkActor2D::GetPosition()
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPosition();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


float *
vtkActor2D::GetPosition2()
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPosition2();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


vtkCoordinate *
vtkActor2D::GetPosition2Coordinate()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCoordinate";
		CODE:
		RETVAL = THIS->GetPosition2Coordinate();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkCoordinate *
vtkActor2D::GetPositionCoordinate()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCoordinate";
		CODE:
		RETVAL = THIS->GetPositionCoordinate();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkProperty2D *
vtkActor2D::GetProperty()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkProperty2D";
		CODE:
		RETVAL = THIS->GetProperty();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float
vtkActor2D::GetWidth()
		CODE:
		RETVAL = THIS->GetWidth();
		OUTPUT:
		RETVAL


static vtkActor2D*
vtkActor2D::New()
		CODE:
		RETVAL = vtkActor2D::New();
		OUTPUT:
		RETVAL


void
vtkActor2D::ReleaseGraphicsResources(arg1)
		vtkWindow *	arg1
		CODE:
		THIS->ReleaseGraphicsResources(arg1);
		XSRETURN_EMPTY;


int
vtkActor2D::RenderOpaqueGeometry(viewport)
		vtkViewport *	viewport
		CODE:
		RETVAL = THIS->RenderOpaqueGeometry(viewport);
		OUTPUT:
		RETVAL


int
vtkActor2D::RenderOverlay(viewport)
		vtkViewport *	viewport
		CODE:
		RETVAL = THIS->RenderOverlay(viewport);
		OUTPUT:
		RETVAL


int
vtkActor2D::RenderTranslucentGeometry(viewport)
		vtkViewport *	viewport
		CODE:
		RETVAL = THIS->RenderTranslucentGeometry(viewport);
		OUTPUT:
		RETVAL


void
vtkActor2D::SetDisplayPosition(arg1, arg2)
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetDisplayPosition(arg1, arg2);
		XSRETURN_EMPTY;


void
vtkActor2D::SetHeight(h)
		float 	h
		CODE:
		THIS->SetHeight(h);
		XSRETURN_EMPTY;


void
vtkActor2D::SetLayerNumber(arg1)
		int 	arg1
		CODE:
		THIS->SetLayerNumber(arg1);
		XSRETURN_EMPTY;


void
vtkActor2D::SetMapper(mapper)
		vtkMapper2D *	mapper
		CODE:
		THIS->SetMapper(mapper);
		XSRETURN_EMPTY;


void
vtkActor2D::SetPosition(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float	arg1
		float	arg2
		CODE:
		THIS->SetPosition(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkActor2D::SetPosition\n");



void
vtkActor2D::SetPosition2(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float	arg1
		float	arg2
		CODE:
		THIS->SetPosition2(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkActor2D::SetPosition2\n");



void
vtkActor2D::SetProperty(arg1)
		vtkProperty2D *	arg1
		CODE:
		THIS->SetProperty(arg1);
		XSRETURN_EMPTY;


void
vtkActor2D::SetWidth(w)
		float 	w
		CODE:
		THIS->SetWidth(w);
		XSRETURN_EMPTY;


void
vtkActor2D::ShallowCopy(prop)
		vtkProp *	prop
		CODE:
		THIS->ShallowCopy(prop);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Actor2DCollection PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkActor2DCollection::AddItem(arg1 = 0)
	CASE: items == 2
		vtkActor2D *	arg1
		CODE:
		THIS->AddItem(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkActor2DCollection::AddItem\n");



const char *
vtkActor2DCollection::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkActor2D *
vtkActor2DCollection::GetLastActor2D()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkActor2D";
		CODE:
		RETVAL = THIS->GetLastActor2D();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkActor2D *
vtkActor2DCollection::GetLastItem()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkActor2D";
		CODE:
		RETVAL = THIS->GetLastItem();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkActor2D *
vtkActor2DCollection::GetNextActor2D()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkActor2D";
		CODE:
		RETVAL = THIS->GetNextActor2D();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkActor2D *
vtkActor2DCollection::GetNextItem()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkActor2D";
		CODE:
		RETVAL = THIS->GetNextItem();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkActor2DCollection::IsItemPresent(arg1 = 0)
	CASE: items == 2
		vtkActor2D *	arg1
		CODE:
		RETVAL = THIS->IsItemPresent(arg1);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkActor2DCollection::IsItemPresent\n");



static vtkActor2DCollection*
vtkActor2DCollection::New()
		CODE:
		RETVAL = vtkActor2DCollection::New();
		OUTPUT:
		RETVAL


void
vtkActor2DCollection::RenderOverlay(viewport)
		vtkViewport *	viewport
		CODE:
		THIS->RenderOverlay(viewport);
		XSRETURN_EMPTY;


void
vtkActor2DCollection::Sort()
		CODE:
		THIS->Sort();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::AssemblyNode PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkAssemblyNode::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


unsigned long
vtkAssemblyNode::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


vtkMatrix4x4 *
vtkAssemblyNode::GetMatrix()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkMatrix4x4";
		CODE:
		RETVAL = THIS->GetMatrix();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkProp *
vtkAssemblyNode::GetProp()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkProp";
		CODE:
		RETVAL = THIS->GetProp();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkAssemblyNode*
vtkAssemblyNode::New()
		CODE:
		RETVAL = vtkAssemblyNode::New();
		OUTPUT:
		RETVAL


void
vtkAssemblyNode::SetMatrix(matrix)
		vtkMatrix4x4 *	matrix
		CODE:
		THIS->SetMatrix(matrix);
		XSRETURN_EMPTY;


void
vtkAssemblyNode::SetProp(prop)
		vtkProp *	prop
		CODE:
		THIS->SetProp(prop);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::AssemblyPath PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkAssemblyPath::AddNode(arg1 = 0, arg2 = 0)
	CASE: items == 3
		vtkProp *	arg1
		vtkMatrix4x4 *	arg2
		CODE:
		THIS->AddNode(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkAssemblyPath::AddNode\n");



void
vtkAssemblyPath::DeleteLastNode()
		CODE:
		THIS->DeleteLastNode();
		XSRETURN_EMPTY;


const char *
vtkAssemblyPath::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkAssemblyNode *
vtkAssemblyPath::GetFirstNode()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAssemblyNode";
		CODE:
		RETVAL = THIS->GetFirstNode();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkAssemblyNode *
vtkAssemblyPath::GetLastNode()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAssemblyNode";
		CODE:
		RETVAL = THIS->GetLastNode();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkAssemblyPath::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


vtkAssemblyNode *
vtkAssemblyPath::GetNextNode()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAssemblyNode";
		CODE:
		RETVAL = THIS->GetNextNode();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkAssemblyPath*
vtkAssemblyPath::New()
		CODE:
		RETVAL = vtkAssemblyPath::New();
		OUTPUT:
		RETVAL


void
vtkAssemblyPath::ShallowCopy(path)
		vtkAssemblyPath *	path
		CODE:
		THIS->ShallowCopy(path);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::AssemblyPaths PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkAssemblyPaths::AddItem(arg1 = 0)
	CASE: items == 2
		vtkAssemblyPath *	arg1
		CODE:
		THIS->AddItem(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkAssemblyPaths::AddItem\n");



const char *
vtkAssemblyPaths::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


unsigned long
vtkAssemblyPaths::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


vtkAssemblyPath *
vtkAssemblyPaths::GetNextItem()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAssemblyPath";
		CODE:
		RETVAL = THIS->GetNextItem();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkAssemblyPaths::IsItemPresent(arg1 = 0)
	CASE: items == 2
		vtkAssemblyPath *	arg1
		CODE:
		RETVAL = THIS->IsItemPresent(arg1);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkAssemblyPaths::IsItemPresent\n");



static vtkAssemblyPaths*
vtkAssemblyPaths::New()
		CODE:
		RETVAL = vtkAssemblyPaths::New();
		OUTPUT:
		RETVAL


void
vtkAssemblyPaths::RemoveItem(arg1 = 0)
	CASE: items == 2
		vtkAssemblyPath *	arg1
		CODE:
		THIS->RemoveItem(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkAssemblyPaths::RemoveItem\n");


MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::BitArray PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkBitArray::Allocate(sz, ext)
		const long 	sz
		const long 	ext
		CODE:
		RETVAL = THIS->Allocate(sz, ext);
		OUTPUT:
		RETVAL


void
vtkBitArray::DeepCopy(arg1 = 0)
	CASE: items == 2
		vtkDataArray *	arg1
		CODE:
		THIS->DeepCopy(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkBitArray::DeepCopy\n");



const char *
vtkBitArray::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkBitArray::GetDataType()
		CODE:
		RETVAL = THIS->GetDataType();
		OUTPUT:
		RETVAL


int
vtkBitArray::GetValue(id)
		const long 	id
		CODE:
		RETVAL = THIS->GetValue(id);
		OUTPUT:
		RETVAL


void
vtkBitArray::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


void
vtkBitArray::InsertComponent(i, j, c)
		const long 	i
		const int 	j
		const float 	c
		CODE:
		THIS->InsertComponent(i, j, c);
		XSRETURN_EMPTY;


long
vtkBitArray::InsertNextValue(i)
		const int 	i
		CODE:
		RETVAL = THIS->InsertNextValue(i);
		OUTPUT:
		RETVAL


void
vtkBitArray::InsertValue(id, i)
		const long 	id
		const int 	i
		CODE:
		THIS->InsertValue(id, i);
		XSRETURN_EMPTY;


static vtkBitArray*
vtkBitArray::New()
		CODE:
		RETVAL = vtkBitArray::New();
		OUTPUT:
		RETVAL


void
vtkBitArray::Resize(numTuples)
		long 	numTuples
		CODE:
		THIS->Resize(numTuples);
		XSRETURN_EMPTY;


void
vtkBitArray::SetComponent(i, j, c)
		const long 	i
		const int 	j
		const float 	c
		CODE:
		THIS->SetComponent(i, j, c);
		XSRETURN_EMPTY;


void
vtkBitArray::SetNumberOfTuples(number)
		const long 	number
		CODE:
		THIS->SetNumberOfTuples(number);
		XSRETURN_EMPTY;


void
vtkBitArray::SetNumberOfValues(number)
		const long 	number
		CODE:
		THIS->SetNumberOfValues(number);
		XSRETURN_EMPTY;


void
vtkBitArray::SetValue(id, value)
		const long 	id
		const int 	value
		CODE:
		THIS->SetValue(id, value);
		XSRETURN_EMPTY;


void
vtkBitArray::Squeeze()
		CODE:
		THIS->Squeeze();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::ByteSwap PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkByteSwap::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkByteSwap*
vtkByteSwap::New()
		CODE:
		RETVAL = vtkByteSwap::New();
		OUTPUT:
		RETVAL


static void
vtkByteSwap::Swap2BERange(arg1 = 0, arg2 = 0)
	CASE: items == 3
		char *	arg1
		int 	arg2
		CODE:
		vtkByteSwap::Swap2BERange(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkByteSwap::Swap2BERange\n");



static void
vtkByteSwap::Swap2LERange(arg1 = 0, arg2 = 0)
	CASE: items == 3
		char *	arg1
		int 	arg2
		CODE:
		vtkByteSwap::Swap2LERange(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkByteSwap::Swap2LERange\n");



static void
vtkByteSwap::Swap4BE(arg1 = 0)
	CASE: items == 2
		char *	arg1
		CODE:
		vtkByteSwap::Swap4BE(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkByteSwap::Swap4BE\n");



static void
vtkByteSwap::Swap4BERange(arg1 = 0, arg2 = 0)
	CASE: items == 3
		char *	arg1
		int 	arg2
		CODE:
		vtkByteSwap::Swap4BERange(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkByteSwap::Swap4BERange\n");



static void
vtkByteSwap::Swap4LE(arg1 = 0)
	CASE: items == 2
		char *	arg1
		CODE:
		vtkByteSwap::Swap4LE(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkByteSwap::Swap4LE\n");



static void
vtkByteSwap::Swap4LERange(arg1 = 0, arg2 = 0)
	CASE: items == 3
		char *	arg1
		int 	arg2
		CODE:
		vtkByteSwap::Swap4LERange(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkByteSwap::Swap4LERange\n");



static void
vtkByteSwap::Swap8BE(arg1 = 0)
	CASE: items == 2
		char *	arg1
		CODE:
		vtkByteSwap::Swap8BE(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkByteSwap::Swap8BE\n");



static void
vtkByteSwap::Swap8BERange(arg1 = 0, arg2 = 0)
	CASE: items == 3
		char *	arg1
		int 	arg2
		CODE:
		vtkByteSwap::Swap8BERange(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkByteSwap::Swap8BERange\n");



static void
vtkByteSwap::Swap8LE(arg1 = 0)
	CASE: items == 2
		char *	arg1
		CODE:
		vtkByteSwap::Swap8LE(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkByteSwap::Swap8LE\n");



static void
vtkByteSwap::Swap8LERange(arg1 = 0, arg2 = 0)
	CASE: items == 3
		char *	arg1
		int 	arg2
		CODE:
		vtkByteSwap::Swap8LERange(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkByteSwap::Swap8LERange\n");


MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Cell PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkCell::Clip(value, cellScalars, locator, connectivity, inPd, outPd, inCd, cellId, outCd, insideOut)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	connectivity
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		int 	insideOut
		CODE:
		THIS->Clip(value, cellScalars, locator, connectivity, inPd, outPd, inCd, cellId, outCd, insideOut);
		XSRETURN_EMPTY;


void
vtkCell::Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	verts
		vtkCellArray *	lines
		vtkCellArray *	polys
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		CODE:
		THIS->Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd);
		XSRETURN_EMPTY;


void
vtkCell::DeepCopy(c)
		vtkCell *	c
		CODE:
		THIS->DeepCopy(c);
		XSRETURN_EMPTY;


float *
vtkCell::GetBounds()
	CASE: items == 1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetBounds();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCell::GetBounds\n");



int
vtkCell::GetCellDimension()
		CODE:
		RETVAL = THIS->GetCellDimension();
		OUTPUT:
		RETVAL


int
vtkCell::GetCellType()
		CODE:
		RETVAL = THIS->GetCellType();
		OUTPUT:
		RETVAL


const char *
vtkCell::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkCell *
vtkCell::GetEdge(edgeId)
		int 	edgeId
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetEdge(edgeId);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkCell *
vtkCell::GetFace(faceId)
		int 	faceId
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetFace(faceId);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkCell::GetInterpolationOrder()
		CODE:
		RETVAL = THIS->GetInterpolationOrder();
		OUTPUT:
		RETVAL


float
vtkCell::GetLength2()
		CODE:
		RETVAL = THIS->GetLength2();
		OUTPUT:
		RETVAL


int
vtkCell::GetNumberOfEdges()
		CODE:
		RETVAL = THIS->GetNumberOfEdges();
		OUTPUT:
		RETVAL


int
vtkCell::GetNumberOfFaces()
		CODE:
		RETVAL = THIS->GetNumberOfFaces();
		OUTPUT:
		RETVAL


int
vtkCell::GetNumberOfPoints()
		CODE:
		RETVAL = THIS->GetNumberOfPoints();
		OUTPUT:
		RETVAL



long
vtkCell::GetPointId(ptId)
		int 	ptId
		CODE:
		RETVAL = THIS->GetPointId(ptId);
		OUTPUT:
		RETVAL


vtkIdList *
vtkCell::GetPointIds()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkIdList";
		CODE:
		RETVAL = THIS->GetPointIds();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkPoints *
vtkCell::GetPoints()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPoints";
		CODE:
		RETVAL = THIS->GetPoints();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkCell::ShallowCopy(c)
		vtkCell *	c
		CODE:
		THIS->ShallowCopy(c);
		XSRETURN_EMPTY;


int
vtkCell::Triangulate(index, ptIds, pts)
		int 	index
		vtkIdList *	ptIds
		vtkPoints *	pts
		CODE:
		RETVAL = THIS->Triangulate(index, ptIds, pts);
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Cell3D PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkCell3D::Clip(value, cellScalars, locator, connectivity, inPd, outPd, inCd, cellId, outCd, insideOut)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	connectivity
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		int 	insideOut
		CODE:
		THIS->Clip(value, cellScalars, locator, connectivity, inPd, outPd, inCd, cellId, outCd, insideOut);
		XSRETURN_EMPTY;


int
vtkCell3D::GetCellDimension()
		CODE:
		RETVAL = THIS->GetCellDimension();
		OUTPUT:
		RETVAL


const char *
vtkCell3D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::CellArray PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkCellArray::Allocate(sz, ext)
		const long 	sz
		const int 	ext
		CODE:
		RETVAL = THIS->Allocate(sz, ext);
		OUTPUT:
		RETVAL


void
vtkCellArray::DeepCopy(ca)
		vtkCellArray *	ca
		CODE:
		THIS->DeepCopy(ca);
		XSRETURN_EMPTY;


long
vtkCellArray::EstimateSize(numCells, maxPtsPerCell)
		long 	numCells
		int 	maxPtsPerCell
		CODE:
		RETVAL = THIS->EstimateSize(numCells, maxPtsPerCell);
		OUTPUT:
		RETVAL


unsigned long
vtkCellArray::GetActualMemorySize()
		CODE:
		RETVAL = THIS->GetActualMemorySize();
		OUTPUT:
		RETVAL


const char *
vtkCellArray::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataArray *
vtkCellArray::GetData()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataArray";
		CODE:
		RETVAL = THIS->GetData();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


long
vtkCellArray::GetInsertLocation(npts)
		int 	npts
		CODE:
		RETVAL = THIS->GetInsertLocation(npts);
		OUTPUT:
		RETVAL


int
vtkCellArray::GetMaxCellSize()
		CODE:
		RETVAL = THIS->GetMaxCellSize();
		OUTPUT:
		RETVAL


long
vtkCellArray::GetNumberOfCells()
		CODE:
		RETVAL = THIS->GetNumberOfCells();
		OUTPUT:
		RETVAL


long
vtkCellArray::GetNumberOfConnectivityEntries()
		CODE:
		RETVAL = THIS->GetNumberOfConnectivityEntries();
		OUTPUT:
		RETVAL


long
vtkCellArray::GetSize()
		CODE:
		RETVAL = THIS->GetSize();
		OUTPUT:
		RETVAL


long
vtkCellArray::GetTraversalLocation(arg1 = 0)
	CASE: items == 2
		long 	arg1
		CODE:
		RETVAL = THIS->GetTraversalLocation(arg1);
		OUTPUT:
		RETVAL
	CASE: items == 1
		CODE:
		RETVAL = THIS->GetTraversalLocation();
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCellArray::GetTraversalLocation\n");



void
vtkCellArray::InitTraversal()
		CODE:
		THIS->InitTraversal();
		XSRETURN_EMPTY;


void
vtkCellArray::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


void
vtkCellArray::InsertCellPoint(id)
		long 	id
		CODE:
		THIS->InsertCellPoint(id);
		XSRETURN_EMPTY;


long
vtkCellArray::InsertNextCell(arg1 = 0)
	CASE: items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1),"Graphics::VTK::IdList")
		vtkIdList *	arg1
		CODE:
		RETVAL = THIS->InsertNextCell(arg1);
		OUTPUT:
		RETVAL
	CASE: items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1),"Graphics::VTK::Cell")
		vtkCell *	arg1
		CODE:
		RETVAL = THIS->InsertNextCell(arg1);
		OUTPUT:
		RETVAL
	CASE: items == 2 && SvIOK(ST(1))
		int 	arg1
		CODE:
		RETVAL = THIS->InsertNextCell(arg1);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCellArray::InsertNextCell\n");



static vtkCellArray*
vtkCellArray::New()
		CODE:
		RETVAL = vtkCellArray::New();
		OUTPUT:
		RETVAL


void
vtkCellArray::Reset()
		CODE:
		THIS->Reset();
		XSRETURN_EMPTY;


void
vtkCellArray::ReverseCell(loc)
		long 	loc
		CODE:
		THIS->ReverseCell(loc);
		XSRETURN_EMPTY;


void
vtkCellArray::SetCells(ncells, cells)
		long 	ncells
		vtkIdTypeArray *	cells
		CODE:
		THIS->SetCells(ncells, cells);
		XSRETURN_EMPTY;


void
vtkCellArray::SetTraversalLocation(loc)
		long 	loc
		CODE:
		THIS->SetTraversalLocation(loc);
		XSRETURN_EMPTY;


void
vtkCellArray::Squeeze()
		CODE:
		THIS->Squeeze();
		XSRETURN_EMPTY;


void
vtkCellArray::UpdateCellCount(npts)
		int 	npts
		CODE:
		THIS->UpdateCellCount(npts);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::CellData PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkCellData::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkCellData*
vtkCellData::New()
		CODE:
		RETVAL = vtkCellData::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::CellLinks PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkCellLinks::AddCellReference(cellId, ptId)
		long 	cellId
		long 	ptId
		CODE:
		THIS->AddCellReference(cellId, ptId);
		XSRETURN_EMPTY;


void
vtkCellLinks::Allocate(numLinks, ext)
		long 	numLinks
		long 	ext
		CODE:
		THIS->Allocate(numLinks, ext);
		XSRETURN_EMPTY;


void
vtkCellLinks::BuildLinks(arg1 = 0, arg2 = 0)
	CASE: items == 3
		vtkDataSet *	arg1
		vtkCellArray *	arg2
		CODE:
		THIS->BuildLinks(arg1, arg2);
		XSRETURN_EMPTY;
	CASE: items == 2
		vtkDataSet *	arg1
		CODE:
		THIS->BuildLinks(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCellLinks::BuildLinks\n");



void
vtkCellLinks::DeepCopy(src)
		vtkCellLinks *	src
		CODE:
		THIS->DeepCopy(src);
		XSRETURN_EMPTY;


void
vtkCellLinks::DeletePoint(ptId)
		long 	ptId
		CODE:
		THIS->DeletePoint(ptId);
		XSRETURN_EMPTY;


unsigned long
vtkCellLinks::GetActualMemorySize()
		CODE:
		RETVAL = THIS->GetActualMemorySize();
		OUTPUT:
		RETVAL


const char *
vtkCellLinks::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


unsigned short
vtkCellLinks::GetNcells(ptId)
		long 	ptId
		CODE:
		RETVAL = THIS->GetNcells(ptId);
		OUTPUT:
		RETVAL


void
vtkCellLinks::InsertNextCellReference(ptId, cellId)
		long 	ptId
		long 	cellId
		CODE:
		THIS->InsertNextCellReference(ptId, cellId);
		XSRETURN_EMPTY;


long
vtkCellLinks::InsertNextPoint(numLinks)
		int 	numLinks
		CODE:
		RETVAL = THIS->InsertNextPoint(numLinks);
		OUTPUT:
		RETVAL


static vtkCellLinks*
vtkCellLinks::New()
		CODE:
		RETVAL = vtkCellLinks::New();
		OUTPUT:
		RETVAL


void
vtkCellLinks::RemoveCellReference(cellId, ptId)
		long 	cellId
		long 	ptId
		CODE:
		THIS->RemoveCellReference(cellId, ptId);
		XSRETURN_EMPTY;


void
vtkCellLinks::Reset()
		CODE:
		THIS->Reset();
		XSRETURN_EMPTY;


void
vtkCellLinks::ResizeCellList(ptId, size)
		long 	ptId
		int 	size
		CODE:
		THIS->ResizeCellList(ptId, size);
		XSRETURN_EMPTY;


void
vtkCellLinks::Squeeze()
		CODE:
		THIS->Squeeze();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::CellTypes PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkCellTypes::Allocate(sz, ext)
		int 	sz
		int 	ext
		CODE:
		RETVAL = THIS->Allocate(sz, ext);
		OUTPUT:
		RETVAL


void
vtkCellTypes::DeepCopy(src)
		vtkCellTypes *	src
		CODE:
		THIS->DeepCopy(src);
		XSRETURN_EMPTY;


void
vtkCellTypes::DeleteCell(cellId)
		int 	cellId
		CODE:
		THIS->DeleteCell(cellId);
		XSRETURN_EMPTY;


unsigned long
vtkCellTypes::GetActualMemorySize()
		CODE:
		RETVAL = THIS->GetActualMemorySize();
		OUTPUT:
		RETVAL


int
vtkCellTypes::GetCellLocation(cellId)
		int 	cellId
		CODE:
		RETVAL = THIS->GetCellLocation(cellId);
		OUTPUT:
		RETVAL


unsigned char
vtkCellTypes::GetCellType(cellId)
		int 	cellId
		CODE:
		RETVAL = THIS->GetCellType(cellId);
		OUTPUT:
		RETVAL


const char *
vtkCellTypes::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkCellTypes::GetNumberOfTypes()
		CODE:
		RETVAL = THIS->GetNumberOfTypes();
		OUTPUT:
		RETVAL


void
vtkCellTypes::InsertCell(id, type, loc)
		int 	id
		unsigned char 	type
		int 	loc
		CODE:
		THIS->InsertCell(id, type, loc);
		XSRETURN_EMPTY;


int
vtkCellTypes::InsertNextCell(type, loc)
		unsigned char 	type
		int 	loc
		CODE:
		RETVAL = THIS->InsertNextCell(type, loc);
		OUTPUT:
		RETVAL


int
vtkCellTypes::InsertNextType(type)
		unsigned char 	type
		CODE:
		RETVAL = THIS->InsertNextType(type);
		OUTPUT:
		RETVAL


int
vtkCellTypes::IsType(type)
		unsigned char 	type
		CODE:
		RETVAL = THIS->IsType(type);
		OUTPUT:
		RETVAL


static vtkCellTypes*
vtkCellTypes::New()
		CODE:
		RETVAL = vtkCellTypes::New();
		OUTPUT:
		RETVAL


void
vtkCellTypes::Reset()
		CODE:
		THIS->Reset();
		XSRETURN_EMPTY;


void
vtkCellTypes::SetCellTypes(ncells, cellTypes, cellLocations)
		int 	ncells
		vtkUnsignedCharArray *	cellTypes
		vtkIntArray *	cellLocations
		CODE:
		THIS->SetCellTypes(ncells, cellTypes, cellLocations);
		XSRETURN_EMPTY;


void
vtkCellTypes::Squeeze()
		CODE:
		THIS->Squeeze();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::CharArray PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkCharArray::Allocate(sz, ext)
		const long 	sz
		const long 	ext
		CODE:
		RETVAL = THIS->Allocate(sz, ext);
		OUTPUT:
		RETVAL


void
vtkCharArray::DeepCopy(ia)
		vtkDataArray *	ia
		CODE:
		THIS->DeepCopy(ia);
		XSRETURN_EMPTY;


const char *
vtkCharArray::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkCharArray::GetComponent(i, j)
		const long 	i
		const int 	j
		CODE:
		RETVAL = THIS->GetComponent(i, j);
		OUTPUT:
		RETVAL


int
vtkCharArray::GetDataType()
		CODE:
		RETVAL = THIS->GetDataType();
		OUTPUT:
		RETVAL


char *
vtkCharArray::GetPointer(id)
		const long 	id
		CODE:
		RETVAL = THIS->GetPointer(id);
		OUTPUT:
		RETVAL


char
vtkCharArray::GetValue(id)
		const long 	id
		CODE:
		RETVAL = THIS->GetValue(id);
		OUTPUT:
		RETVAL


void
vtkCharArray::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


void
vtkCharArray::InsertComponent(i, j, c)
		const long 	i
		const int 	j
		const float 	c
		CODE:
		THIS->InsertComponent(i, j, c);
		XSRETURN_EMPTY;


long
vtkCharArray::InsertNextValue(c)
		const char 	c
		CODE:
		RETVAL = THIS->InsertNextValue(c);
		OUTPUT:
		RETVAL


void
vtkCharArray::InsertValue(id, c)
		const long 	id
		const char 	c
		CODE:
		THIS->InsertValue(id, c);
		XSRETURN_EMPTY;


static vtkCharArray*
vtkCharArray::New()
		CODE:
		RETVAL = vtkCharArray::New();
		OUTPUT:
		RETVAL


void
vtkCharArray::Resize(numTuples)
		long 	numTuples
		CODE:
		THIS->Resize(numTuples);
		XSRETURN_EMPTY;


void
vtkCharArray::SetArray(array, size, save)
		char *	array
		long 	size
		int 	save
		CODE:
		THIS->SetArray(array, size, save);
		XSRETURN_EMPTY;


void
vtkCharArray::SetComponent(i, j, c)
		const long 	i
		const int 	j
		const float 	c
		CODE:
		THIS->SetComponent(i, j, c);
		XSRETURN_EMPTY;


void
vtkCharArray::SetNumberOfTuples(number)
		const long 	number
		CODE:
		THIS->SetNumberOfTuples(number);
		XSRETURN_EMPTY;


void
vtkCharArray::SetNumberOfValues(number)
		const long 	number
		CODE:
		THIS->SetNumberOfValues(number);
		XSRETURN_EMPTY;


void
vtkCharArray::SetValue(id, value)
		const long 	id
		const char 	value
		CODE:
		THIS->SetValue(id, value);
		XSRETURN_EMPTY;


void
vtkCharArray::Squeeze()
		CODE:
		THIS->Squeeze();
		XSRETURN_EMPTY;


char *
vtkCharArray::WritePointer(id, number)
		const long 	id
		const long 	number
		CODE:
		RETVAL = THIS->WritePointer(id, number);
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Collection PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkCollection::AddItem(arg1)
		vtkObject *	arg1
		CODE:
		THIS->AddItem(arg1);
		XSRETURN_EMPTY;


const char *
vtkCollection::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkObject *
vtkCollection::GetItemAsObject(i)
		int 	i
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkObject";
		CODE:
		RETVAL = THIS->GetItemAsObject(i);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkObject *
vtkCollection::GetNextItemAsObject()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkObject";
		CODE:
		RETVAL = THIS->GetNextItemAsObject();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkCollection::GetNumberOfItems()
		CODE:
		RETVAL = THIS->GetNumberOfItems();
		OUTPUT:
		RETVAL


void
vtkCollection::InitTraversal()
		CODE:
		THIS->InitTraversal();
		XSRETURN_EMPTY;


int
vtkCollection::IsItemPresent(arg1)
		vtkObject *	arg1
		CODE:
		RETVAL = THIS->IsItemPresent(arg1);
		OUTPUT:
		RETVAL


static vtkCollection*
vtkCollection::New()
		CODE:
		RETVAL = vtkCollection::New();
		OUTPUT:
		RETVAL


void
vtkCollection::RemoveAllItems()
		CODE:
		THIS->RemoveAllItems();
		XSRETURN_EMPTY;


void
vtkCollection::RemoveItem(arg1 = 0)
	CASE: items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1),"Graphics::VTK::Object")
		vtkObject *	arg1
		CODE:
		THIS->RemoveItem(arg1);
		XSRETURN_EMPTY;
	CASE: items == 2 && SvIOK(ST(1))
		int 	arg1
		CODE:
		THIS->RemoveItem(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCollection::RemoveItem\n");



void
vtkCollection::ReplaceItem(i, arg2)
		int 	i
		vtkObject *	arg2
		CODE:
		THIS->ReplaceItem(i, arg2);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::ContourValues PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkContourValues::GenerateValues(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->GenerateValues(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkContourValues::GenerateValues\n");



const char *
vtkContourValues::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkContourValues::GetNumberOfContours()
		CODE:
		RETVAL = THIS->GetNumberOfContours();
		OUTPUT:
		RETVAL


float
vtkContourValues::GetValue(i)
		int 	i
		CODE:
		RETVAL = THIS->GetValue(i);
		OUTPUT:
		RETVAL


static vtkContourValues*
vtkContourValues::New()
		CODE:
		RETVAL = vtkContourValues::New();
		OUTPUT:
		RETVAL


void
vtkContourValues::SetNumberOfContours(number)
		const int 	number
		CODE:
		THIS->SetNumberOfContours(number);
		XSRETURN_EMPTY;


void
vtkContourValues::SetValue(i, value)
		int 	i
		float 	value
		CODE:
		THIS->SetValue(i, value);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Coordinate PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkCoordinate::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int *
vtkCoordinate::GetComputedDisplayValue(arg1)
		vtkViewport *	arg1
		PREINIT:
		int * retval;
		CODE:
		SP -= items;
		retval = THIS->GetComputedDisplayValue(arg1);
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


float *
vtkCoordinate::GetComputedFloatDisplayValue(arg1)
		vtkViewport *	arg1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetComputedFloatDisplayValue(arg1);
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


float *
vtkCoordinate::GetComputedFloatViewportValue(arg1)
		vtkViewport *	arg1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetComputedFloatViewportValue(arg1);
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


int *
vtkCoordinate::GetComputedLocalDisplayValue(arg1)
		vtkViewport *	arg1
		PREINIT:
		int * retval;
		CODE:
		SP -= items;
		retval = THIS->GetComputedLocalDisplayValue(arg1);
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


int *
vtkCoordinate::GetComputedViewportValue(arg1)
		vtkViewport *	arg1
		PREINIT:
		int * retval;
		CODE:
		SP -= items;
		retval = THIS->GetComputedViewportValue(arg1);
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


float *
vtkCoordinate::GetComputedWorldValue(arg1)
		vtkViewport *	arg1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetComputedWorldValue(arg1);
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int
vtkCoordinate::GetCoordinateSystem()
		CODE:
		RETVAL = THIS->GetCoordinateSystem();
		OUTPUT:
		RETVAL


const char *
vtkCoordinate::GetCoordinateSystemAsString()
		CODE:
		RETVAL = THIS->GetCoordinateSystemAsString();
		OUTPUT:
		RETVAL


vtkCoordinate *
vtkCoordinate::GetReferenceCoordinate()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCoordinate";
		CODE:
		RETVAL = THIS->GetReferenceCoordinate();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float  *
vtkCoordinate::GetValue()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetValue();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


vtkViewport *
vtkCoordinate::GetViewport()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkViewport";
		CODE:
		RETVAL = THIS->GetViewport();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkCoordinate*
vtkCoordinate::New()
		CODE:
		RETVAL = vtkCoordinate::New();
		OUTPUT:
		RETVAL


void
vtkCoordinate::SetCoordinateSystem(arg1)
		int 	arg1
		CODE:
		THIS->SetCoordinateSystem(arg1);
		XSRETURN_EMPTY;


void
vtkCoordinate::SetCoordinateSystemToDisplay()
		CODE:
		THIS->SetCoordinateSystemToDisplay();
		XSRETURN_EMPTY;


void
vtkCoordinate::SetCoordinateSystemToNormalizedDisplay()
		CODE:
		THIS->SetCoordinateSystemToNormalizedDisplay();
		XSRETURN_EMPTY;


void
vtkCoordinate::SetCoordinateSystemToNormalizedViewport()
		CODE:
		THIS->SetCoordinateSystemToNormalizedViewport();
		XSRETURN_EMPTY;


void
vtkCoordinate::SetCoordinateSystemToView()
		CODE:
		THIS->SetCoordinateSystemToView();
		XSRETURN_EMPTY;


void
vtkCoordinate::SetCoordinateSystemToViewport()
		CODE:
		THIS->SetCoordinateSystemToViewport();
		XSRETURN_EMPTY;


void
vtkCoordinate::SetCoordinateSystemToWorld()
		CODE:
		THIS->SetCoordinateSystemToWorld();
		XSRETURN_EMPTY;


void
vtkCoordinate::SetReferenceCoordinate(arg1)
		vtkCoordinate *	arg1
		CODE:
		THIS->SetReferenceCoordinate(arg1);
		XSRETURN_EMPTY;


void
vtkCoordinate::SetValue(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetValue(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetValue(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkCoordinate::SetValue\n");



void
vtkCoordinate::SetViewport(viewport)
		vtkViewport *	viewport
		CODE:
		THIS->SetViewport(viewport);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::CriticalSection PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkCriticalSection::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


void
vtkCriticalSection::Lock()
		CODE:
		THIS->Lock();
		XSRETURN_EMPTY;


static vtkCriticalSection*
vtkCriticalSection::New()
		CODE:
		RETVAL = vtkCriticalSection::New();
		OUTPUT:
		RETVAL


void
vtkCriticalSection::Unlock()
		CODE:
		THIS->Unlock();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::DataArray PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkDataArray::Allocate(sz, ext)
		const long 	sz
		const long 	ext
		CODE:
		RETVAL = THIS->Allocate(sz, ext);
		OUTPUT:
		RETVAL


void
vtkDataArray::ComputeRange(comp)
		int 	comp
		CODE:
		THIS->ComputeRange(comp);
		XSRETURN_EMPTY;


void
vtkDataArray::CopyComponent(j, from, fromComponent)
		const int 	j
		vtkDataArray *	from
		const int 	fromComponent
		CODE:
		THIS->CopyComponent(j, from, fromComponent);
		XSRETURN_EMPTY;


static vtkDataArray *
vtkDataArray::CreateDataArray(dataType)
		int 	dataType
		CODE:
		RETVAL = vtkDataArray::CreateDataArray(dataType);
		OUTPUT:
		RETVAL


void
vtkDataArray::CreateDefaultLookupTable()
		CODE:
		THIS->CreateDefaultLookupTable();
		XSRETURN_EMPTY;


void
vtkDataArray::DeepCopy(da)
		vtkDataArray *	da
		CODE:
		THIS->DeepCopy(da);
		XSRETURN_EMPTY;


void
vtkDataArray::FillComponent(j, c)
		const int 	j
		const float 	c
		CODE:
		THIS->FillComponent(j, c);
		XSRETURN_EMPTY;


unsigned long
vtkDataArray::GetActualMemorySize()
		CODE:
		RETVAL = THIS->GetActualMemorySize();
		OUTPUT:
		RETVAL


const char *
vtkDataArray::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkDataArray::GetComponent(i, j)
		const long 	i
		const int 	j
		CODE:
		RETVAL = THIS->GetComponent(i, j);
		OUTPUT:
		RETVAL


void
vtkDataArray::GetData(tupleMin, tupleMax, compMin, compMax, data)
		long 	tupleMin
		long 	tupleMax
		int 	compMin
		int 	compMax
		vtkFloatArray *	data
		CODE:
		THIS->GetData(tupleMin, tupleMax, compMin, compMax, data);
		XSRETURN_EMPTY;


int
vtkDataArray::GetDataType()
		CODE:
		RETVAL = THIS->GetDataType();
		OUTPUT:
		RETVAL


double
vtkDataArray::GetDataTypeMax()
		CODE:
		RETVAL = THIS->GetDataTypeMax();
		OUTPUT:
		RETVAL


double
vtkDataArray::GetDataTypeMin()
		CODE:
		RETVAL = THIS->GetDataTypeMin();
		OUTPUT:
		RETVAL



vtkLookupTable *
vtkDataArray::GetLookupTable()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkLookupTable";
		CODE:
		RETVAL = THIS->GetLookupTable();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


long
vtkDataArray::GetMaxId()
		CODE:
		RETVAL = THIS->GetMaxId();
		OUTPUT:
		RETVAL


float
vtkDataArray::GetMaxNorm()
		CODE:
		RETVAL = THIS->GetMaxNorm();
		OUTPUT:
		RETVAL


const char *
vtkDataArray::GetName()
		CODE:
		RETVAL = THIS->GetName();
		OUTPUT:
		RETVAL


int
vtkDataArray::GetNumberOfComponents()
		CODE:
		RETVAL = THIS->GetNumberOfComponents();
		OUTPUT:
		RETVAL


int
vtkDataArray::GetNumberOfComponentsMaxValue()
		CODE:
		RETVAL = THIS->GetNumberOfComponentsMaxValue();
		OUTPUT:
		RETVAL


int
vtkDataArray::GetNumberOfComponentsMinValue()
		CODE:
		RETVAL = THIS->GetNumberOfComponentsMinValue();
		OUTPUT:
		RETVAL


long
vtkDataArray::GetNumberOfTuples()
		CODE:
		RETVAL = THIS->GetNumberOfTuples();
		OUTPUT:
		RETVAL


float *
vtkDataArray::GetRange(arg1 = 0)
	CASE: items == 2
		int 	arg1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetRange(arg1);
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;
	CASE: items == 1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetRange();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataArray::GetRange\n");



long
vtkDataArray::GetSize()
		CODE:
		RETVAL = THIS->GetSize();
		OUTPUT:
		RETVAL


float
vtkDataArray::GetTuple1(i)
		const long 	i
		CODE:
		RETVAL = THIS->GetTuple1(i);
		OUTPUT:
		RETVAL


float *
vtkDataArray::GetTuple2(i)
		const long 	i
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetTuple2(i);
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


float *
vtkDataArray::GetTuple3(i)
		const long 	i
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetTuple3(i);
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float *
vtkDataArray::GetTuple4(i)
		const long 	i
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetTuple4(i);
		EXTEND(SP, 4);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUTBACK;
		return;


float *
vtkDataArray::GetTuple9(i)
		const long 	i
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetTuple9(i);
		EXTEND(SP, 9);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUSHs(sv_2mortal(newSVnv(retval[6])));
		PUSHs(sv_2mortal(newSVnv(retval[7])));
		PUSHs(sv_2mortal(newSVnv(retval[8])));
		PUTBACK;
		return;


void
vtkDataArray::GetTuples(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		long 	arg1
		long 	arg2
		vtkDataArray *	arg3
		CODE:
		THIS->GetTuples(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE: items == 3
		vtkIdList *	arg1
		vtkDataArray *	arg2
		CODE:
		THIS->GetTuples(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataArray::GetTuples\n");



void
vtkDataArray::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


void
vtkDataArray::InsertComponent(i, j, c)
		const long 	i
		const int 	j
		const float 	c
		CODE:
		THIS->InsertComponent(i, j, c);
		XSRETURN_EMPTY;


void
vtkDataArray::InsertNextTuple1(value)
		float 	value
		CODE:
		THIS->InsertNextTuple1(value);
		XSRETURN_EMPTY;


void
vtkDataArray::InsertNextTuple2(val0, val1)
		float 	val0
		float 	val1
		CODE:
		THIS->InsertNextTuple2(val0, val1);
		XSRETURN_EMPTY;


void
vtkDataArray::InsertNextTuple3(val0, val1, val2)
		float 	val0
		float 	val1
		float 	val2
		CODE:
		THIS->InsertNextTuple3(val0, val1, val2);
		XSRETURN_EMPTY;


void
vtkDataArray::InsertNextTuple4(val0, val1, val2, val3)
		float 	val0
		float 	val1
		float 	val2
		float 	val3
		CODE:
		THIS->InsertNextTuple4(val0, val1, val2, val3);
		XSRETURN_EMPTY;


void
vtkDataArray::InsertNextTuple9(val0, val1, val2, val3, val4, val5, val6, val7, val8)
		float 	val0
		float 	val1
		float 	val2
		float 	val3
		float 	val4
		float 	val5
		float 	val6
		float 	val7
		float 	val8
		CODE:
		THIS->InsertNextTuple9(val0, val1, val2, val3, val4, val5, val6, val7, val8);
		XSRETURN_EMPTY;


void
vtkDataArray::InsertTuple1(i, value)
		const long 	i
		float 	value
		CODE:
		THIS->InsertTuple1(i, value);
		XSRETURN_EMPTY;


void
vtkDataArray::InsertTuple2(i, val0, val1)
		const long 	i
		float 	val0
		float 	val1
		CODE:
		THIS->InsertTuple2(i, val0, val1);
		XSRETURN_EMPTY;


void
vtkDataArray::InsertTuple3(i, val0, val1, val2)
		const long 	i
		float 	val0
		float 	val1
		float 	val2
		CODE:
		THIS->InsertTuple3(i, val0, val1, val2);
		XSRETURN_EMPTY;


void
vtkDataArray::InsertTuple4(i, val0, val1, val2, val3)
		const long 	i
		float 	val0
		float 	val1
		float 	val2
		float 	val3
		CODE:
		THIS->InsertTuple4(i, val0, val1, val2, val3);
		XSRETURN_EMPTY;


void
vtkDataArray::InsertTuple9(i, val0, val1, val2, val3, val4, val5, val6, val7, val8)
		const long 	i
		float 	val0
		float 	val1
		float 	val2
		float 	val3
		float 	val4
		float 	val5
		float 	val6
		float 	val7
		float 	val8
		CODE:
		THIS->InsertTuple9(i, val0, val1, val2, val3, val4, val5, val6, val7, val8);
		XSRETURN_EMPTY;


void
vtkDataArray::Reset()
		CODE:
		THIS->Reset();
		XSRETURN_EMPTY;


void
vtkDataArray::Resize(numTuples)
		long 	numTuples
		CODE:
		THIS->Resize(numTuples);
		XSRETURN_EMPTY;


void
vtkDataArray::SetComponent(i, j, c)
		const long 	i
		const int 	j
		const float 	c
		CODE:
		THIS->SetComponent(i, j, c);
		XSRETURN_EMPTY;


void
vtkDataArray::SetLookupTable(lut)
		vtkLookupTable *	lut
		CODE:
		THIS->SetLookupTable(lut);
		XSRETURN_EMPTY;


void
vtkDataArray::SetName(name)
		const char *	name
		CODE:
		THIS->SetName(name);
		XSRETURN_EMPTY;


void
vtkDataArray::SetNumberOfComponents(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfComponents(arg1);
		XSRETURN_EMPTY;


void
vtkDataArray::SetNumberOfTuples(number)
		const long 	number
		CODE:
		THIS->SetNumberOfTuples(number);
		XSRETURN_EMPTY;


void
vtkDataArray::SetTuple1(i, value)
		const long 	i
		float 	value
		CODE:
		THIS->SetTuple1(i, value);
		XSRETURN_EMPTY;


void
vtkDataArray::SetTuple2(i, val0, val1)
		const long 	i
		float 	val0
		float 	val1
		CODE:
		THIS->SetTuple2(i, val0, val1);
		XSRETURN_EMPTY;


void
vtkDataArray::SetTuple3(i, val0, val1, val2)
		const long 	i
		float 	val0
		float 	val1
		float 	val2
		CODE:
		THIS->SetTuple3(i, val0, val1, val2);
		XSRETURN_EMPTY;


void
vtkDataArray::SetTuple4(i, val0, val1, val2, val3)
		const long 	i
		float 	val0
		float 	val1
		float 	val2
		float 	val3
		CODE:
		THIS->SetTuple4(i, val0, val1, val2, val3);
		XSRETURN_EMPTY;


void
vtkDataArray::SetTuple9(i, val0, val1, val2, val3, val4, val5, val6, val7, val8)
		const long 	i
		float 	val0
		float 	val1
		float 	val2
		float 	val3
		float 	val4
		float 	val5
		float 	val6
		float 	val7
		float 	val8
		CODE:
		THIS->SetTuple9(i, val0, val1, val2, val3, val4, val5, val6, val7, val8);
		XSRETURN_EMPTY;


void
vtkDataArray::Squeeze()
		CODE:
		THIS->Squeeze();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::DataObject PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkDataObject::AddConsumer(c)
		vtkProcessObject *	c
		CODE:
		THIS->AddConsumer(c);
		XSRETURN_EMPTY;


void
vtkDataObject::CopyInformation(data)
		vtkDataObject *	data
		CODE:
		THIS->CopyInformation(data);
		XSRETURN_EMPTY;


void
vtkDataObject::CopyTypeSpecificInformation(data)
		vtkDataObject *	data
		CODE:
		THIS->CopyTypeSpecificInformation(data);
		XSRETURN_EMPTY;


void
vtkDataObject::DataHasBeenGenerated()
		CODE:
		THIS->DataHasBeenGenerated();
		XSRETURN_EMPTY;


void
vtkDataObject::DeepCopy(src)
		vtkDataObject *	src
		CODE:
		THIS->DeepCopy(src);
		XSRETURN_EMPTY;


unsigned long
vtkDataObject::GetActualMemorySize()
		CODE:
		RETVAL = THIS->GetActualMemorySize();
		OUTPUT:
		RETVAL


const char *
vtkDataObject::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkProcessObject *
vtkDataObject::GetConsumer(i)
		int 	i
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkProcessObject";
		CODE:
		RETVAL = THIS->GetConsumer(i);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkDataObject::GetDataObjectType()
		CODE:
		RETVAL = THIS->GetDataObjectType();
		OUTPUT:
		RETVAL


int
vtkDataObject::GetDataReleased()
		CODE:
		RETVAL = THIS->GetDataReleased();
		OUTPUT:
		RETVAL


unsigned long
vtkDataObject::GetEstimatedMemorySize()
		CODE:
		RETVAL = THIS->GetEstimatedMemorySize();
		OUTPUT:
		RETVAL


vtkExtentTranslator *
vtkDataObject::GetExtentTranslator()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkExtentTranslator";
		CODE:
		RETVAL = THIS->GetExtentTranslator();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkFieldData *
vtkDataObject::GetFieldData()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkFieldData";
		CODE:
		RETVAL = THIS->GetFieldData();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static int
vtkDataObject::GetGlobalReleaseDataFlag()
		CODE:
		RETVAL = vtkDataObject::GetGlobalReleaseDataFlag();
		OUTPUT:
		RETVAL


float
vtkDataObject::GetLocality()
		CODE:
		RETVAL = THIS->GetLocality();
		OUTPUT:
		RETVAL


unsigned long
vtkDataObject::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkDataObject::GetMaximumNumberOfPieces()
		CODE:
		RETVAL = THIS->GetMaximumNumberOfPieces();
		OUTPUT:
		RETVAL


int
vtkDataObject::GetNetReferenceCount()
		CODE:
		RETVAL = THIS->GetNetReferenceCount();
		OUTPUT:
		RETVAL


int
vtkDataObject::GetNumberOfConsumers()
		CODE:
		RETVAL = THIS->GetNumberOfConsumers();
		OUTPUT:
		RETVAL


unsigned long
vtkDataObject::GetPipelineMTime()
		CODE:
		RETVAL = THIS->GetPipelineMTime();
		OUTPUT:
		RETVAL


int
vtkDataObject::GetReleaseDataFlag()
		CODE:
		RETVAL = THIS->GetReleaseDataFlag();
		OUTPUT:
		RETVAL


int
vtkDataObject::GetRequestExactExtent()
		CODE:
		RETVAL = THIS->GetRequestExactExtent();
		OUTPUT:
		RETVAL


vtkSource *
vtkDataObject::GetSource()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkSource";
		CODE:
		RETVAL = THIS->GetSource();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int  *
vtkDataObject::GetUpdateExtent()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetUpdateExtent();
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
vtkDataObject::GetUpdateGhostLevel()
		CODE:
		RETVAL = THIS->GetUpdateGhostLevel();
		OUTPUT:
		RETVAL


int
vtkDataObject::GetUpdateNumberOfPieces()
		CODE:
		RETVAL = THIS->GetUpdateNumberOfPieces();
		OUTPUT:
		RETVAL


int
vtkDataObject::GetUpdatePiece()
		CODE:
		RETVAL = THIS->GetUpdatePiece();
		OUTPUT:
		RETVAL


unsigned long
vtkDataObject::GetUpdateTime()
		CODE:
		RETVAL = THIS->GetUpdateTime();
		OUTPUT:
		RETVAL


int  *
vtkDataObject::GetWholeExtent()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetWholeExtent();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;


void
vtkDataObject::GlobalReleaseDataFlagOff()
		CODE:
		THIS->GlobalReleaseDataFlagOff();
		XSRETURN_EMPTY;


void
vtkDataObject::GlobalReleaseDataFlagOn()
		CODE:
		THIS->GlobalReleaseDataFlagOn();
		XSRETURN_EMPTY;


void
vtkDataObject::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


int
vtkDataObject::IsConsumer(c)
		vtkProcessObject *	c
		CODE:
		RETVAL = THIS->IsConsumer(c);
		OUTPUT:
		RETVAL


static vtkDataObject*
vtkDataObject::New()
		CODE:
		RETVAL = vtkDataObject::New();
		OUTPUT:
		RETVAL


void
vtkDataObject::PrepareForNewData()
		CODE:
		THIS->PrepareForNewData();
		XSRETURN_EMPTY;


void
vtkDataObject::PropagateUpdateExtent()
		CODE:
		THIS->PropagateUpdateExtent();
		XSRETURN_EMPTY;


void
vtkDataObject::ReleaseData()
		CODE:
		THIS->ReleaseData();
		XSRETURN_EMPTY;


void
vtkDataObject::ReleaseDataFlagOff()
		CODE:
		THIS->ReleaseDataFlagOff();
		XSRETURN_EMPTY;


void
vtkDataObject::ReleaseDataFlagOn()
		CODE:
		THIS->ReleaseDataFlagOn();
		XSRETURN_EMPTY;


void
vtkDataObject::RemoveConsumer(c)
		vtkProcessObject *	c
		CODE:
		THIS->RemoveConsumer(c);
		XSRETURN_EMPTY;


void
vtkDataObject::RequestExactExtentOff()
		CODE:
		THIS->RequestExactExtentOff();
		XSRETURN_EMPTY;


void
vtkDataObject::RequestExactExtentOn()
		CODE:
		THIS->RequestExactExtentOn();
		XSRETURN_EMPTY;


void
vtkDataObject::SetExtentTranslator(translator)
		vtkExtentTranslator *	translator
		CODE:
		THIS->SetExtentTranslator(translator);
		XSRETURN_EMPTY;


void
vtkDataObject::SetFieldData(arg1)
		vtkFieldData *	arg1
		CODE:
		THIS->SetFieldData(arg1);
		XSRETURN_EMPTY;


static void
vtkDataObject::SetGlobalReleaseDataFlag(val)
		int 	val
		CODE:
		vtkDataObject::SetGlobalReleaseDataFlag(val);
		XSRETURN_EMPTY;


void
vtkDataObject::SetLocality(arg1)
		float 	arg1
		CODE:
		THIS->SetLocality(arg1);
		XSRETURN_EMPTY;


void
vtkDataObject::SetMaximumNumberOfPieces(arg1)
		int 	arg1
		CODE:
		THIS->SetMaximumNumberOfPieces(arg1);
		XSRETURN_EMPTY;


void
vtkDataObject::SetPipelineMTime(time)
		unsigned long 	time
		CODE:
		THIS->SetPipelineMTime(time);
		XSRETURN_EMPTY;


void
vtkDataObject::SetReleaseDataFlag(arg1)
		int 	arg1
		CODE:
		THIS->SetReleaseDataFlag(arg1);
		XSRETURN_EMPTY;


void
vtkDataObject::SetRequestExactExtent(v)
		int 	v
		CODE:
		THIS->SetRequestExactExtent(v);
		XSRETURN_EMPTY;


void
vtkDataObject::SetSource(s)
		vtkSource *	s
		CODE:
		THIS->SetSource(s);
		XSRETURN_EMPTY;


void
vtkDataObject::SetUpdateExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetUpdateExtent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetUpdateExtent(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetUpdateExtent(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataObject::SetUpdateExtent\n");



void
vtkDataObject::SetUpdateExtentToWholeExtent()
		CODE:
		THIS->SetUpdateExtentToWholeExtent();
		XSRETURN_EMPTY;


void
vtkDataObject::SetUpdateGhostLevel(level)
		int 	level
		CODE:
		THIS->SetUpdateGhostLevel(level);
		XSRETURN_EMPTY;


void
vtkDataObject::SetUpdateNumberOfPieces(num)
		int 	num
		CODE:
		THIS->SetUpdateNumberOfPieces(num);
		XSRETURN_EMPTY;


void
vtkDataObject::SetUpdatePiece(piece)
		int 	piece
		CODE:
		THIS->SetUpdatePiece(piece);
		XSRETURN_EMPTY;


void
vtkDataObject::SetWholeExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetWholeExtent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataObject::SetWholeExtent\n");



void
vtkDataObject::ShallowCopy(src)
		vtkDataObject *	src
		CODE:
		THIS->ShallowCopy(src);
		XSRETURN_EMPTY;


int
vtkDataObject::ShouldIReleaseData()
		CODE:
		RETVAL = THIS->ShouldIReleaseData();
		OUTPUT:
		RETVAL


void
vtkDataObject::TriggerAsynchronousUpdate()
		CODE:
		THIS->TriggerAsynchronousUpdate();
		XSRETURN_EMPTY;


void
vtkDataObject::UnRegister(o)
		vtkObject *	o
		CODE:
		THIS->UnRegister(o);
		XSRETURN_EMPTY;


void
vtkDataObject::Update()
		CODE:
		THIS->Update();
		XSRETURN_EMPTY;


void
vtkDataObject::UpdateData()
		CODE:
		THIS->UpdateData();
		XSRETURN_EMPTY;


void
vtkDataObject::UpdateInformation()
		CODE:
		THIS->UpdateInformation();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::DataObjectCollection PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkDataObjectCollection::AddItem(arg1 = 0)
	CASE: items == 2
		vtkDataObject *	arg1
		CODE:
		THIS->AddItem(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataObjectCollection::AddItem\n");



const char *
vtkDataObjectCollection::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataObject *
vtkDataObjectCollection::GetItem(i)
		int 	i
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataObject";
		CODE:
		RETVAL = THIS->GetItem(i);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkDataObject *
vtkDataObjectCollection::GetNextItem()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataObject";
		CODE:
		RETVAL = THIS->GetNextItem();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkDataObjectCollection*
vtkDataObjectCollection::New()
		CODE:
		RETVAL = vtkDataObjectCollection::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::DataSet PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkDataSet::ComputeBounds()
		CODE:
		THIS->ComputeBounds();
		XSRETURN_EMPTY;


void
vtkDataSet::CopyStructure(ds)
		vtkDataSet *	ds
		CODE:
		THIS->CopyStructure(ds);
		XSRETURN_EMPTY;


void
vtkDataSet::DeepCopy(src)
		vtkDataObject *	src
		CODE:
		THIS->DeepCopy(src);
		XSRETURN_EMPTY;


long
vtkDataSet::FindPoint(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		RETVAL = THIS->FindPoint(arg1, arg2, arg3);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataSet::FindPoint\n");



unsigned long
vtkDataSet::GetActualMemorySize()
		CODE:
		RETVAL = THIS->GetActualMemorySize();
		OUTPUT:
		RETVAL


float *
vtkDataSet::GetBounds()
	CASE: items == 1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetBounds();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataSet::GetBounds\n");



vtkCell *
vtkDataSet::GetCell(arg1 = 0, arg2 = 0)
	CASE: items == 3
		long 	arg1
		vtkGenericCell *	arg2
		CODE:
		THIS->GetCell(arg1, arg2);
		XSRETURN_EMPTY;
	CASE: items == 2
		long 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetCell(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataSet::GetCell\n");



vtkCellData *
vtkDataSet::GetCellData()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCellData";
		CODE:
		RETVAL = THIS->GetCellData();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkDataSet::GetCellNeighbors(cellId, ptIds, cellIds)
		long 	cellId
		vtkIdList *	ptIds
		vtkIdList *	cellIds
		CODE:
		THIS->GetCellNeighbors(cellId, ptIds, cellIds);
		XSRETURN_EMPTY;


void
vtkDataSet::GetCellPoints(cellId, ptIds)
		long 	cellId
		vtkIdList *	ptIds
		CODE:
		THIS->GetCellPoints(cellId, ptIds);
		XSRETURN_EMPTY;


int
vtkDataSet::GetCellType(cellId)
		long 	cellId
		CODE:
		RETVAL = THIS->GetCellType(cellId);
		OUTPUT:
		RETVAL


void
vtkDataSet::GetCellTypes(types)
		vtkCellTypes *	types
		CODE:
		THIS->GetCellTypes(types);
		XSRETURN_EMPTY;


float *
vtkDataSet::GetCenter()
	CASE: items == 1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetCenter();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataSet::GetCenter\n");



const char *
vtkDataSet::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkDataSet::GetDataObjectType()
		CODE:
		RETVAL = THIS->GetDataObjectType();
		OUTPUT:
		RETVAL


float
vtkDataSet::GetLength()
		CODE:
		RETVAL = THIS->GetLength();
		OUTPUT:
		RETVAL


unsigned long
vtkDataSet::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkDataSet::GetMaxCellSize()
		CODE:
		RETVAL = THIS->GetMaxCellSize();
		OUTPUT:
		RETVAL


long
vtkDataSet::GetNumberOfCells()
		CODE:
		RETVAL = THIS->GetNumberOfCells();
		OUTPUT:
		RETVAL


long
vtkDataSet::GetNumberOfPoints()
		CODE:
		RETVAL = THIS->GetNumberOfPoints();
		OUTPUT:
		RETVAL


float *
vtkDataSet::GetPoint(arg1 = 0)
	CASE: items == 2
		long 	arg1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPoint(arg1);
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataSet::GetPoint\n");



void
vtkDataSet::GetPointCells(ptId, cellIds)
		long 	ptId
		vtkIdList *	cellIds
		CODE:
		THIS->GetPointCells(ptId, cellIds);
		XSRETURN_EMPTY;


vtkPointData *
vtkDataSet::GetPointData()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPointData";
		CODE:
		RETVAL = THIS->GetPointData();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float *
vtkDataSet::GetScalarRange()
	CASE: items == 1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetScalarRange();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataSet::GetScalarRange\n");



void
vtkDataSet::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


void
vtkDataSet::ShallowCopy(src)
		vtkDataObject *	src
		CODE:
		THIS->ShallowCopy(src);
		XSRETURN_EMPTY;


void
vtkDataSet::Squeeze()
		CODE:
		THIS->Squeeze();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::DataSetAttributes PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkDataSetAttributes::CopyAllOff()
		CODE:
		THIS->CopyAllOff();
		XSRETURN_EMPTY;


void
vtkDataSetAttributes::CopyAllOn()
		CODE:
		THIS->CopyAllOn();
		XSRETURN_EMPTY;


void
vtkDataSetAttributes::CopyAllocate(pd, sze, ext)
		vtkDataSetAttributes *	pd
		long 	sze
		long 	ext
		CODE:
		THIS->CopyAllocate(pd, sze, ext);
		XSRETURN_EMPTY;


void
vtkDataSetAttributes::CopyData(fromPd, fromId, toId)
		vtkDataSetAttributes *	fromPd
		long 	fromId
		long 	toId
		CODE:
		THIS->CopyData(fromPd, fromId, toId);
		XSRETURN_EMPTY;


void
vtkDataSetAttributes::CopyNormalsOff()
		CODE:
		THIS->CopyNormalsOff();
		XSRETURN_EMPTY;


void
vtkDataSetAttributes::CopyNormalsOn()
		CODE:
		THIS->CopyNormalsOn();
		XSRETURN_EMPTY;


void
vtkDataSetAttributes::CopyScalarsOff()
		CODE:
		THIS->CopyScalarsOff();
		XSRETURN_EMPTY;


void
vtkDataSetAttributes::CopyScalarsOn()
		CODE:
		THIS->CopyScalarsOn();
		XSRETURN_EMPTY;


void
vtkDataSetAttributes::CopyTCoordsOff()
		CODE:
		THIS->CopyTCoordsOff();
		XSRETURN_EMPTY;


void
vtkDataSetAttributes::CopyTCoordsOn()
		CODE:
		THIS->CopyTCoordsOn();
		XSRETURN_EMPTY;


void
vtkDataSetAttributes::CopyTensorsOff()
		CODE:
		THIS->CopyTensorsOff();
		XSRETURN_EMPTY;


void
vtkDataSetAttributes::CopyTensorsOn()
		CODE:
		THIS->CopyTensorsOn();
		XSRETURN_EMPTY;


void
vtkDataSetAttributes::CopyTuple(fromData, toData, fromId, toId)
		vtkDataArray *	fromData
		vtkDataArray *	toData
		long 	fromId
		long 	toId
		CODE:
		THIS->CopyTuple(fromData, toData, fromId, toId);
		XSRETURN_EMPTY;


void
vtkDataSetAttributes::CopyVectorsOff()
		CODE:
		THIS->CopyVectorsOff();
		XSRETURN_EMPTY;


void
vtkDataSetAttributes::CopyVectorsOn()
		CODE:
		THIS->CopyVectorsOn();
		XSRETURN_EMPTY;


void
vtkDataSetAttributes::DeepCopy(pd)
		vtkFieldData *	pd
		CODE:
		THIS->DeepCopy(pd);
		XSRETURN_EMPTY;


vtkDataArray *
vtkDataSetAttributes::GetAttribute(attributeType)
		int 	attributeType
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataArray";
		CODE:
		RETVAL = THIS->GetAttribute(attributeType);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


const char *
vtkDataSetAttributes::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkDataSetAttributes::GetCopyNormals()
		CODE:
		RETVAL = THIS->GetCopyNormals();
		OUTPUT:
		RETVAL


int
vtkDataSetAttributes::GetCopyScalars()
		CODE:
		RETVAL = THIS->GetCopyScalars();
		OUTPUT:
		RETVAL


int
vtkDataSetAttributes::GetCopyTCoords()
		CODE:
		RETVAL = THIS->GetCopyTCoords();
		OUTPUT:
		RETVAL


int
vtkDataSetAttributes::GetCopyTensors()
		CODE:
		RETVAL = THIS->GetCopyTensors();
		OUTPUT:
		RETVAL


int
vtkDataSetAttributes::GetCopyVectors()
		CODE:
		RETVAL = THIS->GetCopyVectors();
		OUTPUT:
		RETVAL


vtkDataArray *
vtkDataSetAttributes::GetNormals()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataArray";
		CODE:
		RETVAL = THIS->GetNormals();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkDataArray *
vtkDataSetAttributes::GetScalars()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataArray";
		CODE:
		RETVAL = THIS->GetScalars();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkDataArray *
vtkDataSetAttributes::GetTCoords()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataArray";
		CODE:
		RETVAL = THIS->GetTCoords();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkDataArray *
vtkDataSetAttributes::GetTensors()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataArray";
		CODE:
		RETVAL = THIS->GetTensors();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkDataArray *
vtkDataSetAttributes::GetVectors()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataArray";
		CODE:
		RETVAL = THIS->GetVectors();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkDataSetAttributes::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


void
vtkDataSetAttributes::InterpolateAllocate(pd, sze, ext)
		vtkDataSetAttributes *	pd
		long 	sze
		long 	ext
		CODE:
		THIS->InterpolateAllocate(pd, sze, ext);
		XSRETURN_EMPTY;


void
vtkDataSetAttributes::InterpolateEdge(fromPd, toId, p1, p2, t)
		vtkDataSetAttributes *	fromPd
		long 	toId
		long 	p1
		long 	p2
		float 	t
		CODE:
		THIS->InterpolateEdge(fromPd, toId, p1, p2, t);
		XSRETURN_EMPTY;


void
vtkDataSetAttributes::InterpolateTime(from1, from2, id, t)
		vtkDataSetAttributes *	from1
		vtkDataSetAttributes *	from2
		long 	id
		float 	t
		CODE:
		THIS->InterpolateTime(from1, from2, id, t);
		XSRETURN_EMPTY;


int
vtkDataSetAttributes::IsArrayAnAttribute(idx)
		int 	idx
		CODE:
		RETVAL = THIS->IsArrayAnAttribute(idx);
		OUTPUT:
		RETVAL


static vtkDataSetAttributes*
vtkDataSetAttributes::New()
		CODE:
		RETVAL = vtkDataSetAttributes::New();
		OUTPUT:
		RETVAL


void
vtkDataSetAttributes::PassData(fd)
		vtkFieldData *	fd
		CODE:
		THIS->PassData(fd);
		XSRETURN_EMPTY;


void
vtkDataSetAttributes::RemoveArray(arg1 = 0)
	CASE: items == 2
		const char *	arg1
		CODE:
		THIS->RemoveArray(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataSetAttributes::RemoveArray\n");



int
vtkDataSetAttributes::SetActiveAttribute(arg1 = 0, arg2 = 0)
	CASE: items == 3 && SvPOK(ST(1))
		const char *	arg1
		int 	arg2
		CODE:
		RETVAL = THIS->SetActiveAttribute(arg1, arg2);
		OUTPUT:
		RETVAL
	CASE: items == 3 && SvIOK(ST(1))
		int 	arg1
		int 	arg2
		CODE:
		RETVAL = THIS->SetActiveAttribute(arg1, arg2);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataSetAttributes::SetActiveAttribute\n");



int
vtkDataSetAttributes::SetActiveNormals(name)
		const char *	name
		CODE:
		RETVAL = THIS->SetActiveNormals(name);
		OUTPUT:
		RETVAL


int
vtkDataSetAttributes::SetActiveScalars(name)
		const char *	name
		CODE:
		RETVAL = THIS->SetActiveScalars(name);
		OUTPUT:
		RETVAL


int
vtkDataSetAttributes::SetActiveTCoords(name)
		const char *	name
		CODE:
		RETVAL = THIS->SetActiveTCoords(name);
		OUTPUT:
		RETVAL


int
vtkDataSetAttributes::SetActiveTensors(name)
		const char *	name
		CODE:
		RETVAL = THIS->SetActiveTensors(name);
		OUTPUT:
		RETVAL


int
vtkDataSetAttributes::SetActiveVectors(name)
		const char *	name
		CODE:
		RETVAL = THIS->SetActiveVectors(name);
		OUTPUT:
		RETVAL


void
vtkDataSetAttributes::SetCopyAttribute(index, value)
		int 	index
		int 	value
		CODE:
		THIS->SetCopyAttribute(index, value);
		XSRETURN_EMPTY;


void
vtkDataSetAttributes::SetCopyNormals(i)
		int 	i
		CODE:
		THIS->SetCopyNormals(i);
		XSRETURN_EMPTY;


void
vtkDataSetAttributes::SetCopyScalars(i)
		int 	i
		CODE:
		THIS->SetCopyScalars(i);
		XSRETURN_EMPTY;


void
vtkDataSetAttributes::SetCopyTCoords(i)
		int 	i
		CODE:
		THIS->SetCopyTCoords(i);
		XSRETURN_EMPTY;


void
vtkDataSetAttributes::SetCopyTensors(i)
		int 	i
		CODE:
		THIS->SetCopyTensors(i);
		XSRETURN_EMPTY;


void
vtkDataSetAttributes::SetCopyVectors(i)
		int 	i
		CODE:
		THIS->SetCopyVectors(i);
		XSRETURN_EMPTY;


int
vtkDataSetAttributes::SetNormals(da)
		vtkDataArray *	da
		CODE:
		RETVAL = THIS->SetNormals(da);
		OUTPUT:
		RETVAL


int
vtkDataSetAttributes::SetScalars(da)
		vtkDataArray *	da
		CODE:
		RETVAL = THIS->SetScalars(da);
		OUTPUT:
		RETVAL


int
vtkDataSetAttributes::SetTCoords(da)
		vtkDataArray *	da
		CODE:
		RETVAL = THIS->SetTCoords(da);
		OUTPUT:
		RETVAL


int
vtkDataSetAttributes::SetTensors(da)
		vtkDataArray *	da
		CODE:
		RETVAL = THIS->SetTensors(da);
		OUTPUT:
		RETVAL


int
vtkDataSetAttributes::SetVectors(da)
		vtkDataArray *	da
		CODE:
		RETVAL = THIS->SetVectors(da);
		OUTPUT:
		RETVAL


void
vtkDataSetAttributes::ShallowCopy(pd)
		vtkFieldData *	pd
		CODE:
		THIS->ShallowCopy(pd);
		XSRETURN_EMPTY;


void
vtkDataSetAttributes::Update()
		CODE:
		THIS->Update();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::DataSetCollection PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkDataSetCollection::AddItem(arg1 = 0)
	CASE: items == 2
		vtkDataSet *	arg1
		CODE:
		THIS->AddItem(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkDataSetCollection::AddItem\n");



const char *
vtkDataSetCollection::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataSet *
vtkDataSetCollection::GetItem(i)
		int 	i
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetItem(i);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkDataSet *
vtkDataSetCollection::GetNextItem()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetNextItem();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkDataSetCollection*
vtkDataSetCollection::New()
		CODE:
		RETVAL = vtkDataSetCollection::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::DebugLeaks PREFIX = vtk

PROTOTYPES: DISABLE



static void
vtkDebugLeaks::ConstructClass(classname)
		const char *	classname
		CODE:
		vtkDebugLeaks::ConstructClass(classname);
		XSRETURN_EMPTY;


static void
vtkDebugLeaks::DeleteTable()
		CODE:
		vtkDebugLeaks::DeleteTable();
		XSRETURN_EMPTY;


static void
vtkDebugLeaks::DestructClass(classname)
		const char *	classname
		CODE:
		vtkDebugLeaks::DestructClass(classname);
		XSRETURN_EMPTY;


const char *
vtkDebugLeaks::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkDebugLeaks*
vtkDebugLeaks::New()
		CODE:
		RETVAL = vtkDebugLeaks::New();
		OUTPUT:
		RETVAL


static void
vtkDebugLeaks::PrintCurrentLeaks()
		CODE:
		vtkDebugLeaks::PrintCurrentLeaks();
		XSRETURN_EMPTY;


static void
vtkDebugLeaks::PromptUserOff()
		CODE:
		vtkDebugLeaks::PromptUserOff();
		XSRETURN_EMPTY;


static void
vtkDebugLeaks::PromptUserOn()
		CODE:
		vtkDebugLeaks::PromptUserOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Directory PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkDirectory::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


const char *
vtkDirectory::GetFile(index)
		int 	index
		CODE:
		RETVAL = THIS->GetFile(index);
		OUTPUT:
		RETVAL


int
vtkDirectory::GetNumberOfFiles()
		CODE:
		RETVAL = THIS->GetNumberOfFiles();
		OUTPUT:
		RETVAL


static vtkDirectory*
vtkDirectory::New()
		CODE:
		RETVAL = vtkDirectory::New();
		OUTPUT:
		RETVAL


int
vtkDirectory::Open(dir)
		const char *	dir
		CODE:
		RETVAL = THIS->Open(dir);
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::DoubleArray PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkDoubleArray::Allocate(sz, ext)
		const long 	sz
		const long 	ext
		CODE:
		RETVAL = THIS->Allocate(sz, ext);
		OUTPUT:
		RETVAL


void
vtkDoubleArray::DeepCopy(da)
		vtkDataArray *	da
		CODE:
		THIS->DeepCopy(da);
		XSRETURN_EMPTY;


const char *
vtkDoubleArray::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkDoubleArray::GetDataType()
		CODE:
		RETVAL = THIS->GetDataType();
		OUTPUT:
		RETVAL


double
vtkDoubleArray::GetValue(id)
		const long 	id
		CODE:
		RETVAL = THIS->GetValue(id);
		OUTPUT:
		RETVAL


void
vtkDoubleArray::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


void
vtkDoubleArray::InsertComponent(i, j, c)
		const long 	i
		const int 	j
		const float 	c
		CODE:
		THIS->InsertComponent(i, j, c);
		XSRETURN_EMPTY;


long
vtkDoubleArray::InsertNextValue(f)
		const double 	f
		CODE:
		RETVAL = THIS->InsertNextValue(f);
		OUTPUT:
		RETVAL


void
vtkDoubleArray::InsertValue(id, f)
		const long 	id
		const double 	f
		CODE:
		THIS->InsertValue(id, f);
		XSRETURN_EMPTY;


static vtkDoubleArray*
vtkDoubleArray::New()
		CODE:
		RETVAL = vtkDoubleArray::New();
		OUTPUT:
		RETVAL


void
vtkDoubleArray::Resize(numTuples)
		long 	numTuples
		CODE:
		THIS->Resize(numTuples);
		XSRETURN_EMPTY;


void
vtkDoubleArray::SetNumberOfTuples(number)
		const long 	number
		CODE:
		THIS->SetNumberOfTuples(number);
		XSRETURN_EMPTY;


void
vtkDoubleArray::SetNumberOfValues(number)
		const long 	number
		CODE:
		THIS->SetNumberOfValues(number);
		XSRETURN_EMPTY;


void
vtkDoubleArray::SetValue(id, value)
		const long 	id
		const double 	value
		CODE:
		THIS->SetValue(id, value);
		XSRETURN_EMPTY;


void
vtkDoubleArray::Squeeze()
		CODE:
		THIS->Squeeze();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::DynamicLoader PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkDynamicLoader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static const char *
vtkDynamicLoader::LastError()
		CODE:
		RETVAL = vtkDynamicLoader::LastError();
		OUTPUT:
		RETVAL


static const char *
vtkDynamicLoader::LibExtension()
		CODE:
		RETVAL = vtkDynamicLoader::LibExtension();
		OUTPUT:
		RETVAL


static const char *
vtkDynamicLoader::LibPrefix()
		CODE:
		RETVAL = vtkDynamicLoader::LibPrefix();
		OUTPUT:
		RETVAL


static vtkDynamicLoader*
vtkDynamicLoader::New()
		CODE:
		RETVAL = vtkDynamicLoader::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::EdgeTable PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkEdgeTable::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


long
vtkEdgeTable::GetNumberOfEdges()
		CODE:
		RETVAL = THIS->GetNumberOfEdges();
		OUTPUT:
		RETVAL


int
vtkEdgeTable::InitEdgeInsertion(numPoints, storeAttributes)
		long 	numPoints
		int 	storeAttributes
		CODE:
		RETVAL = THIS->InitEdgeInsertion(numPoints, storeAttributes);
		OUTPUT:
		RETVAL


int
vtkEdgeTable::InitPointInsertion(newPts, estSize)
		vtkPoints *	newPts
		long 	estSize
		CODE:
		RETVAL = THIS->InitPointInsertion(newPts, estSize);
		OUTPUT:
		RETVAL


void
vtkEdgeTable::InitTraversal()
		CODE:
		THIS->InitTraversal();
		XSRETURN_EMPTY;


void
vtkEdgeTable::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


long
vtkEdgeTable::InsertEdge(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		long 	arg1
		long 	arg2
		int 	arg3
		CODE:
		THIS->InsertEdge(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE: items == 3
		long 	arg1
		long 	arg2
		CODE:
		RETVAL = THIS->InsertEdge(arg1, arg2);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkEdgeTable::InsertEdge\n");



int
vtkEdgeTable::IsEdge(p1, p2)
		long 	p1
		long 	p2
		CODE:
		RETVAL = THIS->IsEdge(p1, p2);
		OUTPUT:
		RETVAL


static vtkEdgeTable*
vtkEdgeTable::New()
		CODE:
		RETVAL = vtkEdgeTable::New();
		OUTPUT:
		RETVAL


void
vtkEdgeTable::Reset()
		CODE:
		THIS->Reset();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::EmptyCell PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkEmptyCell::Clip(value, cellScalars, locator, pts, inPd, outPd, inCd, cellId, outCd, insideOut)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	pts
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		int 	insideOut
		CODE:
		THIS->Clip(value, cellScalars, locator, pts, inPd, outPd, inCd, cellId, outCd, insideOut);
		XSRETURN_EMPTY;


void
vtkEmptyCell::Contour(value, cellScalars, locator, verts1, lines, verts2, inPd, outPd, inCd, cellId, outCd)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	verts1
		vtkCellArray *	lines
		vtkCellArray *	verts2
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		CODE:
		THIS->Contour(value, cellScalars, locator, verts1, lines, verts2, inPd, outPd, inCd, cellId, outCd);
		XSRETURN_EMPTY;


int
vtkEmptyCell::GetCellDimension()
		CODE:
		RETVAL = THIS->GetCellDimension();
		OUTPUT:
		RETVAL


int
vtkEmptyCell::GetCellType()
		CODE:
		RETVAL = THIS->GetCellType();
		OUTPUT:
		RETVAL


const char *
vtkEmptyCell::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkCell *
vtkEmptyCell::GetEdge(arg1)
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetEdge(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkCell *
vtkEmptyCell::GetFace(arg1)
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetFace(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkEmptyCell::GetNumberOfEdges()
		CODE:
		RETVAL = THIS->GetNumberOfEdges();
		OUTPUT:
		RETVAL


int
vtkEmptyCell::GetNumberOfFaces()
		CODE:
		RETVAL = THIS->GetNumberOfFaces();
		OUTPUT:
		RETVAL


static vtkEmptyCell*
vtkEmptyCell::New()
		CODE:
		RETVAL = vtkEmptyCell::New();
		OUTPUT:
		RETVAL


int
vtkEmptyCell::Triangulate(index, ptIds, pts)
		int 	index
		vtkIdList *	ptIds
		vtkPoints *	pts
		CODE:
		RETVAL = THIS->Triangulate(index, ptIds, pts);
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::ExtentTranslator PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkExtentTranslator::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int  *
vtkExtentTranslator::GetExtent()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetExtent();
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
vtkExtentTranslator::GetGhostLevel()
		CODE:
		RETVAL = THIS->GetGhostLevel();
		OUTPUT:
		RETVAL


int
vtkExtentTranslator::GetNumberOfPieces()
		CODE:
		RETVAL = THIS->GetNumberOfPieces();
		OUTPUT:
		RETVAL


int
vtkExtentTranslator::GetPiece()
		CODE:
		RETVAL = THIS->GetPiece();
		OUTPUT:
		RETVAL


int
vtkExtentTranslator::GetSplitMode()
		CODE:
		RETVAL = THIS->GetSplitMode();
		OUTPUT:
		RETVAL


int  *
vtkExtentTranslator::GetWholeExtent()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetWholeExtent();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;


static vtkExtentTranslator*
vtkExtentTranslator::New()
		CODE:
		RETVAL = vtkExtentTranslator::New();
		OUTPUT:
		RETVAL


int
vtkExtentTranslator::PieceToExtent()
		CODE:
		RETVAL = THIS->PieceToExtent();
		OUTPUT:
		RETVAL


int
vtkExtentTranslator::PieceToExtentByPoints()
		CODE:
		RETVAL = THIS->PieceToExtentByPoints();
		OUTPUT:
		RETVAL


void
vtkExtentTranslator::SetExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetExtent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkExtentTranslator::SetExtent\n");



void
vtkExtentTranslator::SetGhostLevel(arg1)
		int 	arg1
		CODE:
		THIS->SetGhostLevel(arg1);
		XSRETURN_EMPTY;


void
vtkExtentTranslator::SetNumberOfPieces(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfPieces(arg1);
		XSRETURN_EMPTY;


void
vtkExtentTranslator::SetPiece(arg1)
		int 	arg1
		CODE:
		THIS->SetPiece(arg1);
		XSRETURN_EMPTY;


void
vtkExtentTranslator::SetSplitModeToBlock()
		CODE:
		THIS->SetSplitModeToBlock();
		XSRETURN_EMPTY;


void
vtkExtentTranslator::SetSplitModeToXSlab()
		CODE:
		THIS->SetSplitModeToXSlab();
		XSRETURN_EMPTY;


void
vtkExtentTranslator::SetSplitModeToYSlab()
		CODE:
		THIS->SetSplitModeToYSlab();
		XSRETURN_EMPTY;


void
vtkExtentTranslator::SetSplitModeToZSlab()
		CODE:
		THIS->SetSplitModeToZSlab();
		XSRETURN_EMPTY;


void
vtkExtentTranslator::SetWholeExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetWholeExtent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkExtentTranslator::SetWholeExtent\n");


MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::FieldData PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkFieldData::AddArray(array)
		vtkDataArray *	array
		CODE:
		RETVAL = THIS->AddArray(array);
		OUTPUT:
		RETVAL


int
vtkFieldData::Allocate(sz, ext)
		const long 	sz
		const long 	ext
		CODE:
		RETVAL = THIS->Allocate(sz, ext);
		OUTPUT:
		RETVAL


void
vtkFieldData::AllocateArrays(num)
		int 	num
		CODE:
		THIS->AllocateArrays(num);
		XSRETURN_EMPTY;


void
vtkFieldData::CopyAllOff()
		CODE:
		THIS->CopyAllOff();
		XSRETURN_EMPTY;


void
vtkFieldData::CopyAllOn()
		CODE:
		THIS->CopyAllOn();
		XSRETURN_EMPTY;


void
vtkFieldData::CopyFieldOff(name)
		const char *	name
		CODE:
		THIS->CopyFieldOff(name);
		XSRETURN_EMPTY;


void
vtkFieldData::CopyFieldOn(name)
		const char *	name
		CODE:
		THIS->CopyFieldOn(name);
		XSRETURN_EMPTY;


void
vtkFieldData::DeepCopy(da)
		vtkFieldData *	da
		CODE:
		THIS->DeepCopy(da);
		XSRETURN_EMPTY;


unsigned long
vtkFieldData::GetActualMemorySize()
		CODE:
		RETVAL = THIS->GetActualMemorySize();
		OUTPUT:
		RETVAL


vtkDataArray *
vtkFieldData::GetArray(arg1 = 0, arg2 = 0)
	CASE: items == 3
		const char *	arg1
		int 	arg2
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataArray";
		CODE:
		RETVAL = THIS->GetArray(arg1, arg2);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		arg2
		RETVAL
	CASE: items == 2 && SvPOK(ST(1))
		const char *	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataArray";
		CODE:
		RETVAL = THIS->GetArray(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE: items == 2 && SvIOK(ST(1))
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataArray";
		CODE:
		RETVAL = THIS->GetArray(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkFieldData::GetArray\n");



int
vtkFieldData::GetArrayContainingComponent(i, arrayComp)
		int 	i
		int 	arrayComp
		CODE:
		RETVAL = THIS->GetArrayContainingComponent(i, arrayComp);
		OUTPUT:
		arrayComp
		RETVAL


const char *
vtkFieldData::GetArrayName(i)
		int 	i
		CODE:
		RETVAL = THIS->GetArrayName(i);
		OUTPUT:
		RETVAL


const char *
vtkFieldData::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkFieldData::GetComponent(i, j)
		const long 	i
		const int 	j
		CODE:
		RETVAL = THIS->GetComponent(i, j);
		OUTPUT:
		RETVAL


void
vtkFieldData::GetField(ptId, f)
		vtkIdList *	ptId
		vtkFieldData *	f
		CODE:
		THIS->GetField(ptId, f);
		XSRETURN_EMPTY;


unsigned long
vtkFieldData::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkFieldData::GetNumberOfArrays()
		CODE:
		RETVAL = THIS->GetNumberOfArrays();
		OUTPUT:
		RETVAL


int
vtkFieldData::GetNumberOfComponents()
		CODE:
		RETVAL = THIS->GetNumberOfComponents();
		OUTPUT:
		RETVAL


long
vtkFieldData::GetNumberOfTuples()
		CODE:
		RETVAL = THIS->GetNumberOfTuples();
		OUTPUT:
		RETVAL


void
vtkFieldData::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


void
vtkFieldData::InsertComponent(i, j, c)
		const long 	i
		const int 	j
		const float 	c
		CODE:
		THIS->InsertComponent(i, j, c);
		XSRETURN_EMPTY;


static vtkFieldData*
vtkFieldData::New()
		CODE:
		RETVAL = vtkFieldData::New();
		OUTPUT:
		RETVAL


void
vtkFieldData::PassData(fd)
		vtkFieldData *	fd
		CODE:
		THIS->PassData(fd);
		XSRETURN_EMPTY;


void
vtkFieldData::RemoveArray(arg1 = 0)
	CASE: items == 2
		const char *	arg1
		CODE:
		THIS->RemoveArray(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkFieldData::RemoveArray\n");



void
vtkFieldData::Reset()
		CODE:
		THIS->Reset();
		XSRETURN_EMPTY;


void
vtkFieldData::SetComponent(i, j, c)
		const long 	i
		const int 	j
		const float 	c
		CODE:
		THIS->SetComponent(i, j, c);
		XSRETURN_EMPTY;


void
vtkFieldData::SetNumberOfArrays(num)
		int 	num
		CODE:
		THIS->SetNumberOfArrays(num);
		XSRETURN_EMPTY;


void
vtkFieldData::SetNumberOfTuples(number)
		const long 	number
		CODE:
		THIS->SetNumberOfTuples(number);
		XSRETURN_EMPTY;


void
vtkFieldData::ShallowCopy(da)
		vtkFieldData *	da
		CODE:
		THIS->ShallowCopy(da);
		XSRETURN_EMPTY;


void
vtkFieldData::Squeeze()
		CODE:
		THIS->Squeeze();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::FileOutputWindow PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkFileOutputWindow::AppendOff()
		CODE:
		THIS->AppendOff();
		XSRETURN_EMPTY;


void
vtkFileOutputWindow::AppendOn()
		CODE:
		THIS->AppendOn();
		XSRETURN_EMPTY;


void
vtkFileOutputWindow::DisplayText(arg1)
		const char *	arg1
		CODE:
		THIS->DisplayText(arg1);
		XSRETURN_EMPTY;


void
vtkFileOutputWindow::FlushOff()
		CODE:
		THIS->FlushOff();
		XSRETURN_EMPTY;


void
vtkFileOutputWindow::FlushOn()
		CODE:
		THIS->FlushOn();
		XSRETURN_EMPTY;


int
vtkFileOutputWindow::GetAppend()
		CODE:
		RETVAL = THIS->GetAppend();
		OUTPUT:
		RETVAL


const char *
vtkFileOutputWindow::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


char *
vtkFileOutputWindow::GetFileName()
		CODE:
		RETVAL = THIS->GetFileName();
		OUTPUT:
		RETVAL


int
vtkFileOutputWindow::GetFlush()
		CODE:
		RETVAL = THIS->GetFlush();
		OUTPUT:
		RETVAL


static vtkFileOutputWindow*
vtkFileOutputWindow::New()
		CODE:
		RETVAL = vtkFileOutputWindow::New();
		OUTPUT:
		RETVAL


void
vtkFileOutputWindow::SetAppend(arg1)
		int 	arg1
		CODE:
		THIS->SetAppend(arg1);
		XSRETURN_EMPTY;


void
vtkFileOutputWindow::SetFileName(arg1)
		char *	arg1
		CODE:
		THIS->SetFileName(arg1);
		XSRETURN_EMPTY;


void
vtkFileOutputWindow::SetFlush(arg1)
		int 	arg1
		CODE:
		THIS->SetFlush(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::FloatArray PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkFloatArray::Allocate(sz, ext)
		const long 	sz
		const long 	ext
		CODE:
		RETVAL = THIS->Allocate(sz, ext);
		OUTPUT:
		RETVAL


void
vtkFloatArray::DeepCopy(fa)
		vtkDataArray *	fa
		CODE:
		THIS->DeepCopy(fa);
		XSRETURN_EMPTY;


const char *
vtkFloatArray::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkFloatArray::GetComponent(i, j)
		const long 	i
		const int 	j
		CODE:
		RETVAL = THIS->GetComponent(i, j);
		OUTPUT:
		RETVAL


int
vtkFloatArray::GetDataType()
		CODE:
		RETVAL = THIS->GetDataType();
		OUTPUT:
		RETVAL


float
vtkFloatArray::GetValue(id)
		const long 	id
		CODE:
		RETVAL = THIS->GetValue(id);
		OUTPUT:
		RETVAL


void
vtkFloatArray::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


void
vtkFloatArray::InsertComponent(i, j, c)
		const long 	i
		const int 	j
		const float 	c
		CODE:
		THIS->InsertComponent(i, j, c);
		XSRETURN_EMPTY;


long
vtkFloatArray::InsertNextValue(f)
		const float 	f
		CODE:
		RETVAL = THIS->InsertNextValue(f);
		OUTPUT:
		RETVAL


void
vtkFloatArray::InsertValue(id, f)
		const long 	id
		const float 	f
		CODE:
		THIS->InsertValue(id, f);
		XSRETURN_EMPTY;


static vtkFloatArray*
vtkFloatArray::New()
		CODE:
		RETVAL = vtkFloatArray::New();
		OUTPUT:
		RETVAL


void
vtkFloatArray::Resize(numTuples)
		long 	numTuples
		CODE:
		THIS->Resize(numTuples);
		XSRETURN_EMPTY;


void
vtkFloatArray::SetComponent(i, j, c)
		const long 	i
		const int 	j
		const float 	c
		CODE:
		THIS->SetComponent(i, j, c);
		XSRETURN_EMPTY;


void
vtkFloatArray::SetNumberOfTuples(number)
		const long 	number
		CODE:
		THIS->SetNumberOfTuples(number);
		XSRETURN_EMPTY;


void
vtkFloatArray::SetNumberOfValues(number)
		const long 	number
		CODE:
		THIS->SetNumberOfValues(number);
		XSRETURN_EMPTY;


void
vtkFloatArray::SetValue(id, value)
		const long 	id
		const float 	value
		CODE:
		THIS->SetValue(id, value);
		XSRETURN_EMPTY;


void
vtkFloatArray::Squeeze()
		CODE:
		THIS->Squeeze();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::FunctionParser PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkFunctionParser::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


char *
vtkFunctionParser::GetFunction()
		CODE:
		RETVAL = THIS->GetFunction();
		OUTPUT:
		RETVAL


int
vtkFunctionParser::GetNumberOfScalarVariables()
		CODE:
		RETVAL = THIS->GetNumberOfScalarVariables();
		OUTPUT:
		RETVAL


int
vtkFunctionParser::GetNumberOfVectorVariables()
		CODE:
		RETVAL = THIS->GetNumberOfVectorVariables();
		OUTPUT:
		RETVAL


double
vtkFunctionParser::GetScalarResult()
		CODE:
		RETVAL = THIS->GetScalarResult();
		OUTPUT:
		RETVAL


char *
vtkFunctionParser::GetScalarVariableName(i)
		int 	i
		CODE:
		RETVAL = THIS->GetScalarVariableName(i);
		OUTPUT:
		RETVAL


double
vtkFunctionParser::GetScalarVariableValue(arg1 = 0)
	CASE: items == 2 && SvPOK(ST(1))
		const char *	arg1
		CODE:
		RETVAL = THIS->GetScalarVariableValue(arg1);
		OUTPUT:
		RETVAL
	CASE: items == 2 && SvIOK(ST(1))
		int 	arg1
		CODE:
		RETVAL = THIS->GetScalarVariableValue(arg1);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkFunctionParser::GetScalarVariableValue\n");



double *
vtkFunctionParser::GetVectorResult()
	CASE: items == 1
		PREINIT:
		double * retval;
		CODE:
		SP -= items;
		retval = THIS->GetVectorResult();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkFunctionParser::GetVectorResult\n");



char *
vtkFunctionParser::GetVectorVariableName(i)
		int 	i
		CODE:
		RETVAL = THIS->GetVectorVariableName(i);
		OUTPUT:
		RETVAL


double *
vtkFunctionParser::GetVectorVariableValue(arg1 = 0)
	CASE: items == 2 && SvPOK(ST(1))
		const char *	arg1
		PREINIT:
		double * retval;
		CODE:
		SP -= items;
		retval = THIS->GetVectorVariableValue(arg1);
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE: items == 2 && SvIOK(ST(1))
		int 	arg1
		PREINIT:
		double * retval;
		CODE:
		SP -= items;
		retval = THIS->GetVectorVariableValue(arg1);
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkFunctionParser::GetVectorVariableValue\n");



int
vtkFunctionParser::IsScalarResult()
		CODE:
		RETVAL = THIS->IsScalarResult();
		OUTPUT:
		RETVAL


int
vtkFunctionParser::IsVectorResult()
		CODE:
		RETVAL = THIS->IsVectorResult();
		OUTPUT:
		RETVAL


static vtkFunctionParser*
vtkFunctionParser::New()
		CODE:
		RETVAL = vtkFunctionParser::New();
		OUTPUT:
		RETVAL


void
vtkFunctionParser::SetFunction(function)
		const char *	function
		CODE:
		THIS->SetFunction(function);
		XSRETURN_EMPTY;


void
vtkFunctionParser::SetScalarVariableValue(arg1 = 0, arg2 = 0)
	CASE: items == 3 && SvPOK(ST(1))
		const char *	arg1
		double 	arg2
		CODE:
		THIS->SetScalarVariableValue(arg1, arg2);
		XSRETURN_EMPTY;
	CASE: items == 3 && SvIOK(ST(1))
		int 	arg1
		double 	arg2
		CODE:
		THIS->SetScalarVariableValue(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkFunctionParser::SetScalarVariableValue\n");



void
vtkFunctionParser::SetVectorVariableValue(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5 && SvPOK(ST(1))
		const char *	arg1
		double 	arg2
		double 	arg3
		double 	arg4
		CODE:
		THIS->SetVectorVariableValue(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE: items == 5 && SvIOK(ST(1))
		int 	arg1
		double 	arg2
		double 	arg3
		double 	arg4
		CODE:
		THIS->SetVectorVariableValue(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkFunctionParser::SetVectorVariableValue\n");


MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::FunctionSet PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkFunctionSet::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkFunctionSet::GetNumberOfFunctions()
		CODE:
		RETVAL = THIS->GetNumberOfFunctions();
		OUTPUT:
		RETVAL


int
vtkFunctionSet::GetNumberOfIndependentVariables()
		CODE:
		RETVAL = THIS->GetNumberOfIndependentVariables();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::GeneralTransform PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkGeneralTransform::CircuitCheck(transform)
		vtkAbstractTransform *	transform
		CODE:
		RETVAL = THIS->CircuitCheck(transform);
		OUTPUT:
		RETVAL


void
vtkGeneralTransform::Concatenate(arg1 = 0)
	CASE: items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1),"Graphics::VTK::Matrix4x4")
		vtkMatrix4x4 *	arg1
		CODE:
		THIS->Concatenate(arg1);
		XSRETURN_EMPTY;
	CASE: items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1),"Graphics::VTK::AbstractTransform")
		vtkAbstractTransform *	arg1
		CODE:
		THIS->Concatenate(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkGeneralTransform::Concatenate\n");



const char *
vtkGeneralTransform::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkAbstractTransform *
vtkGeneralTransform::GetConcatenatedTransform(i)
		int 	i
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAbstractTransform";
		CODE:
		RETVAL = THIS->GetConcatenatedTransform(i);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkAbstractTransform *
vtkGeneralTransform::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAbstractTransform";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkGeneralTransform::GetInverseFlag()
		CODE:
		RETVAL = THIS->GetInverseFlag();
		OUTPUT:
		RETVAL


unsigned long
vtkGeneralTransform::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkGeneralTransform::GetNumberOfConcatenatedTransforms()
		CODE:
		RETVAL = THIS->GetNumberOfConcatenatedTransforms();
		OUTPUT:
		RETVAL


void
vtkGeneralTransform::Identity()
		CODE:
		THIS->Identity();
		XSRETURN_EMPTY;


void
vtkGeneralTransform::Inverse()
		CODE:
		THIS->Inverse();
		XSRETURN_EMPTY;


vtkAbstractTransform *
vtkGeneralTransform::MakeTransform()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAbstractTransform";
		CODE:
		RETVAL = THIS->MakeTransform();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkGeneralTransform*
vtkGeneralTransform::New()
		CODE:
		RETVAL = vtkGeneralTransform::New();
		OUTPUT:
		RETVAL


void
vtkGeneralTransform::Pop()
		CODE:
		THIS->Pop();
		XSRETURN_EMPTY;


void
vtkGeneralTransform::PostMultiply()
		CODE:
		THIS->PostMultiply();
		XSRETURN_EMPTY;


void
vtkGeneralTransform::PreMultiply()
		CODE:
		THIS->PreMultiply();
		XSRETURN_EMPTY;


void
vtkGeneralTransform::Push()
		CODE:
		THIS->Push();
		XSRETURN_EMPTY;


void
vtkGeneralTransform::RotateWXYZ(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		double 	arg1
		double 	arg2
		double 	arg3
		double 	arg4
		CODE:
		THIS->RotateWXYZ(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkGeneralTransform::RotateWXYZ\n");



void
vtkGeneralTransform::RotateX(angle)
		double 	angle
		CODE:
		THIS->RotateX(angle);
		XSRETURN_EMPTY;


void
vtkGeneralTransform::RotateY(angle)
		double 	angle
		CODE:
		THIS->RotateY(angle);
		XSRETURN_EMPTY;


void
vtkGeneralTransform::RotateZ(angle)
		double 	angle
		CODE:
		THIS->RotateZ(angle);
		XSRETURN_EMPTY;


void
vtkGeneralTransform::Scale(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		double 	arg1
		double 	arg2
		double 	arg3
		CODE:
		THIS->Scale(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkGeneralTransform::Scale\n");



void
vtkGeneralTransform::SetInput(input)
		vtkAbstractTransform *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;


void
vtkGeneralTransform::Translate(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		double 	arg1
		double 	arg2
		double 	arg3
		CODE:
		THIS->Translate(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkGeneralTransform::Translate\n");


MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::GenericCell PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkGenericCell::Clip(value, cellScalars, locator, connectivity, inPd, outPd, inCd, cellId, outCd, insideOut)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	connectivity
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		int 	insideOut
		CODE:
		THIS->Clip(value, cellScalars, locator, connectivity, inPd, outPd, inCd, cellId, outCd, insideOut);
		XSRETURN_EMPTY;


void
vtkGenericCell::Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	verts
		vtkCellArray *	lines
		vtkCellArray *	polys
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		CODE:
		THIS->Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd);
		XSRETURN_EMPTY;


void
vtkGenericCell::DeepCopy(c)
		vtkCell *	c
		CODE:
		THIS->DeepCopy(c);
		XSRETURN_EMPTY;


int
vtkGenericCell::GetCellDimension()
		CODE:
		RETVAL = THIS->GetCellDimension();
		OUTPUT:
		RETVAL


int
vtkGenericCell::GetCellType()
		CODE:
		RETVAL = THIS->GetCellType();
		OUTPUT:
		RETVAL


const char *
vtkGenericCell::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkCell *
vtkGenericCell::GetEdge(edgeId)
		int 	edgeId
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetEdge(edgeId);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkCell *
vtkGenericCell::GetFace(faceId)
		int 	faceId
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetFace(faceId);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkGenericCell::GetInterpolationOrder()
		CODE:
		RETVAL = THIS->GetInterpolationOrder();
		OUTPUT:
		RETVAL


int
vtkGenericCell::GetNumberOfEdges()
		CODE:
		RETVAL = THIS->GetNumberOfEdges();
		OUTPUT:
		RETVAL


int
vtkGenericCell::GetNumberOfFaces()
		CODE:
		RETVAL = THIS->GetNumberOfFaces();
		OUTPUT:
		RETVAL



static vtkGenericCell*
vtkGenericCell::New()
		CODE:
		RETVAL = vtkGenericCell::New();
		OUTPUT:
		RETVAL


void
vtkGenericCell::SetCellType(cellType)
		int 	cellType
		CODE:
		THIS->SetCellType(cellType);
		XSRETURN_EMPTY;


void
vtkGenericCell::SetCellTypeToEmptyCell()
		CODE:
		THIS->SetCellTypeToEmptyCell();
		XSRETURN_EMPTY;


void
vtkGenericCell::SetCellTypeToHexahedron()
		CODE:
		THIS->SetCellTypeToHexahedron();
		XSRETURN_EMPTY;


void
vtkGenericCell::SetCellTypeToLine()
		CODE:
		THIS->SetCellTypeToLine();
		XSRETURN_EMPTY;


void
vtkGenericCell::SetCellTypeToPixel()
		CODE:
		THIS->SetCellTypeToPixel();
		XSRETURN_EMPTY;


void
vtkGenericCell::SetCellTypeToPolyLine()
		CODE:
		THIS->SetCellTypeToPolyLine();
		XSRETURN_EMPTY;


void
vtkGenericCell::SetCellTypeToPolyVertex()
		CODE:
		THIS->SetCellTypeToPolyVertex();
		XSRETURN_EMPTY;


void
vtkGenericCell::SetCellTypeToPolygon()
		CODE:
		THIS->SetCellTypeToPolygon();
		XSRETURN_EMPTY;


void
vtkGenericCell::SetCellTypeToPyramid()
		CODE:
		THIS->SetCellTypeToPyramid();
		XSRETURN_EMPTY;


void
vtkGenericCell::SetCellTypeToQuad()
		CODE:
		THIS->SetCellTypeToQuad();
		XSRETURN_EMPTY;


void
vtkGenericCell::SetCellTypeToTetra()
		CODE:
		THIS->SetCellTypeToTetra();
		XSRETURN_EMPTY;


void
vtkGenericCell::SetCellTypeToTriangle()
		CODE:
		THIS->SetCellTypeToTriangle();
		XSRETURN_EMPTY;


void
vtkGenericCell::SetCellTypeToTriangleStrip()
		CODE:
		THIS->SetCellTypeToTriangleStrip();
		XSRETURN_EMPTY;


void
vtkGenericCell::SetCellTypeToVertex()
		CODE:
		THIS->SetCellTypeToVertex();
		XSRETURN_EMPTY;


void
vtkGenericCell::SetCellTypeToVoxel()
		CODE:
		THIS->SetCellTypeToVoxel();
		XSRETURN_EMPTY;


void
vtkGenericCell::SetCellTypeToWedge()
		CODE:
		THIS->SetCellTypeToWedge();
		XSRETURN_EMPTY;


void
vtkGenericCell::ShallowCopy(c)
		vtkCell *	c
		CODE:
		THIS->ShallowCopy(c);
		XSRETURN_EMPTY;


int
vtkGenericCell::Triangulate(index, ptIds, pts)
		int 	index
		vtkIdList *	ptIds
		vtkPoints *	pts
		CODE:
		RETVAL = THIS->Triangulate(index, ptIds, pts);
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Heap PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkHeap::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkHeap::GetNumberOfAllocations()
		CODE:
		RETVAL = THIS->GetNumberOfAllocations();
		OUTPUT:
		RETVAL


static vtkHeap*
vtkHeap::New()
		CODE:
		RETVAL = vtkHeap::New();
		OUTPUT:
		RETVAL


char *
vtkHeap::vtkStrDup(str)
		const char *	str
		CODE:
		RETVAL = THIS->vtkStrDup(str);
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Hexahedron PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkHexahedron::Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	verts
		vtkCellArray *	lines
		vtkCellArray *	polys
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		CODE:
		THIS->Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd);
		XSRETURN_EMPTY;


int
vtkHexahedron::GetCellType()
		CODE:
		RETVAL = THIS->GetCellType();
		OUTPUT:
		RETVAL


const char *
vtkHexahedron::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkCell *
vtkHexahedron::GetEdge(edgeId)
		int 	edgeId
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetEdge(edgeId);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkCell *
vtkHexahedron::GetFace(faceId)
		int 	faceId
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetFace(faceId);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkHexahedron::GetNumberOfEdges()
		CODE:
		RETVAL = THIS->GetNumberOfEdges();
		OUTPUT:
		RETVAL


int
vtkHexahedron::GetNumberOfFaces()
		CODE:
		RETVAL = THIS->GetNumberOfFaces();
		OUTPUT:
		RETVAL


static vtkHexahedron*
vtkHexahedron::New()
		CODE:
		RETVAL = vtkHexahedron::New();
		OUTPUT:
		RETVAL


int
vtkHexahedron::Triangulate(index, ptIds, pts)
		int 	index
		vtkIdList *	ptIds
		vtkPoints *	pts
		CODE:
		RETVAL = THIS->Triangulate(index, ptIds, pts);
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::HomogeneousTransform PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkHomogeneousTransform::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkHomogeneousTransform *
vtkHomogeneousTransform::GetHomogeneousInverse()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkHomogeneousTransform";
		CODE:
		RETVAL = THIS->GetHomogeneousInverse();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkMatrix4x4 *
vtkHomogeneousTransform::GetMatrix(arg1 = 0)
	CASE: items == 2
		vtkMatrix4x4 *	arg1
		CODE:
		THIS->GetMatrix(arg1);
		XSRETURN_EMPTY;
	CASE: items == 1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkMatrix4x4";
		CODE:
		RETVAL = THIS->GetMatrix();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkHomogeneousTransform::GetMatrix\n");



void
vtkHomogeneousTransform::TransformPoints(inPts, outPts)
		vtkPoints *	inPts
		vtkPoints *	outPts
		CODE:
		THIS->TransformPoints(inPts, outPts);
		XSRETURN_EMPTY;


void
vtkHomogeneousTransform::TransformPointsNormalsVectors(inPts, outPts, inNms, outNms, inVrs, outVrs)
		vtkPoints *	inPts
		vtkPoints *	outPts
		vtkDataArray *	inNms
		vtkDataArray *	outNms
		vtkDataArray *	inVrs
		vtkDataArray *	outVrs
		CODE:
		THIS->TransformPointsNormalsVectors(inPts, outPts, inNms, outNms, inVrs, outVrs);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::IdList PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkIdList::Allocate(sz, strategy)
		const int 	sz
		const int 	strategy
		CODE:
		RETVAL = THIS->Allocate(sz, strategy);
		OUTPUT:
		RETVAL


void
vtkIdList::DeepCopy(ids)
		vtkIdList *	ids
		CODE:
		THIS->DeepCopy(ids);
		XSRETURN_EMPTY;


void
vtkIdList::DeleteId(id)
		long 	id
		CODE:
		THIS->DeleteId(id);
		XSRETURN_EMPTY;


const char *
vtkIdList::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


long
vtkIdList::GetId(i)
		const int 	i
		CODE:
		RETVAL = THIS->GetId(i);
		OUTPUT:
		RETVAL


long
vtkIdList::GetNumberOfIds()
		CODE:
		RETVAL = THIS->GetNumberOfIds();
		OUTPUT:
		RETVAL


void
vtkIdList::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


void
vtkIdList::InsertId(i, id)
		const long 	i
		const long 	id
		CODE:
		THIS->InsertId(i, id);
		XSRETURN_EMPTY;


long
vtkIdList::InsertNextId(id)
		const long 	id
		CODE:
		RETVAL = THIS->InsertNextId(id);
		OUTPUT:
		RETVAL


long
vtkIdList::InsertUniqueId(id)
		const long 	id
		CODE:
		RETVAL = THIS->InsertUniqueId(id);
		OUTPUT:
		RETVAL


void
vtkIdList::IntersectWith(otherIds)
		vtkIdList *	otherIds
		CODE:
		THIS->IntersectWith(*otherIds);
		XSRETURN_EMPTY;


long
vtkIdList::IsId(id)
		long 	id
		CODE:
		RETVAL = THIS->IsId(id);
		OUTPUT:
		RETVAL


static vtkIdList*
vtkIdList::New()
		CODE:
		RETVAL = vtkIdList::New();
		OUTPUT:
		RETVAL


void
vtkIdList::Reset()
		CODE:
		THIS->Reset();
		XSRETURN_EMPTY;


void
vtkIdList::SetId(i, id)
		const long 	i
		const long 	id
		CODE:
		THIS->SetId(i, id);
		XSRETURN_EMPTY;


void
vtkIdList::SetNumberOfIds(number)
		const long 	number
		CODE:
		THIS->SetNumberOfIds(number);
		XSRETURN_EMPTY;


void
vtkIdList::Squeeze()
		CODE:
		THIS->Squeeze();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::IdTypeArray PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkIdTypeArray::Allocate(sz, ext)
		const long 	sz
		const long 	ext
		CODE:
		RETVAL = THIS->Allocate(sz, ext);
		OUTPUT:
		RETVAL


void
vtkIdTypeArray::DeepCopy(ia)
		vtkDataArray *	ia
		CODE:
		THIS->DeepCopy(ia);
		XSRETURN_EMPTY;


const char *
vtkIdTypeArray::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkIdTypeArray::GetDataType()
		CODE:
		RETVAL = THIS->GetDataType();
		OUTPUT:
		RETVAL


long
vtkIdTypeArray::GetValue(id)
		const long 	id
		CODE:
		RETVAL = THIS->GetValue(id);
		OUTPUT:
		RETVAL


void
vtkIdTypeArray::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


long
vtkIdTypeArray::InsertNextValue(i)
		const long 	i
		CODE:
		RETVAL = THIS->InsertNextValue(i);
		OUTPUT:
		RETVAL


void
vtkIdTypeArray::InsertValue(id, i)
		const long 	id
		const long 	i
		CODE:
		THIS->InsertValue(id, i);
		XSRETURN_EMPTY;


static vtkIdTypeArray*
vtkIdTypeArray::New()
		CODE:
		RETVAL = vtkIdTypeArray::New();
		OUTPUT:
		RETVAL


void
vtkIdTypeArray::Resize(numTuples)
		long 	numTuples
		CODE:
		THIS->Resize(numTuples);
		XSRETURN_EMPTY;


void
vtkIdTypeArray::SetNumberOfTuples(number)
		const long 	number
		CODE:
		THIS->SetNumberOfTuples(number);
		XSRETURN_EMPTY;


void
vtkIdTypeArray::SetNumberOfValues(number)
		const long 	number
		CODE:
		THIS->SetNumberOfValues(number);
		XSRETURN_EMPTY;


void
vtkIdTypeArray::SetValue(id, value)
		const long 	id
		const long 	value
		CODE:
		THIS->SetValue(id, value);
		XSRETURN_EMPTY;


void
vtkIdTypeArray::Squeeze()
		CODE:
		THIS->Squeeze();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::IdentityTransform PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkIdentityTransform::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


void
vtkIdentityTransform::Inverse()
		CODE:
		THIS->Inverse();
		XSRETURN_EMPTY;


vtkAbstractTransform *
vtkIdentityTransform::MakeTransform()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAbstractTransform";
		CODE:
		RETVAL = THIS->MakeTransform();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkIdentityTransform*
vtkIdentityTransform::New()
		CODE:
		RETVAL = vtkIdentityTransform::New();
		OUTPUT:
		RETVAL


void
vtkIdentityTransform::TransformNormals(inNms, outNms)
		vtkDataArray *	inNms
		vtkDataArray *	outNms
		CODE:
		THIS->TransformNormals(inNms, outNms);
		XSRETURN_EMPTY;


void
vtkIdentityTransform::TransformPoints(inPts, outPts)
		vtkPoints *	inPts
		vtkPoints *	outPts
		CODE:
		THIS->TransformPoints(inPts, outPts);
		XSRETURN_EMPTY;


void
vtkIdentityTransform::TransformPointsNormalsVectors(inPts, outPts, inNms, outNms, inVrs, outVrs)
		vtkPoints *	inPts
		vtkPoints *	outPts
		vtkDataArray *	inNms
		vtkDataArray *	outNms
		vtkDataArray *	inVrs
		vtkDataArray *	outVrs
		CODE:
		THIS->TransformPointsNormalsVectors(inPts, outPts, inNms, outNms, inVrs, outVrs);
		XSRETURN_EMPTY;


void
vtkIdentityTransform::TransformVectors(inVrs, outVrs)
		vtkDataArray *	inVrs
		vtkDataArray *	outVrs
		CODE:
		THIS->TransformVectors(inVrs, outVrs);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::ImageData PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImageData::AllocateScalars()
		CODE:
		THIS->AllocateScalars();
		XSRETURN_EMPTY;


void
vtkImageData::ComputeBounds()
		CODE:
		THIS->ComputeBounds();
		XSRETURN_EMPTY;




void
vtkImageData::CopyAndCastFrom(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0, arg7 = 0)
	CASE: items == 8
		vtkImageData *	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		int 	arg7
		CODE:
		THIS->CopyAndCastFrom(arg1, arg2, arg3, arg4, arg5, arg6, arg7);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageData::CopyAndCastFrom\n");



void
vtkImageData::CopyStructure(ds)
		vtkDataSet *	ds
		CODE:
		THIS->CopyStructure(ds);
		XSRETURN_EMPTY;


void
vtkImageData::CopyTypeSpecificInformation(image)
		vtkDataObject *	image
		CODE:
		THIS->CopyTypeSpecificInformation(image);
		XSRETURN_EMPTY;


void
vtkImageData::Crop()
		CODE:
		THIS->Crop();
		XSRETURN_EMPTY;


void
vtkImageData::DeepCopy(src)
		vtkDataObject *	src
		CODE:
		THIS->DeepCopy(src);
		XSRETURN_EMPTY;


long
vtkImageData::FindPoint(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		RETVAL = THIS->FindPoint(arg1, arg2, arg3);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageData::FindPoint\n");



unsigned long
vtkImageData::GetActualMemorySize()
		CODE:
		RETVAL = THIS->GetActualMemorySize();
		OUTPUT:
		RETVAL


void
vtkImageData::GetAxisUpdateExtent(axis, min, max)
		int 	axis
		int 	min
		int 	max
		CODE:
		THIS->GetAxisUpdateExtent(axis, min, max);
		XSRETURN_EMPTY;
		OUTPUT:
		min
		max


vtkCell *
vtkImageData::GetCell(arg1 = 0, arg2 = 0)
	CASE: items == 3
		long 	arg1
		vtkGenericCell *	arg2
		CODE:
		THIS->GetCell(arg1, arg2);
		XSRETURN_EMPTY;
	CASE: items == 2
		long 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetCell(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageData::GetCell\n");



void
vtkImageData::GetCellPoints(cellId, ptIds)
		long 	cellId
		vtkIdList *	ptIds
		CODE:
		THIS->GetCellPoints(cellId, ptIds);
		XSRETURN_EMPTY;


int
vtkImageData::GetCellType(cellId)
		long 	cellId
		CODE:
		RETVAL = THIS->GetCellType(cellId);
		OUTPUT:
		RETVAL


const char *
vtkImageData::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkImageData::GetDataDimension()
		CODE:
		RETVAL = THIS->GetDataDimension();
		OUTPUT:
		RETVAL


int
vtkImageData::GetDataObjectType()
		CODE:
		RETVAL = THIS->GetDataObjectType();
		OUTPUT:
		RETVAL


int *
vtkImageData::GetDimensions()
	CASE: items == 1
		PREINIT:
		int * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDimensions();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageData::GetDimensions\n");



unsigned long
vtkImageData::GetEstimatedMemorySize()
		CODE:
		RETVAL = THIS->GetEstimatedMemorySize();
		OUTPUT:
		RETVAL


int  *
vtkImageData::GetExtent()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetExtent();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;


int *
vtkImageData::GetIncrements(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->GetIncrements(arg1, arg2, arg3);
		XSRETURN_EMPTY;
		OUTPUT:
		arg1
		arg2
		arg3
	CASE: items == 1
		PREINIT:
		int * retval;
		CODE:
		SP -= items;
		retval = THIS->GetIncrements();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageData::GetIncrements\n");



int
vtkImageData::GetMaxCellSize()
		CODE:
		RETVAL = THIS->GetMaxCellSize();
		OUTPUT:
		RETVAL


long
vtkImageData::GetNumberOfCells()
		CODE:
		RETVAL = THIS->GetNumberOfCells();
		OUTPUT:
		RETVAL


long
vtkImageData::GetNumberOfPoints()
		CODE:
		RETVAL = THIS->GetNumberOfPoints();
		OUTPUT:
		RETVAL


int
vtkImageData::GetNumberOfScalarComponents()
		CODE:
		RETVAL = THIS->GetNumberOfScalarComponents();
		OUTPUT:
		RETVAL


float  *
vtkImageData::GetOrigin()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOrigin();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float *
vtkImageData::GetPoint(arg1 = 0)
	CASE: items == 2
		long 	arg1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPoint(arg1);
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageData::GetPoint\n");



void
vtkImageData::GetPointCells(ptId, cellIds)
		long 	ptId
		vtkIdList *	cellIds
		CODE:
		THIS->GetPointCells(ptId, cellIds);
		XSRETURN_EMPTY;


float
vtkImageData::GetScalarComponentAsFloat(x, y, z, component)
		int 	x
		int 	y
		int 	z
		int 	component
		CODE:
		RETVAL = THIS->GetScalarComponentAsFloat(x, y, z, component);
		OUTPUT:
		RETVAL


int
vtkImageData::GetScalarSize()
		CODE:
		RETVAL = THIS->GetScalarSize();
		OUTPUT:
		RETVAL


int
vtkImageData::GetScalarType()
		CODE:
		RETVAL = THIS->GetScalarType();
		OUTPUT:
		RETVAL


double
vtkImageData::GetScalarTypeMax()
		CODE:
		RETVAL = THIS->GetScalarTypeMax();
		OUTPUT:
		RETVAL


double
vtkImageData::GetScalarTypeMin()
		CODE:
		RETVAL = THIS->GetScalarTypeMin();
		OUTPUT:
		RETVAL


float  *
vtkImageData::GetSpacing()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetSpacing();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


void
vtkImageData::GetVoxelGradient(i, j, k, s, g)
		int 	i
		int 	j
		int 	k
		vtkDataArray *	s
		vtkDataArray *	g
		CODE:
		THIS->GetVoxelGradient(i, j, k, s, g);
		XSRETURN_EMPTY;


static vtkImageData*
vtkImageData::New()
		CODE:
		RETVAL = vtkImageData::New();
		OUTPUT:
		RETVAL


void
vtkImageData::PrepareForNewData()
		CODE:
		THIS->PrepareForNewData();
		XSRETURN_EMPTY;


void
vtkImageData::SetAxisUpdateExtent(axis, min, max)
		int 	axis
		int 	min
		int 	max
		CODE:
		THIS->SetAxisUpdateExtent(axis, min, max);
		XSRETURN_EMPTY;


void
vtkImageData::SetDimensions(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetDimensions(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageData::SetDimensions\n");



void
vtkImageData::SetExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetExtent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageData::SetExtent\n");



void
vtkImageData::SetNumberOfScalarComponents(n)
		int 	n
		CODE:
		THIS->SetNumberOfScalarComponents(n);
		XSRETURN_EMPTY;


void
vtkImageData::SetOrigin(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetOrigin(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageData::SetOrigin\n");



void
vtkImageData::SetScalarType(arg1)
		int 	arg1
		CODE:
		THIS->SetScalarType(arg1);
		XSRETURN_EMPTY;


void
vtkImageData::SetScalarTypeToChar()
		CODE:
		THIS->SetScalarTypeToChar();
		XSRETURN_EMPTY;


void
vtkImageData::SetScalarTypeToDouble()
		CODE:
		THIS->SetScalarTypeToDouble();
		XSRETURN_EMPTY;


void
vtkImageData::SetScalarTypeToFloat()
		CODE:
		THIS->SetScalarTypeToFloat();
		XSRETURN_EMPTY;


void
vtkImageData::SetScalarTypeToInt()
		CODE:
		THIS->SetScalarTypeToInt();
		XSRETURN_EMPTY;


void
vtkImageData::SetScalarTypeToLong()
		CODE:
		THIS->SetScalarTypeToLong();
		XSRETURN_EMPTY;


void
vtkImageData::SetScalarTypeToShort()
		CODE:
		THIS->SetScalarTypeToShort();
		XSRETURN_EMPTY;


void
vtkImageData::SetScalarTypeToUnsignedChar()
		CODE:
		THIS->SetScalarTypeToUnsignedChar();
		XSRETURN_EMPTY;


void
vtkImageData::SetScalarTypeToUnsignedInt()
		CODE:
		THIS->SetScalarTypeToUnsignedInt();
		XSRETURN_EMPTY;


void
vtkImageData::SetScalarTypeToUnsignedLong()
		CODE:
		THIS->SetScalarTypeToUnsignedLong();
		XSRETURN_EMPTY;


void
vtkImageData::SetScalarTypeToUnsignedShort()
		CODE:
		THIS->SetScalarTypeToUnsignedShort();
		XSRETURN_EMPTY;


void
vtkImageData::SetSpacing(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetSpacing(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageData::SetSpacing\n");



void
vtkImageData::SetUpdateExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetUpdateExtent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetUpdateExtent(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetUpdateExtent(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImageData::SetUpdateExtent\n");



void
vtkImageData::ShallowCopy(src)
		vtkDataObject *	src
		CODE:
		THIS->ShallowCopy(src);
		XSRETURN_EMPTY;


void
vtkImageData::UpdateData()
		CODE:
		THIS->UpdateData();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::ImplicitFunction PREFIX = vtk

PROTOTYPES: DISABLE



float
vtkImplicitFunction::EvaluateFunction(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		RETVAL = THIS->EvaluateFunction(arg1, arg2, arg3);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImplicitFunction::EvaluateFunction\n");



float *
vtkImplicitFunction::FunctionGradient(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->FunctionGradient(arg1, arg2, arg3);
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImplicitFunction::FunctionGradient\n");



float
vtkImplicitFunction::FunctionValue(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		RETVAL = THIS->FunctionValue(arg1, arg2, arg3);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImplicitFunction::FunctionValue\n");



const char *
vtkImplicitFunction::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


unsigned long
vtkImplicitFunction::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


vtkAbstractTransform *
vtkImplicitFunction::GetTransform()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAbstractTransform";
		CODE:
		RETVAL = THIS->GetTransform();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkImplicitFunction::SetTransform(arg1)
		vtkAbstractTransform *	arg1
		CODE:
		THIS->SetTransform(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::ImplicitFunctionCollection PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkImplicitFunctionCollection::AddItem(arg1 = 0)
	CASE: items == 2
		vtkImplicitFunction *	arg1
		CODE:
		THIS->AddItem(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkImplicitFunctionCollection::AddItem\n");



const char *
vtkImplicitFunctionCollection::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkImplicitFunction *
vtkImplicitFunctionCollection::GetNextItem()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkImplicitFunction";
		CODE:
		RETVAL = THIS->GetNextItem();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkImplicitFunctionCollection*
vtkImplicitFunctionCollection::New()
		CODE:
		RETVAL = vtkImplicitFunctionCollection::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Indent PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkIndent::Delete()
		CODE:
		THIS->Delete();
		XSRETURN_EMPTY;


const char *
vtkIndent::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkIndent*
vtkIndent::New()
		CODE:
		RETVAL = vtkIndent::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::InitialValueProblemSolver PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkInitialValueProblemSolver::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkFunctionSet *
vtkInitialValueProblemSolver::GetFunctionSet()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkFunctionSet";
		CODE:
		RETVAL = THIS->GetFunctionSet();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkInitialValueProblemSolver::SetFunctionSet(functionset)
		vtkFunctionSet *	functionset
		CODE:
		THIS->SetFunctionSet(functionset);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::IntArray PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkIntArray::Allocate(sz, ext)
		const long 	sz
		const long 	ext
		CODE:
		RETVAL = THIS->Allocate(sz, ext);
		OUTPUT:
		RETVAL


void
vtkIntArray::DeepCopy(ia)
		vtkDataArray *	ia
		CODE:
		THIS->DeepCopy(ia);
		XSRETURN_EMPTY;


const char *
vtkIntArray::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkIntArray::GetDataType()
		CODE:
		RETVAL = THIS->GetDataType();
		OUTPUT:
		RETVAL


int
vtkIntArray::GetValue(id)
		const long 	id
		CODE:
		RETVAL = THIS->GetValue(id);
		OUTPUT:
		RETVAL


void
vtkIntArray::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


void
vtkIntArray::InsertComponent(i, j, c)
		const long 	i
		const int 	j
		const float 	c
		CODE:
		THIS->InsertComponent(i, j, c);
		XSRETURN_EMPTY;


long
vtkIntArray::InsertNextValue(i)
		const int 	i
		CODE:
		RETVAL = THIS->InsertNextValue(i);
		OUTPUT:
		RETVAL


void
vtkIntArray::InsertValue(id, i)
		const long 	id
		const int 	i
		CODE:
		THIS->InsertValue(id, i);
		XSRETURN_EMPTY;


static vtkIntArray*
vtkIntArray::New()
		CODE:
		RETVAL = vtkIntArray::New();
		OUTPUT:
		RETVAL


void
vtkIntArray::Resize(numTuples)
		long 	numTuples
		CODE:
		THIS->Resize(numTuples);
		XSRETURN_EMPTY;


void
vtkIntArray::SetNumberOfTuples(number)
		const long 	number
		CODE:
		THIS->SetNumberOfTuples(number);
		XSRETURN_EMPTY;


void
vtkIntArray::SetNumberOfValues(number)
		const long 	number
		CODE:
		THIS->SetNumberOfValues(number);
		XSRETURN_EMPTY;


void
vtkIntArray::SetValue(id, value)
		const long 	id
		const int 	value
		CODE:
		THIS->SetValue(id, value);
		XSRETURN_EMPTY;


void
vtkIntArray::Squeeze()
		CODE:
		THIS->Squeeze();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::InterpolatedVelocityField PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkInterpolatedVelocityField::CachingOff()
		CODE:
		THIS->CachingOff();
		XSRETURN_EMPTY;


void
vtkInterpolatedVelocityField::CachingOn()
		CODE:
		THIS->CachingOn();
		XSRETURN_EMPTY;


void
vtkInterpolatedVelocityField::ClearLastCellId()
		CODE:
		THIS->ClearLastCellId();
		XSRETURN_EMPTY;


int
vtkInterpolatedVelocityField::GetCacheHit()
		CODE:
		RETVAL = THIS->GetCacheHit();
		OUTPUT:
		RETVAL


int
vtkInterpolatedVelocityField::GetCacheMiss()
		CODE:
		RETVAL = THIS->GetCacheMiss();
		OUTPUT:
		RETVAL


int
vtkInterpolatedVelocityField::GetCaching()
		CODE:
		RETVAL = THIS->GetCaching();
		OUTPUT:
		RETVAL


const char *
vtkInterpolatedVelocityField::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataSet *
vtkInterpolatedVelocityField::GetDataSet()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetDataSet();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


long
vtkInterpolatedVelocityField::GetLastCellId()
		CODE:
		RETVAL = THIS->GetLastCellId();
		OUTPUT:
		RETVAL



static vtkInterpolatedVelocityField*
vtkInterpolatedVelocityField::New()
		CODE:
		RETVAL = vtkInterpolatedVelocityField::New();
		OUTPUT:
		RETVAL


void
vtkInterpolatedVelocityField::SetCaching(arg1)
		int 	arg1
		CODE:
		THIS->SetCaching(arg1);
		XSRETURN_EMPTY;


void
vtkInterpolatedVelocityField::SetDataSet(dataset)
		vtkDataSet *	dataset
		CODE:
		THIS->SetDataSet(dataset);
		XSRETURN_EMPTY;


void
vtkInterpolatedVelocityField::SetLastCellId(arg1)
		long 	arg1
		CODE:
		THIS->SetLastCellId(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Line PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkLine::Clip(value, cellScalars, locator, lines, inPd, outPd, inCd, cellId, outCd, insideOut)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	lines
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		int 	insideOut
		CODE:
		THIS->Clip(value, cellScalars, locator, lines, inPd, outPd, inCd, cellId, outCd, insideOut);
		XSRETURN_EMPTY;


void
vtkLine::Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	verts
		vtkCellArray *	lines
		vtkCellArray *	polys
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		CODE:
		THIS->Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd);
		XSRETURN_EMPTY;


int
vtkLine::GetCellDimension()
		CODE:
		RETVAL = THIS->GetCellDimension();
		OUTPUT:
		RETVAL


int
vtkLine::GetCellType()
		CODE:
		RETVAL = THIS->GetCellType();
		OUTPUT:
		RETVAL


const char *
vtkLine::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkCell *
vtkLine::GetEdge(arg1)
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetEdge(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkCell *
vtkLine::GetFace(arg1)
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetFace(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkLine::GetNumberOfEdges()
		CODE:
		RETVAL = THIS->GetNumberOfEdges();
		OUTPUT:
		RETVAL


int
vtkLine::GetNumberOfFaces()
		CODE:
		RETVAL = THIS->GetNumberOfFaces();
		OUTPUT:
		RETVAL


static vtkLine*
vtkLine::New()
		CODE:
		RETVAL = vtkLine::New();
		OUTPUT:
		RETVAL


int
vtkLine::Triangulate(index, ptIds, pts)
		int 	index
		vtkIdList *	ptIds
		vtkPoints *	pts
		CODE:
		RETVAL = THIS->Triangulate(index, ptIds, pts);
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::LinearTransform PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkLinearTransform::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkLinearTransform *
vtkLinearTransform::GetLinearInverse()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkLinearTransform";
		CODE:
		RETVAL = THIS->GetLinearInverse();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


double *
vtkLinearTransform::TransformDoubleNormal(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		double 	arg1
		double 	arg2
		double 	arg3
		PREINIT:
		double * retval;
		CODE:
		SP -= items;
		retval = THIS->TransformDoubleNormal(arg1, arg2, arg3);
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLinearTransform::TransformDoubleNormal\n");



double *
vtkLinearTransform::TransformDoubleVector(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		double 	arg1
		double 	arg2
		double 	arg3
		PREINIT:
		double * retval;
		CODE:
		SP -= items;
		retval = THIS->TransformDoubleVector(arg1, arg2, arg3);
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLinearTransform::TransformDoubleVector\n");



float *
vtkLinearTransform::TransformFloatNormal(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->TransformFloatNormal(arg1, arg2, arg3);
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLinearTransform::TransformFloatNormal\n");



float *
vtkLinearTransform::TransformFloatVector(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->TransformFloatVector(arg1, arg2, arg3);
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLinearTransform::TransformFloatVector\n");



double *
vtkLinearTransform::TransformNormal(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		double 	arg1
		double 	arg2
		double 	arg3
		PREINIT:
		double * retval;
		CODE:
		SP -= items;
		retval = THIS->TransformNormal(arg1, arg2, arg3);
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLinearTransform::TransformNormal\n");



void
vtkLinearTransform::TransformNormals(inNms, outNms)
		vtkDataArray *	inNms
		vtkDataArray *	outNms
		CODE:
		THIS->TransformNormals(inNms, outNms);
		XSRETURN_EMPTY;


void
vtkLinearTransform::TransformPoints(inPts, outPts)
		vtkPoints *	inPts
		vtkPoints *	outPts
		CODE:
		THIS->TransformPoints(inPts, outPts);
		XSRETURN_EMPTY;


void
vtkLinearTransform::TransformPointsNormalsVectors(inPts, outPts, inNms, outNms, inVrs, outVrs)
		vtkPoints *	inPts
		vtkPoints *	outPts
		vtkDataArray *	inNms
		vtkDataArray *	outNms
		vtkDataArray *	inVrs
		vtkDataArray *	outVrs
		CODE:
		THIS->TransformPointsNormalsVectors(inPts, outPts, inNms, outNms, inVrs, outVrs);
		XSRETURN_EMPTY;


double *
vtkLinearTransform::TransformVector(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		double 	arg1
		double 	arg2
		double 	arg3
		PREINIT:
		double * retval;
		CODE:
		SP -= items;
		retval = THIS->TransformVector(arg1, arg2, arg3);
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLinearTransform::TransformVector\n");



void
vtkLinearTransform::TransformVectors(inVrs, outVrs)
		vtkDataArray *	inVrs
		vtkDataArray *	outVrs
		CODE:
		THIS->TransformVectors(inVrs, outVrs);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Locator PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkLocator::AutomaticOff()
		CODE:
		THIS->AutomaticOff();
		XSRETURN_EMPTY;


void
vtkLocator::AutomaticOn()
		CODE:
		THIS->AutomaticOn();
		XSRETURN_EMPTY;


void
vtkLocator::BuildLocator()
		CODE:
		THIS->BuildLocator();
		XSRETURN_EMPTY;


void
vtkLocator::FreeSearchStructure()
		CODE:
		THIS->FreeSearchStructure();
		XSRETURN_EMPTY;


void
vtkLocator::GenerateRepresentation(level, pd)
		int 	level
		vtkPolyData *	pd
		CODE:
		THIS->GenerateRepresentation(level, pd);
		XSRETURN_EMPTY;


int
vtkLocator::GetAutomatic()
		CODE:
		RETVAL = THIS->GetAutomatic();
		OUTPUT:
		RETVAL


unsigned long
vtkLocator::GetBuildTime()
		CODE:
		RETVAL = THIS->GetBuildTime();
		OUTPUT:
		RETVAL


const char *
vtkLocator::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataSet *
vtkLocator::GetDataSet()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataSet";
		CODE:
		RETVAL = THIS->GetDataSet();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkLocator::GetLevel()
		CODE:
		RETVAL = THIS->GetLevel();
		OUTPUT:
		RETVAL


int
vtkLocator::GetMaxLevel()
		CODE:
		RETVAL = THIS->GetMaxLevel();
		OUTPUT:
		RETVAL


int
vtkLocator::GetMaxLevelMaxValue()
		CODE:
		RETVAL = THIS->GetMaxLevelMaxValue();
		OUTPUT:
		RETVAL


int
vtkLocator::GetMaxLevelMinValue()
		CODE:
		RETVAL = THIS->GetMaxLevelMinValue();
		OUTPUT:
		RETVAL


int
vtkLocator::GetRetainCellLists()
		CODE:
		RETVAL = THIS->GetRetainCellLists();
		OUTPUT:
		RETVAL


float
vtkLocator::GetTolerance()
		CODE:
		RETVAL = THIS->GetTolerance();
		OUTPUT:
		RETVAL


float
vtkLocator::GetToleranceMaxValue()
		CODE:
		RETVAL = THIS->GetToleranceMaxValue();
		OUTPUT:
		RETVAL


float
vtkLocator::GetToleranceMinValue()
		CODE:
		RETVAL = THIS->GetToleranceMinValue();
		OUTPUT:
		RETVAL


void
vtkLocator::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


void
vtkLocator::RetainCellListsOff()
		CODE:
		THIS->RetainCellListsOff();
		XSRETURN_EMPTY;


void
vtkLocator::RetainCellListsOn()
		CODE:
		THIS->RetainCellListsOn();
		XSRETURN_EMPTY;


void
vtkLocator::SetAutomatic(arg1)
		int 	arg1
		CODE:
		THIS->SetAutomatic(arg1);
		XSRETURN_EMPTY;


void
vtkLocator::SetDataSet(arg1)
		vtkDataSet *	arg1
		CODE:
		THIS->SetDataSet(arg1);
		XSRETURN_EMPTY;


void
vtkLocator::SetMaxLevel(arg1)
		int 	arg1
		CODE:
		THIS->SetMaxLevel(arg1);
		XSRETURN_EMPTY;


void
vtkLocator::SetRetainCellLists(arg1)
		int 	arg1
		CODE:
		THIS->SetRetainCellLists(arg1);
		XSRETURN_EMPTY;


void
vtkLocator::SetTolerance(arg1)
		float 	arg1
		CODE:
		THIS->SetTolerance(arg1);
		XSRETURN_EMPTY;


void
vtkLocator::Update()
		CODE:
		THIS->Update();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::LogLookupTable PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkLogLookupTable::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkLogLookupTable*
vtkLogLookupTable::New()
		CODE:
		RETVAL = vtkLogLookupTable::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::LongArray PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkLongArray::Allocate(sz, ext)
		const long 	sz
		const long 	ext
		CODE:
		RETVAL = THIS->Allocate(sz, ext);
		OUTPUT:
		RETVAL


void
vtkLongArray::DeepCopy(da)
		vtkDataArray *	da
		CODE:
		THIS->DeepCopy(da);
		XSRETURN_EMPTY;


const char *
vtkLongArray::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkLongArray::GetDataType()
		CODE:
		RETVAL = THIS->GetDataType();
		OUTPUT:
		RETVAL


long
vtkLongArray::GetValue(id)
		const long 	id
		CODE:
		RETVAL = THIS->GetValue(id);
		OUTPUT:
		RETVAL


void
vtkLongArray::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


void
vtkLongArray::InsertComponent(i, j, c)
		const long 	i
		const int 	j
		const float 	c
		CODE:
		THIS->InsertComponent(i, j, c);
		XSRETURN_EMPTY;


long
vtkLongArray::InsertNextValue(arg1)
		const long 	arg1
		CODE:
		RETVAL = THIS->InsertNextValue(arg1);
		OUTPUT:
		RETVAL


void
vtkLongArray::InsertValue(id, i)
		const long 	id
		const long 	i
		CODE:
		THIS->InsertValue(id, i);
		XSRETURN_EMPTY;


static vtkLongArray*
vtkLongArray::New()
		CODE:
		RETVAL = vtkLongArray::New();
		OUTPUT:
		RETVAL


void
vtkLongArray::Resize(numTuples)
		long 	numTuples
		CODE:
		THIS->Resize(numTuples);
		XSRETURN_EMPTY;


void
vtkLongArray::SetNumberOfTuples(number)
		const long 	number
		CODE:
		THIS->SetNumberOfTuples(number);
		XSRETURN_EMPTY;


void
vtkLongArray::SetNumberOfValues(number)
		const long 	number
		CODE:
		THIS->SetNumberOfValues(number);
		XSRETURN_EMPTY;


void
vtkLongArray::SetValue(id, value)
		const long 	id
		const long 	value
		CODE:
		THIS->SetValue(id, value);
		XSRETURN_EMPTY;


void
vtkLongArray::Squeeze()
		CODE:
		THIS->Squeeze();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::LookupTable PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkLookupTable::Allocate(sz, ext)
		int 	sz
		int 	ext
		CODE:
		RETVAL = THIS->Allocate(sz, ext);
		OUTPUT:
		RETVAL


void
vtkLookupTable::Build()
		CODE:
		THIS->Build();
		XSRETURN_EMPTY;


float  *
vtkLookupTable::GetAlphaRange()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetAlphaRange();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


const char *
vtkLookupTable::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float *
vtkLookupTable::GetColor(arg1 = 0)
	CASE: items == 2
		float 	arg1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetColor(arg1);
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLookupTable::GetColor\n");



float  *
vtkLookupTable::GetHueRange()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetHueRange();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


int
vtkLookupTable::GetNumberOfColors()
		CODE:
		RETVAL = THIS->GetNumberOfColors();
		OUTPUT:
		RETVAL


int
vtkLookupTable::GetNumberOfColorsMaxValue()
		CODE:
		RETVAL = THIS->GetNumberOfColorsMaxValue();
		OUTPUT:
		RETVAL


int
vtkLookupTable::GetNumberOfColorsMinValue()
		CODE:
		RETVAL = THIS->GetNumberOfColorsMinValue();
		OUTPUT:
		RETVAL


int
vtkLookupTable::GetNumberOfTableValues()
		CODE:
		RETVAL = THIS->GetNumberOfTableValues();
		OUTPUT:
		RETVAL


float
vtkLookupTable::GetOpacity(v)
		float 	v
		CODE:
		RETVAL = THIS->GetOpacity(v);
		OUTPUT:
		RETVAL


int
vtkLookupTable::GetRamp()
		CODE:
		RETVAL = THIS->GetRamp();
		OUTPUT:
		RETVAL


float  *
vtkLookupTable::GetSaturationRange()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetSaturationRange();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


int
vtkLookupTable::GetScale()
		CODE:
		RETVAL = THIS->GetScale();
		OUTPUT:
		RETVAL


float  *
vtkLookupTable::GetTableRange()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetTableRange();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


float *
vtkLookupTable::GetTableValue(arg1 = 0)
	CASE: items == 2
		int 	arg1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetTableValue(arg1);
		EXTEND(SP, 4);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLookupTable::GetTableValue\n");



float  *
vtkLookupTable::GetValueRange()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetValueRange();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


static vtkLookupTable*
vtkLookupTable::New()
		CODE:
		RETVAL = vtkLookupTable::New();
		OUTPUT:
		RETVAL


void
vtkLookupTable::SetAlphaRange(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetAlphaRange(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLookupTable::SetAlphaRange\n");



void
vtkLookupTable::SetHueRange(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetHueRange(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLookupTable::SetHueRange\n");



void
vtkLookupTable::SetNumberOfColors(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfColors(arg1);
		XSRETURN_EMPTY;


void
vtkLookupTable::SetNumberOfTableValues(number)
		int 	number
		CODE:
		THIS->SetNumberOfTableValues(number);
		XSRETURN_EMPTY;


void
vtkLookupTable::SetRamp(arg1)
		int 	arg1
		CODE:
		THIS->SetRamp(arg1);
		XSRETURN_EMPTY;


void
vtkLookupTable::SetRampToLinear()
		CODE:
		THIS->SetRampToLinear();
		XSRETURN_EMPTY;


void
vtkLookupTable::SetRampToSCurve()
		CODE:
		THIS->SetRampToSCurve();
		XSRETURN_EMPTY;


void
vtkLookupTable::SetRange(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetRange(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLookupTable::SetRange\n");



void
vtkLookupTable::SetSaturationRange(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetSaturationRange(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLookupTable::SetSaturationRange\n");



void
vtkLookupTable::SetScale(scale)
		int 	scale
		CODE:
		THIS->SetScale(scale);
		XSRETURN_EMPTY;


void
vtkLookupTable::SetScaleToLinear()
		CODE:
		THIS->SetScaleToLinear();
		XSRETURN_EMPTY;


void
vtkLookupTable::SetScaleToLog10()
		CODE:
		THIS->SetScaleToLog10();
		XSRETURN_EMPTY;


void
vtkLookupTable::SetTableRange(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetTableRange(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLookupTable::SetTableRange\n");



void
vtkLookupTable::SetTableValue(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0)
	CASE: items == 6
		int 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		float 	arg5
		CODE:
		THIS->SetTableValue(arg1, arg2, arg3, arg4, arg5);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLookupTable::SetTableValue\n");



void
vtkLookupTable::SetValueRange(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetValueRange(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkLookupTable::SetValueRange\n");


MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Mapper2D PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkMapper2D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkMapper2D*
vtkMapper2D::New()
		CODE:
		RETVAL = vtkMapper2D::New();
		OUTPUT:
		RETVAL


void
vtkMapper2D::RenderOpaqueGeometry(arg1, arg2)
		vtkViewport *	arg1
		vtkActor2D *	arg2
		CODE:
		THIS->RenderOpaqueGeometry(arg1, arg2);
		XSRETURN_EMPTY;


void
vtkMapper2D::RenderOverlay(arg1, arg2)
		vtkViewport *	arg1
		vtkActor2D *	arg2
		CODE:
		THIS->RenderOverlay(arg1, arg2);
		XSRETURN_EMPTY;


void
vtkMapper2D::RenderTranslucentGeometry(arg1, arg2)
		vtkViewport *	arg1
		vtkActor2D *	arg2
		CODE:
		THIS->RenderTranslucentGeometry(arg1, arg2);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Math PREFIX = vtk

PROTOTYPES: DISABLE



static float
vtkMath::DegreesToRadians()
		CODE:
		RETVAL = vtkMath::DegreesToRadians();
		OUTPUT:
		RETVAL


static double
vtkMath::Determinant2x2(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		double 	arg1
		double 	arg2
		double 	arg3
		double 	arg4
		CODE:
		RETVAL = vtkMath::Determinant2x2(arg1, arg2, arg3, arg4);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkMath::Determinant2x2\n");



static double
vtkMath::Determinant3x3(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0, arg7 = 0, arg8 = 0, arg9 = 0)
	CASE: items == 10
		double 	arg1
		double 	arg2
		double 	arg3
		double 	arg4
		double 	arg5
		double 	arg6
		double 	arg7
		double 	arg8
		double 	arg9
		CODE:
		RETVAL = vtkMath::Determinant3x3(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkMath::Determinant3x3\n");



static double
vtkMath::DoubleDegreesToRadians()
		CODE:
		RETVAL = vtkMath::DoubleDegreesToRadians();
		OUTPUT:
		RETVAL


const char *
vtkMath::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkMath*
vtkMath::New()
		CODE:
		RETVAL = vtkMath::New();
		OUTPUT:
		RETVAL


static float
vtkMath::Norm2D()
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkMath::Norm2D\n");



static float
vtkMath::Norm()
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkMath::Norm\n");



static float
vtkMath::Normalize()
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkMath::Normalize\n");



static float
vtkMath::Normalize2D()
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkMath::Normalize2D\n");



static float
vtkMath::Pi()
		CODE:
		RETVAL = vtkMath::Pi();
		OUTPUT:
		RETVAL


static float
vtkMath::Random(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		RETVAL = vtkMath::Random(arg1, arg2);
		OUTPUT:
		RETVAL
	CASE: items == 1
		CODE:
		RETVAL = vtkMath::Random();
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkMath::Random\n");



static void
vtkMath::RandomSeed(s)
		long 	s
		CODE:
		vtkMath::RandomSeed(s);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Matrix4x4 PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkMatrix4x4::Adjoint(in, out)
		vtkMatrix4x4 *	in
		vtkMatrix4x4 *	out
		CODE:
		THIS->Adjoint(in, out);
		XSRETURN_EMPTY;


void
vtkMatrix4x4::DeepCopy(arg1 = 0)
	CASE: items == 2
		vtkMatrix4x4 *	arg1
		CODE:
		THIS->DeepCopy(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkMatrix4x4::DeepCopy\n");



double
vtkMatrix4x4::Determinant()
		CODE:
		RETVAL = THIS->Determinant();
		OUTPUT:
		RETVAL


const char *
vtkMatrix4x4::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


double
vtkMatrix4x4::GetElement(i, j)
		int 	i
		int 	j
		CODE:
		RETVAL = THIS->GetElement(i, j);
		OUTPUT:
		RETVAL


void
vtkMatrix4x4::Identity()
		CODE:
		THIS->Identity();
		XSRETURN_EMPTY;


static void
vtkMatrix4x4::Invert(arg1 = 0, arg2 = 0)
	CASE: items == 3
		vtkMatrix4x4 *	arg1
		vtkMatrix4x4 *	arg2
		CODE:
		vtkMatrix4x4::Invert(arg1, arg2);
		XSRETURN_EMPTY;
	CASE: items == 1
		PREINIT:
		vtkMatrix4x4 *  THIS;
		if( sv_isobject(ST(0)) && (SvTYPE(SvRV(ST(0))) == SVt_PVMG) )
			if (sv_derived_from(ST(0), "Graphics::VTK::Matrix4x4")) {
				THIS = (vtkMatrix4x4 *)SvIV((SV*)SvRV( ST(0) ));
			}
			else{
				croak("Graphics::VTK::Invert() -- THIS not of type Graphics::VTK::Matrix4x4");
			}
		else{
			warn( "Graphics::VTK::Invert() -- THIS is not a blessed SV reference" );
			XSRETURN_UNDEF;
		};
		CODE:
		THIS->Invert();
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkMatrix4x4::Invert\n");



static void
vtkMatrix4x4::Multiply4x4(a, b, c)
		vtkMatrix4x4 *	a
		vtkMatrix4x4 *	b
		vtkMatrix4x4 *	c
		CODE:
		vtkMatrix4x4::Multiply4x4(a, b, c);
		XSRETURN_EMPTY;




float *
vtkMatrix4x4::MultiplyPoint()
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkMatrix4x4::MultiplyPoint\n");



static vtkMatrix4x4*
vtkMatrix4x4::New()
		CODE:
		RETVAL = vtkMatrix4x4::New();
		OUTPUT:
		RETVAL


void
vtkMatrix4x4::SetElement(i, j, value)
		int 	i
		int 	j
		double 	value
		CODE:
		THIS->SetElement(i, j, value);
		XSRETURN_EMPTY;


static void
vtkMatrix4x4::Transpose(arg1 = 0, arg2 = 0)
	CASE: items == 3
		vtkMatrix4x4 *	arg1
		vtkMatrix4x4 *	arg2
		CODE:
		vtkMatrix4x4::Transpose(arg1, arg2);
		XSRETURN_EMPTY;
	CASE: items == 1
		PREINIT:
		vtkMatrix4x4 *  THIS;
		if( sv_isobject(ST(0)) && (SvTYPE(SvRV(ST(0))) == SVt_PVMG) )
			if (sv_derived_from(ST(0), "Graphics::VTK::Matrix4x4")) {
				THIS = (vtkMatrix4x4 *)SvIV((SV*)SvRV( ST(0) ));
			}
			else{
				croak("Graphics::VTK::Transpose() -- THIS not of type Graphics::VTK::Matrix4x4");
			}
		else{
			warn( "Graphics::VTK::Transpose() -- THIS is not a blessed SV reference" );
			XSRETURN_UNDEF;
		};
		CODE:
		THIS->Transpose();
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkMatrix4x4::Transpose\n");



void
vtkMatrix4x4::Zero()
		CODE:
		THIS->Zero();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::MatrixToHomogeneousTransform PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkMatrixToHomogeneousTransform::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkMatrix4x4 *
vtkMatrixToHomogeneousTransform::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkMatrix4x4";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkMatrixToHomogeneousTransform::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


void
vtkMatrixToHomogeneousTransform::Inverse()
		CODE:
		THIS->Inverse();
		XSRETURN_EMPTY;


vtkAbstractTransform *
vtkMatrixToHomogeneousTransform::MakeTransform()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAbstractTransform";
		CODE:
		RETVAL = THIS->MakeTransform();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkMatrixToHomogeneousTransform*
vtkMatrixToHomogeneousTransform::New()
		CODE:
		RETVAL = vtkMatrixToHomogeneousTransform::New();
		OUTPUT:
		RETVAL


void
vtkMatrixToHomogeneousTransform::SetInput(arg1)
		vtkMatrix4x4 *	arg1
		CODE:
		THIS->SetInput(arg1);
		XSRETURN_EMPTY;


void
vtkMatrixToHomogeneousTransform::SetMatrix(matrix)
		vtkMatrix4x4 *	matrix
		CODE:
		THIS->SetMatrix(matrix);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::MatrixToLinearTransform PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkMatrixToLinearTransform::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkMatrix4x4 *
vtkMatrixToLinearTransform::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkMatrix4x4";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


unsigned long
vtkMatrixToLinearTransform::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


void
vtkMatrixToLinearTransform::Inverse()
		CODE:
		THIS->Inverse();
		XSRETURN_EMPTY;


vtkAbstractTransform *
vtkMatrixToLinearTransform::MakeTransform()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAbstractTransform";
		CODE:
		RETVAL = THIS->MakeTransform();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkMatrixToLinearTransform*
vtkMatrixToLinearTransform::New()
		CODE:
		RETVAL = vtkMatrixToLinearTransform::New();
		OUTPUT:
		RETVAL


void
vtkMatrixToLinearTransform::SetInput(arg1)
		vtkMatrix4x4 *	arg1
		CODE:
		THIS->SetInput(arg1);
		XSRETURN_EMPTY;


void
vtkMatrixToLinearTransform::SetMatrix(matrix)
		vtkMatrix4x4 *	matrix
		CODE:
		THIS->SetMatrix(matrix);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::MultiThreader PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkMultiThreader::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static int
vtkMultiThreader::GetGlobalDefaultNumberOfThreads()
		CODE:
		RETVAL = vtkMultiThreader::GetGlobalDefaultNumberOfThreads();
		OUTPUT:
		RETVAL


static int
vtkMultiThreader::GetGlobalMaximumNumberOfThreads()
		CODE:
		RETVAL = vtkMultiThreader::GetGlobalMaximumNumberOfThreads();
		OUTPUT:
		RETVAL


int
vtkMultiThreader::GetNumberOfThreads()
		CODE:
		RETVAL = THIS->GetNumberOfThreads();
		OUTPUT:
		RETVAL


int
vtkMultiThreader::GetNumberOfThreadsMaxValue()
		CODE:
		RETVAL = THIS->GetNumberOfThreadsMaxValue();
		OUTPUT:
		RETVAL


int
vtkMultiThreader::GetNumberOfThreadsMinValue()
		CODE:
		RETVAL = THIS->GetNumberOfThreadsMinValue();
		OUTPUT:
		RETVAL


static vtkMultiThreader*
vtkMultiThreader::New()
		CODE:
		RETVAL = vtkMultiThreader::New();
		OUTPUT:
		RETVAL


static void
vtkMultiThreader::SetGlobalDefaultNumberOfThreads(val)
		int 	val
		CODE:
		vtkMultiThreader::SetGlobalDefaultNumberOfThreads(val);
		XSRETURN_EMPTY;


static void
vtkMultiThreader::SetGlobalMaximumNumberOfThreads(val)
		int 	val
		CODE:
		vtkMultiThreader::SetGlobalMaximumNumberOfThreads(val);
		XSRETURN_EMPTY;


void
vtkMultiThreader::SetNumberOfThreads(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfThreads(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::MutexLock PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkMutexLock::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


void
vtkMutexLock::Lock()
		CODE:
		THIS->Lock();
		XSRETURN_EMPTY;


static vtkMutexLock*
vtkMutexLock::New()
		CODE:
		RETVAL = vtkMutexLock::New();
		OUTPUT:
		RETVAL


void
vtkMutexLock::Unlock()
		CODE:
		THIS->Unlock();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Object PREFIX = vtk

PROTOTYPES: DISABLE


unsigned long
vtkObject::AddObserver(event, func)
		char*	event
		SV*	func
		CODE:
    		vtkPerlCommand *cmd = vtkPerlCommand::New();
		cmd->SetCallback(func);		
		RETVAL = THIS->AddObserver(event, cmd);
		cmd->Delete();
		OUTPUT:
		RETVAL
		
char *
vtkObject::Print()
		CODE:
		ostrstream ostrm;
		THIS->Print(ostrm);
		RETVAL = ostrm.str();
		OUTPUT:
		RETVAL
		


static void
vtkObject::BreakOnError()
		CODE:
		vtkObject::BreakOnError();
		XSRETURN_EMPTY;


void
vtkObject::DebugOff()
		CODE:
		THIS->DebugOff();
		XSRETURN_EMPTY;


void
vtkObject::DebugOn()
		CODE:
		THIS->DebugOn();
		XSRETURN_EMPTY;


void
vtkObject::Delete()
		CODE:
		THIS->Delete();
		XSRETURN_EMPTY;


const char *
vtkObject::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


unsigned char
vtkObject::GetDebug()
		CODE:
		RETVAL = THIS->GetDebug();
		OUTPUT:
		RETVAL


static int
vtkObject::GetGlobalWarningDisplay()
		CODE:
		RETVAL = vtkObject::GetGlobalWarningDisplay();
		OUTPUT:
		RETVAL


unsigned long
vtkObject::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkObject::GetReferenceCount()
		CODE:
		RETVAL = THIS->GetReferenceCount();
		OUTPUT:
		RETVAL


static void
vtkObject::GlobalWarningDisplayOff()
		CODE:
		vtkObject::GlobalWarningDisplayOff();
		XSRETURN_EMPTY;


static void
vtkObject::GlobalWarningDisplayOn()
		CODE:
		vtkObject::GlobalWarningDisplayOn();
		XSRETURN_EMPTY;


int
vtkObject::HasObserver(arg1 = 0)
	CASE: items == 2 && SvPOK(ST(1))
		const char *	arg1
		CODE:
		RETVAL = THIS->HasObserver(arg1);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkObject::HasObserver\n");



static int
vtkObject::IsTypeOf(name)
		const char *	name
		CODE:
		RETVAL = vtkObject::IsTypeOf(name);
		OUTPUT:
		RETVAL


void
vtkObject::Modified()
		CODE:
		THIS->Modified();
		XSRETURN_EMPTY;


static vtkObject*
vtkObject::New()
		CODE:
		RETVAL = vtkObject::New();
		OUTPUT:
		RETVAL


void
vtkObject::Register(o)
		vtkObject *	o
		CODE:
		THIS->Register(o);
		XSRETURN_EMPTY;


void
vtkObject::RemoveObserver(tag)
		unsigned long 	tag
		CODE:
		THIS->RemoveObserver(tag);
		XSRETURN_EMPTY;


static vtkObject *
vtkObject::SafeDownCast(o)
		vtkObject *	o
		CODE:
		RETVAL = vtkObject::SafeDownCast(o);
		OUTPUT:
		RETVAL


void
vtkObject::SetDebug(debugFlag)
		unsigned char 	debugFlag
		CODE:
		THIS->SetDebug(debugFlag);
		XSRETURN_EMPTY;


static void
vtkObject::SetGlobalWarningDisplay(val)
		int 	val
		CODE:
		vtkObject::SetGlobalWarningDisplay(val);
		XSRETURN_EMPTY;


void
vtkObject::SetReferenceCount(arg1)
		int 	arg1
		CODE:
		THIS->SetReferenceCount(arg1);
		XSRETURN_EMPTY;


void
vtkObject::UnRegister(o)
		vtkObject *	o
		CODE:
		THIS->UnRegister(o);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::ObjectFactory PREFIX = vtk

PROTOTYPES: DISABLE



static vtkObject *
vtkObjectFactory::CreateInstance(vtkclassname)
		const char *	vtkclassname
		CODE:
		RETVAL = vtkObjectFactory::CreateInstance(vtkclassname);
		OUTPUT:
		RETVAL


void
vtkObjectFactory::Disable(className)
		const char *	className
		CODE:
		THIS->Disable(className);
		XSRETURN_EMPTY;


const char *
vtkObjectFactory::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


const char *
vtkObjectFactory::GetClassOverrideName(index)
		int 	index
		CODE:
		RETVAL = THIS->GetClassOverrideName(index);
		OUTPUT:
		RETVAL


const char *
vtkObjectFactory::GetClassOverrideWithName(index)
		int 	index
		CODE:
		RETVAL = THIS->GetClassOverrideWithName(index);
		OUTPUT:
		RETVAL


const char *
vtkObjectFactory::GetDescription()
		CODE:
		RETVAL = THIS->GetDescription();
		OUTPUT:
		RETVAL


int
vtkObjectFactory::GetEnableFlag(arg1 = 0, arg2 = 0)
	CASE: items == 3
		const char *	arg1
		const char *	arg2
		CODE:
		RETVAL = THIS->GetEnableFlag(arg1, arg2);
		OUTPUT:
		RETVAL
	CASE: items == 2
		int 	arg1
		CODE:
		RETVAL = THIS->GetEnableFlag(arg1);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkObjectFactory::GetEnableFlag\n");



char *
vtkObjectFactory::GetLibraryPath()
		CODE:
		RETVAL = THIS->GetLibraryPath();
		OUTPUT:
		RETVAL


int
vtkObjectFactory::GetNumberOfOverrides()
		CODE:
		RETVAL = THIS->GetNumberOfOverrides();
		OUTPUT:
		RETVAL


const char *
vtkObjectFactory::GetOverrideDescription(index)
		int 	index
		CODE:
		RETVAL = THIS->GetOverrideDescription(index);
		OUTPUT:
		RETVAL


static void
vtkObjectFactory::GetOverrideInformation(name, arg2)
		const char *	name
		vtkOverrideInformationCollection *	arg2
		CODE:
		vtkObjectFactory::GetOverrideInformation(name, arg2);
		XSRETURN_EMPTY;


static vtkObjectFactoryCollection *
vtkObjectFactory::GetRegisteredFactories()
		CODE:
		RETVAL = vtkObjectFactory::GetRegisteredFactories();
		OUTPUT:
		RETVAL


const char *
vtkObjectFactory::GetVTKSourceVersion()
		CODE:
		RETVAL = THIS->GetVTKSourceVersion();
		OUTPUT:
		RETVAL


int
vtkObjectFactory::HasOverride(arg1 = 0, arg2 = 0)
	CASE: items == 3
		const char *	arg1
		const char *	arg2
		CODE:
		RETVAL = THIS->HasOverride(arg1, arg2);
		OUTPUT:
		RETVAL
	CASE: items == 2
		const char *	arg1
		CODE:
		RETVAL = THIS->HasOverride(arg1);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkObjectFactory::HasOverride\n");



static int
vtkObjectFactory::HasOverrideAny(className)
		const char *	className
		CODE:
		RETVAL = vtkObjectFactory::HasOverrideAny(className);
		OUTPUT:
		RETVAL


static void
vtkObjectFactory::ReHash()
		CODE:
		vtkObjectFactory::ReHash();
		XSRETURN_EMPTY;


static void
vtkObjectFactory::RegisterFactory(arg1)
		vtkObjectFactory *	arg1
		CODE:
		vtkObjectFactory::RegisterFactory(arg1);
		XSRETURN_EMPTY;


static void
vtkObjectFactory::SetAllEnableFlags(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		const char *	arg2
		const char *	arg3
		CODE:
		vtkObjectFactory::SetAllEnableFlags(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE: items == 3
		int 	arg1
		const char *	arg2
		CODE:
		vtkObjectFactory::SetAllEnableFlags(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkObjectFactory::SetAllEnableFlags\n");



void
vtkObjectFactory::SetEnableFlag(flag, className, subclassName)
		int 	flag
		const char *	className
		const char *	subclassName
		CODE:
		THIS->SetEnableFlag(flag, className, subclassName);
		XSRETURN_EMPTY;


static void
vtkObjectFactory::UnRegisterAllFactories()
		CODE:
		vtkObjectFactory::UnRegisterAllFactories();
		XSRETURN_EMPTY;


static void
vtkObjectFactory::UnRegisterFactory(arg1)
		vtkObjectFactory *	arg1
		CODE:
		vtkObjectFactory::UnRegisterFactory(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::ObjectFactoryCollection PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkObjectFactoryCollection::AddItem(arg1 = 0)
	CASE: items == 2
		vtkObjectFactory *	arg1
		CODE:
		THIS->AddItem(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkObjectFactoryCollection::AddItem\n");



const char *
vtkObjectFactoryCollection::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkObjectFactory *
vtkObjectFactoryCollection::GetNextItem()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkObjectFactory";
		CODE:
		RETVAL = THIS->GetNextItem();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkObjectFactoryCollection*
vtkObjectFactoryCollection::New()
		CODE:
		RETVAL = vtkObjectFactoryCollection::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::OrderedTriangulator PREFIX = vtk

PROTOTYPES: DISABLE



long
vtkOrderedTriangulator::AddTetras(arg1 = 0, arg2 = 0)
	CASE: items == 3 && sv_isobject(ST(2)) && sv_derived_from(ST(2),"Graphics::VTK::UnstructuredGrid")
		int 	arg1
		vtkUnstructuredGrid *	arg2
		CODE:
		RETVAL = THIS->AddTetras(arg1, arg2);
		OUTPUT:
		RETVAL
	CASE: items == 3 && sv_isobject(ST(2)) && sv_derived_from(ST(2),"Graphics::VTK::CellArray")
		int 	arg1
		vtkCellArray *	arg2
		CODE:
		RETVAL = THIS->AddTetras(arg1, arg2);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkOrderedTriangulator::AddTetras\n");



const char *
vtkOrderedTriangulator::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkOrderedTriangulator::GetPreSorted()
		CODE:
		RETVAL = THIS->GetPreSorted();
		OUTPUT:
		RETVAL


long
vtkOrderedTriangulator::GetTetras(classification, ugrid)
		int 	classification
		vtkUnstructuredGrid *	ugrid
		CODE:
		RETVAL = THIS->GetTetras(classification, ugrid);
		OUTPUT:
		RETVAL


static vtkOrderedTriangulator*
vtkOrderedTriangulator::New()
		CODE:
		RETVAL = vtkOrderedTriangulator::New();
		OUTPUT:
		RETVAL


void
vtkOrderedTriangulator::PreSortedOff()
		CODE:
		THIS->PreSortedOff();
		XSRETURN_EMPTY;


void
vtkOrderedTriangulator::PreSortedOn()
		CODE:
		THIS->PreSortedOn();
		XSRETURN_EMPTY;


void
vtkOrderedTriangulator::SetPreSorted(arg1)
		int 	arg1
		CODE:
		THIS->SetPreSorted(arg1);
		XSRETURN_EMPTY;


void
vtkOrderedTriangulator::Triangulate()
		CODE:
		THIS->Triangulate();
		XSRETURN_EMPTY;


void
vtkOrderedTriangulator::UpdatePointType(internalId, type)
		long 	internalId
		int 	type
		CODE:
		THIS->UpdatePointType(internalId, type);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::OutputWindow PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkOutputWindow::DisplayDebugText(arg1)
		const char *	arg1
		CODE:
		THIS->DisplayDebugText(arg1);
		XSRETURN_EMPTY;


void
vtkOutputWindow::DisplayErrorText(arg1)
		const char *	arg1
		CODE:
		THIS->DisplayErrorText(arg1);
		XSRETURN_EMPTY;


void
vtkOutputWindow::DisplayGenericWarningText(arg1)
		const char *	arg1
		CODE:
		THIS->DisplayGenericWarningText(arg1);
		XSRETURN_EMPTY;


void
vtkOutputWindow::DisplayText(arg1)
		const char *	arg1
		CODE:
		THIS->DisplayText(arg1);
		XSRETURN_EMPTY;


void
vtkOutputWindow::DisplayWarningText(arg1)
		const char *	arg1
		CODE:
		THIS->DisplayWarningText(arg1);
		XSRETURN_EMPTY;


const char *
vtkOutputWindow::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkOutputWindow *
vtkOutputWindow::GetInstance()
		CODE:
		RETVAL = vtkOutputWindow::GetInstance();
		OUTPUT:
		RETVAL


static vtkOutputWindow*
vtkOutputWindow::New()
		CODE:
		RETVAL = vtkOutputWindow::New();
		OUTPUT:
		RETVAL


void
vtkOutputWindow::PromptUserOff()
		CODE:
		THIS->PromptUserOff();
		XSRETURN_EMPTY;


void
vtkOutputWindow::PromptUserOn()
		CODE:
		THIS->PromptUserOn();
		XSRETURN_EMPTY;


static void
vtkOutputWindow::SetInstance(instance)
		vtkOutputWindow *	instance
		CODE:
		vtkOutputWindow::SetInstance(instance);
		XSRETURN_EMPTY;


void
vtkOutputWindow::SetPromptUser(arg1)
		int 	arg1
		CODE:
		THIS->SetPromptUser(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::OverrideInformation PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkOverrideInformation::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


const char *
vtkOverrideInformation::GetClassOverrideName()
		CODE:
		RETVAL = THIS->GetClassOverrideName();
		OUTPUT:
		RETVAL


const char *
vtkOverrideInformation::GetClassOverrideWithName()
		CODE:
		RETVAL = THIS->GetClassOverrideWithName();
		OUTPUT:
		RETVAL


const char *
vtkOverrideInformation::GetDescription()
		CODE:
		RETVAL = THIS->GetDescription();
		OUTPUT:
		RETVAL


vtkObjectFactory *
vtkOverrideInformation::GetObjectFactory()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkObjectFactory";
		CODE:
		RETVAL = THIS->GetObjectFactory();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkOverrideInformation*
vtkOverrideInformation::New()
		CODE:
		RETVAL = vtkOverrideInformation::New();
		OUTPUT:
		RETVAL


void
vtkOverrideInformation::SetClassOverrideName(arg1)
		char *	arg1
		CODE:
		THIS->SetClassOverrideName(arg1);
		XSRETURN_EMPTY;


void
vtkOverrideInformation::SetClassOverrideWithName(arg1)
		char *	arg1
		CODE:
		THIS->SetClassOverrideWithName(arg1);
		XSRETURN_EMPTY;


void
vtkOverrideInformation::SetDescription(arg1)
		char *	arg1
		CODE:
		THIS->SetDescription(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::OverrideInformationCollection PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkOverrideInformationCollection::AddItem(arg1 = 0)
	CASE: items == 2
		vtkOverrideInformation *	arg1
		CODE:
		THIS->AddItem(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkOverrideInformationCollection::AddItem\n");



const char *
vtkOverrideInformationCollection::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkOverrideInformation *
vtkOverrideInformationCollection::GetNextItem()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkOverrideInformation";
		CODE:
		RETVAL = THIS->GetNextItem();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkOverrideInformationCollection*
vtkOverrideInformationCollection::New()
		CODE:
		RETVAL = vtkOverrideInformationCollection::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::PerspectiveTransform PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkPerspectiveTransform::AdjustViewport(oldXMin, oldXMax, oldYMin, oldYMax, newXMin, newXMax, newYMin, newYMax)
		double 	oldXMin
		double 	oldXMax
		double 	oldYMin
		double 	oldYMax
		double 	newXMin
		double 	newXMax
		double 	newYMin
		double 	newYMax
		CODE:
		THIS->AdjustViewport(oldXMin, oldXMax, oldYMin, oldYMax, newXMin, newXMax, newYMin, newYMax);
		XSRETURN_EMPTY;


void
vtkPerspectiveTransform::AdjustZBuffer(oldNearZ, oldFarZ, newNearZ, newFarZ)
		double 	oldNearZ
		double 	oldFarZ
		double 	newNearZ
		double 	newFarZ
		CODE:
		THIS->AdjustZBuffer(oldNearZ, oldFarZ, newNearZ, newFarZ);
		XSRETURN_EMPTY;


int
vtkPerspectiveTransform::CircuitCheck(transform)
		vtkAbstractTransform *	transform
		CODE:
		RETVAL = THIS->CircuitCheck(transform);
		OUTPUT:
		RETVAL


void
vtkPerspectiveTransform::Concatenate(arg1 = 0)
	CASE: items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1),"Graphics::VTK::Matrix4x4")
		vtkMatrix4x4 *	arg1
		CODE:
		THIS->Concatenate(arg1);
		XSRETURN_EMPTY;
	CASE: items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1),"Graphics::VTK::HomogeneousTransform")
		vtkHomogeneousTransform *	arg1
		CODE:
		THIS->Concatenate(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPerspectiveTransform::Concatenate\n");



void
vtkPerspectiveTransform::Frustum(xmin, xmax, ymin, ymax, znear, zfar)
		double 	xmin
		double 	xmax
		double 	ymin
		double 	ymax
		double 	znear
		double 	zfar
		CODE:
		THIS->Frustum(xmin, xmax, ymin, ymax, znear, zfar);
		XSRETURN_EMPTY;


const char *
vtkPerspectiveTransform::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkHomogeneousTransform *
vtkPerspectiveTransform::GetConcatenatedTransform(i)
		int 	i
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkHomogeneousTransform";
		CODE:
		RETVAL = THIS->GetConcatenatedTransform(i);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkHomogeneousTransform *
vtkPerspectiveTransform::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkHomogeneousTransform";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkPerspectiveTransform::GetInverseFlag()
		CODE:
		RETVAL = THIS->GetInverseFlag();
		OUTPUT:
		RETVAL


unsigned long
vtkPerspectiveTransform::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkPerspectiveTransform::GetNumberOfConcatenatedTransforms()
		CODE:
		RETVAL = THIS->GetNumberOfConcatenatedTransforms();
		OUTPUT:
		RETVAL


void
vtkPerspectiveTransform::Identity()
		CODE:
		THIS->Identity();
		XSRETURN_EMPTY;


void
vtkPerspectiveTransform::Inverse()
		CODE:
		THIS->Inverse();
		XSRETURN_EMPTY;


vtkAbstractTransform *
vtkPerspectiveTransform::MakeTransform()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAbstractTransform";
		CODE:
		RETVAL = THIS->MakeTransform();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkPerspectiveTransform*
vtkPerspectiveTransform::New()
		CODE:
		RETVAL = vtkPerspectiveTransform::New();
		OUTPUT:
		RETVAL


void
vtkPerspectiveTransform::Ortho(xmin, xmax, ymin, ymax, znear, zfar)
		double 	xmin
		double 	xmax
		double 	ymin
		double 	ymax
		double 	znear
		double 	zfar
		CODE:
		THIS->Ortho(xmin, xmax, ymin, ymax, znear, zfar);
		XSRETURN_EMPTY;


void
vtkPerspectiveTransform::Perspective(angle, aspect, znear, zfar)
		double 	angle
		double 	aspect
		double 	znear
		double 	zfar
		CODE:
		THIS->Perspective(angle, aspect, znear, zfar);
		XSRETURN_EMPTY;


void
vtkPerspectiveTransform::Pop()
		CODE:
		THIS->Pop();
		XSRETURN_EMPTY;


void
vtkPerspectiveTransform::PostMultiply()
		CODE:
		THIS->PostMultiply();
		XSRETURN_EMPTY;


void
vtkPerspectiveTransform::PreMultiply()
		CODE:
		THIS->PreMultiply();
		XSRETURN_EMPTY;


void
vtkPerspectiveTransform::Push()
		CODE:
		THIS->Push();
		XSRETURN_EMPTY;


void
vtkPerspectiveTransform::RotateWXYZ(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		double 	arg1
		double 	arg2
		double 	arg3
		double 	arg4
		CODE:
		THIS->RotateWXYZ(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPerspectiveTransform::RotateWXYZ\n");



void
vtkPerspectiveTransform::RotateX(angle)
		double 	angle
		CODE:
		THIS->RotateX(angle);
		XSRETURN_EMPTY;


void
vtkPerspectiveTransform::RotateY(angle)
		double 	angle
		CODE:
		THIS->RotateY(angle);
		XSRETURN_EMPTY;


void
vtkPerspectiveTransform::RotateZ(angle)
		double 	angle
		CODE:
		THIS->RotateZ(angle);
		XSRETURN_EMPTY;


void
vtkPerspectiveTransform::Scale(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		double 	arg1
		double 	arg2
		double 	arg3
		CODE:
		THIS->Scale(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPerspectiveTransform::Scale\n");



void
vtkPerspectiveTransform::SetInput(input)
		vtkHomogeneousTransform *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;


void
vtkPerspectiveTransform::SetMatrix(arg1 = 0)
	CASE: items == 2
		vtkMatrix4x4 *	arg1
		CODE:
		THIS->SetMatrix(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPerspectiveTransform::SetMatrix\n");



void
vtkPerspectiveTransform::Shear(dxdz, dydz, zplane)
		double 	dxdz
		double 	dydz
		double 	zplane
		CODE:
		THIS->Shear(dxdz, dydz, zplane);
		XSRETURN_EMPTY;


void
vtkPerspectiveTransform::Stereo(angle, focaldistance)
		double 	angle
		double 	focaldistance
		CODE:
		THIS->Stereo(angle, focaldistance);
		XSRETURN_EMPTY;


void
vtkPerspectiveTransform::Translate(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		double 	arg1
		double 	arg2
		double 	arg3
		CODE:
		THIS->Translate(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPerspectiveTransform::Translate\n");


MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Pixel PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkPixel::Clip(value, cellScalars, locator, polys, inPd, outPd, inCd, cellId, outCd, insideOut)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	polys
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		int 	insideOut
		CODE:
		THIS->Clip(value, cellScalars, locator, polys, inPd, outPd, inCd, cellId, outCd, insideOut);
		XSRETURN_EMPTY;


void
vtkPixel::Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	verts
		vtkCellArray *	lines
		vtkCellArray *	polys
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		CODE:
		THIS->Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd);
		XSRETURN_EMPTY;


int
vtkPixel::GetCellDimension()
		CODE:
		RETVAL = THIS->GetCellDimension();
		OUTPUT:
		RETVAL


int
vtkPixel::GetCellType()
		CODE:
		RETVAL = THIS->GetCellType();
		OUTPUT:
		RETVAL


const char *
vtkPixel::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkCell *
vtkPixel::GetEdge(edgeId)
		int 	edgeId
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetEdge(edgeId);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkCell *
vtkPixel::GetFace(arg1)
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetFace(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkPixel::GetNumberOfEdges()
		CODE:
		RETVAL = THIS->GetNumberOfEdges();
		OUTPUT:
		RETVAL


int
vtkPixel::GetNumberOfFaces()
		CODE:
		RETVAL = THIS->GetNumberOfFaces();
		OUTPUT:
		RETVAL


static vtkPixel*
vtkPixel::New()
		CODE:
		RETVAL = vtkPixel::New();
		OUTPUT:
		RETVAL


int
vtkPixel::Triangulate(index, ptIds, pts)
		int 	index
		vtkIdList *	ptIds
		vtkPoints *	pts
		CODE:
		RETVAL = THIS->Triangulate(index, ptIds, pts);
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Plane PREFIX = vtk

PROTOTYPES: DISABLE



float
vtkPlane::EvaluateFunction(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		RETVAL = THIS->EvaluateFunction(arg1, arg2, arg3);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPlane::EvaluateFunction\n");



const char *
vtkPlane::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkPlane::GetNormal()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetNormal();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkPlane::GetOrigin()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOrigin();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


static vtkPlane*
vtkPlane::New()
		CODE:
		RETVAL = vtkPlane::New();
		OUTPUT:
		RETVAL


void
vtkPlane::SetNormal(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetNormal(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPlane::SetNormal\n");



void
vtkPlane::SetOrigin(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetOrigin(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPlane::SetOrigin\n");


MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::PlaneCollection PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkPlaneCollection::AddItem(arg1 = 0)
	CASE: items == 2
		vtkPlane *	arg1
		CODE:
		THIS->AddItem(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPlaneCollection::AddItem\n");



const char *
vtkPlaneCollection::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkPlane *
vtkPlaneCollection::GetNextItem()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPlane";
		CODE:
		RETVAL = THIS->GetNextItem();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkPlaneCollection*
vtkPlaneCollection::New()
		CODE:
		RETVAL = vtkPlaneCollection::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Planes PREFIX = vtk

PROTOTYPES: DISABLE



float
vtkPlanes::EvaluateFunction(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		RETVAL = THIS->EvaluateFunction(arg1, arg2, arg3);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPlanes::EvaluateFunction\n");



const char *
vtkPlanes::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataArray *
vtkPlanes::GetNormals()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataArray";
		CODE:
		RETVAL = THIS->GetNormals();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkPlanes::GetNumberOfPlanes()
		CODE:
		RETVAL = THIS->GetNumberOfPlanes();
		OUTPUT:
		RETVAL


vtkPlane *
vtkPlanes::GetPlane(i)
		int 	i
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPlane";
		CODE:
		RETVAL = THIS->GetPlane(i);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkPoints *
vtkPlanes::GetPoints()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPoints";
		CODE:
		RETVAL = THIS->GetPoints();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkPlanes*
vtkPlanes::New()
		CODE:
		RETVAL = vtkPlanes::New();
		OUTPUT:
		RETVAL


void
vtkPlanes::SetBounds(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		float 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		float 	arg5
		float 	arg6
		CODE:
		THIS->SetBounds(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPlanes::SetBounds\n");




void
vtkPlanes::SetNormals(normals)
		vtkDataArray *	normals
		CODE:
		THIS->SetNormals(normals);
		XSRETURN_EMPTY;


void
vtkPlanes::SetPoints(arg1)
		vtkPoints *	arg1
		CODE:
		THIS->SetPoints(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::PointData PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkPointData::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkPointData*
vtkPointData::New()
		CODE:
		RETVAL = vtkPointData::New();
		OUTPUT:
		RETVAL


void
vtkPointData::NullPoint(ptId)
		long 	ptId
		CODE:
		THIS->NullPoint(ptId);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::PointLocator PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkPointLocator::BuildLocator()
		CODE:
		THIS->BuildLocator();
		XSRETURN_EMPTY;



void
vtkPointLocator::FindClosestNPoints(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0)
	CASE: items == 6
		int 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		vtkIdList *	arg5
		CODE:
		THIS->FindClosestNPoints(arg1, arg2, arg3, arg4, arg5);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPointLocator::FindClosestNPoints\n");



long
vtkPointLocator::FindClosestPoint(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		RETVAL = THIS->FindClosestPoint(arg1, arg2, arg3);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPointLocator::FindClosestPoint\n");



void
vtkPointLocator::FindDistributedPoints(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		vtkIdList *	arg5
		int 	arg6
		CODE:
		THIS->FindDistributedPoints(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPointLocator::FindDistributedPoints\n");



void
vtkPointLocator::FindPointsWithinRadius(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0)
	CASE: items == 6
		float 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		vtkIdList *	arg5
		CODE:
		THIS->FindPointsWithinRadius(arg1, arg2, arg3, arg4, arg5);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPointLocator::FindPointsWithinRadius\n");



void
vtkPointLocator::FreeSearchStructure()
		CODE:
		THIS->FreeSearchStructure();
		XSRETURN_EMPTY;


void
vtkPointLocator::GenerateRepresentation(level, pd)
		int 	level
		vtkPolyData *	pd
		CODE:
		THIS->GenerateRepresentation(level, pd);
		XSRETURN_EMPTY;


const char *
vtkPointLocator::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int  *
vtkPointLocator::GetDivisions()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDivisions();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int
vtkPointLocator::GetNumberOfPointsPerBucket()
		CODE:
		RETVAL = THIS->GetNumberOfPointsPerBucket();
		OUTPUT:
		RETVAL


int
vtkPointLocator::GetNumberOfPointsPerBucketMaxValue()
		CODE:
		RETVAL = THIS->GetNumberOfPointsPerBucketMaxValue();
		OUTPUT:
		RETVAL


int
vtkPointLocator::GetNumberOfPointsPerBucketMinValue()
		CODE:
		RETVAL = THIS->GetNumberOfPointsPerBucketMinValue();
		OUTPUT:
		RETVAL


void
vtkPointLocator::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;



long
vtkPointLocator::IsInsertedPoint(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		RETVAL = THIS->IsInsertedPoint(arg1, arg2, arg3);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPointLocator::IsInsertedPoint\n");



static vtkPointLocator*
vtkPointLocator::New()
		CODE:
		RETVAL = vtkPointLocator::New();
		OUTPUT:
		RETVAL


void
vtkPointLocator::SetDivisions(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetDivisions(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPointLocator::SetDivisions\n");



void
vtkPointLocator::SetNumberOfPointsPerBucket(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfPointsPerBucket(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::PointLocator2D PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkPointLocator2D::BuildLocator()
		CODE:
		THIS->BuildLocator();
		XSRETURN_EMPTY;


void
vtkPointLocator2D::FindClosestNPoints(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		int 	arg1
		float 	arg2
		float 	arg3
		vtkIdList *	arg4
		CODE:
		THIS->FindClosestNPoints(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPointLocator2D::FindClosestNPoints\n");




void
vtkPointLocator2D::FindDistributedPoints(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0)
	CASE: items == 6
		int 	arg1
		float 	arg2
		float 	arg3
		vtkIdList *	arg4
		int 	arg5
		CODE:
		THIS->FindDistributedPoints(arg1, arg2, arg3, arg4, arg5);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPointLocator2D::FindDistributedPoints\n");



void
vtkPointLocator2D::FindPointsWithinRadius(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		float 	arg1
		float 	arg2
		float 	arg3
		vtkIdList *	arg4
		CODE:
		THIS->FindPointsWithinRadius(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPointLocator2D::FindPointsWithinRadius\n");



void
vtkPointLocator2D::FreeSearchStructure()
		CODE:
		THIS->FreeSearchStructure();
		XSRETURN_EMPTY;


void
vtkPointLocator2D::GenerateRepresentation(level, pd)
		int 	level
		vtkPolyData *	pd
		CODE:
		THIS->GenerateRepresentation(level, pd);
		XSRETURN_EMPTY;


const char *
vtkPointLocator2D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int  *
vtkPointLocator2D::GetDivisions()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDivisions();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


int
vtkPointLocator2D::GetNumberOfPointsPerBucket()
		CODE:
		RETVAL = THIS->GetNumberOfPointsPerBucket();
		OUTPUT:
		RETVAL


int
vtkPointLocator2D::GetNumberOfPointsPerBucketMaxValue()
		CODE:
		RETVAL = THIS->GetNumberOfPointsPerBucketMaxValue();
		OUTPUT:
		RETVAL


int
vtkPointLocator2D::GetNumberOfPointsPerBucketMinValue()
		CODE:
		RETVAL = THIS->GetNumberOfPointsPerBucketMinValue();
		OUTPUT:
		RETVAL


vtkPoints *
vtkPointLocator2D::GetPoints()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPoints";
		CODE:
		RETVAL = THIS->GetPoints();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkPointLocator2D::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;



static vtkPointLocator2D*
vtkPointLocator2D::New()
		CODE:
		RETVAL = vtkPointLocator2D::New();
		OUTPUT:
		RETVAL


void
vtkPointLocator2D::SetDivisions(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetDivisions(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPointLocator2D::SetDivisions\n");



void
vtkPointLocator2D::SetNumberOfPointsPerBucket(arg1)
		int 	arg1
		CODE:
		THIS->SetNumberOfPointsPerBucket(arg1);
		XSRETURN_EMPTY;


void
vtkPointLocator2D::SetPoints(arg1)
		vtkPoints *	arg1
		CODE:
		THIS->SetPoints(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::PointSet PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkPointSet::ComputeBounds()
		CODE:
		THIS->ComputeBounds();
		XSRETURN_EMPTY;


void
vtkPointSet::CopyStructure(pd)
		vtkDataSet *	pd
		CODE:
		THIS->CopyStructure(pd);
		XSRETURN_EMPTY;


void
vtkPointSet::DeepCopy(src)
		vtkDataObject *	src
		CODE:
		THIS->DeepCopy(src);
		XSRETURN_EMPTY;


long
vtkPointSet::FindPoint(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		RETVAL = THIS->FindPoint(arg1, arg2, arg3);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPointSet::FindPoint\n");



unsigned long
vtkPointSet::GetActualMemorySize()
		CODE:
		RETVAL = THIS->GetActualMemorySize();
		OUTPUT:
		RETVAL


const char *
vtkPointSet::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


unsigned long
vtkPointSet::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkPointSet::GetNetReferenceCount()
		CODE:
		RETVAL = THIS->GetNetReferenceCount();
		OUTPUT:
		RETVAL


long
vtkPointSet::GetNumberOfPoints()
		CODE:
		RETVAL = THIS->GetNumberOfPoints();
		OUTPUT:
		RETVAL


float *
vtkPointSet::GetPoint(arg1 = 0)
	CASE: items == 2
		long 	arg1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPoint(arg1);
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPointSet::GetPoint\n");



vtkPoints *
vtkPointSet::GetPoints()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPoints";
		CODE:
		RETVAL = THIS->GetPoints();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkPointSet::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


void
vtkPointSet::SetPoints(arg1)
		vtkPoints *	arg1
		CODE:
		THIS->SetPoints(arg1);
		XSRETURN_EMPTY;


void
vtkPointSet::ShallowCopy(src)
		vtkDataObject *	src
		CODE:
		THIS->ShallowCopy(src);
		XSRETURN_EMPTY;


void
vtkPointSet::Squeeze()
		CODE:
		THIS->Squeeze();
		XSRETURN_EMPTY;


void
vtkPointSet::UnRegister(o)
		vtkObject *	o
		CODE:
		THIS->UnRegister(o);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Points PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkPoints::Allocate(sz, ext)
		const long 	sz
		const long 	ext
		CODE:
		RETVAL = THIS->Allocate(sz, ext);
		OUTPUT:
		RETVAL


void
vtkPoints::ComputeBounds()
		CODE:
		THIS->ComputeBounds();
		XSRETURN_EMPTY;


void
vtkPoints::DeepCopy(ad)
		vtkPoints *	ad
		CODE:
		THIS->DeepCopy(ad);
		XSRETURN_EMPTY;


unsigned long
vtkPoints::GetActualMemorySize()
		CODE:
		RETVAL = THIS->GetActualMemorySize();
		OUTPUT:
		RETVAL


float *
vtkPoints::GetBounds()
	CASE: items == 1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetBounds();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPoints::GetBounds\n");



const char *
vtkPoints::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkDataArray *
vtkPoints::GetData()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataArray";
		CODE:
		RETVAL = THIS->GetData();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkPoints::GetDataType()
		CODE:
		RETVAL = THIS->GetDataType();
		OUTPUT:
		RETVAL


long
vtkPoints::GetNumberOfPoints()
		CODE:
		RETVAL = THIS->GetNumberOfPoints();
		OUTPUT:
		RETVAL


float *
vtkPoints::GetPoint(arg1 = 0)
	CASE: items == 2
		long 	arg1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPoint(arg1);
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPoints::GetPoint\n");



void
vtkPoints::GetPoints(ptId, fp)
		vtkIdList *	ptId
		vtkPoints *	fp
		CODE:
		THIS->GetPoints(ptId, fp);
		XSRETURN_EMPTY;


void
vtkPoints::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


long
vtkPoints::InsertNextPoint(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		double 	arg1
		double 	arg2
		double 	arg3
		CODE:
		RETVAL = THIS->InsertNextPoint(arg1, arg2, arg3);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPoints::InsertNextPoint\n");



void
vtkPoints::InsertPoint(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		long 	arg1
		double 	arg2
		double 	arg3
		double 	arg4
		CODE:
		THIS->InsertPoint(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPoints::InsertPoint\n");



static vtkPoints*
vtkPoints::New()
		CODE:
		RETVAL = vtkPoints::New();
		OUTPUT:
		RETVAL


void
vtkPoints::Reset()
		CODE:
		THIS->Reset();
		XSRETURN_EMPTY;


void
vtkPoints::SetData(arg1)
		vtkDataArray *	arg1
		CODE:
		THIS->SetData(arg1);
		XSRETURN_EMPTY;


void
vtkPoints::SetDataType(dataType)
		int 	dataType
		CODE:
		THIS->SetDataType(dataType);
		XSRETURN_EMPTY;


void
vtkPoints::SetDataTypeToBit()
		CODE:
		THIS->SetDataTypeToBit();
		XSRETURN_EMPTY;


void
vtkPoints::SetDataTypeToChar()
		CODE:
		THIS->SetDataTypeToChar();
		XSRETURN_EMPTY;


void
vtkPoints::SetDataTypeToDouble()
		CODE:
		THIS->SetDataTypeToDouble();
		XSRETURN_EMPTY;


void
vtkPoints::SetDataTypeToFloat()
		CODE:
		THIS->SetDataTypeToFloat();
		XSRETURN_EMPTY;


void
vtkPoints::SetDataTypeToInt()
		CODE:
		THIS->SetDataTypeToInt();
		XSRETURN_EMPTY;


void
vtkPoints::SetDataTypeToLong()
		CODE:
		THIS->SetDataTypeToLong();
		XSRETURN_EMPTY;


void
vtkPoints::SetDataTypeToShort()
		CODE:
		THIS->SetDataTypeToShort();
		XSRETURN_EMPTY;


void
vtkPoints::SetDataTypeToUnsignedChar()
		CODE:
		THIS->SetDataTypeToUnsignedChar();
		XSRETURN_EMPTY;


void
vtkPoints::SetDataTypeToUnsignedInt()
		CODE:
		THIS->SetDataTypeToUnsignedInt();
		XSRETURN_EMPTY;


void
vtkPoints::SetDataTypeToUnsignedLong()
		CODE:
		THIS->SetDataTypeToUnsignedLong();
		XSRETURN_EMPTY;


void
vtkPoints::SetDataTypeToUnsignedShort()
		CODE:
		THIS->SetDataTypeToUnsignedShort();
		XSRETURN_EMPTY;


void
vtkPoints::SetNumberOfPoints(number)
		long 	number
		CODE:
		THIS->SetNumberOfPoints(number);
		XSRETURN_EMPTY;


void
vtkPoints::SetPoint(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		long 	arg1
		double 	arg2
		double 	arg3
		double 	arg4
		CODE:
		THIS->SetPoint(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPoints::SetPoint\n");



void
vtkPoints::ShallowCopy(ad)
		vtkPoints *	ad
		CODE:
		THIS->ShallowCopy(ad);
		XSRETURN_EMPTY;


void
vtkPoints::Squeeze()
		CODE:
		THIS->Squeeze();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::PolyData PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkPolyData::AddCellReference(cellId)
		long 	cellId
		CODE:
		THIS->AddCellReference(cellId);
		XSRETURN_EMPTY;


void
vtkPolyData::AddReferenceToCell(ptId, cellId)
		long 	ptId
		long 	cellId
		CODE:
		THIS->AddReferenceToCell(ptId, cellId);
		XSRETURN_EMPTY;


void
vtkPolyData::Allocate(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		vtkPolyData *	arg1
		long 	arg2
		int 	arg3
		CODE:
		THIS->Allocate(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE: items == 3
		long 	arg1
		int 	arg2
		CODE:
		THIS->Allocate(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPolyData::Allocate\n");



void
vtkPolyData::BuildCells()
		CODE:
		THIS->BuildCells();
		XSRETURN_EMPTY;


void
vtkPolyData::BuildLinks()
		CODE:
		THIS->BuildLinks();
		XSRETURN_EMPTY;


void
vtkPolyData::ComputeBounds()
		CODE:
		THIS->ComputeBounds();
		XSRETURN_EMPTY;


void
vtkPolyData::CopyCells(pd, idList, locatorNULL)
		vtkPolyData *	pd
		vtkIdList *	idList
		vtkPointLocator *	locatorNULL
		CODE:
		THIS->CopyCells(pd, idList, locatorNULL);
		XSRETURN_EMPTY;


void
vtkPolyData::CopyStructure(ds)
		vtkDataSet *	ds
		CODE:
		THIS->CopyStructure(ds);
		XSRETURN_EMPTY;


void
vtkPolyData::DeepCopy(src)
		vtkDataObject *	src
		CODE:
		THIS->DeepCopy(src);
		XSRETURN_EMPTY;


void
vtkPolyData::DeleteCell(cellId)
		long 	cellId
		CODE:
		THIS->DeleteCell(cellId);
		XSRETURN_EMPTY;


void
vtkPolyData::DeleteCells()
		CODE:
		THIS->DeleteCells();
		XSRETURN_EMPTY;


void
vtkPolyData::DeleteLinks()
		CODE:
		THIS->DeleteLinks();
		XSRETURN_EMPTY;


void
vtkPolyData::DeletePoint(ptId)
		long 	ptId
		CODE:
		THIS->DeletePoint(ptId);
		XSRETURN_EMPTY;


unsigned long
vtkPolyData::GetActualMemorySize()
		CODE:
		RETVAL = THIS->GetActualMemorySize();
		OUTPUT:
		RETVAL


vtkCell *
vtkPolyData::GetCell(arg1 = 0, arg2 = 0)
	CASE: items == 3
		long 	arg1
		vtkGenericCell *	arg2
		CODE:
		THIS->GetCell(arg1, arg2);
		XSRETURN_EMPTY;
	CASE: items == 2
		long 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetCell(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPolyData::GetCell\n");



void
vtkPolyData::GetCellEdgeNeighbors(cellId, p1, p2, cellIds)
		long 	cellId
		long 	p1
		long 	p2
		vtkIdList *	cellIds
		CODE:
		THIS->GetCellEdgeNeighbors(cellId, p1, p2, cellIds);
		XSRETURN_EMPTY;


void
vtkPolyData::GetCellNeighbors(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		long 	arg1
		vtkIdList *	arg2
		vtkIdList *	arg3
		CODE:
		THIS->GetCellNeighbors(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPolyData::GetCellNeighbors\n");



void
vtkPolyData::GetCellPoints(arg1 = 0, arg2 = 0)
	CASE: items == 3
		long 	arg1
		vtkIdList *	arg2
		CODE:
		THIS->GetCellPoints(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPolyData::GetCellPoints\n");



int
vtkPolyData::GetCellType(cellId)
		long 	cellId
		CODE:
		RETVAL = THIS->GetCellType(cellId);
		OUTPUT:
		RETVAL


const char *
vtkPolyData::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkPolyData::GetDataObjectType()
		CODE:
		RETVAL = THIS->GetDataObjectType();
		OUTPUT:
		RETVAL


int
vtkPolyData::GetGhostLevel()
		CODE:
		RETVAL = THIS->GetGhostLevel();
		OUTPUT:
		RETVAL


vtkCellArray *
vtkPolyData::GetLines()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCellArray";
		CODE:
		RETVAL = THIS->GetLines();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkPolyData::GetMaxCellSize()
		CODE:
		RETVAL = THIS->GetMaxCellSize();
		OUTPUT:
		RETVAL


long
vtkPolyData::GetNumberOfCells()
		CODE:
		RETVAL = THIS->GetNumberOfCells();
		OUTPUT:
		RETVAL


long
vtkPolyData::GetNumberOfLines()
		CODE:
		RETVAL = THIS->GetNumberOfLines();
		OUTPUT:
		RETVAL


int
vtkPolyData::GetNumberOfPieces()
		CODE:
		RETVAL = THIS->GetNumberOfPieces();
		OUTPUT:
		RETVAL


long
vtkPolyData::GetNumberOfPolys()
		CODE:
		RETVAL = THIS->GetNumberOfPolys();
		OUTPUT:
		RETVAL


long
vtkPolyData::GetNumberOfStrips()
		CODE:
		RETVAL = THIS->GetNumberOfStrips();
		OUTPUT:
		RETVAL


long
vtkPolyData::GetNumberOfVerts()
		CODE:
		RETVAL = THIS->GetNumberOfVerts();
		OUTPUT:
		RETVAL


int
vtkPolyData::GetPiece()
		CODE:
		RETVAL = THIS->GetPiece();
		OUTPUT:
		RETVAL


void
vtkPolyData::GetPointCells(arg1 = 0, arg2 = 0)
	CASE: items == 3
		long 	arg1
		vtkIdList *	arg2
		CODE:
		THIS->GetPointCells(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPolyData::GetPointCells\n");



vtkCellArray *
vtkPolyData::GetPolys()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCellArray";
		CODE:
		RETVAL = THIS->GetPolys();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkCellArray *
vtkPolyData::GetStrips()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCellArray";
		CODE:
		RETVAL = THIS->GetStrips();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int  *
vtkPolyData::GetUpdateExtent(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->GetUpdateExtent(arg1, arg2, arg3);
		XSRETURN_EMPTY;
		OUTPUT:
		arg1
		arg2
		arg3
	CASE: items == 1
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetUpdateExtent();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPolyData::GetUpdateExtent\n");



vtkCellArray *
vtkPolyData::GetVerts()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCellArray";
		CODE:
		RETVAL = THIS->GetVerts();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkPolyData::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


int
vtkPolyData::InsertNextCell(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		vtkIdList *	arg2
		CODE:
		RETVAL = THIS->InsertNextCell(arg1, arg2);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPolyData::InsertNextCell\n");



int
vtkPolyData::IsEdge(v1, v2)
		int 	v1
		int 	v2
		CODE:
		RETVAL = THIS->IsEdge(v1, v2);
		OUTPUT:
		RETVAL


int
vtkPolyData::IsPointUsedByCell(ptId, cellId)
		long 	ptId
		long 	cellId
		CODE:
		RETVAL = THIS->IsPointUsedByCell(ptId, cellId);
		OUTPUT:
		RETVAL


int
vtkPolyData::IsTriangle(v1, v2, v3)
		int 	v1
		int 	v2
		int 	v3
		CODE:
		RETVAL = THIS->IsTriangle(v1, v2, v3);
		OUTPUT:
		RETVAL


static vtkPolyData*
vtkPolyData::New()
		CODE:
		RETVAL = vtkPolyData::New();
		OUTPUT:
		RETVAL


void
vtkPolyData::RemoveCellReference(cellId)
		long 	cellId
		CODE:
		THIS->RemoveCellReference(cellId);
		XSRETURN_EMPTY;


void
vtkPolyData::RemoveGhostCells(level)
		int 	level
		CODE:
		THIS->RemoveGhostCells(level);
		XSRETURN_EMPTY;


void
vtkPolyData::RemoveReferenceToCell(ptId, cellId)
		long 	ptId
		long 	cellId
		CODE:
		THIS->RemoveReferenceToCell(ptId, cellId);
		XSRETURN_EMPTY;


void
vtkPolyData::ReplaceCellPoint(cellId, oldPtId, newPtId)
		long 	cellId
		long 	oldPtId
		long 	newPtId
		CODE:
		THIS->ReplaceCellPoint(cellId, oldPtId, newPtId);
		XSRETURN_EMPTY;


void
vtkPolyData::Reset()
		CODE:
		THIS->Reset();
		XSRETURN_EMPTY;


void
vtkPolyData::ResizeCellList(ptId, size)
		long 	ptId
		int 	size
		CODE:
		THIS->ResizeCellList(ptId, size);
		XSRETURN_EMPTY;


void
vtkPolyData::ReverseCell(cellId)
		long 	cellId
		CODE:
		THIS->ReverseCell(cellId);
		XSRETURN_EMPTY;


void
vtkPolyData::SetLines(l)
		vtkCellArray *	l
		CODE:
		THIS->SetLines(l);
		XSRETURN_EMPTY;


void
vtkPolyData::SetPolys(p)
		vtkCellArray *	p
		CODE:
		THIS->SetPolys(p);
		XSRETURN_EMPTY;


void
vtkPolyData::SetStrips(s)
		vtkCellArray *	s
		CODE:
		THIS->SetStrips(s);
		XSRETURN_EMPTY;


void
vtkPolyData::SetUpdateExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetUpdateExtent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetUpdateExtent(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetUpdateExtent(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPolyData::SetUpdateExtent\n");



void
vtkPolyData::SetVerts(v)
		vtkCellArray *	v
		CODE:
		THIS->SetVerts(v);
		XSRETURN_EMPTY;


void
vtkPolyData::ShallowCopy(src)
		vtkDataObject *	src
		CODE:
		THIS->ShallowCopy(src);
		XSRETURN_EMPTY;


void
vtkPolyData::Squeeze()
		CODE:
		THIS->Squeeze();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::PolyLine PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkPolyLine::Clip(value, cellScalars, locator, lines, inPd, outPd, inCd, cellId, outCd, insideOut)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	lines
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		int 	insideOut
		CODE:
		THIS->Clip(value, cellScalars, locator, lines, inPd, outPd, inCd, cellId, outCd, insideOut);
		XSRETURN_EMPTY;


void
vtkPolyLine::Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	verts
		vtkCellArray *	lines
		vtkCellArray *	polys
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		CODE:
		THIS->Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd);
		XSRETURN_EMPTY;


int
vtkPolyLine::GenerateSlidingNormals(arg1, arg2, arg3)
		vtkPoints *	arg1
		vtkCellArray *	arg2
		vtkDataArray *	arg3
		CODE:
		RETVAL = THIS->GenerateSlidingNormals(arg1, arg2, arg3);
		OUTPUT:
		RETVAL


int
vtkPolyLine::GetCellDimension()
		CODE:
		RETVAL = THIS->GetCellDimension();
		OUTPUT:
		RETVAL


int
vtkPolyLine::GetCellType()
		CODE:
		RETVAL = THIS->GetCellType();
		OUTPUT:
		RETVAL


const char *
vtkPolyLine::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkCell *
vtkPolyLine::GetEdge(arg1)
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetEdge(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkCell *
vtkPolyLine::GetFace(arg1)
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetFace(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkPolyLine::GetNumberOfEdges()
		CODE:
		RETVAL = THIS->GetNumberOfEdges();
		OUTPUT:
		RETVAL


int
vtkPolyLine::GetNumberOfFaces()
		CODE:
		RETVAL = THIS->GetNumberOfFaces();
		OUTPUT:
		RETVAL



static vtkPolyLine*
vtkPolyLine::New()
		CODE:
		RETVAL = vtkPolyLine::New();
		OUTPUT:
		RETVAL


int
vtkPolyLine::Triangulate(index, ptIds, pts)
		int 	index
		vtkIdList *	ptIds
		vtkPoints *	pts
		CODE:
		RETVAL = THIS->Triangulate(index, ptIds, pts);
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::PolyVertex PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkPolyVertex::Clip(value, cellScalars, locator, verts, inPd, outPd, inCd, cellId, outCd, insideOut)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	verts
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		int 	insideOut
		CODE:
		THIS->Clip(value, cellScalars, locator, verts, inPd, outPd, inCd, cellId, outCd, insideOut);
		XSRETURN_EMPTY;


void
vtkPolyVertex::Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	verts
		vtkCellArray *	lines
		vtkCellArray *	polys
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		CODE:
		THIS->Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd);
		XSRETURN_EMPTY;


int
vtkPolyVertex::GetCellDimension()
		CODE:
		RETVAL = THIS->GetCellDimension();
		OUTPUT:
		RETVAL


int
vtkPolyVertex::GetCellType()
		CODE:
		RETVAL = THIS->GetCellType();
		OUTPUT:
		RETVAL


const char *
vtkPolyVertex::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkCell *
vtkPolyVertex::GetEdge(arg1)
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetEdge(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkCell *
vtkPolyVertex::GetFace(arg1)
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetFace(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkPolyVertex::GetNumberOfEdges()
		CODE:
		RETVAL = THIS->GetNumberOfEdges();
		OUTPUT:
		RETVAL


int
vtkPolyVertex::GetNumberOfFaces()
		CODE:
		RETVAL = THIS->GetNumberOfFaces();
		OUTPUT:
		RETVAL



static vtkPolyVertex*
vtkPolyVertex::New()
		CODE:
		RETVAL = vtkPolyVertex::New();
		OUTPUT:
		RETVAL


int
vtkPolyVertex::Triangulate(index, ptIds, pts)
		int 	index
		vtkIdList *	ptIds
		vtkPoints *	pts
		CODE:
		RETVAL = THIS->Triangulate(index, ptIds, pts);
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Polygon PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkPolygon::Clip(value, cellScalars, locator, tris, inPd, outPd, inCd, cellId, outCd, insideOut)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	tris
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		int 	insideOut
		CODE:
		THIS->Clip(value, cellScalars, locator, tris, inPd, outPd, inCd, cellId, outCd, insideOut);
		XSRETURN_EMPTY;


void
vtkPolygon::Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	verts
		vtkCellArray *	lines
		vtkCellArray *	polys
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		CODE:
		THIS->Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd);
		XSRETURN_EMPTY;


int
vtkPolygon::GetCellDimension()
		CODE:
		RETVAL = THIS->GetCellDimension();
		OUTPUT:
		RETVAL


int
vtkPolygon::GetCellType()
		CODE:
		RETVAL = THIS->GetCellType();
		OUTPUT:
		RETVAL


const char *
vtkPolygon::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkCell *
vtkPolygon::GetEdge(edgeId)
		int 	edgeId
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetEdge(edgeId);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkCell *
vtkPolygon::GetFace(arg1)
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetFace(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkPolygon::GetNumberOfEdges()
		CODE:
		RETVAL = THIS->GetNumberOfEdges();
		OUTPUT:
		RETVAL


int
vtkPolygon::GetNumberOfFaces()
		CODE:
		RETVAL = THIS->GetNumberOfFaces();
		OUTPUT:
		RETVAL


static vtkPolygon*
vtkPolygon::New()
		CODE:
		RETVAL = vtkPolygon::New();
		OUTPUT:
		RETVAL


int
vtkPolygon::Triangulate(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		vtkIdList *	arg2
		vtkPoints *	arg3
		CODE:
		RETVAL = THIS->Triangulate(arg1, arg2, arg3);
		OUTPUT:
		RETVAL
	CASE: items == 2
		vtkIdList *	arg1
		CODE:
		RETVAL = THIS->Triangulate(arg1);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPolygon::Triangulate\n");


MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::PriorityQueue PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkPriorityQueue::Allocate(sz, ext)
		const long 	sz
		const long 	ext
		CODE:
		THIS->Allocate(sz, ext);
		XSRETURN_EMPTY;


float
vtkPriorityQueue::DeleteId(id)
		long 	id
		CODE:
		RETVAL = THIS->DeleteId(id);
		OUTPUT:
		RETVAL


const char *
vtkPriorityQueue::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


long
vtkPriorityQueue::GetNumberOfItems()
		CODE:
		RETVAL = THIS->GetNumberOfItems();
		OUTPUT:
		RETVAL


float
vtkPriorityQueue::GetPriority(id)
		long 	id
		CODE:
		RETVAL = THIS->GetPriority(id);
		OUTPUT:
		RETVAL


void
vtkPriorityQueue::Insert(priority, id)
		float 	priority
		long 	id
		CODE:
		THIS->Insert(priority, id);
		XSRETURN_EMPTY;


static vtkPriorityQueue*
vtkPriorityQueue::New()
		CODE:
		RETVAL = vtkPriorityQueue::New();
		OUTPUT:
		RETVAL


void
vtkPriorityQueue::Reset()
		CODE:
		THIS->Reset();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::ProcessObject PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkProcessObject::AbortExecuteOff()
		CODE:
		THIS->AbortExecuteOff();
		XSRETURN_EMPTY;


void
vtkProcessObject::AbortExecuteOn()
		CODE:
		THIS->AbortExecuteOn();
		XSRETURN_EMPTY;


int
vtkProcessObject::GetAbortExecute()
		CODE:
		RETVAL = THIS->GetAbortExecute();
		OUTPUT:
		RETVAL


const char *
vtkProcessObject::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkProcessObject::GetNumberOfInputs()
		CODE:
		RETVAL = THIS->GetNumberOfInputs();
		OUTPUT:
		RETVAL


float
vtkProcessObject::GetProgress()
		CODE:
		RETVAL = THIS->GetProgress();
		OUTPUT:
		RETVAL


float
vtkProcessObject::GetProgressMaxValue()
		CODE:
		RETVAL = THIS->GetProgressMaxValue();
		OUTPUT:
		RETVAL


float
vtkProcessObject::GetProgressMinValue()
		CODE:
		RETVAL = THIS->GetProgressMinValue();
		OUTPUT:
		RETVAL


char *
vtkProcessObject::GetProgressText()
		CODE:
		RETVAL = THIS->GetProgressText();
		OUTPUT:
		RETVAL


static vtkProcessObject*
vtkProcessObject::New()
		CODE:
		RETVAL = vtkProcessObject::New();
		OUTPUT:
		RETVAL


void
vtkProcessObject::RemoveAllInputs()
		CODE:
		THIS->RemoveAllInputs();
		XSRETURN_EMPTY;


void
vtkProcessObject::SetAbortExecute(arg1)
		int 	arg1
		CODE:
		THIS->SetAbortExecute(arg1);
		XSRETURN_EMPTY;


void
vtkProcessObject::SetEndMethod(func)
		SV*	func
		CODE:
		HV * methodHash;
		HV * HashEntry;
		HE * tempHE;
		HV * tempHV;
      		/* put a copy of the callback in the executeMethodList hash */
		methodHash = perl_get_hv("Graphics::VTK::Object::executeMethodList", FALSE);
    		if (methodHash == (HV*)NULL)
    		    printf("Graphics::VTK::executeMethodList hash doesn't exist???\n");
    		else{
			tempHE = hv_fetch_ent(methodHash, ST(0), 0,0);
	    		if( tempHE == (HE*)NULL ) {  /* Entry doesn't exist (i.e. we didn't create it, make an entry for it */
		    		tempHV = newHV();  /* Create empty hash ref and put in executeMethodList */
				hv_store_ent(methodHash, ST(0), newRV_inc((SV*) tempHV), 0);
			}
		    HashEntry =   (HV *) SvRV(HeVAL(hv_fetch_ent(methodHash, ST(0), 0,0)));
		    hv_store_ent(HashEntry, newSVpv("SetEndMethod",0), newRV(func), 0);
		}
		THIS->SetEndMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkProcessObject::SetProgress(arg1)
		float 	arg1
		CODE:
		THIS->SetProgress(arg1);
		XSRETURN_EMPTY;


void
vtkProcessObject::SetProgressMethod(func)
		SV*	func
		CODE:
		HV * methodHash;
		HV * HashEntry;
		HE * tempHE;
		HV * tempHV;
      		/* put a copy of the callback in the executeMethodList hash */
		methodHash = perl_get_hv("Graphics::VTK::Object::executeMethodList", FALSE);
    		if (methodHash == (HV*)NULL)
    		    printf("Graphics::VTK::executeMethodList hash doesn't exist???\n");
    		else{
			tempHE = hv_fetch_ent(methodHash, ST(0), 0,0);
	    		if( tempHE == (HE*)NULL ) {  /* Entry doesn't exist (i.e. we didn't create it, make an entry for it */
		    		tempHV = newHV();  /* Create empty hash ref and put in executeMethodList */
				hv_store_ent(methodHash, ST(0), newRV_inc((SV*) tempHV), 0);
			}
		    HashEntry =   (HV *) SvRV(HeVAL(hv_fetch_ent(methodHash, ST(0), 0,0)));
		    hv_store_ent(HashEntry, newSVpv("SetProgressMethod",0), newRV(func), 0);
		}
		THIS->SetProgressMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkProcessObject::SetProgressText(arg1)
		char *	arg1
		CODE:
		THIS->SetProgressText(arg1);
		XSRETURN_EMPTY;


void
vtkProcessObject::SetStartMethod(func)
		SV*	func
		CODE:
		HV * methodHash;
		HV * HashEntry;
		HE * tempHE;
		HV * tempHV;
      		/* put a copy of the callback in the executeMethodList hash */
		methodHash = perl_get_hv("Graphics::VTK::Object::executeMethodList", FALSE);
    		if (methodHash == (HV*)NULL)
    		    printf("Graphics::VTK::executeMethodList hash doesn't exist???\n");
    		else{
			tempHE = hv_fetch_ent(methodHash, ST(0), 0,0);
	    		if( tempHE == (HE*)NULL ) {  /* Entry doesn't exist (i.e. we didn't create it, make an entry for it */
		    		tempHV = newHV();  /* Create empty hash ref and put in executeMethodList */
				hv_store_ent(methodHash, ST(0), newRV_inc((SV*) tempHV), 0);
			}
		    HashEntry =   (HV *) SvRV(HeVAL(hv_fetch_ent(methodHash, ST(0), 0,0)));
		    hv_store_ent(HashEntry, newSVpv("SetStartMethod",0), newRV(func), 0);
		}
		THIS->SetStartMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkProcessObject::SqueezeInputArray()
		CODE:
		THIS->SqueezeInputArray();
		XSRETURN_EMPTY;


void
vtkProcessObject::UpdateProgress(amount)
		float 	amount
		CODE:
		THIS->UpdateProgress(amount);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Prop PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkProp::DragableOff()
		CODE:
		THIS->DragableOff();
		XSRETURN_EMPTY;


void
vtkProp::DragableOn()
		CODE:
		THIS->DragableOn();
		XSRETURN_EMPTY;


void
vtkProp::GetActors(arg1)
		vtkPropCollection *	arg1
		CODE:
		THIS->GetActors(arg1);
		XSRETURN_EMPTY;


void
vtkProp::GetActors2D(arg1)
		vtkPropCollection *	arg1
		CODE:
		THIS->GetActors2D(arg1);
		XSRETURN_EMPTY;


const char *
vtkProp::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkProp::GetDragable()
		CODE:
		RETVAL = THIS->GetDragable();
		OUTPUT:
		RETVAL


vtkMatrix4x4 *
vtkProp::GetMatrix()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkMatrix4x4";
		CODE:
		RETVAL = THIS->GetMatrix();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkAssemblyPath *
vtkProp::GetNextPath()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAssemblyPath";
		CODE:
		RETVAL = THIS->GetNextPath();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkProp::GetNumberOfPaths()
		CODE:
		RETVAL = THIS->GetNumberOfPaths();
		OUTPUT:
		RETVAL


int
vtkProp::GetPickable()
		CODE:
		RETVAL = THIS->GetPickable();
		OUTPUT:
		RETVAL


unsigned long
vtkProp::GetRedrawMTime()
		CODE:
		RETVAL = THIS->GetRedrawMTime();
		OUTPUT:
		RETVAL


int
vtkProp::GetVisibility()
		CODE:
		RETVAL = THIS->GetVisibility();
		OUTPUT:
		RETVAL


void
vtkProp::GetVolumes(arg1)
		vtkPropCollection *	arg1
		CODE:
		THIS->GetVolumes(arg1);
		XSRETURN_EMPTY;


void
vtkProp::InitPathTraversal()
		CODE:
		THIS->InitPathTraversal();
		XSRETURN_EMPTY;


static vtkProp*
vtkProp::New()
		CODE:
		RETVAL = vtkProp::New();
		OUTPUT:
		RETVAL


void
vtkProp::Pick()
		CODE:
		THIS->Pick();
		XSRETURN_EMPTY;


void
vtkProp::PickableOff()
		CODE:
		THIS->PickableOff();
		XSRETURN_EMPTY;


void
vtkProp::PickableOn()
		CODE:
		THIS->PickableOn();
		XSRETURN_EMPTY;


void
vtkProp::PokeMatrix(arg1)
		vtkMatrix4x4 *	arg1
		CODE:
		THIS->PokeMatrix(arg1);
		XSRETURN_EMPTY;


void
vtkProp::SetDragable(arg1)
		int 	arg1
		CODE:
		THIS->SetDragable(arg1);
		XSRETURN_EMPTY;


void
vtkProp::SetPickMethod(func)
		SV*	func
		CODE:
		HV * methodHash;
		HV * HashEntry;
		HE * tempHE;
		HV * tempHV;
      		/* put a copy of the callback in the executeMethodList hash */
		methodHash = perl_get_hv("Graphics::VTK::Object::executeMethodList", FALSE);
    		if (methodHash == (HV*)NULL)
    		    printf("Graphics::VTK::executeMethodList hash doesn't exist???\n");
    		else{
			tempHE = hv_fetch_ent(methodHash, ST(0), 0,0);
	    		if( tempHE == (HE*)NULL ) {  /* Entry doesn't exist (i.e. we didn't create it, make an entry for it */
		    		tempHV = newHV();  /* Create empty hash ref and put in executeMethodList */
				hv_store_ent(methodHash, ST(0), newRV_inc((SV*) tempHV), 0);
			}
		    HashEntry =   (HV *) SvRV(HeVAL(hv_fetch_ent(methodHash, ST(0), 0,0)));
		    hv_store_ent(HashEntry, newSVpv("SetPickMethod",0), newRV(func), 0);
		}
		THIS->SetPickMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkProp::SetPickable(arg1)
		int 	arg1
		CODE:
		THIS->SetPickable(arg1);
		XSRETURN_EMPTY;


void
vtkProp::SetVisibility(arg1)
		int 	arg1
		CODE:
		THIS->SetVisibility(arg1);
		XSRETURN_EMPTY;


void
vtkProp::ShallowCopy(prop)
		vtkProp *	prop
		CODE:
		THIS->ShallowCopy(prop);
		XSRETURN_EMPTY;


void
vtkProp::VisibilityOff()
		CODE:
		THIS->VisibilityOff();
		XSRETURN_EMPTY;


void
vtkProp::VisibilityOn()
		CODE:
		THIS->VisibilityOn();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::PropAssembly PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkPropAssembly::AddPart(arg1)
		vtkProp *	arg1
		CODE:
		THIS->AddPart(arg1);
		XSRETURN_EMPTY;


float *
vtkPropAssembly::GetBounds()
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetBounds();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;


const char *
vtkPropAssembly::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


unsigned long
vtkPropAssembly::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


vtkAssemblyPath *
vtkPropAssembly::GetNextPath()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAssemblyPath";
		CODE:
		RETVAL = THIS->GetNextPath();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkPropAssembly::GetNumberOfPaths()
		CODE:
		RETVAL = THIS->GetNumberOfPaths();
		OUTPUT:
		RETVAL


vtkPropCollection *
vtkPropAssembly::GetParts()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPropCollection";
		CODE:
		RETVAL = THIS->GetParts();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkPropAssembly::InitPathTraversal()
		CODE:
		THIS->InitPathTraversal();
		XSRETURN_EMPTY;


static vtkPropAssembly*
vtkPropAssembly::New()
		CODE:
		RETVAL = vtkPropAssembly::New();
		OUTPUT:
		RETVAL


void
vtkPropAssembly::ReleaseGraphicsResources(arg1)
		vtkWindow *	arg1
		CODE:
		THIS->ReleaseGraphicsResources(arg1);
		XSRETURN_EMPTY;


void
vtkPropAssembly::RemovePart(arg1)
		vtkProp *	arg1
		CODE:
		THIS->RemovePart(arg1);
		XSRETURN_EMPTY;


int
vtkPropAssembly::RenderOpaqueGeometry(ren)
		vtkViewport *	ren
		CODE:
		RETVAL = THIS->RenderOpaqueGeometry(ren);
		OUTPUT:
		RETVAL


int
vtkPropAssembly::RenderOverlay(arg1)
		vtkViewport *	arg1
		CODE:
		RETVAL = THIS->RenderOverlay(arg1);
		OUTPUT:
		RETVAL


int
vtkPropAssembly::RenderTranslucentGeometry(ren)
		vtkViewport *	ren
		CODE:
		RETVAL = THIS->RenderTranslucentGeometry(ren);
		OUTPUT:
		RETVAL


void
vtkPropAssembly::ShallowCopy(Prop)
		vtkProp *	Prop
		CODE:
		THIS->ShallowCopy(Prop);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::PropCollection PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkPropCollection::AddItem(arg1 = 0)
	CASE: items == 2
		vtkProp *	arg1
		CODE:
		THIS->AddItem(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkPropCollection::AddItem\n");



const char *
vtkPropCollection::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkProp *
vtkPropCollection::GetLastProp()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkProp";
		CODE:
		RETVAL = THIS->GetLastProp();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkProp *
vtkPropCollection::GetNextProp()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkProp";
		CODE:
		RETVAL = THIS->GetNextProp();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkPropCollection::GetNumberOfPaths()
		CODE:
		RETVAL = THIS->GetNumberOfPaths();
		OUTPUT:
		RETVAL


static vtkPropCollection*
vtkPropCollection::New()
		CODE:
		RETVAL = vtkPropCollection::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Property2D PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkProperty2D::DeepCopy(p)
		vtkProperty2D *	p
		CODE:
		THIS->DeepCopy(p);
		XSRETURN_EMPTY;


const char *
vtkProperty2D::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkProperty2D::GetColor()
		PREINIT:
		float  * retval;
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
vtkProperty2D::GetDisplayLocation()
		CODE:
		RETVAL = THIS->GetDisplayLocation();
		OUTPUT:
		RETVAL


int
vtkProperty2D::GetDisplayLocationMaxValue()
		CODE:
		RETVAL = THIS->GetDisplayLocationMaxValue();
		OUTPUT:
		RETVAL


int
vtkProperty2D::GetDisplayLocationMinValue()
		CODE:
		RETVAL = THIS->GetDisplayLocationMinValue();
		OUTPUT:
		RETVAL


int
vtkProperty2D::GetLineStipplePattern()
		CODE:
		RETVAL = THIS->GetLineStipplePattern();
		OUTPUT:
		RETVAL


int
vtkProperty2D::GetLineStippleRepeatFactor()
		CODE:
		RETVAL = THIS->GetLineStippleRepeatFactor();
		OUTPUT:
		RETVAL


int
vtkProperty2D::GetLineStippleRepeatFactorMaxValue()
		CODE:
		RETVAL = THIS->GetLineStippleRepeatFactorMaxValue();
		OUTPUT:
		RETVAL


int
vtkProperty2D::GetLineStippleRepeatFactorMinValue()
		CODE:
		RETVAL = THIS->GetLineStippleRepeatFactorMinValue();
		OUTPUT:
		RETVAL


float
vtkProperty2D::GetLineWidth()
		CODE:
		RETVAL = THIS->GetLineWidth();
		OUTPUT:
		RETVAL


float
vtkProperty2D::GetLineWidthMaxValue()
		CODE:
		RETVAL = THIS->GetLineWidthMaxValue();
		OUTPUT:
		RETVAL


float
vtkProperty2D::GetLineWidthMinValue()
		CODE:
		RETVAL = THIS->GetLineWidthMinValue();
		OUTPUT:
		RETVAL


float
vtkProperty2D::GetOpacity()
		CODE:
		RETVAL = THIS->GetOpacity();
		OUTPUT:
		RETVAL


float
vtkProperty2D::GetPointSize()
		CODE:
		RETVAL = THIS->GetPointSize();
		OUTPUT:
		RETVAL


float
vtkProperty2D::GetPointSizeMaxValue()
		CODE:
		RETVAL = THIS->GetPointSizeMaxValue();
		OUTPUT:
		RETVAL


float
vtkProperty2D::GetPointSizeMinValue()
		CODE:
		RETVAL = THIS->GetPointSizeMinValue();
		OUTPUT:
		RETVAL


static vtkProperty2D*
vtkProperty2D::New()
		CODE:
		RETVAL = vtkProperty2D::New();
		OUTPUT:
		RETVAL


void
vtkProperty2D::Render(arg1)
		vtkViewport *	arg1
		CODE:
		THIS->Render(arg1);
		XSRETURN_EMPTY;


void
vtkProperty2D::SetColor(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetColor(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkProperty2D::SetColor\n");



void
vtkProperty2D::SetDisplayLocation(arg1)
		int 	arg1
		CODE:
		THIS->SetDisplayLocation(arg1);
		XSRETURN_EMPTY;


void
vtkProperty2D::SetDisplayLocationToBackground()
		CODE:
		THIS->SetDisplayLocationToBackground();
		XSRETURN_EMPTY;


void
vtkProperty2D::SetDisplayLocationToForeground()
		CODE:
		THIS->SetDisplayLocationToForeground();
		XSRETURN_EMPTY;


void
vtkProperty2D::SetLineStipplePattern(arg1)
		int 	arg1
		CODE:
		THIS->SetLineStipplePattern(arg1);
		XSRETURN_EMPTY;


void
vtkProperty2D::SetLineStippleRepeatFactor(arg1)
		int 	arg1
		CODE:
		THIS->SetLineStippleRepeatFactor(arg1);
		XSRETURN_EMPTY;


void
vtkProperty2D::SetLineWidth(arg1)
		float 	arg1
		CODE:
		THIS->SetLineWidth(arg1);
		XSRETURN_EMPTY;


void
vtkProperty2D::SetOpacity(arg1)
		float 	arg1
		CODE:
		THIS->SetOpacity(arg1);
		XSRETURN_EMPTY;


void
vtkProperty2D::SetPointSize(arg1)
		float 	arg1
		CODE:
		THIS->SetPointSize(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Pyramid PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkPyramid::Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	verts
		vtkCellArray *	lines
		vtkCellArray *	polys
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		CODE:
		THIS->Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd);
		XSRETURN_EMPTY;


int
vtkPyramid::GetCellDimension()
		CODE:
		RETVAL = THIS->GetCellDimension();
		OUTPUT:
		RETVAL


int
vtkPyramid::GetCellType()
		CODE:
		RETVAL = THIS->GetCellType();
		OUTPUT:
		RETVAL


const char *
vtkPyramid::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkCell *
vtkPyramid::GetEdge(edgeId)
		int 	edgeId
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetEdge(edgeId);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkCell *
vtkPyramid::GetFace(faceId)
		int 	faceId
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetFace(faceId);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkPyramid::GetNumberOfEdges()
		CODE:
		RETVAL = THIS->GetNumberOfEdges();
		OUTPUT:
		RETVAL


int
vtkPyramid::GetNumberOfFaces()
		CODE:
		RETVAL = THIS->GetNumberOfFaces();
		OUTPUT:
		RETVAL



static vtkPyramid*
vtkPyramid::New()
		CODE:
		RETVAL = vtkPyramid::New();
		OUTPUT:
		RETVAL


int
vtkPyramid::Triangulate(index, ptIds, pts)
		int 	index
		vtkIdList *	ptIds
		vtkPoints *	pts
		CODE:
		RETVAL = THIS->Triangulate(index, ptIds, pts);
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Quad PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkQuad::Clip(value, cellScalars, locator, polys, inPd, outPd, inCd, cellId, outCd, insideOut)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	polys
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		int 	insideOut
		CODE:
		THIS->Clip(value, cellScalars, locator, polys, inPd, outPd, inCd, cellId, outCd, insideOut);
		XSRETURN_EMPTY;


void
vtkQuad::Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	verts
		vtkCellArray *	lines
		vtkCellArray *	polys
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		CODE:
		THIS->Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd);
		XSRETURN_EMPTY;


int
vtkQuad::GetCellDimension()
		CODE:
		RETVAL = THIS->GetCellDimension();
		OUTPUT:
		RETVAL


int
vtkQuad::GetCellType()
		CODE:
		RETVAL = THIS->GetCellType();
		OUTPUT:
		RETVAL


const char *
vtkQuad::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkCell *
vtkQuad::GetEdge(edgeId)
		int 	edgeId
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetEdge(edgeId);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkCell *
vtkQuad::GetFace(arg1)
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetFace(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkQuad::GetNumberOfEdges()
		CODE:
		RETVAL = THIS->GetNumberOfEdges();
		OUTPUT:
		RETVAL


int
vtkQuad::GetNumberOfFaces()
		CODE:
		RETVAL = THIS->GetNumberOfFaces();
		OUTPUT:
		RETVAL


static vtkQuad*
vtkQuad::New()
		CODE:
		RETVAL = vtkQuad::New();
		OUTPUT:
		RETVAL


int
vtkQuad::Triangulate(index, ptIds, pts)
		int 	index
		vtkIdList *	ptIds
		vtkPoints *	pts
		CODE:
		RETVAL = THIS->Triangulate(index, ptIds, pts);
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Quadric PREFIX = vtk

PROTOTYPES: DISABLE



float
vtkQuadric::EvaluateFunction(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		RETVAL = THIS->EvaluateFunction(arg1, arg2, arg3);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkQuadric::EvaluateFunction\n");



const char *
vtkQuadric::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkQuadric::GetCoefficients()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetCoefficients();
		EXTEND(SP, 10);
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
		PUTBACK;
		return;


static vtkQuadric*
vtkQuadric::New()
		CODE:
		RETVAL = vtkQuadric::New();
		OUTPUT:
		RETVAL


void
vtkQuadric::SetCoefficients(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0, arg7 = 0, arg8 = 0, arg9 = 0, arg10 = 0)
	CASE: items == 11
		float 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		float 	arg5
		float 	arg6
		float 	arg7
		float 	arg8
		float 	arg9
		float 	arg10
		CODE:
		THIS->SetCoefficients(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkQuadric::SetCoefficients\n");


MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::RectilinearGrid PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkRectilinearGrid::ComputeBounds()
		CODE:
		THIS->ComputeBounds();
		XSRETURN_EMPTY;




void
vtkRectilinearGrid::CopyStructure(ds)
		vtkDataSet *	ds
		CODE:
		THIS->CopyStructure(ds);
		XSRETURN_EMPTY;


void
vtkRectilinearGrid::DeepCopy(src)
		vtkDataObject *	src
		CODE:
		THIS->DeepCopy(src);
		XSRETURN_EMPTY;


int
vtkRectilinearGrid::FindPoint(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		RETVAL = THIS->FindPoint(arg1, arg2, arg3);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkRectilinearGrid::FindPoint\n");



unsigned long
vtkRectilinearGrid::GetActualMemorySize()
		CODE:
		RETVAL = THIS->GetActualMemorySize();
		OUTPUT:
		RETVAL


vtkCell *
vtkRectilinearGrid::GetCell(arg1 = 0, arg2 = 0)
	CASE: items == 3
		long 	arg1
		vtkGenericCell *	arg2
		CODE:
		THIS->GetCell(arg1, arg2);
		XSRETURN_EMPTY;
	CASE: items == 2
		long 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetCell(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkRectilinearGrid::GetCell\n");



void
vtkRectilinearGrid::GetCellNeighbors(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		long 	arg1
		vtkIdList *	arg2
		vtkIdList *	arg3
		CODE:
		THIS->GetCellNeighbors(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkRectilinearGrid::GetCellNeighbors\n");



void
vtkRectilinearGrid::GetCellPoints(cellId, ptIds)
		long 	cellId
		vtkIdList *	ptIds
		CODE:
		THIS->GetCellPoints(cellId, ptIds);
		XSRETURN_EMPTY;


int
vtkRectilinearGrid::GetCellType(cellId)
		long 	cellId
		CODE:
		RETVAL = THIS->GetCellType(cellId);
		OUTPUT:
		RETVAL


const char *
vtkRectilinearGrid::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkRectilinearGrid::GetDataDimension()
		CODE:
		RETVAL = THIS->GetDataDimension();
		OUTPUT:
		RETVAL


int
vtkRectilinearGrid::GetDataObjectType()
		CODE:
		RETVAL = THIS->GetDataObjectType();
		OUTPUT:
		RETVAL


int  *
vtkRectilinearGrid::GetDimensions()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDimensions();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


int  *
vtkRectilinearGrid::GetExtent()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetExtent();
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
vtkRectilinearGrid::GetMaxCellSize()
		CODE:
		RETVAL = THIS->GetMaxCellSize();
		OUTPUT:
		RETVAL


long
vtkRectilinearGrid::GetNumberOfCells()
		CODE:
		RETVAL = THIS->GetNumberOfCells();
		OUTPUT:
		RETVAL


long
vtkRectilinearGrid::GetNumberOfPoints()
		CODE:
		RETVAL = THIS->GetNumberOfPoints();
		OUTPUT:
		RETVAL


float *
vtkRectilinearGrid::GetPoint(arg1 = 0)
	CASE: items == 2
		long 	arg1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPoint(arg1);
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkRectilinearGrid::GetPoint\n");



void
vtkRectilinearGrid::GetPointCells(ptId, cellIds)
		long 	ptId
		vtkIdList *	cellIds
		CODE:
		THIS->GetPointCells(ptId, cellIds);
		XSRETURN_EMPTY;


vtkDataArray *
vtkRectilinearGrid::GetXCoordinates()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataArray";
		CODE:
		RETVAL = THIS->GetXCoordinates();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkDataArray *
vtkRectilinearGrid::GetYCoordinates()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataArray";
		CODE:
		RETVAL = THIS->GetYCoordinates();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkDataArray *
vtkRectilinearGrid::GetZCoordinates()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkDataArray";
		CODE:
		RETVAL = THIS->GetZCoordinates();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkRectilinearGrid::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


static vtkRectilinearGrid*
vtkRectilinearGrid::New()
		CODE:
		RETVAL = vtkRectilinearGrid::New();
		OUTPUT:
		RETVAL


void
vtkRectilinearGrid::SetDimensions(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetDimensions(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkRectilinearGrid::SetDimensions\n");



void
vtkRectilinearGrid::SetExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetExtent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkRectilinearGrid::SetExtent\n");



void
vtkRectilinearGrid::SetUpdateExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetUpdateExtent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetUpdateExtent(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetUpdateExtent(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkRectilinearGrid::SetUpdateExtent\n");



void
vtkRectilinearGrid::SetXCoordinates(arg1)
		vtkDataArray *	arg1
		CODE:
		THIS->SetXCoordinates(arg1);
		XSRETURN_EMPTY;


void
vtkRectilinearGrid::SetYCoordinates(arg1)
		vtkDataArray *	arg1
		CODE:
		THIS->SetYCoordinates(arg1);
		XSRETURN_EMPTY;


void
vtkRectilinearGrid::SetZCoordinates(arg1)
		vtkDataArray *	arg1
		CODE:
		THIS->SetZCoordinates(arg1);
		XSRETURN_EMPTY;


void
vtkRectilinearGrid::ShallowCopy(src)
		vtkDataObject *	src
		CODE:
		THIS->ShallowCopy(src);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::ReferenceCount PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkReferenceCount::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkReferenceCount*
vtkReferenceCount::New()
		CODE:
		RETVAL = vtkReferenceCount::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::RungeKutta2 PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkRungeKutta2::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkRungeKutta2*
vtkRungeKutta2::New()
		CODE:
		RETVAL = vtkRungeKutta2::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::RungeKutta4 PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkRungeKutta4::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkRungeKutta4*
vtkRungeKutta4::New()
		CODE:
		RETVAL = vtkRungeKutta4::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::ScalarsToColors PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkScalarsToColors::Build()
		CODE:
		THIS->Build();
		XSRETURN_EMPTY;


vtkUnsignedCharArray *
vtkScalarsToColors::ConvertUnsignedCharToRGBA(colors, numComp, numTuples)
		vtkUnsignedCharArray *	colors
		int 	numComp
		int 	numTuples
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkUnsignedCharArray";
		CODE:
		RETVAL = THIS->ConvertUnsignedCharToRGBA(colors, numComp, numTuples);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float
vtkScalarsToColors::GetAlpha()
		CODE:
		RETVAL = THIS->GetAlpha();
		OUTPUT:
		RETVAL


const char *
vtkScalarsToColors::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float *
vtkScalarsToColors::GetColor(arg1 = 0)
	CASE: items == 2
		float 	arg1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetColor(arg1);
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkScalarsToColors::GetColor\n");



float
vtkScalarsToColors::GetLuminance(x)
		float 	x
		CODE:
		RETVAL = THIS->GetLuminance(x);
		OUTPUT:
		RETVAL


float
vtkScalarsToColors::GetOpacity(arg1)
		float 	arg1
		CODE:
		RETVAL = THIS->GetOpacity(arg1);
		OUTPUT:
		RETVAL


vtkUnsignedCharArray *
vtkScalarsToColors::MapScalars(scalars, colorMode, component)
		vtkDataArray *	scalars
		int 	colorMode
		int 	component
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkUnsignedCharArray";
		CODE:
		RETVAL = THIS->MapScalars(scalars, colorMode, component);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkScalarsToColors::SetAlpha(alpha)
		float 	alpha
		CODE:
		THIS->SetAlpha(alpha);
		XSRETURN_EMPTY;


void
vtkScalarsToColors::SetRange(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetRange(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkScalarsToColors::SetRange\n");


MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::ShortArray PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkShortArray::Allocate(sz, ext)
		const long 	sz
		const long 	ext
		CODE:
		RETVAL = THIS->Allocate(sz, ext);
		OUTPUT:
		RETVAL


void
vtkShortArray::DeepCopy(da)
		vtkDataArray *	da
		CODE:
		THIS->DeepCopy(da);
		XSRETURN_EMPTY;


const char *
vtkShortArray::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkShortArray::GetComponent(i, j)
		const long 	i
		const int 	j
		CODE:
		RETVAL = THIS->GetComponent(i, j);
		OUTPUT:
		RETVAL


int
vtkShortArray::GetDataType()
		CODE:
		RETVAL = THIS->GetDataType();
		OUTPUT:
		RETVAL


short
vtkShortArray::GetValue(id)
		const long 	id
		CODE:
		RETVAL = THIS->GetValue(id);
		OUTPUT:
		RETVAL


void
vtkShortArray::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


void
vtkShortArray::InsertComponent(i, j, c)
		const long 	i
		const int 	j
		const float 	c
		CODE:
		THIS->InsertComponent(i, j, c);
		XSRETURN_EMPTY;


long
vtkShortArray::InsertNextValue(arg1)
		const short 	arg1
		CODE:
		RETVAL = THIS->InsertNextValue(arg1);
		OUTPUT:
		RETVAL


void
vtkShortArray::InsertValue(id, i)
		const long 	id
		const short 	i
		CODE:
		THIS->InsertValue(id, i);
		XSRETURN_EMPTY;


static vtkShortArray*
vtkShortArray::New()
		CODE:
		RETVAL = vtkShortArray::New();
		OUTPUT:
		RETVAL


void
vtkShortArray::Resize(numTuples)
		long 	numTuples
		CODE:
		THIS->Resize(numTuples);
		XSRETURN_EMPTY;


void
vtkShortArray::SetComponent(i, j, c)
		const long 	i
		const int 	j
		const float 	c
		CODE:
		THIS->SetComponent(i, j, c);
		XSRETURN_EMPTY;


void
vtkShortArray::SetNumberOfTuples(number)
		const long 	number
		CODE:
		THIS->SetNumberOfTuples(number);
		XSRETURN_EMPTY;


void
vtkShortArray::SetNumberOfValues(number)
		const long 	number
		CODE:
		THIS->SetNumberOfValues(number);
		XSRETURN_EMPTY;


void
vtkShortArray::SetValue(id, value)
		const long 	id
		const short 	value
		CODE:
		THIS->SetValue(id, value);
		XSRETURN_EMPTY;


void
vtkShortArray::Squeeze()
		CODE:
		THIS->Squeeze();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Source PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkSource::ComputeInputUpdateExtents(output)
		vtkDataObject *	output
		CODE:
		THIS->ComputeInputUpdateExtents(output);
		XSRETURN_EMPTY;


void
vtkSource::EnlargeOutputUpdateExtents(output)
		vtkDataObject *	output
		CODE:
		THIS->EnlargeOutputUpdateExtents(output);
		XSRETURN_EMPTY;


const char *
vtkSource::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkSource::GetNumberOfOutputs()
		CODE:
		RETVAL = THIS->GetNumberOfOutputs();
		OUTPUT:
		RETVAL


int
vtkSource::GetOutputIndex(out)
		vtkDataObject *	out
		CODE:
		RETVAL = THIS->GetOutputIndex(out);
		OUTPUT:
		RETVAL


int
vtkSource::GetReleaseDataFlag()
		CODE:
		RETVAL = THIS->GetReleaseDataFlag();
		OUTPUT:
		RETVAL


int
vtkSource::InRegisterLoop(arg1)
		vtkObject *	arg1
		CODE:
		RETVAL = THIS->InRegisterLoop(arg1);
		OUTPUT:
		RETVAL


static vtkSource*
vtkSource::New()
		CODE:
		RETVAL = vtkSource::New();
		OUTPUT:
		RETVAL


void
vtkSource::PropagateUpdateExtent(output)
		vtkDataObject *	output
		CODE:
		THIS->PropagateUpdateExtent(output);
		XSRETURN_EMPTY;


void
vtkSource::ReleaseDataFlagOff()
		CODE:
		THIS->ReleaseDataFlagOff();
		XSRETURN_EMPTY;


void
vtkSource::ReleaseDataFlagOn()
		CODE:
		THIS->ReleaseDataFlagOn();
		XSRETURN_EMPTY;


void
vtkSource::SetReleaseDataFlag(arg1)
		int 	arg1
		CODE:
		THIS->SetReleaseDataFlag(arg1);
		XSRETURN_EMPTY;


void
vtkSource::TriggerAsynchronousUpdate()
		CODE:
		THIS->TriggerAsynchronousUpdate();
		XSRETURN_EMPTY;


void
vtkSource::UnRegister(o)
		vtkObject *	o
		CODE:
		THIS->UnRegister(o);
		XSRETURN_EMPTY;


void
vtkSource::UnRegisterAllOutputs()
		CODE:
		THIS->UnRegisterAllOutputs();
		XSRETURN_EMPTY;


void
vtkSource::Update()
		CODE:
		THIS->Update();
		XSRETURN_EMPTY;


void
vtkSource::UpdateData(output)
		vtkDataObject *	output
		CODE:
		THIS->UpdateData(output);
		XSRETURN_EMPTY;


void
vtkSource::UpdateInformation()
		CODE:
		THIS->UpdateInformation();
		XSRETURN_EMPTY;


void
vtkSource::UpdateWholeExtent()
		CODE:
		THIS->UpdateWholeExtent();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::StructuredData PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkStructuredData::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static int
vtkStructuredData::GetDataDimension(dataDescription)
		int 	dataDescription
		CODE:
		RETVAL = vtkStructuredData::GetDataDimension(dataDescription);
		OUTPUT:
		RETVAL


static vtkStructuredData*
vtkStructuredData::New()
		CODE:
		RETVAL = vtkStructuredData::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::StructuredGrid PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkStructuredGrid::BlankPoint(ptId)
		long 	ptId
		CODE:
		THIS->BlankPoint(ptId);
		XSRETURN_EMPTY;


void
vtkStructuredGrid::BlankingOff()
		CODE:
		THIS->BlankingOff();
		XSRETURN_EMPTY;


void
vtkStructuredGrid::BlankingOn()
		CODE:
		THIS->BlankingOn();
		XSRETURN_EMPTY;


void
vtkStructuredGrid::CopyStructure(ds)
		vtkDataSet *	ds
		CODE:
		THIS->CopyStructure(ds);
		XSRETURN_EMPTY;


void
vtkStructuredGrid::DeepCopy(src)
		vtkDataObject *	src
		CODE:
		THIS->DeepCopy(src);
		XSRETURN_EMPTY;


unsigned long
vtkStructuredGrid::GetActualMemorySize()
		CODE:
		RETVAL = THIS->GetActualMemorySize();
		OUTPUT:
		RETVAL


int
vtkStructuredGrid::GetBlanking()
		CODE:
		RETVAL = THIS->GetBlanking();
		OUTPUT:
		RETVAL


vtkCell *
vtkStructuredGrid::GetCell(arg1 = 0, arg2 = 0)
	CASE: items == 3
		long 	arg1
		vtkGenericCell *	arg2
		CODE:
		THIS->GetCell(arg1, arg2);
		XSRETURN_EMPTY;
	CASE: items == 2
		long 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetCell(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkStructuredGrid::GetCell\n");



void
vtkStructuredGrid::GetCellNeighbors(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		long 	arg1
		vtkIdList *	arg2
		vtkIdList *	arg3
		CODE:
		THIS->GetCellNeighbors(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkStructuredGrid::GetCellNeighbors\n");



void
vtkStructuredGrid::GetCellPoints(cellId, ptIds)
		long 	cellId
		vtkIdList *	ptIds
		CODE:
		THIS->GetCellPoints(cellId, ptIds);
		XSRETURN_EMPTY;


int
vtkStructuredGrid::GetCellType(cellId)
		long 	cellId
		CODE:
		RETVAL = THIS->GetCellType(cellId);
		OUTPUT:
		RETVAL


const char *
vtkStructuredGrid::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkStructuredGrid::GetDataDimension()
		CODE:
		RETVAL = THIS->GetDataDimension();
		OUTPUT:
		RETVAL


int
vtkStructuredGrid::GetDataObjectType()
		CODE:
		RETVAL = THIS->GetDataObjectType();
		OUTPUT:
		RETVAL


int *
vtkStructuredGrid::GetDimensions()
	CASE: items == 1
		PREINIT:
		int * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDimensions();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkStructuredGrid::GetDimensions\n");



int  *
vtkStructuredGrid::GetExtent()
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetExtent();
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
vtkStructuredGrid::GetMaxCellSize()
		CODE:
		RETVAL = THIS->GetMaxCellSize();
		OUTPUT:
		RETVAL


long
vtkStructuredGrid::GetNumberOfCells()
		CODE:
		RETVAL = THIS->GetNumberOfCells();
		OUTPUT:
		RETVAL


long
vtkStructuredGrid::GetNumberOfPoints()
		CODE:
		RETVAL = THIS->GetNumberOfPoints();
		OUTPUT:
		RETVAL


float *
vtkStructuredGrid::GetPoint(arg1 = 0)
	CASE: items == 2
		long 	arg1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPoint(arg1);
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkStructuredGrid::GetPoint\n");



void
vtkStructuredGrid::GetPointCells(ptId, cellIds)
		long 	ptId
		vtkIdList *	cellIds
		CODE:
		THIS->GetPointCells(ptId, cellIds);
		XSRETURN_EMPTY;


vtkUnsignedCharArray *
vtkStructuredGrid::GetPointVisibility()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkUnsignedCharArray";
		CODE:
		RETVAL = THIS->GetPointVisibility();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float *
vtkStructuredGrid::GetScalarRange()
	CASE: items == 1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetScalarRange();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkStructuredGrid::GetScalarRange\n");



void
vtkStructuredGrid::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


unsigned char
vtkStructuredGrid::IsCellVisible(cellId)
		long 	cellId
		CODE:
		RETVAL = THIS->IsCellVisible(cellId);
		OUTPUT:
		RETVAL


unsigned char
vtkStructuredGrid::IsPointVisible(ptId)
		long 	ptId
		CODE:
		RETVAL = THIS->IsPointVisible(ptId);
		OUTPUT:
		RETVAL


static vtkStructuredGrid*
vtkStructuredGrid::New()
		CODE:
		RETVAL = vtkStructuredGrid::New();
		OUTPUT:
		RETVAL


void
vtkStructuredGrid::SetBlanking(blanking)
		int 	blanking
		CODE:
		THIS->SetBlanking(blanking);
		XSRETURN_EMPTY;


void
vtkStructuredGrid::SetDimensions(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetDimensions(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkStructuredGrid::SetDimensions\n");



void
vtkStructuredGrid::SetExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetExtent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkStructuredGrid::SetExtent\n");



void
vtkStructuredGrid::SetPointVisibility(pointVisibility)
		vtkUnsignedCharArray *	pointVisibility
		CODE:
		THIS->SetPointVisibility(pointVisibility);
		XSRETURN_EMPTY;


void
vtkStructuredGrid::SetUpdateExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetUpdateExtent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetUpdateExtent(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetUpdateExtent(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkStructuredGrid::SetUpdateExtent\n");



void
vtkStructuredGrid::ShallowCopy(src)
		vtkDataObject *	src
		CODE:
		THIS->ShallowCopy(src);
		XSRETURN_EMPTY;


void
vtkStructuredGrid::UnBlankPoint(ptId)
		long 	ptId
		CODE:
		THIS->UnBlankPoint(ptId);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::StructuredPoints PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkStructuredPoints::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkStructuredPoints::GetDataObjectType()
		CODE:
		RETVAL = THIS->GetDataObjectType();
		OUTPUT:
		RETVAL


static vtkStructuredPoints*
vtkStructuredPoints::New()
		CODE:
		RETVAL = vtkStructuredPoints::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Tensor PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkTensor::AddComponent(i, j, v)
		int 	i
		int 	j
		float 	v
		CODE:
		THIS->AddComponent(i, j, v);
		XSRETURN_EMPTY;


void
vtkTensor::DeepCopy(t)
		vtkTensor *	t
		CODE:
		THIS->DeepCopy(t);
		XSRETURN_EMPTY;


const char *
vtkTensor::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float *
vtkTensor::GetColumn(j)
		int 	j
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetColumn(j);
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float
vtkTensor::GetComponent(i, j)
		int 	i
		int 	j
		CODE:
		RETVAL = THIS->GetComponent(i, j);
		OUTPUT:
		RETVAL


void
vtkTensor::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


static vtkTensor*
vtkTensor::New()
		CODE:
		RETVAL = vtkTensor::New();
		OUTPUT:
		RETVAL


void
vtkTensor::SetComponent(i, j, v)
		int 	i
		int 	j
		float 	v
		CODE:
		THIS->SetComponent(i, j, v);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Tetra PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkTetra::Clip(value, cellScalars, locator, connectivity, inPd, outPd, inCd, cellId, outCd, insideOut)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	connectivity
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		int 	insideOut
		CODE:
		THIS->Clip(value, cellScalars, locator, connectivity, inPd, outPd, inCd, cellId, outCd, insideOut);
		XSRETURN_EMPTY;


void
vtkTetra::Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	verts
		vtkCellArray *	lines
		vtkCellArray *	polys
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		CODE:
		THIS->Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd);
		XSRETURN_EMPTY;


int
vtkTetra::GetCellType()
		CODE:
		RETVAL = THIS->GetCellType();
		OUTPUT:
		RETVAL


const char *
vtkTetra::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkCell *
vtkTetra::GetEdge(edgeId)
		int 	edgeId
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetEdge(edgeId);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkCell *
vtkTetra::GetFace(faceId)
		int 	faceId
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetFace(faceId);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkTetra::GetNumberOfEdges()
		CODE:
		RETVAL = THIS->GetNumberOfEdges();
		OUTPUT:
		RETVAL


int
vtkTetra::GetNumberOfFaces()
		CODE:
		RETVAL = THIS->GetNumberOfFaces();
		OUTPUT:
		RETVAL




static vtkTetra*
vtkTetra::New()
		CODE:
		RETVAL = vtkTetra::New();
		OUTPUT:
		RETVAL


int
vtkTetra::Triangulate(index, ptIds, pts)
		int 	index
		vtkIdList *	ptIds
		vtkPoints *	pts
		CODE:
		RETVAL = THIS->Triangulate(index, ptIds, pts);
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::TimeStamp PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkTimeStamp::Delete()
		CODE:
		THIS->Delete();
		XSRETURN_EMPTY;


const char *
vtkTimeStamp::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


unsigned long
vtkTimeStamp::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


void
vtkTimeStamp::Modified()
		CODE:
		THIS->Modified();
		XSRETURN_EMPTY;


static vtkTimeStamp*
vtkTimeStamp::New()
		CODE:
		RETVAL = vtkTimeStamp::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::TimerLog PREFIX = vtk

PROTOTYPES: DISABLE



static void
vtkTimerLog::AllocateLog()
		CODE:
		vtkTimerLog::AllocateLog();
		XSRETURN_EMPTY;


static void
vtkTimerLog::DumpLog(filename)
		char *	filename
		CODE:
		vtkTimerLog::DumpLog(filename);
		XSRETURN_EMPTY;


static double
vtkTimerLog::GetCPUTime()
		CODE:
		RETVAL = vtkTimerLog::GetCPUTime();
		OUTPUT:
		RETVAL


const char *
vtkTimerLog::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static double
vtkTimerLog::GetCurrentTime()
		CODE:
		RETVAL = vtkTimerLog::GetCurrentTime();
		OUTPUT:
		RETVAL


double
vtkTimerLog::GetElapsedTime()
		CODE:
		RETVAL = THIS->GetElapsedTime();
		OUTPUT:
		RETVAL


static int
vtkTimerLog::GetMaxEntries()
		CODE:
		RETVAL = vtkTimerLog::GetMaxEntries();
		OUTPUT:
		RETVAL


static void
vtkTimerLog::MarkEvent(EventString)
		char *	EventString
		CODE:
		vtkTimerLog::MarkEvent(EventString);
		XSRETURN_EMPTY;


static vtkTimerLog*
vtkTimerLog::New()
		CODE:
		RETVAL = vtkTimerLog::New();
		OUTPUT:
		RETVAL


static void
vtkTimerLog::ResetLog()
		CODE:
		vtkTimerLog::ResetLog();
		XSRETURN_EMPTY;


static void
vtkTimerLog::SetMaxEntries(a)
		int 	a
		CODE:
		vtkTimerLog::SetMaxEntries(a);
		XSRETURN_EMPTY;


void
vtkTimerLog::StartTimer()
		CODE:
		THIS->StartTimer();
		XSRETURN_EMPTY;


void
vtkTimerLog::StopTimer()
		CODE:
		THIS->StopTimer();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Transform PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkTransform::CircuitCheck(transform)
		vtkAbstractTransform *	transform
		CODE:
		RETVAL = THIS->CircuitCheck(transform);
		OUTPUT:
		RETVAL


void
vtkTransform::Concatenate(arg1 = 0)
	CASE: items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1),"Graphics::VTK::Matrix4x4")
		vtkMatrix4x4 *	arg1
		CODE:
		THIS->Concatenate(arg1);
		XSRETURN_EMPTY;
	CASE: items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1),"Graphics::VTK::LinearTransform")
		vtkLinearTransform *	arg1
		CODE:
		THIS->Concatenate(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTransform::Concatenate\n");



const char *
vtkTransform::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkLinearTransform *
vtkTransform::GetConcatenatedTransform(i)
		int 	i
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkLinearTransform";
		CODE:
		RETVAL = THIS->GetConcatenatedTransform(i);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkLinearTransform *
vtkTransform::GetInput()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkLinearTransform";
		CODE:
		RETVAL = THIS->GetInput();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkAbstractTransform *
vtkTransform::GetInverse(arg1 = 0)
	CASE: items == 2
		vtkMatrix4x4 *	arg1
		CODE:
		THIS->GetInverse(arg1);
		XSRETURN_EMPTY;
	CASE: items == 1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAbstractTransform";
		CODE:
		RETVAL = THIS->GetInverse();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTransform::GetInverse\n");



int
vtkTransform::GetInverseFlag()
		CODE:
		RETVAL = THIS->GetInverseFlag();
		OUTPUT:
		RETVAL


unsigned long
vtkTransform::GetMTime()
		CODE:
		RETVAL = THIS->GetMTime();
		OUTPUT:
		RETVAL


int
vtkTransform::GetNumberOfConcatenatedTransforms()
		CODE:
		RETVAL = THIS->GetNumberOfConcatenatedTransforms();
		OUTPUT:
		RETVAL


float *
vtkTransform::GetOrientation()
	CASE: items == 1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOrientation();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTransform::GetOrientation\n");



float *
vtkTransform::GetOrientationWXYZ()
	CASE: items == 1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOrientationWXYZ();
		EXTEND(SP, 4);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTransform::GetOrientationWXYZ\n");



float *
vtkTransform::GetPosition()
	CASE: items == 1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPosition();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTransform::GetPosition\n");



float *
vtkTransform::GetScale()
	CASE: items == 1
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetScale();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTransform::GetScale\n");



void
vtkTransform::GetTranspose(transpose)
		vtkMatrix4x4 *	transpose
		CODE:
		THIS->GetTranspose(transpose);
		XSRETURN_EMPTY;


void
vtkTransform::Identity()
		CODE:
		THIS->Identity();
		XSRETURN_EMPTY;


void
vtkTransform::Inverse()
		CODE:
		THIS->Inverse();
		XSRETURN_EMPTY;


vtkAbstractTransform *
vtkTransform::MakeTransform()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAbstractTransform";
		CODE:
		RETVAL = THIS->MakeTransform();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkTransform*
vtkTransform::New()
		CODE:
		RETVAL = vtkTransform::New();
		OUTPUT:
		RETVAL


void
vtkTransform::Pop()
		CODE:
		THIS->Pop();
		XSRETURN_EMPTY;


void
vtkTransform::PostMultiply()
		CODE:
		THIS->PostMultiply();
		XSRETURN_EMPTY;


void
vtkTransform::PreMultiply()
		CODE:
		THIS->PreMultiply();
		XSRETURN_EMPTY;


void
vtkTransform::Push()
		CODE:
		THIS->Push();
		XSRETURN_EMPTY;


void
vtkTransform::RotateWXYZ(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		double 	arg1
		double 	arg2
		double 	arg3
		double 	arg4
		CODE:
		THIS->RotateWXYZ(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTransform::RotateWXYZ\n");



void
vtkTransform::RotateX(angle)
		double 	angle
		CODE:
		THIS->RotateX(angle);
		XSRETURN_EMPTY;


void
vtkTransform::RotateY(angle)
		double 	angle
		CODE:
		THIS->RotateY(angle);
		XSRETURN_EMPTY;


void
vtkTransform::RotateZ(angle)
		double 	angle
		CODE:
		THIS->RotateZ(angle);
		XSRETURN_EMPTY;


void
vtkTransform::Scale(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		double 	arg1
		double 	arg2
		double 	arg3
		CODE:
		THIS->Scale(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTransform::Scale\n");



void
vtkTransform::SetInput(input)
		vtkLinearTransform *	input
		CODE:
		THIS->SetInput(input);
		XSRETURN_EMPTY;


void
vtkTransform::SetMatrix(arg1 = 0)
	CASE: items == 2
		vtkMatrix4x4 *	arg1
		CODE:
		THIS->SetMatrix(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTransform::SetMatrix\n");



void
vtkTransform::Translate(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		double 	arg1
		double 	arg2
		double 	arg3
		CODE:
		THIS->Translate(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTransform::Translate\n");


MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::TransformCollection PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkTransformCollection::AddItem(arg1 = 0)
	CASE: items == 2
		vtkTransform *	arg1
		CODE:
		THIS->AddItem(arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkTransformCollection::AddItem\n");



const char *
vtkTransformCollection::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkTransform *
vtkTransformCollection::GetNextItem()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkTransform";
		CODE:
		RETVAL = THIS->GetNextItem();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


static vtkTransformCollection*
vtkTransformCollection::New()
		CODE:
		RETVAL = vtkTransformCollection::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Triangle PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkTriangle::Clip(value, cellScalars, locator, polys, inPd, outPd, inCd, cellId, outCd, insideOut)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	polys
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		int 	insideOut
		CODE:
		THIS->Clip(value, cellScalars, locator, polys, inPd, outPd, inCd, cellId, outCd, insideOut);
		XSRETURN_EMPTY;


void
vtkTriangle::Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	verts
		vtkCellArray *	lines
		vtkCellArray *	polys
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		CODE:
		THIS->Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd);
		XSRETURN_EMPTY;


int
vtkTriangle::GetCellDimension()
		CODE:
		RETVAL = THIS->GetCellDimension();
		OUTPUT:
		RETVAL


int
vtkTriangle::GetCellType()
		CODE:
		RETVAL = THIS->GetCellType();
		OUTPUT:
		RETVAL


const char *
vtkTriangle::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkCell *
vtkTriangle::GetEdge(edgeId)
		int 	edgeId
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetEdge(edgeId);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkCell *
vtkTriangle::GetFace(arg1)
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetFace(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkTriangle::GetNumberOfEdges()
		CODE:
		RETVAL = THIS->GetNumberOfEdges();
		OUTPUT:
		RETVAL


int
vtkTriangle::GetNumberOfFaces()
		CODE:
		RETVAL = THIS->GetNumberOfFaces();
		OUTPUT:
		RETVAL



static vtkTriangle*
vtkTriangle::New()
		CODE:
		RETVAL = vtkTriangle::New();
		OUTPUT:
		RETVAL


int
vtkTriangle::Triangulate(index, ptIds, pts)
		int 	index
		vtkIdList *	ptIds
		vtkPoints *	pts
		CODE:
		RETVAL = THIS->Triangulate(index, ptIds, pts);
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::TriangleStrip PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkTriangleStrip::Clip(value, cellScalars, locator, polys, inPd, outPd, inCd, cellId, outCd, insideOut)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	polys
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		int 	insideOut
		CODE:
		THIS->Clip(value, cellScalars, locator, polys, inPd, outPd, inCd, cellId, outCd, insideOut);
		XSRETURN_EMPTY;


void
vtkTriangleStrip::Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	verts
		vtkCellArray *	lines
		vtkCellArray *	polys
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		CODE:
		THIS->Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd);
		XSRETURN_EMPTY;


int
vtkTriangleStrip::GetCellDimension()
		CODE:
		RETVAL = THIS->GetCellDimension();
		OUTPUT:
		RETVAL


int
vtkTriangleStrip::GetCellType()
		CODE:
		RETVAL = THIS->GetCellType();
		OUTPUT:
		RETVAL


const char *
vtkTriangleStrip::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkCell *
vtkTriangleStrip::GetEdge(edgeId)
		int 	edgeId
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetEdge(edgeId);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkCell *
vtkTriangleStrip::GetFace(arg1)
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetFace(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkTriangleStrip::GetNumberOfEdges()
		CODE:
		RETVAL = THIS->GetNumberOfEdges();
		OUTPUT:
		RETVAL


int
vtkTriangleStrip::GetNumberOfFaces()
		CODE:
		RETVAL = THIS->GetNumberOfFaces();
		OUTPUT:
		RETVAL



static vtkTriangleStrip*
vtkTriangleStrip::New()
		CODE:
		RETVAL = vtkTriangleStrip::New();
		OUTPUT:
		RETVAL


int
vtkTriangleStrip::Triangulate(index, ptIds, pts)
		int 	index
		vtkIdList *	ptIds
		vtkPoints *	pts
		CODE:
		RETVAL = THIS->Triangulate(index, ptIds, pts);
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::UnsignedCharArray PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkUnsignedCharArray::Allocate(sz, ext)
		const long 	sz
		const long 	ext
		CODE:
		RETVAL = THIS->Allocate(sz, ext);
		OUTPUT:
		RETVAL


void
vtkUnsignedCharArray::DeepCopy(da)
		vtkDataArray *	da
		CODE:
		THIS->DeepCopy(da);
		XSRETURN_EMPTY;


const char *
vtkUnsignedCharArray::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkUnsignedCharArray::GetComponent(i, j)
		const long 	i
		const int 	j
		CODE:
		RETVAL = THIS->GetComponent(i, j);
		OUTPUT:
		RETVAL


int
vtkUnsignedCharArray::GetDataType()
		CODE:
		RETVAL = THIS->GetDataType();
		OUTPUT:
		RETVAL


unsigned char
vtkUnsignedCharArray::GetValue(id)
		const long 	id
		CODE:
		RETVAL = THIS->GetValue(id);
		OUTPUT:
		RETVAL


void
vtkUnsignedCharArray::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


void
vtkUnsignedCharArray::InsertComponent(i, j, c)
		const long 	i
		const int 	j
		const float 	c
		CODE:
		THIS->InsertComponent(i, j, c);
		XSRETURN_EMPTY;


long
vtkUnsignedCharArray::InsertNextValue(c)
		const unsigned char 	c
		CODE:
		RETVAL = THIS->InsertNextValue(c);
		OUTPUT:
		RETVAL


void
vtkUnsignedCharArray::InsertValue(id, c)
		const long 	id
		const unsigned char 	c
		CODE:
		THIS->InsertValue(id, c);
		XSRETURN_EMPTY;


static vtkUnsignedCharArray*
vtkUnsignedCharArray::New()
		CODE:
		RETVAL = vtkUnsignedCharArray::New();
		OUTPUT:
		RETVAL


void
vtkUnsignedCharArray::Resize(numTuples)
		long 	numTuples
		CODE:
		THIS->Resize(numTuples);
		XSRETURN_EMPTY;


void
vtkUnsignedCharArray::SetComponent(i, j, c)
		const long 	i
		const int 	j
		const float 	c
		CODE:
		THIS->SetComponent(i, j, c);
		XSRETURN_EMPTY;


void
vtkUnsignedCharArray::SetNumberOfTuples(number)
		const long 	number
		CODE:
		THIS->SetNumberOfTuples(number);
		XSRETURN_EMPTY;


void
vtkUnsignedCharArray::SetNumberOfValues(number)
		const long 	number
		CODE:
		THIS->SetNumberOfValues(number);
		XSRETURN_EMPTY;


void
vtkUnsignedCharArray::SetValue(id, value)
		const long 	id
		const unsigned char 	value
		CODE:
		THIS->SetValue(id, value);
		XSRETURN_EMPTY;


void
vtkUnsignedCharArray::Squeeze()
		CODE:
		THIS->Squeeze();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::UnsignedIntArray PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkUnsignedIntArray::Allocate(sz, ext)
		const long 	sz
		const long 	ext
		CODE:
		RETVAL = THIS->Allocate(sz, ext);
		OUTPUT:
		RETVAL


void
vtkUnsignedIntArray::DeepCopy(arg1 = 0)
	CASE: items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1),"Graphics::VTK::DataArray")
		vtkDataArray *	arg1
		CODE:
		THIS->DeepCopy(arg1);
		XSRETURN_EMPTY;
	CASE: items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1),"Graphics::VTK::DataArray")
		vtkDataArray *	arg1
		CODE:
		THIS->DeepCopy(* arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkUnsignedIntArray::DeepCopy\n");



const char *
vtkUnsignedIntArray::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkUnsignedIntArray::GetDataType()
		CODE:
		RETVAL = THIS->GetDataType();
		OUTPUT:
		RETVAL


unsigned int
vtkUnsignedIntArray::GetValue(id)
		const long 	id
		CODE:
		RETVAL = THIS->GetValue(id);
		OUTPUT:
		RETVAL


void
vtkUnsignedIntArray::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


void
vtkUnsignedIntArray::InsertComponent(i, j, c)
		const long 	i
		const int 	j
		const float 	c
		CODE:
		THIS->InsertComponent(i, j, c);
		XSRETURN_EMPTY;


long
vtkUnsignedIntArray::InsertNextValue(arg1)
		const unsigned int 	arg1
		CODE:
		RETVAL = THIS->InsertNextValue(arg1);
		OUTPUT:
		RETVAL


void
vtkUnsignedIntArray::InsertValue(id, i)
		const long 	id
		const unsigned int 	i
		CODE:
		THIS->InsertValue(id, i);
		XSRETURN_EMPTY;


static vtkUnsignedIntArray*
vtkUnsignedIntArray::New()
		CODE:
		RETVAL = vtkUnsignedIntArray::New();
		OUTPUT:
		RETVAL


void
vtkUnsignedIntArray::Resize(numTuples)
		long 	numTuples
		CODE:
		THIS->Resize(numTuples);
		XSRETURN_EMPTY;


void
vtkUnsignedIntArray::SetNumberOfTuples(number)
		const long 	number
		CODE:
		THIS->SetNumberOfTuples(number);
		XSRETURN_EMPTY;


void
vtkUnsignedIntArray::SetNumberOfValues(number)
		const long 	number
		CODE:
		THIS->SetNumberOfValues(number);
		XSRETURN_EMPTY;


void
vtkUnsignedIntArray::SetValue(id, value)
		const long 	id
		const unsigned int 	value
		CODE:
		THIS->SetValue(id, value);
		XSRETURN_EMPTY;


void
vtkUnsignedIntArray::Squeeze()
		CODE:
		THIS->Squeeze();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::UnsignedLongArray PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkUnsignedLongArray::Allocate(sz, ext)
		const long 	sz
		const long 	ext
		CODE:
		RETVAL = THIS->Allocate(sz, ext);
		OUTPUT:
		RETVAL


void
vtkUnsignedLongArray::DeepCopy(arg1 = 0)
	CASE: items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1),"Graphics::VTK::DataArray")
		vtkDataArray *	arg1
		CODE:
		THIS->DeepCopy(arg1);
		XSRETURN_EMPTY;
	CASE: items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1),"Graphics::VTK::DataArray")
		vtkDataArray *	arg1
		CODE:
		THIS->DeepCopy(* arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkUnsignedLongArray::DeepCopy\n");



const char *
vtkUnsignedLongArray::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkUnsignedLongArray::GetDataType()
		CODE:
		RETVAL = THIS->GetDataType();
		OUTPUT:
		RETVAL


unsigned long
vtkUnsignedLongArray::GetValue(id)
		const long 	id
		CODE:
		RETVAL = THIS->GetValue(id);
		OUTPUT:
		RETVAL


void
vtkUnsignedLongArray::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


void
vtkUnsignedLongArray::InsertComponent(i, j, c)
		const long 	i
		const int 	j
		const float 	c
		CODE:
		THIS->InsertComponent(i, j, c);
		XSRETURN_EMPTY;


long
vtkUnsignedLongArray::InsertNextValue(arg1)
		const unsigned long 	arg1
		CODE:
		RETVAL = THIS->InsertNextValue(arg1);
		OUTPUT:
		RETVAL


void
vtkUnsignedLongArray::InsertValue(id, i)
		const long 	id
		const unsigned long 	i
		CODE:
		THIS->InsertValue(id, i);
		XSRETURN_EMPTY;


static vtkUnsignedLongArray*
vtkUnsignedLongArray::New()
		CODE:
		RETVAL = vtkUnsignedLongArray::New();
		OUTPUT:
		RETVAL


void
vtkUnsignedLongArray::Resize(numTuples)
		long 	numTuples
		CODE:
		THIS->Resize(numTuples);
		XSRETURN_EMPTY;


void
vtkUnsignedLongArray::SetNumberOfTuples(number)
		const long 	number
		CODE:
		THIS->SetNumberOfTuples(number);
		XSRETURN_EMPTY;


void
vtkUnsignedLongArray::SetNumberOfValues(number)
		const long 	number
		CODE:
		THIS->SetNumberOfValues(number);
		XSRETURN_EMPTY;


void
vtkUnsignedLongArray::SetValue(id, value)
		const long 	id
		const unsigned long 	value
		CODE:
		THIS->SetValue(id, value);
		XSRETURN_EMPTY;


void
vtkUnsignedLongArray::Squeeze()
		CODE:
		THIS->Squeeze();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::UnsignedShortArray PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkUnsignedShortArray::Allocate(sz, ext)
		const long 	sz
		const long 	ext
		CODE:
		RETVAL = THIS->Allocate(sz, ext);
		OUTPUT:
		RETVAL


void
vtkUnsignedShortArray::DeepCopy(arg1 = 0)
	CASE: items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1),"Graphics::VTK::DataArray")
		vtkDataArray *	arg1
		CODE:
		THIS->DeepCopy(arg1);
		XSRETURN_EMPTY;
	CASE: items == 2 && sv_isobject(ST(1)) && sv_derived_from(ST(1),"Graphics::VTK::DataArray")
		vtkDataArray *	arg1
		CODE:
		THIS->DeepCopy(* arg1);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkUnsignedShortArray::DeepCopy\n");



const char *
vtkUnsignedShortArray::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float
vtkUnsignedShortArray::GetComponent(i, j)
		const long 	i
		const int 	j
		CODE:
		RETVAL = THIS->GetComponent(i, j);
		OUTPUT:
		RETVAL


int
vtkUnsignedShortArray::GetDataType()
		CODE:
		RETVAL = THIS->GetDataType();
		OUTPUT:
		RETVAL


unsigned short
vtkUnsignedShortArray::GetValue(id)
		const long 	id
		CODE:
		RETVAL = THIS->GetValue(id);
		OUTPUT:
		RETVAL


void
vtkUnsignedShortArray::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


void
vtkUnsignedShortArray::InsertComponent(i, j, c)
		const long 	i
		const int 	j
		const float 	c
		CODE:
		THIS->InsertComponent(i, j, c);
		XSRETURN_EMPTY;


long
vtkUnsignedShortArray::InsertNextValue(arg1)
		const unsigned short 	arg1
		CODE:
		RETVAL = THIS->InsertNextValue(arg1);
		OUTPUT:
		RETVAL


void
vtkUnsignedShortArray::InsertValue(id, i)
		const long 	id
		const unsigned short 	i
		CODE:
		THIS->InsertValue(id, i);
		XSRETURN_EMPTY;


static vtkUnsignedShortArray*
vtkUnsignedShortArray::New()
		CODE:
		RETVAL = vtkUnsignedShortArray::New();
		OUTPUT:
		RETVAL


void
vtkUnsignedShortArray::Resize(numTuples)
		long 	numTuples
		CODE:
		THIS->Resize(numTuples);
		XSRETURN_EMPTY;


void
vtkUnsignedShortArray::SetComponent(i, j, c)
		const long 	i
		const int 	j
		const float 	c
		CODE:
		THIS->SetComponent(i, j, c);
		XSRETURN_EMPTY;


void
vtkUnsignedShortArray::SetNumberOfTuples(number)
		const long 	number
		CODE:
		THIS->SetNumberOfTuples(number);
		XSRETURN_EMPTY;


void
vtkUnsignedShortArray::SetNumberOfValues(number)
		const long 	number
		CODE:
		THIS->SetNumberOfValues(number);
		XSRETURN_EMPTY;


void
vtkUnsignedShortArray::SetValue(id, value)
		const long 	id
		const unsigned short 	value
		CODE:
		THIS->SetValue(id, value);
		XSRETURN_EMPTY;


void
vtkUnsignedShortArray::Squeeze()
		CODE:
		THIS->Squeeze();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::UnstructuredGrid PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkUnstructuredGrid::AddReferenceToCell(ptId, cellId)
		long 	ptId
		long 	cellId
		CODE:
		THIS->AddReferenceToCell(ptId, cellId);
		XSRETURN_EMPTY;


void
vtkUnstructuredGrid::Allocate(numCells, extSize)
		long 	numCells
		int 	extSize
		CODE:
		THIS->Allocate(numCells, extSize);
		XSRETURN_EMPTY;


void
vtkUnstructuredGrid::BuildLinks()
		CODE:
		THIS->BuildLinks();
		XSRETURN_EMPTY;


void
vtkUnstructuredGrid::CopyStructure(ds)
		vtkDataSet *	ds
		CODE:
		THIS->CopyStructure(ds);
		XSRETURN_EMPTY;


void
vtkUnstructuredGrid::DeepCopy(src)
		vtkDataObject *	src
		CODE:
		THIS->DeepCopy(src);
		XSRETURN_EMPTY;


unsigned long
vtkUnstructuredGrid::GetActualMemorySize()
		CODE:
		RETVAL = THIS->GetActualMemorySize();
		OUTPUT:
		RETVAL


vtkCell *
vtkUnstructuredGrid::GetCell(arg1 = 0, arg2 = 0)
	CASE: items == 3
		long 	arg1
		vtkGenericCell *	arg2
		CODE:
		THIS->GetCell(arg1, arg2);
		XSRETURN_EMPTY;
	CASE: items == 2
		long 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetCell(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkUnstructuredGrid::GetCell\n");



vtkCellLinks *
vtkUnstructuredGrid::GetCellLinks()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCellLinks";
		CODE:
		RETVAL = THIS->GetCellLinks();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkUnstructuredGrid::GetCellNeighbors(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		long 	arg1
		vtkIdList *	arg2
		vtkIdList *	arg3
		CODE:
		THIS->GetCellNeighbors(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkUnstructuredGrid::GetCellNeighbors\n");



void
vtkUnstructuredGrid::GetCellPoints(arg1 = 0, arg2 = 0)
	CASE: items == 3
		long 	arg1
		vtkIdList *	arg2
		CODE:
		THIS->GetCellPoints(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkUnstructuredGrid::GetCellPoints\n");



int
vtkUnstructuredGrid::GetCellType(cellId)
		long 	cellId
		CODE:
		RETVAL = THIS->GetCellType(cellId);
		OUTPUT:
		RETVAL


vtkCellArray *
vtkUnstructuredGrid::GetCells()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCellArray";
		CODE:
		RETVAL = THIS->GetCells();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


const char *
vtkUnstructuredGrid::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkUnstructuredGrid::GetDataObjectType()
		CODE:
		RETVAL = THIS->GetDataObjectType();
		OUTPUT:
		RETVAL


int
vtkUnstructuredGrid::GetGhostLevel()
		CODE:
		RETVAL = THIS->GetGhostLevel();
		OUTPUT:
		RETVAL


void
vtkUnstructuredGrid::GetIdsOfCellsOfType(type, array)
		int 	type
		vtkIntArray *	array
		CODE:
		THIS->GetIdsOfCellsOfType(type, array);
		XSRETURN_EMPTY;


void
vtkUnstructuredGrid::GetListOfUniqueCellTypes(uniqueTypes)
		vtkUnsignedCharArray *	uniqueTypes
		CODE:
		THIS->GetListOfUniqueCellTypes(uniqueTypes);
		XSRETURN_EMPTY;


int
vtkUnstructuredGrid::GetMaxCellSize()
		CODE:
		RETVAL = THIS->GetMaxCellSize();
		OUTPUT:
		RETVAL


long
vtkUnstructuredGrid::GetNumberOfCells()
		CODE:
		RETVAL = THIS->GetNumberOfCells();
		OUTPUT:
		RETVAL


int
vtkUnstructuredGrid::GetNumberOfPieces()
		CODE:
		RETVAL = THIS->GetNumberOfPieces();
		OUTPUT:
		RETVAL


int
vtkUnstructuredGrid::GetPiece()
		CODE:
		RETVAL = THIS->GetPiece();
		OUTPUT:
		RETVAL


void
vtkUnstructuredGrid::GetPointCells(ptId, cellIds)
		long 	ptId
		vtkIdList *	cellIds
		CODE:
		THIS->GetPointCells(ptId, cellIds);
		XSRETURN_EMPTY;


int  *
vtkUnstructuredGrid::GetUpdateExtent(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->GetUpdateExtent(arg1, arg2, arg3);
		XSRETURN_EMPTY;
		OUTPUT:
		arg1
		arg2
		arg3
	CASE: items == 1
		PREINIT:
		int  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetUpdateExtent();
		EXTEND(SP, 6);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUSHs(sv_2mortal(newSVnv(retval[4])));
		PUSHs(sv_2mortal(newSVnv(retval[5])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkUnstructuredGrid::GetUpdateExtent\n");



void
vtkUnstructuredGrid::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


int
vtkUnstructuredGrid::InsertNextCell(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		vtkIdList *	arg2
		CODE:
		RETVAL = THIS->InsertNextCell(arg1, arg2);
		OUTPUT:
		RETVAL
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkUnstructuredGrid::InsertNextCell\n");



int
vtkUnstructuredGrid::IsHomogeneous()
		CODE:
		RETVAL = THIS->IsHomogeneous();
		OUTPUT:
		RETVAL


static vtkUnstructuredGrid*
vtkUnstructuredGrid::New()
		CODE:
		RETVAL = vtkUnstructuredGrid::New();
		OUTPUT:
		RETVAL


void
vtkUnstructuredGrid::RemoveReferenceToCell(ptId, cellId)
		long 	ptId
		long 	cellId
		CODE:
		THIS->RemoveReferenceToCell(ptId, cellId);
		XSRETURN_EMPTY;


void
vtkUnstructuredGrid::Reset()
		CODE:
		THIS->Reset();
		XSRETURN_EMPTY;


void
vtkUnstructuredGrid::ResizeCellList(ptId, size)
		long 	ptId
		int 	size
		CODE:
		THIS->ResizeCellList(ptId, size);
		XSRETURN_EMPTY;


void
vtkUnstructuredGrid::SetCells(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		vtkUnsignedCharArray *	arg1
		vtkIntArray *	arg2
		vtkCellArray *	arg3
		CODE:
		THIS->SetCells(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkUnstructuredGrid::SetCells\n");



void
vtkUnstructuredGrid::SetUpdateExtent(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0, arg5 = 0, arg6 = 0)
	CASE: items == 7
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		int 	arg5
		int 	arg6
		CODE:
		THIS->SetUpdateExtent(arg1, arg2, arg3, arg4, arg5, arg6);
		XSRETURN_EMPTY;
	CASE: items == 4
		int 	arg1
		int 	arg2
		int 	arg3
		CODE:
		THIS->SetUpdateExtent(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetUpdateExtent(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkUnstructuredGrid::SetUpdateExtent\n");



void
vtkUnstructuredGrid::ShallowCopy(src)
		vtkDataObject *	src
		CODE:
		THIS->ShallowCopy(src);
		XSRETURN_EMPTY;


void
vtkUnstructuredGrid::Squeeze()
		CODE:
		THIS->Squeeze();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Version PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkVersion::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static int
vtkVersion::GetVTKBuildVersion()
		CODE:
		RETVAL = vtkVersion::GetVTKBuildVersion();
		OUTPUT:
		RETVAL


static int
vtkVersion::GetVTKMajorVersion()
		CODE:
		RETVAL = vtkVersion::GetVTKMajorVersion();
		OUTPUT:
		RETVAL


static int
vtkVersion::GetVTKMinorVersion()
		CODE:
		RETVAL = vtkVersion::GetVTKMinorVersion();
		OUTPUT:
		RETVAL


static const char *
vtkVersion::GetVTKSourceVersion()
		CODE:
		RETVAL = vtkVersion::GetVTKSourceVersion();
		OUTPUT:
		RETVAL


static const char *
vtkVersion::GetVTKVersion()
		CODE:
		RETVAL = vtkVersion::GetVTKVersion();
		OUTPUT:
		RETVAL


static vtkVersion*
vtkVersion::New()
		CODE:
		RETVAL = vtkVersion::New();
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Vertex PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkVertex::Clip(value, cellScalars, locator, pts, inPd, outPd, inCd, cellId, outCd, insideOut)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	pts
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		int 	insideOut
		CODE:
		THIS->Clip(value, cellScalars, locator, pts, inPd, outPd, inCd, cellId, outCd, insideOut);
		XSRETURN_EMPTY;


void
vtkVertex::Contour(value, cellScalars, locator, verts1, lines, verts2, inPd, outPd, inCd, cellId, outCd)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	verts1
		vtkCellArray *	lines
		vtkCellArray *	verts2
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		CODE:
		THIS->Contour(value, cellScalars, locator, verts1, lines, verts2, inPd, outPd, inCd, cellId, outCd);
		XSRETURN_EMPTY;


int
vtkVertex::GetCellDimension()
		CODE:
		RETVAL = THIS->GetCellDimension();
		OUTPUT:
		RETVAL


int
vtkVertex::GetCellType()
		CODE:
		RETVAL = THIS->GetCellType();
		OUTPUT:
		RETVAL


const char *
vtkVertex::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkCell *
vtkVertex::GetEdge(arg1)
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetEdge(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkCell *
vtkVertex::GetFace(arg1)
		int 	arg1
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetFace(arg1);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkVertex::GetNumberOfEdges()
		CODE:
		RETVAL = THIS->GetNumberOfEdges();
		OUTPUT:
		RETVAL


int
vtkVertex::GetNumberOfFaces()
		CODE:
		RETVAL = THIS->GetNumberOfFaces();
		OUTPUT:
		RETVAL


static vtkVertex*
vtkVertex::New()
		CODE:
		RETVAL = vtkVertex::New();
		OUTPUT:
		RETVAL


int
vtkVertex::Triangulate(index, ptIds, pts)
		int 	index
		vtkIdList *	ptIds
		vtkPoints *	pts
		CODE:
		RETVAL = THIS->Triangulate(index, ptIds, pts);
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Viewport PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkViewport::AddActor2D(p)
		vtkProp *	p
		CODE:
		THIS->AddActor2D(p);
		XSRETURN_EMPTY;


void
vtkViewport::AddProp(arg1)
		vtkProp *	arg1
		CODE:
		THIS->AddProp(arg1);
		XSRETURN_EMPTY;


void
vtkViewport::ComputeAspect()
		CODE:
		THIS->ComputeAspect();
		XSRETURN_EMPTY;


void
vtkViewport::DisplayToLocalDisplay(x, y)
		float 	x
		float 	y
		CODE:
		THIS->DisplayToLocalDisplay(x, y);
		XSRETURN_EMPTY;
		OUTPUT:
		x
		y


void
vtkViewport::DisplayToNormalizedDisplay(u, v)
		float 	u
		float 	v
		CODE:
		THIS->DisplayToNormalizedDisplay(u, v);
		XSRETURN_EMPTY;
		OUTPUT:
		u
		v


void
vtkViewport::DisplayToView()
		CODE:
		THIS->DisplayToView();
		XSRETURN_EMPTY;


void
vtkViewport::DisplayToWorld()
		CODE:
		THIS->DisplayToWorld();
		XSRETURN_EMPTY;


vtkActor2DCollection *
vtkViewport::GetActors2D()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkActor2DCollection";
		CODE:
		RETVAL = THIS->GetActors2D();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float  *
vtkViewport::GetAspect()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetAspect();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


float  *
vtkViewport::GetBackground()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetBackground();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float *
vtkViewport::GetCenter()
		PREINIT:
		float * retval;
		CODE:
		SP -= items;
		retval = THIS->GetCenter();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


const char *
vtkViewport::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


float  *
vtkViewport::GetDisplayPoint()
	CASE: items == 1
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetDisplayPoint();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkViewport::GetDisplayPoint\n");



int
vtkViewport::GetIsPicking()
		CODE:
		RETVAL = THIS->GetIsPicking();
		OUTPUT:
		RETVAL


int *
vtkViewport::GetOrigin()
		PREINIT:
		int * retval;
		CODE:
		SP -= items;
		retval = THIS->GetOrigin();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


float
vtkViewport::GetPickX()
		CODE:
		RETVAL = THIS->GetPickX();
		OUTPUT:
		RETVAL


float
vtkViewport::GetPickY()
		CODE:
		RETVAL = THIS->GetPickY();
		OUTPUT:
		RETVAL


float
vtkViewport::GetPickedZ()
		CODE:
		RETVAL = THIS->GetPickedZ();
		OUTPUT:
		RETVAL


float  *
vtkViewport::GetPixelAspect()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPixelAspect();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


vtkPropCollection *
vtkViewport::GetProps()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkPropCollection";
		CODE:
		RETVAL = THIS->GetProps();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int *
vtkViewport::GetSize()
		PREINIT:
		int * retval;
		CODE:
		SP -= items;
		retval = THIS->GetSize();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


vtkWindow *
vtkViewport::GetVTKWindow()
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkWindow";
		CODE:
		RETVAL = THIS->GetVTKWindow();
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


float  *
vtkViewport::GetViewPoint()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetViewPoint();
		EXTEND(SP, 3);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUTBACK;
		return;


float  *
vtkViewport::GetViewport()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetViewport();
		EXTEND(SP, 4);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUTBACK;
		return;


float  *
vtkViewport::GetWorldPoint()
	CASE: items == 1
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetWorldPoint();
		EXTEND(SP, 4);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUTBACK;
		return;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkViewport::GetWorldPoint\n");



int
vtkViewport::IsInViewport(x, y)
		int 	x
		int 	y
		CODE:
		RETVAL = THIS->IsInViewport(x, y);
		OUTPUT:
		RETVAL


void
vtkViewport::LocalDisplayToDisplay(x, y)
		float 	x
		float 	y
		CODE:
		THIS->LocalDisplayToDisplay(x, y);
		XSRETURN_EMPTY;
		OUTPUT:
		x
		y


void
vtkViewport::NormalizedDisplayToDisplay(u, v)
		float 	u
		float 	v
		CODE:
		THIS->NormalizedDisplayToDisplay(u, v);
		XSRETURN_EMPTY;
		OUTPUT:
		u
		v


void
vtkViewport::NormalizedDisplayToViewport(x, y)
		float 	x
		float 	y
		CODE:
		THIS->NormalizedDisplayToViewport(x, y);
		XSRETURN_EMPTY;
		OUTPUT:
		x
		y


void
vtkViewport::NormalizedViewportToView(x, y, z)
		float 	x
		float 	y
		float 	z
		CODE:
		THIS->NormalizedViewportToView(x, y, z);
		XSRETURN_EMPTY;
		OUTPUT:
		x
		y
		z


void
vtkViewport::NormalizedViewportToViewport(u, v)
		float 	u
		float 	v
		CODE:
		THIS->NormalizedViewportToViewport(u, v);
		XSRETURN_EMPTY;
		OUTPUT:
		u
		v


vtkAssemblyPath *
vtkViewport::PickProp(selectionX, selectionY)
		float 	selectionX
		float 	selectionY
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAssemblyPath";
		CODE:
		RETVAL = THIS->PickProp(selectionX, selectionY);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkAssemblyPath *
vtkViewport::PickPropFrom(selectionX, selectionY, arg3)
		float 	selectionX
		float 	selectionY
		vtkPropCollection *	arg3
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkAssemblyPath";
		CODE:
		RETVAL = THIS->PickPropFrom(selectionX, selectionY, arg3);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


void
vtkViewport::RemoveActor2D(p)
		vtkProp *	p
		CODE:
		THIS->RemoveActor2D(p);
		XSRETURN_EMPTY;


void
vtkViewport::RemoveProp(arg1)
		vtkProp *	arg1
		CODE:
		THIS->RemoveProp(arg1);
		XSRETURN_EMPTY;


void
vtkViewport::SetAspect(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetAspect(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkViewport::SetAspect\n");



void
vtkViewport::SetBackground(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetBackground(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkViewport::SetBackground\n");



void
vtkViewport::SetDisplayPoint(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetDisplayPoint(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkViewport::SetDisplayPoint\n");



void
vtkViewport::SetEndRenderMethod(func)
		SV*	func
		CODE:
		HV * methodHash;
		HV * HashEntry;
		HE * tempHE;
		HV * tempHV;
      		/* put a copy of the callback in the executeMethodList hash */
		methodHash = perl_get_hv("Graphics::VTK::Object::executeMethodList", FALSE);
    		if (methodHash == (HV*)NULL)
    		    printf("Graphics::VTK::executeMethodList hash doesn't exist???\n");
    		else{
			tempHE = hv_fetch_ent(methodHash, ST(0), 0,0);
	    		if( tempHE == (HE*)NULL ) {  /* Entry doesn't exist (i.e. we didn't create it, make an entry for it */
		    		tempHV = newHV();  /* Create empty hash ref and put in executeMethodList */
				hv_store_ent(methodHash, ST(0), newRV_inc((SV*) tempHV), 0);
			}
		    HashEntry =   (HV *) SvRV(HeVAL(hv_fetch_ent(methodHash, ST(0), 0,0)));
		    hv_store_ent(HashEntry, newSVpv("SetEndRenderMethod",0), newRV(func), 0);
		}
		THIS->SetEndRenderMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkViewport::SetPixelAspect(arg1 = 0, arg2 = 0)
	CASE: items == 3
		float 	arg1
		float 	arg2
		CODE:
		THIS->SetPixelAspect(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkViewport::SetPixelAspect\n");



void
vtkViewport::SetStartRenderMethod(func)
		SV*	func
		CODE:
		HV * methodHash;
		HV * HashEntry;
		HE * tempHE;
		HV * tempHV;
      		/* put a copy of the callback in the executeMethodList hash */
		methodHash = perl_get_hv("Graphics::VTK::Object::executeMethodList", FALSE);
    		if (methodHash == (HV*)NULL)
    		    printf("Graphics::VTK::executeMethodList hash doesn't exist???\n");
    		else{
			tempHE = hv_fetch_ent(methodHash, ST(0), 0,0);
	    		if( tempHE == (HE*)NULL ) {  /* Entry doesn't exist (i.e. we didn't create it, make an entry for it */
		    		tempHV = newHV();  /* Create empty hash ref and put in executeMethodList */
				hv_store_ent(methodHash, ST(0), newRV_inc((SV*) tempHV), 0);
			}
		    HashEntry =   (HV *) SvRV(HeVAL(hv_fetch_ent(methodHash, ST(0), 0,0)));
		    hv_store_ent(HashEntry, newSVpv("SetStartRenderMethod",0), newRV(func), 0);
		}
		THIS->SetStartRenderMethod(callperlsub, func);
		XSRETURN_EMPTY;


void
vtkViewport::SetViewPoint(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->SetViewPoint(arg1, arg2, arg3);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkViewport::SetViewPoint\n");



void
vtkViewport::SetViewport(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		float 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		CODE:
		THIS->SetViewport(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkViewport::SetViewport\n");



void
vtkViewport::SetWorldPoint(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		float 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		CODE:
		THIS->SetWorldPoint(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkViewport::SetWorldPoint\n");



void
vtkViewport::ViewToDisplay()
		CODE:
		THIS->ViewToDisplay();
		XSRETURN_EMPTY;


void
vtkViewport::ViewToNormalizedViewport(x, y, z)
		float 	x
		float 	y
		float 	z
		CODE:
		THIS->ViewToNormalizedViewport(x, y, z);
		XSRETURN_EMPTY;
		OUTPUT:
		x
		y
		z


void
vtkViewport::ViewToWorld(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->ViewToWorld(arg1, arg2, arg3);
		XSRETURN_EMPTY;
		OUTPUT:
		arg1
		arg2
		arg3
	CASE: items == 1
		CODE:
		THIS->ViewToWorld();
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkViewport::ViewToWorld\n");



void
vtkViewport::ViewportToNormalizedDisplay(x, y)
		float 	x
		float 	y
		CODE:
		THIS->ViewportToNormalizedDisplay(x, y);
		XSRETURN_EMPTY;
		OUTPUT:
		x
		y


void
vtkViewport::ViewportToNormalizedViewport(u, v)
		float 	u
		float 	v
		CODE:
		THIS->ViewportToNormalizedViewport(u, v);
		XSRETURN_EMPTY;
		OUTPUT:
		u
		v


void
vtkViewport::WorldToDisplay()
		CODE:
		THIS->WorldToDisplay();
		XSRETURN_EMPTY;


void
vtkViewport::WorldToView(arg1 = 0, arg2 = 0, arg3 = 0)
	CASE: items == 4
		float 	arg1
		float 	arg2
		float 	arg3
		CODE:
		THIS->WorldToView(arg1, arg2, arg3);
		XSRETURN_EMPTY;
		OUTPUT:
		arg1
		arg2
		arg3
	CASE: items == 1
		CODE:
		THIS->WorldToView();
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkViewport::WorldToView\n");


MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::VoidArray PREFIX = vtk

PROTOTYPES: DISABLE



int
vtkVoidArray::Allocate(sz, ext)
		const long 	sz
		const long 	ext
		CODE:
		RETVAL = THIS->Allocate(sz, ext);
		OUTPUT:
		RETVAL


void
vtkVoidArray::DeepCopy(da)
		vtkDataArray *	da
		CODE:
		THIS->DeepCopy(da);
		XSRETURN_EMPTY;


const char *
vtkVoidArray::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkVoidArray::GetDataType()
		CODE:
		RETVAL = THIS->GetDataType();
		OUTPUT:
		RETVAL


void
vtkVoidArray::Initialize()
		CODE:
		THIS->Initialize();
		XSRETURN_EMPTY;


static vtkVoidArray*
vtkVoidArray::New()
		CODE:
		RETVAL = vtkVoidArray::New();
		OUTPUT:
		RETVAL


void
vtkVoidArray::Resize(numTuples)
		long 	numTuples
		CODE:
		THIS->Resize(numTuples);
		XSRETURN_EMPTY;


void
vtkVoidArray::SetNumberOfTuples(number)
		const long 	number
		CODE:
		THIS->SetNumberOfTuples(number);
		XSRETURN_EMPTY;


void
vtkVoidArray::SetNumberOfValues(number)
		const long 	number
		CODE:
		THIS->SetNumberOfValues(number);
		XSRETURN_EMPTY;


void
vtkVoidArray::Squeeze()
		CODE:
		THIS->Squeeze();
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Voxel PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkVoxel::Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	verts
		vtkCellArray *	lines
		vtkCellArray *	polys
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		CODE:
		THIS->Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd);
		XSRETURN_EMPTY;


int
vtkVoxel::GetCellDimension()
		CODE:
		RETVAL = THIS->GetCellDimension();
		OUTPUT:
		RETVAL


int
vtkVoxel::GetCellType()
		CODE:
		RETVAL = THIS->GetCellType();
		OUTPUT:
		RETVAL


const char *
vtkVoxel::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkCell *
vtkVoxel::GetEdge(edgeId)
		int 	edgeId
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetEdge(edgeId);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkCell *
vtkVoxel::GetFace(faceId)
		int 	faceId
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetFace(faceId);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkVoxel::GetNumberOfEdges()
		CODE:
		RETVAL = THIS->GetNumberOfEdges();
		OUTPUT:
		RETVAL


int
vtkVoxel::GetNumberOfFaces()
		CODE:
		RETVAL = THIS->GetNumberOfFaces();
		OUTPUT:
		RETVAL


static vtkVoxel*
vtkVoxel::New()
		CODE:
		RETVAL = vtkVoxel::New();
		OUTPUT:
		RETVAL


int
vtkVoxel::Triangulate(index, ptIds, pts)
		int 	index
		vtkIdList *	ptIds
		vtkPoints *	pts
		CODE:
		RETVAL = THIS->Triangulate(index, ptIds, pts);
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::WarpTransform PREFIX = vtk

PROTOTYPES: DISABLE



const char *
vtkWarpTransform::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkWarpTransform::GetInverseFlag()
		CODE:
		RETVAL = THIS->GetInverseFlag();
		OUTPUT:
		RETVAL


int
vtkWarpTransform::GetInverseIterations()
		CODE:
		RETVAL = THIS->GetInverseIterations();
		OUTPUT:
		RETVAL


double
vtkWarpTransform::GetInverseTolerance()
		CODE:
		RETVAL = THIS->GetInverseTolerance();
		OUTPUT:
		RETVAL


void
vtkWarpTransform::Inverse()
		CODE:
		THIS->Inverse();
		XSRETURN_EMPTY;


void
vtkWarpTransform::SetInverseIterations(arg1)
		int 	arg1
		CODE:
		THIS->SetInverseIterations(arg1);
		XSRETURN_EMPTY;


void
vtkWarpTransform::SetInverseTolerance(arg1)
		double 	arg1
		CODE:
		THIS->SetInverseTolerance(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Wedge PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkWedge::Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd)
		float 	value
		vtkDataArray *	cellScalars
		vtkPointLocator *	locator
		vtkCellArray *	verts
		vtkCellArray *	lines
		vtkCellArray *	polys
		vtkPointData *	inPd
		vtkPointData *	outPd
		vtkCellData *	inCd
		long 	cellId
		vtkCellData *	outCd
		CODE:
		THIS->Contour(value, cellScalars, locator, verts, lines, polys, inPd, outPd, inCd, cellId, outCd);
		XSRETURN_EMPTY;


int
vtkWedge::GetCellDimension()
		CODE:
		RETVAL = THIS->GetCellDimension();
		OUTPUT:
		RETVAL


int
vtkWedge::GetCellType()
		CODE:
		RETVAL = THIS->GetCellType();
		OUTPUT:
		RETVAL


const char *
vtkWedge::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


vtkCell *
vtkWedge::GetEdge(edgeId)
		int 	edgeId
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetEdge(edgeId);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


vtkCell *
vtkWedge::GetFace(faceId)
		int 	faceId
		PREINIT:
		char  CLASS[80] = "Graphics::VTK::vtkCell";
		CODE:
		RETVAL = THIS->GetFace(faceId);
		if(RETVAL != NULL){
			strcpy(CLASS,"Graphics::VTK::");
			strcat(CLASS,RETVAL->GetClassName()+3);
		}
		OUTPUT:
		RETVAL


int
vtkWedge::GetNumberOfEdges()
		CODE:
		RETVAL = THIS->GetNumberOfEdges();
		OUTPUT:
		RETVAL


int
vtkWedge::GetNumberOfFaces()
		CODE:
		RETVAL = THIS->GetNumberOfFaces();
		OUTPUT:
		RETVAL



static vtkWedge*
vtkWedge::New()
		CODE:
		RETVAL = vtkWedge::New();
		OUTPUT:
		RETVAL


int
vtkWedge::Triangulate(index, ptIds, pts)
		int 	index
		vtkIdList *	ptIds
		vtkPoints *	pts
		CODE:
		RETVAL = THIS->Triangulate(index, ptIds, pts);
		OUTPUT:
		RETVAL

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Window PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkWindow::DoubleBufferOff()
		CODE:
		THIS->DoubleBufferOff();
		XSRETURN_EMPTY;


void
vtkWindow::DoubleBufferOn()
		CODE:
		THIS->DoubleBufferOn();
		XSRETURN_EMPTY;


void
vtkWindow::EraseOff()
		CODE:
		THIS->EraseOff();
		XSRETURN_EMPTY;


void
vtkWindow::EraseOn()
		CODE:
		THIS->EraseOn();
		XSRETURN_EMPTY;


const char *
vtkWindow::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkWindow::GetDPI()
		CODE:
		RETVAL = THIS->GetDPI();
		OUTPUT:
		RETVAL


int
vtkWindow::GetDPIMaxValue()
		CODE:
		RETVAL = THIS->GetDPIMaxValue();
		OUTPUT:
		RETVAL


int
vtkWindow::GetDPIMinValue()
		CODE:
		RETVAL = THIS->GetDPIMinValue();
		OUTPUT:
		RETVAL


int
vtkWindow::GetDoubleBuffer()
		CODE:
		RETVAL = THIS->GetDoubleBuffer();
		OUTPUT:
		RETVAL


int
vtkWindow::GetErase()
		CODE:
		RETVAL = THIS->GetErase();
		OUTPUT:
		RETVAL


int
vtkWindow::GetMapped()
		CODE:
		RETVAL = THIS->GetMapped();
		OUTPUT:
		RETVAL


int
vtkWindow::GetOffScreenRendering()
		CODE:
		RETVAL = THIS->GetOffScreenRendering();
		OUTPUT:
		RETVAL


int *
vtkWindow::GetPosition()
		PREINIT:
		int * retval;
		CODE:
		SP -= items;
		retval = THIS->GetPosition();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


int *
vtkWindow::GetSize()
		PREINIT:
		int * retval;
		CODE:
		SP -= items;
		retval = THIS->GetSize();
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUTBACK;
		return;


char *
vtkWindow::GetWindowName()
		CODE:
		RETVAL = THIS->GetWindowName();
		OUTPUT:
		RETVAL


void
vtkWindow::MakeCurrent()
		CODE:
		THIS->MakeCurrent();
		XSRETURN_EMPTY;


void
vtkWindow::MappedOff()
		CODE:
		THIS->MappedOff();
		XSRETURN_EMPTY;


void
vtkWindow::MappedOn()
		CODE:
		THIS->MappedOn();
		XSRETURN_EMPTY;


void
vtkWindow::OffScreenRenderingOff()
		CODE:
		THIS->OffScreenRenderingOff();
		XSRETURN_EMPTY;


void
vtkWindow::OffScreenRenderingOn()
		CODE:
		THIS->OffScreenRenderingOn();
		XSRETURN_EMPTY;


void
vtkWindow::Render()
		CODE:
		THIS->Render();
		XSRETURN_EMPTY;


void
vtkWindow::SetDPI(arg1)
		int 	arg1
		CODE:
		THIS->SetDPI(arg1);
		XSRETURN_EMPTY;


void
vtkWindow::SetDoubleBuffer(arg1)
		int 	arg1
		CODE:
		THIS->SetDoubleBuffer(arg1);
		XSRETURN_EMPTY;


void
vtkWindow::SetErase(arg1)
		int 	arg1
		CODE:
		THIS->SetErase(arg1);
		XSRETURN_EMPTY;


void
vtkWindow::SetMapped(arg1)
		int 	arg1
		CODE:
		THIS->SetMapped(arg1);
		XSRETURN_EMPTY;


void
vtkWindow::SetOffScreenRendering(arg1)
		int 	arg1
		CODE:
		THIS->SetOffScreenRendering(arg1);
		XSRETURN_EMPTY;


void
vtkWindow::SetParentInfo(arg1)
		char *	arg1
		CODE:
		THIS->SetParentInfo(arg1);
		XSRETURN_EMPTY;


void
vtkWindow::SetPosition(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetPosition(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkWindow::SetPosition\n");



void
vtkWindow::SetSize(arg1 = 0, arg2 = 0)
	CASE: items == 3
		int 	arg1
		int 	arg2
		CODE:
		THIS->SetSize(arg1, arg2);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkWindow::SetSize\n");



void
vtkWindow::SetWindowInfo(arg1)
		char *	arg1
		CODE:
		THIS->SetWindowInfo(arg1);
		XSRETURN_EMPTY;


void
vtkWindow::SetWindowName(arg1)
		char *	arg1
		CODE:
		THIS->SetWindowName(arg1);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::WindowLevelLookupTable PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkWindowLevelLookupTable::Build()
		CODE:
		THIS->Build();
		XSRETURN_EMPTY;


const char *
vtkWindowLevelLookupTable::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


int
vtkWindowLevelLookupTable::GetInverseVideo()
		CODE:
		RETVAL = THIS->GetInverseVideo();
		OUTPUT:
		RETVAL


float
vtkWindowLevelLookupTable::GetLevel()
		CODE:
		RETVAL = THIS->GetLevel();
		OUTPUT:
		RETVAL


float  *
vtkWindowLevelLookupTable::GetMaximumTableValue()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetMaximumTableValue();
		EXTEND(SP, 4);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUTBACK;
		return;


float  *
vtkWindowLevelLookupTable::GetMinimumTableValue()
		PREINIT:
		float  * retval;
		CODE:
		SP -= items;
		retval = THIS->GetMinimumTableValue();
		EXTEND(SP, 4);
		PUSHs(sv_2mortal(newSVnv(retval[0])));
		PUSHs(sv_2mortal(newSVnv(retval[1])));
		PUSHs(sv_2mortal(newSVnv(retval[2])));
		PUSHs(sv_2mortal(newSVnv(retval[3])));
		PUTBACK;
		return;


float
vtkWindowLevelLookupTable::GetWindow()
		CODE:
		RETVAL = THIS->GetWindow();
		OUTPUT:
		RETVAL


void
vtkWindowLevelLookupTable::InverseVideoOff()
		CODE:
		THIS->InverseVideoOff();
		XSRETURN_EMPTY;


void
vtkWindowLevelLookupTable::InverseVideoOn()
		CODE:
		THIS->InverseVideoOn();
		XSRETURN_EMPTY;


static vtkWindowLevelLookupTable*
vtkWindowLevelLookupTable::New()
		CODE:
		RETVAL = vtkWindowLevelLookupTable::New();
		OUTPUT:
		RETVAL


void
vtkWindowLevelLookupTable::SetInverseVideo(iv)
		int 	iv
		CODE:
		THIS->SetInverseVideo(iv);
		XSRETURN_EMPTY;


void
vtkWindowLevelLookupTable::SetLevel(level)
		float 	level
		CODE:
		THIS->SetLevel(level);
		XSRETURN_EMPTY;


void
vtkWindowLevelLookupTable::SetMaximumColor(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		CODE:
		THIS->SetMaximumColor(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkWindowLevelLookupTable::SetMaximumColor\n");



void
vtkWindowLevelLookupTable::SetMaximumTableValue(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		float 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		CODE:
		THIS->SetMaximumTableValue(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkWindowLevelLookupTable::SetMaximumTableValue\n");



void
vtkWindowLevelLookupTable::SetMinimumColor(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		int 	arg1
		int 	arg2
		int 	arg3
		int 	arg4
		CODE:
		THIS->SetMinimumColor(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkWindowLevelLookupTable::SetMinimumColor\n");



void
vtkWindowLevelLookupTable::SetMinimumTableValue(arg1 = 0, arg2 = 0, arg3 = 0, arg4 = 0)
	CASE: items == 5
		float 	arg1
		float 	arg2
		float 	arg3
		float 	arg4
		CODE:
		THIS->SetMinimumTableValue(arg1, arg2, arg3, arg4);
		XSRETURN_EMPTY;
	CASE:
		CODE:
		croak("Unsupported number of args and/or types supplied to vtkWindowLevelLookupTable::SetMinimumTableValue\n");



void
vtkWindowLevelLookupTable::SetWindow(window)
		float 	window
		CODE:
		THIS->SetWindow(window);
		XSRETURN_EMPTY;

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::XMLFileOutputWindow PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkXMLFileOutputWindow::DisplayDebugText(arg1)
		const char *	arg1
		CODE:
		THIS->DisplayDebugText(arg1);
		XSRETURN_EMPTY;


void
vtkXMLFileOutputWindow::DisplayErrorText(arg1)
		const char *	arg1
		CODE:
		THIS->DisplayErrorText(arg1);
		XSRETURN_EMPTY;


void
vtkXMLFileOutputWindow::DisplayGenericWarningText(arg1)
		const char *	arg1
		CODE:
		THIS->DisplayGenericWarningText(arg1);
		XSRETURN_EMPTY;


void
vtkXMLFileOutputWindow::DisplayTag(arg1)
		const char *	arg1
		CODE:
		THIS->DisplayTag(arg1);
		XSRETURN_EMPTY;


void
vtkXMLFileOutputWindow::DisplayText(arg1)
		const char *	arg1
		CODE:
		THIS->DisplayText(arg1);
		XSRETURN_EMPTY;


void
vtkXMLFileOutputWindow::DisplayWarningText(arg1)
		const char *	arg1
		CODE:
		THIS->DisplayWarningText(arg1);
		XSRETURN_EMPTY;


const char *
vtkXMLFileOutputWindow::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkXMLFileOutputWindow*
vtkXMLFileOutputWindow::New()
		CODE:
		RETVAL = vtkXMLFileOutputWindow::New();
		OUTPUT:
		RETVAL

#ifdef WIN32

MODULE = Graphics::VTK::Common	PACKAGE = Graphics::VTK::Win32OutputWindow PREFIX = vtk

PROTOTYPES: DISABLE



void
vtkWin32OutputWindow::DisplayText(arg1)
		const char *	arg1
		CODE:
		THIS->DisplayText(arg1);
		XSRETURN_EMPTY;


const char *
vtkWin32OutputWindow::GetClassName()
		CODE:
		RETVAL = THIS->GetClassName();
		OUTPUT:
		RETVAL


static vtkWin32OutputWindow*
vtkWin32OutputWindow::New()
		CODE:
		RETVAL = vtkWin32OutputWindow::New();
		OUTPUT:
		RETVAL

#endif


