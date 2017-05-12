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
void _print_cut_list(char *fn, struct list_head *cut_list)
{
struct list_head  *item, *safe;
struct TS_cut   *cutitem;
unsigned count=0 ;

printf("\n\n--- print_cut_list(%s, cut_list @ %p) ---\n", fn, cut_list) ;
list_for_each_safe(item,safe,cut_list)
{
	cutitem = list_entry(item, struct TS_cut, next);
	printf(" + item @ %p start=%u, end=%u magic=0x%08x {list @ %p => next %p, prev %p}\n",
			cutitem,
			cutitem->start, cutitem->end, cutitem->magic,
			cutitem->next, cutitem->next.next, cutitem->next.prev) ;

	if (cutitem->magic != TS_SKIP_MAGIC) abort() ;
	if (++count >= 10) abort() ;
};

	printf("\n\n--- print_cut_list(cut_list @ %p) END ---\n", cut_list) ;
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

	strcpy(dest, src) ;

	// replace rindex()
	p = dest + strlen(dest) - 1 ;
	while ((p != dest) && (*p != '.'))
	{
		--p ;
	}

	if (*p == '.') *p = 0 ;
}
