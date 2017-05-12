#ifndef DVB_SCAN
#define DVB_SCAN


#include "dvb_tune.h"
#include "dvb_debug.h"

#include "dvb_tune.h"
#include "dvb_epg.h"
#include "dvb_lib.h"

#include "parse-mpeg.h"


/* ----------------------------------------------------------------------------- */
/* structs & prototypes                                                          */


struct dvbmon {
    int                 verbose;
    int                 tabdebug;
    int                 timeout;
    int                 tabfds;
    int                 tablimit;
    struct dvb_state    *dvb;
    struct psi_info     *info;

    struct list_head    tables;
    struct list_head    versions;
    struct list_head    callbacks;
};


/* ----------------------------------------------------------------------- */
//struct dvbmon* dvbmon_init(struct dvb_state *dvb, int verbose,
//			   int o_nit, int o_sdt, int pmts);

void dvbmon_fini(struct dvbmon* dm);

struct dvbmon *dvb_scan_freqs(struct dvb_state *dvb, int verbose) ;

#endif
