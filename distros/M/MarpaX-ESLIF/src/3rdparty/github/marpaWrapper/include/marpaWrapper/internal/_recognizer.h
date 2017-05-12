#ifndef MARPAWRAPPER_INTERNAL_RECOGNIZER_H
#define MARPAWRAPPER_INTERNAL_RECOGNIZER_H

#include <stddef.h>
#include "marpaWrapper/recognizer.h"
#include "marpa.h"

typedef struct marpaWrapperRecognizerAlternative {
  int symboli;
  int valuei;
  int lengthi;
} marpaWrapperRecognizerAlternative_t;

typedef enum marpaWrapperRecognizerTreeMode {
  MARPAWRAPPERRECOGNIZERTREEMODE_NA = 0,
  MARPAWRAPPERRECOGNIZERTREEMODE_TREE,
  MARPAWRAPPERRECOGNIZERTREEMODE_FOREST
} marpaWrapperRecognizerTreeMode_t;

struct marpaWrapperRecognizer {
  Marpa_Recognizer               marpaRecognizerp;
  marpaWrapperGrammar_t         *marpaWrapperGrammarp;
  marpaWrapperRecognizerOption_t marpaWrapperRecognizerOption;

  /* Storage of symbols for expected terminals */
  size_t                        sizeSymboll;        /* Allocated size */
  size_t                        nSymboll;           /* Used size      */
  int                          *symbolip;

  /* Progress storage */
  size_t                               sizeProgressl; /* Allocated size */
  size_t                               nProgressl;    /* Used size      */
  marpaWrapperRecognizerProgress_t    *progressp;

  marpaWrapperRecognizerTreeMode_t     treeModeb;     /* Indicates that we are already in tree mode */
  short                                haveVariableLengthTokenb; /* Used in forest mode */
};

#endif /* MARPAWRAPPER_INTERNAL_RECOGNIZER_H */
