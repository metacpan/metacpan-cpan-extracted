cpBool
cpConstraintIsRotaryLimitJoint( constraint )
    cpConstraint *constraint

cpRotaryLimitJoint *
cpRotaryLimitJointAlloc(  )

cpRotaryLimitJoint *
cpRotaryLimitJointInit( joint, a, b, min, max )
    cpRotaryLimitJoint *joint
    cpBody *a
    cpBody *b
    cpFloat min
    cpFloat max

cpConstraint *
cpRotaryLimitJointNew( a, b, min, max )
    cpBody *a
    cpBody *b
    cpFloat min
    cpFloat max

cpFloat
cpRotaryLimitJointGetMin( constraint )
    cpConstraint *constraint

void
cpRotaryLimitJointSetMin( constraint, min )
    cpConstraint *constraint
    cpFloat min

cpFloat
cpRotaryLimitJointGetMax( constraint )
    cpConstraint *constraint

void
cpRotaryLimitJointSetMax( constraint, max )
    cpConstraint *constraint
    cpFloat max

