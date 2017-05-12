cpBool
cpConstraintIsPivotJoint( constraint )
    cpConstraint *constraint

cpPivotJoint *
cpPivotJointAlloc(  )

cpPivotJoint *
cpPivotJointInit( joint, a, b, anchorA, anchorB )
    cpPivotJoint *joint
    cpBody *a
    cpBody *b
    cpVect anchorA
    cpVect anchorB

cpConstraint *
cpPivotJointNew( a, b, pivot )
    cpBody *a
    cpBody *b
    cpVect pivot

cpConstraint *
cpPivotJointNew2( a, b, anchorA, anchorB )
    cpBody *a
    cpBody *b
    cpVect anchorA
    cpVect anchorB

cpVect
cpPivotJointGetAnchorA( constraint )
    cpConstraint *constraint

void
cpPivotJointSetAnchorA( constraint, anchorA )
    cpConstraint *constraint
    cpVect anchorA

cpVect
cpPivotJointGetAnchorB( constraint )
    cpConstraint *constraint

void
cpPivotJointSetAnchorB( constraint, anchorB )
    cpConstraint *constraint
    cpVect anchorB

