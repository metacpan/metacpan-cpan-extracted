#define MAX_FILTER_PLIES        4
#define NUM_OUTPUTS 5
#define NUM_ROLLOUT_OUTPUTS 7
#define MAX_INCOMPLETE_MOVES 3875


/* From dice.h */
typedef enum _rng {
    RNG_ANSI, RNG_BBS, RNG_BSD, RNG_ISAAC, RNG_MANUAL, RNG_MD5, RNG_MERSENNE, 
    RNG_RANDOM_DOT_ORG, RNG_USER
} rng;
/* End from dice.h */

typedef struct movefilter_s {
  int   Accept;    /* always allow this many moves. 0 means don't use this */
                   /* level, since at least 1 is needed when used. */
  int   Extra;     /* and add up to this many more... */
  float Threshold; /* ...if they are within this equity */
} movefilter;

typedef struct _evalcontext {
    /* FIXME expand this... e.g. different settings for different position
       classes */
    unsigned int fCubeful : 1; /* cubeful evaluation */
    unsigned int nPlies : 3;
    unsigned int nReduced : 3; /* this will need to be expanded if we add
                                  support for nReduced != 3 */
    unsigned int fDeterministic : 1;
    float        rNoise; /* standard deviation */
} evalcontext;

typedef struct _rolloutcontext {

  evalcontext aecCube[ 2 ], aecChequer [ 2 ]; /* evaluation parameters */
  evalcontext aecCubeLate[ 2 ], aecChequerLate [ 2 ]; /* ... for later moves */
  evalcontext aecCubeTrunc, aecChequerTrunc; /* ... at truncation point */
  movefilter aaamfChequer[ 2 ][ MAX_FILTER_PLIES ][ MAX_FILTER_PLIES ];
  movefilter aaamfLate[ 2 ][ MAX_FILTER_PLIES ][ MAX_FILTER_PLIES ];
  unsigned int fCubeful : 1; /* Cubeful rollout */
  unsigned int fVarRedn : 1; /* variance reduction */
  unsigned int fInitial: 1;  /* roll out as opening position */
  unsigned int fRotate : 1;  /* quasi-random dice */
  unsigned int fLateEvals; /* enable different evals for later moves */
  unsigned int fDoTruncate; /* enable truncated rollouts */
  unsigned short nTruncate; /* truncation */
  unsigned int nTrials; /* number of rollouts */
  unsigned int fTruncBearoff2 : 1; /* cubeless rollout: trunc at BEAROFF2 */
  unsigned int fTruncBearoffOS: 1; /* cubeless rollout: trunc at BEAROFF_OS */
  unsigned short nLate; /* switch evaluations on move nLate of game */
  rng rngRollout;
  int nSeed;

} rolloutcontext;

typedef enum _evaltype {
  EVAL_NONE, EVAL_EVAL, EVAL_ROLLOUT
} evaltype;


typedef struct _evalsetup {
  evaltype et;
  evalcontext ec;
  rolloutcontext rc;
} evalsetup;

typedef struct _move {
  int anMove[ 8 ];
  unsigned char auch[ 10 ];
  int cMoves, cPips;
  /* scores for this move */
  float rScore, rScore2; 
  /* evaluation for this move */
  float arEvalMove[ NUM_ROLLOUT_OUTPUTS ];
  float arEvalStdDev[ NUM_ROLLOUT_OUTPUTS ];
  evalsetup esMove;
} move;

typedef struct _movelist {
    int cMoves; /* and current move when building list */
    int cMaxMoves, cMaxPips;
    int iMoveBest;
    float rBestScore;
    move *amMoves;
} movelist;


extern void swap( int *p0, int *p1 ) {
    int n = *p0;

    *p0 = *p1;
    *p1 = n;
}

static void SaveMoves( movelist *pml, int cMoves, int cPip, int anMoves[],
		       int anBoard[ 2 ][ 25 ], int fPartial ) {
    int i, j;
    move *pm;
    unsigned char auch[ 10 ];

    if( fPartial ) {
	/* Save all moves, even incomplete ones */
	if( cMoves > pml->cMaxMoves )
	    pml->cMaxMoves = cMoves;
	
	if( cPip > pml->cMaxPips )
	    pml->cMaxPips = cPip;
    } else {
	/* Save only legal moves: if the current move moves plays less
	   chequers or pips than those already found, it is illegal; if
	   it plays more, the old moves are illegal. */
	if( cMoves < pml->cMaxMoves || cPip < pml->cMaxPips )
	    return;

	if( cMoves > pml->cMaxMoves || cPip > pml->cMaxPips )
	    pml->cMoves = 0;
	
	pml->cMaxMoves = cMoves;
	pml->cMaxPips = cPip;
    }
    
    pm = pml->amMoves + pml->cMoves;
    
    PositionKey( anBoard, auch );
    
    for( i = 0; i < pml->cMoves; i++ )
	if( EqualKeys( auch, pml->amMoves[ i ].auch ) ) {
	    if( cMoves > pml->amMoves[ i ].cMoves ||
		cPip > pml->amMoves[ i ].cPips ) {
		for( j = 0; j < cMoves * 2; j++ )
		    pml->amMoves[ i ].anMove[ j ] = anMoves[ j ] > -1 ?
			anMoves[ j ] : -1;
    
		if( cMoves < 4 )
		    pml->amMoves[ i ].anMove[ cMoves * 2 ] = -1;

		pml->amMoves[ i ].cMoves = cMoves;
		pml->amMoves[ i ].cPips = cPip;
	    }
	    
	    return;
	}
    
    for( i = 0; i < cMoves * 2; i++ )
	pm->anMove[ i ] = anMoves[ i ] > -1 ? anMoves[ i ] : -1;
    
    if( cMoves < 4 )
	pm->anMove[ cMoves * 2 ] = -1;
    
    for( i = 0; i < 10; i++ )
	pm->auch[ i ] = auch[ i ];

    pm->cMoves = cMoves;
    pm->cPips = cPip;

    for ( i = 0; i < NUM_OUTPUTS; i++ )
      pm->arEvalMove[ i ] = 0.0;
    
    pml->cMoves++;

}

ApplySubMove( int anBoard[ 2 ][ 25 ], 
              const int iSrc, const int nRoll,
              const int fCheckLegal ) {

    int iDest = iSrc - nRoll;

    if( fCheckLegal && ( nRoll < 1 || nRoll > 6 ) ) {
        /* Invalid dice roll */
        errno = EINVAL;
        return -1;
    }
    
    if( iSrc < 0 || iSrc > 24 || iDest > 24 || anBoard[ 1 ][ iSrc ] < 1 ) {
        /* Invalid point number, or source point is empty */
        errno = EINVAL;
        return -1;
    }
    
    anBoard[ 1 ][ iSrc ]--;

    if( iDest < 0 )
        return 0;
    
    if( anBoard[ 0 ][ 23 - iDest ] ) {
        if( anBoard[ 0 ][ 23 - iDest ] > 1 ) {
            /* Trying to move to a point already made by the opponent */
            errno = EINVAL;
            return -1;
        }
        anBoard[ 1 ][ iDest ] = 1;
        anBoard[ 0 ][ 23 - iDest ] = 0;
        anBoard[ 0 ][ 24 ]++;
    } else
        anBoard[ 1 ][ iDest ]++;

    return 0;
}

static int LegalMove( int anBoard[ 2 ][ 25 ], int iSrc, int nPips ) {

    int i, nBack = 0, iDest = iSrc - nPips;

// Egyptian rule is switched off permanently by bigj
//    if( iDest >= 0 ) { /* Here we can do the Chris rule check */
//        if( fEgyptian ) {
//            if( anBoard[ 0 ][ 23 - iDest ] < 2 ) {
//                return ( anBoard[ 1 ][ iDest ] < 5 );
//            };
//            return ( 0 );
//        } else {
//            return ( anBoard[ 0 ][ 23 - iDest ] < 2 );
//        }
//    }

    if ( iDest >= 0) {
         return ( anBoard[ 0 ][ 23 - iDest ] < 2 );
    }

    /* otherwise, attempting to bear off */

    for( i = 1; i < 25; i++ )
        if( anBoard[ 1 ][ i ] > 0 )
            nBack = i;

    return ( nBack <= 5 && ( iSrc == nBack || iDest == -1 ) );
}


static int GenerateMovesSub( movelist *pml, int anRoll[], int nMoveDepth,
			     int iPip, int cPip, int anBoard[ 2 ][ 25 ],
			     int anMoves[], int fPartial ) {
    int i, iCopy, fUsed = 0;
    int anBoardNew[ 2 ][ 25 ];

    if( nMoveDepth > 3 || !anRoll[ nMoveDepth ] )
	return TRUE;

    if( anBoard[ 1 ][ 24 ] ) { /* on bar */
	if( anBoard[ 0 ][ anRoll[ nMoveDepth ] - 1 ] >= 2 )
	    return TRUE;

	anMoves[ nMoveDepth * 2 ] = 24;
	anMoves[ nMoveDepth * 2 + 1 ] = 24 - anRoll[ nMoveDepth ];

	for( i = 0; i < 25; i++ ) {
	    anBoardNew[ 0 ][ i ] = anBoard[ 0 ][ i ];
	    anBoardNew[ 1 ][ i ] = anBoard[ 1 ][ i ];
	}
	
	ApplySubMove( anBoardNew, 24, anRoll[ nMoveDepth ], TRUE );
	
	if( GenerateMovesSub( pml, anRoll, nMoveDepth + 1, 23, cPip +
			      anRoll[ nMoveDepth ], anBoardNew, anMoves,
			      fPartial ) )
	    SaveMoves( pml, nMoveDepth + 1, cPip + anRoll[ nMoveDepth ],
		       anMoves, anBoardNew, fPartial );

	return fPartial;
    } else {
	for( i = iPip; i >= 0; i-- )
	    if( anBoard[ 1 ][ i ] && LegalMove( anBoard, i,
						anRoll[ nMoveDepth ] ) ) {
		anMoves[ nMoveDepth * 2 ] = i;
		anMoves[ nMoveDepth * 2 + 1 ] = i -
		    anRoll[ nMoveDepth ];
		
		for( iCopy = 0; iCopy < 25; iCopy++ ) {
		    anBoardNew[ 0 ][ iCopy ] = anBoard[ 0 ][ iCopy ];
		    anBoardNew[ 1 ][ iCopy ] = anBoard[ 1 ][ iCopy ];
		}
    
		ApplySubMove( anBoardNew, i, anRoll[ nMoveDepth ], TRUE );
		
		if( GenerateMovesSub( pml, anRoll, nMoveDepth + 1,
				   anRoll[ 0 ] == anRoll[ 1 ] ? i : 23,
				   cPip + anRoll[ nMoveDepth ],
				   anBoardNew, anMoves, fPartial ) )
		    SaveMoves( pml, nMoveDepth + 1, cPip +
			       anRoll[ nMoveDepth ], anMoves, anBoardNew,
			       fPartial );
		
		fUsed = 1;
	    }
    }

    return !fUsed || fPartial;
}

extern int 
GenerateMoves( movelist *pml, int anBoard[ 2 ][ 25 ],
               int n0, int n1, int fPartial ) {

  int anRoll[ 4 ], anMoves[ 8 ];
  static move amMoves[ MAX_INCOMPLETE_MOVES ];

    anRoll[ 0 ] = n0;
    anRoll[ 1 ] = n1;

    anRoll[ 2 ] = anRoll[ 3 ] = ( ( n0 == n1 ) ? n0 : 0 );

    pml->cMoves = pml->cMaxMoves = pml->cMaxPips = pml->iMoveBest = 0;
    pml->amMoves = amMoves; /* use static array for top-level search, since
			       it doesn't need to be re-entrant */
    
    GenerateMovesSub( pml, anRoll, 0, 23, 0, anBoard, anMoves,fPartial );

    if( anRoll[ 0 ] != anRoll[ 1 ] ) {
	swap( anRoll, anRoll + 1 );

	GenerateMovesSub( pml, anRoll, 0, 23, 0, anBoard, anMoves, fPartial );
    }

    return pml->cMoves;
}
