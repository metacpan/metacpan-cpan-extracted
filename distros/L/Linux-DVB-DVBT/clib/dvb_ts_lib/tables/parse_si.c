/*
 * parse_si.c
 *
 *  Created on: 2 Apr 2011
 *      Author: sdprice1
 */


// VERSION = 1.01

/*=============================================================================================*/
// USES
/*=============================================================================================*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <ctype.h>
#include <fcntl.h>
#include <inttypes.h>

#include "parse_si.h"

#include "tables/parse_si_pat.h"  /* 0x00 */
#include "tables/parse_si_cat.h"  /* 0x01 */
#include "tables/parse_si_pmt.h"  /* 0x02 */
#include "tables/parse_si_nit.h"  /* 0x40 */
#include "tables/parse_si_sdt.h"  /* 0x42 */
#include "tables/parse_si_bat.h"  /* 0x4a */
#include "tables/parse_si_eit.h"  /* 0x4e */
#include "tables/parse_si_tdt.h"  /* 0x70 */
#include "tables/parse_si_rst.h"  /* 0x71 */
#include "tables/parse_si_st.h"  /* 0x72 */
#include "tables/parse_si_tot.h"  /* 0x73 */
#include "tables/parse_si_cit.h"  /* 0x77 */
#include "tables/parse_si_dit.h"  /* 0x7e */
#include "tables/parse_si_sit.h"  /* 0x7f */

/*=============================================================================================*/
// CONSTANTS
/*=============================================================================================*/

// Maximum section lengths
unsigned SECTION_MAX_LENGTHS[SECTION_MAX+1] = {
	// default max length is 1024 bytes (-1 header -2 crc)
	[0 ... SECTION_MAX]							= 1021,

	// These default to 4043
	[SECTION_ST]							 	= 4093,
	[SECTION_EIT_START ... SECTION_EIT_END] 	= 4093,
	[SECTION_SIT]							 	= 4093,
	[SECTION_CIT]							 	= 4093,

	// This is a funny!
	[SECTION_DIT]							 	= 1
} ;

// Section syntax values
#define SYNTAX_0			0x00
#define SYNTAX_1			0x80
#define SYNTAX_EITHER		0xFF
unsigned SECTION_SYNTAX[SECTION_MAX+1] = {
	// Most have the bit set
	[0 ... SECTION_MAX]							= SYNTAX_1,

	// These have bit 0
	[SECTION_TDT]							 	= SYNTAX_0,
	[SECTION_TOT]							 	= SYNTAX_0,
	[SECTION_RST]							 	= SYNTAX_0,
	[SECTION_DIT]							 	= SYNTAX_0,

	// Special
	[SECTION_ST]							 	= SYNTAX_EITHER,

} ;


/*=============================================================================================*/
// MACROS
/*=============================================================================================*/


/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

static void dummy_handler(struct TS_reader *tsreader, struct TS_state *tsstate, struct Section *section, void *user_data)
{

}


/* ----------------------------------------------------------------------- */
void print_si(struct Section *section)
{
	switch(section->table_id)
	{

		// PAT
		case SECTION_PAT:
			print_pat((struct Section_program_association *)section) ;
			break;

		// CAT
		case SECTION_CAT:
			print_cat((struct Section_conditional_access *)section) ;
			break;

		// PMT
		case SECTION_PMT:
			print_pmt((struct Section_program_map *)section) ;
			break;

		// NIT this
		case SECTION_NIT_ACTUAL:
		// NIT other
		case SECTION_NIT_OTHER:
			print_nit((struct Section_network_information *)section) ;
			break;

		// SDT this
		case SECTION_SDT_ACTUAL:
		// SDT other
		case SECTION_SDT_OTHER:
			print_sdt((struct Section_service_description *)section) ;
			break;

		// BAT
		case SECTION_BAT:
			print_bat((struct Section_bouquet_association *)section) ;
			break;

		// Now/Next this
		case SECTION_EIT_NOW_ACTUAL:
		// Now/Next other
		case SECTION_EIT_NOW_OTHER:
		// EIT this
		case SECTION_EIT_ACTUAL_START ... SECTION_EIT_ACTUAL_END:
		// EIT other
		case SECTION_EIT_OTHER_START ... SECTION_EIT_OTHER_END:
			print_eit((struct Section_event_information *)section) ;
			break;

		// TDT
		case SECTION_TDT:
			print_tdt((struct Section_time_date *)section) ;
			break;

		// RST
		case SECTION_RST:
			print_rst((struct Section_running_status *)section) ;
			break;

		// ST
		case SECTION_ST:
			print_st((struct Section_stuffing *)section) ;
			break;

		// TOT
		case SECTION_TOT:
			print_tot((struct Section_time_offset *)section) ;
			break;

		// CIT
		case SECTION_CIT:
			print_cit((struct Section_content_identifier *)section) ;
			break;

		// DIT
		case SECTION_DIT:
			print_dit((struct Section_discontinuity_information *)section) ;
			break;

		// SIT
		case SECTION_SIT:
			print_sit((struct Section_selection_information *)section) ;
			break;


		default:
			break;
	}

}

/* ----------------------------------------------------------------------- */
int parse_si(struct TS_reader *tsreader, struct TS_state *tsstate, uint8_t *payload, unsigned payload_len)
{
unsigned table_id ;
unsigned section_len ;
unsigned section_syntax ;
unsigned max_section_len ;
unsigned expected_syntax ;
int ptr ;
int payload_left = payload_len ;
Section_handler handler = NULL ;
struct Section_decode_flags	flags ;

	tsparse_dbg_prt(10, ("\n== parse_si() : PID 0x%02x : payload len %d [0x%02x] ==\n", tsstate->pid_item->pidinfo.pid, payload_left, payload[0]));

	CHECK_TS_READER(tsreader) ;
	CHECK_TS_STATE(tsstate) ;
	CHECK_TS_PID(tsstate->pid_item) ;

//fprintf(stderr, "\n== parse_si() : payload len %d [0x%02x] ==\n", payload_left, payload[0]);
//fprintf(stderr, " + payload len %d\n", payload_left);
//fprintf(stderr, " + payload [0x%02x]\n", payload[0]);


	// keep processing while we've got some buffer left AND we're not at the stuffing bytes
	while ( (payload_left > (SI_HEADER_LEN+SI_CRC_LEN)) && (payload[0] != 0xff) )
	{
		tsparse_dbg_prt(10, ("\nparse_si() loop start: payload now:\n"));

//fprintf(stderr, " + loop start: payload left now = %d [payload buff @ %p]\n", payload_left, payload);

		if (tsreader->debug >= 104)
			dump_buff(&payload[0], payload_left, payload_left) ;


		//	pointer_field 8 uimsbf
		ptr = payload[0] ;

		// check to see if we've skipped off the end of the buffer!
		if ( (payload_left-ptr) < (SI_HEADER_LEN+SI_CRC_LEN) )
		{
//fprintf(stderr, " ** ptr=%d - Invalid PTR?\n", ptr);

			if (tsreader->error_hook)
			{
				SET_DVB_ERROR(ERR_SECTIONLEN) ;
				if (tsreader->error_hook)
					tsreader->error_hook(dvb_error_code, &tsstate->pidinfo, tsreader->user_data) ;
			}

			return 0 ;
		}
//fprintf(stderr, " + + ptr=%d payload left now = %d [payload buff @ %p]\n", ptr, payload_left-ptr, &payload[ptr]);

		//	table_id 8 uimsbf
		//	section_syntax_indicator 1 bslbf
		//	indicator 1 bslbf
		//	reserved 2 bslbf
		//	section_length 12 uimsbf
		table_id = payload[ptr+1] & SECTION_MAX ;
		section_syntax = payload[ptr+2] & 0x80 ;

		max_section_len = SECTION_MAX_LENGTHS[table_id] ;
		expected_syntax = SECTION_SYNTAX[table_id] ;

		// number of bytes AFTER this field INCLUDING 4 byte CRC
		section_len = ((payload[ptr+2] & 0x0f)<<8) | payload[ptr+3] ;

		tsparse_dbg_prt(102, ("PSI pid %d Table %d Len %d : 0x%02x 0x%02x 0x%02x 0x%02x \n",
			tsstate->pidinfo.pid, table_id, section_len, payload[ptr+0], payload[ptr+1], payload[ptr+2], payload[ptr+3])) ;

		tsparse_dbg_prt(2, ("PSI pid 0x%x Table 0x%x [ptr 0x%02x] Sect Len %d : Payload left %d (syntax 0x%02x)\n",
				tsstate->pidinfo.pid, table_id,
				ptr,
				section_len, payload_left,
				section_syntax)) ;


		// error check
		if (section_len > max_section_len)
		{
			tsparse_dbg_prt(2, ("PSI pid 0x%x Table 0x%x : section length error : %d (max %d)\n",
					tsstate->pidinfo.pid, table_id,
					section_len,
					max_section_len)) ;

			tsstate->pid_item->pesinfo.psi_error++ ;
			tsstate->pidinfo.pid_error++ ;
			if (tsreader->error_hook)
			{
				SET_DVB_ERROR(ERR_SECTIONLEN) ;
				if (tsreader->error_hook)
					tsreader->error_hook(dvb_error_code, &tsstate->pidinfo, tsreader->user_data) ;
			}

			return 0 ;
		}
		else
		{
			// skip PTR & header
			payload_left -= SI_HEADER_LEN ;

			// get handler for this SI table - skip if none specified
			handler = tsreader->section_decode_table[table_id].handler ;
			flags = tsreader->section_decode_table[table_id].flags ;

			// check section fits into remaining buffer
			if ((section_len <= payload_left) && handler)
			{
				// check syntax
				if ((expected_syntax != SYNTAX_EITHER) && (section_syntax != expected_syntax))
				{
					tsparse_dbg_prt(2, ("Invalid section syntax 0x%02x (expected 0x%02x)\n", section_syntax, expected_syntax)) ;

					SET_DVB_ERROR(ERR_TSCORRUPT) ;
					if (tsreader->error_hook)
						tsreader->error_hook(dvb_error_code, &tsstate->pidinfo, tsreader->user_data) ;

					//TODO: Return here!
					//return 0 ;
				}

				// CRC covers whole packet from table_id to crc, need to extend length by section head
				uint32_t crc = crc32 (&payload[ptr+1], section_len+SECTION_HEADER_LEN);
				if (!crc)
				{
					tsparse_dbg_prt(100, ("**SI CRC PASS**\n")) ;
				}
				else
				{
					tsparse_dbg_prt(2, ("!!SI CRC FAIL!! - SI skipped\n")) ;
					return 0 ;
				}

				// ignore CRC in lower level decoding
				struct TS_bits *bits = bits_new(&payload[ptr+1], section_len+SECTION_HEADER_LEN-SI_CRC_LEN) ;


				switch(table_id)
				{

					// PAT
					case SECTION_PAT:
						if (tsreader->debug >= 103)
							dump_buff(&payload[ptr+1], payload_left, section_len) ;
						parse_pat(tsreader, tsstate, bits, handler, &flags) ;
						break;

					// CAT
					case SECTION_CAT:
						if (tsreader->debug >= 103)
							dump_buff(&payload[ptr+1], payload_left, section_len) ;
						parse_cat(tsreader, tsstate, bits, handler, &flags) ;
						break;

					// PMT
					case SECTION_PMT:
						if (tsreader->debug >= 103)
							dump_buff(&payload[ptr+1], payload_left, section_len) ;
						parse_pmt(tsreader, tsstate, bits, handler, &flags) ;
						break;

					// NIT this
					case SECTION_NIT_ACTUAL:
					// NIT other
					case SECTION_NIT_OTHER:
						if (tsreader->debug >= 103)
							dump_buff(&payload[ptr+1], payload_left, section_len) ;
						parse_nit(tsreader, tsstate, bits, handler, &flags) ;
						break;

					// SDT this
					case SECTION_SDT_ACTUAL:
					// SDT other
					case SECTION_SDT_OTHER:
						if (tsreader->debug >= 103)
							dump_buff(&payload[ptr+1], payload_left, section_len) ;
						parse_sdt(tsreader, tsstate, bits, handler, &flags) ;
						break;

					// BAT
					case SECTION_BAT:
						if (tsreader->debug >= 103)
							dump_buff(&payload[ptr+1], payload_left, section_len) ;
						parse_bat(tsreader, tsstate, bits, handler, &flags) ;
						break;

					// Now/Next this
					case SECTION_EIT_NOW_ACTUAL:
					// Now/Next other
					case SECTION_EIT_NOW_OTHER:
					// EIT this
					case SECTION_EIT_ACTUAL_START ... SECTION_EIT_ACTUAL_END:
					// EIT other
					case SECTION_EIT_OTHER_START ... SECTION_EIT_OTHER_END:
						if (tsreader->debug >= 103)
							dump_buff(&payload[ptr+1], payload_left, section_len) ;
						parse_eit(tsreader, tsstate, bits, handler, &flags) ;
						break;

					// TDT
					case SECTION_TDT:
						if (tsreader->debug >= 103)
							dump_buff(&payload[ptr+1], payload_left, section_len) ;
						parse_tdt(tsreader, tsstate, bits, handler, &flags) ;
						break;

					// RST
					case SECTION_RST:
						if (tsreader->debug >= 103)
							dump_buff(&payload[ptr+1], payload_left, section_len) ;
						parse_rst(tsreader, tsstate, bits, handler, &flags) ;
						break;

					// ST
					case SECTION_ST:
						if (tsreader->debug >= 103)
							dump_buff(&payload[ptr+1], payload_left, section_len) ;
						parse_st(tsreader, tsstate, bits, handler, &flags) ;
						break;

					// TOT
					case SECTION_TOT:
						if (tsreader->debug >= 103)
							dump_buff(&payload[ptr+1], payload_left, section_len) ;
						parse_tot(tsreader, tsstate, bits, handler, &flags) ;
						break;

					// CIT
					case SECTION_CIT:
						if (tsreader->debug >= 103)
							dump_buff(&payload[ptr+1], payload_left, section_len) ;
						parse_cit(tsreader, tsstate, bits, handler, &flags) ;
						break;

					// DIT
					case SECTION_DIT:
						if (tsreader->debug >= 103)
							dump_buff(&payload[ptr+1], payload_left, section_len) ;
						parse_dit(tsreader, tsstate, bits, handler, &flags) ;
						break;

					// SIT
					case SECTION_SIT:
						if (tsreader->debug >= 103)
							dump_buff(&payload[ptr+1], payload_left, section_len) ;
						parse_sit(tsreader, tsstate, bits, handler, &flags) ;
						break;


					default:
fprintf(stderr, "!! Unexpected Table 0x%02x !!\n", table_id) ;
						break;
				}

				bits_free(&bits) ;
			}
		}

		// skip to end of this section (ready for any subsequent section)
		unsigned section_total = (ptr+1) + SECTION_HEADER_LEN + section_len ;
		payload_left -= section_total ;
		payload += section_total ;

		tsparse_dbg_prt(10, (" + parse_si() end of loop : payload left %d\n", payload_left)) ;

	} // while

	return 0 ;
}
