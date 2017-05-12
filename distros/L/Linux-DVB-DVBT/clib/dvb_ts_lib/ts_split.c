// VERSION = "1.000"
//
// Standard C code loaded outside XS space. Contains useful routines used by ts TS parsing functions

// VERSION 1.01

#include "ts_split.h"

//========================================================================================================
// SPLIT
//========================================================================================================

//---------------------------------------------------------------------------------------------------------
//
static void next_split_file(struct TS_cut_data *hook_data, unsigned pktnum)
{
	// close currently open
	if (hook_data->cut_file)
	{
		if (pktnum > hook_data->split_pkt)
		{
			close(hook_data->cut_file) ;
			hook_data->cut_file = 0 ;
		}
	}

	// open next
	if (!hook_data->cut_file)
	{
	char cutname[256] ;

		hook_data->split_pkt = pktnum ;

		sprintf(cutname, "%s-%04u.ts",
				hook_data->ofname, ++hook_data->split_count) ;

		if (hook_data->debug) printf("New split file %s at pkt %d\n", cutname, pktnum) ;


		hook_data->cut_file = open(cutname, O_CREAT | O_TRUNC | O_WRONLY | O_LARGEFILE, 0666);

		if (hook_data->debug >= 10) printf("-> save cut sequence: %s [%d]\n", cutname, hook_data->cut_file) ;
	}

}

//---------------------------------------------------------------------------------------------------------
// void (*tsparse_ts_hook)(unsigned long, unsigned, const uint8_t *, unsigned, unsigned, unsigned) ;
static void ts_split_hook(struct TS_pidinfo *pidinfo, uint8_t *packet, unsigned packet_len, void *user_data)
{
struct TS_cut_data *hook_data = (struct TS_cut_data *)user_data ;
//static unsigned prev_ok=1;
//unsigned ok = 1 ;

	if (hook_data->debug >= 10)
	{
		printf("-> TS PID 0x%x (%u) [%u] :: start=%d err=%d\n",
				pidinfo->pid, pidinfo->pid,
				pidinfo->pktnum,
				pidinfo->pes_start ? 1 : 0,
				pidinfo->pid_error ? 1 : 0) ;
	}

	// check cut
	if (hook_data->current_cut == UNSET_CUT_LIST)
	{
	struct list_head *item;

		list_for_each(item, hook_data->cut_list)
		{
			hook_data->current_cut = list_entry(item, struct TS_cut, next);
//			next_split_file(hook_data) ;
//			if (hook_data->debug) printf("New split file %04d at pkt %d\n", hook_data->split_count, pidinfo->pktnum) ;
			break;
		}
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
//				// save next band into new file
//				next_split_file(hook_data, pidinfo->pktnum) ;
			}

			// beyond end
			else
			{
			struct list_head *item;

				// ok, beyond this cut band - find next cut region
				do
				{
					list_next_each(hook_data->current_cut, END_CUT_LIST, item, hook_data->cut_list)
					{
						hook_data->current_cut = list_entry(item, struct TS_cut, next);
						break;
					}
				} while ( (hook_data->current_cut != END_CUT_LIST) && (pidinfo->pktnum > hook_data->current_cut->start) ) ;

//				prev_ok=1;

//				// save next band into new file
				next_split_file(hook_data, pidinfo->pktnum) ;
//				if (hook_data->debug) printf("New split file %04d at pkt %d\n", hook_data->split_count, pidinfo->pktnum) ;
			}
		}
	}

	if (hook_data->debug >= 10)
	{
		printf("-> TS PID 0x%x (%u) [%u]\n",
				pidinfo->pid, pidinfo->pid,
				pidinfo->pktnum) ;
	}

	// write if allowed to
	if (hook_data->cut_file)
	{
		write(hook_data->cut_file, packet, packet_len);
	}
}



//---------------------------------------------------------------------------------------------------------
int ts_split(char *filename, char *ofilename, struct list_head *cuts_array, unsigned debug)
{
int file;
struct TS_cut_data hook_data ;
struct TS_reader *tsreader ;

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
	tsreader->ts_hook = ts_split_hook ;
	tsreader->user_data = &hook_data ;
	tsreader->debug = debug ;

	remove_ext(filename, hook_data.fname) ;
	remove_ext(ofilename, hook_data.ofname) ;

	// start first file
	next_split_file(&hook_data, 0) ;

	// parse data
    ts_parse(tsreader) ;

    if (hook_data.cut_file)
    	close(hook_data.cut_file) ;

	tsreader_free(tsreader) ;
	free_cut_list(hook_data.cut_list) ;

	return(dvb_error_code) ;
}


