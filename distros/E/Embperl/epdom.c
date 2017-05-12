/*###################################################################################
#
#   Embperl - Copyright (c) 1997-2008 Gerald Richter / ecos gmbh  www.ecos.de
#   Embperl - Copyright (c) 2008-2014 Gerald Richter
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: epdom.c 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################*/


#include "ep.h"
#include "epmacro.h"


/* --- don't use Perl's memory management here --- */

#ifndef DMALLOC
#undef malloc
#undef realloc
#undef strdup
#undef free
#endif


HV * pStringTableHash ;	    /* Hash to translate strings to index number */
HE * * pStringTableArray  ;   /* Array with pointers to strings */
static tStringIndex  * pFreeStringsNdx  ;   /* List of freed string indexes */


tDomTree * pDomTrees ;
static tIndexShort *   pFreeDomTrees ;

static int nMemUsage = 0 ;
static int numNodes  = 0 ;
static int numLevelLookup  = 0 ;
static int numLevelLookupItem  = 0 ;
static int numAttr   = 0 ;
static int numStr    = 0 ;
static int numReplace   = 0 ;

tIndex xNoName  = 0 ;
tIndex xDomTreeAttr = 0 ;
tIndex xDocument ;
tIndex xDocumentFraq ;
tIndex xOrderIndexAttr ;

static tUInt8 * MemFree[4196] ;
static tUInt8 * pMemLast = NULL ;
static tUInt8 * pMemEnd = NULL ;

struct tPad
    {
    tNodeData Nodes [1024] ;
    } ;

typedef struct tPad tPad ;

#define LEVELHASHSIZE 8

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* mydie                                                                    */
/*                                                                          */
/* Fatal Error                                                              */
/*                                                                          */
/* ------------------------------------------------------------------------ */

void mydie (/*in*/ tApp *  a,
                  char *  msg)
    {
    epaTHX_

    LogErrorParam (a, 9999, msg, "") ;
    puts (msg) ;
#ifdef EPDEBUG
#if defined (__GNUC__) && defined (__i386__)
    __asm__ ("int   $0x03\n") ;
#endif
#endif
    exit (1) ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Node memory management                                                   */
/*                                                                          */
/* ------------------------------------------------------------------------ */


#ifdef DMALLOC
tNodeData * dom_malloc_dbg (/*in*/ tApp * a,
                               size_t  nSize, int * pCounter,
                               char * fn, int l)
#else                              
tNodeData * dom_malloc (/*in*/ tApp * a,
                               size_t  nSize, int * pCounter)
#endif
    {
    epaTHX_
    int	    nFree = (nSize+7)>>3 ;
    void *  pNew ;
    
    if (nFree > sizeof (MemFree) / sizeof (void *))
	mydie (a, "Node to huge for dom_malloc") ;

    if ((pNew = MemFree[nFree]))
	{ /* --- take one entry off the free list --- */
	MemFree[nFree] = *((tUInt8 * *)pNew) ;
	(*pCounter)++ ;
	return pNew ;
	}
    
    nSize = nFree * 8 ; /* --- make dividable by 8 --- */
    if (pMemLast + nSize < pMemEnd)
	{ /* --- take space at the end of the pad --- */
	pNew = pMemLast ;
	pMemLast += nSize ;
	(*pCounter)++ ;
	return pNew ;
	}
    
    /* --- Pad full -> alloc new one --- */
    
#ifdef DMALLOC
    pMemLast = _malloc_leap(fn, l, sizeof (tPad)) ;
#else
    pMemLast = malloc(sizeof (tPad)) ;
#endif

    if (pMemLast == NULL)
        {
        char buf[256] ;
        sprintf (buf, "dom_malloc: Out of memory (%u bytes)", (unsigned int)sizeof (tPad)) ;
    	mydie (a, buf) ;
    	}
    	
    nMemUsage += sizeof (tPad) ;

    pMemEnd = pMemLast + sizeof (tPad) ;
    pNew = pMemLast ;
    pMemLast += nSize ;
    (*pCounter)++ ;
    return pNew ;
    }


#ifdef DMALLOC
#undef dom_malloc
#define dom_malloc(a,n,p) dom_malloc_dbg ((a),(n),(p),__FILE__,__LINE__)
#endif



void dom_free (/*in*/ tApp * a,
                      tNodeData * pNode, int * pCounter)
    {
    int	    nSize = sizeof (tNodeData) + pNode -> numAttr * sizeof (tAttrData) ;
    int	    nFree = (nSize+7)>>3 ;
    void *  pFree ;
    
    if (nFree > sizeof (MemFree) / sizeof (void *))
	mydie (a, "Node to huge for dom_malloc") ;

    /* --- add to the free list --- */
    pFree = MemFree[nFree] ;
    MemFree[nFree] = (tUInt8 *)pNode ;
    *((tUInt8 * *)pNode) = pFree ;
    (*pCounter)-- ;
    return ;
    }


void dom_free_size (/*in*/ tApp * a,
                           void * pNode, int nSize, int * pCounter)
    {
    int	    nFree = (nSize+7)>>3 ;
    void *  pFree ;
    
    if (nFree > sizeof (MemFree) / sizeof (void *))
	mydie (a, "Node to huge for dom_malloc") ;

    /* --- add to the free list --- */
    pFree = MemFree[nFree] ;
    MemFree[nFree] = (tUInt8 *)pNode ;
    *((tUInt8 * *)pNode) = pFree ;
    (*pCounter)-- ;
    return ;
    }



tNodeData *  dom_realloc (/*in*/ tApp * a,
                                 tNodeData * pNode, size_t  nSize)
    {
    int	    nOldSize = sizeof (tNodeData) + pNode -> numAttr * sizeof (tAttrData) ;
    tNodeData * pNew ;
    int n ;

    if (((tUInt8 *)pNode) + nOldSize == pMemLast)
	{ /* --- expand --- */
	if (((tUInt8 *)pNode) + nSize < pMemEnd)
	    { /* --- take space at the end of the pad --- */
	    pMemLast = ((tUInt8 *)pNode) + nSize ;
	    return pNode ;
	    }
	}
    
    pNew = dom_malloc (a, nSize, &n) ;
    memcpy (pNew, pNode, nOldSize) ;
    dom_free (a, pNode, &n) ;
    return pNew ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* general memory management                                                */
/*                                                                          */
/* ------------------------------------------------------------------------ */

void * str_malloc (/*in*/ tApp * a,
                          size_t  n)
    {
    epaTHX_
    void * m = malloc(n + sizeof (size_t)) ;
    size_t * m_size;
    if (m)
	{
	nMemUsage += n ;
	/* make the following in multiple step, so sun-cc is happy... */
	m_size = (size_t *) m;
	*m_size = n;
	m_size++;
	m = (void *) m_size ;
	}
    else
        {
        char buf[256] ;
	/*
        sprintf (buf, "%zu bytes", n) ;
        LogErrorParam (a, rcOutOfMemory, "str_malloc failed", buf) ;
        */
        sprintf (buf, "str_malloc: Out of memory (%u bytes)", (unsigned int)(n + sizeof (size_t))) ;
    	mydie (a, buf) ;
    	}

    return m ;
    }

#ifdef DMALLOC

void * str_malloc_dbg (/*in*/ tApp * a,
                              size_t  n, char * fn, int l)
    {
    epaTHX_
    void * m = _malloc_leap(fn, l, n + sizeof (size_t)) ;
    size_t * m_size;
    if (m)
	{
	nMemUsage += n ;
	/* make the following in multiple step, so sun-cc is happy... */
	m_size = (size_t *) m;
	*m_size = n;
	m_size++;
	m = (void *) m_size ;
	}
    else
        {
        char buf[256] ;
	/*
        sprintf (buf, "%zu bytes", n) ;
        LogErrorParam (a, rcOutOfMemory, "str_malloc_dbg failed", buf) ;
        */
        sprintf (buf, "str_malloc: Out of memory (%u bytes)", n + sizeof (size_t)) ;
    	mydie (a, buf) ;
    	}

    return m ;
    }

#endif

void * str_realloc (/*in*/ tApp * a,
                           void * s, size_t  n)
    {
    epaTHX_
    void * m = ((size_t *)s) - 1 ;
    size_t * m_size;
    nMemUsage -= *((size_t *)m) ;
    if ((m = realloc (m, n + sizeof (size_t))))
	{
	nMemUsage += n ;
	/* make the following in multiple step, so sun-cc is happy... */
	m_size = (size_t *) m;
	*m_size = n;
	m_size++;
	m = (void *) m_size ;
	}
    else
        {
        char buf[256] ;
	/*
        sprintf (buf, "%zu bytes", n) ;
        LogErrorParam (a, rcOutOfMemory, "str_realloc failed", buf) ;
        */
        sprintf (buf, "str_realloc: Out of memory (%u bytes)", (unsigned int)(n + sizeof (size_t))) ;
    	mydie (a, buf) ;
    	}
    
    return m ;
    }


#ifdef DMALLOC

void * str_realloc_dbg (/*in*/ tApp * a,
                               void * s, size_t  n, char * fn, int l)
    {
    epaTHX_
    void * m = ((size_t *)s) - 1 ;
    size_t * m_size;
    nMemUsage -= *((size_t *)m) ;
    if ((m = _realloc_leap (fn, l, m, n + sizeof (size_t))))
	{
	nMemUsage += n ;
	/* make the following in multiple step, so sun-cc is happy... */
	m_size = (size_t *) m;
	*m_size = n;
	m_size++;
	m = (void *) m_size ;
	}
    else
        {
        char buf[256] ;
	/*
        sprintf (buf, "%zu bytes", n) ;
        LogErrorParam (a, rcOutOfMemory, "str_realloc failed", buf) ;
        */
        sprintf (buf, "str_realloc: Out of memory (%u bytes)", n + sizeof (size_t)) ;
    	mydie (a, buf) ;
    	}

    return m ;
    }

#endif

void str_free (/*in*/ tApp * a,
                      void * s)
    {
    epaTHX_
    void * m = ((size_t *)s) - 1 ;
    nMemUsage -= *((size_t *)m) ;
    free (m) ;
    }






/* forward */
static int DomTree_free (pTHX_ SV * pSV, MAGIC * mg) ;





/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ArrayNew                                                                 */
/*                                                                          */
/*!
*
* \_en									   
*   Create a new dynamic array
*                                                                          
*   @param  pArray	    Pointer to pointer that will hold new array
*   @param  nAdd	    Number of items that should be added when array 
*			    must be extented
*   @param  nElementSize    Size of one element	     
* \endif                                                                       
*
* \_de									   
*   Erstellt eine neues dynamisches Array
*                                                                          
*   @param  pArray	    Zeiger auf den Zeiger der auf das neue Array zeigt
*   @param  nAdd	    Anzahl der Element die hinzugef?gt werden, wenn
*			    das Array vergr??ert werden mu?
*   @param  nElementSize    Gr??e eines Elements	     
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

#ifdef DMALLOC
int ArrayNew_dbg (/*in*/ tApp * a,
                  /*in*/ const tArray * pArray,
	      /*in*/ int	nAdd,
	      /*in*/ int	nElementSize,
	      /*in*/ char *     sFile,
	      /*in*/ int        nLine) 
#else
int ArrayNew (/*in*/ tApp * a,
              /*in*/ const tArray * pArray,
	      /*in*/ int	nAdd,
	      /*in*/ int	nElementSize)
#endif

    {
    struct tArrayCtrl * pNew ;
    
#ifdef DMALLOC
    if ((pNew = str_malloc_dbg (a, nAdd * nElementSize + sizeof (struct tArrayCtrl), sFile, nLine)) == NULL)
	return 0 ;
#else
    if ((pNew = str_malloc (a, nAdd * nElementSize + sizeof (struct tArrayCtrl))) == NULL)
	return 0 ;
#endif
    
    memset (pNew, 0, nAdd * nElementSize + sizeof (struct tArrayCtrl)) ; 
    *(void * *)pArray = (struct tArray *)(pNew + 1) ;
    pNew -> nMax = nAdd ;
    pNew -> nAdd = nAdd ;
    pNew -> nFill = 0  ;
    pNew -> nElementSize = nElementSize  ;
#ifdef DMALLOC
    strncpy (pNew -> sSig, "ARY  ", sizeof (pNew -> sSig)) ;
    pNew -> sFile = sFile ;
    pNew -> nLine = nLine ;
#endif
    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ArrayNewZero                                                             */
/*                                                                          */
/*!
*
* \_en									   
*   Create a new dynamic array and set it's content to all zero
*                                                                          
*   @param  pArray	    Pointer to pointer that will hold new array
*   @param  nAdd	    Number of items that should be added when array 
*			    must be extented
*   @param  nElementSize    Size of one element	     
* \endif                                                                       
*
* \_de									   
*   Erstellt eine neues dynamisches Array und setzt seinen Inhalt auf Null
*                                                                          
*   @param  pArray	    Zeiger auf den Zeiger der auf das neue Array zeigt
*   @param  nAdd	    Anzahl der Element die hinzugef?gt werden, wenn
*			    das Array vergr??ert werden mu?
*   @param  nElementSize    Gr??e eines Elements	     
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

#ifdef DMALLOC
int ArrayNewZero_dbg (/*in*/ tApp * a,
                      /*in*/ const tArray * pArray,
	      /*in*/ int	nAdd,
	      /*in*/ int	nElementSize,
	      /*in*/ char *     sFile,
	      /*in*/ int        nLine) 
#else
int ArrayNewZero (/*in*/ tApp * a,
                  /*in*/ const tArray * pArray,
	      /*in*/ int	nAdd,
	      /*in*/ int	nElementSize)
#endif

    {
    struct tArrayCtrl * pNew ;
    
#ifdef DMALLOC
    if ((pNew = str_malloc_dbg (a, nAdd * nElementSize + sizeof (struct tArrayCtrl), sFile, nLine)) == NULL)
	return 0 ;
#else
    if ((pNew = str_malloc (a, nAdd * nElementSize + sizeof (struct tArrayCtrl))) == NULL)
	return 0 ;
#endif
    
    memset (pNew, 0, nAdd * nElementSize + sizeof (struct tArrayCtrl)) ; 
    *(void * *)pArray = (struct tArray *)(pNew + 1) ;
    pNew -> nMax = nAdd ;
    pNew -> nAdd = nAdd ;
    pNew -> nFill = 0  ;
    pNew -> nElementSize = nElementSize  ;
#ifdef DMALLOC
    strncpy (pNew -> sSig, "ARY  ", sizeof (pNew -> sSig)) ;
    pNew -> sFile = sFile ;
    pNew -> nLine = nLine ;
#endif

    memset (pNew+1, 0, nAdd * nElementSize) ;

    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ArrayFree                                                                */
/*                                                                          */
/* Create a new dynamic array                                               */
/*                                                                          */
/* ------------------------------------------------------------------------ */

int ArrayFree (/*in*/ tApp * a,
               /*in*/ const tArray * pArray)


    {
    if ((*(void * *)pArray))
        {
        struct tArrayCtrl * pCtrl = ((struct tArrayCtrl *)(*(void * *)pArray)) - 1 ;

#ifdef DMALLOC
        if (strncmp (pCtrl -> sSig, "ARY  ", sizeof (pCtrl -> sSig)) != 0)
            {
            LogErrorParam (a, rcCleanupErr, "ArrayFree Signature", pCtrl -> sSig) ;
            }
        strncpy (pCtrl -> sSig, "ARYFR", sizeof (pCtrl -> sSig)) ;

#endif
        str_free (a, pCtrl) ;

        (*(void * *)pArray) = NULL ;
        }

    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ArrayClone                                                               */
/*                                                                          */
/* Create a new dynamic array as exact copy of old one                      */
/*                                                                          */
/* ------------------------------------------------------------------------ */

#ifdef DMALLOC
int ArrayClone_dbg (/*in*/ tApp * a,
                    /*in*/  const tArray * pOrgArray,
	        /*out*/ const tArray * pNewArray,	      
		/*in*/ char *     sFile,
		/*in*/ int        nLine) 
#else
int ArrayClone (/*in*/ tApp * a,
                /*in*/  const tArray * pOrgArray,
	        /*out*/ const tArray * pNewArray)
#endif

    {
    if (pOrgArray)
        {
        struct tArrayCtrl * pNew ;
        struct tArrayCtrl * pCtrl = ((struct tArrayCtrl *)(*(void * *)pOrgArray)) - 1 ;
        int    size = pCtrl -> nFill * pCtrl -> nElementSize + sizeof (struct tArrayCtrl) ;
    
#ifdef DMALLOC
	if ((pNew = str_malloc_dbg (a, size, sFile, nLine)) == NULL)
	    return 0 ;
#else
        if ((pNew = str_malloc (a, size)) == NULL)
	    return 0 ;
#endif
    
        memcpy (pNew, pCtrl, size) ; 
        *(void * *)pNewArray = (struct tArray *)(pNew + 1) ;
        pNew -> nMax = pCtrl -> nFill ;
        }
    else
        {
        *(void * *)pNewArray = NULL ;
        }
    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ArrayAdd                                                                 */
/*                                                                          */
/* Make space for numElements in Array and return index of first one        */
/*                                                                          */
/* ------------------------------------------------------------------------ */


int ArrayAdd (/*in*/ tApp * a,
              /*in*/ const tArray * pArray,
	      /*in*/ int	numElements)

    {
    struct tArrayCtrl * pCtrl = ((struct tArrayCtrl *)(*(void * *)pArray)) - 1 ;
    int	         nNdx ;


    if (pCtrl -> nFill + numElements > pCtrl -> nMax)
	{
	struct tArrayCtrl * pNew ;
	int		    nNewMax = pCtrl -> nFill + numElements + pCtrl -> nAdd ;
	
#ifdef DMALLOC
	if ((pNew = str_realloc_dbg (a, pCtrl, nNewMax * pCtrl -> nElementSize + sizeof (struct tArrayCtrl), pCtrl -> sFile, pCtrl -> nLine)) == NULL)
	    return 0 ;
#else	
	if ((pNew = str_realloc (a, pCtrl, nNewMax * pCtrl -> nElementSize + sizeof (struct tArrayCtrl))) == NULL)
	    return 0 ;
#endif	
	*(void * *)pArray = (struct tArray *)(pNew + 1) ;
	pNew -> nMax = nNewMax ;
	pCtrl = pNew ;
	}

    nNdx = pCtrl -> nFill ;
    pCtrl -> nFill += numElements ;
    return nNdx ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ArraySub								    */
/*                                                                          */
/* Remove numElemenets from the end of the array. Does not reallocate memory*/
/* Returns -1 if less then numElemenets are avialable			    */
/*									    */
/* ------------------------------------------------------------------------ */


int ArraySub (/*in*/ tApp * a,
              /*in*/ const tArray * pArray,
	      /*in*/ int	numElements)

    {
    struct tArrayCtrl * pCtrl = ((struct tArrayCtrl *)(*(void * *)pArray)) - 1 ;


    if (pCtrl -> nFill < numElements)
	return -1 ;
    else
	pCtrl -> nFill -= numElements ;

    return pCtrl -> nFill ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ArraySet                                                                 */
/*                                                                          */
/* Make space that at least numElements in the Array                        */
/*                                                                          */
/* ------------------------------------------------------------------------ */


int ArraySet (/*in*/ tApp * a,
              /*in*/ const tArray * pArray,
	      /*in*/ int	numElements)

    {
    struct tArrayCtrl * pCtrl = ((struct tArrayCtrl *)(*(void * *)pArray)) - 1 ;
    char *       p ;

    if (numElements > pCtrl -> nMax)
	{
	struct tArrayCtrl * pNew ;
	int		    nNewMax = pCtrl -> nFill + pCtrl -> nAdd ;

	if (nNewMax < numElements)
	    nNewMax = numElements + pCtrl -> nAdd ;
	
#ifdef DMALLOC
	if ((pNew = str_realloc_dbg (a, pCtrl, nNewMax * pCtrl -> nElementSize + sizeof (struct tArrayCtrl), pCtrl -> sFile, pCtrl -> nLine)) == NULL)
	    return 0 ;
#else	
	if ((pNew = str_realloc (a, pCtrl, nNewMax * pCtrl -> nElementSize + sizeof (struct tArrayCtrl))) == NULL)
            {
	    return 0 ;
            }
#endif
	
	p = (char *)(pNew + 1) ;
	*(void * *)pArray = (struct tArray *)p ;
	memset (p + pNew -> nMax * pNew -> nElementSize, 0, (nNewMax - pNew -> nMax) * pNew -> nElementSize) ; 
	pNew -> nMax = nNewMax ;
	pCtrl = pNew ;
	}

    return numElements ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ArraySetSize                                                             */
/*                                                                          */
/* Make space for exact numElements in the Array			    */
/*                                                                          */
/* ------------------------------------------------------------------------ */


int ArraySetSize (/*in*/ tApp * a,
                  /*in*/ const tArray * pArray,
	          /*in*/ int	numElements)

    {
    struct tArrayCtrl * pCtrl = ((struct tArrayCtrl *)(*(void * *)pArray)) - 1 ;

    if (numElements > pCtrl -> nMax)
	ArraySet (a, pArray, numElements) ;
    
    pCtrl -> nFill = numElements ;

    return numElements ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ArrayGetSize                                                             */
/*                                                                          */
/* Get size of Array							    */
/*                                                                          */
/* ------------------------------------------------------------------------ */


int ArrayGetSize (/*in*/ tApp *a,
                  /*in*/ const tArray * pArray)

    {
    struct tArrayCtrl * pCtrl = ((struct tArrayCtrl *)(pArray)) - 1 ;
    
    return pCtrl -> nFill  ;
    }



/* ------------------------------------------------------------------------ */
/*                                                                          */
/* StringNew                                                                */
/*                                                                          */
/* create a new string                                                      */
/*                                                                          */
/* ------------------------------------------------------------------------ */


#ifdef DMALLOC
void StringNew_dbg (/*in*/ tApp * a,
               /*in*/ char * * pArray,
	      /*in*/ int	nAdd,
	      /*in*/ char *     sFile,
	      /*in*/ int        nLine) 
#else
void StringNew (/*in*/ tApp * a,
                /*in*/ char * * pArray,
	      /*in*/ int	nAdd)
#endif

    {	      
    if ((*(void * *)pArray) == NULL)
#ifdef DMALLOC
	ArrayNew_dbg (a, pArray, nAdd, sizeof (char), sFile, nLine) ;
#else
	ArrayNew (a, pArray, nAdd, sizeof (char)) ;
#endif
    else
	ArraySetSize (a, pArray, 0);
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* StringFree                                                               */
/*                                                                          */
/* Free String memory                                                       */
/*                                                                          */
/* ------------------------------------------------------------------------ */


void StringFree (/*in*/ tApp * a,
                 /*in*/ char * * pArray)
	         

    {	      
    if ((*(void * *)pArray) != NULL)
	ArrayFree (a, pArray) ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* StringAdd                                                                */
/*                                                                          */
/* append to string                                                         */
/*                                                                          */
/* ------------------------------------------------------------------------ */


int StringAdd (/*in*/ tApp * a,
               /*in*/ char * *	   pArray,
	       /*in*/ const char * sAdd,
	       /*in*/ int 	   nLen)

    {	      
    int nIndex ;
    int nFill ;

    if (nLen == 0)
	nLen = strlen (sAdd) ;

    nFill = ArrayGetSize (a, *pArray) ;
    /* make sure we always have a trailing zero */
    ArraySet(a, pArray, nFill + nLen + 1) ;

    nIndex = ArrayAdd (a, pArray, nLen) ;

    memcpy ((*pArray)+nIndex, sAdd, nLen) ;
    
    return nIndex ;
    }




/* ------------------------------------------------------------------------ */
/*                                                                          */
/* String2Ndx                                                               */
/*                                                                          */
/* Convert String to an index, if string already exists return index of     */
/* existing string                                                          */
/*                                                                          */
/* ------------------------------------------------------------------------ */


tStringIndex String2NdxInc (/*in*/ tApp * a,
                            /*in*/ const char *	    sText,
			    /*in*/ int		    nLen,
			    /*in*/ int              bInc) 

    {
    epaTHX_
    SV * *  ppSV ;
    SV *    pSVKey ;
    SV *    pSVNdx ;
    HE *    pHEKey ;
    int	    nNdx ;
    

    if (sText == NULL)
	return 0 ;

    if ((ppSV = hv_fetch (pStringTableHash, (char *)sText, nLen, 0)) != NULL)
	{

	/*lprintf (a, "String2Ndx type=%d  iok=%d flg=%x\n", *ppSV?SvTYPE(*ppSV):-1, SvIOK (*ppSV), SvFLAGS(*ppSV)) ;*/

	if (*ppSV != NULL && SvIOKp (*ppSV)) /* use SvIOKp to avoid problems with tainting */
	    {
	    if (bInc)
		SvREFCNT_inc (*ppSV) ;
	    nNdx = SvIVX (*ppSV) ;
	    /*
	    if (nNdx < 6 || nNdx == 92)
	    	lprintf (a, "old string %s (#%d) refcnt=%d\n", Ndx2String (nNdx), nNdx, SvREFCNT(*ppSV)) ;
	    */
	    return nNdx ;
	    }
	}


    /* new string */
	
    nNdx = ArraySub (a, &pFreeStringsNdx, 1) ;
    if (nNdx != (tIndex)(-1))
	nNdx = pFreeStringsNdx[nNdx] ;
    else
	nNdx = ArrayAdd (a, &pStringTableArray, 1) ;
    
    pSVNdx = newSVivDBG1 (nNdx, sText) ;
    SvTAINTED_off (pSVNdx) ;

    if (bInc)
	SvREFCNT_inc (pSVNdx) ;  
    pSVKey = newSVpv (nLen?(char *)sText:"", nLen) ;
    pHEKey = hv_store_ent (pStringTableHash, pSVKey, pSVNdx, 0) ;
    SvREFCNT_dec (pSVKey) ;

    pStringTableArray[nNdx] = pHEKey ;

    numStr++ ;

    
    /*
    if (nNdx < 6 || nNdx == 124)
    	lprintf (a, "new string %s (#%d) refcnt=%d\n", Ndx2String (nNdx), nNdx, SvREFCNT(pSVNdx)) ;
    */

    return nNdx ;    
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* String2UniqueNdx                                                         */
/*                                                                          */
/* Convert String to an unique index                                        */
/* A string lookup will always return the index of the first string         */
/*                                                                          */
/*                                                                          */
/* ------------------------------------------------------------------------ */


tStringIndex String2UniqueNdx (/*in*/ tApp * a,
                               /*in*/ const char *	    sText,
  			       /*in*/ int		    nLen)
			    

    {
    epaTHX_
    SV *    pSVKey ;
    SV *    pSVNdx ;
    HE *    pHEKey ;
    int	    nNdx ;

    if (sText == NULL)
	return 0 ;

    /* new string */
	
    nNdx = ArraySub (a, &pFreeStringsNdx, 1) ;
    if (nNdx != (tIndex)(-1))
	nNdx = pFreeStringsNdx[nNdx] ;
    else
	nNdx = ArrayAdd (a, &pStringTableArray, 1) ;
    

    pSVKey = newSVpv (nLen?(char *)sText:"", nLen) ;
    pHEKey = hv_fetch_ent (pStringTableHash, pSVKey, 0, 0) ;

    if (!pHEKey)
	{
	pSVNdx = newSVivDBG1 (nNdx, sText) ;
	SvTAINTED_off (pSVNdx) ;
        SvREFCNT_inc (pSVNdx) ;
        pHEKey = hv_store_ent (pStringTableHash, pSVKey, pSVNdx, 0) ;
	}

    pStringTableArray[nNdx] = pHEKey ;

    numStr++ ;

    return nNdx ;    
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* NdxStringFree                                                            */
/*                                                                          */
/* Free one reference to a string                                           */
/*                                                                          */
/* ------------------------------------------------------------------------ */


void NdxStringFree (/*in*/ tApp * a,
                    /*in*/ tStringIndex		    nNdx)

    {
    epaTHX_
    HE *    pHE = pStringTableArray[nNdx] ;
    if (pHE)
    	{
        SV *    pSVNdx = HeVAL (pHE) ;
    
        SvREFCNT_dec (pSVNdx) ;

        /*
        if (nNdx < 6 || nNdx == 92)
    	   lprintf (a, "free string %s (#%d) refcnt=%d\n", Ndx2String (nNdx), nNdx, SvREFCNT(pSVNdx)) ;
        */

        
        if (SvREFCNT(pSVNdx) == 1)
	   {
	   int n ;
	
           /* lprintf (a, "delete string %s (#%d)\n", Ndx2String (nNdx), nNdx) ; */
	   hv_delete (pStringTableHash, HeKEY (pHE), HeKLEN(pHE), 0) ;
	   pStringTableArray[nNdx] = NULL ;
	   n = ArrayAdd (a, &pFreeStringsNdx, 1) ;
	   pFreeStringsNdx[n] = nNdx ;

	   numStr-- ;
	   }
	}	   
    }


#ifdef EPDEBUG

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* DEBUG support                                                            */
/*                                                                          */
/*                                                                          */
/*                                                                          */
/* ------------------------------------------------------------------------ */


#define ASSERT_DOMTREE_VALID(a,n) embperl_Assert_DomTree_Valid(a,n,"",__FILE__,__LINE__)
#define ASSERT_NODE_VALID(a,n) embperl_Assert_Node_Valid(a,n,"",__FILE__,__LINE__)
#define ASSERT_ATTR_VALID(a,n) embperl_Assert_Attr_Valid(a,n,NULL,"",__FILE__,__LINE__)

void embperl_Assert_Node_Valid (/*in*/tApp * a, tNodeData *pNode, char * prefix, char * fn, int line) ;


void embperl_Assert_DomTree_Valid (/*in*/tApp * a, tDomTree *pDomTree, char * prefix, char * fn, int line)

    {
    tDomTree * pLookupDomTree ;
    char buf[2048] ;
    
    if (!pDomTree)
        return ;

    if (pDomTree -> xNdx == 0)
        {
        sprintf(buf, "%s DomTree is deleted: %s(%d)\n", prefix, fn, line) ;
        mydie (NULL, buf) ;
        }

    
    pLookupDomTree = DomTree_self(pDomTree -> xNdx) ;
    if (pDomTree != pLookupDomTree)
        {
        sprintf(buf, "%sAddress of DomTree %d does not match Lookup Table: %s(%d)\n", prefix, pDomTree -> xNdx, fn, line) ;
        mydie (NULL, buf) ;
        }
    }

void embperl_Assert_Attr_Valid (/*in*/tApp * a, tAttrData *pAttr, tNodeData *pNode, char * prefix, char * fn, int line)

    {
    tAttrData * pLookupAttr ;
    tNodeData *pLookupNode ;
    tDomTree *pLookupDomTree ;
    char buf[2048] ;
    tIndex xFirstAttr ;
    
    if (!pAttr)
        return ;

    pLookupNode = Attr_selfNode (pAttr) ;
    pLookupDomTree = DomTree_self(pLookupNode -> xDomTree) ;
    pLookupAttr = Attr_self (pLookupDomTree, pAttr -> xNdx) ;
    if (pAttr != pLookupAttr)
        {
        sprintf(buf, "%sAddress of Attr %ld does not match Lookup Table: %s(%d)\n", prefix, pAttr -> xNdx, fn, line) ;
        mydie (NULL, buf) ;
        }

    if (pNode)
        {
        if (pNode != pLookupNode)
            {
            sprintf(buf, "%sAddress of Node of Attr (Node %ld DomTree %d) does not match Node: %s(%d)\n", prefix, pNode -> xNdx, pNode -> xDomTree, fn, line) ;
            mydie (NULL, buf) ;
            }

        }
    else
        {
        sprintf(buf, "%sAttr %ld: ", prefix, pAttr -> xNdx) ;
        embperl_Assert_Node_Valid(a,pLookupNode, buf, fn, line) ;
        }

    if (pAttr -> bFlags & aflgAttrChilds)
        {
        sprintf(buf, "%sAttr %ld aflgAttrChilds: ", prefix, pAttr -> xNdx) ;

        pLookupNode = Node_selfLevel (a, pLookupDomTree, pAttr -> xValue, pLookupNode -> nRepeatLevel) ;
    
        xFirstAttr = pLookupNode -> xNdx ;
   
        while (pLookupNode)
	    {
            embperl_Assert_Node_Valid(a,pLookupNode, buf, fn, line) ;

	    pLookupNode = Node_selfNextSibling (a, pLookupDomTree, pLookupNode, pLookupNode -> nRepeatLevel) ;
            if (pLookupNode)
                {
                if (pLookupNode -> xNdx == xFirstAttr )
                    {
                    sprintf(buf, "%sAttr %ld aflgAttrChilds FirstNode found second time %ld", prefix, pAttr -> xNdx, pLookupNode -> xNdx) ;
                    mydie (a, buf) ;                
                    }
                }
	    }
        }
    }


void embperl_Assert_Node_Valid (/*in*/tApp * a, tNodeData *pNode, char * prefix, char * fn, int line)

    {
    tDomTree * pDomTree  ;
    tNodeData *pLookupNode ;
    tNodeData *pFirstChild ;
    tAttrData *pAttr ;
    int       n ;
    char buf[2048] ;
    
    if (!pNode)
        return ;
    
    
    n = ArrayGetSize (a, pDomTrees) ;
    if (pNode -> xDomTree >= n || pNode -> xDomTree < 0)
        {
        sprintf(buf, "%s DomTree %d out of range (max=%d): %s(%d)\n", prefix, pNode -> xDomTree, n, fn, line) ;
        mydie (NULL, buf) ;
        }


    pDomTree    = DomTree_self (pNode -> xDomTree) ;
    sprintf(buf, "%sDomTree of Node %ld DomTree %d: ", prefix, pNode -> xNdx, pNode -> xDomTree) ;
    embperl_Assert_DomTree_Valid(a,pDomTree, buf, fn, line) ;

    pLookupNode = Node_selfLevel(a, pDomTree, pNode -> xNdx, pNode -> nRepeatLevel) ;
    if (pNode != pLookupNode)
        {
        sprintf(buf, "%sAddress of Node %ld DomTree %d does not match Lookup Table: %s(%d)\n", prefix, pNode -> xNdx, pNode -> xDomTree, fn, line) ;
        mydie (NULL, buf) ;
        }

    
    if (pNode -> xChilds && pNode -> nType != ntypDocumentFraq  && pNode -> nType != ntypDocument)
        {            
        tIndex xNull = xNode_selfLevelNull(pDomTree, pNode) ;
        pLookupNode = Node_self(pDomTree, xNull) ;
        pFirstChild = Node_selfLevel(a, pDomTree, pNode -> xChilds, pNode -> nRepeatLevel) ;
        if (pFirstChild -> xParent != pNode -> xNdx && pFirstChild -> xParent != xNull) 
            {
            sprintf(buf, "%sParent (xParent=%ld) of first Child (Node %ld DomTree %d) does not point to myself (Node %ld DomTree %d NullNode=%ld): %s(%d)\n", 
                prefix, pFirstChild -> xParent, pFirstChild -> xNdx, pFirstChild -> xDomTree, pNode -> xNdx, pNode -> xDomTree, 
                xNull, fn, line) ;
            mydie (NULL, buf) ;
            }

        if (pNode -> nRepeatLevel > 0 && pFirstChild -> xParent != pNode -> xNdx)
            {
            tNodeData * pParent = Node_selfLevel(a, pDomTree, pFirstChild -> xParent, pNode -> nRepeatLevel) ;
            if (pNode != pParent )
                {
                sprintf(buf, "%sLevel %d Level Parent of first Child (Node %ld DomTree %d) does not point to myself (Node %ld) but to Node %ld: %s(%d)\n", 
                    prefix, pNode -> nRepeatLevel, pFirstChild -> xNdx, 
                    pFirstChild -> xDomTree, pNode -> xNdx, pParent -> xNdx, fn, line) ;
                mydie (NULL, buf) ;
                }
            

            }
        }

    if (!*prefix && pNode -> xParent)
        {            
        sprintf(buf, "%sParent of Node %ld DomTree %d: ", prefix, pNode -> xNdx, pNode -> xDomTree) ;
        pLookupNode = Node_selfLevel(a, pDomTree, pNode -> xParent, pNode -> nRepeatLevel) ;
        
        if (pLookupNode -> nType == ntypAttr)
            embperl_Assert_Attr_Valid(a, (tAttrData *)pLookupNode, NULL, buf, fn, line) ;
        else
            embperl_Assert_Node_Valid(a, pLookupNode, buf, fn, line) ;
        }    

    if (!*prefix && pNode -> xNext)
        {            
        sprintf(buf, "%sNext of Node %ld DomTree %d: ", prefix, pNode -> xNdx, pNode -> xDomTree) ;
        pLookupNode = Node_selfLevel(a, pDomTree, pNode -> xNext, pNode -> nRepeatLevel) ;
        embperl_Assert_Node_Valid(a,pLookupNode, buf, fn, line) ;
        }    
    
    if (!*prefix && pNode -> xPrev)
        {            
        sprintf(buf, "%sPrev of Node %ld DomTree %d: ", prefix, pNode -> xNdx, pNode -> xDomTree) ;
        pLookupNode = Node_selfLevel(a, pDomTree, pNode -> xPrev, pNode -> nRepeatLevel) ;
        embperl_Assert_Node_Valid(a,pLookupNode, buf, fn, line) ;
        }    
    
    pAttr = (tAttrData * )(pNode + 1) ;
    n     = pNode -> numAttr ;

    sprintf(buf, "%sAttr of Node %ld DomTree %d: ", prefix, pNode -> xNdx, pNode -> xDomTree) ;
    while (n)
	{
        embperl_Assert_Attr_Valid(a,pAttr, pNode, buf, fn, line) ;
        n-- ;
	pAttr++ ;
	}
    
    }




#else
#define ASSERT_DOMTREE_VALID(a,n)
#define ASSERT_NODE_VALID(a,n)
#define ASSERT_ATTR_VALID(a,n)
#endif

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* DomInit                                                                  */
/*                                                                          */
/*                                                                          */
/*                                                                          */
/* ------------------------------------------------------------------------ */


int DomInit (/*in*/ tApp * a)

    {
    epaTHX_
    SV *    pSVKey ;
    SV *    pSVNdx ;
    HE *    pHEKey ;
    

    tNodeData testnode ;
    tAttrData testattr ;

    if (((char *)(&testnode.nType) - (char *)&testnode) !=
            ((char *)(&testattr.nType) - (char *)&testattr))
        {
        mydie (a, "Attr.nType and Node.nType are not at the same offset. There is a problem with the typedefinitions in epdom.h") ;
        }
    
    if (((char *)(&testnode.xNdx) - (char *)&testnode) !=
            ((char *)(&testattr.xNdx) - (char *)&testattr))
        {
        mydie (a, "Attr.xNdx and Node.xNdx are not at the same offset. There is a problem with the typedefinitions in epdom.h") ;
        }
    
    if (((char *)(&testnode.xChilds) - (char *)&testnode) !=
            ((char *)(&testattr.xValue) - (char *)&testattr))
        {
        mydie (a, "Attr.xValue and Node.xChilds are not at the same offset. There is a problem with the typedefinitions in epdom.h") ;
        }
    
    if (sizeof(testnode.xChilds) != sizeof (testattr.xValue))
        {
        mydie (a, "Attr.xValue and Node.xChilds do not have the same size. There is a problem with the typedefinitions in epdom.h") ;
        }
    
    pStringTableHash = newHV () ;

    ArrayNew (a, &pStringTableArray, 256, sizeof (HE *)) ; 
    ArrayNew (a, &pFreeStringsNdx, 256, sizeof (tStringIndex *)) ; 

    ArrayAdd (a, &pStringTableArray, 2) ;
    /* NULL */
    pSVNdx = newSViv (0) ;
    SvREFCNT_inc (pSVNdx) ;  
    pSVKey = newSVpv ("", 0) ;
    pHEKey = hv_store_ent (pStringTableHash, pSVKey, pSVNdx, 0) ;
    pStringTableArray[0] = pHEKey ;

    /* "" */
    pSVNdx = newSViv (1) ;
    SvREFCNT_inc (pSVNdx) ;  
    pSVKey = newSVpv ("", 0) ;
    pHEKey = hv_store_ent (pStringTableHash, pSVKey, pSVNdx, 0) ;
    pStringTableArray[1] = pHEKey ;

    numStr+=2 ;

    xNoName       = String2Ndx (a, "<noname>", 8) ;
    xDomTreeAttr  = String2Ndx (a, "<domtree>", 9) ;
    xDocument     = String2Ndx (a, "Document", 8) ;
    xDocumentFraq = String2Ndx (a, "DocumentFraq", 12) ;
    xOrderIndexAttr   = String2Ndx (a, "<orderindex>", 10) ;

    ArrayNew (a, &pDomTrees, 64, sizeof (tDomTree)) ; 
    ArrayAdd (a, &pDomTrees, 1) ;
    memset (&pDomTrees[0], 0, sizeof (tDomTree)) ;
    ArrayNew (a, &pFreeDomTrees, 64, sizeof (tIndex)) ;

    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* DomStats                                                                 */
/*                                                                          */
/* print statistics                                                         */
/*                                                                          */
/* ------------------------------------------------------------------------ */


void DomStats (/*in*/ tApp * a)

    {
    lprintf (a, "[%d]PERF: DOMSTAT: MemUsage = %d Bytes  numNodes = %d  numLevelLookup = %d  numLevelLookupItem = %d  numStr = %d  numReplace = %d  \n", a -> pThread -> nPid, nMemUsage, numNodes, numLevelLookup, numLevelLookupItem, numStr, numReplace) ;
#ifdef DMALLOC
        dmalloc_message ("[%d]PERF: DOMSTAT: MemUsage = %d Bytes  numNodes = %d  numLevelLookup = %d  numLevelLookupItem = %d  numStr = %d  numReplace = %d  \n", a -> pThread  -> nPid, nMemUsage, numNodes, numLevelLookup, numLevelLookupItem, numStr, numReplace) ;
#endif        
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* DomTree_alloc							    */
/*                                                                          */
/* Alloc storage for a new DomTree and associate it with a SV. deleteing    */
/* the SV will delete the DomTree  also 				    */
/*                                                                          */
/* ------------------------------------------------------------------------ */

MGVTBL DomTree_mvtTab = { NULL, NULL, NULL, NULL, DomTree_free } ;


tDomTree * DomTree_alloc (tApp * a)

    {
    tDomTree * pDomTree ;
    tIndexShort     n ;
    SV *       pSV ;
    struct magic * pMagic ;
    epaTHX_

    n = ArraySub (a, &pFreeDomTrees, 1) ;
    if (n != (tIndex)(-1))
	n = pFreeDomTrees[n] ;
    else
	n = ArrayAdd (a, &pDomTrees, 1) ;
    pDomTree = DomTree_self (n) ;

    memset (pDomTree, 0, sizeof (*pDomTree)) ;
    
    pSV = newSViv (n) ;
    sv_magic (pSV, pSV, 0, NULL, n) ;
    pMagic = mg_find (pSV, 0) ;

    if (pMagic)
	pMagic -> mg_virtual = &DomTree_mvtTab ;
    else
        {
        LogErrorParam (a, rcMagicError, "", "") ;
        }

    pDomTree -> pDomTreeSV = pSV ;
    pDomTree -> xNdx = n ;
    pDomTree -> xSourceNdx = n ;


    return pDomTree ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* DomTree_new                                                              */
/*                                                                          */
/*                                                                          */
/*                                                                          */
/* ------------------------------------------------------------------------ */

int DomTree_new (/*in*/ tApp * a,
                        tDomTree * * pNewLookup)

    {
    epaTHX_
    tDomTree * pDomTree ;
    pDomTree = DomTree_alloc (a) ;

    ArrayNew (a, &pDomTree -> pLookup, 256, sizeof (tLookupItem)) ; 
    ArrayAdd (a, &pDomTree -> pLookup, 1) ;

    pDomTree -> pCheckpoints = NULL ;
    pDomTree -> pDependsOn = newAV () ;

    *pNewLookup = pDomTree  ;

    return pDomTree -> xNdx ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* DomTree_dodelete							      */
/*                                                                          */
/* Frees all memory allocated by this DomTree				    */
/*                                                                          */
/* ------------------------------------------------------------------------ */

static int DomTree_dodelete (/*in*/ tApp * a, tDomTree * pDomTree)

    {
    epaTHX_
    tLookupItem * pLookup = pDomTree -> pLookup ;
    int        numLookup  ;
    tIndexShort     xDomTree  = pDomTree -> xNdx ;
    tIndex     xNdx ;
    tIndex     xNode = -1 ;
    tRepeatLevelLookup * pLookupLevelNode  ;
    tRepeatLevelLookupItem * pLookupLevelNodeLevel  ;
    tRepeatLevelLookupItem * pItem  ;
    tRepeatLevelLookupItem * pNext  ;
    int n ;


    if ((a -> pCurrReq?a -> pCurrReq -> Component.Config.bDebug:a -> Config.bDebug) & dbgDOM)
	lprintf (a, "[%d]Delete: DomTree = %d SVs=%d\n", a -> pThread -> nPid, pDomTree -> xNdx, sv_count) ; 

    if (!xDomTree)
	{
	if ((a -> pCurrReq?a -> pCurrReq -> Component.Config.bDebug:a -> Config.bDebug) & dbgDOM)
	    lprintf (a, "[%d]Delete: Already deleted DomTree = %d SVs=%d\n", a -> pThread -> nPid, pDomTree -> xNdx, sv_count) ; 
	return ok ;
	}
    
    numLookup = ArrayGetSize (a, pLookup) ;
    pLookup += numLookup - 1 ;
    while (numLookup-- > 0)
	{
	tNodeData * pNode = pLookup -> pLookup ;
	
	if (pNode && pNode -> nType != (tNodeType)ntypAttr && xDomTree == pNode -> xDomTree)
	    {
	    /* lprintf (a, "delete typ=%d  Pad  xNdx=%d\n", pPad -> nType, pPad -> xNdx) ; */

	    int n = pNode -> numAttr ;
	    tAttrData * pAttr = Node_selfFirstAttr(pNode) ;

	    while (n--)
		{
		/* pDomTree -> pLookup[pAttr -> xNdx] = NULL ; */
		if (pAttr -> bFlags)
		    {
		    if (pAttr -> xName)
			NdxStringFree (a, pAttr -> xName) ;
		    if (pAttr -> xValue && (pAttr -> bFlags & aflgAttrValue))
			NdxStringFree (a, pAttr -> xValue) ;
		    }
		pAttr++ ;
		}
	    /* lprintf (a, "delete typ=%d  Node xNdx=%d\n", pNode -> nType, pNode -> xNdx) ; */
	    /* pDomTree -> pLookup[pNode -> xNdx] = NULL ; */
	    if (pNode -> nText)
		NdxStringFree (a, pNode -> nText) ;
	    
	    xNode = pNode -> xNdx ;
	    dom_free (a, pNode, &numNodes) ;
	    }
	else
            {
            xNode = -1 ;
            pNode = NULL ;
            }

	if ((pLookupLevelNode = pLookup ->  pLookupLevel) && (pLookupLevelNode -> xNullNode == xNode || pNode == NULL))
	    {
	    pLookupLevelNodeLevel = pLookupLevelNode -> items ;
	    n = pLookupLevelNode -> numItems ;
	    while (n-- > 0)
		{
		pNext = pLookupLevelNodeLevel -> pNext ;
		while (pNext)
		    {
		    pItem = pNext ;
		    pNext = pItem -> pNext ;
		    dom_free_size (a, pItem, sizeof (tRepeatLevelLookupItem), &numLevelLookupItem) ;
		    }
		pLookupLevelNodeLevel++ ;
		}

	    dom_free_size (a, pLookupLevelNode, sizeof (tRepeatLevelLookup)  + sizeof (tRepeatLevelLookupItem) * (pLookupLevelNode -> numItems - 1), &numLevelLookup) ;
	    }


	pLookup-- ;
	}


    ArrayFree (a, &pDomTree -> pLookup) ;
    ArrayFree (a, &pDomTree -> pCheckpoints) ;
    
    if (pDomTree -> pSV)
	SvREFCNT_dec (pDomTree -> pSV) ;

    if (pDomTree -> pDependsOn)
	{
        /*
        int i ;

        for (i = 0 ; i <= AvFILL (pDomTree -> pDependsOn); i++)
	    {
	    SV * pSV = *av_fetch (pDomTree -> pDependsOn, i, 0) ;
            lprintf (a, "pDependsOn DomTree #%d type = %d cnt=%d n=%d\n", i, SvTYPE(pSV), SvREFCNT(pSV), SvIVX(pSV)) ;
	    }
        */

	av_clear (pDomTree -> pDependsOn) ;
	
        SvREFCNT_dec (pDomTree -> pDependsOn) ;
	}
	
    xNdx = ArrayAdd (a, &pFreeDomTrees, 1) ;
    pDomTree -> xNdx = 0 ;
    pFreeDomTrees[xNdx] = xDomTree ;

#if defined (_MDEBUG) && defined (WIN32)
    _ASSERTE( _CrtCheckMemory( ) );
#endif

    return ok ;    
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* DomTree_free 							    */
/*                                                                          */
/* Frees all memory allocated by this DomTree				    */
/* Do not call directly. Is called by Perl when RefCnt goes to zero	    */
/*                                                                          */
/*                                                                          */
/* ------------------------------------------------------------------------ */


static int DomTree_free (pTHX_ SV * pSV, MAGIC * mg)

    {
    if (mg && mg -> mg_len && !PL_in_clean_all)
        return DomTree_dodelete (CurrApp, DomTree_self (mg -> mg_len)) ;
    else
        return ok ;    
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* DomTree_delete							    */
/*                                                                          */
/* Frees all memory allocated by this DomTree				    */
/*                                                                          */
/* ------------------------------------------------------------------------ */

int DomTree_delete (/*in*/ tApp * a, tDomTree * pDomTree)

    {
    epaTHX_
    SvREFCNT_dec (pDomTree -> pDomTreeSV) ;
    return ok ;
    }

    
/* ------------------------------------------------------------------------ */
/*                                                                          */
/* DomTree_clone                                                            */
/*                                                                          */
/*                                                                          */
/*                                                                          */
/* ------------------------------------------------------------------------ */

int DomTree_clone (/*in*/ tApp * a, 
                   /*in*/ tDomTree *	pOrgDomTree,
		   /*out*/tDomTree * *  pNewDomTree,
		   /*in*/ int           bForceDocFraq)

    {
    epaTHX_
    tDomTree * pDomTree ;
    tNodeData * pDocument ;
    tIndex      xOrgDomTree = pOrgDomTree -> xNdx ; 
    
    	
    pDomTree = DomTree_alloc (a) ;
    pDomTree -> pDependsOn = newAV () ;
    pOrgDomTree = DomTree_self (xOrgDomTree) ; /* relookup in case it has moved */
    
    pDomTree -> xDocument = pOrgDomTree -> xDocument ;
    pDomTree -> xSourceNdx= pOrgDomTree -> xNdx ;
    if ((a -> pCurrReq?a -> pCurrReq -> Component.Config.bDebug:a -> Config.bDebug) & dbgDOM)
	lprintf (a, "[%d]DOM: DomTree %d depends on DomTree %d\n", a -> pThread -> nPid, pDomTree -> xNdx, pOrgDomTree -> xNdx) ; 
    av_push (pDomTree -> pDependsOn, SvREFCNT_inc (pOrgDomTree -> pDomTreeSV)) ;
    pDomTree -> xFilename = pOrgDomTree -> xFilename ;

    ArrayClone (a, &pOrgDomTree -> pLookup, &pDomTree -> pLookup) ; 
    ArrayClone (a, &pOrgDomTree -> pCheckpoints, &pDomTree -> pCheckpoints) ; 

    if ((pDomTree -> pSV = pOrgDomTree -> pSV))
        SvREFCNT_inc (pDomTree -> pSV) ;

    pDocument = Node_self (pDomTree, pDomTree -> xDocument) ;
    
    if (bForceDocFraq || pDocument -> nType == ntypDocumentFraq)
	{
	tAttrData * pAttr; 
	pDocument = Node_selfCloneNode (a, pDomTree, pDocument, 0, 1) ;
	pAttr = Element_selfSetAttribut (a, pDomTree, pDocument, 0, NULL, xDomTreeAttr, (char *)&pDomTree -> xNdx, sizeof (pDomTree -> xNdx)) ;
	pAttr -> bFlags = aflgOK ; /* reset string value flag */
	pDomTree -> xDocument = pDocument -> xNdx ;
	pDocument -> nType = ntypDocumentFraq ;
	if (pDocument -> nText != xDocumentFraq)
	    {
	    NdxStringFree (a, pDocument -> nText) ;
	    pDocument -> nText = xDocumentFraq ;
	    NdxStringRefcntInc (a, xDocumentFraq) ;
	    }
	}
    

    *pNewDomTree = pDomTree  ;

    return pDomTree -> xNdx ;
    }

/*---------------------------------------------------------------------------
* DomTree_checkpoint                                                       
*/
/*!
*
* \_en									   
* Compare checkpoint from program execution with list build during        
* compilation and change the DomTree and repeat level according to the     
* program flow                                                            
*                                                                          
* @param   r               Embperl request data                            
* @param   xDomTree	   current DomTree we are working on              
* @param   nRunCheckpoint  Number of checkpoint that was just executed     
* \endif                                                                       
*
* \_de									   
* Vergeleicht den Checkpoint von der Programmausf?hrung mit dem Checkpoint 
* beim Compilieren und ?ndert den DomTree entsprechend dem Programmflu? ab 
*                                                                          
* @param   r               Embperl Requestdaten                            
* @param   xDomTree	   akuteller DomTree der bearbeitet wird          
* @param   nRunCheckpoint  Nummer des Checkpoints der gerade abgearbeitet  
*                          wurde                                           
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

void DomTree_checkpoint (tReq * r, tIndex nRunCheckpoint)


    {
    epTHX_
    tApp * a = r -> pApp ;
    tIndex nCompileCheckpoint = r -> Component.nCurrCheckpoint ;
    tDomTree * pDomTree = DomTree_self (r -> Component.xCurrDomTree) ;
    tDomTreeCheckpoint * pCheckpoints = pDomTree -> pCheckpoints ;
    tDomTreeCheckpointStatus * pCheckpointStatus =  &pDomTree -> pCheckpointStatus[nRunCheckpoint] ;

    if (r -> Component.nPhase  != phRun)
        return ;
    
    if (!pDomTree -> xDocument)
        {
        /* first checkpoint in sub -> set xDocument */
        tNodeData * pDocument ;
        tAttrData * pAttr ;

        if ((a -> pCurrReq?a -> pCurrReq -> Component.Config.bDebug:a -> Config.bDebug) & dbgCheckpoint)
            lprintf (a, "[%d]Checkpoint: Start Sub DomTree=%d xx -> %d SVs=%d\n", a -> pThread -> nPid, r -> Component.xCurrDomTree, nRunCheckpoint, sv_count) ; 
        
        pDomTree -> xDocument = pCheckpoints[nRunCheckpoint].xNode ;
        
        pDocument = Node_self (pDomTree, pDomTree -> xDocument) ;
	pAttr = Element_selfSetAttribut (a, pDomTree, pDocument, 0, NULL, xDomTreeAttr, (char *)&pDomTree -> xNdx, sizeof (pDomTree -> xNdx)) ;
	pAttr -> bFlags = aflgOK ; /* reset string value flag */
        pDocument = Node_self (pDomTree, pDomTree -> xDocument) ;
	pDocument -> nType = ntypDocumentFraq ;
	if (pDocument -> nText != xDocumentFraq)
	    {
	    NdxStringFree (a, pDocument -> nText) ;
	    pDocument -> nText = xDocumentFraq ;
	    NdxStringRefcntInc (a, xDocumentFraq) ;
	    }
        
        r -> Component.nCurrCheckpoint = nRunCheckpoint+1 ;
        r -> Component.nCurrRepeatLevel = 0 ;
        return ;
        }

    r -> Component.bSubNotEmpty = 1 ;

    pCheckpointStatus -> nRepeatLevel       = r -> Component.nCurrRepeatLevel ;
    pCheckpointStatus -> nCompileCheckpoint = nCompileCheckpoint ;
    pCheckpointStatus -> xJumpFromNode      = 0 ;

    if (nRunCheckpoint == nCompileCheckpoint)
        {
        if (pCheckpoints[nCompileCheckpoint].xNode != -1)
	    {
	    tNodeData * pCompileNode = Node_selfLevel (a, pDomTree, pCheckpoints[nCompileCheckpoint].xNode, r -> Component.nCurrRepeatLevel) ;
	    tNodeData * pPrevNode    = Node_selfPreviousSibling (a, pDomTree, pCompileNode, r -> Component.nCurrRepeatLevel) ;

	    if (pPrevNode && pPrevNode -> xNext != pCompileNode -> xNdx)
		{
		pPrevNode = Node_selfCondCloneNode (a, pDomTree, pPrevNode, r -> Component.nCurrRepeatLevel) ;
		pPrevNode -> xNext = pCompileNode -> xNdx ;
                if ((a -> pCurrReq?a -> pCurrReq -> Component.Config.bDebug:a -> Config.bDebug) & dbgCheckpoint)
	        lprintf (a, "[%d]Checkpoint: end of loop DomTree=%d Index=%d Node=%d(%d) RepeatLevel=%d Line=%d -> Index=%d Node=%d(%d) Line=%d SVs=%d\n", 
			    a -> pThread -> nPid, r -> Component.xCurrDomTree, 
			    nCompileCheckpoint, pPrevNode -> xNdx, xNode_selfLevelNull(pDomTree,pPrevNode), r -> Component.nCurrRepeatLevel, pPrevNode -> nLinenumber, 
			    nRunCheckpoint,     pCompileNode -> xNdx, xNode_selfLevelNull(pDomTree,pCompileNode), pCompileNode -> nLinenumber, sv_count) ; 
		}
	    }

        if ((a -> pCurrReq?a -> pCurrReq -> Component.Config.bDebug:a -> Config.bDebug) & dbgCheckpoint)
	    lprintf (a, "[%d]Checkpoint: ok DomTree=%d %d -> %d SVs=%d\n", a -> pThread -> nPid, r -> Component.xCurrDomTree, nCompileCheckpoint, nRunCheckpoint, sv_count) ; 
        r -> Component.nCurrCheckpoint++ ;
        return ;
        }

    if (nRunCheckpoint > nCompileCheckpoint)
        {
        tNodeData * pCompileNode = Node_selfLevel (a, pDomTree, pCheckpoints[nCompileCheckpoint].xNode, r -> Component.nCurrRepeatLevel) ;
        if (pCheckpoints[nRunCheckpoint].xNode == -1)
            {
            pCompileNode = Node_selfCondCloneNode (a, pDomTree, pCompileNode , r -> Component.nCurrRepeatLevel) ;
	    pCompileNode -> bFlags |= nflgStopOutput ;
            if ((a -> pCurrReq?a -> pCurrReq -> Component.Config.bDebug:a -> Config.bDebug) & dbgCheckpoint)
		    lprintf (a, "[%d]Checkpoint: stop output DomTree=%d Index=%d Node=%d(%d) Line=%d\n", 
			    a -> pThread -> nPid, r -> Component.xCurrDomTree, nCompileCheckpoint, 
			    pCompileNode -> xNdx,  xNode_selfLevelNull(pDomTree,pCompileNode), 
			    pCompileNode -> nLinenumber) ;
            return ;
            }
        else
            {            
            tNodeData * pRunNode     = Node_selfLevel (a, pDomTree, pCheckpoints[nRunCheckpoint].xNode, r -> Component.nCurrRepeatLevel) ;
            tNodeData * pPrevNode    = Node_selfPreviousSibling (a, pDomTree, pCompileNode, r -> Component.nCurrRepeatLevel) ;
        
            tNodeData * pCompileParent = NodeAttr_selfParentNode (pDomTree, pCompileNode, r -> Component.nCurrRepeatLevel) ;
            tNodeData * pRunParent     = NodeAttr_selfParentNode (pDomTree, pRunNode, r -> Component.nCurrRepeatLevel) ;

            if (pPrevNode)
                pPrevNode = Node_selfCondCloneNode (a, pDomTree, pPrevNode, r -> Component.nCurrRepeatLevel) ;
            else
                {
                pPrevNode = Node_selfCondCloneNode (a, pDomTree, pCompileNode, r -> Component.nCurrRepeatLevel) ;
                pPrevNode -> bFlags |= nflgIgnore ;
                }

            if (pCompileParent  -> xNdx == pRunParent -> xNdx )
                {
                pRunNode = Node_selfCondCloneNode (a, pDomTree, pRunNode, r -> Component.nCurrRepeatLevel) ;
        
                pRunNode -> xPrev = pPrevNode -> xNdx ;
                pPrevNode -> xNext = pRunNode -> xNdx ;
	        pRunNode -> bFlags  |= nflgNewLevelPrev ;
	        pPrevNode -> bFlags |= nflgNewLevelNext ;

                if ((a -> pCurrReq?a -> pCurrReq -> Component.Config.bDebug:a -> Config.bDebug) & dbgCheckpoint)
		        lprintf (a, "[%d]Checkpoint: jump forward DomTree=%d Index=%d Node=%d(%d) Line=%d -> Index=%d Node=%d(%d) Line=%d SVs=%d\n", 
			        a -> pThread -> nPid, r -> Component.xCurrDomTree, nCompileCheckpoint, 
			        pPrevNode -> xNdx,  xNode_selfLevelNull(pDomTree,pPrevNode), 
			        pPrevNode -> nLinenumber, nRunCheckpoint, 
			        pRunNode -> xNdx,  xNode_selfLevelNull(pDomTree,pRunNode), 
			        pRunNode -> nLinenumber, sv_count) ; 
                           
                }
            else if (pCompileParent && pRunParent)
                {
                tNodeData * pCompileParent2 = NodeAttr_selfParentNode (pDomTree, pCompileParent, r -> Component.nCurrRepeatLevel) ;
                tNodeData * pRunParent2     = NodeAttr_selfParentNode (pDomTree, pRunParent, r -> Component.nCurrRepeatLevel) ;

                if (pCompileParent2 && pCompileParent2 -> xNdx == pRunParent -> xNdx)
		    {
		    pPrevNode = Node_selfCondCloneNode (a, pDomTree, pCompileParent, r -> Component.nCurrRepeatLevel) ;
		    pRunNode  = Node_selfCondCloneNode (a, pDomTree, pRunNode, r -> Component.nCurrRepeatLevel) ;
		    pRunNode -> xPrev = pPrevNode -> xNdx ;
		    pPrevNode -> xNext = pRunNode -> xNdx ;
		    pPrevNode -> xChilds = 0 ;
		    pRunNode -> bFlags  |= nflgNewLevelPrev ;
		    pPrevNode -> bFlags |= nflgNewLevelNext ;

		    if ((a -> pCurrReq?a -> pCurrReq -> Component.Config.bDebug:a -> Config.bDebug) & dbgCheckpoint)
		        lprintf (a, "[%d]Checkpoint: jump forward last child DomTree=%d Index=%d Node=%d(%d) Line=%d -> Index=%d Node=%d(%d) Line=%d SVs=%d\n", 
			        a -> pThread -> nPid, r -> Component.xCurrDomTree, nCompileCheckpoint, 
			        pPrevNode -> xNdx,  xNode_selfLevelNull(pDomTree,pPrevNode), 
			        pPrevNode -> nLinenumber, nRunCheckpoint, 
			        pRunNode -> xNdx,  xNode_selfLevelNull(pDomTree,pRunNode), 
			        pRunNode -> nLinenumber, sv_count) ; 
		    }
                else if (pCompileParent2 && pRunParent2 && pCompileParent2 -> xNdx == pRunParent2 -> xNdx )
                    {
		    if (pRunParent -> nType != ntypAttr && pCompileParent -> nType != ntypAttr) 
		        {
		        pRunParent = Node_selfCondCloneNode (a, pDomTree, pRunParent, r -> Component.nCurrRepeatLevel) ;
		        pCompileParent = Node_selfCondCloneNode (a, pDomTree, pCompileParent, r -> Component.nCurrRepeatLevel) ;
		        pRunParent -> xPrev     = pCompileParent -> xNdx ;
		        pCompileParent -> xNext = pRunParent -> xNdx ;
		        pRunParent -> bFlags  |= nflgNewLevelPrev ;
		        pCompileParent -> bFlags |= nflgNewLevelNext ;
		        }
		    else
		        {
		        int nCompile = Attr_selfAttrNum(((tAttrData *)pCompileParent)) ;
		        int nRun     = Attr_selfAttrNum(((tAttrData *)pRunParent)) ;
		        int i ;

		        pCompileParent2 = Node_selfLevel (a, pDomTree, pCompileParent2 -> xNdx, r -> Component.nCurrRepeatLevel) ;
		        pCompileParent2 = Node_selfCondCloneNode (a, pDomTree, pCompileParent2, r -> Component.nCurrRepeatLevel) ;

		        for (i = nRun - 1 ; i > nCompile; i--)
			    {
			    if ((a -> pCurrReq?a -> pCurrReq -> Component.Config.bDebug:a -> Config.bDebug) & dbgCheckpoint)
			        {
			        tAttrData * pAttr = Element_selfGetNthAttribut (a, pDomTree, pCompileParent2, i) ;
			        lprintf (a,  "[%d]Checkpoint: remove attr #%d flags=%x attr=%d node=%d\n", a -> pThread -> nPid, i, pAttr -> bFlags, pAttr ->xNdx, pCompileParent2 -> xNdx) ; 
			        }
			    Element_selfRemoveNthAttribut (a, pDomTree, pCompileParent2, r -> Component.nCurrRepeatLevel, i) ;
			    }
		        }

		    pPrevNode -> xNext = Node_selfFirstChild (a, pDomTree, pCompileParent, r -> Component.nCurrRepeatLevel) -> xNdx ;
		    pPrevNode -> bFlags |= nflgNewLevelNext ;
                    if ((a -> pCurrReq?a -> pCurrReq -> Component.Config.bDebug:a -> Config.bDebug) & dbgCheckpoint)
                        lprintf (a, "[%d]Checkpoint: jump forward2 DomTree=%d Index=%d Node=%d(%d),%d,%d Line=%d -> Index=%d Node=%d(%d),%d,%d Line=%d SVs=%d\n", 
		                       a -> pThread -> nPid, r -> Component.xCurrDomTree, nCompileCheckpoint, 
				       pPrevNode -> xNdx, xNode_selfLevelNull(pDomTree,pPrevNode), 
				       pCompileParent -> xNdx, pCompileParent2?pCompileParent2 -> xNdx:-1, 
				       pPrevNode -> nLinenumber, 
				       nRunCheckpoint, pRunNode -> xNdx, xNode_selfLevelNull(pDomTree,pRunNode), 
				       pRunParent -> xNdx, pRunParent2?pRunParent2 -> xNdx:-1, 
				       pRunNode -> nLinenumber, sv_count) ; 
                    }
                else
                    {
                    char buf[512] ;

                    if ((a -> pCurrReq?a -> pCurrReq -> Component.Config.bDebug:a -> Config.bDebug) & dbgCheckpoint)
                        lprintf (a, "[%d]Checkpoint: jump forward2 DomTree=%d Index=%d Node=%d(%d),%d,%d Line=%d -> Index=%d Node=%d(%d),%d,%d Line=%d SVs=%d\n", 
		                       a -> pThread -> nPid, r -> Component.xCurrDomTree, nCompileCheckpoint, 
				       pPrevNode -> xNdx, xNode_selfLevelNull(pDomTree,pPrevNode), 
				       pCompileParent -> xNdx, pCompileParent2?pCompileParent2 -> xNdx:-1, 
				       pPrevNode -> nLinenumber, 
				       nRunCheckpoint, pRunNode -> xNdx, xNode_selfLevelNull(pDomTree,pRunNode), 
				       pRunParent -> xNdx, pRunParent2?pRunParent2 -> xNdx:-1, 
				       pRunNode -> nLinenumber, sv_count) ; 
    
                    sprintf(buf, "Unstructured forward jump, %200.200s Line %d -> Line %d", DomTree_filename(r -> Component.xCurrDomTree), pPrevNode -> nLinenumber, pRunNode -> nLinenumber) ;
                    mydie (a, buf) ;
                    }
                }
            else
                {
                char buf[512] ;

                if ((a -> pCurrReq?a -> pCurrReq -> Component.Config.bDebug:a -> Config.bDebug) & dbgCheckpoint)
	                lprintf (a, "[%d]Checkpoint: jump forward DomTree=%d Index=%d Node=%d Line=%d -> Index=%d Node=%d Line=%d SVs=%d\n", a -> pThread -> nPid, r -> Component.xCurrDomTree, nCompileCheckpoint, pPrevNode -> xNdx, pPrevNode -> nLinenumber, nRunCheckpoint, pRunNode -> xNdx, pRunNode -> nLinenumber, sv_count) ; 
    
                sprintf(buf, "Unstructured forward jump (no parents), %200.200s Line %d -> Line %d", DomTree_filename(r -> Component.xCurrDomTree), pPrevNode -> nLinenumber, pRunNode -> nLinenumber) ;
                mydie (a, buf) ;
                }
            r -> Component.nCurrCheckpoint = nRunCheckpoint + 1 ;
            return ;
            }
        }
	{
        tNodeData * pCompileNode = Node_selfLevel (a, pDomTree, pCheckpoints[nCompileCheckpoint].xNode, r -> Component.nCurrRepeatLevel) ;
        tNodeData * pRunNode     = Node_selfLevel (a, pDomTree, pCheckpoints[nRunCheckpoint].xNode, (tRepeatLevel)(r -> Component.nCurrRepeatLevel+1)) ;
        tNodeData * pPrevNode    = Node_selfPreviousSibling (a, pDomTree, pCompileNode, r -> Component.nCurrRepeatLevel) ;
        
        tNodeData * pCompileParent = NodeAttr_selfParentNode (pDomTree, pCompileNode, r -> Component.nCurrRepeatLevel) ;
        tNodeData * pCompileParent2= NodeAttr_selfParentNode (pDomTree, pCompileParent, r -> Component.nCurrRepeatLevel) ;
        tNodeData * pRunParent     = NodeAttr_selfParentNode (pDomTree, pRunNode, r -> Component.nCurrRepeatLevel) ;
        tNodeData * pRunParent2    = NodeAttr_selfParentNode (pDomTree, pRunParent, r -> Component.nCurrRepeatLevel) ;

        if (pPrevNode)
            pPrevNode = Node_selfCondCloneNode (a, pDomTree, pPrevNode, r -> Component.nCurrRepeatLevel) ;
        else
            {
            pPrevNode = Node_selfCondCloneNode (a, pDomTree, pCompileNode, r -> Component.nCurrRepeatLevel) ;
            pPrevNode -> bFlags |= nflgIgnore ;
            }

        if (pCompileParent -> xNdx  == pRunParent -> xNdx)
            {
            r -> Component.nCurrRepeatLevel++ ;            
            pRunNode = Node_selfCondCloneNode (a, pDomTree, pRunNode, r -> Component.nCurrRepeatLevel) ;
        
            pRunNode -> xPrev = pPrevNode -> xNdx ;
            pPrevNode -> xNext = pRunNode -> xNdx ;
	    pRunNode -> bFlags  |= nflgNewLevelPrev ;
	    pPrevNode -> bFlags |= nflgNewLevelNext ;

            if ((a -> pCurrReq?a -> pCurrReq -> Component.Config.bDebug:a -> Config.bDebug) & dbgCheckpoint)
	        lprintf (a, "[%d]Checkpoint: jump backward DomTree=%d Index=%d Node=%d(%d) RepeatLevel=%d Line=%d -> Index=%d Node=%d(%d) Line=%d SVs=%d\n", 
                                      a -> pThread -> nPid, r -> Component.xCurrDomTree, 
                                      nCompileCheckpoint, pPrevNode -> xNdx, xNode_selfLevelNull(pDomTree, pPrevNode),
                                        r -> Component.nCurrRepeatLevel, pPrevNode -> nLinenumber, 
                                      nRunCheckpoint,     pRunNode -> xNdx, xNode_selfLevelNull(pDomTree, pRunNode),
                                         pRunNode -> nLinenumber, sv_count) ; 

            }
        else if (pRunParent2 && pCompileParent2 && pCompileParent2 -> xNdx  == pRunParent2 -> xNdx)
            {
            pPrevNode = Node_selfPreviousSibling (a, pDomTree, pCompileParent, r -> Component.nCurrRepeatLevel) ;
            if (pPrevNode)
                pPrevNode = Node_selfCondCloneNode (a, pDomTree, pPrevNode, r -> Component.nCurrRepeatLevel) ;
            else
                {
                pPrevNode = Node_selfCondCloneNode (a, pDomTree, pCompileParent, r -> Component.nCurrRepeatLevel) ;
                pPrevNode -> bFlags |= nflgIgnore ;
                }

            r -> Component.nCurrRepeatLevel++ ;            
            pRunNode  = Node_selfCondCloneNode   (a, pDomTree, pRunParent, r -> Component.nCurrRepeatLevel) ;
        
            pRunNode -> xPrev = pPrevNode -> xNdx ;
            pPrevNode -> xNext = pRunNode -> xNdx ;
	    pRunNode -> bFlags  |= nflgNewLevelPrev ;
	    pPrevNode -> bFlags |= nflgNewLevelNext ;

            if ((a -> pCurrReq?a -> pCurrReq -> Component.Config.bDebug:a -> Config.bDebug) & dbgCheckpoint)
	        lprintf (a, "[%d]Checkpoint: jump backward parent DomTree=%d Index=%d Node=%d RepeatLevel=%d Line=%d -> Index=%d Node=%d Line=%d SVs=%d\n", a -> pThread -> nPid, r -> Component.xCurrDomTree, nCompileCheckpoint, pPrevNode -> xNdx, r -> Component.nCurrRepeatLevel, pPrevNode -> nLinenumber, nRunCheckpoint, pRunNode -> xNdx, pRunNode -> nLinenumber, sv_count) ; 

            }
        else if (xNode_selfLevelNull(pDomTree,pPrevNode) == xNode_selfLevelNull(pDomTree,pRunParent))
            {
            if ((a -> pCurrReq?a -> pCurrReq -> Component.Config.bDebug:a -> Config.bDebug) & dbgCheckpoint)
	        lprintf (a, "[%d]Checkpoint: jump backward2 DomTree=%d Index=%d Node=%d(%d),%d(%d) Line=%d -> Index=%d Node=%d(%d),%d(%d) Line=%d SVs=%d\n", 
			    a -> pThread -> nPid, r -> Component.xCurrDomTree, 
			    nCompileCheckpoint, pPrevNode -> xNdx,	xNode_selfLevelNull(pDomTree,pPrevNode),
						pCompileParent -> xNdx, xNode_selfLevelNull(pDomTree,pCompileParent),
						pPrevNode -> nLinenumber, 
			    nRunCheckpoint,	pRunNode -> xNdx,	xNode_selfLevelNull(pDomTree,pRunNode),
						pRunParent -> xNdx,	xNode_selfLevelNull(pDomTree,pRunParent),
						pRunNode -> nLinenumber, sv_count) ; 
	    pPrevNode = Node_selfLastChild (a, pDomTree, pPrevNode, r -> Component.nCurrRepeatLevel) ;
            pPrevNode = Node_selfCondCloneNode (a, pDomTree, pPrevNode, r -> Component.nCurrRepeatLevel) ;
        
            r -> Component.nCurrRepeatLevel++ ;            

            pRunNode = Node_selfCondCloneNode (a, pDomTree, pRunNode, r -> Component.nCurrRepeatLevel) ;
            pRunNode -> xPrev = pPrevNode -> xNdx ;
            pPrevNode -> xNext = pRunNode -> xNdx ;
	    pRunNode -> bFlags  |= nflgNewLevelPrev ;
	    pPrevNode -> bFlags |= nflgNewLevelNext ;
	    pCheckpointStatus -> xJumpFromNode    = pPrevNode -> xNdx ;
	    pCheckpointStatus -> xJumpToNode      = pRunNode -> xNdx ;

            if ((a -> pCurrReq?a -> pCurrReq -> Component.Config.bDebug:a -> Config.bDebug) & dbgCheckpoint)
	        lprintf (a, "[%d]Checkpoint: jump backward last child DomTree=%d Index=%d Node=%d(%d) RepeatLevel=%d Line=%d -> Index=%d Node=%d(%d) Line=%d SVs=%d\n", 
			    a -> pThread -> nPid, r -> Component.xCurrDomTree, 
			    nCompileCheckpoint, pPrevNode -> xNdx, xNode_selfLevelNull(pDomTree,pPrevNode), r -> Component.nCurrRepeatLevel, pPrevNode -> nLinenumber, 
			    nRunCheckpoint,     pRunNode -> xNdx, xNode_selfLevelNull(pDomTree,pRunNode), pRunNode -> nLinenumber, sv_count) ; 

            }
        else if (pRunParent2 && xNode_selfLevelNull(pDomTree,pPrevNode) == xNode_selfLevelNull(pDomTree,pRunParent2))
            {
            if ((a -> pCurrReq?a -> pCurrReq -> Component.Config.bDebug:a -> Config.bDebug) & dbgCheckpoint)
	        lprintf (a, "[%d]Checkpoint: jump backward2 DomTree=%d Index=%d Node=%d(%d),%d(%d) Line=%d -> Index=%d Node=%d(%d),%d(%d) Line=%d SVs=%d\n", 
			    a -> pThread -> nPid, r -> Component.xCurrDomTree, 
			    nCompileCheckpoint, pPrevNode -> xNdx,	xNode_selfLevelNull(pDomTree,pPrevNode),
						pCompileParent -> xNdx, xNode_selfLevelNull(pDomTree,pCompileParent),
						pPrevNode -> nLinenumber, 
			    nRunCheckpoint,	pRunNode -> xNdx,	xNode_selfLevelNull(pDomTree,pRunNode),
						pRunParent -> xNdx,	xNode_selfLevelNull(pDomTree,pRunParent),
						pRunNode -> nLinenumber, sv_count) ; 
	    pPrevNode = Node_selfLastChild (a, pDomTree, pPrevNode, r -> Component.nCurrRepeatLevel) ;
	    pPrevNode = Node_selfLastChild (a, pDomTree, pPrevNode, r -> Component.nCurrRepeatLevel) ;
            pPrevNode = Node_selfCondCloneNode (a, pDomTree, pPrevNode, r -> Component.nCurrRepeatLevel) ;
        
            r -> Component.nCurrRepeatLevel++ ;            

            pRunNode = Node_selfCondCloneNode (a, pDomTree, pRunNode, r -> Component.nCurrRepeatLevel) ;
            pRunNode -> xPrev = pPrevNode -> xNdx ;
            pPrevNode -> xNext = pRunNode -> xNdx ;
	    pRunNode -> bFlags  |= nflgNewLevelPrev ;
	    pPrevNode -> bFlags |= nflgNewLevelNext ;
	    pCheckpointStatus -> xJumpFromNode    = pPrevNode -> xNdx ;
	    pCheckpointStatus -> xJumpToNode      = pRunNode -> xNdx ;

            if ((a -> pCurrReq?a -> pCurrReq -> Component.Config.bDebug:a -> Config.bDebug) & dbgCheckpoint)
	        lprintf (a, "[%d]Checkpoint: jump backward last child 2 DomTree=%d Index=%d Node=%d(%d) RepeatLevel=%d Line=%d -> Index=%d Node=%d(%d) Line=%d SVs=%d\n", 
			    a -> pThread -> nPid, r -> Component.xCurrDomTree, 
			    nCompileCheckpoint, pPrevNode -> xNdx, xNode_selfLevelNull(pDomTree,pPrevNode), r -> Component.nCurrRepeatLevel, pPrevNode -> nLinenumber, 
			    nRunCheckpoint,     pRunNode -> xNdx, xNode_selfLevelNull(pDomTree,pRunNode), pRunNode -> nLinenumber, sv_count) ; 

            }
        else
            {
            char buf[512] ;
            
            if ((a -> pCurrReq?a -> pCurrReq -> Component.Config.bDebug:a -> Config.bDebug) & dbgCheckpoint)
	        lprintf (a, "[%d]Checkpoint: jump backward2 DomTree=%d Index=%d Node=%d(%d),%d(%d) Line=%d -> Index=%d Node=%d(%d),%d(%d) Line=%d SVs=%d\n", 
			    a -> pThread -> nPid, r -> Component.xCurrDomTree, 
			    nCompileCheckpoint, pPrevNode -> xNdx,	xNode_selfLevelNull(pDomTree,pPrevNode),
						pCompileParent -> xNdx, xNode_selfLevelNull(pDomTree,pCompileParent),
						pPrevNode -> nLinenumber, 
			    nRunCheckpoint,	pRunNode -> xNdx,	xNode_selfLevelNull(pDomTree,pRunNode),
						pRunParent -> xNdx,	xNode_selfLevelNull(pDomTree,pRunParent),
						pRunNode -> nLinenumber, sv_count) ; 

            sprintf(buf, "Unstructured backward jump, %200.200s Line %d -> Line %d", DomTree_filename(r -> Component.xCurrDomTree), pPrevNode -> nLinenumber, pRunNode -> nLinenumber) ;
            mydie (a, buf) ;
            }
        }
    r -> Component.nCurrCheckpoint = nRunCheckpoint + 1 ;
    }




/*--------------------------------------------------------------------------*/
/*                                                                          */
/* DomTree_discardAfterCheckpoint                                           */
/*                                                                          */
/*!
*
* \_en									   
* Discard anything in the tree from the checkpoint given in nRunCheckpoint
*                                                                          
* @param   r               Embperl request data                            
* @param   xDomTree	   current DomTree we are working on              
* @param   nRunCheckpoint  Number of checkpoint from on which the output should
*                          discared
* \endif                                                                       
*
* \_de									   
* 
* Verwrirft alles ab dem in nRunCheckpoint ?bergebenen Punkt
*                                                                          
* @param   r               Embperl Requestdaten                            
* @param   xDomTree	   akuteller DomTree der bearbeitet wird          
* @param   nRunCheckpoint  Nummer des Checkpoints ab dem aller Output
*                          verworfen wird
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

void DomTree_discardAfterCheckpoint (tReq * r, tIndex nRunCheckpoint)


    {
    epTHX_
    tApp * a = r -> pApp ;
    tIndex xDomTree	      = r -> Component.xCurrDomTree ;
    tDomTree * pDomTree = DomTree_self (xDomTree) ;
    tDomTreeCheckpointStatus * pCheckpointStatus =  &pDomTree -> pCheckpointStatus[nRunCheckpoint] ;

    r -> Component.nCurrRepeatLevel = pCheckpointStatus -> nRepeatLevel ;
    r -> Component.nCurrCheckpoint  = pCheckpointStatus -> nCompileCheckpoint  ;
    
    if ((a -> pCurrReq?a -> pCurrReq -> Component.Config.bDebug:a -> Config.bDebug) & dbgCheckpoint)
        lprintf (a, "[%d]Checkpoint: discard all from checkpoint=%d DomTree=%d new RepeatLevel=%d new Checkpoint=%d\n",
	         a -> pThread -> nPid, nRunCheckpoint, r -> Component.xCurrDomTree, r -> Component.nCurrRepeatLevel, r -> Component.nCurrCheckpoint) ; 

    if (pCheckpointStatus -> xJumpFromNode)
	{
	tNodeData * pLastChild  = Node_self (pDomTree,  pCheckpointStatus -> xJumpFromNode) ;
	tNodeData * pParent     = Node_self (pDomTree, pLastChild -> xParent) ;
	tNodeData * pFirstChild = Node_self (pDomTree, pParent -> xChilds) ;

	if (pCheckpointStatus -> xJumpToNode) 
	    {
	    tIndex n = ArrayGetSize (a, pDomTree -> pLookup) ;
	    tIndex i ;
	    for (i = pCheckpointStatus -> xJumpToNode; i < n; i++)
		{
		tNodeData * pNode = Node_self (pDomTree,  i) ;
		if (pNode && pNode -> nType != ntypAttr)
		    {
		    if ((a -> pCurrReq?a -> pCurrReq -> Component.Config.bDebug:a -> Config.bDebug) & dbgCheckpoint)
			lprintf (a, "[%d]Checkpoint: discard all from checkpoint=%d DomTree=%d remove node %d\n",
				    a -> pThread -> nPid, nRunCheckpoint, r -> Component.xCurrDomTree, i) ; 

		    Node_selfRemoveChild (a, pDomTree, pParent -> xNdx, pNode) ;
		    }
		}
	    }

        if (pFirstChild)
            {
            pFirstChild = Node_selfCondCloneNode (a, pDomTree, pFirstChild, pFirstChild -> nRepeatLevel) ;
	    pFirstChild -> xPrev = pLastChild -> xNdx ;
	    pLastChild  -> xNext = pFirstChild -> xNdx ;
	
	    if ((a -> pCurrReq?a -> pCurrReq -> Component.Config.bDebug:a -> Config.bDebug) & dbgCheckpoint)
	        lprintf (a, "[%d]Checkpoint: discard all from table   Parent=%d FirstChild=%d LastChild=%d\n",
		     a -> pThread -> nPid, pParent -> xNdx, pFirstChild -> xNdx, pLastChild -> xNdx) ; 
	    }
	}


    }
    

/* ------------------------------------------------------------------------ 

interface Node {
  #  NodeType 
  const unsigned short      ELEMENT_NODE                   = 1;
  const unsigned short      ATTRIBUTE_NODE                 = 2;
  const unsigned short      TEXT_NODE                      = 3;
  const unsigned short      CDATA_SECTION_NODE             = 4;
  const unsigned short      ENTITY_REFERENCE_NODE          = 5;
  const unsigned short      ENTITY_NODE                    = 6;
  const unsigned short      PROCESSING_INSTRUCTION_NODE    = 7;
  const unsigned short      COMMENT_NODE                   = 8;
  const unsigned short      DOCUMENT_NODE                  = 9;
  const unsigned short      DOCUMENT_TYPE_NODE             = 10;
  const unsigned short      DOCUMENT_FRAGMENT_NODE         = 11;
  const unsigned short      NOTATION_NODE                  = 12;

  readonly attribute DOMString        nodeName;
           attribute DOMString        nodeValue;
                                        # raises(DOMException) on setting 
                                        # raises(DOMException) on retrieval

  readonly attribute unsigned short   nodeType;
  readonly attribute Node             parentNode;
  readonly attribute NodeList         childNodes;
  readonly attribute Node             firstChild;
  readonly attribute Node             lastChild;
  readonly attribute Node             previousSibling;
  readonly attribute Node             nextSibling;
  readonly attribute NamedNodeMap     attributes;
  # Modified in DOM Level 2:
  readonly attribute Document         ownerDocument;
  Node               insertBefore(in Node newChild, 
                                  in Node refChild)
                                        raises(DOMException);
  Node               replaceChild(in Node newChild, 
                                  in Node oldChild)
                                        raises(DOMException);
  Node               removeChild(in Node oldChild)
                                        raises(DOMException);
  Node               appendChild(in Node newChild)
                                        raises(DOMException);
  boolean            hasChildNodes();
  Node               cloneNode(in boolean deep);
  # Introduced in DOM Level 2: 
  void               normalize();
  # Introduced in DOM Level 2: 
  boolean            supports(in DOMString feature, 
                              in DOMString version);
  # Introduced in DOM Level 2: 
  readonly attribute DOMString        namespaceURI;
  # Introduced in DOM Level 2: 
           attribute DOMString        prefix;
                                        # raises(DOMException) on setting 

  # Introduced in DOM Level 2: 
  readonly attribute DOMString        localName;
};



*/

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Node_selfLevelItem							    */
/*                                                                          */
/*! 
*   \_en
*   returns the node with index xNode and repeat level nLevel. If there is
*   node node in this repeat level, the node from the source DomTree with
*   level zero is returned
*   
*   @param  pDomTree	    current DomTree we are working on              
*   @param  xNode           node index
*   @param  nRepeatLevel    repeat level
*
*   @note   Don't use this function directly, use the macro Node_selfLevel
*   \endif                                                                       
*
*   \_de									   
*   Liefert den Node mit dem Index xNode und dem RepeatLevel nLevel. Wenn
*   dieser nicht existiert wird der Node mit Index Null aus dem Source
*   DomTree zur?ck geliefert
*
*   @param  pDomTree	    DomTree der den Node enth?lt              
*   @param  pNode           Node Index
*   @param  nRepeatLevel    RepeatLevel
*
*   @note   Dieser Funtkion sollte nicht direkt aufgerufen werden, sondern
*	    das Makro Node_selfLevel
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



tNodeData * Node_selfLevelItem (/*in*/ tApp * a, 
                                /*in*/ tDomTree *    pDomTree,
				/*in*/ tNode	     xNode,
				/*in*/ tRepeatLevel  nLevel)

    {
    tRepeatLevelLookup * pLookupLevelNode  ;
    tLookupItem *   pLookup  ;

    pLookupLevelNode = pDomTree -> pLookup[xNode].pLookupLevel ;
    if (pLookupLevelNode)
	{
	register tRepeatLevelLookupItem * pLookupLevelNodeLevel	= &pLookupLevelNode -> items[nLevel & pLookupLevelNode -> nMask] ;
	register tNodeData *              pLnNode		= pLookupLevelNodeLevel -> pNode ;
	if (!pLnNode)
	    {
	    pLookup = DomTree_self(pDomTree -> xSourceNdx) -> pLookup ;
	    if (ArrayGetSize(a, pLookup) > xNode)
		return ((struct tNodeData *)(pLookup[xNode].pLookup)) ;
	    else
		return ((struct tNodeData *)(pDomTree -> pLookup[xNode].pLookup)) ;
	    }
	if (pLnNode -> nRepeatLevel == nLevel)
	    return pLnNode ;
	while ((pLookupLevelNodeLevel = pLookupLevelNodeLevel -> pNext))
	    {
	    pLnNode = pLookupLevelNodeLevel -> pNode ;
	    if (pLnNode -> nRepeatLevel == nLevel)
		return pLnNode ;
	    }
	}
    
    
    pLookup = DomTree_self(pDomTree -> xSourceNdx) -> pLookup ;
    if (ArrayGetSize(a, pLookup) > xNode)
	return ((struct tNodeData *)(pLookup[xNode].pLookup)) ;
    
    return ((struct tNodeData *)(pDomTree -> pLookup[xNode].pLookup)) ;
    }




/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Node_cloneNode                                                           */
/*                                                                          */
/*! 
*   \_en
*   clones a node 
*   
*   @param  pDomTree	    current DomTree we are working on              
*   @param  pNode           node that should be cloned
*   @param  nRepeatLevel    repeat level for new node
*   @param  bDeep           determines how children are handled
*                           - 1 clone children also 
*                           - 0 clone no children 
*                           - -1 clone no attributes and no children
*   \endif                                                                       
*
*   \_de									   
*   Cloned einen Node
*
*   @param  pDomTree	    DomTree der den Node enth?lt              
*   @param  pNode           Node der gecloned werden soll
*   @param  nRepeatLevel    RepeatLevel f?r neuen Node
*   @param  bDeep           legt fest wie Kindelemente behandelt werden
*                           - 1 cloned Kindelemente 
*                           - 0 cloned keine Kindelemente
*                           - -1 cloned keine Attribute und keine Kindelemente
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */


tNodeData * Node_selfCloneNode (/*in*/ tApp * a, 
                                /*in*/ tDomTree *      pDomTree,
				/*in*/ tNodeData *     pNode,
                                /*in*/ tRepeatLevel    nRepeatLevel,
				/*in*/  int	       bDeep)

    {
    epaTHX_
    int	        len  = sizeof (tNodeData) + (bDeep == -1?0:pNode -> numAttr * sizeof (tAttrData)) ; 
    tNode       xNewNode ;
    tNodeData * pNew ;

    ASSERT_NODE_VALID(a,pNode) ;
    
    if ((pNew = dom_malloc (a, len, &numNodes)) == NULL)
	return NULL ;

    memcpy (pNew, pNode, len) ;
    xNewNode		= ArrayAdd (a, &pDomTree -> pLookup, 1) ;
    pDomTree -> pLookup[xNewNode].pLookup	= pNew ;
    pDomTree -> pLookup[xNewNode].pLookupLevel	= NULL ;
    pNew -> xNdx	= xNewNode ;
    pNew -> xDomTree    = pDomTree -> xNdx ;
    pNew -> nRepeatLevel    = nRepeatLevel ;

    if (pNew -> nText)
	NdxStringRefcntInc (a, pNew -> nText) ;
    
    if (bDeep == -1)
	pNew -> numAttr = 0 ;
    else
	{
	tAttrData * pAttr = (tAttrData * )(pNew + 1) ;
	int         n     = pNew -> numAttr ;

	while (n)
	    {
	    xNewNode = ArrayAdd (a, &pDomTree -> pLookup, 1) ;
	    pDomTree -> pLookup[xNewNode].pLookup = pAttr ;
            pDomTree -> pLookup[xNewNode].pLookupLevel	= NULL ;
	    pAttr -> xNdx = xNewNode ;
	    if (pAttr -> xName)
		NdxStringRefcntInc (a, pAttr -> xName) ;
	    if (pAttr -> xValue && (pAttr -> bFlags & aflgAttrValue))
		NdxStringRefcntInc (a, pAttr -> xValue) ;
	    n-- ;
	    pAttr++ ;
	    }
	}
    if (bDeep < 1)
	pNew -> xChilds = 0 ;


    return pNew ;
    }
                                

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Node_cloneNode                                                           */
/*                                                                          */
/*! 
*   \_en
*   clones a node 
*   
*   @param  pDomTree	    current DomTree we are working on              
*   @param  xNode           node that should be cloned
*   @param  nRepeatLevel    repeat level for new node
*   @param  bDeep           determines how children are handled
*                           - 1 clone children also 
*                           - 0 clone no children 
*                           - -1 clone no attributes and no children
*   \endif                                                                       
*
*   \_de									   
*   Cloned einen Node
*
*   @param  pDomTree	    DomTree der den Node enth?lt              
*   @param  xNode           Node der gecloned werden soll
*   @param  nRepeatLevel    RepeatLevel f?r neuen Node
*   @param  bDeep           legt fest wie Kindelemente behandelt werden
*                           - 1 cloned Kindelemente 
*                           - 0 cloned keine Kindelemente
*                           - -1 cloned keine Attribute und keine Kindelemente
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */


tNode Node_cloneNode (/*in*/ tApp * a, 
                      /*in*/ tDomTree *      pDomTree,
		      /*in*/ tNode 	     xNode,
                      /*in*/ tRepeatLevel    nRepeatLevel,
		      /*in*/  int	     bDeep)

    {
    tNodeData * pNew = Node_selfCloneNode (a, pDomTree, Node_self (pDomTree, xNode), nRepeatLevel, bDeep) ;

    if (pNew)
	return pNew -> xNdx ;

    return 0 ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Node_selfCondCloneNode                                                   */
/*                                                                          */
/*! 
*   \_en
*   clone a node if it's part of a different DomTree or has a different     
*   repeat level in preparation for a modification. This is part of the
*   copy on write stragtegie. As long as a node isn't written to it may 
*   point to another node from which the current DomTree was copied or
*   within a different repeat level. Before writing to the node this
*   function has to be called to make sure we are modifing the right node                           
*
*   @note   Most times you will not call this function directly. All functions
*           that operates on the DomTree makes sure to call this function first
*           for you
*   
*   @param  pDomTree	    current DomTree we are working on              
*   @param  pNode           node that should be cloned
*   @param  nRepeatLevel    repeat level for new node
*   \endif                                                                       
*
*   \_de									   
*   Cloned einen Node wenn dieser Teil eines anderen DomTree oder eines
*   anderen RepeatLevel ist. Dies ist Teil der "copy on write" Strategie
*   solange ein Node nicht beschrieben wird, kann dieser als Zeiger auf
*   einen anderen Node in einem DomTree oder RepeatLevel aus dem er kopiert
*   wurde sein. Sobald der Node ge?ndert werden mu?, mu? diese Funktion
*   aufgerufen werden um sicherzustellen das der korekte Node modifiziert
*   wird.
*
*   @note   In den meisten F?llen ist es nicht n?tig diese Funktion direkt
*           aufzurufen, da alle Funktionen die den DomTree modifizieren
*           dies sicherstellen.
*
*   @param  pDomTree	    DomTree der den Node enth?lt              
*   @param  pNode           Node der gecloned werden soll
*   @param  nRepeatLevel    RepeatLevel f?r neuen Node
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */


tNodeData * Node_selfCondCloneNode (/*in*/ tApp * a, 
                                    /*in*/ tDomTree *      pDomTree,
				    /*in*/ tNodeData *     pNode,
                                    /*in*/ tRepeatLevel    nRepeatLevel)

    {
    epaTHX_
    int	        len  ;
    tNodeData * pNew ;
    tAttrData * pAttr ;
    int         n ;
    tLookupItem *  pLookup  ;
    tNode	xNdx ;
    tRepeatLevelLookup * pLookupLevelNode  ;
    tRepeatLevelLookupItem * pLookupLevelNodeLevel ;

    ASSERT_NODE_VALID(a,pNode) ;
    
    if (pNode -> nType == ntypAttr)
        mydie (a, "Node expected, but Attribute found. Maybe unclosed quote?") ;
    
    if (pNode -> xDomTree == pDomTree -> xNdx && pNode -> nRepeatLevel == nRepeatLevel)
        return pNode ;

 
/* lprintf(a, "selfCondCloneNode 1 node=%d repeatlevel=%d\n", pNode -> xNdx, nRepeatLevel) ;    */
 
    if (nRepeatLevel == 0)
        {
        pLookup = pDomTree -> pLookup ;
        len	    = sizeof (tNodeData) + pNode -> numAttr * sizeof (tAttrData) ; 
        xNdx    = pNode -> xNdx ;

        if ((pLookup[xNdx].pLookup = pNew = dom_malloc (a, len, &numNodes)) == NULL)
	    return NULL ;

        ASSERT_NODE_VALID(a,pNode) ;
        
        memcpy (pNew, pNode, len) ;

        pNew -> xDomTree    = pDomTree -> xNdx ;

        if (pNew -> nText)
	    NdxStringRefcntInc (a, pNew -> nText) ;
    
        pAttr = (tAttrData * )(pNew + 1) ;
        n     = pNew -> numAttr ;

        while (n)
	    {
	    pLookup[pAttr -> xNdx].pLookup = pAttr ;
	    if (pAttr -> xName)
	        NdxStringRefcntInc (a, pAttr -> xName) ;
	    if (pAttr -> xValue && (pAttr -> bFlags & aflgAttrValue))
	        NdxStringRefcntInc (a, pAttr -> xValue) ;
	    n-- ;
	    pAttr++ ;
	    }
        
        ASSERT_NODE_VALID(a,pNew) ;

        return pNew ;
        }

    if (!(pNew = Node_selfCloneNode (a, pDomTree, pNode, nRepeatLevel, 1))) 
        return NULL ;

    pLookup = pDomTree -> pLookup ;
    pLookupLevelNode = pLookup[pNode -> xNdx].pLookupLevel ;
    if (!pLookupLevelNode)
        {
        if ((pLookupLevelNode = pLookup[pNode -> xNdx].pLookupLevel = 
		  (tRepeatLevelLookup *)dom_malloc (a, sizeof (tRepeatLevelLookup) + sizeof (tRepeatLevelLookupItem) * (LEVELHASHSIZE - 1), &numLevelLookup)) == NULL)
	    return NULL ;
        pLookupLevelNode -> nMask = LEVELHASHSIZE - 1 ;
        pLookupLevelNode -> numItems = LEVELHASHSIZE ;
        pLookupLevelNode -> xNullNode = pNode -> xNdx ;
        memset (pLookupLevelNode -> items, 0, sizeof (*pLookupLevelNodeLevel) * LEVELHASHSIZE) ;
        }
    pLookup[pNew -> xNdx].pLookupLevel = pLookupLevelNode ;
    pLookupLevelNodeLevel= &pLookupLevelNode -> items[nRepeatLevel & pLookupLevelNode -> nMask] ;
    if (pLookupLevelNodeLevel -> pNode)
        {
        tRepeatLevelLookupItem * pNewItem = (tRepeatLevelLookupItem *)dom_malloc (a, sizeof (tRepeatLevelLookupItem), &numLevelLookupItem) ;
        if (!pNewItem)
	    return NULL ;

        pNewItem -> pNode =  pLookupLevelNodeLevel -> pNode ;   
        pNewItem -> pNext =  pLookupLevelNodeLevel -> pNext ;   
        pLookupLevelNodeLevel -> pNode = pNew ;   
        pLookupLevelNodeLevel -> pNext = pNewItem ;   
        }
    else
        {
        pLookupLevelNodeLevel -> pNode = pNew ;   
        }

    ASSERT_NODE_VALID(a,pNew) ;

    return pNew ;
    }

                                
/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Node_selfForceLevel                                                      */
/*                                                                          */
/*! 
*   \_en
*   returns a pointer to a node for a given index and repeat level. If the
*   node does not exist in the current DomTree or RepeatLevel it is created
*   
*   @param  pDomTree	    current DomTree we are working on              
*   @param  xNode           index for node
*   @param  nRepeatLevel    repeat level for node
*   \endif                                                                       
*
*   \_de									   
*   Liefert einen Zeiger auf eine Node zu einen gegebenen Index und RepeatLevel.
*   Existiert der Node noch nicht in diesem DomTree oder RepeatLevel wird er
*   erzeugt
*
*   @param  pDomTree	    DomTree der den Node enth?lt              
*   @param  xNode           index f?r Node
*   @param  nRepeatLevel    RepeatLevel f?r Node
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */


tNodeData * Node_selfForceLevel(/*in*/ tApp * a, 
                                /*in*/ tDomTree *      pDomTree,
				/*in*/ tNode           xNode,
                                /*in*/ tRepeatLevel    nRepeatLevel)

    {
    tNodeData * pNode = Node_selfLevel (a, pDomTree, xNode, nRepeatLevel) ;

    return Node_selfCondCloneNode (a, pDomTree, pNode, nRepeatLevel) ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Node_newAndAppend                                                        */
/*                                                                          */
/* Create new node and append it to parent                                  */
/*                                                                          */
/* ------------------------------------------------------------------------ */



tNodeData * Node_newAndAppend (/*in*/ tApp * a, 
                               /*in*/  tDomTree *	 pDomTree,
                               /*in*/  tIndex            xParent,
                               /*in*/  tRepeatLevel      nRepeatLevel,
                               /*in*/  tIndex *          pxChilds,
                               /*in*/  tSInt32           nLinenumber,
                               /*in*/  tSInt32           nSize) 

    {
    tIndex xChilds        = pxChilds?*pxChilds:0 ;
    tNodeData * pNewChild  ;
    tIndex      xNdx      = ArrayAdd (a, &pDomTree -> pLookup, 1) ;

    if (nSize == 0)
        nSize = sizeof (tNodeData) ;

    if ((pDomTree -> pLookup[xNdx].pLookup = pNewChild = dom_malloc (a, nSize, &numNodes)) == NULL)
	return NULL ;
    pDomTree -> pLookup[xNdx].pLookupLevel = NULL ;

    memset (pNewChild, 0, nSize) ;
    pNewChild -> xParent = xParent ;
    pNewChild -> xNdx    = xNdx ;
    pNewChild -> nLinenumber = (tUInt16)nLinenumber ;
    pNewChild -> bFlags = nflgOK ;
    pNewChild -> xDomTree = pDomTree -> xNdx ;
    pNewChild -> nRepeatLevel = nRepeatLevel ;

    if (xChilds)
        { /* --- attribute has already children, get the first and last one --- */
	tNodeData * pFirstChild = Node_selfLevel (a, pDomTree, xChilds, nRepeatLevel) ;
        tNodeData * pLastChild  = Node_selfLevel (a, pDomTree, pFirstChild -> xPrev, nRepeatLevel) ;
	pFirstChild = Node_selfCondCloneNode (a, pDomTree, pFirstChild, nRepeatLevel) ;
	pLastChild = Node_selfCondCloneNode (a, pDomTree, pLastChild, nRepeatLevel) ;

        pNewChild -> xNext      = pFirstChild -> xNdx ;    
        pNewChild -> xPrev      = pLastChild -> xNdx ;    
        pFirstChild -> xPrev    = xNdx ;    
        pLastChild -> xNext     = xNdx ;    
        }
    else
        /* --- attribute has no children, get a new one --- */
        {
        pNewChild -> xPrev   = xNdx ;
        pNewChild -> xNext   = xNdx ;
        if (pxChilds)
            *pxChilds = xNdx ;
        }

    return pNewChild ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Node_selfExpand                                                          */
/*                                                                          */
/*!
*   \_en
*   Expand a node to hold more attributes
*   
*   @param  pNode	    Node to expand
*   @param  numOldAttr	    number of Attributes in the old node that must
*			    be relocated (-1 to take form pNode)
*   @param  numNewAttr	    new number of attributes
*   @return		    The node with space for numNewAttr
*
*   @warning	The node may have a new memory address after this function
*   \endif                                                                       
*
*   \_de									   
*   Expandiert einen Node um mehr Attribute aufzunehmen
*   
*   @param  pNode	    Node der expandiert werden soll
*   @param  numOldAttr	    Anzahl der Attribute die Relokiert werden m?ssen
*			    (-1 um alle Attribute zu relokieren)
*   @param  numNewAttr	    Neue Anzahl der Attribute
*   @return		    Den Node mit platz f?r numNewAttr
*
*   @warning	Der Node liegt nach dem Aufruf dieser Funktion u.U. an 
*		anderen Speicheradresse
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */




tNodeData * Node_selfExpand   (/*in*/ tApp * a, 
                               /*in*/  tDomTree *	 pDomTree,
                               /*in*/  tNodeData *       pNode,
                               /*in*/  tUInt16           numOldAttr, 
                               /*in*/  tUInt16           numNewAttr) 

    {
    tNodeData * pNewChild  ;
    tNode       xNdx = pNode -> xNdx ;
    int		nSize = sizeof (tNodeData) + numNewAttr  * sizeof (tAttrData) ;

    if ((pNewChild = dom_realloc (a, pNode, nSize)) == NULL)
	return NULL ;

    if (pNewChild != pNode)
	{
	tAttrData *	    pAttr	    = ((struct tAttrData * )(pNewChild + 1))  ;
	tLookupItem *	    pLookup	    = pDomTree -> pLookup ;
	tRepeatLevelLookup *pLookupLevelNode= pLookup[xNdx].pLookupLevel ; 

	if (numOldAttr == (tUInt16) -1)
	    numOldAttr = pNewChild -> numAttr ;

	pLookup[xNdx].pLookup = pNewChild ;
	if (pLookupLevelNode)
	    {
	    tRepeatLevel nLevel = pNewChild -> nRepeatLevel ;
	    register tRepeatLevelLookupItem * pLookupLevelNodeLevel	= &pLookupLevelNode -> items[nLevel & pLookupLevelNode -> nMask] ;
	    register tNodeData *              pLnNode		= pLookupLevelNodeLevel -> pNode ;
	    if (pLnNode && pLnNode -> nRepeatLevel == nLevel)
		pLookupLevelNodeLevel -> pNode = pNewChild ;
	    else
		{
		while ((pLookupLevelNodeLevel = pLookupLevelNodeLevel -> pNext))
		    {
		    pLnNode = pLookupLevelNodeLevel -> pNode ;
		    if (pLnNode -> nRepeatLevel == nLevel)
			{
			pLookupLevelNodeLevel -> pNode = pNewChild ;
			break ;
			}
		    }
		}
	    }    

	while (numOldAttr--)
	    {
	    pLookup[pAttr -> xNdx].pLookup = pAttr ;
	    pLookup[pAttr -> xNdx].pLookupLevel = NULL ;
	    pAttr++ ; 
	    }
	
	
	}
   
    return pNewChild ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Node_appendChild                                                         */
/*                                                                          */
/* Append a child node to a parent node                                     */
/*                                                                          */
/* ------------------------------------------------------------------------ */



tNode Node_appendChild (/*in*/ tApp * a, 
                        /*in*/  tDomTree *	 pDomTree,
			/*in*/	tNode 		 xParent,
                        /*in*/  tRepeatLevel     nRepeatLevel,
			/*in*/	tNodeType	 nType,
			/*in*/	int              bForceAttrValue,
			/*in*/	const char *	 sText,
			/*in*/	int		 nTextLen,
			/*in*/	int		 nLevel,
			/*in*/	int		 nLinenumber,
			/*in*/	const char *	 sLogMsg)

    {
    epaTHX_
    tNodeData *	pParent;
    tIndex	xText ;

    pParent = Node_self (pDomTree, xParent) ;

    /* --- clone node if it doesn't live in the current DomTree -- */
    if (pParent)
	{
	if (pParent -> nType == ntypAttr)
	    {
	    tNodeData * pNode = Attr_selfNode (((tAttrData *)pParent)) ;

	    pNode = Node_selfCondCloneNode (a, pDomTree, pNode, nRepeatLevel) ;
	    pParent = Node_self (pDomTree, xParent) ; /* relookup in case of node move */
	    }
	else
	    {
	    pParent = Node_selfCondCloneNode (a, pDomTree, pParent, nRepeatLevel) ;
	    }
	}
    
    if (nType == ntypAttr)
	{ /* add new attribute to node */	    
	struct tAttrData *  pNew  ;
	tIndex		    xNdx ;

	pParent = Node_selfExpand (a, pDomTree, pParent, (tUInt16)-1, (tUInt16)(pParent -> numAttr + 1)) ;

	pNew = ((struct tAttrData * )(pParent + 1)) + pParent -> numAttr ;

        xNdx = ArrayAdd (a, &pDomTree -> pLookup, 1) ;
	pDomTree -> pLookup[xNdx].pLookup = (struct tNodeData *)pNew ;
	pDomTree -> pLookup[xNdx].pLookupLevel = NULL ;

	pNew -> xName	    = sText?String2NdxNoInc (a, sText, nTextLen):nTextLen ;
	NdxStringRefcntInc (a, pNew -> xName) ;
	pNew -> xValue	    = 0 ;
	pNew -> bFlags	    = aflgOK ;
	pNew -> nType	    = nType ;
	pNew -> xNdx	    = xNdx ;
	pNew -> nNodeOffset = ((tUInt8 *)pNew) - ((tUInt8 *)pParent) ;
        pParent -> numAttr++ ;
	numAttr++ ;

	if ((a -> pCurrReq?a -> pCurrReq -> Component.Config.bDebug:a -> Config.bDebug) & dbgParse)
	    lprintf (a, "[%d]PARSE: AddNode: +%02d %*s Attribut parent=%d node=%d type=%d text=%*.*s (#%d) %s\n", 
	    a -> pThread -> nPid, nLevel, nLevel * 2, "", xParent, xNdx, nType, sText?nTextLen:0, sText?nTextLen:1000, sText?sText:Ndx2String (nTextLen), sText?String2NdxNoInc (a, sText, nTextLen):nTextLen, sLogMsg?sLogMsg:"") ; 

	return xNdx ;
	}
    
    if ((bForceAttrValue || nType == ntypAttrValue) && 
	(pParent -> nType != ntypAttr || (pParent -> bFlags & aflgAttrChilds) == 0))
	{ 
	/* --- add value of attribute, to non attribute parent node		    */
	/*     first add dummy attribute to parent with xNoName as name index	    */
	/*     if this attribute already exist, append the new value as new _child_ */
	/*     to that attribute. This means, that an attribute can have multiple   */
	/*     child(values), in which case we set the aflgAttrChilds flag	    */

	struct tAttrData * pNew = (struct tAttrData * )pParent ; 
        int bAddChild = 0 ;
	
	if (pNew -> nType != ntypAttr)
            { /* --- parent is not a attribute --- */   
	    if (nType == ntypAttrValue)
		{
		int i ;

		for (i = 0; i < nTextLen; i++)
		    {
		    if (!isspace (sText[i]))
			break ;
		    }
		
		if (i == nTextLen)
		    return 1 ; /* do not add only spaces as cdata inside a tag */
		}

	    pNew = ((tAttrData *)(pParent + 1)) + pParent -> numAttr - 1 ; /* get last attribute of node */
	    if (pParent -> numAttr == 0 || pNew -> xName != xNoName || bForceAttrValue > 1)
		{ /* --- add dummy attribute --- */
		if (!(xParent = Node_appendChild (a, pDomTree, xParent, nRepeatLevel, ntypAttr, 0, NULL, xNoName, nLevel, nLinenumber, "<noname>")))
		    return 0 ;
		nLevel++ ;
		pNew = Attr_self (pDomTree, xParent) ;  
                }
	    else
		{ /* --- dummy attribute already exist, reuse it --- */
		xParent = pNew -> xNdx ;
		bAddChild = 1 ;
		nLevel++ ;
		}
	    }
        
        
        if (!bAddChild && !bForceAttrValue)
	    { /* we have an simple attribute, now put the value into it */
	    pNew -> xValue  = sText?String2NdxNoInc (a, sText, nTextLen):nTextLen ;
	    NdxStringRefcntInc (a, pNew -> xValue) ;
	    if ((a -> pCurrReq?a -> pCurrReq -> Component.Config.bDebug:a -> Config.bDebug) & dbgParse)
		lprintf (a, "[%d]PARSE: AddNode: +%02d %*s AttributValue parent=%d node=%d type=%d text=%*.*s (#%d) %s\n", a -> pThread -> nPid, nLevel, nLevel * 2, "", xParent, pNew -> xNdx, nType, 
					   sText?nTextLen:0, sText?nTextLen:1000, sText?sText:Ndx2String (nTextLen), sText?String2NdxNoInc (a, sText, nTextLen):nTextLen, sLogMsg?sLogMsg:"") ; 
	    pNew -> bFlags |= aflgAttrValue ;

	    return xParent ;
	    }
        else
    	    /* --- we have to add a new child to the attribute, so set the attribute as parent --- */
	    pParent = (tNodeData *)pNew ;

        }

    /* --- if we come we here we have add a new child node --- */

	{
	struct tNodeData *  pNew    ;
	tIndex xOldValue = 0 ;

	if (pParent && pParent -> nType == ntypAttr)
	    { /* --- we add a new child to an attribute --- */
            if (((tAttrData *)pParent) -> bFlags & aflgAttrValue)
                {
                xOldValue = ((tAttrData *)pParent) -> xValue ;
                ((tAttrData *)pParent) -> xValue = 0 ;
                
                pNew = Node_newAndAppend (a, pDomTree, xParent, nRepeatLevel, &(((tAttrData *)pParent) -> xValue), nLinenumber, 0) ;
                pNew -> nType = ntypAttrValue ;
                pNew -> nText = xOldValue ;
                }

            ((tAttrData *)pParent) -> bFlags &= ~aflgAttrValue ;
            ((tAttrData *)pParent) -> bFlags |= aflgAttrChilds ;
            pNew = Node_newAndAppend (a, pDomTree, xParent, nRepeatLevel, &(((tAttrData *)pParent) -> xValue), nLinenumber, 0) ;
            
            }
        else
            {
            pNew = Node_newAndAppend (a, pDomTree, xParent, nRepeatLevel, pParent?&(pParent -> xChilds):NULL, nLinenumber, 0) ;
            }
        
       
	if (sText)
	    xText = String2Ndx (a, sText, nTextLen) ;
	else
	    {
	    NdxStringRefcntInc(a, nTextLen) ;
	    xText = nTextLen ;
	    }
	pNew -> nType = nType ;
        pNew -> nText = xText ;
	
	if ((a -> pCurrReq?a -> pCurrReq -> Component.Config.bDebug:a -> Config.bDebug) & dbgParse)
	    lprintf (a, "[%d]PARSE: AddNode: +%02d %*s Element parent=%d node=%d type=%d text=%*.*s (#%d) %s\n", a -> pThread -> nPid, nLevel, nLevel * 2, "", xParent, pNew -> xNdx, nType, 
	    					   sText?nTextLen:0, sText?nTextLen:1000, sText?sText:Ndx2String (nTextLen), sText?String2NdxNoInc (a, sText, nTextLen):nTextLen, sLogMsg?sLogMsg:"") ; 

	return pNew -> xNdx ;
	}
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Node_removeChild                                                         */
/*                                                                          */
/* Remove a child node                                                      */
/*                                                                          */
/* ------------------------------------------------------------------------ */



tNodeData * Node_selfRemoveChild (/*in*/ tApp * a, 
                                  /*in*/ tDomTree *     pDomTree,
			          /*in*/ tNode	        xParent,
			          /*in*/ tNodeData *	pChild)

    {
    struct tNodeData *	pParent = Node_self (pDomTree, pChild -> xParent) ;
    
    if (pChild -> xNext == pChild -> xNdx)
        { /* --- the only child --- */
        pParent -> xChilds = 0 ;
        }
    else 
        {
        tNodeData * pPrev = Node_self (pDomTree, pChild -> xPrev) ;
        tNodeData * pNext = Node_self (pDomTree, pChild -> xNext) ;

        if (pParent -> xChilds == pChild -> xNdx)
            { /* --- the first child --- */
            pParent -> xChilds = pChild -> xNext ;
            }

        if (pPrev && pPrev -> xNext == pChild -> xNdx)
	    {
	    tNodeData * pNextL = Node_selfLevel (a, pDomTree, pChild -> xNext, pChild -> nRepeatLevel) ;
	    pPrev -> xNext = pNextL -> xNdx ;
	    }
        if (pNext && pNext -> xPrev == pChild -> xNdx)
	    {
	    tNodeData * pPrevL = Node_selfLevel (a, pDomTree, pChild -> xPrev, pChild -> nRepeatLevel) ;
	    pNext -> xPrev = pPrevL -> xNdx ;
	    }
        }

    
    pDomTree -> pLookup[pChild -> xNdx].pLookup = NULL ;
    
	{
	tRepeatLevelLookup * pLookupLevelNode = pDomTree -> pLookup[pChild -> xNdx].pLookupLevel ;
	if (pLookupLevelNode)
	    {
	    register tRepeatLevelLookupItem * pLookupLevelNodeLevel	= &pLookupLevelNode -> items[pChild -> nRepeatLevel & pLookupLevelNode -> nMask] ;
	    tRepeatLevelLookupItem * pLast = NULL ;
	    while (pLookupLevelNodeLevel && pLookupLevelNodeLevel -> pNode != pChild) 
		{
		pLast = pLookupLevelNodeLevel ;
		pLookupLevelNodeLevel = pLookupLevelNodeLevel -> pNext ;
		}

	    if (pLookupLevelNodeLevel)
		{
		if (pLast)
		    {
		    pLast -> pNext = pLookupLevelNodeLevel -> pNext ;
		    dom_free_size (a, pLookupLevelNodeLevel, sizeof (tRepeatLevelLookupItem), &numLevelLookupItem) ;
		    }
		else if (pLookupLevelNodeLevel -> pNext)
		    {
		    pLast = pLookupLevelNodeLevel -> pNext ;
		    pLookupLevelNodeLevel -> pNode = pLast -> pNode ;
		    pLookupLevelNodeLevel -> pNext = pLast -> pNext ;
		    dom_free_size (a, pLast, sizeof (tRepeatLevelLookupItem), &numLevelLookupItem) ;
		    }
		else
		    {
		    pLookupLevelNodeLevel -> pNode = NULL ;
		    }
		}
	    if (pLookupLevelNode -> xNullNode != pChild -> xNdx)
		pDomTree -> pLookup[pChild -> xNdx].pLookupLevel = NULL ;
	    }    
	
	}

    dom_free (a, pChild, &numNodes) ;

    return NULL ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Node_removeChild                                                         */
/*                                                                          */
/* Remove a child node                                                      */
/*                                                                          */
/* ------------------------------------------------------------------------ */



tNode Node_removeChild (/*in*/ tApp * a, 
                        /*in*/ tDomTree *       pDomTree,
			/*in*/ tNode		xParent,
			/*in*/ tNode		xChild,
                        /*in*/ tRepeatLevel     nRepeatLevel)

    {
    Node_selfRemoveChild (a, pDomTree, xParent, Node_selfLevel (a, pDomTree, xChild, nRepeatLevel)) ;
    return 0 ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Node_replaceChild                                                        */
/*                                                                          */
/* Replaces the node pointed by pOldChildDomTree/xOldChild/nOldRepeatLevel, */
/* with the node pointed by pDomTree/xNode/nRepeatLevel                     */
/*                                                                          */
/* ------------------------------------------------------------------------ */



tNode Node_replaceChildWithNode (/*in*/ tApp * a, 
                                 /*in*/ tDomTree *      pDomTree,
				 /*in*/ tNode		xNode,
                                 /*in*/ tRepeatLevel    nRepeatLevel,
                                 /*in*/ tDomTree *      pOldChildDomTree,
				 /*in*/ tNode		xOldChild,
                                 /*in*/ tRepeatLevel    nOldRepeatLevel)

    {
    epaTHX_
    tNodeData *	pNode      = Node_selfLevel (a, pDomTree, xNode, nRepeatLevel) ;
    tNodeData *	pOldChild   = Node_selfCondCloneNode (a, pOldChildDomTree, Node_selfLevel (a, pOldChildDomTree, xOldChild, nOldRepeatLevel), nOldRepeatLevel) ; 
    int	    len  = sizeof (tNodeData) + pNode -> numAttr * sizeof (tAttrData) ; 
    int	    numAttr = pOldChild -> numAttr ;
    tAttrData * pAttr  ;
    int         n      ;
    tLookupItem * pLookup  ;

	
    pOldChild  = Node_selfExpand (a, pOldChildDomTree, pOldChild, 0, pNode -> numAttr) ;
    
    if (pOldChild -> nText)
	NdxStringFree (a, pOldChild -> nText) ;

    pAttr = ((struct tAttrData * )(pOldChild + 1))  ;
    n     = pOldChild -> numAttr ;

    while (n > 0)
	{
	if (pAttr -> xName)
	    NdxStringFree (a, pAttr -> xName) ;
	if (pAttr -> xValue && (pAttr -> bFlags & aflgAttrValue))
	    NdxStringFree (a, pAttr -> xValue) ;
	n-- ;
	pAttr++ ;
	}

    memcpy (pOldChild, pNode, len) ;

    if (pOldChild -> nText)
	NdxStringRefcntInc (a, pOldChild -> nText) ;
    

    pOldChild -> xDomTree = pDomTree -> xNdx ;
    pOldChild -> xNdx       = xOldChild ;

    pAttr = ((struct tAttrData * )(pOldChild + 1))  ;
    n     = pNode -> numAttr ;
    pLookup = pDomTree -> pLookup ;


    while (n > 0)
	{
	if (pAttr -> xName)
	    NdxStringRefcntInc (a, pAttr -> xName) ;
	if (pAttr -> xValue && (pAttr -> bFlags & aflgAttrValue))
	    NdxStringRefcntInc  (a, pAttr -> xValue) ;
	pLookup[pAttr -> xNdx].pLookup = pAttr ;
	n-- ;
	pAttr++ ;
	}
    
    pAttr = ((struct tAttrData * )(pOldChild + 1)) + pOldChild -> numAttr ;
    n     = numAttr - pNode -> numAttr ;

    while (n > 0)
	{
	pAttr -> bFlags = nflgDeleted ;
	if (pAttr -> xName)
	    NdxStringFree (a, pAttr -> xName) ;
	if (pAttr -> xValue && (pAttr -> bFlags & aflgAttrValue))
	    NdxStringFree (a, pAttr -> xValue) ;
	n-- ;
	pAttr++ ;
	}

    if (pOldChild -> nType == ntypDocument)
        {
        pOldChild -> nType = ntypDocumentFraq ;
	if (pOldChild -> nText != xDocumentFraq)
	    {
	    NdxStringFree (a, pOldChild -> nText) ;
	    pOldChild -> nText = xDocumentFraq ;
	    NdxStringRefcntInc (a, xDocumentFraq) ;
	    }
        }

    if (pOldChild -> nType == ntypDocumentFraq)
	{
	tAttrData * pAttr = Element_selfSetAttribut (a, pOldChildDomTree, pOldChild, nOldRepeatLevel, NULL, xDomTreeAttr, (char *)&pDomTree -> xNdx, sizeof (pDomTree -> xNdx)) ;
	pAttr -> bFlags = aflgOK ; /* reset string value flag */
	}

    if (pOldChildDomTree -> xNdx != pDomTree -> xNdx)
	{
	if ((a -> pCurrReq?a -> pCurrReq -> Component.Config.bDebug:a -> Config.bDebug) & dbgDOM)
	    lprintf (a, "[%d]DOM: DomTree %d depends on DomTree %d\n", a -> pThread -> nPid, pOldChildDomTree -> xNdx, pDomTree -> xNdx) ; 
        av_push (pOldChildDomTree -> pDependsOn, SvREFCNT_inc (pDomTree -> pDomTreeSV)) ;
	}
    
    return pOldChild -> xNdx ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Node_insertBefore                                                        */
/*                                                                          */
/* Inserts a child node before another node                                 */
/*                                                                          */
/* ------------------------------------------------------------------------ */


tNode Node_insertBefore_CDATA    (/*in*/ tApp * a, 
                                 /*in*/ const char *    sText,
				 /*in*/ int             nTextLen,
			         /*in*/ int		nEscMode,
                                 /*in*/ tDomTree *      pRefNodeDomTree,
				 /*in*/ tNode		xRefNode,
                                 /*in*/ tRepeatLevel    nRefRepeatLevel)

    {
    tNodeData *	pRefNode      = Node_selfLevel (a, pRefNodeDomTree, xRefNode, nRefRepeatLevel) ;
    tNodeData *	pPrevNode      = Node_selfPreviousSibling (a, pRefNodeDomTree, pRefNode, nRefRepeatLevel) ;


    tNodeData * pNew = Node_newAndAppend (a, pRefNodeDomTree, pRefNode -> xParent, nRefRepeatLevel, NULL, pRefNode -> nLinenumber, sizeof (tNodeData)) ;        

    pNew -> xChilds = 0 ;
    pNew -> bFlags  = 0 ; 
        
    if (nEscMode != -1)
	{
        pNew -> nType  = (nEscMode & 8)?ntypText:((nEscMode & 3)?ntypTextHTML:ntypCDATA) ;
	pNew -> bFlags &= ~(nflgEscUTF8 + nflgEscUrl + nflgEscChar) ;
	pNew -> bFlags |= (nEscMode ^ nflgEscChar) & (nflgEscUTF8 + nflgEscUrl + nflgEscChar) ;
	}
    else
	pNew -> nType  = ntypCDATA ;

    pNew -> nText = String2Ndx (a, sText, nTextLen) ;

    
    pRefNode  = Node_selfCondCloneNode (a, pRefNodeDomTree, pRefNode, nRefRepeatLevel) ; 
    if (pPrevNode)
        pPrevNode  = Node_selfCondCloneNode (a, pRefNodeDomTree, pPrevNode, nRefRepeatLevel) ; 
    else
        {
        tNodeData * pParent  ;

        if ((pParent = Node_selfLevel (a, pRefNodeDomTree, pRefNode -> xParent, nRefRepeatLevel)) == NULL ||
            pParent -> xChilds != pRefNode -> xPrev)
            pPrevNode = Node_selfLevel (a, pRefNodeDomTree, pRefNode -> xPrev, nRefRepeatLevel) ; /* first one */
        else
            pPrevNode = NULL ;
        }

    if (pPrevNode)
        {
        pPrevNode -> xNext = pNew -> xNdx ;
        pNew -> xPrev = pPrevNode -> xNdx ;
        }
    else
        pNew -> xPrev = pRefNode -> xPrev ;
    pRefNode -> xPrev = pNew -> xNdx ;
    pNew -> xNext = pRefNode -> xNdx ;

    return pNew -> xNdx ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Node_insertAfter                                                         */
/*                                                                          */
/* Inserts a child node after another node                                  */
/*                                                                          */
/* ------------------------------------------------------------------------ */

tNode Node_insertAfter          (/*in*/ tApp * a, 
                                 /*in*/ tDomTree *      pNewNodeDomTree,
				 /*in*/ tNode		xNewNode,
                                 /*in*/ tRepeatLevel    nNewRepeatLevel,
                                 /*in*/ tDomTree *      pRefNodeDomTree,
				 /*in*/ tNode		xRefNode,
                                 /*in*/ tRepeatLevel    nRefRepeatLevel)

    {
    epaTHX_
    tNodeData *	pNewNode      = Node_selfLevel (a, pNewNodeDomTree, xNewNode, nNewRepeatLevel) ;
    tNodeData *	pRefNode      = Node_selfLevel (a, pRefNodeDomTree, xRefNode, nRefRepeatLevel) ;
    tNodeData *	pNxtNode      = Node_selfNextSibling (a, pRefNodeDomTree, pRefNode, nRefRepeatLevel) ;


    if (pNewNodeDomTree != pRefNodeDomTree)
        {
        tNodeData * pNew = Node_newAndAppend (a, pRefNodeDomTree, pRefNode -> xParent, nRefRepeatLevel, NULL, pNewNode -> nLinenumber, sizeof (tNodeData) /* + pNewNode -> numAttr * sizeof (tAttrData) (attributes are NOT copied !!)*/) ;        

        pNew -> nText   = pNewNode -> nText ;
        pNew -> xChilds = pNewNode -> xChilds ;
        pNew -> nType   = pNewNode -> nType ;
        pNew -> bFlags  = pNewNode -> bFlags  ;
        
        if (pNew -> nText)
	    NdxStringRefcntInc (a, pNew -> nText) ;
        pNewNode = pNew ;
        }    
    
    pRefNode  = Node_selfCondCloneNode (a, pRefNodeDomTree, pRefNode, nRefRepeatLevel) ; 
    if (pNxtNode)
        pNxtNode  = Node_selfCondCloneNode (a, pRefNodeDomTree, pNxtNode, nRefRepeatLevel) ; 
    else
        {
        tNodeData * pParent  ;

        if ((pParent = Node_selfLevel (a, pRefNodeDomTree, pRefNode -> xParent, nRefRepeatLevel)) == NULL ||
            pParent -> xChilds != pRefNode -> xNext)
            pNxtNode = Node_selfLevel (a, pRefNodeDomTree, pRefNode -> xNext, nRefRepeatLevel) ; /* first one */
        else
            pNxtNode = NULL ;
        }

    if (pNxtNode)
        {
        pNxtNode -> xPrev = pNewNode -> xNdx ;
        pNewNode -> xNext = pNxtNode -> xNdx ;
        }
    else
        pNewNode -> xNext = pRefNode -> xNext ;
    pRefNode -> xNext = pNewNode -> xNdx ;
    pNewNode -> xPrev = pRefNode -> xNdx ;

    if (pNewNode -> nType == ntypDocument)
        {
        pNewNode -> nType = ntypDocumentFraq ;
	if (pNewNode -> nText != xDocumentFraq)
	    {
	    NdxStringFree (a, pNewNode -> nText) ;
	    pNewNode -> nText = xDocumentFraq ;
	    NdxStringRefcntInc (a, xDocumentFraq) ;
	    }
        }

    if (pNewNode -> nType == ntypDocumentFraq)
	{
	tAttrData * pAttr = Element_selfSetAttribut (a, pRefNodeDomTree, pNewNode, nRefRepeatLevel, NULL, xDomTreeAttr, (char *)&pNewNodeDomTree -> xNdx, sizeof (pNewNodeDomTree -> xNdx)) ;
	pAttr -> bFlags = aflgOK ; /* reset string value flag */
	}

    if (pRefNodeDomTree -> xNdx != pNewNodeDomTree -> xNdx)
	{
	if ((a -> pCurrReq?a -> pCurrReq -> Component.Config.bDebug:a -> Config.bDebug) & dbgDOM)
	    lprintf (a, "[%d]DOM: DomTree %d depends on DomTree %d\n", a -> pThread -> nPid, pRefNodeDomTree -> xNdx, pNewNodeDomTree -> xNdx) ; 
        av_push (pRefNodeDomTree -> pDependsOn, SvREFCNT_inc (pNewNodeDomTree -> pDomTreeSV)) ;
	}

    return pNewNode -> xNdx ;
    }



    
/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Node_insertAfter_CDATA                                                   */
/*                                                                          */
/* Inserts a cdata after another node                                       */
/*                                                                          */
/* ------------------------------------------------------------------------ */

tNode Node_insertAfter_CDATA    (/*in*/ tApp * a, 
                                 /*in*/ const char *    sText,
				 /*in*/ int             nTextLen,
			         /*in*/ int		nEscMode,
                                 /*in*/ tDomTree *      pRefNodeDomTree,
				 /*in*/ tNode		xRefNode,
                                 /*in*/ tRepeatLevel    nRefRepeatLevel)

    {
    tNodeData *	pRefNode      = Node_selfLevel (a, pRefNodeDomTree, xRefNode, nRefRepeatLevel) ;
    tNodeData *	pNxtNode      = Node_selfNextSibling (a, pRefNodeDomTree, pRefNode, nRefRepeatLevel) ;


    tNodeData * pNew = Node_newAndAppend (a, pRefNodeDomTree, pRefNode -> xParent, nRefRepeatLevel, NULL, pRefNode -> nLinenumber, sizeof (tNodeData)) ;        

    pNew -> xChilds = 0 ;
    pNew -> bFlags  = 0 ; 
        
    if (nEscMode != -1)
	{
        pNew -> nType  = (nEscMode & 8)?ntypText:((nEscMode & 3)?ntypTextHTML:ntypCDATA) ;
	pNew -> bFlags &= ~(nflgEscUTF8 + nflgEscUrl + nflgEscChar) ;
	pNew -> bFlags |= (nEscMode ^ nflgEscChar) & (nflgEscUTF8 + nflgEscUrl + nflgEscChar) ;
	}
    else
	pNew -> nType  = ntypCDATA ;

    pNew -> nText = String2Ndx (a, sText, nTextLen) ;

    
    pRefNode  = Node_selfCondCloneNode (a, pRefNodeDomTree, pRefNode, nRefRepeatLevel) ; 
    if (pNxtNode)
        pNxtNode  = Node_selfCondCloneNode (a, pRefNodeDomTree, pNxtNode, nRefRepeatLevel) ; 
    else
        {
        tNodeData * pParent  ;

        if ((pParent = Node_selfLevel (a, pRefNodeDomTree, pRefNode -> xParent, nRefRepeatLevel)) == NULL ||
            pParent -> xChilds != pRefNode -> xNext)
            pNxtNode = Node_selfLevel (a, pRefNodeDomTree, pRefNode -> xNext, nRefRepeatLevel) ; /* first one */
        else
            pNxtNode = NULL ;
        }

    if (pNxtNode)
        {
        pNxtNode -> xPrev = pNew -> xNdx ;
        pNew -> xNext = pNxtNode -> xNdx ;
        }
    else
        pNew -> xNext = pRefNode -> xNext ;
    pRefNode -> xNext = pNew -> xNdx ;
    pNew -> xPrev = pRefNode -> xNdx ;

    return pNew -> xNdx ;
    }



    







/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Node_replaceChild                                                        */
/*                                                                          */
/* Replace child node                                                       */
/*                                                                          */
/* ------------------------------------------------------------------------ */

tNode Node_replaceChildWithCDATA (/*in*/ tApp * a, 
                                  /*in*/ tDomTree *	 pDomTree,
				  /*in*/ tNode		 xOldChild,
                                  /*in*/ tRepeatLevel    nRepeatLevel,
                                  /*in*/ const char *	 sText,
				  /*in*/ int		 nTextLen,
				  /*in*/ int		 nEscMode,
				  /*in*/ int		 bFlags)

    {
    tNodeData *	pOldChild  ;
    tStringIndex n ;
    
    numReplace++ ;

    /* *** lprintf (a, "rp1--> SVs=%d  %s  DomTree Old=%d\n", sv_count, sText?sText:"<null>", Node_selfDomTree (Node_self (pDomTree, xOldChild))) ; */

    pOldChild  = Node_selfCondCloneNode (a, pDomTree, Node_selfLevel (a, pDomTree, xOldChild, nRepeatLevel), nRepeatLevel) ; 

    if (nEscMode != -1)
	{
        pOldChild -> nType  = (nEscMode & 8)?ntypText:((nEscMode & 3)?ntypTextHTML:ntypCDATA) ;
	pOldChild -> bFlags &= ~(nflgEscUTF8 + nflgEscUrl + nflgEscChar) ;
	pOldChild -> bFlags |= (nEscMode ^ nflgEscChar) & (nflgEscUTF8 + nflgEscUrl + nflgEscChar) ;
	}
    else
	pOldChild -> nType  = ntypCDATA ;

    n = pOldChild -> nText ;
    pOldChild -> nText = String2Ndx (a, sText, nTextLen) ;
    pOldChild -> xChilds = 0 ;
    pOldChild -> bFlags |= bFlags ;
    if (n)
	NdxStringFree (a, n) ;

    /* *** lprintf (a, "rp<-- nText=%d sText=>%*.*s< nTextLen = %d  SVs=%d\n", pOldChild -> nText, nTextLen,nTextLen, sText?sText:"<null>",  nTextLen, sv_count) ; */
    return pOldChild -> xNdx ;
    }




/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Node_selfLastChild                                                       */
/*                                                                          */
/* Get last child node							    */
/*                                                                          */
/* ------------------------------------------------------------------------ */


tNodeData * Node_selfLastChild   (/*in*/ tApp * a, 
                                  /*in*/  tDomTree *   pDomTree,
				  /*in*/  tNodeData *  pNode, 
                                  /*in*/  tRepeatLevel nRepeatLevel)

    {
    if (pNode -> xChilds)
        return Node_selfLevel (a, pDomTree, Node_selfFirstChild (a, pDomTree, pNode, nRepeatLevel) -> xPrev, nRepeatLevel) ;
    
    return 0 ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Node_selfNthChild (pNode, nChildNo) ;                                    */
/*                                                                          */
/* Get nth child node							    */
/*                                                                          */
/* ------------------------------------------------------------------------ */


struct tNodeData * Node_selfNthChild (/*in*/ tApp * a, 
                                      /*in*/  tDomTree *        pDomTree,
				      /*in*/ struct tNodeData * pNode,
                                      /*in*/  tRepeatLevel      nRepeatLevel,
				      /*in*/ int		nChildNo) 

    {
    if (pNode -> xChilds)
        {
        tNodeData * pChild  ;
        tNodeData * pFirstChild = Node_selfFirstChild (a, pDomTree, pNode, nRepeatLevel) ;

        if (nChildNo == 0)
            return pFirstChild ;
        
        
        pChild = pFirstChild ;

        do
            {
            pChild = Node_selfNotNullLevel (a, pDomTree, pChild -> xNext, nRepeatLevel) ;
            if (nChildNo-- < 2)
                return pChild ;
            }
        while (nChildNo > 1 && pChild != pFirstChild) ;
        }

    return 0 ;
    }



/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Node_nextSibling (xNode) ;                                               */
/*                                                                          */
/* Get next sibling node						    */
/*                                                                          */
/* ------------------------------------------------------------------------ */


tNodeData * Node_selfNextSibling (/*in*/ tApp * a, 
                                  /*in*/ tDomTree *  pDomTree,
			          /*in*/ tNodeData * pNode, 
                                  /*in*/  tRepeatLevel nRepeatLevel)

    {
    tNodeData * pParent  ;
    tNodeData * pNxt ;

    if (pNode -> nType == ntypAttr || pNode -> xNext == pNode -> xNdx)
        return NULL ;
    
    if ((pParent = Node_selfLevel (a, pDomTree, pNode -> xParent, nRepeatLevel)) != NULL)
        {
        if (pParent -> xChilds == pNode -> xNext)
            return NULL ;
        }

    if (pNode -> bFlags & nflgNewLevelNext)
	pNxt = Node_self (pDomTree, pNode -> xNext) ; 
    else
	pNxt = Node_selfLevel (a, pDomTree, pNode -> xNext, nRepeatLevel) ; 
    
    /*
    if (pParent && pNxt -> nRepeatLevel)
        {
        if (pParent -> xChilds == xNode_selfLevelNull(pDomTree,pNxt) )
            return NULL ;
        }
    */

    if (!pParent)
        {
        if (pNxt -> nType == ntypDocumentFraq)
            return NULL ;
        }
    return pNxt ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Node_nextSibling (xNode) ;                                               */
/*                                                                          */
/* Get next sibling node						    */
/*                                                                          */
/* ------------------------------------------------------------------------ */


tNode Node_nextSibling (/*in*/ tApp * a, 
                        /*in*/ tDomTree *   pDomTree,
			/*in*/ tNode        xNode, 
                        /*in*/ tRepeatLevel nRepeatLevel)


    {
    tNodeData * pNode = Node_selfNotNullLevel (a, pDomTree, xNode, nRepeatLevel) ;
    tNodeData * pParent  ;

    if (pNode -> nType == ntypAttr || pNode -> xNext == pNode -> xNdx)
        return 0 ;
    
    pParent = Node_selfLevel (a, pDomTree, pNode -> xParent, nRepeatLevel) ;
    if (pParent -> xChilds == pNode -> xNext)
        return 0 ;
    
    return pNode -> xNext ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Node_previousSibling (xNode) ;                                           */
/*                                                                          */
/* Get previous sibling node						    */
/*                                                                          */
/* ------------------------------------------------------------------------ */


tNodeData * Node_selfPreviousSibling (/*in*/ tApp * a, 
                                      /*in*/ tDomTree *  pDomTree,
			          /*in*/ tNodeData * pNode, 
                                  /*in*/  tRepeatLevel nRepeatLevel)

    {
    tNodeData * pParent  ;

    if (pNode -> nType == ntypAttr || pNode -> xPrev == pNode -> xNdx)
        return 0 ;
    
    pParent = Node_selfLevel (a, pDomTree, pNode -> xParent, nRepeatLevel) ;
    if (pParent -> xChilds == pNode -> xNdx)
        return 0 ;
    
    if (pNode -> bFlags & nflgNewLevelPrev)
	return Node_self (pDomTree, pNode -> xPrev) ; 
    else
	return Node_selfLevel (a, pDomTree, pNode -> xPrev, nRepeatLevel) ; 
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Node_previousSibling (xNode) ;                                           */
/*                                                                          */
/* Get previous sibling node						    */
/*                                                                          */
/* ------------------------------------------------------------------------ */


tNode Node_previousSibling (/*in*/ tApp * a, 
                            /*in*/ tDomTree *   pDomTree,
			    /*in*/ tNode        xNode, 
                            /*in*/ tRepeatLevel nRepeatLevel)


    {
    tNodeData * pNode = Node_selfNotNullLevel (a, pDomTree, xNode, nRepeatLevel) ;
    tNodeData * pParent  ;

    if (pNode -> nType == ntypAttr || pNode -> xPrev == pNode -> xNdx)
        return 0 ;
    
    pParent = Node_selfLevel (a, pDomTree, pNode -> xParent, nRepeatLevel) ;
    if (pParent -> xChilds == pNode -> xNdx)
        return 0 ;
    
    return pNode -> xPrev ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Node_childsText (a, xNode) ;                                                */
/*                                                                          */
/* Get the text of all child nodes in one string			    */
/*                                                                          */
/* ------------------------------------------------------------------------ */


char * Node_childsText (/*in*/ tApp * a, 
                        /*in*/ tDomTree *  pDomTree,
		       /*in*/  tNode       xNode,
                       /*in*/ tRepeatLevel nRepeatLevel,
		       /*i/o*/ char * *    ppText,
		       /*in*/  int         bDeep) 

    {
    tNodeData * pParent = Node_selfLevel (a, pDomTree, xNode, nRepeatLevel) ;
    tNodeData * pNode  ;
    char *      sNodeText ;
    char *      sText = ppText?*ppText:NULL ;

    if (pParent)
	{
	if (sText == NULL)
	    StringNew (a, &sText, 1024) ;
	pNode = Node_selfFirstChild (a, pDomTree, pParent, nRepeatLevel) ;
	while (pNode)
	    {
	    sNodeText = Node_selfNodeName(pNode) ;
	    StringAdd (a, &sText, sNodeText, 0) ;
	    
	    if (bDeep)
		Node_childsText (a, pDomTree, pNode -> xNdx, nRepeatLevel, &sText, 1) ;

	    pNode = Node_selfNextSibling (a, pDomTree, pNode, nRepeatLevel) ;
	    }

	}
    if (ppText)
	*ppText = sText ;
    return sText ;
    }




/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Node_toString                                                            */
/*                                                                          */
/*                                                                          */
/*                                                                          */
/* ------------------------------------------------------------------------ */



static tNodeData * Node_toString2 (/*i/o*/ register req *   r,
				   /*in*/  tDomTree *	    pDomTree,
				   /*in*/  tNode	    xNode,
				   /*in*/ tRepeatLevel *    pRepeatLevel) 
				  


    {
    epTHX_
    tApp * a = r -> pApp ;
    tRepeatLevel nRepeatLevel = *pRepeatLevel ;
    tNodeData * pNode = Node_self (pDomTree, xNode) ;
    tNodeData * pLast ;
    struct tCharTrans * pChar2Html  ;

    if (!pNode)
        return NULL ;
            
    if (r -> Config.nOutputEscCharset == ocharsetLatin1)
    	pChar2Html = Char2Html ;
    else if (r -> Config.nOutputEscCharset == ocharsetLatin2)
    	pChar2Html = Char2HtmlLatin2 ;
    else
    	pChar2Html = Char2HtmlMin ;
    
    
    if (pNode -> nType == ntypDocumentFraq)
	{
	int o        = pDomTree -> xNdx ;
        tAttrData *  pAttr = Element_selfGetAttribut (a, pDomTree, pNode, NULL, xDomTreeAttr) ;
        if (pAttr)
            {
            char * p ;
            char * pNdx ;

            pNdx = Attr_selfValue(a, pDomTree, pAttr, nRepeatLevel, &p) ;
            pDomTree = DomTree_self (*(tIndexShort *)pNdx) ;
            }

        if (r -> Component.Config.bDebug & dbgOutput)
	    lprintf (a,  "[%d]toString: ** Switch from DomTree=%d to new DomTree=%d\n", r -> pThread -> nPid, o, pDomTree -> xNdx) ; 
		
	}
    

    pNode = Node_selfFirstChild (a, pDomTree, pNode, nRepeatLevel) ;


    while (pNode)
	{
        if (pNode -> bFlags & nflgStopOutput)
            {
            if (r -> Component.Config.bDebug & dbgOutput)
	        lprintf (a,  "[%d]toString: Node=%d(%d) RepeatLevel=%d type=%d flags=%x -> stop output\n", r -> pThread -> nPid, pNode -> xNdx, xNode_selfLevelNull(pDomTree,pNode), nRepeatLevel, pNode -> nType,  pNode -> bFlags) ; 

            return NULL ;
            }

        if (r -> Component.Config.bDebug & dbgOutput)
	    lprintf (a,  "[%d]toString: Node=%d(%d) RepeatLevel=%d type=%d flags=%x text=>%s<= (#%d) SVs=%d\n", r -> pThread -> nPid, pNode -> xNdx, xNode_selfLevelNull(pDomTree,pNode), nRepeatLevel, pNode -> nType,  pNode -> bFlags, Ndx2String (pNode -> nText), pNode -> nText, sv_count) ; 

	if (pNode -> nType == ntypDocumentFraq)
	    {
            Node_toString (r, pDomTree, pNode -> xNdx, 0) ; 
	    }
	else
            {
            if (pNode -> bFlags & nflgIgnore)
                ;
            else if (pNode -> nType == ntypTag || pNode -> nType == ntypStartTag || pNode -> nType == ntypProcessingInstr)
	        {
	        int n = pNode -> numAttr ;
	        struct tAttrData * pAttr = (struct tAttrData *)(pNode + 1) ;
	        char * pNodeName = Node_selfNodeName (pNode) ;
	        char * pNodeStart ;
	        char * pNodeEnd ;
	        char * p ;
	        int    nNodeStartLen ;
	        int    nNodeEndLen ;
	        int    nNodeNameLen ;
	        int    nLastLen ;
	        
	        if (*pNodeName)
		    {
		    if (*pNodeName == ':')
		        {
		        pNodeStart = ++pNodeName ;
		        nNodeStartLen = 0 ;
		        nNodeEndLen   = 0 ;
		        while (*pNodeName && *pNodeName != ':')
			    {
			    nNodeStartLen++ ;
			    pNodeName++ ;
			    }
		        if (*pNodeName == ':')
			    {
			    pNodeEnd = ++pNodeName ;
			    while (*pNodeName && *pNodeName != ':')
			        {
			        nNodeEndLen++ ;
			        pNodeName++ ;
			        }
			    }
                        else
                            pNodeEnd = "" ;
		        if (*pNodeName == ':')
			    pNodeName++ ;
		        
		        nNodeNameLen = 0 ;
		        p = pNodeName ;
		        while (*p && *p != ':')
			    {
			    p++ ;
			    nNodeNameLen++ ;
			    }
		        }
		    else if (pNode -> nType == ntypProcessingInstr)
                        {
		        pNodeStart = "<?" ;
		        pNodeEnd = "?>" ;
		        nNodeStartLen = 2 ;
		        nNodeEndLen = 2 ;
		        nNodeNameLen = strlen (pNodeName) ;
                        }
                    else
		        {
		        nNodeStartLen = 1 ;
                        nNodeEndLen = r -> Config.nOutputMode == omodeXml && pNode -> nType == ntypTag?3:1 ;
		        nNodeNameLen = strlen (pNodeName) ;
                        pNodeStart = "<" ;
                        pNodeEnd = nNodeEndLen == 3?" />":">" ;
		        }

		    owrite (r, pNodeStart, nNodeStartLen) ;
		    owrite (r, pNodeName, nNodeNameLen) ;
		    if (*pNodeName)
		        nLastLen = 1 ;
		    else
		        nLastLen = 0 ;
		    
		    while (n--)
		        {
		        if (pAttr -> bFlags)
			    {
			    char * s ;
			    int    l ;
			    if (nLastLen)
			        {				
			        oputc (r, ' ') ;
			        nLastLen = 0 ;
			        }
			    if (pAttr -> xName != xNoName)
			        {
			        Ndx2StringLen (pAttr -> xName,s,l) ;
			        owrite (r, s, l);
			        nLastLen += l ;
			        }

			    if (pAttr -> xValue)
			        {
			        if (pAttr -> xName != xNoName)
                                    {
                                    if (pAttr -> bFlags & aflgSingleQuote)
				        oputs (r, "='") ;
				    else
				        oputs (r, "=\"") ;
                                    }
			        if (pAttr -> bFlags & aflgAttrChilds)
				    {
				    tAttrData * pAttrNode = (tAttrData * )Node_toString2 (r, pDomTree, pAttr -> xNdx, &nRepeatLevel) ;
				    if (pAttrNode && pAttrNode != pAttr)
				        {
				        pAttr = pAttrNode ;
				        pNode = Attr_selfNode(pAttr) ;
				        n = pNode -> numAttr - Attr_selfAttrNum (pAttr) - 1 ;
				        if (n < 0)
					    n = 0 ;
				        }
				    nLastLen++ ;
				    }
			        else
				    {
				    Ndx2StringLen (pAttr -> xValue, s, l) ;
				    while (isspace (*s) && l > 0)
				        s++, l-- ;
                                    /*OutputEscape (r, s, l, (pAttr -> bFlags & aflgEscXML)?Char2XML:(pAttr -> bFlags & aflgEscUrl)?Char2Url:Char2Html, (char)((pAttr -> bFlags & aflgEscChar)?'\\':0)) ;*/
                                    owrite (r, s, l) ;
				    nLastLen += l ;
				    }
			        if (pAttr -> xName != xNoName)
                                    {
                                    if (pAttr -> bFlags & aflgSingleQuote)
				        oputc (r, '\'') ;
				    else
				        oputc (r, '"') ;
                                    }
			        }
			    }
		        pAttr++ ;
		        }
		    owrite (r, pNodeEnd, nNodeEndLen) ;
		    }
	        }
	    else if (pNode -> nType == ntypText)
	        {
	        char * s ;
	        int    l ;
	        Ndx2StringLen (pNode -> nText,s,l) ;
                OutputEscape (r, s, l, Char2XML, (char)((pNode -> bFlags & nflgEscChar)?'\\':0)) ;
	        }
	    else if (pNode -> nType == ntypTextHTML)
	        {
	        char * s ;
	        int    l ;
	        Ndx2StringLen (pNode -> nText,s,l) ;
                OutputEscape (r, s, l, (pNode -> bFlags & nflgEscUTF8)?(pNode -> bFlags & nflgEscUrl)?Char2Url:Char2HtmlMin:(pNode -> bFlags & nflgEscUrl)?Char2Url:pChar2Html, (char)((pNode -> bFlags & nflgEscChar)?'\\':0)) ;
	        }
	    else 
	        {
	        char * s ;
	        int    l ;
	        Ndx2StringLen (pNode -> nText,s,l) ;
	        owrite (r, s, l);
	        }

            Node_toString2 (r, pDomTree, pNode -> xNdx, &nRepeatLevel) ;

	    if (pNode -> nType == ntypStartTag && (pNode -> bFlags & nflgIgnore) == 0)
	        {
	        char * pNodeName = Node_selfNodeName (pNode) ;
    
	        if (*pNodeName == ':')
		    {
		    int i = 4 ;
		    while (i > 0 && *pNodeName)
		        if (*pNodeName++ == ':')
			    i-- ;
		    if (*pNodeName)
		        oputs (r, pNodeName) ;
		    }
	        else
		    {
		    oputs (r, "</") ;
		    oputs (r, Node_selfNodeName (pNode)) ;
                    oputc (r, '>') ;
		    }
	        }
            }

        pLast   = pNode ;
	pNode  = Node_selfNextSibling (a, pDomTree, pNode, nRepeatLevel) ;

        if (pNode && pLast -> bFlags & nflgNewLevelNext)
            nRepeatLevel = pNode -> nRepeatLevel ;

	}

    *pRepeatLevel = nRepeatLevel ;

    return NULL ;
    }


#if 0
	if (nOrderNdx == nOrderIndexNode)
	    nOrderNdx++ ;

	if (pNode -> nType == ntypDocumentFraq)
	    pNextNode = NULL ;
	else
	    pNextNode = Node_selfFirstChild (a, pDomTree, pNode, nRepeatLevel) ;
	if (pNextNode == NULL)
	    {
	    pNextNode  = Node_selfNextSibling (a, pDomTree, pNode, nRepeatLevel) ;
	    while (pNextNode == NULL)
		{
		pNextNode = Node_selfParentNode (pDomTree, pNode, nRepeatLevel) ;
		if (pNextNode == NULL || pNextNode  == pFirstNode || pNextNode -> nType == ntypAttr)
                    {
                    return bCheckpointFound?pNextNode:NULL ;
                    }
		    
		pNode = pNextNode ;
		pNextNode  = Node_selfNextSibling (a, pDomTree, pNextNode, nRepeatLevel) ;
		if (pNode -> nType == ntypStartTag && (pNode -> bFlags & nflgIgnore) == 0)
		    {
		    char * pNodeName = Node_selfNodeName (pNode) ;
	    
		    if (*pNodeName == ':')
			{
			int i = 4 ;
			while (i > 0 && *pNodeName)
			    if (*pNodeName++ == ':')
				i-- ;
			if (*pNodeName)
			    oputs (r, pNodeName) ;
			}
		    else
			{
			oputs (r, "</") ;
			oputs (r, Node_selfNodeName (pNode)) ;
			oputc (r, '>') ;
			}
		    pLastStartTag = Node_selfParentNode (pDomTree, pNextNode?pNextNode:pNode, nRepeatLevel) ;
		    }
		}
	    }
	pNode = pNextNode ;
	}

    *pOrderNdx = nOrderNdx ;

    return NULL ;    
    }
#endif



void Node_toString (/*i/o*/ register req *  r,
		    /*in*/ tDomTree *	    pDomTree,
		    /*in*/ tNode	    xNode,
                    /*in*/ tRepeatLevel     nRepeatLevel)


    {
    Node_toString2 (r, pDomTree, xNode, &nRepeatLevel) ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* NodeList_toString                                                            */
/*                                                                          */
/*                                                                          */
/*                                                                          */
/* ------------------------------------------------------------------------ */


void NodeList_toString (/*in*/  tDomTree *   pDomTree,
			/*in*/ tNode	    xNode)


    {
    

    }

    
/* ------------------------------------------------------------------------

interface Element : Node {
  readonly attribute DOMString        tagName;
  DOMString          getAttribute(in DOMString name);
  void               setAttribute(in DOMString name, 
                                  in DOMString value)
                                        raises(DOMException);
  void               removeAttribute(in DOMString name)
                                        raises(DOMException);
  Attr               getAttributeNode(in DOMString name);
  Attr               setAttributeNode(in Attr newAttr)
                                        raises(DOMException);
  Attr               removeAttributeNode(in Attr oldAttr)
                                        raises(DOMException);
  NodeList           getElementsByTagName(in DOMString name);
  # Introduced in DOM Level 2: 
  DOMString          getAttributeNS(in DOMString namespaceURI, 
                                    in DOMString localName);
  # Introduced in DOM Level 2: 
  void               setAttributeNS(in DOMString namespaceURI, 
                                    in DOMString qualifiedName, 
                                    in DOMString value)
                                        raises(DOMException);
  # Introduced in DOM Level 2: 
  void               removeAttributeNS(in DOMString namespaceURI, 
                                       in DOMString localName)
                                        raises(DOMException);
  # Introduced in DOM Level 2: 
  Attr               getAttributeNodeNS(in DOMString namespaceURI, 
                                        in DOMString localName);
  # Introduced in DOM Level 2: 
  Attr               setAttributeNodeNS(in Attr newAttr)
                                        raises(DOMException);
  # Introduced in DOM Level 2: 
  NodeList           getElementsByTagNameNS(in DOMString namespaceURI, 
                                            in DOMString localName);
  # Introduced in DOM Level 2: 
  boolean            hasAttribute(in DOMString name);
  # Introduced in DOM Level 2: 
  boolean            hasAttributeNS(in DOMString namespaceURI, 
                                    in DOMString localName);
};


------------------------------------------------------------------------- */

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Element_selfGetAttribut                                                  */
/*                                                                          */
/* Get attribute value of Element by name                                   */
/*                                                                          */
/* ------------------------------------------------------------------------ */



tAttrData *  Element_selfGetAttribut (/*in*/ tApp * a, 
                                      /*in*/ tDomTree *	        pDomTree,
				      /*in*/ struct tNodeData * pNode,
				      /*in*/ const char *	sAttrName,
				      /*in*/ int		nAttrNameLen) 

    {
    int nAttrName = sAttrName?String2NdxNoInc (a, sAttrName, nAttrNameLen):nAttrNameLen ;
    struct tAttrData * pAttr = (struct tAttrData * )(pNode + 1) ;
    int  n = pNode -> numAttr ;

    while (n > 0 && (nAttrName != pAttr -> xName || !pAttr -> bFlags))
	{
	n-- ;
	pAttr++ ;
	}

    if (n)
	return pAttr ;

    return NULL ;
    }



/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Element_selfGetNthAttribut                                               */
/*                                                                          */
/* Get attribute value of Element by index                                  */
/*                                                                          */
/* ------------------------------------------------------------------------ */



tAttrData *  Element_selfGetNthAttribut (/*in*/ tApp * a, 
                                         /*in*/ tDomTree *	   pDomTree,
			  	         /*in*/ struct tNodeData * pNode,
				         /*in*/ int                n)

    {
    struct tAttrData * pAttr = (struct tAttrData * )(pNode + 1) ;
    int  num = pNode -> numAttr ;

    if (n < 0 || n >= num)
        return NULL ;

    return pAttr + n ;
    }




/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Element_selfSetAttribut                                                  */
/*                                                                          */
/* Set attribute value of Element by name                                   */
/*                                                                          */
/* ------------------------------------------------------------------------ */



tAttrData *  Element_selfSetAttribut (/*in*/ tApp * a, 
                                      /*in*/ tDomTree *	        pDomTree,
				      /*in*/ struct tNodeData * pNode,
				      /*in*/ tRepeatLevel       nRepeatLevel,
				      /*in*/ const char *	sAttrName,
				      /*in*/ int		nAttrNameLen,
				      /*in*/ const char *       sNewValue, 
				      /*in*/ int		nNewValueLen) 

    {
    epaTHX_
    tAttrData * pAttr ;
    tNode xAttr ;
    tNodeData * pNewNode ;

    pNode = Node_selfCondCloneNode (a, pDomTree, pNode, nRepeatLevel) ;

    pAttr = Element_selfGetAttribut (a, pDomTree, pNode, sAttrName, nAttrNameLen) ;

    if (pAttr)
	{
	tIndex xValue = sNewValue?String2NdxNoInc (a, sNewValue, nNewValueLen):nNewValueLen ;
	NdxStringRefcntInc (a, xValue) ;

	if (pAttr -> xValue && (pAttr -> bFlags & aflgAttrValue))
	    NdxStringFree (a, pAttr -> xValue) ;

      	pAttr -> bFlags |= aflgAttrValue ;
        pAttr -> bFlags &= ~aflgAttrChilds ;

        pAttr -> xValue = xValue ;
	return pAttr ;
	}

    pNewNode = pNode ;

    
    xAttr = Node_appendChild (a, pDomTree, pNewNode -> xNdx, nRepeatLevel, ntypAttr, 0, sAttrName, nAttrNameLen, 0, pNewNode -> nLinenumber, NULL) ;
    Node_appendChild (a, pDomTree, xAttr, nRepeatLevel,  ntypAttrValue, 0, sNewValue, nNewValueLen, 0, pNewNode -> nLinenumber, NULL) ;
    return (tAttrData *)Node_self(pDomTree, xAttr) ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Element_selfRemoveAttribut                                               */
/*                                                                          */
/* Remove attribute of Element by name                                      */
/*                                                                          */
/* ------------------------------------------------------------------------ */



tAttrData *  Element_selfRemoveAttributPtr (/*in*/ tApp * a, 
                                            /*in*/ tDomTree *	        pDomTree,
				      /*in*/ struct tNodeData * pNode,
				      /*in*/ tRepeatLevel       nRepeatLevel,
				      /*in*/ tAttrData *	pAttr)

    {
    pNode = Node_selfCondCloneNode (a, pDomTree, pNode, nRepeatLevel) ;

    if (pAttr)
	{
	if (pAttr -> xName)
	    NdxStringFree (a, pAttr -> xName) ;
	if (pAttr -> xValue && (pAttr -> bFlags & aflgAttrValue))
	    NdxStringFree (a, pAttr -> xValue) ;
	pAttr -> bFlags = 0 ;
	}

    /*
    int    nCopyAttr ;

    if (pAttr)
	{
	nAttr = pAttr - ((struct tAttrData * )(pNode + 1)) ;
	pNode -> numAttr-- ;
	nCopyAttr = pNode -> numAttr - nAttr  ;
	if (nCopyAttr)
	    {
	    memcpy (pAttr, pAttr + 1, nCopyAttr * sizeof (tAttrData)) ;
	    while (nCopyAttr--)
		{
		pDomTree -> pLookup[pAttr -> xNdx] = pAttr ;
		pAttr++ ;
		}
	    }
	}
    */

    return pAttr ;
    }


tAttrData *  Element_selfRemoveAttribut (/*in*/ tApp * a, 
                                         /*in*/ tDomTree *	        pDomTree,
				      /*in*/ struct tNodeData * pNode,
				      /*in*/ tRepeatLevel       nRepeatLevel,
				      /*in*/ const char *	sAttrName,
				      /*in*/ int		nAttrNameLen)

    {
    tAttrData * pAttr ;

    pNode = Node_selfCondCloneNode (a, pDomTree, pNode, nRepeatLevel) ;

    pAttr = Element_selfGetAttribut (a, pDomTree, pNode, sAttrName, nAttrNameLen) ;

    return Element_selfRemoveAttributPtr (a, pDomTree, pNode, nRepeatLevel, pAttr) ;
    }
    
tAttrData *  Element_selfRemoveNthAttribut (/*in*/ tApp * a, 
                                            /*in*/ tDomTree *	        pDomTree,
				      /*in*/ struct tNodeData * pNode,
				      /*in*/ tRepeatLevel       nRepeatLevel,
				      /*in*/ int                n) 

    {
    tAttrData * pAttr ;

    pNode = Node_selfCondCloneNode (a, pDomTree, pNode, nRepeatLevel) ;

    pAttr = Element_selfGetNthAttribut (a, pDomTree, pNode, n) ;

    return Element_selfRemoveAttributPtr (a, pDomTree, pNode, nRepeatLevel, pAttr) ;
    }
    

/* ------------------------------------------------------------------------


interface Attr : Node {
  readonly attribute DOMString        name;
  readonly attribute boolean          specified;
           attribute DOMString        value;
                                        # raises(DOMException) on setting 

  # Introduced in DOM Level 2: 
  readonly attribute Element          ownerElement;
};

------------------------------------------------------------------------ */



/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Attr_selfValue							    */
/*                                                                          */
/*                                                                          */
/*                                                                          */
/* ------------------------------------------------------------------------ */



char *       Attr_selfValue (/*in*/ tApp * a, 
                             /*in*/  tDomTree *	        pDomTree,
			     /*in*/  struct tAttrData * pAttr,
			     /*in*/  tRepeatLevel       nRepeatLevel,
			     /*out*/ char * *		ppAttr) 

    {
    struct tNodeData * pNode ;
    struct tNodeData * pAttrNode ;
      tIndex xFirstAttr ;

    ASSERT_ATTR_VALID(a,pAttr) ;
      
      if (!pAttr || pAttr -> bFlags == aflgDeleted)
	return NULL ;
/* lprintf (a, "selvalue 1 f=%x a=%x aa=%x an=%d off=%d av=%d\n", pAttr -> bFlags , aflgAttrChilds, pAttr, pAttr -> xNdx, pAttr -> nNodeOffset, pAttr -> xValue) ; */

    pAttrNode = Attr_selfNode(pAttr) ;
    ASSERT_NODE_VALID(a,pAttrNode) ;

/* lprintf (a, "selvalue f=%x a=%x aa=%x an=%d off=%d av=%d na=%x nn=%d a\n", pAttr -> bFlags , aflgAttrChilds, pAttr, pAttr -> xNdx, pAttr -> nNodeOffset, pAttr -> xValue, pAttrNode, pAttrNode -> xNdx) ; */

   
    pNode = Node_selfLevel (a, pDomTree, pAttrNode -> xNdx, nRepeatLevel) ;
    ASSERT_NODE_VALID(a,pNode) ;

/* lprintf (a, "selvalue f=%x a=%x aa=%x an=%d off=%d av=%d na=%x nn=%d node=%x\n", pAttr -> bFlags , aflgAttrChilds, pAttr, pAttr -> xNdx, pAttr -> nNodeOffset, pAttr -> xValue, pAttrNode, pAttrNode -> xNdx, pNode) ;*/
       
    
    if (pNode != pAttrNode)
        {
        pAttr = Element_selfGetAttribut (a, pDomTree, pNode, NULL, pAttr -> xName) ;
        if (!pAttr)
	    return NULL ;
        }
    ASSERT_ATTR_VALID(a,pAttr) ;
    ASSERT_NODE_VALID(a,pNode) ;
    ASSERT_NODE_VALID(a,pAttrNode) ;

/*lprintf (a, "selvalue f=%x a=%x aa=%x an=%d off=%d av=%d na=%x nn=%d a\n", pAttr -> bFlags , aflgAttrChilds, pAttr, pAttr -> xNdx, pAttr -> nNodeOffset, pAttr -> xValue, pAttrNode, pAttrNode -> xNdx) ;*/
    if ((pAttr -> bFlags & aflgAttrChilds) == 0)
	    return Ndx2String (pAttr -> xValue) ;

    pNode = Node_selfLevel (a, pDomTree, pAttr -> xValue, nRepeatLevel) ;
    
    StringNew (a, ppAttr, 512) ;
    xFirstAttr = pNode -> xNdx ;
   
    while (pNode)
	{
	char * s ;
	int    l ;

        ASSERT_NODE_VALID(a,pNode) ;

/*lprintf (a, "selvalue f=%x node=%x nodendx=%d  aa=%x an=%d off=%d av=%d na=%x nn=%d a\n", pAttr -> bFlags , pNode, pNode -> xNdx, pAttr, pAttr -> xNdx, pAttr -> nNodeOffset, pAttr -> xValue, pAttrNode, pAttrNode -> xNdx) ;*/

    if ((pNode -> bFlags & nflgIgnore) == 0)
            {                
	    Ndx2StringLen (pNode -> nText,s,l) ;
	    StringAdd (a, ppAttr, s, l) ;
            }
	pNode = Node_selfNextSibling (a, pDomTree, pNode, nRepeatLevel) ;
        if (!pNode || pNode -> xNdx == xFirstAttr)
	            break ;
	}

    return *ppAttr ;
    }
