#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <chipmunk/chipmunk.h>

#include "const-c.inc"

#define MY_CXT_KEY "Games::Chipmunk::_guts" XS_VERSION

typedef struct {
    HV * bodyVelocityFuncs;
    HV * bodyPositionFuncs;
    HV * bodyEachShapeFuncs;
    HV * bodyEachConstraintFuncs;
    HV * bodyArbiterIteratorFuncs;

    HV * constraintPreSolveFuncs;
    HV * constraintPostSolveFuncs;

    HV * dampedRotarySpringTorqueFuncs;

    HV * dampedSpringForceFuncs;
} my_cxt_t;

START_MY_CXT

#include "callback_funcs.c"



MODULE = Games::Chipmunk		PACKAGE = Games::Chipmunk		

BOOT: 
{
    MY_CXT_INIT;
    MY_CXT.bodyVelocityFuncs = newHV();
}


PROTOTYPES: ENABLE

INCLUDE: const-xs.inc

INCLUDE: inc/chipmunk.xsh
INCLUDE: inc/cpArbiter.xsh
INCLUDE: inc/cpBB.xsh
INCLUDE: inc/cpBody.xsh
INCLUDE: inc/cpConstraint.xsh
INCLUDE: inc/cpDampedRotarySpring.xsh
INCLUDE: inc/cpDampedSpring.xsh
INCLUDE: inc/cpGearJoint.xsh
INCLUDE: inc/cpGrooveJoint.xsh
INCLUDE: inc/cpHastySpace.xsh
INCLUDE: inc/cpPinJoint.xsh
INCLUDE: inc/cpPivotJoint.xsh
INCLUDE: inc/cpPolyline.xsh
INCLUDE: inc/cpPolyShape.xsh
INCLUDE: inc/cpRatchetJoint.xsh
INCLUDE: inc/cpRotaryLimitJoint.xsh
INCLUDE: inc/cpShape.xsh
INCLUDE: inc/cpSimpleMotor.xsh
INCLUDE: inc/cpSlideJoint.xsh
INCLUDE: inc/cpSpace.xsh
INCLUDE: inc/cpSpatialIndex.xsh

cpVect
_CPVZERO()
    CODE:
        RETVAL = cpvzero;
    OUTPUT:
        RETVAL

cpCircleShape *
cpCircleShapeAlloc()

cpVect
cpCircleShapeGetOffset(shape)
	const cpShape *	shape

cpFloat
cpCircleShapeGetRadius(shape)
	const cpShape *	shape

cpCircleShape *
cpCircleShapeInit(circle, body, radius, offset)
	cpCircleShape *	circle
	cpBody *	body
	cpFloat	radius
	cpVect	offset

cpShape *
cpCircleShapeNew(body, radius, offset)
	cpBody *	body
	cpFloat	radius
	cpVect	offset

cpVect
cpvslerp(v1, v2, t)
	cpVect	v1
	cpVect	v2
	cpFloat	t

cpVect
cpvslerpconst(v1, v2, a)
	cpVect	v1
	cpVect	v2
	cpFloat	a

cpVect
cpv( x, y )
    const cpFloat x
    const cpFloat y

cpBool
cpveql(v1, v2)
    cpVect v1
    cpVect v2

cpVect
cpvadd(v1, v2)
    cpVect v1
    cpVect v2

cpVect
cpvneg( v )
    cpVect v

cpVect
cpvsub( v1, v2 )
    cpVect v1
    cpVect v2

cpVect
cpvmult( v, s )
    cpVect v
    cpFloat s

cpFloat
cpvdot( v1, v2 )
    cpVect v1
    cpVect v2

cpFloat
cpvcross( v1, v2 )
    cpVect v1
    cpVect v2

cpVect
cpvperp( v )
    cpVect v

cpVect
cpvrperp( v )
    cpVect v

cpVect
cpvproject( v1, v2 )
    cpVect v1
    cpVect v2

cpVect
cpvforangle( a )
    cpFloat a

cpFloat
cpvtoangle( v )
    cpVect v

cpVect
cpvrotate( v1, v2 )
    cpVect v1
    cpVect v2

cpVect
cpvunrotate( v1, v2 )
    cpVect v1
    cpVect v2

cpFloat
cpvlengthsq( v )
    cpVect v

cpFloat
cpvlength( v )
    cpVect v

cpVect
cpvlerp( v1, v2, t )
    cpVect v1
    cpVect v2
    cpFloat t

cpVect
cpvnormalize( v )
    cpVect v

cpVect
cpvclamp( v, len )
    cpVect v
    cpFloat len

cpVect
cpvlerpconst( v1, v2, d )
    cpVect v1
    cpVect v2
    cpFloat d

cpFloat
cpvdist( v1, v2 )
    cpVect v1
    cpVect v2

cpFloat
cpvdistsq( v1, v2 )
    cpVect v1
    cpVect v2

cpBool
cpvnear( v1, v2, dist )
    cpVect v1
    cpVect v2
    cpFloat dist

cpFloat
cpfmax( a, b )
    cpFloat a
    cpFloat b

cpFloat
cpfmin( a, b )
    cpFloat a
    cpFloat b

cpFloat
cpfabs( f )
    cpFloat f

cpFloat
cpfclamp( f, min, max )
    cpFloat f
    cpFloat min
    cpFloat max

cpFloat
cpflerp( f1, f2, t )
    cpFloat f1
    cpFloat f2
    cpFloat t

cpFloat
cpflerpconst( f1, f2, d )
    cpFloat f1
    cpFloat f2
    cpFloat d


MODULE = Games::Chipmunk		PACKAGE = Games::Chipmunk::cpVect

cpFloat
x( vect )
        cpVect vect
    CODE:
        RETVAL = vect.x;
    OUTPUT:
        RETVAL

cpFloat
y( vect )
        cpVect vect
    CODE:
        RETVAL = vect.y;
    OUTPUT:
        RETVAL
