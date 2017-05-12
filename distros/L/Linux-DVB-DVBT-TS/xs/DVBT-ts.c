 # VERSION = "1.000"


 # /*---------------------------------------------------------------------------------------------------*/
 # /* Repair TS file */

int
dvb_ts_repair(char *filename, char *ofilename, HV *settings_href=NULL)
	INIT:
		struct TS_settings settings;
		SV **val;

	CODE:
		dvb_error_clear() ;
		clear_settings(&settings) ;

		if (settings_href)
		{
			HVF_IV(settings_href, debug, settings.debug) ;
			HVF_IV(settings_href, null_error_packets, settings.null_error_packets) ;
			HVF_SVV(settings_href, error_callback, settings.error_callback) ;
			HVF_SVV(settings_href, user_data, settings.perl_data) ;
		}

		// repair
		RETVAL = tsrepair(filename, ofilename, &settings) ;

	OUTPUT:
      RETVAL

# /*---------------------------------------------------------------------------------------------------*/
# /* Parse TS file */

int
dvb_ts_parse(char *filename, HV *settings_href)
    INIT:
        struct TS_settings settings;
        SV **val;
        int ival ;

	CODE:
		dvb_error_clear() ;
		clear_settings(&settings) ;

		if (settings_href)
		{
			HVF_IV(settings_href, debug, settings.debug) ;

			HVF_IV(settings_href, num_pkts, settings.num_pkts) ;
			HVF_IV(settings_href, skip_pkts, settings.skip_pkts) ;
			HVF_IV(settings_href, origin, settings.origin) ;

			HVF_SVV(settings_href, pid_callback, settings.pid_callback) ;
			HVF_SVV(settings_href, error_callback, settings.error_callback) ;
			HVF_SVV(settings_href, payload_callback, settings.payload_callback) ;
			HVF_SVV(settings_href, ts_callback, settings.ts_callback) ;
			HVF_SVV(settings_href, pes_callback, settings.pes_callback) ;
			HVF_SVV(settings_href, pes_data_callback, settings.pes_data_callback) ;
			HVF_SVV(settings_href, progress_callback, settings.progress_callback) ;
			HVF_SVV(settings_href, mpeg2_callback, settings.mpeg2_callback) ;
			HVF_SVV(settings_href, mpeg2_rgb_callback, settings.mpeg2_rgb_callback) ;
			HVF_SVV(settings_href, audio_callback, settings.audio_callback) ;

			HVF_SVV(settings_href, user_data, settings.perl_data) ;
		}


		// parse
		RETVAL = tsparse(filename, &settings) ;

	OUTPUT:
     RETVAL



# /*---------------------------------------------------------------------------------------------------*/
# /* Parse TS file - start */

TSReader *
dvb_ts_parse_begin(char *filename, HV *settings_href)
    INIT:
        struct TS_settings settings;
        SV **val;
        int ival ;

	CODE:
		dvb_error_clear() ;
		clear_settings(&settings) ;

		if (settings_href)
		{
			HVF_IV(settings_href, debug, settings.debug) ;

			HVF_IV(settings_href, num_pkts, settings.num_pkts) ;
			HVF_IV(settings_href, skip_pkts, settings.skip_pkts) ;
			HVF_IV(settings_href, origin, settings.origin) ;

			HVF_SVV(settings_href, pid_callback, settings.pid_callback) ;
			HVF_SVV(settings_href, error_callback, settings.error_callback) ;
			HVF_SVV(settings_href, payload_callback, settings.payload_callback) ;
			HVF_SVV(settings_href, ts_callback, settings.ts_callback) ;
			HVF_SVV(settings_href, pes_callback, settings.pes_callback) ;
			HVF_SVV(settings_href, pes_data_callback, settings.pes_data_callback) ;
			HVF_SVV(settings_href, progress_callback, settings.progress_callback) ;
			HVF_SVV(settings_href, mpeg2_callback, settings.mpeg2_callback) ;
			HVF_SVV(settings_href, mpeg2_rgb_callback, settings.mpeg2_rgb_callback) ;
			HVF_SVV(settings_href, audio_callback, settings.audio_callback) ;

			HVF_SVV(settings_href, user_data, settings.perl_data) ;
		}

		// parse
		RETVAL = tsparse_start(filename, &settings) ;

	OUTPUT:
		 RETVAL

# /*---------------------------------------------------------------------------------------------------*/
# /* Parse TS file - run */

int
dvb_ts_parse_run(TSReader *tsreader)

	CODE:
		dvb_error_clear() ;

		// check
		VALID_READER(tsreader) ;

		// run
		if (!RETVAL)
			RETVAL = tsparse_run(tsreader) ;

	OUTPUT:
		 RETVAL


# /*---------------------------------------------------------------------------------------------------*/
# /* Parse TS file - end */

int
dvb_ts_parse_end(TSReader *tsreader)

	CODE:
		dvb_error_clear() ;

		// check
		VALID_READER(tsreader) ;

		// finish
		if (!RETVAL)
			RETVAL = tsparse_end(tsreader) ;

	OUTPUT:
		 RETVAL


# /*---------------------------------------------------------------------------------------------------*/
# /* Parse TS file - stop parsing */

int
dvb_ts_parse_stop(TSReader *tsreader)

	CODE:
		dvb_error_clear() ;

		// check
		VALID_READER(tsreader) ;

		// stop now
		if (!RETVAL)
			tsreader_stop(tsreader) ;

	OUTPUT:
		 RETVAL


# /*---------------------------------------------------------------------------------------------------*/
# /* Set file pos */

int
dvb_ts_setpos(TSReader *tsreader, int skip_pkts, int origin, unsigned num_pkts)

	CODE:
		dvb_error_clear() ;

		// check
		VALID_READER(tsreader) ;

		// set position
		if (!RETVAL)
			RETVAL = tsreader_setpos(tsreader, skip_pkts, origin, num_pkts) ;

	OUTPUT:
		 RETVAL


# /*---------------------------------------------------------------------------------------------------*/
# /* Read bits of the file to get quick overview */

SV *
dvb_ts_info(char *filename, HV *settings_href)
    INIT:
		TSReader *tsreader ;
        struct TS_settings settings;
        SV **val;
        HV *info_href = (HV *)sv_2mortal((SV *)newHV());
        HV *pid_href = (HV *)sv_2mortal((SV *)newHV());
		struct TS_pid   *piditem;
		struct list_head *item;
		char key[256] ;

	CODE:
		dvb_error_clear() ;

		/* Create Perl data */
		HVS(info_href, pids, newRV((SV *)pid_href)) ;

		clear_settings(&settings) ;
		if (settings_href)
		{
			HVF_IV(settings_href, debug, settings.debug) ;
		}

		// get info
		tsreader = tsinfo(filename, &settings) ;

		if (!tsreader)
		{
			char *errstr = dvb_error_str(dvb_error_code) ;
			HVS_STR(info_href, error, errstr) ;
		}
		else
		{
			// save info in a HASH
			HVS_I(info_href, tsreader->tsstate, total_pkts) ;
			_store_time(info_href, "duration", (tsreader->tsstate->end_ts - tsreader->tsstate->start_ts) ) ;
			_store_ts(info_href, "start_ts", tsreader->tsstate->start_ts) ;
			_store_ts(info_href, "end_ts", tsreader->tsstate->end_ts) ;

			list_for_each(item, &tsreader->tsstate->pid_list)
			{
			HV *h ;

				piditem = list_entry(item, struct TS_pid, next);

				/* Convert structure fields into hash elements */
				h = (HV *)sv_2mortal((SV *)newHV());

				_add_pidinfo(h, &piditem->pidinfo) ;
				_add_pesinfo(h, &piditem->pesinfo) ;

				sprintf(key, "%d", piditem->pidinfo.pid) ;
				hv_store(pid_href, key, strlen(key),  newRV((SV *)h), 0) ;
			}


			// end
			tsparse_end(tsreader) ;
		}

		RETVAL = newRV((SV *)info_href);

	OUTPUT:
		 RETVAL

# /*---------------------------------------------------------------------------------------------------*/
# /* Return error string */

SV *
dvb_ts_error_str()
	INIT:
		SV *str;
		char *error_str ;

	CODE:
		error_str = dvb_error_str(dvb_error_code) ;
		RETVAL = newSVpv(error_str, 0) ;

	OUTPUT:
     	 RETVAL

# /*---------------------------------------------------------------------------------------------------*/
# /* Return error code : 0 = no error */

int
dvb_ts_error()

	CODE:
		RETVAL = dvb_error_code ;

	OUTPUT:
     	 RETVAL

