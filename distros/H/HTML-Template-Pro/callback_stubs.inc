/* 
 * File: callback_stubs.c
 * Author: Igor Vlasenko <vlasenko@imath.kiev.ua>
 * Created: Tue Jul 14 22:47:11 2009
 */

#include "pstring.h"
#include "pbuffer.h"

struct builtin_writer_state {
  size_t size;
  pbuffer* bufptr;
};


/* writer_functype stub */
/* endnext points on next character to end of interval as in c++ */
static void BACKCALL stub_write_chars_to_stdout (ABSTRACT_WRITER* none,const char* begin, const char* endnext) {
  if (endnext==begin) return;
  if (0==fwrite(begin, sizeof(char), endnext-begin, stdout)) {
    tmpl_log(TMPL_LOG_ERROR,"find_file_func stub: can't fwrite to stdout\n");
  }
}

/* writer_functype stub */
/* endnext points at the character next to the end of the interval */
static void BACKCALL stub_write_chars_to_pbuffer (ABSTRACT_WRITER* state,const char* begin, const char* endnext) {
  size_t addlen = endnext-begin;
  size_t oldlen;
  pbuffer* pbuf;
  if (addlen==0) return;
  oldlen = ((struct builtin_writer_state*) state)->size;
  pbuf = ((struct builtin_writer_state*) state)->bufptr;
  pbuffer_resize(pbuf, oldlen + addlen + 1);
  memcpy(pbuffer_string(pbuf) + oldlen, begin, addlen);
  ((struct builtin_writer_state*) state)->size += addlen;
}

static ABSTRACT_USERFUNC* BACKCALL stub_is_expr_userfnc_func (ABSTRACT_FUNCMAP* af, PSTRING name) {
  tmpl_log(TMPL_LOG_DEBUG,"is_expr_userfnc_func stub: EXPR is not initialized properly. user func dispatcher was not supplied.\n");
  return NULL;
}

static PSTRING BACKCALL stub_load_file_func (ABSTRACT_FILTER* none, const char* filename) {
  tmpl_log(TMPL_LOG_ERROR,"load_file_func stub: callback function for filters was not specified.");
  return mmap_load_file(filename);
}

static int BACKCALL stub_unload_file_func (ABSTRACT_FILTER* none, PSTRING memarea) {
  tmpl_log(TMPL_LOG_ERROR,"unload_file_func stub: callback function for filters was not specified.");
  return mmap_unload_file(memarea);
}

static int BACKCALL stub_get_ABSTRACT_ARRAY_length_func (ABSTRACT_DATASTATE* none1, ABSTRACT_ARRAY* none) {
  return -1; /* treat all arrays as arrays of undefined length */
}


/*
 *  Local Variables:
 *  mode: c
 *  End:
 */
