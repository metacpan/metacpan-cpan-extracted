#ifndef _PROSTATE_H
#define _PROSTATE_H	1

#include "pbuffer.h"

struct tagstack {
  struct tagstack_entry* entry;
  int pos;
  int depth;
};

struct tmplpro_param;

typedef int boolval;

struct tmplpro_state {
  boolval  is_visible;
  const char* top;
  const char* next_to_end;
  const char* last_processed_pos;
  const char* cur_pos;
  struct tmplpro_param* param;
  /* current tag */
  int   tag;
  boolval  is_tag_closed;
  boolval  is_tag_commented;
  const char* tag_start;

  /* internal buffers */
  /* tag stack */
  struct tagstack tag_stack;

  /* expr string buffers; used to unescape pstring args and for num -> string */
  pbuffer expr_left_pbuffer;
  pbuffer expr_right_pbuffer;
};

extern TMPLPRO_LOCAL void log_state(struct tmplpro_state*, int level, const char *fmt, ...) FORMAT_PRINTF(3,4);

#endif /* prostate.h */

/* 
 * Local Variables:
 * mode: c 
 * End: 
 */
