void
cpMessage( condition, file, line, isError, isHardError, message, ... )
    char *condition
    char *file
    int line
    int isError
    int isHardError
    char *message

cpFloat
cpMomentForCircle( m, r1, r2, offset )
    cpFloat m
    cpFloat r1
    cpFloat r2
    cpVect offset

cpFloat
cpAreaForCircle( r1, r2 )
    cpFloat r1
    cpFloat r2

cpFloat
cpMomentForSegment( m, a, b, radius )
    cpFloat m
    cpVect a
    cpVect b
    cpFloat radius

cpFloat
cpAreaForSegment( a, b, radius )
    cpVect a
    cpVect b
    cpFloat radius

cpFloat
cpMomentForPoly( m, count, verts, offset, radius )
    cpFloat m
    int count
    cpVect *verts
    cpVect offset
    cpFloat radius

cpFloat
cpAreaForPoly( count, verts, radius )
    int count
    cpVect *verts
    cpFloat radius

cpVect
cpCentroidForPoly( count, verts )
    int count
    cpVect *verts

cpFloat
cpMomentForBox( m, width, height )
    cpFloat m
    cpFloat width
    cpFloat height

cpFloat
cpMomentForBox2( m, box )
    cpFloat m
    cpBB box

int
cpConvexHull( count, verts, result, first, tol )
    int count
    cpVect *verts
    cpVect *result
    int *first
    cpFloat tol

# EXPORTS:
# cpMessage
# cpMomentForCircle
# cpAreaForCircle
# cpMomentForSegment
# cpAreaForSegment
# cpMomentForPoly
# cpAreaForPoly
# cpCentroidForPoly
# cpMomentForBox
# cpMomentForBox2
# cpConvexHull
