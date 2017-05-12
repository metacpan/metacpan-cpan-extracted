 # VERSION = "1.000"

 # /*---------------------------------------------------------------------------------------------------*/
 # /* Cut TS file removing cut regions (adverts) */

int
dvb_ts_cut(char *filename, char *ofilename, SV *cuts_aref, HV *settings_href=NULL)
	INIT:
		struct TS_settings settings;
		SV **val;
		struct list_head   	cut_list;
		unsigned 		num_entries ;
		unsigned 		i ;
		SV				**item ;
		HV				*href ;
		unsigned		start ;
		unsigned		end ;

	CODE:
		dvb_error_clear() ;
		clear_settings(&settings) ;

		if (settings_href)
		{
			HVF_IV(settings_href, debug, settings.debug) ;
			HVF_IV(settings_href, save_cut, settings.save_cut) ;
			HVF_SVV(settings_href, error_callback, settings.error_callback) ;
			HVF_SVV(settings_href, user_data, settings.perl_data) ;
		}

		// fprintf(stderr, "cuts_aref ok = %d\n", SvROK(cuts_aref)) ;
		// fprintf(stderr, "cuts_aref type %d want %d\n", SvTYPE(SvRV(cuts_aref)), SVt_PVAV);


		if ((!SvROK(cuts_aref))
		|| (SvTYPE(SvRV(cuts_aref)) != SVt_PVAV))
		{
		 	croak("Linux::DVB::DVBT::TS::dvb_ts_cut requires a valid cuts array ref") ;
		}

	    // av_len returns -1 for empty. Returns maximum index number otherwise
		num_entries = av_len( (AV *)SvRV(cuts_aref) ) + 1 ;
		if (num_entries <= 0)
		{
		 	croak("Linux::DVB::DVBT::TS::dvb_ts_cut requires a list of cuts hashes") ;
		}


		// Create cut list
		INIT_LIST_HEAD(&cut_list);

		for (i=0; i <= num_entries ; i++)
		{
			if ((item = av_fetch((AV *)SvRV(cuts_aref), i, 0)) && SvOK (*item))
			{
	  			if ( SvTYPE(SvRV(*item)) != SVt_PVHV )
	  			{
	 			 	croak("Linux::DVB::DVBT::TS::dvb_ts_cut requires a list of cut hashes") ;
	 			}
	 			href = (HV *)SvRV(*item) ;

	 			// get start..end cut packet numbers
	 			val = HVF(href, start_pkt) ;
			 	start = SvIV (*val) ;
	 			val = HVF(href, end_pkt) ;
			 	end = SvIV (*val) ;

	 			// add to cut list
			 	add_cut(&cut_list, start, end) ;
			}
		}


		//_print_cut_list("__INITIAL__", &cut_list) ;

		// cut (frees the cut_list)
 		RETVAL = ts_cut(filename, ofilename, &cut_list, settings.debug) ;

	OUTPUT:
      RETVAL

# /*---------------------------------------------------------------------------------------------------*/
# /* Split TS file into program segments and advert segments */

int
dvb_ts_split(char *filename, char *ofilename, SV *cuts_aref, HV *settings_href=NULL)
	INIT:
		struct TS_settings settings;
		SV **val;
		struct list_head   	cut_list;
		unsigned 		num_entries ;
		unsigned 		i ;
		SV				**item ;
		HV				*href ;
		unsigned		start ;
		unsigned		end ;

	CODE:
		dvb_error_clear() ;
		clear_settings(&settings) ;

		if (settings_href)
		{
			HVF_IV(settings_href, debug, settings.debug) ;
			HVF_IV(settings_href, save_cut, settings.save_cut) ;
			HVF_SVV(settings_href, error_callback, settings.error_callback) ;
			HVF_SVV(settings_href, user_data, settings.perl_data) ;
		}

		// fprintf(stderr, "cuts_aref ok = %d\n", SvROK(cuts_aref)) ;
		// fprintf(stderr, "cuts_aref type %d want %d\n", SvTYPE(SvRV(cuts_aref)), SVt_PVAV);


		if ((!SvROK(cuts_aref))
		|| (SvTYPE(SvRV(cuts_aref)) != SVt_PVAV))
		{
		 	croak("Linux::DVB::DVBT::TS::dvb_ts_split requires a valid cuts array ref") ;
		}

	    // av_len returns -1 for empty. Returns maximum index number otherwise
		num_entries = av_len( (AV *)SvRV(cuts_aref) ) + 1 ;
		if (num_entries <= 0)
		{
		 	croak("Linux::DVB::DVBT::TS::dvb_ts_split requires a list of cuts hashes") ;
		}


		// Create cut list
		INIT_LIST_HEAD(&cut_list);

		for (i=0; i <= num_entries ; i++)
		{
			if ((item = av_fetch((AV *)SvRV(cuts_aref), i, 0)) && SvOK (*item))
			{
	  			if ( SvTYPE(SvRV(*item)) != SVt_PVHV )
	  			{
	 			 	croak("Linux::DVB::DVBT::TS::dvb_ts_split requires a list of cut hashes") ;
	 			}
	 			href = (HV *)SvRV(*item) ;

	 			// get start..end cut packet numbers
	 			val = HVF(href, start_pkt) ;
			 	start = SvIV (*val) ;
	 			val = HVF(href, end_pkt) ;
			 	end = SvIV (*val) ;

	 			// add to cut list
			 	add_cut(&cut_list, start, end) ;
			}
		}


		//_print_cut_list("__INITIAL__", &cut_list) ;

		// split (frees the cut_list)
		RETVAL = ts_split(filename, ofilename, &cut_list, settings.debug) ;

	OUTPUT:
     RETVAL


