
 # /*---------------------------------------------------------------------------------------------------*/
 # /* Remove the demux filter (specified via the file handle) */
int
dvb_del_demux (DVB *dvb, int fd)

	CODE:
		if (fd > 0)
		{
			// delete demux filter
			RETVAL = dvb_demux_remove_filter(dvb, fd) ;
		}
		else
		{
			RETVAL = -1 ;
		}

	OUTPUT:
       RETVAL



 # /*---------------------------------------------------------------------------------------------------*/
 # /* Set the DEMUX to add a new stream specified by it's pid. Returns file handle or negative if fail */
int
dvb_add_demux (DVB *dvb, unsigned int pid)

	CODE:
		// set demux
		RETVAL = dvb_demux_add_filter(dvb, pid) ;

	OUTPUT:
       RETVAL



 # /*---------------------------------------------------------------------------------------------------*/
 # /* Stream the raw TS data to a file (assumes frontend & demux are already set up  */
int
dvb_record (DVB *dvb, char *filename, int sec)
	CODE:
		if (sec <= 0)
	          croak ("Linux::DVB::DVBT::dvb_record requires a valid record length in seconds");


		// open dvr first
		RETVAL = dvb_dvr_open(dvb) ;

        // save stream
		if (RETVAL == 0)
		{
			RETVAL = write_stream(dvb, filename, sec) ;

			// close dvr
			dvb_dvr_release(dvb) ;
		}


	OUTPUT:
      RETVAL


 # /*---------------------------------------------------------------------------------------------------*/
 # /* Record a multiplex */
 #
 #	struct multiplex_file_struct {
 #		int								file;
 #		time_t 							start;
 #		time_t 							end;
 #	    unsigned int                    done;
 #	    uint64_t                        errors;
 #	    uint64_t                        pkts;
 #	} ;
 #
 #	struct multiplex_pid_struct {
 #	    struct multiplex_file_struct	 *file_info ;
 #	    unsigned int                     pid;
 #	} ;
 #

int
dvb_record_demux (DVB *dvb, AV *multiplex_aref, HV *options_href=NULL)

  INIT:
	unsigned 		num_entries ;
	int				i ;
	SV				**item ;
	SV 				**val;
	HV				*href ;
	HV				*errors_href ;
	HV				*overflows_href ;
	HV				*pkts_href ;
	HV				*timeslip_href ;
	char			*str ;
    char 			key[256] ;
    char 			string[256] ;

    AV 				*pid_array;
	unsigned 		num_pids ;
	int				j ;
	SV				**piditem ;

	struct multiplex_file_struct	*file_info ;
	struct multiplex_pid_struct		*pid_list ;
	unsigned						pid_list_length ;
	unsigned						pid_index;

	time_t 		now, start, end;
	int			file ;
	int rc ;

	unsigned 	use_demux2 = 0 ;
	unsigned	pnr = 0 ;
	int			event_id = -1 ;
 	unsigned	timeslip_start = 0 ;
 	unsigned	timeslip_end = 0 ;
 	unsigned	max_timeslip = 0 ;

  CODE:

	if (options_href)
	{
		HVF_IV(options_href, use_demux2, use_demux2) ;
	}


    // av_len returns -1 for empty. Returns maximum index number otherwise
	//num_entries = av_len( (AV *)SvRV(multiplex_aref) ) + 1 ;
	num_entries = av_len( multiplex_aref ) + 1 ;
	if (num_entries <= 0)
	{
	 	croak("Linux::DVB::DVBT::dvb_record_demux requires a list of multiplex hashes") ;
	}

	// count number of entries (and check structure)
	pid_list_length = 0 ;

	for (i=0; i <= num_entries ; i++)
	{
		if ((item = av_fetch(multiplex_aref, i, 0)) && SvOK (*item))
		{
  			if ( SvTYPE(SvRV(*item)) != SVt_PVHV )
  			{
 			 	croak("Linux::DVB::DVBT::dvb_record_demux requires a list of multiplex hashes") ;
 			}
 			href = (HV *)SvRV(*item) ;

 			// get pids
 			val = HVF(href, pids) ;
 			pid_array = (AV *) SvRV (*val);
 			num_pids = av_len(pid_array) + 1 ;

			pid_list_length += num_pids ;
		}
	}

	// create arrays
	now = time(NULL);
 	pid_list = (struct multiplex_pid_struct *)safemalloc( sizeof(struct multiplex_pid_struct) * pid_list_length);
 	file_info = (struct multiplex_file_struct *)safemalloc( sizeof(struct multiplex_file_struct) * num_entries );

	for (i=0, pid_index=0; i <= num_entries ; i++)
	{
		if ((item = av_fetch(multiplex_aref, i, 0)) && SvOK (*item))
		{
 			href = (HV *)SvRV(*item) ;

 			val = HVF(href, destfile) ;
 			str = (char *)SvPV(*val, SvLEN(*val)) ;
			file = open(str, O_WRONLY | O_TRUNC | O_CREAT | O_LARGEFILE, 0666);
		    if (-1 == file) {

				fprintf(stderr,"open %s: %s\n",str,strerror(errno));
				croak("Linux::DVB::DVBT::dvb_record_demux failed to write to file") ;
		    }

			// create file info struct
		 	file_info[i].file = file ;

 			val = HVF(href, offset) ;
		 	file_info[i].start = now + SvIV (*val) ;

 			val = HVF(href, duration) ;
		 	file_info[i].duration = SvIV (*val) ;
		 	file_info[i].end = file_info[i].start + SvIV (*val) ;


		 	pnr = 0 ;
		 	event_id = -1 ;
		 	timeslip_start = 0 ;
		 	timeslip_end = 0 ;
		 	max_timeslip = 0 ;

		 	HVF_IV(href, pnr, pnr) ;
		 	HVF_IV(href, event_id, event_id) ;
		 	HVF_IV(href, timeslip_start, timeslip_start) ;
		 	HVF_IV(href, timeslip_end, timeslip_end) ;
		 	HVF_IV(href, max_timeslip, max_timeslip) ;

 			// get pids
 			val = HVF(href, pids) ;
 			pid_array = (AV *) SvRV (*val);
 			num_pids = av_len(pid_array) + 1 ;

 			for (j=0; j < num_pids ; j++, ++pid_index)
 			{
 				if ((piditem = av_fetch(pid_array, j, 0)) && SvOK (*piditem))
 				{
 					pid_list[pid_index].file_info = &file_info[i] ;
 					pid_list[pid_index].pid  = SvIV (*piditem) ;
 					pid_list[pid_index].started = 0 ;
 					pid_list[pid_index].done = 0 ;

 					// Statistics
 					pid_list[pid_index].errors = 0 ;
 					pid_list[pid_index].overflows = 0 ;
 					pid_list[pid_index].pkts = 0 ;
 					pid_list[pid_index].timeslip_start_secs = 0 ;
 					pid_list[pid_index].timeslip_end_secs = 0 ;

 					// Timeslipping
 					pid_list[pid_index].pnr = pnr ;
 					pid_list[pid_index].event_id = event_id ;
 					pid_list[pid_index].running_status = RUNNING_STATUS_UNDEF ;
 					pid_list[pid_index].max_timeslip = max_timeslip ;

 					// Flags - set to timeslip start and/or end of prog
 					pid_list[pid_index].timeslip_start = timeslip_start ;
 					pid_list[pid_index].timeslip_end = timeslip_end ;


 					// internal
 					pid_list[pid_index].running_event_id = EVENT_ID_UNDEF ;
 					pid_list[pid_index].pending_event_id = EVENT_ID_UNDEF ;
 					pid_list[pid_index].got_eit = 0 ;
 					pid_list[pid_index].ref = (void *)item ;
 				}
 			}

		}
	}

 	// open dvr first
 	RETVAL = dvb_dvr_open(dvb) ;

     // save stream
 	if (RETVAL == 0)
 	{
		RETVAL = write_stream_demux(dvb, pid_list, pid_index) ;

 		// close dvr
 		dvb_dvr_release(dvb) ;
 	}

 	// Copy error/packet counts
	for (i=0; i < pid_index; ++i)
	{
		item = (SV **)pid_list[i].ref ;
		href = (HV *)SvRV(*item) ;

		sprintf(key, "%d", pid_list[i].pid) ;

		// set errors (save 64 bit value as a string)
		val = HVF(href, errors) ;
		errors_href = (HV *) SvRV (*val);
		sprintf(string, "%"PRIu64, pid_list[i].errors) ;
		hv_store(errors_href, key, strlen(key), newSVpv(string, 0), 0);

		// set overflows (save 64 bit value as a string)
		val = HVF(href, overflows) ;
		overflows_href = (HV *) SvRV (*val);
		sprintf(string, "%"PRIu64, pid_list[i].overflows) ;
		hv_store(overflows_href, key, strlen(key), newSVpv(string, 0), 0);

		// set packets (save 64 bit value as a string)
		val = HVF(href, pkts) ;
		pkts_href = (HV *) SvRV (*val);
		sprintf(string, "%"PRIu64, pid_list[i].pkts) ;
		hv_store(pkts_href, key, strlen(key), newSVpv(string, 0), 0);

		// set timeslip statistics
		val = HVF(href, timeslip_start_secs) ;
		timeslip_href = (HV *) SvRV (*val);
		sprintf(string, "%u", pid_list[i].timeslip_start_secs) ;
		hv_store(timeslip_href, key, strlen(key), newSVpv(string, 0), 0);
		val = HVF(href, timeslip_end_secs) ;
		timeslip_href = (HV *) SvRV (*val);
		sprintf(string, "%u", pid_list[i].timeslip_end_secs) ;
		hv_store(timeslip_href, key, strlen(key), newSVpv(string, 0), 0);


	}

 	// free up
 	for (i=0; i < num_entries ; i++)
 	{
 		if (file_info[i].file > 0)
 		{
 			close(file_info[i].file) ;
 		}
 	}
 	safefree(pid_list) ;
 	safefree(file_info) ;


  OUTPUT:
    RETVAL


