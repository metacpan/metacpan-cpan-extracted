INCLUDE: inc/cpConstraint_custom.xsh


void
cpConstraintDestroy( constraint )
    cpConstraint *constraint

void
cpConstraintFree( constraint )
    cpConstraint *constraint

cpSpace*
cpConstraintGetSpace( constraint )
    cpConstraint *constraint

cpBody*
cpConstraintGetBodyA( constraint )
    cpConstraint *constraint

cpBody*
cpConstraintGetBodyB( constraint )
    cpConstraint *constraint

cpFloat
cpConstraintGetMaxForce( constraint )
    cpConstraint *constraint

void
cpConstraintSetMaxForce( constraint, maxForce )
    cpConstraint *constraint
    cpFloat maxForce

cpFloat
cpConstraintGetErrorBias( constraint )
    cpConstraint *constraint

void
cpConstraintSetErrorBias( constraint, errorBias )
    cpConstraint *constraint
    cpFloat errorBias

cpFloat
cpConstraintGetMaxBias( constraint )
    cpConstraint *constraint

void
cpConstraintSetMaxBias( constraint, maxBias )
    cpConstraint *constraint
    cpFloat maxBias

cpBool
cpConstraintGetCollideBodies( constraint )
    cpConstraint *constraint

void
cpConstraintSetCollideBodies( constraint, collideBodies )
    cpConstraint *constraint
    cpBool collideBodies

cpConstraintPreSolveFunc
cpConstraintGetPreSolveFunc( constraint )
    cpConstraint *constraint

cpConstraintPostSolveFunc
cpConstraintGetPostSolveFunc( constraint )
    cpConstraint *constraint

cpDataPointer
cpConstraintGetUserData( constraint )
    cpConstraint *constraint

void
cpConstraintSetUserData( constraint, userData )
    cpConstraint *constraint
    cpDataPointer userData

cpFloat
cpConstraintGetImpulse( constraint )
    cpConstraint *constraint

