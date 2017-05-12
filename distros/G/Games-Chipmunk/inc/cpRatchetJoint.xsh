cpBool
cpConstraintIsRatchetJoint( constraint )
    cpConstraint *constraint

cpRatchetJoint *
cpRatchetJointAlloc(  )

cpRatchetJoint *
cpRatchetJointInit( joint, a, b, phase, ratchet )
    cpRatchetJoint *joint
    cpBody *a
    cpBody *b
    cpFloat phase
    cpFloat ratchet

cpConstraint *
cpRatchetJointNew( a, b, phase, ratchet )
    cpBody *a
    cpBody *b
    cpFloat phase
    cpFloat ratchet

cpFloat
cpRatchetJointGetAngle( constraint )
    cpConstraint *constraint

void
cpRatchetJointSetAngle( constraint, angle )
    cpConstraint *constraint
    cpFloat angle

cpFloat
cpRatchetJointGetPhase( constraint )
    cpConstraint *constraint

void
cpRatchetJointSetPhase( constraint, phase )
    cpConstraint *constraint
    cpFloat phase

cpFloat
cpRatchetJointGetRatchet( constraint )
    cpConstraint *constraint

void
cpRatchetJointSetRatchet( constraint, ratchet )
    cpConstraint *constraint
    cpFloat ratchet

