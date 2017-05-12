cpPolyShape *
cpPolyShapeAlloc(  )

cpPolyShape *
cpPolyShapeInit( poly, body, count, verts, transform, radius )
    cpPolyShape *poly
    cpBody *body
    int count
    cpVect *verts
    cpTransform transform
    cpFloat radius

cpPolyShape *
cpPolyShapeInitRaw( poly, body, count, verts, radius )
    cpPolyShape *poly
    cpBody *body
    int count
    cpVect *verts
    cpFloat radius

cpShape *
cpPolyShapeNew( body, count, verts, transform, radius )
    cpBody *body
    int count
    cpVect *verts
    cpTransform transform
    cpFloat radius

cpShape *
cpPolyShapeNewRaw( body, count, verts, radius )
    cpBody *body
    int count
    cpVect *verts
    cpFloat radius

cpPolyShape *
cpBoxShapeInit( poly, body, width, height, radius )
    cpPolyShape *poly
    cpBody *body
    cpFloat width
    cpFloat height
    cpFloat radius

cpPolyShape *
cpBoxShapeInit2( poly, body, box, radius )
    cpPolyShape *poly
    cpBody *body
    cpBB box
    cpFloat radius

cpShape *
cpBoxShapeNew( body, width, height, radius )
    cpBody *body
    cpFloat width
    cpFloat height
    cpFloat radius

cpShape *
cpBoxShapeNew2( body, box, radius )
    cpBody *body
    cpBB box
    cpFloat radius

int
cpPolyShapeGetCount( shape )
    cpShape *shape

cpVect
cpPolyShapeGetVert( shape, index )
    cpShape *shape
    int index

cpFloat
cpPolyShapeGetRadius( shape )
    cpShape *shape

