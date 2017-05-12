cpSpace *
cpSpaceAlloc(  )

cpSpace *
cpSpaceInit( space )
    cpSpace *space

cpSpace *
cpSpaceNew(  )

void
cpSpaceDestroy( space )
    cpSpace *space

void
cpSpaceFree( space )
    cpSpace *space

int
cpSpaceGetIterations( space )
    cpSpace *space

void
cpSpaceSetIterations( space, iterations )
    cpSpace *space
    int iterations

cpVect
cpSpaceGetGravity( space )
    cpSpace *space

void
cpSpaceSetGravity( space, gravity )
    cpSpace *space
    cpVect gravity

cpFloat
cpSpaceGetDamping( space )
    cpSpace *space

void
cpSpaceSetDamping( space, damping )
    cpSpace *space
    cpFloat damping

cpFloat
cpSpaceGetIdleSpeedThreshold( space )
    cpSpace *space

void
cpSpaceSetIdleSpeedThreshold( space, idleSpeedThreshold )
    cpSpace *space
    cpFloat idleSpeedThreshold

cpFloat
cpSpaceGetSleepTimeThreshold( space )
    cpSpace *space

void
cpSpaceSetSleepTimeThreshold( space, sleepTimeThreshold )
    cpSpace *space
    cpFloat sleepTimeThreshold

cpFloat
cpSpaceGetCollisionSlop( space )
    cpSpace *space

void
cpSpaceSetCollisionSlop( space, collisionSlop )
    cpSpace *space
    cpFloat collisionSlop

cpFloat
cpSpaceGetCollisionBias( space )
    cpSpace *space

void
cpSpaceSetCollisionBias( space, collisionBias )
    cpSpace *space
    cpFloat collisionBias

cpTimestamp
cpSpaceGetCollisionPersistence( space )
    cpSpace *space

void
cpSpaceSetCollisionPersistence( space, collisionPersistence )
    cpSpace *space
    cpTimestamp collisionPersistence

cpDataPointer
cpSpaceGetUserData( space )
    cpSpace *space

void
cpSpaceSetUserData( space, userData )
    cpSpace *space
    cpDataPointer userData

cpBody *
cpSpaceGetStaticBody( space )
    cpSpace *space

cpFloat
cpSpaceGetCurrentTimeStep( space )
    cpSpace *space

cpBool
cpSpaceIsLocked( space )
    cpSpace *space

cpCollisionHandler *
cpSpaceAddDefaultCollisionHandler( space )
    cpSpace *space

cpCollisionHandler *
cpSpaceAddCollisionHandler( space, a, b )
    cpSpace *space
    cpCollisionType a
    cpCollisionType b

cpCollisionHandler *
cpSpaceAddWildcardHandler( space, type )
    cpSpace *space
    cpCollisionType type

cpShape *
cpSpaceAddShape( space, shape )
    cpSpace *space
    cpShape *shape

cpBody *
cpSpaceAddBody( space, body )
    cpSpace *space
    cpBody *body

cpConstraint *
cpSpaceAddConstraint( space, constraint )
    cpSpace *space
    cpConstraint *constraint

void
cpSpaceRemoveShape( space, shape )
    cpSpace *space
    cpShape *shape

void
cpSpaceRemoveBody( space, body )
    cpSpace *space
    cpBody *body

void
cpSpaceRemoveConstraint( space, constraint )
    cpSpace *space
    cpConstraint *constraint

cpBool
cpSpaceContainsShape( space, shape )
    cpSpace *space
    cpShape *shape

cpBool
cpSpaceContainsBody( space, body )
    cpSpace *space
    cpBody *body

cpBool
cpSpaceContainsConstraint( space, constraint )
    cpSpace *space
    cpConstraint *constraint

cpBool
cpSpaceAddPostStepCallback( space, func, key, data )
    cpSpace *space
    cpPostStepFunc func
    void *key
    void *data

void
cpSpacePointQuery( space, point, maxDistance, filter, func, data )
    cpSpace *space
    cpVect point
    cpFloat maxDistance
    cpShapeFilter filter
    cpSpacePointQueryFunc func
    void *data

cpShape *
cpSpacePointQueryNearest( space, point, maxDistance, filter, out )
    cpSpace *space
    cpVect point
    cpFloat maxDistance
    cpShapeFilter filter
    cpPointQueryInfo *out

void
cpSpaceSegmentQuery( space, start, end, radius, filter, func, data )
    cpSpace *space
    cpVect start
    cpVect end
    cpFloat radius
    cpShapeFilter filter
    cpSpaceSegmentQueryFunc func
    void *data

cpShape *
cpSpaceSegmentQueryFirst( space, start, end, radius, filter, out )
    cpSpace *space
    cpVect start
    cpVect end
    cpFloat radius
    cpShapeFilter filter
    cpSegmentQueryInfo *out

void
cpSpaceBBQuery( space, bb, filter, func, data )
    cpSpace *space
    cpBB bb
    cpShapeFilter filter
    cpSpaceBBQueryFunc func
    void *data

cpBool
cpSpaceShapeQuery( space, shape, func, data )
    cpSpace *space
    cpShape *shape
    cpSpaceShapeQueryFunc func
    void *data

void
cpSpaceEachBody( space, func, data )
    cpSpace *space
    cpSpaceBodyIteratorFunc func
    void *data

void
cpSpaceEachShape( space, func, data )
    cpSpace *space
    cpSpaceShapeIteratorFunc func
    void *data

void
cpSpaceEachConstraint( space, func, data )
    cpSpace *space
    cpSpaceConstraintIteratorFunc func
    void *data

void
cpSpaceReindexStatic( space )
    cpSpace *space

void
cpSpaceReindexShape( space, shape )
    cpSpace *space
    cpShape *shape

void
cpSpaceReindexShapesForBody( space, body )
    cpSpace *space
    cpBody *body

void
cpSpaceUseSpatialHash( space, dim, count )
    cpSpace *space
    cpFloat dim
    int count

void
cpSpaceStep( space, dt )
    cpSpace *space
    cpFloat dt

void
cpSpaceDebugDraw( space, options )
    cpSpace *space
    cpSpaceDebugDrawOptions *options

