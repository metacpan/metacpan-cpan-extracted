cpFloat
cpArbiterGetRestitution( arb )
    const cpArbiter *arb

void
cpArbiterSetRestitution( arb, restitution )
    cpArbiter *arb
    cpFloat restitution

cpFloat
cpArbiterGetFriction( arb )
    const cpArbiter *arb

void
cpArbiterSetFriction( arb, friction )
    cpArbiter *arb
    cpFloat friction

cpVect
cpArbiterGetSurfaceVelocity( arb )
    cpArbiter *arb

void
cpArbiterSetSurfaceVelocity( arb, vr )
    cpArbiter *arb
    cpVect vr

cpDataPointer
cpArbiterGetUserData( arb )
    const cpArbiter *arb

void
cpArbiterSetUserData( arb, userData )
    cpArbiter *arb
    cpDataPointer userData

cpVect
cpArbiterTotalImpulse( arb )
    const cpArbiter *arb

cpFloat
cpArbiterTotalKE( arb )
    const cpArbiter *arb

cpBool
cpArbiterIgnore( arb )
    cpArbiter *arb

void
cpArbiterGetShapes( arb, a, b )
    const cpArbiter *arb
    cpShape **a
    cpShape **b

void
cpArbiterGetBodies( arb, a, b )
    const cpArbiter *arb
    cpBody **a
    cpBody **b

cpContactPointSet
cpArbiterGetContactPointSet( arb )
    const cpArbiter *arb

void
cpArbiterSetContactPointSet( arb, set )
    cpArbiter *arb
    cpContactPointSet *set

cpBool
cpArbiterIsFirstContact( arb )
    const cpArbiter *arb

cpBool
cpArbiterIsRemoval( arb )
    const cpArbiter *arb

int
cpArbiterGetCount( arb )
    const cpArbiter *arb

cpVect
cpArbiterGetNormal( arb )
    const cpArbiter *arb

cpVect
cpArbiterGetPointA( arb, i )
    const cpArbiter *arb
    int i

cpVect
cpArbiterGetPointB( arb, i )
    const cpArbiter *arb
    int i

cpFloat
cpArbiterGetDepth( arb, i )
    const cpArbiter *arb
    int i

cpBool
cpArbiterCallWildcardBeginA( arb, space )
    cpArbiter *arb
    cpSpace *space

cpBool
cpArbiterCallWildcardBeginB( arb, space )
    cpArbiter *arb
    cpSpace *space

cpBool
cpArbiterCallWildcardPreSolveA( arb, space )
    cpArbiter *arb
    cpSpace *space

cpBool
cpArbiterCallWildcardPreSolveB( arb, space )
    cpArbiter *arb
    cpSpace *space

void
cpArbiterCallWildcardPostSolveA( arb, space )
    cpArbiter *arb
    cpSpace *space

void
cpArbiterCallWildcardPostSolveB( arb, space )
    cpArbiter *arb
    cpSpace *space

void
cpArbiterCallWildcardSeparateA( arb, space )
    cpArbiter *arb
    cpSpace *space

void
cpArbiterCallWildcardSeparateB( arb, space )
    cpArbiter *arb
    cpSpace *space

