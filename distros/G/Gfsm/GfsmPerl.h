#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <gfsm.h>

/*======================================================================
 * Debugging
 */
//#define GFSMDEBUG 1

#if defined(GFSMDEBUG) || defined(GFSM_PERL_DEBUG)
# define GFSM_PERL_DEBUG_EVAL(code_) code_
#else
# define GFSM_PERL_DEBUG_EVAL(code_)
#endif

/*======================================================================
 * Memory Stuff
 */

//-- GFSM_PERL_THREADS: if defined, use a mutex in all memory operations (doesn't work)
#undef GFSM_PERL_THREADS
//#define GFSM_PERL_THREADS

#ifdef GFSM_PERL_THREADS
# include "thread.h"
# define GFSM_PERL_USE_VTABLE 1
#endif

//-- GFSM_PERL_USE_VTABLE: if defined, make glib use perl memory management functions
#undef GFSM_PERL_USE_VTABLE
//#define GFSM_PERL_USE_VTABLE

//-- memory stuff: threads (broken)
#ifdef GFSM_PERL_THREADS
 extern perl_mutex gfsm_perl_mutex;
# define GFSM_PERL_LOCK   MUTEX_LOCK(&gfsm_perl_mutex)
# define GFSM_PERL_UNLOCK MUTEX_UNLOCK(&gfsm_perl_mutex)
#else
# define GFSM_PERL_LOCK
# define GFSM_PERL_UNLOCK
#endif

//-- memory stuff: vtable (seems to work)
#ifdef GFSM_PERL_USE_VTABLE
 extern GMemVTable gfsm_perl_vtable;
#endif

void gfsm_perl_init(void);
gpointer gfsm_perl_malloc(gsize n_bytes);
gpointer gfsm_perl_realloc(gpointer mem, gsize n_bytes);
void gfsm_perl_free(gpointer mem);

//-- memory stuff: post-object cleanup (blow chunks)
void gfsm_perl_blow_chunks(void);


AV *gfsm_perl_paths_to_av(gfsmSet *paths_s);
HV *gfsm_perl_path_to_hv(gfsmPath *path);
AV *gfsm_perl_ptr_array_to_av_uv(GPtrArray *ary);

AV *gfsm_perl_arcpaths_to_av(GSList *arcpaths);
SV *gfsm_perl_arcpath_to_sv(gfsmArcPath *ap);

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
 * gfsmPerlAlphabet: alphabet of scalars
 */

typedef struct {
  gfsmUserAlphabet a; //-- underlying alphabet
  HV *hv; //-- maps keys->labels
  AV *av; //-- maps labels->keys
} gfsmPerlAlphabet;

/*--------------------------------------------------------------
 * gfsmPerlAlphabet: constructors etc.
 */
gfsmAlphabet *gfsm_perl_alphabet_new(void);

void gfsm_perl_alphabet_free(gfsmPerlAlphabet *alph);

/*--------------------------------------------------------------
 * gfsmPerlAlphabet: user methods
 */

//-- key_lookup: key->label lookup function
gfsmLabelVal gfsm_perl_alphabet_key_lookup(gfsmPerlAlphabet *alph, SV* key);

//-- lab_lookup: label->key lookup function
SV* gfsm_perl_alphabet_label_lookup(gfsmPerlAlphabet *alph, gfsmLabelVal lab);

//-- insert: insertion function: receives a newly copied key!
gfsmLabelVal gfsm_perl_alphabet_insert(gfsmPerlAlphabet *alph, SV *key, gfsmLabelVal lab);

//-- lab_remove: label removal function
void gfsm_perl_alphabet_remove(gfsmPerlAlphabet *alph, gfsmLabelVal lab);

//-- string read function for perl scalars
SV *gfsm_perl_alphabet_scalar_read(gfsmPerlAlphabet *alph, GString *gstr);

//-- string write function for perl scalars
void gfsm_perl_alphabet_scalar_write(gfsmPerlAlphabet *alph, SV *sv, GString *gstr);

/*--------------------------------------------------------------
 * gfsmPerlAlphabet: debug
 */
#ifdef GFSMDEBUG
SV *addav(AV *av, int ix, SV *val);
void rmav(AV *av, int ix);
SV *addhv(HV *hv, SV *key, SV *val);
void rmhv(HV *hv, SV *key);
#endif


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
