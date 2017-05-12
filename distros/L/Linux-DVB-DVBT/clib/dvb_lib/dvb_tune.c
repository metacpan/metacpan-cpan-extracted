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

#include <sys/time.h>
#include <sys/ioctl.h>

#include "dvb_debug.h"
#include "dvb_error.h"
#include "dvb_tune.h"



// Debug problem where frequency readback from DVB tuner is not the same as requested
//
// requested= 698167000
// readback=  698166000
//
//#define TEST_FREQ_READBACK


/* ----------------------------------------------------------------------- */
static void print_params(struct dvb_frontend_parameters *params)
{
	fprintf(stderr, "inv=%d bw=%d crh=%d crl=%d con=%d tr=%d g=%d hi=%d",
	    params->inversion,
		params->u.ofdm.bandwidth,
		params->u.ofdm.code_rate_HP,
		params->u.ofdm.code_rate_LP,
		params->u.ofdm.constellation,
		params->u.ofdm.transmission_mode,
		params->u.ofdm.guard_interval,
		params->u.ofdm.hierarchy_information

	) ;
}


/* ======================================================================= */
/* keep track of freqs tuned to during scan                                */

LIST_HEAD(freq_list);

/* ----------------------------------------------------------------------- */
//struct freqitem {
//    struct list_head    next;
//
//    int                 frequency;
//    struct dvb_frontend_parameters	params ;	// frontend format (enums)
//    
//	/* signal quality measure */
//	unsigned 		ber ;
//	unsigned		snr ;
//	unsigned		strength ;
//	unsigned		uncorrected_blocks ;	// if we use this then need to time it and account for wrap!
//    
//	// various flags used during scan    
//    struct {
//    	unsigned seen	: 1 ;	// set if we've attempted to tune to this freq
//    	unsigned tuned	: 1 ;	// set if successfully tuned to this freq
//    } flags ;
//};
struct freqitem* freqitem_get(struct dvb_frontend_parameters *params)
{
struct freqitem   *freqi;
struct list_head *item;
int frequency = params->frequency ;

if (dvb_debug>=10)
{
	fprintf(stderr, "freqitem_get() FREQ=%d [params: ", params->frequency) ;
	print_params(params) ;
	fprintf(stderr, "]\n") ;
}

	// round up frequency to nearest kHz
	frequency = ROUND_FREQUENCY(frequency) ;

    list_for_each(item,&freq_list) {
		freqi = list_entry(item, struct freqitem, next);
		if (freqi->frequency != frequency)
		    continue;
		return freqi;
    }
    freqi = malloc(sizeof(*freqi));
    memset(freqi,0,sizeof(*freqi));
    
    freqi->frequency    = frequency ;		// convenience
    freqi->params.frequency    = frequency ;
    
    freqi->params.inversion    = params->inversion ;
	freqi->params.u.ofdm.bandwidth = params->u.ofdm.bandwidth ;
	freqi->params.u.ofdm.code_rate_HP = params->u.ofdm.code_rate_HP ;
	freqi->params.u.ofdm.code_rate_LP = params->u.ofdm.code_rate_LP ;
	freqi->params.u.ofdm.constellation = params->u.ofdm.constellation ;
	freqi->params.u.ofdm.transmission_mode = params->u.ofdm.transmission_mode ;
	freqi->params.u.ofdm.guard_interval = params->u.ofdm.guard_interval ;
	freqi->params.u.ofdm.hierarchy_information = params->u.ofdm.hierarchy_information ;

	// init flags    
    freqi->flags.seen    = 0;
    freqi->flags.tuned   = 0;

    list_add_tail(&freqi->next,&freq_list);
    return freqi;
}

/* ----------------------------------------------------------------------- */
// Update a freq_item with the latest parameter values. Used to set actual
// tuning params
//
struct freqitem* freqitem_update(struct dvb_frontend_parameters *params)
{
struct freqitem   *freqi;
int frequency = params->frequency ;

if (dvb_debug>=10)
{
	fprintf(stderr, "freqitem_update() FREQ=%d [params: ", params->frequency) ;
	print_params(params) ;
	fprintf(stderr, "]\n") ;
}

	// get freq_item
	freqi = freqitem_get(params) ;

	// set values
    freqi->params.inversion    = params->inversion ;
	freqi->params.u.ofdm.bandwidth = params->u.ofdm.bandwidth ;
	freqi->params.u.ofdm.code_rate_HP = params->u.ofdm.code_rate_HP ;
	freqi->params.u.ofdm.code_rate_LP = params->u.ofdm.code_rate_LP ;
	freqi->params.u.ofdm.constellation = params->u.ofdm.constellation ;
	freqi->params.u.ofdm.transmission_mode = params->u.ofdm.transmission_mode ;
	freqi->params.u.ofdm.guard_interval = params->u.ofdm.guard_interval ;
	freqi->params.u.ofdm.hierarchy_information = params->u.ofdm.hierarchy_information ;

    return freqi;
}

/* ----------------------------------------------------------------------- */
struct freqitem* freqitem_get_from_stream(struct psi_stream *stream) 
{
struct dvb_frontend_parameters params ;	
struct tuning_params vdr_params ;
struct freqitem   *freqi;

	// translate params
	params_stream_to_vdr(stream, &vdr_params) ;
	params_vdr_to_frontend(&vdr_params, &params) ;

	freqi = freqitem_get(&params) ;
	
	return freqi ;
}


/* ----------------------------------------------------------------------- */
void clear_freqlist()
{
struct list_head *item, *safe;
struct freqitem   *freqi;

	/* Free up results */
   	list_for_each_safe(item,safe,&freq_list)
   	{
		freqi = list_entry(item, struct freqitem, next);
		list_del(&freqi->next);

		free(freqi);
   	};
   	
}


/* ----------------------------------------------------------------------- */
void print_freqi(struct freqitem   *freqi)
{
	fprintf(stderr, "FREQ: %d Hz seen=%d tuned=%d (Strength=%d) [",
		freqi->frequency,
		freqi->flags.seen,
		freqi->flags.tuned,
		freqi->strength
	) ;
	print_params(&freqi->params) ;
	fprintf(stderr, "]\n") ;
}


/* ----------------------------------------------------------------------- */
void print_freqs()
{
    struct freqitem   *freqi;
    struct list_head *item;

	fprintf(stderr, "\n\n\n==FREQUENCY LIST==\n\n") ;
    list_for_each(item,&freq_list) {
		freqi = list_entry(item, struct freqitem, next);
		print_freqi(freqi) ;
    }
}



/* ======================================================================= */
/* map vdr config file numbers to enums                                    */


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
    [   0 ]           = QPSK,
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

static fe_spectral_inversion_t fe_vdr_inversion[] = {
    [ 0 ... VDR_MAX ] = INVERSION_AUTO,
    [ 0 ]             = INVERSION_OFF,
    [ 1 ]             = INVERSION_ON,
};

// Keep track of whether the current hardware can handle auto inversion
int dvb_inversion = INVERSION_AUTO ;



/* ----------------------------------------------------------------------- */
static unsigned fixup_freq(unsigned freq)
{
unsigned fixed_freq = freq ;

	/*
	 * DVB-C,T
	 *   - kernel API uses Hz here.
	 *   - /etc/vdr/channel.conf allows Hz, Hz and MHz
	 */
	if (fixed_freq < 1000000)
	    fixed_freq *= 1000;
	if (fixed_freq < 1000000)
	    fixed_freq *= 1000;
	    
	return fixed_freq ;
}


// conversion utilities

/* ----------------------------------------------------------------------- */
// Convert the stream tuning params (stored as strings) into "VDR" format integers
void params_stream_to_vdr(struct psi_stream *stream, struct tuning_params *vdr_params)
{
	// default to AUTO
	vdr_params->bandwidth=VDR_MAX;
	vdr_params->code_rate_high=VDR_MAX;
	vdr_params->code_rate_low=VDR_MAX;
	vdr_params->modulation=VDR_MAX;
	vdr_params->transmission=VDR_MAX;
	vdr_params->guard_interval=VDR_MAX;
	vdr_params->hierarchy=VDR_MAX;

	// convert params
	vdr_params->frequency = stream->frequency ;

//	if (stream->polarization)
//	{
//		vdr_params->inversion = atoi(stream->polarization) ;
//	}

	// use auto setting if possible
	vdr_params->inversion = dvb_inversion ;

	if (stream->bandwidth)
	{
		vdr_params->bandwidth = atoi(stream->bandwidth) ;
	}
	if (stream->code_rate_hp)
	{
		vdr_params->code_rate_high = atoi(stream->code_rate_hp) ;
	}
	if (stream->code_rate_lp)
	{
		vdr_params->code_rate_low = atoi(stream->code_rate_lp) ;
	}
	if (stream->constellation)
	{
		vdr_params->modulation = atoi(stream->constellation) ;
	}
	if (stream->transmission)
	{
		vdr_params->transmission = atoi(stream->transmission) ;
	}
	if (stream->guard)
	{
		vdr_params->guard_interval = atoi(stream->guard) ;
	}
	if (stream->hierarchy)
	{
		vdr_params->hierarchy = atoi(stream->hierarchy) ;
	}


}

/* ----------------------------------------------------------------------- */
// Convert the "VDR" format integers into frontend tuning params (enums)
void params_to_frontend(
		int frequency,
		int inversion,
		int bandwidth,
		int code_rate_high,
		int code_rate_low,
		int modulation,
		int transmission,
		int guard_interval,
		int hierarchy,
		struct dvb_frontend_parameters *params)
{
	params->frequency = fixup_freq(frequency) ;

	// Params decoded for transponders are converted into strings - convert back
	params->inversion = fe_vdr_inversion [ inversion ] ;
	params->u.ofdm.bandwidth = fe_vdr_bandwidth [ bandwidth ];
	params->u.ofdm.code_rate_HP = fe_vdr_rates [ code_rate_high ];
	params->u.ofdm.code_rate_LP = fe_vdr_rates [ code_rate_low ];
	params->u.ofdm.constellation = fe_vdr_modulation [ modulation ];
	params->u.ofdm.transmission_mode = fe_vdr_transmission [ transmission ];
	params->u.ofdm.guard_interval = fe_vdr_guard [ guard_interval ];
	params->u.ofdm.hierarchy_information = fe_vdr_hierarchy [ hierarchy ];

}


/* ----------------------------------------------------------------------- */
// Convert the "VDR" format integers into frontend tuning params (enums)
void params_vdr_to_frontend(struct tuning_params *vdr_params, struct dvb_frontend_parameters *params) 
{
	params_to_frontend(
		vdr_params->frequency,
		vdr_params->inversion,
		vdr_params->bandwidth,
		vdr_params->code_rate_high,
		vdr_params->code_rate_low,
		vdr_params->modulation,
		vdr_params->transmission,
		vdr_params->guard_interval,
		vdr_params->hierarchy,
		params) ;
}




/* ----------------------------------------------------------------------- */
/* Called any time
 * 
 * Tune the frontend. Expects parameters as "VDR" format integers
 * (e.g. code_rate = 34)
 */
int dvb_tune(struct dvb_state *h,
		int frequency,
		int inversion,
		int bandwidth,
		int code_rate_high,
		int code_rate_low,
		int modulation,
		int transmission,
		int guard_interval,
		int hierarchy,

		int timeout
)
{
	int rc=0 ;

	rc = dvb_frontend_tune(h,
		frequency,
		inversion,
		bandwidth,
		code_rate_high,
		code_rate_low,
		modulation,
		transmission,
		guard_interval,
		hierarchy
	);
	if (rc != 0) return rc ;

	rc = dvb_wait_tune(h, timeout) ;
	if (rc != 0) return rc ;

	return rc ;
}


/* ----------------------------------------------------------------------- */
/* Called during scanning
 * 
 * Same as dvb_tune() but also adds frequency to scan frequency list
 */
int dvb_scan_tune(struct dvb_state *h,
		int frequency,
		int inversion,
		int bandwidth,
		int code_rate_high,
		int code_rate_low,
		int modulation,
		int transmission,
		int guard_interval,
		int hierarchy,

		int timeout
)
{
int rc=0 ;
struct dvb_frontend_parameters params ;
struct freqitem* freqi ;

	params_to_frontend(
		frequency,
		inversion,
		bandwidth,
		code_rate_high,
		code_rate_low,
		modulation,
		transmission,
		guard_interval,
		hierarchy,
		&params) ;
		
	// Save frequency settings for requested frequency
	freqi = freqitem_get(&params) ;
	freqi->flags.seen = 1 ;
	
	// tune it
	rc = dvb_frontend_tune(h,
		frequency,
		inversion,
		bandwidth,
		code_rate_high,
		code_rate_low,
		modulation,
		transmission,
		guard_interval,
		hierarchy
	);
	if (rc != 0) return rc ;
	
	// wait until tuning is complete (also reads back tuning information from the hardware and sets h->p)
	rc = dvb_wait_tune(h, timeout) ;
	if (rc != 0) return rc ;

	// tuned ok
	freqi = freqitem_get(&h->p) ;
	freqi->flags.seen = 1 ;
	freqi->flags.tuned = 1 ;

	return rc ;
}



/* ======================================================================= */
/* handle diseqc                                                           */

/* ----------------------------------------------------------------------- */
int
xioctl(int fd, int cmd, void *arg)
{
    int rc;

    rc = ioctl(fd,cmd,arg);
    if (dvb_debug>1) fprintf(stderr,": %s\n",(rc == 0) ? "ok" : strerror(errno));

    if (0 == rc)
    	return rc;

	RETURN_DVB_ERROR(ERR_IOCTL);
}

/* ======================================================================= */
/* handle dvb frontend                                                     */

/* ----------------------------------------------------------------------- */
int dvb_frontend_open(struct dvb_state *h, int write)
{
	int *fd;

	if (dvb_debug>1) _fn_start((char *)__FUNCTION__) ;
	if (dvb_debug>1) {_prt_indent((char *)__FUNCTION__) ; fprintf(stderr, "Open %s\n", write ? "write" : "read-only");}

	fd = write ? &h->fdwr : &h->fdro;

    if (-1 != *fd)
    {
    	if (dvb_debug>1) {_prt_indent((char *)__FUNCTION__) ; fprintf(stderr, "Already got fd=%d\n", *fd);}
    	if (dvb_debug>1) _fn_end((char *)__FUNCTION__, 0) ;
    	return 0;
    }

    *fd = open(h->frontend, (write ? O_RDWR : O_RDONLY) | O_NONBLOCK);

    if (-1 == *fd) {
    	if (dvb_debug>1) fprintf(stderr,"dvb fe: open %s: %s (%d)\n", h->frontend,strerror(errno), errno);
		if (dvb_debug>1) _fn_end((char *)__FUNCTION__, -10) ;
		RETURN_DVB_ERROR(ERR_FE_OPEN);
    }

    if (dvb_debug>1) {_prt_indent((char *)__FUNCTION__) ; fprintf(stderr, "Created fd=%d\n", *fd);}
	if (dvb_debug>1) _fn_end((char *)__FUNCTION__, 0) ;
    return 0;
}

/* ----------------------------------------------------------------------- */
void dvb_frontend_release(struct dvb_state *h, int write)
{
    int *fd = write ? &h->fdwr : &h->fdro;

    if (-1 != *fd) {
		close(*fd);
		*fd = -1;
    }
}


/* ----------------------------------------------------------------------- */
/* Convert from "VDR" format params (e.g. code rate=34 into frontend param enums) */
int dvb_frontend_tune(struct dvb_state *h,
		int frequency,
		int inversion,
		int bandwidth,
		int code_rate_high,
		int code_rate_low,
		int modulation,
		int transmission,
		int guard_interval,
		int hierarchy
)
{
char *diseqc;
char *action;
int lof = 0;
int val;
int rc;

if (dvb_debug>1) _fn_start((char *)__FUNCTION__) ;

    if ( (rc=dvb_frontend_open(h, /* write=1*/1)) < 0 )
    {
    	if (dvb_debug>1) fprintf(stderr,"unable to open rw frontend\n");
    	if (dvb_debug>1) _fn_end((char *)__FUNCTION__, rc) ;

    	RETURN_DVB_ERROR(rc);;
    }

    if (dvb_debug>1) _dump_state((char *)__FUNCTION__, "at start", h) ;
   	if (dvb_debug>1) {_prt_indent((char *)__FUNCTION__) ; fprintf(stderr, "OFDM\n") ; }

	params_to_frontend(
		frequency,
		inversion,
		bandwidth,
		code_rate_high,
		code_rate_low,
		modulation,
		transmission,
		guard_interval,
		hierarchy,
		&h->p) ;

    if (0 == memcmp(&h->p, &h->plast, sizeof(h->plast))) {
		if (dvb_frontend_is_locked(h)) {
		    /* same frequency and frontend still locked */
		    if (dvb_debug) fprintf(stderr,"dvb fe: skipped tuning\n");
		    rc = 0;
		    goto done;
		}
    }

if (dvb_debug>1) _dump_state((char *)__FUNCTION__, "before ioctl call", h) ;

    rc = ERR_GENERIC ;
if (dvb_debug>1) {_prt_indent((char *)__FUNCTION__) ; fprintf(stderr, "xiotcl(FE_SET_FRONTEND)\n") ; }
    if ( (rc=xioctl(h->fdwr,FE_SET_FRONTEND,&h->p)) < 0) {
    	// failed
	    if (dvb_debug) dump_fe_info(h);
		goto done;
    }

    if (dvb_debug)
    	dump_fe_info(h);

    memcpy(&h->plast, &h->p, sizeof(h->plast));
    rc = 0;

done:

	if (dvb_debug>1) _fn_end((char *)__FUNCTION__, rc) ;

    // Hmm, the driver seems not to like that :-/
    // dvb_frontend_release(h,1);
	RETURN_DVB_ERROR(rc);;
}

/* ----------------------------------------------------------------------- */
/* Returns true if any other process currently has this frontend in use */
int dvb_frontend_is_busy(struct dvb_state *h)
{
int rc;
int is_busy = 0 ;

    if ( (rc=dvb_frontend_open(h, /* write=1*/1)) < 0 )
    {
    	is_busy = 1 ;
    }
    else
    {
    	dvb_frontend_release(h, /* write */ 1) ;
    }

    return is_busy ;
}

/* ----------------------------------------------------------------------- */
/* print tuning settings */
void dvb_frontend_tune_info(struct dvb_state *h)
{
struct dvb_frontend_parameters info ;
	
    if (xioctl(h->fdro,FE_GET_FRONTEND,&info) != 0)
    {
//		dump_fe_info(h);
//		goto done;
        if (dvb_debug>=5)
        {
        	fprintf(stderr, "Error reading FE info\n") ;
        }
    }
    else
    {
		if (dvb_debug>=5)
		{
			fprintf(stderr, "readback tuning:\n") ;
			_dump_frontend_params(0, &info) ;
		}
    }

}


/* ----------------------------------------------------------------------- */
int dvb_frontend_is_locked(struct dvb_state *h)
{
    fe_status_t  status  = 0;

    if (ioctl(h->fdro, FE_READ_STATUS, &status) < 0) {
    	if (dvb_debug>1) perror("dvb fe: ioctl FE_READ_STATUS");
		return 0;
    }
if (dvb_debug>=10) fprintf(stderr, "frontend status=0x%04x\n", status) ;

    return (status & FE_HAS_LOCK);
}

/* ----------------------------------------------------------------------- */
int dvb_signal_quality(struct dvb_state *h, 
	unsigned 		*ber,
	unsigned		*snr,
	unsigned		*strength,
	unsigned		*uncorrected_blocks
)
{
uint32_t 		ber32 ;
int16_t			snr16 ;
int16_t			strength16 ;
uint32_t		uncorrected_blocks32 ;
int ok = 1 ;

	*ber = 0 ;
	*snr = 0 ;
	*strength = 0 ;
	*uncorrected_blocks = 0 ;

	
    if (ioctl(h->fdro, FE_READ_BER, &ber32) < 0)
    {
//		perror("dvb fe: ioctl FE_READ_BER");
		ok = 0 ;
    }
    if (ioctl(h->fdro, FE_READ_SNR, &snr16) < 0)
    {
//		perror("dvb fe: ioctl FE_READ_SNR");
		ok = 0 ;
    }

	if (ioctl(h->fdro, FE_READ_SIGNAL_STRENGTH, &strength16) < 0)
	{
//		perror("dvb fe: ioctl FE_READ_SIGNAL_STRENGTH");
		ok = 0 ;
	}
	
	if (ioctl(h->fdro, FE_READ_UNCORRECTED_BLOCKS, &uncorrected_blocks32) < 0)
	{
//		perror("dvb fe: ioctl FE_READ_UNCORRECTED_BLOCKS");
		ok = 0 ;
	}

	// copy values
	*strength = (unsigned)(strength16) & 0xFFFF ;
	*snr = (unsigned)(snr16) & 0xFFFF ;
	*ber = (unsigned)(ber32) ;
	*uncorrected_blocks = (unsigned)(uncorrected_blocks32) ;

	if (dvb_debug>1) 
		fprintf(stderr, "dvb_signal_quality() ber=%u (0x%08x), snr=%u (0x%04x), uncorrected=%u (0x%08x), strength=%u (0x%04x)\n", 
			*ber, *ber,
			*snr, *snr,
			*uncorrected_blocks, *uncorrected_blocks,
			*strength, *strength) ;

    return ok ;
}

//#define USLEEP	40
#define USLEEP	200

/* ----------------------------------------------------------------------- */
int dvb_frontend_wait_lock(struct dvb_state *h, int timeout)
{
fe_status_t  status  = 0;
int i ;

	// timeout is in ms - convert to number of wait loops
	// Thanks to Martin Ward for pointing out that I needed to round the value up
	timeout = (timeout + USLEEP - 1) / USLEEP ;
	if (timeout <= 0)
		timeout = 1 ;

	for (i = 0; i < timeout; i++) {

	    if (-1 == ioctl(h->fdro, FE_READ_STATUS, &status)) {
	    	if (dvb_debug>1) perror("dvb fe: ioctl FE_READ_STATUS");
			RETURN_DVB_ERROR(ERR_IOCTL) ;
	    }

if ( (dvb_debug>=10) && (i%10==0) ) fprintf(stderr, ">>> tuning status == 0x%04x\n", status) ;

		if (status & FE_HAS_LOCK) {
			return 0;
		}

		usleep (USLEEP*1000);
	}
    
    
	RETURN_DVB_ERROR(ERR_TUNING_TIMEOUT) ;
}

/* ======================================================================= */
/* handle dvb demux                                                        */




/* ----------------------------------------------------------------------- */
int dvb_demux_add_filter(struct dvb_state *h, unsigned int pid)
{
int fd;
struct dmx_pes_filter_params f;

	fd = open(h->demux, O_RDONLY);
	if (fd == -1) {
		if (dvb_debug>1) perror("cannot open demux device");
		RETURN_DVB_ERROR(ERR_DEMUX_OPEN) ;
	}

	memset(&f, 0, sizeof(f));
	f.pid = (uint16_t) pid;
	f.input = DMX_IN_FRONTEND;
	f.output = DMX_OUT_TS_TAP;
	f.pes_type = DMX_PES_OTHER;
	f.flags   = DMX_IMMEDIATE_START;

	if (xioctl(fd, DMX_SET_PES_FILTER, &f) < 0) {
		if (dvb_debug>1) perror("DMX_SET_PES_FILTER");
		RETURN_DVB_ERROR( ERR_SET_PES_FILTER );
	}

	if (dvb_debug) fprintf(stderr, "set filter for PID 0x%04x on fd %d\n", pid, fd);

	return fd ;
}

/* ----------------------------------------------------------------------- */
int dvb_demux_remove_filter(struct dvb_state *h, int fd)
{
    if (-1 != fd) {
		xioctl(fd,DMX_STOP,NULL);
		close(fd);
		fd = -1;
    }

	return fd ;
}



/* ----------------------------------------------------------------------- */
int dvb_demux_get_section(int fd, unsigned char *buf, int len)
{
    int rc;

    memset(buf,0,len);
    if ((rc = read(fd, buf, len)) < 0)
    {
		if ((ETIMEDOUT != errno && EOVERFLOW != errno) || dvb_debug)
		{
			if (dvb_debug>1) fprintf(stderr,"dvb mux: read: %s [%d] rc=%d\n", strerror(errno), errno, rc);
		}
		SET_ERROR(rc, ERR_READ) ;
    }
    return(rc) ;
}


/* ----------------------------------------------------------------------- */
int dvb_demux_req_section(struct dvb_state *h, int fd, int pid,
			  int sec, int mask, int oneshot, int timeout)
{
struct dmx_sct_filter_params filter;

	if (dvb_debug>1) _fn_start((char *)__FUNCTION__) ;
	if (dvb_debug>1) {_prt_indent((char *)__FUNCTION__) ; fprintf(stderr, "fd=%d pid=%d sec=%d mask=%d oneshot=%d timeout=%d\n", fd, pid, sec, mask, oneshot, timeout); }

    memset(&filter,0,sizeof(filter));
    filter.pid              = pid;
    filter.filter.filter[0] = sec;
    filter.filter.mask[0]   = mask;
    filter.timeout          = timeout * 1000;
    filter.flags            = DMX_IMMEDIATE_START | DMX_CHECK_CRC;
    if (oneshot)
    	filter.flags       |= DMX_ONESHOT;

    if (-1 == fd) {
    	fd = open(h->demux, O_RDWR);
		if (-1 == fd) {
			if (dvb_debug>1) fprintf(stderr,"dvb mux: [pid %d] open %s: %s\n",
									pid, h->demux, strerror(errno));
			goto oops;
		}
    }
    if (xioctl(fd, DMX_SET_FILTER, &filter) < 0) {
    	if (dvb_debug>1) fprintf(stderr,"dvb mux: [pid %d] ioctl DMX_SET_PES_FILTER: %s\n",
									pid, strerror(errno));
    	goto oops;
    }

	if (dvb_debug>1) _fn_end((char *)__FUNCTION__, 0) ;
    return fd;

 oops:
    if (-1 != fd)
    	close(fd);

	if (dvb_debug>1) _fn_end((char *)__FUNCTION__, -1) ;
	RETURN_DVB_ERROR( ERR_REQ_SECTION );
}


/* ======================================================================= */
/* open/close/tune dvr                                                     */

/* ----------------------------------------------------------------------- */
int dvb_dvr_open(struct dvb_state *h)
{
int rc=0;

	if (dvb_debug>1) _fn_start((char *)__FUNCTION__) ;

	if (-1 == h->dvro)
	{
		h->dvro = open(h->dvr,  O_RDONLY) ;
		if (-1 == h->dvro)
		{
			if (dvb_debug>1) fprintf(stderr,"error opening dvr0: %s\n", strerror(errno));
			SET_ERROR(rc, ERR_DVR_OPEN) ;
		}
	}

	if (dvb_debug>5) _dump_state((char *)__FUNCTION__, "", h);
	if (dvb_debug>1) _fn_end((char *)__FUNCTION__, rc) ;
	return rc ;
}

/* ----------------------------------------------------------------------- */
int dvb_dvr_release(struct dvb_state *h)
{
    if (-1 != h->dvro)
    {
		close(h->dvro);
		h->dvro = -1;
    }

    return 0 ;
}


/* ======================================================================= */
/* open/close/tune dvb devices                                             */

/* ----------------------------------------------------------------------- */
void dvb_fini(struct dvb_state *h)
{
	if (dvb_debug>1) _fn_start((char *)__FUNCTION__) ;

    dvb_frontend_release(h, /* write=1 */ 1);
    dvb_frontend_release(h, /* read=0 */  0);

//Now handled by Perl
//    dvb_demux_filter_release(h);


    // Clear out freq list
    clear_freqlist() ;

    // Close DVB
    dvb_dvr_release(h);
    free(h);

	if (dvb_debug>1) _fn_end((char *)__FUNCTION__, 0) ;
}

/* ----------------------------------------------------------------------- */
struct dvb_state* dvb_init(char *adapter, int frontend)
{
struct dvb_state *h;
int rc = 0 ;

	if (dvb_debug>1) _fn_start((char *)__FUNCTION__) ;

	// clear out errors
	dvb_error_clear() ;

	// create
    h = malloc(sizeof(*h));
    if (NULL == h) {
    	SET_ERROR(rc, ERR_MALLOC) ;
    	goto oops;
    }
    memset(h,0,sizeof(*h));
    h->fdro     = -1;
    h->fdwr     = -1;
    h->dvro     = -1;

    snprintf(h->frontend, sizeof(h->frontend),"%s/frontend%d", adapter, frontend);
    snprintf(h->demux,    sizeof(h->demux),   "%s/demux%d",    adapter, frontend);
    snprintf(h->dvr,      sizeof(h->demux),   "%s/dvr%d",      adapter, frontend);

    if ( (rc=dvb_frontend_open(h, /* read=0 */ 0)) < 0 ) {
    	if (dvb_debug) fprintf(stderr, "dvb init: frontend failed to open : fdro=%d, fdwr=%d\n", h->fdro, h->fdwr);
    	goto oops;
    }

	// get info about the tuner
    if ( (rc=xioctl(h->fdro, FE_GET_INFO, &h->info)) < 0  ) {
		if (dvb_debug) fprintf(stderr, "dvb init: xiotcl FE_GET_INFO failed\n");
		//perror("dvb init: ioctl FE_GET_INFO");
		goto oops;
    }

    // see if we can use auto inversion
    if (h->info.caps & FE_CAN_INVERSION_AUTO)
    {
    	// ok to use auto
    	dvb_inversion = INVERSION_AUTO ;
    }
    else
    {
    	// use the old default of 0
    	dvb_inversion = INVERSION_OFF ;
    }

    if (dvb_debug>1) _fn_end((char *)__FUNCTION__, 0) ;
    return h;

 oops:
    if (h)
    	dvb_fini(h);

    if (dvb_debug>1) _fn_end((char *)__FUNCTION__, rc) ;
    SET_DVB_ERROR(rc) ;
    return NULL;
}

/* ----------------------------------------------------------------------- */
struct dvb_state* dvb_init_nr(int adapter, int frontend)
{
char path[32];

	if (dvb_debug>1) _fn_start((char *)__FUNCTION__) ;

    snprintf(path,sizeof(path),"/dev/dvb/adapter%d",adapter);
	if (dvb_debug>1) _fn_end((char *)__FUNCTION__, 0) ;
    return dvb_init(path, frontend);
}




/* ----------------------------------------------------------------------- */
int dvb_wait_tune(struct dvb_state *h, int timeout)
{
struct dvb_frontend_parameters info ;

	if (dvb_debug>1) _fn_start((char *)__FUNCTION__) ;
	if (dvb_debug>1) _dump_state((char *)__FUNCTION__, "", h);

	if (dvb_debug>1) {_prt_indent((char *)__FUNCTION__) ; fprintf(stderr, "Ensure frontend locked (timeout=%d)\n", timeout); }
    if (0 == timeout)
    {
		if (!dvb_frontend_is_locked(h))
		{
			if (dvb_debug>1) _fn_end((char *)__FUNCTION__, -1) ;
			RETURN_DVB_ERROR(ERR_TUNING_TIMEOUT0) ;
		}
    }
    else
    {
		if (0 != dvb_frontend_wait_lock(h, timeout))
		{
			if (dvb_debug>1) _fn_end((char *)__FUNCTION__, -1) ;
			RETURN_DVB_ERROR(ERR_TUNING_TIMEOUT) ;
		}
    }

	// Update the tuning parameters
    if ( xioctl(h->fdro,FE_GET_FRONTEND,&info) != 0)
    {
        if (dvb_debug>=5)
        {
        	fprintf(stderr, "Error reading FE info\n") ;
        }
    }
    else
    {
        if (dvb_debug>=5)
        {
        	fprintf(stderr, "readback tuning:\n") ;
    		_dump_frontend_params(0, &info) ;
        }

		// Actually, this piece of code is now obsolete since I'm currently only interested in the
		// (rounded) frequency. The scan frequency list only compare entries by frequency. I'm keeping
		// the code in case I want to switch back to checking the other tuning params (satellite decode
		// perhaps?)
		//
		// Anyway, it turns out that some tuners (a) readback all zeroes, or (b) readback a frequency
		// 1 kHz less than actually set! To avoid these problems, I'm actually keeping the requested frequency
		//


		// only overwrite params if these came back correctly - some tuners don't seem to properly support
		// readback
		if (info.frequency > 0)
		{
			// save the frequency to ensure it's correct
			int frequency = h->p.frequency ;

			// update the parameters with the params reported by the DVB tuner
			memcpy(&h->p, &info, sizeof(h->p));

	#ifdef TEST_FREQ_READBACK
			// Debug problem where frequency readback from DVB tuner is not the same as requested
			//
			// requested= 698167000
			// readback=  698166000
			//
			h->p.frequency -= 1000 ;
	#endif

			// restore frequency
			h->p.frequency = frequency ;

			if (dvb_debug>=10)
			{
				fprintf(stderr, "WAIT TUNE : params "); print_params(&h->p) ; fprintf(stderr, "\n");
			}
	
			// update the freq item with these settings
			freqitem_update(&h->p) ;
	
			if (dvb_debug>=5)
			{
				fprintf(stderr, "freqitem update:\n") ;
				_dump_frontend_params(0, &h->p) ;
			}
		}

    }

	if (dvb_debug>1) _fn_end((char *)__FUNCTION__, 0) ;
    return 0;
}


