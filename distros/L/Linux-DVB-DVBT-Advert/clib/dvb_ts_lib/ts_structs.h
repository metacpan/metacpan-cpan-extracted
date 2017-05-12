/*
 * ts_structs.h
 *
 *  Created on: 14 Apr 2011
 *      Author: sdprice1
 */

#ifndef TS_STRUCTS_H_
#define TS_STRUCTS_H_

#include <inttypes.h>

//-- config --
#include "config.h"

#include "list.h"
#include "dvb_error.h"

// libmpeg2
#include "mpeg2.h"
#include "mpeg2convert.h"

// mpeg2audio
#include "mpegaudio.h"

// SI tables
#include "tables/si_structs.h"

/*=============================================================================================*/
// CONSTANTS
/*=============================================================================================*/

#define NULL_PID		0x1fff
#define MAX_PID			NULL_PID
#define ALL_PID			(MAX_PID+1)

// ISO 13818-1
#define SYNC_BYTE			0x47
#define TS_PACKET_LEN		188
//#define MAX_SECTION_LEN 	1021
#define TS_FREQ				90000

// create a buffer that is a number of packets long
// (this is approx 4k)
#define TS_BUFFSIZE				(24 * TS_PACKET_LEN)

// Read in 1-2 packets less than the full buffer size to allow for "unused" spare bytes
#define TS_BUFFSIZE_READ		(TS_BUFFSIZE - (2 * TS_PACKET_LEN))


// clear memory
#define CLEAR_MEM(mem)	memset(mem, 0, sizeof(*mem))


// PTS, timing etc
#define UNSET_TS			((int64_t)-1)
#define FPS					25
#define VIDEO_PTS_DELTA		(TS_FREQ / FPS)


/*=============================================================================================*/
// MACROS
/*=============================================================================================*/

// print debug if debug setting is high enough
#define tsparse_dbg_prt(LVL, ARGS)	\
		if (tsreader->debug >= LVL)	{ printf ARGS ; fflush(stdout) ; }

#define DO_CHECK_MAGIC

#ifdef DO_CHECK_MAGIC
#define CHECK_TS_MAGIC(b, magic, type)	\
	if (!b || (b->MAGIC != magic))	\
	{									\
		fprintf(stderr, "Invalid %s [%p] at %s %d\n", type, b, __FILE__, __LINE__) ; \
	}
#else
#define CHECK_TS_MAGIC(b, magic, type)
#endif

/*=============================================================================================*/
// STRUCTURES
/*=============================================================================================*/

enum TS_pes_type {
	// ISO 11172-2 Video
	picture_start_code			= 0x100,
	// slice_start_codes (including slice_vertical_positions)	0x101 .. 0x1AF
	slice_start_code_start		= 0x101,
	slice_start_code_end		= 0x1AF,

	// reserved1				= 0x1B0,
	// reserved2				= 0x1B1,
	user_data_start_code		= 0x1B2,
	sequence_header_code		= 0x1B3,
	sequence_error_code			= 0x1B4,
	extension_start_code		= 0x1B5,
	// reserved3				= 0x1B6,
	sequence_end_code			= 0x1B7,
	group_start_code			= 0x1B8,

	// system start codes (see note)	0x1B9 .. 0x1FF
	system_start_code_start		= 0x1B9,
	system_start_code_end		= 0x1FF,

	// ISO 13818-1
	program_stream_map			= 0x1bc,
	private_stream_1			= 0x1bd,
	padding_stream				= 0x1be,
	private_stream_2			= 0x1bf,

	// 0x1C0 .. 0x1DF (audio stream 00..1F)
	audio_stream				= 0x1c0,
	audio_stream_mask			= 0x1e0,

	// 0x1E0 .. 0x1EF (video stream 0..F)
	video_stream				= 0x1e0,
	video_stream_mask			= 0x1f0,

	ECM_stream					= 0x1f0,
	EMM_stream					= 0x1f1,
	DSMCC_stream				= 0x1f2,
	a13522_stream				= 0x1f3,
	H2221_A_stream				= 0x1f4,
	H2221_B_stream				= 0x1f5,
	H2221_C_stream				= 0x1f6,
	H2221_D_stream				= 0x1f7,
	H2221_E_stream				= 0x1f8,
	ancillary_stream			= 0x1f9,
	program_stream_directory	= 0x1ff
};

enum TS_frame_flags {

	FRAME_FLAG_START			= 0x0001,
	FRAME_FLAG_SLICE			= 0x0002,
	FRAME_FLAG_USER_DATA		= 0x0004,
	FRAME_FLAG_SEQ_HEAD			= 0x0008,
	FRAME_FLAG_SEQ_ERROR		= 0x0010,
	FRAME_FLAG_EXTENSION		= 0x0020,
	FRAME_FLAG_SEQ_END			= 0x0040,
	FRAME_FLAG_GOP				= 0x0080,
	FRAME_FLAG_SYSTEM			= 0x0100,
	FRAME_FLAG_RESERVED			= 0x8000,
} ;


typedef struct mpeg2_audio {
	unsigned 		sample_rate	;
	unsigned 		channels ;
	unsigned 		samples_per_frame ;
	short			*audio ;
	unsigned 		samples ;
	unsigned 		audio_framenum ;
	unsigned 		framesize ;
	unsigned		pts_delta ;
	int64_t			pts ;
} mpeg2_audio_t ;

enum TS_progress_state {
	PROGRESS_START,
	PROGRESS_RUNNING,
	PROGRESS_END,
	PROGRESS_STOPPED
};



//----------------------------------------------------------------------------------------------
// Callbacks

struct TS_state ;
struct TS_buffer ;
struct TS_pidinfo ;
struct TS_pesinfo ;
struct TS_frame_info ;

typedef unsigned (*tsparse_pid_hook)(unsigned, void *) ;
typedef void (*tsparse_error_hook)(enum DVB_error, struct TS_pidinfo *, void *) ;
typedef void (*tsparse_payload_hook)(struct TS_pidinfo *, uint8_t *, unsigned, void *) ;
typedef void (*tsparse_ts_hook)(struct TS_pidinfo *, uint8_t *, unsigned, void *) ;
typedef void (*tsparse_pes_hook)(struct TS_pidinfo *, struct TS_pesinfo *, uint8_t *, unsigned, void *) ;
typedef void (*tsparse_pes_data_hook)(struct TS_pidinfo *, struct TS_pesinfo *, uint8_t *, unsigned, void *) ;
typedef void (*tsparse_progress_hook)(enum TS_progress_state state, unsigned progress, unsigned total, void *) ;
typedef void (*tsparse_mpeg2_hook)(struct TS_pidinfo *, struct TS_frame_info *, const mpeg2_info_t *, void *) ;
typedef void (*tsparse_mpeg2_rgb_hook)(struct TS_pidinfo *, struct TS_frame_info *, const mpeg2_info_t *, void *) ;
typedef void (*tsparse_audio_hook)(struct TS_pidinfo *, struct TS_pesinfo *, const mpeg2_audio_t *, void *) ;


//----------------------------------------------------------------------------------------------
// Generic buffer

#define MAGIC_BUFF	0x5344500B
struct TS_buffer {
	unsigned	MAGIC ;
	unsigned	buff_size ;
	unsigned	data_len ;
	uint8_t *	buff ;
};

#define CHECK_TS_BUFF(b)	CHECK_TS_MAGIC(b, MAGIC_BUFF, "TS_buffer")

//----------------------------------------------------------------------------------------------
// PID information

struct TS_pidinfo {
	unsigned pid ;
	unsigned err_flag ;
	unsigned pes_start ;
	unsigned afc ;
	unsigned pid_error ;

	unsigned pktnum ;
};

//----------------------------------------------------------------------------------------------
// Current PES state

enum TS_pes_psi {
	T_PSI,
	T_PES,
};

struct TS_pesinfo {
	unsigned code ;

	unsigned start_pkt ;
	unsigned end_pkt ;

	int64_t start_dts ;
	int64_t start_pts ;
	int64_t end_dts ;
	int64_t end_pts ;
	int64_t dts ;
	int64_t pts ;

	enum TS_pes_psi	pes_psi ;
	unsigned psi_error ;
	unsigned pes_error ;
	unsigned ts_error ;

	// reference to the data portion of the PES packet (if it has one)
	uint8_t * 	pesdata_p ;
	unsigned 	pesdata_len ;

};


//----------------------------------------------------------------------------------------------
// Information relating to the current video frame

struct TS_frame_info {
	unsigned framenum ;
	unsigned gop_pkt ;

	// copy of PES info for this frame
	struct TS_pesinfo pesinfo ;

	// copy of PID info for this frame
	struct TS_pidinfo pidinfo ;
};



//----------------------------------------------------------------------------------------------
// Current PID state

enum TS_pesstate {
	PES_SKIP,
	PES_HEADER,
	PES_PAYLOAD
};
#define MAGIC_PID		0x53445001
struct TS_pid {
    struct list_head    next;

	unsigned MAGIC ;
    struct TS_pidinfo	pidinfo ;
    struct TS_pesinfo	pesinfo ;
    struct TS_buffer *	pes_buff ;
    enum TS_pesstate	pes_state ;
};

#define CHECK_TS_PID(b)	CHECK_TS_MAGIC(b, MAGIC_PID, "TS_pid")



#if 0
//----------------------------------------------------------------------------------------------
// Each TS packet consists of data and a state that is either collecting (i.e. filling a PES packet before
// checking), has been marked as an error, or has been marked as being good
// Once it's marked as good/bad, then all packets making up the PES can be processed
enum TS_pkstate {
	PKT_SKIP,
	PKT_FILLING,
	PKT_OK,
	PKT_ERR
};
struct TS_pkt {
    struct list_head    next;

	uint8_t			ts_packet[TS_PACKET_LEN] ;
	unsigned		pktnum;
	enum TS_pkstate pkt_state ;
};
#endif

//----------------------------------------------------------------------------------------------
// Current parse state
#define MAGIC_STATE		0x53445002
struct TS_state {
	unsigned MAGIC ;
	struct TS_pidinfo 	pidinfo ;
	struct TS_pid		*pid_item ;

	// list of TS_pid
    struct list_head    pid_list;

    // Set to total number of packets
    unsigned			total_pkts ;

    // set to min/max pts/dts times
	int64_t 			start_ts ;
	int64_t 			end_ts ;

	// Stop flag - set by callbacks to exit the loop
	unsigned			stop_flag ;

//    // list of TS packets
//	unsigned			start_pktnum ;
//
//	// list of TS_pkt
//	struct list_head	pkt_list ;
};
#define CHECK_TS_STATE(b)	CHECK_TS_MAGIC(b, MAGIC_STATE, "TS_state")

//----------------------------------------------------------------------------------------------
// Current buffer state
struct TS_buff_state {
	uint8_t buffer[TS_BUFFSIZE];
	int buffer_len ;

	uint8_t *bptr ;
	int bytes_left ;

	int status;
	unsigned get_sync ;
	int running ;

	unsigned pktnum ;
};


//----------------------------------------------------------------------------------------------
// TS reader

#define MAGIC_READER	0x5344500F
typedef struct TS_reader {
	// set by user
	int						file ;
	unsigned 				debug ;
	unsigned				num_pkts ;
	int64_t					skip ;
	int						origin ;
	void 					*user_data ;

	tsparse_pid_hook		pid_hook ;
	tsparse_error_hook		error_hook ;
	tsparse_payload_hook	payload_hook ;
	tsparse_ts_hook			ts_hook ;
	tsparse_pes_hook		pes_hook ;
	tsparse_pes_data_hook	pes_data_hook ;
	tsparse_mpeg2_hook		mpeg2_hook ;
	tsparse_mpeg2_rgb_hook	mpeg2_rgb_hook ;
	tsparse_audio_hook		audio_hook ;
	tsparse_progress_hook	progress_hook ;

	// internally set
	struct TS_state			*tsstate ;
	struct TS_buff_state	buff_state ;
	unsigned				MAGIC ;

	struct {
		unsigned				step ;
		unsigned				scale ;
		unsigned				next_progress ;
		unsigned				total ;
	}						progress_info ;

	// Optional libmpeg2
	struct {
		mpeg2dec_t 				*decoder;
		const mpeg2_info_t 		*info;
		unsigned				start_framenum;
		unsigned				framenum;
		unsigned				gop_pktnum;
		uint8_t 				*video_buffer ;
		unsigned				convert_rgb ;

		struct TS_frame_info	*frame_info_list ;
		unsigned				frame_info_list_size ;
		unsigned				frame_info_index ;
	} 						mpeg2 ;

	// Optional mpeg2audio
	struct {
		unsigned				audio_init ;
		unsigned				framenum;
		short					*audio_buf ;
		uint8_t					*storage_buf ;
		uint8_t					*write_ptr ;
		uint8_t					*read_ptr ;
		unsigned 				audio_samples ;
	} 						mpeg2audio ;


	// Register the SI tables that you'd like to be decoded (none are decoded by default)
	struct Section_registry		section_decode_table[SECTION_MAX+1] ;

} TSReader ;

#define CHECK_TS_READER(b)	CHECK_TS_MAGIC(b, MAGIC_READER, "TS_reader")



#endif /* TS_STRUCTS_H_ */
