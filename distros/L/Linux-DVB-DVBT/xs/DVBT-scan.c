 # VERSION = "1.001"

 # /*---------------------------------------------------------------------------------------------------*/
 # /* Set up for scanning */

void
dvb_scan_new(DVB *dvb, int verbose)
	CODE:
		// init the freq list
		clear_freqlist() ;

 # /*---------------------------------------------------------------------------------------------------*/
 # /* Set up for scanning */

void
dvb_scan_init(DVB *dvb, int verbose)
	CODE:
	 	dvb_scan_init(dvb, verbose) ;

 # /*---------------------------------------------------------------------------------------------------*/
 # /* Clear up after scanning */

void
dvb_scan_end(DVB *dvb, int verbose)
	CODE:
 		/* Free up results */
		dvb_scan_end(dvb, verbose) ;

 # /*---------------------------------------------------------------------------------------------------*/
 # /* Scan all frequencies starting from whatever the current tuning is */
SV *
dvb_scan(DVB *dvb, int verbose)

  INIT:
    HV * results;

    AV * streams ;
    HV * freqs ;
    AV * programs ;

    char key[256] ;
    char key2[256] ;

    struct dvbmon *dm ;
	struct list_head *item, *safe, *pitem, *fitem ;
	struct psi_program *program ;
	struct psi_stream *stream;
	struct prog_info *pinfo ;
    struct freqitem   *freqi;
    struct freq_info  *finfo;

    results = (HV *)sv_2mortal((SV *)newHV());

    streams = (AV *)sv_2mortal((SV *)newAV());
    programs = (AV *)sv_2mortal((SV *)newAV());
    freqs = (HV *)sv_2mortal((SV *)newHV());

  CODE:
  	/* get info */
    dm = dvb_scan_freqs(dvb, verbose) ;

  	/** Create Perl data **/
	HVS(results, ts, newRV((SV *)streams)) ;
	HVS(results, pr, newRV((SV *)programs)) ;
	HVS(results, freqs, newRV((SV *)freqs)) ;

 if (DVBT_DEBUG >= 10)
 {
	fprintf(stderr, "\n\n == DVBT.xs::dvb_scan() ================\n") ;

 }

    /* Store frequency info */
    list_for_each(item,&freq_list)
    {
		HV * fh;

		freqi = list_entry(item, struct freqitem, next);

		// Only consider valid frequencies
		if (VALID_FREQ(freqi->frequency))
		{

 if (DVBT_DEBUG >= 10)
 {
		fprintf(stderr, "#@f FREQ: %d Hz seen=%d tuned=%d (Strength=%d) [",
			freqi->frequency,
			freqi->flags.seen,
			freqi->flags.tuned,
			freqi->strength
		) ;
		fprintf(stderr, "inv=%d bw=%d crh=%d crl=%d con=%d tr=%d g=%d hi=%d",
		    freqi->params.inversion,
			freqi->params.u.ofdm.bandwidth,
			freqi->params.u.ofdm.code_rate_HP,
			freqi->params.u.ofdm.code_rate_LP,
			freqi->params.u.ofdm.constellation,
			freqi->params.u.ofdm.transmission_mode,
			freqi->params.u.ofdm.guard_interval,
			freqi->params.u.ofdm.hierarchy_information
		) ;
		fprintf(stderr, "]\n") ;
		fprintf(stderr, "#@f Mod=%d\n", co_t[ freqi->params.u.ofdm.constellation ] );
 }

			/* Convert structure fields into hash elements */
			fh = (HV *)sv_2mortal((SV *)newHV());

			HVS_I(fh, freqi, strength) ;
			HVS_I(fh, freqi, ber) ;
			HVS_I(fh, freqi, snr) ;
			HVS(fh, seen, newSViv(freqi->flags.seen)) ;
			HVS(fh, tuned, newSViv(freqi->flags.tuned)) ;

			// Convert frontend params into VDR values
			HVS_INT(fh, inversion, freqi->params.inversion) ;
			HVS_INT(fh, bandwidth, bw[ freqi->params.u.ofdm.bandwidth ] );
			HVS_INT(fh, code_rate_high, ra_t[ freqi->params.u.ofdm.code_rate_HP ] );
			HVS_INT(fh, code_rate_low, ra_t[ freqi->params.u.ofdm.code_rate_LP ] );
			HVS_INT(fh, modulation, co_t[ freqi->params.u.ofdm.constellation ] );
			HVS_INT(fh, transmission, tr[ freqi->params.u.ofdm.transmission_mode ] );
			HVS_INT(fh, guard_interval, gu[ freqi->params.u.ofdm.guard_interval ] );
			HVS_INT(fh, hierarchy, hi[ freqi->params.u.ofdm.hierarchy_information ] );

			sprintf(key, "%d", freqi->frequency) ;
			hv_store(freqs, key, strlen(key),  newRV((SV *)fh), 0) ;

		} // freq valid
	} // foreach freq



    /* Store stream info */
	list_for_each(item,&dm->info->streams)
	{
		HV * rh;
		HV * tsidh;
		int frequency ;

		stream = list_entry(item, struct psi_stream, next);

			// round up frequency to nearest kHz
			// HVS_I(rh, stream, frequency) ;
			frequency = ROUND_FREQUENCY(stream->frequency) ;

 if (DVBT_DEBUG >= 10)
 {
	fprintf(stderr, "#@f  stream: TSID %d freq = %d Hz [%d Hz] : tuned=%d updated=%d\n",
		stream->tsid,
		stream->frequency,
		frequency,
		stream->tuned,
		stream->updated
	) ;
 }


			/*
			//    	  int                  tsid;
			//
			//        // network //
			//        int                  netid;
			//        char                 net[PSI_STR_MAX];
			//
			//        int                  frequency;
			//        int                  symbol_rate;
			//        char                 *bandwidth;
			//        char                 *constellation;
			//        char                 *hierarchy;
			//        char                 *code_rate_hp;
			//        char                 *code_rate_lp;
			//        char                 *fec_inner;
			//        char                 *guard;
			//        char                 *transmission;
			//        char                 *polarization;
			*/

			/* Convert structure fields into hash elements */
			rh = (HV *)sv_2mortal((SV *)newHV());
			tsidh = (HV *)sv_2mortal((SV *)newHV());

			HVS_INT(rh, frequency, frequency) ;

			HVS_I(rh, stream, tsid) ;
			HVS_I(rh, stream, netid) ;
			HVS_S(rh, stream, bandwidth) ;
			HVSN_S(rh, stream, code_rate_hp, 	code_rate_high) ;
			HVSN_S(rh, stream, code_rate_lp, 	code_rate_low) ;
			HVSN_S(rh, stream, constellation, 	modulation) ;
			HVSN_S(rh, stream, guard, 			guard_interval) ;
			HVS_S(rh, stream, hierarchy) ;
			HVS_S(rh, stream, net) ;
			HVS_S(rh, stream, transmission) ;

			/* Process the program lcns attached to this stream

			'lcn' => {

				$tsid => {

					$pnr => {
						'service_type' => xx,
						'visible' => yy,
						'lcn' => zz,
					}
				}
			}
			*/
			list_for_each(pitem,&stream->prog_info_list)
			{
				/* Convert structure fields into hash elements */
				HV * pnrh = (HV *)sv_2mortal((SV *)newHV());

				pinfo = list_entry(pitem, struct prog_info, next);

 if (DVBT_DEBUG >= 10)
 {
	fprintf(stderr, "#@p  + LCN: %d (pnr %d) type=%d visible=%d\n",
		pinfo->lcn,
		pinfo->service_id,
		pinfo->service_type,
		pinfo->visible
	) ;
 }

				if (pinfo->lcn > 0)
				{
					/*
					int 				 service_id ; # same as pnr
					int 				 service_type ;
					int					 visible ;
					int					 lcn ;
					*/
					HVS_I(pnrh, pinfo, service_type) ;
					HVS_I(pnrh, pinfo, visible) ;
					HVS_I(pnrh, pinfo, lcn) ;

					sprintf(key2, "%d", pinfo->service_id) ;
					hv_store(tsidh, key2, strlen(key2),  newRV((SV *)pnrh), 0) ;
				}
			}
			HVS(rh, lcn, newRV((SV *)tsidh)) ;

			av_push(streams, newRV((SV *)rh));

	}

	/* store program info */
	list_for_each(item,&dm->info->programs)
	{
		program = list_entry(item, struct psi_program, next);

	    if (DVBT_DEBUG >= 15)
	    {
	    	print_program(program) ;
	    }

		/*
		//         int                  tsid;
		//         int                  pnr;
		//         int                  version;
		//         int                  running;
		//         int                  ca;
		//
		//         // program data //
		//         int                  type;
		//         int                  p_pid;             // program
		//         int                  v_pid;             // video
		//         int                  a_pid;             // audio
		//         int                  t_pid;             // teletext
		//         int                  s_pid;             // subtitle //by rainbowcrypt
		//         char                 audio[PSI_STR_MAX];
		//         char                 subtitle[PSI_STR_MAX]; //by rainbowcrypt
		//         char                 net[PSI_STR_MAX];
		//         char                 name[PSI_STR_MAX];
		//
		//         // status info //
		//         int                  updated;
		//         int                  seen;
		*/

 if (DVBT_DEBUG >= 10)
 {
	fprintf(stderr, "#@p PROG %d-%d: %s\n",
		program->tsid,
		program->pnr,
		program->name
	) ;
 }

		/* Only bother saving this if the same is set AND type > 0*/
		if ((strlen(program->name) > 0) && (program->type > 0))
		{
		HV * rh;
		AV * freq_array;
		int frequency ;

			/* Convert structure fields into hash elements */
			rh = (HV *)sv_2mortal((SV *)newHV());

 if (DVBT_DEBUG >= 10)
 {
	fprintf(stderr, "#@p + PNR %d pmt=%d  Video=%d Audio=%d Teletext=%d Subtitle=%d (type=%d)\n", /* by rainbowcrypt*/
		program->pnr,
		program->p_pid,
		program->v_pid,
		program->a_pid,
		program->t_pid,
		program->s_pid, /*by rainbowcrypt*/
		program->type
	) ;
 }

			HVS_I(rh, 	program, tsid) ;
			HVS_I(rh, 	program, pnr) ;
			HVS_I(rh, 	program, ca) ;
			HVS_I(rh, 	program, type) ;
			HVSN_I(rh, 	program, p_pid, 	pmt) ;
			HVSN_I(rh, 	program, v_pid, 	video) ;
			HVSN_I(rh, 	program, a_pid,		audio) ;
			HVSN_I(rh, 	program, t_pid,		teletext) ;
			HVSN_I(rh, 	program, s_pid,		subtitle) ;
			HVSN_I(rh, 	program, pcr_pid,	pcr) ;
			HVSN_S(rh, 	program, audio,		audio_details) ;
			HVSN_S(rh, 	program, subtitle,	subtitle_details) ; /*by rainbowcrypt*/
			HVS_S(rh, 	program, net) ;
			HVS_S(rh, 	program, name) ;

			// add frequencies
			freq_array = (AV *)sv_2mortal((SV *)newAV());
		    list_for_each(fitem,&program->tuned_freq_list) {
		        finfo = list_entry(fitem, struct freq_info, next);

				// round up frequency to nearest kHz
				frequency = ROUND_FREQUENCY(finfo->frequency) ;

 if (DVBT_DEBUG >= 10)
 {
	fprintf(stderr, "#@f + + freq = %d Hz [%d Hz]\n",
		finfo->frequency, frequency
	) ;
 }

		        AVS_I(freq_array, frequency) ;
		    }
			HVS(rh, freqs, newRV((SV *)freq_array)) ;

			// save entry in list
			av_push(programs, newRV((SV *)rh));

		}
	}

 if (DVBT_DEBUG >= 10)
 {
	fprintf(stderr, "\n\n == DVBT.xs::dvb_scan() - END =============\n") ;
 }


    RETVAL = newRV((SV *)results);
  OUTPUT:
    RETVAL

