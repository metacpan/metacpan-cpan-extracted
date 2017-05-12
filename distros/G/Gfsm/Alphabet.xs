#/*-*- Mode: C -*- */

MODULE = Gfsm		PACKAGE = Gfsm::Alphabet

##=====================================================================
## Constructors etc.
##=====================================================================

##-- disable perl prototypes
PROTOTYPES: DISABLE

##--------------------------------------------------------------
## Constructor: new()
gfsmAlphabet*
new(char *CLASS)
CODE:
//RETVAL=gfsm_string_alphabet_new();
 RETVAL=gfsm_perl_alphabet_new();
OUTPUT:
 RETVAL

##--------------------------------------------------------------
## clear
void
clear(gfsmAlphabet *abet)
CODE:
 gfsm_alphabet_clear(abet);

##--------------------------------------------------------------
## Destructor: DESTROY()
void
DESTROY(gfsmAlphabet* abet)
CODE:
 if (abet) gfsm_perl_alphabet_free((gfsmPerlAlphabet*)abet);
 gfsm_perl_blow_chunks();


##=====================================================================
## Accessors
##=====================================================================

##--------------------------------------------------------------
## Alphabet properties

gfsmLabelVal
lab_min(gfsmAlphabet *abet)
CODE:
 RETVAL=abet->lab_min;
OUTPUT:
 RETVAL

gfsmLabelVal
lab_max(gfsmAlphabet *abet)
CODE:
 RETVAL=abet->lab_max;
OUTPUT:
 RETVAL

gfsmLabelVal
size(gfsmAlphabet *abet)
CODE:
 RETVAL=gfsm_alphabet_size(abet);
OUTPUT:
 RETVAL

gboolean
utf8(gfsmAlphabet *abet, ...)
CODE:
 if (items > 1) {
   abet->utf8 = SvTRUE(ST(1));
 }
 RETVAL = abet->utf8;
OUTPUT:
 RETVAL


##--------------------------------------------------------------
## Lookup & Manipulation

#//-- insert a (key,label) pair : UNSAFE!
#gfsmLabelVal
#insert(gfsmAlphabet *abet, char *key, gfsmLabelVal label=gfsmNoLabel)
#CODE:
# /*RETVAL=gfsm_alphabet_insert(abet,key,label);*/
#OUTPUT:
# RETVAL

#//-- get label of key, or insert new label
#gfsmLabelVal
#get_label(gfsmAlphabet *abet, char *key, gfsmLabelVal label=gfsmNoLabel)
gfsmLabelVal
get_label(gfsmAlphabet *abet, SV *key, gfsmLabelVal label=gfsmNoLabel)
CODE:
 RETVAL=gfsm_alphabet_get_full(abet,key,label);
OUTPUT:
 RETVAL

#//-- find a label of key, no auto-insertion
#gfsmLabelVal
#find_label(gfsmAlphabet *abet, char *key)
gfsmLabelVal
find_label(gfsmAlphabet *abet, SV *key)
CODE:
 RETVAL=gfsm_alphabet_find_label(abet,key);
OUTPUT:
 RETVAL

#//-- get key for label, or insert gfsmNoKey : UNSAFE
#char *
#get_key(gfsmAlphabet *abet, gfsmLabelVal label)
#CODE:
# RETVAL=gfsm_alphabet_get_key(abet,label);
#OUTPUT:
# RETVAL

#//-- find key for a label value, no auto-insertion
#char *
#find_key(gfsmAlphabet *abet, gfsmLabelVal label)
SV *
find_key(gfsmAlphabet *abet, gfsmLabelVal label)
CODE:
  RETVAL=newSVsv(gfsm_alphabet_find_key(abet,label));
OUTPUT:
  RETVAL

#//-- remove a key
#void
#remove_key(gfsmAlphabet *abet, char *key)
void
remove_key(gfsmAlphabet *abet, SV *key)
CODE:
 gfsm_alphabet_remove_key(abet,key);

#//-- remove a label
void
remove_label(gfsmAlphabet *abet, gfsmLabelVal label)
CODE:
 gfsm_alphabet_remove_label(abet,label);

#//-- merge keys from alphabet a2 into a1
void
merge(gfsmAlphabet *a1, gfsmAlphabet *a2)
CODE:
 gfsm_alphabet_union(a1,a2);

#//-- return an array-ref of all defined labels
AV *
labels(gfsmAlphabet *abet)
PREINIT:
 GPtrArray *tmp;
 int i;
CODE:
{
 tmp = g_ptr_array_new();
 gfsm_alphabet_labels_to_array(abet,tmp);

 RETVAL = newAV();
 sv_2mortal((SV*)RETVAL);
 for (i=0; i < tmp->len; i++) {
   av_push(RETVAL, newSViv((IV)GPOINTER_TO_INT(g_ptr_array_index(tmp,i))));
 }
 
 g_ptr_array_free(tmp,TRUE);
}
OUTPUT:
 RETVAL

##--------------------------------------------------------------
## Low-level index access
HV *
asHash(gfsmPerlAlphabet *abet)
CODE:
 RETVAL = abet->hv;
OUTPUT:
 RETVAL

AV *
asArray(gfsmPerlAlphabet *abet)
CODE:
 RETVAL = abet->av;
OUTPUT:
 RETVAL

void
__debug(gfsmPerlAlphabet *abet)
CODE:
{
  SV *hval;
  char *hkey;
  I32  hkeylen, i;
  fprintf(stderr, "gfsmPerlAlphabet::debug(abet=%p ~ %u)\n", abet, GPOINTER_TO_UINT(abet));

  fprintf(stderr, " + hv=%p, refs=%u\n", abet->hv, (unsigned int)SvREFCNT((SV*)abet->hv));
  for (hv_iterinit(abet->hv); (hval=hv_iternextsv(abet->hv, &hkey, &hkeylen)); ) {
    fprintf(stderr, "   - '%s' => labsv=%p  labuv=%u  labrefs=%u\n",
	    hkey, hval, (unsigned int)SvUV(hval), (unsigned int)SvREFCNT(hval));
  }

  fprintf(stderr, " + av=%p , refs=%u\n", abet->av, (unsigned int)SvREFCNT((SV*)abet->av));
  for (i=0; i <= av_len(abet->av); i++) {
    SV **keysvp = av_fetch(abet->av, i, 0);
    fprintf(stderr, "   - %u => ", (unsigned int)i);
    if (keysvp && *keysvp && SvOK(*keysvp)) {
      fprintf(stderr, "keysv=%p  keypv=(%s)  keyrefs=%u\n",
	      *keysvp, SvPV_nolen(*keysvp), (unsigned int)SvREFCNT(*keysvp));
    } else {
      fprintf(stderr, "-undef-\n");
    }
  }
}

##--------------------------------------------------------------
## I/O

gboolean
_load(gfsmAlphabet *abet, FILE *f)
PREINIT:
 gfsmError *err=NULL;
CODE:
 RETVAL=gfsm_alphabet_load_file(abet, f, &err);
 if (err && err->message) {
   SV *perlerr = get_sv("Gfsm::Error",TRUE);
   sv_setpv(perlerr, err->message);
   g_error_free(err);
 }
OUTPUT:
 RETVAL

gboolean
_save(gfsmAlphabet *abet, FILE *f)
PREINIT:
 gfsmError *err=NULL;
CODE:
 RETVAL=gfsm_alphabet_save_file(abet, f, &err);
 if (err && err->message) {
   SV *perlerr = get_sv("Gfsm::Error",TRUE);
   sv_setpv(perlerr, err->message);
   g_error_free(err);
 }
OUTPUT:
 RETVAL

##--------------------------------------------------------------
## Automaton Utilities

#gfsmAutomaton *composition_filter(gfsmAlphabet *abet, gfsmSRType srtype)



##--------------------------------------------------------------
## String Utilities

##-- BUGGY (?)
gfsmLabelVector *
string_to_labels(gfsmAlphabet *abet, const char *str, gboolean warn_on_undefined=TRUE, gboolean att_style=FALSE)
CODE:
 RETVAL = gfsm_alphabet_generic_string_to_labels(abet,str,NULL,warn_on_undefined,att_style);
OUTPUT:
 RETVAL
CLEANUP:
 if (RETVAL) g_ptr_array_free(RETVAL,TRUE);


##-- BUGGY (?)
char *
labels_to_string(gfsmAlphabet *abet, gfsmLabelVector *labels, gboolean warn_on_undefined=TRUE, gboolean att_style=FALSE)
CODE:
 RETVAL = gfsm_alphabet_labels_to_string(abet,labels,warn_on_undefined,att_style);
OUTPUT:
 RETVAL
CLEANUP:
 if (RETVAL) g_free(RETVAL);
 if (labels) g_ptr_array_free(labels,TRUE);
