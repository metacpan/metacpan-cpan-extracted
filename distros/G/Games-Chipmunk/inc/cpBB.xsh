cpBB
cpBBNew(l, b, r, t)
    cpFloat l
    cpFloat b
    cpFloat r
    cpFloat t

cpBB
cpBBNewForExtents(c, hw, hh)
    cpVect c
    cpFloat hw
    cpFloat hh

cpBB
cpBBNewForCircle(p, r)
    cpVect p
    cpFloat r

cpBool
cpBBIntersects(a, b)
    cpBB a
    cpBB b

cpBool
cpBBContainsBB(bb, other)
    cpBB bb
    cpBB other

cpBool
cpBBContainsVect(bb, v)
    cpBB bb
    cpVect v

cpBB
cpBBMerge(a, b)
    cpBB a
    cpBB b

cpBB
cpBBExpand(bb, v)
    cpBB bb
    cpVect v

cpVect
cpBBCenter(bb)
    cpBB bb

cpFloat
cpBBArea(bb)
    cpBB bb

cpFloat
cpBBMergedArea(a, b)
    cpBB a
    cpBB b

cpFloat
cpBBSegmentQuery(bb, a, b)
    cpBB bb
    cpVect a
    cpVect b

cpBool
cpBBIntersectsSegment(bb, a, b)
    cpBB bb
    cpVect a
    cpVect b

cpVect
cpBBClampVect(bb, v)
    cpBB bb
    cpVect v

cpVect
cpBBWrapVect(bb, v)
    cpBB bb
    cpVect v

cpBB
cpBBOffset(bb, v)
    cpBB bb
    cpVect v
