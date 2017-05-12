#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <gfsm.h>
#include <gfsmxl.h>

/*======================================================================
 * Debugging
 */
//#define GFSMXL_DEBUG 1

#ifdef GFSMXL_DEBUG
# define GFSMXL_DEBUG_EVAL(code_) code_
#else
# define GFSMXL_DEBUG_EVAL(code_)
#endif

/*======================================================================
 * Memory Stuff
 */
gpointer gfsm_perl_malloc(gsize n_bytes);
gpointer gfsm_perl_realloc(gpointer mem, gsize n_bytes);
void gfsm_perl_free(gpointer mem);

/*======================================================================
 * Gfsm::XL::Cascade Utilities
 */
typedef struct {
  gfsmxlCascade *csc;
  AV            *av;   //-- holds automaton scalars
} gfsmxlCascadePerl;

gfsmxlCascadePerl *gfsmxl_perl_cascade_new(void);
void gfsmxl_perl_cascade_clear(gfsmxlCascadePerl *cscp);
void gfsmxl_perl_cascade_free (gfsmxlCascadePerl *cscp);

void gfsmxl_perl_cascade_append_sv(gfsmxlCascadePerl *cscp, SV *xfsm_sv);
void gfsmxl_perl_cascade_set_sv(gfsmxlCascadePerl *cscp, guint n, SV *xfsm_sv);
SV*  gfsmxl_perl_cascade_get_sv(gfsmxlCascadePerl *cscp, int i);
SV*  gfsmxl_perl_cascade_pop_sv(gfsmxlCascadePerl *cscp);

void gfsmxl_perl_cascade_refresh_av(gfsmxlCascadePerl *cscp); //-- create cscp->av from csc->csc->xfsms

/*======================================================================
 * Gfsm::XL::Cascade::Lookup Utilities
 */
typedef struct {
  gfsmxlCascadeLookup *cl;     //-- underlying gfsmxlCascadeLookup struct
  SV                  *csc_sv; //-- holds SV* for underlying cascade
} gfsmxlCascadeLookupPerl;

gfsmxlCascadeLookupPerl *gfsmxl_perl_cascade_lookup_new(SV *csc_sv, gfsmWeight max_w, guint max_paths, guint max_ops);
void gfsmxl_perl_cascade_lookup_set_cascade_sv(gfsmxlCascadeLookupPerl *clp, SV *csc_sv);
void gfsmxl_perl_cascade_lookup_free (gfsmxlCascadeLookupPerl *clp);

/*======================================================================
 * Type conversions
 */
//AV *gfsm_perl_paths_to_av(gfsmSet *paths_s);
//HV *gfsm_perl_path_to_hv(gfsmPath *path);
//AV *gfsm_perl_ptr_array_to_av_uv(GPtrArray *ary);

AV *gfsm_perl_ptr_array_to_av_uv(GPtrArray *ary);
HV *gfsm_perl_path_to_hv(gfsmPath *path);
AV *gfsmxl_perl_patharray_to_av(gfsmxlPathArray *paths_a);

/*======================================================================
 * Weight stuff
 */
#ifdef GFSM_WEIGHT_IS_UNION
#define gfsm_perl_weight_setfloat(w,f) ((w).f=(f))
#define gfsm_perl_weight_getfloat(w)   ((w).f)
#else
typedef gfloat gfsmWeightVal;
#define gfsm_perl_weight_setfloat(w,f) ((w)=(f))
#define gfsm_perl_weight_getfloat(w)   (w)
#endif /* GFSM_WEIGHT_IS_UNION */

/*======================================================================
 * I/O: structs
 */
//-- struct for gfsm I/O to a perl scalar
typedef struct {
  SV     *sv; //-- scalar being written to
  size_t pos; //-- read position
} gfsmPerlSVHandle;

/*----------------------------------------------------------------------
 * I/O: Methods: SV*
 */
gfsmIOHandle *gfsmperl_io_new_sv(SV *sv, size_t pos);
void gfsmperl_io_free_sv(gfsmIOHandle *ioh);

gboolean gfsmperl_eof_sv(gfsmPerlSVHandle *svh);
gboolean gfsmperl_read_sv(gfsmPerlSVHandle *svh, void *buf, size_t nbytes);
gboolean gfsmperl_write_sv(gfsmPerlSVHandle *svh, const void *buf, size_t nbytes);
