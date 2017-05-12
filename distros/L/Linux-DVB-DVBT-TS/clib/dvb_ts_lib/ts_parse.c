/*
 * ts_parse.c
 *
 *  Created on: 28 Apr 2010
 *      Author: sdprice1
 */

// VERSION = 2.00

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <ctype.h>
#include <fcntl.h>
#include <inttypes.h>

#include "ts_parse.h"
#include "ts_bits.h"
#include "tables/parse_si.h"
#include "dvbsnoop/crc32.h"

/*=============================================================================================*/
// libmpeg2
void dump_state (FILE * f, mpeg2_state_t state, const mpeg2_info_t * info,
		 int offset, int verbose);

/*=============================================================================================*/

// Check for PTS/DTS wrap
#define MAX_TS_DIFF		(60 * TS_FREQ)
#define TS_WRAP			(1LL << 33)

// libmpeg2 states
static char *STATE_STRINGS[16] = {
			[0 ... 15]	= "UNKNOWN",
		    [STATE_BUFFER] = "STATE_BUFFER",
		    [STATE_SEQUENCE] = "STATE_SEQUENCE",
		    [STATE_SEQUENCE_REPEATED] = "STATE_SEQUENCE_REPEATED",
		    [STATE_GOP] = "STATE_GOP",
		    [STATE_PICTURE] = "STATE_PICTURE",
		    [STATE_SLICE_1ST] = "STATE_SLICE_1ST",
		    [STATE_PICTURE_2ND] = "STATE_PICTURE_2ND",
		    [STATE_SLICE] = "STATE_SLICE",
		    [STATE_END] = "STATE_END",
		    [STATE_INVALID] = "STATE_INVALID",
		    [STATE_INVALID_END] = "STATE_INVALID_END",
		    [STATE_SEQUENCE_MODIFIED] = "STATE_SEQUENCE_MODIFIED"
} ;



// mpeg2audio settings
#define AUDIOBUFFER		80000
#define STORAGE_SIZE 	100000
#define MIN_BUFFER 		4000


//define DEBUG_PTS

#define CHECK_MAGIC
#ifndef CHECK_MAGIC
#undef CHECK_TS_READER
#define CHECK_TS_READER(b)
#undef CHECK_TS_BUFF
#define CHECK_TS_BUFF(b)
#endif


/*=============================================================================================*/
#define FRAMEINFO_BLOCKSIZE		1024

//---------------------------------------------------------------------------------------------------------------------------
// Return the frame info array entry for this index. Allocates more memory as appropriate
struct TS_frame_info *frame_info_entry(struct TS_reader *tsreader, unsigned index)
{
	CHECK_TS_READER(tsreader) ;

	// Allocate if not already allocated
	if (!tsreader->mpeg2.frame_info_list)
	{
		tsreader->mpeg2.frame_info_list_size = FRAMEINFO_BLOCKSIZE ;
		tsreader->mpeg2.frame_info_list = (struct TS_frame_info *)malloc(tsreader->mpeg2.frame_info_list_size * sizeof(struct TS_frame_info)) ;
		memset(tsreader->mpeg2.frame_info_list, 0, tsreader->mpeg2.frame_info_list_size * sizeof(struct TS_frame_info)) ;
	}

	// If index > array size, expand
	if (index >= tsreader->mpeg2.frame_info_list_size)
	{
		tsreader->mpeg2.frame_info_list_size += FRAMEINFO_BLOCKSIZE ;
		tsreader->mpeg2.frame_info_list = (struct TS_frame_info *)realloc(tsreader->mpeg2.frame_info_list, tsreader->mpeg2.frame_info_list_size * sizeof(struct TS_frame_info)) ;
		memset(&tsreader->mpeg2.frame_info_list[tsreader->mpeg2.frame_info_list_size - FRAMEINFO_BLOCKSIZE], 0, FRAMEINFO_BLOCKSIZE * sizeof(struct TS_frame_info)) ;
	}

	return &tsreader->mpeg2.frame_info_list[index] ;
}

//---------------------------------------------------------------------------------------------------------------------------
// Free the frame info array
void free_frame_info_list(struct TS_reader *tsreader)
{
	CHECK_TS_READER(tsreader) ;
	if (tsreader->mpeg2.frame_info_list_size)
	{
		tsreader->mpeg2.frame_info_list_size = 0 ;
		free(tsreader->mpeg2.frame_info_list) ;
		tsreader->mpeg2.frame_info_list = NULL ;
	}
}


/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void dump_buff(const uint8_t *payload, unsigned payload_len, unsigned display_len)
{
unsigned byte ;

	if ((display_len == 0) || (display_len > payload_len))
		display_len = payload_len ;

	printf("---[ Len: %d  Displaying: %d ]------------------------------------------\n", payload_len, display_len) ;
	for (byte=0; byte < display_len; ++byte)
	{
		if (byte % 32 == 0)
		{
			printf("%04x: ", byte) ;
		}
		printf("%02x ", payload[byte]) ;
		if (byte % 8 == 7)
		{
			printf(" - ") ;
		}
		if (byte % 32 == 31)
		{
			printf("\n") ;
		}
	}
	if (display_len < payload_len)
	{
		printf("[") ;
		for (; (byte < display_len+3) && (byte < payload_len); ++byte)
		{
			printf("%02x ", payload[byte]) ;
			if (byte % 32 == 31)
			{
				printf("\n") ;
			}
		}
		printf("... ]") ;
	}
	printf("\n------------------------------------------------------------\n") ;
}


/*=============================================================================================*/
// TS_buff

/* ----------------------------------------------------------------------- */
void buffer_free(struct TS_buffer **buff)
{
struct TS_buffer *bp = *buff ;

//fprintf(stderr, "buffer_free(**TS_buffer=%p)\n", buff) ;

	if (bp)
	{
//		fprintf(stderr, " + **TS_buffer=%p [=> %p]\n", buff, *buff) ;
//		fprintf(stderr, " + buff_size=%d buff= %p\n", bp->buff_size, bp->buff) ;
		if (bp->buff_size)
		{
			free(bp->buff) ;
		}
		free(bp) ;
	}
	*buff = NULL ;
}

/* ----------------------------------------------------------------------- */
struct TS_buffer *buffer_new()
{
struct TS_buffer *bp ;

	// create struct
	bp = (struct TS_buffer *)malloc(sizeof(struct TS_buffer)) ;
	CLEAR_MEM(bp) ;

	bp->MAGIC = MAGIC_BUFF ;


	// create buffer
	bp->data_len = 0 ;
	bp->buff = (uint8_t *)malloc(TS_BUFFSIZE*sizeof(uint8_t)) ;
	bp->buff_size = TS_BUFFSIZE ;

//fprintf(stderr, "buffer_new() TS_buffer=%p [buff = %p])\n", bp, bp->buff) ;

	return bp ;
}

/* ----------------------------------------------------------------------- */
void buffer_clear(struct TS_buffer *bp)
{
	//CLEAR_MEM(bp)
	bp->data_len = 0 ;
}


/* ----------------------------------------------------------------------- */
uint8_t *buffer_data(struct TS_buffer **buff, const uint8_t *data, unsigned data_len)
{
struct TS_buffer *bp ;
unsigned new_len ;

//fprintf(stderr, "buffer_data(**TS_buffer=%p, data_len=%d)\n", buff, data_len) ;

	// check for first time
	if (!*buff)
	{
		// create struct
		*buff = buffer_new() ;
	}
	bp = *buff ;
	new_len = bp->data_len + data_len ;

//	fprintf(stderr, " + **TS_buffer=%p [=> %p] : buff=%p\n", buff, *buff, bp->buff) ;

	// able to add data?
	if (new_len >= bp->buff_size)
	{
//		fprintf(stderr, " + + realloc()\n") ;
		bp->buff_size += TS_BUFFSIZE ;
		bp->buff = realloc(bp->buff, bp->buff_size) ;
//		fprintf(stderr, " + + buff=%p\n", bp->buff) ;
	}
	else if (bp->buff_size - new_len > 2*TS_BUFFSIZE )
	{
//		fprintf(stderr, " + + downsize() data_len=%d, new_len=%d : curr size=%d\n", bp->data_len, new_len, bp->buff_size) ;
		// scale down if required
		bp->buff_size = ( ( (new_len + TS_BUFFSIZE-1) / TS_BUFFSIZE) + 1) * TS_BUFFSIZE ;
//		fprintf(stderr, " + + new size=%d\n", bp->buff_size) ;
		bp->buff = realloc(bp->buff, bp->buff_size) ;
//		fprintf(stderr, " + + buff=%p\n", bp->buff) ;
	}

//	fprintf(stderr, " + buff=%p .. %p : copying into %p .. %p\n", bp->buff, &bp->buff[bp->buff_size-1], &bp->buff[bp->data_len], &bp->buff[bp->data_len+data_len-1]) ;

	// copy data
	memcpy(&bp->buff[bp->data_len], data, data_len) ;
	bp->data_len += data_len ;

	return bp->buff ;
}


/*=============================================================================================*/
// TS_pid

/* ----------------------------------------------------------------------- */
// get existing or return created
static struct TS_pid* piditem_get(struct list_head *pid_list, struct TS_pidinfo *pidinfo)
{
struct TS_pid   *piditem;
struct list_head *item;

	list_for_each(item, pid_list)
	{
		piditem = list_entry(item, struct TS_pid, next);
		if (piditem->pidinfo.pid != pidinfo->pid)
			continue;

		return piditem;
    }

	piditem = malloc(sizeof(*piditem));
    CLEAR_MEM(piditem);
    piditem->MAGIC = MAGIC_PID ;

	//    struct TS_pid {
	//        struct list_head    next;
	//
	//        struct TS_pidinfo	pidinfo ;
	//        struct TS_buffer *	pes_buff ;
	//        enum TS_pesstate	pes_state ;
	//    };

    memcpy(&piditem->pidinfo, pidinfo, sizeof(*pidinfo)) ;
    piditem->pes_buff = buffer_new() ;
    piditem->pes_state = PES_SKIP ;
    list_add_tail(&piditem->next, pid_list);

    piditem->pesinfo.start_pts = UNSET_TS ;
    piditem->pesinfo.start_dts = UNSET_TS ;
    piditem->pesinfo.end_pts = UNSET_TS ;
    piditem->pesinfo.end_dts = UNSET_TS ;
    piditem->pesinfo.pts = UNSET_TS ;
    piditem->pesinfo.dts = UNSET_TS ;

    piditem->pesinfo.pes_psi = T_PES ;

    return piditem;
}

/* ----------------------------------------------------------------------- */
// get existing or return created
static void piditem_free(struct TS_pid * piditem)
{
	//    struct TS_pid {
	//        struct list_head    next;
	//
	//        struct TS_pidinfo	pidinfo ;
	//        struct TS_buffer *	pes_buff ;
	//        enum TS_pesstate	pes_state ;
	//    };

    buffer_free(&piditem->pes_buff) ;

    free(piditem);
}

/* ----------------------------------------------------------------------- */
// Start of new PES, reset flags/counters etc
static void pes_start(struct TS_pid * pid_item)
{
	pid_item->pes_buff->data_len = 0 ;
	pid_item->pes_state = PES_HEADER ;

	pid_item->pesinfo.psi_error = 0 ;
	pid_item->pesinfo.pes_error = 0 ;
	pid_item->pesinfo.ts_error = 0 ;
}


/*=============================================================================================*/
// TS_state

//struct TS_state {
//	unsigned MAGIC ;
//	struct TS_pidinfo 	pidinfo ;
//	struct TS_pid		*pid_item ;
//
//	// list of TS_pid
//    struct list_head    pid_list;
//
//    // Set to total number of packets
//    unsigned			total_pkts ;
//
//    // set to min/max pts/dts times
//	int64_t 			start_ts ;
//	int64_t 			end_ts ;
//
//	// Stop flag - set by callbacks to exit the loop
//	unsigned			stop_flag ;
//
////    // list of TS packets
////	unsigned			start_pktnum ;
////
////	// list of TS_pkt
////	struct list_head	pkt_list ;
//};

/* ----------------------------------------------------------------------- */
static void tsstate_free(struct TS_state *tsstate)
{
struct list_head  *item, *safe;
struct TS_pid    *piditem;
//struct TS_pkt    *pktitem;

	list_for_each_safe(item,safe,&tsstate->pid_list)
	{
		piditem = list_entry(item, struct TS_pid, next);
		list_del(&piditem->next);
		piditem_free(piditem);
	};
//	list_for_each_safe(item,safe,&tsstate->pkt_list)
//	{
//		pktitem = list_entry(item, struct TS_pkt, next);
//		list_del(&pktitem->next);
//		free(pktitem);
//	};

    free(tsstate) ;
}

/* ----------------------------------------------------------------------- */
static struct TS_state *tsstate_new()
{
struct TS_state *tsstate ;

	// create struct
	tsstate = (struct TS_state *)malloc(sizeof(struct TS_state)) ;
	CLEAR_MEM(tsstate) ;
	tsstate->MAGIC = MAGIC_STATE ;

	tsstate->pidinfo.pktnum = 0 ;
	tsstate->pidinfo.pid_error = 0 ;

	INIT_LIST_HEAD(&tsstate->pid_list);

	tsstate->start_ts = UNSET_TS ;
	tsstate->end_ts = UNSET_TS ;

	tsstate->pid_item = (struct TS_pid *)0 ;
	tsstate->total_pkts = 0 ;
	tsstate->stop_flag = 0 ;

//    // list of TS packets
//	INIT_LIST_HEAD(&tsstate->pkt_list);
//	tsstate->start_pktnum = 0LLU ;

	return tsstate ;
}


/*=============================================================================================*/


/* ----------------------------------------------------------------------- */
static int getbuff(int fh, uint8_t *buffer, int *count)
{
int rc ;
int status ;
int data_ready ;

	status = 0 ;

	rc = read(fh, buffer, *count);

	// return actual read amount
	*count = rc ;

	switch (rc) {
	case -1:
		RETURN_DVB_ERROR(ERR_READ) ;
	case 0:
		RETURN_DVB_ERROR(ERR_EOF) ;

	default:
		break;
	}
	return(status) ;
}


//---------------------------------------------------------------------------------------------------------------------------
unsigned mpeg2_frame_flags(struct TS_reader *tsreader, struct TS_state *tsstate, uint8_t *pesdata, unsigned pesdata_len)
{
uint8_t *p = pesdata ;
unsigned flags = 0 ;

	CHECK_TS_READER(tsreader) ;
	while (p && ((int)pesdata_len-(int)(p-pesdata) >= 4) && (p = memchr(p, 0, (int)pesdata_len-(int)(p-pesdata))) )
	{
		if ((int)pesdata_len-(int)(p-pesdata) >= 4)
		{
			if ( (p[0]==0) && (p[1]==0) && (p[2]==1) )
			{
				if ( p[3]==0 )
				{
					flags |= FRAME_FLAG_START ;

					tsparse_dbg_prt(200, (" @@ Video Start @@ pes start pkt %u : [at offset %d]\n",
							tsstate->pid_item->pesinfo.start_pkt, (int)(p-pesdata))) ;
				}
				else
				{
					char *codestr ;
					char tmp[256] ;

					int code = 0x100 + (int)p[3] ;
					switch (code)
					{
					case user_data_start_code:
						flags |= FRAME_FLAG_USER_DATA ;
						codestr = "USER DATA" ;
						break ;

					case sequence_header_code:
						flags |= FRAME_FLAG_SEQ_HEAD ;
						codestr = "SEQ HEAD" ;
						break ;

					case sequence_error_code:
						flags |= FRAME_FLAG_SEQ_ERROR ;
						codestr = "SEQ ERROR" ;
						break ;

					case extension_start_code:
						flags |= FRAME_FLAG_EXTENSION ;
						codestr = "EXTENSION" ;
						break ;

					case sequence_end_code:
						flags |= FRAME_FLAG_SEQ_END ;
						codestr = "SEQ END" ;
						break ;

					case group_start_code:
						flags |= FRAME_FLAG_GOP ;
						codestr = "GOP" ;
						break ;

					default:
						if ( (code >= slice_start_code_start) && (code <= slice_start_code_end) )
						{
							flags |= FRAME_FLAG_SLICE ;
							sprintf(tmp, "SLICE %d", code - slice_start_code_start + 1) ;
							codestr = tmp ;
						}
						else if ( (code >= system_start_code_start) && (code <= system_start_code_end) )
						{
							flags |= FRAME_FLAG_SYSTEM ;
							sprintf(tmp, "SYSTEM") ;
							codestr = tmp ;
						}
						else
						{
							flags |= FRAME_FLAG_RESERVED ;
							codestr = "" ;
						}
						break ;
					}

					tsparse_dbg_prt(200, ("    @#@ code 0x%02x %s @#@ pes start pkt %u : [at offset %d]\n",
							(int)p[3], codestr, tsstate->pid_item->pesinfo.start_pkt, (int)(p-pesdata))) ;
				}
				p+=3 ;
			}
		}

		if ((int)pesdata_len-(int)(p-pesdata) > 4)
		{
			++p ;
		}
		else
		{
			p = NULL ;
		}
	}

	return flags ;
}


//---------------------------------------------------------------------------------------------------------------------------
// NOTE: When skipping packets/frames, we need to have seen the previous GOP to get the frame for this GOP. Otherwise, we only
// get a frame out for the frame following the GOP
//
//               GOP                        GOP                        GOP
//   DATA:  ------|--------------------------|--------------------------|--------------------------|
//                 012345678901234567890123456012345678901234567890123456012345678901234567890123456
//
//   Skip=0 v
//           ------|--------------------------|--------------------------|--------------------------|
//                 |
//                 v
//                 First frame = Frame 0
//
//   Skip=2nd GOP
//                                           v
//          ------|--------------------------|--------------------------|--------------------------|
//                 012345678901234567890123456012345678901234567890123456012345678901234567890123456
//				                            |
//				                            v
//				                        First frame
//
//          i.e. first frame out = Frame 27 NOT Frame 26
//

#define MAX_STATE_CYCLE		100
static void process_mpeg2(struct TS_reader *tsreader, struct TS_state *tsstate, uint8_t *pesdata, unsigned pesdata_len)
{
mpeg2_state_t state;
unsigned state_cycle = 0 ;
unsigned frame_flags ;

// for debug
static int total_offset = 0;
const mpeg2_info_t * info;

	CHECK_TS_READER(tsreader) ;


	tsparse_dbg_prt(202, ("\n\n--[ video ]----------\n%d bytes\n", pesdata_len)) ;
	if (tsreader->debug >= 202)
		dump_buff(pesdata, pesdata_len, pesdata_len) ;

	// mainly looking for GOP start
	frame_flags = mpeg2_frame_flags(tsreader, tsstate, pesdata, pesdata_len) ;
	if (frame_flags & FRAME_FLAG_GOP)
	{
		tsreader->mpeg2.gop_pktnum = tsstate->pid_item->pesinfo.start_pkt ;
	}

	// check this is a video stream
	if ( (tsstate->pid_item->pesinfo.code & video_stream_mask) != video_stream)
	{
		return ;
	}

	// for debug
    info = mpeg2_info(tsreader->mpeg2.decoder);
    total_offset += pesdata_len ;

	do
	{
		state = mpeg2_parse (tsreader->mpeg2.decoder);


		/*
		 * With verbose=100, dump_state format:
		 *
		 *  %8x = file offset
		 *  %c%c = seq code, gop code S=seq, G=gop
		 *  %c%c%c = curr fbuff code, curr pic code, curr pic2 code (a-z or A-Z for new) 0..25
		 *  %c%c%c = disp fbuff code, disp pic code, disp pic2 code
		 *  %c = discard fbuf code
		 *  %s = State name
		 *
		 *
		 *  GOP = Group of 26 pictures
		 */
		tsparse_dbg_prt(200, ("---[ mpeg2 dump_state ]------------------------\nstate = %s [%d]\n", STATE_STRINGS[state], state));
		if (tsreader->debug >= 202)
			dump_state (stderr, state, info,
					total_offset - mpeg2_getpos(tsreader->mpeg2.decoder), 100 /* verbosity */);
		tsparse_dbg_prt(102, ("state = %s [%d]\n", STATE_STRINGS[state], state));

		switch (state) {
		case STATE_BUFFER:
			// HAVE TO COPY DATA TO NEW BUFFER SO THAT libmpeg2 HAS A COPY TO WORK ON IN THE MEANTIME!
			if (tsreader->mpeg2.video_buffer) free(tsreader->mpeg2.video_buffer) ;
			tsreader->mpeg2.video_buffer = (uint8_t *)malloc(pesdata_len * sizeof(uint8_t)) ;
			memcpy(tsreader->mpeg2.video_buffer, pesdata, pesdata_len) ;
			mpeg2_buffer (tsreader->mpeg2.decoder, tsreader->mpeg2.video_buffer, tsreader->mpeg2.video_buffer + pesdata_len);
			break;

		case STATE_SEQUENCE:
			if (tsreader->mpeg2.convert_rgb)
			{
				mpeg2_convert(tsreader->mpeg2.decoder, mpeg2convert_rgb24, NULL);
			}
			break;
		case STATE_SLICE:
		case STATE_END:
		case STATE_INVALID_END:
			if (tsreader->mpeg2.info->display_fbuf)
			{
				// call callback
//				if (tsreader->mpeg2_hook)
				{
					struct TS_frame_info *frame_info ;

					unsigned frame_info_index = (unsigned)tsreader->mpeg2.info->current_picture->tag ;
					frame_info = frame_info_entry(tsreader, frame_info_index) ;

					if (tsreader->mpeg2.convert_rgb)
					{
						tsreader->mpeg2_rgb_hook(&tsstate->pidinfo,
											 frame_info,
											 tsreader->mpeg2.info,
											 tsreader->user_data) ;
					}
					else
					{
						tsreader->mpeg2_hook(&tsstate->pidinfo,
											 frame_info,
											 tsreader->mpeg2.info,
											 tsreader->user_data) ;
					}
				}
				++tsreader->mpeg2.framenum ;
			}
			break;

		case STATE_INVALID:
			break ;
		case STATE_SEQUENCE_REPEATED:
			break ;
		case STATE_GOP:
			break ;
		case STATE_PICTURE:
			break ;
		case STATE_SLICE_1ST:
			break ;
		case STATE_PICTURE_2ND:
			break ;
		case STATE_SEQUENCE_MODIFIED:
			break ;

		default:
			break;
		}
	} while ( (state != STATE_BUFFER) && (state_cycle++ < MAX_STATE_CYCLE) ) ;

	// Use the tags to store:
	// tag = frame info index
	// tag2 = packet count of pes containing GOP (once every 26 frames)
	struct TS_frame_info *frame_info = frame_info_entry(tsreader, tsreader->mpeg2.frame_info_index) ;
	frame_info->framenum = tsreader->mpeg2.framenum ;
	frame_info->gop_pkt = tsreader->mpeg2.gop_pktnum ;
	memcpy(&frame_info->pesinfo, &tsstate->pid_item->pesinfo, sizeof(tsstate->pid_item->pesinfo)) ;
	memcpy(&frame_info->pidinfo, &tsstate->pid_item->pidinfo, sizeof(tsstate->pid_item->pidinfo)) ;

	mpeg2_tag_picture(tsreader->mpeg2.decoder, tsreader->mpeg2.frame_info_index, tsreader->mpeg2.gop_pktnum) ;
	tsreader->mpeg2.frame_info_index++ ;

	tsparse_dbg_prt(102, ("cycle=%d\n-------------------------------------\n\n", state_cycle));
}

//---------------------------------------------------------------------------------------------------------------------------
// mpeg2 decoder (again) but this time converts the image to RGB
//
static void process_mpeg2_rgb(struct TS_reader *tsreader, struct TS_state *tsstate, uint8_t *pesdata, unsigned pesdata_len)
{
mpeg2_state_t state;
unsigned state_cycle = 0 ;
unsigned frame_flags ;

// for debug
static int total_offset = 0;
const mpeg2_info_t * info;

	CHECK_TS_READER(tsreader) ;

	tsparse_dbg_prt(202, ("\n\n--[ rgb video ]----------\n%d bytes\n", pesdata_len)) ;
	if (tsreader->debug >= 202)
		dump_buff(pesdata, pesdata_len, pesdata_len) ;

	// mainly looking for GOP start
	frame_flags = mpeg2_frame_flags(tsreader, tsstate, pesdata, pesdata_len) ;
	if (frame_flags & FRAME_FLAG_GOP)
	{
		tsreader->mpeg2.gop_pktnum = tsstate->pid_item->pesinfo.start_pkt ;
	}

	// check this is a video stream
	if ( (tsstate->pid_item->pesinfo.code & video_stream_mask) != video_stream)
	{
		return ;
	}

	// for debug
    info = mpeg2_info(tsreader->mpeg2.decoder);
    total_offset += pesdata_len ;

	do
	{
		state = mpeg2_parse (tsreader->mpeg2.decoder);

		/*
		 * With verbose=100, dump_state format:
		 *
		 *  %8x = file offset
		 *  %c%c = seq code, gop code S=seq, G=gop
		 *  %c%c%c = curr fbuff code, curr pic code, curr pic2 code (a-z or A-Z for new) 0..25
		 *  %c%c%c = disp fbuff code, disp pic code, disp pic2 code
		 *  %c = discard fbuf code
		 *  %s = State name
		 *
		 *
		 *  GOP = Group of 26 pictures
		 */
		tsparse_dbg_prt(200, ("---[ rgb mpeg2 dump_state ]------------------------\nstate = %s [%d]\n", STATE_STRINGS[state], state));
		if (tsreader->debug >= 202)
			dump_state (stderr, state, info,
					total_offset - mpeg2_getpos(tsreader->mpeg2.decoder), 100 /* verbosity */);
		tsparse_dbg_prt(102, ("state = %s [%d]\n", STATE_STRINGS[state], state));

		switch (state) {
		case STATE_BUFFER:
			// HAVE TO COPY DATA TO NEW BUFFER SO THAT libmpeg2 HAS A COPY TO WORK ON IN THE MEANTIME!
			if (tsreader->mpeg2.video_buffer) free(tsreader->mpeg2.video_buffer) ;
			tsreader->mpeg2.video_buffer = (uint8_t *)malloc(pesdata_len * sizeof(uint8_t)) ;
			memcpy(tsreader->mpeg2.video_buffer, pesdata, pesdata_len) ;
			mpeg2_buffer (tsreader->mpeg2.decoder, tsreader->mpeg2.video_buffer, tsreader->mpeg2.video_buffer + pesdata_len);
			break;

		case STATE_SEQUENCE:
		    mpeg2_convert (tsreader->mpeg2.decoder, mpeg2convert_rgb24, NULL);
			break;

		case STATE_SLICE:
		case STATE_END:
		case STATE_INVALID_END:
			if (tsreader->mpeg2.info->display_fbuf)
			{
				// call callback
				if (tsreader->mpeg2_rgb_hook)
				{
					struct TS_frame_info *frame_info ;

					unsigned frame_info_index = (unsigned)tsreader->mpeg2.info->current_picture->tag ;
					frame_info = frame_info_entry(tsreader, frame_info_index) ;

					tsreader->mpeg2_rgb_hook(&tsstate->pidinfo,
										 frame_info,
										 tsreader->mpeg2.info,
										 tsreader->user_data) ;
				}
				++tsreader->mpeg2.framenum ;
			}
			break;

		case STATE_INVALID:
			break ;
		case STATE_SEQUENCE_REPEATED:
			break ;
		case STATE_GOP:
			break ;
		case STATE_PICTURE:
			break ;
		case STATE_SLICE_1ST:
			break ;
		case STATE_PICTURE_2ND:
			break ;
		case STATE_SEQUENCE_MODIFIED:
			break ;

		default:
			break;
		}
	} while ( (state != STATE_BUFFER) && (state_cycle++ < MAX_STATE_CYCLE) ) ;

	// Use the tags to store:
	// tag = frame info index
	// tag2 = packet count of pes containing GOP (once every 26 frames)
	struct TS_frame_info *frame_info = frame_info_entry(tsreader, tsreader->mpeg2.frame_info_index) ;
	frame_info->framenum = tsreader->mpeg2.framenum ;
	frame_info->gop_pkt = tsreader->mpeg2.gop_pktnum ;
	memcpy(&frame_info->pesinfo, &tsstate->pid_item->pesinfo, sizeof(tsstate->pid_item->pesinfo)) ;
	memcpy(&frame_info->pidinfo, &tsstate->pid_item->pidinfo, sizeof(tsstate->pid_item->pidinfo)) ;

	mpeg2_tag_picture(tsreader->mpeg2.decoder, tsreader->mpeg2.frame_info_index, tsreader->mpeg2.gop_pktnum) ;
	tsreader->mpeg2.frame_info_index++ ;

	tsparse_dbg_prt(102, ("cycle=%d\n-------------------------------------\n\n", state_cycle));
}



//---------------------------------------------------------------------------------------------------------------------------
static void process_audio(struct TS_reader *tsreader, struct TS_state *tsstate, uint8_t *pesdata, unsigned pesdata_len)
{
int done_bytes, avail_bytes, bytes;
int samples, audio_bytes;
mpeg2_audio_t audio_info ;

	CHECK_TS_READER(tsreader) ;

	// check this is an audio stream
	if ( (tsstate->pid_item->pesinfo.code & audio_stream_mask) != audio_stream)
	{
		return ;
	}

	if (&tsreader->mpeg2audio.write_ptr[pesdata_len] - tsreader->mpeg2audio.storage_buf > STORAGE_SIZE)
	{
		printf("ERROR: Audio buffer full\n");
		abort() ;
	}
	memcpy(tsreader->mpeg2audio.write_ptr, pesdata, pesdata_len);
	tsreader->mpeg2audio.write_ptr = &tsreader->mpeg2audio.write_ptr[pesdata_len];
	avail_bytes = tsreader->mpeg2audio.write_ptr - tsreader->mpeg2audio.read_ptr;

	// start with this PTS
	audio_info.pts = tsstate->pid_item->pesinfo.dts ;

	done_bytes = 1;
	while ( (avail_bytes > MIN_BUFFER) && (done_bytes > 0) )
	{
		audio_bytes = 0;
		tsparse_dbg_prt(102, ("avail_bytes=%d, done=%d\n", avail_bytes, done_bytes)) ;

		// Decode the frame in buffer
		done_bytes = decode_frame(tsreader->mpeg2audio.audio_buf, &audio_bytes, tsreader->mpeg2audio.read_ptr, (int)(tsreader->mpeg2audio.write_ptr - tsreader->mpeg2audio.read_ptr));

		// convert the audio buffer size in bytes, into the total number of samples (shorts). Samples per chan = samples / num_chans
		samples = audio_bytes / sizeof(short) ;

		tsreader->mpeg2audio.read_ptr = &tsreader->mpeg2audio.read_ptr[done_bytes];
		avail_bytes -= done_bytes;

		// Pass the samples to the user
		audio_info.sample_rate = get_samplerate() ;
		audio_info.channels = get_channels() ;
		audio_info.framesize = get_framesize() ;
		audio_info.audio = tsreader->mpeg2audio.audio_buf ;
		audio_info.samples = samples ;
		audio_info.audio_framenum = tsreader->mpeg2audio.framenum ;

		audio_info.samples_per_frame = audio_info.framesize * audio_info.channels ;

		// Calculate the PTS delta between audio frames
		audio_info.pts_delta = 90000 * audio_info.framesize / audio_info.sample_rate ;

		// call callback
		if ( (audio_info.samples_per_frame > 0) && tsreader->audio_hook )
		{
			tsreader->mpeg2audio.audio_samples += samples;
			while (tsreader->mpeg2audio.audio_samples >= audio_info.samples_per_frame)
			{
				// callback a frame at a time
				audio_info.samples = audio_info.samples_per_frame ;
				tsreader->audio_hook(&tsstate->pidinfo, &tsstate->pid_item->pesinfo,
						&audio_info, tsreader->user_data) ;

				tsreader->mpeg2audio.audio_samples -= audio_info.samples_per_frame;
				audio_info.audio -= audio_info.samples_per_frame ;

				// This is the audio frame count
				audio_info.audio_framenum++ ;

				// step to expected next DTS
				audio_info.pts += (int64_t)audio_info.pts_delta ;
			}
			tsreader->mpeg2audio.framenum = audio_info.audio_framenum ;

		}
	}

	// Shuffle any remaining data down to the bottom of the buffer
	bytes = 0 ;
	while (tsreader->mpeg2audio.read_ptr < tsreader->mpeg2audio.write_ptr) {
		tsreader->mpeg2audio.storage_buf[bytes++] = *tsreader->mpeg2audio.read_ptr++;
	}
	tsreader->mpeg2audio.write_ptr = &tsreader->mpeg2audio.storage_buf[bytes];
	tsreader->mpeg2audio.read_ptr = tsreader->mpeg2audio.storage_buf;

}


///* ----------------------------------------------------------------------- */
//static int process_psi(struct TS_reader *tsreader, struct TS_state *tsstate,
//			uint8_t *payload, unsigned payload_len)
//{
//	tsparse_dbg_prt(102, ("process_psi(pid %d) payload len %d\n",
//			tsstate->pidinfo.pid, payload_len)) ;
//
//	// Call table processor
//
//	return 0 ;
//}

/* ----------------------------------------------------------------------- */
static int process_pes(struct TS_reader *tsreader, struct TS_state *tsstate,
			uint8_t *payload, unsigned payload_len)
{
unsigned code ;
unsigned packet_length ;
unsigned byte ;
int64_t pts, dts ;
int i ;
unsigned set_ts = 0 ;
unsigned pts_dts ;

#ifdef DEBUG_PTS
unsigned dbg_bytes[32] ;
unsigned dbg_num ;
#endif

	CHECK_TS_READER(tsreader) ;

	tsparse_dbg_prt(102, ("process_pes(pid %d) payload len %d\n",
		tsstate->pidinfo.pid, payload_len)) ;

	if (payload_len < 7)
		return 0 ;

	//	packet_start_code_prefix				24 bslbf
	//	stream_id								8 uimsbf
	//	packet_length							16 uimsbf
	//
	code = 0x100 | payload[3] ;
	packet_length = ((payload[4])<<8) | payload[5] ;

	tsstate->pid_item->pesinfo.code = code ;

	tsparse_dbg_prt(102, ("PES code 0x%03x PES Len %d Data:\n", code, packet_length)) ;
	if (tsreader->debug >= 103)
		dump_buff(payload, payload_len, 32) ;

	byte = 6 ;

	//	ISO13818-1:
	//
	//	if (stream_id != program_stream_map
	//	&& stream_id != padding_stream
	//	&& stream_id != private_stream_2
	//	&& stream_id != ECM
	//	&& stream_id != EMM
	//	&& stream_id != program_stream_directory
	//	&& stream_id != DSMCC_stream
	//	&& stream_id != ITU-T Rec. H.222.1 type E stream) {
	if (
			code != program_stream_map
		&&	code != padding_stream
		&&	code != private_stream_2
		&&	code != ECM_stream
		&&	code != EMM_stream
		&&	code != program_stream_directory
		&&	code != DSMCC_stream
		&&	code != H2221_E_stream
	)
	{
	unsigned pes_header_len ;

		//		'10' 2 bslbf
		//		PES_scrambling_control 2 bslbf
		//		PES_priority 1 bslbf
		//		data_alignment_indicator 1 bslbf
		//		copyright 1 bslbf
		//		original_or_copy 1 bslbf
		++byte ;

		//		PTS_DTS_flags 2 bslbf
		//		ESCR_flag 1 bslbf
		//		ES_rate_flag 1 bslbf
		//		DSM_trick_mode_flag 1 bslbf
		//		additional_copy_info_flag 1 bslbf
		//		PES_CRC_flag 1 bslbf
		//		PES_extension_flag 1 bslbf
		pts_dts = (payload[byte] >> 6) & 0x3 ;
		++byte ;

		tsparse_dbg_prt(102, (" + decoding pes data (pts_dts=%d [0x%02x])...\n", pts_dts, payload[byte-1])) ;

		//		PES_header_data_length 8 uimsbf
		pes_header_len = payload[byte] ;
		++byte ;

		// point at just the PES data part
		tsstate->pid_item->pesinfo.pesdata_p = &payload[byte+pes_header_len] ;
		tsstate->pid_item->pesinfo.pesdata_len = payload_len - (byte+pes_header_len) ;

		tsparse_dbg_prt(102, (" + pes header len=%d...\n", pes_header_len)) ;

//		if (PTS_DTS_flags = = '10') {
//			'0010' 4 bslbf
//			PTS [32..30] 3 bslbf
//			marker_bit 1 bslbf
//			PTS [29..15] 15 bslbf
//			marker_bit 1 bslbf
//			PTS [14..0] 15 bslbf
//			marker_bit 1 bslbf
//		}
		if (pts_dts == 2)
		{
#ifdef DEBUG_PTS
dbg_bytes[0] = payload[byte] ;
dbg_bytes[1] = payload[byte+1] ;
dbg_bytes[2] = payload[byte+2] ;
dbg_bytes[3] = payload[byte+3] ;
dbg_bytes[4] = payload[byte+4] ;
dbg_num=5 ;
#endif

			if ( (payload[byte] & 0xf0) != 0x20)
			{
				// handle error
				tsstate->pid_item->pesinfo.pes_error++ ;
				tsstate->pidinfo.pid_error++ ;
				if (tsreader->error_hook)
				{
					SET_DVB_ERROR(ERR_PESHEAD) ;
					tsreader->error_hook(dvb_error_code, &tsstate->pidinfo, tsreader->user_data) ;
				}
			}
			pts = (int64_t)((payload[byte] >> 1) & 0x07) << 30;
			pts |= (((payload[byte+1]<<8) | payload[byte+2]) >> 1) << 15;
			pts |=  (((payload[byte+3]<<8) | payload[byte+4]) >> 1);

			tsparse_dbg_prt(100, ("PTS definition:\n")) ;
			if (tsreader->debug >= 100)
				dump_buff(&payload[byte], payload_len, 5) ;

			byte += 5 ;

			dts = pts ;
			++set_ts ;
		}

//		if (PTS_DTS_flags = = '11') {
//			'0011' 4 bslbf
//			PTS [32..30] 3 bslbf
//			marker_bit 1 bslbf

//			PTS [29..15] 15 bslbf
//			marker_bit 1 bslbf

//			PTS [14..0] 15 bslbf
//			marker_bit 1 bslbf

//			'0001' 4 bslbf
//			DTS [32..30] 3 bslbf
//			marker_bit 1 bslbf

//			DTS [29..15] 15 bslbf
//			marker_bit 1 bslbf

//			DTS [14..0] 15 bslbf
//			marker_bit 1 bslbf
//		}
		if (pts_dts == 3)
		{
#ifdef DEBUG_PTS
dbg_bytes[0] = payload[byte] ;
dbg_bytes[1] = payload[byte+1] ;
dbg_bytes[2] = payload[byte+2] ;
dbg_bytes[3] = payload[byte+3] ;
dbg_bytes[4] = payload[byte+4] ;
dbg_bytes[5] = payload[byte+5] ;
dbg_bytes[6] = payload[byte+6] ;
dbg_bytes[7] = payload[byte+7] ;
dbg_bytes[8] = payload[byte+8] ;
dbg_bytes[9] = payload[byte+9] ;
dbg_num=10 ;
#endif
			if ( (payload[byte] & 0xf0) != 0x30)
			{
				// handle error
				tsstate->pid_item->pesinfo.pes_error++ ;
				tsstate->pidinfo.pid_error++ ;
				if (tsreader->error_hook)
				{
					SET_DVB_ERROR(ERR_PESHEAD) ;
					tsreader->error_hook(dvb_error_code, &tsstate->pidinfo, tsreader->user_data) ;
				}
			}
		    pts = (int64_t)((payload[byte] >> 1) & 0x07) << 30;
		    pts |= (((payload[byte+1]<<8) | payload[byte+2]) >> 1) << 15;
		    pts |=  (((payload[byte+3]<<8) | payload[byte+4]) >> 1);

			tsparse_dbg_prt(100, ("PTS definition:\n")) ;
		    if (tsreader->debug >= 100)
				dump_buff(&payload[byte], payload_len, 5) ;

		    byte += 5 ;

		    dts = (int64_t)((payload[byte] >> 1) & 0x07) << 30;
		    dts |= (((payload[byte+1]<<8) | payload[byte+2]) >> 1) << 15;
		    dts |=  (((payload[byte+3]<<8) | payload[byte+4]) >> 1);

			tsparse_dbg_prt(100, ("DTS definition:\n")) ;
		    if (tsreader->debug >= 100)
				dump_buff(&payload[byte], payload_len, 5) ;

			byte += 5 ;

			++set_ts ;
		}


//		if (ESCR_flag = = '1') {
//			reserved 2 bslbf
//			ESCR_base[32..30] 3 bslbf
//			marker_bit 1 bslbf
//			ESCR_base[29..15] 15 bslbf
//			marker_bit 1 bslbf
//			ESCR_base[14..0] 15 bslbf
//			marker_bit 1 bslbf
//			ESCR_extension 9 uimsbf
//			marker_bit 1 bslbf
//		}
//		if (ES_rate_flag = = '1') {
//			marker_bit 1 bslbf
//			ES_rate 22 uimsbf
//			marker_bit 1 bslbf
//		}
//		if (DSM_trick_mode_flag = = '1') {
//			trick_mode_control 3 uimsbf
//			if ( trick_mode_control = = fast_forward ) {
//				field_id 2 bslbf
//				intra_slice_refresh 1 bslbf
//				frequency_truncation 2 bslbf
//			}
//			else if ( trick_mode_control = = slow_motion ) {
//				rep_cntrl 5 uimsbf
//			}
//			else if ( trick_mode_control = = freeze_frame ) {
//				field_id 2 uimsbf
//				reserved 3 bslbf
//			}
//			else if ( trick_mode_control = = fast_reverse ) {
//				field_id 2 bslbf
//				intra_slice_refresh 1 bslbf
//				frequency_truncation 2 bslbf
//			else if ( trick_mode_control = = slow_reverse ) {
//				rep_cntrl 5 uimsbf
//			}
//			else
//				reserved 5 bslbf
//		}
//		if ( additional_copy_info_flag = = '1') {
//			marker_bit 1 bslbf
//			additional_copy_info 7 bslbf
//		}
//		if ( PES_CRC_flag = = '1') {
//			previous_PES_packet_CRC 16 bslbf
//		}
//		if ( PES_extension_flag = = '1') {
//			PES_private_data_flag 1 bslbf
//			pack_header_field_flag 1 bslbf
//			program_packet_sequence_counter_flag 1 bslbf
//			P-STD_buffer_flag 1 bslbf
//			reserved 3 bslbf
//			PES_extension_flag_2 1 bslbf
//			if ( PES_private_data_flag = = '1') {
//				PES_private_data 128 bslbf
//			}
//			if (pack_header_field_flag = = '1') {
//				pack_field_length 8 uimsbf
//				pack_header()
//			}
//			if (program_packet_sequence_counter_flag = = '1') {
//				marker_bit 1 bslbf
//				program_packet_sequence_counter 7 uimsbf
//				marker_bit 1 bslbf
//				MPEG1_MPEG2_identifier 1 bslbf
//				original_stuff_length 6 uimsbf
//			}
//			if ( P-STD_buffer_flag = = '1') {
//				'01' 2 bslbf
//				P-STD_buffer_scale 1 bslbf
//				P-STD_buffer_size 13 uimsbf
//			}
//			if ( PES_extension_flag_2 = = '1') {
//				marker_bit 1 bslbf
//				PES_extension_field_length 7 uimsbf
//				for (i = 0; i < PES_extension_field_length; i++) {
//					reserved 8 bslbf
//				}
//			}
//		}
//		for (i = 0; i < N1; i++) {
//			stuffing_byte 8 bslbf
//		}
//		for (i = 0; i < N2; i++) {
//			PES_packet_data_byte 8 bslbf
//		}
//	}
	}


	// setting the pts/dts?
	if (set_ts)
	{
		// PTS
		if (tsstate->pid_item->pesinfo.start_pts == UNSET_TS)
		{
			tsstate->pid_item->pesinfo.start_pts = pts ;
		}
		else
		{
			// check for wrap
			if (pts+MAX_TS_DIFF < tsstate->pid_item->pesinfo.start_pts)
			{
				// wrapped, so adjust
				pts += TS_WRAP ;
			}
		}

		if (tsstate->pid_item->pesinfo.end_pts == UNSET_TS)
		{
			tsstate->pid_item->pesinfo.end_pts = pts ;
		}
		else
		{
			if (tsstate->pid_item->pesinfo.end_pts < pts)
				tsstate->pid_item->pesinfo.end_pts = pts ;
		}
		tsstate->pid_item->pesinfo.pts = pts ;

		// DTS
		if (tsstate->pid_item->pesinfo.start_dts == UNSET_TS)
		{
			tsstate->pid_item->pesinfo.start_dts = pts ;
		}
		else
		{
			// check for wrap
			if (dts+MAX_TS_DIFF < tsstate->pid_item->pesinfo.start_dts)
			{
				// wrapped, so adjust
				dts += TS_WRAP ;
			}
		}

		if (tsstate->pid_item->pesinfo.end_dts == UNSET_TS)
		{
			tsstate->pid_item->pesinfo.end_dts = pts ;
		}
		else
		{
			if (tsstate->pid_item->pesinfo.end_dts < dts)
				tsstate->pid_item->pesinfo.end_dts = dts ;
		}
		tsstate->pid_item->pesinfo.dts = dts ;

		tsparse_dbg_prt(102, ("TIMESTAMP: pid %d [0x%03x] rel ts=%d\n",
			tsstate->pidinfo.pid, code,
			(int)(dts - tsstate->pid_item->pesinfo.start_dts)
			));

#ifdef DEBUG_PTS
printf("DTS: pid %d [0x%03x] pts=%"PRId64" 0x%0"PRIx64"  (dts=%"PRId64") : pts_dts=%d [",
		tsstate->pidinfo.pid, code, pts, pts, dts, pts_dts);
for (i=0; i<dbg_num; ++i)
{
	printf("0x%02x ", dbg_bytes[i]) ;
}
printf("]\n") ;
#endif
	}

	return 0 ;
}




/* ----------------------------------------------------------------------- */
static int handle_payload(struct TS_reader *tsreader, struct TS_state *tsstate,
			uint8_t *payload, unsigned payload_len)
{
	CHECK_TS_READER(tsreader) ;
	if (tsstate->pidinfo.pid == NULL_PID)
		return 0 ;

	tsparse_dbg_prt(102, ("handle_payload(pid %d) : pkt %u : payload len %d  pes_start=%d\n",
		tsstate->pidinfo.pid, tsstate->pidinfo.pktnum,
		payload_len, tsstate->pidinfo.pes_start?1:0)) ;

    // process buffered data
	if (tsstate->pidinfo.pes_start)
	{
		if (tsstate->pid_item->pes_buff->data_len)
		{
		uint8_t *buff = tsstate->pid_item->pes_buff->buff ;
		unsigned buff_len = tsstate->pid_item->pes_buff->data_len ;

			tsparse_dbg_prt(102, ("handle_payload(pid %d) : call process_*() with existing buffer : buffered data len %d:\n",
					tsstate->pidinfo.pid, tsstate->pid_item->pes_buff->data_len)) ;

			if ((buff[0]==0) && (buff[1]==0) && (buff[2]==1))
			{
				// do something with the PES data
				tsstate->pid_item->pesinfo.pes_psi = T_PES ;
				process_pes(tsreader, tsstate, buff, buff_len) ;
			}

			//# PSI
			else
			{
				if (tsreader->debug >= 103)
					dump_buff(buff, buff_len, (tsreader->debug >= 104 ? buff_len : 31) ) ;

				// do something with the PSI data
				tsstate->pid_item->pesinfo.pes_psi = T_PSI ;
				parse_si(tsreader, tsstate, buff, buff_len) ;
			}

			// send to hook
			if (tsreader->pes_hook)
			{
				// Complete PES packet - Header + Data
				tsreader->pes_hook(&tsstate->pidinfo, &tsstate->pid_item->pesinfo,
						buff, buff_len,
						tsreader->user_data) ;
			}

			// send to hook
			if (tsreader->pes_data_hook)
			{
				// Just the PES data
				tsreader->pes_data_hook(&tsstate->pidinfo, &tsstate->pid_item->pesinfo,
						tsstate->pid_item->pesinfo.pesdata_p, tsstate->pid_item->pesinfo.pesdata_len,
						tsreader->user_data) ;
			}

			// send to hook
			if (tsreader->mpeg2.decoder)
			{
				// Just the PES data
				process_mpeg2(tsreader, tsstate, tsstate->pid_item->pesinfo.pesdata_p, tsstate->pid_item->pesinfo.pesdata_len) ;
			}

			// send to hook
			if (tsreader->audio_hook)
			{
				// Just the PES data
				process_audio(tsreader, tsstate, tsstate->pid_item->pesinfo.pesdata_p, tsstate->pid_item->pesinfo.pesdata_len) ;
			}
		}

		// reset state
		pes_start(tsstate->pid_item) ;
	}

    // process current data
	if (tsstate->pidinfo.pes_start)
	{
		tsstate->pid_item->pesinfo.start_pkt = tsreader->tsstate->pidinfo.pktnum ;
		tsstate->pid_item->pesinfo.end_pkt = tsreader->tsstate->pidinfo.pktnum ;

		tsparse_dbg_prt(102, ("handle_payload(pid %d) : calling process_* with new data : payload len = %d\n",
				tsstate->pidinfo.pid, payload_len)) ;

		//	#	Name 						Size 		Description
		//	#
		//	#	Packet start code prefix 	3 bytes 	0x000001
		//	#	Stream id 					1 byte 		Examples: Audio streams (0xC0-0xDF), Video streams (0xE0-0xEF) [2] [3] [4] [5]
		//	#											Note: The above 4 bytes is called the 32 bit start code.
		//	#	PES Packet length 			2 bytes 	Can be zero.If the PES packet length is set to zero, the PES packet can be of any length. A value of zero for the PES packet length can be used only when the PES packet payload is a video elementary stream.[6]
		//	#	Optional PES header 		variable length
		//	#	Stuffing bytes 				variable length
		//	#	Data 									See elementary stream. In the case of private streams the first byte of the payload is the sub-stream number.
		//	#
		if ((payload[0]==0) && (payload[1]==0) && (payload[2]==1))
		{
			// do something with the PES data
			process_pes(tsreader, tsstate, payload, payload_len) ;
		}

		//# PSI
		else
		{
			// do something with the PSI data
//SDP-just buffer until next start?//			process_psi(tsreader, tsstate, payload, payload_len) ;
		}
	}

	// buffer if required
	if (tsstate->pid_item->pes_state != PES_SKIP)
	{
		tsstate->pid_item->pesinfo.end_pkt = tsreader->tsstate->pidinfo.pktnum ;

		buffer_data(&tsstate->pid_item->pes_buff, payload, payload_len) ;

		tsparse_dbg_prt(102, ("<buffered> handle_payload(pid %d) : buffered - length now = %d\n",
				tsstate->pidinfo.pid, tsstate->pid_item->pes_buff->data_len)) ;
//		if (tsreader->debug >= 103)
//			dump_buff(tsstate->pid_item->pes_buff->buff, tsstate->pid_item->pes_buff->data_len, (tsreader->debug >= 104 ? tsstate->pid_item->pes_buff->data_len : 31) ) ;
	}

	return 0 ;
}

/* ----------------------------------------------------------------------- */
static int parse_ts_packet(struct TS_reader *tsreader, struct TS_state *tsstate,
		uint8_t *packet, unsigned packet_len)
{
unsigned pid_ok, pes_complete ;

uint8_t *payload ;
unsigned start ;
int payload_len ;

	CHECK_TS_READER(tsreader) ;
	tsstate->pid_item = NULL ;

	/*
		# ISO 13818-1
		#
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
		#			data_byte 8 bslbf
		#		}
		#	}
	*/
	tsstate->pidinfo.pid = (((packet[1] & 0x1f) << 8) | (packet[2] & 0xff)) & MAX_PID ;
	tsstate->pidinfo.err_flag = packet[1] & 0x80;
	tsstate->pidinfo.pes_start = packet[1] & 0x40;

    /* skip adaptation field */
	tsstate->pidinfo.afc = (packet[3] >> 4) & 3;
	start=4 ;
	payload = &packet[start] ;

	if (tsstate->pidinfo.afc == 0) /* reserved value */
        return 0;
    if (tsstate->pidinfo.afc == 2) /* adaptation field only */
        return 0;
    if (tsstate->pidinfo.afc == 3)
    {
        /* skip adaptation_field */
    	start += payload[0] + 1 ;
    }
    /* if past the end of packet, ignore */
    if (start >= packet_len)
        return 0;

	payload = &packet[start] ;
	payload_len = packet_len - start ;

if (tsreader->debug >= 100)
{
	printf ("PID %d (0x%03x) - start=%d, payload len=%d\n", tsstate->pidinfo.pid, tsstate->pidinfo.pid, start, payload_len) ;
	dump_buff(packet, packet_len, 31) ;
}


    // cumulative error
    tsstate->pidinfo.pid_error = 0 ;

	// look at pid?
	pid_ok=1;
	if (tsreader->pid_hook)
	{
		//# see if we want to process this pid
		pid_ok = tsreader->pid_hook(tsstate->pidinfo.pid, tsreader->user_data) ;
	}


	if (pid_ok)
	{
		// Update pid
		tsstate->pid_item = piditem_get(&tsstate->pid_list, &tsstate->pidinfo) ;

		//## Do checks for this packet

		//# sync check
		if (packet[0] != SYNC_BYTE)
		{
			++tsstate->pidinfo.pid_error ;
			if (tsreader->error_hook)
			{
				SET_DVB_ERROR(ERR_BADSYNC) ;
				tsreader->error_hook(dvb_error_code, &tsstate->pidinfo, tsreader->user_data) ;
			}
		}

		// # error check
		if (tsstate->pidinfo.err_flag)
		{
			++tsstate->pidinfo.pid_error ;
			if (tsreader->error_hook)
			{
				SET_DVB_ERROR(ERR_TSERR) ;
				tsreader->error_hook(dvb_error_code, &tsstate->pidinfo, tsreader->user_data) ;
			}
		}

		//    /* continuity check (currently not used) */
		//    cc = (packet[3] & 0xf);
		//    cc_ok = (tss->last_cc < 0) || ((((tss->last_cc + 1) & 0x0f) == cc));
		//    tss->last_cc = cc;

		tsstate->pid_item->pidinfo.pid_error = tsstate->pidinfo.pid_error ;
		tsstate->pid_item->pesinfo.ts_error += tsstate->pidinfo.pid_error ;
		if (tsstate->pidinfo.err_flag) ++tsstate->pid_item->pesinfo.ts_error ;

		if (tsreader->payload_hook)
		{
			tsreader->payload_hook(&tsstate->pidinfo, payload, payload_len, tsreader->user_data) ;
		}

		//# data may be a complete PES/PSI
		handle_payload(tsreader, tsstate, payload, payload_len) ;

		//## do something with raw packet
		if (tsreader->ts_hook)
		{
			tsreader->ts_hook(&tsstate->pidinfo, packet, packet_len, tsreader->user_data) ;
		}
	}

	return 0 ;
}

/*=============================================================================================*/
// PUBLIC
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
// Convert a TS packet into a NULL packet - overwrites the data
void ts_null_packet(uint8_t *packet, unsigned packet_len)
{

	/*
	 * For null packets the payload_unit_start_indicator shall be set to '0'.
	 * PID value 0x1FFF is reserved for null packets
	 * In the case of a null packet the value of the adaptation_field_control shall be set to '01'.
	 * In the case of a null packet the value of the continuity_counter is undefined.
	 * In the case of null packets with PID value 0x1FFF, data_bytes may be assigned any value.
	 *
	 *
		# ISO 13818-1
		#
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
		#			data_byte 8 bslbf
		#		}
		#	}
	*/
	// sync
	packet[0] = SYNC_BYTE ;

	// pid = 0x1fff
	// transport_error_indicator = 0
	// payload_unit_start_indicator = 0
	// transport_priority = 0
	packet[1] = (NULL_PID>>8) & 0x1f ;
	packet[2] = NULL_PID & 0xff ;

    /* adaptation field = 01 */
	packet[3] = (packet[3] & 0xcf) | 0x10 ;

}



/*=============================================================================================*/
// SI table decoding

/* ----------------------------------------------------------------------- */
int tsreader_register_section(struct TS_reader *tsreader,
		unsigned table_id, unsigned mask,
		Section_handler	handler, struct Section_decode_flags flags)
{
int updated = 0 ;
enum TS_section_ids masked_val ;
enum TS_section_ids id ;

	CHECK_TS_READER(tsreader) ;

	// add/remove handler entries from the table
	id = table_id & SECTION_MAX ;

	id &= mask ;
	masked_val = id ;
	for ( ; (id <= SECTION_MAX) && ( (id & mask) == masked_val); ++id )
	{
		tsreader->section_decode_table[id].flags = flags ;
		tsreader->section_decode_table[id].handler = handler ;
		++updated ;
	}
	return (updated) ;
}


/*=============================================================================================*/
// TS_reader

/* ----------------------------------------------------------------------- */
// Set the start & end points for whole video based on min/max times of the streams
void tsreader_set_timing(struct TS_reader *tsreader)
{
struct list_head  *item;
struct TS_pid    *piditem;

	CHECK_TS_READER(tsreader) ;
	tsparse_dbg_prt(102, ("tsreader_set_timing()\n")) ;

	list_for_each(item,&tsreader->tsstate->pid_list)
	{
		piditem = list_entry(item, struct TS_pid, next);

		tsparse_dbg_prt(102, ("Start=%"PRId64"  End=%"PRId64"\n", tsreader->tsstate->start_ts, tsreader->tsstate->end_ts)) ;
		tsparse_dbg_prt(102, ("PID %d\n", piditem->pidinfo.pid)) ;
		tsparse_dbg_prt(102, (" + PTS Start=%"PRId64"  End=%"PRId64" : DTS Start=%"PRId64"  End=%"PRId64"\n",
										piditem->pesinfo.start_pts, piditem->pesinfo.end_pts,
										piditem->pesinfo.start_dts, piditem->pesinfo.end_dts
										)) ;

		// start
		if (piditem->pesinfo.start_pts != UNSET_TS)
		{
			if  ((tsreader->tsstate->start_ts == UNSET_TS) || (piditem->pesinfo.start_pts < tsreader->tsstate->start_ts))
			{
				tsreader->tsstate->start_ts = piditem->pesinfo.start_pts ;
				tsparse_dbg_prt(102, (" + + Set start = pts\n")) ;
			}
		}
		if (piditem->pesinfo.start_dts != UNSET_TS)
		{
			if  ((tsreader->tsstate->start_ts == UNSET_TS) || (piditem->pesinfo.start_dts < tsreader->tsstate->start_ts))
			{
				tsreader->tsstate->start_ts = piditem->pesinfo.start_dts ;
				tsparse_dbg_prt(102, (" + + Set start = dts\n")) ;
			}
		}

		// end
		if (piditem->pesinfo.end_pts != UNSET_TS)
		{
			if  ((tsreader->tsstate->end_ts == UNSET_TS) || (piditem->pesinfo.end_pts > tsreader->tsstate->end_ts))
			{
				tsreader->tsstate->end_ts = piditem->pesinfo.end_pts ;
				tsparse_dbg_prt(102, (" + + Set end = pts\n")) ;
			}
		}
		if (piditem->pesinfo.end_dts != UNSET_TS)
		{
			if  ((tsreader->tsstate->end_ts == UNSET_TS) || (piditem->pesinfo.end_dts > tsreader->tsstate->end_ts))
			{
				tsreader->tsstate->end_ts = piditem->pesinfo.end_dts ;
				tsparse_dbg_prt(102, (" + + Set end = dts\n")) ;
			}
		}
	};

	tsparse_dbg_prt(102, ("Start=%"PRId64"  End=%"PRId64"\n", tsreader->tsstate->start_ts, tsreader->tsstate->end_ts)) ;
	tsparse_dbg_prt(102, ("tsreader_set_timing() - DONE\n")) ;
}


/* ----------------------------------------------------------------------- */
// Origin is as lseek ; skip_pkts can be -ve if origin is SEEK_END
int tsreader_setpos(struct TS_reader *tsreader, int skip_pkts, int origin, unsigned num_pkts)
{
off64_t rc = 0 ;
off64_t pos ;
int abs_skip ;
int skip_sign ;

	CHECK_TS_READER(tsreader) ;

	abs_skip = skip_pkts ;
	skip_sign = 1 ;
	if (skip_pkts < 0)
	{
		abs_skip = -skip_pkts ;
		skip_sign = -1 ;
	}

	// check for over-run
	if (abs_skip > tsreader->tsstate->total_pkts)
	{
		abs_skip = tsreader->tsstate->total_pkts ;
	}
	skip_pkts = skip_sign * abs_skip ;

	// set position
	tsreader->num_pkts = num_pkts ;
	tsreader->skip = abs_skip ;
	tsreader->origin = origin ;
	tsreader->tsstate->pidinfo.pktnum = 0 ;

	// skip if no file open
	if (!tsreader->file)
		return 0 ;

//TODO: check skip_pkts < num_pkts
//TODO: check against total pkts (tsreader->tsstate->total_pkts)


	// calc pos
	pos = (off64_t)(skip_pkts) * (off64_t)(TS_PACKET_LEN) ;

	tsparse_dbg_prt(100, ("tsreader_setpos(skip=%d, origin=%d) pos=%"PRId64"\n", skip_pkts, origin, (long long int)pos)) ;

	rc = lseek64(tsreader->file, pos, origin) ;

	tsparse_dbg_prt(100, ("lseek pos now = %"PRId64"\n", (long long int)rc)) ;

	if (rc == (off64_t)-1)
	{
		SET_DVB_ERROR(ERR_FILE_SEEK) ;
		if (tsreader->debug >= 100)
			perror("File seek error: ") ;

		// On error - reset to start of file
		lseek64(tsreader->file, (off64_t)0, SEEK_SET) ;

//TODO: on error seek to 0?
	}
	else
	{
		// set packet number
		tsreader->tsstate->pidinfo.pktnum = (unsigned)(rc / TS_PACKET_LEN) ;
	}

	return(dvb_error_code) ;
}

/* ----------------------------------------------------------------------- */
void tsreader_start_framenum(struct TS_reader *tsreader, unsigned framenum)
{
	CHECK_TS_READER(tsreader) ;
	tsreader->mpeg2.start_framenum = framenum ;
	tsreader->mpeg2.framenum = framenum ;
}


/* ----------------------------------------------------------------------- */
struct TS_reader *tsreader_new(char *filename)
{
int file = 0 ;
struct TS_reader *tsreader = NULL ;
off64_t size ;

	// open file iff specified
	if (filename)
	{
		file = open(filename, O_RDONLY | O_LARGEFILE | O_BINARY, 0666);
		if (-1 == file)
		{
			SET_DVB_ERROR(ERR_FILE) ;
			return(NULL);
		}
	}

	// create struct
	tsreader = (struct TS_reader *)malloc(sizeof(struct TS_reader)) ;
	CLEAR_MEM(tsreader) ;
	tsreader->MAGIC = MAGIC_READER ;

	tsreader->file = file ;
	tsreader->tsstate = tsstate_new() ;

	// work out total number of packets
	if (tsreader->file)
	{
		size = lseek64(tsreader->file, -1, SEEK_END) ;

		// size = -1 :
		// errorno=EINVAL for zero length file
		if (size < 0)
		{
			size = 0 ;
			SET_DVB_ERROR(ERR_FILE) ;
			if (errno == EINVAL)
			{
				SET_DVB_ERROR(ERR_FILE_ZERO) ;
			}
			tsreader_free(tsreader) ;
			return(NULL) ;
		}
		tsreader->tsstate->total_pkts = (unsigned)(size / (off64_t)TS_PACKET_LEN) ;
	}

	// set position
	tsreader_setpos(tsreader, 0, SEEK_SET, 0) ;

	return tsreader ;
}


/* ----------------------------------------------------------------------- */
struct TS_reader *tsreader_new_nofile()
{
	struct TS_reader *tsreader = tsreader_new( (char *)NULL ) ;

	return tsreader ;
}

/* ----------------------------------------------------------------------- */
// abort loop
void tsreader_stop(struct TS_reader *tsreader)
{
	CHECK_TS_READER(tsreader) ;
	tsreader->tsstate->stop_flag = 1 ;
}

/* ----------------------------------------------------------------------- */
void tsreader_free(struct TS_reader *tsreader)
{
	if (tsreader)
	{
		CHECK_TS_READER(tsreader) ;
		if (tsreader->file)
			close(tsreader->file) ;

		tsstate_free(tsreader->tsstate) ;

		// optionally clear out libmpeg2 settings
		if (tsreader->mpeg2.decoder)
			mpeg2_close (tsreader->mpeg2.decoder);
	    if (tsreader->mpeg2.video_buffer)
	    	free(tsreader->mpeg2.video_buffer) ;
	    free_frame_info_list(tsreader) ;

	    // optionally clear mpeg2audio settings
		if (tsreader->mpeg2audio.audio_buf)
			free(tsreader->mpeg2audio.audio_buf) ;

		if (tsreader->mpeg2audio.storage_buf)
			free(tsreader->mpeg2audio.storage_buf) ;

		free(tsreader) ;
	}
}

/* ----------------------------------------------------------------------- */
static void tsreader_set_mpeg2(struct TS_reader *tsreader)
{
	CHECK_TS_READER(tsreader) ;

	// optionally set up libmpeg2 settings
	if (tsreader->mpeg2_hook || tsreader->mpeg2_rgb_hook)
	{
		if (!tsreader->mpeg2.decoder)
		{
			tsreader->mpeg2.decoder = mpeg2_init ();
		    if (tsreader->mpeg2.decoder == NULL) {
				fprintf (stderr, "Could not allocate a decoder object.\n");
				exit (1);
		    }
		    tsreader->mpeg2.info = mpeg2_info (tsreader->mpeg2.decoder);
		    tsreader->mpeg2.framenum = 0;
		    tsreader->mpeg2.start_framenum = 0;
		    tsreader->mpeg2.gop_pktnum = 0;

		    tsreader->mpeg2.convert_rgb = 0;
		    if (tsreader->mpeg2_rgb_hook)
		    {
		    	// colour conversion
		    	tsreader->mpeg2.convert_rgb = 1;
		    }

		    tsreader->mpeg2.frame_info_list_size = 0 ;
			tsreader->mpeg2.frame_info_list = NULL ;
			tsreader->mpeg2.frame_info_index = 0 ;
		}
	}
}


/* ----------------------------------------------------------------------- */
static void tsreader_set_audio(struct TS_reader *tsreader)
{
	CHECK_TS_READER(tsreader) ;

	// optionally set up mpeg2audio settings
	if (tsreader->audio_hook)
	{
		if (!tsreader->mpeg2audio.audio_init)
		{
			decode_init();
		    tsreader->mpeg2audio.audio_init = 1 ;
		    tsreader->mpeg2audio.framenum = 0;
		    tsreader->mpeg2audio.audio_samples = 0;

		    tsreader->mpeg2audio.audio_buf = (short *)malloc(sizeof(short) * AUDIOBUFFER) ;
			CLEAR_MEM(tsreader->mpeg2audio.audio_buf) ;

		    tsreader->mpeg2audio.storage_buf = (uint8_t *)malloc(sizeof(uint8_t) * STORAGE_SIZE) ;
			CLEAR_MEM(tsreader->mpeg2audio.storage_buf) ;
			tsreader->mpeg2audio.write_ptr = tsreader->mpeg2audio.storage_buf ;
			tsreader->mpeg2audio.read_ptr = tsreader->mpeg2audio.storage_buf ;
		}
	}
}


/* ----------------------------------------------------------------------- */
// Only called when a file is specified
int ts_parse(struct TS_reader *tsreader)
{
uint8_t buffer[TS_BUFFSIZE];
int bytes_read ;
int status;

	CHECK_TS_READER(tsreader) ;

	status = 0 ;

	// check file open
	if (!tsreader->file)
	{
		RETURN_DVB_ERROR(ERR_FILE) ;
	}

	// initialise
	status = tsreader_data_start(tsreader) ;
	if (status) return (status) ;

    // main loop
    while (tsreader->buff_state.running > 0)
    {
		bytes_read = TS_BUFFSIZE_READ ;
    	status = getbuff(tsreader->file, buffer, &bytes_read) ;

    	// add packet and process
    	status = tsreader_data_add(tsreader, buffer, bytes_read) ;
    	if (status) return (status) ;

    } // while running

    // finish off
	status = tsreader_data_end(tsreader) ;

    return status;
}


/* ----------------------------------------------------------------------- */
int tsreader_data_start(struct TS_reader *tsreader)
{
	CHECK_TS_READER(tsreader) ;
	tsparse_dbg_prt(10, ("TS: tsreader_data_start()\n")) ;
	tsparse_dbg_prt(100, ("TS: # Total packets = %d\n", tsreader->tsstate->total_pkts)) ;

	tsreader->buff_state.bptr = tsreader->buff_state.buffer ;
	tsreader->buff_state.buffer_len = 0 ;
	tsreader->buff_state.running = 1 ;
	tsreader->buff_state.get_sync = 1 ;
	tsreader->buff_state.pktnum = 0 ;
	tsreader->buff_state.status = 0 ;


	// Ensure libmpeg2 info is correct
	tsreader_set_mpeg2(tsreader) ;

	// Ensure audio info is set up
	tsreader_set_audio(tsreader) ;

	// Progress required?
	if (tsreader->progress_hook)
	{
		tsreader->progress_info.scale = 1 ;
		if (tsreader->tsstate->total_pkts*100 > 0xffffffff)
		{
			tsreader->progress_info.scale = ( (tsreader->tsstate->total_pkts*100) / 0xffffffff) + 1 ;
		}
		tsreader->progress_info.step = tsreader->tsstate->total_pkts / (tsreader->progress_info.scale * 100) ;
		tsreader->progress_info.total = tsreader->tsstate->total_pkts / tsreader->progress_info.scale ;
		tsreader->progress_info.next_progress = tsreader->progress_info.step ;

		tsreader->progress_hook(PROGRESS_START, 0, tsreader->progress_info.total, tsreader->user_data) ;
	}

	return 0 ;
}



/* ----------------------------------------------------------------------- */
int tsreader_data_add(struct TS_reader *tsreader, uint8_t *data, unsigned data_len)
{
unsigned byte_num ;

tsparse_dbg_prt(10, ("TS: tsreader_data_add() running=%d data_len=%d : Current size = %d\n", tsreader->buff_state.running, data_len, tsreader->buff_state.buffer_len)) ;

	CHECK_TS_READER(tsreader) ;

	// skip if stopped
	if (!tsreader->buff_state.running)
		return 0 ;

	// skip if no data
	if (data_len == 0)
		return 0 ;

	// add new data
	if (tsreader->buff_state.buffer_len < TS_PACKET_LEN)
	{
    	tsreader->buff_state.bptr = tsreader->buff_state.buffer ;
    	tsreader->buff_state.buffer_len = data_len ;
    	memcpy(tsreader->buff_state.buffer, data, data_len*sizeof(uint8_t)) ;

    	tsreader->buff_state.get_sync = 1 ;

//fprintf(stderr, "bptr[0]=0x%02x\n", tsreader->buff_state.bptr[0]) ;
//fprintf(stderr, "bptr=%p\n", tsreader->buff_state.bptr) ;
//fprintf(stderr, "buffer_len=%d\n", tsreader->buff_state.buffer_len) ;

    	tsparse_dbg_prt(10, ("TS: Reload buffer : 0x%02x (bptr @ %p) %d bytes left\n",
    			tsreader->buff_state.bptr[0], tsreader->buff_state.bptr, tsreader->buff_state.buffer_len)) ;
	}
	// check overflow (should never happen!)
	else if (tsreader->buff_state.buffer_len + data_len >= TS_BUFFSIZE)
	{
		// restart
		data_len %= TS_BUFFSIZE ;
    	tsreader->buff_state.bptr = tsreader->buff_state.buffer ;
    	tsreader->buff_state.buffer_len = data_len ;
    	memcpy(tsreader->buff_state.buffer, data, data_len*sizeof(uint8_t)) ;

    	tsreader->buff_state.get_sync = 1 ;

fprintf(stderr, "\n**OVERFLOW**\n") ;

    	tsparse_dbg_prt(10, ("TS: *OVERFLOW* Reload buffer : 0x%02x (bptr @ %p) %d bytes left\n",
    			tsreader->buff_state.bptr[0], tsreader->buff_state.bptr, tsreader->buff_state.buffer_len)) ;
	}
	// append data
	else
	{
//		unsigned data_used = (tsreader->buff_state.bptr - tsreader->buff_state.buffer) ;
//		if (data_len + tsreader->buff_state.buffer_len + data_used >= TS_BUFFSIZE )
//		{
//			data_len = TS_BUFFSIZE - 1 - (tsreader->buff_state.buffer_len + data_used) ;
//		}

		// append data
    	memcpy(&tsreader->buff_state.bptr[tsreader->buff_state.buffer_len], data, data_len*sizeof(uint8_t)) ;
    	tsreader->buff_state.buffer_len += data_len ;

    	tsparse_dbg_prt(10, ("TS: Append buffer : 0x%02x (bptr @ %p) %d bytes left\n",
    			tsreader->buff_state.bptr[0], tsreader->buff_state.bptr, tsreader->buff_state.buffer_len)) ;
	}

	while (tsreader->buff_state.running && (tsreader->buff_state.buffer_len > 0) )
	{
		tsparse_dbg_prt(100, ("TS: Loop start...(len=%d) running=%d, get sync=%d\n",
				tsreader->buff_state.buffer_len,
				tsreader->buff_state.running,
				tsreader->buff_state.get_sync)) ;

		// check for sync if required
		if (tsreader->buff_state.get_sync)
		{
			tsparse_dbg_prt(10, ("TS: waiting for sync...\n")) ;

			// wait for sync byte, but abort if we've waited for at least 4 packets and not found it
			byte_num=0;
			while ( (tsreader->buff_state.buffer_len > 0) && (tsreader->buff_state.bptr[0] != SYNC_BYTE) && (byte_num < (4*TS_PACKET_LEN)) )
			{
				tsreader->buff_state.buffer_len-- ;
				tsreader->buff_state.bptr++ ;
				byte_num++ ;

				tsparse_dbg_prt(10, ("TS:  + byte[0]=0x%02x num=%d\n", tsreader->buff_state.bptr[0], byte_num)) ;
			}
			tsreader->buff_state.get_sync = 0 ;

			// did we find it?
			if  ((tsreader->buff_state.buffer_len == 0) || (tsreader->buff_state.bptr[0] != SYNC_BYTE))
			{
				// clear buffer
				tsreader->buff_state.get_sync = 1 ;
				tsreader->buff_state.buffer_len = 0 ;

				// return error
				RETURN_DVB_ERROR(ERR_NOSYNC) ;
			}
		}
		tsparse_dbg_prt(10, ("TS: handling TS packets...(buffer @ %p => 0x%02x)\n", tsreader->buff_state.buffer, tsreader->buff_state.bptr[0])) ;

		// handle rest of TS packet(s)
		while ( tsreader->buff_state.running && !tsreader->buff_state.get_sync && (tsreader->buff_state.buffer_len >= TS_PACKET_LEN) )
		{
			tsparse_dbg_prt(10, ("TS: Start data of loop : 0x%02x (bptr @ %p) %d bytes left : local pkt count = %u\n",
					tsreader->buff_state.bptr[0], tsreader->buff_state.bptr, tsreader->buff_state.buffer_len, tsreader->buff_state.pktnum)) ;
			tsparse_dbg_prt(10, ("TS: # pkt count = %u\n", tsreader->buff_state.pktnum)) ;

			// check sync byte
			if (tsreader->buff_state.bptr[0] != SYNC_BYTE)
			{
				// re-sync
				++tsreader->buff_state.get_sync ;

				tsparse_dbg_prt(10, ("TS: ! Resync required : 0x%02x (bptr @ %p)\n", tsreader->buff_state.bptr[0], tsreader->buff_state.bptr)) ;
			}
			else
			{
				// Do something with the packet
				parse_ts_packet(tsreader, tsreader->tsstate, tsreader->buff_state.bptr, TS_PACKET_LEN) ;

				// Progress required?
				if (tsreader->progress_hook)
				{
					if (tsreader->buff_state.pktnum == tsreader->progress_info.next_progress)
					{
						tsreader->progress_hook(PROGRESS_RUNNING,
								(unsigned)(tsreader->buff_state.pktnum / tsreader->progress_info.scale),
								tsreader->progress_info.total,
								tsreader->user_data) ;

						tsreader->progress_info.next_progress += tsreader->progress_info.step ;
					}
				}

				//== check for end ==
				++tsreader->buff_state.pktnum ;
				++tsreader->tsstate->pidinfo.pktnum ;

				// only compare with total packets if it's been set!
				if (tsreader->tsstate->total_pkts && (tsreader->buff_state.pktnum >= tsreader->tsstate->total_pkts) )
				{
					// reached end of file
					tsreader->buff_state.running = 0 ;
					tsparse_dbg_prt(100, ("TS: stop running total pkts (len=%d)\n", tsreader->buff_state.buffer_len)) ;
				}

				// check if max packets has been set
				if (tsreader->num_pkts && (tsreader->buff_state.pktnum >= tsreader->num_pkts) )
				{
					// reached requested number of packets
					tsreader->buff_state.running = 0 ;
					tsparse_dbg_prt(100, ("TS: stop running num pkts> (len=%d)\n", tsreader->buff_state.buffer_len)) ;
				}

				// check special STOP flag
				if (tsreader->tsstate->stop_flag)
				{
					// stop request
					tsreader->buff_state.running = 0 ;
					tsparse_dbg_prt(100, ("TS: stop running flag (len=%d)\n", tsreader->buff_state.buffer_len)) ;
				}

				// update buffer
				tsreader->buff_state.buffer_len -= TS_PACKET_LEN ;
				tsreader->buff_state.bptr += TS_PACKET_LEN ;

			} // if get_sync

			tsparse_dbg_prt(10, ("TS: End of data loop : 0x%02x (bptr @ %p) %d bytes left\n",
					tsreader->buff_state.bptr[0], tsreader->buff_state.bptr, tsreader->buff_state.buffer_len)) ;

			tsparse_dbg_prt(10, ("TS: running=%d, get sync=%d, buff len=%d\n",
					tsreader->buff_state.running, tsreader->buff_state.get_sync, tsreader->buff_state.buffer_len)) ;

		} // while in sync


		// process other bytes if still got data
		if ((tsreader->buff_state.buffer_len > 0) && (tsreader->buff_state.bptr[0] != SYNC_BYTE))
		{
			tsreader->buff_state.get_sync = 1 ;
		}

		tsparse_dbg_prt(100, ("TS: Loop end...(len=%d)\n", tsreader->buff_state.buffer_len)) ;

	} // while got data

	return 0 ;
}


/* ----------------------------------------------------------------------- */
int tsreader_data_end(struct TS_reader *tsreader)
{
	CHECK_TS_READER(tsreader) ;

	// Progress required?
	if (tsreader->progress_hook)
	{
		unsigned scaled_pktnum = (unsigned)(tsreader->buff_state.pktnum / tsreader->progress_info.scale) ;
		if (scaled_pktnum > tsreader->progress_info.total) scaled_pktnum = tsreader->progress_info.total ;

		if (tsreader->tsstate->stop_flag)
		{
			// premature stop
			tsreader->progress_hook(PROGRESS_STOPPED,
					scaled_pktnum,
					tsreader->progress_info.total,
					tsreader->user_data) ;
		}
		else
		{
			// run to end
			tsreader->progress_hook(PROGRESS_END,
					tsreader->progress_info.total,
					tsreader->progress_info.total,
					tsreader->user_data) ;
		}
	}

	tsparse_dbg_prt(10, ("TS: tsreader_data_end() - END\n")) ;

    return 0;
}

