cpBool
cpConstraintIsDampedSpring( constraint )
    cpConstraint *constraint

cpDampedSpring*
cpDampedSpringAlloc(  )

cpDampedSpring*
cpDampedSpringInit( joint, a, b, anchorA, anchorB, restLength, stiffness, damping )
    cpDampedSpring *joint
    cpBody *a
    cpBody *b
    cpVect anchorA
    cpVect anchorB
    cpFloat restLength
    cpFloat stiffness
    cpFloat damping

cpConstraint*
cpDampedSpringNew( a, b, anchorA, anchorB, restLength, stiffness, damping )
    cpBody *a
    cpBody *b
    cpVect anchorA
    cpVect anchorB
    cpFloat restLength
    cpFloat stiffness
    cpFloat damping

cpVect
cpDampedSpringGetAnchorA( constraint )
    cpConstraint *constraint

void
cpDampedSpringSetAnchorA( constraint, anchorA )
    cpConstraint *constraint
    cpVect anchorA

cpVect
cpDampedSpringGetAnchorB( constraint )
    cpConstraint *constraint

void
cpDampedSpringSetAnchorB( constraint, anchorB )
    cpConstraint *constraint
    cpVect anchorB

cpFloat
cpDampedSpringGetRestLength( constraint )
    cpConstraint *constraint

void
cpDampedSpringSetRestLength( constraint, restLength )
    cpConstraint *constraint
    cpFloat restLength

cpFloat
cpDampedSpringGetStiffness( constraint )
    cpConstraint *constraint

void
cpDampedSpringSetStiffness( constraint, stiffness )
    cpConstraint *constraint
    cpFloat stiffness

cpFloat
cpDampedSpringGetDamping( constraint )
    cpConstraint *constraint

void
cpDampedSpringSetDamping( constraint, damping )
    cpConstraint *constraint
    cpFloat damping

cpDampedSpringForceFunc
cpDampedSpringGetSpringForceFunc( constraint )
    cpConstraint *constraint
