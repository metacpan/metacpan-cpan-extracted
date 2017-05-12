/*
 */

/*=============================================================================================*/
// USES
/*=============================================================================================*/

#include <features.h>

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <ctype.h>
#include <fcntl.h>
#include <inttypes.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/ioctl.h>

#include "dvb_lib.h"
#include "dvb_tune.h"
#include "dvb_stream.h"
#include "dvb_debug.h"
#include "dvb_error.h"

#include "ts_parse.h"

// Added for EIT decoding
#include "tables/parse_si_eit.h"


/*=============================================================================================*/
// CONSTANTS
/*=============================================================================================*/

//#define TEST_NO_EIT
#define TIMESTAMP_PRINT


// DVR buffer read timeout
#define TIMEOUT_SECS	3

// Max delay before now/next service should have been seen
// One or other is usually available after 7 secs; both after 20 secs
#define GET_EIT_DELAY	10
#define EIT_NEXT_DELAY	30


/*=============================================================================================*/
// MACROS
/*=============================================================================================*/

#ifdef TIMESTAMP_PRINT
#define dvbstream_fprintf				fprintf_timestamp
#define dvbstream_dbg_prt(LVL, ARGS)	\
		if (tsreader->debug >= LVL)	{ printf_timestamp ARGS ; fflush(stdout) ; }
#else
#define dvbstream_fprintf				fprintf
#define dvbstream_dbg_prt(LVL, ARGS)	tsparse_dbg_prt(LVL, ARGS)
#endif


/*=============================================================================================*/
// STRUCTS
/*=============================================================================================*/

struct Timeslip_data {
	struct multiplex_pid_struct 	*pid_list ;
	unsigned 						num_entries ;
};


/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

#ifdef PROFILE_STREAM

#undef TS_BUFFSIZE
#define TS_BUFFSIZE 188

#define BINS_TIME			10
#define clear_bins(bins)	memset(bins, 0, (TS_BUFFSIZE+1)*sizeof(unsigned))
#define inc_bin(bins, bin)	if ((bin>=0) && (bin <= TS_BUFFSIZE)) { ++bins[bin]; }

/* ----------------------------------------------------------------------- */
void show_bins(unsigned *bins)
{
unsigned bin ;

	printf("Read histogram: ") ;
	for (bin=0; bin <= TS_BUFFSIZE; ++bin)
	{
		if (bins[bin])
		{
			printf("%d=%d, ", bin, bins[bin]) ;
		}
	}
	printf("\n") ;
}
#endif

/* ----------------------------------------------------------------------- */
// Wait for data ready or timeout
int
input_timeout (int filedes, unsigned int seconds)
{
   fd_set set;
   struct timeval timeout;

   /* Initialize the file descriptor set. */
   FD_ZERO (&set);
   FD_SET (filedes, &set);

   /* Initialize the timeout data structure. */
   timeout.tv_sec = seconds;
   timeout.tv_usec = 0;

   /* select returns 0 if timeout, 1 if input available, -1 if error. */
   return TEMP_FAILURE_RETRY (select (FD_SETSIZE,
                                      &set, NULL, NULL,
                                      &timeout));
}




/* ----------------------------------------------------------------------- */
int getbuff(struct dvb_state *h, char *buffer, int *count)
{
int rc ;
int status ;
int data_ready ;
fe_status_t  fe_status  = 0;
int read_count = *count ;


	status = 0 ;

	// wait for data (or time out)
	data_ready = input_timeout(h->dvro, TIMEOUT_SECS) ;
	if (data_ready != 1)
	{
		if (dvb_debug >= 10) fprintf(stderr,"reading %d bytes\n", *count);
		if (data_ready < 0)
		{
			//perror("read");
			RETURN_DVB_ERROR(ERR_SELECT);
		}
		else
		{
			//fprintf_timestamp(stderr,"timed out\n");
			RETURN_DVB_ERROR(ERR_TIMEOUT);
		}
#ifdef PROFILE_STREAM
perror("data ready error : ");
#endif
	}

	// got to here so data is available
	rc = read(h->dvro, buffer, read_count);

	// return actual read amount
	if (rc > 0)
	{
		*count = rc ;
	}
	else
	{
#ifdef PROFILE_STREAM
perror("read error : ");
#endif
		if (errno == EOVERFLOW)
		{
			// ignore overflow error
			status = ERR_OVERFLOW ;
			rc = 1 ;
		}
		else
		{
			// some problem - show frontend status
			if (-1 != ioctl(h->fdro, FE_READ_STATUS, &fe_status))
			{
				if (dvb_debug) fprintf_timestamp(stderr, ">>> tuning status == 0x%04x\n", fe_status) ;
			}
		}
	}

if (dvb_debug >= 10) fprintf(stderr, "getbuff(): request=%d read=%d\n", *count, rc) ;

	switch (rc) {
	case -1:
		//fprintf_timestamp(stderr,"reading %d bytes\n", count);
		//perror("read");
		RETURN_DVB_ERROR(ERR_READ);
	case 0:
		//fprintf_timestamp(stderr,"EOF\n");
		RETURN_DVB_ERROR(ERR_EOF);

	default:
		break;
	}
	return(status) ;
}

/* ----------------------------------------------------------------------- */
int write_stream(struct dvb_state *h, char *filename, int sec)
{
time_t start, end, now, prev;
char buffer[TS_BUFFSIZE];
int file;
int count;
int rc, nwrite;
unsigned done ;

    if (sec <= 0)
    {
		//fprintf(stderr, "Invalid duration (%d)\n", sec);
    	RETURN_DVB_ERROR(ERR_DURATION);
    }

    if (-1 == h->dvro)
    {
		//fprintf(stderr,"dvr device not open\n");
		RETURN_DVB_ERROR(ERR_DVR_OPEN);
    }

    file = open(filename, O_WRONLY | O_TRUNC | O_CREAT | O_LARGEFILE, 0666);
    if (-1 == file) {
		//fprintf(stderr,"open %s: %s\n",filename,strerror(errno));
		RETURN_DVB_ERROR(ERR_FILE);
    }

    count = 0;
    start = time(NULL);
    end = sec + time(NULL);
	for (done=0; !done;)
	{
		rc = read(h->dvro, buffer, sizeof(buffer));
		switch (rc) {
		case -1:
			//perror("read");
			RETURN_DVB_ERROR(ERR_READ);
		case 0:
			//fprintf(stderr,"EOF\n");
			RETURN_DVB_ERROR(ERR_EOF);
		default:
			nwrite = write(file, buffer, rc);
			count += rc;
			break;
		}
		now = time(NULL);

		if (dvb_debug)
		{
			if (prev != now)
			{
				fprintf(stderr, "%d / %d : %d bytes\n", (int)(now-start), (int)(end-start), rc) ;
				prev = now ;
			}
		}

		if (now >= end)
		{
			++done ;
			break;
		}
	}
    
    close(file);

    return 0;
}



//=======================================================================================================================
// Using TS parser to add functionality
//=======================================================================================================================

//---------------------------------------------------------------------------------------------------------------------------
static void eit_handler(struct TS_reader *tsreader, struct TS_state *tsstate, struct Section *section, void *user_data)
{
struct Timeslip_data *timeslip_data = (struct Timeslip_data *)user_data ;
struct Section_event_information *eit = (struct Section_event_information *)section ;
unsigned pid_index ;

	dvbstream_dbg_prt(3, ("Called eit_handler with : 0x%02x TSID %d\n", eit->table_id, eit->transport_stream_id)) ;

	// expect there to be only one currently running & one pending program per channel (service_id)

	// update all of the pids that have a matching event_id
	for (pid_index=0; (pid_index < timeslip_data->num_entries); ++pid_index)
	{
		// check that we specified an event to find
		if (timeslip_data->pid_list[pid_index].event_id >= 0)
		{
			dvbstream_dbg_prt(3, ("EV: check service id %d : list id = %d\n",
				eit->service_id,
				timeslip_data->pid_list[pid_index].pnr)) ;

			// match program number
			if (timeslip_data->pid_list[pid_index].pnr == eit->service_id)
			{
				// find the event
				struct list_head  *item, *safe;
				struct EIT_entry  *eit_entry;

				list_for_each_safe(item,safe,&eit->eit_array) {
					eit_entry = list_entry(item, struct EIT_entry, next);

					if (dvb_debug >= 1)
						dvbstream_fprintf(stderr, "EV: check event id %d, running = %d: list event id = %d\n",
							eit_entry->event_id,
							eit_entry->running_status,
							timeslip_data->pid_list[pid_index].event_id
							) ;

					if (eit_entry->event_id == timeslip_data->pid_list[pid_index].event_id)
					{
						timeslip_data->pid_list[pid_index].running_status = eit_entry->running_status ;

						dvbstream_dbg_prt(3, ("EVENT + PID %d : pnr %d event %d - running = %d\n",
							tsstate->pidinfo.pid,
							eit->service_id,
							eit_entry->event_id,
							eit_entry->running_status
							)) ;
					}
					else
					{
						// if another service is running, then this one can't be
						if (eit_entry->running_status == RUNNING_STATUS_RUNNING)
						{
							if (timeslip_data->pid_list[pid_index].running_status == RUNNING_STATUS_RUNNING)
							{
								timeslip_data->pid_list[pid_index].running_status = RUNNING_STATUS_COMPLETE ;
							}
						}

					}

					// NOTE: Due to the asynchronous arrival of the now & next events (which are independent), can't assume
					// that the event id's will cycle correctly. For example, where we have a set of programs A -> B -> C
					// the now/next event ids can present as:
					//
					//	now		next
					//	--------------
					//	undef	undef		start
					//	undef	B			B next event arrives
					//	A		B			A now event arrives
					//	A		C			C next event arrives
					//	B		C			B now event arrives
					//
					//	rather than the easier to handle:
					//
					//	now		next
					//	--------------
					//	undef	undef
					//	A		undef
					//	A		B
					//	B		C
					//
					//	so we can't assume anything about the pair of indicators
					//
					//

					// track the current running/pending events
					if (eit_entry->running_status == RUNNING_STATUS_RUNNING)
					{
						timeslip_data->pid_list[pid_index].running_event_id = eit_entry->event_id ;
						timeslip_data->pid_list[pid_index].got_eit = 1 ;
					}
					else if (eit_entry->running_status == RUNNING_STATUS_PENDING)
					{
						timeslip_data->pid_list[pid_index].pending_event_id = eit_entry->event_id ;
						timeslip_data->pid_list[pid_index].got_eit = 1 ;
					}

				};
			}
		}
	}
}


/* ----------------------------------------------------------------------- */
int write_stream_demux(struct dvb_state *h, struct multiplex_pid_struct *pid_list, unsigned num_entries)
{
time_t now, prev, end_time;
char buffer[TS_BUFFSIZE];
char *bptr ;
int status, final_status;
int rc, wrc;
unsigned ts_pid, ts_err ;
unsigned pid_index ;
int running ;
unsigned running_timeslip ;
int buffer_len ;
int bytes_read ;
char debugstr[1024] ;

struct TS_reader *tsreader ;
struct Timeslip_data timeslip_data ;
struct Section_decode_flags flags ;

	// Initialise the TS parser
	running_timeslip = 0 ;
	tsreader = tsreader_new_nofile() ;
	tsreader_data_start(tsreader) ;

	timeslip_data.num_entries = num_entries ;
	timeslip_data.pid_list = pid_list ;
	tsreader->user_data = &timeslip_data ;

#ifdef TEST_NO_EIT

    dvbstream_fprintf(stderr, "**TEST MODE: TESTING NO EIT DATA**\n") ;

#endif


if (dvb_debug >= 4)
	tsreader->debug = dvb_debug ;


#ifdef PROFILE_STREAM
unsigned read_bins[TS_BUFFSIZE+1] ;
time_t bins_time ;
#endif

    if (-1 == h->dvro)
    {
    	if (dvb_debug >= 2)
    		dvbstream_fprintf(stderr,"dvr device not open\n");

		RETURN_DVB_ERROR(ERR_DVR_OPEN);
    }

    // make access to demux non-blocking
    setNonblocking(h->dvro) ;

    // sticky error
    final_status = 0 ;

#ifdef PROFILE_STREAM
    clear_bins(read_bins) ;
    bins_time = time(NULL) + BINS_TIME ;
#endif

	// find end time
    end_time = 0 ;
	for (pid_index=0; pid_index < num_entries; ++pid_index)
	{
		if (end_time < pid_list[pid_index].file_info->end)
		{
			end_time = pid_list[pid_index].file_info->end;
		}

		// check timeslip
		if (pid_list[pid_index].max_timeslip == 0)
		{
			// cancel timeslip
			pid_list[pid_index].event_id = -1 ;
			pid_list[pid_index].timeslip_start = 0 ;
			pid_list[pid_index].timeslip_end = 0 ;

		}
		if (pid_list[pid_index].event_id >= 0)
		{
			running_timeslip = 1 ;
		}

		// Display settings
		if (dvb_debug)
		{
			dvbstream_fprintf(stderr, "(%02d) PID %d : pnr=%d event=%d timeslip [start %d, end %d] max=%d\n",
					pid_index,
					pid_list[pid_index].pid,
					pid_list[pid_index].pnr,
					pid_list[pid_index].event_id,
					pid_list[pid_index].timeslip_start,
					pid_list[pid_index].timeslip_end,
					pid_list[pid_index].max_timeslip) ;
		}
	}

	// Only add the overhead of parsing the EITs if something requires timeslip
	if (running_timeslip)
	{
	    // register an interest
	    flags.decode_descriptor = 0 ;
	    int num_added = tsreader_register_section(tsreader,
	    		SECTION_EIT_NOW_ACTUAL, 0xff,
	    		eit_handler, flags) ;

	}


    // main loop
    running = num_entries ;
	buffer_len = 0 ;
	bptr = buffer ;
	prev = time(NULL);
    while (running > 0)
    {
		// start of each packet
		now = time(NULL);

		// check for request for new bytes
		if (buffer_len < TS_PACKET_LEN)
		{
			// next packets
			bytes_read = TS_BUFFSIZE_READ ;
			status = getbuff(h, buffer, &bytes_read) ;

			// special case of buffer overflow - update counts then continue
			if (status == ERR_OVERFLOW)
			{
				// increment counts
				for (pid_index=0; pid_index < num_entries; ++pid_index)
				{
					if (!pid_list[pid_index].done)
					{
						pid_list[pid_index].overflows++;
					}
				}
				status = ERR_NONE ;

				// check for end
				if (now > end_time)
				{
					running = 0 ;

					if (dvb_debug)
							dvbstream_fprintf(stderr, " + + Force stop all due now (%d) > end (%d)\n",
									(int)now,
									(int)end_time
									) ;
					break ;
				}
				continue ;
			}

			if (!final_status) final_status = status ;
			buffer_len = bytes_read ;
			bptr = buffer ;

			if (dvb_debug >= 10)
				dvbstream_fprintf(stderr, "Reload buffer : 0x%02x (bptr @ %p) %d bytes left\n", buffer_len?bptr[0]:0, bptr, buffer_len) ;

#ifdef PROFILE_STREAM
			inc_bin(read_bins, bytes_read) ;
#endif
		}


		if (dvb_debug >= 10)
			dvbstream_fprintf(stderr, "Start of loop : 0x%02x (bptr @ %p) %d bytes left\n", buffer_len?bptr[0]:0, bptr, buffer_len) ;

		// reset to a value that won't ever match
		ts_pid = NULL_PID ;

		// check sync byte
		while ( (bptr[0] != SYNC_BYTE) && (buffer_len > 0) )
		{
			if (dvb_debug >= 10)
				dvbstream_fprintf(stderr, "! Searching for sync : 0x%02x (bptr @ %p) len=%d\n", buffer_len?bptr[0]:0, bptr, buffer_len) ;

			++bptr ;
			--buffer_len ;
		}

		// only process if we have a packet's worth
		if (buffer_len >= TS_PACKET_LEN)
		{
			/* decode header
			#	sync_byte 8 bslbf
			#
			#	transport_error_indicator 1 bslbf
			#	payload_unit_start_indicator 1 bslbf
			#	transport_priority 1 bslbf
			#	PID 13 uimsbf
			#
			#	transport_scrambling_control 2 bslbf
			#	adaptation_field_control 2 bslbf
			#	continuity_counter 4 uimsbf
			#
			#	if(adaptation_field_control = = '10' || adaptation_field_control = = '11'){
			#		adaptation_field()
			#	}
			#	if(adaptation_field_control = = '01' || adaptation_field_control = = '11') {
			#		for (i = 0; i < N; i++){
			#		data_byte 8 bslbf
			#		}
			#	}
			*/
			ts_err = bptr[1] & 0x80 ;
			ts_pid = ((bptr[1] & 0x1f) << 8) | (bptr[2] & 0xff) & MAX_PID ;
			if (dvb_debug >= 10)
			{
				if (prev != now)
				{
					dvbstream_fprintf(stderr, "-> TS PID 0x%x (%u)\n", ts_pid, ts_pid) ;
				}
			}

#ifndef TEST_NO_EIT

			// TS parse
			if (running_timeslip)
			{
				tsreader_data_add(tsreader, buffer, buffer_len) ;
			}
#endif

		}

		// search the pid list for a match (also keep done flags up to date - in case there are no packets for this pid!)
		for (pid_index=0; pid_index < num_entries; ++pid_index)
		{
			// debug display
			if (dvb_debug)
			{
				if (prev != now)
				{
					if (pid_index==0)
					{
						dvbstream_fprintf(stderr, "%d Running / %d Total\n", running, num_entries);
					}

					sprintf(debugstr, "[File %02d] (%02d) + + PID %d : %"PRIu64" pkts (%"PRIu64" errors) : [event %d run %d] : [now %d next %d : got EIT %u] : now=%d, end=%d, file end=%d : ",
							(int)pid_list[pid_index].file_info->file,
							pid_index,
							pid_list[pid_index].pid,
							pid_list[pid_index].pkts,
							pid_list[pid_index].errors,
							pid_list[pid_index].event_id,
							pid_list[pid_index].running_status,
							pid_list[pid_index].running_event_id,
							pid_list[pid_index].pending_event_id,
							pid_list[pid_index].got_eit,
							(int)now,
							(int)end_time,
							(int)pid_list[pid_index].file_info->end
							) ;

					if (pid_list[pid_index].done)
					{
						strcat(debugstr, "complete") ;
					}
					else
					{
						if (now >= pid_list[pid_index].file_info->start)
						{
							if (pid_list[pid_index].started)
							{
								if (now <= pid_list[pid_index].file_info->end)
								{
									sprintf(debugstr, "%s recording (%d secs remaining)",
										debugstr,
										(int)(pid_list[pid_index].file_info->end - now)) ;
								}
								else
								{
									sprintf(debugstr, "%s recording (+%d secs slipped)",
										debugstr,
										(int)(now - pid_list[pid_index].file_info->end)) ;
								}
							}
							else
							{
								sprintf(debugstr, "%s timeslipping start by %d secs ...",
									debugstr,
									(int)(now - pid_list[pid_index].file_info->start)) ;
							}
						}
						else
						{
							sprintf(debugstr, "%s starting in %d secs ...",
								debugstr,
								(int)(pid_list[pid_index].file_info->start - now)) ;
						}
					}

					if (dvb_debug >= 2)
					{
						dvbstream_fprintf(stderr, "%s [buff len=%d]\n", debugstr, buffer_len) ;
					}
					else
					{
						dvbstream_fprintf(stderr, "%s\n", debugstr) ;
					}
				}
			} // dvb_debug

#ifdef PROFILE_STREAM
			if (now >= bins_time)
			{
				show_bins(read_bins) ;
				clear_bins(read_bins) ;
				bins_time = time(NULL) + BINS_TIME ;
			}

//			usleep(10000) ;
#endif


			// skip if done
			if (!pid_list[pid_index].done)
			{
				//----------------------------------------------------------
				// START

				// check start time
				if (!pid_list[pid_index].started && (now >= pid_list[pid_index].file_info->start))
				{
					unsigned started = 0 ;

					// track start timeslip
					pid_list[pid_index].timeslip_start_secs = (unsigned)(now - pid_list[pid_index].file_info->start) ;

					// check for timeslipping start
					if (pid_list[pid_index].timeslip_start)
					{
						// check for timeout
						if (now - pid_list[pid_index].file_info->start >= pid_list[pid_index].max_timeslip)
						{
							// got to start now
							started = 1 ;

							if (dvb_debug)
									dvbstream_fprintf(stderr, " + + PID %d : Force start due to MAX TIMESLIP (%d) timeout\n",
											pid_list[pid_index].pid,
											pid_list[pid_index].max_timeslip
											) ;
						}
						else
						{
							// check status
							if (pid_list[pid_index].running_status >= RUNNING_STATUS_RUNNING)
							{
								started = 1 ;

								if (dvb_debug)
										dvbstream_fprintf(stderr, " + + PID %d : start due EIT now RUNNING\n",
												pid_list[pid_index].pid
												) ;
							}
						}

						// Catch the error case where the now/next service is not running (or program recording
						// has started too early/late or with the wrong event id)
						//
						// Pending event id should be set within 7 secs and it should be the program we're about the record.
						// If we've started recording in the middle of the required program, then the eit handler will have
						// set the running status and we'll automatically start recording
						//
						if (!started && !pid_list[pid_index].got_eit)
						{
							// check for timeout
							if (pid_list[pid_index].timeslip_start_secs >= GET_EIT_DELAY)
							{
								// force a start now since we're unlikely to get the now/next info
								started = 1 ;

								if (dvb_debug)
										dvbstream_fprintf(stderr, " + + PID %d : Force start due to GET_EIT timeout\n",
												pid_list[pid_index].pid
												) ;
							}
						}
						if (!started && (pid_list[pid_index].event_id != pid_list[pid_index].pending_event_id))
						{
							// check for timeout
							if (pid_list[pid_index].timeslip_start_secs >= EIT_NEXT_DELAY)
							{
								// force a start now since we're unlikely to get the now/next info
								started = 1 ;

								if (dvb_debug)
										dvbstream_fprintf(stderr, " + + PID %d : Force start due to EIT NEXT timeout\n",
												pid_list[pid_index].pid
												) ;
							}
						}
					}
					else
					{
						// ok to start
						started = 1 ;

						if (dvb_debug)
								dvbstream_fprintf(stderr, " + + PID %d : start now (no timeslip)\n",
										pid_list[pid_index].pid
										) ;
					}

					// start now?
					pid_list[pid_index].started |= started ;

					// update file end (and maximum end time)
					pid_list[pid_index].file_info->end = (now + pid_list[pid_index].file_info->duration) ;
					if (end_time < pid_list[pid_index].file_info->end)
					{
						end_time = pid_list[pid_index].file_info->end;
					}

				} // !started AND (now >= start)


				//----------------------------------------------------------
				// WRITE

				// matching pid?
				if (ts_pid == pid_list[pid_index].pid)
				{

					// see if we've now started recording
					if (pid_list[pid_index].started)
					{
						// write this packet to the corresponding file
						wrc=write(pid_list[pid_index].file_info->file, bptr, TS_PACKET_LEN);

						// error count
						if (ts_err)
						{
							pid_list[pid_index].errors++;
						}

						// debug
						pid_list[pid_index].pkts++;

						if (dvb_debug >= 10)
							dvbstream_fprintf(stderr, " + + Written PID %u : total %"PRIu64" pkts (%"PRIu64" errors) : ",
									pid_list[pid_index].pid,
									pid_list[pid_index].pkts,
									pid_list[pid_index].errors
									) ;

					} // started

				} // transport stream pid == this pid


				//----------------------------------------------------------
				// END

				// check end time - mark as done if elapsed
				if (now > pid_list[pid_index].file_info->end)
				{
					unsigned done =0 ;

					// check for timeslipping end
					if (pid_list[pid_index].timeslip_end)
					{
						// track end timeslip
						pid_list[pid_index].timeslip_end_secs = (unsigned)(now - pid_list[pid_index].file_info->end) ;

						// check for timeout
						if (now - pid_list[pid_index].file_info->end >= pid_list[pid_index].max_timeslip)
						{
							// got to stop now
							done = 1 ;

							if (dvb_debug)
									dvbstream_fprintf(stderr, " + + PID %d : Force end due to MAX TIMESLIP (%d) timeout\n",
											pid_list[pid_index].pid,
											pid_list[pid_index].max_timeslip
											) ;
						}
						else
						{
							// check status
							if (pid_list[pid_index].running_status > RUNNING_STATUS_RUNNING)
							{
								done = 1 ;

								if (dvb_debug)
										dvbstream_fprintf(stderr, " + + PID %d : end due to EIT running NOT RUNNING\n",
												pid_list[pid_index].pid
												) ;
							}
						}



						// Catch the error case where the now/next service is not running (or program recording
						// has started too early/late or with the wrong event id)
						if (!done &&
							(pid_list[pid_index].event_id != pid_list[pid_index].running_event_id) &&
							(pid_list[pid_index].event_id != pid_list[pid_index].pending_event_id)
						)
						{
							// check for timeout
							if (pid_list[pid_index].timeslip_end_secs >= EIT_NEXT_DELAY)
							{
								// force a stop now since we're unlikely to get the now/next info
								done = 1 ;

								if (dvb_debug)
										dvbstream_fprintf(stderr, " + + PID %d : Force end due to EIT NEXT timeout\n",
												pid_list[pid_index].pid
												) ;

							}
						}

					}
					else
					{
						// ok to stop
						done = 1 ;

						if (dvb_debug)
								dvbstream_fprintf(stderr, " + + PID %d : Force end (no timeslip)\n",
										pid_list[pid_index].pid
										) ;
					}

					// set flag?
					if (done)
					{
						pid_list[pid_index].done = 1 ;
						--running ;
					}
					else
					{
						// adjust max end time while we're time slipping this pid
						if (end_time < now + EIT_NEXT_DELAY)
						{
							// allow enough time to see the timeout
							end_time = now + EIT_NEXT_DELAY + 1;
						}

					}

				} // Timeslipping End : now > end

			} // !done

		} // for each pid

		//----------------------------------------------
		// update buffer
		if (buffer_len >= TS_PACKET_LEN)
		{
			buffer_len -= TS_PACKET_LEN ;
			bptr += TS_PACKET_LEN ;
		}

		prev = now ;

		if (dvb_debug >= 10)
			dvbstream_fprintf(stderr, "End of loop : 0x%02x (bptr @ %p) %d bytes left\n", buffer_len?bptr[0]:0, bptr, buffer_len) ;

    } // while running


	// terminate the TS parser
	tsreader_data_end(tsreader) ;
	tsreader_free(tsreader) ;


    return final_status;
}


