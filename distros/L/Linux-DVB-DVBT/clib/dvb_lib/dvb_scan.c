#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <ctype.h>
#include <fcntl.h>
#include <inttypes.h>
#include <sys/poll.h>

#include <sys/time.h>
#include <sys/ioctl.h>


#include "tables/si_structs.h"

#include "dvb_scan.h"
#include "dvb_debug.h"

#if 0
/* ----------------------------------------------------------------------- */
/* map vdr config file numbers to enums                                    */

#define VDR_MAX 999

static fe_bandwidth_t fe_vdr_bandwidth[] = {
    [ 0 ... VDR_MAX ] = BANDWIDTH_AUTO,
    [ 8 ]             = BANDWIDTH_8_MHZ,
    [ 7 ]             = BANDWIDTH_7_MHZ,
    [ 6 ]             = BANDWIDTH_6_MHZ,
};

static fe_code_rate_t fe_vdr_rates[] = {
    [ 0 ... VDR_MAX ] = FEC_AUTO,
    [ 12 ]            = FEC_1_2,
    [ 23 ]            = FEC_2_3,
    [ 34 ]            = FEC_3_4,
    [ 45 ]            = FEC_4_5,
    [ 56 ]            = FEC_5_6,
    [ 67 ]            = FEC_6_7,
    [ 78 ]            = FEC_7_8,
    [ 89 ]            = FEC_8_9,
};

static fe_modulation_t fe_vdr_modulation[] = {
    [ 0 ... VDR_MAX ] = QAM_AUTO,
    [  16 ]           = QAM_16,
    [  32 ]           = QAM_32,
    [  64 ]           = QAM_64,
    [ 128 ]           = QAM_128,
    [ 256 ]           = QAM_256,
#ifdef FE_ATSC
    [   8 ]           = VSB_8,
    [   1 ]           = VSB_16,
#endif
};

static fe_transmit_mode_t fe_vdr_transmission[] = {
    [ 0 ... VDR_MAX ] = TRANSMISSION_MODE_AUTO,
    [ 2 ]             = TRANSMISSION_MODE_2K,
    [ 8 ]             = TRANSMISSION_MODE_8K,
};

static fe_guard_interval_t fe_vdr_guard[] = {
    [ 0 ... VDR_MAX ] = GUARD_INTERVAL_AUTO,
    [  4 ]            = GUARD_INTERVAL_1_4,
    [  8 ]            = GUARD_INTERVAL_1_8,
    [ 16 ]            = GUARD_INTERVAL_1_16,
    [ 32 ]            = GUARD_INTERVAL_1_32,
};

static fe_hierarchy_t fe_vdr_hierarchy[] = {
    [ 0 ... VDR_MAX ] = HIERARCHY_AUTO,
    [ 0 ]             = HIERARCHY_NONE,
    [ 1 ]             = HIERARCHY_1,
    [ 2 ]             = HIERARCHY_2,
    [ 4 ]             = HIERARCHY_4,
};
#endif
/* ----------------------------------------------------------------------- */



/* ----------------------------------------------------------------------------- */
/* structs & prototypes                                                          */

#define FALSE	0
#define TRUE	!FALSE

struct table {
    struct list_head    next;
    char                *name;
    int                 pid;
    int                 sec;
    int                 fd;
    int                 once;
    int                 done;
};

struct version {
    struct list_head    next;
    char                *name;
    int                 id;
    int                 version;
};

typedef void (*dvbmon_notify)(struct psi_info *info, int event,
			      int tsid, int pnr, void *data);

#define DVBMON_EVENT_SWITCH_TS    1
#define DVBMON_EVENT_UPDATE_TS    2
#define DVBMON_EVENT_UPDATE_PR    3
#define DVBMON_EVENT_DESTROY     99

//struct dvbmon* dvbmon_init(struct dvb_state *dvb, int verbose,
//			   int o_nit, int o_sdt, int pmts);
void dvbmon_refresh(struct dvbmon* dm);
void dvbmon_add_callback(struct dvbmon* dm, dvbmon_notify func, void *data);
void dvbmon_del_callback(struct dvbmon* dm, dvbmon_notify func, void *data);


struct callback {
    struct list_head    next;
    dvbmon_notify       func;
    void                *data;
};

static void table_add(struct dvbmon *dm, char *name, int pid, int sec,
		      int oneshot);
static void table_open(struct dvbmon *dm, struct table *tab);
static void table_refresh(struct dvbmon *dm, struct table *tab);
static void table_close(struct dvbmon *dm, struct table *tab);
static void table_del(struct dvbmon *dm, int pid, int sec);
static void table_next(struct dvbmon *dm);

/* ----------------------------------------------------------------------- */
// DEBUG
/* ----------------------------------------------------------------------- */


/* ----------------------------------------------------------------------- */
static void print_streams(struct dvbmon *dvbmon)
{
struct psi_stream *stream;
struct list_head   *item;

	fprintf(stderr, "\n\n\n==STREAMS==\n\n") ;
    list_for_each(item,&dvbmon->info->streams)
    {
    	stream = list_entry(item, struct psi_stream, next);
    	print_stream(stream) ;
    }
}


/* ----------------------------------------------------------------------- */
static void print_programs(struct dvbmon *dvbmon)
{
struct psi_program *program ;
struct list_head   *item;

	fprintf(stderr, "\n==PROGRAMS==\n\n") ;
    if (dvb_debug >= 25)
    {
    	fprintf(stderr, " &dvbmon->info->programs=>%p [next=%p, prev=%p]\n", &dvbmon->info->programs, dvbmon->info->programs.next, dvbmon->info->programs.prev) ;
    }
    list_for_each(item,&dvbmon->info->programs)
    {
	    if (dvb_debug >= 25)
	    {
	    	fprintf(stderr, "[item=%p next=%p, prev=%p] ", item, item->next, item->prev) ;
	    }
        program = list_entry(item, struct psi_program, next);
        print_program(program) ;
    }
	fprintf(stderr, "\n============\n\n") ;
}




/* ------------------------------------------------------------------------ */
// CALLBACKS
/* ------------------------------------------------------------------------ */

/* ------------------------------------------------------------------------ */

/*
4.4.2 Terrestrial delivery systems
For terrestrial delivery systems bandwidth within a single transmitted TS is a valuable resource and in order to
safeguard the bandwidth allocated to the primary services receivable from the actual multiplex, the following minimum
repetition rates are specified in order to reflect the need to impose a limit on the amount of available bandwidth used for
this purpose:
a) all sections of the NIT shall be transmitted at least every 10 s;
b) all sections of the BAT shall be transmitted at least every 10 s, if present;
c) all sections of the SDT for the actual multiplex shall be transmitted at least every 2 s;
d) all sections of the SDT for other TSs shall be transmitted at least every 10 s if present;
e) all sections of the EIT Present/Following Table for the actual multiplex shall be transmitted at least every 2 s;
f) all sections of the EIT Present/Following Tables for other TSs shall be transmitted at least every 20 s if
present.

The repetition rates for further EIT tables will depend greatly on the number of services and the quantity of related SI
information. The following transmission intervals should be followed if practicable but they may be increased as the use
of EIT tables is increased. The times are the consequence of a compromise between the acceptable provision of data to a
viewer and the use of multiplex bandwidth.

a) all sections of the EIT Schedule table for the first full day for the actual TS, shall be transmitted at least every
10 s, if present;
b) all sections of the EIT Schedule table for the first full day for other TSs, shall be transmitted at least every
60 s, if present;
c) all sections of the EIT Schedule table for the actual TS, shall be transmitted at least every 30 s, if present;
d) all sections of the EIT Schedule table for other TSs, shall be transmitted at least every 300 s, if present;
e) the TDT and TOT shall be transmitted at least every 30 s.

*/

/* ----------------------------------------------------------------------------- */

//PAT								0x00 500 ms
//TSDT								0x02 10 s [1]
//NIT actual						0x10 10s / 25 ms
//NIT other							0x10 10s / 25 ms
//SDT actual						0x11 2s / 25 ms
//SDT other							0x11 10s / 25 ms
//BAT								0x11 10s / 25 ms
//EIT actual present-following		0x12 2s / 25 ms [2]
//EIT other present-following		0x12 10s / 25 ms [2]
//TOT								0x14 30s / 25 ms
//TDT								0x14 30s / 25 ms
//PMT								ALL 500 ms

//static int scan_timeout_secs = 20 ;
//static int scan_timeout_secs = 40 ;		// debugging!
static int scan_timeout_secs = 40 ;		// new

//static int nodata_timeout_secs = 15 ;	// should see *something* by then
static int nodata_timeout_secs = 40 ;	// debugging!
//static int nodata_timeout_secs = 20 ;	// new

static int poll_timeout_ms = 1000 ;

static int current;

static void dvbwatch_tty(struct psi_info *info, int event,
			 int tsid, int pnr, void *data)
{
	struct dvbmon *dvbmon = (struct dvbmon *)data ;
    struct psi_program *pr;

    // Uses static global:
    // current

    switch (event)
    {
    case DVBMON_EVENT_SWITCH_TS:
		if (dvbmon->verbose) fprintf(stderr,"  tsid  %5d\n",tsid);
		current = tsid;
		break;
		
    case DVBMON_EVENT_UPDATE_PR:
		break ;
		
    }
}




/* ----------------------------------------------------------------------------- */
// TABLE MANAGEMENT
/* ----------------------------------------------------------------------------- */

/* ----------------------------------------------------------------------------- */
static void table_open(struct dvbmon *dm, struct table *tab)
{
    if (tab->once && (dm->tabfds >= dm->tablimit))
		return;

    tab->fd = dvb_demux_req_section(dm->dvb, -1, tab->pid, tab->sec, 0xff,
				    tab->once, dm->timeout);
    if (-1 == tab->fd)
		return;

    dm->tabfds++;

    if (dm->tabdebug)
		fprintf(stderr,"dvbmon: open:  %s %4d | fd=%d n=%d\n",
			tab->name, tab->pid, tab->fd, dm->tabfds);
}

/* ----------------------------------------------------------------------------- */
static struct table* table_find(struct dvbmon *dm, int pid, int sec)
{
    struct table      *tab;
    struct list_head  *item;

    list_for_each(item,&dm->tables) {
		tab = list_entry(item, struct table, next);
		if (tab->pid == pid && tab->sec == sec)
		    return tab;
    }
    return NULL;
}


/* ----------------------------------------------------------------------------- */
static void table_close(struct dvbmon *dm, struct table *tab)
{
    if (-1 == tab->fd)
	return;

    close(tab->fd);

    tab->fd = -1;
    if (tab->once)
    	tab->done = 1;

    dm->tabfds--;
    if (dm->tabdebug)
	fprintf(stderr,"dvbmon: close: %s %4d | n=%d\n",
		tab->name, tab->pid, dm->tabfds);
}

/* ----------------------------------------------------------------------------- */
static void table_next(struct dvbmon *dm)
{
    struct table      *tab;
    struct list_head  *item;

    list_for_each(item,&dm->tables) {
		tab = list_entry(item, struct table, next);
		if (tab->fd != -1)
		    continue;
		if (tab->done)
		    continue;
		table_open(dm,tab);
		if (dm->tabfds >= dm->tablimit)
		    return;
    }
}

/* ----------------------------------------------------------------------------- */
static void table_add(struct dvbmon *dm, char *name, int pid, int sec,
		      int oneshot)
{
    struct table *tab;

    tab = table_find(dm, pid, sec);
    if (tab)
	return;
    tab = malloc(sizeof(*tab));
    memset(tab,0,sizeof(*tab));
    tab->name = name;
    tab->pid  = pid;
    tab->sec  = sec;
    tab->fd   = -1;
    tab->once = oneshot;
    tab->done = 0;
    list_add_tail(&tab->next,&dm->tables);
    if (dm->tabdebug)
	fprintf(stderr,"dvbmon: add:   %s %4d (0x%02x) | sec=0x%02x once=%d\n",
		tab->name, tab->pid, tab->pid, tab->sec, tab->once);

    table_open(dm,tab);
}

/* ----------------------------------------------------------------------------- */
static void table_del(struct dvbmon *dm, int pid, int sec)
{
    struct table      *tab;

    tab = table_find(dm, pid, sec);
    if (NULL == tab)
	return;
    table_close(dm,tab);

    if (dm->tabdebug)
    	fprintf(stderr,"dvbmon: del:   %s %4d\n", tab->name, tab->pid);
    list_del(&tab->next);
    free(tab);
}

/* ----------------------------------------------------------------------------- */
static void table_refresh(struct dvbmon *dm, struct table *tab)
{
    tab->fd = dvb_demux_req_section(dm->dvb, tab->fd, tab->pid,
				    tab->sec, 0xff, 0, dm->timeout);
    if (-1 == tab->fd) {
		fprintf(stderr,"%s: failed\n",__FUNCTION__);
		list_del(&tab->next);
		free(tab);
		return;
    }
}

/* ----------------------------------------------------------------------------- */
static int table_data_seen(struct dvbmon *dm, char *name, int id, int version)
{
    struct version    *ver;
    struct list_head  *item;
    int seen = 0;

    list_for_each(item,&dm->versions) {
		ver = list_entry(item, struct version, next);
		if (ver->name == name && ver->id == id) {
			if (ver->version == version)
			seen = 1;
			ver->version = version;
			return seen;
		}
    }
    ver = malloc(sizeof(*ver));
    memset(ver,0,sizeof(*ver));
    ver->name    = name;
    ver->id      = id;
    ver->version = version;
    list_add_tail(&ver->next,&dm->versions);

    return seen;
}

/* ----------------------------------------------------------------------------- */
/* ----------------------------------------------------------------------------- */


/* ----------------------------------------------------------------------------- */
struct dvbmon*
dvbmon_init(struct dvb_state *dvb, int verbose, int o_nit, int o_sdt, int pmts)
{
    struct dvbmon *dm;

    dm = malloc(sizeof(*dm));
    memset(dm,0,sizeof(*dm));
    INIT_LIST_HEAD(&dm->tables);
    INIT_LIST_HEAD(&dm->versions);
    INIT_LIST_HEAD(&dm->callbacks);

    dm->verbose  = verbose;
    dm->tabdebug = 0;
    dm->tablimit = 3 + (o_nit ? 1 : 0) + (o_sdt ? 1 : 0) + pmts;
    dm->timeout  = 60;
    dm->dvb      = dvb;
    dm->info     = psi_info_alloc();
    if (dm->dvb) {
		if (dm->verbose>1)
			fprintf(stderr,"dvbmon: hwinit ok\n");

		table_add(dm, "pat",   0x00, 0x00, 0);
		table_add(dm, "nit",   0x10, 0x40, 0);
		table_add(dm, "sdt",   0x11, 0x42, 0);
		if (o_nit)
			table_add(dm, "nit",   0x10, 0x41, 0);
		if (o_sdt)
			table_add(dm, "sdt",   0x11, 0x46, 0);


	} else {
		fprintf(stderr,"dvbmon: hwinit FAILED\n");
    }
    
    if (dvb_debug >= 15)
		dm->tabdebug = 1 ;
    
    return dm;
}

/* ----------------------------------------------------------------------------- */
static void call_callbacks(struct dvbmon* dm, int event, int tsid, int pnr)
{
    struct callback   *cb;
    struct list_head  *item;

    list_for_each(item,&dm->callbacks) {
		cb = list_entry(item, struct callback, next);
		cb->func(dm->info,event,tsid,pnr,cb->data);
    }
}


/* ----------------------------------------------------------------------------- */
void dvbmon_fini(struct dvbmon* dm)
{
    struct list_head  *item, *safe;
    struct version    *ver;
    struct table      *tab;
    struct callback   *cb;

    call_callbacks(dm, DVBMON_EVENT_DESTROY, 0, 0);
    list_for_each_safe(item,safe,&dm->tables) {
		tab = list_entry(item, struct table, next);
		table_del(dm, tab->pid, tab->sec);
    };

    list_for_each_safe(item,safe,&dm->versions) {
		ver = list_entry(item, struct version, next);
		list_del(&ver->next);
		free(ver);
    };

    list_for_each_safe(item,safe,&dm->callbacks) {
        cb = list_entry(item, struct callback, next);
        list_del(&cb->next);
        free(cb);
    };

    psi_info_free(dm->info);
    free(dm);
}

/* ----------------------------------------------------------------------------- */
void dvbmon_refresh(struct dvbmon* dm)
{
    struct list_head  *item;
    struct version    *ver;

    list_for_each(item,&dm->versions) {
		ver = list_entry(item, struct version, next);
		ver->version = PSI_NEW;
    }

}

/* ----------------------------------------------------------------------------- */
void dvbmon_add_callback(struct dvbmon* dm, dvbmon_notify func, void *data)
{
    struct callback *cb;

    cb = malloc(sizeof(*cb));
    memset(cb,0,sizeof(*cb));
    cb->func = func;
    cb->data = data;
    list_add_tail(&cb->next,&dm->callbacks);
}

/* ----------------------------------------------------------------------------- */
void dvbmon_del_callback(struct dvbmon* dm, dvbmon_notify func, void *data)
{
    struct callback   *cb = NULL;
    struct list_head  *item;

    list_for_each(item,&dm->callbacks) {
	cb = list_entry(item, struct callback, next);
	if (cb->func == func && cb->data == data)
	    break;
	cb = NULL;
    }
    if (NULL == cb) {
    	if (dm->verbose) fprintf(stderr,"dvbmon: oops: rm unknown cb %p %p\n",func,data);
	return;
    }
    list_del(&cb->next);
    free(cb);
}


/* ------------------------------------------------------------------------ */
/* ------------------------------------------------------------------------ */
static int table_data(struct dvbmon *dm, struct table *tab, int verbose, int tuned_freq)
{
struct list_head *item;
struct psi_program *pr;
struct psi_stream *stream;
int id, version, current, old_tsid;
unsigned char buf[4096];

    if (NULL == tab) {
		fprintf(stderr,"dvbmon: invalid table\n");
		return FALSE;
    }

    /* get data */
    if (dvb_demux_get_section(tab->fd, buf, sizeof(buf)) < 0) {
		if (dvb_debug)
			fprintf(stderr,"dvbmon: reading %s failed (frontend not locked?), "
				"fd %d, trying to re-init.\n", tab->name, tab->fd);
		table_refresh(dm,tab);
		return TRUE;
    }
    if (tab->once) {
		table_close(dm,tab);
		table_next(dm);
    }

    id      = mpeg_getbits(buf,24,16);
    version = mpeg_getbits(buf,42,5);
    current = mpeg_getbits(buf,47,1);

    if (dvb_debug)
    {
    	fprintf(stderr, "id 0x%02x : ver=%d curr=%d\n", id, version, current) ;
    	if (verbose)
    	{
        	fprintf(stderr, "TABLE:\n   name %s, pid 0x%02x, sec 0x%02x\n", tab->name, tab->pid, tab->sec) ;
    	}
    }

    if (!current)
    	return TRUE;

    // Skip processing this table iff it's been seen before AND it's not PAT or NIT
    if (table_data_seen(dm, tab->name, id, version) &&
    		SECTION_PAT != tab->sec /* pat */&&
    		SECTION_NIT_ACTUAL != tab->sec /* nit this */ &&
    		SECTION_NIT_OTHER != tab->sec /* nit other */
    )
    {
        if (dvb_debug) fprintf(stderr, "Table seen\n") ;
    	return TRUE;
    }

    switch (tab->sec) {
		case SECTION_PAT: /* pat */
			old_tsid = dm->info->tsid;
			mpeg_parse_psi_pat(dm->info, buf, dm->verbose, tuned_freq);
			if (old_tsid != dm->info->tsid)
				call_callbacks(dm, DVBMON_EVENT_SWITCH_TS, dm->info->tsid, 0);
			break;

		case SECTION_PMT: /* pmt */
			pr = psi_program_get(dm->info, dm->info->tsid, id, tuned_freq, 0);
			if (!pr) {
				if (dm->verbose) fprintf(stderr,"dvbmon: 404: tsid %d pid %d\n", dm->info->tsid, id);
				break;
			}
			mpeg_parse_psi_pmt(pr, buf, dm->verbose, tuned_freq);
			break;

		case SECTION_NIT_ACTUAL: /* nit this  */
		case SECTION_NIT_OTHER: /* nit other */
			mpeg_parse_psi_nit(dm->info, buf, dm->verbose, tuned_freq);
			break;

		case SECTION_SDT_ACTUAL: /* sdt this  */
		case SECTION_SDT_OTHER: /* sdt other */
			mpeg_parse_psi_sdt(dm->info, buf, dm->verbose, tuned_freq);
			break;

		default:
			if (dm->verbose) fprintf(stderr,"dvbmon: oops: sec=0x%02x\n",tab->sec);
			break;
    }

    /* check for changes */
    if (dm->info->pat_updated) {
		dm->info->pat_updated = 0;
		if (dm->verbose>1)
			fprintf(stderr,"dvbmon: updated: pat\n");
		list_for_each(item,&dm->info->programs) {
			pr = list_entry(item, struct psi_program, next);
			if (!pr->seen)
				table_del(dm, pr->p_pid, 2);
		}
		list_for_each(item,&dm->info->programs) {
			pr = list_entry(item, struct psi_program, next);
			if (pr->seen && pr->p_pid)
			{
				table_add(dm, "pmt", pr->p_pid, 2, 1);
				if (dvb_debug>=15) print_program(pr) ;
			}
			pr->seen = 0;
		}
    }

    /* inform callbacks */
    list_for_each(item,&dm->info->streams) {
        stream = list_entry(item, struct psi_stream, next);
		if (!stream->updated)
			continue;
		stream->updated = 0;
		call_callbacks(dm, DVBMON_EVENT_UPDATE_TS, stream->tsid, 0);
    }

    list_for_each(item,&dm->info->programs) {
		pr = list_entry(item, struct psi_program, next);

if (dvb_debug)
{
	fprintf(stderr, " + PROG: pnr %d tsid %d type %d name %s net %s : updated %d seen %d [tuned=%d]\n",
			pr->pnr, pr->tsid, pr->type, pr->name, pr->net, pr->updated, pr->seen, tuned_freq) ;
}


		if (!pr->updated)
			continue;
		pr->updated = 0;
//		dvb_lang_parse_audio(pr->audio);
		call_callbacks(dm, DVBMON_EVENT_UPDATE_PR, pr->tsid, pr->pnr);
    }

    return TRUE;
}



/* ------------------------------------------------------------------------ */
/* ------------------------------------------------------------------------ */


/* ------------------------------------------------------------------------ */
static void tty_scan(struct dvb_state *dvb, struct dvbmon *dvbmon)
{
time_t tuned;
char *name;
int num_freqs ;

int ready ;
int ready_total ;
int i ;
int rc ;

int nfds=0 ; // TODO: just use dvbmon->tabfds


struct pollfd *pollfds;
struct table *tab = NULL;
struct table **table_list = NULL;

struct list_head   *item, *safe;
struct psi_stream *stream;

struct freqitem *current_freqi, *stream_freqi ;

// Uses static global:
// poll_timeout_ms
// scan_timeout_secs
// current


	// display settings
	if (dvb_debug >= 2) dvb_frontend_tune_info(dvb);


	// get current frequency info
	current_freqi = freqitem_get(&dvb->p) ;

	// mark the currently tuned in frequency as a success!
	current_freqi->flags.tuned = 1 ;

	// update signal quality
	dvb_signal_quality(dvb,
 		&current_freqi->ber,
		&current_freqi->snr,
		&current_freqi->strength,
		&current_freqi->uncorrected_blocks
	) ;

if (dvb_debug >= 1)
{
	fprintf_timestamp(stderr, "\n-- tty_scan() v2 current FREQ %d (seen=%d, tuned=%d) -- \n",
		dvb->p.frequency,
		current_freqi->flags.seen,
		current_freqi->flags.tuned
	) ;
}

//	// skip if already seen
//	if (current_freqi->flags.seen) return ;
	
	// mark the currently tuned as seen
	current_freqi->flags.seen = 1 ;


    // Prepare for polling
    pollfds = (struct pollfd* )malloc(sizeof(struct pollfd) * dvbmon->tablimit);
    memset(pollfds, 0, sizeof(struct pollfd) * dvbmon->tablimit) ;

    table_list = (struct table** )malloc(sizeof(struct table *) * dvbmon->tablimit);
    memset(table_list, 0, sizeof(struct table *) * dvbmon->tablimit) ;

	// start
    for (num_freqs=1;num_freqs;)
    {
//    	// reset the scan tables
//    	dvbmon_reset_tables(dvbmon) ;
    	
    	// reset global count (updated as we see data)
		current = 0;

		// get current frequency info
		current_freqi = freqitem_get(&dvb->p) ;

		// mark the currently tuned in frequency as a success!
		current_freqi->flags.tuned = 1 ;
		current_freqi->flags.seen = 1 ;

		// update signal quality
		dvb_signal_quality(dvb,
	 		&current_freqi->ber,
			&current_freqi->snr,
			&current_freqi->strength,
			&current_freqi->uncorrected_blocks
		) ;

		
		if (dvb_debug>1) fprintf_timestamp(stderr,"Current freqi = %d\n", current_freqi->frequency);

		if (dvb_debug>10) fprintf(stderr,"about to poll ..\n");

		// keep a count of data seen for this freq - allows us to abort early
		ready_total = 0 ;

		/* fish for data */
		tuned = time(NULL);
		while (time(NULL) - tuned < scan_timeout_secs)
		{
			if (dvb_debug>10) fprintf(stderr,"Polling for data (timer=%d) ...\n", (int)(time(NULL) - tuned));

//struct table {
//    struct list_head    next;
//    char                *name;
//    int                 pid;
//    int                 sec;
//    int                 fd;
//    int                 once;
//    int                 done;
//};

if (dvb_debug >=14) fprintf(stderr, "Table List:\n") ;

			// Get latest poll info
			memset(pollfds, 0, sizeof(struct pollfd) * dvbmon->tablimit) ;
			memset(table_list, 0, sizeof(struct table *) * dvbmon->tablimit) ;
			nfds=0 ;
			list_for_each(item, &dvbmon->tables)
			{
				tab = list_entry(item, struct table, next);
if (dvb_debug >=14) fprintf(stderr, "(%d) Table %s : pid=0x%02x sec=0x%02x fd=%d once=%d done=%d\n", 
									nfds, tab->name, tab->pid, tab->sec, tab->fd, tab->once, tab->done) ;
				if (tab && (tab->fd>0) )
				{
					pollfds[nfds].fd = tab->fd ;
					pollfds[nfds].events = POLLIN ;
					pollfds[nfds].revents = 0 ;

					table_list[nfds] = tab ;

					++nfds ;
				}
			}
if (dvb_debug >=14) fprintf(stderr, "%d active entries\n\n", nfds) ;

			// poll
			ready = poll(pollfds, nfds, poll_timeout_ms);
			ready_total += ready ;

			if (dvb_debug>10) fprintf_timestamp(stderr," + ready=%d (total=%d)\n", ready, ready_total);

			if (ready > 0)
			{
				// Check each fd
				for(i=0; i<nfds; i++)
				{
					if (dvb_debug>10) fprintf(stderr," %d : revents=0x%02x\n", i, pollfds[i].revents);

					if ( (pollfds[i].revents & POLLIN) == POLLIN)
					{
						if (dvb_debug>10) fprintf(stderr," + dispatch..\n");
if (dvb_debug >=14) fprintf(stderr, "Table[%d] %s : pid=0x%02x sec=0x%02x fd=%d once=%d done=%d\n", 
	i, table_list[i]->name, table_list[i]->pid, table_list[i]->sec, table_list[i]->fd, table_list[i]->once, table_list[i]->done) ;

						// fd is ready so dispatch
						table_data(dvbmon, table_list[i], dvbmon->verbose, current_freqi->frequency) ;
					}
				}
			}
			
			if (ready == 0)
			{
				// have we seen anything on this freq?
				if (ready_total == 0)
				{
					// abort early?
					if (time(NULL) - tuned >= nodata_timeout_secs)
					{
if (dvb_debug >=14) fprintf_timestamp(stderr, "! Early abort...\n") ;
						break ;
					}	
				}
			}
			
			if (ready < 0)
			{
				perror("Poll fail") ;
			}
		}

		if (dvb_debug>10) fprintf_timestamp(stderr,"done while loop ..\n");


		if (!current)
		{
			if (dvbmon->verbose) fprintf(stderr,"No data received. Frontend is%s locked.\n",
										dvb_frontend_is_locked(dvb) ? "" : " not");
		}

if (dvb_debug >= 10)
{
		fprintf(stderr, "\n\n----------------------------------------------------\nStreams so far:\n") ;
	    print_streams(dvbmon) ;
		fprintf(stderr, "----------------------------------------------------\n\n") ;

		fprintf(stderr, "\n\n----------------------------------------------------\nFreq list so far:\n") ;
	    print_freqs() ;
		fprintf(stderr, "----------------------------------------------------\n\n") ;
}

if (dvb_debug >= 15)
{
		fprintf(stderr, "\n\n----------------------------------------------------\nPrograms so far:\n") ;
	    print_programs(dvbmon) ;
		fprintf(stderr, "----------------------------------------------------\n\n") ;
}

   		// Process streams
		if (dvb_debug>=3) fprintf(stderr, "Processing new streams...\n") ;
	    list_for_each_safe(item,safe,&dvbmon->info->streams)
	    {
	    	stream = list_entry(item, struct psi_stream, next);

		if (dvb_debug>=3) fprintf(stderr, "stream: freq %d -> tune=%d\n", stream->frequency, stream->tuned) ;

			// only process un-tuned streams
	    	if (!stream->tuned)
	    	{
	    		// check 'other frequency list'
	    		if (stream->freq_list_len > 0)
	    		{
	    		int i ;
	    		
					if (dvb_debug>=3) 
						fprintf(stderr, " + creating %d clones..\n", stream->freq_list_len) ;

					for (i = 0; i < stream->freq_list_len; i++)
					{
					struct psi_stream *clone_stream;
					struct freqitem *clone_stream_freqi ;
						
						if (dvb_debug) 
							fprintf(stderr, " + creating clone stream: freq %d Hz\n", stream->freq_list[i]) ;

						// create a "cloned" stream with just a new frequency
						clone_stream = psi_stream_newfreq(dvbmon->info, stream, stream->freq_list[i]) ;

						// check to see if clone has been tuned to before
			    		clone_stream_freqi = freqitem_get_from_stream(clone_stream) ;
						if (dvb_debug>=3)
						{
							fprintf(stderr, " + Cloning tuned flag from: ") ;
							print_freqi(clone_stream_freqi) ;
						} 
			    		clone_stream->tuned = clone_stream_freqi->flags.tuned ;

						if (dvb_debug) 
							fprintf(stderr, "clone stream: freq %d -> tune=%d\n", clone_stream->frequency, clone_stream->tuned) ;

					}
	    		} // !tuned
	    		
	    		// check to see if this stream *has* actually been tuned already
	    		stream_freqi = freqitem_get_from_stream(stream) ;
				if (dvb_debug>=3)
				{
					fprintf(stderr, " + Copying tuned flag from: ") ;
					print_freqi(stream_freqi) ;
				} 
	    		stream->tuned = stream_freqi->flags.tuned ;

				if (dvb_debug) 
					fprintf(stderr, "stream: freq %d -> tune=%d\n", stream->frequency, stream->tuned) ;
	    	}
	    }

if (dvb_debug >= 10)
{
		fprintf(stderr, "\n\n----------------------------------------------------\nStreams after processing freq list:\n") ;
	    print_streams(dvbmon) ;
		fprintf(stderr, "----------------------------------------------------\n\n") ;

		fprintf(stderr, "\n\n----------------------------------------------------\nFreq list so far:\n") ;
	    print_freqs() ;
		fprintf(stderr, "----------------------------------------------------\n\n") ;
}

	    
		num_freqs=0;
	    list_for_each(item,&dvbmon->info->streams)
	    {
	    	stream = list_entry(item, struct psi_stream, next);

if (dvb_debug > 3) fprintf(stderr, "check stream  tsid %d freq %d Hz tuned=%d [num freqs=%d]\n", 
						stream->tsid, stream->frequency, stream->tuned, num_freqs) ;

	    	// Find next freq to select (if any left)
	    	if (!stream->tuned)
	    	{
				// map stream frequency onto freq list
				stream_freqi = freqitem_get_from_stream(stream) ;

if (dvb_debug > 3) fprintf(stderr, " + check stream freq seen=%d tuned=%d\n", stream_freqi->flags.seen, stream_freqi->flags.tuned) ;
if (dvb_debug > 3) 
{
	fprintf(stderr, "Stream ") ;
	print_freqi(stream_freqi) ;
}

//				if (!stream_freqi->flags.seen)
//				{
//if (dvb_debug>=10) fprintf(stderr, "stream: freq %d (%d) -> SKIP tune=%d\n", stream->frequency, stream_freqi->frequency, stream->tuned) ;
//
//	    		}
//				else
//				{
//					if (dvbmon->verbose) fprintf(stderr, "Already seen freq %d - tsid %d (%s)\n", stream->frequency, stream->tsid, stream->net) ;
//				}

	    	}
	    }


if (dvb_debug > 2) fprintf(stderr, "# freqs left = %d\n", num_freqs) ;

    }

if (dvbmon->verbose >= 2)
{
    print_streams(dvbmon) ;
    print_programs(dvbmon) ;
}

    // Clean up
    free(table_list) ;
    free(pollfds) ;
}




/* ----------------------------------------------------------------------- */
struct dvbmon *dvbmon ;


// TODO: Pass in timeout value....
struct dvbmon *dvb_scan_freqs(struct dvb_state *dvb, int verbose)
{

	// do scan
	tty_scan(dvb, dvbmon);

	// return results
	return dvbmon ;
}


/* ----------------------------------------------------------------------- */
void dvb_scan_init(struct dvb_state *dvb, int verbose)
{
	// Initialise the monitor
    dvbmon = dvbmon_init(dvb, verbose, /* other NIT */ 1,  /* other SDT */ 0, /* # PMTs */ 2);

	// set up scanning callback handler
	dvbmon_add_callback(dvbmon,dvbwatch_tty, dvbmon);
	
}

/* ----------------------------------------------------------------------- */
void dvb_scan_end(struct dvb_state *dvb, int verbose)
{
	// clear out monitor
	dvbmon_fini(dvbmon) ;
}
