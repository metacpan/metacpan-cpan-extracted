/*
 * handle dvb devices
 * import vdr channels.conf files
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <ctype.h>
#include <fcntl.h>
#include <inttypes.h>
#include <time.h>

#include <sys/time.h>
#ifndef WIN32
	#include <sys/ioctl.h>
	#include <linux/dvb/frontend.h>
	#include <linux/dvb/dmx.h>

	#ifdef HAVE_DVB
		#include "dvb_tune.h"
		#include "struct-dvb.h"
	#endif
#else
	#include <win_time.h>
#endif

#include "dvb_debug.h"

/*------------------------------------------------------------------*/
int dvb_debug=0;
static int dbg_indent = 0 ;

//time_t  tv_sec    seconds
//long    tv_nsec   nanoseconds
static struct timespec t0 ;
static struct timespec t1 ;
static struct timespec tdiff ;

static char timer_buff[128] ;

/*------------------------------------------------------------------*/
struct timespec *dbg_timer_start()
{
	clock_gettime(CLOCK_REALTIME, &t0) ;

//fprintf(stderr, "t0 : sec=%u ns=%lu\n", t0.tv_sec, t0.tv_nsec) ;
	return &t0 ;
}

/*------------------------------------------------------------------*/
struct timespec *dbg_timer_stop()
{
	clock_gettime(CLOCK_REALTIME, &t1) ;

//fprintf(stderr, "t1 : sec=%u ns=%lu\n", t1.tv_sec, t1.tv_nsec) ;
//fprintf(stderr, "t0 is sec=%u ns=%lu\n", t0.tv_sec, t0.tv_nsec) ;

	tdiff.tv_nsec = t1.tv_nsec - t0.tv_nsec ;
	tdiff.tv_sec = t1.tv_sec - t0.tv_sec ;
	if (tdiff.tv_nsec < 0L)
	{
		tdiff.tv_sec--;
		tdiff.tv_nsec += 1000000000L ;
	}
//fprintf(stderr, "tdiff = sec=%u ns=%lu\n", tdiff.tv_sec, tdiff.tv_nsec) ;

	return &t1 ;
}

/*------------------------------------------------------------------*/
struct timespec *dbg_timer_duration()
{
	return &tdiff ;
}

/*------------------------------------------------------------------*/
char *dbg_sprintf_timer(const char *format, struct timespec *t)
{
unsigned us ;
struct tm  *ts;
char  buf[80];

	// print timestamp
    ts = localtime(&t->tv_sec);
    strftime(buf, sizeof(buf), format, ts);

    // tack on us
    us = (unsigned)(t->tv_nsec / 1000L) ;
	sprintf(timer_buff, "%s.%06u", buf, us) ;

	return timer_buff ;
}

/*------------------------------------------------------------------*/
// Just format the difference and return the string
char *dbg_sprintf_duration(const char *format)
{
	return dbg_sprintf_timer(format, &tdiff) ;
}


/*------------------------------------------------------------------*/
void fprintf_timestamp(FILE *stream, const char *format, ...)
{
struct timespec t ;
int ms ;
struct tm  *ts;
char       buf[80];
va_list ap;

    va_start(ap, format);
 
	if (0 != clock_gettime(CLOCK_REALTIME, &t))
	{
		perror("Get time fail") ;
		return ;
	}

	// print timestamp
    ts = localtime(&t.tv_sec);
    strftime(buf, sizeof(buf), "%H:%M:%S", ts);
    ms = (int)(t.tv_nsec / 1000000L) ;
	fprintf(stream, "[%s.%03d] ", buf, ms) ;
	
	// print message
	vfprintf(stream, format, ap);

    va_end(ap);
}


/*------------------------------------------------------------------*/
void printf_timestamp(const char *format, ...)
{
struct timespec t ;
int ms ;
struct tm  *ts;
char       buf[80];
va_list ap;

    va_start(ap, format);
 
	if (0 != clock_gettime(CLOCK_REALTIME, &t))
	{
		perror("Get time fail") ;
		return ;
	}

	// print timestamp
    ts = localtime(&t.tv_sec);
    strftime(buf, sizeof(buf), "%H:%M:%S", ts);
    ms = (int)(t.tv_nsec / 1000000L) ;
	fprintf(stdout, "[%s.%03d] ", buf, ms) ;
	
	// print message
	vfprintf(stdout, format, ap);

    va_end(ap);
}



/*------------------------------------------------------------------*/
#ifndef WIN32
#ifdef HAVE_DVB

void dump_fe_info(struct dvb_state *h)
{
    switch (h->info.type) {
    case FE_QPSK:
	fprintf(stderr,"dvb fe: tuning freq=lof+%d Hz, inv=%s "
		"symbol_rate=%d fec_inner=%s\n",
		h->p.frequency,
		dvb_fe_inversion [ h->p.inversion ],
		h->p.u.qpsk.symbol_rate,
		dvb_fe_rates [ h->p.u.qpsk.fec_inner ]);
	break;
    case FE_QAM:
	fprintf(stderr,"dvb fe: tuning freq=%d Hz, inv=%s "
		"symbol_rate=%d fec_inner=%s modulation=%s\n",
		h->p.frequency,
		dvb_fe_inversion  [ h->p.inversion       ],
		h->p.u.qam.symbol_rate,
		dvb_fe_rates      [ h->p.u.qam.fec_inner  ],
		dvb_fe_modulation [ h->p.u.qam.modulation ]);
	break;
    case FE_OFDM:
	fprintf(stderr,"dvb fe: tuning freq=%d Hz, inv=%s (%d) "
		"bandwidth=%s (%d) code_rate=[%s-%s] (%d - %d) constellation=%s (%d) "
		"transmission=%s (%d) guard=%s (%d) hierarchy=%s (%d)\n",
		h->p.frequency,
		dvb_fe_inversion    [ h->p.inversion                    ],
		h->p.inversion ,
		dvb_fe_bandwidth    [ h->p.u.ofdm.bandwidth             ],
		h->p.u.ofdm.bandwidth,
		dvb_fe_rates        [ h->p.u.ofdm.code_rate_HP          ],
		dvb_fe_rates        [ h->p.u.ofdm.code_rate_LP          ],
		h->p.u.ofdm.code_rate_HP,
		h->p.u.ofdm.code_rate_LP,
		dvb_fe_modulation   [ h->p.u.ofdm.constellation         ],
		h->p.u.ofdm.constellation,
		dvb_fe_transmission [ h->p.u.ofdm.transmission_mode     ],
		h->p.u.ofdm.transmission_mode,
		dvb_fe_guard        [ h->p.u.ofdm.guard_interval        ],
		h->p.u.ofdm.guard_interval,
		dvb_fe_hierarchy    [ h->p.u.ofdm.hierarchy_information ],
		h->p.u.ofdm.hierarchy_information
		);
	break;
#ifdef FE_ATSC
    case FE_ATSC:
	fprintf(stderr,"dvb fe: tuning freq=%d Hz, modulation=%s\n",
		h->p.frequency,
		dvb_fe_modulation [ h->p.u.vsb.modulation ]);
	break;
#endif
    }
}

/*------------------------------------------------------------------*/
void _fn_start(char *name)
{
	++dbg_indent ;
	_prt_indent(name) ; fprintf(stderr, "()\n") ;
}
void _fn_end(char *name, int rc)
{
	_prt_indent(name) ; fprintf(stderr, " - END (rc=%d)\n", rc) ;
	dbg_indent-- ;
}
void _indent(int level)
{
int i ;
	for(i=0; i<level; i++)
	{
		fprintf(stderr, " ") ;
	}
}
void _prt_indent(char *name)
{
	_indent(dbg_indent) ;
	fprintf(stderr, "%s: ", name) ;
}


#ifdef INFO
struct dvb_frontend_info {
	char       name[128];
	fe_type_t  type;
	__u32      frequency_min;
	__u32      frequency_max;
	__u32      frequency_stepsize;
	__u32      frequency_tolerance;
	__u32      symbol_rate_min;
	__u32      symbol_rate_max;
	__u32      symbol_rate_tolerance;	/* ppm */
	__u32      notifier_delay;		/* DEPRECATED */
	fe_caps_t  caps;
};
#endif

void _dump_frontend_info(int indent, struct dvb_frontend_info *info)
{
int ind=4 ;

_indent(indent+ind) ; fprintf(stderr, "char       name=%s\n", info->name) ;
_indent(indent+ind) ; fprintf(stderr, "fe_type_t  type=%d\n", info->type) ;
_indent(indent+ind) ; fprintf(stderr, "_u32       frequency_min=%u\n", info->frequency_min) ;
_indent(indent+ind) ; fprintf(stderr, "_u32       frequency_max=%u\n", info->frequency_max) ;
_indent(indent+ind) ; fprintf(stderr, "_u32       frequency_stepsize=%u\n", info->frequency_stepsize) ;
_indent(indent+ind) ; fprintf(stderr, "_u32       frequency_tolerance=%u\n", info->frequency_tolerance) ;
_indent(indent+ind) ; fprintf(stderr, "_u32       symbol_rate_min=%u\n", info->symbol_rate_min) ;
_indent(indent+ind) ; fprintf(stderr, "_u32       symbol_rate_max=%u\n", info->symbol_rate_max) ;
_indent(indent+ind) ; fprintf(stderr, "_u32       symbol_rate_tolerance=%u ppm\n", info->symbol_rate_tolerance) ;
_indent(indent+ind) ; fprintf(stderr, "_u32       notifier_delay=%u deprecated\n", info->notifier_delay) ;

}

#ifdef INFO
struct dvb_ofdm_parameters {
	fe_bandwidth_t      bandwidth;
	fe_code_rate_t      code_rate_HP;  /* high priority stream code rate */
	fe_code_rate_t      code_rate_LP;  /* low priority stream code rate */
	fe_modulation_t     constellation; /* modulation type (see above) */
	fe_transmit_mode_t  transmission_mode;
	fe_guard_interval_t guard_interval;
	fe_hierarchy_t      hierarchy_information;
};


struct dvb_frontend_parameters {
	__u32 frequency;     /* (absolute) frequency in Hz for QAM/OFDM/ATSC */
			     /* intermediate frequency in Hz for QPSK */
	fe_spectral_inversion_t inversion;
	union {
		struct dvb_qpsk_parameters qpsk;
		struct dvb_qam_parameters  qam;
		struct dvb_ofdm_parameters ofdm;
		struct dvb_vsb_parameters vsb;
	} u;
};
#endif

void _dump_frontend_params(int indent, struct dvb_frontend_parameters *p)
{
int ind=4 ;

_indent(indent+ind) ; fprintf(stderr, "__u32                   frequency=%u\n", p->frequency) ;
_indent(indent+ind) ; fprintf(stderr, "fe_spectral_inversion_t inversion=%d (%s)\n", 	p->inversion,	dvb_fe_inversion    [ p->inversion                    ]) ;
_indent(indent+ind) ; fprintf(stderr, "fe_bandwidth_t          bandwidthy=%d (%s)\n",	p->u.ofdm.bandwidth,	dvb_fe_bandwidth    [ p->u.ofdm.bandwidth             ]) ;
_indent(indent+ind) ; fprintf(stderr, "fe_code_rate_t          code_rate_HPy=%d (%s)\n",	p->u.ofdm.code_rate_HP,	dvb_fe_rates        [ p->u.ofdm.code_rate_HP          ]) ;
_indent(indent+ind) ; fprintf(stderr, "fe_code_rate_t          code_rate_LP=%d (%s)\n",	p->u.ofdm.code_rate_LP,	dvb_fe_rates        [ p->u.ofdm.code_rate_LP          ]) ;
_indent(indent+ind) ; fprintf(stderr, "fe_modulation_t         constellation=%d (%s)\n",	p->u.ofdm.constellation,	dvb_fe_modulation   [ p->u.ofdm.constellation         ]) ;
_indent(indent+ind) ; fprintf(stderr, "fe_transmit_mode_t      transmission_mod=%d (%s)\n",	p->u.ofdm.transmission_mode,	 dvb_fe_transmission [ p->u.ofdm.transmission_mode     ]) ;
_indent(indent+ind) ; fprintf(stderr, "fe_guard_interval_t     guard_interval=%d (%s)\n", p->u.ofdm.guard_interval,		dvb_fe_guard        [ p->u.ofdm.guard_interval        ]) ;
_indent(indent+ind) ; fprintf(stderr, "fe_hierarchy_t          hierarchy_information=%d (%s)\n", p->u.ofdm.hierarchy_information,	dvb_fe_hierarchy    [ p->u.ofdm.hierarchy_information ]) ;

}

#ifdef INFO
typedef enum
{
	DMX_OUT_DECODER, /* Streaming directly to decoder. */
	DMX_OUT_TAP,     /* Output going to a memory buffer */
			 /* (to be retrieved via the read command).*/
	DMX_OUT_TS_TAP   /* Output multiplexed into a new TS  */
			 /* (to be retrieved by reading from the */
			 /* logical DVR device).                 */
} dmx_output_t;


typedef enum
{
	DMX_IN_FRONTEND, /* Input from a front-end device.  */
	DMX_IN_DVR       /* Input from the logical DVR device.  */
} dmx_input_t;


typedef enum
{
	DMX_PES_AUDIO0,
	DMX_PES_VIDEO0,
	DMX_PES_TELETEXT0,
	DMX_PES_SUBTITLE0,
	DMX_PES_PCR0,

	DMX_PES_AUDIO1,
	DMX_PES_VIDEO1,
	DMX_PES_TELETEXT1,
	DMX_PES_SUBTITLE1,
	DMX_PES_PCR1,

	DMX_PES_AUDIO2,
	DMX_PES_VIDEO2,
	DMX_PES_TELETEXT2,
	DMX_PES_SUBTITLE2,
	DMX_PES_PCR2,

	DMX_PES_AUDIO3,
	DMX_PES_VIDEO3,
	DMX_PES_TELETEXT3,
	DMX_PES_SUBTITLE3,
	DMX_PES_PCR3,

	DMX_PES_OTHER
} dmx_pes_type_t;

struct dmx_pes_filter_params
{
	__u16          pid;
	dmx_input_t    input;
	dmx_output_t   output;
	dmx_pes_type_t pes_type;
	__u32          flags;
};

struct demux_filter {
    int                              fd;
    struct dmx_pes_filter_params     filter;
};
#endif

void _dump_demux_filter(int indent, struct demux_filter *f)
{
int ind=4 ;

_indent(indent+ind) ; fprintf(stderr, "int                              fd=%d\n", f->fd) ;
_indent(indent+ind) ; fprintf(stderr, "struct dmx_pes_filter_params     filter={\n") ;
ind+=4;

_indent(indent+ind) ; fprintf(stderr, "__u16          pid=%d\n", f->filter.pid) ;
_indent(indent+ind) ; fprintf(stderr, "dmx_input_t    input=%d\n", f->filter.input) ;
_indent(indent+ind) ; fprintf(stderr, "dmx_output_t   output=%d\n", f->filter.output) ;
_indent(indent+ind) ; fprintf(stderr, "dmx_pes_type_t pes_type=%d\n", f->filter.pes_type) ;
_indent(indent+ind) ; fprintf(stderr, "__u32          flags=%d\n", f->filter.flags) ;

ind-=4;
_indent(indent+ind) ; fprintf(stderr, "}\n") ;

}


#ifdef INFO

struct dvb_state {
    /* device file names */
    char                             frontend[32];
    char                             demux[32];

    /* frontend */
    int                              fdro;
    int                              fdwr;
    struct dvb_frontend_info         info;
    struct dvb_frontend_parameters   p;
    struct dvb_frontend_parameters   plast;

    /* demux */
    struct demux_filter              audio;
    struct demux_filter              video;
};
#endif

void _dump_state(char *name, char *msg, struct dvb_state *h)
{
int ind=4 ;
	_prt_indent(name) ; fprintf(stderr, "DVB STATE %s\n", msg) ;
	_indent(dbg_indent+ind) ; fprintf(stderr, "dvbstate {\n") ;
	ind+=4 ;

	_indent(dbg_indent+ind) ; fprintf(stderr, "char frontend=%s\n", h->frontend) ;
	_indent(dbg_indent+ind) ; fprintf(stderr, "char demux=%s\n", h->demux) ;
	_indent(dbg_indent+ind) ; fprintf(stderr, "char dvr=%s\n", h->dvr) ;
	_indent(dbg_indent+ind) ; fprintf(stderr, "int  fdro=%d\n", h->fdro) ;
	_indent(dbg_indent+ind) ; fprintf(stderr, "int  fdwr=%d\n", h->fdwr) ;
	_indent(dbg_indent+ind) ; fprintf(stderr, "int  dvro=%d\n", h->dvro) ;

	_indent(dbg_indent+ind) ; fprintf(stderr, "struct dvb_frontend_info  info = {\n") ;
	_dump_frontend_info(dbg_indent+ind, &h->info) ;
	_indent(dbg_indent+ind) ; fprintf(stderr, "}\n") ;

	_indent(dbg_indent+ind) ; fprintf(stderr, "/* p params used in ioctl call */\n") ;
	_indent(dbg_indent+ind) ; fprintf(stderr, "struct dvb_frontend_parameters  p = {\n") ;
	_dump_frontend_params(dbg_indent+ind, &h->p) ;
	_indent(dbg_indent+ind) ; fprintf(stderr, "}\n") ;

	_indent(dbg_indent+ind) ; fprintf(stderr, "struct dvb_frontend_parameters  plast = {\n") ;
	_dump_frontend_params(dbg_indent+ind, &h->plast) ;
	_indent(dbg_indent+ind) ; fprintf(stderr, "}\n") ;


	_indent(dbg_indent+ind) ; fprintf(stderr, "struct demux_filter  audio = {\n") ;
	_dump_demux_filter(dbg_indent+ind, &h->audio) ;
	_indent(dbg_indent+ind) ; fprintf(stderr, "}\n") ;

	_indent(dbg_indent+ind) ; fprintf(stderr, "struct demux_filter  video = {\n") ;
	_dump_demux_filter(dbg_indent+ind, &h->video) ;
	_indent(dbg_indent+ind) ; fprintf(stderr, "}\n") ;


	ind-=4 ;
	_indent(dbg_indent+ind) ; fprintf(stderr, "}\n\n") ;

}
/*------------------------------------------------------------------*/
#endif
#endif
