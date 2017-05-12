INCLUDE: inc/cpSpatialIndex_custom.xsh



void
cpSpatialIndexFree(index)
	cpSpatialIndex *	index

cpSweep1D *
cpSweep1DAlloc()

cpSpatialIndex *
cpSweep1DInit(sweep, bbfunc, staticIndex)
	cpSweep1D *	sweep
	cpSpatialIndexBBFunc	bbfunc
	cpSpatialIndex *	staticIndex

cpSpatialIndex *
cpSweep1DNew(bbfunc, staticIndex)
	cpSpatialIndexBBFunc	bbfunc
	cpSpatialIndex *	staticIndex

void
cpSpatialIndexDestroy( index )
    cpSpatialIndex * index 

int
cpSpatialIndexCount( index )
    cpSpatialIndex * index

cpBool
cpSpatialIndexContains( index, obj, hashid )
    cpSpatialIndex * index
    void * obj
    cpHashValue hashid

void
cpSpatialIndexInsert( index, obj, hashid )
    cpSpatialIndex * index
    void * obj
    cpHashValue hashid

void
cpSpatialIndexCollideStatic(dynamicIndex, staticIndex, func, data)
    cpSpatialIndex * dynamicIndex
    cpSpatialIndex * staticIndex
    cpSpatialIndexQueryFunc func
    void * data

void
cpSpatialIndexRemove( index, obj, hashid )
    cpSpatialIndex * index
    void * obj
    cpHashValue hashid

void
cpSpatialIndexReindex( index )
    cpSpatialIndex * index

void
cpSpatialIndexReindexObject( index, obj, hashid )
    cpSpatialIndex * index
    void * obj
    cpHashValue hashid
