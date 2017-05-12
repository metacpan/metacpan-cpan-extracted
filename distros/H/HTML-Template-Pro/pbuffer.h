#ifndef _PBUFFER_H
#define _PBUFFER_H	1

#include<stdlib.h>
#include<pabidecl.h>
#include "pstring.h"

typedef struct pbuffer {
  size_t bufsize;
  char*  buffer;
} pbuffer;

#define PBUFFER_MULTIPLICATOR 2

TMPLPRO_LOCAL size_t pbuffer_size(const pbuffer*);
TMPLPRO_LOCAL void   pbuffer_preinit(pbuffer* pBuffer);
TMPLPRO_LOCAL char*  pbuffer_init(pbuffer*);
TMPLPRO_LOCAL char*  pbuffer_init_as(pbuffer* pBuffer,size_t size);
TMPLPRO_LOCAL char*  pbuffer_string(const pbuffer*);
TMPLPRO_LOCAL char*  pbuffer_resize(pbuffer*, size_t size);
TMPLPRO_LOCAL void   pbuffer_free(pbuffer*);
TMPLPRO_LOCAL void pbuffer_fill_from_pstring(pbuffer* pBuffer, PSTRING pstr);
TMPLPRO_LOCAL void pbuffer_swap(pbuffer* buf1, pbuffer* buf2);

#endif /* pbuffer.h */

/*
 * Local Variables:
 * mode: c
 * End:
 */
