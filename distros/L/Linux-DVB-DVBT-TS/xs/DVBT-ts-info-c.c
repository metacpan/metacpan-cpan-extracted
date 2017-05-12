// VERSION = "1.000"
//
// Standard C code loaded outside XS space. Contains useful routines used by ts TS infofunctions

//========================================================================================================
// INFO
//========================================================================================================

//---------------------------------------------------------------------------------------------------------
// Create tsreader then get video duration. Returns info in tsreader struct that must be free-d externally
//
// TODO: Decode PAT etc
//
struct TS_reader *tsinfo(char *filename, struct TS_settings *settings)
{
int file;
struct TS_reader *tsreader ;
unsigned pkt_num ;

	tsreader = tsreader_new(filename) ;
    if (!tsreader)
    {
		//fprintf(stderr,"ERROR %s: %s\n",filename,dvb_error_str(dvb_error_code));
    	return(NULL);
    }

	// only support the following standard settings - NO CALLBACKS (so no need for hook data)!
	tsreader->debug = settings->debug ;

	pkt_num = 1300 ;
	if (tsreader->tsstate->total_pkts <= 2*pkt_num)
	{
		// Short file - parse the lot
		tsreader_setpos(tsreader, 0, SEEK_SET, tsreader->tsstate->total_pkts) ;
		ts_parse(tsreader) ;
	}
	else
	{
		// parse data - start
		tsreader_setpos(tsreader, 0, SEEK_SET, 1300) ;
		ts_parse(tsreader) ;

		// parse data - end
		tsreader_setpos(tsreader, -1300, SEEK_END, 1300) ;
		ts_parse(tsreader) ;
	}

    // update the timing
    tsreader_set_timing(tsreader) ;

    return tsreader ;
}


