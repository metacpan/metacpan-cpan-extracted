#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <stdarg.h>
#include <limits.h> /* For INT_MAX */

#include "marpa.h"
#include "config.h"
#include "marpaWrapper/internal/_asf.h"
#include "marpaWrapper/internal/_recognizer.h"
#include "marpaWrapper/internal/_grammar.h"
#include "marpaWrapper/internal/_logging.h"

#ifndef MARPAWRAPPERASF_INTSET_MAXROWS
#define MARPAWRAPPERASF_INTSET_MAXROWS 65536   /* x &0xFFFF */
#endif

#undef MARPAWRAPPERASF_INTSET_MODULO
/* x mod 65536 is x & 0xffff when x is unsigned */
/* #define MARPAWRAPPERASF_INTSET_MODULO (MARPAWRAPPERASF_INTSET_MAXROWS - 1) */
#define MARPAWRAPPERASF_INTSET_MODULO(x) ((x) & 0xFFFF)

#ifndef MARPAWRAPPERASF_FACTORING_MAX
#define MARPAWRAPPERASF_FACTORING_MAX 42
#endif

#ifndef MARPAWRAPPERASF_NID_LEAF_BASE
#define MARPAWRAPPERASF_NID_LEAF_BASE (-MARPAWRAPPERASF_FACTORING_MAX - 1)
#endif

/* The number of causes for a given nidset is very often a number quite small */
/* there the default genericStack available memory will suffice to indice     */
/* eveyrthing. If not memory will be allocated anyway.                        */
#ifndef MARPAWRAPPERASF_CAUSESHASH_SIZE
#if GENERICSTACK_DEFAULT_LENGTH > 0
#define MARPAWRAPPERASF_CAUSESHASH_SIZE GENERICSTACK_DEFAULT_LENGTH
#else
#define MARPAWRAPPERASF_CAUSESHASH_SIZE 128  /* Subjective number */
#endif
#endif

/* Same argument for all the sparse arrays below */
#ifndef MARPAWRAPPERASF_VALUESPARSEARRAY_SIZE
#if GENERICSTACK_DEFAULT_LENGTH > 0
#define MARPAWRAPPERASF_VALUESPARSEARRAY_SIZE GENERICSTACK_DEFAULT_LENGTH
#else
#define MARPAWRAPPERASF_VALUESPARSEARRAY_SIZE 128  /* Subjective number */
#endif
#endif

#ifndef MARPAWRAPPERASF_NIDSETSPARSEARRAY_SIZE
#if GENERICSTACK_DEFAULT_LENGTH > 0
#define MARPAWRAPPERASF_NIDSETSPARSEARRAY_SIZE GENERICSTACK_DEFAULT_LENGTH
#else
#define MARPAWRAPPERASF_NIDSETSPARSEARRAY_SIZE 128  /* Subjective number */
#endif
#endif

#ifndef MARPAWRAPPERASF_POWERSETSPARSEARRAY_SIZE
#if GENERICSTACK_DEFAULT_LENGTH > 0
#define MARPAWRAPPERASF_POWERSETSPARSEARRAY_SIZE GENERICSTACK_DEFAULT_LENGTH
#else
#define MARPAWRAPPERASF_POWERSETSPARSEARRAY_SIZE 128  /* Subjective number */
#endif
#endif

#ifndef MARPAWRAPPERASF_ORNODEINUSESPARSEARRAY_SIZE
#if GENERICSTACK_DEFAULT_LENGTH > 0
#define MARPAWRAPPERASF_ORNODEINUSESPARSEARRAY_SIZE GENERICSTACK_DEFAULT_LENGTH
#else
#define MARPAWRAPPERASF_ORNODEINUSESPARSEARRAY_SIZE 128  /* Subjective number */
#endif
#endif

static marpaWrapperAsfOption_t marpaWrapperAsfOptionDefault = {
  NULL,   /* genericLoggerp */
   1,     /* highRankOnlyb */
   1,     /* orderByRankb */
   0,     /* ambiguousb */
   0      /* maxParsesi */
};

static char *marpaWrapperAsfIdsets[_MARPAWRAPPERASFIDSET_IDSETE_MAX] = {
  "nidset",
  "powerset"
};

typedef struct marpaWrapperAfsAndNodeIdAndPredecessorId {
  Marpa_And_Node_ID andNodeIdi;
  Marpa_And_Node_ID andNodePredecessorIdi;
} marpaWrapperAfsAndNodeIdAndPredecessorId_t;

static inline void                       _marpaWrapperAsf_orNodeStackp_freev(marpaWrapperAsf_t *marpaWrapperAsfp);
static inline void                       _marpaWrapperAsf_gladeStackp_freev(marpaWrapperAsf_t *marpaWrapperAsfp);
static inline void                       _marpaWrapperAsf_glade_freev(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfGlade_t *gladep);
static inline void                       _marpaWrapperAsf_symchesStackp_freev(marpaWrapperAsf_t *marpaWrapperAsfp, genericStack_t *symchesStackp);
static inline void                       _marpaWrapperAsf_factoringStackp_freev(marpaWrapperAsf_t *marpaWrapperAsfp, genericStack_t **factoringStackpp);
static inline void                       _marpaWrapperAsf_factoringsStackp_freev(marpaWrapperAsf_t *marpaWrapperAsfp, genericStack_t *factoringsStackp);
static inline genericStack_t            *_marpaWrapperAsf_factoringStackp_resetb(marpaWrapperAsf_t *marpaWrapperAsfp, genericStack_t **factoringStackpp);
static inline short                      _marpaWrapperAsf_peakb(marpaWrapperAsf_t *marpaWrapperAsfp, int *gladeIdip);
static inline int                        _marpaWrapperAsf_andNodeIdAndPredecessorIdCmpi(const void *p1, const void *p2);
static inline short                      _marpaWrapperAsf_intsetIdb(marpaWrapperAsf_t *marpaWrapperAsfp, int *intsetIdip, int counti, int *idip);
static inline int                        _marpaWrapperAsf_idCmpi(const void *p1, const void *p2);

static inline marpaWrapperAsfIdset_t    *_marpaWrapperAsf_idset_obtainp(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfIdsete_t idsete, int counti, int *idip);
static inline int                       *_marpaWrapperAsf_idset_idip(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfIdsete_t idsete, marpaWrapperAsfIdset_t *idsetp);
static inline short                      _marpaWrapperAsf_idset_idi_by_ixib(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfIdsete_t idsete, marpaWrapperAsfIdset_t *idsetp, int ixi, int *idip);
static inline int                        _marpaWrapperAsf_idset_counti(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfIdsete_t idsete, marpaWrapperAsfIdset_t *idsetp);
static inline int                        _marpaWrapperAsf_idset_idi(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfIdsete_t idsete, marpaWrapperAsfIdset_t *idsetp);
static inline void                       _marpaWrapperAsf_idset_freev(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfIdsete_t idsete);

/* nidset methods */
int                                      _marpaWrapperAsf_nidset_sparseArrayIndi(void *userDatavp, genericStackItemType_t itemType, void **pp);
void                                     _marpaWrapperAsf_nidset_sparseArrayFreev(void *userDatavp, void **pp);
static inline marpaWrapperAsfNidset_t   *_marpaWrapperAsf_nidset_obtainp(marpaWrapperAsf_t *marpaWrapperAsfp, int counti, int *idip);
static inline int                       *_marpaWrapperAsf_nidset_idip(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfIdset_t *idsetp);
static inline short                      _marpaWrapperAsf_nidset_idi_by_ixib(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfIdset_t *idsetp, int ixi, int *idip);
static inline int                        _marpaWrapperAsf_nidset_counti(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfIdset_t *idsetp);
static inline int                        _marpaWrapperAsf_nidset_idi(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfIdset_t *idsetp);
static inline void                       _marpaWrapperAsf_nidset_freev(marpaWrapperAsf_t *marpaWrapperAsfp);

/* powerset methods */
int                                      _marpaWrapperAsf_powerset_sparseArrayIndi(void *userDatavp, genericStackItemType_t itemType, void **pp);
void                                     _marpaWrapperAsf_powerset_sparseArrayFreev(void *userDatavp, void **pp);
static inline marpaWrapperAsfPowerset_t *_marpaWrapperAsf_powerset_obtainp(marpaWrapperAsf_t *marpaWrapperAsfp, int counti, int *idip);
static inline int                       *_marpaWrapperAsf_powerset_idip(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfIdset_t *idsetp);
static inline short                      _marpaWrapperAsf_powerset_idi_by_ixib(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfIdset_t *idsetp, int ixi, int *idip);
static inline int                        _marpaWrapperAsf_powerset_counti(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfIdset_t *idsetp);
static inline int                        _marpaWrapperAsf_powerset_idi(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfIdset_t *idsetp);
static inline void                       _marpaWrapperAsf_powerset_freev(marpaWrapperAsf_t *marpaWrapperAsfp);

/* Specific to nid */
static inline int                        _marpaWrapperAsf_nidset_sort_ixi(marpaWrapperAsf_t *marpaWrapperAsfp, int nidi);
static inline int                        _marpaWrapperAsf_and_node_to_nidi(int idi);
static inline int                        _marpaWrapperAsf_nid_to_and_nodei(int idi);
static inline int                        _marpaWrapperAsf_sourceDataCmpi(const void *p1, const void *p2);
static inline int                        _marpaWrapperAsf_nid_token_idi(marpaWrapperAsf_t *marpaWrapperAsfp, int nidi);
static inline int                        _marpaWrapperAsf_nid_symbol_idi(marpaWrapperAsf_t *marpaWrapperAsfp, int nidi);
static inline int                        _marpaWrapperAsf_nid_rule_idi(marpaWrapperAsf_t *marpaWrapperAsfp, int nidi);
static inline int                        _marpaWrapperAsf_nid_spani(marpaWrapperAsf_t *marpaWrapperAsfp, int nidi, int *lengthip);

/* Specific to powerset */
static inline marpaWrapperAsfNidset_t   *_marpaWrapperAsf_powerset_nidsetp(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfPowerset_t *powersetp, int ixi);
static inline marpaWrapperAsfGlade_t    *_marpaWrapperAsf_glade_obtainp(marpaWrapperAsf_t *marpaWrapperAsfp, int gladei);
static inline short                      _marpaWrapperAsf_first_factoringb(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfChoicePoint_t *choicepointp, int nidOfChoicePointi, short *firstFactoringbp);
static inline short                      _marpaWrapperAsf_factoring_finishb(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfChoicePoint_t *choicepointp, int nidOfChoicePointi, short *factoringFinishbp);
static inline short                      _marpaWrapperAsf_factoring_iterateb(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfChoicePoint_t *choicepointp, short *factoringIteratebp);
static inline short                      _marpaWrapperAsf_next_factoringb(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfChoicePoint_t *choicepointp, int nidOfChoicePointi, short *factoringbp);

/* Specific to glade */
static inline short                      _marpaWrapperAsf_glade_id_factorsb(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfChoicePoint_t *choicepointp, genericStack_t **stackpp);
int                                      _marpaWrapperAsf_causesHash_indi(void *userDatavp, genericStackItemType_t itemType, void **pp);
static inline short                      _marpaWrapperAsf_and_nodes_to_cause_nidsp(marpaWrapperAsf_t *marpaWrapperAsfp, genericStack_t *andNodeIdStackp, genericStack_t *causeNidsStackp);
#if MARPAWRAPPERASF_USE_VISITED_FLAG > 0
static inline short                      _marpaWrapperAsf_glade_is_visitedb(marpaWrapperAsf_t *marpaWrapperAsfp, int gladeIdi);
#endif
#if MARPAWRAPPERASF_USE_VISITED_FLAG > 0
static inline void                       _marpaWrapperAsf_glade_visited_clearb(marpaWrapperAsf_t *marpaWrapperAsfp, int *gladeIdip);
#endif
static inline short                      _marpaWrapperAsf_glade_symch_countb(marpaWrapperAsf_t *marpaWrapperAsfp, int gladeIdi, int *countip);
static inline int                        _marpaWrapperAsf_glade_symbol_idi(marpaWrapperAsf_t *marpaWrapperAsfp, int gladeIdi);
static inline int                        _marpaWrapperAsf_glade_spani(marpaWrapperAsf_t *marpaWrapperAsfp, int gladeIdi, int *lengthip);

/* Specific to orNodeInUseSparseArray */
int                                      _marpaWrapperAsf_orNodeInUse_sparseArrayIndi(void *userDatavp, genericStackItemType_t itemType, void **pp);

/* Specific to nook */
static inline marpaWrapperAsfNook_t     *_marpaWrapperAsf_nook_newp(marpaWrapperAsf_t *marpaWrapperAsfp, int orNodeIdi, int parentOrNodeIdi);
static inline short                      _marpaWrapperAsf_nook_has_semantic_causeb(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfNook_t *nookp);
static inline short                      _marpaWrapperAsf_setLastChoiceb(marpaWrapperAsf_t *marpaWrapperAsfp, short *haveLastChoicebp, marpaWrapperAsfNook_t *nookp);
static inline short                      _marpaWrapperAsf_nook_incrementb(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfNook_t *nookp, short *haveLastChoicebp);

/* Specific to symch */
static inline short                      _marpaWrapperAsf_symch_factoring_countb(marpaWrapperAsf_t *marpaWrapperAsfp, int gladeIdi, int symchIxi, int *factoringCountip);

/* Specific to intset */
int                                      _marpaWrapperAsf_intset_keyIndFunctioni(void *userDatavp, genericStackItemType_t itemType, void **pp);
short                                    _marpaWrapperAsf_intset_keyCmpFunctionb(void *userDatavp, void **pp1, void **pp2);
void                                    *_marpaWrapperAsf_intset_keyCopyFunctionp(void *userDatavp, void **pp);
void                                     _marpaWrapperAsf_intset_keyFreeFunctionv(void *userDatavp, void **pp);

/* General */
void                                     _marpaWrapperAsf_idset_sparseArrayFreev(void *userDatavp, void **pp);
static inline unsigned long              _marpaWrapperAsf_djb2(unsigned char *str);
static inline unsigned long              _marpaWrapperAsf_djb2_s(unsigned char *str, int lengthi);
static inline int                        _marpaWrapperAsf_token_es_spani(marpaWrapperAsf_t *marpaWrapperAsfp, int andNodeIdi, int *lengthip);
static inline int                        _marpaWrapperAsf_or_node_es_spani(marpaWrapperAsf_t *marpaWrapperAsfp, int choicepointi, int *lengthip);
#ifndef MARPAWRAPPER_NTRACE
static inline void                       _marpaWrapperAsf_dump_stack(marpaWrapperAsf_t *marpaWrapperAsfp, char *what, genericStack_t *stackp);
#endif
static inline short                      _marpaWrapperAsf_traverse_nextFactoringb(marpaWrapperAsfTraverser_t *traverserp, int *factoringIxip);
static inline short                      _marpaWrapperAsf_traverse_nextSymchb(marpaWrapperAsfTraverser_t *traverserp, int *symchIxip);

/* Specific to choicepoint */
static inline marpaWrapperAsfChoicePoint_t *_marpaWrapperAsf_choicepoint_newp(marpaWrapperAsf_t *marpaWrapperAsfp);
static inline void                          _marpaWrapperAsf_choicepoint_freev(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfChoicePoint_t *choicepointp);

/* Specific to value using the ASF */
static inline short                       _marpaWrapperAsf_valueTraverserb(marpaWrapperAsfTraverser_t *traverserp, void *userDatavp, int *valueip);

/* Specific to value sparse array */
int                                      _marpaWrapperAsf_valueSparseArray_indi(void *userDatavp, genericStackItemType_t itemType, void **pp);

/* For my very internal purpose */
#ifndef MARPAWRAPPER_NTRACE
static void _marpaWrapperAsf_dumpintsetHashpv(marpaWrapperAsf_t *marpaWrapperAsfp);
#endif

/****************************************************************************/
marpaWrapperAsf_t *marpaWrapperAsf_newp(marpaWrapperRecognizer_t *marpaWrapperRecognizerp, marpaWrapperAsfOption_t *marpaWrapperAsfOptionp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperAsf_newp);
  marpaWrapperAsf_t                          *marpaWrapperAsfp           = NULL;
  marpaWrapperAsfOrNode_t                    *orNodep                    = NULL;
  marpaWrapperAfsAndNodeIdAndPredecessorId_t *andNodeIdAndPredecessorIdp = NULL;
  genericLogger_t                            *genericLoggerp             = NULL;
  Marpa_Earley_Set_ID                         marpaLatestEarleySetIdi;
  int                                         highRankOnlyFlagi;
  int                                         ambiguousi;
  int                                         nulli;
  int                                         andNodeCounti;
  Marpa_Or_Node_ID                            orNodei;
  int                                         ixi;
  Marpa_And_Node_ID                           andNodeIdi;
  int                                        *andNodep;
  Marpa_And_Node_ID                           andNodePredecessorIdi;
  
  if (marpaWrapperRecognizerp == NULL) {
    errno = EINVAL;
    goto err;
  }

  if (marpaWrapperAsfOptionp == NULL) {
    marpaWrapperAsfOptionp = &marpaWrapperAsfOptionDefault;
  }
  genericLoggerp = marpaWrapperAsfOptionp->genericLoggerp;

  /* Impossible if we are already valuating it */
  if (marpaWrapperRecognizerp->treeModeb != MARPAWRAPPERRECOGNIZERTREEMODE_NA) {
    MARPAWRAPPER_ERROR(genericLoggerp, "Already in valuation mode");
    goto err;
  }

  /* Create an asf instance */
  marpaWrapperAsfp = malloc(sizeof(marpaWrapperAsf_t));
  if (marpaWrapperAsfp == NULL) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "malloc failure: %s", strerror(errno));
    goto err;
  }

  marpaWrapperAsfp->marpaWrapperRecognizerp = marpaWrapperRecognizerp;
  marpaWrapperAsfp->marpaWrapperAsfOption   = *marpaWrapperAsfOptionp;
  marpaWrapperAsfp->marpaBocagep            = NULL;
  marpaWrapperAsfp->marpaOrderp             = NULL;
  marpaWrapperAsfp->orNodeStackp            = NULL;
  marpaWrapperAsfp->intsetHashp             = NULL;
  marpaWrapperAsfp->nidsetSparseArrayp      = NULL;
  marpaWrapperAsfp->powersetSparseArrayp    = NULL;
  marpaWrapperAsfp->gladeStackp             = NULL;
  marpaWrapperAsfp->nextIntseti             = 0;
  marpaWrapperAsfp->traverserCallbackp      = NULL;
  marpaWrapperAsfp->userDatavp              = NULL;
  marpaWrapperAsfp->worklistStackp          = NULL;
  marpaWrapperAsfp->intsetidp               = NULL;
  marpaWrapperAsfp->intsetcounti            = 0;
  marpaWrapperAsfp->causeNidsp              = NULL;
  marpaWrapperAsfp->causeNidsi              = 0;
  marpaWrapperAsfp->gladeObtainTmpStackp    = NULL;
  marpaWrapperAsfp->causesHashp             = NULL;

  /* Always succeed as per the doc */
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_r_latest_earley_set(%p)", marpaWrapperRecognizerp->marpaRecognizerp);
  marpaLatestEarleySetIdi = marpa_r_latest_earley_set(marpaWrapperRecognizerp->marpaRecognizerp);

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_b_new(%p, %d)", marpaWrapperRecognizerp->marpaRecognizerp, (int) marpaLatestEarleySetIdi);
  marpaWrapperAsfp->marpaBocagep = marpa_b_new(marpaWrapperRecognizerp->marpaRecognizerp, marpaLatestEarleySetIdi);
  if (marpaWrapperAsfp->marpaBocagep == NULL) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
    goto err;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_o_new(%p)", marpaWrapperAsfp->marpaBocagep);
  marpaWrapperAsfp->marpaOrderp = marpa_o_new(marpaWrapperAsfp->marpaBocagep);
  if (marpaWrapperAsfp->marpaOrderp == NULL) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
    goto err;
  }

  highRankOnlyFlagi = (marpaWrapperAsfOptionp->highRankOnlyb != 0) ? 1 : 0;
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_o_high_rank_only_set(%p, %d)", marpaWrapperAsfp->marpaOrderp, highRankOnlyFlagi);
  if (marpa_o_high_rank_only_set(marpaWrapperAsfp->marpaOrderp, highRankOnlyFlagi) != highRankOnlyFlagi) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
    goto err;
  }

  if (marpaWrapperAsfOptionp->orderByRankb != 0) {
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_o_rank(%p)", marpaWrapperAsfp->marpaOrderp);
    if (marpa_o_rank(marpaWrapperAsfp->marpaOrderp) < 0) {
      MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
      goto err;
    }
  }

  if (marpaWrapperAsfOptionp->ambiguousb == 0) {
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_o_ambiguity_metric(%p)", marpaWrapperAsfp->marpaOrderp);
    ambiguousi = marpa_o_ambiguity_metric(marpaWrapperAsfp->marpaOrderp);
    if (ambiguousi < 0) {
      MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
      goto err;
    } else if (ambiguousi > 1) {
      MARPAWRAPPER_ERROR(genericLoggerp, "Parse is ambiguous");
      goto err;
    }
  }

  /* ASF is not possible for a null parse */
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_o_is_null(%p)", marpaWrapperAsfp->marpaOrderp);
  nulli = marpa_o_is_null(marpaWrapperAsfp->marpaOrderp);
  if (nulli < 0) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
    goto err;
  } else if (nulli >= 1) {
    MARPAWRAPPER_ERROR(genericLoggerp, "Parse is null");
    goto err;
  }
  
  GENERICSTACK_NEW(marpaWrapperAsfp->orNodeStackp);
  if (GENERICSTACK_ERROR(marpaWrapperAsfp->orNodeStackp)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "orNode stack initialization error, %s", strerror(errno));
    goto err;
  }

  GENERICHASH_NEW_ALL(marpaWrapperAsfp->intsetHashp,
                      _marpaWrapperAsf_intset_keyIndFunctioni,
                      _marpaWrapperAsf_intset_keyCmpFunctionb,
                      _marpaWrapperAsf_intset_keyCopyFunctionp,
                      _marpaWrapperAsf_intset_keyFreeFunctionv,
                      NULL,  /* The value type will always be INT: no need */
                      NULL,  /* for a copy not a free functions for the value */
                      MARPAWRAPPERASF_INTSET_MAXROWS,
                      0);
  if (GENERICHASH_ERROR(marpaWrapperAsfp->intsetHashp)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "Intset hash initialization error, %s", strerror(errno));
    goto err;
  }

  GENERICSPARSEARRAY_NEW_ALL(marpaWrapperAsfp->nidsetSparseArrayp,
			     _marpaWrapperAsf_nidset_sparseArrayIndi,
			     /* We make sure we never insert if it already exist: no need to an internal copy again. */
			     /* We take this as an advantage by returning what is allocated on the heap just before  */
			     /* the call to GENERICSPARSEARRAY_SET: this is alleviating the needed of another FIND.  */
			     NULL,
			     _marpaWrapperAsf_nidset_sparseArrayFreev, /* ... so we just need to free it */
			     MARPAWRAPPERASF_NIDSETSPARSEARRAY_SIZE, /* We know we hash on this number of rows */
			     0
			     );
  if (GENERICSPARSEARRAY_ERROR(marpaWrapperAsfp->nidsetSparseArrayp)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "Nidset sparse array initialization error, %s", strerror(errno));
    goto err;
  }

  GENERICSPARSEARRAY_NEW_ALL(marpaWrapperAsfp->powersetSparseArrayp,
			     _marpaWrapperAsf_powerset_sparseArrayIndi,
			     /* Same remark as before */
			     NULL,
			     _marpaWrapperAsf_powerset_sparseArrayFreev, /* ... so we just need to free it */
			     MARPAWRAPPERASF_POWERSETSPARSEARRAY_SIZE, /* We know we hash on this number of rows */
			     0
			     );
  if (GENERICSPARSEARRAY_ERROR(marpaWrapperAsfp->powersetSparseArrayp)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "Powerset sparse array error, %s", strerror(errno));
    goto err;
  }

  GENERICSTACK_NEW(marpaWrapperAsfp->gladeStackp);
  if (GENERICSTACK_ERROR(marpaWrapperAsfp->gladeStackp)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "glade stack initialization error, %s", strerror(errno));
    goto err;
  }

  GENERICSTACK_NEW(marpaWrapperAsfp->worklistStackp);
  if (GENERICSTACK_ERROR(marpaWrapperAsfp->worklistStackp)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "worklistStackp stack initialization error, %s", strerror(errno));
    goto err;
  }

  GENERICSTACK_NEW(marpaWrapperAsfp->gladeObtainTmpStackp);
  if (GENERICSTACK_ERROR(marpaWrapperAsfp->gladeObtainTmpStackp)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "gladeObtainTmpStackp stack initialization error, %s", strerror(errno));
    goto err;
  }

  GENERICHASH_NEW(marpaWrapperAsfp->causesHashp, _marpaWrapperAsf_causesHash_indi);
  if (GENERICHASH_ERROR(marpaWrapperAsfp->causesHashp)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "causesHashp hash initialization error, %s", strerror(errno));
    goto err;
  }

  /* Say we are in forest mode */
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Flagging tree mode to FOREST");
  marpaWrapperRecognizerp->treeModeb = MARPAWRAPPERRECOGNIZERTREEMODE_FOREST;

  /* Get all the primary AND nodes */
  for (orNodei = 0; ; orNodei++) {
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "_marpa_o_or_node_and_node_count(%p, %d)", marpaWrapperAsfp->marpaOrderp, orNodei);
    andNodeCounti = _marpa_o_or_node_and_node_count(marpaWrapperAsfp->marpaOrderp, orNodei);
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "OR Node Id %d says there are %d AND nodes", orNodei, andNodeCounti);
    if (andNodeCounti == -1) {
      andNodeCounti = 0;
    }
    if (andNodeCounti < 0) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "Invalid OR Node Id %d", orNodei);
      goto err;
    }
    if (andNodeCounti == 0) {
      break;
    }

    orNodep = malloc(sizeof(marpaWrapperAsfOrNode_t));
    if (orNodep == NULL) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "malloc failure: %s", strerror(errno));
      goto err;
    }
    andNodep = malloc(andNodeCounti * sizeof(int));
    if (andNodep == NULL) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "malloc failure: %s", strerror(errno));
      goto err;
    }

    orNodep->nAndNodei = andNodeCounti;
    orNodep->andNodep = andNodep;

    /* Prepare the sort the AND Node Ids or this OR Node using predecessor Id */
    andNodeIdAndPredecessorIdp = malloc(andNodeCounti * sizeof(marpaWrapperAfsAndNodeIdAndPredecessorId_t));
    if (andNodeIdAndPredecessorIdp == NULL) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "malloc failure: %s", strerror(errno));
      goto err;
    }

    for (ixi = 0; ixi < andNodeCounti; ixi++) {
      MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "_marpa_o_or_node_and_node_id_by_ix(%p, %d, %d)", marpaWrapperAsfp->marpaOrderp, orNodei, ixi);
      andNodeIdi = _marpa_o_or_node_and_node_id_by_ix(marpaWrapperAsfp->marpaOrderp, orNodei, ixi);
      MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "_marpa_b_and_node_predecessor(%p, %d);", marpaWrapperAsfp->marpaBocagep, andNodeIdi);
      andNodePredecessorIdi = _marpa_b_and_node_predecessor(marpaWrapperAsfp->marpaBocagep, andNodeIdi);
      if (andNodePredecessorIdi < 0) {
	andNodePredecessorIdi = -1;
      }

      andNodeIdAndPredecessorIdp[ixi].andNodeIdi            = andNodeIdi;
      andNodeIdAndPredecessorIdp[ixi].andNodePredecessorIdi = andNodePredecessorIdi;
    }

    qsort(andNodeIdAndPredecessorIdp,
	  (size_t) andNodeCounti,
	  sizeof(marpaWrapperAfsAndNodeIdAndPredecessorId_t),
	  _marpaWrapperAsf_andNodeIdAndPredecessorIdCmpi);
    
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "OR_NODE[%3d]", orNodei);
    for (ixi = 0; ixi < andNodeCounti; ixi++) {
      andNodep[ixi] = andNodeIdAndPredecessorIdp[ixi].andNodeIdi;
      MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "\tAND_NODE[%3d]: %3d", ixi, andNodep[ixi]);
    }

    free(andNodeIdAndPredecessorIdp);
    andNodeIdAndPredecessorIdp = NULL;

    GENERICSTACK_SET_PTR(marpaWrapperAsfp->orNodeStackp, orNodep, orNodei);
    if (GENERICSTACK_ERROR(marpaWrapperAsfp->orNodeStackp)) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "orNode stack failure: %s", strerror(errno));
      goto err;
    }

  }

  if (genericLoggerp != NULL) {
    MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Cloning genericLogger");

    marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp = GENERICLOGGER_CLONE(genericLoggerp);
    if (marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp == NULL) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "Failed to clone genericLogger: %s", strerror(errno));
      goto err;
    }
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return %p", marpaWrapperAsfp);
  return marpaWrapperAsfp;

err:
  if (marpaWrapperAsfp != NULL) {
    int errnoi = errno;

    if ((genericLoggerp != NULL) &&
        (marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp != NULL) &&
        (marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp != genericLoggerp)) {
      MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Freeing cloned genericLogger");
      GENERICLOGGER_FREE(marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp);
    }
    marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp = NULL;

    if (orNodep != NULL) {
      if (orNodep->andNodep != NULL) {
	free(orNodep->andNodep);
      }
      free(orNodep);
    }

    if (andNodeIdAndPredecessorIdp != NULL) {
      free(andNodeIdAndPredecessorIdp);
    }
    
    marpaWrapperAsf_freev(marpaWrapperAsfp);
    errno = errnoi;
  }

  if (marpaWrapperRecognizerp != NULL) {
    marpaWrapperRecognizerp->treeModeb = MARPAWRAPPERRECOGNIZERTREEMODE_NA;
  }

  return NULL;
}

/****************************************************************************/
short marpaWrapperAsf_traverseb(marpaWrapperAsf_t *marpaWrapperAsfp, traverserCallback_t traverserCallbackp, void *userDatavp, int *valueip)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperAsf_traverseb);
  genericLogger_t            *genericLoggerp = NULL;
  int                         gladeIdi;
  marpaWrapperAsfGlade_t     *gladep;
  marpaWrapperAsfTraverser_t  traverser;
  int                         valuei;
  genericSparseArray_t        valueSparseArray;
  genericSparseArray_t       *valueSparseArrayp = &valueSparseArray;

  GENERICSPARSEARRAY_INIT(valueSparseArrayp, _marpaWrapperAsf_valueSparseArray_indi);

  if (marpaWrapperAsfp == NULL) {
    errno = EINVAL;
    goto err;
  }

  genericLoggerp = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;

  if (traverserCallbackp == NULL) {
    MARPAWRAPPER_ERROR(genericLoggerp, "traverserCallbackp is NULL");
    goto err;
  }

  if (_marpaWrapperAsf_peakb(marpaWrapperAsfp, &gladeIdi) == 0) {
    goto err;
  }
  gladep = _marpaWrapperAsf_glade_obtainp(marpaWrapperAsfp, gladeIdi);
  if (gladep == NULL) {
    goto err;
  }

  marpaWrapperAsfp->traverserCallbackp = traverserCallbackp;
  marpaWrapperAsfp->userDatavp         = userDatavp;

  traverser.marpaWrapperAsfp  = marpaWrapperAsfp;
  traverser.valueSparseArrayp = valueSparseArrayp;
  traverser.gladep            = gladep;
  traverser.symchIxi          = 0;
  traverser.factoringIxi      = 0;

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Calling traverser for glade %d", gladep->idi);
  if (! marpaWrapperAsfp->traverserCallbackp(&traverser, marpaWrapperAsfp->userDatavp, &valuei)) {
    goto err;
  }

  if (valueip != NULL) {
    *valueip = valuei;
  }
  GENERICSPARSEARRAY_RESET(valueSparseArrayp, marpaWrapperAsfp);
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 1");
  return 1;

 err:
  GENERICSPARSEARRAY_RESET(valueSparseArrayp, marpaWrapperAsfp);
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

/****************************************************************************/
void marpaWrapperAsf_freev(marpaWrapperAsf_t *marpaWrapperAsfp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperAsf_freev);
  genericLogger_t         *genericLoggerp;

  if (marpaWrapperAsfp != NULL) {
    /* Keep a copy of the generic logger. If original is not NULL, then we have a clone of it */
    genericLoggerp = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;

    if (marpaWrapperAsfp->marpaOrderp != NULL) {
      MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_o_unref(%p)", marpaWrapperAsfp->marpaOrderp);
      marpa_o_unref(marpaWrapperAsfp->marpaOrderp);
    }

    if (marpaWrapperAsfp->marpaBocagep != NULL) {
      MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_b_unref(%p)", marpaWrapperAsfp->marpaBocagep);
      marpa_b_unref(marpaWrapperAsfp->marpaBocagep);
    }

    if (marpaWrapperAsfp->marpaWrapperRecognizerp != NULL) {
      MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Flagging tree mode to NA");
      marpaWrapperAsfp->marpaWrapperRecognizerp->treeModeb = MARPAWRAPPERRECOGNIZERTREEMODE_NA;
    }

    MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Freeing orNode stack");
    _marpaWrapperAsf_orNodeStackp_freev(marpaWrapperAsfp);

    MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Freeing intset hash");
#ifndef MARPAWRAPPER_NTRACE
    _marpaWrapperAsf_dumpintsetHashpv(marpaWrapperAsfp);
#endif
    GENERICHASH_FREE(marpaWrapperAsfp->intsetHashp, marpaWrapperAsfp);

    MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Freeing Nidset stack");
    _marpaWrapperAsf_nidset_freev(marpaWrapperAsfp);

    MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Freeing Powerset stack");
    _marpaWrapperAsf_powerset_freev(marpaWrapperAsfp);

    MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Freeing glade stack");
    _marpaWrapperAsf_gladeStackp_freev(marpaWrapperAsfp);

    MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Freeing worklist stack");
    GENERICSTACK_FREE(marpaWrapperAsfp->worklistStackp);

    if (marpaWrapperAsfp->intsetidp != NULL) {
      MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Freeing intsetidp");
      free(marpaWrapperAsfp->intsetidp);
    }

    if (marpaWrapperAsfp->causeNidsp != NULL) {
      MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Freeing causeNidsp");
      free(marpaWrapperAsfp->causeNidsp);
    }

    MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Freeing gladeObtainTmpStackp");
    GENERICSTACK_FREE(marpaWrapperAsfp->gladeObtainTmpStackp);

    MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Freeing causesHashp");
    GENERICHASH_FREE(marpaWrapperAsfp->causesHashp, marpaWrapperAsfp);

    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "free(%p)", marpaWrapperAsfp);
    free(marpaWrapperAsfp);

    if (genericLoggerp != NULL) {
      MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Freeing cloned generic logger");
      GENERICLOGGER_FREE(genericLoggerp);
    }
  }
}

/****************************************************************************/
static inline void _marpaWrapperAsf_orNodeStackp_freev(marpaWrapperAsf_t *marpaWrapperAsfp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_orNodeStackp_freev);
  int                      orNodeUsedi;
  int                      i;
  marpaWrapperAsfOrNode_t *orNodep;

  if (marpaWrapperAsfp->orNodeStackp != NULL) {
    orNodeUsedi = GENERICSTACK_USED(marpaWrapperAsfp->orNodeStackp);
    for (i = 0; i < orNodeUsedi; i++) {
      if (GENERICSTACK_IS_PTR(marpaWrapperAsfp->orNodeStackp, i)) {
	orNodep = GENERICSTACK_GET_PTR(marpaWrapperAsfp->orNodeStackp, i);
	if (orNodep->andNodep != NULL) {
	  free(orNodep->andNodep);
	}
	free(orNodep);
      }
    }
    GENERICSTACK_FREE(marpaWrapperAsfp->orNodeStackp);
  }
}

/****************************************************************************/
static inline void _marpaWrapperAsf_gladeStackp_freev(marpaWrapperAsf_t *marpaWrapperAsfp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_gladeStackp_freev);
  int                      gladeUsedi;
  int                      i;
  marpaWrapperAsfGlade_t  *gladep;

  if (marpaWrapperAsfp->gladeStackp != NULL) {
    gladeUsedi = GENERICSTACK_USED(marpaWrapperAsfp->gladeStackp);
    for (i = 0; i < gladeUsedi; i++) {
      if (GENERICSTACK_IS_PTR(marpaWrapperAsfp->gladeStackp, i)) {
	gladep = GENERICSTACK_GET_PTR(marpaWrapperAsfp->gladeStackp, i);
        _marpaWrapperAsf_glade_freev(marpaWrapperAsfp, gladep);
      }
    }
    GENERICSTACK_FREE(marpaWrapperAsfp->gladeStackp);
  }
}

/****************************************************************************/
static inline void _marpaWrapperAsf_glade_freev(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfGlade_t *gladep)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_glade_freev);

  if (gladep != NULL) {
    _marpaWrapperAsf_symchesStackp_freev(marpaWrapperAsfp, gladep->symchesStackp);
    free(gladep);
  }
}

/****************************************************************************/
static inline void _marpaWrapperAsf_symchesStackp_freev(marpaWrapperAsf_t *marpaWrapperAsfp, genericStack_t *symchesStackp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_symchesStackp_freev);
  int                      symchesUsedi;
  int                      i;
  genericStack_t          *factoringsStackp;

  if (symchesStackp != NULL) {
    symchesUsedi = GENERICSTACK_USED(symchesStackp);
    for (i = 0; i < symchesUsedi; i++) {
      /* symchesStackp is a stack of factoringsStackp */
      if (GENERICSTACK_IS_PTR(symchesStackp, i)) {
	factoringsStackp = GENERICSTACK_GET_PTR(symchesStackp, i);
	_marpaWrapperAsf_factoringsStackp_freev(marpaWrapperAsfp, factoringsStackp);
      }
    }
    GENERICSTACK_FREE(symchesStackp);
  }
}

/****************************************************************************/
static inline void _marpaWrapperAsf_factoringStackp_freev(marpaWrapperAsf_t *marpaWrapperAsfp, genericStack_t **factoringStackpp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_factoringStackp_freev);
  int                      factoringUsedi;
  int                      i;
  marpaWrapperAsfNook_t   *nookp;

  if (factoringStackpp != NULL) {
    genericStack_t *factoringStackp = *factoringStackpp;
    if (factoringStackp != NULL) {
      factoringUsedi = GENERICSTACK_USED(factoringStackp);
      for (i = 0; i < factoringUsedi; i++) {
	if (GENERICSTACK_IS_PTR(factoringStackp, i)) {
	  nookp = GENERICSTACK_GET_PTR(factoringStackp, i);
	  if (nookp != NULL) {
	    free(nookp);
	  }
	}
      }
      GENERICSTACK_FREE(factoringStackp);
    }
    *factoringStackpp = NULL;
  }
}

/****************************************************************************/
static inline void _marpaWrapperAsf_factoringsStackp_freev(marpaWrapperAsf_t *marpaWrapperAsfp, genericStack_t *factoringsStackp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_factoringsStackp_freev);
  int                      factoringsUsedi;
  int                      i;
  genericStack_t          *localStackp;

  if (factoringsStackp != NULL) {
    factoringsUsedi = GENERICSTACK_USED(factoringsStackp);
    /* At indice >= 2, factoringsStackp can contain inner generic stacks */
    /* that are an array of gladeIdi */
    for (i = 2; i < factoringsUsedi; i++) {
      if (GENERICSTACK_IS_PTR(factoringsStackp, i)) {
        localStackp = GENERICSTACK_GET_PTR(factoringsStackp, i);
	GENERICSTACK_FREE(localStackp);
      }
    }
    /* Note: GENERICSTACK_FREE() is always restting the pointer as well */
    GENERICSTACK_FREE(factoringsStackp);
  }
}

/****************************************************************************/
static inline genericStack_t *_marpaWrapperAsf_factoringStackp_resetb(marpaWrapperAsf_t *marpaWrapperAsfp, genericStack_t **factoringStackpp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_factoringStackp_resetb);
  genericLogger_t             *genericLoggerp = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
  genericStack_t              *factoringStackp;

  if (factoringStackpp == NULL) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "factoringStackpp is NULL", strerror(errno));
    goto err;
  }
  _marpaWrapperAsf_factoringStackp_freev(marpaWrapperAsfp, factoringStackpp);
  GENERICSTACK_NEW(factoringStackp);
  if (GENERICSTACK_ERROR(factoringStackp)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "factoringStack reset failure: %s", strerror(errno));
    goto err;
  }

  *factoringStackpp = factoringStackp;
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return %p", factoringStackp);
  return factoringStackp;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return NULL");
  return NULL;
}

/****************************************************************************/
static inline short _marpaWrapperAsf_peakb(marpaWrapperAsf_t *marpaWrapperAsfp, int *gladeIdip)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_peakb);
  genericLogger_t         *genericLoggerp = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
  genericStack_t          *orNodeStackp   = marpaWrapperAsfp->orNodeStackp;
  int                      augmentOrNodeIdi;
  int                      augmentAndNodeIdi;
  int                      startOrNodeIdi;
  marpaWrapperAsfNidset_t *baseNidsetp;
  marpaWrapperAsfOrNode_t *orNodep;
  int                      gladeIdi;
  marpaWrapperAsfGlade_t  *gladep;

  augmentOrNodeIdi = (int) _marpa_b_top_or_node(marpaWrapperAsfp->marpaBocagep);
  if (augmentOrNodeIdi < -1) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperAsfp->marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
    goto err;
  }

  if (! GENERICSTACK_IS_PTR(orNodeStackp, augmentOrNodeIdi)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "marpaWrapperAsfp->orNodeStackp not a pointer at indice %d", augmentOrNodeIdi);
    goto err;
  }
  orNodep = GENERICSTACK_GET_PTR(orNodeStackp, augmentOrNodeIdi);

  if (orNodep->nAndNodei <= 0) {
    MARPAWRAPPER_ERROR(genericLoggerp, "No AND node at this orNode stack");
    goto err;
  }
  augmentAndNodeIdi = orNodep->andNodep[0];
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "_marpa_b_and_node_cause(%p, %d);", marpaWrapperAsfp->marpaBocagep, augmentAndNodeIdi);
  startOrNodeIdi = _marpa_b_and_node_cause(marpaWrapperAsfp->marpaBocagep, augmentAndNodeIdi);
  if (startOrNodeIdi < -1) {
    MARPAWRAPPER_MARPA_G_ERROR(genericLoggerp, marpaWrapperAsfp->marpaWrapperRecognizerp->marpaWrapperGrammarp->marpaGrammarp);
    goto err;
  }

  baseNidsetp = _marpaWrapperAsf_nidset_obtainp(marpaWrapperAsfp, 1, &startOrNodeIdi);
  if (baseNidsetp == NULL) {
    goto err;
  }

  /* We cannot "obtain" the glade if it is not registered */
  gladeIdi = _marpaWrapperAsf_nidset_idi(marpaWrapperAsfp, baseNidsetp);
  if (! GENERICSTACK_IS_PTR(marpaWrapperAsfp->gladeStackp, gladeIdi)) {

    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Generating glade at indice %d", gladeIdi);
    gladep = malloc(sizeof(marpaWrapperAsfGlade_t));

    if (gladep == NULL) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "malloc failure: %s", strerror(errno));
      goto err;
    }
    gladep->idi           = gladeIdi;
    gladep->symchesStackp = NULL;
#if MARPAWRAPPERASF_USE_VISITED_FLAG > 0
    gladep->visitedb      = 0;
#endif
#if MARPAWRAPPERASF_USE_REGISTERED_FLAG > 0
    gladep->registeredb   = 1;
#endif
    GENERICSTACK_SET_PTR(marpaWrapperAsfp->gladeStackp, gladep, gladeIdi);
    if (GENERICSTACK_ERROR(marpaWrapperAsfp->gladeStackp)) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "glade stack failure: %s", strerror(errno));
      free(gladep);
      goto err;
    }
  } else {

    gladep = GENERICSTACK_GET_PTR(marpaWrapperAsfp->gladeStackp,  gladeIdi);
#if MARPAWRAPPERASF_USE_REGISTERED_FLAG > 0
    gladep->registeredb   = 1;
#endif
  }

  if (_marpaWrapperAsf_glade_obtainp(marpaWrapperAsfp, gladeIdi) == NULL) {
    goto err;
  }

  *gladeIdip = gladeIdi;
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return 1, *gladeIdip=%d", *gladeIdip);
  return 1;

 err:
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return 0", 0);
  return 0;
}

/****************************************************************************/
static inline int _marpaWrapperAsf_andNodeIdAndPredecessorIdCmpi(const void *p1, const void *p2)
/****************************************************************************/
{
  marpaWrapperAfsAndNodeIdAndPredecessorId_t *a1 = (marpaWrapperAfsAndNodeIdAndPredecessorId_t *) p1;
  marpaWrapperAfsAndNodeIdAndPredecessorId_t *a2 = (marpaWrapperAfsAndNodeIdAndPredecessorId_t *) p2;

  return
    (a1->andNodePredecessorIdi < a2->andNodePredecessorIdi)
    ?
    -1
    :
    (
     (a1->andNodePredecessorIdi > a2->andNodePredecessorIdi)
     ?
     1
     :
     (
      (a1->andNodeIdi < a2->andNodeIdi)
      ?
      -1
      :
      (
       (a1->andNodeIdi > a2->andNodeIdi)
       ?
       1
       :
       0
       )
      )
     )
    ;
}

/****************************************************************************/
static inline short _marpaWrapperAsf_intsetIdb(marpaWrapperAsf_t *marpaWrapperAsfp, int *intsetIdip, int counti, int *idip)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_intsetIdb);
  genericLogger_t         *genericLoggerp = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
  genericHash_t           *intsetHashp    = marpaWrapperAsfp->intsetHashp;
  int                      intsetcounti   = counti + 1;
  short                    findResultb;
  int                      intsetIdi;
  int                     *intsetidp;
  int                      indicei;
  int                      idi0i;
  int                      idi1i;

  /* This method is responsible of memoization and is called very often */
  if (intsetcounti > marpaWrapperAsfp->intsetcounti) {
    if (marpaWrapperAsfp->intsetcounti <= 0) {
      intsetidp = marpaWrapperAsfp->intsetidp = (int *) malloc(sizeof(int) * intsetcounti);
      if (intsetidp == NULL) {
	MARPAWRAPPER_ERRORF(genericLoggerp, "malloc failure: %s", strerror(errno));
	goto err;
      }
    } else {
      intsetidp = realloc(marpaWrapperAsfp->intsetidp, sizeof(int) * intsetcounti);
      if (intsetidp == NULL) {
	MARPAWRAPPER_ERRORF(genericLoggerp, "realloc failure: %s", strerror(errno));
	goto err;
      } else {
	marpaWrapperAsfp->intsetidp = intsetidp;
      }
    }
    marpaWrapperAsfp->intsetcounti = intsetcounti;
  } else {
    intsetidp = marpaWrapperAsfp->intsetidp;
  }

  *intsetidp = counti;
  if (counti > 0) {
    switch (counti) {
    case 1:
      intsetidp[1] = idip[0];
      break;
    case 2:
      idi0i = idip[0];
      idi1i = idip[1];
      if (idi0i < idi1i) {
	intsetidp[1] = idi0i;
	intsetidp[2] = idi1i;
      } else {
	intsetidp[1] = idi1i;
	intsetidp[2] = idi0i;
      }
      break;
    default:
      memcpy(++intsetidp, idip, sizeof(int) * counti);
      qsort(intsetidp--, (size_t) counti, sizeof(int), _marpaWrapperAsf_idCmpi);
      break;
    }
  }

#ifndef MARPAWRAPPER_NTRACE
  {
    int idi;
    MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Looking for this context:");
    if (counti > 0) {
      for (idi = 1; idi <= counti; idi++) {
	MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "   idi[0]=%d", intsetidp[idi]);
      }
    }
  }
#endif
  /* If we are going to insert, we want to precompute indice instead of letting */
  /* the hash macros doing it for the find(), and then for the set().           */
  indicei = _marpaWrapperAsf_intset_keyIndFunctioni((void *) marpaWrapperAsfp, GENERICSTACKITEMTYPE_PTR, (void **) &intsetidp);
  GENERICHASH_FIND_BY_IND(intsetHashp,
			  marpaWrapperAsfp,
			  PTR,
			  intsetidp,
			  INT,
			  &intsetIdi,
			  findResultb,
			  indicei);
  if (GENERICHASH_ERROR(intsetHashp)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "intset hash find failure: %s", strerror(errno));
    goto err;
  }
  if (! findResultb) {
    intsetIdi = marpaWrapperAsfp->nextIntseti++;
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Creating next intset id %d at hash row indice %d", intsetIdi, indicei);
    GENERICHASH_SET_BY_IND(intsetHashp,
			   marpaWrapperAsfp,
			   PTR,
			   intsetidp,
			   INT,
			   intsetIdi,
			   indicei);
    if (GENERICHASH_ERROR(intsetHashp)) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "intset hash set failure: %s", strerror(errno));
      goto err;
    }
  } else {
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Found intset id %d at hash row %d", intsetIdi, indicei);
  }

  *intsetIdip = intsetIdi;

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return 1, *intsetIdip=%d", *intsetIdip);
  return 1;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

/****************************************************************************/
static inline int _marpaWrapperAsf_idCmpi(const void *p1, const void *p2)
/****************************************************************************/
{
  int i1 = * ((int *) p1);
  int i2 = * ((int *) p2);

  return (i1 < i2) ? -1 : ((i1 > i2) ? 1 : 0);
}

/****************************************************************************/
static inline marpaWrapperAsfIdset_t *_marpaWrapperAsf_idset_obtainp(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfIdsete_t idsete, int counti, int *idip)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_idset_obtainp);
  genericLogger_t         *genericLoggerp = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
  genericSparseArray_t    *sparseArrayp   = (idsete == MARPAWRAPPERASFIDSET_NIDSET) ? marpaWrapperAsfp->nidsetSparseArrayp : marpaWrapperAsfp->powersetSparseArrayp;
  char                    *idsets         = marpaWrapperAsfIdsets[idsete];
  marpaWrapperAsfIdset_t  *idsetp         = NULL;
  int                      intsetIdi;
  short                    findResult;

  if (_marpaWrapperAsf_intsetIdb(marpaWrapperAsfp, &intsetIdi, counti, idip) == 0) {
    goto done;
  }

  GENERICSPARSEARRAY_FIND(sparseArrayp, marpaWrapperAsfp, intsetIdi, PTR, &idsetp, findResult);
  if (GENERICSPARSEARRAY_ERROR(sparseArrayp)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "%s, sparse array find failure: %s", idsets, strerror(errno));
    goto done;
  }
  if (! findResult) {
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "%s: indice %d not yet generated", idsets, intsetIdi);
    idsetp = (marpaWrapperAsfIdset_t *) malloc(sizeof(marpaWrapperAsfIdset_t));
    if (idsetp == NULL) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "malloc failure: %s", strerror(errno));
      goto done;
    }
    idsetp->idi = intsetIdi;
    idsetp->counti = counti;
    if (counti <= 0) {
      idsetp->idip = NULL;
    } else {
      if ((idsetp->idip = malloc(sizeof(int) * counti)) == NULL) {
	MARPAWRAPPER_ERRORF(genericLoggerp, "malloc failure: %s", strerror(errno));
	free(idsetp);
	idsetp = NULL;
	goto done;
      }
      memcpy(idsetp->idip, idip, (size_t) (counti * sizeof(int)));
      qsort(idsetp->idip, (size_t) counti, sizeof(int), _marpaWrapperAsf_idCmpi);
    }
    GENERICSPARSEARRAY_SET(sparseArrayp, marpaWrapperAsfp, intsetIdi, PTR, idsetp);
    if (GENERICSPARSEARRAY_ERROR(sparseArrayp)) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "%s sparse array set failure: %s", idsets, strerror(errno));
      if (idsetp->idip != NULL) {
	free(idsetp->idip);
      }
      free(idsetp);
      idsetp = NULL;
      goto done;
    }
  }

 done:
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "%s: return %p", idsets, idsetp);
  return idsetp;
}

/****************************************************************************/
static inline int *_marpaWrapperAsf_idset_idip(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfIdsete_t idsete, marpaWrapperAsfIdset_t *idsetp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_idset_idip);
#ifndef MARPAWRAPPER_NTRACE
  genericLogger_t         *genericLoggerp = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
#endif

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "%s: return %p", marpaWrapperAsfIdsets[idsete], idsetp->idip);
  return idsetp->idip;
}

/****************************************************************************/
static inline short _marpaWrapperAsf_idset_idi_by_ixib(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfIdsete_t idsete, marpaWrapperAsfIdset_t *idsetp, int ixi, int *idip)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_idset_idi_by_ixib);
  genericLogger_t         *genericLoggerp = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;

  if (ixi >= idsetp->counti) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "%s: indice %d out of range [0..%d[", marpaWrapperAsfIdsets[idsete], ixi, idsetp->counti);
    goto err;
  }

  *idip = idsetp->idip[ixi];

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "%s: return 1, *idip=%d", marpaWrapperAsfIdsets[idsete], *idip);
  return 1;

 err:
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "%s: return 0", marpaWrapperAsfIdsets[idsete]);
  return 0;
  
}

/****************************************************************************/
static inline int _marpaWrapperAsf_idset_counti(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfIdsete_t idsete, marpaWrapperAsfIdset_t *idsetp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_idset_counti);
#ifndef MARPAWRAPPER_NTRACE
  genericLogger_t         *genericLoggerp = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
#endif

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "%s: return %d", marpaWrapperAsfIdsets[idsete], idsetp->counti);
  return idsetp->counti;
}

/****************************************************************************/
static inline int _marpaWrapperAsf_idset_idi(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfIdsete_t idsete, marpaWrapperAsfIdset_t *idsetp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_idset_idi);
#ifndef MARPAWRAPPER_NTRACE
  genericLogger_t         *genericLoggerp = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
#endif

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "%s: return %d", marpaWrapperAsfIdsets[idsete], (int) idsetp->idi);
  return idsetp->idi;
}

/****************************************************************************/
static inline void _marpaWrapperAsf_idset_freev(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfIdsete_t idsete)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_idset_freev);
  genericSparseArray_t   **sparseArraypp  = (idsete == MARPAWRAPPERASFIDSET_NIDSET) ? &(marpaWrapperAsfp->nidsetSparseArrayp) : &(marpaWrapperAsfp->powersetSparseArrayp);
  genericSparseArray_t    *sparseArrayp;

  if (*sparseArraypp != NULL) {
    sparseArrayp = *sparseArraypp;
    GENERICSPARSEARRAY_FREE(sparseArrayp, marpaWrapperAsfp);
    *sparseArraypp = NULL;
  }
}

/****************************************************************************/
int _marpaWrapperAsf_nidset_sparseArrayIndi(void *userDatavp, genericStackItemType_t itemType, void **pp)
/****************************************************************************/
{
  return _marpaWrapperAsf_djb2_s((unsigned char *) pp, sizeof(int)) % MARPAWRAPPERASF_NIDSETSPARSEARRAY_SIZE;
  /* We know what we are doing, i.e. that *pp is a positive int */
  /* return (* ((int *) pp)) % MARPAWRAPPERASF_NIDSETSPARSEARRAY_SIZE; */
}

/****************************************************************************/
void _marpaWrapperAsf_nidset_sparseArrayFreev(void *userDatavp, void **pp)
/****************************************************************************/
{
  _marpaWrapperAsf_idset_sparseArrayFreev(userDatavp, pp);
}

/****************************************************************************/
static inline marpaWrapperAsfNidset_t *_marpaWrapperAsf_nidset_obtainp(marpaWrapperAsf_t *marpaWrapperAsfp, int counti, int *idip)
/****************************************************************************/
{
  return _marpaWrapperAsf_idset_obtainp(marpaWrapperAsfp, MARPAWRAPPERASFIDSET_NIDSET, counti, idip);
}

/****************************************************************************/
static inline int *_marpaWrapperAsf_nidset_idip(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfIdset_t *idsetp)
/****************************************************************************/
{
  return _marpaWrapperAsf_idset_idip(marpaWrapperAsfp, MARPAWRAPPERASFIDSET_NIDSET, idsetp);
}

/****************************************************************************/
static inline short _marpaWrapperAsf_nidset_idi_by_ixib(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfIdset_t *idsetp, int ixi, int *idip)
/****************************************************************************/
{
  return _marpaWrapperAsf_idset_idi_by_ixib(marpaWrapperAsfp, MARPAWRAPPERASFIDSET_NIDSET, idsetp, ixi, idip);
}

/****************************************************************************/
static inline int _marpaWrapperAsf_nidset_counti(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfIdset_t *idsetp)
/****************************************************************************/
{
  return _marpaWrapperAsf_idset_counti(marpaWrapperAsfp, MARPAWRAPPERASFIDSET_NIDSET, idsetp);
}

/****************************************************************************/
static inline int _marpaWrapperAsf_nidset_idi(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfIdset_t *idsetp)
/****************************************************************************/
{
  return _marpaWrapperAsf_idset_idi(marpaWrapperAsfp, MARPAWRAPPERASFIDSET_NIDSET, idsetp);
}

/****************************************************************************/
static inline void _marpaWrapperAsf_nidset_freev(marpaWrapperAsf_t *marpaWrapperAsfp)
/****************************************************************************/
{
  _marpaWrapperAsf_idset_freev(marpaWrapperAsfp, MARPAWRAPPERASFIDSET_NIDSET);
}

/****************************************************************************/
int _marpaWrapperAsf_powerset_sparseArrayIndi(void *userDatavp, genericStackItemType_t itemType, void **pp)
/****************************************************************************/
{
  return _marpaWrapperAsf_djb2_s((unsigned char *) pp, sizeof(int)) % MARPAWRAPPERASF_POWERSETSPARSEARRAY_SIZE;
  /* We know what we are doing, i.e. that *pp is a positive int */
  /* return (* ((int *) pp)) % MARPAWRAPPERASF_POWERSETSPARSEARRAY_SIZE; */
}

/****************************************************************************/
void _marpaWrapperAsf_powerset_sparseArrayFreev(void *userDatavp, void **pp)
/****************************************************************************/
{
  _marpaWrapperAsf_idset_sparseArrayFreev(userDatavp, pp);
}

/****************************************************************************/
static inline marpaWrapperAsfPowerset_t *_marpaWrapperAsf_powerset_obtainp(marpaWrapperAsf_t *marpaWrapperAsfp, int counti, int *idip)
/****************************************************************************/
{
  return _marpaWrapperAsf_idset_obtainp(marpaWrapperAsfp, MARPAWRAPPERASFIDSET_POWERSET, counti, idip);
}

/****************************************************************************/
static inline int *_marpaWrapperAsf_powerset_idip(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfIdset_t *idsetp)
/****************************************************************************/
{
  return _marpaWrapperAsf_idset_idip(marpaWrapperAsfp, MARPAWRAPPERASFIDSET_POWERSET, idsetp);
}

/****************************************************************************/
static inline short _marpaWrapperAsf_powerset_idi_by_ixib(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfIdset_t *idsetp, int ixi, int *idip)
/****************************************************************************/
{
  return _marpaWrapperAsf_idset_idi_by_ixib(marpaWrapperAsfp, MARPAWRAPPERASFIDSET_POWERSET, idsetp, ixi, idip);
}

/****************************************************************************/
static inline int _marpaWrapperAsf_powerset_counti(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfIdset_t *idsetp)
/****************************************************************************/
{
  return _marpaWrapperAsf_idset_counti(marpaWrapperAsfp, MARPAWRAPPERASFIDSET_POWERSET, idsetp);
}

/****************************************************************************/
static inline int _marpaWrapperAsf_powerset_idi(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfIdset_t *idsetp)
/****************************************************************************/
{
  return _marpaWrapperAsf_idset_idi(marpaWrapperAsfp, MARPAWRAPPERASFIDSET_POWERSET, idsetp);
}

/****************************************************************************/
static inline void _marpaWrapperAsf_powerset_freev(marpaWrapperAsf_t *marpaWrapperAsfp)
/****************************************************************************/
{
  _marpaWrapperAsf_idset_freev(marpaWrapperAsfp, MARPAWRAPPERASFIDSET_POWERSET);
}

/****************************************************************************/
int _marpaWrapperAsf_orNodeInUse_sparseArrayIndi(void *userDatavp, genericStackItemType_t itemType, void **pp)
/****************************************************************************/
{
  return _marpaWrapperAsf_djb2_s((unsigned char *) pp, sizeof(int)) % MARPAWRAPPERASF_ORNODEINUSESPARSEARRAY_SIZE;
  /* We know what we are doing, i.e. that *pp is a positive int */
  /* return (* ((int *) pp)) % MARPAWRAPPERASF_ORNODEINUSESPARSEARRAY_SIZE; */
}

/****************************************************************************/
static inline marpaWrapperAsfNook_t *_marpaWrapperAsf_nook_newp(marpaWrapperAsf_t *marpaWrapperAsfp, int orNodeIdi, int parentOrNodeIdi)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_nook_newp);
  genericLogger_t         *genericLoggerp = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
  marpaWrapperAsfNook_t   *nookp;
  short                    haveLastChoiceb;

  nookp = malloc(sizeof(marpaWrapperAsfNook_t));
  if (nookp == NULL) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "malloc failure: %s", strerror(errno));
    goto err;
  }

  nookp->orNodeIdi              = orNodeIdi;
  nookp->firstChoicei           = 0;
  nookp->lastChoicei            = 0;
  nookp->parentOrNodeIdi        = parentOrNodeIdi;
  nookp->isCauseb               = 0;
  nookp->isPredecessorb         = 0;
  nookp->causeIsExpandedb       = 0;
  nookp->predecessorIsExpandedb = 0;

  if (_marpaWrapperAsf_setLastChoiceb(marpaWrapperAsfp, &haveLastChoiceb, nookp) == 0) {
    goto err;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Created nook {OR_NODE=%d, PARENT=%d, FIRST_CHOICE=%d, LAST_CHOICE=%d}", nookp->orNodeIdi, nookp->parentOrNodeIdi, nookp->firstChoicei, nookp->lastChoicei);

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return %p", nookp);
  return nookp;

 err:
  if (nookp != NULL) {
    free(nookp);
  }
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return NULL");
  return NULL;
}

/****************************************************************************/
static inline short _marpaWrapperAsf_nook_has_semantic_causeb(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfNook_t *nookp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_nook_has_semantic_causeb);
#ifndef MARPAWRAPPER_NTRACE
  genericLogger_t          *genericLoggerp           = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
#endif
  int                       orNodeIdi               = nookp->orNodeIdi;
  marpaWrapperRecognizer_t *marpaWrapperRecognizerp = marpaWrapperAsfp->marpaWrapperRecognizerp;
  marpaWrapperGrammar_t    *marpaWrapperGrammarp    = marpaWrapperRecognizerp->marpaWrapperGrammarp;
  Marpa_Grammar             marpaGrammarp           = marpaWrapperGrammarp->marpaGrammarp;
  Marpa_Bocage              marpaBocagep            = marpaWrapperAsfp->marpaBocagep;
  Marpa_IRL_ID              irlIdi;
  int                       predotPositioni;
  Marpa_Symbol_ID           predotIsyIdi;
  short                    rcb;

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "_marpa_b_or_node_irl(%p, %d)", marpaBocagep, orNodeIdi);
  irlIdi = _marpa_b_or_node_irl(marpaBocagep, orNodeIdi);
  
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "_marpa_b_or_node_position(%p, %d)", marpaBocagep, orNodeIdi);
  predotPositioni = _marpa_b_or_node_position(marpaBocagep, orNodeIdi) - 1;

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "_marpa_g_irl_rhs(%p, %d, %d)", marpaGrammarp, (int) irlIdi, predotPositioni);
  predotIsyIdi = _marpa_g_irl_rhs(marpaGrammarp, irlIdi, predotPositioni);

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "_marpa_g_nsy_is_semantic(%p, %d)", marpaGrammarp, (int) predotIsyIdi);
  rcb = (_marpa_g_nsy_is_semantic(marpaGrammarp, predotIsyIdi) != 0) ? 1 : 0;

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return %d", (int) rcb);
  return rcb;
}

/****************************************************************************/
static inline short _marpaWrapperAsf_setLastChoiceb(marpaWrapperAsf_t *marpaWrapperAsfp, short *haveLastChoicebp, marpaWrapperAsfNook_t *nookp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_setLastChoiceb);
  genericLogger_t         *genericLoggerp     = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
  genericStack_t          *orNodeStackp       = marpaWrapperAsfp->orNodeStackp;
  int                      orNodeIdi          = nookp->orNodeIdi;
  int                      choicei            = nookp->firstChoicei;
  marpaWrapperAsfOrNode_t *orNodep;

  if (! GENERICSTACK_IS_PTR(orNodeStackp, orNodeIdi)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "No entry in orNode stack at indice %d", orNodeIdi);
    goto err;
  }
  orNodep = GENERICSTACK_GET_PTR(orNodeStackp, orNodeIdi);

  if (choicei >= orNodep->nAndNodei) {
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "No last choice available: choicei=%d >= orNodep->nAndNodei=%d", choicei, orNodep->nAndNodei);
    *haveLastChoicebp = 0;
  } else {
    if (_marpaWrapperAsf_nook_has_semantic_causeb(marpaWrapperAsfp, nookp)) {
      Marpa_Bocage marpaBocagep = marpaWrapperAsfp->marpaBocagep;
      int          andNodeIdi   = orNodep->andNodep[choicei];
      int          currentPredecessori;
      int          nextPredecessori;

      MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "_marpa_b_and_node_predecessor(%p, %d)", marpaBocagep, andNodeIdi);
      currentPredecessori = _marpa_b_and_node_predecessor(marpaBocagep, andNodeIdi);
      if (currentPredecessori < 0) {
	currentPredecessori = -1;
      }
      while (1) {
	if (++choicei >= orNodep->nAndNodei) {
	  break;
	}
	andNodeIdi = orNodep->andNodep[choicei];
	MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "_marpa_b_and_node_predecessor(%p, %d)", marpaBocagep, andNodeIdi);
	nextPredecessori = _marpa_b_and_node_predecessor(marpaBocagep, andNodeIdi);
	if (nextPredecessori < 0) {
	  nextPredecessori = -1;
	}
	if (currentPredecessori != nextPredecessori) {
	  break;
	}
      }
      --choicei;
    }
    nookp->lastChoicei = choicei;
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Setted last choice of nook {OR_NODE=%d, PARENT=%d, FIRST_CHOICE=%d, LAST_CHOICE=%d}", nookp->orNodeIdi, nookp->parentOrNodeIdi, nookp->firstChoicei, nookp->lastChoicei);
    *haveLastChoicebp = 1;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return 1, *haveLastChoicebp=%d", (int) *haveLastChoicebp);
  return 1;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

/****************************************************************************/
static inline short _marpaWrapperAsf_nook_incrementb(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfNook_t *nookp, short *haveLastChoicebp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_nook_incrementb);
#ifndef MARPAWRAPPER_NTRACE
  genericLogger_t         *genericLoggerp     = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
#endif

  nookp->firstChoicei = nookp->lastChoicei + 1;

  if (_marpaWrapperAsf_setLastChoiceb(marpaWrapperAsfp, haveLastChoicebp, nookp) == 0) {
    goto err;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Incremented nook {OR_NODE=%d, PARENT=%d, FIRST_CHOICE=%d, LAST_CHOICE=%d}", nookp->orNodeIdi, nookp->parentOrNodeIdi, nookp->firstChoicei, nookp->lastChoicei);
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return 1, *haveLastChoicebp=%d", (int) *haveLastChoicebp);
  return 1;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

/****************************************************************************/
static inline short _marpaWrapperAsf_symch_factoring_countb(marpaWrapperAsf_t *marpaWrapperAsfp, int gladeIdi, int symchIxi, int *factoringCountip)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_symch_factoring_countb);
  genericLogger_t         *genericLoggerp     = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
  marpaWrapperAsfGlade_t  *gladep;
  genericStack_t          *symchesStackp;
  genericStack_t          *factoringsStackp;

  gladep = _marpaWrapperAsf_glade_obtainp(marpaWrapperAsfp, gladeIdi);
  if (gladep == NULL) {
    goto err;
  }
  symchesStackp = gladep->symchesStackp;
  if (! GENERICSTACK_IS_PTR(symchesStackp, symchIxi)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "No symch at indice %d", symchIxi);
    goto err;
  }
  factoringsStackp = GENERICSTACK_GET_PTR(symchesStackp,  symchIxi);
  if (factoringsStackp == NULL) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "Null factorings stack at symch indice %d", symchIxi);
    goto err;
  }
  /* factoringsStackp is (symchRuleIdi, PTR, stack of gladeIdi) */
  /* This is length - 2 */
  *factoringCountip = GENERICSTACK_USED(factoringsStackp) - 2;

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return 1, *factoringCountip=%d", *factoringCountip);
  return 1;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

/****************************************************************************/
static inline int _marpaWrapperAsf_nidset_sort_ixi(marpaWrapperAsf_t *marpaWrapperAsfp, int nidi)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_nidset_sort_ixi);
#ifndef MARPAWRAPPER_NTRACE
  genericLogger_t         *genericLoggerp     = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
#endif
  marpaWrapperRecognizer_t *marpaWrapperRecognizerp = marpaWrapperAsfp->marpaWrapperRecognizerp;
  marpaWrapperGrammar_t    *marpaWrapperGrammarp    = marpaWrapperRecognizerp->marpaWrapperGrammarp;
  Marpa_Grammar             marpaGrammarp           = marpaWrapperGrammarp->marpaGrammarp;
  Marpa_Bocage              marpaBocagep            = marpaWrapperAsfp->marpaBocagep;
  int                       rci;
  
  if (nidi >= 0) {
    Marpa_IRL_ID  irlIdi;
    Marpa_Rule_ID xrlIdi;

    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "_marpa_b_or_node_irl(%p, %d)", marpaBocagep, nidi);
    irlIdi = _marpa_b_or_node_irl(marpaBocagep, nidi);
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "_marpa_g_source_xrl(%p, %d)", marpaGrammarp, (int) irlIdi);
    xrlIdi = _marpa_g_source_xrl(marpaGrammarp, irlIdi);

    rci = (int) xrlIdi;
  } else {
    int andNodeIdi = _marpaWrapperAsf_nid_to_and_nodei(nidi);
    int tokenNsyIdi;
    int tokenIdi;

    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "_marpa_b_and_node_symbol(%p, %d)", marpaBocagep, andNodeIdi);
    tokenNsyIdi = _marpa_b_and_node_symbol(marpaBocagep, andNodeIdi);
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "_marpa_g_source_xsy(%p, %d)", marpaGrammarp, tokenNsyIdi);
    tokenIdi = _marpa_g_source_xsy(marpaGrammarp, tokenNsyIdi);

    /* -2 is reserved to 'end of data' */
    rci = -tokenIdi - 3;
  }

  return rci;
}

/****************************************************************************/
static inline int _marpaWrapperAsf_and_node_to_nidi(int idi)
/****************************************************************************/
{
  return -idi + MARPAWRAPPERASF_NID_LEAF_BASE;
}

/****************************************************************************/
static inline int _marpaWrapperAsf_nid_to_and_nodei(int idi)
/****************************************************************************/
{
  return -idi + MARPAWRAPPERASF_NID_LEAF_BASE;
}

/****************************************************************************/
static inline int _marpaWrapperAsf_sourceDataCmpi(const void *p1, const void *p2)
/****************************************************************************/
{
  marpaWrapperAsfSourceData_t *d1 = (marpaWrapperAsfSourceData_t *) p1;
  marpaWrapperAsfSourceData_t *d2 = (marpaWrapperAsfSourceData_t *) p2;

  return (d1->sortIxi < d2->sortIxi) ? -1 : ((d1->sortIxi > d2->sortIxi) ? 1 : 0);
}

/****************************************************************************/
static inline int _marpaWrapperAsf_nid_token_idi(marpaWrapperAsf_t *marpaWrapperAsfp, int nidi)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_nid_token_idi);
#ifndef MARPAWRAPPER_NTRACE
  genericLogger_t *genericLoggerp = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
#endif
  int              idi            = -1;

  if (nidi <= MARPAWRAPPERASF_NID_LEAF_BASE) {
    int                       andNodeIdi              = _marpaWrapperAsf_nid_to_and_nodei(nidi);
    marpaWrapperRecognizer_t *marpaWrapperRecognizerp = marpaWrapperAsfp->marpaWrapperRecognizerp;
    marpaWrapperGrammar_t    *marpaWrapperGrammarp    = marpaWrapperRecognizerp->marpaWrapperGrammarp;
    Marpa_Grammar             marpaGrammarp           = marpaWrapperGrammarp->marpaGrammarp;
    Marpa_Bocage              marpaBocagep            = marpaWrapperAsfp->marpaBocagep;
    int                       tokenNsyIdi;

    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "_marpa_b_and_node_symbol(%p, %d)", marpaBocagep, andNodeIdi);
    tokenNsyIdi = _marpa_b_and_node_symbol(marpaBocagep, andNodeIdi);

    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "_marpa_g_source_xsy(%p, %d)", marpaBocagep, tokenNsyIdi);
    idi = (int) _marpa_g_source_xsy(marpaGrammarp, tokenNsyIdi);
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return %d", idi);
  return idi;
}

/****************************************************************************/
static inline int _marpaWrapperAsf_nid_symbol_idi(marpaWrapperAsf_t *marpaWrapperAsfp, int nidi)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_nid_symbol_idi);
  genericLogger_t          *genericLoggerp          = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
  int                       idi                     = -1;
  int                       tokenIdi;

  tokenIdi = _marpaWrapperAsf_nid_token_idi(marpaWrapperAsfp, nidi);
  if (tokenIdi >= 0) {
    idi = tokenIdi;
  } else {
    if (nidi < 0) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "No symbol ID for node ID: %d", nidi);
    } else {
      marpaWrapperRecognizer_t *marpaWrapperRecognizerp = marpaWrapperAsfp->marpaWrapperRecognizerp;
      marpaWrapperGrammar_t    *marpaWrapperGrammarp    = marpaWrapperRecognizerp->marpaWrapperGrammarp;
      Marpa_Grammar             marpaGrammarp           = marpaWrapperGrammarp->marpaGrammarp;
      Marpa_Bocage              marpaBocagep            = marpaWrapperAsfp->marpaBocagep;
      Marpa_IRL_ID              irlIdi;
      Marpa_Rule_ID             xrlIdi;
      Marpa_Symbol_ID           lhsIdi;

      MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "_marpa_b_or_node_irl(%p, %d)", marpaBocagep, nidi);
      irlIdi = _marpa_b_or_node_irl(marpaBocagep, nidi);
      MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "_marpa_g_source_xrl(%p, %d)", marpaGrammarp, (int) irlIdi);
      xrlIdi = _marpa_g_source_xrl(marpaGrammarp, irlIdi);
      MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "marpa_g_rule_lhs(%p, %d)", marpaGrammarp, (int) xrlIdi);
      lhsIdi = marpa_g_rule_lhs(marpaGrammarp, xrlIdi);

      idi = (int) lhsIdi;
    }
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return %d", idi);
  return idi;
}

/****************************************************************************/
static inline int _marpaWrapperAsf_nid_rule_idi(marpaWrapperAsf_t *marpaWrapperAsfp, int nidi)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_nid_rule_idi);
#ifndef MARPAWRAPPER_NTRACE
  genericLogger_t *genericLoggerp = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
#endif
  int              idi            = -1;

  if (nidi >= 0) {
    marpaWrapperRecognizer_t *marpaWrapperRecognizerp = marpaWrapperAsfp->marpaWrapperRecognizerp;
    marpaWrapperGrammar_t    *marpaWrapperGrammarp    = marpaWrapperRecognizerp->marpaWrapperGrammarp;
    Marpa_Grammar             marpaGrammarp           = marpaWrapperGrammarp->marpaGrammarp;
    Marpa_Bocage              marpaBocagep            = marpaWrapperAsfp->marpaBocagep;
    Marpa_IRL_ID              irlIdi;
    
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "_marpa_b_or_node_irl(%p, %d)", marpaBocagep, nidi);
    irlIdi = _marpa_b_or_node_irl(marpaBocagep, nidi);

    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "_marpa_g_source_xrl(%p, %d)", marpaGrammarp, (int) irlIdi);
    idi = (int) _marpa_g_source_xrl(marpaGrammarp, irlIdi);
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return %d", idi);
  return idi;
}

/****************************************************************************/
static inline int _marpaWrapperAsf_nid_spani(marpaWrapperAsf_t *marpaWrapperAsfp, int nidi, int *lengthip)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_nid_spani);
#ifndef MARPAWRAPPER_NTRACE
  genericLogger_t   *genericLoggerp = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
#endif
  int                spanIdi        = -1;
  int                lengthi;

  if (nidi <= MARPAWRAPPERASF_NID_LEAF_BASE) {
    int andNodeIdi = _marpaWrapperAsf_nid_to_and_nodei(nidi);

    spanIdi = _marpaWrapperAsf_token_es_spani(marpaWrapperAsfp, andNodeIdi, &lengthi);
  }
  if (nidi >= 0) {
    spanIdi = _marpaWrapperAsf_or_node_es_spani(marpaWrapperAsfp, nidi, &lengthi);
  }

  if (lengthip != NULL) {
    *lengthip = lengthi;
  }
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return %d (length %d)", spanIdi, lengthi);
  return spanIdi;
}

/****************************************************************************/
static inline int _marpaWrapperAsf_token_es_spani(marpaWrapperAsf_t *marpaWrapperAsfp, int andNodeIdi, int *lengthip)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_token_es_spani);
#ifndef MARPAWRAPPER_NTRACE
  genericLogger_t *genericLoggerp = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
#endif
  Marpa_Bocage     marpaBocagep   = marpaWrapperAsfp->marpaBocagep;
  int              predecessorIdi;
  int              parentOrNodeIdi;
  int              spanIdi;
  int              lengthi;

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "_marpa_b_and_node_predecessor(%p, %d);", marpaBocagep, andNodeIdi);
  predecessorIdi = _marpa_b_and_node_predecessor(marpaBocagep, andNodeIdi);

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "_marpa_b_and_node_parent(%p, %d);", marpaBocagep, andNodeIdi);
  parentOrNodeIdi = _marpa_b_and_node_parent(marpaBocagep, andNodeIdi);

  if (predecessorIdi >=0) {
    int originEsi;
    int currentEsi;

    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "_marpa_b_or_node_set(%p, %d);", marpaBocagep, predecessorIdi);
    originEsi = _marpa_b_or_node_set(marpaBocagep, predecessorIdi);

    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "_marpa_b_or_node_set(%p, %d);", marpaBocagep, predecessorIdi);
    currentEsi = _marpa_b_or_node_set(marpaBocagep, parentOrNodeIdi);

    spanIdi = originEsi; 
    lengthi = currentEsi - originEsi;
  } else {

    spanIdi = _marpaWrapperAsf_or_node_es_spani(marpaWrapperAsfp, parentOrNodeIdi, &lengthi);
  }

  if (lengthip != NULL) {
    *lengthip = lengthi;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return spanIdi=%d, lengthi=%d", spanIdi, lengthi);
  return spanIdi;
}

/****************************************************************************/
static inline marpaWrapperAsfNidset_t *_marpaWrapperAsf_powerset_nidsetp(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfPowerset_t *powersetp, int ixi)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_powerset_nidsetp);
  genericLogger_t         *genericLoggerp     = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
  genericSparseArray_t    *nidsetSparseArrayp = marpaWrapperAsfp->nidsetSparseArrayp;
  marpaWrapperAsfNidset_t *nidsetp;
  short                    findResult         = 0;
  int                      counti;
  int                      idi;

  counti = _marpaWrapperAsf_powerset_counti(marpaWrapperAsfp, powersetp);
  if (ixi < counti) {
    if (_marpaWrapperAsf_powerset_idi_by_ixib(marpaWrapperAsfp, powersetp, ixi, &idi) == 0) {
      goto err;
    }
    GENERICSPARSEARRAY_FIND(nidsetSparseArrayp, marpaWrapperAsfp, idi, PTR, &nidsetp, findResult);
    if (! findResult) {
      nidsetp = NULL;
    }
    if (GENERICSPARSEARRAY_ERROR(nidsetSparseArrayp)) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "nidset sparse array find failure: %s", strerror(errno));
      goto err;
    }
  } else {
    nidsetp = NULL;
  }
  
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return %p", nidsetp); /* nidsetp can be NULL */
  return nidsetp;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return NULL");
  return NULL;
}

/****************************************************************************/
static inline marpaWrapperAsfGlade_t *_marpaWrapperAsf_glade_obtainp(marpaWrapperAsf_t *marpaWrapperAsfp, int gladei)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_glade_obtainp);
  genericLogger_t             *genericLoggerp         = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
  genericStack_t              *gladeStackp            = marpaWrapperAsfp->gladeStackp;
  genericSparseArray_t        *nidsetSparseArrayp     = marpaWrapperAsfp->nidsetSparseArrayp;
  genericStack_t              *gladeObtainTmpStackp   = marpaWrapperAsfp->gladeObtainTmpStackp;
  marpaWrapperAsfSourceData_t *sourceDatap            = NULL;
  int                          nidWithCurrentSortIxii = 0;
  int                         *nidWithCurrentSortIxip = NULL;
  int                          symchIdii              = 0;
  int                         *symchIdip              = NULL;
  short                        thisNidEndb            = 0;
  int                         *symbolip               = NULL;
  genericStack_t              *gotFactoringStackp     = NULL;
  genericStack_t              *symchesStackp          = NULL;
  genericStack_t              *factoringsStackp       = NULL;
  marpaWrapperAsfChoicePoint_t *choicepointp = NULL;
  int                          nSourceDatai;
  marpaWrapperAsfGlade_t      *gladep;
  marpaWrapperAsfNidset_t     *baseNidsetp;
  marpaWrapperAsfPowerset_t   *choicepointPowersetp;
  int                          sourceNidi;
  int                          nidIxi;
  int                          ixi;
  int                          sortIxOfThisNidi;
  int                          thisNidi;
  int                          currentSortIxi;
  marpaWrapperAsfNidset_t     *nidsetForSortIxp;
  int                          symchCounti;
  int                          symchIxi;
  int                          choicepointNidi;
  int                          symchRuleIdi;
  short                        findResult;

  if (   (! GENERICSTACK_IS_PTR(gladeStackp, gladei))
      || ((gladep = GENERICSTACK_GET_PTR(gladeStackp, gladei)) == NULL)
#if MARPAWRAPPERASF_USE_REGISTERED_FLAG > 0
      || (gladep->registeredb == 0)
#endif
      ) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "Attempt to use an invalid glade, one whose ID is %d", gladei);
    goto err;
  }

  /* Return the glade if it is already set up */
  if (gladep->symchesStackp != NULL) {
    goto done;
  }

  GENERICSPARSEARRAY_FIND(nidsetSparseArrayp, marpaWrapperAsfp, gladei, PTR, &baseNidsetp, findResult);
  if (GENERICSPARSEARRAY_ERROR(nidsetSparseArrayp)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "nidset sparse array find failure: %s", strerror(errno));
    goto err;
  }
  if (! findResult) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "No nidset at glade id %d", gladei);
    goto err;
  }
  nSourceDatai = _marpaWrapperAsf_nidset_counti(marpaWrapperAsfp, baseNidsetp);
  if (nSourceDatai <= 0) {
    MARPAWRAPPER_ERROR(genericLoggerp, "No nidset");
    goto err;
  }
  sourceDatap = malloc((size_t) (nSourceDatai * sizeof(marpaWrapperAsfSourceData_t)));
  if (sourceDatap == NULL) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "malloc failure: %s", strerror(errno));
    goto err;
  }
  for (ixi = 0; ixi < nSourceDatai; ixi++) {
    if (_marpaWrapperAsf_nidset_idi_by_ixib(marpaWrapperAsfp, baseNidsetp, ixi, &sourceNidi) == 0) {
      goto err;
    }
    sourceDatap[ixi].sortIxi = _marpaWrapperAsf_nidset_sort_ixi(marpaWrapperAsfp, sourceNidi);
    if (_marpaWrapperAsf_nidset_idi_by_ixib(marpaWrapperAsfp, baseNidsetp, ixi, &(sourceDatap[ixi].sourceNidi)) == 0) {
      goto err;
    }
  }
  qsort(sourceDatap, (size_t) nSourceDatai, sizeof(marpaWrapperAsfSourceData_t), _marpaWrapperAsf_sourceDataCmpi);

  sortIxOfThisNidi = sourceDatap[0].sortIxi;
  thisNidi         = sourceDatap[0].sourceNidi;
  nidIxi           = 1;
  currentSortIxi   = sortIxOfThisNidi;
  while (1) {
    if (sortIxOfThisNidi != currentSortIxi) {
      /* Current only whole id break logic */
      nidsetForSortIxp = _marpaWrapperAsf_nidset_obtainp(marpaWrapperAsfp, nidWithCurrentSortIxii, nidWithCurrentSortIxip);
      if (nidsetForSortIxp == NULL) {
	goto err;
      }
      /* Create or extend symchIdip */
      if (symchIdip == NULL) {
	symchIdip = malloc(sizeof(int));
	if (symchIdip == NULL) {
	  MARPAWRAPPER_ERRORF(genericLoggerp, "malloc failure: %s", strerror(errno));
	  goto err;
	}
      } else {
	int *tmpip = realloc(symchIdip, (size_t) ((symchIdii + 1) * sizeof(int)));
	if (tmpip == NULL) {
	  MARPAWRAPPER_ERRORF(genericLoggerp, "realloc failure: %s", strerror(errno));
	  goto err;
	}
	symchIdip = tmpip;
      }
      symchIdip[symchIdii++] = _marpaWrapperAsf_nidset_idi(marpaWrapperAsfp, nidsetForSortIxp);
      free(nidWithCurrentSortIxip);
      nidWithCurrentSortIxip = NULL;
      nidWithCurrentSortIxii = 0;

      currentSortIxi = sortIxOfThisNidi;
    }
    if (thisNidEndb != 0) {
      break;
    }
    /* Create or extend nidWithCurrentSortIxip */
    if (nidWithCurrentSortIxip == NULL) {
      nidWithCurrentSortIxip = malloc(sizeof(int));
      if (nidWithCurrentSortIxip == NULL) {
	MARPAWRAPPER_ERRORF(genericLoggerp, "malloc failure: %s", strerror(errno));
	goto err;
      }
    } else {
      int *tmpip = realloc(nidWithCurrentSortIxip, (size_t) ((nidWithCurrentSortIxii + 1) * sizeof(int)));
      if (tmpip == NULL) {
	MARPAWRAPPER_ERRORF(genericLoggerp, "realloc failure: %s", strerror(errno));
	goto err;
      }
      nidWithCurrentSortIxip = tmpip;
    }
    nidWithCurrentSortIxip[nidWithCurrentSortIxii++] = thisNidi;
    if (nidIxi < nSourceDatai) {
      sortIxOfThisNidi = sourceDatap[nidIxi].sortIxi;
      thisNidi         = sourceDatap[nidIxi].sourceNidi;
      nidIxi++;
      continue;
    }
    thisNidEndb = 1;
    sortIxOfThisNidi = -2;
  }
  choicepointPowersetp = _marpaWrapperAsf_powerset_obtainp(marpaWrapperAsfp, symchIdii, symchIdip);
  if (choicepointPowersetp == NULL) {
    goto err;
  }
  choicepointp = _marpaWrapperAsf_choicepoint_newp(marpaWrapperAsfp);
  if (choicepointp == NULL) {
    goto err;
  }

  /* Check if choicepoint already seen ? */
  GENERICSTACK_NEW(symchesStackp);
  if (GENERICSTACK_ERROR(symchesStackp)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "Failure to initalize symchesStackp, %s", strerror(errno));
    goto err;
  }
  symchCounti = _marpaWrapperAsf_powerset_counti(marpaWrapperAsfp, choicepointPowersetp);
  for (symchIxi = 0; symchIxi < symchCounti; symchIxi++) {
    marpaWrapperAsfNidset_t *symchNidsetp;
    int                      nidcounti;
    int                      nidixi;
    
    /* Free factoring stack */
    _marpaWrapperAsf_factoringStackp_freev(marpaWrapperAsfp, &(choicepointp->factoringStackp));

    symchNidsetp = _marpaWrapperAsf_powerset_nidsetp(marpaWrapperAsfp, choicepointPowersetp, symchIxi);
    if (symchNidsetp == NULL) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "symchNidsetp is NULL", strerror(errno));
      goto err;
    }
    if (_marpaWrapperAsf_nidset_idi_by_ixib(marpaWrapperAsfp, symchNidsetp, 0, &choicepointNidi) == 0) {
      goto err;
    }
    symchRuleIdi = _marpaWrapperAsf_nid_rule_idi(marpaWrapperAsfp, choicepointNidi);
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Generating factoringsStackp for rule %d", symchRuleIdi);

    /* Initial NULL indicates no factorings omitted */
    GENERICSTACK_NEW(factoringsStackp);
    if (GENERICSTACK_ERROR(factoringsStackp)) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "factoringsStackp initialization failure: %s", strerror(errno));
      goto err;
    }
    GENERICSTACK_PUSH_INT(factoringsStackp, symchRuleIdi);
    if (GENERICSTACK_ERROR(factoringsStackp)) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "factoringsStackp set at indice 0 failure: %s", strerror(errno));
      GENERICSTACK_FREE(factoringsStackp);
      goto err;
    }
    GENERICSTACK_PUSH_PTR(factoringsStackp, NULL);
    if (GENERICSTACK_ERROR(factoringsStackp)) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "factoringsStackp set at indice 1 failure: %s", strerror(errno));
      GENERICSTACK_FREE(factoringsStackp);
      goto err;
    }

    /* For a token, there will not be multiple factorings or nids */
    if (symchRuleIdi < 0) {
      marpaWrapperAsfNidset_t *baseNidsetp = _marpaWrapperAsf_nidset_obtainp(marpaWrapperAsfp, 1, &choicepointNidi);
      int                      gladeIdi;
      genericStack_t          *localStackp = NULL;

      if (baseNidsetp == NULL) {
	goto err;
      }
      gladeIdi = _marpaWrapperAsf_nidset_idi(marpaWrapperAsfp, baseNidsetp);
      if (! GENERICSTACK_IS_PTR(gladeStackp, gladeIdi)) {
        marpaWrapperAsfGlade_t *localGladep;

	MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Generating glade at indice %d", gladeIdi);
        localGladep = malloc(sizeof(marpaWrapperAsfGlade_t));
        if (localGladep == NULL) {
          MARPAWRAPPER_ERRORF(genericLoggerp, "malloc failure: %s", strerror(errno));
          goto err;
        }
        localGladep->idi           = gladeIdi;
        localGladep->symchesStackp = NULL;
#if MARPAWRAPPERASF_USE_VISITED_FLAG > 0
        localGladep->visitedb      = 0;
#endif
#if MARPAWRAPPERASF_USE_REGISTERED_FLAG > 0
        localGladep->registeredb   = 1;
#endif
        GENERICSTACK_SET_PTR(gladeStackp, localGladep, gladeIdi);
        if (GENERICSTACK_ERROR(gladeStackp)) {
          MARPAWRAPPER_ERRORF(genericLoggerp, "glade stack failure: %s", strerror(errno));
          free(localGladep);
          goto err;
        }
#if MARPAWRAPPERASF_USE_REGISTERED_FLAG > 0
      } else {
        marpaWrapperAsfGlade_t *localGladep;

        localGladep = GENERICSTACK_GET_PTR(gladeStackp, gladeIdi);
        localGladep->registeredb = 1;
#endif
      }

      GENERICSTACK_NEW(localStackp);
      if (GENERICSTACK_ERROR(localStackp)) {
	MARPAWRAPPER_ERRORF(genericLoggerp, "localStackp initialization failure, %s", strerror(errno));
	goto err;
      }
      GENERICSTACK_PUSH_INT(localStackp, gladeIdi);
      if (GENERICSTACK_ERROR(localStackp)) {
	MARPAWRAPPER_ERRORF(genericLoggerp, "localStackp push failure, %s", strerror(errno));
        GENERICSTACK_FREE(localStackp);
	goto err;
      }
      GENERICSTACK_PUSH_PTR(factoringsStackp, localStackp);
      if (GENERICSTACK_ERROR(factoringsStackp)) {
	MARPAWRAPPER_ERRORF(genericLoggerp, "Failure to push factoringsStackp, %s", strerror(errno));
	GENERICSTACK_FREE(localStackp);
	goto err;
      }
      /* localStackp is now in factoringsStackp */
      localStackp = NULL;
      GENERICSTACK_PUSH_PTR(symchesStackp, factoringsStackp);
      if (GENERICSTACK_ERROR(symchesStackp)) {
	MARPAWRAPPER_ERRORF(genericLoggerp, "Failure to push symchesStack, %s", strerror(errno));
	goto err;
      }
      /* factoringsStackp is now in symchesStackp, and we do NOT execute the rest of the loop */
      factoringsStackp = NULL;
      continue;
    }

    symchNidsetp = _marpaWrapperAsf_powerset_nidsetp(marpaWrapperAsfp, choicepointPowersetp, symchIxi);
    if (symchNidsetp == NULL) {
      MARPAWRAPPER_ERROR(genericLoggerp, "symchNidsetp is NULL");
      goto err;
    }
    nidcounti = _marpaWrapperAsf_nidset_counti(marpaWrapperAsfp, symchNidsetp);
    for (nidixi = 0; nidixi < nidcounti; nidixi++) {
      short breakFactoringsLoop = 0;
      short firstFactoringb;
      short factoringb;
      
      if (_marpaWrapperAsf_nidset_idi_by_ixib(marpaWrapperAsfp, symchNidsetp, nidixi, &choicepointNidi) == 0) {
	goto err;
      }
      if (_marpaWrapperAsf_first_factoringb(marpaWrapperAsfp, choicepointp, choicepointNidi, &firstFactoringb) == 0) {
	goto err;
      }

      GENERICSTACK_USED(gladeObtainTmpStackp) = 0;
      gotFactoringStackp = gladeObtainTmpStackp;
      if (_marpaWrapperAsf_glade_id_factorsb(marpaWrapperAsfp, choicepointp, &gotFactoringStackp) == 0) {
	goto err;
      }

      /* Here, either gotFactoringStackp is NULL, either it is gladeObtainTmpStackp */
      while (gotFactoringStackp != NULL) {
	if (GENERICSTACK_USED(factoringsStackp) > MARPAWRAPPERASF_FACTORING_MAX) {
	  /* Update factorings omitted flag - this indice is already allocated: factoringsStackp cannot change*/
	  GENERICSTACK_SET_INT(factoringsStackp, 1, 1);
	  if (GENERICSTACK_ERROR(factoringsStackp)) {
	    MARPAWRAPPER_ERROR(genericLoggerp, "Failure to set omitted flag in local factoring");
	    goto err;
	  }
	  breakFactoringsLoop = 1;
	  break;
	}
	{
	  genericStack_t *tmpFactoringStackp;
	  int             itemIxi;

	  GENERICSTACK_NEW(tmpFactoringStackp);
	  if (GENERICSTACK_ERROR(tmpFactoringStackp)) {
	    MARPAWRAPPER_ERROR(genericLoggerp, "Failure to initalize tmpFactoringStackp");
	    goto err;
	  }
          if (GENERICSTACK_USED(gotFactoringStackp) > 0) {
            for (itemIxi = GENERICSTACK_USED(gotFactoringStackp) - 1; itemIxi >= 0; itemIxi--) {
              if (! GENERICSTACK_IS_INT(gotFactoringStackp, itemIxi)) {
                MARPAWRAPPER_ERRORF(genericLoggerp, "Indice %d is not an int", itemIxi);
                GENERICSTACK_FREE(tmpFactoringStackp);
                goto err;
              }
	    
              GENERICSTACK_PUSH_INT(tmpFactoringStackp, GENERICSTACK_GET_INT(gotFactoringStackp,  itemIxi));
              if (GENERICSTACK_ERROR(tmpFactoringStackp)) {
                MARPAWRAPPER_ERROR(genericLoggerp, "Failure to push in tmpFactoringStackp");
                GENERICSTACK_FREE(tmpFactoringStackp);
                goto err;
              }
            }
          }

          GENERICSTACK_PUSH_PTR(factoringsStackp, tmpFactoringStackp);
          if (GENERICSTACK_ERROR(factoringsStackp)) {
            MARPAWRAPPER_ERROR(genericLoggerp, "Failure to push in factoringsStackp");
            GENERICSTACK_FREE(tmpFactoringStackp);
            goto err;
          }
          /* tmpFactoringStackp is now in factoringsStackp */

	  if (_marpaWrapperAsf_next_factoringb(marpaWrapperAsfp, choicepointp, choicepointNidi, &factoringb) == 0) {
	    goto err;
	  }
	  GENERICSTACK_USED(gladeObtainTmpStackp) = 0;
	  gotFactoringStackp = gladeObtainTmpStackp;
	  if (_marpaWrapperAsf_glade_id_factorsb(marpaWrapperAsfp, choicepointp, &gotFactoringStackp) == 0) {
	    goto err;
	  }
	}
      }
      if (breakFactoringsLoop != 0) {
	break;
      }
    }
    GENERICSTACK_PUSH_PTR(symchesStackp, factoringsStackp);
    if (GENERICSTACK_ERROR(symchesStackp)) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "Failure to push symchesStack, %s", strerror(errno));
      goto err;
    }
    /* factoringsStackp is now in symchesStackp */
    factoringsStackp = NULL;
  }

  /* Replace current symches */
  _marpaWrapperAsf_symchesStackp_freev(marpaWrapperAsfp, gladep->symchesStackp);
  gladep->symchesStackp = symchesStackp;
  /* symchesStackp is now in gladep */
  symchesStackp = NULL;
  gladep->idi = gladei;

  GENERICSTACK_SET_PTR(gladeStackp, gladep, gladei);
  if (GENERICSTACK_ERROR(gladeStackp)) {
    MARPAWRAPPER_ERROR(genericLoggerp, "Failure to set in gladeStackp");
    goto err;
  }

  goto done;

 err:
  gladep = NULL;
  if (symchesStackp != NULL) {
    _marpaWrapperAsf_symchesStackp_freev(marpaWrapperAsfp, symchesStackp);
  }

 done:
  if (sourceDatap != NULL) {
    free(sourceDatap);
  }
  if (nidWithCurrentSortIxip != NULL) {
    free(nidWithCurrentSortIxip);
  }
  if (symchIdip != NULL) {
    free(symchIdip);
  }
  if (symbolip != NULL) {
    free(symbolip);
  }
  _marpaWrapperAsf_factoringsStackp_freev(marpaWrapperAsfp, factoringsStackp);
  _marpaWrapperAsf_choicepoint_freev(marpaWrapperAsfp, choicepointp);

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return %p", gladep);
  return gladep;
}

/****************************************************************************/
static inline short _marpaWrapperAsf_first_factoringb(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfChoicePoint_t *choicepointp, int nidOfChoicePointi, short *firstFactoringbp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_first_factoringb);
  genericLogger_t             *genericLoggerp          = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
  genericStack_t              *orNodeStackp            = marpaWrapperAsfp->orNodeStackp;
  marpaWrapperAsfNook_t       *nookp                   = NULL;
  genericSparseArray_t        *orNodeInUseSparseArrayp = choicepointp->orNodeInUseSparseArrayp;
  marpaWrapperAsfOrNode_t     *orNodep;
  genericStack_t              *factoringStackp;

  /* Current NID of current SYMCH */
  /* The caller should ensure that we are never called unless the current NIS is for a rule */
  if (nidOfChoicePointi < 0) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "First factoring called for negative NID %d", nidOfChoicePointi);
      goto err;
  }

  /* Due to skipping, even the top OR node can have no valid choices */
  if ((! GENERICSTACK_IS_PTR(orNodeStackp, nidOfChoicePointi)) ||
      (((orNodep = GENERICSTACK_GET_PTR(orNodeStackp, nidOfChoicePointi))->nAndNodei) <= 0)) {
    _marpaWrapperAsf_factoringStackp_freev(marpaWrapperAsfp, &(choicepointp->factoringStackp));
    *firstFactoringbp = 0;
    goto done;
  }

  GENERICSPARSEARRAY_SET(orNodeInUseSparseArrayp, marpaWrapperAsfp, nidOfChoicePointi, SHORT, 1);
  if (GENERICSPARSEARRAY_ERROR(orNodeInUseSparseArrayp)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "orNodeInUseSparseArrayp set failure: %s", strerror(errno));
    goto err;
  }

  nookp = _marpaWrapperAsf_nook_newp(marpaWrapperAsfp, nidOfChoicePointi, -1);
  if (nookp == NULL) {
    goto err;
  }

  if (_marpaWrapperAsf_factoringStackp_resetb(marpaWrapperAsfp, &(choicepointp->factoringStackp)) == 0) {
    goto err;
  }

  factoringStackp = choicepointp->factoringStackp;
  GENERICSTACK_PUSH_PTR(factoringStackp, nookp);
  if (GENERICSTACK_ERROR(factoringStackp)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "factoringStackp push failure: %s", strerror(errno));
    goto err;
  }

  /* nookp is now in marpaWrapperAsfp->factoringStackp */
  nookp = NULL;

  /* Iterate as long as we cannot finish this stack */
  while (1) {
    short factoringFinishb;
    short factoringIterateb;

    if (_marpaWrapperAsf_factoring_finishb(marpaWrapperAsfp, choicepointp, nidOfChoicePointi, &factoringFinishb) == 0) {
      goto err;
    }
    if (factoringFinishb != 0) {
      break;
    }
    
    if (_marpaWrapperAsf_factoring_iterateb(marpaWrapperAsfp, choicepointp, &factoringIterateb) == 0) {
      goto err;
    }
    if (factoringIterateb == 0) {
      goto done;
    }
  }

  *firstFactoringbp = 1;

 done:
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return 1, *firstFactoringbp=%d", (int) *firstFactoringbp);
  return 1;

 err:
  if (nookp != NULL) {
    free(nookp);
  }
  
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

/****************************************************************************/
static inline short _marpaWrapperAsf_factoring_finishb(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfChoicePoint_t *choicepointp, int nidOfChoicePointi, short *factoringFinishbp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_factoring_finishb);
  genericLogger_t          *genericLoggerp          = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
  Marpa_Bocage              marpaBocagep            = marpaWrapperAsfp->marpaBocagep;
  genericStack_t           *orNodeStackp            = marpaWrapperAsfp->orNodeStackp;
  genericStack_t           *factoringStackp         = choicepointp->factoringStackp;
  genericSparseArray_t     *orNodeInUseSparseArrayp = choicepointp->orNodeInUseSparseArrayp;
  genericStack_t           *worklistStackp          = marpaWrapperAsfp->worklistStackp;
  int                       worklistUsedi;
  int                       worklistStacki;
  int                       worklistLasti;

  if (factoringStackp == NULL) {
    MARPAWRAPPER_ERROR(genericLoggerp, "factoringStackp is NULL");
    goto err;
  }

  GENERICSTACK_USED(worklistStackp) = 0;
  for (worklistStacki = 0; worklistStacki < GENERICSTACK_USED(factoringStackp); worklistStacki++) {
    GENERICSTACK_SET_INT(worklistStackp, worklistStacki, worklistStacki);
    if (GENERICSTACK_ERROR(worklistStackp)) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "worklistStackp initialization at indice %d failure: %s", worklistStacki, strerror(errno));
      goto err;
    }
  }

  while ((worklistUsedi = GENERICSTACK_USED(worklistStackp)) > 0) {
    marpaWrapperAsfNook_t   *workNookp;
    int                      workOrNodeIdi;
    int                      workingChoicei;
    marpaWrapperAsfOrNode_t *orNodep;
    int                      workAndNodeIdi;
    int                      childOrNodei;
    short                    childIsCauseb = 0;
    short                    childIsPredecessorb = 0;
    marpaWrapperAsfNook_t   *newNookp;
    /* See GCC comment below */
    short                    orNodeInUsedb = 0;
    short                    findResultb = 0;

    worklistLasti = worklistUsedi - 1;

    if (! GENERICSTACK_IS_PTR(factoringStackp, worklistLasti)) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "No nook at indice %d", worklistLasti);
      goto err;
    }
    workNookp = GENERICSTACK_GET_PTR(factoringStackp, worklistLasti);
    workOrNodeIdi  = workNookp->orNodeIdi;
    if (! GENERICSTACK_IS_PTR(orNodeStackp, workOrNodeIdi)) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "No orNode at indice %d of orNodesStackp", workOrNodeIdi);
      goto err;
    }
    orNodep = GENERICSTACK_GET_PTR(orNodeStackp, workOrNodeIdi);

    workingChoicei = workNookp->firstChoicei;;
    if (workingChoicei >= orNodep->nAndNodei) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "No andNode at indice %d of orNodep->andNodep", workingChoicei);
      goto err;
    }
    workAndNodeIdi = orNodep->andNodep[workingChoicei];

    if (workNookp->causeIsExpandedb == 0) {
      if (_marpaWrapperAsf_nook_has_semantic_causeb(marpaWrapperAsfp, workNookp) == 0) {
        childOrNodei = (int) _marpa_b_and_node_cause(marpaBocagep, workAndNodeIdi);
        childIsCauseb = 1;
        goto endFindChildOrNodeLabel;
      }
    }

    workNookp->causeIsExpandedb = 1;
    if (workNookp->predecessorIsExpandedb == 0) {
      childOrNodei = (int) _marpa_b_and_node_predecessor(marpaBocagep, workAndNodeIdi);
      if (childOrNodei >= 0) {
        childIsPredecessorb = 1;
        goto endFindChildOrNodeLabel;
      }
    }

    workNookp->predecessorIsExpandedb = 1;
    GENERICSTACK_POP_INT(worklistStackp);
    continue;

  endFindChildOrNodeLabel:
    GENERICSPARSEARRAY_FIND(orNodeInUseSparseArrayp, marpaWrapperAsfp, childOrNodei, SHORT, &orNodeInUsedb, findResultb);
    if (GENERICSPARSEARRAY_ERROR(orNodeInUseSparseArrayp)) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "orNodeInUseSparseArrayp find failure, %s", strerror(errno));
      goto err;
    }
    /* GCC seem to badly optimize this statement: if (findResultb && orNodeInUsedb), always doing the && */
    /* even if findResultb is 0 - this is why both are explicitely initialized. */
    if (findResultb && orNodeInUsedb) {
      *factoringFinishbp = 0;
      goto done;
    }

    if ((! GENERICSTACK_IS_PTR(orNodeStackp,  workOrNodeIdi)) ||
        (((marpaWrapperAsfOrNode_t *) GENERICSTACK_GET_PTR(orNodeStackp, workOrNodeIdi))->nAndNodei <= 0)) {
      *factoringFinishbp = 0;
      goto done;
    }

    newNookp = _marpaWrapperAsf_nook_newp(marpaWrapperAsfp, childOrNodei, worklistLasti);
    if (childIsCauseb != 0) {
      newNookp->isCauseb = 1;
      workNookp->causeIsExpandedb = 1;
    }
    if (childIsPredecessorb != 0) {
      newNookp->isPredecessorb = 1;
      workNookp->predecessorIsExpandedb = 1;
    }

    GENERICSTACK_PUSH_PTR(factoringStackp, newNookp);
    if (GENERICSTACK_ERROR(factoringStackp)) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "factoringStackp push failure, %s", strerror(errno));
      goto err;
    }
    GENERICSTACK_PUSH_INT(worklistStackp, GENERICSTACK_USED(factoringStackp) - 1);
    if (GENERICSTACK_ERROR(worklistStackp)) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "worklistStackp push failure, %s", strerror(errno));
      goto err;
    }
  }

  *factoringFinishbp = 1;

 done:
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return 1, *factoringFinishbp=%d", (int) *factoringFinishbp);
  return 1;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

/****************************************************************************/
static inline short _marpaWrapperAsf_factoring_iterateb(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfChoicePoint_t *choicepointp, short *factoringIteratebp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_factoring_iterateb);
  genericLogger_t          *genericLoggerp          = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
  genericStack_t           *factoringStackp         = choicepointp->factoringStackp;
  genericSparseArray_t     *orNodeInUseSparseArrayp = choicepointp->orNodeInUseSparseArrayp;
  marpaWrapperAsfNook_t    *topNookp;
  marpaWrapperAsfNook_t    *parentNookp;
  int                       stackIxOfParentNooki;
  int                       orNodei;
  int                       factoringStacki;
  short                     haveLastChoiceb;

  while (1) {
    factoringStacki = GENERICSTACK_USED(factoringStackp);
    if (factoringStacki <= 0) {
      _marpaWrapperAsf_factoringStackp_freev(marpaWrapperAsfp, &(choicepointp->factoringStackp));
      *factoringIteratebp = 0;
      goto done;
    }

    if (! GENERICSTACK_IS_PTR(factoringStackp, factoringStacki - 1)) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "No nook at indice %d of factoringStackp", (factoringStacki - 1));
      goto err;
    }
    topNookp = GENERICSTACK_GET_PTR(factoringStackp, factoringStacki - 1);
    if (_marpaWrapperAsf_nook_incrementb(marpaWrapperAsfp, topNookp, &haveLastChoiceb) == 0) {
      goto err;
    }
    if (haveLastChoiceb == 1) {
      break;
    }

    /* Could not iterate */
    /* "Dirty" the corresponding bits in the parent and pop this nook */
    stackIxOfParentNooki = topNookp->parentOrNodeIdi;
    if (stackIxOfParentNooki >= 0) {
      if (! GENERICSTACK_IS_PTR(factoringStackp,  stackIxOfParentNooki)) {
	MARPAWRAPPER_ERRORF(genericLoggerp, "No nook at indice %d of factoringStackp", stackIxOfParentNooki);
	goto err;
      }
      parentNookp = GENERICSTACK_GET_PTR(factoringStackp,  stackIxOfParentNooki);
      if (topNookp->isCauseb != 0) {
	parentNookp->causeIsExpandedb = 0;
      }
      if (topNookp->isPredecessorb != 0) {
	parentNookp->predecessorIsExpandedb = 0;
      }
    }
    orNodei = topNookp->orNodeIdi;
    GENERICSPARSEARRAY_SET(orNodeInUseSparseArrayp, marpaWrapperAsfp, orNodei, PTR, NULL);
    if (GENERICSPARSEARRAY_ERROR(orNodeInUseSparseArrayp)) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "orNodeInUseSparseArrayp set failure, %s", strerror(errno));
      goto err;
    }
    /* On the top of the stack, this is topNookp per definition */
    GENERICSTACK_POP_PTR(factoringStackp);
    if (GENERICSTACK_ERROR(factoringStackp)) {
      MARPAWRAPPER_ERROR(genericLoggerp, "failure to pop from factoringStackp");
      goto err;
    }
    free(topNookp);
  }

  *factoringIteratebp = 1;

 done:
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return 1, *factoringFinishbp=%d", (int) *factoringIteratebp);
  return 1;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

/****************************************************************************/
static inline short _marpaWrapperAsf_glade_id_factorsb(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfChoicePoint_t *choicepointp, genericStack_t **stackpp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_glade_id_factorsb);
  genericLogger_t          *genericLoggerp          = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
  genericStack_t           *stackp                  = *stackpp;
  genericStack_t           *orNodeStackp            = marpaWrapperAsfp->orNodeStackp;
  genericStack_t           *gladeStackp             = marpaWrapperAsfp->gladeStackp;
  genericStack_t            andNodeIdStack;
  genericStack_t           *andNodeIdStackp         = &andNodeIdStack;
  genericStack_t            causeNidsStack;
  genericStack_t           *causeNidsStackp         = &causeNidsStack;
  int                      *causeNidsp;
  int                       factorIxi;
  marpaWrapperAsfNook_t    *nookp;
  int                       orNodeIdi;
  marpaWrapperAsfOrNode_t  *orNodep;
  int                       nAndNodei;
  int                      *andNodep;
  int                       choicei;
  marpaWrapperAsfNidset_t  *baseNidsetp;
  int                       gladeIdi;
  int                       choicepointpMaxIndice;
  genericStack_t           *choicepointpFactoringStackp;
  
  GENERICSTACK_INIT(andNodeIdStackp);
  GENERICSTACK_INIT(causeNidsStackp);
  
  if (choicepointp->factoringStackp == NULL) {
    stackp = NULL;
    goto done;
  }

  choicepointpFactoringStackp = choicepointp->factoringStackp;
  choicepointpMaxIndice = GENERICSTACK_USED(choicepointpFactoringStackp) - 1;
  for (factorIxi = 0; factorIxi <= choicepointpMaxIndice; factorIxi++) {

    if (! GENERICSTACK_IS_PTR(choicepointpFactoringStackp,  factorIxi)) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "Not a pointer at indice %d of factoringStackp", factorIxi);
      goto err;
    }
    nookp = GENERICSTACK_GET_PTR(choicepointpFactoringStackp,  factorIxi);
    if (_marpaWrapperAsf_nook_has_semantic_causeb(marpaWrapperAsfp, nookp) == 0) {
      continue;
    }

    orNodeIdi = nookp->orNodeIdi;

    if (! GENERICSTACK_IS_PTR(orNodeStackp, orNodeIdi)) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "Not a pointer at indice %d of orNodeStackp", orNodeIdi);
      goto err;
    }
    orNodep = GENERICSTACK_GET_PTR(orNodeStackp, orNodeIdi);

    nAndNodei = orNodep->nAndNodei;
    andNodep = orNodep->andNodep;
    GENERICSTACK_USED(andNodeIdStackp) = 0;

    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "nook of OR_NODE %d first choice and last choice are %d and %d", nookp->orNodeIdi, nookp->firstChoicei, nookp->lastChoicei);
    for (choicei = nookp->firstChoicei; choicei <= nookp->lastChoicei; choicei++) {
      if ((choicei < 0) || (choicei > nAndNodei)) {
	MARPAWRAPPER_ERRORF(genericLoggerp, "andNode %d out of range [%d..%d[", choicei, 0, nAndNodei);
	goto err;
      }
      GENERICSTACK_PUSH_INT(andNodeIdStackp, andNodep[choicei]);
      if (GENERICSTACK_ERROR(andNodeIdStackp)) {
	MARPAWRAPPER_ERRORF(genericLoggerp, "generic stack push failure to andNodeIdStackp, %s", strerror(errno));
	goto err;
      }
    }
    GENERICSTACK_USED(causeNidsStackp) = 0;
    if (_marpaWrapperAsf_and_nodes_to_cause_nidsp(marpaWrapperAsfp, andNodeIdStackp, causeNidsStackp) == 0) {
      goto err;
    }
    GENERICSTACK_USED(andNodeIdStackp) = 0;

    if (GENERICSTACK_USED(causeNidsStackp) <= 0) {
      causeNidsp = NULL;
    } else {
      int i;

      if (GENERICSTACK_USED(causeNidsStackp) > marpaWrapperAsfp->causeNidsi) {
	if (marpaWrapperAsfp->causeNidsi <= 0) {
	  causeNidsp = marpaWrapperAsfp->causeNidsp = (int *) malloc(sizeof(int) * GENERICSTACK_USED(causeNidsStackp));
	  if (causeNidsp == NULL) {
	    MARPAWRAPPER_ERRORF(genericLoggerp, "malloc failure: %s", strerror(errno));
	    goto err;
	  }
	} else {
	  causeNidsp = realloc(marpaWrapperAsfp->causeNidsp, sizeof(int) * GENERICSTACK_USED(causeNidsStackp));
	  if (causeNidsp == NULL) {
	    MARPAWRAPPER_ERRORF(genericLoggerp, "malloc failure: %s", strerror(errno));
	    goto err;
	  } else {
	    marpaWrapperAsfp->causeNidsp = causeNidsp;
	  }
	}
	marpaWrapperAsfp->causeNidsi = GENERICSTACK_USED(causeNidsStackp);
      } else {
	causeNidsp = marpaWrapperAsfp->causeNidsp;
      }

      for (i = 0; i < GENERICSTACK_USED(causeNidsStackp); i++) {
	causeNidsp[i] = GENERICSTACK_GET_INT(causeNidsStackp, i);
	MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "... causeNidsp[%d] = %d", i, causeNidsp[i]);
      }
    }
    baseNidsetp = _marpaWrapperAsf_nidset_obtainp(marpaWrapperAsfp, GENERICSTACK_USED(causeNidsStackp), causeNidsp);
    if (baseNidsetp == NULL) {
      goto err;
    }
    gladeIdi = _marpaWrapperAsf_nidset_idi(marpaWrapperAsfp, baseNidsetp);
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "... gladeIdi = %d", gladeIdi);
    if (! GENERICSTACK_IS_PTR(gladeStackp,  gladeIdi)) {
      marpaWrapperAsfGlade_t *gladep;

      MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Generating glade at indice %d", gladeIdi);
      gladep = malloc(sizeof(marpaWrapperAsfGlade_t));
      if (gladep == NULL) {
        MARPAWRAPPER_ERRORF(genericLoggerp, "malloc failure: %s", strerror(errno));
        goto err;
      }
      gladep->idi           = gladeIdi;
      gladep->symchesStackp = NULL;
#if MARPAWRAPPERASF_USE_VISITED_FLAG > 0
      gladep->visitedb      = 0;
#endif
#if MARPAWRAPPERASF_USE_REGISTERED_FLAG > 0
      gladep->registeredb   = 1;
#endif
      GENERICSTACK_SET_PTR(gladeStackp, gladep,  gladeIdi);
      if (GENERICSTACK_ERROR(gladeStackp)) {
        MARPAWRAPPER_ERROR(genericLoggerp, "Failure to set in gladeStackp");
        free(gladep);
        goto err;
      }
#if MARPAWRAPPERASF_USE_REGISTERED_FLAG > 0
    } else {
      marpaWrapperAsfGlade_t *gladep;

      gladep = GENERICSTACK_GET_PTR(gladeStackp,  gladeIdi);
      gladep->registeredb = 1;
#endif
    }
    GENERICSTACK_PUSH_INT(stackp, gladeIdi);
    if (GENERICSTACK_ERROR(stackp)) {
      MARPAWRAPPER_ERROR(genericLoggerp, "Failure to push in stackp");
      goto err;
    }

  }
  
 done:
  GENERICSTACK_RESET(andNodeIdStackp);
  GENERICSTACK_RESET(causeNidsStackp);
  
  *stackpp = stackp;
#ifndef MARPAWRAPPER_NTRACE
  _marpaWrapperAsf_dump_stack(marpaWrapperAsfp, "Glade id factors", *stackpp);
#endif
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return 1, *stackpp=%p", *stackpp);
  return 1;

 err:
  GENERICSTACK_RESET(andNodeIdStackp);
  GENERICSTACK_RESET(causeNidsStackp);
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

/****************************************************************************/
int _marpaWrapperAsf_causesHash_indi(void *userDatavp, genericStackItemType_t itemType, void **pp)
/****************************************************************************/
{
  return _marpaWrapperAsf_djb2_s((unsigned char *) pp, sizeof(int)) % MARPAWRAPPERASF_CAUSESHASH_SIZE;
  /* return abs(* ((int *) pp)) % MARPAWRAPPERASF_CAUSESHASH_SIZE; */
}

/****************************************************************************/
static inline short _marpaWrapperAsf_and_nodes_to_cause_nidsp(marpaWrapperAsf_t *marpaWrapperAsfp, genericStack_t *andNodeIdStackp, genericStack_t *causeNidsStackp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_and_nodes_to_cause_nidsp);
  genericLogger_t          *genericLoggerp          = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
  Marpa_Bocage              marpaBocagep            = marpaWrapperAsfp->marpaBocagep;
  genericHash_t            *causesHashp             = marpaWrapperAsfp->causesHashp;
  int                       i;
  int                       andNodeIdi;
  int                       causeNidi;
  int                       goti;
  int                       indicei;
  short                     findResultb;

  GENERICHASH_RELAX(causesHashp, marpaWrapperAsfp);

  for (i = 0; i < GENERICSTACK_USED(andNodeIdStackp); i++) {
    if (! GENERICSTACK_IS_INT(andNodeIdStackp, i)) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "Not an int at indice %d andNodeIdStackp", i);
      goto err;
    }
    andNodeIdi = GENERICSTACK_GET_INT(andNodeIdStackp, i);
    causeNidi = (int) _marpa_b_and_node_cause(marpaBocagep, andNodeIdi);
    if (causeNidi < 0) {
      causeNidi = _marpaWrapperAsf_and_node_to_nidi(andNodeIdi);
    }
    /* If we are going to insert, we want to precompute indice instead of letting */
    /* the hash macros doing it for the find(), and then for the set().           */
    indicei = _marpaWrapperAsf_causesHash_indi((void *) marpaWrapperAsfp, GENERICSTACKITEMTYPE_PTR, (void **) &causeNidi);

    GENERICHASH_FIND_BY_IND(causesHashp,
			    marpaWrapperAsfp,
			    INT,
			    causeNidi,
			    INT,
			    &goti,
			    findResultb,
			    indicei);
    if (GENERICHASH_ERROR(causesHashp)) {
      MARPAWRAPPER_ERROR(genericLoggerp, "Error looking into causesHashp");
      goto err;
    }
    if (! findResultb) {
      GENERICSTACK_PUSH_INT(causeNidsStackp, causeNidi);
      if (GENERICSTACK_ERROR(causeNidsStackp)) {
	MARPAWRAPPER_ERROR(genericLoggerp, "Failure to push to causeNidsStackp");
	goto err;
      }
      GENERICHASH_SET_BY_IND(causesHashp,
			     marpaWrapperAsfp,
			     INT,
			     causeNidi,
			     INT,
			     1,
			     indicei);
      if (GENERICHASH_ERROR(causesHashp)) {
        MARPAWRAPPER_ERROR(genericLoggerp, "Error setting into causesHashp");
        goto err;
      }
    }
  }
  
#ifndef MARPAWRAPPER_NTRACE
  _marpaWrapperAsf_dump_stack(marpaWrapperAsfp, "<============= andNodeIdStackp", andNodeIdStackp);
  _marpaWrapperAsf_dump_stack(marpaWrapperAsfp, "=============> causeNidsStackp", causeNidsStackp);
#endif
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 1");
  return 1;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

/****************************************************************************/
static inline short _marpaWrapperAsf_next_factoringb(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfChoicePoint_t *choicepointp, int nidOfChoicePointi, short *factoringbp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_next_factoringb);
  genericLogger_t          *genericLoggerp          = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
  short                     factoringb              = 0;

  if (choicepointp->factoringStackp == NULL) {
      MARPAWRAPPER_ERROR(genericLoggerp, "Attempt to iterate factoring of uninitialized checkpoint");
      goto err;
  }

  while (1) {
    short factoringIterateb;
    short factoringFinishb;
    
    if (_marpaWrapperAsf_factoring_iterateb(marpaWrapperAsfp, choicepointp, &factoringIterateb) == 0) {
      goto err;
    }
    if (factoringIterateb == 0) {
      break;
    }
    if (_marpaWrapperAsf_factoring_finishb(marpaWrapperAsfp, choicepointp, nidOfChoicePointi, &factoringFinishb) == 0) {
      goto err;
    }
    if (factoringFinishb != 0) {
      factoringb = 1;
      break;
    }
  }

  *factoringbp = factoringb;
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return 1, *factorinbp=%d", *factoringbp);
  return 1;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;

}

#if MARPAWRAPPERASF_USE_VISITED_FLAG > 0
/****************************************************************************/
static inline short _marpaWrapperAsf_glade_is_visitedb(marpaWrapperAsf_t *marpaWrapperAsfp, int gladeIdi)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_glade_is_visitedb);
  genericLogger_t         *genericLoggerp = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
  short                    rcb            = 0;
  genericStack_t          *gladeStackp    = marpaWrapperAsfp->gladeStackp;
  marpaWrapperAsfGlade_t  *gladep;

  if (GENERICSTACK_IS_PTR(gladeStackp,  gladeIdi)) {

    gladep = GENERICSTACK_GET_PTR(gladeStackp,  gladeIdi);
    rcb = gladep->visitedb;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return %d", rcb);
  return rcb;
}
#endif

#if MARPAWRAPPERASF_USE_VISITED_FLAG > 0
/****************************************************************************/
static inline void _marpaWrapperAsf_glade_visited_clearb(marpaWrapperAsf_t *marpaWrapperAsfp, int *gladeIdip)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_glade_visited_clearb);
  genericLogger_t         *genericLoggerp = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
  genericStack_t          *gladeStackp    = marpaWrapperAsfp->gladeStackp;
  marpaWrapperAsfGlade_t  *gladep;
  int                      i;

  if (gladeIdip != NULL) {
    if (GENERICSTACK_IS_PTR(gladeStackp,  *gladeIdip)) {

      gladep = GENERICSTACK_GET_PTR(gladeStackp,  *gladeIdip);
      gladep->visitedb = 0;
    }
  } else {
    for (i = 0; i < GENERICSTACK_USED(gladeStackp); i++) {
      if (GENERICSTACK_IS_PTR(gladeStackp, i)) {

	gladep = GENERICSTACK_GET_PTR(gladeStackp, i);
	gladep->visitedb = 0;
      }
    }
  }
}
#endif

/****************************************************************************/
static inline short _marpaWrapperAsf_glade_symch_countb(marpaWrapperAsf_t *marpaWrapperAsfp, int gladeIdi, int *countip)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_glade_symch_countb);
  genericLogger_t         *genericLoggerp = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
  marpaWrapperAsfGlade_t  *gladep;
  int                      counti;

  gladep = _marpaWrapperAsf_glade_obtainp(marpaWrapperAsfp, gladeIdi);
  if (gladep == NULL) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "No glade found for glade ID %d", gladeIdi);
    goto err;
  }

  counti = GENERICSTACK_USED(gladep->symchesStackp);
  if (countip != NULL) {
    *countip = counti;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return 1 (*countip=%d)", counti);
  return 1;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

/****************************************************************************/
static inline int _marpaWrapperAsf_glade_symbol_idi(marpaWrapperAsf_t *marpaWrapperAsfp, int gladeIdi)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_glade_symbol_idi);
  genericLogger_t         *genericLoggerp     = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
  genericSparseArray_t    *nidsetSparseArrayp = marpaWrapperAsfp->nidsetSparseArrayp;
  int                      nid0;
  marpaWrapperAsfNidset_t *nidsetp;
  int                      symbolIdi;
  short                    findResult;

  GENERICSPARSEARRAY_FIND(nidsetSparseArrayp, marpaWrapperAsfp, gladeIdi, PTR, &nidsetp, findResult);
  if (GENERICSPARSEARRAY_ERROR(nidsetSparseArrayp)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "nidset sparse array find failure: %s", strerror(errno));
    goto err;
  }
  if (! findResult) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "No glade found for glade ID %d", gladeIdi);
    goto err;
  }

  if (_marpaWrapperAsf_nidset_idi_by_ixib(marpaWrapperAsfp, nidsetp, 0, &nid0) == 0) {
    goto err;
  }
  
  symbolIdi = _marpaWrapperAsf_nid_symbol_idi(marpaWrapperAsfp, nid0);
  if (symbolIdi < 0) {
    goto err;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return %d", symbolIdi);
  return symbolIdi;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return -1");
  return -1;
}

/****************************************************************************/
static inline int _marpaWrapperAsf_glade_spani(marpaWrapperAsf_t *marpaWrapperAsfp, int gladeIdi, int *lengthip)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_glade_spani);
  genericLogger_t         *genericLoggerp     = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
  genericSparseArray_t    *nidsetSparseArrayp = marpaWrapperAsfp->nidsetSparseArrayp;
  int                      spanIdi            = -1;
  int                      nid0;
  marpaWrapperAsfNidset_t *nidsetp;
  short                    findResult;
  int                      lengthi;

  GENERICSPARSEARRAY_FIND(nidsetSparseArrayp, marpaWrapperAsfp, gladeIdi, PTR, &nidsetp, findResult);
  if (GENERICSPARSEARRAY_ERROR(nidsetSparseArrayp)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "nidset sparse array find failure: %s", strerror(errno));
    goto err;
  }
  if (! findResult) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "No glade found for glade ID %d", gladeIdi);
    goto err;
  }

  if (_marpaWrapperAsf_nidset_idi_by_ixib(marpaWrapperAsfp, nidsetp, 0, &nid0) == 0) {
    goto err;
  }
  
  spanIdi = _marpaWrapperAsf_nid_spani(marpaWrapperAsfp, nid0, &lengthi);

  if (lengthip != NULL) {
    *lengthip = lengthi;
  }
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return %d (length %d)", spanIdi, lengthi);
  return spanIdi;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return -1");
  return -1;
}

/****************************************************************************/
int marpaWrapperAsf_traverse_rh_lengthi(marpaWrapperAsfTraverser_t *traverserp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperAsf_traverse_rh_lengthi);
  genericLogger_t          *genericLoggerp = NULL;
  marpaWrapperAsf_t        *marpaWrapperAsfp;
  marpaWrapperAsfGlade_t   *gladep;
  int                       symchIxi;
  genericStack_t           *factoringsStackp;
  genericStack_t           *downFactoringsStackp;
  int                       downRuleIdi;
  int                       factoringIxi;
  int                       realFactoringIxi;
  int                       lengthi;

  if (traverserp == NULL) {
    errno = EINVAL;
    goto err;
  }

  marpaWrapperAsfp = traverserp->marpaWrapperAsfp;
  genericLoggerp = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;

  gladep = traverserp->gladep;
  if (gladep == NULL) {
    MARPAWRAPPER_ERROR(genericLoggerp, "Current glade is NULL");
    goto err;
  }
  symchIxi = traverserp->symchIxi;
  /* symchesStackp is a stack of factoringsStack */
  if (! GENERICSTACK_IS_PTR(gladep->symchesStackp,  symchIxi)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "No symch at indice %d of current glade", symchIxi);
    goto err;
  }
  factoringsStackp = GENERICSTACK_GET_PTR(gladep->symchesStackp, symchIxi);
  /* factoringsStackp is (symchRuleIdi, PTR, downFactoringsStackp[0], downFactoringsStackp[1], ... ) */
  if (! GENERICSTACK_IS_INT(factoringsStackp, 0)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "Not an integer at indice 0 of factoringsStackp", 0);
#ifndef MARPAWRAPPER_NTRACE
    _marpaWrapperAsf_dump_stack(marpaWrapperAsfp, "symchesStackp", gladep->symchesStackp);
    _marpaWrapperAsf_dump_stack(marpaWrapperAsfp, "factoringsStackp", factoringsStackp);
#endif
    goto err;
  }

  factoringIxi = traverserp->factoringIxi;
  realFactoringIxi = 2 + factoringIxi;
  if (! GENERICSTACK_IS_PTR(factoringsStackp, realFactoringIxi)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "Not a pointer at indice 2+%d of factoringsStackp", factoringIxi);
#ifndef MARPAWRAPPER_NTRACE
    _marpaWrapperAsf_dump_stack(marpaWrapperAsfp, "symchesStackp", gladep->symchesStackp);
    _marpaWrapperAsf_dump_stack(marpaWrapperAsfp, "factoringsStackp", factoringsStackp);
#endif
    goto err;
  }
  downRuleIdi          = GENERICSTACK_GET_INT(factoringsStackp, 0);
  downFactoringsStackp = GENERICSTACK_GET_PTR(factoringsStackp, realFactoringIxi);
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "downRuleIdi is %d", downRuleIdi);

  if (downRuleIdi < 0) {
    MARPAWRAPPER_ERROR(genericLoggerp, "Called not allowed for a token");
    goto err;
  }

  /* downFactoringsStackp is a stack of gladeIdi */
  lengthi = GENERICSTACK_USED(downFactoringsStackp);
  
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return 1, lengthl = %d", lengthi);
  return lengthi;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return -1");
  return -1;
}


/****************************************************************************/
short marpaWrapperAsf_traverse_rh_valueb(marpaWrapperAsfTraverser_t *traverserp, int rhIxi, int *valueip, int *lengthip)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperAsf_traverse_rh_valueb);
  genericLogger_t            *genericLoggerp = NULL;
  genericSparseArray_t       *valueSparseArrayp;
  marpaWrapperAsfTraverser_t  childTraverser;
  short                       childValueSparseArrayb = 0;
  genericSparseArray_t        childValueSparseArray;
  genericSparseArray_t       *childValueSparseArrayp = &childValueSparseArray;
  int                         valuei;
  int                         lengthi;
  marpaWrapperAsf_t          *marpaWrapperAsfp;
  marpaWrapperAsfGlade_t     *gladep;
  int                         symchIxi;
  genericStack_t             *factoringsStackp;
  genericStack_t             *downFactoringsStackp;
  int                         ruleIdi;
  int                         factoringIxi;
  int                         realFactoringIxi;
  int                         maxRhixi;
  marpaWrapperAsfGlade_t     *downGladep;
  int                         downGladeIdi;
  short                       findResultb = 0;

  if (traverserp == NULL) {
    errno = EINVAL;
    goto err;
  }

  marpaWrapperAsfp  = traverserp->marpaWrapperAsfp;
  valueSparseArrayp = traverserp->valueSparseArrayp;
  genericLoggerp    = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;

  GENERICSPARSEARRAY_INIT(childValueSparseArrayp, _marpaWrapperAsf_valueSparseArray_indi);
  if (GENERICSPARSEARRAY_ERROR(childValueSparseArrayp)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "childValueSparseArrayp initialization failure: %s", strerror(errno));
    goto err;
  }
  childValueSparseArrayb = 1;

  gladep = traverserp->gladep;
  if (gladep == NULL) {
    MARPAWRAPPER_ERROR(genericLoggerp, "Current glade is NULL");
    goto err;
  }
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Current glade id is %d", gladep->idi);
  symchIxi = traverserp->symchIxi;
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Current symchIxi is %d", symchIxi);
  /* symchesStackp is a stack of factoringsStack */
  if (! GENERICSTACK_IS_PTR(gladep->symchesStackp,  symchIxi)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "No symch at indice %d of current glade", symchIxi);
    goto err;
  }
  factoringsStackp = GENERICSTACK_GET_PTR(gladep->symchesStackp, symchIxi);
  /* factoringsStackp is (symchRuleIdi, PTR, downFactoringsStackp[0], downFactoringsStackp[1], ... ) */
  if (! GENERICSTACK_IS_INT(factoringsStackp, 0)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "Not an integer at indice 0 of factoringsStackp", 0);
#ifndef MARPAWRAPPER_NTRACE
    _marpaWrapperAsf_dump_stack(marpaWrapperAsfp, "symchesStackp", gladep->symchesStackp);
    _marpaWrapperAsf_dump_stack(marpaWrapperAsfp, "factoringsStackp", factoringsStackp);
#endif
    goto err;
  }

  /* symchesStackp contains entries in the form: (rule_id, xxx, @factorings) */
  ruleIdi          = GENERICSTACK_GET_INT(factoringsStackp, 0);
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Current rule id is %d", ruleIdi);

  if (ruleIdi < 0) {
    marpaWrapperRecognizer_t *marpaWrapperRecognizerp = marpaWrapperAsfp->marpaWrapperRecognizerp;
    int                       spanIdi;
    
    /* Current node is a token: its value is its span ID, and this is working only if no alternative */
    /* have a length > 1 */
    if (marpaWrapperRecognizerp->haveVariableLengthTokenb != 0) {
      MARPAWRAPPER_ERROR(genericLoggerp, "This call is not allowed if there is at least one variablen length token");
      goto err;
    }
    spanIdi = _marpaWrapperAsf_glade_spani(marpaWrapperAsfp, gladep->idi, &lengthi);
    if (spanIdi < 0) {
      goto err;
    }
    /* The span ID is the indice in the input stack - meaningless if lengthi is <= 0, the caller have to take care: */
    /* then spanIdi is 0. */
    valuei = spanIdi;
    goto ok;
  }

  factoringIxi = traverserp->factoringIxi;
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Current factoringIxi is %d", factoringIxi);

  realFactoringIxi = 2 + factoringIxi;
  if (! GENERICSTACK_IS_PTR(factoringsStackp, realFactoringIxi)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "Not a pointer at indice 2+%d of factoringsStackp", factoringIxi);
#ifndef MARPAWRAPPER_NTRACE
    _marpaWrapperAsf_dump_stack(marpaWrapperAsfp, "symchesStackp", gladep->symchesStackp);
    _marpaWrapperAsf_dump_stack(marpaWrapperAsfp, "factoringsStackp", factoringsStackp);
#endif
    goto err;
  }
  downFactoringsStackp = GENERICSTACK_GET_PTR(factoringsStackp, realFactoringIxi);

#ifndef MARPAWRAPPER_NTRACE
  _marpaWrapperAsf_dump_stack(marpaWrapperAsfp, "downFactoringsStackp", downFactoringsStackp);
#endif
  maxRhixi = GENERICSTACK_USED(downFactoringsStackp);
  lengthi = maxRhixi; /* Number of RHS */
  /*
   * Nullables have no RHS
   */
  if (maxRhixi <= 0) {
    MARPAWRAPPER_TRACE(genericLoggerp, funcs, "Nullable case");
    goto ok;
  }
  --maxRhixi;
  if (rhIxi > maxRhixi) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "rhIxi should be in range [0..%d]", maxRhixi);
    goto err;
  }
  if (! GENERICSTACK_IS_INT(downFactoringsStackp, rhIxi)) {
    MARPAWRAPPER_ERROR(genericLoggerp, "Not an int in downFactoringsStackp");
    goto err;
  }
  downGladeIdi = GENERICSTACK_GET_INT(downFactoringsStackp, rhIxi);
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Current downGladeIdi is %d", downGladeIdi);
  GENERICSPARSEARRAY_FIND(valueSparseArrayp, marpaWrapperAsfp, downGladeIdi, INT, &valuei, findResultb);
  if (GENERICSPARSEARRAY_ERROR(valueSparseArrayp)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "valueSparseArrayp find failure, %s", strerror(errno));
    goto err;
  }
  if (findResultb) {
    /* Already memoized */
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Memoized valuei=%d", valuei);
    goto ok;
  }
  downGladep = _marpaWrapperAsf_glade_obtainp(marpaWrapperAsfp, downGladeIdi);
  if (downGladep == NULL) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "No glade found for glade ID %d", downGladeIdi);
    goto err;
  }
  /*
   * Do a shallow clone
   */
  childTraverser.marpaWrapperAsfp  = marpaWrapperAsfp;
  childTraverser.valueSparseArrayp = childValueSparseArrayp;
  childTraverser.gladep            = downGladep;
  childTraverser.symchIxi          = 0;
  childTraverser.factoringIxi      = 0;
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Calling traverser for downglade %d", downGladep->idi);
  if (! marpaWrapperAsfp->traverserCallbackp(&childTraverser, marpaWrapperAsfp->userDatavp, &valuei)) {
    goto err;
  }

  GENERICSPARSEARRAY_SET(valueSparseArrayp, marpaWrapperAsfp, downGladeIdi, INT, valuei);
  if (GENERICSPARSEARRAY_ERROR(valueSparseArrayp)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "valueSparseArrayp set failure, %s", strerror(errno));
    goto err;   
  }

ok:
  GENERICSPARSEARRAY_RESET(childValueSparseArrayp, marpaWrapperAsfp);
  if (valueip != NULL) {
    *valueip = valuei;
  }
  if (lengthip != NULL) {
    *lengthip = lengthi;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return 1 (*valueip=%d, *lengthip=%d)", valuei, lengthi);
  return 1;

 err:
  if (childValueSparseArrayb) {
    GENERICSPARSEARRAY_RESET(childValueSparseArrayp, marpaWrapperAsfp);
  }
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

/****************************************************************************/
short marpaWrapperAsf_traverse_symbolIdb(marpaWrapperAsfTraverser_t *traverserp, int *symbolIdip)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperAsf_traverse_symbolIdb);
  genericLogger_t          *genericLoggerp = NULL;
  marpaWrapperAsf_t        *marpaWrapperAsfp;
  marpaWrapperAsfGlade_t   *gladep;
  int                       gladeIdi;
  int                       symbolIdi;

  if (traverserp == NULL) {
    errno = EINVAL;
    goto err;
  }

  marpaWrapperAsfp = traverserp->marpaWrapperAsfp;
  genericLoggerp = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;

  gladep = traverserp->gladep;
  if (gladep == NULL) {
    MARPAWRAPPER_ERROR(genericLoggerp, "Current glade is NULL");
    goto err;
  }
  gladeIdi = gladep->idi;

  symbolIdi = _marpaWrapperAsf_glade_symbol_idi(marpaWrapperAsfp, gladeIdi);
  if (symbolIdi < 0) {
    goto err;
  }

  if (symbolIdip != NULL) {
    *symbolIdip = symbolIdi;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return 1, *symbolIdip=%d", symbolIdi);
  return 1;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

/****************************************************************************/
short marpaWrapperAsf_traverse_ruleIdb(marpaWrapperAsfTraverser_t *traverserp, int *ruleIdip)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperAsf_traverse_ruleIdb);
  genericLogger_t          *genericLoggerp = NULL;
  marpaWrapperAsf_t        *marpaWrapperAsfp;
  genericStack_t           *symchesStackp;
  marpaWrapperAsfGlade_t   *gladep;
  int                       symchIxi;
  genericStack_t           *factoringsStackp;
  int                       ruleIdi;

  if (traverserp == NULL) {
    errno = EINVAL;
    goto err;
  }

  marpaWrapperAsfp = traverserp->marpaWrapperAsfp;
  genericLoggerp = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;

  gladep = traverserp->gladep;
  if (gladep == NULL) {
    MARPAWRAPPER_ERROR(genericLoggerp, "Current glade is NULL");
    goto err;
  }
  symchIxi = traverserp->symchIxi;
  symchesStackp = gladep->symchesStackp;
  if (! GENERICSTACK_IS_PTR(symchesStackp,  symchIxi)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "No symch at indice %d", symchIxi);
    goto err;
  }
  factoringsStackp = GENERICSTACK_GET_PTR(symchesStackp,  symchIxi);
  if (factoringsStackp == NULL) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "Null factorings stack at symch indice %d", symchIxi);
    goto err;
  }
  ruleIdi = GENERICSTACK_GET_INT(factoringsStackp, 0);

  if (ruleIdip != NULL) {
    *ruleIdip = ruleIdi;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return 1, *ruleIdip=%d", ruleIdi);
  return 1;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

/****************************************************************************/
static inline short _marpaWrapperAsf_traverse_nextFactoringb(marpaWrapperAsfTraverser_t *traverserp, int *factoringIxip)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_traverse_nextFactoringb);
  genericLogger_t          *genericLoggerp = NULL;
  marpaWrapperAsf_t        *marpaWrapperAsfp;
  marpaWrapperAsfGlade_t   *gladep;
  int                       gladeIdi;
  int                       symchIxi;
  int                       lastFactoringi;
  int                       countFactoringi;
  int                       factoringIxi;

  if (traverserp == NULL) {
    errno = EINVAL;
    goto err;
  }

  marpaWrapperAsfp = traverserp->marpaWrapperAsfp;
  genericLoggerp = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;

  /* Never happens */
  /*
  if (factoringIxip == NULL) {
    MARPAWRAPPER_ERROR(genericLoggerp, "factoringIxip is NULL");
    goto err;
  }
  */

  gladep = traverserp->gladep;
  if (gladep == NULL) {
    MARPAWRAPPER_ERROR(genericLoggerp, "Current glade is NULL");
    goto err;
  }
  gladeIdi = gladep->idi;
  symchIxi = traverserp->symchIxi;

  if (_marpaWrapperAsf_symch_factoring_countb(marpaWrapperAsfp, gladeIdi, symchIxi, &countFactoringi) == 0) {
    goto err;
  }
  lastFactoringi = countFactoringi - 1;

  factoringIxi = traverserp->factoringIxi;
  if (factoringIxi >= lastFactoringi) {
    /* This is not formally an internal error: user asked for the next factoring and there is none */
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Current factoringIxi %d is >= last factoring indice %d", factoringIxi, lastFactoringi);
    *factoringIxip = -1;
  } else {
    *factoringIxip = traverserp->factoringIxi = ++factoringIxi;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return 1, *factoringIxip=%d", *factoringIxip);
  return 1;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

/****************************************************************************/
static inline short _marpaWrapperAsf_traverse_nextSymchb(marpaWrapperAsfTraverser_t *traverserp, int *symchIxip)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_traverse_nextSymchb);
  genericLogger_t          *genericLoggerp = NULL;
  marpaWrapperAsf_t        *marpaWrapperAsfp;
  marpaWrapperAsfGlade_t   *gladep;
  int                       gladeIdi;
  int                       symchIxi;
  int                       lastSymchi;
  int                       counti;

  if (traverserp == NULL) {
    errno = EINVAL;
    goto err;
  }

  marpaWrapperAsfp = traverserp->marpaWrapperAsfp;
  genericLoggerp = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;

  if (symchIxip == NULL) {
    MARPAWRAPPER_ERROR(genericLoggerp, "symchIxip is NULL");
    goto err;
  }

  gladep = traverserp->gladep;
  if (gladep == NULL) {
    MARPAWRAPPER_ERROR(genericLoggerp, "Current glade is NULL");
    goto err;
  }
  gladeIdi = gladep->idi;
  symchIxi = traverserp->symchIxi;

  if (_marpaWrapperAsf_glade_symch_countb(marpaWrapperAsfp, gladeIdi, &counti) == 0) {
    goto err;
  }
  lastSymchi = counti - 1;

  if (symchIxi >= lastSymchi) {
    /* This is not formally an internal error: this is part of calls behind nextb() */
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Current symchIxi %d is >= last symch indice %d", symchIxi, lastSymchi);
    *symchIxip = -1;
  } else {
    *symchIxip = traverserp->symchIxi = ++symchIxi;
    traverserp->factoringIxi = 0;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return 1, *symchIxip=%d", *symchIxip);
  return 1;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

/****************************************************************************/
short marpaWrapperAsf_traverse_nextb(marpaWrapperAsfTraverser_t *traverserp, short *nextbp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperAsf_traverse_nextb);
#ifndef MARPAWRAPPER_NTRACE
  genericLogger_t          *genericLoggerp = NULL;
#endif
  int                       idi;
  short                     nextb = 1;

  if (traverserp == NULL) {
    errno = EINVAL;
    goto err;
  }

#ifndef MARPAWRAPPER_NTRACE
  genericLoggerp = traverserp->marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
#endif

  if (_marpaWrapperAsf_traverse_nextFactoringb(traverserp, &idi) == 0) {
    goto err;
  }
  if (idi < 0) {
    if (_marpaWrapperAsf_traverse_nextSymchb(traverserp, &idi) == 0) {
      goto err;
    }
    if (idi < 0) {
      nextb = 0;
    }
  }

  if (nextbp != NULL) {
    *nextbp = nextb;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return 1, *nextbp=%d", (int) nextb);
  return 1;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

/****************************************************************************/
marpaWrapperAsf_t *marpaWrapperAsf_traverse_asfp(marpaWrapperAsfTraverser_t *traverserp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperAsf_traverse_asfp);
  marpaWrapperAsf_t        *marpaWrapperAsfp;
#ifndef MARPAWRAPPER_NTRACE
  genericLogger_t          *genericLoggerp;
#endif

  if (traverserp == NULL) {
    errno = EINVAL;
    return NULL;
  }

  marpaWrapperAsfp = traverserp->marpaWrapperAsfp;
#ifndef MARPAWRAPPER_NTRACE
  genericLoggerp = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
#endif

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return %p", marpaWrapperAsfp);
  return marpaWrapperAsfp;
}

/****************************************************************************/
marpaWrapperRecognizer_t *marpaWrapperAsf_recognizerp(marpaWrapperAsf_t *marpaWrapperAsfp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperAsf_recognizerp);
#ifndef MARPAWRAPPER_NTRACE
  genericLogger_t          *genericLoggerp;
#endif
  marpaWrapperRecognizer_t *marpaWrapperRecognizerp;

  if (marpaWrapperAsfp == NULL) {
    errno = EINVAL;
    return NULL;
  }

#ifndef MARPAWRAPPER_NTRACE
  genericLoggerp          = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
#endif
  marpaWrapperRecognizerp = marpaWrapperAsfp->marpaWrapperRecognizerp;

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return %p", marpaWrapperRecognizerp);
  return marpaWrapperRecognizerp;
}

/****************************************************************************/
short marpaWrapperAsf_genericLoggerp(marpaWrapperAsf_t *marpaWrapperAsfp, genericLogger_t **genericLoggerpp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperAsf_genericLoggerp);
  genericLogger_t *genericLoggerp;

  if (marpaWrapperAsfp == NULL) {
    errno = EINVAL;
    return 0;
  }

  genericLoggerp = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
  if (genericLoggerpp != NULL) {
    *genericLoggerpp = genericLoggerp;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return 1 (*genericLoggerpp=%p)", genericLoggerp);
  return 1;
}

/****************************************************************************/
void _marpaWrapperAsf_idset_sparseArrayFreev(void *userDatavp, void **pp)
/****************************************************************************/
{
  /* We know we receive a pointer to a (marpaWrapperAsfIdset_t  *)  that is never NULL */
  marpaWrapperAsfIdset_t  *idsetp = * ((marpaWrapperAsfIdset_t **) pp);

  if (idsetp->idip != NULL) {
    free(idsetp->idip);
  }
  free(idsetp);
}

/****************************************************************************/
static inline unsigned long _marpaWrapperAsf_djb2(unsigned char *str)
/****************************************************************************/
{
  unsigned long hash = 5381;
  int c;

  while ((c = *str++)) { /* gcc warning suggesting parentheses around assignment used as truth value - fine with me */
    hash = ((hash << 5) + hash) + c; /* hash * 33 + c */
  }

  return hash;
}

/****************************************************************************/
static inline unsigned long _marpaWrapperAsf_djb2_s(unsigned char *str, int lengthi)
/****************************************************************************/
{
  unsigned long hash = 5381;
  int c;
  int i;

  for (i = 0; i < lengthi; i++) {
    c = *str++;
    hash = ((hash << 5) + hash) + c; /* hash * 33 + c */
  }

  return hash;
}

/****************************************************************************/
int _marpaWrapperAsf_intset_keyIndFunctioni(void *userDatavp, genericStackItemType_t itemType, void **pp)
/****************************************************************************/
{
#ifndef MARPAWRAPPER_NTRACE
  /* For performance, this block, used only in TRACE mode, is compiled only if */
  /* compiled with support of tracing at this level.                           */
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_intset_keyIndFunctioni);
  marpaWrapperAsf_t *marpaWrapperAsfp = (marpaWrapperAsf_t *) userDatavp;
  genericLogger_t   *genericLoggerp   = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
#endif
  /* *pp is an array of int, with size at indice 0                                    */
  int   *idip = (int *) *pp;
  int    sizi = idip[0];
  int    sumi = 0;
  int    i;
  int    rci;

  if (sizi == 0) {
    return 0;
  }

  for (i = 1; i <= sizi; i++) {
    sumi ^= idip[i];
#ifndef MARPAWRAPPER_NTRACE
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "idip[%d]=%d => sumi=%d", i, idip[i], sumi);
#endif
  }

  rci = MARPAWRAPPERASF_INTSET_MODULO(sumi);
#ifndef MARPAWRAPPER_NTRACE
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "sumi=%d => indice %d", i, sumi, rci);
#endif

  return rci;
}

/****************************************************************************/
short _marpaWrapperAsf_intset_keyCmpFunctionb(void *userDatavp, void **pp1, void **pp2)
/****************************************************************************/
{
#ifndef MARPAWRAPPER_NTRACE
  /* For performance, this block, used only in TRACE mode, is compiled only if */
  /* compiled with support of tracing at this level.                           */
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_intset_keyCmpFunctionb);
  marpaWrapperAsf_t *marpaWrapperAsfp = (marpaWrapperAsf_t *) userDatavp;
  genericLogger_t   *genericLoggerp   = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
#endif
  int *idi1p = (int *) *pp1;
  int *idi2p = (int *) *pp2;
  int  siz1i = idi1p[0];
  int  siz2i = idi2p[0];
  int  i;

#ifndef MARPAWRAPPER_NTRACE
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "siz1i %d == siz2i %d ?", siz1i, siz2i);
#endif
  if (siz1i != siz2i) {
#ifndef MARPAWRAPPER_NTRACE
    MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
#endif
    return 0;
  } else if (siz1i == 0) {
#ifndef MARPAWRAPPER_NTRACE
    MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 1");
#endif
    return 1;
  }
  
  /* By definition elements are ordered */
  for (i = 1; i <= siz1i; i++) {
#ifndef MARPAWRAPPER_NTRACE
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "idi1[%d] %d == idi2[%d] %d ?", i, idi1p[i], i, idi2p[i]);
#endif
    if (idi1p[i] != idi2p[i]) {
#ifndef MARPAWRAPPER_NTRACE
      MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
#endif
      return 0;
    }
  }

#ifndef MARPAWRAPPER_NTRACE
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 1");
#endif
  return 1;
}

/****************************************************************************/
void *_marpaWrapperAsf_intset_keyCopyFunctionp(void *userDatavp, void **pp)
/****************************************************************************/
{
#ifndef MARPAWRAPPER_NTRACE
  /* For performance, this block, used only in TRACE mode, is compiled only if */
  /* compiled with support of tracing at this level.                           */
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_intset_keyCopyFunctionp);
  marpaWrapperAsf_t *marpaWrapperAsfp = (marpaWrapperAsf_t *) userDatavp;
  genericLogger_t   *genericLoggerp   = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
#endif
  int   *idip = (int *) *pp;
  int    sizi = idip[0];
  size_t sizl = sizeof(int) * (sizi + 1);
  int   *rcp = NULL;

#ifndef MARPAWRAPPER_NTRACE
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "sizi %ld", (unsigned long) sizl);
#endif

  rcp = malloc(sizl);
  if (rcp == NULL) {
#ifndef MARPAWRAPPER_NTRACE
    MARPAWRAPPER_ERRORF(genericLoggerp, "malloc failure: %s", strerror(errno));
#endif
    goto err;
  }
  memcpy(rcp, idip, sizl);
#ifndef MARPAWRAPPER_NTRACE
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return %p", rcp);
#endif
  return rcp;

 err:
#ifndef MARPAWRAPPER_NTRACE
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return NULL");
#endif
  return rcp;
}

/****************************************************************************/
void _marpaWrapperAsf_intset_keyFreeFunctionv(void *userDatavp, void **pp)
/****************************************************************************/
{
  free((int *) *pp);
}

/****************************************************************************/
static inline int _marpaWrapperAsf_or_node_es_spani(marpaWrapperAsf_t *marpaWrapperAsfp, int choicepointi, int *lengthip)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_or_node_es_spani);
#ifndef MARPAWRAPPER_NTRACE
  genericLogger_t *genericLoggerp = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
#endif
  Marpa_Bocage     marpaBocagep   = marpaWrapperAsfp->marpaBocagep;
  int              originEsi;
  int              currentEsi;
  int              spanIdi;
  int              lengthi;

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "_marpa_b_or_node_origin(%p, %d)", marpaBocagep, choicepointi);
  originEsi = _marpa_b_or_node_origin(marpaBocagep, choicepointi);
  
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "_marpa_b_or_node_set(%p, %d)", marpaBocagep, choicepointi);
  currentEsi = _marpa_b_or_node_set(marpaBocagep, choicepointi);
  
  spanIdi = originEsi;
  lengthi = currentEsi - originEsi;

  if (lengthip != NULL) {
    *lengthip = lengthi;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return spanIdi=%d, *lengthip=%d", spanIdi, lengthi);
  return spanIdi;
}

#ifndef MARPAWRAPPER_NTRACE
/****************************************************************************/
static inline void _marpaWrapperAsf_dump_stack(marpaWrapperAsf_t *marpaWrapperAsfp, char *what, genericStack_t *stackp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_dump_stack);
  genericLogger_t         *genericLoggerp           = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
  int                      i;

  if (what == NULL) {
    what = "uncategorized";
  }
  
  if (stackp == NULL) {
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "%s stack is NULL", what);
  } else {
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "%s stack length is %d", what, GENERICSTACK_USED(stackp));
    for (i = 0; i < GENERICSTACK_USED(stackp); i++) {
      switch (GENERICSTACKITEMTYPE(stackp, i)) {
      case GENERICSTACKITEMTYPE_NA:
	MARPAWRAPPER_TRACE(genericLoggerp, funcs, "... stackp[%d] is NA");
	break;
      case GENERICSTACKITEMTYPE_CHAR:
	MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "... stackp[%d] is CHAR: '%c' (0x%d)", i, GENERICSTACK_GET_CHAR(stackp, i), (int) GENERICSTACK_GET_CHAR(stackp, i));
	break;
      case GENERICSTACKITEMTYPE_SHORT:
	MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "... stackp[%d] is SHORT: %d", i, (int) GENERICSTACK_GET_SHORT(stackp, i));
	break;
      case GENERICSTACKITEMTYPE_INT:
	MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "... stackp[%d] is INT: %d", i, GENERICSTACK_GET_INT(stackp, i));
	break;
      case GENERICSTACKITEMTYPE_LONG:
	MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "... stackp[%d] is LONG: %ld", i, GENERICSTACK_GET_LONG(stackp, i));
	break;
      case GENERICSTACKITEMTYPE_FLOAT:
	MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "... stackp[%d] is FLOAT: %f", i, (double) GENERICSTACK_GET_FLOAT(stackp, i));
	break;
      case GENERICSTACKITEMTYPE_DOUBLE:
	MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "... stackp[%d] is DOUBLE: %f", i, GENERICSTACK_GET_DOUBLE(stackp, i));
	break;
      case GENERICSTACKITEMTYPE_PTR:
	MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "... stackp[%d] is PTR: %p", i, GENERICSTACK_GET_PTR(stackp, i));
	break;
      default:
	MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "... stackp[%d] is unknown", i);
	break;
      }
    }
  }
}
#endif

/****************************************************************************/
static inline marpaWrapperAsfChoicePoint_t *_marpaWrapperAsf_choicepoint_newp(marpaWrapperAsf_t *marpaWrapperAsfp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_choicepoint_newp);
  genericLogger_t              *genericLoggerp = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
  marpaWrapperAsfChoicePoint_t *choicepointp;

  choicepointp = malloc(sizeof(marpaWrapperAsfChoicePoint_t));
  if (choicepointp == NULL) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "malloc failure: %s", strerror(errno));
    goto err;
  }

  choicepointp->factoringStackp   = NULL;
  GENERICSPARSEARRAY_NEW(choicepointp->orNodeInUseSparseArrayp, _marpaWrapperAsf_orNodeInUse_sparseArrayIndi);
  if (GENERICSPARSEARRAY_ERROR(choicepointp->orNodeInUseSparseArrayp)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "orNodeInUseSparseArrayp initialization failure: %s", strerror(errno));
    goto err;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return %p", choicepointp);
  return choicepointp;

 err:
  _marpaWrapperAsf_choicepoint_freev(marpaWrapperAsfp, choicepointp);
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return NULL");
  return NULL;
}

/****************************************************************************/
static inline void _marpaWrapperAsf_choicepoint_freev(marpaWrapperAsf_t *marpaWrapperAsfp, marpaWrapperAsfChoicePoint_t *choicepointp)
/****************************************************************************/
{
  if (choicepointp != NULL) {
    _marpaWrapperAsf_factoringStackp_freev(marpaWrapperAsfp, &(choicepointp->factoringStackp));
    GENERICSPARSEARRAY_FREE(choicepointp->orNodeInUseSparseArrayp, marpaWrapperAsfp);
    free(choicepointp);
  }
}

#ifndef MARPAWRAPPER_NTRACE
/****************************************************************************/
static void _marpaWrapperAsf_dumpintsetHashpv(marpaWrapperAsf_t *marpaWrapperAsfp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_dumpintsetHashpv);
  genericLogger_t   *genericLoggerp  = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
  genericHash_t     *intsetHashp     = marpaWrapperAsfp->intsetHashp;
  int                i;
  int                j;
  int                k;
  int               *idip;
  int                nInRowi;

  if (intsetHashp == NULL) {
    return;
  }

  for (i = 0; i < GENERICSTACK_USED(intsetHashp->keyStackp); i++) {
    genericStack_t *subStackp;

    if (! GENERICSTACK_IS_PTR(intsetHashp->keyStackp, i)) {
      continue;
    }

    subStackp = GENERICSTACK_GET_PTR(intsetHashp->keyStackp, i);
    nInRowi = 0;
    for (j = 0; j < GENERICSTACK_USED(subStackp); j++) {

      if (! GENERICSTACK_IS_PTR(subStackp, j)) {
	continue;
      }
      ++nInRowi;
      idip = GENERICSTACK_GET_PTR(subStackp, j);
      MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Row %6d column %6d", i, j);
      for (k = 1; k <= idip[0]; k++) {
	MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "   %d", idip[k]);
      }
    }
    if (nInRowi > 1) {
      MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Row %6d has %d collisions", i, nInRowi);
    }
  }
}
#endif

/****************************************************************************/
int _marpaWrapperAsf_valueSparseArray_indi(void *userDatavp, genericStackItemType_t itemType, void **pp)
/****************************************************************************/
{
  return _marpaWrapperAsf_djb2_s((unsigned char *) pp, sizeof(int)) % MARPAWRAPPERASF_VALUESPARSEARRAY_SIZE;
  /* return abs(* ((int *) pp)) % MARPAWRAPPERASF_CAUSESHASH_SIZE; */
}

/****************************************************************************/
marpaWrapperAsfValue_t *marpaWrapperAsfValue_newp(marpaWrapperRecognizer_t *marpaWrapperRecognizerp, marpaWrapperAsfOption_t *marpaWrapperAsfOptionp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperAsfValue_newp);
  marpaWrapperAsf_t      *marpaWrapperAsfp      = NULL;
  marpaWrapperAsfValue_t *marpaWrapperAsfValuep = NULL;
  genericLogger_t        *genericLoggerp;

  marpaWrapperAsfp = marpaWrapperAsf_newp(marpaWrapperRecognizerp, marpaWrapperAsfOptionp);
  if (marpaWrapperAsfp == NULL) {
    errno = EINVAL;
    return 0;
  }

  genericLoggerp = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;

  marpaWrapperAsfValuep = (marpaWrapperAsfValue_t *) malloc(sizeof(marpaWrapperAsfValue_t));
  if (marpaWrapperAsfValuep == NULL) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "malloc failure: %s", strerror(errno));
    goto err;
  }

  marpaWrapperAsfValuep->marpaWrapperAsfp                  = marpaWrapperAsfp;
  marpaWrapperAsfValuep->traverserp                        = NULL;
  marpaWrapperAsfValuep->nParsesi                          = 0;
  marpaWrapperAsfValuep->userDatavp                        = NULL;
  marpaWrapperAsfValuep->okRuleCallbackp                   = NULL;
  marpaWrapperAsfValuep->okSymbolCallbackp                 = NULL;
  marpaWrapperAsfValuep->okNullingCallbackp                = NULL;
  marpaWrapperAsfValuep->valueRuleCallbackp                = NULL;
  marpaWrapperAsfValuep->valueSymbolCallbackp              = NULL;
  marpaWrapperAsfValuep->valueNullingCallbackp             = NULL;
  marpaWrapperAsfValuep->parentRuleiStackp                 = NULL;
  marpaWrapperAsfValuep->wantedOutputStacki                = 0;
  marpaWrapperAsfValuep->leveli                            = 0;
  marpaWrapperAsfValuep->firstb                            = 1;
  marpaWrapperAsfValuep->indicei                           = -1;
  marpaWrapperAsfValuep->wantNextChoiceb                   = 0;
  marpaWrapperAsfValuep->gotNextChoiceb                    = 0;
  marpaWrapperAsfValuep->consumedNextChoicesPerLevelStackp = NULL;
  marpaWrapperAsfValuep->haveNextChoicePerLevelStackp      = NULL;

  GENERICSTACK_NEW(marpaWrapperAsfValuep->parentRuleiStackp);
  if (GENERICSTACK_ERROR(marpaWrapperAsfValuep->parentRuleiStackp)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "marpaWrapperAsfValuep->parentRuleiStackp initialization failure, %s", strerror(errno));
    goto err;
  }

  GENERICSTACK_NEW(marpaWrapperAsfValuep->consumedNextChoicesPerLevelStackp);
  if (GENERICSTACK_ERROR(marpaWrapperAsfValuep->consumedNextChoicesPerLevelStackp)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "marpaWrapperAsfValuep->consumedNextChoicesPerLevelStackp initialization failure: %s", strerror(errno));
    goto err;
  }

  GENERICSTACK_NEW(marpaWrapperAsfValuep->haveNextChoicePerLevelStackp);
  if (GENERICSTACK_ERROR(marpaWrapperAsfValuep->haveNextChoicePerLevelStackp)) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "marpaWrapperAsfValuep->haveNextChoicePerLevelStackp initialization failure: %s", strerror(errno));
    goto err;
  }

  goto done;

 err:
  marpaWrapperAsfValue_freev(marpaWrapperAsfValuep);
  marpaWrapperAsfValuep = NULL;

 done:
  return marpaWrapperAsfValuep;
}

/****************************************************************************/
short marpaWrapperAsfValue_valueb(marpaWrapperAsfValue_t *marpaWrapperAsfValuep,
                                  void                              *userDatavp,
                                  marpaWrapperAsfOkRuleCallback_t    okRuleCallbackp,
                                  marpaWrapperAsfOkSymbolCallback_t  okSymbolCallbackp,
                                  marpaWrapperAsfOkNullingCallback_t okNullingCallbackp,
                                  marpaWrapperValueRuleCallback_t    valueRuleCallbackp,
                                  marpaWrapperValueSymbolCallback_t  valueSymbolCallbackp,
                                  marpaWrapperValueNullingCallback_t valueNullingCallbackp)
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(marpaWrapperAsf_valueb);
  marpaWrapperAsf_t *marpaWrapperAsfp;
#ifndef MARPAWRAPPER_NTRACE
  genericLogger_t   *genericLoggerp;
#endif
  short              rcb;
  int                valuei;

  if (marpaWrapperAsfValuep == NULL) {
    errno = EINVAL;
    return -1;
  }

  marpaWrapperAsfp = marpaWrapperAsfValuep->marpaWrapperAsfp;
#ifndef MARPAWRAPPER_NTRACE
  genericLoggerp = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;
#endif

  marpaWrapperAsfValuep->userDatavp                        = userDatavp;
  marpaWrapperAsfValuep->okRuleCallbackp                   = okRuleCallbackp;
  marpaWrapperAsfValuep->okSymbolCallbackp                 = okSymbolCallbackp;
  marpaWrapperAsfValuep->okNullingCallbackp                = okNullingCallbackp;
  marpaWrapperAsfValuep->valueRuleCallbackp                = valueRuleCallbackp;
  marpaWrapperAsfValuep->valueSymbolCallbackp              = valueSymbolCallbackp;
  marpaWrapperAsfValuep->valueNullingCallbackp             = valueNullingCallbackp;

#ifndef MARPAWRAPPER_NTRACE
  {
    int i;
    MARPAWRAPPER_TRACE(genericLoggerp, funcs,"-------------------------");
    MARPAWRAPPER_TRACE(genericLoggerp, funcs,"Current state of choices:");
    MARPAWRAPPER_TRACE(genericLoggerp, funcs,"-------------------------");
    for (i = 0; i < GENERICSTACK_USED(marpaWrapperAsfValuep->haveNextChoicePerLevelStackp); i++) {
      if (GENERICSTACK_IS_SHORT(marpaWrapperAsfValuep->haveNextChoicePerLevelStackp, i)) {
        MARPAWRAPPER_TRACEF(genericLoggerp, funcs,"haveNextChoicePerLevelStackp[%d]=%d", i, (int) GENERICSTACK_GET_SHORT(marpaWrapperAsfValuep->haveNextChoicePerLevelStackp, i));
      } else {
        MARPAWRAPPER_TRACEF(genericLoggerp, funcs,"haveNextChoicePerLevelStackp[%d]=NA", i);
      }
    }
    for (i = 0; i < GENERICSTACK_USED(marpaWrapperAsfValuep->consumedNextChoicesPerLevelStackp); i++) {
      if (GENERICSTACK_IS_INT(marpaWrapperAsfValuep->consumedNextChoicesPerLevelStackp, i)) {
        MARPAWRAPPER_TRACEF(genericLoggerp, funcs,"consumedNextChoicesPerLevelStackp[%d]=%d", i, GENERICSTACK_GET_SHORT(marpaWrapperAsfValuep->consumedNextChoicesPerLevelStackp, i));
      } else {
        MARPAWRAPPER_TRACEF(genericLoggerp, funcs,"consumedNextChoicesPerLevelStackp[%d]=NA", i);
      }
    }
  }
#endif

  /* Check if next round should be done */
  if ((marpaWrapperAsfp->marpaWrapperAsfOption.maxParsesi > 0) && (marpaWrapperAsfValuep->nParsesi >= marpaWrapperAsfp->marpaWrapperAsfOption.maxParsesi)) {
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Maximum number of parse trees is reached: %d", marpaWrapperAsfp->marpaWrapperAsfOption.maxParsesi);
    goto err;
  }

  rcb = marpaWrapperAsf_traverseb(marpaWrapperAsfp, _marpaWrapperAsf_valueTraverserb, marpaWrapperAsfValuep, &valuei);
  if (! rcb) {
    goto err;
  }
  if (valuei < 0) {
    /* All alternatives were rejected */
    goto err;
  }

  /* Prepare the next round */
  marpaWrapperAsfValuep->nParsesi++;
  marpaWrapperAsfValuep->userDatavp                      = NULL;
  marpaWrapperAsfValuep->okRuleCallbackp                 = NULL;
  marpaWrapperAsfValuep->okSymbolCallbackp               = NULL;
  marpaWrapperAsfValuep->okNullingCallbackp              = NULL;
  marpaWrapperAsfValuep->valueRuleCallbackp              = NULL;
  marpaWrapperAsfValuep->valueSymbolCallbackp            = NULL;
  marpaWrapperAsfValuep->valueNullingCallbackp           = NULL;
  marpaWrapperAsfValuep->wantedOutputStacki              =  0;
  marpaWrapperAsfValuep->traverserp                      = NULL;
  marpaWrapperAsfValuep->leveli                          =  0;
  marpaWrapperAsfValuep->firstb                          =  0;
  marpaWrapperAsfValuep->indicei                         = -1;
  marpaWrapperAsfValuep->wantNextChoiceb                 =  1;
  marpaWrapperAsfValuep->gotNextChoiceb                  =  0;
  rcb = 1;
  goto done;

 err:
  rcb = marpaWrapperAsfValuep->firstb ? -1 /* Error */: 0 /* End */;

 done:
  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return %d", (int) rcb);
  return rcb;
}

/****************************************************************************/
static inline short _marpaWrapperAsf_valueTraverserb(marpaWrapperAsfTraverser_t *traverserp, void *userDatavp, int *valueip)
/****************************************************************************/
/* Our traverser has the following semantics:                               */
/* *valueip is the wanted indice in output stack.                           */
/*                                                                          */
/* It returns -1 if failure                                                 */
/*             0 if the end                                                 */
/*             1 if ok                                                      */
/*                                                                          */
/* Each iteration is doing a replay to get positionned where needed.        */
/****************************************************************************/
{
  MARPAWRAPPER_FUNCS(_marpaWrapperAsf_valueTraverserb);
  marpaWrapperAsf_t                  *marpaWrapperAsfp      = marpaWrapperAsf_traverse_asfp(traverserp);
  genericLogger_t                    *genericLoggerp        = NULL;
  marpaWrapperAsfValue_t             *marpaWrapperAsfValuep = (marpaWrapperAsfValue_t *) userDatavp;
  genericStack_t                     *parentRuleiStackp     = marpaWrapperAsfValuep->parentRuleiStackp;
  marpaWrapperAsfOkRuleCallback_t     okRuleCallbackp       = marpaWrapperAsfValuep->okRuleCallbackp;
  marpaWrapperAsfOkSymbolCallback_t   okSymbolCallbackp     = marpaWrapperAsfValuep->okSymbolCallbackp;
  marpaWrapperAsfOkNullingCallback_t  okNullingCallbackp    = marpaWrapperAsfValuep->okNullingCallbackp;
  marpaWrapperValueRuleCallback_t     valueRuleCallbackp    = marpaWrapperAsfValuep->valueRuleCallbackp;
  marpaWrapperValueSymbolCallback_t   valueSymbolCallbackp  = marpaWrapperAsfValuep->valueSymbolCallbackp;
  marpaWrapperValueNullingCallback_t  valueNullingCallbackp = marpaWrapperAsfValuep->valueNullingCallbackp;
  int                                 wantedOutputStacki    = marpaWrapperAsfValuep->wantedOutputStacki;
  short                               rcb;
  int                                 marpaRuleIdi;
  int                                 marpaSymbolIdi;
  int                                 rhvaluei;
  int                                 rhlengthi;
  int                                 tokenValuei;
  int                                 lengthi;
  int                                 rhIxi;
  short                               nextb;
  int                                 nbAlternativeOki;
  int                                 arg0i;
  int                                 argni;
  int                                 localWantedOutputStacki;
  short                               manageNextChoiceb;
  int                                 consumedNextChoicesi;
  int                                 nextChoicei;
  int                                 numberOfLevelsInStacki;
  int                                 i;
  short                               isDeepestLevelWithAChoiceb;
  short                               haveLevelWithAChoiceb;
  int                                 indicei;

  marpaWrapperAsfValuep->leveli++;
  marpaWrapperAsfValuep->traverserp = traverserp; /* Take care: any call CAN change it - this is why it is restored systematically after ANY call */
  indicei = ++marpaWrapperAsfValuep->indicei;

  rcb = marpaWrapperAsf_genericLoggerp(marpaWrapperAsfp, &genericLoggerp);
  marpaWrapperAsfValuep->traverserp = traverserp; /* Restore */
  if (! rcb) {
    goto err;
  }

  rcb = marpaWrapperAsf_traverse_ruleIdb(traverserp, &marpaRuleIdi);
  marpaWrapperAsfValuep->traverserp = traverserp; /* Restore */
  if (! rcb) {
    goto err;
  }

  rcb = marpaWrapperAsf_traverse_symbolIdb(traverserp, &marpaSymbolIdi);
  marpaWrapperAsfValuep->traverserp = traverserp; /* Restore */
  if (! rcb) {
    goto err;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs,"[%3d][%3d] Rule %d, symbol %d, wanted indice in the output stack: %d", marpaWrapperAsfValuep->leveli, indicei, marpaRuleIdi, marpaSymbolIdi, wantedOutputStacki);

  if (marpaRuleIdi < 0) {
    /* This is a token - we do not really mind if this is a rule with no rhs, or a nullable symbol */
    manageNextChoiceb = 0;

    /* Get its value */
    rcb = marpaWrapperAsf_traverse_rh_valueb(traverserp, 0, &rhvaluei, &rhlengthi);
    marpaWrapperAsfValuep->traverserp = traverserp; /* Restore */
    if (! rcb) {
      goto err;
    }

    /* marpaSymbolIdi is the symbol ID of either a the LHS rule with no RHS, or of a nulling symbol */
    if (rhlengthi <= 0) {
      /* Nulling token */
      if (okNullingCallbackp == NULL) {
        MARPAWRAPPER_ERRORF(genericLoggerp, "Ok nulling callback is needed for symbol No %d", marpaSymbolIdi);
        goto reject;
      }
      rcb = okNullingCallbackp(marpaWrapperAsfValuep->userDatavp, marpaWrapperAsfValuep->parentRuleiStackp, marpaSymbolIdi);
      marpaWrapperAsfValuep->traverserp = traverserp; /* Restore */
      if (rcb < 0) {
        MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Symbol No %d ok nulling callback says reject", marpaSymbolIdi);
        goto reject;
      } else if (rcb == 0) {
        MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Symbol No %d ok nulling callback says failure", marpaSymbolIdi);
        goto err;
      }
      if (valueNullingCallbackp == NULL) {
        MARPAWRAPPER_ERRORF(genericLoggerp, "Value nulling callback is needed for symbol No %d", marpaSymbolIdi);
        goto reject;
      }
      rcb = valueNullingCallbackp(marpaWrapperAsfValuep->userDatavp, marpaSymbolIdi, wantedOutputStacki);
      marpaWrapperAsfValuep->traverserp = traverserp; /* Restore */
      if (! rcb) {
        MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Symbol No %d value nulling callback says failure", marpaSymbolIdi);
        goto err;
      }
    } else {
      /* Non-Nulling token. By definition this is a "lexeme", refering to input stack at indice tokenValuei. */
      /* Marpa does not like when input stack start with 0, it is required (and documented) to always */
      /* start with something non-meaninful at indice 0. Real values start at indice 1. */
      tokenValuei = rhvaluei + 1;
      if (okSymbolCallbackp == NULL) {
        MARPAWRAPPER_ERRORF(genericLoggerp, "Ok symbol callback is needed for symbol No %d", marpaSymbolIdi);
        goto reject;
      }
      rcb = okSymbolCallbackp(marpaWrapperAsfValuep->userDatavp, marpaWrapperAsfValuep->parentRuleiStackp, marpaSymbolIdi, tokenValuei);
      marpaWrapperAsfValuep->traverserp = traverserp; /* Restore */
      if (rcb < 0) {
        MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Symbol No %d ok callback says reject", marpaSymbolIdi);
        goto reject;
      } else if (rcb == 0) {
        MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Symbol No %d ok callback says failure", marpaSymbolIdi);
        goto err;
      }
      if (valueSymbolCallbackp == NULL) {
        MARPAWRAPPER_ERRORF(genericLoggerp, "Value symbol callback is needed for symbol No %d", marpaSymbolIdi);
        goto reject;
      }
      rcb = valueSymbolCallbackp(marpaWrapperAsfValuep->userDatavp, marpaSymbolIdi, tokenValuei, wantedOutputStacki);
      marpaWrapperAsfValuep->traverserp = traverserp; /* Restore */
      if (! rcb) {
        MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Symbol No %d value callback says failure", marpaSymbolIdi);
        goto err;
      }
    }

    /* A token act as a single alternative */
    nbAlternativeOki = 1;
  } else {
    /* This is a rule */

    GENERICSTACK_PUSH_INT(parentRuleiStackp, marpaRuleIdi);
    if (GENERICSTACK_ERROR(parentRuleiStackp)) {
      MARPAWRAPPER_ERRORF(genericLoggerp, "parentRuleiStackp push failure, %s", strerror(errno));
      goto err;
    }
    
    manageNextChoiceb    = 1;
    consumedNextChoicesi = 0;

    /* Look how far is this level */
    if (GENERICSTACK_IS_INT(marpaWrapperAsfValuep->consumedNextChoicesPerLevelStackp, indicei)) {
      consumedNextChoicesi = GENERICSTACK_GET_INT(marpaWrapperAsfValuep->consumedNextChoicesPerLevelStackp, indicei);
      if (consumedNextChoicesi > 0) {
        MARPAWRAPPER_TRACEF(genericLoggerp, funcs,"[%3d][%3d] ==> Consuming immediately %d choices", marpaWrapperAsfValuep->leveli, indicei, consumedNextChoicesi);
        for (nextChoicei = 1; nextChoicei <= consumedNextChoicesi; nextChoicei++) {
          /* Check for another alternative */
          rcb = marpaWrapperAsf_traverse_nextb(traverserp, &nextb);
          marpaWrapperAsfValuep->traverserp = traverserp; /* Restore */
          if (! rcb) {
            goto err;
          }
          if (! nextb) {
            /* Impossible */
            MARPAWRAPPER_ERRORF(genericLoggerp, "[%3d][%5d] ==> Tried to consume a choice that do not exist", marpaWrapperAsfValuep->leveli, indicei, marpaWrapperAsfValuep->leveli);
            goto err;
          }
        }
      }
    }

    if (marpaWrapperAsfValuep->wantNextChoiceb) {
      if (! marpaWrapperAsfValuep->gotNextChoiceb) {
        if (GENERICSTACK_IS_SHORT(marpaWrapperAsfValuep->haveNextChoicePerLevelStackp, indicei) &&
            GENERICSTACK_GET_SHORT(marpaWrapperAsfValuep->haveNextChoicePerLevelStackp, indicei)) {
          /* We accept to get next choice at this iteration only if this is the deepest that give this possibility */
          numberOfLevelsInStacki = GENERICSTACK_USED(marpaWrapperAsfValuep->haveNextChoicePerLevelStackp);
          isDeepestLevelWithAChoiceb = 1;
          for (i = indicei + 1; i < numberOfLevelsInStacki; i++) {
            if (GENERICSTACK_IS_SHORT(marpaWrapperAsfValuep->haveNextChoicePerLevelStackp, i) &&
                GENERICSTACK_GET_SHORT(marpaWrapperAsfValuep->haveNextChoicePerLevelStackp, i)) {
              MARPAWRAPPER_TRACEF(genericLoggerp, funcs,"[%3d][%3d] ==> Not switching to next choice - another iteration can do so indice at %d", marpaWrapperAsfValuep->leveli, indicei, i);
              isDeepestLevelWithAChoiceb = 0;
              break;
            }
          }
          if (isDeepestLevelWithAChoiceb) {
            marpaWrapperAsfValuep->gotNextChoiceb = 1;
            MARPAWRAPPER_TRACEF(genericLoggerp, funcs,"[%3d][%3d] ==> Getting next choice", marpaWrapperAsfValuep->leveli, indicei);
            /* We do not do the goto nextRule, because we want to verify that the prediction was correct */
            rcb = marpaWrapperAsf_traverse_nextb(traverserp, &nextb);
            marpaWrapperAsfValuep->traverserp = traverserp; /* Restore */
            if (! rcb) {
              goto err;
            }
            if (! nextb) {
              /* Impossible */
              MARPAWRAPPER_ERRORF(genericLoggerp, "[%3d][%3d] ==> Predicted next choice does not exist", marpaWrapperAsfValuep->leveli, indicei);
              goto err;
            }
            rcb = marpaWrapperAsf_traverse_ruleIdb(traverserp, &marpaRuleIdi);
            marpaWrapperAsfValuep->traverserp = traverserp; /* Restore */
            if (! rcb) {
              goto err;
            }
            ++consumedNextChoicesi;

            /* This is invalidating all the further iteration numbers */
            MARPAWRAPPER_TRACEF(genericLoggerp, funcs,"[%3d][%3d] ==> Invalidating any other setup after current indice", marpaWrapperAsfValuep->leveli, indicei);
            GENERICSTACK_USED(marpaWrapperAsfValuep->haveNextChoicePerLevelStackp)      = indicei + 1;
            GENERICSTACK_USED(marpaWrapperAsfValuep->consumedNextChoicesPerLevelStackp) = indicei + 1;
          }
        }
      }
      if (! marpaWrapperAsfValuep->gotNextChoiceb) {
        /* If we are here, this is an error ir no choice change is possible at any iteration */
        haveLevelWithAChoiceb = 0;
        for (i = 0; i < GENERICSTACK_USED(marpaWrapperAsfValuep->haveNextChoicePerLevelStackp); i++) {
          if (GENERICSTACK_IS_SHORT(marpaWrapperAsfValuep->haveNextChoicePerLevelStackp, i) &&
              GENERICSTACK_GET_SHORT(marpaWrapperAsfValuep->haveNextChoicePerLevelStackp, i)) {
            haveLevelWithAChoiceb = 1;
            break;
          }
        }
        if (! haveLevelWithAChoiceb) {
          MARPAWRAPPER_TRACEF(genericLoggerp, funcs,"[%3d][%3d] ==> No choice is available at any iteration - end of parse tree valuation", marpaWrapperAsfValuep->leveli, indicei);
          goto err;
        }
      }
    }

    nbAlternativeOki = 0;
    while (1) {

      /* Rule length */
      lengthi = marpaWrapperAsf_traverse_rh_lengthi(traverserp);
      marpaWrapperAsfValuep->traverserp = traverserp; /* Restore */
      if (lengthi < 0) {
        goto err;
      }

      /* Rule value */
      for (rhIxi = 0, localWantedOutputStacki = wantedOutputStacki;
           rhIxi < lengthi;
           rhIxi++, localWantedOutputStacki++) {

        marpaWrapperAsfValuep->wantedOutputStacki = localWantedOutputStacki;
        rcb = marpaWrapperAsf_traverse_rh_valueb(traverserp, rhIxi, &localWantedOutputStacki, NULL);
        marpaWrapperAsfValuep->traverserp = traverserp; /* Restore */
        if (! rcb) {
          marpaWrapperAsfValuep->wantedOutputStacki = wantedOutputStacki;
          goto err;
        }

        if (localWantedOutputStacki < 0) {
          /* There is rejection below: go to next alternative */
          MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Rule No %d traversal is hitting a reject", marpaRuleIdi);
          /* We do not change next free indice in the output stack so that user can free what is now a garbage */
          marpaWrapperAsfValuep->wantedOutputStacki = wantedOutputStacki;
          goto nextRule;
        }
      }
      argni = --localWantedOutputStacki;
      arg0i = argni - (lengthi - 1);

      GENERICSTACK_POP_INT(parentRuleiStackp);
      if (GENERICSTACK_ERROR(parentRuleiStackp)) {
        MARPAWRAPPER_ERRORF(genericLoggerp, "parentRuleiStackp pop failure, %s", strerror(errno));
        goto err;
      }

      /* Check if it is ok */
      if (okRuleCallbackp == NULL) {
        MARPAWRAPPER_ERRORF(genericLoggerp, "Ok rule callback is needed for rule No %d", marpaRuleIdi);
        goto reject;
      }
      rcb = okRuleCallbackp(marpaWrapperAsfValuep->userDatavp, marpaWrapperAsfValuep->parentRuleiStackp, marpaRuleIdi, arg0i, argni);
      marpaWrapperAsfValuep->traverserp = traverserp; /* Restore */
      if (rcb < 0) {
        MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Rule No %d value callback says reject", marpaRuleIdi);
	if (nbAlternativeOki == 0) {
	  nbAlternativeOki = -1;
	}
        goto reject;
      } else if (rcb == 0) {
        MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Rule No %d value callback says failure", marpaRuleIdi);
        goto err;
      }

      if (valueRuleCallbackp == NULL) {
        MARPAWRAPPER_ERRORF(genericLoggerp, "Value rule callback is needed for rule No %d", marpaRuleIdi);
        goto reject;
      }
      rcb = valueRuleCallbackp(marpaWrapperAsfValuep->userDatavp, marpaRuleIdi, arg0i, argni, wantedOutputStacki);
      marpaWrapperAsfValuep->traverserp = traverserp; /* Restore */
      if (! rcb) {
        MARPAWRAPPER_ERRORF(genericLoggerp, "Rule No %d value callback failure", marpaSymbolIdi);
        goto err;
      }

      /* Prune the number of accepted alternatives */
      if (++nbAlternativeOki == 1) {
	MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "Rule No %d value callback success: ignoring other alternatives", marpaSymbolIdi);
        break;
      }

    nextRule:
      /* Check for another alternative */
      rcb = marpaWrapperAsf_traverse_nextb(traverserp, &nextb);
      marpaWrapperAsfValuep->traverserp = traverserp; /* Restore */
      if (! rcb) {
        goto err;
      }
      if (! nextb) {
        break;
      }
      /* There is another alternative: get the ruleId */
      rcb = marpaWrapperAsf_traverse_ruleIdb(traverserp, &marpaRuleIdi);
      marpaWrapperAsfValuep->traverserp = traverserp; /* Restore */
      if (! rcb) {
        goto err;
      }
      ++consumedNextChoicesi;
    }

  }

  if (nbAlternativeOki < 0) {
    /* All alternatives were rejected */
    wantedOutputStacki = -1;
  }
  rcb = 1;
  goto done;

 reject:
  /* Formally not an error, we indicate our caller this is a rejection */
  rcb = 1;
  wantedOutputStacki = -1;
  goto done;

 err:
  rcb = 0;

 done:
  if (rcb) {
    rcb = marpaWrapperAsf_traverse_nextb(traverserp, &nextb);
    marpaWrapperAsfValuep->traverserp = traverserp; /* Restore */
    if (! rcb) {
      goto err;
    }
    if (manageNextChoiceb) {
      GENERICSTACK_SET_SHORT(marpaWrapperAsfValuep->haveNextChoicePerLevelStackp, nextb, indicei);
      if (GENERICSTACK_ERROR(marpaWrapperAsfValuep->haveNextChoicePerLevelStackp)) {
        MARPAWRAPPER_ERRORF(genericLoggerp, "[%3d][%3d] ==> marpaWrapperAsfValuep->haveNextChoicePerLevelStackp set failure, %s", marpaWrapperAsfValuep->leveli, indicei, strerror(errno));
        goto err;
      }
      MARPAWRAPPER_TRACEF(genericLoggerp, funcs,"[%3d][%3d] ==> Setted have next choice flag to %d", marpaWrapperAsfValuep->leveli, indicei, (int) nextb);

      GENERICSTACK_SET_INT(marpaWrapperAsfValuep->consumedNextChoicesPerLevelStackp, consumedNextChoicesi, indicei);
      if (GENERICSTACK_ERROR(marpaWrapperAsfValuep->consumedNextChoicesPerLevelStackp)) {
        MARPAWRAPPER_ERRORF(genericLoggerp, "[%3d][%3d] ==> marpaWrapperAsfValuep->consumedNextChoicesPerLevelStackp set failure, %s", marpaWrapperAsfValuep->leveli, indicei, strerror(errno));
        goto err;
      }
      MARPAWRAPPER_TRACEF(genericLoggerp, funcs,"[%3d][%3d] ==> Setted consumed next choices to %d", marpaWrapperAsfValuep->leveli, indicei, consumedNextChoicesi);
    }
    if (valueip != NULL) {
      *valueip = wantedOutputStacki;
    }
  }

#ifndef MARPAWRAPPER_NTRACE
  if (rcb) {
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "[%3d][%3d] return %d, *valueip=%d", marpaWrapperAsfValuep->leveli, indicei, (int) rcb, wantedOutputStacki);
  } else {
    MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "[%3d][%3d] return %d", marpaWrapperAsfValuep->leveli, indicei, (int) rcb);
  }
#endif
  
  marpaWrapperAsfValuep->leveli--;

  return rcb;
}

/****************************************************************************/
void marpaWrapperAsfValue_freev(marpaWrapperAsfValue_t *marpaWrapperAsfValuep)
/****************************************************************************/
{
  if (marpaWrapperAsfValuep != NULL) {
    GENERICSTACK_FREE(marpaWrapperAsfValuep->parentRuleiStackp);
    GENERICSTACK_FREE(marpaWrapperAsfValuep->consumedNextChoicesPerLevelStackp);
    GENERICSTACK_FREE(marpaWrapperAsfValuep->haveNextChoicePerLevelStackp);
    marpaWrapperAsf_freev(marpaWrapperAsfValuep->marpaWrapperAsfp);
    free(marpaWrapperAsfValuep);
  }
}

/****************************************************************************/
short marpaWrapperAsfValue_value_startb(marpaWrapperAsfValue_t *marpaWrapperAsfValuep, int *startip)
/****************************************************************************/
{
  const static char          *funcs          = "marpaWrapperAsfValue_value_startb";
  genericLogger_t            *genericLoggerp = NULL;
  marpaWrapperAsf_t          *marpaWrapperAsfp;
  marpaWrapperAsfTraverser_t *traverserp;
  marpaWrapperAsfGlade_t     *gladep;
  int                         starti;

  if (marpaWrapperAsfValuep == NULL) {
    errno = EINVAL;
    goto err;
  }

  marpaWrapperAsfp  = marpaWrapperAsfValuep->marpaWrapperAsfp;
  if (marpaWrapperAsfp == NULL) {
    errno = EINVAL;
    goto err;
  }

  genericLoggerp    = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;

  traverserp = marpaWrapperAsfValuep->traverserp;
  if (traverserp == NULL) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "%s called outside traverser", funcs);
    goto err;
  }

  gladep = traverserp->gladep;
  if (gladep == NULL) {
    MARPAWRAPPER_ERROR(genericLoggerp, "Current glade is NULL");
    goto err;
  }

  starti = _marpaWrapperAsf_glade_spani(marpaWrapperAsfp, gladep->idi, NULL /* lengthip */);
  if (starti < 0) {
    goto err;
  }

  if (startip != NULL) {
    *startip = starti;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return 1 (*startip=%d)", starti);
  return 1;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

/****************************************************************************/
short marpaWrapperAsfValue_value_lengthb(marpaWrapperAsfValue_t *marpaWrapperAsfValuep, int *lengthip)
/****************************************************************************/
{
  const static char          *funcs          = "marpaWrapperAsfValue_value_lengthb";
  genericLogger_t            *genericLoggerp = NULL;
  marpaWrapperAsf_t          *marpaWrapperAsfp;
  marpaWrapperAsfTraverser_t *traverserp;
  marpaWrapperAsfGlade_t     *gladep;
  int                         lengthi;

  if (marpaWrapperAsfValuep == NULL) {
    errno = EINVAL;
    goto err;
  }

  marpaWrapperAsfp  = marpaWrapperAsfValuep->marpaWrapperAsfp;
  if (marpaWrapperAsfp == NULL) {
    errno = EINVAL;
    goto err;
  }

  genericLoggerp    = marpaWrapperAsfp->marpaWrapperAsfOption.genericLoggerp;

  traverserp = marpaWrapperAsfValuep->traverserp;
  if (traverserp == NULL) {
    MARPAWRAPPER_ERRORF(genericLoggerp, "%s called outside traverser", funcs);
    goto err;
  }

  gladep = traverserp->gladep;
  if (gladep == NULL) {
    MARPAWRAPPER_ERROR(genericLoggerp, "Current glade is NULL");
    goto err;
  }

  if (_marpaWrapperAsf_glade_spani(marpaWrapperAsfp, gladep->idi, &lengthi) < 0) {
    goto err;
  }

  if (lengthip != NULL) {
    *lengthip = lengthi;
  }

  MARPAWRAPPER_TRACEF(genericLoggerp, funcs, "return 1 (*lengthip=%d)", lengthi);
  return 1;

 err:
  MARPAWRAPPER_TRACE(genericLoggerp, funcs, "return 0");
  return 0;
}

