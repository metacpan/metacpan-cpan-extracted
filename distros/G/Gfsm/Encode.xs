#/*-*- Mode: C -*- */

MODULE = Gfsm		PACKAGE = Gfsm::Automaton           PREFIX = gfsm_automaton

##=====================================================================
## Automata: Encoding + Decoding
##=====================================================================

##-- disable perl prototypes
PROTOTYPES: DISABLE

#//------------------------------
#/** Destructively encode an automaton using specified key */
void
gfsm_automaton_encode(gfsmAutomaton *fsm, gfsmAutomaton *keyfsm, gboolean encode_labels=TRUE, gboolean encode_weights=TRUE)
PREINIT:
  gfsmArcLabelKey *key=NULL;
CODE:
  key = gfsm_arclabel_fsm_to_key(keyfsm,NULL);
  gfsm_automaton_encode(fsm, key, encode_labels, encode_weights);
  gfsm_arclabel_key_to_fsm(key,keyfsm);
  if (key) gfsm_arclabel_key_free(key);

#//------------------------------
#/** Destructively decode an automaton using specified key */
void
gfsm_automaton_decode(gfsmAutomaton *fsm, gfsmAutomaton *keyfsm, gboolean decode_labels=TRUE, gboolean decode_weights=TRUE)
PREINIT:
  gfsmArcLabelKey *key=NULL;
CODE:
  key = gfsm_arclabel_fsm_to_key(keyfsm,NULL);
  gfsm_automaton_decode(fsm, key, decode_labels, decode_weights);
  if (key) gfsm_arclabel_key_free(key);
