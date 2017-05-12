/*
 * ts_skip.h
 *
 *  Created on: 25 Jan 2011
 *      Author: sdprice1
 */

#ifndef TS_SKIP_H_
#define TS_SKIP_H_

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <ctype.h>
#include <fcntl.h>
#include <inttypes.h>

#include "list.h"

#include "ts_parse.h"

//========================================================================================================
// SKIP DATA
//========================================================================================================

/**
 * list_for_each	-	iterate over a list
 * @pos:	the &struct list_head to use as a loop counter.
 * @head:	the head for your list.
 */
#define list_next_each(current, END, pos, head) \
	for (pos = (&current->next)->next, current=END; pos != (head); pos = pos->next)

#define TS_SKIP_MAGIC 0x11332255

// Linked list of cut regions
struct TS_cut {
    struct list_head    next;
	unsigned 			start ;
	unsigned 			end ;
	unsigned			magic ;
};
#define UNSET_CUT_LIST	(struct TS_cut *)-1
#define END_CUT_LIST	(struct TS_cut *)-2


// data passed into hooks
struct TS_cut_data {
	// general
	struct TS_settings	*settings ;

	int ofile ;
	int debug ;

	int split_count ;
	unsigned split_pkt ;

	char fname[256] ;
	char ofname[256] ;
	int cut_file ;

	// cut list
    struct list_head   	*cut_list;

    // current cut entry
    struct TS_cut		*current_cut ;

    // pointer to the reader
    struct TS_reader *tsreader ;
} ;


//---------------------------------------------------------------------------------------------------------
void add_cut(struct list_head *cut_list, unsigned start, unsigned end) ;
void _print_cut_list(char *fn, struct list_head *cut_list) ;
void free_cut_list(struct list_head *cut_list) ;
void remove_ext(char *src, char *dest) ;


#endif /* TS_SKIP_H_ */
