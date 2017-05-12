#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

/* Standard system headers: */
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>

/* Stuff from the Brill tagger source: */
#include "lex.h"
#include "darray.h"
#include "registry.h"
#include "memory.h"
#include "useful.h"
#include "rules.h"

#define MAXTAGLEN 256  /* max char length of pos tags */
#define MAXWORDLEN 256 /* max char length of words */

#define RESTRICT_MOVE 1   /* if this is set to 1, then a rule "change a tag */
			  /* from x to y" will only apply to a word if:
			     a) the word was not in the training set or
			     b) the word was tagged with y at least once in
			     the training set  
			     When training on a very small corpus, better
			     performance might be obtained by setting this to
			     0, but for most uses it should be set to 1 */

#ifndef PERL_UNUSED_VAR
#define PERL_UNUSED_VAR(var) if (0) var = var
#endif


/* A structure to shove all the otherwise-global stuff into */
typedef struct {
  Registry lexicon_hash;
  Registry lexicon_tag_hash;
  Registry good_right_hash;
  Registry good_left_hash;
  Registry ntot_hash;
  Registry bigram_hash;
  Registry wordlist_hash;
  
  Darray rule_array;
  Darray contextual_rule_array;
} tagger_context;

/* Convert a SV* containing an arrayref into an AV* */
AV *unpack_aref(SV *input_rv, char *name) {
  if ( !SvROK(input_rv) || SvTYPE(SvRV(input_rv)) != SVt_PVAV ) {
    croak("Argument '%s' must be array reference", name);
  }
  
  return (AV*) SvRV(input_rv);
}

/* Extract the '_context' structure out of $self */
tagger_context *get_tagger_context (SV *self) {
  HV *self_hash = (HV*) SvRV(self);
  SV **fetched = hv_fetch(self_hash, "_context", 8, 0);
  if (fetched == NULL) croak("Couldn't fetch the _context slot in $self");

  return (tagger_context *) SvIV(*fetched);
}

/* Used in the above free_registry() function below */
void free_registry_entry(void *key, void *value, void *other) {
  PERL_UNUSED_VAR(other);
  Safefree(key);
  if (value != (void *)1) Safefree(value);
}

/* Destroy a Registry whose keys & values have been allocated using
 * perl's memory manager
 */
void free_registry(Registry r) {
  Registry_traverse(r, free_registry_entry, NULL);
  Registry_destroy(r);
}

/* Destroy the memory allocated to one of the rule arrays */
void free_rule_array(Darray a) {
  int i;
  int t = Darray_len(a);
  for (i=0; i<t; i++) {
    rule_destroy(Darray_get(a, i));
  }
  Darray_destroy(a);
}

MODULE = Lingua::BrillTagger         PACKAGE = Lingua::BrillTagger

PROTOTYPES: ENABLE

void
_xs_init (self, int lexicon_size)
    SV   * self
  CODE:
    {
      /* Initializes data structures that will be used in the lifetime of $self */

      SV **fetched;
      HV *self_hash;
      tagger_context *c;
      New(id, c, 1, tagger_context);

      /* Instantiate the various structures that will be needed for tagging */
      c->lexicon_hash    = Registry_create(Registry_strcmp, Registry_strhash);
      c->lexicon_tag_hash= Registry_create(Registry_strcmp, Registry_strhash);
      c->ntot_hash       = Registry_create(Registry_strcmp, Registry_strhash);
      c->good_right_hash = Registry_create(Registry_strcmp, Registry_strhash);
      c->good_left_hash  = Registry_create(Registry_strcmp, Registry_strhash);
      c->bigram_hash     = Registry_create(Registry_strcmp, Registry_strhash);
      c->wordlist_hash   = Registry_create(Registry_strcmp, Registry_strhash);

      c->rule_array = Darray_create();
      c->contextual_rule_array = Darray_create();

      
      Registry_size_hint(c->lexicon_hash, lexicon_size);
      Registry_size_hint(c->lexicon_tag_hash, lexicon_size);


      /* Create a new slot in $self to hold the tagger_context* struct */
      self_hash = (HV*) SvRV(self);
      fetched = hv_fetch(self_hash, "_context", 8, 1);
      if (fetched == NULL) croak("Couldn't create the _context slot in $self");
      
      sv_setiv(*fetched, (IV) c);
      SvREADONLY_on(*fetched);
    }

void
_xs_destroy (self)
     SV   * self
  CODE:
    {
      tagger_context *c = get_tagger_context(self);
      
      free_registry(c->lexicon_hash);
      free_registry(c->lexicon_tag_hash);
      free_registry(c->ntot_hash);
      free_registry(c->good_right_hash);
      free_registry(c->good_left_hash);
      free_registry(c->bigram_hash);
      free_registry(c->wordlist_hash);
      
      free_rule_array(c->rule_array);
      free_rule_array(c->contextual_rule_array);

      Safefree(c);
    }

void
_add_to_lexicon( self, word, tag )
     SV   * self
     char * word
     char * tag
  CODE:
    {
      tagger_context *c = get_tagger_context(self);
      Registry_add(c->lexicon_hash, savepv(word), savepv(tag));
    }

void
_add_to_lexicon_tags( self, bigram )
     SV   * self
     char * bigram
  CODE:
    {
      tagger_context *c = get_tagger_context(self);
      Registry_add(c->lexicon_tag_hash, savepv(bigram), (char *)1);
    }

void
_add_lexical_rule( self, rule )
     SV   * self
     char * rule
  CODE:
    {
      tagger_context *c = get_tagger_context(self);
      trans_rule *r = parse_lexical_rule(rule);
      Darray_addh(c->rule_array, r);
    }


void
_add_contextual_rule( self, rule )
     SV   * self
     char * rule
  CODE:
    {
      tagger_context *c = get_tagger_context(self);
      trans_rule *r = parse_contextual_rule(rule);
      Darray_addh(c->contextual_rule_array, r);
    }


void
_add_wordlist_word( self, word )
     SV   * self
     char * word
  CODE:
    {
      tagger_context *c = get_tagger_context(self);
      Registry_add(c->wordlist_hash, savepv(word), (char *)1);
    }

void
_add_goodleft( self, word )
     SV   * self
     char * word
  CODE:
    {
      tagger_context *c = get_tagger_context(self);
      Registry_add(c->good_left_hash, savepv(word), (char *)1);
    }

void
_add_goodright( self, word )
     SV   * self
     char * word
  CODE:
    {
      tagger_context *c = get_tagger_context(self);
      Registry_add(c->good_right_hash, savepv(word), (char *)1);
    }

void
_load_into_corpus( self, word )
     SV   * self
     char * word
  CODE:
    {
      tagger_context *c = get_tagger_context(self);
      if (Registry_get(c->lexicon_hash, word) == NULL) {
	Registry_add(c->ntot_hash, savepv(word), (char *)1);
      }
    }
     

void
_add_bigram( self, bigram1, bigram2 )
     SV   * self
     char * bigram1
     char * bigram2
  CODE:
    {
      char bigram_space[2+2*MAXWORDLEN];

      tagger_context *c = get_tagger_context(self);

      /* XXX ntot_hash is likely empty here */

      if (
	  (Registry_get(c->good_right_hash,bigram1) && Registry_get(c->ntot_hash,bigram2))
	  ||
	  (Registry_get(c->good_left_hash, bigram2) && Registry_get(c->ntot_hash,bigram1))
	 ) {

	snprintf(bigram_space, 2+2*MAXWORDLEN, "%s %s", bigram1, bigram2);
	Registry_add(c->bigram_hash, savepv(bigram_space), (char *)1);
      }
    }

void
_default_tag_finish( self, text, tags )
     SV   * self
     SV   * text
     SV   * tags
  CODE:
    {
      int j;
      SV **fetched;
      char *tempstr, *word;

      AV *text_av = unpack_aref(text, "text");
      AV *tags_av = unpack_aref(tags, "tags");

      int num_tokens = av_len(text_av)+1;

      tagger_context *c = get_tagger_context(self);

      if (num_tokens != av_len(tags_av)+1)
	croak("Different number of entries in text & tag arrays");


      for(j=0; j<num_tokens; j++) {

	fetched = av_fetch(text_av, j, 0);
	if (fetched == NULL)
	  croak("Token %d was missing unexpectedly upon replacement", j);
	word = SvPV_nolen(*fetched);
	
	fetched = av_fetch(tags_av, j, 0);
	if (fetched == NULL)
	  croak("Tag %d was missing unexpectedly upon replacement", j);
	
	if ((tempstr = Registry_get(c->lexicon_hash, word)) != NULL) {
	  /* Hmm, seems like I should have to free this memory, but
	     doing so causes a core dump... */
	  /* Safefree(SvPV_nolen(*fetched)); */
	  sv_setpv(*fetched, savepv(tempstr));
	}
      }
    }


void
_apply_lexical_rules( self, text, tags, EXTRAWDS )
     SV   * self
     SV   * text
     SV   * tags
     int    EXTRAWDS
  CODE:
    {
      int num_rules, j;
      SV **fetched;

      AV *text_av = unpack_aref(text, "text");
      AV *tags_av = unpack_aref(tags, "tags");

      Darray text_array = Darray_create();
      Darray tag_array  = Darray_create();
      
      tagger_context *c = get_tagger_context(self);

      int num_tokens = av_len(text_av)+1;
      if (num_tokens != av_len(tags_av)+1)
	croak("Different number of entries in text & tag arrays");

      /* Stuff the incoming tokens & tags into Darrays */
      for (j=0; j<num_tokens; j++) {
	fetched = av_fetch(text_av, j, 0);
	if (fetched == NULL)
	  croak("Token %d was missing unexpectedly", j);
	/* warn("Setting text entry %d to %s", j, SvPV_nolen(*fetched)); */
	Darray_addh(text_array, savepv( SvPV_nolen(*fetched) ));

	fetched = av_fetch(tags_av, j, 0);
	if (fetched == NULL)
	  croak("Tag %d was missing unexpectedly", j);
	/* warn("Setting tag entry %d to %s", j, SvPV_nolen(*fetched)); */
	Darray_addh(tag_array, savepv( SvPV_nolen(*fetched) ));
      }

      /* Apply the rules */
      num_rules = Darray_len(c->rule_array);
      for (j=0; j < num_rules; ++j) {
	apply_lexical_rule(Darray_get(c->rule_array, j),
			   text_array, tag_array,
			   c->lexicon_hash, c->wordlist_hash, c->bigram_hash,
			   EXTRAWDS);
      }
      
      /* Stuff the results back into the perl arrays */
      for (j=0; j<num_tokens; j++) {
	fetched = av_fetch(text_av, j, 0);
	if (fetched == NULL)
	  croak("Token %d was missing unexpectedly upon replacement", j);
	sv_setpv(*fetched, savepv( Darray_get(text_array, j) ));

	fetched = av_fetch(tags_av, j, 0);
	if (fetched == NULL)
	  croak("Tag %d was missing unexpectedly upon replacement", j);
	sv_setpv(*fetched, savepv( Darray_get(tag_array, j) ));
      }

      Darray_destroy(text_array);
      Darray_destroy(tag_array);
    }


void
_apply_contextual_rules( self, text, tags )
     SV   * self
     SV   * text
     SV   * tags
  CODE:
    {
      int num_rules, j;
      SV **fetched;
      char **text_array, **tag_array;
      
      AV *text_av = unpack_aref(text, "text");
      AV *tags_av = unpack_aref(tags, "tags");

      int num_tokens = av_len(text_av)+1;

      tagger_context *c = get_tagger_context(self);
      
      if (num_tokens != av_len(tags_av)+1)
	croak("Different number of entries in text & tag arrays");

      /* Allocate space for the arrays (but not yet array entries) */
      New(0, text_array, num_tokens, char*);
      New(0, tag_array,  num_tokens, char*);
      

      /* Stuff the incoming tokens & tags into char* arrays */
      for (j=0; j<num_tokens; j++) {
	fetched = av_fetch(text_av, j, 0);
	if (fetched == NULL)
	  croak("Token %d was missing unexpectedly", j);
	/* warn("Setting text entry %d to %s\n", j, SvPV_nolen(*fetched)); */
	text_array[j] = savepv( SvPV_nolen(*fetched) );

	fetched = av_fetch(tags_av, j, 0);
	if (fetched == NULL)
	  croak("Tag %d was missing unexpectedly", j);
	/* warn("Setting tag entry %d to %s\n", j, SvPV_nolen(*fetched)); */
	tag_array[j] = savepv( SvPV_nolen(*fetched) );
      }
      
      
      if (RESTRICT_MOVE && Registry_entry_count(c->lexicon_hash) == 0)
	croak("Must load a lexicon before applying contextual rules");


      /* Apply the rules */
      num_rules = Darray_len(c->contextual_rule_array);
      for (j=0; j < num_rules; ++j) {
	apply_contextual_rule(Darray_get(c->contextual_rule_array, j),
			      text_array, tag_array, num_tokens,
			      RESTRICT_MOVE, c->lexicon_hash, c->lexicon_tag_hash);
      }
      
      /* Stuff the results back into the perl arrays */
      for (j=0; j<num_tokens; j++) {
	fetched = av_fetch(tags_av, j, 0);
	if (fetched == NULL)
	  croak("Tag %d was missing unexpectedly upon replacement", j);
	sv_setpv(*fetched, tag_array[j]);
      }

      Safefree(text_array);
      Safefree(tag_array);
    }
