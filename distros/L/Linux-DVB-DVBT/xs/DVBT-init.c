

# /*---------------------------------------------------------------------------------------------------*/

HV *
dvb_device_probe(unsigned adap, unsigned fe, unsigned debug=0)

  INIT:

	struct devinfo *info ;

	HV *results ;

  CODE:

	/* get info */
	info = dvb_probe_frontend(adap, fe, debug) ;

	if (info)
	{
		results = device_info_hv(info) ;

		/* free info */
		free(info) ;
	}
	else
	{
		results = (HV *)sv_2mortal((SV *)newHV());
	}

	RETVAL = results ;

  OUTPUT:
 	 RETVAL



 # /*---------------------------------------------------------------------------------------------------*/

SV *
dvb_device_names(DVB *dvb)
	INIT:
        HV * results;

	CODE:
		results = (HV *)sv_2mortal((SV *)newHV());

		/* get device names from dvb struct */
		HVS(results, fe_name, newSVpv(dvb->frontend, 0)) ;
		HVS(results, demux_name, newSVpv(dvb->demux, 0)) ;
		HVS(results, dvr_name, newSVpv(dvb->dvr, 0)) ;

	    RETVAL = newRV((SV *)results);
	  OUTPUT:
	    RETVAL


 # /*---------------------------------------------------------------------------------------------------*/

DVB *
dvb_init(char *adapter, int frontend)
	CODE:
	 RETVAL = dvb_init(adapter, frontend) ;
	OUTPUT:
	 RETVAL


 # /*---------------------------------------------------------------------------------------------------*/

DVB *
dvb_init_nr(int adapter_num, int frontend_num)
	CODE:
	 RETVAL = dvb_init_nr(adapter_num, frontend_num) ;
	OUTPUT:
	 RETVAL

 # /*---------------------------------------------------------------------------------------------------*/

void
dvb_fini(DVB *dvb);
	CODE:
	 dvb_fini(dvb) ;


 # /*---------------------------------------------------------------------------------------------------*/

void
dvb_set_debug(int debug);
	CODE:
	 dvb_debug = debug ;
	 DVBT_DEBUG = debug ;

# /*---------------------------------------------------------------------------------------------------*/
# /* Return error string */

SV *
dvb_error_str()
	INIT:
		SV *str;
		char *error_str ;

	CODE:
		error_str = dvb_error_str(dvb_error_code) ;
		RETVAL = newSVpv(error_str, 0) ;

	OUTPUT:
     RETVAL

# /*---------------------------------------------------------------------------------------------------*/
# /* Get file flags */

void
dvb_file_flags()

	CODE:
     fprintf(stderr, "O_LARGEFILE 0x%08x\n", O_LARGEFILE) ;
     fprintf(stderr, "O_WRONLY    0x%08x\n", O_WRONLY) ;
     fprintf(stderr, "O_TRUNC     0x%08x\n", O_TRUNC) ;
     fprintf(stderr, "O_CREAT     0x%08x\n", O_CREAT) ;


# /*---------------------------------------------------------------------------------------------------*/
# /* Get amount of free disk space for specified path */

float
dvb_free_disk(char *path)

	INIT:
		unsigned long long free_space ;

	CODE:
		free_space = get_free_space(path) ;
		//fprintf(stderr, "free_space(%s) %llu\n", path, free_space) ;
		RETVAL = (float)free_space ;
		//fprintf(stderr, " + space %.2f\n", RETVAL) ;

	OUTPUT:
		RETVAL

