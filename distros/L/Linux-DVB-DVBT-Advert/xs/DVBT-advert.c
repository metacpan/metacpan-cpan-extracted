 # VERSION = "1.000"

 # /*---------------------------------------------------------------------------------------------------*/
 # /* Run advert detection */

AV *
dvb_advert_detect(char *filename, HV *settings_href=NULL)
	INIT:
		HV * results;
		HV * settings ;
		SV * sv_user_data ;
		AV * wrapper ;

		struct Ad_user_data *user_data ;
		SV **val;
		HV * rh;
		unsigned i ;
		char key[256] ;

	    wrapper = (AV *)sv_2mortal((SV *)newAV());
		results = (HV *)sv_2mortal((SV *)newHV());
	    settings = (HV *)sv_2mortal((SV *)newHV());

	CODE:
		/* Create Perl data */
		HVS(results, settings, newRV((SV *)settings)) ;

		dvb_error_clear() ;
		user_data = (struct Ad_user_data *)malloc(sizeof(struct Ad_user_data)) ;
		memset(user_data, 0, sizeof(struct Ad_user_data)) ;
		init_user_data(user_data) ;

		execute_advert_detection(user_data, filename, settings_href, results, settings) ;

	    // == Pass results back to Perl ==

	    av_push(wrapper, newRV((SV *)results));

	    sv_user_data = sv_newmortal();
	    sv_setref_pv(sv_user_data, "AdataPtr", (void*)user_data);
	    av_push(wrapper, newRV((SV *)sv_user_data));

	    //RETVAL = newRV((SV *)wrapper);
	    RETVAL = wrapper;
	    //RETVAL = user_data ;


	OUTPUT:
      RETVAL



# /*---------------------------------------------------------------------------------------------------*/
# /* Run advert detection */

AV *
dvb_advert_detect_from_file(char *filename, HV *settings_href=NULL)
	INIT:
		HV * results ;
		HV * settings ;
		SV * sv_user_data ;
		AV * wrapper ;

		struct Ad_user_data *user_data ;
		SV **val;
		HV * rh;
		unsigned i ;
		char key[256] ;

	    wrapper = (AV *)sv_2mortal((SV *)newAV());
		results = (HV *)sv_2mortal((SV *)newHV());
	    settings = (HV *)sv_2mortal((SV *)newHV());

	CODE:
		/* Create Perl data */
		HVS(results, settings, newRV((SV *)settings)) ;

		dvb_error_clear() ;
		user_data = (struct Ad_user_data *)malloc(sizeof(struct Ad_user_data)) ;
		memset(user_data, 0, sizeof(struct Ad_user_data)) ;
		init_user_data(user_data) ;

		// Set settings
		advert_set_settings(user_data, settings_href) ;

		if (user_data->debug) fprintf(stderr, "[XS] Detect-from-file... \n") ;

		// read file
		detect_from_file(user_data, filename) ;

	    if (user_data->debug) fprintf(stderr, "[XS] dvb_err=%s [%03d]\n", dvb_error_str(dvb_error_code), dvb_error_code) ;
		if (user_data->debug) fprintf(stderr, "[XS] Detect-from-file done\n") ;

	    // == Pass results back to Perl ==

	    // copy settings
	    advert_get_settings(user_data, settings) ;

	    av_push(wrapper, newRV((SV *)results));

	    sv_user_data = sv_newmortal();
	    sv_setref_pv(sv_user_data, "AdataPtr", (void*)user_data);
	    av_push(wrapper, newRV((SV *)sv_user_data));

	    //RETVAL = newRV((SV *)wrapper);
	    RETVAL = wrapper;
	    //RETVAL = user_data ;

	OUTPUT:
     RETVAL




# /*---------------------------------------------------------------------------------------------------*/
# /* Get advert default settings (combined with any specified settings) */

SV *
dvb_advert_def_settings(HV *settings_href=NULL)
	INIT:
		HV * results;
		HV * frames ;
		HV * settings ;

		struct Ad_user_data user_data ;
		SV **val;
		HV * rh;
		unsigned i ;
		char key[256] ;

	    settings = (HV *)sv_2mortal((SV *)newHV());

	CODE:
		dvb_error_clear() ;
		init_user_data(&user_data) ;

		// Set settings
		advert_set_settings(&user_data, settings_href) ;

	    // == Pass results back to Perl ==
		advert_get_settings(&user_data, settings) ;

	    // Free up structures
		free_user_data(&user_data) ;

	    RETVAL = newRV((SV *)settings);

	OUTPUT:
     RETVAL


