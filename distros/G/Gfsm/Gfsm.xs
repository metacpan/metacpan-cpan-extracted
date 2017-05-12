/*-*- Mode: C -*- */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "thread.h"

#include <gfsm.h>
#include "GfsmPerl.h"

MODULE = Gfsm		PACKAGE = Gfsm

##=====================================================================
## Gfsm (bootstrap)
##=====================================================================
BOOT:
 {
   gfsm_perl_init();
 } 

##=====================================================================
## Gfsm (Debug)
##=====================================================================

#ifdef GFSMDEBUG

int __refcnt(SV *sv)
CODE:
 if (sv && SvOK(sv)) {
   RETVAL = SvREFCNT(sv);
 } else {
   XSRETURN_UNDEF;
 }
OUTPUT:
 RETVAL

#endif


##=====================================================================
## Gfsm (Constants)
##=====================================================================
INCLUDE: Constants.xs

##=====================================================================
## Gfsm::Semiring
##=====================================================================
INCLUDE: Semiring.xs

##=====================================================================
## Gfsm::Alphabet
##=====================================================================
INCLUDE: Alphabet.xs

##=====================================================================
## Gfsm::Automaton
##=====================================================================
INCLUDE: Automaton.xs
INCLUDE: ArcIter.xs
INCLUDE: Algebra.xs
INCLUDE: Arith.xs
INCLUDE: Encode.xs
INCLUDE: Lookup.xs
INCLUDE: Paths.xs
INCLUDE: Trie.xs
INCLUDE: StateSort.xs

##=====================================================================
## Gfsm::Automaton::Indexed
##=====================================================================
INCLUDE: Indexed.xs
