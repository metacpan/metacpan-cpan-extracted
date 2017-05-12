#include "prostate.h"
#include "tmpllog.h"

TMPLPRO_LOCAL void log_state(struct tmplpro_state* state, int level, const char *fmt, ...) 
{
    va_list vl;
    char* masterpath=state->param->masterpath;
    va_start(vl, fmt);
    tmpl_log(level, "HTML::Template::Pro:");
    if (masterpath != NULL) {
      tmpl_log(level, "%s:",masterpath);
    }
    if (state->tag !=HTML_TEMPLATE_NO_TAG) {
      tmpl_log(level, "HTML::Template::Pro:in %sTMPL_%s at pos " MOD_TD ": ",
	  (state->is_tag_closed ? "/" : ""), 
	   (state->tag>HTML_TEMPLATE_BAD_TAG && state->tag <=HTML_TEMPLATE_LAST_TAG_USED) ? TAGNAME[state->tag] : "", 
	   TO_PTRDIFF_T(state->tag_start - state->top));
    }
    tmpl_vlog(level, fmt, vl);
    va_end(vl);
}

/* 
 * Local Variables:
 * mode: c 
 * End: 
 */
