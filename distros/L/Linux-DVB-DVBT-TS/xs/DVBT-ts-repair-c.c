// VERSION = "1.000"
//
// Standard C code loaded outside XS space. Contains useful routines used by ts TS parsing functions

//========================================================================================================
// REPAIR
//========================================================================================================

//---------------------------------------------------------------------------------------------------------
static void repair_ts_hook(struct TS_pidinfo *pidinfo, uint8_t *packet, unsigned packet_len, void *user_data)
{
struct TS_parse_data *hook_data = (struct TS_parse_data *)user_data ;

	if (hook_data->ofile)
	{
		if (pidinfo->pid_error)
		{
			if (hook_data->null_error_packets)
			{
				// convert packet to null
				ts_null_packet(packet, packet_len) ;

				// write it
				write(hook_data->ofile, packet, packet_len);
			}
		}
		else
		{
			// no error
			write(hook_data->ofile, packet, packet_len);
		}
	}
}

//---------------------------------------------------------------------------------------------------------
int tsrepair(char *filename, char *ofilename, struct TS_settings *settings)
{
int file;
struct TS_parse_data hook_data ;
struct TS_reader *tsreader ;

	hook_data.settings = settings ;
	hook_data.null_error_packets = settings->null_error_packets ;

    hook_data.ofile = open(ofilename, O_CREAT | O_TRUNC | O_WRONLY | O_LARGEFILE, 0666);
    if (-1 == hook_data.ofile) {
		//fprintf(stderr,"open %s: %s\n",ofilename,strerror(errno));
		RETURN_DVB_ERROR(ERR_FILE);
    }

	tsreader = tsreader_new(filename) ;
    if (!tsreader)
    {
		//fprintf(stderr,"ERROR %s: %s\n",filename,dvb_error_str(dvb_error_code));
    	return(dvb_error_code);
    }

	tsreader->ts_hook = repair_ts_hook ;
	tsreader->user_data = &hook_data ;

	// only support the following standard settings
	tsreader->debug = settings->debug ;
	tsreader->error_hook = parse_error_hook ;

	// parse data
    ts_parse(tsreader) ;

	close(hook_data.ofile) ;

	tsreader_free(tsreader) ;
	return(dvb_error_code) ;
}

