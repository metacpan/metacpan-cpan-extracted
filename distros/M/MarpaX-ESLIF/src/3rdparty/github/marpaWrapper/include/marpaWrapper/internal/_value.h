#ifndef MARPAWRAPPER_INTERNAL_VALUE_H
#define MARPAWRAPPER_INTERNAL_VALUE_H

#include <stddef.h>
#include "marpaWrapper/value.h"
#include "marpa.h"

struct marpaWrapperValue {
  marpaWrapperRecognizer_t     *marpaWrapperRecognizerp;
  marpaWrapperValueOption_t     marpaWrapperValueOption;
  Marpa_Bocage                  marpaBocagep;
  Marpa_Order                   marpaOrderp;
  Marpa_Tree                    marpaTreep;
  Marpa_Value                   marpaValuep;
};

#endif /* MARPAWRAPPER_INTERNAL_VALUE_H */
