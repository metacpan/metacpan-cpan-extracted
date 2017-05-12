cpBool
cpConstraintIsSimpleMotor( constraint )
    cpConstraint *constraint

cpSimpleMotor *
cpSimpleMotorAlloc(  )

cpSimpleMotor *
cpSimpleMotorInit( joint, a, b, rate )
    cpSimpleMotor *joint
    cpBody *a
    cpBody *b
    cpFloat rate

cpConstraint *
cpSimpleMotorNew( a, b, rate )
    cpBody *a
    cpBody *b
    cpFloat rate

cpFloat
cpSimpleMotorGetRate( constraint )
    cpConstraint *constraint

void
cpSimpleMotorSetRate( constraint, rate )
    cpConstraint *constraint
    cpFloat rate

