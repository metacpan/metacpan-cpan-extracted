INCLUDE: inc/cpDampedRotarySpring_custom.xsh


cpBool
cpConstraintIsDampedRotarySpring( constraint )
    cpConstraint *constraint

cpDampedRotarySpring*
cpDampedRotarySpringAlloc(  )

cpDampedRotarySpring*
cpDampedRotarySpringInit( joint, a, b, restAngle, stiffness, damping )
    cpDampedRotarySpring *joint
    cpBody *a
    cpBody *b
    cpFloat restAngle
    cpFloat stiffness
    cpFloat damping

cpConstraint*
cpDampedRotarySpringNew( a, b, restAngle, stiffness, damping )
    cpBody *a
    cpBody *b
    cpFloat restAngle
    cpFloat stiffness
    cpFloat damping

cpFloat
cpDampedRotarySpringGetRestAngle( constraint )
    cpConstraint *constraint

void
cpDampedRotarySpringSetRestAngle( constraint, restAngle )
    cpConstraint *constraint
    cpFloat restAngle

cpFloat
cpDampedRotarySpringGetStiffness( constraint )
    cpConstraint *constraint

void
cpDampedRotarySpringSetStiffness( constraint, stiffness )
    cpConstraint *constraint
    cpFloat stiffness

cpFloat
cpDampedRotarySpringGetDamping( constraint )
    cpConstraint *constraint

void
cpDampedRotarySpringSetDamping( constraint, damping )
    cpConstraint *constraint
    cpFloat damping

cpDampedRotarySpringTorqueFunc
cpDampedRotarySpringGetSpringTorqueFunc( constraint )
    cpConstraint *constraint
