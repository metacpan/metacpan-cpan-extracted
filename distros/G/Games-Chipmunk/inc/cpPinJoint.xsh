cpBool
cpConstraintIsPinJoint( constraint )
    cpConstraint *constraint

cpPinJoint *
cpPinJointAlloc(  )

cpPinJoint *
cpPinJointInit( joint, a, b, anchorA, anchorB )
    cpPinJoint *joint
    cpBody *a
    cpBody *b
    cpVect anchorA
    cpVect anchorB

cpConstraint *
cpPinJointNew( a, b, anchorA, anchorB )
    cpBody *a
    cpBody *b
    cpVect anchorA
    cpVect anchorB

cpVect
cpPinJointGetAnchorA( constraint )
    cpConstraint *constraint

void
cpPinJointSetAnchorA( constraint, anchorA )
    cpConstraint *constraint
    cpVect anchorA

cpVect
cpPinJointGetAnchorB( constraint )
    cpConstraint *constraint

void
cpPinJointSetAnchorB( constraint, anchorB )
    cpConstraint *constraint
    cpVect anchorB

cpFloat
cpPinJointGetDist( constraint )
    cpConstraint *constraint

void
cpPinJointSetDist( constraint, dist )
    cpConstraint *constraint
    cpFloat dist

