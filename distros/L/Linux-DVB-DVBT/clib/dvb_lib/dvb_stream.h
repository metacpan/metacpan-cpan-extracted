#ifndef DVB_STREAM
#define DVB_STREAM

#include <inttypes.h>
#include "dvb_struct.h"

#define EVENT_ID_UNDEF		-1

struct multiplex_file_struct {
	int								file;
	time_t 							start;
	time_t 							duration;
	time_t 							end;
} ;

struct multiplex_pid_struct {
    struct multiplex_file_struct	 *file_info ;
    unsigned int                     pid;
    unsigned int                     started;
    unsigned int                     done;
    uint64_t						 errors;
    uint64_t						 overflows;
    uint64_t	                     pkts;
    unsigned int                     timeslip_start_secs;
    unsigned int                     timeslip_end_secs;

    // New - used for tracking event start/stop
    unsigned						 pnr ;
    int	                         	 event_id ;			// id=-1 means unset (event_id = 0 is a valid id)
    unsigned                         running_status ;
    unsigned                         timeslip_start ;	// flag: when set allows timeslip of start of prog
    unsigned                         timeslip_end ;		// flag: when set allows timeslip of end of prog
    unsigned                         max_timeslip ;

    // track the current running/pending events
	int								running_event_id ;
	int								pending_event_id ;
	unsigned						got_eit ;			// flag set when either the now or next event id is set

    // internal (Perl)
    void							 *ref ;

} ;


/* ----------------------------------------------------------------------- */
int write_stream(struct dvb_state *h, char *filename, int sec) ;

/* ----------------------------------------------------------------------- */
int write_stream_demux(struct dvb_state *h, struct multiplex_pid_struct *pid_list, unsigned num_entries) ;
int write_stream_demux2(struct dvb_state *h, struct multiplex_pid_struct *pid_list, unsigned num_entries);

#endif
