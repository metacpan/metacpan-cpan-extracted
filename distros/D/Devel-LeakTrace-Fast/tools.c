/* tools.c */

#include "tools.h"

/* Enable to do old style brute force checking too */
/* #define BRUTE_FORCE */
/* #define SANITY  */

typedef struct {
    int line;
} where;

static hash *var_map = NULL;    /* Maps SV* to location where var was created */
static list current_free;
static list current_arenas;
static int note_init_done = 0;

static int ( *runops_old ) ( pTHX );

#ifdef BRUTE_FORCE
static hash *brute = NULL;
#endif

#define live_sv(sv) \
    (SvTYPE(sv) != SVTYPEMASK && SvREFCNT(sv))

#define free_sv(sv) \
    (!live_sv(sv))

#define list_hint(l) \
    (!(l) ? 100 : (list_used(l) + 10))

/* Perl opcodes which trigger a memory scan */
#define interesting_op(o) \
    ((o) == OP_NEXTSTATE || \
     (o) == OP_DBSTATE   || \
     (o) == OP_SETSTATE)

static void nomem( void ) {
    fprintf( stderr, "Devel::LeakTrace::Fast: Out of memory\n" );
    exit( 1 );
}

static const where *get_where( int line, const char *file ) {
    static int init_done = 0;
    static hash *cache = NULL;
    static buffer work;
    where *w;
    int err;
    size_t sz;

    if ( !file ) {
        return NULL;
    }

    if ( !init_done ) {
        if ( err = buffer_init( &work, 256, 64 ), ERR_None != err ) {
            nomem(  );
        }
        if ( err = hash_new( 1000, &cache ), ERR_None != err ) {
            nomem(  );
        }
        init_done = 1;
    }

    sz = sizeof( where ) + strlen( file ) + 1;
    if ( err = buffer_ensure( &work, sz ), ERR_None != err ) {
        nomem(  );
    }

    w = ( where * ) work.buf;
    w->line = line;
    strcpy( ( char * )( w + 1 ), file );

    /* Already got it? */
    if ( w = ( where * ) hash_get( cache, w, sz ), NULL != w ) {
        return w;
    }

    if ( w = malloc( sz ), !w ) {
        nomem(  );
    }

    memcpy( w, work.buf, sz );

    /* Add it to cache */
    if ( err = hash_put( cache, w, sz, w ), ERR_None != err ) {
        nomem(  );
    }

    return w;
}

static void new_var( SV * sv, const void *p ) {
    int err;
    const where *w = p;

/*    fprintf(stderr, "%s, line %d: New var: %p\n", (const char *) (w + 1), w->line, sv);*/
    if ( !var_map ) {
        fprintf( stderr, "Oops. var_map == NULL\n" );
        exit( 1 );
    }

    if ( err =
         hash_put( var_map, &sv, sizeof( sv ), ( void * )w ),
         ERR_None != err ) {
        nomem(  );
    }
}

static void free_var( SV * sv, const void *p ) {
    int err;

/*    fprintf(stderr, "%s, line %d: Free var: %p\n", (const char *) (w + 1), w->line, sv);*/
    if ( !var_map ) {
        fprintf( stderr, "Oops. var_map == NULL\n" );
        exit( 1 );
    }

    if ( err =
         hash_delete_key( var_map, &sv, sizeof( sv ) ), ERR_None != err ) {
        nomem(  );
    }
}

static void new_arena( SV * sva, const void *p ) {
    const where *w = p;
    int err;
    /*fprintf(stderr, "%s, line %d: New arena: %p\n", (const char *) (w + 1), w->line, sva); */
    SV *sv = sva + 1;
    SV *svend = &sva[SvREFCNT( sva )];

    while ( sv < svend ) {
        if ( live_sv( sv ) ) {
            /* New variable */
            new_var( sv, w );
        }
        else {
            /* Pretend any new free SVs were already in the free list otherwise
             * when we compare the new free list with the old one it'll look as
             * if lots of variables that never existed have been freed.
             */
            if ( err = list_append( &current_free, sv ), ERR_None != err ) {
                nomem(  );
            }
        }
        ++sv;
    }
    /*fprintf(stderr, "%s, line %d: End new arena: %p\n", (const char *) (w + 1), w->line, sva); */
}

static void free_arena( SV * sva, const void *p ) {
    const where *w = p;
    fprintf( stderr, "%s, line %d: Free arena: %p\n",
             ( const char * )( w + 1 ), w->line, sva );
    fprintf( stderr, "Don't know what to do when an arena is freed...\n" );
    exit( 1 );
}

#ifdef SANITY
static void in_free_only( SV * sv, const void *p ) {
    fprintf( stderr, "%p is in free list but not arenas", sv );
}

static void in_comp_only( SV * sv, const void *p ) {
    fprintf( stderr, "%p is in arenas but not free list", sv );
}

/* Sanity check - compare the free list with the list of free SVs in the arenas */
static void free_list_sane( void ) {
    list real_free;
    list comp_free;
    int err;
    SV *sva;
    long diff;

    /* Get the real free list */
    if ( err =
         list_build( &real_free, PL_sv_root, list_hint( &current_free ) ),
         ERR_None != err ) {
        nomem(  );
    }

    /* Get the list of all the free SVs in all the arenas */
    if ( err =
         list_init( &comp_free, list_hint( &real_free ) ),
         ERR_None != err ) {
        nomem(  );
    }

    for ( sva = PL_sv_arenaroot; sva; sva = ( SV * ) SvANY( sva ) ) {
        SV *sv = sva + 1;
        SV *svend = &sva[SvREFCNT( sva )];

        while ( sv < svend ) {
            if ( free_sv( sv ) ) {
                if ( err = list_append( &comp_free, sv ), ERR_None != err ) {
                    nomem(  );
                }
            }
            ++sv;
        }
    }

    diff =
        list_true_diff( &real_free, &comp_free, NULL, in_free_only,
                        in_comp_only );

    if ( diff != 0 ) {
        fprintf( stderr, "Lists have %ld differences, stopping\n", diff );
        fprintf( stderr,
                 "%ld items in free list, %ld free items in arenas\n",
                 ( long )list_used( &real_free ),
                 ( long )list_used( &comp_free ) );
        exit( 1 );
    }
}
#endif

static void note_new_vars( int line, const char *file ) {
    list new_arenas;
    list new_free;
    int err;
    const where *w;

    if ( !file ) {
        return;
    }
#ifdef SANITY
    free_list_sane(  );
#endif

    w = get_where( line, file );

    /*fprintf(stderr, "note_new_vars(%d, \"%s\")\n", line, file); */

    if ( err =
         list_build( &new_arenas, PL_sv_arenaroot,
                     list_hint( &current_arenas ) ), ERR_None != err ) {
        nomem(  );
    }

    if ( err =
         list_build( &new_free, PL_sv_root, list_hint( &current_free ) ),
         ERR_None != err ) {
        nomem(  );
    }

    if ( note_init_done ) {
        /* Scan the lists looking for new arenas and deleted
         * free slots. A deleted free slot implies the creation of a new
         * variable.
         */

        list_true_diff( &current_arenas, &new_arenas, w, new_arena,
                        free_arena );
        list_true_diff( &new_free, &current_free, w, new_var, free_var );

        list_delete( &current_arenas );
        list_delete( &current_free );
    }

    /* Roll round to new versions of lists */
    current_arenas = new_arenas;
    current_free = new_free;
    note_init_done = 1;
}

#ifdef BRUTE_FORCE
static void brute_force( int line, const char *file ) {
    SV *sva;
    hash *baby;
    const where *w;
    int err;

    fprintf( stderr, "brute_force(%d, \"%s\")\n", line, file );

    w = get_where( line, file );

    if ( err = hash_new( PL_sv_count, &baby ), ERR_None != err ) {
        nomem(  );
    }

    for ( sva = PL_sv_arenaroot; sva; sva = ( SV * ) SvANY( sva ) ) {
        SV *sv = sva + 1;
        SV *svend = &sva[SvREFCNT( sva )];

        while ( sv < svend ) {
            if ( live_sv( sv ) ) {
                const where *nw = w;

                if ( brute ) {
                    const where *ow;
                    if ( ( ow = hash_get( brute, &sv, sizeof( sv ) ) ) ) {
                        nw = hash_GETNULL( ow );
                    }
                    else {
                        if ( w ) {
                            fprintf( stderr,
                                     "%s, line %d: New var (bf): %p\n",
                                     ( const char * )( w + 1 ), w->line,
                                     sv );
                        }
                    }
                }

                if ( err = hash_put( baby, &sv, sizeof( sv ),
                                     hash_PUTNULL( ( void * )nw ) ),
                     ERR_None != err ) {
                    nomem(  );
                }
            }
            ++sv;
        }
    }

    hash_delete( brute );
    brute = baby;
}

#define NOTE_NEW_VARS(l, f)     \
    do {                        \
        note_new_vars(l, f);    \
        brute_force(l, f);      \
    } while (0);

#else

#define NOTE_NEW_VARS(l, f) \
    note_new_vars(l, f)

#endif

static int runops_leakcheck( pTHX ) {
    char *lastfile = NULL;
    int lastline = 0;

    while ( ( PL_op = CALL_FPTR( PL_op->op_ppaddr ) ( aTHX ) ) ) {
        PERL_ASYNC_CHECK(  );

        if ( interesting_op( PL_op->op_type ) ) {
            /*fprintf(stderr, "%s, line %d\n", lastfile, lastline); */
            NOTE_NEW_VARS( lastline, lastfile );
            lastfile = CopFILE( cCOP );
            lastline = CopLINE( cCOP );
        }
    }

    /*fprintf(stderr, "%s, line %d\n", lastfile, lastline); */
    NOTE_NEW_VARS( lastline, lastfile );

    TAINT_NOT;
    return 0;
}

void tools_reset_counters( void ) {
    int err;

    hash_delete( var_map );
    var_map = NULL;

    /*fprintf(stderr, "\nNew var_map\n\n"); */

    if ( err = hash_new( 1000, &var_map ), ERR_None != err ) {
        nomem(  );
    }

    list_delete( &current_arenas );
    list_delete( &current_free );
    note_init_done = 0;

    note_new_vars( 0, NULL );

#ifdef BRUTE_FORCE
    hash_delete( brute );
    brute = NULL;
    brute_force( 0, NULL );
#endif
}

void tools_hook_runops( void ) {
    tools_reset_counters(  );
    /*note_new_vars(0, NULL); */
    /*brute_force(0, NULL); */
    if ( PL_runops != runops_leakcheck ) {
        runops_old = PL_runops;
        PL_runops = runops_leakcheck;
    }
}

static void print_var( SV * sv, const where * w ) {
    char *type;

    if ( !w && var_map ) {
        w = hash_get( var_map, &sv, sizeof( sv ) );
    }

    switch ( SvTYPE( sv ) ) {
    case SVt_PVAV:
        type = "AV";
        break;
    case SVt_PVCV:
        type = "CV";
        break;
    case SVt_PVGV:
        type = "GV";
        break;
    case SVt_PVHV:
        type = "HV";
        break;
    case SVt_RV:
        type = "RV";
        break;
    default:
        type = "SV";
        break;
    }

    fprintf( stderr, "leaked %s(0x%p) from %s line %d\n",
             type, sv, ( const char * )( w + 1 ), w->line );
}

void tools_show_used( void ) {
/*  SV *sva; */
    hash_iter i;
    const void *k;
    size_t kl;

#ifdef BRUTE_FORCE
    fprintf( stderr, "Leaks found by free list snooping:\n" );
#endif

    k = hash_get_first_key( var_map, &i, &kl );
    while ( k ) {
        const where *w =
            ( const where * )hash_GETNULL( hash_get( var_map, k, kl ) );
        if ( w ) {
            print_var( *( SV ** ) k, w );
        }
        k = hash_get_next_key( var_map, &i, &kl );
    }

#if 0
    for ( sva = PL_sv_arenaroot; sva; sva = ( SV * ) SvANY( sva ) ) {
        SV *sv = sva + 1;
        SV *svend = &sva[SvREFCNT( sva )];

        while ( sv < svend ) {
            if ( live_sv( sv ) ) {
                fprintf( stderr, "var in pool at %p\n", sv );
            }
            ++sv;
        }
    }
#endif

#ifdef BRUTE_FORCE
    if ( brute ) {

        fprintf( stderr, "Leaks found by brute force:\n" );
        k = hash_get_first_key( brute, &i, &kl );
        while ( k ) {
            const where *w =
                ( const where * )hash_GETNULL( hash_get( brute, k, kl ) );
            if ( w ) {
                print_var( *( SV ** ) k, w );
            }
            k = hash_get_next_key( brute, &i, &kl );
        }
    }
#endif
}
