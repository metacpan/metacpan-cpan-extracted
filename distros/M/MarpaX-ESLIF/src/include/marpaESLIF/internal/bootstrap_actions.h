#ifndef MARPAESLIF_INTERNAL_BOOTSTRAP_ACTIONS_H
#define MARPAESLIF_INTERNAL_BOOTSTRAP_ACTIONS_H

#include <marpaESLIF.h>

/* This file contain the declaration of all bootstrap actions, i.e. the ESLIF grammar itself */
/* This is an example of how to use the API */

static marpaESLIFValueRuleCallback_t   _marpaESLIF_bootstrap_ruleActionResolver(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, char *actions);
static marpaESLIFValueFreeCallback_t   _marpaESLIF_bootstrap_freeActionResolver(void *userDatavp, marpaESLIFValue_t *marpaESLIFValuep, char *actions);

#endif /* MARPAESLIF_INTERNAL_BOOTSTRAP_ACTIONS_H */

