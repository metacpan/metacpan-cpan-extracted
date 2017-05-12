/* tools.h */

#ifndef __TOOLS_H
#define __TOOLS_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "common.h"
#include "hash.h"
#include "list.h"

void tools_show_used( void );
void tools_reset_counters( void );
void tools_hook_runops( void );

#endif                          /* __TOOLS_H */
