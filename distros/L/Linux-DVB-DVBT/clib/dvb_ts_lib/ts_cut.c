// VERSION = "1.000"
//
// Standard C code loaded outside XS space. Contains useful routines used by ts TS parsing functions

// VERSION 1.01

#include "ts_split.h"

//========================================================================================================
// CUT
//========================================================================================================


//---------------------------------------------------------------------------------------------------------
// void (*tsparse_ts_hook)(unsigned long, unsigned, const uint8_t *, unsigned, unsigned, unsigned) ;
void ts_cut_hook(struct TS_pidinfo *pidinfo, uint8_t *packet, unsigned packet_len, void *user_data)
{
struct TS_cut_data *hook_data = (struct TS_cut_data *)user_data ;
static unsigned prev_ok=1;

	if (hook_data->ofile)
	{
	unsigned ok = 1 ;

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
				break;
			}
		}

		if (hook_data->current_cut != END_CUT_LIST)
		{
			// check current
			if (pidinfo->pktnum < hook_data->current_cut->start)
			{
				// ok, not in this cut band
			}
			else
			{

				if (pidinfo->pktnum <= hook_data->current_cut->end)
				{
					// cut, in this cut band
					ok = 0 ;

					if (prev_ok)
					{
						if (hook_data->debug) printf("Skipping %u .. %u\n", hook_data->current_cut->start, hook_data->current_cut->end) ;
					}

					prev_ok = ok ;

				}
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

					prev_ok=1;

				}
			}
		}

		if (hook_data->debug >= 10)
		{
			printf("-> TS PID 0x%x (%u) [%u] :: ok=%d\n",
					pidinfo->pid, pidinfo->pid,
					pidinfo->pktnum,
					ok) ;
		}


		// write if allowed to
		if (ok)
		{
			// no error
			write(hook_data->ofile, packet, packet_len);
		}
	}
}



//---------------------------------------------------------------------------------------------------------
int ts_cut(char *filename, char *ofilename, struct list_head *cuts_array, unsigned debug)
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

    hook_data.ofile = open(ofilename, O_CREAT | O_TRUNC | O_WRONLY | O_LARGEFILE, 0666);
    if (-1 == hook_data.ofile) {
		RETURN_DVB_ERROR(ERR_FILE);
    }

	tsreader = tsreader_new(filename) ;
    if (!tsreader)
    {
    	return(dvb_error_code);
    }
	tsreader->ts_hook = ts_cut_hook ;
	tsreader->user_data = &hook_data ;
	tsreader->debug = debug ;

	remove_ext(filename, hook_data.fname) ;
	remove_ext(ofilename, hook_data.ofname) ;

	// parse data
    ts_parse(tsreader) ;

	close(hook_data.ofile) ;

	tsreader_free(tsreader) ;
	free_cut_list(hook_data.cut_list) ;

	return(dvb_error_code) ;
}


