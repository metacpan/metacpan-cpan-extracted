#/*-*- Mode: C -*- */

MODULE = Gfsm		PACKAGE = Gfsm::Automaton           PREFIX = gfsm_automaton

##=====================================================================
## Automata: Algebra
##=====================================================================

##-- disable perl prototypes
PROTOTYPES: DISABLE

#/** Set optional */
void
gfsm_automaton_optional(gfsmAutomaton *fsm)

#/** Compute transitive (@is_plus!=FALSE) or reflexive+transitive (@is_plus==FALSE)
# *  closure of @fsm.
# *  Destructively alters @fsm1.
# */
void
gfsm_automaton_closure(gfsmAutomaton *fsm, gboolean is_plus=FALSE)

#/** Compute @n ary closure of @fsm.
# *  \returns @fsm
# */
void
gfsm_automaton_n_closure(gfsmAutomaton *fsm, guint n)


#//------------------------------

#/**
# * Compute the complement of @fsm with respect to its own alphabet (alph==NULL),
# * or wrt. alph!=NULL, which should contain all of the lower-labels from @fsm.
# * Destructively alters @fsm.
# * \returns @fsm
# */
void
gfsm_automaton_complement(gfsmAutomaton *fsm, gfsmAlphabet *alph=NULL)
CODE:
 if (alph) { gfsm_automaton_complement_full(fsm,alph); }
 else      { gfsm_automaton_complement(fsm); }

#/**
# * Complete the lower side of automaton @fsm with respect to the alphabet @alph
# * by directing "missing" arcs to a new sink-state.  Destructively
# * alters @fsm.
# * \returns Id of the new sink state.
# */
gfsmStateId
gfsm_automaton_complete(gfsmAutomaton  *fsm, gfsmAlphabet *alph)
CODE:
 gfsm_automaton_complete(fsm,alph,&RETVAL);
OUTPUT:
 RETVAL


#//------------------------------

#/** Compute the composition of two transducers @fsm1 and @fsm2.
# *  Pseudo-destructive on @fsm1.
# *  \returns @fsm1.
# */
void
gfsm_automaton_compose(gfsmAutomaton *fsm1, gfsmAutomaton *fsm2)

#/** Compute the composition of two transducers @fsm1 and @fsm2 
# *  into the transducer @composition.
# *  \param fsm1 Lower-middle transducer
# *  \param fsm2 Middle-upper transducer
# *
# *  \seealso Mohri, Pereira, and Riley (1996) "Weighted Automata in Text and Speech Processing",
# *    ECAI '96, John Wiley & Sons, Ltd.
# *
# *  \returns composition automaton
# */
void
gfsm_automaton_compose_full(gfsmAutomaton *fsm1, gfsmAutomaton *fsm2, gfsmAutomaton *composition)
CODE:
 gfsm_automaton_compose_full(fsm1,fsm2, composition,NULL);

#//------------------------------

#/** Append @fsm2 onto the end of @fsm1 @n times.  \returns @fsm1 */
void
gfsm_automaton_concat(gfsmAutomaton *fsm1, gfsmAutomaton *fsm2, guint n=1)
CODE:
 gfsm_automaton_n_concat(fsm1,fsm2,n);


#//------------------------------
#/** Determinise @nfa to @dfa. 
# *  \note weights on epsilon-arcs are probably not handled correctly.
# */
void
gfsm_automaton_determinize_full(gfsmAutomaton *nfa, gfsmAutomaton *dfa)

#/** Determinise @nfa pseudo-destructively.
# *  \note weights on epsilon-arcs are probably not handled correctly.
# */
void
gfsm_automaton_determinize(gfsmAutomaton *fsm)

#//------------------------------

#/** Remove language of acceptor @fsm2 from acceptor @fsm1.
# *  Pseudo-destructively alters @fsm1.
# *  Really just an alias for intersect_full(fsm1,fsm2,NULL)
# *  \returns @fsm1
# */
void
gfsm_automaton_difference(gfsmAutomaton *fsm1, gfsmAutomaton *fsm2)

#/** Compute difference of acceptors (@fsm1-@fsm2) into acceptor @diff,
# *  which may be passed as NULL to implicitly create a new automaton.
# *  Really just an alias for intersect_full(fsm1,complement(clone(fsm2)),diff).
# *  \returns (possibly new) difference automaton @diff
# */
void
gfsm_automaton_difference_full(gfsmAutomaton *fsm1, gfsmAutomaton *fsm2, gfsmAutomaton *diff)


#//------------------------------
#/** Compute the intersection of two acceptors @fsm1 and @fsm2 (lower-side intersection).
# *  Pseudo-destructive on @fsm1.
# *  \returns @fsm1.
# */
void
gfsm_automaton_intersect(gfsmAutomaton *fsm1, gfsmAutomaton *fsm2)

#/** Compute the intersection of two acceptors @fsm1 and @fsm2 
# *  into the acceptor @intersect, which may be passed as NULL to create a new FSM.
# *  @spenum stores a mapping from (@fsm1,@fsm2) StatePairs to @fsm StateIds,
# *  if it is passed as NULL, a temporary hash will be created.
# *  \returns @fsm3.
# */
void
gfsm_automaton_intersect_full(gfsmAutomaton *fsm1, gfsmAutomaton *fsm2, gfsmAutomaton *intersect)
CODE:
 gfsm_automaton_intersect_full(fsm1,fsm2,intersect,NULL);

#//------------------------------
#/** Minimize an automaton, treating transducers as pair-acceptors.
# *  Pseudo-destructive on @fsm.
# */
void
gfsm_automaton_minimize(gfsmAutomaton *fsm, gboolean rmeps = TRUE)
CODE:
 gfsm_automaton_minimize_full(fsm, rmeps);

#//------------------------------
#/** Compact an automaton by encoding, minimizing, and decoding.
# *  Pseudo-destructive on @fsm.
# */
void
gfsm_automaton_compact(gfsmAutomaton *fsm, gboolean rmeps = TRUE)
CODE:
 gfsm_automaton_compact_full(fsm, rmeps);

#//------------------------------
#/** Invert upper and lower labels of an FSM */
void
gfsm_automaton_invert(gfsmAutomaton *fsm)

#//------------------------------
#/** Compute Cartesian product of acceptors @fsm1 and @fsm2.
# *  Destructively alters @fsm1.
# */
void
gfsm_automaton_product(gfsmAutomaton *fsm1, gfsmAutomaton *fsm2)

#//------------------------------
#/** Compute Cartesian product of acceptors @fsm1 and @fsm2.
# *  Destructively alters both @fsm1 and @fsm2
# */
void
gfsm_automaton_product2(gfsmAutomaton *fsm1, gfsmAutomaton *fsm2)
CODE:
 gfsm_automaton_product2(fsm1,fsm2);

#//-- alias
void
__product(gfsmAutomaton *fsm1, gfsmAutomaton *fsm2)
CODE:
 gfsm_automaton_product2(fsm1,fsm2);


#//------------------------------
#/** Project one "side" (lower or upper) of @fsm */
void
gfsm_automaton_project(gfsmAutomaton *fsm, gfsmLabelSide which)

#//------------------------------
#/** Replace label-pair \a (lo,hi) with \a fsm2 in \a fsm1.
# */
void
gfsm_automaton_replace(gfsmAutomaton *fsm1, gfsmLabelVal lo, gfsmLabelVal hi, gfsmAutomaton *fsm2)

#//------------------------------
#/** Insert automaton \a fsm2 into \a fsm1 between states \a q1from and \a q1to with weight \a w.
# */
void
gfsm_automaton_insert_automaton(gfsmAutomaton *fsm1, gfsmStateId q1from, gfsmStateId q1to, gfsmAutomaton *fsm2, gfsmWeight w)

#//------------------------------
#/** Remove unreachable states from @fsm.  \returns @fsm */
void
gfsm_automaton_connect(gfsmAutomaton *fsm)

#//------------------------------
#/** Reverse an @fsm. \returns @fsm */
void
gfsm_automaton_reverse(gfsmAutomaton *fsm)

#//------------------------------
#/** Remove epsilon arcs from @fsm.  \returns @fsm */
void
gfsm_automaton_rmepsilon(gfsmAutomaton *fsm)

#//------------------------------
#/** Assign the union of @fsm1 and @fsm2 to @fsm1. \returns @fsm1 */
void
gfsm_automaton_union(gfsmAutomaton *fsm1, gfsmAutomaton *fsm2)


