#/*-*- Mode: C -*- */

MODULE = Gfsm		PACKAGE = Gfsm::ArcIter           PREFIX = gfsm_arciter_

##=====================================================================
## Constructors etc.
##=====================================================================

##-- disable perl prototypes
PROTOTYPES: DISABLE

##--------------------------------------------------------------
## Constructor: new()
gfsmArcIter *
new(char *CLASS, gfsmAutomaton *fsm=NULL, gfsmStateId stateid=gfsmNoState)
CODE:
 RETVAL = gfsm_slice_new(gfsmArcIter);
 if (fsm && stateid != gfsmNoState) { gfsm_arciter_open(RETVAL, fsm, stateid); }
 else                               { gfsm_arciter_close(RETVAL); }
OUTPUT:
 RETVAL

##--------------------------------------------------------------
## Constructor: clone() (full copy)
gfsmArcIter *
clone(gfsmArcIter *ai)
PREINIT:
 char *CLASS=HvNAME(SvSTASH(SvRV(ST(0))));  // needed by typemap
CODE:
 RETVAL = gfsm_arciter_clone(ai);
OUTPUT:
 RETVAL


##--------------------------------------------------------------
## Destructor: DESTROY()
void
DESTROY(gfsmArcIter *ai)
CODE:
 if (ai) {
   gfsm_arciter_close(ai);
   gfsm_slice_free(gfsmArcIter,ai);
 }


##--------------------------------------------------------------
## Open/close
void
gfsm_arciter_open(gfsmArcIter *aip, gfsmAutomaton *fsm, gfsmStateId stateid)

void
gfsm_arciter_close(gfsmArcIter *aip)

#//-- reset to 1st outgoing arc from the selected state
void
gfsm_arciter_reset(gfsmArcIter *aip)


#/*======================================================================
# * Methods: Arc Access & manipulation
# */
gboolean
gfsm_arciter_ok(gfsmArcIter *aip)

void
gfsm_arciter_remove(gfsmArcIter *aip)

##//-- get/set target state
gfsmStateId
target(gfsmArcIter *aip, ...)
PREINIT:
 gfsmArc *a=NULL;
CODE:
 if ( (a=gfsm_arciter_arc(aip)) ) {
   if (items > 1) { a->target = (gfsmStateId)SvIV(ST(1)); }
   RETVAL = a->target;
 } else {
   RETVAL = gfsmNoState;
 }
OUTPUT:
 RETVAL

##//-- get/set lower label
gfsmLabelId
lower(gfsmArcIter *aip, ...)
PREINIT:
 gfsmArc *a=NULL;
CODE:
 if ( (a=gfsm_arciter_arc(aip)) ) {
   if (items > 1) { a->lower = (gfsmLabelId)SvIV(ST(1)); }
   RETVAL = a->lower;
 } else {
   RETVAL = gfsmNoLabel;
 }
OUTPUT:
 RETVAL

##//-- get/set upper label
gfsmLabelId
upper(gfsmArcIter *aip, ...)
PREINIT:
 gfsmArc *a=NULL;
CODE:
 if ( (a=gfsm_arciter_arc(aip)) ) {
   if (items > 1) { a->upper = (gfsmLabelId)SvIV(ST(1)); }
   RETVAL = a->upper;
 } else {
   RETVAL = gfsmNoLabel;
 }
OUTPUT:
 RETVAL

##//-- get/set arc weight
gfsmWeight
weight(gfsmArcIter *aip, ...)
PREINIT:
 gfsmArc *a=NULL;
CODE:
 if ( (a=gfsm_arciter_arc(aip)) ) {
   if (items > 1) { gfsm_perl_weight_setfloat(a->weight, (gfloat)SvNV(ST(1))); }
   RETVAL = a->weight;
 } else {
   gfsm_perl_weight_setfloat(RETVAL,0); /* HACK */
 }
OUTPUT:
 RETVAL


#/*======================================================================
# * Methods: Arc iterators: Traversal
# */
void
gfsm_arciter_next(gfsmArcIter *aip)

#/** Position an arc-iterator to the next arc with lower label @lo */
void
gfsm_arciter_seek_lower(gfsmArcIter *aip, gfsmLabelVal lo)

#/** Position an arc-iterator to the next arc with upper label @hi */
void
gfsm_arciter_seek_upper(gfsmArcIter *aip, gfsmLabelVal hi)

#/** Position an arc-iterator to the next arc
# *  with lower label @lo and upper label @hi.
# *  If either @lo or @hi is gfsmNoLabel, the corresponding label(s)
# *  will be ignored.
# */
void
gfsm_arciter_seek_both(gfsmArcIter *aip, gfsmLabelVal lo, gfsmLabelVal hi)
