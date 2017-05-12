cpBool
cpConstraintIsGearJoint( constraint )
    cpConstraint *constraint

cpGearJoint*
cpGearJointAlloc(  )

cpGearJoint*
cpGearJointInit( joint, a, b, phase, ratio )
    cpGearJoint *joint
    cpBody *a
    cpBody *b
    cpFloat phase
    cpFloat ratio

cpConstraint*
cpGearJointNew( a, b, phase, ratio )
    cpBody *a
    cpBody *b
    cpFloat phase
    cpFloat ratio

cpFloat
cpGearJointGetPhase( constraint )
    cpConstraint *constraint

void
cpGearJointSetPhase( constraint, phase )
    cpConstraint *constraint
    cpFloat phase

cpFloat
cpGearJointGetRatio( constraint )
    cpConstraint *constraint

void
cpGearJointSetRatio( constraint, ratio )
    cpConstraint *constraint
    cpFloat ratio

