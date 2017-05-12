INCLUDE: inc/cpBody_custom.xsh


cpBody *
cpBodyAlloc(  )

cpBody *
cpBodyInit( body, mass, moment )
    cpBody *body
    cpFloat mass
    cpFloat moment

cpBody *
cpBodyNew( mass, moment )
    cpFloat mass
    cpFloat moment

cpBody *
cpBodyNewKinematic(  )

cpBody *
cpBodyNewStatic(  )

void
cpBodyDestroy( body )
    cpBody *body

void
cpBodyFree( body )
    cpBody *body

void
cpBodyActivate( body )
    cpBody *body

void
cpBodyActivateStatic( body, filter )
    cpBody *body
    cpShape *filter

void
cpBodySleep( body )
    cpBody *body

void
cpBodySleepWithGroup( body, group )
    cpBody *body
    cpBody *group

cpBool
cpBodyIsSleeping( body )
    cpBody *body

cpBodyType
cpBodyGetType( body )
    cpBody *body

void
cpBodySetType( body, type )
    cpBody *body
    cpBodyType type

cpSpace *
cpBodyGetSpace( body )
    cpBody *body

cpFloat
cpBodyGetMass( body )
    cpBody *body

void
cpBodySetMass( body, m )
    cpBody *body
    cpFloat m

cpFloat
cpBodyGetMoment( body )
    cpBody *body

void
cpBodySetMoment( body, i )
    cpBody *body
    cpFloat i

cpVect
cpBodyGetPosition( body )
    cpBody *body

void
cpBodySetPosition( body, pos )
    cpBody *body
    cpVect pos

cpVect
cpBodyGetCenterOfGravity( body )
    cpBody *body

void
cpBodySetCenterOfGravity( body, cog )
    cpBody *body
    cpVect cog

cpVect
cpBodyGetVelocity( body )
    cpBody *body

cpVect
cpBodyGetForce( body )
    cpBody *body

void
cpBodySetForce( body, force )
    cpBody *body
    cpVect force

cpFloat
cpBodyGetAngle( body )
    cpBody *body

void
cpBodySetAngle( body, a )
    cpBody *body
    cpFloat a

cpFloat
cpBodyGetAngularVelocity( body )
    cpBody *body

void
cpBodySetAngularVelocity( body, angularVelocity )
    cpBody *body
    cpFloat angularVelocity

cpFloat
cpBodyGetTorque( body )
    cpBody *body

void
cpBodySetTorque( body, torque )
    cpBody *body
    cpFloat torque

cpVect
cpBodyGetRotation( body )
    cpBody *body

cpDataPointer
cpBodyGetUserData( body )
    cpBody *body

void
cpBodySetUserData( body, userData )
    cpBody *body
    cpDataPointer userData

void
cpBodyUpdateVelocity( body, gravity, damping, dt )
    cpBody *body
    cpVect gravity
    cpFloat damping
    cpFloat dt

void
cpBodyUpdatePosition( body, dt )
    cpBody *body
    cpFloat dt

cpVect
cpBodyLocalToWorld( body, point )
    cpBody *body
    cpVect point

cpVect
cpBodyWorldToLocal( body, point )
    cpBody *body
    cpVect point

void
cpBodyApplyForceAtWorldPoint( body, force, point )
    cpBody *body
    cpVect force
    cpVect point

void
cpBodyApplyForceAtLocalPoint( body, force, point )
    cpBody *body
    cpVect force
    cpVect point

void
cpBodyApplyImpulseAtWorldPoint( body, impulse, point )
    cpBody *body
    cpVect impulse
    cpVect point

void
cpBodyApplyImpulseAtLocalPoint( body, impulse, point )
    cpBody *body
    cpVect impulse
    cpVect point

cpVect
cpBodyGetVelocityAtWorldPoint( body, point )
    cpBody *body
    cpVect point

cpVect
cpBodyGetVelocityAtLocalPoint( body, point )
    cpBody *body
    cpVect point

cpFloat
cpBodyKineticEnergy( body )
    cpBody *body

# EXPORTS:
# cpBodyAlloc
# cpBodyInit
# cpBodyNew
# cpBodyNewKinematic
# cpBodyNewStatic
# cpBodyDestroy
# cpBodyFree
# cpBodyActivate
# cpBodyActivateStatic
# cpBodySleep
# cpBodySleepWithGroup
# cpBodyIsSleeping
# cpBodyGetType
# cpBodySetType
# cpBodyGetSpace
# cpBodyGetMass
# cpBodySetMass
# cpBodyGetMoment
# cpBodySetMoment
# cpBodyGetPosition
# cpBodySetPosition
# cpBodyGetCenterOfGravity
# cpBodySetCenterOfGravity
# cpBodyGetVelocity
# cpBodySetVelocity
# cpBodyGetForce
# cpBodySetForce
# cpBodyGetAngle
# cpBodySetAngle
# cpBodyGetAngularVelocity
# cpBodySetAngularVelocity
# cpBodyGetTorque
# cpBodySetTorque
# cpBodyGetRotation
# cpBodyGetUserData
# cpBodySetUserData
# cpBodySetVelocityUpdateFunc
# cpBodySetPositionUpdateFunc
# cpBodyUpdateVelocity
# cpBodyUpdatePosition
# cpBodyLocalToWorld
# cpBodyWorldToLocal
# cpBodyApplyForceAtWorldPoint
# cpBodyApplyForceAtLocalPoint
# cpBodyApplyImpulseAtWorldPoint
# cpBodyApplyImpulseAtLocalPoint
# cpBodyGetVelocityAtWorldPoint
# cpBodyGetVelocityAtLocalPoint
# cpBodyKineticEnergy
# cpBodyEachShape
# cpBodyEachConstraint
# cpBodyEachArbiter
