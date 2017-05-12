cpBool
cpConstraintIsSlideJoint( constraint )
    cpConstraint *constraint

cpSlideJoint *
cpSlideJointAlloc(  )

cpSlideJoint *
cpSlideJointInit( joint, a, b, anchorA, anchorB, min, max )
    cpSlideJoint *joint
    cpBody *a
    cpBody *b
    cpVect anchorA
    cpVect anchorB
    cpFloat min
    cpFloat max

cpConstraint *
cpSlideJointNew( a, b, anchorA, anchorB, min, max )
    cpBody *a
    cpBody *b
    cpVect anchorA
    cpVect anchorB
    cpFloat min
    cpFloat max

cpVect
cpSlideJointGetAnchorA( constraint )
    cpConstraint *constraint

void
cpSlideJointSetAnchorA( constraint, anchorA )
    cpConstraint *constraint
    cpVect anchorA

cpVect
cpSlideJointGetAnchorB( constraint )
    cpConstraint *constraint

void
cpSlideJointSetAnchorB( constraint, anchorB )
    cpConstraint *constraint
    cpVect anchorB

cpFloat
cpSlideJointGetMin( constraint )
    cpConstraint *constraint

void
cpSlideJointSetMin( constraint, min )
    cpConstraint *constraint
    cpFloat min

cpFloat
cpSlideJointGetMax( constraint )
    cpConstraint *constraint

void
cpSlideJointSetMax( constraint, max )
    cpConstraint *constraint
    cpFloat max

