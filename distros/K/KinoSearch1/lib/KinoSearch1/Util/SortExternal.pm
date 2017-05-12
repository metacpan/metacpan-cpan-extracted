package KinoSearch1::Util::SortExternal;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::CClass );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # constructor args
        invindex      => undef,
        seg_name      => undef,
        mem_threshold => 2**24,
    );
}
our %instance_vars;

sub new {
    my $class = shift;
    verify_args( \%instance_vars, @_ );
    my %args = ( %instance_vars, @_ );
    my $invindex = $args{invindex};

    $class = ref($class) || $class;

    my $filename = "$args{seg_name}.srt";
    $invindex->delete_file($filename) if $invindex->file_exists($filename);
    my $outstream = $invindex->open_outstream($filename);

    return _new( $class, $outstream,
        @args{qw( invindex seg_name mem_threshold )} );
}

# Prepare to start fetching sorted results.
sub sort_all {
    my $self = shift;

    # deal with any items in the cache right now
    if ( $self->_get_num_runs == 0 ) {
        # if we've never exceeded mem_threshold, sort in-memory
        $self->_sort_cache;
    }
    else {
        # create a run from whatever's in the cache right now
        $self->_sort_run;
    }

    # done adding elements, so close file and reopen as an instream
    $self->_get_outstream->close;
    my $filename = $self->_get_seg_name . ".srt";
    my $instream = $self->_get_invindex()->open_instream($filename);
    $self->_set_instream($instream);

    # allow fetching now that we're set up
    $self->_enable_fetch;
}

sub close { shift->_get_instream()->close }

1;

__END__

__XS__

MODULE = KinoSearch1    PACKAGE = KinoSearch1::Util::SortExternal

void
_new(class, outstream_sv, invindex_sv, seg_name_sv, mem_threshold)
    char         *class;
    SV           *outstream_sv;
    SV           *invindex_sv;
    SV           *seg_name_sv;
    I32           mem_threshold;
PREINIT:
    SortExternal *sortex;
PPCODE:
    sortex = Kino1_SortEx_new(outstream_sv, invindex_sv, seg_name_sv,
        mem_threshold);
    ST(0)  = sv_newmortal();
    sv_setref_pv( ST(0), class, (void*)sortex );
    XSRETURN(1);

=for comment

Add one or more items to the sort pool.

=cut

void
feed(sortex, ...)
    SortExternal *sortex;
PREINIT:
    I32      i;
PPCODE:
    for (i = 1; i < items; i++) {   
        SV const * item_sv = ST(i);
        if (!SvPOK(item_sv))
            continue;
        sortex->feed(sortex, SvPVX(item_sv), SvCUR(item_sv));
    }

=for comment

Fetch the next sorted item from the sort pool.  sort_all must be called first.

=cut

SV*
fetch(sortex)
    SortExternal *sortex;
PREINIT:
    ByteBuf *bb;
CODE:
    bb = sortex->fetch(sortex);
    if (bb == NULL) {
        RETVAL = newSV(0);
    }
    else {
        RETVAL = newSVpvn(bb->ptr, bb->size);
        Kino1_BB_destroy(bb);
    }
OUTPUT: RETVAL

=for comment

Sort all items currently in memory.

=cut

void
_sort_cache(sortex)
    SortExternal *sortex;
PPCODE:
    Kino1_SortEx_sort_cache(sortex);

=for comment

Sort everything in memory and write the sorted elements to disk, creating a
SortExRun C object.

=cut

void
_sort_run(sortex);
    SortExternal *sortex;
PPCODE:
    Kino1_SortEx_sort_run(sortex);

=for comment

Turn on fetching.

=cut

void
_enable_fetch(sortex)
    SortExternal *sortex;
PPCODE:
    Kino1_SortEx_enable_fetch(sortex);
    
SV*
_set_or_get(sortex, ...)
    SortExternal *sortex;
ALIAS:
    _set_outstream = 1
    _get_outstream = 2
    _set_instream  = 3
    _get_instream  = 4
    _set_num_runs  = 5
    _get_num_runs  = 6
    _set_invindex  = 7
    _get_invindex  = 8
    _set_seg_name  = 9
    _get_seg_name  = 10
CODE:
{
    KINO_START_SET_OR_GET_SWITCH

    case 1:  SvREFCNT_dec(sortex->outstream_sv);
             sortex->outstream_sv = newSVsv( ST(1) );
             Kino1_extract_struct(sortex->outstream_sv, sortex->outstream, 
                OutStream*, "KinoSearch1::Store::OutStream");
             /* fall through */
    case 2:  RETVAL = newSVsv(sortex->outstream_sv);
             break;
             
    case 3:  SvREFCNT_dec(sortex->instream_sv);
             sortex->instream_sv = newSVsv( ST(1) );
             Kino1_extract_struct(sortex->instream_sv, sortex->instream, 
                InStream*, "KinoSearch1::Store::InStream");
             /* fall through */
    case 4:  RETVAL = newSVsv(sortex->instream_sv);
             break;

    case 5:  Kino1_confess("can't set num_runs");
             /* fall through */
    case 6:  RETVAL = newSViv(sortex->num_runs);
             break;

    case 7:  Kino1_confess("can't set_invindex");
             /* fall through */
    case 8:  RETVAL = newSVsv(sortex->invindex_sv);
             break;
             
    case 9:  Kino1_confess("can't set_seg_name");
             /* fall through */
    case 10: RETVAL = newSVsv(sortex->seg_name_sv);
             break;

    KINO_END_SET_OR_GET_SWITCH
}
OUTPUT: RETVAL

void
DESTROY(sortex)
    SortExternal *sortex;
PPCODE:
    Kino1_SortEx_destroy(sortex);

__H__

#ifndef H_KINOSEARCH_UTIL_SORT_EXTERNAL
#define H_KINOSEARCH_UTIL_SORT_EXTERNAL 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "KinoSearch1StoreInStream.h"
#include "KinoSearch1StoreOutStream.h"
#include "KinoSearch1UtilByteBuf.h"
#include "KinoSearch1UtilCClass.h"
#include "KinoSearch1UtilMemManager.h"

typedef struct sortexrun {
    double     start;
    double     file_pos;
    double     end;
    ByteBuf  **cache;
    I32        cache_cap;
    I32        cache_elems;
    I32        cache_pos;
    I32        slice_size;
} SortExRun;

typedef struct sortexternal {
    ByteBuf   **cache;            /* item cache, both incoming and outgoing */
    I32         cache_cap;        /* allocated limit for cache */
    I32         cache_elems;      /* number of elems in cache */ 
    I32         cache_pos;        /* index of current element in cache */
    ByteBuf   **scratch;          /* memory for use by mergesort */
    I32         scratch_cap;      /* allocated limit for scratch */
    I32         mem_threshold;    /* bytes of mem allowed for cache */
    I32         cache_bytes;      /* bytes of mem occupied by cache */
    I32         run_cache_limit;  /* bytes of mem allowed each run cache */
    SortExRun **runs;
    I32         num_runs;
    SV         *outstream_sv;
    OutStream  *outstream;
    SV         *instream_sv;
    InStream   *instream;
    SV         *invindex_sv;
    SV         *seg_name_sv;
    void      (*feed) (struct sortexternal*, char*, I32);
    ByteBuf*  (*fetch)(struct sortexternal*);
} SortExternal;

SortExternal* Kino1_SortEx_new(SV*, SV*, SV*, I32);
void          Kino1_SortEx_feed(SortExternal*, char*, I32);
ByteBuf*      Kino1_SortEx_fetch(SortExternal*);
ByteBuf*      Kino1_SortEx_fetch_death(SortExternal*);
void          Kino1_SortEx_enable_fetch(SortExternal*);
void          Kino1_SortEx_sort_cache(SortExternal*);
void          Kino1_SortEx_sort_run(SortExternal*);
void          Kino1_SortEx_destroy(SortExternal*);

#endif /* include guard */

__C__

#include "KinoSearch1UtilSortExternal.h"

static SortExRun* Kino1_SortEx_new_run(double, double);
static void       Kino1_SortEx_grow_bufbuf(ByteBuf***, I32, I32);
static I32        Kino1_SortEx_refill_run(SortExternal*, SortExRun*);
static void       Kino1_SortEx_refill_cache(SortExternal*);
static void       Kino1_SortEx_merge_runs(SortExternal*);
static ByteBuf*   Kino1_SortEx_find_endpost(SortExternal*);
static I32        Kino1_SortEx_define_slice(SortExRun*, ByteBuf*);
static void       Kino1_SortEx_mergesort(ByteBuf**, ByteBuf**, I32);
static void       Kino1_SortEx_msort(ByteBuf**, ByteBuf**, U32, U32);
static void       Kino1_SortEx_merge(ByteBuf**, U32, ByteBuf**, U32, 
                                    ByteBuf**);
static void       Kino1_SortEx_clear_cache(SortExternal*);
static void       Kino1_SortEx_clear_run_cache(SortExRun*);
static void       Kino1_SortEx_destroy_run(SortExRun*);

#define KINO_PER_ITEM_OVERHEAD (sizeof(ByteBuf) + sizeof(ByteBuf*))

SortExternal*
Kino1_SortEx_new(SV *outstream_sv, SV *invindex_sv, SV *seg_name_sv, 
                I32 mem_threshold) {
    SortExternal *sortex;

    /* allocate */
    Kino1_New(0, sortex, 1, SortExternal);
    Kino1_New(0, sortex->cache, 100, ByteBuf*);
    Kino1_New(0, sortex->runs, 1, SortExRun*);

    /* init */
    sortex->scratch         = NULL;
    sortex->scratch_cap     = 0;
    sortex->cache_cap       = 100;
    sortex->cache_elems     = 0;
    sortex->cache_pos       = 0;
    sortex->cache_bytes     = 0;
    sortex->num_runs        = 0;
    sortex->instream_sv     = &PL_sv_undef;
    sortex->feed            = Kino1_SortEx_feed;
    sortex->fetch           = Kino1_SortEx_fetch_death;

    /* assign */
    sortex->outstream_sv  = newSVsv(outstream_sv);
    Kino1_extract_struct(outstream_sv, sortex->outstream,
        OutStream*, "KinoSearch1::Store::OutStream");
    sortex->invindex_sv   = newSVsv(invindex_sv);
    sortex->seg_name_sv   = newSVsv(seg_name_sv);
    sortex->mem_threshold = mem_threshold;
    
    /* derive */
    sortex->run_cache_limit = mem_threshold / 2;

    return sortex;
}


/* Create a new SortExRun object */
static SortExRun*
Kino1_SortEx_new_run(double start, double end) {
    SortExRun *run;
    
    /* allocate */
    Kino1_New(0, run, 1, SortExRun);
    Kino1_New(0, run->cache, 100, ByteBuf*);

    /* init */
    run->cache_cap   = 100;
    run->cache_elems = 0;
    run->cache_pos   = 0;

    /* assign */
    run->start    = start;
    run->file_pos = start;
    run->end      = end;

    return run;
}

void
Kino1_SortEx_feed(SortExternal* sortex, char* ptr, I32 len) {
    /* add room for more cache elements if needed */
    if (sortex->cache_elems == sortex->cache_cap) {
        /* add 100, plus 10% of the current capacity */
        sortex->cache_cap = sortex->cache_cap + 100 + (sortex->cache_cap / 8);
        Kino1_Renew(sortex->cache, sortex->cache_cap, ByteBuf*);
    }

    sortex->cache[ sortex->cache_elems ] = Kino1_BB_new_string(ptr, len);
    sortex->cache_elems++;
        
    /* track memory consumed */
    sortex->cache_bytes += KINO_PER_ITEM_OVERHEAD;
    sortex->cache_bytes += len + 1;

    /* check if it's time to flush the cache */
    if (sortex->cache_bytes >= sortex->mem_threshold)
        Kino1_SortEx_sort_run(sortex);
}

ByteBuf*
Kino1_SortEx_fetch(SortExternal *sortex) {
    if (sortex->cache_pos >= sortex->cache_elems)
        Kino1_SortEx_refill_cache(sortex);

    if (sortex->cache_elems > 0) {
        return sortex->cache[ sortex->cache_pos++ ];
    }
    else {
        return NULL;
    }
}

ByteBuf*
Kino1_SortEx_fetch_death(SortExternal *sortex) {
    ByteBuf *bb = NULL;
    Kino1_confess("can't call fetch before sort_all");
    return bb;
}

void
Kino1_SortEx_enable_fetch(SortExternal *sortex) {
    sortex->fetch = Kino1_SortEx_fetch;
}

/* Allocate more memory to an array of pointers to pointers to ByteBufs, if
 * the current allocation isn't sufficient.
 */
static void
Kino1_SortEx_grow_bufbuf(ByteBuf ***bb_buf, I32 current, I32 desired) {
    if (current < desired)
        Kino1_Renew(*bb_buf, desired, ByteBuf*);
}

/* Sort the main cache.
 */
void
Kino1_SortEx_sort_cache(SortExternal *sortex) {
    Kino1_SortEx_grow_bufbuf(&sortex->scratch, sortex->scratch_cap,
        sortex->cache_elems);
    Kino1_SortEx_mergesort(sortex->cache, sortex->scratch, 
        sortex->cache_elems);
}

void
Kino1_SortEx_sort_run(SortExternal *sortex) {
    OutStream  *outstream;
    ByteBuf   **cache, **cache_end;
    ByteBuf    *bb;
    double      start, end;

    /* bail if there's nothing in the cache */
    if (sortex->cache_bytes == 0)
        return;

    /* allocate space for a new run */
    sortex->num_runs++;
    Kino1_Renew(sortex->runs, sortex->num_runs, SortExRun*);

    /* make local copies */
    outstream = sortex->outstream;
    cache     = sortex->cache;

    /* mark start of run */
    start = outstream->tell(outstream);
    
    /* write sorted items to file */
    Kino1_SortEx_sort_cache(sortex);
    cache_end = cache + sortex->cache_elems;
    for (cache = sortex->cache; cache < cache_end; cache++) {
        bb = *cache;
        outstream->write_vint(outstream, bb->size);
        outstream->write_bytes(outstream, bb->ptr, bb->size);
    }

    /* clear the cache */
    Kino1_SortEx_clear_cache(sortex);

    /* mark end of run and build a new SortExRun object */
    end = outstream->tell(outstream);
    sortex->runs[ sortex->num_runs - 1 ] = Kino1_SortEx_new_run(start, end);

    /* recalculate the size allowed for each run's cache */
    sortex->run_cache_limit = (sortex->mem_threshold / 2) / sortex->num_runs;
    sortex->run_cache_limit = sortex->run_cache_limit < 65536
        ? 65536 
        : sortex->run_cache_limit;
}

/* Recover sorted items from disk, up to the allowable memory limit. 
 */
static I32 
Kino1_SortEx_refill_run(SortExternal* sortex, SortExRun *run) {
    InStream *instream;
    double    end;
    I32       run_cache_bytes = 0;
    int       num_elems       = 0; /* number of items recovered */
    I32       len;
    ByteBuf  *bb;
    I32       run_cache_limit;

    /* see if we actually need to refill */
    if (run->cache_elems - run->cache_pos)
        return run->cache_elems - run->cache_pos;
    else 
        Kino1_SortEx_clear_run_cache(run);

    /* make local copies */
    instream        = sortex->instream;
    run_cache_limit = sortex->run_cache_limit;
    end             = run->end;

    instream->seek(instream, run->file_pos);

    while (1) {
        /* bail if we've read everything in this run */
        if (instream->tell(instream) >= end) {
            /* make sure we haven't read too much */
            if (instream->tell(instream) > end) {
                UV pos = instream->tell(instream);
                Kino1_confess(
                    "read past end of run: %"UVuf", %"UVuf, pos, (UV)end );
            }
            break;
        }

        /* bail if we've hit the ceiling for this run's cache */
        if (run_cache_bytes > run_cache_limit)
            break;

        /* retrieve and decode len; allocate a ByteBuf and recover the string */
        len = instream->read_vint(instream);
        bb  = Kino1_BB_new(len);
        instream->read_bytes(instream, bb->ptr, len);
        bb->ptr[len] = '\0';

        /* add to the run's cache */
        if (num_elems == run->cache_cap) {
            run->cache_cap = run->cache_cap + 100 + (run->cache_cap / 8);
            Kino1_Renew(run->cache, run->cache_cap, ByteBuf*);
        }
        run->cache[ num_elems ] = bb;

        /* track how much we've read so far */
        num_elems++;
        run_cache_bytes += len + 1 + KINO_PER_ITEM_OVERHEAD;
    }

    /* reset the cache array position and length; remember file pos */
    run->cache_elems = num_elems;
    run->cache_pos   = 0;
    run->file_pos    = instream->tell(instream);

    return num_elems;
}

/* Refill the main cache, drawing from the caches of all runs.
 */
static void
Kino1_SortEx_refill_cache(SortExternal *sortex) {
    ByteBuf   *endpost;
    SortExRun *run;
    I32        i = 0;
    I32        total = 0;

    /* free all the existing ByteBufs, as they've been fetched by now */
    Kino1_SortEx_clear_cache(sortex);
    
    /* make sure all runs have at least one item in the cache */
    while (i < sortex->num_runs) {
        run = sortex->runs[i];
        if (   (run->cache_elems > run->cache_pos)
            || (Kino1_SortEx_refill_run(sortex, run)) 
        ) {
            i++;
        }
        else {
            /* discard empty runs */
            Kino1_SortEx_destroy_run(run);
            sortex->num_runs--;
            sortex->runs[i] = sortex->runs[ sortex->num_runs ];
            sortex->runs[ sortex->num_runs ] = NULL;
        }
    }

    if (!sortex->num_runs)
        return;

    /* move as many items as possible into the sorting cache */
    endpost = Kino1_SortEx_find_endpost(sortex);
    for (i = 0; i < sortex->num_runs; i++) {
        total += Kino1_SortEx_define_slice(sortex->runs[i], endpost);
    }

    /* make sure we have enough room in both the main cache and the scratch */
    Kino1_SortEx_grow_bufbuf(&sortex->cache,   sortex->cache_cap,   total);
    Kino1_SortEx_grow_bufbuf(&sortex->scratch, sortex->scratch_cap, total);

    Kino1_SortEx_merge_runs(sortex);
    sortex->cache_elems = total;
}

/* Merge all the items which are "in-range" from all the Runs into the main
 * cache.
 */
static void 
Kino1_SortEx_merge_runs(SortExternal *sortex) {
    SortExRun   *run;
    ByteBuf   ***slice_starts;
    ByteBuf    **cache = sortex->cache;
    I32         *slice_sizes;
    I32          i = 0, j = 0, slice_size = 0, num_slices = 0;

    Kino1_New(0, slice_starts, sortex->num_runs, ByteBuf**);
    Kino1_New(0, slice_sizes,  sortex->num_runs, I32);

    /* copy all the elements in range into the cache */
    j = 0;
    for (i = 0; i < sortex->num_runs; i++) {
        run = sortex->runs[i];
        slice_size      = run->slice_size;
        if (slice_size == 0)
            continue;

        slice_sizes[j]  = slice_size;
        slice_starts[j] = cache;
        Copy( (run->cache + run->cache_pos), cache, slice_size, ByteBuf* );
        
        run->cache_pos += slice_size;
        cache += slice_size;
        num_slices = ++j;
    }

    /* exploit previous sorting, rather than sort cache naively */
    while (num_slices > 1) {
        /* leave the first slice intact if the number of slices is odd */
        i = 0;
        j = 0;
        while (i < num_slices) {
            if (num_slices - i >= 2) {
                /* merge two consecutive slices */
                slice_size = slice_sizes[i] + slice_sizes[i+1];
                Kino1_SortEx_merge(slice_starts[i], slice_sizes[i],
                    slice_starts[i+1], slice_sizes[i+1], sortex->scratch);
                slice_sizes[j] = slice_size;
                slice_starts[j] = slice_starts[i];
                Copy(sortex->scratch, slice_starts[j], slice_size, ByteBuf*);

                i += 2;
                j += 1;
            }
            else if (num_slices - i >= 1) {
                /* move single slice pointer */
                slice_sizes[j]  = slice_sizes[i];
                slice_starts[j] = slice_starts[i];
                i += 1;
                j += 1;
            }
        }
        num_slices = j;
    }

    Kino1_Safefree(slice_starts);
    Kino1_Safefree(slice_sizes);
}

/* Return a pointer to the item in one of the runs' caches which is 
 * the highest in sort order, but which we can guarantee is lower in sort
 * order than any item which has yet to enter a run cache. 
 */
static ByteBuf*
Kino1_SortEx_find_endpost(SortExternal *sortex) {
    int         i;
    ByteBuf    *endpost = NULL, *candidate = NULL;
    SortExRun  *run;

    for (i = 0; i < sortex->num_runs; i++) {
        /* get a run and verify no errors */
        run = sortex->runs[i];
        if (run->cache_pos == run->cache_elems || run->cache_elems < 1)
            Kino1_confess("find_endpost encountered an empty run cache");

        /* get the last item in this run's cache */
        candidate = run->cache[ run->cache_elems - 1 ];

        /* if it's the first run, the item is automatically the new endpost */
        if (i == 0) {
            endpost = candidate;
            continue;
        }
        /* if it's less than the current endpost, it's the new endpost */
        else if (Kino1_BB_compare(candidate, endpost) < 0) {
            endpost = candidate;
        }
    }

    return endpost;
}

/* Record the number of items in the run's cache which are lexically
 * less than or equal to the endpost.
 */
static I32
Kino1_SortEx_define_slice(SortExRun *run, ByteBuf *endpost) {
    I32 lo, mid, hi, delta;
    ByteBuf **cache = run->cache;

    /* operate on a slice of the cache */
    lo  = run->cache_pos - 1;
    hi  = run->cache_elems;

    /* binary search */
    while (hi - lo > 1) {
        mid = (lo + hi) / 2;
        delta = Kino1_BB_compare(cache[mid], endpost);
        if (delta > 0) 
            hi = mid;
        else
            lo = mid;
    }

    run->slice_size = lo == -1 
        ? 0 
        : (lo - run->cache_pos) + 1;
    return run->slice_size;
}

/* Standard merge sort.
 */
static void
Kino1_SortEx_mergesort(ByteBuf **bufbuf, ByteBuf **scratch, I32 buf_size) {
    if (buf_size == 0)
        return;
    Kino1_SortEx_msort(bufbuf, scratch, 0, buf_size - 1);
}

/* Standard merge sort msort function.
 */
static void
Kino1_SortEx_msort(ByteBuf **bufbuf, ByteBuf **scratch, U32 left, U32 right) {
    I32 mid;

    if (right > left) {
        mid = ( (right+left)/2 ) + 1;
        Kino1_SortEx_msort(bufbuf, scratch, left, mid - 1);
        Kino1_SortEx_msort(bufbuf, scratch, mid,  right);
        Kino1_SortEx_merge( (bufbuf + left),  (mid - left), 
                           (bufbuf + mid), (right - mid + 1), scratch);
        Copy( scratch, (bufbuf + left), (right - left + 1), ByteBuf* );
    }
}

/* Standard mergesort merge function.  This variant is capable of merging two
 * discontiguous source arrays.  Copying elements back into the source is left
 * for the caller.
 */
static void
Kino1_SortEx_merge(ByteBuf **left_ptr,  U32 left_size,
                  ByteBuf **right_ptr, U32 right_size,
                  ByteBuf **dest) {
    ByteBuf **left_boundary, **right_boundary;

    left_boundary  = left_ptr  + left_size;
    right_boundary = right_ptr + right_size;

    while (left_ptr < left_boundary && right_ptr < right_boundary) {
        if (Kino1_BB_compare(*left_ptr, *right_ptr) < 1) {
            *dest++ = *left_ptr++;
        }
        else {
            *dest++ = *right_ptr++;
        }
    }
    while (left_ptr < left_boundary) {
        *dest++ = *left_ptr++;
    }
    while (right_ptr < right_boundary) {
        *dest++ = *right_ptr++;
    }
}

static void
Kino1_SortEx_clear_cache(SortExternal *sortex) {
    ByteBuf **cache, **cache_end;
    cache_end = sortex->cache + sortex->cache_elems;
    /* only blow away items that haven't been released */
    for (cache = sortex->cache + sortex->cache_pos; 
         cache < cache_end; cache++
    ) {
        Kino1_BB_destroy(*cache);
    }
    sortex->cache_bytes = 0;
    sortex->cache_elems = 0;
    sortex->cache_pos   = 0;
}

static void
Kino1_SortEx_clear_run_cache(SortExRun *run) {
    ByteBuf **cache, **cache_end;
    cache_end = run->cache + run->cache_elems;
    /* only destroy items which haven't been passed to the main cache */
    for (cache = run->cache + run->cache_pos; cache < cache_end; cache++) {
        Kino1_BB_destroy(*cache);
    }
    run->cache_elems = 0;
    run->cache_pos   = 0;
}

void
Kino1_SortEx_destroy(SortExternal *sortex) {
    I32 i;
    
    /* delegate to Perl garbage collector */
    SvREFCNT_dec(sortex->outstream_sv);
    SvREFCNT_dec(sortex->instream_sv);
    SvREFCNT_dec(sortex->invindex_sv);
    SvREFCNT_dec(sortex->seg_name_sv);

    /* free the cache and the scratch */
    Kino1_SortEx_clear_cache(sortex);
    Kino1_Safefree(sortex->cache);
    Kino1_Safefree(sortex->scratch);

    /* free all of the runs and the array that held them */
    for (i = 0; i < sortex->num_runs; i++) {
        Kino1_SortEx_destroy_run(sortex->runs[i]);
    }
    Kino1_Safefree(sortex->runs);

    /* free me */
    Kino1_Safefree(sortex);
}

static void
Kino1_SortEx_destroy_run(SortExRun *run) {
    Kino1_SortEx_clear_run_cache(run);
    Kino1_Safefree(run->cache);
    Kino1_Safefree(run);
}

__POD__

==begin devdocs

==head1 NAME

KinoSearch1::Util::SortExternal - external sorting

==head1 DESCRIPTION

External sorting implementation, using lexical comparison.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut
