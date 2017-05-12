#ifndef _TAGSTACK_H
#define _TAGSTACK_H	1

struct tagstack_entry {
  int tag;		/* code of tag */
  int value;		/* if (true/false) - used in else */
  int vcontext;		/* visibility context of the tag (visible/unvisible) */
  const char* position;	/* start of tag; useful for loops */
};

static 
void tagstack_init(struct tagstack* tagstack);
static 
void tagstack_free(struct tagstack* tagstack);
static 
void tagstack_push(struct tagstack* tagstack, struct tagstack_entry);
static 
struct tagstack_entry tagstack_pop(struct tagstack* tagstack, int* is_underflow);
INLINE
static 
struct tagstack_entry* tagstack_top(const struct tagstack* tagstack);
INLINE
static 
int tagstack_notempty(const struct tagstack* tagstack);

#endif /* tagstack.h */

/*
 * Local Variables:
 * mode: c 
 * End: 
 */
