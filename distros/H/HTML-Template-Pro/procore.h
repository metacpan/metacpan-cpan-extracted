#include "pstring.h"
#include "tmpllog.h"
#include "pabstract.h"

struct tmplpro_param;

static int tmplpro_exec_tmpl_filename (struct tmplpro_param* ProParams,const char* filename);
static int tmplpro_exec_tmpl_scalarref (struct tmplpro_param* ProParams, PSTRING memarea);

static const char* const errlist[] = { 
  "ok",
  "invalid argument",
  "file not found",
  "can't open file",
  "syntax error in template",
  "not enough memory (allocation error)",
  "",
  "",
  ""
};

/* 
 * Local Variables:
 * mode: c 
 * End: 
 */
