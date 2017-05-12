cpSegmentShape *
cpSegmentShapeAlloc()

cpVect
cpSegmentShapeGetA(shape)
	const cpShape *	shape

cpVect
cpSegmentShapeGetB(shape)
	const cpShape *	shape

cpVect
cpSegmentShapeGetNormal(shape)
	const cpShape *	shape

cpFloat
cpSegmentShapeGetRadius(shape)
	const cpShape *	shape

cpSegmentShape *
cpSegmentShapeInit(seg, body, a, b, radius)
	cpSegmentShape *	seg
	cpBody *	body
	cpVect	a
	cpVect	b
	cpFloat	radius

cpShape *
cpSegmentShapeNew(body, a, b, radius)
	cpBody *	body
	cpVect	a
	cpVect	b
	cpFloat	radius

void
cpSegmentShapeSetNeighbors(shape, prev, next)
	cpShape *	shape
	cpVect	prev
	cpVect	next

cpBB
cpShapeCacheBB(shape)
	cpShape *	shape

void
cpShapeDestroy(shape)
	cpShape *	shape

cpShapeFilter
cpShapeFilterNew(group, categories, mask)
    cpGroup group
    cpBitmask categories
    cpBitmask mask

void
cpShapeFree(shape)
	cpShape *	shape

cpFloat
cpShapePointQuery(shape, p, out)
	cpShape *	shape
    cpVect      p
    cpPointQueryInfo * out

cpBool
cpShapeSegmentQuery(shape, a, b, radius, info)
	cpShape *	shape
	cpVect	a
	cpVect	b
    cpFloat radius
	cpSegmentQueryInfo *	info

void
cpShapeSetBody(shape, body)
	cpShape *	shape
	cpBody *	body

cpBB
cpShapeUpdate(shape, transform)
	cpShape *	shape
    cpTransform transform

void
cpShapeSetFriction(shape, value)
    cpShape * shape
    cpFloat value

cpBB
cpShapeGetBB( shape )
    cpShape * shape
