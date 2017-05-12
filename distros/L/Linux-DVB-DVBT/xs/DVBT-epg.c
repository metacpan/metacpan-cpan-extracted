 # /*---------------------------------------------------------------------------------------------------*/

void
dvb_clear_epg();
	CODE:
	 clear_epg() ;


 # /*---------------------------------------------------------------------------------------------------*/
 # /* Scan all streams to gather all EPG information */
SV *
dvb_epg(DVB *dvb, int verbose, int alive, int section)

 INIT:
   AV * results;

	struct list_head *epg_list ;
	struct list_head *item, *safe;
    struct epgitem   *epg;
    struct epgitem   dummy_epg;

   results = (AV *)sv_2mortal((SV *)newAV());

 CODE:

	/*
	   // NOTE: Mask allows for multiple sections
	   // e.g. 0x50, 0xf0 means "read sections 0x50 - 0x5f"

	   //
		//    0x4E event_information_section - actual_transport_stream, present/following
		//    0x4F event_information_section - other_transport_stream, present/following
		//    0x50 to 0x5F event_information_section - actual_transport_stream, schedule
		//    0x60 to 0x6F event_information_section - other_transport_stream, schedule
	   //
	   // 0x50 - 0x6f => 01010000 - 01101111
	*/
	if (section)
	{
		epg_list = get_eit(/* struct dvb_state *dvb */ dvb,
	   		/* int section */section, /* int mask */0xff,
	   		/* int verbose */ verbose, /* int alive */ alive) ;
	}
	else
	{
		epg_list = get_eit(/* struct dvb_state *dvb */ dvb,
			/* int section */0x50, /* int mask */0xf0,
			/* int verbose */ verbose, /* int alive */ alive) ;

		epg_list = get_eit(/* struct dvb_state *dvb */ dvb,
			/* int section */0x60, /* int mask */0xf0,
			/* int verbose */ verbose, /* int alive */ alive) ;
	}

    if (epg_list)
    {
		/* Create Perl data */
		list_for_each(item, epg_list)
		{
		HV * rh;

			epg = list_entry(item, struct epgitem, next);

			/* Convert structure fields into hash elements */
			rh = (HV *)sv_2mortal((SV *)newHV());

			HVS_I(rh, epg, id) ;
			HVS_I(rh, epg, tsid) ;
			HVS_I(rh, epg, pnr) ;
			HVS_I(rh, epg, start) ;
			HVS_I(rh, epg, stop) ;
			HVS_I(rh, epg, duration_secs) ;
			HVS_I(rh, epg, flags) ;

			if (epg->lang[0])
			{
				HVS_STRING(rh, epg, lang);
			}
			if (epg->name[0])
			{
				// title
				HVS_STRING(rh, epg, name);
			}
			if (epg->stext[0])
			{
				// synopsis / description
				HVS_STRING(rh, epg, stext);
			}
			if (epg->etext)
			{
				// extended text
				HVS_STRING(rh, epg, etext);
			}
			if (epg->playing)
			{
				HVS_I(rh, epg, playing) ;
			}
			if (epg->cat[0])
			{
				hv_store(rh, "genre", sizeof("genre")-1, newSVpv(_to_string(epg->cat[0]), 0), 0) ;
			}
			if (epg->tva_prog[0])
			{
				HVS_STRING(rh, epg, tva_prog);
			}
			if (epg->tva_series[0])
			{
				HVS_STRING(rh, epg, tva_series);
			}

			av_push(results, newRV((SV *)rh));
	   }


   }

   RETVAL = newRV((SV *)results);
 OUTPUT:
   RETVAL

 # /*---------------------------------------------------------------------------------------------------*/
 # /* Gather EPG statistics */
SV *
dvb_epg_stats(DVB *dvb)

 INIT:
    HV * results;

	struct partitem  *partp;
	struct erritem   *errp;
	struct list_head *item;

    HV * totals ;
    AV * parts ;
    AV * errors ;

    results = (HV *)sv_2mortal((SV *)newHV());
    totals = (HV *)sv_2mortal((SV *)newHV());
    parts = (AV *)sv_2mortal((SV *)newAV());
    errors = (AV *)sv_2mortal((SV *)newAV());

 CODE:

	/* Create Perl data */
	HVS(results, totals, newRV((SV *)totals)) ;
	HVS(results, parts, newRV((SV *)parts)) ;
	HVS(results, errors, newRV((SV *)errors)) ;


	// totals
	HVS_INT(totals, parts_remaining, parts_remaining) ;
	HVS_INT(totals, total_errors, total_errors) ;


	// list of parts
	list_for_each(item, &parts_list)
	{
	HV * rh;
	struct partitem  *partp;

		partp = list_entry(item, struct partitem, next);

		/* Convert structure fields into hash elements */
		rh = (HV *)sv_2mortal((SV *)newHV());

		/*
		struct partitem {
		    struct list_head    next;
		    int                 pnr;
		    int                 tsid;
		    int                 parts;
		    int                 parts_left;
		};
		*/
		HVS_I(rh, partp, pnr) ;
		HVS_I(rh, partp, tsid) ;
		HVS_I(rh, partp, parts) ;
		HVS_I(rh, partp, parts_left) ;


		av_push(parts, newRV((SV *)rh));
	}

	// list of errors
	list_for_each(item, &errs_list)
	{
	HV * rh;
	struct erritem   *errp;

		errp = list_entry(item, struct erritem, next);

		/* Convert structure fields into hash elements */
		rh = (HV *)sv_2mortal((SV *)newHV());

		/*
		struct erritem {
		    struct list_head    next;
		    int                 freq;
		    int                 section;
		    int                 errors;
		};
		*/
		HVS_I(rh, errp, freq) ;
		HVS_I(rh, errp, section) ;
		HVS_I(rh, errp, errors) ;

		av_push(errors, newRV((SV *)rh));
	}


   	RETVAL = newRV((SV *)results);
 OUTPUT:
   RETVAL


