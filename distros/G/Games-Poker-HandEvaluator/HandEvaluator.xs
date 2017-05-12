#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "poker_defs.h"

#include "inlines/eval.h"
#include "deck_std.h"
#include "rules_std.h"

int parse_cards(char *handstr, StdDeck_CardMask* cards) {
  char *p;
  int c = 0;
  int ncards = 0;
  char str[80];

  StdDeck_CardMask_RESET(*cards);
  strcpy(str, handstr);
  p = strtok(str, " ");

  do {
    if (DstringToCard(StdDeck, p, &c) == 0)
      return 0;
    if (!StdDeck_CardMask_CARD_IS_SET(*cards, c)) {
      StdDeck_CardMask_SET(*cards, c);
      ++ncards;
    };
  } while ((p = strtok(NULL, " ")) != NULL);
  return ncards;
}

MODULE = Games::Poker::HandEvaluator		PACKAGE = Games::Poker::HandEvaluator		

int
_evaluate( hand );
    char* hand;
PREINIT:
    StdDeck_CardMask cards;
    int ncards;
CODE:
    ncards = parse_cards(hand, &cards);
    if (ncards) 
        RETVAL = StdDeck_StdRules_EVAL_N(cards, ncards);
    else
        RETVAL = 0;
OUTPUT:
    RETVAL

char*
handval( hval )
    int hval;
PREINIT:
  char buf[80];
  int n;
CODE:
  StdRules_HandVal_toString(hval, buf);
  RETVAL = buf; /* Hopefully Perl copies this... */
OUTPUT:
  RETVAL
