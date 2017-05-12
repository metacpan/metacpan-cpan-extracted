/*
 * ts_parse.h
 *
 *  Created on: 29 Apr 2010
 *      Author: sdprice1
 */

#ifndef TS_PARSE_H_
#define TS_PARSE_H_

// All TS structs
#include "ts_structs.h"


/*=============================================================================================*/
// CONSTANTS
/*=============================================================================================*/


/*=============================================================================================*/
// STRUCTURES
/*=============================================================================================*/


/*=============================================================================================*/
// GLOBAL FUNCTIONS
/*=============================================================================================*/

// utility
void dump_buff(const uint8_t *payload, unsigned payload_len, unsigned display_len) ;

void buffer_free(struct TS_buffer **buff);
struct TS_buffer *buffer_new();
void buffer_clear(struct TS_buffer *bp);
uint8_t *buffer_data(struct TS_buffer **buff, const uint8_t *data, unsigned data_len);

// TS utils
void ts_null_packet(uint8_t *packet, unsigned packet_len) ;

// SI table decoding
int tsreader_register_section(struct TS_reader *tsreader,
		unsigned table_id, unsigned mask,
		Section_handler	handler, struct Section_decode_flags flags) ;

// TS parsing
int tsreader_setpos(struct TS_reader *tsreader, int skip_pkts, int origin, unsigned num_pkts) ;
void tsreader_start_framenum(struct TS_reader *tsreader, unsigned framenum) ;
struct TS_reader *tsreader_new(char *filename) ;
struct TS_reader *tsreader_new_nofile() ;
void tsreader_free(struct TS_reader *) ;
int ts_parse(struct TS_reader *tsreader) ;
void tsreader_stop(struct TS_reader *tsreader) ;

// "Live" parsing
int tsreader_data_start(struct TS_reader *tsreader) ;
int tsreader_data_add(struct TS_reader *tsreader, uint8_t *data, unsigned data_len) ;
int tsreader_data_end(struct TS_reader *tsreader) ;


#endif /* TS_PARSE_H_ */
