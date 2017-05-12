/*
 * ts_skip.c
 *
 *  Created on: 25 Jan 2011
 *      Author: sdprice1
 */

#include "ts_skip.h"

//========================================================================================================
// SKIP
//========================================================================================================

//---------------------------------------------------------------------------------------------------------
void add_cut(struct list_head *cut_list, unsigned start, unsigned end)
{
struct TS_cut   *cutitem;

	cutitem = malloc(sizeof(*cutitem));
    CLEAR_MEM(cutitem);
    list_add_tail(&cutitem->next, cut_list);

    cutitem->start = start ;
    cutitem->end = end ;
    cutitem->magic = TS_SKIP_MAGIC ;
}

//---------------------------------------------------------------------------------------------------------
void _print_cut_item(struct TS_cut *cutitem)
{

	fprintf(stderr, "item @ %p ", cutitem) ;
	if (cutitem == UNSET_CUT_LIST)
	{
		fprintf(stderr, "UNSET_CUT_LIST\n") ;
	}
	else if (cutitem == END_CUT_LIST)
	{
		fprintf(stderr, "END_CUT_LIST\n") ;
	}
	else
	{
		if (cutitem->magic != TS_SKIP_MAGIC) fprintf(stderr, "\n!!ERROR: Cut item invalid!!\n") ;
		fprintf(stderr, "start=%u, end=%u magic=0x%08x {list @ %p => next %p, prev %p}\n",
				cutitem,
				cutitem->start, cutitem->end, cutitem->magic,
				cutitem->next, cutitem->next.next, cutitem->next.prev) ;

	}
}


//---------------------------------------------------------------------------------------------------------
void _print_cut_list(char *fn, struct list_head *cut_list)
{
struct list_head  *item, *safe;
struct TS_cut   *cutitem;
unsigned count=0 ;

	fprintf(stderr, "\n\n--- print_cut_list(%s, cut_list @ %p) ---\n", fn, cut_list) ;
	list_for_each_safe(item,safe,cut_list)
	{
		cutitem = list_entry(item, struct TS_cut, next);

		fprintf(stderr, "[%2d] ", count) ; _print_cut_item(cutitem) ;

		if (++count >= 30)
		{
			fprintf(stderr, "!!ERROR: Too many cuts!!\n") ;
			exit(10) ;
		}
	};

	fprintf(stderr, "\n\n--- print_cut_list(cut_list @ %p) END ---\n", cut_list) ;
}


//---------------------------------------------------------------------------------------------------------
void free_cut_list(struct list_head *cut_list)
{
struct list_head  *item, *safe;
struct TS_cut   *cutitem;


//	_print_cut_list("free_cut_list", cut_list) ;

	list_for_each_safe(item,safe,cut_list)
	{
		cutitem = list_entry(item, struct TS_cut, next);
		list_del(&cutitem->next);
		free(cutitem);
	};

}


//---------------------------------------------------------------------------------------------------------
void remove_ext(char *src, char *dest)
{
char *p ;

	strncpy(dest, src, MAX_PATH_LEN) ;

	// replace rindex()
	p = dest + strlen(dest) - 1 ;
	while ((p != dest) && (*p != '.'))
	{
		--p ;
	}

	if (*p == '.') *p = 0 ;
}
