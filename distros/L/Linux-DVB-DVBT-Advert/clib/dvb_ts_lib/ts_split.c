// VERSION = "1.000"
//
// Standard C code loaded outside XS space. Contains useful routines used by ts TS parsing functions

// VERSION 1.01

#include "ts_split.h"

//========================================================================================================
// SPLIT
//========================================================================================================

//---------------------------------------------------------------------------------------------------------
static void _print_hook_data(struct TS_cut_data *data)
{
	fprintf(stderr, "Hook data @ %p\n", data) ;
	fprintf(stderr, " + magic : 0x%08x\n", data->magic) ;
	fprintf(stderr, " + settings : %p\n", data->settings) ;
	fprintf(stderr, " + ofile : %d\n", data->ofile) ;
	fprintf(stderr, " + debug : %d\n", data->debug) ;
	fprintf(stderr, " + split_count : %d\n", data->split_count) ;
	fprintf(stderr, " + fname : %s\n", data->fname) ;
	fprintf(stderr, " + ofname : %s\n", data->ofname) ;
	fprintf(stderr, " + cut_file : %d\n", data->cut_file) ;
	fprintf(stderr, " + cut_list : %p\n", data->cut_list) ;
	fprintf(stderr, " + current_cut : %p\n", data->current_cut) ;
	fprintf(stderr, " + tsreader : %p\n", data->tsreader) ;
	fprintf(stderr, " + end : 0x%08x\n", data->magic_end) ;
}

//---------------------------------------------------------------------------------------------------------
//
static void next_split_file(struct TS_cut_data *hook_data, unsigned pktnum)
{
	if (hook_data->debug) fprintf(stderr, " + + next_split_file(%u) - start\n", pktnum) ;

	// close currently open
	if (hook_data->cut_file)
	{
		if (pktnum > hook_data->split_pkt)
		{
			close(hook_data->cut_file) ;
			hook_data->cut_file = 0 ;
			if (hook_data->debug) fprintf(stderr, " + + + closed existing file\n") ;
		}
	}

	// open next
	if (!hook_data->cut_file)
	{
	char cutname[256] ;

		hook_data->split_pkt = pktnum ;

		sprintf(cutname, "%s-%04u.ts",
				hook_data->ofname, ++hook_data->split_count) ;

		if (hook_data->debug) fprintf(stderr, " + + New split file %s at pkt %d\n", cutname, pktnum) ;


		hook_data->cut_file = open(cutname, O_CREAT | O_TRUNC | O_WRONLY | O_LARGEFILE, 0666);

		if (hook_data->debug >= 10) fprintf(stderr, " + + -> save cut sequence: %s [fd %d]\n", cutname, hook_data->cut_file) ;
	}

	if (hook_data->debug) fprintf(stderr, " + + next_split_file() - end\n") ;
}

//---------------------------------------------------------------------------------------------------------
static void ts_split_hook(struct TS_pidinfo *pidinfo, uint8_t *packet, unsigned packet_len, void *user_data)
{
struct TS_cut_data *hook_data = (struct TS_cut_data *)user_data ;

	if (hook_data->debug) fprintf(stderr, "ts_split_hook() - start  [hook_data @ %p]\n", hook_data) ;

	if (!hook_data)
	{
		fprintf(stderr, "!!ERROR: Null data pointer!!\n") ;
	}
	if (hook_data->magic != TS_CUTDATA_MAGIC)
	{
		fprintf(stderr, "!!ERROR: Corrupted data pointer!!\n") ;
	}

	if (hook_data->debug >= 10)
	{
	    _print_hook_data(hook_data) ;

		fprintf(stderr, "-> TS PID 0x%x (%u) [pkt %u] :: start=%d err=%d\n",
				pidinfo->pid, pidinfo->pid,
				pidinfo->pktnum,
				pidinfo->pes_start ? 1 : 0,
				pidinfo->pid_error ? 1 : 0) ;

		fprintf(stderr, " + initial : current cut = "); _print_cut_item(hook_data->current_cut) ;

		if (pidinfo->pktnum >= 100)
		{
			fprintf(stderr, " + turning off debug....\n");
			hook_data->debug = 0 ;
			hook_data->tsreader->debug = 0 ;
		}
	}

	// check cut
	if (hook_data->current_cut == UNSET_CUT_LIST)
	{
	struct list_head *item;

		if (hook_data->debug >= 2) fprintf(stderr, " + find first cut entry...\n");
		list_for_each(item, hook_data->cut_list)
		{
			hook_data->current_cut = list_entry(item, struct TS_cut, next);
			break;
		}
	}
	if (hook_data->debug >= 2)
	{
		fprintf(stderr, " + start: current_cut [%p] = ", hook_data->current_cut) ;
		_print_cut_item(hook_data->current_cut) ;
	}

	if (hook_data->current_cut != END_CUT_LIST)
	{
		// check current
		if (pidinfo->pktnum < hook_data->current_cut->start)
		{
			// still before start of next band
		}
		else
		{
			// Now >= start

			// New file at start of region
			if ( pidinfo->pktnum == hook_data->current_cut->start )
			{
				// save next band into new file
				next_split_file(hook_data, pidinfo->pktnum) ;
			}

			// writing : start -> end
			else if (pidinfo->pktnum < hook_data->current_cut->end)
			{
			}

			// writing : end
			else if (pidinfo->pktnum == hook_data->current_cut->end)
			{
			}

			// beyond end
			else
			{
			struct list_head *item;

				if (hook_data->debug) fprintf(stderr, " + past end of this cut region, move to next...\n") ;

				// ok, beyond this cut band - find next cut region
				do
				{
					list_next_each(hook_data->current_cut, END_CUT_LIST, item, hook_data->cut_list)
					{
						hook_data->current_cut = list_entry(item, struct TS_cut, next);
						break;
					}

				} while ( (hook_data->current_cut != END_CUT_LIST) && (pidinfo->pktnum > hook_data->current_cut->start) ) ;

				if (hook_data->debug >= 2)
				{
					fprintf(stderr, " + next: current_cut %p = ", hook_data->current_cut) ;
					_print_cut_item(hook_data->current_cut) ;
				}

				// save next band into new file
				next_split_file(hook_data, pidinfo->pktnum) ;
				if (hook_data->debug) fprintf(stderr, " + New split file %04d at pkt %d\n", hook_data->split_count, pidinfo->pktnum) ;
			}
		}
	}

	// write if allowed to
	if (hook_data->cut_file)
	{
		if (hook_data->debug >= 10)
		{
			fprintf(stderr, " + Writing TS PID 0x%x [pkt %u]...\n",
					pidinfo->pid,
					pidinfo->pktnum) ;
		}

		write(hook_data->cut_file, packet, packet_len);
	}

	if (hook_data->debug) fprintf(stderr, "ts_split_hook() - end\n") ;
}



//---------------------------------------------------------------------------------------------------------
int ts_split(char *filename, char *ofilename, struct list_head *cuts_array, unsigned debug)
{
int file;
struct TS_cut_data hook_data ;
struct TS_reader *tsreader ;

	if (debug >= 2) fprintf(stderr, "ts_split() - start [hook_data @ %p]\n", &hook_data) ;

	hook_data.magic = TS_CUTDATA_MAGIC ;
	hook_data.magic_end = 0xdeaddead ;
	hook_data.cut_list = cuts_array ;

	hook_data.current_cut = UNSET_CUT_LIST ;
	hook_data.debug = debug ;
	hook_data.ofile = 0 ;
	hook_data.split_count = 0 ;
	hook_data.cut_file = 0 ;
    hook_data.ofile = 0 ;

	tsreader = tsreader_new(filename) ;
    if (!tsreader)
    {
    	return(dvb_error_code);
    }
    hook_data.tsreader = tsreader ;
    if (debug >= 5) _print_hook_data(&hook_data) ;
	remove_ext(filename, hook_data.fname) ;
	remove_ext(ofilename, hook_data.ofname) ;
    if (debug >= 5) _print_hook_data(&hook_data) ;

	tsreader->ts_hook = ts_split_hook ;
	tsreader->user_data = &hook_data ;
	tsreader->debug = debug ;


	// start first file
	next_split_file(&hook_data, 0) ;

	if (debug >= 5) fprintf(stderr, " + parse file...\n") ;

	// parse data
    ts_parse(tsreader) ;

    if (hook_data.cut_file)
    	close(hook_data.cut_file) ;

	if (debug >= 5) fprintf(stderr, " + free tsreader...\n") ;
	tsreader_free(tsreader) ;

	if (debug >= 5) fprintf(stderr, " + free cut list...\n") ;
	free_cut_list(hook_data.cut_list) ;

	if (debug >= 2) fprintf(stderr, "ts_split() - start\n") ;

	return(dvb_error_code) ;
}


