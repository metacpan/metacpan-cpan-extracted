#ifndef DVB_TUNING
#define DVB_TUNING


#include "dvb_struct.h"
#include "parse-mpeg.h"


// round up frequency to nearest kHz
#define ROUND_FREQUENCY(freq)	(int)(((float)freq / 1000.0) + 0.5 ) * 1000

//  Frequency must be at least 100 MHz
//  The Stockholm agreement of 1961 says:
//    Band III  : 174 MHz - 230 MHz
//    Band IV/V : 470 MHz - 826 MHz
//
//  Current dvb-t files range: 177.5 MHz - 858 MHz
//
//  So 100 MHz allows for country "variations"!
//
#define MIN_FREQ		100000000
#define VALID_FREQ(f)	((f) >= MIN_FREQ ? 1 : 0)


// Default is to use 'auto'
#define VDR_MAX 		999
#define TUNING_AUTO		VDR_MAX


int xioctl(int fd, int cmd, void *arg);
int dvb_frontend_open(struct dvb_state *h, int write);


// Tuning params stored in "VDR" integer format (e.g. code rate=34)
struct tuning_params {
	int frequency;
	int inversion;
	int bandwidth;
	int code_rate_high;
	int code_rate_low;
	int modulation;
	int transmission;
	int guard_interval;
	int hierarchy;
} ;

/* ----------------------------------------------------------------------- */
struct freqitem {
    struct list_head    next;

    int                 frequency;				// convenience copy of frequency (NB: Freq is in Hz for dvb-t)
    struct dvb_frontend_parameters	params ;	// frontend format (enums)
    
	/* signal quality measure */
	unsigned 		ber ;
	unsigned		snr ;
	unsigned		strength ;
	unsigned		uncorrected_blocks ;	// if we use this then need to time it and account for wrap!
    
	// various flags used during scan    
    struct {
    	unsigned seen	: 1 ;	// set if we've attempted to tune to this freq
    	unsigned tuned	: 1 ;	// set if successfully tuned to this freq
    } flags ;
};

extern struct list_head freq_list ;

struct freqitem* freqitem_get(struct dvb_frontend_parameters *params) ;
struct freqitem* freqitem_get_from_stream(struct psi_stream *stream) ;
void clear_freqlist() ;
void print_freqi(struct freqitem   *freqi) ;
void print_freqs() ;

// conversion utilities
void params_stream_to_vdr(struct psi_stream *stream, struct tuning_params *vdr_params) ;
void params_vdr_to_frontend(struct tuning_params *vdr_params, struct dvb_frontend_parameters *params) ;
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
		struct dvb_frontend_parameters *params) ;


/* ----------------------------------------------------------------------- */

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
) ;

int dvb_wait_tune(struct dvb_state *h, int timeout) ;

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
) ;

int dvb_select_channel(struct dvb_state *h,
		int frequency,
		int inversion,
		int bandwidth,
		int code_rate_high,
		int code_rate_low,
		int modulation,
		int transmission,
		int guard_interval,
		int hierarchy,

		int vpid,
		int apid,

		int sid
) ;

void dvb_frontend_release(struct dvb_state *h, int write);
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
);
//int dvb_tune_from_stream(struct dvb_state *dvb, struct psi_stream *stream, int timeout) ;

int dvb_frontend_is_locked(struct dvb_state *h);
int dvb_frontend_wait_lock(struct dvb_state *h, int timeout);
int dvb_finish_tune(struct dvb_state *h, int timeout);

int dvb_signal_quality(struct dvb_state *h, 
	unsigned 		*ber,
	unsigned		*snr,
	unsigned		*strength,
	unsigned		*uncorrected_blocks
) ;

void dvb_frontend_tune_info(struct dvb_state *h) ;

/* ======================================================================= */
/* handle dvb demux                                                        */

void dvb_demux_filter_setup(struct dvb_state *h, int video, int audio);
int dvb_demux_filter_apply(struct dvb_state *h);
void dvb_demux_filter_release(struct dvb_state *h);
int dvb_demux_get_section(int fd, unsigned char *buf, int len) ;
int dvb_demux_req_section(struct dvb_state *h, int fd, int pid,
			  int sec, int mask, int oneshot, int timeout) ;

/* ======================================================================= */
/* handle dvb dvr                                                          */

int dvb_dvr_open(struct dvb_state *h) ;
int dvb_dvr_release(struct dvb_state *h) ;

/* ======================================================================= */
/* open/close/tune dvb devices                                             */

struct dvb_state* dvb_init(char *adapter, int frontend);
struct dvb_state* dvb_init_nr(int adapter, int frontend);
void dvb_fini(struct dvb_state *h);

#endif
