cpBool
cpConstraintIsGrooveJoint( constraint )
    cpConstraint *constraint

cpGrooveJoint*
cpGrooveJointAlloc(  )

cpGrooveJoint*
cpGrooveJointInit( joint, a, b, groove_a, groove_b, anchorB )
    cpGrooveJoint *joint
    cpBody *a
    cpBody *b
    cpVect groove_a
    cpVect groove_b
    cpVect anchorB

cpConstraint*
cpGrooveJointNew( a, b, groove_a, groove_b, anchorB )
    cpBody *a
    cpBody *b
    cpVect groove_a
    cpVect groove_b
    cpVect anchorB

cpVect
cpGrooveJointGetGrooveA( constraint )
    cpConstraint *constraint

void
cpGrooveJointSetGrooveA( constraint, grooveA )
    cpConstraint *constraint
    cpVect grooveA

cpVect
cpGrooveJointGetGrooveB( constraint )
    cpConstraint *constraint

void
cpGrooveJointSetGrooveB( constraint, grooveB )
    cpConstraint *constraint
    cpVect grooveB

cpVect
cpGrooveJointGetAnchorB( constraint )
    cpConstraint *constraint

void
cpGrooveJointSetAnchorB( constraint, anchorB )
    cpConstraint *constraint
    cpVect anchorB

