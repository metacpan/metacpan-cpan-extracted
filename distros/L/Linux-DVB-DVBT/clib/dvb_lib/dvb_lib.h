#ifndef DVB_LIB
#define DVB_LIB

#include <linux/dvb/frontend.h>
#include <linux/dvb/dmx.h>

#include "dvb_struct.h"
#include "dvb_tune.h"
#include "dvb_epg.h"
#include "dvb_scan.h"
#include "dvb_error.h"
#include "dvb_stream.h"

#include "list.h"


/* ----------------------------------------------------------------------- */
// MACROS
/* ----------------------------------------------------------------------- */

#define DVB_FN_START(name)	\
char *_name="name" ; \
if (dvb_debug>1) _fn_start(_name) ;

#define DVB_FN_END(err)	\
if (dvb_debug>1) _fn_end(_name, err) ;

#define UNSET          (-1U)
#define DIMOF(array)   (sizeof(array)/sizeof(array[0]))
#define SDIMOF(array)  ((signed int)(sizeof(array)/sizeof(array[0])))
#define GETELEM(array,index,default) \
	(index < sizeof(array)/sizeof(array[0]) ? array[index] : default)


/* ----------------------------------------------------------------------- */
// CONSTANTS
/* ----------------------------------------------------------------------- */

#define MAX_ADAPTERS	16
#define MAX_FRONTENDS	16


/* ----------------------------------------------------------------------- */
// FUNCTIONS
/* ----------------------------------------------------------------------- */

int setNonblocking(int fd) ;

/* ----------------------------------------------------------------------- */
// PERL INTERFACE
/* ----------------------------------------------------------------------- */

struct devinfo * dvb_probe_frontend(unsigned adap, unsigned fe, int debug) ;

unsigned long long get_free_space(const char *path) ;

#endif
